import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/member_api_service.dart';
import '../../services/vip_api_service.dart';
import '../../shared/throttle.dart';

class SubscribeInforPage extends StatefulWidget {
  const SubscribeInforPage({super.key});

  @override
  State<SubscribeInforPage> createState() => _SubscribeInforPageState();
}

class _SubscribeInforPageState extends State<SubscribeInforPage> {
  Map<String, dynamic>? _userInfo;
  List<VipPlan> _vipPlans = [];
  bool _loadingPlans = false;
  final _buyThrottle = ActionThrottle(interval: const Duration(seconds: 3));
  bool _sheetOpen = false;

  String get _nickname => _userInfo?['nickname'] as String? ?? '用户';
  String? get _avatar => _userInfo?['headimg'] as String?;
  String get _mobile => _userInfo?['mobile'] as String? ?? '';
  int get _vip => _userInfo?['vip'] as int? ?? 0;
  String? get _vipExpire => _userInfo?['vipExpire'] as String?;

  String get _vipText {
    if (_vip == 1 && _vipExpire != null) return '会员 到期：$_vipExpire';
    return '暂未开通会员';
  }

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final result = await MemberApiService.getMemberInfo();
    if (result.isSuccess && result.data != null) {
      if (mounted) setState(() { _userInfo = result.data; });
    } else {
      final info = await AuthService.getUserInfo();
      if (mounted) setState(() { _userInfo = info; });
    }
  }

  Future<void> _showBuySheet() async {
    if (_sheetOpen) return;
    await _buyThrottle.run(() async {
    _sheetOpen = true;
    setState(() => _loadingPlans = true);
    final vipResult = await VipApiService.getVipPlans();
    if (!mounted) return;
    setState(() { _vipPlans = vipResult.plans; _loadingPlans = false; });
    if (!mounted) return;

    await showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) {
        int selected = 0;
        int payMethod = 0; // 0=微信, 1=支付宝
        return StatefulBuilder(builder: (context, setState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.6, minChildSize: 0.5, maxChildSize: 0.9,
            builder: (_, controller) => Container(
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Column(children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 12),
                const Text('购买会员', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),
                SizedBox(height: 170, child: Row(children: _vipPlans.asMap().entries.map((e) {
                  final i = e.key;
                  final plan = e.value;
                  return Expanded(child: GestureDetector(
                    onTap: () => setState(() => selected = i),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6), padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                      decoration: BoxDecoration(color: i == selected ? const Color(0xFFFFF2E8) : Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: i == selected ? const Color(0xFFFF7A47) : const Color(0xFFEEEEEE), width: i == selected ? 1.5 : 1)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                        if (plan.tag != null)
                          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3), decoration: BoxDecoration(color: i == selected ? const Color(0xFFFF7A47) : const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(10)), child: Text(plan.tag!, style: TextStyle(fontSize: 12, color: i == selected ? Colors.white : Colors.black45, fontWeight: FontWeight.w500))),
                        const SizedBox(height: 10),
                        Text(plan.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text('¥${plan.price.toStringAsFixed(0)}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: i == selected ? const Color(0xFFFF7A47) : Colors.black87)),
                        Text('¥${plan.originalPrice.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: Colors.black38, decoration: TextDecoration.lineThrough)),
                        const SizedBox(height: 6),
                        if (plan.saveLabel != null)
                          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: i == selected ? const Color(0xFFFFF0E8) : const Color(0xFFFAFAFA), borderRadius: BorderRadius.circular(8)), child: Text(plan.saveLabel!, style: TextStyle(fontSize: 11, color: i == selected ? const Color(0xFFFF7A47) : Colors.black38))),
                      ])),
                  ));
                }).toList())),
                const SizedBox(height: 14),
                // 支付方式
                const Align(alignment: Alignment.centerLeft, child: Text('支付方式', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: GestureDetector(
                    onTap: () => setState(() => payMethod = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: payMethod == 0 ? const Color(0xFF09BB07) : const Color(0xFFE8E8E8), width: payMethod == 0 ? 1.5 : 1),
                      ),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Image.asset('assets/images/icon/login-1.png', width: 22, height: 22),
                        const SizedBox(width: 6),
                        Text('微信支付', style: TextStyle(fontSize: 13, color: payMethod == 0 ? const Color(0xFF333333) : const Color(0xFF999999), fontWeight: payMethod == 0 ? FontWeight.w600 : FontWeight.w400)),
                      ]),
                    ),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: GestureDetector(
                    onTap: () => setState(() => payMethod = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: payMethod == 1 ? const Color(0xFF1677FF) : const Color(0xFFE8E8E8), width: payMethod == 1 ? 1.5 : 1),
                      ),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Container(width: 22, height: 22, decoration: const BoxDecoration(color: Color(0xFF1677FF), shape: BoxShape.circle), child: const Center(child: Text('支', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)))),
                        const SizedBox(width: 6),
                        Text('支付宝', style: TextStyle(fontSize: 13, color: payMethod == 1 ? const Color(0xFF333333) : const Color(0xFF999999), fontWeight: payMethod == 1 ? FontWeight.w600 : FontWeight.w400)),
                      ]),
                    ),
                  )),
                ]),
                const SizedBox(height: 16),
                SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF7A47), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))), child: const Text('确认支付', style: TextStyle(fontSize: 16, color: Colors.white)))),
                const SizedBox(height: 8),
                const Text('成为会员即表示已阅读并同意 《增值服务协议》', style: TextStyle(color: Colors.black45, fontSize: 12)),
              ])),
          );
        });
      },
    );
    setState(() => _sheetOpen = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFAF2), elevation: 0,
        leading: IconButton(icon: const Icon(Icons.keyboard_arrow_left, color: Color(0xDD000000), size: 34), onPressed: () => Navigator.pop(context)),
        centerTitle: true,
        title: const Text('订阅服务权益详情', style: TextStyle(color: Colors.black87, fontSize: 17, fontWeight: FontWeight.w600)),
      ),
      backgroundColor: const Color(0xFFFFFAF2),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFAF2), Color(0xFFFFFAF2)],
          ),
        ),
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Container(
            decoration: BoxDecoration(color: const Color(0xFFFFC6B2), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFFC6B2), width: 1)),
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  CircleAvatar(radius: 28, backgroundColor: Colors.white, backgroundImage: _avatar != null && _avatar!.isNotEmpty ? NetworkImage(_avatar!) : null, child: (_avatar == null || _avatar!.isEmpty) ? const Icon(Icons.person, color: Colors.orangeAccent) : null),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_nickname, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(_vipText, style: TextStyle(color: _vip == 1 ? const Color(0xFFFF7A47) : Colors.black54, fontSize: 13)),
                  ])),
                  ElevatedButton(
                    onPressed: _showBuySheet,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF7A47), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                    child: Text(_vip == 1 ? '续费' : '开通会员', style: const TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ]),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(color: const Color(0xFFFEF3EB), borderRadius: BorderRadius.circular(12)),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                  _FeatureItem(icon: Icons.hd, label: '完整视频回看', desc: '不错过重要时刻'),
                  _FeatureItem(icon: Icons.video_collection, label: '每日精彩短片', desc: '智能剪辑萌宠日常'),
                  _FeatureItem(icon: Icons.cloud, label: '超大云储空间', desc: '安全存储更省心'),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          _BenefitCard(index: 1, title: '完整视频回看', body: '智能识别萌宠自动录像，完整记录爱宠日常点滴。可选 3 天 / 7 天云端留存，支持 ISO27001 加密传输与存储。', image: 'assets/images/device/device1.png'),
          const SizedBox(height: 12),
          _BenefitCard(index: 2, title: '每日精彩短片', body: '自动汇总昨日萌宠日常，一键生成 30 秒趣味短片，支持分享与下载。', image: 'assets/images/device/device2.png'),
          const SizedBox(height: 12),
          _BenefitCard(index: 3, title: '超大云储空间', body: '实拍视频足量存储，海量萌宠影像随心存。全程加密保护，隐私无忧。', image: 'assets/images/device/device3.png'),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: _showBuySheet,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF7A47), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))),
            child: Text(_vip == 1 ? '续费' : '开通会员', style: const TextStyle(fontSize: 16, color: Colors.white)),
          )),
        ]),
      ),
    ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String desc;
  const _FeatureItem({required this.icon, required this.label, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFFFF2EC), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: const Color(0xFFFF7A47))),
      const SizedBox(height: 8),
      Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      Text(desc, style: const TextStyle(color: Colors.black54, fontSize: 12), textAlign: TextAlign.center),
    ]);
  }
}

class _BenefitCard extends StatelessWidget {
  final int index;
  final String title;
  final String body;
  final String image;
  const _BenefitCard({required this.index, required this.title, required this.body, required this.image});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), decoration: BoxDecoration(color: const Color(0xFFFFF0E8), borderRadius: BorderRadius.circular(6)), child: Text('权益 $index', style: const TextStyle(color: Color(0xFFFF7A47)))),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 8),
        Container(height: 120, decoration: BoxDecoration(color: const Color(0xFFFFF7F3), borderRadius: BorderRadius.circular(8)), child: Center(child: Image.asset(image, width: 180, fit: BoxFit.contain))),
        const SizedBox(height: 8),
        Text(body, style: const TextStyle(color: Colors.black54)),
      ]),
    );
  }
}
