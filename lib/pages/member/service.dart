import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:huawei_ml_language/huawei_ml_language.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../services/api_client.dart';
import '../../services/user_state.dart';

class ServicePage extends StatefulWidget {
  const ServicePage({super.key});

  @override
  State<ServicePage> createState() => _ServicePageState();
}

class _ServicePageState extends State<ServicePage> {
  final TextEditingController _inputCtrl = TextEditingController();
  final _listenable = IndicatorStateListenable();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;
  bool _isListening = false;
  Timer? _listenTimer;
  String? _recognizerError;
  String _localeId = 'zh_CN';
  bool _isHuaweiDevice = false;
  MLAsrRecognizer? _huaweiAsr;
  int? _sessionId;
  String? _sessionType;
  final List<Map<String, dynamic>> _messages = [];
  late EasyRefreshController _easyController;
  bool _shrinkWrap = false;
  double? _viewportDimension;
  int _msgPage = 1;
  bool _msgHasMore = true;

  @override
  void initState() {
    super.initState();
    _easyController = EasyRefreshController(controlFinishRefresh: true, controlFinishLoad: true);
    _listenable.addListener(_onHeaderChange);
    _inputCtrl.addListener(() => setState(() {}));
    _initSpeech();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && context.read<UserState>().isLoggedIn) {
        _initChatSession();
      }
    });
  }

  @override
  void dispose() {
    _listenTimer?.cancel();
    _listenable.removeListener(_onHeaderChange);
    _easyController.dispose();
    _inputCtrl.dispose();
    super.dispose();
  }

  void _onHeaderChange() {
    final state = _listenable.value;
    if (state != null) {
      final position = state.notifier.position;
      _viewportDimension ??= position.viewportDimension;
      final shrinkWrap = state.notifier.position.maxScrollExtent == 0;
      if (_shrinkWrap != shrinkWrap && _viewportDimension == position.viewportDimension) {
        setState(() => _shrinkWrap = shrinkWrap);
      }
    }
  }

  // ---------- 业务逻辑 ----------

  Future<void> _initChatSession() async {
    print('[客服会话] ===== 获取会话 =====');
    try {
      final res = await ApiClient.instance.get('/app/chat/session/ai');
      print('[客服会话] isSuccess=${res.isSuccess}, msg=${res.message}');
      print('[客服会话] data=${res.data}');
      if (res.isSuccess && res.isMap) {
        final map = res.asMap;
        _sessionId = map['id'] as int?;
        _sessionType = map['sessionType'] as String?;
        print('[客服会话] id=$_sessionId, type=$_sessionType, ragId=${map['ragId']}');
        if (mounted) setState(() {});
        if (_sessionId != null) _loadMessages();
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
      final body = <String, dynamic>{'sessionId': _sessionId, 'page': page, 'size': 20};
      final res = await ApiClient.instance.post('/app/chat/messages', body: body);
      print('[客服消息] isSuccess=${res.isSuccess}, msg=${res.message}');
      if (res.isSuccess) {
        final list = res.asList;
        print('[客服消息] 共${list.length}条消息');
        final newMsgs = list.map((e) => e as Map<String, dynamic>).toList();
        if (!mounted) return;
        setState(() {
          if (loadMore) {
            _messages.addAll(newMsgs);
          } else {
            _messages..clear()..addAll(newMsgs);
          }
          _msgPage = page;
          _msgHasMore = list.length >= 20;
        });
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
    if (containsRengong) {
      setState(() => _messages.insert(0, <String, dynamic>{'messageType': 'transfer_confirm', 'confirmed': false}));
      _scrollToBottom();
      return;
    }
    final bool isAi = (_sessionType ?? 'ai') == 'ai';
    setState(() {
      if (isAi) {
        _messages.insert(0, <String, dynamic>{'messageType': 'loading', 'senderType': 'agent'});
      }
      _messages.insert(isAi ? 1 : 0, <String, dynamic>{'content': text, 'senderType': 'user', 'createTime': DateTime.now().toIso8601String()});
    });
    _scrollToBottom();
    await _callSendApi(text, _sessionType ?? 'ai');
  }

  Future<void> _callSendApi(String text, String type) async {
    if (_sessionId == null) return;
    try {
      final body = <String, dynamic>{'sessionId': _sessionId, 'content': text, 'type': type, 'messageType': 'text'};
      print('[客服发送] body=$body');
      final res = await ApiClient.instance.post('/app/chat/sendMsg', body: body);
      print('[客服发送] isSuccess=${res.isSuccess}, msg=${res.message}, data=${res.data}');
      if (res.isSuccess) {
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
            _messages.insert(0, reply);
          } else if (loadingIdx >= 0) {
            _messages.removeAt(loadingIdx);
          }
        });
        _scrollToBottom();
      } else if (type == 'ai') {
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
        if (m['messageType'] == 'transfer_confirm') { m['confirmed'] = true; break; }
      }
    });
  }

  Future<void> _closeSession() async {
    print('[客服会话] ===== 关闭会话 =====');
    try {
      await ApiClient.instance.post('/app/chat/session/close', body: {'sessionId': _sessionId});
      setState(() {
        _sessionId = null;
        _messages.clear();
        _msgPage = 1;
        _msgHasMore = true;
      });
      Future.delayed(const Duration(milliseconds: 300), _initChatSession);
    } catch (e) {
      print('[客服会话] 关闭异常: $e');
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      try {
        PrimaryScrollController.of(context).jumpTo(0);
      } catch (_) {}
    });
  }

  Future<void> _initSpeech() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final manufacturer = androidInfo.manufacturer.toLowerCase();
      _isHuaweiDevice = manufacturer.contains('huawei') || manufacturer.contains('honor');
    } catch (_) {}
    if (_isHuaweiDevice) {
      if (mounted) setState(() => _speechAvailable = true);
      return;
    }
    try {
      final available = await _speech.initialize(onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          _listenTimer?.cancel();
          if (mounted) setState(() => _isListening = false);
        }
      });
      if (mounted) setState(() => _speechAvailable = available);
    } catch (_) {
      if (mounted) setState(() => _speechAvailable = false);
    }
    if (_speechAvailable) {
      try {
        final locales = await _speech.locales();
        final hasZh = locales.any((l) => l.localeId == 'zh_CN');
        final sysLocale = await _speech.systemLocale();
        _localeId = hasZh ? 'zh_CN' : (sysLocale?.localeId ?? 'en_US');
      } catch (_) {}
    }
  }

  Future<void> _startListening() async {
    if (_isHuaweiDevice) {
      // Huawei ML Kit
      _huaweiAsr = MLAsrRecognizer();
      _huaweiAsr!.setAsrListener(MLAsrListener(onRecognizingResults: (result) {
        if (result.isNotEmpty && mounted) setState(() => _inputCtrl.text = result);
      }, onError: (error, code) {
        if (mounted) setState(() => _isListening = false);
      }));
      try {
        final config = MLAsrSetting(
          language: _localeId == 'zh_CN' ? MLAsrConstants.LAN_ZH_CN : MLAsrConstants.LAN_EN_US,
          feature: MLAsrConstants.FEATURE_WORDFLUX,
        );
        _huaweiAsr!.startRecognizing(config);
        if (mounted) setState(() => _isListening = true);
      } catch (_) { if (mounted) setState(() => _isListening = false); }
    } else {
      if (!_speechAvailable) return;
      await _speech.listen(
        onResult: (r) { if (mounted) setState(() => _inputCtrl.text = r.recognizedWords); },
        localeId: _localeId,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      );
      if (mounted) setState(() => _isListening = true);
      _listenTimer = Timer(const Duration(seconds: 25), () => _stopListening());
    }
  }

  Future<void> _stopListening() async {
    _listenTimer?.cancel();
    if (_isHuaweiDevice) {
      try { _huaweiAsr?.destroy(); _huaweiAsr = null; } catch (_) {}
    } else {
      await _speech.stop();
    }
    if (mounted) setState(() => _isListening = false);
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _stopListening();
    } else {
      await _startListening();
    }
  }

  // ---------- UI ----------

  Widget _buildInputBar() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return SafeArea(
      top: false,
      bottom: false,
      child: Container(
        color: Colors.white,
        padding: EdgeInsets.fromLTRB(8, 8, 8, 8 + bottomPadding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _toggleListening,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 36, height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isListening ? const Color(0xFFFF7A47) : Colors.transparent,
                  border: Border.all(color: _isListening ? const Color(0xFFFF7A47) : Colors.grey[400]!),
                ),
                child: _isListening
                    ? const _PulsingDot(dotSize: 8, dotColor: Colors.white)
                    : Icon(Icons.mic_none, size: 18, color: Colors.grey[600]),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(19),
                ),
                child: TextField(
                  controller: _inputCtrl,
                  minLines: 1,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: _isListening ? '正在识别语音...' : '请输入消息',
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  style: const TextStyle(fontSize: 13, color: Color(0xFF333333)),
                  onSubmitted: (_) => _sendMessage(_inputCtrl.text),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _sendMessage(_inputCtrl.text),
              child: Container(
                width: 34, height: 34,
                decoration: const BoxDecoration(color: Color(0xFFFF7A47), shape: BoxShape.circle),
                child: Image.asset('assets/images/icon/send-1.png', width: 17, height: 17),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return ClipOval(
      child: Container(
        width: 36, height: 36,
        decoration: const BoxDecoration(color: Color(0xFFFF7A47)),
        child: const Icon(Icons.support_agent, size: 20, color: Colors.white),
      ),
    );
  }

  Widget _buildMessageItem(int index) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final msg = _messages[index];
        final isAgent = msg['senderType'] == 'agent';
        final maxWidth = math.min(constraints.maxWidth - 124, 400.0);
        final content = (msg['content'] as String?) ?? '';
        final time = _formatTime(msg['createTime'] as String?);
        final isTransferConfirm = msg['messageType'] == 'transfer_confirm';
        final isConfirmed = msg['confirmed'] == true;
        final isLastMsg = index == _messages.length - 1;

        // 转人工确认卡片
        if (isTransferConfirm) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAvatar(),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(4),
                      bottomRight: Radius.circular(16),
                    ),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('是否确认转接人工客服？', style: TextStyle(fontSize: 14, color: Color(0xFF333333))),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 32,
                        child: ElevatedButton(
                          onPressed: isConfirmed ? null : _onConfirmTransfer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF7A47),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            elevation: 0,
                          ),
                          child: Text(isConfirmed ? '已确认' : '确认转人工', style: const TextStyle(fontSize: 12, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        // loading 卡片
        if (msg['messageType'] == 'loading') {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAvatar(),
                const SizedBox(width: 10),
                Container(
                  constraints: const BoxConstraints(maxWidth: 160),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4), topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(4), bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: const Color(0xFFFF7A47))),
                      const SizedBox(width: 8),
                      const Text('正在思考...', style: TextStyle(fontSize: 13, color: Color(0xFF999999))),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        // 普通消息
        final continuously = index > 0 && _messages[index - 1]['senderType'] == msg['senderType'];

        return Container(
          margin: EdgeInsets.only(top: 8, bottom: continuously ? 0 : 8, left: 16, right: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isAgent) ...[
                if (!continuously)
                  Padding(padding: const EdgeInsets.only(right: 8), child: _buildAvatar())
                else
                  const SizedBox(width: 44),
              ],
              if (!isAgent) const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isAgent ? const Color(0xFFF5F5F5) : const Color(0xFFFF7A47),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isAgent && !continuously ? 4 : 16),
                    bottomRight: Radius.circular(!isAgent && !continuously ? 4 : 16),
                  ),
                ),
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: isAgent ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                  children: [
                    Text(content, style: TextStyle(fontSize: 14, color: isAgent ? const Color(0xFF333333) : Colors.white, height: 1.5)),
                    if (time.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(time, style: TextStyle(fontSize: 11, color: isAgent ? Colors.grey : Colors.white.withValues(alpha: 0.7))),
                    ],
                  ],
                ),
              ),
              if (isAgent) const Spacer(),
              if (!isAgent && !continuously)
                Padding(padding: const EdgeInsets.only(left: 8), child: _buildAvatar())
              else if (!isAgent)
                const SizedBox(width: 44),
            ],
          ),
        );
      },
    );
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(timeStr).toLocal();
      return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.keyboard_arrow_left, color: Colors.black87, size: 34),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          centerTitle: true,
          title: const Text('客服', style: TextStyle(color: Colors.black87, fontSize: 17, fontWeight: FontWeight.w500)),
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
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: EasyRefresh(
                    clipBehavior: Clip.none,
                    onRefresh: () {},
                    onLoad: () {
                      return Future.delayed(const Duration(milliseconds: 300), () {
                        if (!mounted) return;
                        _loadMessages(loadMore: true);
                      });
                    },
                    header: ListenerHeader(
                      listenable: _listenable,
                      triggerOffset: 100000,
                      clamping: false,
                    ),
                    footer: BuilderFooter(
                      triggerOffset: 40,
                      clamping: false,
                      position: IndicatorPosition.above,
                      infiniteOffset: null,
                      processedDuration: Duration.zero,
                      builder: (context, state) {
                        return Stack(
                          children: [
                            SizedBox(height: state.offset, width: double.infinity),
                            if (state.mode == IndicatorMode.ready)
                              const Positioned(
                                bottom: 0, left: 0, right: 0,
                                child: Center(
                                  child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFFFF7A47))),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    child: CustomScrollView(
                      reverse: true,
                      shrinkWrap: _shrinkWrap,
                      clipBehavior: Clip.none,
                      slivers: [
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _buildMessageItem(index),
                            childCount: _messages.length,
                          ),
                        ),
                      ],
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
                        Text('正在聆听...', style: TextStyle(color: Color(0xFFFF7A47), fontSize: 13)),
                      ],
                    ),
                  ),

                // 底部输入栏占位（防止消息列表被遮挡）
                _buildInputBar(),
              ],
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
  const _PulsingDot({this.dotSize = 6, this.dotColor = const Color(0xFFFF7A47)});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) => Transform.scale(
        scale: 0.6 + 0.4 * _controller.value,
        child: child,
      ),
      child: Container(width: widget.dotSize, height: widget.dotSize, decoration: BoxDecoration(color: widget.dotColor, shape: BoxShape.circle)),
    );
  }
}
