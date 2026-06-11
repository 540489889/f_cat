import '../models/home_device.dart';
import 'api_client.dart';

/// 家庭设备 API 服务
///
/// 对接后端 /app/home/device/** 系列接口。
/// 所有请求通过 ApiClient 统一转发，自动携带 Authorization 头
/// 并在 Token 过期时自动刷新。
class DeviceService {
  static final ApiClient _api = ApiClient.instance;

  // ==================== 设备管理 ====================

  /// 获取家庭设备列表（含 IoT 实时状态）
  static Future<DeviceListResult> getDeviceList({
    required int homeId,
  }) async {
    final res = await _api.get(
      '/app/home/device/list',
      queryParams: {'homeId': homeId},
    );
    if (res.isSuccess) {
      final list = res.asList;
      final devices = list
          .map((e) => HomeDevice.fromJson(e as Map<String, dynamic>))
          .toList();
      return DeviceListResult.ok(devices, res.message);
    }
    return DeviceListResult.fail(res.message);
  }

  /// 获取设备详情（含 IoT 实时状态）
  static Future<DeviceResult> getDeviceDetail({
    required int id,
  }) async {
    final res = await _api.get('/app/home/device/detail/$id');
    if (res.isSuccess && res.isMap) {
      return DeviceResult.ok(HomeDevice.fromJson(res.asMap));
    }
    return DeviceResult.fail(res.message);
  }

  /// 修改设备信息（别名/房间）
  static Future<ApiResult> updateDevice({
    required int id,
    String? alias,
    String? room,
  }) async {
    final body = <String, dynamic>{'id': id};
    if (alias != null) body['alias'] = alias;
    if (room != null) body['room'] = room;
    final res = await _api.put('/app/home/device/update', body: body);
    if (res.isSuccess) return ApiResult.ok(res.message);
    return ApiResult.fail(res.message);
  }

  /// 解绑设备
  static Future<ApiResult> unbindDevice({
    required int id,
  }) async {
    final res = await _api.delete('/app/home/device/unbind/$id');
    if (res.isSuccess) return ApiResult.ok(res.message);
    return ApiResult.fail(res.message);
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
    final body = <String, dynamic>{
      'homeId': homeId,
      'sn': sn,
    };
    if (alias != null) body['alias'] = alias;
    if (room != null) body['room'] = room;
    if (macAddress != null) body['macAddress'] = macAddress;
    if (deviceType != null) body['deviceType'] = deviceType;
    if (firmwareVersion != null) body['firmwareVersion'] = firmwareVersion;
    final res = await _api.post('/app/home/device/bind/sn', body: body);
    if (res.isSuccess) return ApiResult.ok(res.message);
    return ApiResult.fail(res.message);
  }

  // ==================== IoT 控制 ====================

  /// 发送设备控制指令
  static Future<ApiResult> sendCommand({
    required int homeDeviceId,
    required String command,
    Map<String, dynamic>? params,
  }) async {
    final body = <String, dynamic>{'command': command};
    if (params != null) body['params'] = params;
    final res = await _api.post(
      '/app/home/device/iot/control/by-id/$homeDeviceId',
      body: body,
    );
    if (res.isSuccess) return ApiResult.ok(res.message);
    return ApiResult.fail(res.message);
  }

  /// 查询设备最新遥测数据
  static Future<DeviceDataResult> getLatestData({
    required int homeDeviceId,
  }) async {
    final res =
        await _api.get('/app/home/device/iot/data/$homeDeviceId/latest');
    if (res.isSuccess) {
      final dataMap = res.asMap;
      final items = (dataMap['data'] as List<dynamic>?)
              ?.map((e) =>
                  DeviceDataPoint.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      return DeviceDataResult.ok(items);
    }
    return DeviceDataResult.fail(res.message);
  }

  /// 查询设备 IoT 实时状态
  static Future<DeviceStatusResult> getDeviceStatus({
    required int homeDeviceId,
  }) async {
    final res =
        await _api.get('/app/home/device/iot/status/$homeDeviceId');
    if (res.isSuccess && res.isMap) {
      return DeviceStatusResult.ok(res.asMap);
    }
    return DeviceStatusResult.fail(res.message);
  }
}

// ==================== 结果封装 ====================

/// 通用 API 结果
class ApiResult {
  final bool isSuccess;
  final String message;
  ApiResult._({required this.isSuccess, required this.message});
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
      DeviceListResult._(
          isSuccess: true, message: msg ?? '成功', devices: devices);
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
  factory DeviceStatusResult.ok(Map<String, dynamic>? status,
          [String? msg]) =>
      DeviceStatusResult._(
          isSuccess: true, message: msg ?? '成功', status: status);
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
