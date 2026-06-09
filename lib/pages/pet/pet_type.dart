import 'package:flutter/material.dart';

enum PetType { cat, dog }

class PetTypePage extends StatefulWidget {
  const PetTypePage({super.key});

  @override
  State<PetTypePage> createState() => _PetTypePageState();
}

class _PetTypePageState extends State<PetTypePage> {
  PetType? _selected;

  void _select(PetType type) {
    setState(() => _selected = type);
    // 返回所选类型的字符串（可根据需要调整返回值）
    Navigator.pop(context, type == PetType.cat ? '猫' : '狗');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(children: [
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.keyboard_arrow_left, size: 34)),
                const Expanded(child: Text('宠物类型', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold))),
                const SizedBox(width: 48),
              ]),
            ),

            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  // Text('宠物类型', style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold)),
                  // SizedBox(height: 8),
                  Text('请选择您的宠物类型', style: TextStyle(fontSize: 16, color: Colors.black54)),
                ],
              ),
            ),

            const SizedBox(height: 28),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(child: _buildCard(PetType.cat, Colors.blue.shade700, '喵星人')),
                  const SizedBox(width: 16),
                  Expanded(child: _buildCard(PetType.dog, Colors.orange.shade700, '汪星人')),
                ],
              ),
            ),

            const Expanded(child: SizedBox()),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(PetType type, Color color, String title) {
    final selected = _selected == type;
    return GestureDetector(
      onTap: () => _select(type),
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 6))],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(title, style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      color: selected ? Colors.white : Colors.transparent,
                    ),
                    child: selected ? const Icon(Icons.check, size: 18, color: Colors.orange) : null,
                  ),
                ],
              ),
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: Opacity(
                opacity: 0.95,
                child: Icon(type == PetType.cat ? Icons.pets : Icons.pets, size: 64, color: Colors.white.withValues(alpha: 0.9)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
