import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:huawei_ml_language/huawei_ml_language.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'add.dart';
import '../../services/pet_ai_service.dart';

/// 宠物介绍页（添加宠物第 2 步）
///
/// 用户可通过语音或手动输入介绍宠物，
/// 也可跳过直接进入信息填写页。
class PetIntroducePage extends StatefulWidget {
  final String? headimg;
  final String? imgs;

  const PetIntroducePage({super.key, this.headimg, this.imgs});

  @override
  State<PetIntroducePage> createState() => _PetIntroducePageState();
}

class _PetIntroducePageState extends State<PetIntroducePage> {
  final TextEditingController _introController = TextEditingController();

  // 语音识别相关
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;
  bool _isListening = false;
  String? _recognizerError;
  String _localeId = 'zh_CN';
  bool _isHuaweiDevice = false;
  MLAsrRecognizer? _huaweiAsr;

  /// 用户当前是否期望保持聆听状态（不受系统超时影响）
  bool _shouldBeListening = false;

  /// 当前聆听会话开始前，输入框中已有的文本（用于追加模式）
  String _sessionBaseText = '';

  /// 当前聆听会话中已确认的最终识别结果累积
  String _accumulatedText = '';

  /// 自动恢复聆听的防抖时间戳
  DateTime _lastRestartTime = DateTime(2000);

  /// 输入框是否有文本内容（控制跳过/下一步按钮）
  bool _hasText = false;

  /// 是否正在调用 AI 分析
  bool _isAnalyzing = false;

  /// speech_to_text 会话计数器，用于过滤旧会话的残留回调
  int _sttSessionId = 0;

  @override
  void initState() {
    super.initState();
    _introController.addListener(_onIntroTextChanged);
    _initSpeech();
  }

  @override
  void dispose() {
    if (_isHuaweiDevice) {
      _huaweiAsr?.destroy();
    } else {
      _speech.cancel();
    }
    _introController.removeListener(_onIntroTextChanged);
    _introController.dispose();
    super.dispose();
  }

  /// 构建显示文本：基础文本 + 累积已确认文本 + 当前部分识别文本
  /// [partialWords] 为当前部分识别结果（可为空）
  String _buildDisplayText({String partialWords = ''}) {
    final base = _sessionBaseText;
    final accumulated = _accumulatedText;
    final parts = <String>[];
    if (base.isNotEmpty) parts.add(base);
    if (accumulated.isNotEmpty) parts.add(accumulated);
    if (partialWords.isNotEmpty) parts.add(partialWords);
    return parts.join(' ');
  }

  /// 将已确认文本写入输入框
  void _commitToController({String partialWords = ''}) {
    if (!mounted) return;
    final display = _buildDisplayText(partialWords: partialWords);
    setState(() {
      _introController.text = display;
      _introController.selection =
          TextSelection.collapsed(offset: display.length);
    });
  }

  Future<void> _initSpeech() async {
    // 1. 检测设备厂商
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final manufacturer = androidInfo.manufacturer.toLowerCase();
      _isHuaweiDevice =
          manufacturer.contains('huawei') || manufacturer.contains('honor');
      debugPrint(
          '[语音识别] 设备厂商: ${androidInfo.manufacturer}, 华为: $_isHuaweiDevice');
    } catch (e) {
      debugPrint('[语音识别] 获取设备信息失败: $e');
    }

    // 2. 华为设备 → 使用华为 ML Kit
    if (_isHuaweiDevice) {
      if (mounted) setState(() => _speechAvailable = true);
      return;
    }

