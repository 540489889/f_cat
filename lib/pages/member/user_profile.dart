import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'nickname.dart';
import '../../services/user_state.dart';
import '../../services/home_state.dart';
import '../../services/api_client.dart';
import '../../services/member_api_service.dart';
import '../../shared/image_picker_dialog.dart';

/// 用户资料页
class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  // 当前头像（network/asset 字符串，或 File 对象）
  dynamic _currentAvatar = 'assets/images/pet_avatar.png';
  // 昵称
  String _nickname = '';
  // 生日
  DateTime? _birthday;

  @override
  void initState() {
    super.initState();
    final userState = context.read<UserState>();
    _nickname = userState.username;
    final headimg = userState.userInfo?['headimg'];
    if (headimg != null && headimg is String && headimg.startsWith('http')) {
      _currentAvatar = headimg;
    }
    final birthdayStr = userState.userInfo?['birthday'];
    if (birthdayStr != null && birthdayStr is String) {
      _birthday = DateTime.tryParse(birthdayStr);
    }
  }

  /// 显示当前头像
  Widget _buildCurrentAvatar() {
    if (_currentAvatar is File) {
      return ClipOval(
        child: Image.file(_currentAvatar, width: 56, height: 56, fit: BoxFit.cover),
      );
    }
    if (_currentAvatar is String && (_currentAvatar as String).startsWith('http')) {
      return ClipOval(
        child: Image.network(_currentAvatar, width: 56, height: 56, fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Image.asset('assets/images/pet_avatar.png', width: 56, height: 56, fit: BoxFit.cover),
        ),
      );
    }
    return ClipOval(
      child: Image.asset(_currentAvatar, width: 56, height: 56, fit: BoxFit.cover),
    );
  }

  /// 弹出头像选择弹窗
  void _showAvatarSheet() {
    _pickFromGallery();
  }

  /// 从相册选择并上传
  Future<void> _pickFromGallery() async {
    final source = await showImagePickerDialog(context);
    if (source == null) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked != null && mounted) {
      setState(() {
        _currentAvatar = File(picked.path);
      });
      // 上传头像
      final result = await ApiClient.instance.uploadFile(
        '/app/user/file/upload',
        filePath: picked.path,
        fileField: 'file',
        extraFields: {'scene': 'avatar'},
      );
      if (!mounted) return;
      if (result.isSuccess && result.data != null) {
        final url = result.data is String
            ? result.data as String
            : result.asMap['url']?.toString() ?? '';
        if (url.isNotEmpty) {
          setState(() => _currentAvatar = url);
          _updateMemberInfo(headimg: url);
        }
      }
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
    if (picked != null) {
      setState(() => _birthday = picked);
      _updateMemberInfo(birthday: picked);
    }
  }

  /// 调用后端更新会员信息
  Future<void> _updateMemberInfo({
    String? nickname,
    String? headimg,
    DateTime? birthday,
  }) async {
    final result = await MemberApiService.updateMemberInfo(
      nickname: nickname,
      headimg: headimg,
      birthday: birthday,
    );
    if (!mounted) return;
    if (result.isSuccess) {
      if (nickname != null) {
        setState(() => _nickname = nickname);
        context.read<UserState>().setUsername(nickname);
      }
      if (headimg != null) {
        context.read<UserState>().updateUserInfo({'headimg': headimg});
      }
      if (birthday != null) {
        context.read<UserState>().updateUserInfo({'birthday': birthday.toIso8601String()});
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    }
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
      final userState = context.read<UserState>();
      final homeState = context.read<HomeState>();
      homeState.reset();
      await userState.logout();
      // AuthGate 已重建为 LoginPage，但 UserProfilePage 还压在根 Navigator 上面
      // popUntil 回到根路由，露出 AuthGate 的 LoginPage
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
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
                const SizedBox(height: 12),
                _buildAccountCard(),
                const SizedBox(height: 12),
                _buildDeleteAccountCard(),
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
            value: _nickname,
            showArrow: true,
            onTap: () async {
              final result = await Navigator.push<String>(
                context,
                MaterialPageRoute(builder: (_) => NicknamePage(initialNickname: _nickname)),
              );
              if (result != null && result.isNotEmpty && mounted) {
                _updateMemberInfo(nickname: result);
              }
            },
          ),
          const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF0F0F0)),
          // _buildInfoRow(
          //   icon: Icons.wc_outlined,
          //   title: '性别',
          //   showArrow: true,
          //   onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GenderPage())),
          // ),
          // const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF0F0F0)),
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

  /// 账户管理卡片
  Widget _buildAccountCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.phone_android_outlined,
            title: '手机号码',
            value: '未绑定',
            showArrow: true,
            onTap: () {
              // TODO: 绑定手机号码
            },
          ),
          const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF0F0F0)),
          _buildInfoRow(
            icon: Icons.wechat_outlined,
            title: '微信授权',
            value: '未授权',
            showArrow: true,
            onTap: () {
              // TODO: 微信授权
            },
          ),
          const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF0F0F0)),
          _buildInfoRow(
            icon: Icons.apple,
            title: 'AppleID',
            value: '未绑定',
            showArrow: true,
            onTap: () {
              // TODO: 绑定AppleID
            },
          ),
          const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF0F0F0)),
          _buildInfoRow(
            icon: Icons.system_update_outlined,
            title: '检查更新',
            value: '最新版本',
            showArrow: true,
            onTap: () {
              // TODO: 检查更新逻辑
            },
          ),
        ],
      ),
    );
  }

  /// 注销账户卡片
  Widget _buildDeleteAccountCard() {
    return GestureDetector(
      onTap: () {
        // TODO: 注销账户逻辑
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.delete_outline, size: 20, color: Color(0xFFE53935)),
            SizedBox(width: 12),
            Text(
              '注销账户',
              style: TextStyle(fontSize: 16, color: Color(0xFFE53935)),
            ),
            Spacer(),
            Icon(Icons.chevron_right, size: 20, color: Colors.black26),
          ],
        ),
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
    Color? titleColor,
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor ?? const Color(0xFFFF7A47)),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(fontSize: 16, color: titleColor ?? Colors.black87),
            ),
            const Spacer(),
            if (value != null)
              Text(
                value,
                style: const TextStyle(fontSize: 15, color: Colors.black54),
              ),
            if (showArrow) ...[
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 20, color: iconColor?.withValues(alpha: 0.26) ?? Colors.black26),
            ],
          ],
        ),
      ),
    );
  }
}
