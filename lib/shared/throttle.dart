/// 防止重复点击的工具类
///
/// 用法：
/// ```dart
/// final _throttle = ActionThrottle();
///
/// void _onSave() async {
///   await _throttle.run(() async {
///     // API 调用...
///   });
/// }
/// ```
class ActionThrottle {
  DateTime _lastTime = DateTime(2000);
  final Duration interval;

  ActionThrottle({this.interval = const Duration(seconds: 2)});

  /// 节流执行，在 [interval] 内重复调用会被忽略
  Future<void> run(Future<void> Function() action) async {
    final now = DateTime.now();
    if (now.difference(_lastTime) < interval) return;
    _lastTime = now;
    try {
      await action();
    } catch (_) {
      // 即使异常也重置，避免永久锁定
      _lastTime = DateTime(2000);
      rethrow;
    }
  }

  /// 重置节流状态
  void reset() => _lastTime = DateTime(2000);
}
