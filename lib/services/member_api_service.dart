import 'package:flutter/foundation.dart';
import 'api_client.dart';
import 'auth_service.dart';

/// 会员 API 服务
///
/// 对接后端 /app/member/** 系列接口。
class MemberApiService {
  static final ApiClient _api = ApiClient.instance;

  /// 获取会员信息
  static Future<MemberResult> getMemberInfo() async {
    final res = await _api.get('/app/member/info');
    debugPrint('===== 会员信息 API 返回 =====');
    debugPrint('isSuccess: ${res.isSuccess}');
    debugPrint('message: ${res.message}');
    debugPrint('data: ${res.data}');
    if (res.isSuccess) {
      final map = res.asMap;
      // 更新本地用户信息
      await AuthService.saveUserInfo(map);
      return MemberResult.ok(map);
    }
    return MemberResult.fail(res.message);
  }
}

class MemberResult {
  final bool isSuccess;
  final String message;
  final Map<String, dynamic>? data;

  MemberResult._({required this.isSuccess, required this.message, this.data});

  factory MemberResult.ok(Map<String, dynamic> data) =>
      MemberResult._(isSuccess: true, message: '成功', data: data);

  factory MemberResult.fail([String? msg]) =>
      MemberResult._(isSuccess: false, message: msg ?? '请求失败');
}
