import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/http_client.dart';

/// 用户登录状态管理（Provider）
class UserState extends ChangeNotifier {
  bool _isLoggedIn = false;
  String _username = '';
  String? _accessToken;
  String? _refreshToken;
  bool _initialized = false;

  StreamSubscription<void>? _forceLogoutSub;

  bool get isLoggedIn => _isLoggedIn;
  String get username => _username;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  bool get initialized => _initialized;

  UserState() {
    // 监听强制登出事件（refresh token 过期时由 AuthHttpClient 触发）
    _forceLogoutSub = AuthHttpClient.instance.forceLogoutStream.listen((_) {
      debugPrint('[UserState] 收到强制登出事件（refresh token 过期）');
      _forceLogout();
    });
  }

  @override
  void dispose() {
    _forceLogoutSub?.cancel();
    super.dispose();
  }

  /// 应用启动时检查登录状态
  Future<void> checkLoginStatus() async {
    final hasToken = await AuthService.hasValidToken();
    if (hasToken) {
      final token = await AuthService.getAccessToken();
      final userInfo = await AuthService.getUserInfo();
      _accessToken = token;
      _refreshToken = await AuthService.getRefreshToken();
      _isLoggedIn = true;
      _username = userInfo?['nickName'] as String? ??
          userInfo?['mobile'] as String? ??
          '用户';
    }
    _initialized = true;
    notifyListeners();
  }

  /// 保存登录结果
  Future<void> onLoginSuccess({
    required String accessToken,
    required String refreshToken,
    int expiresIn = 7200,
    String? username,
    Map<String, dynamic>? userInfo,
  }) async {
    await AuthService.saveToken(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresIn: expiresIn,
    );
    if (userInfo != null) {
      await AuthService.saveUserInfo(userInfo);
    }
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _isLoggedIn = true;
    _initialized = true;
    _username = username ??
        userInfo?['nickName'] as String? ??
        userInfo?['mobile'] as String? ??
        '用户';
    notifyListeners();
  }

  /// 退出登录（用户主动触发）
  Future<void> logout() async {
    await AuthService.logout(_accessToken);
    _isLoggedIn = false;
    _accessToken = null;
    _refreshToken = null;
    _username = '';
    notifyListeners();
  }

  /// 强制登出（refresh token 过期时自动触发，不清除后端 session）
  void _forceLogout() {
    AuthService.clearLocalToken();
    _isLoggedIn = false;
    _accessToken = null;
    _refreshToken = null;
    _username = '';
    notifyListeners();
  }

  /// 更新用户名
  void setUsername(String name) {
    _username = name;
    notifyListeners();
  }
}
