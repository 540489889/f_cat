import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ali_auth/ali_auth.dart';
import 'package:wechat_bridge/wechat_bridge.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:provider/provider.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../services/auth_service.dart';
import '../../services/user_state.dart';
import '../home_shell.dart' show HomeShell, globalWechatCallback;
import '../../shared/toast.dart';
import '../../shared/throttle.dart';
import 'bindMoobile.dart';

// 构建与示意图匹配的一键登录配置
AliAuthModel buildLoginModel({required String androidSk, required String iosSk}) {
  // 底部弹窗布局参数（根据屏幕尺寸动态计算）
  final screenHeight = (ui.PlatformDispatcher.instance.views.first.physicalSize.height /
          ui.PlatformDispatcher.instance.views.first.devicePixelRatio)
      .floor();
  final int dialogHeight = (screenHeight * 0.6).floor();
  final int unit = dialogHeight ~/ 8;
  final int logBtnHeight = 48;
  // 第三方图标行配置
  final thirdMap = {
    "width": -1,
    "height": -1,
    "top": unit * 4 + 40,
    "space": 20,
    "size": 15,
    "color": "#616161",
    'itemWidth': 40,
    'itemHeight': 40,
  };

  return AliAuthModel(
    androidSk,
    iosSk,
    isDebug: true,
    autoQuitPage: false,
    pageType: PageType.dialogBottom,
    statusBarColor: "#00000000",
    bottomNavColor: "#FFFFFF",
    lightColor: true,
    isStatusBarHidden: false,
    statusBarUIFlag: UIFAG.systemUiFalgLayoutFullscreen,
    navHidden: true,
    // Logo
    logoOffsetY: unit ~/ 2,
    logoImgPath: "assets/images/logo.png",
    logoHidden: false,
    logoWidth: 70,
    logoHeight: 70,
    logoScaleType: ScaleType.fitXy,
    // 号码
    numberColor: "#333333",
    numberSize: 18,
    numFieldOffsetY: unit * 2,
    numberFieldOffsetX: 0,
    numberLayoutGravity: Gravity.centerHorizntal,
    // 登录按钮
    logBtnText: "本机号码一键登录",
    logBtnTextSize: 16,
    logBtnTextColor: "#FFFFFF",
    logBtnHeight: logBtnHeight,
    logBtnOffsetY: unit * 3,
    logBtnOffsetX: 0,
    logBtnMarginLeftAndRight: 20,
    logBtnLayoutGravity: Gravity.centerHorizntal,
    logBtnToastHidden: false,
    // 切换验证码登录
    switchAccText: "验证码登录",
    switchOffsetY: unit * 4,
    switchOffsetY_B: -1,
    switchAccTextColor: "#666666",
    switchAccTextSize: 16,
    // 协议
    protocolOneName: "《用户协议》",
    protocolOneURL: "https://example.com/user",
    protocolTwoName: "《隐私政策》",
    protocolTwoURL: "https://example.com/privacy",
    protocolCustomColor: "#FF7A47",
    protocolColor: "#999999",
    protocolLayoutGravity: Gravity.centerHorizntal,
    protocolGravity: Gravity.centerHorizntal,
    privacyTextSize: 12,
    privacyMargin: 28,
    privacyBefore: "我已阅读并同意",
    privacyEnd: "",
    vendorPrivacyPrefix: "《",
    vendorPrivacySuffix: "》",
    checkBoxWidth: 15,
    checkBoxHeight: 15,
    checkboxHidden: false,
    privacyState: false,
    // 底部弹窗特定参数
    dialogHeight: dialogHeight,
    dialogBottom: true,
    dialogCornerRadiusArray: [10, 10, 0, 0],
    dialogAlpha: 0.4,
    pageBackgroundRadius: 10,
    customThirdView: CustomThirdView.fromJson(thirdMap),
    pageBackgroundPath: "",  // 去掉 SDK 默认背景图，避免黑屏
  );
}
class LoginPage extends StatefulWidget {
  final VoidCallback? onLoginSuccess;
  const LoginPage({super.key, this.onLoginSuccess});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _codeCtrl = TextEditingController();
  bool _agree = false;
  Timer? _countdownTimer;
  int _secondsLeft = 0;
  bool _sending = false;
  bool _logining = false;
  bool _showCodeLogin = false; // 默认隐藏，一键登录失败才显示
  final _loginThrottle = ActionThrottle();
  Timer? _aliAuthTimeout;
  late final Player _player;
  late final VideoController _videoController;
  bool _videoInitialized = false;

  bool get _canLogin =>
      _phoneCtrl.text.trim().length == 11 &&
      _codeCtrl.text.trim().length == 6;

