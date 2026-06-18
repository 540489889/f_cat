import 'package:flutter/foundation.dart';
import 'api_client.dart';

/// 宠物分类 API 服务
///
/// 对接后端 /app/cates/** 系列接口。
class CatesApiService {
  static final ApiClient _api = ApiClient.instance;

  /// 获取品种分类树
  /// mark: 'cat' 或 'dog'
  static Future<CatesResult> getCatesTree({required String mark}) async {
    debugPrint('===== 品种分类 请求参数 =====');
    debugPrint('mark: $mark');
    final res = await _api.get('/app/cates/data/$mark');
    debugPrint('===== 品种分类 API 返回 =====');
    debugPrint('isSuccess: ${res.isSuccess}');
    debugPrint('message: ${res.message}');
    debugPrint('data: ${res.data}');
    if (res.isSuccess) {
      final map = res.asMap;
      return CatesResult.ok(data: map);
    }
    return CatesResult.fail(res.message);
  }
}

/// 分类结果
class CatesResult {
  final bool isSuccess;
  final String message;
  final Map<String, dynamic>? data;

  CatesResult._({required this.isSuccess, required this.message, this.data});

  factory CatesResult.ok({Map<String, dynamic>? data, String? msg}) =>
      CatesResult._(isSuccess: true, message: msg ?? '成功', data: data);

  factory CatesResult.fail([String? msg]) =>
      CatesResult._(isSuccess: false, message: msg ?? '请求失败');
}
