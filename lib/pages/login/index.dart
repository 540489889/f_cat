import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ali_auth/ali_auth.dart';
import 'package:wechat_bridge/wechat_bridge.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/user_state.dart';

// 构建与示意图匹配的一键登录配置
AliAuthModel buildLoginModel({required String androidSk, required String iosSk}) {
  // 默认布局参数
  final int unit = 20;
  final int dialogWidth = -1;
  final int dialogHeight = -1;
  final int screenWidth = 360;
  final int screenHeight = 640;
  final int logBtnHeight = 56;
  // 第三方图标行配置
  final thirdMap = {
    "width": -1,
    "height": -1,
    "top": unit * 10 + 80,
    "space": 20,
    "size": 16,
    'itemWidth': 50,
    'itemHeight': 50,
    // "viewItemName": [],
    // "viewItemPath": ["assets/alipay.png", "assets/taobao.png", "assets/sina.png"]
  };

  return AliAuthModel(
    androidSk,
    iosSk,
    isDebug: true,
    autoQuitPage: false,
    pageType: PageType.fullPort,
    statusBarColor: "#FFFFFF",
    bottomNavColor: "#FFFFFF",
    lightColor: false,
    isStatusBarHidden: false,
    navHidden: true,
    logoOffsetY: unit * 2 ,
    logoImgPath: "assets/images/logo.png",
    logoHidden: false,
    logoWidth: 140,
    logoHeight: 70,
    logoScaleType: ScaleType.fitXy,
    numberColor: "#333333",
    numberSize: 28,
    numFieldOffsetY: unit * 9,
    logBtnText: "本机号码一键登录",
    logBtnTextSize: 16,
    logBtnTextColor: "#FFFFFF",
    logBtnBackgroundPath: "assets/images/btn-bg.png",
    logBtnHeight: 100,
    logBtnMarginLeftAndRight: 28,
    logBtnOffsetY: unit * 12,
    switchAccText: "更多登录方式",
    switchOffsetY: unit * 12 + 120,
    switchAccTextColor: "#666666",
    privacyMargin: 28,
    privacyBefore: "我已阅读并同意",
    // uncheckedImgPath: "assets/btn_unchecked.png",
    // checkedImgPath: "assets/btn_checked.png",
    checkBoxWidth: 15,
    checkBoxHeight: 15,
    dialogWidth: -1,
    dialogHeight: -1,
    pageBackgroundPath: "",
    customThirdView: CustomThirdView.fromJson(thirdMap),
  );
}
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

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
  bool _showCodeLogin = false;

  bool get _canLogin =>
      _phoneCtrl.text.trim().length == 11 &&
      _codeCtrl.text.trim().length == 6;

  // 测试阶段使用模拟短信（固定验证码 000000），生产环境请将此值设为 false
  static const bool _isTestMode = true;

  final String androidSk =
      "hlYZMVTt+HRwZo7YYBmiY3Mmddtmhaim6zC9uUmd7eAdSAuvtB7l7aSPySwDgDWmGmRdBueHGT6gvrJ41Ed1gM8ZZ3Tz9P5vq7LxbWQdgAqhDUQPuPq5lXDJiUI5ya0Vpa9GH/t5mwi1UwPByAhLJgSngcvqIM0Ppwbb4glSBuDLGabsqx36554sOxc6smvbQPHK+CLMR45d68h4HAZfwD2SSQRMrk6sZIVAZTIXexv6u3ribn1VVIlmjtxFT4VgsqdFrxGytwPhoWU8Dt4WpI4JWqXFgTM0qSWdcWcpJ8o=";
  final String iosSk =
      "UVPdnrl0/TshSU81f/ttUi9NPe2juqKl6820ufMR/3F96IVmhX7U5onkMxO5Lp5z29CFfDZkMvRVXzyRjj+TGsfEs56+LVAAFOFrUQ4nLqcn2cmntgSR4WvNMVf/JbxeZLuwEck3uI6A7foHfUqtndlpdRZTMJA/DgTMhue+TeEtzMwdqCpk54w9tP7ysUfm4Wo+s/g48UBAj29G3KltyF+AjC5x11spdtPsoJQwr9rEs/F8AVAKI1pTms22qibv";
  // 用于调试显示或状态
  String _authStatus = '';

  @override
  void initState() {
    super.initState();
    // 注册全局一键登录事件监听（参考示例）
    AliAuth.loginListen(
      onEvent: (onEvent) {
        debugPrint('AliAuth event: $onEvent');
        try {
          if (onEvent is Map) {
            setState(() => _authStatus = onEvent.toString());
            if (onEvent['code'] == '700001') {
              // 点击更多登录方式
              setState(() => _showCodeLogin = true);
              AliAuth.quitPage();
            }
            if (onEvent['code'] == '700005') {
              setState(() => _showCodeLogin = true);
              // 可选择调用 AliAuth.quitPage();
            }
            // 成功拿到token
            if (onEvent['code'] == '600000' && onEvent['data'] != null) {
              final token = onEvent['data']['token'];
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('一键登录成功')));
              // 返回给调用者或执行后端校验：这里直接 pop 返回 token
              if (mounted) {
                Navigator.of(context).pop({'token': token, 'raw': onEvent});
              }
            }
          }
        } catch (e) {
          debugPrint('处理 AliAuth 事件异常: $e');
        }
      },
      onError: (err) {
        debugPrint('AliAuth 监听错误: $err');
        setState(() => _showCodeLogin = true);
      },
    );

    // 默认自动调用阿里云一键登录
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleAliAuth();
    });
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    _countdownTimer?.cancel();
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

    if (_isTestMode) {
      // 测试模式：直接提示固定验证码，不调用后端
      // _showSnack('测试验证码：000000（测试阶段固定验证码）');
      await Future.delayed(const Duration(seconds: 1));
    } else {
      // 生产模式：调用后端发送短信
      final result = await AuthService.sendSmsCode(phone);
      if (!mounted) return;
      if (result.isSuccess) {
        _showSnack('验证码已发送');
      } else {
        setState(() => _sending = false);
        _showSnack(result.message);
        return;
      }
    }

    setState(() => _sending = false);
    _startCountdown(60);
  }

  Future<void> _login() async {
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
      _showProtocolDialog();
      return;
    }

    await _performLogin(phone, code);
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
              expiresIn: result.expiresIn ?? 7200,
              username: phone,
              userInfo: result.userInfo,
            );
      }
      if (context.mounted) {
        _showSnack('登录成功');
        Navigator.of(context).pop(true);
      }
    } else {
      _showSnack(result.message);
    }
  }

  void _showProtocolDialog() {
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
                        style: TextStyle(color: Color(0xFFFF8A65)),
                      ),
                      TextSpan(text: '、'),
                      TextSpan(
                        text: '《用户协议》',
                        style: TextStyle(color: Color(0xFFFF8A65)),
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
                          _performLogin(
                            _phoneCtrl.text.trim(),
                            _codeCtrl.text.trim(),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: const Color(0xFFFF8A65),
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
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => Stack(
        children: [
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 60),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    msg,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) entry.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: _showCodeLogin
            ? SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 24),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.topLeft,
                        child: IconButton(
                          onPressed: () => Navigator.maybePop(context),
                          icon: const Icon(Icons.keyboard_arrow_left,
                              size: 34),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '验证码登录',
                        style: TextStyle(
                            fontSize: 26, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 32),

                // phone input
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F2),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      const Text(
                        '+86',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          onChanged: (_) => setState(() {}),
                          maxLength: 11,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            hintText: '手机号',
                            border: InputBorder.none,
                            counterText: '',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // code input with send button
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F2),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _codeCtrl,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                          maxLength: 6,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            hintText: '验证码',
                            border: InputBorder.none,
                            counterText: '',
                          ),
                        ),
                      ),
                      const VerticalDivider(
                        width: 12,
                        thickness: 1,
                        color: Colors.grey,
                      ),
                      _secondsLeft > 0
                          ? Text(
                              '$_secondsLeft s',
                              style: const TextStyle(color: Colors.orange),
                            )
                          : GestureDetector(
                              onTap: _sending ? null : _sendCode,
                              child: Text(
                                _sending ? '发送中...' : '发送验证码',
                                style: TextStyle(
                                  color: _sending ? Colors.grey : Colors.orange,
                                ),
                              ),
                            ),
                    ],
                  ),
                ),

                // 测试模式提示
                if (_isTestMode) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 16, color: Color(0xFFFF8A65)),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '测试验证码：000000（测试阶段固定验证码）',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFFE65100),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _agree = !_agree),
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey),
                        ),
                        child: _agree
                            ? const Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.orange,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '我已阅读并同意 ',
                              style: const TextStyle(color: Colors.black87),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => setState(() => _agree = !_agree),
                            ),
                            TextSpan(
                              text: '《用户协议》',
                              style: const TextStyle(color: Colors.orange),
                              recognizer: null,
                            ),
                            const TextSpan(
                              text: ' 、',
                              style: TextStyle(color: Colors.black87),
                            ),
                            TextSpan(
                              text: '《隐私政策》',
                              style: const TextStyle(color: Colors.orange),
                              recognizer: null,
                            ),
                          ],
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: (_logining || !_canLogin) ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _canLogin ? const Color(0xFFFF8A65) : Colors.grey,
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
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            '验证并登录',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),

                const SizedBox(height: 100),

                const Text('其他登录方式', style: TextStyle(color: Colors.black54)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _socialButton('assets/images/icon/login-1.png', type: 'wechat'),
                    const SizedBox(width: 24),
                    _socialButton('assets/images/icon/login-2.png', type: 'apple'),
                    const SizedBox(width: 24),
                    _socialButton('assets/images/icon/login-3.png', type: 'phone'),
                  ],
                ),
              ],
            ),
          ),
        )
            : const Center(
                child: CircularProgressIndicator(),
              ),
      ),
    );
  }

  Widget _socialButton(String icon, {String type = ''}) {
    return SizedBox(
      width: 65,
      height: 65,
      child: IconButton(
        onPressed: () {
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
          width: 65, // 图片大小
          height: 65,
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
        Navigator.of(context).pop(true);
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

  Future<void> _handleAliAuth() async {
    // ScaffoldMessenger.of(
    //   context,
    // ).showSnackBar(const SnackBar(content: Text('正在启动阿里云一键登录')));
    try {
      // 构建 AliAuthModel（根据示例简化配置，可扩展）
      final model = AliAuthModel(
        androidSk,
        iosSk,
        isDebug: true,
        pageType: PageType.fullPort,
        logBtnText: '本机一键登录',
        protocolOneName: '《用户协议》',
        protocolOneURL: 'https://example.com/user',
        protocolTwoName: '《隐私政策》',
        protocolTwoURL: 'https://example.com/privacy',
      );

          await AliAuth.initSdk(buildLoginModel(androidSk: androidSk, iosSk: iosSk));
      // 发起授权页
      await AliAuth.login();
    } catch (e) {
      setState(() => _showCodeLogin = true);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('一键登录启动失败: $e')));
      }
    }
  }
}

// export
Widget loginPage() => const LoginPage();
