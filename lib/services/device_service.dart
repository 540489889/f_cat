import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/home_device.dart';
import 'http_client.dart';

/// 家庭设备 API 服务
///
/// 对接后端 /app/home/device/** 系列接口。
/// 所有请求通过 AuthHttpClient 统一转发，自动携带 Authorization 头
/// 并在 Token 过期时自动刷新。
class DeviceService {
  static const String _baseUrl = 'http://192.168.1.135:8080';

  static AuthHttpClient get _http => AuthHttpClient.instance;

  // ==================== 设备管理 ====================

  /// 获取家庭设备列表（含 IoT 实时状态）
  ///
  /// [homeId] 家庭ID
  static Future<DeviceListResult> getDeviceList({
    required int homeId,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/app/home/device/list')
          .replace(queryParameters: {'homeId': '$homeId'});
      final response = await _http.get(uri);
      return _parseDeviceList(response);
    } catch (e) {
      return DeviceListResult.fail('网络异常：$e');
    }
  }

  /// 获取设备详情（含 IoT 实时状态）
  static Future<DeviceResult> getDeviceDetail({
    required int id,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/app/home/device/detail/$id');
      final response = await _http.get(uri);
      return _parseDevice(response);
    } catch (e) {
      return DeviceResult.fail('网络异常：$e');
    }
  }

  /// 修改设备信息（别名/房间）
  static Future<ApiResult> updateDevice({
    required int id,
    String? alias,
    String? room,
  }) async {
    try {
      final body = <String, dynamic>{'id': id};
      if (alias != null) body['alias'] = alias;
      if (room != null) body['room'] = room;
      final uri = Uri.parse('$_baseUrl/app/home/device/update');
      final response = await _http.put(
        uri,
        body: jsonEncode(body),
      );
      return _parseResult(response);
    } catch (e) {
      return ApiResult.fail('网络异常：$e');
    }
  }

  /// 解绑设备
  static Future<ApiResult> unbindDevice({
    required int id,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/app/home/device/unbind/$id');
      final response = await _http.delete(uri);
      return _parseResult(response);
    } catch (e) {
      return ApiResult.fail('网络异常：$e');
    }
  }

  // ==================== 设备绑定 ====================

  /// 通过 SN 绑定设备
  static Future<ApiResult> bindBySn({
    required int homeId,
    required String sn,
    String? alias,
    String? room,
    String? macAddress,
    int? deviceType,
    String? firmwareVersion,
  }) async {
    try {
      final body = <String, dynamic>{
        'homeId': homeId,
        'sn': sn,
      };
      if (alias != null) body['alias'] = alias;
      if (room != null) body['room'] = room;
      if (macAddress != null) body['macAddress'] = macAddress;
      if (deviceType != null) body['deviceType'] = deviceType;
      if (firmwareVersion != null) body['firmwareVersion'] = firmwareVersion;
      final uri = Uri.parse('$_baseUrl/app/home/device/bind/sn');
      final response = await _http.post(
        uri,
        body: jsonEncode(body),
      );
      return _parseResult(response);
    } catch (e) {
      return ApiResult.fail('网络异常：$e');
    }
  }

  // ==================== IoT 控制 ====================

  /// 发送设备控制指令
  ///
  /// [homeDeviceId] 家庭设备绑定记录ID
  /// [command] 指令名，如 "dispense"、"set_mode"
  /// [params] 可选参数 Map
  static Future<ApiResult> sendCommand({
    required int homeDeviceId,
    required String command,
    Map<String, dynamic>? params,
  }) async {
    try {
      final body = <String, dynamic>{'command': command};
      if (params != null) body['params'] = params;
      final uri = Uri.parse(
          '$_baseUrl/app/home/device/iot/control/by-id/$homeDeviceId');
      final response = await _http.post(
        uri,
        body: jsonEncode(body),
      );
      final result = jsonDecode(response.body) as Map<String, dynamic>;
      final code = result['code'] as int? ?? 500;
      final msg = result['msg'] as String? ?? '操作失败';
      if (response.statusCode == 200 && code == 200) {
        return ApiResult.ok(result['data']?.toString() ?? msg);
      }
      return ApiResult.fail(msg);
    } catch (e) {
      return ApiResult.fail('网络异常：$e');
    }
  }

  /// 查询设备最新遥测数据
  static Future<DeviceDataResult> getLatestData({
    required int homeDeviceId,
  }) async {
    try {
      final uri = Uri.parse(
          '$_baseUrl/app/home/device/iot/data/$homeDeviceId/latest');
      final response = await _http.get(uri);
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final code = body['code'] as int? ?? 500;
      if (response.statusCode == 200 && code == 200) {
        final data = body['data'] as Map<String, dynamic>?;
        final items = (data?['data'] as List<dynamic>?)
                ?.map((e) => DeviceDataPoint.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];
        return DeviceDataResult.ok(items);
      }
      return DeviceDataResult.fail(body['msg'] as String? ?? '查询失败');
    } catch (e) {
      return DeviceDataResult.fail('网络异常：$e');
    }
  }

