import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/user_state.dart';
import '../services/pet_state.dart';
import 'login/index.dart';
import 'home_shell.dart';

/// 全局微信授权码回调
void Function(String code)? globalWechatCallback;

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
    userState.addListener(_onUserStateChanged);
  }

  void _onUserStateChanged() {
    if (!mounted) return;
    final loggedIn = context.read<UserState>().isLoggedIn;
    debugPrint('AuthGate._onUserStateChanged: loggedIn=$loggedIn, _isLoggedIn=$_isLoggedIn');
    if (loggedIn != _isLoggedIn) {
      setState(() => _isLoggedIn = loggedIn);
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
    // 检查中不渲染，避免一闪而过首页
    if (_checking) return const SizedBox.shrink();

    if (!_isLoggedIn) {
      return LoginPage(
        onLoginSuccess: () {
          if (mounted) setState(() => _isLoggedIn = true);
        },
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PetState>().refresh();
    });
    return HomeShell(key: HomeShell.globalKey);
  }
}
