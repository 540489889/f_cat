import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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

/// 全局微信授权码回调
void Function(String code)? globalWechatCallback;

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 接收 Android 原生端微信授权 code
  const MethodChannel('com.flttercat/wechat')
      .setMethodCallHandler((call) async {
    debugPrint('[Flutter WechatChannel] method=${call.method}, args=${call.arguments}');
    if (call.method == 'onWechatAuthCode') {
      final code = call.arguments as String?;
      if (code != null) {
        debugPrint('[Flutter WechatChannel] calling globalWechatCallback with code=$code');
        globalWechatCallback?.call(code);
      }
    }
    return null;
  });

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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF8A65),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FB),
        datePickerTheme: const DatePickerThemeData(
          backgroundColor: Colors.white,
          headerBackgroundColor: Color(0xFFFF8A65),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.black,
      ),
      themeMode: themeNotifier.mode,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en', 'US'),
      ],
      locale: const Locale('zh', 'CN'),
      home: HomeShell(key: HomeShell.globalKey),
    );
  }
}

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
    // 监听登录状态变化：退出登录时跳转登录页
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserState>().addListener(_onUserStateChanged);
    });
    _checkLogin();
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
          // 登录成功 → relauanch 到全新主页
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
        backgroundColor: Colors.white,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFFF8A65),
        unselectedItemColor: const Color(0xFF9E9E9E),
        items: _tabs
            .map(
              (tab) => BottomNavigationBarItem(
                icon: Image.asset(tab['icon'] as String, width: 24, height: 24),
                activeIcon: Image.asset(tab['activeIcon'] as String, width: 24, height: 24),
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
