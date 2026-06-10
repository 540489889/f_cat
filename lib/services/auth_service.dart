import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// APP端认证服务 - 对接后端 /app/login/** API
class AuthService {
  // 统一通过网关访问
  // 生产环境：改为 https://app.jolipaw.pet
  static const String _baseUrl = 'http://192.168.1.135:8080';

  static const String _tokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'login_user';

  // ==================== 公开接口 ====================

  /// 发送短信验证码
  static Future<AuthResult> sendSmsCode(String mobile) async {
    try {
      final uri = Uri.parse('$_baseUrl/auth/app/login/smscode')
          .replace(queryParameters: {'mobile': mobile});
      final response = await http.post(uri, headers: _jsonHeaders());
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && body['code'] == 200) {
        return AuthResult.ok(body['msg'] ?? '验证码已发送');
      }
      return AuthResult.fail(body['msg'] ?? '发送验证码失败');
    } catch (e) {
      return AuthResult.fail('网络异常：$e');
    }
  }

  /// 手机验证码登录
  static Future<LoginResult> loginByMobileCode(
      String mobile, String code) async {
    try {
      final uri = Uri.parse('$_baseUrl/auth/app/login/mobileCode');
      final response = await http.post(
        uri,
        headers: _jsonHeaders(),
        body: jsonEncode({'mobile': mobile, 'code': code}),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && body['code'] == 200) {
        final data = body['data'] as Map<String, dynamic>?;
        if (data != null) {
          return LoginResult.ok(
            accessToken: data['access_token'] as String? ?? '',
            refreshToken: data['refresh_token'] as String? ?? '',
            expiresIn: data['expires_in'] as int? ?? 7200,
            userInfo: data['memberInfo'] as Map<String, dynamic>?,
          );
        }
      }
      return LoginResult.fail(body['msg'] ?? '登录失败');
    } catch (e) {
      return LoginResult.fail('网络异常：$e');
    }
  }

  /// 退出登录
  static Future<bool> logout(String? token) async {
    if (token == null || token.isEmpty) return true;
    try {
      final uri = Uri.parse('$_baseUrl/auth/app/logout');
      await http.delete(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );
    } catch (_) {
      // 即使后端失败也要清除本地状态
    }
    await _clearLocalToken();
    return true;
  }

  /// 刷新Token
  static Future<LoginResult> refreshToken(String? refreshToken) async {
    if (refreshToken == null || refreshToken.isEmpty) {
      return LoginResult.fail('Refresh Token 为空');
    }
    try {
      final uri = Uri.parse('$_baseUrl/auth/app/token/refresh');
      final response = await http.post(
        uri,
        headers: {'Authorization': 'Bearer $refreshToken'},
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && body['code'] == 200) {
        final data = body['data'] as Map<String, dynamic>?;
        if (data != null) {
          return LoginResult.ok(
            accessToken: data['access_token'] as String? ?? '',
            refreshToken: data['refresh_token'] as String? ?? '',
            expiresIn: data['expires_in'] as int? ?? 7200,
          );
        }
      }
      return LoginResult.fail(body['msg'] ?? '刷新失败');
    } catch (e) {
      return LoginResult.fail('网络异常：$e');
    }
  }

  // ==================== 本地持久化 ====================

  /// 保存Token到本地
  static Future<void> saveToken({
    required String accessToken,
    required String refreshToken,
    int expiresIn = 7200,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
    await prefs.setInt(
        '${_tokenKey}_expires_at',
        DateTime.now().millisecondsSinceEpoch + expiresIn * 1000);
  }

  /// 读取本地Access Token
  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// 读取本地Refresh Token
  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  /// 检查本地Token是否有效
  static Future<bool> hasValidToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null || token.isEmpty) return false;
    final expiresAt = prefs.getInt('${_tokenKey}_expires_at');
    if (expiresAt != null &&
        DateTime.now().millisecondsSinceEpoch > expiresAt) {
      // Token 过期，尝试刷新
      final refresh = prefs.getString(_refreshTokenKey);
      if (refresh != null && refresh.isNotEmpty) {
        final result = await refreshToken(refresh);
        if (result.isSuccess) {
          return true;
        }
      }
      return false;
    }
    return true;
  }

  /// 保存用户信息
  static Future<void> saveUserInfo(Map<String, dynamic> userInfo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(userInfo));
  }

  /// 读取用户信息
  static Future<Map<String, dynamic>?> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_userKey);
    if (json == null) return null;
    return jsonDecode(json) as Map<String, dynamic>;
  }

  /// 清除本地Token
  static Future<void> _clearLocalToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove('${_tokenKey}_expires_at');
    await prefs.remove(_userKey);
  }

  // ==================== 内部 ====================

  static Map<String, String> _jsonHeaders() {
    return {'Content-Type': 'application/json; charset=utf-8'};
  }
}

/// 通用请求结果
class AuthResult {
  final bool isSuccess;
  final String message;
  AuthResult._(this.isSuccess, this.message);
  factory AuthResult.ok(String message) => AuthResult._(true, message);
  factory AuthResult.fail(String message) => AuthResult._(false, message);
}

/// 登录结果
class LoginResult {
  final bool isSuccess;
  final String message;
  final String? accessToken;
  final String? refreshToken;
  final int? expiresIn;
  final Map<String, dynamic>? userInfo;

  LoginResult._({
    required this.isSuccess,
    required this.message,
    this.accessToken,
    this.refreshToken,
    this.expiresIn,
    this.userInfo,
  });

  factory LoginResult.ok({
    required String accessToken,
    required String refreshToken,
    int expiresIn = 7200,
    Map<String, dynamic>? userInfo,
  }) =>
      LoginResult._(
        isSuccess: true,
        message: '登录成功',
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresIn: expiresIn,
        userInfo: userInfo,
      );

  factory LoginResult.fail(String message) =>
      LoginResult._(isSuccess: false, message: message);
}
