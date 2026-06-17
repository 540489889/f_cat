import 'package:flutter/foundation.dart';
import 'api_client.dart';

/// 收货地址 API 服务
///
/// 对接后端 /app/address/** 系列接口。
class AddressApiService {
  static final ApiClient _api = ApiClient.instance;

  /// 获取默认地址
  static Future<AddressItem?> getDefaultAddress() async {
    final res = await _api.get('/app/address/default');
    debugPrint('===== 默认地址 API 返回 =====');
    debugPrint('isSuccess: ${res.isSuccess}');
    debugPrint('message: ${res.message}');
    debugPrint('data: ${res.data}');
    if (res.isSuccess) {
      final item = AddressItem.fromJson(res.asMap);
      debugPrint('默认地址: id=${item.id}, name=${item.name}, region=${item.region}, detail=${item.detail}');
      return item;
    }
    debugPrint('===== 无默认地址 =====');
    return null;
  }

  /// 获取地址列表
  static Future<AddressListResult> getAddressList() async {
    final res = await _api.get('/app/address/list');
    debugPrint('===== 地址列表 API 返回 =====');
    debugPrint('isSuccess: ${res.isSuccess}');
    debugPrint('message: ${res.message}');
    debugPrint('data: ${res.data}');
    if (res.isSuccess) {
      final list = res.asList;
      debugPrint('地址数量: ${list.length}');
      final addresses = list
          .map((e) {
            debugPrint('  地址: $e');
            return AddressItem.fromJson(e as Map<String, dynamic>);
          })
          .toList();
      return AddressListResult.ok(addresses, res.message);
    }
    debugPrint('===== 地址列表请求失败 =====');
    return AddressListResult.fail(res.message);
  }

  /// 新增地址
  static Future<AddressResult> addAddress({
    required String region,
    required String detail,
    required String name,
    required String phone,
    bool isDefault = false,
  }) async {
    final parts = region.split(' ');
    final body = {
      'province': parts.elementAtOrNull(0) ?? '',
      'city': parts.elementAtOrNull(1) ?? '',
      'district': parts.elementAtOrNull(2) ?? '',
      'address': detail,
      'uname': name,
      'mobile': phone,
      'isDefault': isDefault ? 1 : 0,
    };
    debugPrint('===== 新增地址 请求参数 =====');
    debugPrint('$body');
    final res = await _api.post('/app/address/add', body: body);
    debugPrint('===== 新增地址 API 返回 =====');
    debugPrint('isSuccess: ${res.isSuccess}');
    debugPrint('message: ${res.message}');
    debugPrint('data: ${res.data}');
    if (res.isSuccess) {
      final item = AddressItem.fromJson(res.asMap);
      return AddressResult.ok(item, res.message);
    }
    debugPrint('===== 新增地址失败 =====');
    return AddressResult.fail(res.message);
  }

  /// 更新地址
  static Future<AddressResult> updateAddress({
    required int id,
    required String region,
    required String detail,
    required String name,
    required String phone,
    bool isDefault = false,
  }) async {
    final parts = region.split(' ');
    final res = await _api.post(
      '/app/address/update',
      body: {
        'id': id,
        'province': parts.elementAtOrNull(0) ?? '',
        'city': parts.elementAtOrNull(1) ?? '',
        'district': parts.elementAtOrNull(2) ?? '',
        'address': detail,
        'uname': name,
        'mobile': phone,
        'isDefault': isDefault ? 1 : 0,
      },
    );
    if (res.isSuccess) {
      final item = AddressItem.fromJson(res.asMap);
      return AddressResult.ok(item, res.message);
    }
    return AddressResult.fail(res.message);
  }

  /// 删除地址
  static Future<BaseResult> deleteAddress({required int id}) async {
    final res = await _api.post('/app/address/delete/$id');
    debugPrint('===== 删除地址 API 返回 (id=$id) =====');
    debugPrint('isSuccess: ${res.isSuccess}');
    debugPrint('message: ${res.message}');
    debugPrint('data: ${res.data}');
    if (res.isSuccess) {
      return BaseResult.ok(res.message);
    }
    debugPrint('===== 删除地址失败 =====');
    return BaseResult.fail(res.message);
  }
}

/// 地址数据模型
class AddressItem {
  final int id;
  final String region;
  final String detail;
  final String name;
  final String phone;
  final bool isDefault;

  AddressItem({
    required this.id,
    required this.region,
    required this.detail,
    required this.name,
    required this.phone,
    this.isDefault = false,
  });

  factory AddressItem.fromJson(Map<String, dynamic> json) {
    final province = json['province'] as String? ?? '';
    final city = json['city'] as String? ?? '';
    final district = json['district'] as String? ?? '';
    return AddressItem(
      id: json['id'] as int? ?? 0,
      region: '$province $city $district'.trim(),
      detail: json['address'] as String? ?? '',
      name: json['uname'] as String? ?? '',
      phone: json['mobile'] as String? ?? '',
      isDefault: (json['isDefault'] as int? ?? 0) == 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'province': region.split(' ').elementAtOrNull(0) ?? '',
        'city': region.split(' ').elementAtOrNull(1) ?? '',
        'district': region.split(' ').elementAtOrNull(2) ?? '',
        'address': detail,
        'uname': name,
        'mobile': phone,
        'isDefault': isDefault ? 1 : 0,
      };
}

/// 地址列表结果
class AddressListResult {
  final bool isSuccess;
  final String message;
  final List<AddressItem> addresses;

  AddressListResult._({required this.isSuccess, required this.message, required this.addresses});

  factory AddressListResult.ok(List<AddressItem> addresses, [String? msg]) =>
      AddressListResult._(isSuccess: true, message: msg ?? '成功', addresses: addresses);

  factory AddressListResult.fail([String? msg]) =>
      AddressListResult._(isSuccess: false, message: msg ?? '请求失败', addresses: []);
}

/// 单个地址结果
class AddressResult {
  final bool isSuccess;
  final String message;
  final AddressItem? address;

  AddressResult._({required this.isSuccess, required this.message, this.address});

  factory AddressResult.ok(AddressItem address, [String? msg]) =>
      AddressResult._(isSuccess: true, message: msg ?? '成功', address: address);

  factory AddressResult.fail([String? msg]) =>
      AddressResult._(isSuccess: false, message: msg ?? '请求失败');
}

/// 基础结果（删除用）
class BaseResult {
  final bool isSuccess;
  final String message;

  BaseResult._({required this.isSuccess, required this.message});

  factory BaseResult.ok([String? msg]) =>
      BaseResult._(isSuccess: true, message: msg ?? '成功');

  factory BaseResult.fail([String? msg]) =>
      BaseResult._(isSuccess: false, message: msg ?? '请求失败');
}
