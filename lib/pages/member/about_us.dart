import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/api_config.dart';

/// 关于我们页面
class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

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
          '关于我们',
          style: TextStyle(
            color: Color(0xFF222222),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  // Logo
                  _buildLogo(),
                  const SizedBox(height: 16),
                  // 应用名称
                  const Text(
                    '只创宠物',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF222222),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Slogan
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      '毛孩温柔爪印 · AI智能相伴 · 悦享舒心养宠',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF999999),
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // 选项列表
                  _buildOptionCard(context),
                ],
              ),
            ),
          ),
          // 底部版权信息
          _buildCopyright(),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Image.asset(
      'assets/images/logo.png',
      width: 88,
      height: 88,
    );
  }

  Widget _buildOptionCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          _optionItem(
            title: '用户协议',
            onTap: () => _launchUrl(context, ApiConfig.userAgreementUrl),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF4F4F4)),
          _optionItem(
            title: '隐私政策',
            onTap: () => _launchUrl(context, ApiConfig.privacyUrl),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF4F4F4)),
          _optionItem(
            title: '关于我们',
            onTap: () => _launchUrl(context, ApiConfig.companyUrl),
          ),
        ],
      ),
    );
  }

  Widget _optionItem({required String title, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF333333),
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  static Future<void> _launchUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('无法打开链接')),
        );
      }
    }
  }

  Widget _buildCopyright() {
    return Container(
      padding: const EdgeInsets.only(bottom: 32, top: 16),
      child: Column(
        children: [
          const Text(
            'Copyright@2016-2025',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF999999),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '只创(深圳)智能科技有限公司版权所有',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF999999),
            ),
          ),
        ],
      ),
    );
  }
}
