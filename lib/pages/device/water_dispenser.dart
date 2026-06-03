import 'package:flutter/material.dart';

class WaterDispenserPage extends StatelessWidget {
  const WaterDispenserPage({super.key});

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
        title: const Text('智能饮水机 PRO', style: TextStyle(color: Colors.black87)),
        actions: [
          IconButton(onPressed: () => _showSettingsSheet(context), icon: const Icon(Icons.settings, color: Colors.black54)),
        ],
      ),
      backgroundColor: const Color(0xFFF6F6F6),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // status tag + image
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: const Text('正常工作', style: TextStyle(color: Colors.green)),
              ),
              const SizedBox(height: 12),

              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/device/device2.png',
                    width: 300,
                    height: 220,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // stats card
              Container(
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const [
                    _StatColumn(top: '3 次', bottom: '今日喝水'),
                    _DividerV(),
                    _StatColumn(top: '100 ML', bottom: '喝水量'),
                    _DividerV(),
                    _StatColumn(top: '4.8 L', bottom: '剩余水量'),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // energy management
              Container(
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [Text('能源管理', style: TextStyle(fontWeight: FontWeight.bold)), Text('设置', style: TextStyle(color: Colors.black54))]),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        _StatColumn(top: '100 %', bottom: '电池电量'),
                        _DividerV(),
                        _StatColumn(top: '10 次', bottom: '今日净化水'),
                        _DividerV(),
                        _StatColumn(top: '0.001 kw/h', bottom: '今日用电'),
                      ],
                    )
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Today water chart section
              Container(
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [Row(children: [Icon(Icons.opacity, color: Color(0xFF42A5F5)), SizedBox(width: 8), Text('今日喝水', style: TextStyle(fontWeight: FontWeight.bold))]), Text('3 次')]),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 180,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: const [
                          SizedBox(width: 28, child: Text("4'09\"", style: TextStyle(color: Colors.black54))),
                          SizedBox(width: 8),
                          Expanded(child: _SimpleBarChart()),
                        ],
                      ),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // drink records
              Container(
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('喝水记录', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _RecordItem(time: '07:38', text: '超级无敌小虎妞喝水，停留 39s'),
                    _RecordItem(time: '07:30', text: '超级无敌小虎妞喝水，停留 39s'),
                    _RecordItem(time: '00:30', text: '超级无敌小虎妞喝水，停留 39s'),
                  ],
                ),
              ),

              const SizedBox(height: 84),
            ],
          ),
        ),
      ),

      bottomSheet: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _BottomAction(icon: Icons.repeat, label: '持续涌泉', active: true),
            _BottomAction(icon: Icons.timelapse, label: '间歇涌泉', active: false),
            _BottomAction(icon: Icons.bubble_chart, label: '智能涌泉', active: false),
          ],
        ),
      ),
    );
  }
}

void _showSettingsSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      double fountain = 3;
      double sleep = 10;
      return StatefulBuilder(builder: (context, setState) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.62,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Text('能源管理', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(width: 12),
                        Text('电池模式', style: TextStyle(color: Colors.black54)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: const Color(0xFFF7F7F7), borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          children: [
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('涌泉时间'), Text('${3}分钟')]),
                            Slider(
                              value: fountain,
                              min: 1,
                              max: 10,
                              divisions: 9,
                              activeColor: const Color(0xFFFF8A65),
                              onChanged: (v) => setState(() => fountain = v),
                            ),
                            const SizedBox(height: 8),
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('休眠时间'), Text('${10}分钟')]),
                            Slider(
                              value: sleep,
                              min: 1,
                              max: 60,
                              divisions: 59,
                              activeColor: const Color(0xFFFF8A65),
                              onChanged: (v) => setState(() => sleep = v),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: const Color(0xFFF7F7F7), borderRadius: BorderRadius.circular(12)),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                          Text('预计每日净水', style: TextStyle(color: Colors.black54)),
                          SizedBox(height: 6),
                          Text('166次', style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 12),
                          Text('预计每日用电量', style: TextStyle(color: Colors.black54)),
                          SizedBox(height: 6),
                          Text('0.0042kw/h', style: TextStyle(fontWeight: FontWeight.bold)),
                        ]),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8A65), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('确定', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ),
            ],
          ),
        );
      });
    },
  );
}

class _StatColumn extends StatelessWidget {
  final String top;
  final String bottom;
  const _StatColumn({required this.top, required this.bottom});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(top, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(bottom, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }
}

class _DividerV extends StatelessWidget {
  const _DividerV();
  @override
  Widget build(BuildContext context) => Container(width: 1, height: 48, color: Colors.grey[200]);
}

class _SimpleBarChart extends StatelessWidget {
  const _SimpleBarChart();
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              _Bar(height: 90),
              _Bar(height: 150),
              _Bar(height: 70),
              _Bar(height: 0),
              _Bar(height: 0),
              _Bar(height: 0),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: const [Text('0时'), Text('4时'), Text('8时'), Text('12时'), Text('16时'), Text('20时')]),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  final double height;
  const _Bar({required this.height});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: height,
      decoration: BoxDecoration(color: const Color(0xFFFF8A65), borderRadius: BorderRadius.circular(6)),
    );
  }
}

class _RecordItem extends StatelessWidget {
  final String time;
  final String text;
  const _RecordItem({required this.time, required this.text});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(time, style: const TextStyle(color: Colors.black54)),
          const SizedBox(width: 12),
          const Icon(Icons.opacity, color: Color(0xFF42A5F5)),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _BottomAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  const _BottomAction({required this.icon, required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(color: active ? const Color(0xFFFF8A65) : Colors.white, shape: BoxShape.circle),
          child: Icon(icon, color: active ? Colors.white : Colors.black54),
        ),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(color: active ? const Color(0xFFFF8A65) : Colors.black54)),
      ],
    );
  }
}
