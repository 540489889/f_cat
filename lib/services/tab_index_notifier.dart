import 'package:flutter/foundation.dart';

/// 追踪当前 Tab 索引的 ChangeNotifier
///
/// HomeShell 在切换 tab 时更新此值，各 tab 页面可监听以处理可见/不可见逻辑
///（如暂停/恢复视频播放）
class TabIndexNotifier extends ChangeNotifier {
  int _index = 0;

  int get index => _index;

  void update(int index) {
    if (_index != index) {
      _index = index;
      notifyListeners();
    }
  }
}
