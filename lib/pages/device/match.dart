import 'package:flutter/material.dart';

class MatchPage extends StatefulWidget {
  const MatchPage({super.key});

  @override
  State<MatchPage> createState() => _MatchPageState();
}

class _MatchPageState extends State<MatchPage> {
  bool _confirmed = false;

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
        title: const Text('手动连接', style: TextStyle(color: Colors.black87)),
      ),
      backgroundColor: const Color(0xFFF6F6F6),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
            ),

            const SizedBox(height: 18),

            Align(
              alignment: Alignment.centerLeft,
              child: Text('1、确保设备已接通电源。', style: TextStyle(fontSize: 14, color: Colors.black54)),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('2、长按设备XX颜色圆点按钮，听到提示音后松开。', style: TextStyle(fontSize: 14, color: Colors.black54)),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('3、确认指示灯开始闪烁XX色，设备已进入配网状态。', style: TextStyle(fontSize: 14, color: Colors.black54)),
            ),

            const Spacer(),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Checkbox(
                  value: _confirmed,
                  activeColor: const Color(0xFFFF8A65),
                  onChanged: (v) => setState(() => _confirmed = v ?? false),
                ),
                const SizedBox(width: 6),
                const Text('已确认上述操作', style: TextStyle(color: Colors.black54)),
              ],
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _confirmed ? () {
                  // TODO: 下一步逻辑
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8A65),
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('下一步', style: TextStyle(fontSize: 16)),
              ),
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
