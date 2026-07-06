import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'tabbar/pet_home_page.dart';
import 'tabbar/devices_page.dart';
import 'tabbar/my_page.dart';
import 'tabbar/pets_page.dart';
import '../services/tab_index_notifier.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  /// 全局 Key，用于外部切换 Tab
  static final GlobalKey<HomeShellState> globalKey = GlobalKey<HomeShellState>();

  @override
  State<HomeShell> createState() => HomeShellState();
}

class HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

  static const _tabs = [
    {'label': '管家', 'icon': 'assets/images/tabbar/home.png', 'activeIcon': 'assets/images/tabbar/home_active.png'},
    {'label': '宠物', 'icon': 'assets/images/tabbar/pet.png', 'activeIcon': 'assets/images/tabbar/pet_active.png'},
    {'label': '设备', 'icon': 'assets/images/tabbar/device.png', 'activeIcon': 'assets/images/tabbar/device_active.png'},
    {'label': '我的', 'icon': 'assets/images/tabbar/my_active.png', 'activeIcon': 'assets/images/tabbar/my.png'},
  ];

  static const _pages = [
    PetHomePage(),
    PetsPage(),
    DevicesPage(),
    MyPage(),
  ];

  /// 外部调用切换 Tab
  void switchToTab(int index) {
    setState(() => _selectedIndex = index.clamp(0, _pages.length - 1));
    context.read<TabIndexNotifier>().update(_selectedIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) {
          setState(() => _selectedIndex = i);
          context.read<TabIndexNotifier>().update(i);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFFFF7A47),
        unselectedItemColor: Colors.grey,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        items: _tabs.map((t) => BottomNavigationBarItem(
          icon: Image.asset(t['icon']!, width: 24, height: 24),
          activeIcon: Image.asset(t['activeIcon']!, width: 24, height: 24),
          label: t['label'],
        )).toList(),
      ),
    );
  }
}
