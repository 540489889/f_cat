import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

/// 带 Token 自动刷新的 HTTP 客户端
///
/// 功能：
/// 1. 自动携带 Authorization 头
/// 2. 发送前主动检查 Token 是否即将过期，提前刷新（避免无效请求）
/// 3. 收到 401 时自动刷新 Token 并用新 Token 重试请求
/// 4. 刷新失败时广播强制登出事件
/// 5. 并发请求只做一次刷新（锁机制）
class AuthHttpClient {
  AuthHttpClient._();

  static final AuthHttpClient instance = AuthHttpClient._();

  final http.Client _client = http.Client();

  /// 刷新锁：防止多个并发请求同时刷新 Token
  bool _isRefreshing = false;
  Completer<bool>? _refreshCompleter;

  /// 强制登出事件流（refresh token 过期时触发）
  final StreamController<void> _forceLogoutController =
      StreamController<void>.broadcast();

  Stream<void> get forceLogoutStream => _forceLogoutController.stream;

  /// 释放资源
  void dispose() {
    _client.close();
    _forceLogoutController.close();
  }

  // ==================== 公开 HTTP 方法 ====================

  Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    final h = await _buildHeaders(headers);
    if (h == null) return _unauthorizedResponse(url);
    final response = await _client.get(url, headers: h);
    return _handleResponse(response, url, headers, (u, hdrs) => _client.get(u, headers: hdrs));
  }

  Future<http.Response> post(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    final h = await _buildHeaders(headers);
    if (h == null) return _unauthorizedResponse(url);
    final response =
        await _client.post(url, headers: h, body: body, encoding: encoding);
    return _handleResponse(response, url, headers,
        (u, hdrs) => _client.post(u, headers: hdrs, body: body, encoding: encoding));
  }

  Future<http.Response> put(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    final h = await _buildHeaders(headers);
    if (h == null) return _unauthorizedResponse(url);
    final response =
        await _client.put(url, headers: h, body: body, encoding: encoding);
    return _handleResponse(response, url, headers,
        (u, hdrs) => _client.put(u, headers: hdrs, body: body, encoding: encoding));
  }

  Future<http.Response> delete(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    final h = await _buildHeaders(headers);
    if (h == null) return _unauthorizedResponse(url);
    final response =
        await _client.delete(url, headers: h, body: body, encoding: encoding);
    return _handleResponse(response, url, headers,
        (u, hdrs) => _client.delete(u, headers: hdrs, body: body, encoding: encoding));
  }

  // ==================== 内部逻辑 ====================

  /// Token 提前刷新时间窗口（秒）：过期前 60 秒就开始刷新，避免时钟偏差
  static const int _refreshBufferSeconds = 60;

  /// 当 Token 失效且无法刷新时，返回一个模拟的 401 响应
  http.Response _unauthorizedResponse(Uri url) {
    debugPrint('[AuthHttpClient] Token 已失效且刷新失败，返回模拟401: $url');
    return http.Response(
      '{"code":401,"msg":"登录已过期，请重新登录"}',
      401,
      headers: {'content-type': 'application/json'},
    );
  }

  /// 构建请求头：合并自定义头 + Authorization
  /// 主动检查 Token 是否即将过期，过期则在发送前刷新
  /// 如果 Token 刷新失败，返回 null 表示无法发送请求
  Future<Map<String, String>?> _buildHeaders(
      Map<String, String>? custom) async {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
    };
    if (custom != null) headers.addAll(custom);

    // 检查 Token 是否过期或即将过期，过期则自动刷新
    final valid = await _ensureValidToken();
    if (!valid) return null; // token 失效，不应发送请求

    final token = await AuthService.getAccessToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// 确保本地 Token 有效（过期或即将过期时主动刷新）
  /// 返回 true = token 有效可继续请求，false = token 失效需登出
  Future<bool> _ensureValidToken() async {
    // 如果已经有刷新在进行，跳过（避免重复刷新）
    if (_isRefreshing) return true;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null || token.isEmpty) return true; // 无 token，跳过检查

    final expiresAt = prefs.getInt('access_token_expires_at');
    if (expiresAt == null) return true;

    // 提前 _refreshBufferSeconds 秒刷新，防止客户端/服务端时钟偏差
    final bufferMs = _refreshBufferSeconds * 1000;
    if (DateTime.now().millisecondsSinceEpoch + bufferMs > expiresAt) {
      debugPrint('[AuthHttpClient] Token 即将过期，主动刷新...');
      _isRefreshing = true;
      try {
        final refresh = prefs.getString('refresh_token');
        if (refresh == null || refresh.isEmpty) {
          debugPrint('[AuthHttpClient] Refresh Token 为空，触发强制登出');
          _forceLogoutController.add(null);
          return false;
        }
        final result = await AuthService.refreshToken(refresh);
        if (result.isSuccess) {
          debugPrint('[AuthHttpClient] Token 主动刷新成功');
          await AuthService.saveToken(
            accessToken: result.accessToken!,
            refreshToken: result.refreshToken!,
            expiresIn: result.expiresIn ?? 1800,
          );
          return true;
        } else {
          debugPrint('[AuthHttpClient] Token 主动刷新失败: ${result.message}，触发强制登出');
          _forceLogoutController.add(null);
          return false;
        }
      } catch (e) {
        debugPrint('[AuthHttpClient] Token 主动刷新异常: $e，触发强制登出');
        _forceLogoutController.add(null);
        return false;
      } finally {
        _isRefreshing = false;
      }
    }
    return true; // token 未过期，可继续使用
  }

  /// 处理响应：401 时尝试刷新 Token 并用新 Token 重试
  Future<http.Response> _handleResponse(
    http.Response response,
    Uri url,
    Map<String, String>? customHeaders,
    Future<http.Response> Function(Uri, Map<String, String>) doRequest,
  ) async {
    // 非 401 直接返回
    if (response.statusCode != 401) return response;

    debugPrint('[AuthHttpClient] 收到 401，尝试刷新 Token...');

    // 如果已经有刷新进行中，等待它完成
    if (_isRefreshing) {
      final success = await _refreshCompleter!.future;
      if (success) {
        debugPrint('[AuthHttpClient] 等待刷新完成，用新 Token 重试请求');
        final newHeaders = await _buildHeaders(customHeaders);
        if (newHeaders == null) return response;
        return doRequest(url, newHeaders);
      }
      // 刷新失败，直接返回 401
      return response;
    }

    // 开始刷新
    _isRefreshing = true;
    _refreshCompleter = Completer<bool>();

    try {
      final refreshToken = await AuthService.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        debugPrint('[AuthHttpClient] Refresh Token 为空，触发强制登出');
        _forceLogoutController.add(null);
        _refreshCompleter!.complete(false);
        return response;
      }

      final result = await AuthService.refreshToken(refreshToken);

      if (result.isSuccess) {
        debugPrint('[AuthHttpClient] Token 刷新成功，保存新 Token');
        await AuthService.saveToken(
          accessToken: result.accessToken!,
          refreshToken: result.refreshToken!,
          expiresIn: result.expiresIn ?? 1800,
        );
        _refreshCompleter!.complete(true);
        // 用新 Token 重建请求头并重试
        final newHeaders = await _buildHeaders(customHeaders);
        if (newHeaders == null) return response;
        return doRequest(url, newHeaders);
      } else {
        debugPrint('[AuthHttpClient] Refresh Token 过期或无效，触发强制登出');
        _forceLogoutController.add(null);
        _refreshCompleter!.complete(false);
        return response;
      }
    } catch (e) {
      debugPrint('[AuthHttpClient] 刷新 Token 异常: $e');
      _forceLogoutController.add(null);
      _refreshCompleter!.complete(false);
      return response;
    } finally {
      _isRefreshing = false;
      _refreshCompleter = null;
    }
  }
}
