import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/device_info.dart';
import '../models/provision_data.dart';
import '../models/provision_status.dart';

/// BLE 配网服务
///
/// 封装与 ESP32-C6 设备的完整 BLE 配网交互流程：
/// 扫描 → 连接 → MTU 协商 → 服务发现 → CCCD 订阅 → 读设备信息 → 写凭证 → 监听结果
///
/// ## GATT 服务定义
///
/// 设备实际使用 16-bit 标准 UUID（与对接文档中的 128-bit 厂商 UUID 不同）：
/// - Service: FFF0
/// - DeviceInfo (READ): FFF1 — 读取设备信息 (JSON)
/// - ProvData (WRITE): FFF2 — 写入 WiFi 凭证 (JSON)
/// - Status (NOTIFY): FFF3 — 接收配网状态通知
///
/// ## 广播名称
///
/// 设备广播名为 `PetDevice_{SN后4位}`，如 `PetDevice_0002`。
///
/// ## 关键约束
///
/// - 设备等待凭证超时：30 秒（超时后主动断开 BLE）
/// - WiFi 连接超时：15 秒
/// - MTU 建议 ≥ 512（支持完整 JSON 传输）
/// - 必须先订阅 CCCD 再写入凭证，否则收不到状态通知
class BleProvisioningService {
  // ━━━ GATT UUID 定义（设备实际使用 16-bit 标准 UUID）━━━

  /// 配网服务 UUID (FFF0)
  static const serviceUuid    = '0000fff0-0000-1000-8000-00805f9b34fb';

  /// 设备信息特征 UUID (FFF1) — READ，返回 JSON: {sn, model, fw_ver}
  static const deviceInfoUuid = '0000fff1-0000-1000-8000-00805f9b34fb';

  /// 配网数据特征 UUID (FFF2) — WRITE，接收 JSON: {ssid, password, ...}
  static const provDataUuid   = '0000fff2-0000-1000-8000-00805f9b34fb';

  /// 配网状态特征 UUID (FFF3) — NOTIFY，推送 JSON: {status, sn, ...}
  static const statusUuid     = '0000fff3-0000-1000-8000-00805f9b34fb';

  // ━━━ 广播名称过滤前缀 ━━━

  /// 设备广播名称前缀，用于扫描时过滤非 JoliPaw 设备
  static const broadcastPrefix = 'PetDevice_';

  // ━━━ 超时配置 ━━━

  /// BLE 扫描超时（10 秒）
  static const scanTimeout    = Duration(seconds: 10);

  /// BLE 连接超时（5 秒）
  static const connectTimeout = Duration(seconds: 5);

  /// 配网整体超时（25 秒 = WiFi 15s 超时 + 10s 余量）
  static const provTimeout    = Duration(seconds: 25);

  /// 当前连接的 BLE 设备
  BluetoothDevice? _device;

  /// FFF1 特征引用 — 读取设备信息
  BluetoothCharacteristic? _deviceInfoChar;

  /// FFF2 特征引用 — 写入配网数据
  BluetoothCharacteristic? _provDataChar;

  /// FFF3 特征引用 — 订阅配网状态通知
  BluetoothCharacteristic? _statusChar;

  /// BLE 连接状态订阅
  StreamSubscription<OnConnectionStateChangedEvent>? _connSub;

  /// 获取当前连接的设备
  BluetoothDevice? get device => _device;

  /// 检查设备是否已连接
  ///
  /// 返回 true 表示设备已连接,可以执行 GATT 操作;
  /// 返回 false 表示设备未连接或连接已断开。
  bool get isConnected => _device != null;

  /// 获取当前 BLE 连接状态
  ///
  /// 如果设备未连接,返回 null。
  Future<BluetoothConnectionState?> getConnectionState() async {
    if (_device == null) return null;
    return await _device!.connectionState.first;
  }

  /// 连接指定设备并协商 MTU
  ///
  /// 步骤：
  /// 1. 建立 BLE 连接（超时 5 秒，不使用 autoConnect）
  /// 2. 请求 MTU 协商为 512 字节（支持完整 JSON 传输）
  ///
  /// 连接成功后需调用 [discoverServices] 发现 GATT 服务。
  Future<void> connect(BluetoothDevice device) async {
    _device = device;

    // 建立 BLE 连接，autoConnect=false 表示不自动重连
    await device.connect(timeout: connectTimeout, autoConnect: false);

    // 请求 MTU 协商，设备端已设置 esp_ble_gatt_set_local_mtu(512)
    final mtu = await device.requestMtu(512);
    print('[BLE] MTU 协商结果: $mtu');
  }

