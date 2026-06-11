import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'http_client.dart';

/// 统一 API 请求客户端
///
/// 封装了：
/// - 自动拼接 baseUrl
/// - JSON 解析与统一错误处理
/// - 支持带 Auth 请求（通过 AuthHttpClient 自动刷新 Token）
/// - 支持无 Auth 请求（登录/短信等接口）
///
/// 用法：
/// ```dart
/// final res = await ApiClient.instance.get('/app/home/list');
/// if (res.isSuccess) {
///   final list = (res.data as List).map((e) => HomeInfo.fromJson(e)).toList();
/// }
/// ```
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  final AuthHttpClient _authHttp = AuthHttpClient.instance;
  final http.Client _rawHttp = http.Client();

  Map<String, String> get _jsonHeaders =>
      {'Content-Type': 'application/json; charset=utf-8'};

  Uri _buildUri(String path, [Map<String, dynamic>? queryParams]) {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(queryParameters:
          queryParams.map((k, v) => MapEntry(k, v.toString())));
    }
    return uri;
  }

  // ==================== 带 Auth 的请求（自动携带 Token、自动刷新） ====================

  Future<ApiResponse> get(String path,
      {Map<String, dynamic>? queryParams}) async {
    try {
      final uri = _buildUri(path, queryParams);
      final response = await _authHttp.get(uri);
      return _parseResponse(response);
    } catch (e) {
      return ApiResponse.fail('网络异常：$e');
    }
  }

  Future<ApiResponse> post(String path,
      {Map<String, dynamic>? body}) async {
    try {
      final uri = _buildUri(path);
      final response = await _authHttp.post(
        uri,
        body: body != null ? jsonEncode(body) : null,
      );
      return _parseResponse(response);
    } catch (e) {
      return ApiResponse.fail('网络异常：$e');
    }
  }

  Future<ApiResponse> put(String path,
      {Map<String, dynamic>? body,
      Map<String, dynamic>? queryParams}) async {
    try {
      final uri = _buildUri(path, queryParams);
      final response = await _authHttp.put(
        uri,
        body: body != null ? jsonEncode(body) : null,
      );
      return _parseResponse(response);
    } catch (e) {
      return ApiResponse.fail('网络异常：$e');
    }
  }

  Future<ApiResponse> delete(String path) async {
    try {
      final uri = _buildUri(path);
      final response = await _authHttp.delete(uri);
      return _parseResponse(response);
    } catch (e) {
      return ApiResponse.fail('网络异常：$e');
    }
  }

  // ==================== 无 Auth 请求（登录/短信/刷新 Token 等接口） ====================

  Future<ApiResponse> rawGet(String path,
      {Map<String, String>? headers,
      Map<String, dynamic>? queryParams}) async {
    try {
      final uri = _buildUri(path, queryParams);
      final response = await _rawHttp.get(
        uri,
        headers: {..._jsonHeaders, ...?headers},
      );
      return _parseResponse(response);
    } catch (e) {
      return ApiResponse.fail('网络异常：$e');
    }
  }

  Future<ApiResponse> rawPost(String path,
      {Map<String, String>? headers,
      Map<String, dynamic>? queryParams,
      Object? body}) async {
    try {
      final uri = _buildUri(path, queryParams);
      final response = await _rawHttp.post(
        uri,
        headers: {..._jsonHeaders, ...?headers},
        body: body,
      );
      return _parseResponse(response);
    } catch (e) {
      return ApiResponse.fail('网络异常：$e');
    }
  }

  Future<ApiResponse> rawDelete(String path,
      {Map<String, String>? headers}) async {
    try {
      final uri = _buildUri(path);
      final response = await _rawHttp.delete(
        uri,
        headers: {..._jsonHeaders, ...?headers},
      );
      return _parseResponse(response);
    } catch (e) {
      return ApiResponse.fail('网络异常：$e');
    }
  }

  // ==================== 内部 ====================

  ApiResponse _parseResponse(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final code = body['code'] as int? ?? 500;
    final msg = body['msg'] as String? ?? '';
    if (response.statusCode == 200 && code == 200) {
      return ApiResponse.ok(body['data'], msg);
    }
    return ApiResponse.fail(msg);
  }

  /// 释放资源
  void dispose() {
    _rawHttp.close();
  }
}

/// 统一 API 响应
class ApiResponse {
  final bool isSuccess;
  final String message;
  final dynamic data;

  ApiResponse._({required this.isSuccess, required this.message, this.data});

  factory ApiResponse.ok(dynamic data, [String? msg]) =>
      ApiResponse._(isSuccess: true, message: msg ?? '成功', data: data);

  factory ApiResponse.fail([String? msg]) =>
      ApiResponse._(isSuccess: false, message: msg ?? '请求失败');

  /// 判断 data 是否为 Map
  bool get isMap => data is Map<String, dynamic>;

  /// 将 data 强转为 Map（安全，失败返回空 Map）
  Map<String, dynamic> get asMap =>
      (data is Map<String, dynamic>) ? data as Map<String, dynamic> : {};

  /// 将 data 强转为 List（安全，失败返回空 List）
  List<dynamic> get asList => (data is List<dynamic>) ? data as List<dynamic> : [];
}
