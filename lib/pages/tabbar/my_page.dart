import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../member/subscribe_infor.dart';
import '../login/index.dart';
import '../member/album.dart';
import '../member/news.dart';
import '../member/service.dart';
import '../mall/index.dart';
import '../../services/user_state.dart';
import '../../services/home_state.dart';


class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  int _deviceCount = 0;

  Widget _sectionCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: children
            .map((w) => Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), child: w))
            .toList(),
      ),
    );
  }

  Widget _rowItem(String iconPath, String title, {Widget? trailing}) {
    return Row(
      children: [
        Image.asset(iconPath, width: 24, height: 24),
        const SizedBox(width: 12),
        Expanded(child: Text(title, style: const TextStyle(fontSize: 16))),
        if (trailing != null) trailing else const Icon(Icons.chevron_right, color: Colors.grey),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {

      final userState = context.watch<UserState>();
  // print("===== 全局 UserState 数据 =====");
  // print("是否登录: ${userState.isLoggedIn}");
  // print("用户名: ${userState.username}");
  // print("AccessToken: ${userState.accessToken}");
  // print("RefreshToken: ${userState.refreshToken}");

  final homeState = context.watch<HomeState>();
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFF7A47), Color(0xFFF2F2F2)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                  children: [
                  const SizedBox(width: 80),
                  Expanded(
                    child: Center(
                      child: Text(
                        '我的',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                  Stack(
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const NewsPage()));
                        },
                        icon: Image.asset('assets/images/icon/m-11.png', width: 28, height: 28),
                      ),
                      Positioned(
                        right: 10,
                        top: 10,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        ),
                      ),
                    ],
                  ),

                  // 右侧：设置图标
                  IconButton(onPressed: () {}, icon: Image.asset('assets/images/icon/m-22.png', width: 28, height: 28)),
                ],
              ),
            ),


            // profile row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: GestureDetector(
                onTap: _handleProfileTap,
                child: Container(
                  // padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        child: const Icon(Icons.person, size: 30, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: context.watch<UserState>().isLoggedIn
                              ? [
                                  Text(context.watch<UserState>().username, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                  const SizedBox(height: 4),
                                  Text('$_deviceCount 个智能设备', style: const TextStyle(color: Colors.white70)),
                                ]
                              : const [
                                  Text('登录', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                  SizedBox(height: 4),
                                  Text('登录后可管理设备', style: TextStyle(color: Colors.white70)),
                                ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.white70),
                    ],
                  ),
                ),
              ),
            ),

            // sections
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _sectionCard([
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscribeInforPage())),
                        child: _rowItem('assets/images/icon/p1.png', '订阅服务'),
                      ),
                      const Divider(height: 1, color: Color(0xFFF4F4F4)),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const MallPage()), // 这里跳转到商城
                          );
                        },
                        child: _rowItem('assets/images/icon/p2.png', '商城'),
                      ),
                    ]),

                    _sectionCard([
                      _rowItem('assets/images/icon/p3.png', '共享关联', trailing: Row(mainAxisSize: MainAxisSize.min, children: const [Text('1 个关联账号', style: TextStyle(color: Colors.black45)), SizedBox(width: 6), Icon(Icons.chevron_right, color: Colors.grey)])),
                      const Divider(height: 1, color: Color(0xFFF4F4F4)),
                      GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AlbumPage()),
                            );
                          },
                          child: _rowItem('assets/images/icon/p4.png', '我的相册'),
                        ),
                    ]),

                    _sectionCard([
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ServicePage()),
                            );
                          },
                          child:   _rowItem('assets/images/icon/p5.png', '客服'),
                        ),
                    
                      const Divider(height: 1, color: Color(0xFFF4F4F4)),
                      _rowItem('assets/images/icon/p6.png', '投诉建议'),
                      const Divider(height: 1, color: Color(0xFFF4F4F4)),
                      _rowItem('assets/images/icon/p8.png', '检查更新', trailing: Row(mainAxisSize: MainAxisSize.min, children: const [Text('最新版本', style: TextStyle(color: Colors.black45)), SizedBox(width: 6), Icon(Icons.chevron_right, color: Colors.grey)])),
                      const Divider(height: 1, color: Color(0xFFF4F4F4)),
                      _rowItem('assets/images/icon/p7.png', '关于我们'),
                    ]),

                    // 退出登录按钮
                    if (context.watch<UserState>().isLoggedIn)
                      _buildLogoutButton(),

                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleProfileTap() async {
    final userState = context.read<UserState>();

    if (userState.isLoggedIn) {
      // 已登录 - 进入个人中心（可扩展）
      return;
    }
    final res = await Navigator.push(
        context, MaterialPageRoute(builder: (_) => const LoginPage()));
    if (res == true) {
      setState(() {
        _deviceCount = 3;
      });
    }
  }

  /// 退出登录按钮
  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: _confirmLogout,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout, size: 18, color: Color(0xFFE53935)),
              SizedBox(width: 6),
              Text(
                '退出登录',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFFE53935),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 确认退出登录 — 底部弹窗样式
  Future<void> _confirmLogout() async {
    final confirm = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(14),
        ),
        
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 内容区
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Column(
                children: [
                  const Text(
                    '退出登录',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '确定要退出当前账号吗？',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // 退出按钮
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                // borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFE53935),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 17),
                ),
                child: const Text('退出登录'),
              ),
            ),
            // 取消按钮
            Container(
              width: double.infinity,
              // margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                // borderRadius: BorderRadius.circular(14),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
              ),
              child: TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF007AFF),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
                child: const Text('取消'),
              ),
            ),
            // SizedBox(height: MediaQuery.of(ctx).padding.bottom + 16),
          ],
        ),
      ),
    );

    if (confirm == true && mounted) {
      final homeState = context.read<HomeState>();
      homeState.reset();
      await context.read<UserState>().logout();
    }
  }
}
