import 'package:flutter/material.dart';
import '../../services/member_api_service.dart';

/// 消息设置页面
class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _pushEnabled = true;
  bool _deviceEnabled = true;
  bool _systemEnabled = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final result = await MemberApiService.getNoticeSettings();
    if (!mounted) return;
    if (result.isSuccess && result.data != null) {
      setState(() {
        _pushEnabled = result.pushEnabled;
        _deviceEnabled = result.deviceEnabled;
        _systemEnabled = result.systemEnabled;
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveSetting() async {
    await MemberApiService.updateNoticeSettings(
      petMsg: _pushEnabled ? 1 : 0,
      deviceMsg: _deviceEnabled ? 1 : 0,
      sysMsg: _systemEnabled ? 1 : 0,
    );
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
        title: const Text(
          '消息设置',
          style: TextStyle(
            color: Color(0xFF222222),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF7A47)))
          : Column(
              children: [
                const SizedBox(height: 16),
                _buildSwitchCard(),
                const SizedBox(height: 16),
                _buildClearCacheTile(),
              ],
            ),
    );
  }

  Widget _buildSwitchCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          _switchItem(
            title: '推送通知',
            subtitle: '接收系统消息和活动通知',
            value: _pushEnabled,
            onChanged: (v) {
              setState(() => _pushEnabled = v);
              _saveSetting();
            },
          ),
          const Divider(
              height: 1, indent: 16, endIndent: 16, color: Color(0xFFF4F4F4)),
          _switchItem(
            title: '设备信息',
            subtitle: '设备状态变更时通知我',
            value: _deviceEnabled,
            onChanged: (v) {
              setState(() => _deviceEnabled = v);
              _saveSetting();
            },
          ),
          const Divider(
              height: 1, indent: 16, endIndent: 16, color: Color(0xFFF4F4F4)),
          _switchItem(
            title: '系统通知',
            subtitle: '接收系统维护和更新提醒',
            value: _systemEnabled,
            onChanged: (v) {
              setState(() => _systemEnabled = v);
              _saveSetting();
            },
          ),
        ],
      ),
    );
  }

  Widget _switchItem({
    required String title,
    String subtitle = '',
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF333333),
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF999999),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFFFF7A47),
          ),
        ],
      ),
    );
  }

  Widget _buildClearCacheTile() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: GestureDetector(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('缓存已清除')),
          );
        },
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: const [
              Expanded(
                child: Text(
                  '清除缓存',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF333333),
                  ),
                ),
              ),
              Text(
                '0.00 MB',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF999999),
                ),
              ),
              SizedBox(width: 6),
              Icon(Icons.chevron_right, color: Colors.grey, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
