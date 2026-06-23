import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NicknamePage extends StatefulWidget {
  const NicknamePage({super.key});

  @override
  State<NicknamePage> createState() => _NicknamePageState();
}

class _NicknamePageState extends State<NicknamePage> {
  final TextEditingController _ctrl = TextEditingController();
  bool _canSave = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      final valid = _ctrl.text.trim().isNotEmpty;
      if (valid != _canSave) setState(() => _canSave = valid);
    });
  }

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
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.keyboard_arrow_left, size: 34)),
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
                      autofocus: true,
                      maxLength: 6,
                      maxLengthEnforcement: MaxLengthEnforcement.enforced,
                      decoration: const InputDecoration(border: InputBorder.none, hintText: '输入昵称', counterText: ''),
                    ),
                  ),
                  if (_ctrl.text.isNotEmpty)
                    GestureDetector(onTap: () => _ctrl.clear(), child: const Icon(Icons.close, color: Colors.grey)),
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
                  onPressed: _canSave ? () => Navigator.pop(context, _ctrl.text.trim()) : null,
									style: ElevatedButton.styleFrom(
                    backgroundColor: _canSave ? const Color(0xFFFF7A47) : const Color(0xFFDDDDDD),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  ),
                  child: Text('保存', style: TextStyle(fontSize: 18, color: _canSave ? Colors.white : const Color(0xFF999999))),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
