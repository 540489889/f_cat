import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'package:easy_refresh/easy_refresh.dart';
import '../information/water.dart';
import '../pet/add.dart';
import '../pet/information.dart';
import '../../services/pet_state.dart';

class PetsPage extends StatefulWidget {
  const PetsPage({super.key});

  @override
  State<PetsPage> createState() => _PetsPageState();
}

class _PetsPageState extends State<PetsPage> {
  late EasyRefreshController _easyController;

  @override
  void initState() {
    super.initState();
    _easyController = EasyRefreshController(controlFinishRefresh: true);
  }

  @override
  void dispose() {
    _easyController.dispose();
    super.dispose();
  }

  // dynamic metrics 0..5
  final Map<String, double> _metrics = {
    '贪吃': 4,
    '规律': 4,
    '活跃': 5,
    '饮水': 3,
    '亲人': 3,
  };

  Widget _petCard(PetInfo pet, {bool isSelected = false, bool isLast = false}) {
    final card = Container(
      width: 200,
      margin: EdgeInsets.only(right: isLast ? 0 : 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? const Color(0xFFFF7E4D) : const Color(0xFFEEEEEE),
          width: isSelected ? 2 : 1,
        ),
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
            child: Stack(
              children: [
                Center(
                  child: ClipOval(
                    child: pet.headimg.isNotEmpty
                        ? Image.network(pet.headimg, width: 68, height: 68, fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => Image.asset('assets/images/icon/home-i-1.png', width: 68, height: 68, fit: BoxFit.contain))
                        : Image.asset('assets/images/icon/home-i-1.png', width: 68, height: 68, fit: BoxFit.contain),
                  ),
                ),
                Positioned(
                  right: 1,
                  bottom: 1,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: pet.sex == 'male' ? const Color(0xFF4D8FFF) : const Color(0xFFFF78A6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      pet.sex == 'male' ? Icons.male : Icons.female,
                      size: 12,
                      color: Colors.white,
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
                Text(pet.nickname, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Row(children: [Image.asset(
                    "assets/images/icon/birthday-ico.png",
                    width: 15,
                    height: 15,
                  ), const SizedBox(width: 6), Text(pet.ageLabel, style: const TextStyle(color: Colors.black54))]),
                const SizedBox(height: 2),
                Row(children: [Image.asset(
                    "assets/images/icon/weight-ico.png",
                    width: 15,
                    height: 15,
                  ), const SizedBox(width: 6), Text('${pet.weight}kg', style: const TextStyle(color: Colors.black54))]),
              ],
            ),
          )
        ],
      ),
    );

    return card;
  }

  Map<String, double> _mapFromAnalysis(PetAnalysis? analysis) {
    if (analysis != null && analysis.items.isNotEmpty) {
      return Map.fromEntries(analysis.items.map((e) => MapEntry(e.title, e.value.toDouble())));
    }
    return _metrics;
  }

  Color _colorForTitle(String title) {
    switch (title) {
      case '饮水': return const Color(0xFF42A5F5);
      case '进食': return const Color(0xFFFFA726);
      case '运动': return const Color(0xFF66BB6A);
      case '排便': return const Color(0xFFAB47BC);
      case '睡觉': return const Color(0xFF42A5F5);
      case '体重': return const Color(0xFFFF7043);
      default: return const Color(0xFF4FC3F7);
    }
  }

