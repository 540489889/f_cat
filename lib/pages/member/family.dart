import 'package:flutter/material.dart';
import '../../services/home_api_service.dart';
import '../../shared/toast.dart';
import 'edit_family.dart';

/// 家庭/共享关联页面
///
/// 分为两种状态：
/// - 空状态：未加入任何家庭，展示引导创建
/// - 有数据：展示家庭信息、成员、关联设备
class FamilyPage extends StatefulWidget {
  const FamilyPage({super.key});

  @override
  State<FamilyPage> createState() => _FamilyPageState();
}

class _FamilyPageState extends State<FamilyPage> {
  bool _loading = true;

  // ---- 家庭数据 ----
  int _homeId = 0;
  String _familyName = '';
  String _avatar = '';
  bool _hasFamily = false;
  List<Map<String, String>> _members = []; // {avatar, name}
  int _deviceCount = 0;

  @override
  void initState() {
    super.initState();
    _loadFamilyData();
  }

  Future<void> _loadFamilyData() async {
    final result = await HomeApiService.getHomeInfo();

    if (!mounted) return;

    if (result.isSuccess && result.detail != null) {
      final data = result.detail!;
      setState(() {
        _hasFamily = true;
        _homeId = data['id'] as int? ?? 0;
        _familyName = data['name'] as String? ?? '';
        _avatar = data['avatar'] as String? ?? '';
        _deviceCount = 0; // TODO: 对接设备接口
        _members = []; // TODO: 对接成员接口
        _loading = false;
      });
    } else {
      // 未加入家庭
      setState(() {
        _hasFamily = false;
        _familyName = '';
        _members = [];
        _deviceCount = 0;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_left,
              color: Color(0xFF222222), size: 34),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        centerTitle: true,
        title: Text(
          _hasFamily ? _familyName : '共享关联',
          style: const TextStyle(
            color: Color(0xFF222222),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _hasFamily
              ? _buildHasFamily()
              : _buildEmpty(),
    );
  }

  // ==================== 空状态 ====================

  Widget _buildEmpty() {
    return SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.all(15),
        padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Container(
              alignment: Alignment.center,
              child: Image.asset(
                'assets/images/icon/home-i-3.png',
                width: 132,
                height: 132,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              '还没有加入任何家庭哦~',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 12),
            // 副文案
            const Text(
              '创建家庭，邀请TA加入',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF999999),
              ),
            ),
            const SizedBox(height: 48),
            // 创建家庭按钮
            GestureDetector(
              onTap: _onCreateFamily,
              child: Container(
                width: 260,
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF7A47), Color(0xFFFF5C2E)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF7A47).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    '创建家庭',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== 有家庭数据 ====================

  Widget _buildHasFamily() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 12),

                // -- 家庭名称卡片 --
                _buildCard(
                  children: [
                    _buildRow(
                      title: _familyName,
                      trailing: const Icon(Icons.chevron_right,
                          color: Color(0xFFCCCCCC)),
                      onTap: _onEditFamilyName,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // -- 家庭成员卡片 --
                if (_members.isNotEmpty)
                  _buildCard(
                    title: '家庭成员',
                    children: [
                      ..._members.asMap().entries.map((e) {
                        final isLast = e.key == _members.length - 1;
                        return Column(
                          children: [
                            _buildMemberRow(e.value),
                            if (!isLast)
                              const Divider(
                                  height: 1,
                                  indent: 52,
                                  color: Color(0xFFF5F5F5)),
                          ],
                        );
                      }),
                    ],
                  ),
                // const SizedBox(height: 12),

                // -- 关联设备卡片 --
                // _buildCard(
                //   children: [
                //     _buildRow(
                //       title: '关联设备',
                //       trailing: Row(
                //         mainAxisSize: MainAxisSize.min,
                //         children: [
                //           Text(
                //             '$_deviceCount个设备',
                //             style: const TextStyle(
                //                 color: Color(0xFF999999), fontSize: 14),
                //           ),
                //           const SizedBox(width: 4),
                //           const Icon(Icons.chevron_right,
                //               color: Color(0xFFCCCCCC)),
                //         ],
                //       ),
                //       onTap: _onTapDevice,
                //     ),
                //   ],
                // ),
              ],
            ),
          ),
        ),

        // -- 邀请成员按钮（固定在底部） --
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: GestureDetector(
            onTap: _onInviteMember,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF7A47), Color(0xFFFF5C2E)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF7A47).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  '邀请成员',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==================== 通用组件 ====================