  /// 发现 GATT 服务并缓存 Characteristic 引用
  ///
  /// 遍历设备的所有服务和特征，找到 JoliPaw 配网服务 (FFF0) 下的
  /// 三个特征并缓存引用：
  /// - FFF1 (READ) → [_deviceInfoChar]
  /// - FFF2 (WRITE) → [_provDataChar]
  /// - FFF3 (NOTIFY) → [_statusChar]
  ///
  /// 如果缺少任何必需的特征，抛出 [StateError]。
  Future<void> discoverServices() async {
    if (_device == null) throw StateError('未连接设备');

    final services = await _device!.discoverServices();

    // 打印所有服务和特征（调试用）
    print('[BLE] 发现 ${services.length} 个服务:');
    for (final service in services) {
      print('[BLE]   服务 UUID: ${service.uuid.str128}');
      for (final char in service.characteristics) {
        final props = <String>[];
        if (char.properties.read) props.add('READ');
        if (char.properties.write) props.add('WRITE');
        if (char.properties.writeWithoutResponse) props.add('WRITE_NO_RESP');
        if (char.properties.notify) props.add('NOTIFY');
        if (char.properties.indicate) props.add('INDICATE');
        print('[BLE]     特征 UUID: ${char.uuid.str128} [${props.join(',')}]');
      }
    }

    // 在 FFF0 服务下查找三个必需的特征
    for (final service in services) {
      if (service.uuid.str128.toLowerCase() == serviceUuid.toLowerCase()) {
        print('[BLE] 找到 JOLIPAW 服务: ${service.uuid.str128}');
        for (final char in service.characteristics) {
          final uuid = char.uuid.str128.toLowerCase();
          if (uuid == deviceInfoUuid.toLowerCase()) {
            print('[BLE]   -> DeviceInfo (READ)');
            _deviceInfoChar = char;
          } else if (uuid == provDataUuid.toLowerCase()) {
            print('[BLE]   -> ProvData (WRITE)');
            _provDataChar = char;
          } else if (uuid == statusUuid.toLowerCase()) {
            print('[BLE]   -> Status (NOTIFY)');
            _statusChar = char;
          }
        }
      }
    }

    // 检查所有必需的特征是否已找到
    final missing = <String>[];
    if (_deviceInfoChar == null) missing.add('DeviceInfo($deviceInfoUuid)');
    if (_provDataChar == null) missing.add('ProvData($provDataUuid)');
    if (_statusChar == null) missing.add('Status($statusUuid)');
    if (missing.isNotEmpty) {
      throw StateError('缺少特征: ${missing.join(", ")}');
    }
  }

  /// 订阅配网状态通知
  ///
  /// 向 FFF3 的 CCCD (0x2902) 写入 0x0001 开启 Notify。
  /// **必须在写入凭证前调用**，否则无法接收设备的状态推送。
  Future<void> subscribeStatusNotify() async {
    if (_statusChar == null) throw StateError('Status Characteristic 未发现');
    await _statusChar!.setNotifyValue(true);
  }

