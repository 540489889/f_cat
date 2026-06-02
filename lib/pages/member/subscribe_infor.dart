import 'package:flutter/material.dart';

class SubscribeInforPage extends StatelessWidget {
  const SubscribeInforPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black87), onPressed: () => Navigator.of(context).pop()),
        centerTitle: true,
        title: const Text('订阅服务权益详情', style: TextStyle(color: Colors.black87)),
      ),
      backgroundColor: const Color(0xFFFDF7F3),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFFFF6F2), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  CircleAvatar(radius: 28, backgroundColor: Colors.white, child: Icon(Icons.person, color: Colors.orangeAccent)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('赵德柱', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 6),
                        Text('会员 到期：2026/07/30', style: TextStyle(color: Colors.black54)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (ctx) {
                            int selected = 0;
                            return StatefulBuilder(builder: (context, setState) {
                              return DraggableScrollableSheet(
                                initialChildSize: 0.46,
                                minChildSize: 0.3,
                                maxChildSize: 0.9,
                                builder: (_, controller) => Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                                  child: Column(
                                    children: [
                                      Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                                      const SizedBox(height: 12),
                                      const Text('购买会员', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 12),
                                      // plans
                                      SizedBox(
                                        height: 180,
                                        child: Row(
                                          children: List.generate(3, (i) {
                                            final titles = ['限时', '优惠', '超值'];
                                            final subs = ['月度会员', '季度会员', '年度会员'];
                                            final prices = ['¥49', '¥129', '¥299'];
                                            final saves = ['立即省 30 元', '立即省 30 元', '立即省 30 元'];
                                            final bool active = i == selected;
                                            return Expanded(
                                              child: GestureDetector(
                                                onTap: () => setState(() => selected = i),
                                                child: Container(
                                                  margin: const EdgeInsets.symmetric(horizontal: 6),
                                                  padding: const EdgeInsets.all(12),
                                                  decoration: BoxDecoration(
                                                    color: active ? const Color(0xFFFFF2E8) : Colors.white,
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(color: active ? const Color(0xFFFFA07A) : const Color(0xFFF0F0F0)),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), decoration: BoxDecoration(color: active ? const Color(0xFFFF8A65) : const Color(0xFFF6F6F6), borderRadius: BorderRadius.circular(12)), child: Text(titles[i], style: TextStyle(color: active ? Colors.white : Colors.black54))),
                                                      const SizedBox(height: 8),
                                                      Text(subs[i], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                                      const Spacer(),
                                                      Text(prices[i], style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: active ? const Color(0xFFFF8A65) : Colors.black)),
                                                      const SizedBox(height: 6),
                                                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), decoration: BoxDecoration(color: const Color(0xFFFFF4F0), borderRadius: BorderRadius.circular(12)), child: Text(saves[i], style: const TextStyle(fontSize: 12, color: Color(0xFFFF8A65)))),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          }),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            // TODO: integrate payment flow
                                            Navigator.of(context).pop();
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFFFF8A65),
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                          ),
                                          child: const Text('续费', style: TextStyle(fontSize: 16)),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text('成为会员即表示已阅读并同意 《增值服务协议》', style: TextStyle(color: Colors.black45, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              );
                            });
                          },
                        );
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8A65), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                      child: const Text('续费'))
                ],
              ),
            ),

            const SizedBox(height: 12),

            // icons row
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _FeatureItem(icon: Icons.hd, label: '完整视频回看', desc: '不错过重要时刻'),
                  _FeatureItem(icon: Icons.video_collection, label: '每日精彩短片', desc: '智能剪辑萌宠日常'),
                  _FeatureItem(icon: Icons.cloud, label: '超大云储空间', desc: '安全存储更省心'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // benefit cards
            _BenefitCard(index: 1, title: '完整视频回看', body: '智能识别萌宠自动录像，完整记录爱宠日常点滴。可选 3 天 / 7 天云端留存，支持 ISO27001 加密传输与存储。', image: 'assets/images/device/device1.png'),
            const SizedBox(height: 12),
            _BenefitCard(index: 2, title: '每日精彩短片', body: '自动汇总昨日萌宠日常，一键生成 30 秒趣味短片，支持分享与下载。', image: 'assets/images/device/device2.png'),
            const SizedBox(height: 12),
            _BenefitCard(index: 3, title: '超大云储空间', body: '实拍视频足量存储，海量萌宠影像随心存。全程加密保护，隐私无忧。', image: 'assets/images/device/device3.png'),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8A65), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))),
                child: const Text('续费', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
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
    return Column(
      children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFFFF2EC), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: const Color(0xFFFF8A65))),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(desc, style: const TextStyle(color: Colors.black54), textAlign: TextAlign.center),
      ],
    );
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), decoration: BoxDecoration(color: const Color(0xFFFFF0E8), borderRadius: BorderRadius.circular(6)), child: Text('权益 $index', style: const TextStyle(color: Color(0xFFFF8A65)))),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 8),
          Container(height: 120, decoration: BoxDecoration(color: const Color(0xFFFFF7F3), borderRadius: BorderRadius.circular(8)), child: Center(child: Image.asset(image, width: 180, fit: BoxFit.contain))),
          const SizedBox(height: 8),
          Text(body, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}
