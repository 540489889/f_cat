import 'package:flutter/material.dart';
import 'manual.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF2E8), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black87),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          '智能连接设备',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    TextButton(
                       onPressed: () {
                        // 跳转到 manual.dart 里的 ManualPage 页面
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ManualPage()),
                        );
                      },
                      child: const Text('手动连接', style: TextStyle(color: Colors.black54)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      '正在搜索可连接的设备...',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '打开手机蓝牙和定位，并确保设备处于配网状态',
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  ],
                ),
              ),

              const Expanded(
                child: Center(
                  child: _SearchCenter(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchCenter extends StatefulWidget {
  const _SearchCenter({Key? key}) : super(key: key);

  @override
  State<_SearchCenter> createState() => _SearchCenterState();
}

class _SearchCenterState extends State<_SearchCenter> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  // Configurable parameters to match the video more closely
  static const int pulseCount = 3;
  // Pulse color and timing tuned for visible expanding effect
  static const Color pulseColor = Color(0xFFFF914D);
  static const int controllerMs = 2000; // overall loop duration (ms)

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: controllerMs))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Size chosen to match existing layout; pulses will be drawn relative to size
    const double size = 320;

    return SizedBox(
      width: size,
      height: size,
      child: Transform.translate(
        offset: const Offset(0, -90), // x=0, y=-20 向上移 20
        child: Stack(
        alignment: Alignment.center,
        
        children: [
          // soft white background circle
          Container(
            width: size - 40,
            height: size - 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.6),
            ),
          ),

          // Pulses painted behind the center content
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (context, child) {
                return CustomPaint(
                  size: const Size(size, size),
                  painter: _PulsePainter(
                    progress: _ctrl.value,
                    count: pulseCount,
                    color: pulseColor,
                  ),
                );
              },
            ),
          ),

          // Middle gradient circle
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(colors: [Color(0xFFFFE6D6), Color(0xFFFFB28C)]),
              // boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.15), blurRadius: 20, spreadRadius: 6)],
            ),
          ),

          // Center icon
          CircleAvatar(
            radius: 44,
            backgroundColor: Colors.white,
            child: Image.asset(
              'assets/images/icon/bluetooth-ico.png',
              width: 48,
              height: 48,
            ),
          ),
        ],
      ),

      ),
      
    );
  }
}

class _PulsePainter extends CustomPainter {
  final double progress; // 0..1
  final int count;
  final Color color;

  _PulsePainter({required this.progress, required this.count, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.shortestSide * 0.8; // allow pulses to reach well outside mid circle
    final minRadius = size.shortestSide * 0.10; // starting small

    for (int i = 0; i < count; i++) {
      // compute phase for this pulse, staggered around the loop
      double phase = (progress - i / count) % 1.0;
      if (phase < 0) phase += 1.0;

      // We want each pulse to expand slowly over most of the cycle
      // Use easing for natural feel
      final eased = Curves.easeInOut.transform(phase.clamp(0.0, 1.0));

      final radius = minRadius + (maxRadius - minRadius) * eased;
      final opacity = ((1.0 - eased) * 1.0).clamp(0.0, 1.0);

      if (opacity <= 0.01) continue;

      final innerOpacity = (opacity * 0.9).clamp(0.0, 1.0);

      final rect = Rect.fromCircle(center: center, radius: radius);
      final shader = RadialGradient(
        colors: [color.withOpacity(opacity), color.withOpacity(innerOpacity * 0.25), color.withOpacity(0.0)],
        stops: [0.0, 0.6, 1.0],
      ).createShader(rect);

      final paint = Paint()
        ..shader = shader
        ..blendMode = BlendMode.plus; // additive blend for stronger glow
      canvas.drawCircle(center, radius, paint);

      // draw a stronger inner fill to make pulses more visible
      final innerPaint = Paint()..color = color.withOpacity(innerOpacity)..blendMode = BlendMode.plus;
      canvas.drawCircle(center, radius * 0.32, innerPaint);
    }

  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    if (oldDelegate is _PulsePainter) {
      return oldDelegate.progress != progress || oldDelegate.count != count || oldDelegate.color != color;
    }
    return true;
  }
}
