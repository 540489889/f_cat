import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'api_client.dart';

/// 订单 API 服务
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
        orderId: map['id'] as int? ?? 0,
        orderSn: map['sn'] as String? ?? '',
        totalPrice: (map['totalPrice'] as num?)?.toDouble() ?? 0,
        price: (map['price'] as num?)?.toDouble() ?? 0,
        expireTime: DateTime.tryParse(map['expireTime'] as String? ?? ''),
      );
    }
    return OrderResult.fail(res.message);
  }

  /// 支付订单
  static Future<BasePayResult> payOrder({
    required int orderId,
    required String payType,
  }) async {
    debugPrint('===== 支付订单 请求参数 =====');
    debugPrint('orderId: $orderId, payType: $payType');
    final res = await _api.post('/app/order/pay?orderId=$orderId&payType=$payType');
    debugPrint('===== 支付订单 API 返回 =====');
    debugPrint('isSuccess: ${res.isSuccess}');
    debugPrint('message: ${res.message}');
    debugPrint('data: ${res.data}');
    if (res.isSuccess) {
      return BasePayResult.ok(payData: res.data?.toString() ?? '', msg: res.message);
    }
    return BasePayResult.fail(res.message);
  }

  /// 取消订单
  static Future<BasePayResult> cancelOrder({required int orderId}) async {
    debugPrint('===== 取消订单 请求参数 =====');
    debugPrint('orderId: $orderId');
    final res = await _api.post('/app/order/cancel/$orderId');
    debugPrint('===== 取消订单 API 返回 =====');
    debugPrint('isSuccess: ${res.isSuccess}');
    debugPrint('message: ${res.message}');
    debugPrint('data: ${res.data}');
    if (res.isSuccess) {
      return BasePayResult.ok(msg: '订单已取消');
    }
    return BasePayResult.fail(res.message);
  }

  /// 获取订单列表
  static Future<OrderListResult> getOrderList({
    int pageNum = 1,
    int pageSize = 10,
    int? status,
  }) async {
    final params = <String, dynamic>{'pageNum': pageNum, 'pageSize': pageSize};
    if (status != null) params['status'] = status;
    debugPrint('===== 订单列表 请求参数 =====');
    debugPrint('$params');
    final res = await _api.get('/app/order/list', queryParams: params);
    debugPrint('===== 订单列表 API 返回 =====');
    debugPrint('isSuccess: ${res.isSuccess}');
    debugPrint('data: ${res.data}');
    if (res.isSuccess) {
      final map = res.asMap;
      final records = (map['records'] as List<dynamic>?)
              ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      return OrderListResult.ok(records, map['total'] as int? ?? 0);
    }
    return OrderListResult.fail(res.message);
  }
}

/// 订单结果
class OrderResult {
  final bool isSuccess;
  final String message;
  final int orderId;
  final String orderSn;
  final double totalPrice;
  final double price;
  final DateTime? expireTime;

  OrderResult._({
    required this.isSuccess,
    required this.message,
    this.orderId = 0,
    this.orderSn = '',
    this.totalPrice = 0,
    this.price = 0,
    this.expireTime,
  });

  factory OrderResult.ok({int orderId = 0, String orderSn = '', double totalPrice = 0, double price = 0, DateTime? expireTime}) =>
      OrderResult._(isSuccess: true, message: '下单成功', orderId: orderId, orderSn: orderSn, totalPrice: totalPrice, price: price, expireTime: expireTime);

  factory OrderResult.fail([String? msg]) =>
      OrderResult._(isSuccess: false, message: msg ?? '下单失败');
}

/// 基础支付结果
class BasePayResult {
  final bool isSuccess;
  final String message;
  final String payData;

  BasePayResult._({required this.isSuccess, required this.message, this.payData = ''});

  factory BasePayResult.ok({String payData = '', String? msg}) =>
      BasePayResult._(isSuccess: true, message: msg ?? '支付成功', payData: payData);

  factory BasePayResult.fail([String? msg]) =>
      BasePayResult._(isSuccess: false, message: msg ?? '支付失败');
}

/// 订单列表项
class OrderItem {
  final int id;
  final String sn;
  final String? title;
  final double price;
  final double totalPrice;
  final int quantity;
  final int? status;
  final String? createTime;
  final String? image;
  final String? model;
  final String? subtitle;
  final int deviceId;

  OrderItem({
    required this.id,
    required this.sn,
    this.title,
    required this.price,
    required this.totalPrice,
    this.quantity = 1,
    this.status,
    this.createTime,
    this.image,
    this.model,
    this.subtitle,
    this.deviceId = 0,
  });

  String get statusLabel {
    switch (status) {
      case -1: return '已取消';
      case 0: return '待付款';
      case 1: return '已付款';
      case 2: return '已发货';
      case 3: return '已完成';
      case 4: return '售后退货';
      default: return '未知';
    }
  }

  Color get statusColor {
    switch (status) {
      case -1: return const Color(0xFFCCCCCC);
      case 0: return const Color(0xFFFF8A65);
      case 1: return const Color(0xFF07C160);
      case 2: return const Color(0xFF1890FF);
      case 3: return const Color(0xFF999999);
      case 4: return const Color(0xFF999999);
      default: return const Color(0xFF999999);
    }
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    double _toDouble(dynamic v) => (v is double) ? v : (v is int) ? v.toDouble() : 0;
    return OrderItem(
      id: json['id'] as int? ?? 0,
      sn: json['sn'] as String? ?? '',
      title: json['deviceTitle'] as String?,
      price: _toDouble(json['price']),
      totalPrice: _toDouble(json['totalPrice']),
      quantity: json['num'] as int? ?? 1,
      status: json['status'] as int?,
      createTime: json['createTime'] as String?,
      image: json['deviceImg'] as String?,
      model: json['deviceModel'] as String?,
      subtitle: json['deviceSubtitle'] as String?,
      deviceId: json['deviceId'] as int? ?? 0,
    );
  }

  String get timeText {
    if (createTime == null) return '';
    final t = DateTime.tryParse(createTime!);
    if (t == null) return '';
    return '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')} ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }
}

/// 订单列表结果
class OrderListResult {
  final bool isSuccess;
  final String message;
  final List<OrderItem> orders;
  final int total;

  OrderListResult._({required this.isSuccess, required this.message, required this.orders, required this.total});

  factory OrderListResult.ok(List<OrderItem> orders, int total, [String? msg]) =>
      OrderListResult._(isSuccess: true, message: msg ?? '成功', orders: orders, total: total);

  factory OrderListResult.fail([String? msg]) =>
      OrderListResult._(isSuccess: false, message: msg ?? '请求失败', orders: [], total: 0);
}
