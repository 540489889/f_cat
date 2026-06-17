import 'package:flutter/foundation.dart';
import 'api_client.dart';

/// 订单 API 服务
///
/// 对接后端 /app/order/** 系列接口。
class OrderApiService {
  static final ApiClient _api = ApiClient.instance;

  /// 创建订单
  static Future<OrderResult> createOrder({
    required int deviceId,
    required int quantity,
    required int addressId,
    String? remark,
  }) async {
    final body = {
      'deviceId': deviceId,
      'num': quantity,
      'addressId': addressId,
      if (remark != null && remark.isNotEmpty) 'remark': remark,
    };
    debugPrint('===== 创建订单 请求参数 =====');
    debugPrint('$body');
    final res = await _api.post('/app/order/create', body: body);
    debugPrint('===== 创建订单 API 返回 =====');
    debugPrint('isSuccess: ${res.isSuccess}');
    debugPrint('message: ${res.message}');
    debugPrint('data: ${res.data}');
    if (res.isSuccess) {
      final map = res.asMap;
      return OrderResult.ok(
        orderSn: map['sn'] as String? ?? '',
        totalPrice: (map['totalPrice'] as num?)?.toDouble() ?? 0,
        price: (map['price'] as num?)?.toDouble() ?? 0,
      );
    }
    debugPrint('===== 创建订单失败 =====');
    return OrderResult.fail(res.message);
  }
}

/// 订单结果
class OrderResult {
  final bool isSuccess;
  final String message;
  final String orderSn;
  final double totalPrice;
  final double price;

  OrderResult._({
    required this.isSuccess,
    required this.message,
    this.orderSn = '',
    this.totalPrice = 0,
    this.price = 0,
  });

  factory OrderResult.ok({String orderSn = '', double totalPrice = 0, double price = 0}) =>
      OrderResult._(isSuccess: true, message: '下单成功', orderSn: orderSn, totalPrice: totalPrice, price: price);

  factory OrderResult.fail([String? msg]) =>
      OrderResult._(isSuccess: false, message: msg ?? '下单失败');
}
