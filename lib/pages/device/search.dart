import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/ble_provisioning_service.dart';
import 'provision_page.dart';
import 'manual.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
    with SingleTickerProviderStateMixin {
  /// 是否正在扫描
  bool _isScanning = false;

  /// 扫描到的设备列表
  List<ScanResult> _devices = [];

  /// 蓝牙权限未开启
  bool _bluetoothDenied = false;

  /// 错误提示
  String? _errorMsg;

  /// 脉冲动画控制器
  late final AnimationController _ctrl;

  static const int controllerMs = 2000;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: controllerMs),
    );
    // 页面初始化时自动检查权限并开始扫描
    _checkPermissionsAndScan();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// 检查权限并开始扫描
  Future<void> _checkPermissionsAndScan() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    final allGranted = statuses.values.every((s) => s.isGranted);
    if (!allGranted) {
      if (mounted) {
        setState(() => _bluetoothDenied = true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showBluetoothDialog();
        });
      }
      return;
    }

    setState(() => _bluetoothDenied = false);
    _startScan();
  }

  /// 启动 BLE 扫描
  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _errorMsg = null;
      _devices = [];
      _ctrl.repeat();
    });

    // 等待 BLE 适配器就绪（手动连接页面能搜到就是因为有多页导航的延迟）
    await Future.delayed(const Duration(milliseconds: 800));

    try {
      final results = await BleProvisioningService.scanDevices();
      if (mounted) {
        _ctrl.stop();
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
        _ctrl.stop();
        setState(() {
          _isScanning = false;
          _errorMsg = '扫描失败: $e';
        });
      }
    }
  }

  /// 点击设备跳转到配网页面
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF2E8), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_left,
                          color: Colors.black87, size: 34),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          '智能连接设备',
                          style:
                              TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ManualPage()),
                        );
                      },
                      child: const Text('手动连接',
                          style: TextStyle(color: Colors.black54)),
                    ),
                  ],
                ),
              ),
              if (_bluetoothDenied) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      SizedBox(height: 8),
                      Text(
                        '附近的设备',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '请检查蓝牙使用权限是否开启',
                        style:
                            TextStyle(fontSize: 14, color: Color(0x89000000)),
                      ),
                    ],
                  ),
                ),
                // const Spacer(),
                const SizedBox(height: 120),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bluetooth,
                          size: 60, color: Color(0xFFFF8A65)),
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: _showBluetoothDialog,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0x89000000),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                        child: const Text(
                          '蓝牙使用权限未打开，去开启',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
              ] else if (_isScanning) ...[
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        '正在搜索可连接的设备...',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '打开手机蓝牙和定位，并确保设备处于配网状态',
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const Expanded(
                  child: Center(child: _PulseAnimation(ctrl: null)),
                ),
              ] else if (_errorMsg != null) ...[
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '搜索完成',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _errorMsg!,
                              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 124),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: _checkPermissionsAndScan,
                    icon: const Icon(Icons.refresh),
                    label: const Text('重新扫描'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8A65),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ),
                // const SizedBox(height: 16),
                // Center(
                //   child: TextButton.icon(
                //     onPressed: () async {
                //       await openAppSettings();
                //     },
                //     icon: const Icon(Icons.settings, size: 18),
                //     label: const Text('前往系统设置授权'),
                //     style: TextButton.styleFrom(
                //       foregroundColor: Colors.grey[600],
                //     ),
                //   ),
                // ),
                // const Spacer(),
              ] else ...[
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '发现 ${_devices.length} 台设备',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _devices.length,
                    itemBuilder: (context, index) {
                      final result = _devices[index];
                      // 多源获取设备名称（Android 兼容）
                      final advLocal = result.advertisementData.localName;
                      final adv = result.device.advName;
                      final plat = result.device.platformName;
                      final name = advLocal.isNotEmpty
                          ? advLocal
                          : (adv.isNotEmpty ? adv : plat);
                      final id = result.device.remoteId.str;
                      final rssi = result.rssi;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFFF8A65),
                            child: Image.asset(
                                'assets/images/icon/bluetooth-ico.png',
                                width: 24,
                                height: 24),
                          ),
                          title: Text(name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('ID: $id | 信号: ${rssi}dBm'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _onDeviceTap(result),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showBluetoothDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '开通蓝牙使用权限',
                  style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  '为了找到附近的智能设备，请前往\n"设置-小佩宠物"打开蓝牙使用权限',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                Image.asset(
                  'assets/images/bluetooth-guide.png',
                  width: 250,
                  height: 100,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.bluetooth,
                    size: 48,
                    color: Color(0xFFFF8A65),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey,
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: const Text('取消'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          openAppSettings();
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: const Color(0xFFFF8A65),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: const Text('去设置'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 脉冲动画组件
class _PulseAnimation extends StatelessWidget {
  final AnimationController? ctrl;
  const _PulseAnimation({this.ctrl});

  @override
  Widget build(BuildContext context) {
    return _PulseAnimationWidget(ctrl: ctrl);
  }
}

class _PulseAnimationWidget extends StatefulWidget {
  final AnimationController? ctrl;
  const _PulseAnimationWidget({this.ctrl});

  @override
  State<_PulseAnimationWidget> createState() => _PulseAnimationWidgetState();
}

class _PulseAnimationWidgetState extends State<_PulseAnimationWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = (widget.ctrl ??
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: controllerMs),
        )..repeat());
    if (widget.ctrl == null) _ctrl.repeat();
  }

  @override
  void dispose() {
    if (widget.ctrl == null) _ctrl.dispose();
    super.dispose();
  }

  static const int pulseCount = 3;
  static const int controllerMs = 2000;
  static const Color pulseColor = Color(0xFFFF6D00);
  

  @override
  Widget build(BuildContext context) {
    const double size = 320;

    return SizedBox(
      width: size,
      height: size,
      child: Transform.translate(
        offset: const Offset(0, -90),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: size - 40,
              height: size - 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
            RepaintBoundary(
              child: AnimatedBuilder(
                animation: _ctrl,
                builder: (context, child) {
                  return CustomPaint(
                    size: const Size(size, size),
                    painter: _PulsePainter(
                      progress: _ctrl.value,
                      count: pulseCount,
                      color: pulseColor,
                    ),
                  );
                },
              ),
            ),
            Container(
              width: 120,
              height: 120,
              // decoration: const BoxDecoration(
              //   shape: BoxShape.circle,
              //   gradient: RadialGradient(
              //       colors: [Color(0xFFFFE6D6), Color(0xFFFFB28C)]),
              // ),
            ),
            CircleAvatar(
              radius: 44,
              backgroundColor: Colors.white,
              child: Image.asset(
                'assets/images/icon/bluetooth-ico.png',
                width: 48,
                height: 48,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulsePainter extends CustomPainter {
  final double progress; // 0..1
  final int count;
  final Color color;

  _PulsePainter({required this.progress, required this.count, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.shortestSide * 0.5; // allow pulses to reach well outside mid circle
    final minRadius = size.shortestSide * 0.10; // starting small

    for (int i = 0; i < count; i++) {
      // compute phase for this pulse, staggered around the loop
      double phase = (progress - i / count) % 1.0;
      if (phase < 0) phase += 1.0;

      // We want each pulse to expand slowly over most of the cycle
      // Use easing for natural feel
      final eased = Curves.easeInOut.transform(phase.clamp(0.0, 1.0));

      final radius = minRadius + (maxRadius - minRadius) * eased;
      final opacity = ((1.0 - eased) * 1.0).clamp(0.0, 1.0);

      if (opacity <= 0.01) continue;

      final innerOpacity = (opacity * 1.4).clamp(0.0, 1.0);

      final rect = Rect.fromCircle(center: center, radius: radius);
      final shader = RadialGradient(
        colors: [color.withValues(alpha: opacity), color.withValues(alpha: innerOpacity * 0.6), color.withValues(alpha: 0.0)],
        stops: [0.0, 0.6, 1.0],
      ).createShader(rect);

      final paint = Paint()
        ..shader = shader
        ..blendMode = BlendMode.srcOver;
      canvas.drawCircle(center, radius, paint);

      // draw a stronger inner fill to make pulses more visible
      final innerPaint = Paint()..color = color.withValues(alpha: innerOpacity)..blendMode = BlendMode.srcOver;
      canvas.drawCircle(center, radius * 0.32, innerPaint);
    }

  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    if (oldDelegate is _PulsePainter) {
      return oldDelegate.progress != progress || oldDelegate.count != count || oldDelegate.color != color;
    }
    return true;
  }
}