  /// 读取设备信息 (FFF1 READ)
  ///
  /// 读取设备的 SN、型号、固件版本。
  ///
  /// ## 容错机制
  ///
  /// 部分固件版本的 FFF1 可能返回空数据，处理策略：
  /// 1. 最多重试 3 次，每次间隔 500ms
  /// 2. 如果全部为空，返回默认值 `DeviceInfo(sn: '未知', ...)`
  /// 3. JSON 解析失败时，将原始字符串作为 SN 返回
  Future<DeviceInfo> readDeviceInfo() async {
    if (_deviceInfoChar == null) throw StateError('DeviceInfo Characteristic 未发现');

    List<int> bytes = [];
    // 重试最多 3 次（设备固件可能需要时间准备数据）
    for (int i = 0; i < 3; i++) {
      bytes = await _deviceInfoChar!.read();
      final rawStr = utf8.decode(bytes, allowMalformed: true);
      print('[BLE] DeviceInfo 原始数据($i): "$rawStr" (${bytes.length} bytes)');
      if (bytes.isNotEmpty && rawStr.trim().isNotEmpty) break;
      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (bytes.isEmpty) {
      // 设备未返回任何数据，使用默认值继续配网流程
      print('[BLE] DeviceInfo 为空，使用默认值');
      return DeviceInfo(sn: '未知', model: '未知', fwVer: '未知');
    }

    try {
      // 尝试解析 JSON: {"sn": "...", "model": "...", "fw_ver": "..."}
      return DeviceInfo.fromBytes(bytes);
    } catch (e) {
      // JSON 解析失败，降级为原始字符串作为 SN
      final raw = utf8.decode(bytes, allowMalformed: true);
      print('[BLE] DeviceInfo JSON 解析失败，原始数据: $raw');
      return DeviceInfo(sn: raw.isNotEmpty ? raw : '未知', model: '未知', fwVer: '未知');
    }
  }

  /// 写入 WiFi 配网凭证 (FFF2 WRITE)
  ///
  /// 将 [ProvisionData] 编码为 JSON 字节数组，写入 FFF2 特征。
  ///
  /// ## 双重写入模式回退
  ///
  /// 先尝试 Write With Response (withoutResponse=false)，
  /// 如果失败（如 fbp-code:6 / GATT Request Not Supported），
  /// 自动回退到 Write Without Response (withoutResponse=true)。
  /// 部分设备固件只支持其中一种写入模式。
  Future<void> writeProvisionData(ProvisionData data) async {
    if (_provDataChar == null) throw StateError('ProvData Characteristic 未发现');
    final bytes = data.toBytes();
    final jsonStr = utf8.decode(bytes);
    print('[BLE] 写入配网数据: $jsonStr (${bytes.length} bytes)');
    try {
      // 优先使用 Write With Response（更可靠，有确认）
      await _provDataChar!.write(bytes, withoutResponse: false);
      print('[BLE] 配网数据写入成功');
    } catch (e) {
      print('[BLE] 配网数据写入失败: $e');
      // 回退到 Write Without Response（部分设备只支持此模式）
      print('[BLE] 重试: withoutResponse=true');
      await _provDataChar!.write(bytes, withoutResponse: true);
      print('[BLE] 配网数据写入成功 (withoutResponse)');
    }
  }

  /// 监听配网状态通知流
  ///
  /// 基于 FFF3 的 [lastValueStream],自动过滤空数据并解析为 [ProvisionStatus]。
  ///
  /// 正常流程会依次推送:
  /// 1. `prov_received` — 设备已收到凭证,正在连接 WiFi
  /// 2. `wifi_connected` 或 `wifi_failed` — 最终结果
  Stream<ProvisionStatus> get statusStream {
    if (_statusChar == null) throw StateError('Status Characteristic 未发现');
    return _statusChar!.lastValueStream
        .where((bytes) {
          print('[BLE] 收到 Notify 数据: ${bytes.length} bytes');
          if (bytes.isNotEmpty) {
            final rawStr = utf8.decode(bytes, allowMalformed: true);
            print('[BLE] Notify 原始数据: "$rawStr"');
          }
          return bytes.isNotEmpty;
        })                    // 过滤空数据
        .map((bytes) {
          final status = ProvisionStatus.fromBytes(bytes);
          print('[BLE] 解析配网状态: ${status.type}');
          return status;
        });     // 解析 JSON
  }

  /// 监听 BLE 连接状态变化
  ///
  /// 用于检测配网过程中的意外断开（非配网完成后的主动断开）。
  /// 配网成功后设备会主动关闭 BLE，这是正常行为。
  Stream<BluetoothConnectionState> get connectionStateStream {
    if (_device == null) throw StateError('未连接设备');
    return _device!.connectionState;
  }

  /// 断开 BLE 连接并清理所有资源
  ///
  /// 清理内容：
  /// - 取消连接状态订阅
  /// - 断开 BLE 连接（忽略异常，设备可能已主动关闭）
  /// - 置空所有 Characteristic 引用
  Future<void> disconnect() async {
    await _connSub?.cancel();
    _connSub = null;
    if (_device != null) {
      try {
        await _device!.disconnect();
      } catch (_) {
        // 忽略断开时的异常（设备可能已主动关闭 BLE 或连接已丢失）
      }
    }
    _device = null;
    _deviceInfoChar = null;
    _provDataChar = null;
    _statusChar = null;
  }

  /// 启动 BLE 扫描，返回过滤后的 PetDevice 设备列表
  ///
  /// ## 扫描策略
  ///
  /// - 不使用 Service UUID 过滤（`withServices`），因为部分 Android 设备
  ///   不支持 128-bit UUID 过滤
  /// - 扫描所有 BLE 设备后在应用层按名称前缀 `PetDevice_` 过滤
  /// - 已按设备 remoteId 去重
  ///
  /// ## Android 兼容性
  ///
  /// Android 上 `platformName` 可能为空，优先使用 `advName`
  /// （广播数据中的 Complete Local Name）。
  ///
  /// ## 返回
  ///
  /// 过滤后的 [ScanResult] 列表，超时后自动停止扫描。
  static Future<List<ScanResult>> scanDevices({
    Duration timeout = scanTimeout,
  }) async {
    // 检查设备是否支持蓝牙
    if (await FlutterBluePlus.isSupported == false) {
      throw StateError('此设备不支持蓝牙');
    }

    final results = <ScanResult>[];

    // 监听扫描结果，在应用层按名称前缀过滤
    final sub = FlutterBluePlus.onScanResults.listen((scanResults) {
      for (final r in scanResults) {
        // 优先取广播名称（Android 上 platformName 可能为空）
        final name = r.device.advName.isNotEmpty
            ? r.device.advName
            : r.device.platformName;

        // 按 PetDevice_ 前缀过滤 + 按 remoteId 去重
        if (name.startsWith(broadcastPrefix) &&
            !results.any((e) => e.device.remoteId == r.device.remoteId)) {
          results.add(r);
        }
      }
    });

    // 不加 withServices 过滤，扫描所有设备后在应用层过滤
    // startScan 的 timeout 到期后会自动停止扫描
    await FlutterBluePlus.startScan(timeout: timeout);

    // 停止监听扫描结果
    await sub.cancel();

    return results;
  }
}