  // 测试阶段使用模拟短信（固定验证码 000000），生产环境请将此值设为 false
  static const bool _isTestMode = false;

  final String androidSk =
      "hlYZMVTt+HRwZo7YYBmiY3Mmddtmhaim6zC9uUmd7eAdSAuvtB7l7aSPySwDgDWmGmRdBueHGT6gvrJ41Ed1gM8ZZ3Tz9P5vq7LxbWQdgAqhDUQPuPq5lXDJiUI5ya0Vpa9GH/t5mwi1UwPByAhLJgSngcvqIM0Ppwbb4glSBuDLGabsqx36554sOxc6smvbQPHK+CLMR45d68h4HAZfwD2SSQRMrk6sZIVAZTIXexv6u3ribn1VVIlmjtxFT4VgsqdFrxGytwPhoWU8Dt4WpI4JWqXFgTM0qSWdcWcpJ8o=";
  final String iosSk =
      "UVPdnrl0/TshSU81f/ttUi9NPe2juqKl6820ufMR/3F96IVmhX7U5onkMxO5Lp5z29CFfDZkMvRVXzyRjj+TGsfEs56+LVAAFOFrUQ4nLqcn2cmntgSR4WvNMVf/JbxeZLuwEck3uI6A7foHfUqtndlpdRZTMJA/DgTMhue+TeEtzMwdqCpk54w9tP7ysUfm4Wo+s/g48UBAj29G3KltyF+AjC5x11spdtPsoJQwr9rEs/F8AVAKI1pTms22qibv";
  // 用于调试显示或状态
  String _authStatus = '';

  @override
  void initState() {
    super.initState();
    _initVideo();
    // 注册全局一键登录事件监听
    AliAuth.loginListen(
      onEvent: (onEvent) {
        debugPrint('AliAuth event: $onEvent');
        try {
          if (onEvent is Map) {
            setState(() => _authStatus = onEvent.toString());
            if (onEvent['code'] == '700001') {
              // 点击更多登录方式
              _aliAuthTimeout?.cancel();
              setState(() => _showCodeLogin = true);
              AliAuth.quitPage();
            }
            if (onEvent['code'] == '700005') {
              _aliAuthTimeout?.cancel();
              setState(() => _showCodeLogin = true);
              // 可选择调用 AliAuth.quitPage();
            }
            if (onEvent['code'] == '600008') {
              setState(() => _showCodeLogin = true);
              // 可选择调用 AliAuth.quitPage();
              AliAuth.quitPage();
            }
            // 成功拿到运营商标识token（data 直接就是 token 字符串）
            if (onEvent['code'] == '600000' && onEvent['data'] != null) {
              final token = onEvent['data'] is String
                  ? onEvent['data'] as String
                  : onEvent['data']['token'] as String;
              AliAuth.quitPage(); // 先关闭授权页
              if (mounted) {
                _handleMobileAuth(token);
              }
            }
          }
        } catch (e) {
          debugPrint('处理 AliAuth 事件异常: $e');
        }
      },
      onError: (err) {
        debugPrint('AliAuth 监听错误: $err');
        _aliAuthTimeout?.cancel();
        setState(() => _showCodeLogin = true);
      },
    );

    // 注册微信登录回调
    globalWechatCallback = (code) {
      if (mounted) _handleWechatAuth(code);
    };

    // 默认直接进入验证码登录
    _showCodeLogin = true;
  }

  Future<void> _initVideo() async {
    _player = Player();
    _videoController = VideoController(_player);
    _player.stream.error.listen((e) {
      debugPrint('Video error: $e');
    });
    try {
      await _player.open(Media('asset:///assets/images/bg4_h264.mp4'));
      await _player.setVolume(0.0);
      await _player.setPlaylistMode(PlaylistMode.single);
      if (mounted) setState(() => _videoInitialized = true);
    } catch (e) {
      debugPrint('Video init error: $e');
    }
  }

  /// 启动 AliAuth 超时保护：超时后自动切换到验证码登录
  void _startAliAuthTimeout() {
    _aliAuthTimeout?.cancel();
    _aliAuthTimeout = Timer(const Duration(seconds: 8), () {
      if (mounted && !_showCodeLogin) {
        debugPrint('AliAuth 超时，自动切换到验证码登录');
        AliAuth.quitPage();
        setState(() => _showCodeLogin = true);
      }
    });
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    _countdownTimer?.cancel();
    _aliAuthTimeout?.cancel();
    _player.dispose();
    // 清理 ali_auth 资源和监听
    try {
      AliAuth.dispose();
    } catch (e) {
      debugPrint('AliAuth.dispose() 失败: $e');
    }
    super.dispose();
  }

