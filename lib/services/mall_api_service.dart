import 'package:flutter/foundation.dart';
import 'api_client.dart';

/// 商城商品 API 服务
///
/// 对接后端 /mall/** 系列接口。
class MallApiService {
  static final ApiClient _api = ApiClient.instance;

  /// 获取商品列表（分页）
  ///
  /// 响应 data 结构：
  /// {
  ///   "records": [{id, name, price, originalPrice, image, ...}],
  ///   "total": 10,
  ///   "pageNum": 1,
  ///   "pageSize": 10
  /// }
  static Future<MallProductListResult> getProductList({
    int pageNum = 1,
    int pageSize = 10,
  }) async {
    final res = await _api.get(
      '/app/mall/list',
      queryParams: {'pageNum': pageNum, 'pageSize': pageSize},
    );
    debugPrint('===== 商城商品列表 API 返回 =====');
    debugPrint('isSuccess: ${res.isSuccess}');
    debugPrint('message: ${res.message}');
    debugPrint('data: ${res.data}');
    if (res.isSuccess) {
      final map = res.asMap;
      debugPrint('data keys: ${map.keys}');
      debugPrint('records count: ${(map['records'] as List<dynamic>?)?.length ?? 0}');
      debugPrint('total: ${map['total']}');
      final records = (map['records'] as List<dynamic>?)
              ?.map((e) {
                debugPrint('  item: $e');
                return MallProduct.fromJson(e as Map<String, dynamic>);
              })
              .toList() ??
          [];
      final total = map['total'] as int? ?? 0;
      return MallProductListResult.ok(records, total, res.message);
    }
    debugPrint('===== 商品列表请求失败 =====');
    return MallProductListResult.fail(res.message);
  }

  /// 获取商品详情
  static Future<MallProductResult> getDeviceDetail({required int id}) async {
    final res = await _api.get('/app/mall/detail/$id');
    debugPrint('===== 商品详情 API 返回 (id=$id) =====');
    debugPrint('isSuccess: ${res.isSuccess}');
    debugPrint('data: ${res.data}');
    if (res.isSuccess) {
      final product = MallProduct.fromJson(res.asMap);
      return MallProductResult.ok(product);
    }
    return MallProductResult.fail(res.message);
  }
}

/// 商品数据模型
class MallProduct {
  final int id;
  final String title;
  final double price;
  final double? orgPrice;
  final String? subtitle;
  final String? imglogo;
  final String? imgs;
  final String? model;
  final String? type;
  final int stock;
  final int sales;

  MallProduct({
    required this.id,
    required this.title,
    required this.price,
    this.orgPrice,
    this.subtitle,
    this.imglogo,
    this.imgs,
    this.model,
    this.type,
    this.stock = 0,
    this.sales = 0,
  });

  factory MallProduct.fromJson(Map<String, dynamic> json) {
    return MallProduct(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      orgPrice: (json['orgPrice'] as num?)?.toDouble(),
      subtitle: json['subtitle'] as String?,
      imglogo: json['imglogo'] as String?,
      imgs: json['imgs'] as String?,
      model: json['model'] as String?,
      type: json['type'] as String?,
      stock: json['stock'] as int? ?? 0,
      sales: json['sales'] as int? ?? 0,
    );
  }
}

/// 商品列表结果
class MallProductListResult {
  final bool isSuccess;
  final String message;
  final List<MallProduct> products;
  final int total;

  MallProductListResult._({
    required this.isSuccess,
    required this.message,
    required this.products,
    required this.total,
  });

  factory MallProductListResult.ok(
    List<MallProduct> products,
    int total, [
    String? msg,
  ]) {
    return MallProductListResult._(
      isSuccess: true,
      message: msg ?? '成功',
      products: products,
      total: total,
    );
  }

  factory MallProductListResult.fail([String? msg]) {
    return MallProductListResult._(
      isSuccess: false,
      message: msg ?? '请求失败',
      products: [],
      total: 0,
    );
  }
}

/// 商品详情结果
class MallProductResult {
  final bool isSuccess;
  final String message;
  final MallProduct? product;

  MallProductResult._({
    required this.isSuccess,
    required this.message,
    this.product,
  });

  factory MallProductResult.ok(MallProduct product) {
    return MallProductResult._(isSuccess: true, message: '成功', product: product);
  }

  factory MallProductResult.fail([String? msg]) {
    return MallProductResult._(isSuccess: false, message: msg ?? '请求失败');
  }
}
