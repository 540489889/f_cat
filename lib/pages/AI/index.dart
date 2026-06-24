import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_config.dart';
import '../../services/user_state.dart';

class AIPage extends StatefulWidget {
  const AIPage({super.key});

  @override
  State<AIPage> createState() => _AIPageState();
}

class _AIPageState extends State<AIPage> {
  final TextEditingController _textCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final _focusNode = FocusNode();

  // 完整的消息列表（最多100条）
  final List<_MessageData> _fullMessages = [];

  // 当前可见的起始下标（0=显示全部，越大=隐藏的旧消息越多）
  int _visibleOffset = 0;
  bool _hasMore = false;
  bool _loadingMore = false;
  bool _hasHistory = false;

  final _quickTags = ['水量分析', '饮食建议', '今日心情', '健康周报'];

  String? _sessionId;
  bool _isStreaming = false;
  http.Client? _httpClient;

  /// 当前显示的消息
  List<_MessageData> get _displayMessages {
    if (_visibleOffset == 0) return _fullMessages;
    return _fullMessages.sublist(_visibleOffset);
  }

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) _scrollToBottom();
    });
    _loadPersistedData();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels <= 50 && _hasMore && !_loadingMore) {
      _loadMoreMessages();
    }
  }

  Future<void> _loadPersistedData() async {
    final prefs = await SharedPreferences.getInstance();
    final sid = prefs.getString('ai_session_id');
    if (sid != null && sid.isNotEmpty) _sessionId = sid;

    final msgsJson = prefs.getString('ai_messages');
    if (msgsJson != null) {
      try {
        final list = jsonDecode(msgsJson) as List;
        _fullMessages.clear();
        for (final m in list) {
          final mm = m as Map<String, dynamic>;
          _fullMessages.add(_MessageData(
            isUser: mm['isUser'] as bool,
            content: mm['content'] as String? ?? '',
            isLoading: false,
          ));
        }

        if (_fullMessages.isNotEmpty) {
          _hasHistory = true;
          // 初始只显示最新10条
          _visibleOffset = (_fullMessages.length - 10).clamp(0, _fullMessages.length);
          _hasMore = _visibleOffset > 0;
          if (mounted) setState(() {});
          _scrollToBottom();
        }
      } catch (_) {}
    }
  }

  void _loadMoreMessages() {
    if (!_hasMore || _loadingMore) return;
    setState(() => _loadingMore = true);

    // 记录当前顶部 item 高度，用于保持滚动位置
    final prevExtent = _scrollCtrl.hasClients ? _scrollCtrl.position.maxScrollExtent : 0.0;

    Future.delayed(const Duration(milliseconds: 200), () {
      final newOffset = (_visibleOffset - 10).clamp(0, _fullMessages.length);
      setState(() {
        _visibleOffset = newOffset;
        _hasMore = _visibleOffset > 0;
        _loadingMore = false;
      });

      // 跳回到之前的位置，保持视觉连贯
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollCtrl.hasClients) {
          final newExtent = _scrollCtrl.position.maxScrollExtent;
          final delta = newExtent - prevExtent;
          if (delta > 0) {
            _scrollCtrl.jumpTo(delta);
          }
        }
      });
    });
  }

  Future<void> _persistSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    if (_sessionId != null) {
      await prefs.setString('ai_session_id', _sessionId!);
    }
  }

  Future<void> _persistMessages() async {
    final prefs = await SharedPreferences.getInstance();
    if (_fullMessages.isEmpty) {
      await prefs.remove('ai_messages');
      return;
    }
    final list = _fullMessages.map((m) => {
      'isUser': m.isUser,
      'content': m.content,
    }).toList();
    await prefs.setString('ai_messages', jsonEncode(list));
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    _httpClient?.close();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
      }
    });
  }

  Future<void> _sendMessage({String? text}) async {
    final message = (text ?? _textCtrl.text).trim();
    if (message.isEmpty || _isStreaming) return;

    print('[AI Chat] ▶ 用户消息: $message');
    _textCtrl.clear();

    _hasHistory = true;
    _fullMessages.add(_MessageData(isUser: true, content: message));
    _visibleOffset = 0; // 新消息时展示全部
    _hasMore = false;
    setState(() {});
    _scrollToBottom();

    final aiMsg = _MessageData(isUser: false, isLoading: true);
    final aiIndex = _fullMessages.length;
    _fullMessages.add(aiMsg);
    setState(() {});
    _scrollToBottom();

    _isStreaming = true;

    try {
      final uri = Uri.parse('${ApiConfig.llmBaseUrl}/api/agent/chat');
      final userId = context.read<UserState>().userInfo?['id'] as int?;
      final requestBody = {
        'message': message,
        if (userId != null) 'user_id': userId,
        if (_sessionId != null) 'session_id': _sessionId,
      };
      print('═══════════════════════════════════════');
      print('[AI Chat] ▶ 请求地址: $uri');
      print('[AI Chat] ▶ 请求体: ${jsonEncode(requestBody)}');
      print('[AI Chat] ▶ session_id: ${_sessionId ?? "(新会话)"}');
      print('[AI Chat] ▶ user_id: $userId');

      final request = http.Request('POST', uri);
      request.headers['Content-Type'] = 'application/json';
      request.headers['Accept'] = 'text/event-stream';
      request.body = jsonEncode(requestBody);

      _httpClient?.close();
      _httpClient = http.Client();
      final response = await _httpClient!.send(request);

      final stream = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      String? currentEvent;
      StringBuffer dataBuffer = StringBuffer();
      final contentBuffer = StringBuffer();

      print('[AI Chat] ✔ SSE 流已连接');
      int eventCount = 0;
      await for (final line in stream) {
        if (line.isEmpty && currentEvent != null) {
          eventCount++;
          final data = dataBuffer.toString();
          print('[AI Chat] ◀ SSE事件 #$eventCount: event="$currentEvent" data=${data.length > 300 ? '${data.substring(0, 300)}...' : data}');
          _handleSSEEvent(currentEvent, data, contentBuffer, aiIndex);
          currentEvent = null;
          dataBuffer = StringBuffer();
          continue;
        }
        if (line.startsWith('event: ')) {
          currentEvent = line.substring(7).trim();
        } else if (line.startsWith('data: ')) {
          dataBuffer.write(line.substring(6));
        }
      }
      print('[AI Chat] ✔ SSE 流结束，共收到 $eventCount 个事件');
      print('[AI Chat] ◀ 最终回复长度: ${contentBuffer.length} 字符');
      print('═══════════════════════════════════════');
    } catch (e) {
      print('[AI Chat] ✘ 网络异常: $e');
      _updateAIMessage(aiIndex, _MessageData(isUser: false, content: '网络连接失败，请稍后重试'));
    } finally {
      _isStreaming = false;
      _httpClient?.close();
      _httpClient = null;
    }
  }

  void _handleSSEEvent(String event, String data, StringBuffer contentBuffer, int aiIndex) {
    Map<String, dynamic> parsed;
    try {
      parsed = jsonDecode(data) as Map<String, dynamic>;
    } catch (_) {
      return;
    }

    switch (event) {
      case 'text':
        final content = parsed['content'] as String? ?? '';
        contentBuffer.write(content);
        _updateAIMessage(aiIndex, _MessageData(isUser: false, content: contentBuffer.toString()));
        _scrollToBottom();
        break;
      case 'thinking':
        final innerData = parsed['data'] as Map?;
        if (innerData?['tool_name'] != null) {
          print('[AI Chat]  🔧 Tool调用: ${innerData!['tool_name']}');
        }
        break;
      case 'data':
        final innerData = parsed['data'] as Map?;
        print('[AI Chat]  📦 Tool结果: tool=${innerData?['tool_name']} result=${innerData?['result'] != null ? '${(innerData!['result'] as String).length}字符' : 'null'}');
        break;
      case 'chart':
        final chartData = parsed['data'] as Map?;
        final hint = chartData?['chart_hint'] as Map?;
        print('[AI Chat]  📊 图表: type=${hint?['suggested_type']}, rows=${(chartData?['rows'] as List?)?.length ?? 0}行');
        break;
      case 'error':
        print('[AI Chat]  ✘ 服务端错误');
        if (contentBuffer.isEmpty) {
          _updateAIMessage(aiIndex, _MessageData(isUser: false, content: '服务暂时不可用，请稍后重试'));
        }
        break;
      case 'done':
        final doneData = parsed['data'] as Map?;
        final sid = doneData?['session_id'] as String?;
        if (sid != null && sid.isNotEmpty) {
          _sessionId = sid;
          _persistSessionId();
        }
        if (contentBuffer.isEmpty) {
          _updateAIMessage(aiIndex, _MessageData(isUser: false, content: '操作已完成'));
        }
        _persistMessages();
        break;
    }
  }

  void _updateAIMessage(int index, _MessageData msg) {
    if (!mounted) return;
    setState(() {
      _fullMessages[index] = msg;
    });
  }

  void _onNewChat() {
    SharedPreferences.getInstance().then((p) {
      p.remove('ai_session_id');
      p.remove('ai_messages');
    });
    setState(() {
      _sessionId = null;
      _fullMessages.clear();
      _visibleOffset = 0;
      _hasMore = false;
      _hasHistory = false;
    });
  }

  void _onQuickTag(String tag) {
    _sendMessage(text: tag);
  }

  @override
  Widget build(BuildContext context) {
    final hasMessages = _hasHistory || _fullMessages.isNotEmpty;
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_left, size: 34),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Smart Core', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Image.asset('assets/images/icon/add-1.png', width: 24, height: 24),
            onPressed: _onNewChat,
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => _focusNode.unfocus(),
        child: Container(
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
                child: !hasMessages
                    ? ListView(
                        controller: _scrollCtrl,
                        children: [
                          _buildWelcome(),
                        ],
                      )
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: _displayMessages.length + (_loadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == 0 && _loadingMore) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                            );
                          }
                          final msgIndex = _loadingMore ? index - 1 : index;
                          return _buildBubble(_displayMessages[msgIndex]);
                        },
                      ),
              ),
              _buildInputBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcome() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Image.asset('assets/images/icon/ai-logo.png', width: 120, height: 120, fit: BoxFit.contain),
        const SizedBox(height: 20),
        const Text('回答由AI生成，仅供参考', style: TextStyle(fontSize: 13, color: Color(0xFF999999))),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildBubble(_MessageData msg) {
    if (msg.isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Image.asset('assets/images/icon/ai-logo.png', width: 45, height: 45),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
              child: const Text('Smart Core 正在思考中...', style: TextStyle(fontSize: 14, color: Color(0xFF888888))),
            ),
          ],
        ),
      );
    }

    if (msg.isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Align(
          alignment: Alignment.centerRight,
          child: Container(
            margin: const EdgeInsets.only(left: 50),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(color: const Color(0xFFFF7A45), borderRadius: BorderRadius.circular(22)),
            child: Text(msg.content, style: const TextStyle(fontSize: 14, color: Colors.white)),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset('assets/images/icon/ai-logo.png', width: 45, height: 45),
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                margin: const EdgeInsets.only(right: 50),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
                ),
                child: Text(msg.content, style: const TextStyle(fontSize: 14, color: Color(0xFF333333), height: 1.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _quickTags.map((tag) {
                  return GestureDetector(
                    onTap: () => _onQuickTag(tag),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE8D4C8))),
                      child: Text(tag, style: const TextStyle(fontSize: 13, color: Color(0xFF8B6914))),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                GestureDetector(onTap: () {}, child: Container(padding: const EdgeInsets.all(8), child: const Icon(Icons.mic, size: 24, color: Color(0xFFBBBBBB)))),
                const SizedBox(width: 4),
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFFE8D4C8))),
                    child: Center(
                      child: TextField(
                        controller: _textCtrl,
                        focusNode: _focusNode,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: '有什么问题都可以问我哦~',
                          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFBBBBBB)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                          isDense: true,
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _sendMessage(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFFF7A45)),
                    child: Center(child: Image.asset('assets/images/icon/send-1.png', width: 20, height: 20)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageData {
  final bool isUser;
  final String content;
  final bool isLoading;
  const _MessageData({required this.isUser, this.content = '', this.isLoading = false});
}
