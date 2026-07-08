import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

/// APP端认证服务 - 对接后端 /app/login/** API
///
/// 使用原始 http 请求（不走 AuthHttpClient），因为登录/刷新 Token 接口
/// 本身不需要前置 Token 认证。
/// 安全将 dynamic 转换为 int（处理 API 返回 String 类型数字的情况）
int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

/// 安全比较后端返回的 code 字段是否为 200（兼容 String/num 类型）
bool _isSuccess(dynamic code) {
  if (code is int) return code == 200;
  if (code is String) return code == '200';
  if (code is double) return code == 200.0;
  return false;
}

class AuthService {
  static const String _tokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'login_user';

  static Map<String, String> get _jsonHeaders =>
      {'Content-Type': 'application/json; charset=utf-8'};

  // ==================== 公开接口 ====================

  /// 发送短信验证码
  static Future<AuthResult> sendSmsCode(String mobile) async {
    try {
      final base = Uri.parse(ApiConfig.baseUrl);
      final uri = base.replace(path: '/auth/app/login/smscode', queryParameters: {'mobile': mobile});
      final response = await http.post(uri, headers: _jsonHeaders);
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      debugPrint('[AuthService] sendSmsCode response: ${response.statusCode} $body');
      if (response.statusCode == 200 && _isSuccess(body['code'])) {
        return AuthResult.ok(body['msg'] ?? '验证码已发送');
      }
      return AuthResult.fail(body['msg'] ?? '发送验证码失败');
    } catch (e) {
      debugPrint('[AuthService] sendSmsCode error: $e');
      return AuthResult.fail('网络异常：$e');
    }
  }

  
  /// 微信APP授权登录
  static Future<WechatLoginResult> loginByWechat(String code) async {
    try {
      debugPrint('[wechatLogin] code=$code');
      debugPrint('[wechatLogin] baseUrl=${ApiConfig.baseUrl}');
      final base = Uri.parse(ApiConfig.baseUrl);
      final uri = base.replace(path: '/auth/app/login/weixin', queryParameters: {'code': code});
      final response = await http.post(uri, headers: _jsonHeaders);
      debugPrint('[wechatLogin] statusCode=${response.statusCode}');
      debugPrint('[wechatLogin] body=${response.body}');
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && _isSuccess(body['code'])) {
        final data = body['data'] as Map<String, dynamic>?;
        if (data != null) {
          // 需要绑定手机号
          if (data['message'] == 'bindMobile') {
            return WechatLoginResult.needsBind(
              cacheKey: data['cacheKey'] as String? ?? '',
            );
          }
          // 直接登录成功
          return WechatLoginResult.ok(
            accessToken: data['access_token'] as String? ?? '',
            refreshToken: data['refresh_token'] as String? ?? '',
            expiresIn: _toInt(data['expires_in']) ?? 1800,
            userInfo: data['memberInfo'] as Map<String, dynamic>?,
          );
        }
      }
      return WechatLoginResult.fail(body['msg'] ?? '微信登录失败');
    } catch (e) {
      return WechatLoginResult.fail('网络异常：$e');
    }
  }

  /// 微信绑定手机号登录
  static Future<LoginResult> bindMobile({
    required String cacheKey,
    required String mobile,
    required String code,
  }) async {
    try {
      debugPrint('[bindMobile] cacheKey=$cacheKey, mobile=$mobile, code=$code');
    
      final uri = Uri.parse('${ApiConfig.baseUrl}/auth/app/login/bindMobile');
      final response = await http.post(
        uri,
        headers: _jsonHeaders,
        body: jsonEncode({
          'cacheKey': cacheKey,
          'mobile': mobile,
          'code': code,
        }),
      );
      debugPrint('[bindMobile] statusCode=${response.statusCode}');
      debugPrint('[bindMobile] body=${response.body}');
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && _isSuccess(body['code'])) {
        final data = body['data'] as Map<String, dynamic>?;
        if (data != null) {
          return LoginResult.ok(
            accessToken: data['access_token'] as String? ?? '',
            refreshToken: data['refresh_token'] as String? ?? '',
            expiresIn: _toInt(data['expires_in']) ?? 1800,
            userInfo: data['memberInfo'] as Map<String, dynamic>?,
          );
        }
      }
      return LoginResult.fail(body['msg'] ?? '绑定失败');
    } catch (e) {
      return LoginResult.fail('网络异常：$e');
    }
  }

  /// 阿里云一键登录（本机号码认证）
  static Future<LoginResult> loginByMobileAuth(String token) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/auth/app/login/mobileAuth')
          .replace(queryParameters: {'accessToken': token});
      final response = await http.post(uri, headers: _jsonHeaders);
      debugPrint('[mobileAuth] statusCode: ${response.statusCode}');
      debugPrint('[mobileAuth] body: ${response.body}');
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && _isSuccess(body['code'])) {
        final data = body['data'] as Map<String, dynamic>?;
        if (data != null) {
          return LoginResult.ok(
            accessToken: data['access_token'] as String? ?? '',
            refreshToken: data['refresh_token'] as String? ?? '',
            expiresIn: _toInt(data['expires_in']) ?? 1800,
            userInfo: data['memberInfo'] as Map<String, dynamic>?,
          );
        }
      }
      debugPrint('[mobileAuth] FAIL — code: ${body['code']}, msg: ${body['msg']}');
      return LoginResult.fail(body['msg'] ?? '一键登录失败');
    } catch (e) {
      return LoginResult.fail('网络异常：$e');
    }
  }

  /// 手机验证码登录
  static Future<LoginResult> loginByMobileCode(
      String mobile, String code) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/auth/app/login/mobileCode');
      final response = await http.post(
        uri,
        headers: _jsonHeaders,
        body: jsonEncode({'mobile': mobile, 'code': code}),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && _isSuccess(body['code'])) {
        final data = body['data'] as Map<String, dynamic>?;
        if (data != null) {
          return LoginResult.ok(
            accessToken: data['access_token'] as String? ?? '',
            refreshToken: data['refresh_token'] as String? ?? '',
            expiresIn: _toInt(data['expires_in']) ?? 1800,
            userInfo: data['memberInfo'] as Map<String, dynamic>?,
          );
        }
      }
      return LoginResult.fail(body['msg'] ?? '登录失败');
    } catch (e) {
      return LoginResult.fail('网络异常：$e');
    }
  }

  /// 退出登录（同时通知后端注销 Token）
  static Future<bool> logout(String? token, {String? refreshToken}) async {
    try {
      if (token != null && token.isNotEmpty) {
        final uri = Uri.parse('${ApiConfig.baseUrl}/auth/app/logout');
        final headers = <String, String>{'Authorization': 'Bearer $token'};
        // 发送 Refresh Token 以便后端将其加入黑名单
        if (refreshToken != null && refreshToken.isNotEmpty) {
          headers['X-Refresh-Token'] = refreshToken;
        }
        await http.delete(uri, headers: headers).timeout(const Duration(seconds: 5));
      }
    } catch (e) {
      debugPrint('[AuthService] 后端登出请求失败（忽略）: $e');
    } finally {
      await clearLocalToken();
    }
    return true;
  }

  /// 刷新Token
  static Future<LoginResult> refreshToken(String? refreshToken) async {
    if (refreshToken == null || refreshToken.isEmpty) {
      return LoginResult.fail('Refresh Token 为空');
    }
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/auth/app/token/refresh');
      final response = await http.post(
        uri,
        headers: {'Authorization': 'Bearer $refreshToken'},
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && _isSuccess(body['code'])) {
        final data = body['data'] as Map<String, dynamic>?;
        if (data != null) {
          return LoginResult.ok(
            accessToken: data['access_token'] as String? ?? '',
            refreshToken: data['refresh_token'] as String? ?? '',
            expiresIn: _toInt(data['expires_in']) ?? 1800,
          );
        }
      }
      return LoginResult.fail(body['msg'] ?? '刷新失败');
    } catch (e) {
      return LoginResult.fail('网络异常：$e');
    }
  }

  // ==================== 本地持久化 ====================

  static Future<void> saveToken({
    required String accessToken,
    required String refreshToken,
    int expiresIn = 1800,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
    await prefs.setInt(
        '${_tokenKey}_expires_at',
        DateTime.now().millisecondsSinceEpoch + expiresIn * 1000);
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  static Future<bool> hasValidToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null || token.isEmpty) return false;
    final expiresAt = prefs.getInt('${_tokenKey}_expires_at');
    if (expiresAt != null &&
        DateTime.now().millisecondsSinceEpoch > expiresAt) {
      final refresh = prefs.getString(_refreshTokenKey);
      if (refresh != null && refresh.isNotEmpty) {
        final result = await refreshToken(refresh);
        if (result.isSuccess) {
          await saveToken(
            accessToken: result.accessToken!,
            refreshToken: result.refreshToken!,
            expiresIn: result.expiresIn ?? 1800,
          );
          return true;
        }
      }
      return false;
    }
    return true;
  }

  static Future<void> saveUserInfo(Map<String, dynamic> userInfo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(userInfo));
  }

  static Future<Map<String, dynamic>?> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_userKey);
    if (json == null) return null;
    return jsonDecode(json) as Map<String, dynamic>;
  }

  static Future<void> clearLocalToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove('${_tokenKey}_expires_at');
    await prefs.remove(_userKey);
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
    int expiresIn = 1800,
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

/// 微信登录结果（可能需绑定手机号）
class WechatLoginResult {
  final bool isSuccess;
  final bool needsBind;
  final String message;
  final String? cacheKey;
  final String? accessToken;
  final String? refreshToken;
  final int? expiresIn;
  final Map<String, dynamic>? userInfo;

  WechatLoginResult._({
    required this.isSuccess,
    required this.needsBind,
    required this.message,
    this.cacheKey,
    this.accessToken,
    this.refreshToken,
    this.expiresIn,
    this.userInfo,
  });

  factory WechatLoginResult.ok({
    required String accessToken,
    required String refreshToken,
    int expiresIn = 1800,
    Map<String, dynamic>? userInfo,
  }) =>
      WechatLoginResult._(
        isSuccess: true,
        needsBind: false,
        message: '登录成功',
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresIn: expiresIn,
        userInfo: userInfo,
      );

  factory WechatLoginResult.needsBind({required String cacheKey}) =>
      WechatLoginResult._(
        isSuccess: false,
        needsBind: true,
        message: 'bindMobile',
        cacheKey: cacheKey,
      );

  factory WechatLoginResult.fail(String message) =>
      WechatLoginResult._(
        isSuccess: false,
        needsBind: false,
        message: message,
      );
}
