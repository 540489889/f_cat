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
  Map<String, dynamic>? _userInfo;

  StreamSubscription<void>? _forceLogoutSub;

  bool get isLoggedIn => _isLoggedIn;
  String get username => _username;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  bool get initialized => _initialized;
  Map<String, dynamic>? get userInfo => _userInfo;

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
      final info = await AuthService.getUserInfo();
      _accessToken = token;
      _refreshToken = await AuthService.getRefreshToken();
      _isLoggedIn = true;
      _userInfo = info;
      _username = (info?['nickName'] ?? info?['nickname']) as String? ??
          info?['mobile'] as String? ??
          '用户';
    }
    _initialized = true;
    notifyListeners();
  }

  /// 保存登录结果
  Future<void> onLoginSuccess({
    required String accessToken,
    required String refreshToken,
    int expiresIn = 1800,
    String? username,
    Map<String, dynamic>? userInfo,
  }) async {
    debugPrint('===== 登录成功 onLoginSuccess =====');
    debugPrint('accessToken: $accessToken');
    debugPrint('refreshToken: $refreshToken');
    debugPrint('expiresIn: $expiresIn');
    debugPrint('username(传入): $username');
    debugPrint('userInfo: $userInfo');
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
    _userInfo = userInfo;
    _username = username ??
        (userInfo?['nickName'] ?? userInfo?['nickname']) as String? ??
        userInfo?['mobile'] as String? ??
        '用户';
    debugPrint('最终 username: $_username');
    debugPrint('==================================');
    notifyListeners();
  }

  /// 退出登录（用户主动触发）
  Future<void> logout() async {
    debugPrint('UserState.logout() 开始');
    try {
      await AuthService.logout(_accessToken, refreshToken: _refreshToken);
    } catch (e) {
      debugPrint('UserState.logout() 后端API调用失败（忽略，继续清除本地状态）: $e');
      // 即使后端 API 失败，也要清除本地登录态
    }
    _isLoggedIn = false;
    _accessToken = null;
    _refreshToken = null;
    _username = '';
    _userInfo = null;
    debugPrint('UserState.logout() notifyListeners, hasListeners=$hasListeners');
    notifyListeners();
    debugPrint('UserState.logout() 完成');
  }

  /// 强制登出（refresh token 过期时自动触发，不清除后端 session）
  void _forceLogout() {
    AuthService.clearLocalToken();
    _isLoggedIn = false;
    _accessToken = null;
    _refreshToken = null;
    _username = '';
    _userInfo = null;
    notifyListeners();
  }

  /// 更新用户名
  void setUsername(String name) {
    _username = name;
    notifyListeners();
  }
}