  /// 白色圆角卡片
  Widget _buildCard({
    String? title,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Padding(
              padding:
                  const EdgeInsets.only(left: 16, top: 16, bottom: 4),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF5F5F5)),
          ],
          ...children,
        ],
      ),
    );
  }

  /// 点击行
  Widget _buildRow({
    Widget? leading,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            if (leading != null) ...[
              leading,
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                    fontSize: 16, color: Color(0xFF333333)),
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }

  /// 成员行（带头像）
  Widget _buildMemberRow(Map<String, String> member) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // 头像
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFFFF3EE),
            backgroundImage: (member['avatar'] != null &&
                    member['avatar']!.isNotEmpty)
                ? NetworkImage(member['avatar']!)
                : null,
            child: (member['avatar'] == null || member['avatar']!.isEmpty)
                ? const Icon(Icons.person, size: 22, color: Color(0xFFFF7A47))
                : null,
          ),
          const SizedBox(width: 12),
          // 名字
          Text(
            member['name'] ?? '',
            style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF333333),
                fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          // 角色标签
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3EE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              '成员',
              style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFFFF7A47),
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== 交互 ====================

  void _onCreateFamily() {
    // TODO: 跳转创建家庭页面
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('创建家庭')),
    );
  }

  void _onInviteMember() {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (_) => _InviteMemberDialog(
        homeId: _homeId,
        scaffoldMessenger: scaffoldMessenger,
      ),
    );
  }

  void _onEditFamilyName() async {
    final result = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        builder: (_) => EditFamilyPage(
          homeId: _homeId,
          name: _familyName,
          avatar: _avatar,
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        if (result.containsKey('name')) _familyName = result['name']!;
        if (result.containsKey('avatar')) _avatar = result['avatar']!;
      });
    }
  }

  void _onTapDevice() {
    // TODO: 跳转关联设备页面
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('关联设备')),
    );
  }
}

// ==================== 邀请成员弹窗 ====================

class _InviteMemberDialog extends StatefulWidget {
  final int homeId;
  final ScaffoldMessengerState scaffoldMessenger;
  const _InviteMemberDialog({
    required this.homeId,
    required this.scaffoldMessenger,
  });

  @override
  State<_InviteMemberDialog> createState() => _InviteMemberDialogState();
}

class _InviteMemberDialogState extends State<_InviteMemberDialog> {
  final TextEditingController _mobileController = TextEditingController();
  bool _sending = false;
  bool _isValid = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _mobileController.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _mobileController.removeListener(_onInputChanged);
    _mobileController.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    final text = _mobileController.text.trim();
    final valid = RegExp(r'^1[3-9]\d{9}$').hasMatch(text);
    if (valid != _isValid || _errorMsg != null) {
      setState(() {
        _isValid = valid;
        _errorMsg = null;
      });
    }
  }

  Future<void> _onInvite() async {
    if (!_isValid) return;

    final mobile = _mobileController.text.trim();

    setState(() => _sending = true);

    final result = await HomeApiService.inviteMember(
      homeId: widget.homeId,
      mobile: mobile,
    );

    if (!mounted) return;

    if (result.isSuccess) {
      Toast.show(context, '邀请成功');
      Navigator.pop(context);
    } else {
      setState(() {
        _sending = false;
        _errorMsg = result.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 顶部：关闭按钮
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Color(0xFF999999), size: 22),
                onPressed: _sending ? null : () => Navigator.pop(context),
              ),
            ),
            // 标题
            const Text(
              '邀请家庭成员',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF222222),
              ),
            ),
            const SizedBox(height: 8),
            // 副标题
            const Text(
              '你想把爱宠分享给谁',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF999999),
              ),
            ),
            // 错误提示
            if (_errorMsg != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMsg!,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFFFF4759),
                ),
              ),
            ],
            const SizedBox(height: 24),
            // 输入框
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: _mobileController,
                keyboardType: TextInputType.phone,
                textAlign: TextAlign.center,
                enabled: !_sending,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF333333),
                ),
                decoration: const InputDecoration(
                  hintText: '请输入手机号码',
                  hintStyle: TextStyle(
                    fontSize: 15,
                    color: Color(0xFFCCCCCC),
                  ),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 28),
            // 邀请按钮
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              width: double.infinity,
              height: 48,
              child: GestureDetector(
                onTap: (_isValid && !_sending) ? _onInvite : null,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: (_isValid && !_sending)
                        ? const LinearGradient(
                            colors: [Color(0xFFFF7A47), Color(0xFFFF5C2E)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          )
                        : const LinearGradient(
                            colors: [Color(0xFFCCCCCC), Color(0xFFCCCCCC)],
                          ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: (_isValid && !_sending)
                        ? [
                            BoxShadow(
                              color: const Color(0xFFFF7A47).withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: _sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            '邀请',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
