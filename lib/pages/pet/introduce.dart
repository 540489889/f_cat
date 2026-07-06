import 'package:flutter/material.dart';
import 'add.dart';

/// 宠物介绍页（添加宠物第 2 步）
///
/// 用户可通过语音或手动输入介绍宠物，
/// 也可跳过直接进入信息填写页。
class PetIntroducePage extends StatefulWidget {
  final String? headimg;
  final String? imgs;

  const PetIntroducePage({super.key, this.headimg, this.imgs});

  @override
  State<PetIntroducePage> createState() => _PetIntroducePageState();
}

class _PetIntroducePageState extends State<PetIntroducePage> {
  final TextEditingController _introController = TextEditingController();

  @override
  void dispose() {
    _introController.dispose();
    super.dispose();
  }

  void _goToAddPage({String? introduction}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddPetPage(
          headimg: widget.headimg,
          imgs: widget.imgs,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F4),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 顶部导航
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.keyboard_arrow_left,
                        color: Color(0xFF222222), size: 34),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        '添加宠物',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF222222),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 48,
                    child: Text(
                      '2/4',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFF7A47),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // 进度条
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                children: List.generate(4, (index) {
                  return Expanded(
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: index < 2
                            ? const Color(0xFFFF7A47)
                            : const Color(0xFFE0E0E0),
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 32),
            // 标题
            const Text(
              '先来介绍一下它',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF222222),
              ),
            ),
            const SizedBox(height: 8),
            // 副标题
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                '你可以通过语音或手动输入来介绍它，\n帮助我们更准确的了解它。',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF999999),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // 语音内容卡片
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '语音内容',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF222222),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: TextField(
                          controller: _introController,
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          decoration: const InputDecoration(
                            hintText: '例如：它叫豆包，品种是比熊，性别是弟弟，2岁，体重15斤"',
                            hintStyle: TextStyle(
                              fontSize: 14,
                              color: Color(0xFFCCCCCC),
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // 底部按钮
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => _goToAddPage(
                        introduction: _introController.text.trim()),
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF7A47),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: const Center(
                        child: Text(
                          '开始语音输入',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => _goToAddPage(),
                    child: const Text(
                      '跳过',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFFF7A47),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
