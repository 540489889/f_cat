import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../services/api_client.dart';

class ServicePage extends StatefulWidget {
  const ServicePage({super.key});

  @override
  State<ServicePage> createState() => _ServicePageState();
}

class _ServicePageState extends State<ServicePage> {
  final TextEditingController _inputCtrl = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;
  bool _isListening = false;
  Timer? _listenTimer;
  String? _recognizerError;
  String _localeId = 'zh_CN';
  int? _sessionId;
  String? _sessionType;
  final List<Map<String, dynamic>> _messages = [];
  final ScrollController _scrollCtrl = ScrollController();
  int _msgPage = 1;
  bool _msgHasMore = true;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initChatSession();
  }

  @override
  void dispose() {
    _listenTimer?.cancel();
    _scrollCtrl.dispose();
    _inputCtrl.dispose();
    _speech.cancel();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    try {
      final available = await _speech.initialize(
        onStatus: (status) {
          debugPrint('[语音识别] 状态: $status');
          if (status == 'done' || status == 'notListening') {
            _listenTimer?.cancel();
            if (mounted) setState(() => _isListening = false);
          }
        },
        onError: (err) {
          debugPrint('[语音识别] 错误: ${err.errorMsg}');
          _listenTimer?.cancel();
          if (mounted) setState(() => _isListening = false);
        },
        debugLogging: true,
      );
      debugPrint('[语音识别] 初始化结果: $available');
      if (mounted) setState(() => _speechAvailable = available);
    } catch (e) {
      debugPrint('[语音识别] 初始化失败: $e');
      if (mounted) {
        setState(() => _speechAvailable = false);
        _recognizerError = '当前设备不支持系统语音识别，请使用键盘输入';
      }
      return;
    }

    // 语言获取独立 try-catch，失败不影响语音可用性
    if (_speechAvailable) {
      try {
        final locales = await _speech.locales();
        debugPrint('[语音识别] 可用语言: ${locales.map((l) => l.localeId)}');
        final hasZh = locales.any((l) => l.localeId == 'zh_CN');
        final sysLocale = await _speech.systemLocale();
        _localeId = hasZh ? 'zh_CN' : (sysLocale?.localeId ?? 'en_US');
        debugPrint('[语音识别] 使用语言: $_localeId');
      } catch (e) {
        debugPrint('[语音识别] 获取语言失败: $e');
      }
    }
  }

  Future<void> _initChatSession() async {
    print('[客服会话] ===== 获取会话 =====');
    try {
      final res = await ApiClient.instance.get('/app/chat/session/ai');
      print('[客服会话] httpCode=${res.isSuccess}, msg=${res.message}');
      print('[客服会话] data=${res.data}');
      if (res.isSuccess && res.isMap) {
        final map = res.asMap;
        _sessionId = map['id'] as int?;
        _sessionType = map['sessionType'] as String?;
        print('[客服会话] id=$_sessionId, type=$_sessionType, ragId=${map['ragId']}');
        if (mounted) setState(() {});
        // 获取消息历史
        if (_sessionId != null) {
          _loadMessages();
        }
      }
    } catch (e) {
      print('[客服会话] 异常: $e');
    }
  }

  Future<void> _loadMessages({bool loadMore = false}) async {
    if (_sessionId == null) return;
    if (loadMore && !_msgHasMore) return;
    final page = loadMore ? _msgPage + 1 : 1;
    print('[客服消息] ===== 获取消息 page=$page =====');
    try {
      final body = <String, dynamic>{
        'sessionId': _sessionId,
        'page': page,
        'size': 20,
      };
      final res = await ApiClient.instance.post('/app/chat/messages', body: body);
      print('[客服消息] isSuccess=${res.isSuccess}, msg=${res.message}');
      if (res.isSuccess) {
        final list = res.asList;
        print('[客服消息] 共${list.length}条消息');
        final newMsgs = <Map<String, dynamic>>[];
        for (int i = list.length - 1; i >= 0; i--) {
          newMsgs.add(list[i] as Map<String, dynamic>);
        }
        if (!mounted) return;
        setState(() {
          if (loadMore) {
            // 记录当前第一条消息id，用于保持滚动位置
            _messages.insertAll(0, newMsgs);
          } else {
            _messages
              ..clear()
              ..addAll(newMsgs);
          }
          _msgPage = page;
          _msgHasMore = list.length >= 20;
        });
        if (!loadMore) _scrollToBottom();
      }
    } catch (e) {
      print('[客服消息] 异常: $e');
    }
  }

  Future<void> _sendMessage(String content) async {
    if (_sessionId == null || content.isEmpty) return;
    final text = content.trim();
    _inputCtrl.clear();

    final containsRengong = text.contains('人工');

    // 如果包含"人工"，插入确认转人工的卡片，不调用发送消息接口
    if (containsRengong) {
      setState(() => _messages.add(<String, dynamic>{
        'content': text,
        'senderType': 'user',
        'createTime': DateTime.now().toIso8601String(),
      }));
      setState(() => _messages.add(<String, dynamic>{
        'messageType': 'transfer_confirm',
        'content': '是否确认转接人工客服？',
        'senderType': 'agent',
      }));
      _scrollToBottom();
      return;
    }

    // 先添加用户消息（即时回显）
    setState(() => _messages.add(<String, dynamic>{
      'content': text,
      'senderType': 'user',
      'createTime': DateTime.now().toIso8601String(),
    }));
    // AI 模式下先插入加载卡片
    final bool isAi = (_sessionType ?? 'ai') == 'ai';
    if (isAi) {
      setState(() => _messages.add(<String, dynamic>{
        'messageType': 'loading',
        'senderType': 'agent',
      }));
    }
    _scrollToBottom();
    await _callSendApi(text, _sessionType ?? 'ai');
  }

  Future<void> _callSendApi(String text, String type) async {
    if (_sessionId == null) return;
    try {
      final body = <String, dynamic>{
        'sessionId': _sessionId,
        'content': text,
        'type': type,
        'messageType': 'text',
      };
      print('[客服发送] body=$body');
      final res = await ApiClient.instance.post('/app/chat/sendMsg', body: body);
      print('[客服发送] isSuccess=${res.isSuccess}, msg=${res.message}, data=${res.data}');
      if (res.isSuccess) {
        // 找到加载卡片并替换为 AI 回复
        final loadingIdx = _messages.indexWhere((m) => m['messageType'] == 'loading');
        Map<String, dynamic>? reply;
        if (res.data is List) {
          for (final item in (res.data as List)) {
            if (item is Map<String, dynamic> && item['senderType'] != 'user' && item['senderType'] != 'member') {
              reply = item;
            }
          }
        } else if (res.isMap) {
          final map = res.asMap;
          if (map['senderType'] != 'user' && map['senderType'] != 'member') {
            reply = map;
          }
        }
        setState(() {
          if (loadingIdx >= 0 && reply != null) {
            _messages[loadingIdx] = reply;
          } else if (reply != null) {
            _messages.add(reply);
          } else if (loadingIdx >= 0) {
            _messages.removeAt(loadingIdx);
          }
        });
        _scrollToBottom();
      } else if (type == 'ai') {
        // AI 请求失败，移除加载卡片
        final idx = _messages.indexWhere((m) => m['messageType'] == 'loading');
        if (idx >= 0) setState(() => _messages.removeAt(idx));
      }
    } catch (e) {
      print('[客服发送] 异常: $e');
    }
  }

  Future<void> _onConfirmTransfer() async {
    setState(() {
      _sessionType = 'manual';
      for (final m in _messages) {
        if (m['messageType'] == 'transfer_confirm') {
          m['confirmed'] = true;
          break;
        }
      }
    });
    // 调用转人工接口
    if (_sessionId == null) return;
    try {
      final res = await ApiClient.instance.post('/app/chat/transfer', body: <String, dynamic>{
        'sessionId': _sessionId,
      });
      print('[转人工] isSuccess=${res.isSuccess}, data=${res.data}');
    } catch (e) {
      print('[转人工] 异常: $e');
    }
  }

  Future<void> _closeSession() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('关闭会话'),
        content: const Text('确定要关闭当前会话吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消', style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('关闭', style: TextStyle(color: Color(0xFFFF4D4F)))),
        ],
      ),
    );
    if (confirm != true || _sessionId == null) return;
    try {
      await ApiClient.instance.post('/app/chat/close/$_sessionId');
      if (mounted) Navigator.pop(context);
    } catch (e) {
      print('[关闭会话] 异常: $e');
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  void _stopListening() async {
    _listenTimer?.cancel();
    await _speech.stop();
    if (mounted) setState(() => _isListening = false);
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      _stopListening();
      return;
    }

    if (!_speechAvailable) {
      _showToast(_recognizerError ?? '语音识别不可用，请检查麦克风权限');
      return;
    }

    setState(() => _isListening = true);

    // 注意：不要 await listen()，它是长时操作，采用 fire-and-forget 方式
    try {
      _speech.listen(
        onResult: (result) {
          final words = result.recognizedWords;
          debugPrint('[语音识别] final=${result.finalResult}, words="$words"');

          if (words.isNotEmpty && mounted) {
            setState(() {
              _inputCtrl.text = words;
              _inputCtrl.selection = TextSelection.collapsed(offset: words.length);
            });
          }
        },
        onSoundLevelChange: (level) {
          debugPrint('[语音识别] 音量: $level');
        },
        listenOptions: stt.SpeechListenOptions(
          localeId: _localeId,
          listenMode: stt.ListenMode.search,
          cancelOnError: false,
          onDevice: false,
          partialResults: true,
          autoPunctuation: true,
        ),
      );
    } catch (e) {
      debugPrint('[语音识别] listen 异常: $e');
      if (mounted) setState(() => _isListening = false);
    }

    // 15秒超时自动停止（华为等设备语音服务可能无响应）
    _listenTimer?.cancel();
    _listenTimer = Timer(const Duration(seconds: 15), () {
      if (_isListening) {
        debugPrint('[语音识别] 超时自动停止');
        _stopListening();
        _showToast('未检测到语音，请重试');
      }
    });
  }

  void _showToast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 80, left: 40, right: 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFFF7A47).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(18),
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/logo.png', width: 36, height: 36, fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const Icon(Icons.pets, color: Color(0xFFFF7A47), size: 20),
        ),
      ),
    );
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(timeStr).toLocal();
      return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF5F0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_left,
              color: Colors.black87, size: 34),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        centerTitle: true,
        title: const Text('客服',
            style: TextStyle(
                color: Colors.black87,
                fontSize: 17,
                fontWeight: FontWeight.w500)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: _closeSession,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFFF7A47).withValues(alpha: 0.1),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
              ),
              icon: const Icon(Icons.power_settings_new, size: 14, color: Color(0xFFFF7A47)),
              label: const Text('关闭', style: TextStyle(color: Color(0xFFFF7A47), fontSize: 12)),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF5F0), Colors.white],
          ),
        ),
        child: Column(
          children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _loadMessages(loadMore: true),
              color: const Color(0xFFFF7A47),
              child: ListView.builder(
                controller: _scrollCtrl,
                physics: const AlwaysScrollableScrollPhysics(),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];

                // 转人工确认卡片 — 样式与AI消息一致
                if (msg['messageType'] == 'transfer_confirm') {
                  final confirmed = msg['confirmed'] == true;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        _buildAvatar(),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                                bottomLeft: Radius.circular(0),
                                bottomRight: Radius.circular(12),
                              ),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('是否确认转接人工客服？', style: TextStyle(fontSize: 14, color: Color(0xFF333333), height: 1.5)),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: 140,
                                  height: 34,
                                  child: ElevatedButton(
                                    onPressed: confirmed ? null : _onConfirmTransfer,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: confirmed ? const Color(0xFFCCCCCC) : const Color(0xFFFF7A47),
                                      padding: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
                                    ),
                                    child: Text(
                                      confirmed ? '已确认转人工' : '确认转人工',
                                      style: TextStyle(fontSize: 13, color: confirmed ? Colors.white70 : Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // AI 加载中卡片
                if (msg['messageType'] == 'loading') {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAvatar(),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                              bottomLeft: Radius.circular(0),
                              bottomRight: Radius.circular(12),
                            ),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 14, height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: const Color(0xFFFF7A47).withValues(alpha: 0.6)),
                              ),
                              const SizedBox(width: 8),
                              const Text('思考中...', style: TextStyle(fontSize: 13, color: Color(0xFF999999))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final isAgent = msg['senderType'] == 'agent';
                final content = msg['content'] as String? ?? '';
                final time = _formatTime(msg['createTime'] as String?);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: isAgent
                        ? MainAxisAlignment.start
                        : MainAxisAlignment.end,
                    children: [
                      if (isAgent) ...[
                        _buildAvatar(),
                        const SizedBox(width: 10),
                      ],
                      Flexible(
                        child: Container(
                          padding:
                              const EdgeInsets.fromLTRB(14, 12, 14, 10),
                          decoration: BoxDecoration(
                            color: isAgent ? Colors.white : const Color(0xFFFF7A47),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(12),
                              topRight: const Radius.circular(12),
                              bottomLeft: isAgent
                                  ? const Radius.circular(0)
                                  : const Radius.circular(12),
                              bottomRight: isAgent
                                  ? const Radius.circular(12)
                                  : const Radius.circular(0),
                            ),
                            boxShadow: isAgent
                                ? [
                                    BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.04),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2)),
                                  ]
                                : null,
                          ),
                          child: Column(
                            crossAxisAlignment: isAgent
                                ? CrossAxisAlignment.start
                                : CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                content,
                                style: TextStyle(
                                    fontSize: 14,
                                    color: isAgent
                                        ? const Color(0xFF333333)
                                        : Colors.white,
                                    height: 1.5),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                time,
                                style: TextStyle(
                                  color: isAgent
                                      ? Colors.grey
                                      : Colors.white.withValues(alpha: 0.7),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (!isAgent) ...[
                        const SizedBox(width: 10),
                        _buildAvatar(),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
          ),

          // 录音状态提示条
          if (_isListening)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              color: const Color(0xFFFF7A47).withValues(alpha: 0.1),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _PulsingDot(),
                  SizedBox(width: 8),
                  Text('正在聆听...',
                      style: TextStyle(
                          color: Color(0xFFFF7A47), fontSize: 13)),
                ],
              ),
            ),

          // 底部输入栏
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              decoration: const BoxDecoration(color: Colors.white),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 麦克风按钮
                  GestureDetector(
                    onTap: _toggleListening,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isListening
                            ? const Color(0xFFFF7A47)
                            : Colors.transparent,
                        border: Border.all(
                          color: _isListening
                              ? const Color(0xFFFF7A47)
                              : Colors.grey[400]!,
                        ),
                      ),
                      child: Center(
                        child: _isListening
                            ? const _PulsingDot(
                                dotSize: 10, dotColor: Colors.white)
                            : const Icon(Icons.mic_none,
                                color: Colors.grey, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 输入框
                  Expanded(
                    child: Container(
                      height: 38,
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(19),
                      ),
                      child: TextField(
                        controller: _inputCtrl,
                        onTap: _scrollToBottom,
                        textAlignVertical: TextAlignVertical.center,
                        decoration: InputDecoration.collapsed(
                          hintText: _isListening ? '正在识别语音...' : '请输入消息',
                          hintStyle: TextStyle(
                            color: _isListening
                                ? const Color(0xFFFF7A47)
                                    .withValues(alpha: 0.6)
                                : Colors.grey[400],
                            fontSize: 13,
                          ),
                        ),
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF333333)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 发送按钮
                  GestureDetector(
                    onTap: () {
                      final text = _inputCtrl.text.trim();
                      if (text.isNotEmpty) {
                        _sendMessage(text);
                      }
                    },
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                          color: Color(0xFFFF7A47),
                          shape: BoxShape.circle),
                      child: Image.asset(
                          'assets/images/icon/send-1.png',
                          width: 17,
                          height: 17),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

/// 录音时麦克风内的脉冲动画小点
class _PulsingDot extends StatefulWidget {
  final double dotSize;
  final Color dotColor;

  const _PulsingDot({this.dotSize = 8, this.dotColor = const Color(0xFFFF7A47)});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _scale = Tween(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) => Transform.scale(
        scale: _scale.value,
        child: Container(
          width: widget.dotSize,
          height: widget.dotSize,
          decoration: BoxDecoration(
            color: widget.dotColor,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
