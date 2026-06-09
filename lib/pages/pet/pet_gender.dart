import 'package:flutter/material.dart';

enum PetGender { GG, MM, sterilizationGG, sterilizationMM }

class PetGenderPage extends StatefulWidget {
  const PetGenderPage({super.key});

  @override
  State<PetGenderPage> createState() => _PetGenderPageState();
}

class _PetGenderPageState extends State<PetGenderPage> {
  PetGender? _selected;

  void _select(PetGender gender) {
    setState(() => _selected = gender);
    String result;
    switch (gender) {
      case PetGender.GG:
        result = 'GG';
        break;
      case PetGender.MM:
        result = 'MM';
        break;
      case PetGender.sterilizationGG:
        result = '绝育GG';
        break;
      case PetGender.sterilizationMM:
        result = '绝育MM';
        break;
    }
    Navigator.pop(context, result);
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
        return Icons.medical_services;
      case PetGender.sterilizationMM:
        return Icons.medical_services;
    }
  }

  Color _getColor(PetGender gender) {
    switch (gender) {
      case PetGender.GG:
        return Colors.blue.shade700;
      case PetGender.MM:
        return Colors.pink.shade500;
      case PetGender.sterilizationGG:
        return Colors.teal.shade600;
      case PetGender.sterilizationMM:
        return Colors.purple.shade600;
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
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                '请选择您的宠物性别',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ),
            const SizedBox(height: 28),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _buildCard(PetGender.GG),
                    _buildCard(PetGender.MM),
                    _buildCard(PetGender.sterilizationGG),
                    _buildCard(PetGender.sterilizationMM),
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
      onTap: () => _select(gender),
      child: Container(
        width: (MediaQuery.of(context).size.width - 64) / 2,
        height: 140,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.25),
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
                        ? const Icon(Icons.check, size: 18, color: Colors.orange)
                        : null,
                  ),
                ],
              ),
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: Opacity(
                opacity: 0.95,
                child: Icon(
                  icon,
                  size: 64,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}