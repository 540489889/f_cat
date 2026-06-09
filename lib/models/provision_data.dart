import 'dart:convert';

/// WiFi 配网凭证模型
///
/// 对应 BLE GATT 特征 WRITE (FFF2) 发送的 JSON 数据。
/// APP 将用户选择的 WiFi 信息编码为 JSON 字节数组，通过 BLE 写入设备。
///
/// 发送格式示例：
/// ```json
/// {
///   "ssid": "MyHomeWiFi",
///   "password": "mypassword123",
///   "timestamp": 1716616800,
///   "auth_url": "https://api.jolipaw.com",
///   "mqtt_broker": "mqtt.jolipaw.com"
/// }
/// ```
///
/// 字段约束：
/// - ssid / password 为必填，缺失则设备返回 invalid_data
/// - timestamp 校验窗口 300 秒（仅当设备已 NTP 同步时才校验）
/// - WiFi 安全模式：WPA2-PSK，仅支持 2.4GHz
class ProvisionData {
  /// WiFi 名称（最大 32 字节）
  final String ssid;

  /// WiFi 密码（最大 64 字节）
  final String password;

  /// 设备认证服务器 URL（可选，如 https://api.jolipaw.com）
  final String? authUrl;

  /// MQTT Broker 地址（可选，如 mqtt.jolipaw.com）
  final String? mqttBroker;

  /// Unix 时间戳（秒），用于防重放攻击（可选）
  final int? timestamp;

  ProvisionData({
    required this.ssid,
    required this.password,
    this.authUrl,
    this.mqttBroker,
    this.timestamp,
  });

  /// 序列化为 JSON Map
  ///
  /// 仅输出非空的可选字段，保持报文精简。
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'ssid': ssid,
      'password': password,
    };
    if (timestamp != null) map['timestamp'] = timestamp;
    if (authUrl != null) map['auth_url'] = authUrl;
    if (mqttBroker != null) map['mqtt_broker'] = mqttBroker;
    return map;
  }

  /// 编码为 JSON 字节数组，用于 BLE WRITE
  ///
  /// 流程：toJson() → json.encode() → utf8.encode() → List<int>
  List<int> toBytes() => utf8.encode(json.encode(toJson()));

  @override
  String toString() => 'ProvisionData(ssid: $ssid, authUrl: $authUrl)';
}
