import 'package:flutter/material.dart';
import '../device/search.dart';
import '../device/water_dispenser.dart';

class DevicesPage extends StatelessWidget {
  const DevicesPage({super.key});

  static final List<_DeviceInfo> _devices = [
    _DeviceInfo(
      title: '智能饮水机 PRO',
      status: '在线',
      battery: '85%',
      badge: '水量充足',
      badgeColor: const Color(0xFFD7F2EB),
      badgeTextColor: const Color(0xFF37A86D),
      image: 'assets/images/device/device1.png',
      actionLabel: '换水',
    ),
    _DeviceInfo(
      title: '智能喂食器 Mini',
      status: '在线',
      battery: '85%',
      badge: '余粮充足',
      badgeColor: const Color(0xFFD7F2EB),
      badgeTextColor: const Color(0xFF37A86D),
      image: 'assets/images/device/device2.png',
      actionLabel: '投食',
    ),
    _DeviceInfo(
      title: '智能猫砂盆 Smart',
      status: '在线',
      battery: '85%',
      badge: '猫砂不足',
      badgeColor: const Color(0xFFFFE5E5),
      badgeTextColor: const Color(0xFFFF5A5A),
      image: 'assets/images/device/device3.png',
      actionLabel: '清理',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F7FB),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  const Expanded(
                    child: Center(
                      child: Text(
                        '设备',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  _buildAddButton(context),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '我的设备(${_devices.length})',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _devices.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  return _DeviceCard(device: _devices[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 8)),
        ],
      ),
      child: IconButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SearchPage()),
          );
        },
        icon: const Icon(Icons.add, color: Color(0xFF444444)),
        splashRadius: 22,
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final _DeviceInfo device;
  const _DeviceCard({required this.device});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 18, offset: const Offset(0, 10)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              // color: const Color(0xFFF4F4F4),
              borderRadius: BorderRadius.circular(18),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(
                device.image,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.devices, size: 40, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(device.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: Color(0xFF4CAF50), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(device.status, style: const TextStyle(color: Color(0xFF4A4A4A), fontSize: 13)),
                    const SizedBox(width: 10),
                    Text('电量 ${device.battery}', style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: device.badgeColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    device.badge,
                    style: TextStyle(color: device.badgeTextColor, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                 const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            if (device.title == '智能饮水机 PRO') {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const WaterDispenserPage()));
                            } else {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => DeviceDetailPage(title: device.title)));
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF8A65),
                            minimumSize: const Size(70, 36),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          child: const Text('详情', style: TextStyle(color: Color(0xFFFFFFFF),fontSize: 14)),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 250, 225, 225),
                            minimumSize: const Size(70, 36),
                            side: const BorderSide(color: Color(0xFFFF8A65)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          child: Text(device.actionLabel, style: const TextStyle(color: Color(0xFFFF8A65), fontSize: 14)),
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

class _DeviceInfo {
  final String title;
  final String status;
  final String battery;
  final String badge;
  final Color badgeColor;
  final Color badgeTextColor;
  final String image;
  final String actionLabel;

  const _DeviceInfo({
    required this.title,
    required this.status,
    required this.battery,
    required this.badge,
    required this.badgeColor,
    required this.badgeTextColor,
    required this.image,
    required this.actionLabel,
  });
}

class DeviceDetailPage extends StatelessWidget {
  final String title;
  const DeviceDetailPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: Colors.black87)),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(child: Text('设备详情：$title')),
    );
  }
}
