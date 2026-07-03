import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 生成3D形象过程页
///
/// 展示3D形象生成进度，包括基础资料分析、照片质量检测、
/// 面部特征提取、3D模型生成、动态渲染等步骤。
class Pet3DGenerationPage extends StatefulWidget {
  final String? petImageUrl;

  const Pet3DGenerationPage({super.key, this.petImageUrl});

  @override
  State<Pet3DGenerationPage> createState() => _Pet3DGenerationPageState();
}

class _Pet3DGenerationPageState extends State<Pet3DGenerationPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  int _currentStep = 3; // 当前步骤索引：0-4
  final List<bool> _completed = [true, true, true, false, false];

  final List<Map<String, String>> _steps = [
    {
      'title': '基础资料分析完成',
      'subtitle': '宠物品种，年龄性别等信息已识别',
    },
    {
      'title': '照片质量检测通过',
      'subtitle': '照片清晰，角度全面，符合生成要求',
    },
    {
      'title': '宠物面部，形态特征提取完成',
      'subtitle': '宠物面部，形态特征点识别成功',
    },
    {
      'title': '生成3D模型中...',
      'subtitle': '正在构建宠物3D模型，请稍候',
    },
    {
      'title': '渲染动态形象',
      'subtitle': '即将生成生动可爱的动态形象',
    },
  ];

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // 模拟进度更新
    _simulateProgress();
  }

  Future<void> _simulateProgress() async {
    // 4秒后完成第4步
    await Future.delayed(const Duration(seconds: 4));
    if (!mounted) return;
    setState(() {
      _completed[3] = true;
      _currentStep = 4;
    });

    // 再过3秒完成第5步
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    setState(() {
      _completed[4] = true;
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      child: Scaffold(
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
                    onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                    icon: const Icon(Icons.keyboard_arrow_left,
                        color: Color(0xFF222222), size: 34),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        '生成专属形象',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF222222),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // const SizedBox(height: 24),
                    // 标题
                    const Text(
                      '正在为宠物生成专属 3D 形象',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF222222),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 副标题
                    const Text(
                      '生成过程可能需要1-3分钟，请耐心等待',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF999999),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // 圆形进度 + 宠物头像
                    AnimatedBuilder(
                      animation: _progressController,
                      builder: (context, child) {
                        return SizedBox(
                          width: 120,
                          height: 120,
                          child: CustomPaint(
                            painter: _CircularProgressPainter(
                              progress: _progressController.value,
                              color: const Color(0xFFFF7A47),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: ClipOval(
                                child: widget.petImageUrl != null
                                    ? Image.network(
                                        widget.petImageUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => _defaultAvatar(),
                                      )
                                    : _defaultAvatar(),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    // 进度列表卡片
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: List.generate(_steps.length, (index) {
                            final isCompleted = _completed[index];
                            final isCurrent = index == _currentStep;
                            final isLast = index == _steps.length - 1;

                            return _buildStepItem(
                              title: _steps[index]['title']!,
                              subtitle: _steps[index]['subtitle']!,
                              isCompleted: isCompleted,
                              isCurrent: isCurrent,
                              isLast: isLast,
                            );
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 底部提示文字
                    const Text(
                      '生成结果将自动同步到管家主页',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF999999),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 稍后查看按钮
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
                        child: Container(
                          width: double.infinity,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: const Center(
                            child: Text(
                              '稍后查看',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFFF7A47),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _defaultAvatar() {
    return Container(
      color: const Color(0xFFFFF3EE),
      child: const Icon(Icons.pets, size: 48, color: Color(0xFFFF7A47)),
    );
  }

  Widget _buildStepItem({
    required String title,
    required String subtitle,
    required bool isCompleted,
    required bool isCurrent,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 左侧进度线
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? const Color(0xFF07C160)
                    : isCurrent
                        ? const Color(0xFFFF7A47)
                        : Colors.transparent,
                border: isCompleted || isCurrent
                    ? null
                    : Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : isCurrent
                      ? Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        )
                      : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isCompleted
                    ? const Color(0xFF07C160).withValues(alpha: 0.3)
                    : const Color(0xFFE0E0E0),
              ),
          ],
        ),
        const SizedBox(width: 12),
        // 右侧文字
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isCompleted || isCurrent
                      ? const Color(0xFF222222)
                      : const Color(0xFF999999),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: isCompleted || isCurrent
                      ? const Color(0xFF666666)
                      : const Color(0xFFCCCCCC),
                ),
              ),
              if (!isLast) const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}

/// 圆形进度动画绘制器
class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CircularProgressPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 4) / 2;

    // 背景圆环
    final bgPaint = Paint()
      ..color = const Color(0xFFFFE6D9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(center, radius, bgPaint);

    // 进度弧
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) =>
      oldDelegate.progress != progress;
}