  /// 查询设备 IoT 实时状态
  static Future<DeviceStatusResult> getDeviceStatus({
    required int homeDeviceId,
  }) async {
    try {
      final uri =
          Uri.parse('$_baseUrl/app/home/device/iot/status/$homeDeviceId');
      final response = await _http.get(uri);
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final code = body['code'] as int? ?? 500;
      if (response.statusCode == 200 && code == 200) {
        final data = body['data'] as Map<String, dynamic>?;
        return DeviceStatusResult.ok(data);
      }
      return DeviceStatusResult.fail(body['msg'] as String? ?? '查询失败');
    } catch (e) {
      return DeviceStatusResult.fail('网络异常：$e');
    }
  }

  // ==================== 内部解析 ====================

  static DeviceListResult _parseDeviceList(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final code = body['code'] as int? ?? 500;
    if (response.statusCode == 200 && code == 200) {
      final data = body['data'] as List<dynamic>?;
      final devices = data
              ?.map((e) =>
                  HomeDevice.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      return DeviceListResult.ok(devices, body['msg'] as String?);
    }
    return DeviceListResult.fail(body['msg'] as String? ?? '获取设备列表失败');
  }

  static DeviceResult _parseDevice(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final code = body['code'] as int? ?? 500;
    if (response.statusCode == 200 && code == 200) {
      final data = body['data'] as Map<String, dynamic>?;
      if (data != null) {
        return DeviceResult.ok(HomeDevice.fromJson(data));
      }
      return DeviceResult.fail('设备数据为空');
    }
    return DeviceResult.fail(body['msg'] as String? ?? '获取设备详情失败');
  }

  static ApiResult _parseResult(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final code = body['code'] as int? ?? 500;
    final msg = body['msg'] as String? ?? '操作失败';
    if (response.statusCode == 200 && code == 200) {
      return ApiResult.ok(body['data']?.toString() ?? msg);
    }
    return ApiResult.fail(msg);
  }
}

// ==================== 结果封装 ====================

/// 通用 API 结果
class ApiResult {
  final bool isSuccess;
  final String message;
  final String? data;
  ApiResult._({required this.isSuccess, required this.message, this.data});
  factory ApiResult.ok([String? msg]) =>
      ApiResult._(isSuccess: true, message: msg ?? '操作成功');
  factory ApiResult.fail(String msg) =>
      ApiResult._(isSuccess: false, message: msg);
}

/// 设备列表结果
class DeviceListResult {
  final bool isSuccess;
  final String message;
  final List<HomeDevice> devices;
  DeviceListResult._({
    required this.isSuccess,
    required this.message,
    this.devices = const [],
  });
  factory DeviceListResult.ok(List<HomeDevice> devices, [String? msg]) =>
      DeviceListResult._(isSuccess: true, message: msg ?? '成功', devices: devices);
  factory DeviceListResult.fail(String msg) =>
      DeviceListResult._(isSuccess: false, message: msg);
}

/// 单个设备结果
class DeviceResult {
  final bool isSuccess;
  final String message;
  final HomeDevice? device;
  DeviceResult._({required this.isSuccess, required this.message, this.device});
  factory DeviceResult.ok(HomeDevice device) =>
      DeviceResult._(isSuccess: true, message: '成功', device: device);
  factory DeviceResult.fail(String msg) =>
      DeviceResult._(isSuccess: false, message: msg);
}

/// 设备遥测数据结果
class DeviceDataResult {
  final bool isSuccess;
  final String message;
  final List<DeviceDataPoint> data;
  DeviceDataResult._({
    required this.isSuccess,
    required this.message,
    this.data = const [],
  });
  factory DeviceDataResult.ok(List<DeviceDataPoint> data, [String? msg]) =>
      DeviceDataResult._(isSuccess: true, message: msg ?? '成功', data: data);
  factory DeviceDataResult.fail(String msg) =>
      DeviceDataResult._(isSuccess: false, message: msg);
}

/// 设备状态结果
class DeviceStatusResult {
  final bool isSuccess;
  final String message;
  final Map<String, dynamic>? status;
  DeviceStatusResult._({
    required this.isSuccess,
    required this.message,
    this.status,
  });
  factory DeviceStatusResult.ok(Map<String, dynamic>? status, [String? msg]) =>
      DeviceStatusResult._(isSuccess: true, message: msg ?? '成功', status: status);
  factory DeviceStatusResult.fail(String msg) =>
      DeviceStatusResult._(isSuccess: false, message: msg);
}

/// 遥测数据点
class DeviceDataPoint {
  final String timestamp;
  final String metric;
  final String value;

  DeviceDataPoint({
    required this.timestamp,
    required this.metric,
    required this.value,
  });

  factory DeviceDataPoint.fromJson(Map<String, dynamic> json) {
    return DeviceDataPoint(
      timestamp: json['timestamp'] as String? ?? '',
      metric: json['metric'] as String? ?? '',
      value: json['value'] as String? ?? '',
    );
  }
}
