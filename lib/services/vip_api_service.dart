import 'package:flutter/foundation.dart';
import 'api_client.dart';

/// VIP 会员 API 服务
///
/// 对接后端 /app/vip/** 系列接口。
class VipApiService {
  static final ApiClient _api = ApiClient.instance;

  /// 获取 VIP 套餐列表
  static Future<VipListResult> getVipPlans() async {
    final res = await _api.get('/app/vip/vips');
    debugPrint('===== VIP套餐 API 返回 =====');
    debugPrint('isSuccess: ${res.isSuccess}');
    debugPrint('message: ${res.message}');
    debugPrint('data: ${res.data}');
    if (res.isSuccess) {
      final list = res.asList;
      debugPrint('套餐数量: ${list.length}');
      final plans = list
          .map((e) {
            final m = e as Map<String, dynamic>;
            debugPrint('  套餐: $m');
            return VipPlan.fromJson(m);
          })
          .toList();
      return VipListResult.ok(plans);
    }
    return VipListResult.fail(res.message);
  }
}

class VipPlan {
  final int id;
  final String name;
  final double price;
  final double originalPrice;
  final String? tag;
  final String? saveLabel;

  VipPlan({required this.id, required this.name, required this.price, required this.originalPrice, this.tag, this.saveLabel});

  factory VipPlan.fromJson(Map<String, dynamic> json) {
    return VipPlan(
      id: json['id'] as int? ?? 0,
      name: json['title'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      originalPrice: (json['orgPrice'] as num?)?.toDouble() ?? 0,
      tag: json['tag'] as String?,
      saveLabel: json['subtitle'] as String?,
    );
  }
}

class VipListResult {
  final bool isSuccess;
  final String message;
  final List<VipPlan> plans;

  VipListResult._({required this.isSuccess, required this.message, required this.plans});

  factory VipListResult.ok(List<VipPlan> plans) =>
      VipListResult._(isSuccess: true, message: '成功', plans: plans);

  factory VipListResult.fail([String? msg]) =>
      VipListResult._(isSuccess: false, message: msg ?? '请求失败', plans: []);
}