    // 3. 非华为设备 → 使用 speech_to_text
    try {
      final available = await _speech.initialize(
        onStatus: (status) {
          debugPrint('[语音识别] 状态: $status');
          if (status == 'done' || status == 'notListening') {
            _onSttStopped();
          }
        },
        onError: (err) {
          debugPrint('[语音识别] 错误: ${err.errorMsg}');
          _onSttStopped();
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

  /// speech_to_text 停止时调用（无论是手动停止还是系统超时）
  void _onSttStopped() {
    if (!mounted) return;

    // 防抖：500ms 内连续停止只处理第一次，避免系统残留状态回调导致重复重启
    final now = DateTime.now();
    if (_shouldBeListening &&
        now.difference(_lastRestartTime) < const Duration(milliseconds: 500)) {
      debugPrint('[语音识别] 忽略快速连续停止，避免重复重启');
      return;
    }

    setState(() => _isListening = false);

    if (_shouldBeListening) {
      _lastRestartTime = now;
      debugPrint('[语音识别] 系统停止，自动恢复聆听...');
      _startSttListening();
    }
  }

  /// 启动 speech_to_text 聆听
  void _startSttListening() {
    if (!mounted || _isListening) return;
    _sttSessionId++;
    final int sessionId = _sttSessionId;
    setState(() => _isListening = true);
    try {
      _speech.listen(
        onResult: (result) {
          // 忽略旧会话的残留回调，避免重复追加已被累积的文本
          if (sessionId != _sttSessionId) return;
          final words = result.recognizedWords;
          debugPrint('[语音识别] final=${result.finalResult}, words="$words"');
          if (mounted) {
            if (result.finalResult) {
              // 最终结果：追加到累积文本
              if (words.isNotEmpty) {
                _accumulatedText = _accumulatedText.isEmpty
                    ? words
                    : '$_accumulatedText $words';
              }
              _commitToController();
            } else {
              // 部分结果：显示 累积已确认文本 + 当前部分结果
              _commitToController(partialWords: words);
            }
          }
        },
        onSoundLevelChange: (level) {
          debugPrint('[语音识别] 音量: $level');
        },
        listenOptions: stt.SpeechListenOptions(
          localeId: _localeId,
          listenMode: stt.ListenMode.dictation,
          cancelOnError: false,
          onDevice: false,
          partialResults: true,
          autoPunctuation: true,
          pauseFor: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      debugPrint('[语音识别] listen 异常: $e');
      if (mounted) {
        setState(() => _isListening = false);
        // 非手动停止时尝试恢复
        if (_shouldBeListening) {
          Future.delayed(const Duration(milliseconds: 300), _startSttListening);
        }
      }
    }
  }

  /// 创建华为 ML Kit 语音识别实例
  void _createHuaweiAsr() {
    _huaweiAsr = MLAsrRecognizer();
    _huaweiAsr!.setAsrListener(MLAsrListener(
      onRecognizingResults: (String result) {
        debugPrint('[华为ASR] 实时识别: "$result"');
        if (result.isNotEmpty && mounted) {
          // 部分结果：显示 累积已确认文本 + 当前部分结果
          _commitToController(partialWords: result);
        }
      },
      onResults: (String result) {
        debugPrint('[华为ASR] 最终结果: "$result"');
        if (result.isNotEmpty && mounted) {
          // 最终结果：追加到累积文本，显示完整内容
          _accumulatedText = _accumulatedText.isEmpty
              ? result
              : '$_accumulatedText $result';
          _commitToController();
        }
      },
      onError: (int errorCode, String errorMsg) {
        debugPrint('[华为ASR] 错误: $errorCode $errorMsg');
        if (mounted && _shouldBeListening) {
          // 非手动停止，重置实例并尝试恢复
          debugPrint('[华为ASR] 错误时自动恢复...');
          _huaweiAsr = null;
          if (mounted) setState(() => _isListening = false);
          _startHuaweiListening();
        }
      },
      onState: (int state) {
        debugPrint('[华为ASR] 状态码: $state');
      },
    ));
  }

  /// 启动华为 ML Kit 聆听
  void _startHuaweiListening() {
    if (!mounted) return;
    // 不检查 _isListening，因为可能从 onError 恢复时 _isListening 为 true
    // 由调用方确保不会重复启动
    final bool isNewInstance = _huaweiAsr == null;
    if (isNewInstance) {
      debugPrint('[华为ASR] 创建实例...');
      _createHuaweiAsr();
    }
    try {
      debugPrint('[华为ASR] 开始识别...');
      final config = MLAsrSetting(
        language: MLAsrConstants.LAN_ZH_CN,
        feature: MLAsrConstants.FEATURE_WORDFLUX,
      );
      _huaweiAsr!.startRecognizing(config);
      if (mounted) setState(() => _isListening = true);
    } on PlatformException catch (e) {
      if (e.message?.contains('Not initialized') ?? false) {
        debugPrint('[华为ASR] 未初始化，重新创建并重试...');
        _createHuaweiAsr();
        if (mounted) setState(() => _isListening = false);
      } else {
        debugPrint('[华为ASR] startRecognizing PlatformException: $e');
        if (mounted) setState(() => _isListening = false);
      }
    } catch (e) {
      debugPrint('[华为ASR] startRecognizing 异常: $e');
      if (mounted) setState(() => _isListening = false);
    }
  }

  void _stopListening() async {
    _shouldBeListening = false;
    if (_isHuaweiDevice) {
      _huaweiAsr?.destroy();
      _huaweiAsr = null;
    } else {
      await _speech.stop();
    }
    if (mounted) setState(() => _isListening = false);
  }

  Future<void> _toggleListening() async {
    debugPrint(
        '[语音识别] 点击: isListening=$_isListening, speechAvailable=$_speechAvailable, isHuawei=$_isHuaweiDevice');

    if (_isListening) {
      _stopListening();
      return;
    }

    // 开始新的聆听会话前保存已有文本，重置累积
    _sessionBaseText = _introController.text;
    _accumulatedText = '';

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

    _shouldBeListening = true;

    if (_isHuaweiDevice) {
      // 华为 ML Kit：首次创建实例后需等待原生初始化完成
      if (_huaweiAsr == null) {
        debugPrint('[华为ASR] 首次创建实例，等待初始化...');
        _createHuaweiAsr();
        await Future.delayed(const Duration(milliseconds: 1000));
        debugPrint('[华为ASR] 初始化等待完成，开始识别');
      }
      try {
        debugPrint('[华为ASR] 开始识别...');
        final config = MLAsrSetting(
          language: MLAsrConstants.LAN_ZH_CN,
          feature: MLAsrConstants.FEATURE_WORDFLUX,
        );
        _huaweiAsr!.startRecognizing(config);
        if (mounted) setState(() => _isListening = true);
      } on PlatformException catch (e) {
        if (e.message?.contains('Not initialized') ?? false) {
          debugPrint('[华为ASR] 未初始化，重新创建并重试...');
          _createHuaweiAsr();
          await Future.delayed(const Duration(milliseconds: 500));
          try {
            final config = MLAsrSetting(
              language: MLAsrConstants.LAN_ZH_CN,
              feature: MLAsrConstants.FEATURE_WORDFLUX,
            );
            _huaweiAsr!.startRecognizing(config);
            if (mounted) setState(() => _isListening = true);
          } catch (e2) {
            debugPrint('[华为ASR] 重试失败: $e2');
            if (mounted) setState(() => _isListening = false);
          }
        } else {
          debugPrint('[华为ASR] startRecognizing PlatformException: $e');
          if (mounted) setState(() => _isListening = false);
        }
      } catch (e) {
        debugPrint('[华为ASR] startRecognizing 异常: $e');
        if (mounted) setState(() => _isListening = false);
      }
    } else {
      _startSttListening();
    }
  }

  void _onIntroTextChanged() {
    final hasText = _introController.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
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

  void _goToAddPage({String? introduction}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddPetPage(
          headimg: widget.headimg,
          imgs: widget.imgs,
        ),
      ),
    );
  }

  Future<void> _handleNext() async {
    // 无文本内容：直接跳转（跳过逻辑）
    if (!_hasText) {
      _goToAddPage();
      return;
    }

    // 有文本内容：调用 AI 分析
    setState(() => _isAnalyzing = true);
    try {
      final data = await PetAiService.analyzePetIntroduction(
        description: _introController.text,
        headimg: widget.headimg,
        imgs: widget.imgs,
      );

      if (!mounted) return;
      setState(() => _isAnalyzing = false);

      if (data != null && data.isNotEmpty) {
        // AI 分析成功，携带数据跳转
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddPetPage(
              headimg: widget.headimg,
              imgs: widget.imgs,
              prefillData: data,
            ),
          ),
        );
      } else {
        // AI 分析失败或无有效数据，提示后按跳过逻辑跳转
        _showToast('AI 分析失败，请稍后重试或跳过此步');
        _goToAddPage();
      }
    } catch (e) {
      debugPrint('[引入页] AI 分析异常: $e');
      if (mounted) {
        setState(() => _isAnalyzing = false);
        _showToast('网络异常，请稍后重试');
        _goToAddPage();
      }
    }
  }

  String get _buttonText {
    if (!_speechAvailable) return '语音识别不可用';
    if (_isListening) return '停止聆听';
    return '开始语音输入';
  }

  Color get _buttonColor {
    if (_isListening) return const Color(0xFFE05555);
    if (!_speechAvailable) return const Color(0xFFCCCCCC);
    return const Color(0xFFFF7A47);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F4),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 顶部导航
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.keyboard_arrow_left,
                        color: Color(0xFF222222), size: 34),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        '添加宠物',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF222222),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 48,
                    child: Text(
                      '2/4',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFF7A47),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // 进度条
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                children: List.generate(4, (index) {
                  return Expanded(
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: index < 2
                            ? const Color(0xFFFF7A47)
                            : const Color(0xFFE0E0E0),
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 32),
            // 标题
            const Text(
              '先来介绍一下它',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF222222),
              ),
            ),
            const SizedBox(height: 8),
            // 副标题
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                '你可以通过语音或手动输入来介绍它，\n帮助我们更准确的了解它。',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF999999),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // 语音内容卡片
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '语音内容',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF222222),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: TextField(
                          controller: _introController,
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          decoration: const InputDecoration(
                            hintText:
                                '例如：它叫豆包，品种是比熊，性别是弟弟，2岁，体重15斤"',
                            hintStyle: TextStyle(
                              fontSize: 14,
                              color: Color(0xFFCCCCCC),
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // 底部按钮
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _speechAvailable ? _toggleListening : null,
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        color: _buttonColor,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Center(
                        child: _isListening
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.stop_circle_outlined,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    '停止聆听',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                _buttonText,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: _speechAvailable
                                      ? Colors.white
                                      : Color(0xFF999999),
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _isAnalyzing ? null : _handleNext,
                    child: _isAnalyzing
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFFF7A47),
                            ),
                          )
                        : Text(
                            _hasText ? '下一步' : '跳过',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFFFF7A47),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
