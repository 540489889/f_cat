import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/home_device.dart';
import '../../services/home_state.dart';
import '../../services/user_state.dart';
import '../device/search.dart';
import '../device/device_detail_page.dart';

/// 设备列表页 - 对接后端 /app/home/device/list 系列 API
class DevicesPage extends StatefulWidget {
  const DevicesPage({super.key});
  static final List<HomeDevice> _devices = [
    HomeDevice(
      id: 1,
      homeId: 1,
      deviceId: 1,
      deviceTitle: '智能饮水机 PRO',
      deviceType: 'drinker',
      deviceImglogo: 'assets/images/device/device1.png',
      iotOnline: true,
    ),
    // HomeDevice(
    //   id: 2,
    //   homeId: 1,
    //   deviceId: 2,
    //   deviceTitle: '智能喂食器 Mini',
    //   deviceType: 'feeder',
    //   deviceImglogo: 'assets/images/device/device2.png',
    //   iotOnline: true,
    // ),
    // HomeDevice(
    //   id: 3,
    //   homeId: 1,
    //   deviceId: 3,
    //   deviceTitle: '智能猫砂盆 Smart',
    //   deviceType: 'toilet',
    //   deviceImglogo: 'assets/images/device/device3.png',
    //   iotOnline: false,
    // ),
  ];

  
  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initHomeState());
  }

  /// 初始化家庭上下文（首次加载或退出登录后重新加载）
