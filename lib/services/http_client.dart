import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

/// 带 Token 自动刷新的 HTTP 客户端
///
/// 功能：
/// 1. 自动携带 Authorization 头
/// 2. 收到 401 时自动尝试刷新 Token 并重试请求
/// 3. 刷新失败时广播强制登出事件
/// 4. 并发请求只做一次刷新（锁机制）
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
    final response = await _client.get(url, headers: h);
    return _handleResponse(response, () => _client.get(url, headers: h));
  }

  Future<http.Response> post(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    final h = await _buildHeaders(headers);
    final response =
        await _client.post(url, headers: h, body: body, encoding: encoding);
    return _handleResponse(
        response, () => _client.post(url, headers: h, body: body, encoding: encoding));
  }

  Future<http.Response> put(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    final h = await _buildHeaders(headers);
    final response =
        await _client.put(url, headers: h, body: body, encoding: encoding);
    return _handleResponse(
        response, () => _client.put(url, headers: h, body: body, encoding: encoding));
  }

  Future<http.Response> delete(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    final h = await _buildHeaders(headers);
    final response =
        await _client.delete(url, headers: h, body: body, encoding: encoding);
    return _handleResponse(
        response, () => _client.delete(url, headers: h, body: body, encoding: encoding));
  }

  // ==================== 内部逻辑 ====================

  /// 构建请求头：合并自定义头 + Authorization
  Future<Map<String, String>> _buildHeaders(
      Map<String, String>? custom) async {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
    };
    if (custom != null) headers.addAll(custom);

    final token = await AuthService.getAccessToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// 处理响应：401 时尝试刷新 Token 并重试
  Future<http.Response> _handleResponse(
    http.Response response,
    Future<http.Response> Function() retry,
  ) async {
    // 非 401 直接返回
    if (response.statusCode != 401) return response;

    debugPrint('[AuthHttpClient] 收到 401，尝试刷新 Token...');

    // 如果已经有刷新进行中，等待它完成
    if (_isRefreshing) {
      final success = await _refreshCompleter!.future;
      if (success) {
        debugPrint('[AuthHttpClient] 等待刷新完成，重试请求');
        return retry();
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
          expiresIn: result.expiresIn ?? 7200,
        );
        _refreshCompleter!.complete(true);
        // 用新 Token 重试原始请求
        return retry();
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
