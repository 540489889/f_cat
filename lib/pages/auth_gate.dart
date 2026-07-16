import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import '../services/user_state.dart';
import '../services/pet_state.dart';
import 'login/index.dart';
import 'home_shell.dart';

/// 全局微信授权码回调
void Function(String code)? globalWechatCallback;

/// 启动页：与原生 LaunchTheme 保持一致的启动图，避免黑屏闪烁
class _SplashPage extends StatefulWidget {
  const _SplashPage();

  @override
  State<_SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<_SplashPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SizedBox.expand(
        child: Image.asset(
          'assets/images/launch_image_compressed.png',
          fit: BoxFit.fill,
          gaplessPlayback: true,
        ),
      ),
    );
  }
}

/// 路由拦截器：根据登录状态决定显示 LoginPage 还是 HomeShell
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _checking = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final userState = context.read<UserState>();
    try {
      await userState.checkLoginStatus();
    } catch (_) {}
    if (!mounted) return;
    _isLoggedIn = userState.isLoggedIn;
    setState(() => _checking = false);

    // 延迟移除原生启动图：登录页多留一会（避免视频加载未完成时闪黑屏）
    final delayMs = _isLoggedIn ? 300 : 800;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration(milliseconds: delayMs), () {
        FlutterNativeSplash.remove();
      });
    });

    userState.addListener(_onUserStateChanged);
  }

  void _onUserStateChanged() {
    debugPrint('AuthGate._onUserStateChanged 触发 mounted=$mounted');
    if (!mounted) return;
    final loggedIn = context.read<UserState>().isLoggedIn;
    debugPrint('AuthGate._onUserStateChanged: loggedIn=$loggedIn, _isLoggedIn=$_isLoggedIn');
    // 只处理登出（loggedIn=false）的情况。登录成功由 LoginPage.onLoginSuccess 回调统一处理。
    if (!loggedIn && loggedIn != _isLoggedIn) {
      // 延迟到帧末再 setState。因为 ChangeNotifier.notifyListeners() 是同步的，
      // 如果此时同步 setState，会导致 Widget 树立即重建，而其他 listener（如
      // MyPage）还在 notifyListeners 的调用栈中，它们的 Element 可能已被 deactivate，
      // 进而触发 "Looking up a deactivated widget's ancestor" 错误。
      // addPostFrameCallback 确保所有同步 listener 执行完毕后再重建 Widget 树。
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _isLoggedIn = false);
      });
    }
  }

  @override
  void dispose() {
    try {
      context.read<UserState>().removeListener(_onUserStateChanged);
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 检查中显示启动图，避免黑屏闪烁
    if (_checking) return const _SplashPage();

    if (!_isLoggedIn) {
      return Stack(
        children: [
          // 启动图作为背景，避免从 _SplashPage 切换到 LoginPage 时的黑屏
          Positioned.fill(
            child: Image.asset(
              'assets/images/launch_image_compressed.png',
              fit: BoxFit.fill,
            ),
          ),
          LoginPage(
            key: const ValueKey('login_page'),
            onLoginSuccess: () {
              if (mounted) setState(() => _isLoggedIn = true);
            },
          ),
        ],
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PetState>().refresh();
    });
    return HomeShell(key: HomeShell.globalKey);
  }
}
