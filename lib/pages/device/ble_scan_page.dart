import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/ble_provisioning_service.dart';
import 'provision_page.dart';

/// BLE 设备扫描页面
///
/// App 首页，负责：
/// 1. 请求蓝牙和位置权限
/// 2. 检查蓝牙适配器状态
/// 3. 扫描并展示 `PetDevice_` 前缀的设备列表
/// 4. 点击设备后跳转到 [ProvisionPage] 配网页面
class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  /// 是否正在扫描
  bool _isScanning = false;

  /// 扫描到的设备列表（已去重）
  List<ScanResult> _devices = [];

  /// 错误提示信息（null 表示无错误）
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    // 页面初始化时自动检查权限并开始扫描
    _checkPermissionsAndScan();
  }

  /// 检查权限并开始扫描
  ///
  /// 权限要求：
  /// - `bluetoothScan` — BLE 扫描权限 (Android 12+)
  /// - `bluetoothConnect` — BLE 连接权限 (Android 12+)
  /// - `locationWhenInUse` — 位置权限（BLE 扫描需要，Android 系统要求）
  Future<void> _checkPermissionsAndScan() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    final allGranted = statuses.values.every((s) => s.isGranted);
    if (!allGranted) {
      setState(() => _errorMsg = '需要蓝牙和位置权限才能扫描设备');
      return;
    }

    // 检查蓝牙适配器是否已开启
    final adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) {
      setState(() => _errorMsg = '请开启蓝牙后重试');
      return;
    }

    _startScan();
  }

  /// 启动 BLE 扫描
  ///
  /// 调用 [BleProvisioningService.scanDevices] 扫描 10 秒，
  /// 自动过滤 `PetDevice_` 前缀的设备并去重。
  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _errorMsg = null;
      _devices = [];
    });

    try {
      final results = await BleProvisioningService.scanDevices();
      if (mounted) {
        setState(() {
          _devices = results;
          _isScanning = false;
          if (results.isEmpty) {
            _errorMsg = '未发现设备，请确保设备处于配网模式';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _errorMsg = '扫描失败: $e';
        });
      }
    }
  }

  /// 点击设备列表项，跳转到配网页面
  void _onDeviceTap(ScanResult result) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProvisionPage(scanResult: result),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('扫描设备'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _buildBody(),
      // 扫描进行中时隐藏 FAB，扫描完成后显示“重新扫描”按钮
      floatingActionButton: _isScanning
          ? null
          : FloatingActionButton.extended(
              onPressed: _startScan,
              icon: const Icon(Icons.refresh),
              label: const Text('重新扫描'),
            ),
    );
  }

  /// 根据当前状态构建页面内容
  ///
  /// 三种状态：
  /// - 扫描中：显示加载动画
  /// - 有错误：显示错误图标和提示
  /// - 有设备：显示设备列表
  Widget _buildBody() {
    // 状态 1: 扫描中 - 显示加载动画
    if (_isScanning) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在扫描附近设备...', style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

    // 状态 2: 有错误 - 显示错误信息
    if (_errorMsg != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bluetooth_disabled, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(_errorMsg!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            ],
          ),
        ),
      );
    }

    // 状态 3: 有设备 - 显示设备列表
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _devices.length,
      itemBuilder: (context, index) {
        final device = _devices[index];
        // 优先取广播名称（Android 上 platformName 可能为空，优先使用 advName）
        final name = device.device.advName.isNotEmpty
            ? device.device.advName
            : device.device.platformName;
        final id = device.device.remoteId.str;
        final rssi = device.rssi;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(Icons.pets, color: Colors.white),
            ),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('ID: $id | 信号: ${rssi}dBm'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _onDeviceTap(device),
          ),
        );
      },
    );
  }
}
