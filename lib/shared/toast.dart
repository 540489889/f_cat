import 'package:flutter/material.dart';

/// 全局 Toast 提示组件
/// 使用 Overlay 实现，不依赖 Scaffold，居中显示黑色半透明圆角提示
class Toast {
  /// 显示居中 Toast
  /// [context] 当前页面的 BuildContext
  /// [message] 提示文字
  /// [duration] 显示时长，默认 2 秒
  static void show(BuildContext context, String message, {Duration duration = const Duration(seconds: 2)}) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => Stack(
        children: [
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 60),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    overlay.insert(entry);
    Future.delayed(duration, () {
      entry.remove();
    });
  }
}
