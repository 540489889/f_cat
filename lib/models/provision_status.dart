import 'dart:convert';

/// 配网状态枚举
///
/// 对应设备通过 BLE Notify (FFF3) 推送的 `status` 字段值。
/// 正常流程：provReceived → wifiConnected
/// 失败流程：provReceived → wifiFailed
enum ProvisionStatusType {
  provReceived,   /// 设备已收到凭证，正在连接 WiFi（"prov_received"）
  wifiConnected,  /// WiFi 连接成功（"wifi_connected"）
  wifiFailed,     /// WiFi 连接失败（"wifi_failed"）
  invalidData,    /// 写入的数据无效，JSON 解析失败或缺少必填字段（"invalid_data"）
  unknown,        /// 未知状态（无法识别的 status 值）
}

/// 配网状态通知模型
///
/// 对应 BLE GATT 特征 NOTIFY (FFF3) 推送的 JSON 数据。
/// 设备最多推送 2 条通知：
/// 1. `prov_received` — 凭证已接收，正在连接 WiFi
/// 2. `wifi_connected` 或 `wifi_failed` — 最终结果
///
/// 通知格式示例：
/// ```json
/// {"status": "wifi_connected", "sn": "WATRPOC00002", "wifi_connected": true, "ip": "192.168.1.100"}
/// {"status": "wifi_failed", "sn": "WATRPOC00002", "reason": "timeout"}
/// ```
class ProvisionStatus {
  /// 状态类型（prov_received / wifi_connected / wifi_failed 等）
  final ProvisionStatusType type;

  /// 设备序列号
  final String sn;

  /// WiFi 是否已连接
  final bool wifiConnected;

  /// 设备 IP 地址（连接成功时有值，如 "192.168.1.100"）
  final String ip;

  /// 失败原因（仅 wifi_failed 时有值）
  ///
  /// 可选值：
  /// - `"timeout"` — 15 秒内未连接成功
  /// - `"auth_error"` — 密码错误或认证失败
  /// - `"not_found"` — 未找到指定 SSID 的 AP
  final String? reason;

  ProvisionStatus({
    required this.type,
    required this.sn,
    required this.wifiConnected,
    required this.ip,
    this.reason,
  });

  /// 从 JSON Map 构造实例
  ///
  /// 将设备推送的 `status` 字符串解析为 [ProvisionStatusType] 枚举。
  factory ProvisionStatus.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String? ?? '';
    final type = _parseStatusType(statusStr);
    return ProvisionStatus(
      type: type,
      sn: json['sn'] as String? ?? '',
      wifiConnected: json['wifi_connected'] as bool? ?? false,
      ip: json['ip'] as String? ?? '0.0.0.0',
      reason: json['reason'] as String?,
    );
  }

  /// 从 BLE Notify 的原始字节数组构造实例
  ///
  /// 先将字节解码为 UTF-8 字符串，再解析 JSON。
  factory ProvisionStatus.fromBytes(List<int> bytes) {
    final jsonStr = utf8.decode(bytes);
    return ProvisionStatus.fromJson(json.decode(jsonStr) as Map<String, dynamic>);
  }

  /// 将设备推送的 status 字符串解析为枚举类型
  static ProvisionStatusType _parseStatusType(String status) {
    switch (status) {
      case 'prov_received':
        return ProvisionStatusType.provReceived;
      case 'wifi_connected':
        return ProvisionStatusType.wifiConnected;
      case 'wifi_failed':
        return ProvisionStatusType.wifiFailed;
      case 'invalid_data':
        return ProvisionStatusType.invalidData;
      default:
        return ProvisionStatusType.unknown;
    }
  }

  /// 获取失败原因的用户友好描述
  ///
  /// 将设备返回的 reason 码转换为中文提示,用于 UI 展示。
  /// 
  /// 支持的失败原因:
  /// - `timeout` — WiFi 连接超时(可能原因:5G网络、信号弱、DHCP失败等)
  /// - `auth_error` — 密码错误或认证失败
  /// - `not_found` — 未找到指定的 SSID
  /// - `dhcp_failed` — DHCP 获取 IP 失败
  /// - `dns_error` — DNS 解析失败
  /// - `internet_unreachable` — 无法访问互联网(无公网)
  String get failReasonText {
    switch (reason) {
      case 'timeout':
        return 'WiFi 连接超时\n\n'
            '可能原因:\n'
            '• 设备仅支持 2.4GHz WiFi,您连接的是 5G 网络\n'
            '• WiFi 信号太弱,设备无法稳定连接\n'
            '• 路由器设置了 MAC 地址过滤\n'
            '• WiFi 网络不可用或被隐藏\n\n'
            '建议:\n'
            '• 请使用 2.4GHz 网络(名称通常不带 "5G")\n'
            '• 将设备靠近路由器后重试\n'
            '• 检查路由器是否开启了 AP 隔离';
      
      case 'auth_error':
        return 'WiFi 密码错误\n\n'
            '可能原因:\n'
            '• 输入的 WiFi 密码不正确\n'
            '• WiFi 使用了 WPA3 加密(设备仅支持 WPA2)\n'
            '• 路由器设置了企业级认证(802.1X)\n\n'
            '建议:\n'
            '• 请仔细检查 WiFi 密码(区分大小写)\n'
            '• 在手机 WiFi 设置中查看加密类型\n'
            '• 确保使用 WPA2-PSK 加密方式';
      
      case 'not_found':
        return '未找到 WiFi 网络\n\n'
            '可能原因:\n'
            '• WiFi 名称(SSID)输入错误\n'
            '• 设备距离路由器太远,搜索不到信号\n'
            '• WiFi 已关闭或路由器未通电\n\n'
            '建议:\n'
            '• 点击扫描图标选择正确的 WiFi\n'
            '• 确保路由器工作正常\n'
            '• 将设备靠近路由器后重试';
      
      case 'dhcp_failed':
        return '无法获取 IP 地址\n\n'
            '可能原因:\n'
            '• 路由器 DHCP 服务未开启\n'
            '• IP 地址池已耗尽\n'
            '• 路由器设置了静态 IP 分配\n\n'
            '建议:\n'
            '• 重启路由器后重试\n'
            '• 检查路由器 DHCP 设置\n'
            '• 尝试连接其他 WiFi 网络';
      
      case 'dns_error':
        return 'DNS 解析失败\n\n'
            '可能原因:\n'
            '• 路由器 DNS 设置错误\n'
            '• 网络供应商 DNS 服务异常\n\n'
            '建议:\n'
            '• 重启路由器\n'
            '• 在路由器中设置 DNS 为 8.8.8.8';
      
      case 'internet_unreachable':
        return '无法访问互联网\n\n'
            '可能原因:\n'
            '• WiFi 网络没有公网访问权限\n'
            '• 路由器未连接外网\n'
            '• 网络被防火墙拦截\n\n'
            '建议:\n'
            '• 检查路由器是否正常上网\n'
            '• 使用手机连接同一 WiFi 测试\n'
            '• 检查是否需要认证登录(如校园网)';
      
      default:
        return '配网失败\n\n'
            '可能原因:\n'
            '• WiFi 名称或密码错误\n'
            '• 设备仅支持 2.4GHz 网络\n'
            '• 路由器设置了访问限制\n\n'
            '建议:\n'
            '• 检查 WiFi 信息是否正确\n'
            '• 使用 2.4GHz 网络重试\n'
            '• 重启设备后重新配网';
    }
  }

  @override
  String toString() =>
      'ProvisionStatus(type: $type, sn: $sn, wifi: $wifiConnected, ip: $ip, reason: $reason)';
}
