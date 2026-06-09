import 'dart:convert';

/// 设备信息模型
///
/// 对应 BLE GATT 特征 READ (FFF1) 返回的 JSON 数据。
/// 设备固件返回格式示例：
/// ```json
/// {"sn": "WATRPOC00002", "model": "waterer", "fw_ver": "1.0.0"}
/// ```
///
/// 字段说明：
/// - [sn] — 设备序列号，全局唯一，格式如 `WATRPOC00002`（WATR=饮水机, POC=原型, 00002=序号）
/// - [model] — 设备型号，如 `waterer`（饮水机）、`feeder`（喂食器）
/// - [fwVer] — 固件版本号，语义化版本格式
class DeviceInfo {
  /// 设备序列号，全局唯一标识
  final String sn;

  /// 设备型号（如 "waterer" 表示饮水机）
  final String model;

  /// 固件版本号（如 "1.0.0"）
  final String fwVer;

  DeviceInfo({
    required this.sn,
    required this.model,
    required this.fwVer,
  });

  /// 从 JSON Map 构造实例
  ///
  /// 字段缺失时默认为空字符串，避免解析崩溃。
  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      sn: json['sn'] as String? ?? '',
      model: json['model'] as String? ?? '',
      fwVer: json['fw_ver'] as String? ?? '',
    );
  }

  /// 从 BLE 读取的原始字节数组构造实例
  ///
  /// 先将字节解码为 UTF-8 字符串，再解析 JSON。
  factory DeviceInfo.fromBytes(List<int> bytes) {
    final jsonStr = utf8.decode(bytes);
    return DeviceInfo.fromJson(json.decode(jsonStr) as Map<String, dynamic>);
  }

  /// 序列化为 JSON Map
  Map<String, dynamic> toJson() => {
        'sn': sn,
        'model': model,
        'fw_ver': fwVer,
      };

  @override
  String toString() => 'DeviceInfo(sn: $sn, model: $model, fw: $fwVer)';
}
