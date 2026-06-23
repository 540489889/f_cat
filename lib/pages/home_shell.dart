import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/user_state.dart';
import '../services/pet_state.dart';
import 'login/index.dart';
import 'tabbar/pet_home_page.dart';
import 'tabbar/devices_page.dart';
import 'tabbar/my_page.dart';
import 'tabbar/pets_page.dart';

/// 全局微信授权码回调
void Function(String code)? globalWechatCallback;

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  /// 全局 Key，用于外部切换 Tab
  static final GlobalKey<HomeShellState> globalKey = GlobalKey<HomeShellState>();

  @override
  State<HomeShell> createState() => HomeShellState();
}

class HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;
  bool _loginPageShown = false;

  static const _tabs = [
    {'label': '管家', 'icon': 'assets/images/tabbar/home.png', 'activeIcon': 'assets/images/tabbar/home_active.png'},
    {'label': '宠物', 'icon': 'assets/images/tabbar/pet.png', 'activeIcon': 'assets/images/tabbar/pet_active.png'},
    {'label': '设备', 'icon': 'assets/images/tabbar/device.png', 'activeIcon': 'assets/images/tabbar/device_active.png'},
    {'label': '我的', 'icon': 'assets/images/tabbar/my_active.png', 'activeIcon': 'assets/images/tabbar/my.png'},
  ];

  static const _pages = [
    PetHomePage(),
    PetsPage(),
    DevicesPage(),
    MyPage(),
  ];

  /// 外部调用切换 Tab
  void switchToTab(int index) {
    setState(() => _selectedIndex = index.clamp(0, _pages.length - 1));
  }

  @override
  void initState() {
    super.initState();
    // 延迟到帧构建完成后加载宠物数据，避免 build 阶段 notifyListeners 报错
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<PetState>().refresh();
      }
      context.read<UserState>().addListener(_onUserStateChanged);
    });
    _checkLogin();
  }

  @override
  void dispose() {
    try {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<UserState>().removeListener(_onUserStateChanged);
        }
      });
    } catch (_) {}
    super.dispose();
  }

  void _onUserStateChanged() {
    if (!mounted) return;
    final userState = context.read<UserState>();
    if (!userState.isLoggedIn && !_loginPageShown) {
      _loginPageShown = true;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      ).then((result) {
        if (!mounted) return;
        _loginPageShown = false;
        if (result == true) {
          // 登录成功 → relaunch 到全新主页
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeShell()),
            (route) => false,
          );
        } else {
          setState(() {});
        }
      });
    }
  }

  Future<void> _checkLogin() async {
    try {
      await context.read<UserState>().checkLoginStatus();
    } catch (_) {}
    if (!mounted) return;
    if (!context.read<UserState>().isLoggedIn) {
      final res = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
      if (!mounted) return;
      if (res == true) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeShell()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFFFF7A47),
        unselectedItemColor: Colors.grey,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        items: _tabs.map((t) => BottomNavigationBarItem(
          icon: Image.asset(t['icon']!, width: 24, height: 24),
          activeIcon: Image.asset(t['activeIcon']!, width: 24, height: 24),
          label: t['label'],
        )).toList(),
      ),
    );
  }
}
