import 'package:flutter/foundation.dart';
import 'api_client.dart';

/// 宠物信息 API 服务
///
/// 对接后端 /app/pet/** 系列接口。
class PetApiService {
  static final ApiClient _api = ApiClient.instance;

  /// 获取默认宠物信息
  static Future<void> getDefaultPet() async {
    debugPrint('===== 获取默认宠物 =====');
    final res = await _api.get('/app/pet/default');
    debugPrint('===== 默认宠物 API 返回 =====');
    debugPrint('isSuccess: ${res.isSuccess}');
    debugPrint('message: ${res.message}');
    debugPrint('data: ${res.data}');
  }

  /// 添加宠物
  static Future<PetResult> addPet({
    required String nickname,
    required String type,
    required String variety,
    required String sex,
    required String sterilization,
    required String birthday,
    required double weight,
    String? headimg,
    String? imgs,
  }) async {
    final body = <String, dynamic>{
      'nickname': nickname,
      'type': type,
      'variety': variety,
      'sex': sex,
      'sterilization': sterilization,
      'birthday': birthday,
      'weight': weight,
      'headimg': headimg ?? '',
      'imgs': imgs ?? '',
    };
    debugPrint('===== 添加宠物 请求参数 =====');
    debugPrint('$body');
    final res = await _api.post('/app/pet/add', body: body);
    debugPrint('===== 添加宠物 API 返回 =====');
    debugPrint('isSuccess: ${res.isSuccess}');
    debugPrint('message: ${res.message}');
    debugPrint('data: ${res.data}');
    if (res.isSuccess) {
      return PetResult.ok(res.message);
    }
    return PetResult.fail(res.message);
  }
}

class PetResult {
  final bool isSuccess;
  final String message;

  PetResult._({required this.isSuccess, required this.message});

  factory PetResult.ok([String? msg]) =>
      PetResult._(isSuccess: true, message: msg ?? '添加成功');

  factory PetResult.fail([String? msg]) =>
      PetResult._(isSuccess: false, message: msg ?? '添加失败');
}
