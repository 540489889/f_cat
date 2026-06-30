import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:huawei_ml_language/huawei_ml_language.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:fl_chart/fl_chart.dart';
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

  bool _isStreaming = false;
  http.Client? _httpClient;

  // text 事件节流：避免逐字 setState（~50ms 合并一次）
  Timer? _textThrottleTimer;
  int _lastTextUpdatedIndex = -1;

  // V2.1: device_confirm / device_select 卡片状态
  Map<String, dynamic>? _pendingConfirm;
  Map<String, dynamic>? _pendingSelect;

  // 语音识别相关
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;
  bool _isListening = false;
  Timer? _listenTimer;
  String? _recognizerError;
  String _localeId = 'zh_CN';
  bool _isHuaweiDevice = false;
  MLAsrRecognizer? _huaweiAsr;

  /// 当前显示的消息（始终返回快照副本，防止并发修改异常）
  List<_MessageData> get _displayMessages {
    if (_visibleOffset == 0) return List.from(_fullMessages);
    return _fullMessages.sublist(_visibleOffset);
  }

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) _scrollToBottom();
    });
    _initSpeech();
    _loadPersistedData();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels <= 50 && _hasMore && !_loadingMore) {
      _loadMoreMessages();
    }
  }

  Future<void> _loadPersistedData() async {
    // V2.1: 直接从服务端加载，不显示本地缓存避免闪烁
    _loadServerHistory();
  }

  /// V2.1: 从服务端加载聊天历史
  Future<void> _loadServerHistory() async {
    print('[History] ▶ 开始加载服务端历史...');
    try {
      final token = context.read<UserState>().accessToken;
      if (token == null || token.isEmpty) {
        print('[History] ✘ token 为空，跳过');
        return;
      }

      final uri = Uri.parse('${ApiConfig.llmBaseUrl}/api/chat/messages?limit=30');
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      print('[History] 状态码: ${response.statusCode}');
      print('[History] 原始响应（按行拆分）：');
      const chunkSize = 800;
      for (int i = 0; i < response.body.length; i += chunkSize) {
        final chunk = response.body.substring(i, (i + chunkSize).clamp(0, response.body.length));
        print('[History] ${chunk}');
      }
      if (response.statusCode != 200) return;

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final serverMessages = (body['messages'] as List?) ?? [];
      print('[History] 服务端返回 ${serverMessages.length} 条消息');

      if (serverMessages.isEmpty) {
        print('[History] 无历史');
        if (mounted) {
          setState(() {
            _fullMessages.clear();
            _visibleOffset = 0;
            _hasMore = false;
            _hasHistory = false;
          });
        }
        return;
      }

      // 服务端返回是倒序（最新在前），反转后合并
      final newMessages = <_MessageData>[];
      for (final m in serverMessages.reversed) {
        final role = m['role'] as String? ?? '';
        final content = m['content'] as String? ?? '';
        if (content.isEmpty) continue;
        newMessages.add(_MessageData(
          isUser: role == 'user',
          content: content,
          isLoading: false,
        ));
      }

      print('[History] 消息顺序（反转后）：');
      for (int i = 0; i < newMessages.length; i++) {
        final prefix = newMessages[i].isUser ? '👤' : '🤖';
        final text = newMessages[i].content.length > 40
            ? '${newMessages[i].content.substring(0, 40)}...'
            : newMessages[i].content;
        print('[History]   [$i] $prefix $text');
      }

      // 合并相邻同角色消息（服务端可能把多段回复存为独立消息）
      final merged = <_MessageData>[];
      for (final m in newMessages) {
        if (merged.isNotEmpty && merged.last.isUser == m.isUser) {
          // 同角色相邻，合并 content（保留已有 chartInfo）
          final prev = merged.last;
          merged[merged.length - 1] = _MessageData(
            isUser: prev.isUser,
            content: '${prev.content}\n${m.content}',
            chartInfo: prev.chartInfo ?? m.chartInfo,
          );
        } else {
          merged.add(m);
        }
      }
      newMessages
        ..clear()
        ..addAll(merged);

      if (newMessages.isNotEmpty && mounted) {
        // 合并本地缓存的图表数据
        final prefs = await SharedPreferences.getInstance();
        final chartsJson = prefs.getString('ai_charts');
        if (chartsJson != null) {
          try {
            final charts = jsonDecode(chartsJson) as Map<String, dynamic>;
            for (int i = 0; i < newMessages.length; i++) {
              final key = newMessages[i].content;
              if (key.isNotEmpty && charts.containsKey(key)) {
                final c = charts[key] as Map<String, dynamic>;
                final pts = (c['points'] as List).map((p) {
                  final pm = p as Map<String, dynamic>;
                  return _ChartPoint(
                    time: pm['time'] as String? ?? '',
                    value: (pm['value'] as num?)?.toDouble() ?? 0,
                    field: pm['field'] as String? ?? '',
                  );
                }).toList();
                newMessages[i] = _MessageData(
                  isUser: newMessages[i].isUser,
                  content: newMessages[i].content,
                  chartInfo: _ChartInfo(chartType: c['chartType'] as String? ?? 'line', points: pts),
                );
              }
            }
          } catch (_) {}
        }

        setState(() {
          _fullMessages.clear();
          _fullMessages.addAll(newMessages);
          _hasHistory = true;
          _visibleOffset = 0; // 显示全部历史
          _hasMore = false;
        });
        print('[History] ✔ 已加载 ${newMessages.length} 条历史');
        _scrollToBottom();
        _persistMessages();
      }
    } catch (e) {
      print('[History] ✘ 加载失败: $e');
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

  Future<void> _persistMessages() async {
    final prefs = await SharedPreferences.getInstance();
    if (_fullMessages.isEmpty) {
      await prefs.remove('ai_messages');
      await prefs.remove('ai_charts');
      return;
    }
    final list = _fullMessages.map((m) => {
      'isUser': m.isUser,
      'content': m.content,
    }).toList();
    await prefs.setString('ai_messages', jsonEncode(list));

    // 同时持久化图表数据（key=content，用于历史回显）
    final charts = <String, dynamic>{};
    for (final m in _fullMessages) {
      if (m.chartInfo != null) {
        charts[m.content] = {
          'chartType': m.chartInfo!.chartType,
          'points': m.chartInfo!.points.map((p) => {
            'time': p.time, 'value': p.value, 'field': p.field,
          }).toList(),
        };
      }
    }
    if (charts.isNotEmpty) {
      await prefs.setString('ai_charts', jsonEncode(charts));
    }
  }

  @override
  void dispose() {
    _listenTimer?.cancel();
    _textThrottleTimer?.cancel();
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    _httpClient?.close();
    if (_isHuaweiDevice) {
      _huaweiAsr?.destroy();
    } else {
      _speech.cancel();
    }
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
      }
    });
  }

  Future<void> _initSpeech() async {
    // 1. 检测设备厂商
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final manufacturer = androidInfo.manufacturer.toLowerCase();
      _isHuaweiDevice = manufacturer.contains('huawei') || manufacturer.contains('honor');
      debugPrint('[语音识别] 设备厂商: ${androidInfo.manufacturer}, 华为: $_isHuaweiDevice');
    } catch (e) {
      debugPrint('[语音识别] 获取设备信息失败: $e');
    }

    // 2. 华为设备 → 使用华为 ML Kit
    if (_isHuaweiDevice) {
      // 不在这里创建实例，避免创建后长时间未用导致 native handler 失效；
      // 实例将在第一次点击麦克风时创建。
      if (mounted) setState(() => _speechAvailable = true);
      return;
    }

    // 3. 非华为设备 → 使用 speech_to_text
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

    // 语言获取独立 try-catch
    if (_speechAvailable) {
      try {
        final locales = await _speech.locales();
        final hasZh = locales.any((l) => l.localeId == 'zh_CN');
        final sysLocale = await _speech.systemLocale();
        _localeId = hasZh ? 'zh_CN' : (sysLocale?.localeId ?? 'en_US');
      } catch (_) {}
    }
  }

  /// 创建华为 ML Kit 语音识别实例
  void _createHuaweiAsr() {
    _huaweiAsr = MLAsrRecognizer();
    _huaweiAsr!.setAsrListener(MLAsrListener(
      onRecognizingResults: (String result) {
        debugPrint('[华为ASR] 实时识别: "$result"');
        if (result.isNotEmpty && mounted) {
          setState(() {
            _textCtrl.text = result;
            _textCtrl.selection = TextSelection.collapsed(offset: result.length);
          });
        }
      },
      onResults: (String result) {
        debugPrint('[华为ASR] 最终结果: "$result"');
        if (result.isNotEmpty && mounted) {
          setState(() {
            _textCtrl.text = result;
            _textCtrl.selection = TextSelection.collapsed(offset: result.length);
          });
          _stopListening();
        }
      },
      onError: (int errorCode, String errorMsg) {
        debugPrint('[华为ASR] 错误: $errorCode $errorMsg');
        if (mounted && _isListening) _stopListening();
      },
      onState: (int state) {
        debugPrint('[华为ASR] 状态码: $state');
      },
    ));
  }

  void _stopListening() async {
    _listenTimer?.cancel();
    if (_isHuaweiDevice) {
      _huaweiAsr?.destroy();
      _huaweiAsr = null;
    } else {
      await _speech.stop();
    }
    if (mounted) setState(() => _isListening = false);
  }

  Future<void> _toggleListening() async {
    debugPrint('[语音识别] 点击麦克风: isListening=$_isListening, speechAvailable=$_speechAvailable, isHuawei=$_isHuaweiDevice');

    if (_isListening) {
      _stopListening();
      return;
    }

    // 运行时请求录音权限
    final status = await Permission.microphone.status;
    if (!status.isGranted) {
      final result = await Permission.microphone.request();
      if (!result.isGranted) {
        _showToast('需要麦克风权限才能使用语音识别');
        return;
      }
      await Future.delayed(const Duration(milliseconds: 300));
    }

    if (!_speechAvailable) {
      debugPrint('[语音识别] speechAvailable=false, error=$_recognizerError');
      _showToast(_recognizerError ?? '语音识别不可用，请检查麦克风权限');
      return;
    }

    setState(() => _isListening = true);

    // fire-and-forget，不要 await 长时操作
    if (_isHuaweiDevice) {
      if (_huaweiAsr == null) {
        debugPrint('[华为ASR] 创建实例...');
        _createHuaweiAsr();
        await Future.delayed(const Duration(milliseconds: 1000));
        debugPrint('[华为ASR] 实例已等待 1000ms');
      }
      try {
        debugPrint('[华为ASR] 开始识别...');
        final config = MLAsrSetting(
          language: MLAsrConstants.LAN_ZH_CN,
          feature: MLAsrConstants.FEATURE_WORDFLUX,
        );
        _huaweiAsr!.startRecognizing(config);
      } on PlatformException catch (e) {
        // 如果原生端还没初始化好，重新创建再试一次
        if (e.message?.contains('Not initialized') ?? false) {
          debugPrint('[华为ASR] 未初始化，重新创建...');
          _createHuaweiAsr();
          await Future.delayed(const Duration(milliseconds: 500));
          try {
            final config = MLAsrSetting(
              language: MLAsrConstants.LAN_ZH_CN,
              feature: MLAsrConstants.FEATURE_WORDFLUX,
            );
            _huaweiAsr!.startRecognizing(config);
          } catch (e2) {
            debugPrint('[华为ASR] 重试失败: $e2');
            if (mounted) setState(() => _isListening = false);
          }
        } else {
          debugPrint('[华为ASR] startRecognizing 异常: $e');
          if (mounted) setState(() => _isListening = false);
        }
      } catch (e) {
        debugPrint('[华为ASR] startRecognizing 异常: $e');
        if (mounted) setState(() => _isListening = false);
      }
    } else {
      try {
        _speech.listen(
          onResult: (result) {
            final words = result.recognizedWords;
            debugPrint('[语音识别] final=${result.finalResult}, words="$words"');
            if (words.isNotEmpty && mounted) {
              setState(() {
                _textCtrl.text = words;
                _textCtrl.selection = TextSelection.collapsed(offset: words.length);
              });
              if (result.finalResult) {
                _stopListening();
              }
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
    }

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
      ),
    );
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
    final contentBuffer = StringBuffer();

    try {
      final uri = Uri.parse('${ApiConfig.llmBaseUrl}/api/agent/chat');
      final userState = context.read<UserState>();
      final userId = userState.userInfo?['id'] as int?;
      final token = userState.accessToken;

      final requestBody = {
        'message': message,
        if (userId != null) 'user_id': userId,
      };
      print('═══════════════════════════════════════');
      print('[AI Chat] ▶ 请求地址: $uri');
      print('[AI Chat] ▶ 请求体: ${jsonEncode(requestBody)}');
      print('[AI Chat] ▶ user_id: $userId');

      final request = http.Request('POST', uri);
      request.headers['Content-Type'] = 'application/json';
      request.headers['Accept'] = 'text/event-stream';
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.body = jsonEncode(requestBody);

      _httpClient?.close();
      _httpClient = http.Client();
      final response = await _httpClient!.send(request);

      final stream = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      String? currentEvent;
      StringBuffer dataBuffer = StringBuffer();

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
      _flushThrottledText(aiIndex, contentBuffer);
      _updateAIMessage(aiIndex, _MessageData(isUser: false, content: '网络连接失败，请稍后重试'));
    } finally {
      _textThrottleTimer?.cancel();
      _textThrottleTimer = null;
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
        _lastTextUpdatedIndex = aiIndex;
        // 节流：最多每 50ms 刷新一次 UI，大幅减少 setState 次数
        _textThrottleTimer ??= Timer(const Duration(milliseconds: 50), () {
          _textThrottleTimer = null;
          if (!mounted) return;
          _updateAIMessage(_lastTextUpdatedIndex, _MessageData(isUser: false, content: contentBuffer.toString()));
          _scrollToBottom();
        });
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
        final chartData = parsed['data'] as Map<String, dynamic>?;
        final hint = chartData?['chart_hint'] as Map<String, dynamic>?;
        final type = hint?['suggested_type'] as String? ?? 'line';
        final rows = (chartData?['rows'] as List?) ?? [];
        final points = rows.map<Map<String, dynamic>>((r) => (r as Map).cast<String, dynamic>()).map((r) {
          return _ChartPoint(
            time: (r['time'] as String?) ?? '',
            value: (r['value'] as num?)?.toDouble() ?? 0,
            field: (r['field'] as String?) ?? '',
          );
        }).toList();

        print('[AI Chat]  📊 图表: type=$type, rows=${points.length}行');

        // 将图表数据附着到当前 AI 消息上
        if (mounted && points.isNotEmpty) {
          final chartInfo = _ChartInfo(chartType: type, points: points);
          setState(() {
            _fullMessages[aiIndex] = _MessageData(
              isUser: false,
              content: '[图表]',
              chartInfo: chartInfo,
            );
          });
        }
        break;
      case 'error':
        print('[AI Chat]  ✘ 服务端错误');
        _flushThrottledText(aiIndex, contentBuffer);
        if (contentBuffer.isEmpty) {
          _updateAIMessage(aiIndex, _MessageData(isUser: false, content: '服务暂时不可用，请稍后重试'));
        }
        break;
      case 'done':
        _flushThrottledText(aiIndex, contentBuffer);
        final doneData = parsed['data'] as Map?;
        // V2.1: context_reason 三态处理
        final reason = doneData?['context_reason'] as String? ?? '';
        if (reason == 'rebuilt') {
          _showToast('上次短期上下文已过期，已基于历史记录继续为你服务');
        } else if (reason == 'rebuild_failed') {
          _showToast('上下文加载失败，仅基于当前消息回答');
        }
        if (contentBuffer.isEmpty) {
          _updateAIMessage(aiIndex, _MessageData(isUser: false, content: '操作已完成'));
        }
        _persistMessages();
        break;

      case 'device_confirm':
        // V1.10: 高风险操作确认卡片
        final confirmData = parsed['data'] as Map<String, dynamic>?;
        if (confirmData != null && mounted) {
          setState(() => _pendingConfirm = confirmData);
        }
        break;

      case 'device_select':
        // V1.11: 多设备选择卡片
        final selectData = parsed['data'] as Map<String, dynamic>?;
        if (selectData != null && mounted) {
          setState(() => _pendingSelect = selectData);
        }
        break;
    }
  }

  /// 立即刷新节流中未显示的 text 内容
  void _flushThrottledText(int aiIndex, StringBuffer contentBuffer) {
    _textThrottleTimer?.cancel();
    _textThrottleTimer = null;
    if (contentBuffer.isNotEmpty) {
      _updateAIMessage(aiIndex, _MessageData(isUser: false, content: contentBuffer.toString()));
    }
  }

  void _updateAIMessage(int index, _MessageData msg) {
    if (!mounted) return;
    setState(() {
      final existing = index < _fullMessages.length ? _fullMessages[index] : null;
      _fullMessages[index] = _MessageData(
        isUser: msg.isUser,
        content: msg.content,
        isLoading: msg.isLoading,
        chartInfo: msg.chartInfo ?? existing?.chartInfo,
      );
      print('[AI Chat]  📍 _updateAIMessage idx=$index chartInfo=${_fullMessages[index].chartInfo != null} (kept=${existing?.chartInfo != null})');
    });
  }

  /// V2.1: 清空当前短期上下文（仅 Redis，不动 DB）
  Future<void> _clearContext() async {
    try {
      final token = context.read<UserState>().accessToken;
      if (token == null) return;
      await http.post(
        Uri.parse('${ApiConfig.llmBaseUrl}/api/chat/context/clear'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: '{}',
      ).timeout(const Duration(seconds: 5));
      _showToast('上下文已清空');
    } catch (e) {
      debugPrint('[AI Chat] 清空上下文失败: $e');
    }
  }

  /// V2.1: 删除全部聊天历史（软删 DB + 清 Redis）
  Future<void> _deleteHistory() async {
    try {
      final token = context.read<UserState>().accessToken;
      if (token == null) return;
      final response = await http.delete(
        Uri.parse('${ApiConfig.llmBaseUrl}/api/chat/history'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final count = body['deleted_count'] ?? 0;
        final status = body['status'] ?? '';
        if (status == 'partial') {
          _showToast('历史已删除 $count 条，但 Redis 清理未完成（下次对话自动修复）');
        } else {
          _showToast('已删除 $count 条聊天历史');
        }
      }
    } catch (e) {
      debugPrint('[AI Chat] 删除历史失败: $e');
      _showToast('删除失败，请稍后重试');
    }
  }

  void _onNewChat() {
    _clearContext();
    setState(() {
      _fullMessages.clear();
      _visibleOffset = 0;
      _hasMore = false;
      _hasHistory = false;
      _pendingConfirm = null;
      _pendingSelect = null;
    });
    SharedPreferences.getInstance().then((p) {
      p.remove('ai_session_id'); // V2.1: 清理旧 session_id 缓存
      p.remove('ai_messages');
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.grey),
            onSelected: (value) {
              switch (value) {
                case 'clear_context':
                  _clearContext();
                  break;
                case 'delete_history':
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('确认删除'),
                      content: const Text('将删除全部聊天历史，此操作不可撤销。'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('取消'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _deleteHistory().then((_) {
                              setState(() {
                                _fullMessages.clear();
                                _visibleOffset = 0;
                                _hasMore = false;
                                _hasHistory = false;
                              });
                            });
                          },
                          child: const Text('删除', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_context',
                child: Row(
                  children: [
                    Icon(Icons.cleaning_services_outlined, size: 18, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('清空当前上下文', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete_history',
                child: Row(
                  children: [
                    Icon(Icons.delete_forever_outlined, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('删除全部聊天历史', style: TextStyle(fontSize: 14, color: Colors.red)),
                  ],
                ),
              ),
            ],
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
              // 录音状态提示条
              if (_isListening)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  color: const Color(0xFFFF7A45).withValues(alpha: 0.1),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _PulsingDot(),
                      SizedBox(width: 8),
                      Text('正在聆听...', style: TextStyle(color: Color(0xFFFF7A45), fontSize: 13)),
                    ],
                  ),
                ),
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
              // V1.10: 高风险操作确认卡片
              if (_pendingConfirm != null) _buildConfirmCard(),
              // V1.11: 多设备选择卡片
              if (_pendingSelect != null) _buildDeviceSelectCard(),
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
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
          child: const Text('Smart Core 正在思考中...', style: TextStyle(fontSize: 14, color: Color(0xFF888888))),
        ),
      );
    }

    if (msg.isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Align(
          alignment: Alignment.centerRight,
          child: Container(
            margin: const EdgeInsets.only(left: 20),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(color: const Color(0xFFFF7A45), borderRadius: BorderRadius.circular(22)),
            child: Text(msg.content, style: const TextStyle(fontSize: 14, color: Colors.white)),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        margin: const EdgeInsets.only(right: 20),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (msg.content.isNotEmpty)
              Text(msg.content, style: const TextStyle(fontSize: 14, color: Color(0xFF333333), height: 1.5)),
            if (msg.chartInfo != null) ...[
              if (msg.content.isNotEmpty) const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FB),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(8),
                child: _buildChart(msg.chartInfo!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 内联图表渲染（fl_chart）
  Widget _buildChart(_ChartInfo info) {
    final points = info.points;
    if (points.isEmpty) return const SizedBox.shrink();

    // 判断是否跨多天：跨天显示 MM-dd，同一天显示 HH:mm
    bool multiDay = false;
    try {
      final dates = points.map((p) {
        final dt = DateTime.parse(p.time);
        return DateTime(dt.year, dt.month, dt.day);
      }).toSet();
      multiDay = dates.length > 1;
    } catch (_) {}

    String fmtTime(String t) {
      try {
        final dt = DateTime.parse(t).toLocal();
        if (multiDay) {
          return '${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
        }
        return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {
        return t.length > 10 ? t.substring(t.length - 8) : t;
      }
    }

    return SizedBox(
      height: 220,
      child: info.chartType == 'line'
                  ? LineChart(
                      LineChartData(
                        gridData: FlGridData(show: true, drawVerticalLine: false),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 32,
                              getTitlesWidget: (v, _) => Text(
                                v.toInt().toString(),
                                style: const TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: (points.length / 4).ceilToDouble().clamp(1, 10),
                              getTitlesWidget: (v, _) {
                                final idx = v.toInt();
                                if (idx < 0 || idx >= points.length) return const SizedBox.shrink();
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    fmtTime(points[idx].time),
                                    style: const TextStyle(fontSize: 9, color: Colors.grey),
                                  ),
                                );
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: List.generate(points.length, (i) => FlSpot(i.toDouble(), points[i].value)),
                            isCurved: true,
                            color: const Color(0xFFFF7A47),
                            barWidth: 1,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: const Color(0xFFFF7A47).withValues(alpha: 0.1),
                            ),
                          ),
                        ],
                      ),
                    )
                  : BarChart(
                      BarChartData(
                        gridData: FlGridData(show: true, drawVerticalLine: false),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 32,
                              getTitlesWidget: (v, _) => Text(
                                v.toInt().toString(),
                                style: const TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: (points.length / 4).ceilToDouble().clamp(1, 10),
                              getTitlesWidget: (v, _) {
                                final idx = v.toInt();
                                if (idx < 0 || idx >= points.length) return const SizedBox.shrink();
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    fmtTime(points[idx].time),
                                    style: const TextStyle(fontSize: 9, color: Colors.grey),
                                  ),
                                );
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: List.generate(points.length, (i) {
                          return BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: points[i].value,
                                color: const Color(0xFFFF7A47),
                                width: 8,
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
    );
  }

  /// V1.10: 高风险操作确认卡片
  Widget _buildConfirmCard() {
    final data = _pendingConfirm!;
    final token = data['confirmation_token'] as String? ?? '';
    final confirmationText = data['confirmation_text'] as String? ?? '确认执行此操作？';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFF7A47).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF7A47), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  confirmationText,
                  style: const TextStyle(fontSize: 13, color: Color(0xFFE65100)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => _cancelDeviceConfirm(token),
                style: TextButton.styleFrom(foregroundColor: Colors.grey),
                child: const Text('取消'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _confirmDevice(token),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7A47),
                  foregroundColor: Colors.white,
                ),
                child: const Text('确认执行'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// V1.11: 多设备选择卡片
  Widget _buildDeviceSelectCard() {
    final data = _pendingSelect!;
    final prompt = data['prompt'] as String? ?? '请选择设备';
    final devices = (data['devices'] as List?) ?? [];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFF7A47).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(prompt, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 10),
          ...devices.map((d) {
            final sn = d['sn'] as String? ?? '';
            final name = d['name'] as String? ?? sn;
            final online = d['online'] as bool? ?? false;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _selectDevice(sn, name),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF333333),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Row(
                    children: [
                      Icon(online ? Icons.check_circle : Icons.wifi_off,
                          size: 16, color: online ? Colors.green : Colors.grey),
                      const SizedBox(width: 8),
                      Text(name, style: const TextStyle(fontSize: 14)),
                      const Spacer(),
                      Text(sn, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  /// V1.10: 确认执行设备操作
  Future<void> _confirmDevice(String token) async {
    try {
      final accessToken = context.read<UserState>().accessToken;
      final response = await http.post(
        Uri.parse('${ApiConfig.llmBaseUrl}/api/device/confirm'),
        headers: {
          'Content-Type': 'application/json',
          if (accessToken != null) 'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({'confirmation_token': token}),
      ).timeout(const Duration(seconds: 10));

      if (mounted) {
        setState(() => _pendingConfirm = null);
        if (response.statusCode == 200) {
          _showToast('操作已执行');
        } else {
          _showToast('操作失败，请重新发起');
        }
      }
    } catch (e) {
      debugPrint('[AI Chat] 确认设备操作失败: $e');
      if (mounted) {
        setState(() => _pendingConfirm = null);
        _showToast('操作失败，请重试');
      }
    }
  }

  /// V1.10: 取消设备操作
  Future<void> _cancelDeviceConfirm(String token) async {
    try {
      final accessToken = context.read<UserState>().accessToken;
      await http.post(
        Uri.parse('${ApiConfig.llmBaseUrl}/api/device/cancel'),
        headers: {
          'Content-Type': 'application/json',
          if (accessToken != null) 'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({'confirmation_token': token}),
      ).timeout(const Duration(seconds: 5));
    } catch (_) {}
    if (mounted) setState(() => _pendingConfirm = null);
  }

  /// V1.11: 选择设备后发起新一轮对话
  void _selectDevice(String sn, String name) {
    setState(() => _pendingSelect = null);
    final text = '我选择了 $name（$sn）';
    _textCtrl.text = text;
    _sendMessage();
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
                GestureDetector(
                  onTap: _toggleListening,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isListening
                          ? const Color(0xFFFF7A45)
                          : Colors.transparent,
                      border: Border.all(
                        color: _isListening
                            ? const Color(0xFFFF7A45)
                            : Colors.grey[400]!,
                      ),
                    ),
                    child: Center(
                      child: _isListening
                          ? const _PulsingDot(dotSize: 10, dotColor: Colors.white)
                          : const Icon(Icons.mic_none, color: Colors.grey, size: 20),
                    ),
                  ),
                ),
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
                          hintText: _isListening ? '正在识别语音...' : '有什么问题都可以问我哦~',
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
  final _ChartInfo? chartInfo;
  const _MessageData({required this.isUser, this.content = '', this.isLoading = false, this.chartInfo});
}

/// SSE chart 事件数据
class _ChartInfo {
  final String chartType; // line / bar
  final List<_ChartPoint> points;
  const _ChartInfo({required this.chartType, required this.points});
}

class _ChartPoint {
  final String time;
  final double value;
  final String field;
  const _ChartPoint({required this.time, required this.value, required this.field});
}

/// 录音时麦克风内的脉冲动画小点
class _PulsingDot extends StatefulWidget {
  final double dotSize;
  final Color dotColor;

  const _PulsingDot({this.dotSize = 8, this.dotColor = const Color(0xFFFF7A45)});

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
