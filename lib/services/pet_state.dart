import 'package:flutter/foundation.dart';
import 'pet_api_service.dart';

export 'pet_api_service.dart' show PetInfo;

/// 宠物列表状态管理（Provider）
///
/// 全局共享，pet_home_page 和 pets_page 共用同一份数据，
/// /app/pet/list 接口只调用一次。
class PetState extends ChangeNotifier {
  List<PetInfo> _pets = [];
  int _selectedIndex = 0;
  bool _loaded = false;
  bool _loading = false;

  List<PetInfo> get pets => _pets;
  int get selectedIndex => _selectedIndex;
  bool get isEmpty => _pets.isEmpty;
  bool get isNotEmpty => _pets.isNotEmpty;
  bool get isLoaded => _loaded;

  void selectPet(int index) {
    if (index >= 0 && index < _pets.length && index != _selectedIndex) {
      _selectedIndex = index;
      notifyListeners();
    }
  }

  /// 加载宠物列表（防并发，仅当未在请求中时发起调用）
  Future<void> loadPets() async {
    if (_loading) return;
    _loading = true;
    notifyListeners(); // 立即通知 UI 显示加载状态
    final list = await PetApiService.listUserPets();
    if (list != null) {
      _pets = list;
      final defaultIdx = list.indexWhere((p) => p.isDefault);
      _selectedIndex = defaultIdx >= 0 ? defaultIdx : 0;
    }
    _loaded = true;
    _loading = false;
    notifyListeners();
  }

  /// 刷新宠物列表（允许重新加载，用于重登/添加宠物后）
  Future<void> refresh() async {
    _loading = false;
    await loadPets();
  }
}
