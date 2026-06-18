import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'nickname.dart';
import 'gender.dart';
import '../../services/user_state.dart';
import '../../services/home_state.dart';

/// 头像选项
class _AvatarOption {
  final String name;
  final Widget icon;
  const _AvatarOption({required this.name, required this.icon});
}

/// 用户资料页
class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  // 当前头像（network/asset 字符串，或 File 对象）
  dynamic _currentAvatar = 'assets/images/pet_avatar.png';
  // 生日
  DateTime? _birthday;

  /// 预设头像选项
  static const List<_AvatarOption> _presetAvatars = [
    _AvatarOption(name: '毛毛狐', icon: Icon(Icons.pets, size: 36, color: Color(0xFFFF7043))),
    _AvatarOption(name: '跳跳蛙', icon: Icon(Icons.pest_control, size: 36, color: Color(0xFF66BB6A))),
    _AvatarOption(name: '抖抖鸟', icon: Icon(Icons.flutter_dash, size: 36, color: Color(0xFF42A5F5))),
    _AvatarOption(name: '趴趴猴', icon: Icon(Icons.energy_savings_leaf, size: 36, color: Color(0xFFAB47BC))),
    _AvatarOption(name: '灰灰狼', icon: Icon(Icons.dark_mode, size: 36, color: Color(0xFF8D6E63))),
  ];

  /// 当前选中的预设头像索引，-1 表示未选中
  int _selectedPreset = -1;

  /// 显示当前头像
  Widget _buildCurrentAvatar() {
    if (_currentAvatar is File) {
      return ClipOval(
        child: Image.file(_currentAvatar, width: 56, height: 56, fit: BoxFit.cover),
      );
    }
    return ClipOval(
      child: Image.asset(_currentAvatar, width: 56, height: 56, fit: BoxFit.cover),
    );
  }

  /// 弹出头像选择弹窗
  void _showAvatarSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '选择头像',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),
                // 预设头像（3 列 × 2 行）
                ...List.generate(2, (row) => Padding(
                  padding: EdgeInsets.only(bottom: row == 0 ? 16 : 0),
                  child: Row(
                    children: List.generate(3, (col) {
                      final i = row * 3 + col;
                      if (i >= _presetAvatars.length) {
                        return Expanded(
                        child: GestureDetector(
                          onTap: () => _pickFromGallery(ctx),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFFE0E0E0)),
                                ),
                                child: const Center(
                                  child: Icon(Icons.add, size: 30, color: Color(0xFFBDBDBD)),
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                '手动上传',
                                softWrap: false,
                                style: TextStyle(fontSize: 12, color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                      );
                      }
                      final selected = _selectedPreset == i;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setSheetState(() => _selectedPreset = i);
                            setState(() {
                              _selectedPreset = i;
                              _currentAvatar = 'assets/images/pet_avatar.png';
                            });
                            Navigator.pop(ctx);
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: selected ? const Color(0xFFFF7A47) : const Color(0xFFE0E0E0),
                                    width: selected ? 2.5 : 1,
                                  ),
                                ),
                                child: Center(child: _presetAvatars[i].icon),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _presetAvatars[i].name,
                                softWrap: false,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: selected ? const Color(0xFFFF7A47) : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                )),
                const SizedBox(height: 16),
                // 取消按钮
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.black54,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('取消', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 从相册选择
  Future<void> _pickFromGallery(BuildContext ctx) async {
    Navigator.pop(ctx);
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null && mounted) {
      setState(() {
        _selectedPreset = -1;
        _currentAvatar = File(picked.path);
      });
    }
  }

  /// 选择生日
  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthday ?? now,
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) setState(() => _birthday = picked);
  }

  Widget _buildLogoutButton() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: GestureDetector(
        onTap: _confirmLogout,
        child: const Center(
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.logout, size: 18, color: Color(0xFFE53935)),
            SizedBox(width: 6),
            Text('退出登录', style: TextStyle(fontSize: 16, color: Color(0xFFE53935), fontWeight: FontWeight.w500)),
          ]),
        ),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('退出登录'),
        content: const Text('确定要退出当前账号吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消', style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('退出登录', style: TextStyle(color: Color(0xFFE53935)))),
        ],
      ),
    );
    if (confirm == true && mounted) {
      context.read<HomeState>().reset();
      await context.read<UserState>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_left, color: Colors.black87, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text(
          '个人中心',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(children: [
                const SizedBox(height: 12),
                _buildAvatarRow(),
                const SizedBox(height: 12),
                _buildInfoCard(),
              ]),
            ),
          ),
          if (context.watch<UserState>().isLoggedIn)
            _buildLogoutButton(),
        ],
      ),
    );
  }

  /// 头像行
  Widget _buildAvatarRow() {
    return GestureDetector(
      onTap: _showAvatarSheet,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Text(
              '头像',
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const Spacer(),
            _buildCurrentAvatar(),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 20, color: Colors.black26),
          ],
        ),
      ),
    );
  }

  /// 信息卡片
  Widget _buildInfoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.person_outline,
            title: '昵称',
            value: '用户457559',
            showArrow: true,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NicknamePage())),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF0F0F0)),
          _buildInfoRow(
            icon: Icons.wc_outlined,
            title: '性别',
            showArrow: true,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GenderPage())),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF0F0F0)),
          _buildInfoRow(
            icon: Icons.calendar_today_outlined,
            title: '生日',
            value: _birthday != null
                ? '${_birthday!.year}-${_birthday!.month.toString().padLeft(2, '0')}-${_birthday!.day.toString().padLeft(2, '0')}'
                : null,
            showArrow: true,
            onTap: _pickBirthday,
          ),
        ],
      ),
    );
  }

  /// 信息行
  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    String? value,
    bool showArrow = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFFFF7A47)),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const Spacer(),
            if (value != null)
              Text(
                value,
                style: const TextStyle(fontSize: 15, color: Colors.black54),
              ),
            if (showArrow) ...[
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, size: 20, color: Colors.black26),
            ],
          ],
        ),
      ),
    );
  }
}