  void _startCountdown(int seconds) {
    _countdownTimer?.cancel();
    setState(() {
      _secondsLeft = seconds;
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 1) {
        t.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft -= 1);
      }
    });
  }

  Future<void> _sendCode() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) {
      _showSnack('请输入手机号');
      return;
    }
    setState(() => _sending = true);

    // 无论是否测试模式，都调用后端接口（后端 smsMock=true 时会将 000000 存入 Redis）
    final result = await AuthService.sendSmsCode(phone);
    if (!mounted) return;
    if (result.isSuccess) {
      if (_isTestMode) {
        _showSnack('测试验证码：000000');
      } else {
        _showSnack('验证码已发送');
      }
    } else {
      setState(() => _sending = false);
      _showSnack(result.message);
      return;
    }

    setState(() => _sending = false);
    _startCountdown(60);
  }

  Future<void> _login() async {
    await _loginThrottle.run(() async {
    final phone = _phoneCtrl.text.trim();
    final code = _codeCtrl.text.trim();
    if (phone.isEmpty) {
      _showSnack('请输入手机号');
      return;
    }
    if (code.isEmpty) {
      _showSnack('请输入验证码');
      return;
    }
    if (!_agree) {
      _showProtocolDialog(onAgree: () {
        _performLogin(phone, code);
      });
      return;
    }

    await _performLogin(phone, code);
    });
  }

  Future<void> _performLogin(String phone, String code) async {
    setState(() => _logining = true);
    final result = await AuthService.loginByMobileCode(phone, code);
    print('isSuccess: ${result.isSuccess}');
    print('message: ${result.message}');
    print('accessToken: ${result.accessToken}');
    print('userInfo: ${result.userInfo}');

    if (!mounted) return;

    setState(() => _logining = false);

    if (result.isSuccess) {
      // 保存登录状态到 Provider
      if (context.mounted) {
        await context.read<UserState>().onLoginSuccess(
              accessToken: result.accessToken!,
              refreshToken: result.refreshToken!,
              expiresIn: result.expiresIn ?? 1800,
              username: phone,
              userInfo: result.userInfo,
            );
      }
      if (context.mounted) {
        _goHome();
      }
    } else {
      _showSnack(result.message);
    }
  }

  void _onLoginDone() {
    widget.onLoginSuccess?.call();
    _goHome();
  }

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeShell()),
      (route) => false,
    );
  }

  void _showProtocolDialog({VoidCallback? onAgree}) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '隐私政策和服务协议',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                RichText(
                  textAlign: TextAlign.left,
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                    children: [
                      TextSpan(
                        text: '为了更好地保障您的合法权益，请你阅读',
                      ),
                      TextSpan(
                        text: '《隐私政策》',
                        style: TextStyle(color: Color(0xFFFF7A47)),
                      ),
                      TextSpan(text: '、'),
                      TextSpan(
                        text: '《用户协议》',
                        style: TextStyle(color: Color(0xFFFF7A47)),
                      ),
                      TextSpan(
                        text: '，点击同意后将继续登录',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey,
                          side: const BorderSide(color: Colors.grey),
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: const Text('不同意'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          setState(() => _agree = true);
                          onAgree?.call();
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: const Color(0xFFFF7A47),
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: const Text('同意并继续'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    Toast.show(context, msg);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFF7A47),
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            // 渐变背景始终显示，视频未渲染首帧时不会黑屏
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFF7A47), Color(0xFFFFF5F0)],
                  ),
                ),
              ),
            ),
            if (_videoInitialized)
              Positioned.fill(
                child: Video(
                  controller: _videoController,
                  fit: BoxFit.cover,
                ),
              ),

            SafeArea(
              bottom: false,
              child: _showCodeLogin
                  ? Column(
                      children: [
                        const Spacer(),
                        Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  '验证码登录',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF222222)),
                                ),
                                const SizedBox(height: 24),
                                // phone
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF2F2F2),
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 6),
                                  child: Row(
                                    children: [
                                      const Text('+86',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF333333))),
                                      const SizedBox(width: 12),
                                      Container(
                                          width: 1,
                                          height: 20,
                                          color: const Color(0xFFDDDDDD)),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TextField(
                                          controller: _phoneCtrl,
                                          keyboardType: TextInputType.phone,
                                          onChanged: (_) => setState(() {}),
                                          maxLength: 11,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                          ],
                                          style: const TextStyle(
                                              color: Color(0xFF333333)),
                                          decoration: const InputDecoration(
                                            hintText: '手机号',
                                            hintStyle: TextStyle(
                                                color: Color(0xFF999999)),
                                            border: InputBorder.none,
                                            counterText: '',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // code
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF2F2F2),
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 6),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _codeCtrl,
                                          keyboardType: TextInputType.number,
                                          onChanged: (_) => setState(() {}),
                                          maxLength: 6,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                          ],
                                          style: const TextStyle(
                                              color: Color(0xFF333333)),
                                          decoration: const InputDecoration(
                                            hintText: '验证码',
                                            hintStyle: TextStyle(
                                                color: Color(0xFF999999)),
                                            border: InputBorder.none,
                                            counterText: '',
                                          ),
                                        ),
                                      ),
                                      Container(
                                          width: 1,
                                          height: 20,
                                          color: const Color(0xFFDDDDDD)),
                                      const SizedBox(width: 12),
                                      _secondsLeft > 0
                                          ? Text('$_secondsLeft s',
                                              style: const TextStyle(
                                                  color: Color(0xFFFF7A47)))
                                          : GestureDetector(
                                              onTap:
                                                  _sending ? null : _sendCode,
                                              child: Text(
                                                _sending ? '发送中...' : '发送验证码',
                                                style: TextStyle(
                                                  color: _sending
                                                      ? const Color(0xFF999999)
                                                      : const Color(0xFFFF7A47),
                                                ),
                                              ),
                                            ),
                                    ],
                                  ),
                                ),
                                if (_isTestMode) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF3E0),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.info_outline,
                                            size: 16,
                                            color: Color(0xFFFF7A47)),
                                        SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            '测试验证码：000000',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFFE65100)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                const SizedBox(height: 22),
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed:
                                        (_logining || !_canLogin) ? null : _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _canLogin
                                          ? const Color(0xFFFF7A47)
                                          : Colors.grey,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(28),
                                      ),
                                    ),
                                    child: _logining
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.white),
                                            ),
                                          )
                                        : const Text('验证并登录',
                                            style: TextStyle(
                                                fontSize: 18,
                                                color: Colors.white)),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                const Text('其他登录方式',
                                    style: TextStyle(color: Colors.black54)),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _socialButton(
                                        'assets/images/icon/login-1.png',
                                        type: 'wechat'),
                                    const SizedBox(width: 24),
                                    if (Platform.isIOS) ...[
                                      _socialButton(
                                          'assets/images/icon/login-2.png',
                                          type: 'apple'),
                                      const SizedBox(width: 24),
                                    ],
                                    _socialButton(
                                        'assets/images/icon/login-3.png',
                                        type: 'phone'),
                                  ],
                                ),
                                const SizedBox(height: 15),
                                Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      GestureDetector(
                                        onTap: () =>
                                            setState(() => _agree = !_agree),
                                        child: Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border:
                                                Border.all(color: Colors.grey),
                                          ),
                                          child: _agree
                                              ? const Icon(Icons.check,
                                                  size: 16,
                                                  color: Colors.orange)
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: RichText(
                                          text: TextSpan(
                                            style: const TextStyle(
                                                fontSize: 13),
                                            children: [
                                              TextSpan(
                                                text: '我已阅读并同意 ',
                                                style: const TextStyle(
                                                    color: Colors.black87),
                                                recognizer:
                                                    TapGestureRecognizer()
                                                      ..onTap = () =>
                                                          setState(() =>
                                                              _agree = !_agree),
                                              ),
                                              const TextSpan(
                                                text: '《用户协议》',
                                                style: TextStyle(
                                                    color: Colors.orange),
                                              ),
                                              const TextSpan(
                                                text: ' 、',
                                                style: TextStyle(
                                                    color: Colors.black87),
                                              ),
                                              const TextSpan(
                                                text: '《隐私政策》',
                                                style: TextStyle(
                                                    color: Colors.orange),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _socialButton(String icon, {String type = ''}) {
    return SizedBox(
      width: 55,
      height: 55,
      child: IconButton(
        onPressed: () {
          if (!_agree) {
            _showProtocolDialog(onAgree: () {
              switch (type) {
                case 'wechat':
                  _handleWechatLogin();
                  break;
                case 'apple':
                  _handleAppleLogin();
                  break;
                case 'phone':
                  _handleAliAuth();
                  break;
              }
            });
            return;
          }
          switch (type) {
            case 'wechat':
              _handleWechatLogin();
              break;
            case 'apple':
              _handleAppleLogin();
              break;
            case 'phone':
              _handleAliAuth();
              break;
            default:
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('第三方登录 - 未实现')));
          }
        },
        icon: Image.asset(
          icon,
          width: 50, // 图片大小
          height: 50,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Future<void> _handleWechatLogin() async {
    try {
      final platform = WechatBridgePlatform.instance;

      // 1. 检查微信是否已安装
      final isInstalled = await platform.isInstalled();
      debugPrint('微信是否已安装: $isInstalled');
      if (!isInstalled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('请先安装微信')),
          );
        }
        return;
      }

      // 调试：拦截回调，打印 code 并阻止后续登录流程
      // globalWechatCallback = (code) {
      //   debugPrint('[WeChat Debug] 微信返回的 code: $code');
      //   // 恢复原始回调（不执行 _handleWechatAuth）
      // };

      // 2. 发起授权登录
      debugPrint('开始微信授权登录...');
      await platform.auth(
        scope: [WechatScope.kSNSApiUserInfo],
      );
      debugPrint('微信授权登录请求已发送');
    } catch (e) {
      debugPrint('微信登录异常: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('微信登录异常: $e')),
        );
      }
    }
  }

  Future<void> _handleAppleLogin() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // debugPrint('Apple登录凭证: $credential');
      // debugPrint('identityToken: ${credential.identityToken}');
      // debugPrint('authorizationCode: ${credential.authorizationCode}');
      // debugPrint('userIdentifier: ${credential.userIdentifier}');
      // debugPrint('givenName: ${credential.givenName}');
      // debugPrint('familyName: ${credential.familyName}');
      // debugPrint('email: ${credential.email}');

      // TODO: 将 credential 发送到你的后端服务器进行验证和登录
      // final response = await http.post(
      //   Uri.parse('https://your-server.com/api/apple-login'),
      //   body: {
      //     'identityToken': credential.identityToken,
      //     'authorizationCode': credential.authorizationCode,
      //     'userIdentifier': credential.userIdentifier,
      //     if (credential.givenName != null) 'givenName': credential.givenName,
      //     if (credential.familyName != null) 'familyName': credential.familyName,
      //     if (credential.email != null) 'email': credential.email,
      //   },
      // );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Apple登录成功')),
        );
        // 登录成功后返回
        _goHome();
      }
    } catch (e) {
      debugPrint('Apple登录异常: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Apple登录失败: $e')),
        );
      }
    }
  }

  /// 发送运营商标识token到后端完成一键登录
  /// 发送微信授权code到后端
  Future<void> _handleWechatAuth(String code) async {
    final result = await AuthService.loginByWechat(code);
    debugPrint('微信登录结果: isSuccess=${result.isSuccess}, needsBind=${result.needsBind}, message=${result.message}');
    if (!mounted) return;
    if (result.isSuccess) {
      await context.read<UserState>().onLoginSuccess(
            accessToken: result.accessToken!,
            refreshToken: result.refreshToken!,
            expiresIn: result.expiresIn ?? 1800,
            userInfo: result.userInfo,
          );
      if (mounted) _onLoginDone();
    } else if (result.needsBind) {
      // 需要绑定手机号
      final bindRes = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => BindMobilePage(cacheKey: result.cacheKey!),
        ),
      );
      if (bindRes == true && mounted) _onLoginDone();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('微信登录失败: ${result.message}')),
        );
      }
    }
  }

  Future<void> _handleMobileAuth(String token) async {

    final result = await AuthService.loginByMobileAuth(token);

    debugPrint('一键登录结果: isSuccess=${result.isSuccess}, message=${result.message}');

    if (!mounted) return;

    if (result.isSuccess) {
      await context.read<UserState>().onLoginSuccess(
            accessToken: result.accessToken!,
            refreshToken: result.refreshToken!,
            expiresIn: result.expiresIn ?? 1800,
            userInfo: result.userInfo,
          );
      if (mounted) {
        _goHome();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('一键登录失败: ${result.message}')),
        );
      }
      setState(() => _showCodeLogin = true);
    }
  }

  Future<void> _handleAliAuth() async {
    // 启动超时保护，防止 SDK 无响应导致页面永远转圈
    _startAliAuthTimeout();
    try {
      await AliAuth.initSdk(buildLoginModel(androidSk: androidSk, iosSk: iosSk));
      // 发起授权页，此方法阻塞直到授权页关闭
      await AliAuth.login();
      // 授权页关闭 → 显示验证码登录
      _aliAuthTimeout?.cancel();
      if (mounted) setState(() => _showCodeLogin = true);
    } catch (e) {
      // 唤起失败 → 显示验证码登录
      _aliAuthTimeout?.cancel();
      if (mounted) {
        setState(() => _showCodeLogin = true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('一键登录启动失败: $e')));
      }
    }
  }
}

// export
Widget loginPage() => const LoginPage();
