import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wechat_bridge/wechat_bridge.dart';
import 'shared/theme_notifier.dart';
import 'pages/tabbar/pet_home_page.dart';
import 'pages/tabbar/devices_page.dart';
import 'pages/tabbar/my_page.dart';
import 'pages/tabbar/pets_page.dart';
import 'pages/login/index.dart';
import 'services/user_state.dart';
import 'services/home_state.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 仅在移动端注册微信 SDK（Web 不支持）
  if (!kIsWeb) {
    WechatBridgePlatform.instance.registerApp(
      appId: 'wxcf5ef326f4119c89',
      universalLink: 'https://app.jolipaw.pet/jolipaw/',
    );

    WechatBridgePlatform.instance.respStream().listen((resp) {
      debugPrint('=== 微信回调 resp 类型: ${resp.runtimeType} ===');
      if (resp is WechatAuthResp) {
        debugPrint('微信授权回调 - code: ${resp.code}, state: ${resp.state}, isSuccessful: ${resp.isSuccessful}, isCancelled: ${resp.isCancelled}, errorMsg: ${resp.errorMsg}');
      }
      if (resp.isSuccessful) {
        debugPrint('微信操作成功: $resp');
      } else if (resp.isCancelled) {
        debugPrint('用户取消微信操作');
      } else {
        debugPrint('微信操作失败: ${resp.errorMsg}');
      }
    });
  }

  // 关键：透明状态栏 + 文字深色
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // 状态栏透明
      statusBarBrightness: Brightness.light, // 文字深色（适配浅色背景）
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    ),
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
        ChangeNotifierProvider(create: (_) => UserState()),
        ChangeNotifierProvider(create: (_) => HomeState()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'cat',
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFFF5F7FB),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.black,
      ),
      themeMode: themeNotifier.mode,
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;
  bool _loginChecked = true; // 跳过登录检查
  bool _loginPageShown = false;

  static const _tabs = [
    {'label': '管家', 'icon': Icons.home_filled},
    {'label': '宠物', 'icon': Icons.pets},
    {'label': '设备', 'icon': Icons.devices},
    {'label': '我的', 'icon': Icons.person_outline},
  ];

  static const _pages = [
    PetHomePage(),
    PetsPage(),
    DevicesPage(),
    MyPage(),
  ];

  @override
  void initState() {
    super.initState();
    // 监听登录状态变化：退出登录时跳转登录页
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserState>().addListener(_onUserStateChanged);
    });
    // _checkLogin();
  }

  @override
  void dispose() {
    try {
      // 避免在 dispose 后获取 context
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<UserState>().removeListener(_onUserStateChanged);
        }
      });
    } catch (_) {}
    super.dispose();
  }

  void _onUserStateChanged() {
    if (!mounted || !_loginChecked) return;
    final userState = context.read<UserState>();
    if (!userState.isLoggedIn && !_loginPageShown) {
      _loginPageShown = true;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      ).then((_) {
        if (mounted) {
          _loginPageShown = false;
          setState(() {});
        }
      });
    }
  }

  Future<void> _checkLogin() async {
    if (!mounted) return;
    await context.read<UserState>().checkLoginStatus();
    if (!mounted) return;
    setState(() => _loginChecked = true);
    // 如果未登录，弹出登录页
    if (!context.read<UserState>().isLoggedIn) {
      final res = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
      if (res == true && mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loginChecked) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFFF8A65),
        unselectedItemColor: const Color(0xFF9E9E9E),
        items: _tabs
            .map(
              (tab) => BottomNavigationBarItem(
                icon: Icon(tab['icon'] as IconData),
                label: tab['label'] as String,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  final String title;
  const _PlaceholderPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: Center(
        child: Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
