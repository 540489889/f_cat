import 'package:flutter/material.dart';

class WaterPage extends StatelessWidget {
  const WaterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text('饮水', style: TextStyle(color: Colors.black87)),
      ),
      backgroundColor: const Color(0xFFEFF7FF),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF8A65),
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

            // Chart Card
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black12.withValues(alpha: 0.03), blurRadius: 6)],
              ),
              child: Column(
                children: [
                  // tabs
                  // Container(
                  //   margin: const EdgeInsets.all(12),
                  //   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  //   decoration: BoxDecoration(
                  //     color: const Color(0xFFF5F7FA),
                  //     borderRadius: BorderRadius.circular(8),
                  //   ),
                  //   child: Row(
                  //     mainAxisAlignment: MainAxisAlignment.spaceAround,
                  //     children: const [
                  //       _TabLabel(label: '日', selected: true),
                  //       _TabLabel(label: '周', selected: false),
                  //       _TabLabel(label: '月', selected: false),
                  //       _TabLabel(label: '年', selected: false),
                  //     ],
                  //   ),
                  // ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // left labels
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text("4'09\"", style: TextStyle(color: Colors.black54)),
                            SizedBox(height: 28),
                            Text("3'06\"", style: TextStyle(color: Colors.black54)),
                            SizedBox(height: 28),
                            Text("2'04\"", style: TextStyle(color: Colors.black54)),
                            SizedBox(height: 28),
                            Text("1'02\"", style: TextStyle(color: Colors.black54)),
                            SizedBox(height: 28),
                            Text("0'00\"", style: TextStyle(color: Colors.black54)),
                          ],
                        ),

                        const SizedBox(width: 12),

                        // bars area
                        Expanded(
                          child: Column(
                            children: [
                              SizedBox(
                                height: 180,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: const [
                                    _Bar(height: 80),
                                    _Bar(height: 140),
                                    _Bar(height: 60),
                                    _Bar(height: 0),
                                    _Bar(height: 0),
                                    _Bar(height: 0),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 8),
                              // x labels
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: const [
                                  Text('0时', style: TextStyle(color: Colors.black54)),
                                  Text('4时', style: TextStyle(color: Colors.black54)),
                                  Text('8时', style: TextStyle(color: Colors.black54)),
                                  Text('12时', style: TextStyle(color: Colors.black54)),
                                  Text('16时', style: TextStyle(color: Colors.black54)),
                                  Text('20时', style: TextStyle(color: Colors.black54)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Comparison card
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black12.withValues(alpha: 0.03), blurRadius: 6)],
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Icon(Icons.opacity, color: Color(0xFF42A5F5)),
                        SizedBox(height: 8),
                        Text('饮水对比', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
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

class _TabLabel extends StatelessWidget {
  final String label;
  final bool selected;
  const _TabLabel({required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFFFFFFF) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(color: selected ? const Color(0xFFFF8A65) : Colors.black54)),
    );
  }
}

class _Bar extends StatelessWidget {
  final double height;
  const _Bar({required this.height});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            width: 12,
            height: height,
            decoration: BoxDecoration(
              color: const Color(0xFFFF8A65),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }
}
