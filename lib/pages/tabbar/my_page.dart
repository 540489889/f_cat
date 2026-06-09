import 'package:flutter/material.dart';
import '../member/subscribe_infor.dart';
import '../login/index.dart';
import '../member/album.dart';
import '../member/news.dart';
import '../member/service.dart';
import '../mall/index.dart';


class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  bool _loggedIn = false;
  String _username = '';
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
    return Container(
      color: const Color(0xFFFBF6F2),
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
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  Stack(
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const NewsPage()));
                        },
                        icon: Image.asset('assets/images/icon/m-1.png', width: 28, height: 28),
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
                  IconButton(onPressed: () {}, icon: Image.asset('assets/images/icon/m-2.png', width: 28, height: 28)),
                ],
              ),
            ),


            // profile row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: GestureDetector(
                onTap: _handleProfileTap,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                  child: Row(
                    children: [
                      CircleAvatar(radius: 30, backgroundColor: const Color(0xFFF2F2F2), child: const Icon(Icons.person, size: 30, color: Colors.grey)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _loggedIn
                              ? [
                                  Text(_username, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text('$_deviceCount 个智能设备', style: const TextStyle(color: Colors.black54)),
                                ]
                              : const [
                                  Text('登录', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  SizedBox(height: 4),
                                  Text('登录后可管理设备', style: TextStyle(color: Colors.black54)),
                                ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.grey),
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
                      _rowItem('assets/images/icon/p7.png', '检查更新'),
                      const Divider(height: 1, color: Color(0xFFF4F4F4)),
                      _rowItem('assets/images/icon/p8.png', '关于我们', trailing: Row(mainAxisSize: MainAxisSize.min, children: const [Text('最新版本', style: TextStyle(color: Colors.black45)), SizedBox(width: 6), Icon(Icons.chevron_right, color: Colors.grey)])),
                    ]),

                    

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
    final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage()));
    if (res == true) {
      setState(() {
        _loggedIn = true;
        _username = '赵德柱';
        _deviceCount = 3;
      });
    }
  }
}