void _initHomeState() {
    final homeState = context.read<HomeState>();

    // 首次初始化：加载家庭列表，无家庭则自动创建
    if (!homeState.initialized) {
      homeState.initHome();
    }

    // 监听登录状态变化：登出时重置，重新登录时初始化
    context.read<UserState>().addListener(_onUserStateChanged);
  }

  void _onUserStateChanged() {
    if (!mounted) return;
    final userState = context.read<UserState>();
    final homeState = context.read<HomeState>();

    if (!userState.isLoggedIn && homeState.initialized) {
      // 用户退出登录 → 重置家庭状态
      homeState.reset();
    } else if (userState.isLoggedIn && !homeState.initialized) {
      // 用户重新登录 → 重新初始化
      homeState.initHome();
    }
  }

  @override
  void dispose() {
    // 避免内存泄漏
    try {
      context.read<UserState>().removeListener(_onUserStateChanged);
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin 需要调用
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
            _buildHeader(),
            const SizedBox(height: 14),
            Expanded(child: _buildDeviceList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const SizedBox(width: 36),
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
    );
  }

  Widget _buildDeviceList() {
    return Consumer<HomeState>(
      builder: (context, homeState, _) {
        // 调试：打印设备列表数据
        debugPrint('[DevicesPage] initialized=${homeState.initialized}, loading=${homeState.loading}, error=${homeState.error}');
        debugPrint('[DevicesPage] devices count=${homeState.devices.length}');
        for (var i = 0; i < homeState.devices.length; i++) {
          final d = homeState.devices[i];
          debugPrint('[DevicesPage] device[$i]: id=${d.id}, title=${d.deviceTitle}, type=${d.deviceType}, online=${d.isOnline}, sn=${d.sn}');
        }

        // 初始化中或首次加载
        if (!homeState.initialized) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('正在加载家庭信息...',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        // 空状态 - 无设备
        if (homeState.devices.isEmpty) {
          return _buildEmptyState(homeState);
        }

        // 设备列表（loading 刷新时不阻塞已有列表，RefreshIndicator 自身提供视觉反馈）
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => homeState.refresh(),
                child: ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: homeState.devices.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    return _DeviceCard(
                      device: homeState.devices[index],
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 空状态 — 暂无设备
  Widget _buildEmptyState(HomeState homeState) {
    return RefreshIndicator(
      onRefresh: () => homeState.refresh(),
      child: ListView(
        children: [
          const SizedBox(height: 8),
          // 我的设备(0)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '我的设备(0)',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 14),
          // 空白卡片
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // 插图
                  Image.asset(
                    'assets/images/icon/home-i-2.png',
                    width: 120,
                    height: 120,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '暂无数据',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '绑定设备，记录萌宠日常，实时监测健康~',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black45,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 去添加设备 按钮
                  SizedBox(
                    width: 160,
                    height: 42,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SearchPage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF8A65),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(21),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        '去添加设备',
                        style: TextStyle(fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 显示家庭切换弹窗
  void _showHomeSwitcher(BuildContext context) {
    final homeState = context.read<HomeState>();
    if (homeState.homes.length <= 1) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('切换家庭',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const Divider(height: 1),
              ...homeState.homes.map((home) => ListTile(
                    leading: Icon(
                      home.homeId == homeState.currentHomeId
                          ? Icons.home_filled
                          : Icons.home_outlined,
                      color: home.homeId == homeState.currentHomeId
                          ? const Color(0xFFFF8A65)
                          : null,
                    ),
                    title: Text(home.name),
                    subtitle: Text(home.role == 'owner' ? '所有者' :
                        home.role == 'admin' ? '管理员' : '成员'),
                    trailing: home.homeId == homeState.currentHomeId
                        ? const Icon(Icons.check, color: Color(0xFFFF8A65))
                        : null,
                    onTap: () {
                      Navigator.pop(ctx);
                      if (home.homeId != homeState.currentHomeId) {
                        homeState.switchHome(home.homeId);
                      }
                    },
                  )),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SearchPage()),
        );
      },
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 22),
      ),
    );
  }
}

/// 设备卡片组件
class _DeviceCard extends StatelessWidget {
  final HomeDevice device;

  const _DeviceCard({required this.device});

  @override
  Widget build(BuildContext context) {
    final actions = HomeState.getActionsForType(device.deviceType);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          // 设备图片
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: device.deviceImglogo?.isNotEmpty == true
                  ? Image.network(
                      device.deviceImglogo!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _defaultImage(),
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      },
                    )
                  : _defaultImage(),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 设备名称
                Text(
                  device.displayName,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                // 在线状态
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: device.isOnline
                            ? const Color(0xFF4CAF50)
                            : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      device.isOnline ? '在线' : '离线',
                      style: const TextStyle(
                          color: Color(0xFF4A4A4A), fontSize: 13),
                    ),
                    if (device.sn != null && device.sn!.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Text(
                        'SN: ${device.sn}',
                        style: const TextStyle(
                            color: Color(0xFF9E9E9E), fontSize: 12),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 5),
                // 设备型号
                if (device.deviceModel?.isNotEmpty == true)
                  Text(
                    device.deviceModel!,
                    style:
                        const TextStyle(color: Color(0xFF9E9E9E), fontSize: 12),
                  ),
                const SizedBox(height: 5),
                // 房间标签
                if (device.room?.isNotEmpty == true)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      device.room!,
                      style: const TextStyle(
                          color: Color(0xFF666666),
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                const SizedBox(height: 8),
                // 操作按钮
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DeviceDetailPage(
                              homeDeviceId: device.id,
                              initialTitle: device.displayName,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF8A65),
                        minimumSize: const Size(70, 36),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text('详情',
                          style: TextStyle(
                              color: Color(0xFFFFFFFF), fontSize: 14)),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: device.isOnline
                          ? () => _onQuickAction(context, actions)
                          : null,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 250, 225, 225),
                        minimumSize: const Size(70, 36),
                        side: const BorderSide(color: Color(0xFFFF8A65)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                      ),
                      child: Text(
                        actions.actionLabel,
                        style: const TextStyle(
                            color: Color(0xFFFF8A65), fontSize: 14),
                      ),
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

  Widget _defaultImage() {
    return Container(
      color: const Color(0xFFF4F4F4),
      child: const Icon(Icons.devices, size: 40, color: Colors.grey),
    );
  }

  void _onQuickAction(BuildContext context, DeviceActions actions) {
    // 快速操作：直接跳转到详情页
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DeviceDetailPage(
          homeDeviceId: device.id,
          initialTitle: device.displayName,
        ),
      ),
    );
  }
}