  Widget _statCard(String iconPath, String title, String value, double progress, {Color color = const Color(0xFF4FC3F7), VoidCallback? onTap, bool isNetworkIcon = false, String rateTxt = ''}) {
    final card = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            isNetworkIcon
                ? Image.network(iconPath, width: 30, height: 30, errorBuilder: (_, _, _) => const Icon(Icons.error_outline, size: 30))
                : Image.asset(iconPath, width: 30, height: 30),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 12))
          ]),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              if (rateTxt.isNotEmpty)
                Text(rateTxt, style: const TextStyle(fontSize: 10, color: Colors.black45)),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            child: LinearProgressIndicator(value: progress, color: color, backgroundColor: const Color(0xFFF0F0F0)),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: card);
    }

    return card;
  }

  Widget _ratingRow(String label, double stars, {String? iconUrl}) {
    final int filled = stars.clamp(0, 5).toInt();
    return Row(
      children: [
        if (iconUrl != null) ...[
          Image.network(iconUrl, width: 20, height: 20, errorBuilder: (_, _, _) => const SizedBox.shrink()),
          const SizedBox(width: 4),
        ],
        Expanded(child: Text(label, style: const TextStyle(color: Colors.black87, fontSize: 12))),
        Row(children: List.generate(5, (i) => Padding(
          padding: const EdgeInsets.only(left: 2),
          child: Icon(i < filled ? Icons.star : Icons.star_border, color: const Color(0xFFFFA726), size: 16),
        ))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final petState = context.watch<PetState>();
    final pets = petState.pets;
    final selectedIdx = petState.selectedIndex;
    final loading = !petState.isLoaded;

    return Stack(
      children: [
        Container(
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
                  // 标题栏固定在顶部
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
                          onTap: () async {
                            final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPetPage()));
                            if (result == true) {
                              context.read<PetState>().refresh();
                            }
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
                    child: EasyRefresh(
                      controller: _easyController,
                      header: const ClassicHeader(
                        dragText: '下拉刷新',
                        armedText: '释放刷新',
                        readyText: '刷新中...',
                        processingText: '刷新中...',
                        processedText: '刷新成功',
                        failedText: '刷新失败',
                        noMoreText: '没有更多',
                        messageText: '最后更新于 %T',
                      ),
                      onRefresh: () async {
                        await context.read<PetState>().refresh();
                        _easyController.finishRefresh();
                      },
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                        // horizontal pet list / empty state
                        if (petState.isLoaded && pets.isEmpty)
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
                                      onPressed: () async {
                                        final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPetPage()));
                                        if (result == true) {
                                          context.read<PetState>().refresh();
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFFF7A47),
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
                        else if (!petState.isLoaded || pets.isNotEmpty)
                          ...[
                            SizedBox(
                              height: 110,
                              child: pets.isEmpty
                                  ? null
                                  : ListView(
                                      scrollDirection: Axis.horizontal,
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                      children: pets.asMap().entries.map((e) {
                                        final isSelected = e.key == selectedIdx;
                                        final isLast = e.key == pets.length - 1;
                                        return GestureDetector(
                                          onTap: () async {
                                            if (isSelected) {
                                              // 已选中 → 跳转宠物档案
                                              final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => InformationPage(petId: e.value.id)));
                                              if (result == true) {
                                                context.read<PetState>().refresh();
                                              }
                                            } else {
                                              // 未选中 → 选中（自动获取今日数据）
                                              context.read<PetState>().selectPet(e.key);
                                            }
                                          },
                                          child: _petCard(e.value, isSelected: isSelected, isLast: isLast),
                                        );
                                      }).toList(),
                                    ),
                            ),
                            if (pets.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  children: const [Icon(Icons.insert_chart, color: Color(0xFFFF7A47)), SizedBox(width: 8), Text('今日数据', style: TextStyle(fontWeight: FontWeight.bold))],
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
                                      children: petState.todayItems.map((item) {
                                        final color = _colorForTitle(item.title);
                                        return _statCard(
                                          item.icon,
                                          item.title,
                                          item.displayValue,
                                          item.rate,
                                          color: color,
                                          isNetworkIcon: true,
                                          rateTxt: item.rateTxt,
                                          onTap: item.title == '饮水' ? () {
                                            Navigator.push(context, MaterialPageRoute(builder: (_) => const WaterPage()));
                                          } : null,
                                        );
                                      }).toList(),
                                    ),
                                 )
                                
                              ),
                              const SizedBox(height: 12),
                            ],
                            if (pets.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(children: [
                                      Image(image: AssetImage('assets/images/icon/hd-2.png'), width: 22, height: 22),
                                      SizedBox(width: 8),
                                      Text('性格养成', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    ]),
                                    const SizedBox(height: 12),
                                    Container(
                                      child: Column(
                                        children: [
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFFF4F0),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              petState.analysis?.notice ?? 'AI解读：暂无数据',
                                              style: const TextStyle(color: Color(0xFF7F7F7F)),
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
                                                  painter: _RadarPainter(_mapFromAnalysis(petState.analysis)),
                                                ),
                                              ),
                                              const SizedBox(width: 20),
                                              Expanded(
                                                child: petState.analysis != null && petState.analysis!.items.isNotEmpty
                                                  ? Column(
                                                      children: petState.analysis!.items.map((item) => Padding(
                                                        padding: const EdgeInsets.only(bottom: 6),
                                                        child: _ratingRow(item.title, item.value.toDouble(), iconUrl: item.icon),
                                                      )).toList(),
                                                    )
                                                  : Column(
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
                          ],
                        const SizedBox(height: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
        if (loading)
          Container(
            color: const Color(0xFFFFFAF2),
            child: const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF7A47)),
            ),
          ),
      ],
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
    final paintBorder = Paint()..color = const Color(0xFFFF7A47)..style = PaintingStyle.stroke..strokeWidth = 2;

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




