import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/home_info.dart';
import 'http_client.dart';

/// 家庭管理 API 服务
///
/// 对接后端 /app/home/** 系列接口（创建、列表、详情等）。
/// 所有请求通过 AuthHttpClient 统一转发，自动携带 Authorization 头
/// 并在 Token 过期时自动刷新。
class HomeApiService {
  static const String _baseUrl = 'http://192.168.1.135:8080';

  static AuthHttpClient get _http => AuthHttpClient.instance;

  // ==================== 家庭管理 ====================

  /// 获取我的家庭列表
  static Future<HomeListResult> getMyHomes() async {
    try {
      final uri = Uri.parse('$_baseUrl/app/home/list');
      final response = await _http.get(uri);
      return _parseHomeList(response);
    } catch (e) {
      return HomeListResult.fail('网络异常：$e');
    }
  }

  /// 创建家庭
  static Future<CreateHomeResult> createHome({
    required String name,
    String? avatar,
  }) async {
    try {
      final body = <String, dynamic>{'name': name};
      if (avatar != null) body['avatar'] = avatar;
      final uri = Uri.parse('$_baseUrl/app/home/create');
      final response = await _http.post(
        uri,
        body: jsonEncode(body),
      );
      return _parseCreateHome(response);
    } catch (e) {
      return CreateHomeResult.fail('网络异常：$e');
    }
  }

  /// 获取家庭详情
  static Future<HomeDetailResult> getHomeDetail({
    required int homeId,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/app/home/detail/$homeId');
      final response = await _http.get(uri);
      return _parseHomeDetail(response);
    } catch (e) {
      return HomeDetailResult.fail('网络异常：$e');
    }
  }

  /// 修改家庭信息
  static Future<ApiResultStr> updateHome({
    required int homeId,
    String? name,
    String? avatar,
  }) async {
    try {
      final params = <String, String>{'homeId': '$homeId'};
      if (name != null) params['name'] = name;
      if (avatar != null) params['avatar'] = avatar;
      final uri = Uri.parse('$_baseUrl/app/home/update')
          .replace(queryParameters: params);
      final response = await _http.put(uri);
      return _parseApiResult(response);
    } catch (e) {
      return ApiResultStr.fail('网络异常：$e');
    }
  }

  /// 解散家庭
  static Future<ApiResultStr> dissolveHome({
    required int homeId,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/app/home/dissolve/$homeId');
      final response = await _http.delete(uri);
      return _parseApiResult(response);
    } catch (e) {
      return ApiResultStr.fail('网络异常：$e');
    }
  }

  // ==================== 内部解析 ====================

  static HomeListResult _parseHomeList(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final code = body['code'] as int? ?? 500;
    if (response.statusCode == 200 && code == 200) {
      final data = body['data'] as List<dynamic>?;
      final homes = data
              ?.map(
                  (e) => HomeInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      return HomeListResult.ok(homes);
    }
    return HomeListResult.fail(body['msg'] as String? ?? '获取家庭列表失败');
  }

  static CreateHomeResult _parseCreateHome(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final code = body['code'] as int? ?? 500;
    if (response.statusCode == 200 && code == 200) {
      final data = body['data'] as Map<String, dynamic>?;
      if (data != null) {
        return CreateHomeResult.ok(
          homeId: data['id'] as int? ?? 0,
          name: data['name'] as String? ?? '',
          inviteCode: data['inviteCode'] as String?,
        );
      }
      return CreateHomeResult.fail('创建成功但返回数据为空');
    }
    return CreateHomeResult.fail(body['msg'] as String? ?? '创建家庭失败');
  }

  static HomeDetailResult _parseHomeDetail(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final code = body['code'] as int? ?? 500;
    if (response.statusCode == 200 && code == 200) {
      final data = body['data'] as Map<String, dynamic>?;
      if (data != null) {
        return HomeDetailResult.ok(data);
      }
      return HomeDetailResult.fail('家庭详情为空');
    }
    return HomeDetailResult.fail(body['msg'] as String? ?? '获取详情失败');
  }

  static ApiResultStr _parseApiResult(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final code = body['code'] as int? ?? 500;
    final msg = body['msg'] as String? ?? '操作失败';
    if (response.statusCode == 200 && code == 200) {
      return ApiResultStr.ok(msg);
    }
    return ApiResultStr.fail(msg);
  }
}

// ==================== 结果封装 ====================

class HomeListResult {
  final bool isSuccess;
  final String message;
  final List<HomeInfo> homes;
  HomeListResult._({
    required this.isSuccess,
    required this.message,
    this.homes = const [],
  });
  factory HomeListResult.ok(List<HomeInfo> homes, [String? msg]) =>
      HomeListResult._(isSuccess: true, message: msg ?? '成功', homes: homes);
  factory HomeListResult.fail(String msg) =>
      HomeListResult._(isSuccess: false, message: msg);
}

class CreateHomeResult {
  final bool isSuccess;
  final String message;
  final int homeId;
  final String name;
  final String? inviteCode;
  CreateHomeResult._({
    required this.isSuccess,
    required this.message,
    this.homeId = 0,
    this.name = '',
    this.inviteCode,
  });
  factory CreateHomeResult.ok({
    required int homeId,
    required String name,
    String? inviteCode,
  }) =>
      CreateHomeResult._(
        isSuccess: true,
        message: '创建成功',
        homeId: homeId,
        name: name,
        inviteCode: inviteCode,
      );
  factory CreateHomeResult.fail(String msg) =>
      CreateHomeResult._(isSuccess: false, message: msg);
}

class HomeDetailResult {
  final bool isSuccess;
  final String message;
  final Map<String, dynamic>? detail;
  HomeDetailResult._({required this.isSuccess, required this.message, this.detail});
  factory HomeDetailResult.ok(Map<String, dynamic> detail, [String? msg]) =>
      HomeDetailResult._(isSuccess: true, message: msg ?? '成功', detail: detail);
  factory HomeDetailResult.fail(String msg) =>
      HomeDetailResult._(isSuccess: false, message: msg);
}

class ApiResultStr {
  final bool isSuccess;
  final String message;
  ApiResultStr._({required this.isSuccess, required this.message});
  factory ApiResultStr.ok([String? msg]) =>
      ApiResultStr._(isSuccess: true, message: msg ?? '操作成功');
  factory ApiResultStr.fail(String msg) =>
      ApiResultStr._(isSuccess: false, message: msg);
}
