import '../models/home_info.dart';
import 'api_client.dart';

/// 家庭管理 API 服务
///
/// 对接后端 /app/home/** 系列接口（创建、列表、详情等）。
/// 所有请求通过 ApiClient（底层 AuthHttpClient）统一转发，自动携带 Authorization 头
/// 并在 Token 过期时自动刷新。
class HomeApiService {
  static final ApiClient _api = ApiClient.instance;

  // ==================== 家庭管理 ====================

  /// 获取我的家庭列表
  static Future<HomeListResult> getMyHomes() async {
    final res = await _api.get('/app/home/list');
    if (res.isSuccess) {
      final list = res.asList;
      final homes = list
          .map((e) => HomeInfo.fromJson(e as Map<String, dynamic>))
          .toList();
      return HomeListResult.ok(homes);
    }
    return HomeListResult.fail(res.message);
  }

  /// 创建家庭
  static Future<CreateHomeResult> createHome({
    required String name,
    String? avatar,
  }) async {
    final body = <String, dynamic>{'name': name};
    if (avatar != null) body['avatar'] = avatar;
    final res = await _api.post('/app/home/create', body: body);
    if (res.isSuccess && res.isMap) {
      final data = res.asMap;
      return CreateHomeResult.ok(
        homeId: data['id'] as int? ?? 0,
        name: data['name'] as String? ?? '',
        inviteCode: data['inviteCode'] as String?,
      );
    }
    return CreateHomeResult.fail(res.message);
  }

  /// 获取家庭详情
  static Future<HomeDetailResult> getHomeDetail({
    required int homeId,
  }) async {
    final res = await _api.get('/app/home/detail/$homeId');
    if (res.isSuccess && res.isMap) {
      return HomeDetailResult.ok(res.asMap);
    }
    return HomeDetailResult.fail(res.message);
  }

  /// 修改家庭信息
  static Future<ApiResultStr> updateHome({
    required int homeId,
    required String name,
    required String avatar,
  }) async {
    final body = <String, dynamic>{
      'homeId': homeId,
      'name': name,
      'avatar': avatar,
    };
    final res = await _api.post('/app/home/update', body: body);
    if (res.isSuccess) return ApiResultStr.ok(res.message);
    return ApiResultStr.fail(res.message);
  }

  /// 邀请成员
  static Future<ApiResultStr> inviteMember({
    required int homeId,
    required String mobile,
  }) async {
    final body = <String, dynamic>{
      'homeId': homeId,
      'mobile': mobile,
    };
    final res = await _api.post('/app/home/member/invite', body: body);
    if (res.isSuccess) return ApiResultStr.ok(res.message);
    return ApiResultStr.fail(res.message);
  }

  /// 解散家庭
  static Future<ApiResultStr> dissolveHome({
    required int homeId,
  }) async {
    final res = await _api.delete('/app/home/dissolve/$homeId');
    if (res.isSuccess) return ApiResultStr.ok(res.message);
    return ApiResultStr.fail(res.message);
  }

  /// 获取家庭信息（/app/home/info POST）
  /// 返回 data Map，包含 id, name, avatar, inviteCode, ownerId, maxMembers 等
  static Future<HomeDetailResult> getHomeInfo() async {
    final res = await _api.post('/app/home/info');
    if (res.isSuccess && res.isMap) {
      return HomeDetailResult.ok(res.asMap);
    }
    return HomeDetailResult.fail(res.message);
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
  HomeDetailResult._(
      {required this.isSuccess, required this.message, this.detail});
  factory HomeDetailResult.ok(Map<String, dynamic> detail, [String? msg]) =>
      HomeDetailResult._(
          isSuccess: true, message: msg ?? '成功', detail: detail);
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
