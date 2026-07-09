import 'package:flutter/material.dart';
import 'figure.dart';

class Pet3DGeneratedPage extends StatelessWidget {
  final String? imageUrl;
  final VoidCallback? onViewPressed;
  final VoidCallback? onRegeneratePressed;

  const Pet3DGeneratedPage({
    super.key,
    this.imageUrl,
    this.onViewPressed,
    this.onRegeneratePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F1EA),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            const Text(
              '生成专属形象',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E1E1E),
              ),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF000000).withValues(alpha: 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: imageUrl != null
                        ? Image.network(
                            imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _defaultImage(),
                          )
                        : _defaultImage(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 34),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Text(
                    '宠物的专属 3D 形象已生成',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF222222),
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    '现在可以进入管家主页，查看它的动态形象。',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF8E8E8E),
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                   onPressed: onRegeneratePressed ?? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PetFigurePage(for3D: true))),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7A47),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    '重新生成',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            // const SizedBox(height: 16),
            // TextButton(
            //   onPressed: onRegeneratePressed ?? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PetFigurePage(for3D: true))),
            //   style: TextButton.styleFrom(
            //     foregroundColor: const Color(0xFFFF7A47),
            //     textStyle: const TextStyle(
            //       fontSize: 16,
            //       fontWeight: FontWeight.w600,
            //     ),
            //   ),
            //   child: const Text('重新生成'),
            // ),
            const SizedBox(height: 22),
          ],
        ),
      ),
    );
  }

  Widget _defaultImage() {
    return Container(
      color: const Color(0xFFF8F2E6),
      child: Image.asset('assets/images/pet_avatar.png', fit: BoxFit.cover),
    );
  }
}
 