import 'package:flutter/material.dart';

enum PetGender { GG, MM, sterilizationGG, sterilizationMM }

class PetGenderPage extends StatefulWidget {
  const PetGenderPage({super.key});

  @override
  State<PetGenderPage> createState() => _PetGenderPageState();
}

class _PetGenderPageState extends State<PetGenderPage> {
  PetGender? _selected;

  void _onSelect(PetGender gender) {
    final isMale = gender == PetGender.GG || gender == PetGender.sterilizationGG;
    final isNeutered = gender == PetGender.sterilizationGG || gender == PetGender.sterilizationMM;
    Navigator.pop(context, {
      'sex': isMale ? 'male' : 'female',
      'sterilization': isNeutered ? 'y' : 'n',
      'label': _getTitle(gender),
    });
  }

  String _getTitle(PetGender gender) {
    switch (gender) {
      case PetGender.GG:
        return 'GG';
      case PetGender.MM:
        return 'MM';
      case PetGender.sterilizationGG:
        return '绝育GG';
      case PetGender.sterilizationMM:
        return '绝育MM';
    }
  }

  IconData _getIcon(PetGender gender) {
    switch (gender) {
      case PetGender.GG:
        return Icons.male;
      case PetGender.MM:
        return Icons.female;
      case PetGender.sterilizationGG:
        return Icons.face;
      case PetGender.sterilizationMM:
        return Icons.favorite;
    }
  }

  Color _getColor(PetGender gender) {
    switch (gender) {
      case PetGender.GG:
        return const Color(0xFF4A84F0);
      case PetGender.MM:
        return const Color(0xFFF78233);
      case PetGender.sterilizationGG:
        return const Color(0xFFF7B030);
      case PetGender.sterilizationMM:
        return const Color(0xFF03C7CA);
    }
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
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.keyboard_arrow_left, size: 34),
                  ),
                  const Expanded(
                    child: Text(
                      '宠物性别',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('请选择宠物性别', style: TextStyle(fontSize: 16, color: Colors.black54)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildCard(PetGender.GG)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildCard(PetGender.MM)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildCard(PetGender.sterilizationGG)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildCard(PetGender.sterilizationMM)),
                      ],
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(PetGender gender) {
    final selected = _selected == gender;
    final color = _getColor(gender);
    final title = _getTitle(gender);
    final icon = _getIcon(gender);

    return GestureDetector(
      onTap: () => _onSelect(gender),
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      color: selected ? Colors.white : Colors.transparent,
                    ),
                    child: selected
                        ? const Icon(Icons.check, size: 16, color: Colors.orange)
                        : null,
                  ),
                ],
              ),
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: Icon(icon, size: 48, color: Colors.white.withValues(alpha: 0.7)),
            ),
          ],
        ),
      ),
    );
  }
}
