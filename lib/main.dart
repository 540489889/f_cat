import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:huawei_ml_language/huawei_ml_language.dart';
import 'package:provider/provider.dart';
import 'package:wechat_bridge/wechat_bridge.dart';
import 'shared/theme_notifier.dart';
import 'pages/home_shell.dart';
import 'services/user_state.dart';
import 'services/home_state.dart';
import 'services/pet_state.dart';
import 'package:flutter/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 华为ML Kit API Key
  try {
    await MLLanguageApp().setApiKey(
      'DgEDAJ3FBk98hDrUbgLP7tlMfXKJbhw3tGXNdsP9sxWbTgNqRquauAoAB+mt3gFUUFUesKJDzgTna3MN426lobWGe+TDcI7nt7gBlQ==',
    );
  } catch (e) {
    debugPrint('setApiKey 失败: $e');
  }

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

  // 仅在移动端注册微信 SDK 和支付宝（Web 不支持）
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
        ChangeNotifierProvider(create: (_) => PetState()),
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
          seedColor: const Color(0xFFFF7A47),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FB),
        datePickerTheme: const DatePickerThemeData(
          backgroundColor: Colors.white,
          headerBackgroundColor: Color(0xFFFF7A47),
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
