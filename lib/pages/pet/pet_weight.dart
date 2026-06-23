import 'package:flutter/material.dart';
import 'package:simple_ruler_picker/simple_ruler_picker.dart';

class PetWeightPage extends StatefulWidget {
  final double initialWeight;
  const PetWeightPage({super.key, this.initialWeight = 4.0});

  @override
  State<PetWeightPage> createState() => _PetWeightPageState();
}

class _PetWeightPageState extends State<PetWeightPage> {
  late double _weight;

  @override
  void initState() {
    super.initState();
    _weight = widget.initialWeight;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
             Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(children: [
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.keyboard_arrow_left, size: 34)),
                const Expanded(child: Text('宠物体重', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold))),
                const SizedBox(width: 48),
              ]),
            ),

            const SizedBox(height: 54),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  _weight.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 36,
                    color: Color(0xFFFF7A47),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Kg',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            SimpleRulerPicker(
              height: 140,
              minValue: 0, // 最小值0kg
              maxValue: 100, // 最大值10.0kg（内部÷10）
              initialValue: (_weight * 10).toInt(), // 初始4.0→40
              selectedColor: const Color(0xFFFF7A47),
              onValueChanged: (int val) {
                setState(() {
                  _weight = val / 10.0;
                });
              },
            ),

            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                '中华田园猫的正常体重范围是：\n3.0Kg-7.0Kg',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, _weight.toStringAsFixed(1));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7A47),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: const Text('完成', style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}