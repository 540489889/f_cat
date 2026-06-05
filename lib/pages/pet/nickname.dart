import 'package:flutter/material.dart';

class NicknamePage extends StatefulWidget {
  const NicknamePage({super.key});

  @override
  State<NicknamePage> createState() => _NicknamePageState();
}

class _NicknamePageState extends State<NicknamePage> {
  final TextEditingController _ctrl = TextEditingController(text: '旋旋');

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
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
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back)),
                const Expanded(child: Text('昵称', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold))),
                const SizedBox(width: 48),
              ]),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(color: const Color(0xFFF7F7F8), borderRadius: BorderRadius.circular(28)),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      decoration: const InputDecoration(border: InputBorder.none, hintText: '输入昵称'),
                    ),
                  ),
                  if (_ctrl.text.isNotEmpty)
                    GestureDetector(onTap: () => setState(() => _ctrl.clear()), child: const Icon(Icons.close, color: Colors.grey)),
                ]),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, _ctrl.text),
									style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8A65), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))),
                  child: const Text('保存', style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
