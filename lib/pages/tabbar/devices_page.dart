import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../device/search.dart';
import '../device/device_detail_page.dart';

/// 设备列表页
class DevicesPage extends StatefulWidget {
  const DevicesPage({super.key});

  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  final List<Map<String, dynamic>> _devices = [
    // {
    //   'title': '智能饮水机 PRO',
    //   'type': 'drinker',
    //   'image': 'assets/images/device/device1.png',
    //   'online': true,
    //   'sn': 'WATR001',
    // },
  ];

  /// 点击添加设备按钮时检查权限，通过后再跳转（避免 IndexedStack 预加载时弹窗）
  Future<void> _checkPermissionsAndGoToSearch() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    final allGranted = statuses.values.every((s) => s.isGranted);
    if (!allGranted && mounted) {
      _showPermissionDialog();
      return;
    }
    if (mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchPage()));
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('需要权限'),
        content: const Text('为了搜索和连接附近的智能设备，需要开启蓝牙和位置权限。请在系统设置中允许。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text('去设置'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFAF2), Color(0xFFF2F2F2)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(context),
            const SizedBox(height: 14),
            Expanded(child: _buildDeviceList(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const SizedBox(width: 36),
          const Expanded(
            child: Center(
              child: Text('设备', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ),
          GestureDetector(
            onTap: _checkPermissionsAndGoToSearch,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(18)),
              child: const Icon(Icons.add, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceList(BuildContext context) {
    if (_devices.isEmpty) {
      return _buildEmptyState(context);
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _devices.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final d = _devices[index];
        return _DeviceCard(
          title: d['title'] as String,
          image: d['image'] as String,
          online: d['online'] as bool,
          sn: d['sn'] as String?,
          type: d['type'] as String,
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Image.asset('assets/images/icon/home-i-2.png', width: 120, height: 120),
            const SizedBox(height: 16),
            const Text('暂无设备', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 8),
            const Text('绑定设备，记录萌宠日常，实时监测健康~', style: TextStyle(fontSize: 13, color: Colors.black45)),
            const SizedBox(height: 24),
            SizedBox(
              width: 160,
              height: 42,
              child: ElevatedButton(
                onPressed: _checkPermissionsAndGoToSearch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7A47),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(21)),
                  elevation: 0,
                ),
                child: const Text('去添加设备', style: TextStyle(fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 设备卡片组件
class _DeviceCard extends StatelessWidget {
  final String title;
  final String image;
  final bool online;
  final String? sn;
  final String type;

  const _DeviceCard({
    required this.title,
    required this.image,
    required this.online,
    this.sn,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 18, offset: const Offset(0, 10))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(18)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(image, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: online ? const Color(0xFF4CAF50) : Colors.grey, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(online ? '在线' : '离线', style: const TextStyle(color: Color(0xFF4A4A4A), fontSize: 13)),
                    if (sn != null && sn!.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Text('SN: $sn', style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 12)),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => DeviceDetailPage(homeDeviceId: 0, initialTitle: title),
                        ));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF7A47),
                        minimumSize: const Size(70, 36),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text('详情', style: TextStyle(color: Colors.white, fontSize: 14)),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: online
                          ? () {
                              Navigator.push(context, MaterialPageRoute(
                                builder: (_) => DeviceDetailPage(homeDeviceId: 0, initialTitle: title),
                              ));
                            }
                          : null,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 250, 225, 225),
                        minimumSize: const Size(70, 36),
                        side: const BorderSide(color: Color(0xFFFF7A47)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text('控制', style: TextStyle(color: Color(0xFFFF7A47), fontSize: 14)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
