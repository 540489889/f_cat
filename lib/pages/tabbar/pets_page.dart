import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../information/water.dart';

class PetsPage extends StatefulWidget {
  const PetsPage({super.key});

  @override
  State<PetsPage> createState() => _PetsPageState();
}

class _PetsPageState extends State<PetsPage> {
  // dynamic metrics 0..5
  final Map<String, double> _metrics = {
    '贪吃': 4,
    '规律': 4,
    '活跃': 5,
    '饮水': 3,
    '亲人': 3,
  };

  Widget _petCard(String name, String age, String weight) {
    return Container(
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
            decoration: BoxDecoration(color: const Color(0xFFF7F2EE), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.pets, size: 40, color: Color(0xFFFF8A65)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Row(children: [const Icon(Icons.cake, size: 14, color: Colors.grey), const SizedBox(width: 6), Text(age, style: const TextStyle(color: Colors.black54))]),
                const SizedBox(height: 4),
                Row(children: [const Icon(Icons.monitor_weight, size: 14, color: Colors.grey), const SizedBox(width: 6), Text(weight, style: const TextStyle(color: Colors.black54))]),
              ],
            ),
          )
        ],
      ),
    );
  }


  Widget _statCard(IconData icon, String title, String value, double progress, {Color color = const Color(0xFF4FC3F7), VoidCallback? onTap}) {
    final card = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, color: color), const SizedBox(width: 8), Text(title, style: const TextStyle(fontSize: 12))]),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: progress, color: color, backgroundColor: const Color(0xFFF0F0F0)),
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
      color: const Color(0xFFFBF6F2),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                // 左边占位，和右边 IconButton 同宽
                const SizedBox(width: 48),
                // 中间文字居中
                Expanded(
                  child: Center(
                    child: Text(
                      '宠物',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                // 右边图标
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // horizontal pet list
                    SizedBox(
                      height: 110,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          _petCard('超级小虎妞', '2岁', '3.3kg'),
                          _petCard('旺财', '2岁', '3.3kg'),
                        ],
                      ),
                    ),
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
                      child: GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _statCard(Icons.water_drop, '饮水', '180 ml', 0.8, color: const Color(0xFF42A5F5), onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const WaterPage()));
                          }),
                          _statCard(Icons.restaurant, '进食', '280 g', 0.25, color: const Color(0xFFFFA726)),
                          _statCard(Icons.sports_tennis, '运动', '2 h 15 min', 0.6, color: const Color(0xFF66BB6A)),
                          _statCard(Icons.emoji_food_beverage, '排便', '3 次', 0.9, color: const Color(0xFFAB47BC)),
                          _statCard(Icons.nights_stay, '睡眠', '3.8 h', 0.75, color: const Color(0xFF42A5F5)),
                          _statCard(Icons.monitor_weight, '体重', '3.5 kg', 0.9, color: const Color(0xFFFF7043)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [Text('性格养成', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), Text('全部', style: TextStyle(color: Colors.black54))]),
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

