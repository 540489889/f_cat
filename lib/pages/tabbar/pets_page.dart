import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../information/water.dart';
import '../pet/add.dart';
import '../pet/information.dart';

class PetsPage extends StatefulWidget {
  const PetsPage({super.key});

  @override
  State<PetsPage> createState() => _PetsPageState();
}

class _PetsPageState extends State<PetsPage> {
  // 宠物数据列表
  static final List<_PetItem> _pets = [
    // _PetItem(name: '超级小虎妞', age: '2岁', weight: '3.3kg', avatar: 'assets/images/pet_avatar.png'),
    // _PetItem(name: '旺财', age: '2岁', weight: '3.3kg', avatar: 'assets/images/pet_avatar.png'),
  ];

  // dynamic metrics 0..5
  final Map<String, double> _metrics = {
    '贪吃': 4,
    '规律': 4,
    '活跃': 5,
    '饮水': 3,
    '亲人': 3,
  };

  Widget _petCard(String name, String age, String weight, String avatar) {
    final card = Container(
      width: 220,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F2EE),
              borderRadius: BorderRadius.circular(50),
            ),
            // 关键：用 Stack 包裹！！！
            child: Stack(
              children: [
                // 中间的头像
                Center(
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(avatar),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),

                // ======================
                // 右下角性别图标（现在可以正常显示）
                // ======================
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Color(0xFF4D8FFF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.male,
                      size: 15,
                      color: Color.fromARGB(255, 255, 255, 255),
                      // color: Color(0xFFFF78A6), // 女生粉色
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Row(children: [Image.asset(
                    "assets/images/icon/birthday-ico.png",
                    width: 15,
                    height: 15,
                    // color: Color(0xFFFF8A65),      // 可以给图片上色（不需要就删掉这行）
                  ), const SizedBox(width: 6), Text(age, style: const TextStyle(color: Colors.black54))]),
                const SizedBox(height: 2),
                Row(children: [Image.asset(
                    "assets/images/icon/weight-ico.png",
                    width: 15,
                    height: 15,
                    // color: Color(0xFFFF8A65),      // 可以给图片上色（不需要就删掉这行）
                  ), const SizedBox(width: 6), Text(weight, style: const TextStyle(color: Colors.black54))]),
              ],
            ),
          )
        ],
      ),
    );

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const InformationPage()));
      },
      child: card,
    );
  }

  Widget _statCard(String imagePath, String title, String value, double progress, {Color color = const Color(0xFF4FC3F7), VoidCallback? onTap}) {
    final card = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Image.asset(imagePath, width: 30, height: 30), const SizedBox(width: 8), Text(title, style: const TextStyle(fontSize: 12))]),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          
          Container(
             child:SizedBox(
                child: LinearProgressIndicator(value: progress, color: color, backgroundColor: const Color(0xFFF0F0F0)),
             )
          
          )
          
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: card);
    }

    return card;
  }

  Widget _ratingRow(String label, double stars) {
    final int filled = stars.clamp(0, 5).toInt();
    return Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(color: Colors.black87))),
        Row(children: List.generate(5, (i) => Icon(i < filled ? Icons.star : Icons.star_border, color: const Color(0xFFFFA726), size: 16))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
       decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFAF2), Color(0xFFF2F2F2)],
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
                  const SizedBox(width: 36),
                  const Expanded(
                    child: Center(
                      child: Text(
                        '宠物',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPetPage()));
                    },
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // horizontal pet list / empty state
                    if (_pets.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Image.asset(
                                'assets/images/icon/home-i-1.png',
                                width: 93,
                                height: 100,
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                '请先创建宠物资料',
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                '创建宠物资料，记录萌宠的美好生活~',
                                style: TextStyle(fontSize: 14, color: Colors.black45),
                              ),
                              const SizedBox(height: 28),
                              SizedBox(
                                width: 200,
                                height: 46,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPetPage()));
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFF8A65),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)),
                                    elevation: 0,
                                  ),
                                  child: const Text('立即添加宠物', style: TextStyle(fontSize: 16)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        height: 110,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: _pets.map((p) => _petCard(p.name, p.age, p.weight, p.avatar)).toList(),
                        ),
                      ),
                    if (_pets.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: const [Icon(Icons.insert_chart, color: Color(0xFFFF8A65)), SizedBox(width: 8), Text('今日数据', style: TextStyle(fontWeight: FontWeight.bold))],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: 
                         SizedBox(
                           child: GridView.count(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              shrinkWrap: true,
                               childAspectRatio: 1.5, 
                              physics: const NeverScrollableScrollPhysics(),
                              children: [
                                _statCard('assets/images/icon/d1.png', '饮水', '180 ml', 0.8, color: const Color(0xFF42A5F5), onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const WaterPage()));
                                }),
                                _statCard('assets/images/icon/d2.png', '进食', '280 g', 0.25, color: const Color(0xFFFFA726)),
                                _statCard('assets/images/icon/d3.png', '运动', '2 h 15 min', 0.6, color: const Color(0xFF66BB6A)),
                                _statCard('assets/images/icon/d4.png', '排便', '3 次', 0.9, color: const Color(0xFFAB47BC)),
                                _statCard('assets/images/icon/d5.png', '睡眠', '3.8 h', 0.75, color: const Color(0xFF42A5F5)),
                                _statCard('assets/images/icon/d6.png', '体重', '3.5 kg', 0.9, color: const Color(0xFFFF7043)),
                              ],
                            ),
                         )
                        
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_pets.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                            children: const [Text('性格养成', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), 
                            Text('全部', style: TextStyle(color: Colors.black54))]),
                            const SizedBox(height: 12),
                            Container(
                              // padding: const EdgeInsets.all(10),
                              // decoration: BoxDecoration(color: const Color(0xFFFFF4F0), borderRadius: BorderRadius.circular(10)),
                              child: Column(
                                children: [
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF4F0),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      'AI解读：虎妞是个特别守时的乖宝宝，吃饭从不迟到，就是有点不爱喝水。',
                                      style: TextStyle(color: Color(0xFF7F7F7F)),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                       const SizedBox(width: 10),
                                      Container(
                                        width: 120,
                                        height: 120,
                                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                                        child: CustomPaint(
                                          painter: _RadarPainter(Map.from(_metrics)),
                                        ),
                                      ),
                                      const SizedBox(width: 40),
                                      Expanded(
                                        child: Column(
                                          children: [
                                            _ratingRow('贪吃', 4),
                                            const SizedBox(height: 6),
                                            _ratingRow('规律', 4),
                                            const SizedBox(height: 6),
                                            _ratingRow('活跃', 5),
                                            const SizedBox(height: 6),
                                            _ratingRow('饮水', 3),
                                            const SizedBox(height: 6),
                                            _ratingRow('亲人', 3),
                                          ],
                                        ),
                                      )
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final Map<String, double> metrics;
  _RadarPainter(this.metrics);

  @override
  void paint(Canvas canvas, Size size) {
    final paintGrid = Paint()..color = Colors.grey.withValues(alpha: 0.12)..style = PaintingStyle.stroke;
    final paintAxis = Paint()..color = Colors.grey.withValues(alpha: 0.2)..style = PaintingStyle.stroke;
    final paintFill = Paint()..color = const Color(0xFFFFCCAB).withValues(alpha: 0.35)..style = PaintingStyle.fill;
    final paintBorder = Paint()..color = const Color(0xFFFF8A65)..style = PaintingStyle.stroke..strokeWidth = 2;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final center = Offset(cx, cy);
    final radius = (size.shortestSide / 2) - 8;

    final entries = metrics.entries.toList();
    final int points = entries.length;
    if (points == 0) return;

    // concentric levels
    for (int level = 1; level <= 5; level++) {
      final path = Path();
      for (int i = 0; i < points; i++) {
        final angle = (i / points) * 2 * math.pi - math.pi / 2;
        final r = radius * (level / 5);
        final x = cx + r * math.cos(angle);
        final y = cy + r * math.sin(angle);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, paintGrid);
    }

    final dataPath = Path();
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < points; i++) {
      final e = entries[i];
      final angle = (i / points) * 2 * math.pi - math.pi / 2;
      final x = cx + radius * math.cos(angle);
      final y = cy + radius * math.sin(angle);
      canvas.drawLine(center, Offset(x, y), paintAxis);

      // label
      textPainter.text = TextSpan(text: e.key, style: const TextStyle(color: Colors.black54, fontSize: 10));
      textPainter.layout();
      final lx = cx + (radius + 6) * math.cos(angle) - textPainter.width / 2;
      final ly = cy + (radius + 6) * math.sin(angle) - textPainter.height / 2;
      textPainter.paint(canvas, Offset(lx, ly));

      final valueR = (e.value.clamp(0.0, 5.0) / 5.0) * radius;
      final dxp = cx + valueR * math.cos(angle);
      final dyp = cy + valueR * math.sin(angle);
      if (i == 0) {
        dataPath.moveTo(dxp, dyp);
      } else {
        dataPath.lineTo(dxp, dyp);
      }
    }
    dataPath.close();

    canvas.drawPath(dataPath, paintFill);
    canvas.drawPath(dataPath, paintBorder);
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) => oldDelegate.metrics.toString() != metrics.toString();
}

class _PetItem {
  final String name;
  final String age;
  final String weight;
  final String avatar;
  const _PetItem({required this.name, required this.age, required this.weight, required this.avatar});
}


