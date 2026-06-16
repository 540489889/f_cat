import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class WaterPage extends StatefulWidget {
  const WaterPage({super.key});

  @override
  State<WaterPage> createState() => _WaterPageState();
}

class _WaterPageState extends State<WaterPage> {
  String _tabSelected = '日';

  // 时间段数据（秒）
  static const List<Map<String, dynamic>> _dayData = [
    {'label': '0时', 'value': 64},   // 1'04"
    {'label': '4时', 'value': 186},  // 3'06"
    {'label': '8时', 'value': 249},  // 4'09"
    {'label': '12时', 'value': 124}, // 2'04"
    {'label': '16时', 'value': 62},  // 1'02"
    {'label': '20时', 'value': 40},  // 0'40"
    {'label': '24时', 'value': 0},   // 0'00"
  ];

  static const _barColor = Color(0xFFFF8A65);
  static const _maxY = 300.0; // Y轴最大值 5'00"
  static const _interval = 60.0; // 刻度间隔 1'00"

  String _fmtSec(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return "$m'${s.toString().padLeft(2, '0')}\"";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_left, color: Colors.black87, size: 34),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text('饮水', style: TextStyle(color: Colors.black87)),
      ),
      backgroundColor: const Color(0xFFEFF7FF),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            // 设备筛选行
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _barColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('全部', style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 12),
                const CircleAvatar(radius: 18, backgroundImage: AssetImage('assets/images/device/device1.png')),
                const SizedBox(width: 8),
                const CircleAvatar(radius: 18, backgroundImage: AssetImage('assets/images/device/device2.png')),
              ],
            ),

            const SizedBox(height: 16),

            // ============ 图表卡片 ============
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black12.withValues(alpha: 0.03), blurRadius: 6)],
              ),
              child: Column(
                children: [
                  // 标题行：今日喝水 + 次数
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('今日喝水', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      Text('3次', style: TextStyle(fontSize: 15, color: _barColor, fontWeight: FontWeight.w600)),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // 日/周/月 切换
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: ['日', '周', '月'].map((t) {
                        final selected = _tabSelected == t;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _tabSelected = t),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: selected ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: selected ? [BoxShadow(color: Colors.black12.withValues(alpha: 0.05), blurRadius: 4)] : null,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                t,
                                style: TextStyle(
                                  color: selected ? _barColor : Colors.black45,
                                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // fl_chart 柱状图
                  SizedBox(
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: _maxY,
                        minY: 0,
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              return BarTooltipItem(
                                _fmtSec(rod.toY.round()),
                                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 24,
                              getTitlesWidget: (value, meta) {
                                final i = value.toInt();
                                if (i < 0 || i >= _dayData.length) return const SizedBox.shrink();
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    _dayData[i]['label'] as String,
                                    style: const TextStyle(color: Colors.black45, fontSize: 11),
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 44,
                              interval: _interval,
                              getTitlesWidget: (value, meta) {
                                if (value == meta.max) return const SizedBox.shrink();
                                return Text(
                                  _fmtSec(value.round()),
                                  style: const TextStyle(color: Colors.black45, fontSize: 11),
                                );
                              },
                            ),
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: _interval,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: const Color(0xFFEEEEEE),
                            strokeWidth: 1,
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: List.generate(_dayData.length, (i) {
                          final v = (_dayData[i]['value'] as int).toDouble();
                          return BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: v,
                                color: _barColor,
                                width: 10,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(5),
                                  topRight: Radius.circular(5),
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ============ 饮水对比卡片 ============
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black12.withValues(alpha: 0.03), blurRadius: 6)],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.opacity, color: Color(0xFF42A5F5), size: 18),
                            SizedBox(width: 4),
                            Text('饮水对比', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('较昨日同期  ↑10%', style: TextStyle(color: Colors.orangeAccent)),
                        SizedBox(height: 8),
                        Text('3次', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        SizedBox(height: 6),
                        Text('今日饮水次数', style: TextStyle(color: Colors.black54)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        SizedBox(height: 32),
                        Text('较昨日同期  ↓3%', style: TextStyle(color: Colors.green)),
                        SizedBox(height: 8),
                        Text('2 min', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        SizedBox(height: 6),
                        Text('今日平均时长', style: TextStyle(color: Colors.black54)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
