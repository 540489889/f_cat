import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// WiFi 网络信息模型
///
/// 封装从 Android 原生 WifiManager 扫描得到的单个 WiFi 网络信息。
/// 通过 Platform Channel (`com.jolipaw/wifi`) 从 [MainActivity.kt] 获取。
class WifiNetwork {
  /// WiFi 名称 (SSID)
  final String ssid;

  /// 信号强度 (dBm)，值越大信号越好，典型范围 -30 ~ -90
  final int rssi;

  /// 加密能力描述（如 "[WPA2-PSK-CCMP][ESS]"）
  final String capabilities;

  WifiNetwork({required this.ssid, required this.rssi, required this.capabilities});

  /// 根据信号强度返回对应的 WiFi 信号图标
  ///
  /// 信号分级：
  /// - rssi > -50：极强信号
  /// - rssi > -65：强信号
  /// - rssi > -75：中等信号（3 格）
  /// - rssi <= -75：弱信号（1 格）
  IconData get signalIcon {
    if (rssi > -50) return Icons.wifi;
    if (rssi > -65) return Icons.wifi;
    if (rssi > -75) return Icons.network_wifi_3_bar;
    return Icons.network_wifi_1_bar_sharp;
  }

  /// 判断该网络是否加密
  ///
  /// 通过检查 capabilities 字符串中是否包含 WPA/WEP/EAP 关键字判断。
  bool get isEncrypted =>
      capabilities.contains('WPA') ||
      capabilities.contains('WEP') ||
      capabilities.contains('EAP');
}

/// WiFi 选择弹窗
///
/// 通过 Android 原生 Platform Channel 扫描周围 WiFi 网络，
/// 展示 WiFi 列表供用户选择，返回选中的 SSID。
///
/// 使用方式：
/// ```dart
/// final ssid = await WifiPickerDialog.show(context);
/// if (ssid != null) { /* 用户选择了某个 WiFi */ }
/// ```
///
/// 通信机制：
/// - Channel: `com.flttercat/wifi`
/// - 方法: `scanWifi` — 调用 Android 原生 WifiManager.startScan()
/// - 返回: `List<Map<String, dynamic>>` (ssid, rssi, capabilities)
class WifiPickerDialog extends StatefulWidget {
  const WifiPickerDialog({super.key});

  /// 显示 WiFi 选择弹窗
  ///
  /// 返回选中的 SSID 字符串，null 表示用户取消。
  static Future<String?> show(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (_) => const WifiPickerDialog(),
    );
  }

  @override
  State<WifiPickerDialog> createState() => _WifiPickerDialogState();
}

class _WifiPickerDialogState extends State<WifiPickerDialog> {
  /// 与 Android 原生层通信的 Platform Channel
  /// 对应 MainActivity.kt 中的 `com.flttercat/wifi` MethodChannel
  static const _channel = MethodChannel('com.flttercat/wifi');

  /// 扫描到的 WiFi 网络列表
  List<WifiNetwork>? _networks;

  /// 是否正在扫描
  bool _loading = true;

  /// 错误信息
  String? _error;

  @override
  void initState() {
    super.initState();
    _scanWifi();
  }

  /// 调用原生层扫描 WiFi
  ///
  /// 通过 Platform Channel 调用 Android `WifiManager.startScan()`，
  /// 扫描结果按信号强度降序排列，已按 SSID 去重。
  ///
  /// 错误处理：
  /// - [PlatformException] — 原生层返回的错误（如 WiFi 未开启）
  /// - 通用异常 — 通信失败或其他错误
  Future<void> _scanWifi() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // 调用原生 scanWifi 方法，返回 List<Map>
      final result = await _channel.invokeMethod<List>('scanWifi');
      // 将原生返回的 Map 列表转换为 WifiNetwork 对象列表
      final list = (result ?? []).map((item) {
        final m = Map<String, dynamic>.from(item);
        return WifiNetwork(
          ssid: m['ssid'] as String,
          rssi: m['rssi'] as int,
          capabilities: (m['capabilities'] as String?) ?? '',
        );
      }).toList();
      if (mounted) {
        setState(() {
          _networks = list;
          _loading = false;
        });
      }
    } on PlatformException catch (e) {
      // 原生层错误（如 WiFi_OFF、SCAN_ERROR）
      if (mounted) {
        setState(() {
          _error = e.message ?? 'WiFi 扫描失败';
          _loading = false;
        });
      }
    } catch (e) {
      // 其他异常
      if (mounted) {
        setState(() {
          _error = 'WiFi 扫描失败: $e';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题栏
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
              child: Row(
                children: [
                  const Icon(Icons.wifi, size: 22),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('选择 WiFi 网络',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: '重新扫描',
                    onPressed: _loading ? null : _scanWifi,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // 内容区
            Flexible(
              child: _buildContent(),
            ),
            // 底部按钮
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(8),
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                child: const Text('取消'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建弹窗内容区
  ///
  /// 三种状态：
  /// - 加载中：显示加载动画
  /// - 有错误：显示错误图标和重试按钮
  /// - 有数据：显示 WiFi 列表
  Widget _buildContent() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('正在扫描 WiFi...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 40, color: Colors.red.shade300),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _scanWifi,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_networks == null || _networks!.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text('未发现 WiFi 网络'),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: _networks!.length,
      itemBuilder: (context, index) {
        final net = _networks![index];
        return ListTile(
          leading: Icon(net.signalIcon,
              color: Theme.of(context).colorScheme.primary),
          title: Text(net.ssid),
          subtitle: Text('${net.rssi} dBm'),
          trailing: net.isEncrypted
              ? const Icon(Icons.lock, size: 18)
              : const Icon(Icons.lock_open, size: 18, color: Colors.grey),
          onTap: () => Navigator.of(context).pop(net.ssid),
        );
      },
    );
  }
}
