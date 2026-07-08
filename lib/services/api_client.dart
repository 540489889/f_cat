import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'http_client.dart';
import 'auth_service.dart';

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
      {Map<String, dynamic>? queryParams,
      Map<String, dynamic>? body}) async {
    try {
      final uri = _buildUri(path, queryParams);
      final response = body != null
          ? await _authHttp.getWithBody(uri, body: jsonEncode(body))
          : await _authHttp.get(uri);
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

  /// 上传文件（multipart/form-data）
  /// [fileField] 后端接收的字段名，一般为 'file'
  Future<ApiResponse> uploadFile(String path, {
    required String filePath,
    String fileField = 'file',
    Map<String, String>? extraFields,
  }) async {
    try {
      final base = Uri.parse(ApiConfig.baseUrl);
      final uri = base.replace(path: path);
      debugPrint('[ApiClient.upload] url=${uri.toString()}, filePath=$filePath');
      final token = await AuthService.getAccessToken();
      final request = http.MultipartRequest('POST', uri);
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.files.add(await http.MultipartFile.fromPath(fileField, filePath));
      if (extraFields != null) {
        request.fields.addAll(extraFields);
      }
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      debugPrint('[ApiClient.upload] status=${response.statusCode}');
      return _parseResponse(response);
    } catch (e) {
      debugPrint('[ApiClient.upload] error: $e');
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

  /// 分行打印长文本，避免 debugPrint 默认截断
  static void _printFull(String prefix, String text) {
    debugPrint('$prefix status=${text.length} chars');
    const chunkSize = 800;
    for (int i = 0; i < text.length; i += chunkSize) {
      final end = (i + chunkSize < text.length) ? i + chunkSize : text.length;
      debugPrint(text.substring(i, end));
    }
  }

  /// 安全解析响应体，兼容非 JSON、空响应等异常情况
  ApiResponse _parseResponse(http.Response response) {
    // 打印完整响应（调试用），分行避免截断
    _printFull('[API]', 'status=${response.statusCode}, body=${response.body}');

    // 非 200 HTTP 状态码
    if (response.statusCode != 200) {
      final errMsg = _safeDecodeMsg(response.body) ?? '请求失败(${response.statusCode})';
      return ApiResponse.fail(errMsg);
    }

    // 空响应体
    final bodyStr = response.body;
    if (bodyStr.isEmpty) {
      return ApiResponse.fail('服务器返回空响应');
    }

    // JSON 解析
    try {
      final body = jsonDecode(bodyStr) as Map<String, dynamic>;
      final code = body['code'];
      final msg = body['msg'] as String? ?? '';
      if (code is int && code == 200 || code is String && code == '200') {
        return ApiResponse.ok(body['data'], msg);
      }
      return ApiResponse.fail(msg);
    } on FormatException catch (e) {
      return ApiResponse.fail('响应格式异常：${e.message}');
    } on TypeError {
      return ApiResponse.fail('响应数据类型异常');
    }
  }

  /// 尝试从非 JSON 响应体中提取错误信息
  String? _safeDecodeMsg(String body) {
    if (body.isEmpty) return null;
    try {
      final map = jsonDecode(body) as Map<String, dynamic>;
      return map['msg'] as String?;
    } catch (_) {
      // 截取前200字符防止 HTML/长文本撑爆 UI
      return body.length > 200 ? '${body.substring(0, 200)}...' : body;
    }
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
