import 'package:flutter/material.dart';

enum PetGender { GG, MM, sterilizationGG, sterilizationMM }

class PetGenderPage extends StatefulWidget {
  const PetGenderPage({super.key});

  @override
  State<PetGenderPage> createState() => _PetGenderPageState();
}

class _PetGenderPageState extends State<PetGenderPage> {
  PetGender? _sex;       // GG 或 MM
  PetGender? _neutered;  // sterilizationGG 或 sterilizationMM

  bool get _canConfirm => _sex != null && _neutered != null;

  void _onConfirm() {
    if (!_canConfirm) return;
    final isMale = _sex == PetGender.GG;
    final isNeutered = _neutered == PetGender.sterilizationGG || _neutered == PetGender.sterilizationMM;
    Navigator.pop(context, {
      'sex': isMale ? 'male' : 'female',
      'sterilization': isNeutered ? 'y' : 'n',
      'label': isNeutered ? (isMale ? '绝育GG' : '绝育MM') : (isMale ? 'GG' : 'MM'),
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

  bool _isSelected(PetGender gender) {
    switch (gender) {
      case PetGender.GG:
      case PetGender.MM:
        return _sex == gender;
      case PetGender.sterilizationGG:
      case PetGender.sterilizationMM:
        return _neutered == gender;
    }
  }

  void _onCardTap(PetGender gender) {
    setState(() {
      switch (gender) {
        case PetGender.GG:
        case PetGender.MM:
          _sex = gender;
          // 如果已经选了不匹配的绝育项，清掉
          if (_neutered == PetGender.sterilizationGG && gender == PetGender.MM) _neutered = null;
          if (_neutered == PetGender.sterilizationMM && gender == PetGender.GG) _neutered = null;
          break;
        case PetGender.sterilizationGG:
        case PetGender.sterilizationMM:
          _neutered = gender;
          // 如果已经选了不匹配的性别，清掉
          if (_sex == PetGender.MM && gender == PetGender.sterilizationGG) _sex = null;
          if (_sex == PetGender.GG && gender == PetGender.sterilizationMM) _sex = null;
          break;
      }
    });
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
                    // ======== 性别选择 ========
                    const Text('请选择宠物性别', style: TextStyle(fontSize: 16, color: Colors.black54)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildCard(PetGender.GG)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildCard(PetGender.MM)),
                      ],
                    ),
                    const SizedBox(height: 36),
                    // ======== 是否绝育 ========
                    const Text('是否绝育', style: TextStyle(fontSize: 16, color: Colors.black54)),
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
            // ======== 确认按钮（固定在底部） ========
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _canConfirm ? _onConfirm : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canConfirm ? const Color(0xFFFF7A47) : const Color(0xFFDDDDDD),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  ),
                  child: Text('确认', style: TextStyle(fontSize: 18, color: _canConfirm ? Colors.white : const Color(0xFF999999))),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(PetGender gender) {
    final selected = _isSelected(gender);
    final color = _getColor(gender);
    final title = _getTitle(gender);
    final icon = _getIcon(gender);

    return GestureDetector(
      onTap: () => _onCardTap(gender),
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