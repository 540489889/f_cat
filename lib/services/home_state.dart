import 'package:flutter/foundation.dart';
import '../models/home_device.dart';
import '../models/home_info.dart';
import 'device_service.dart';
import 'home_api_service.dart';

/// 家庭状态管理（Provider）
///
/// 管理家庭列表、当前家庭上下文、设备列表、加载状态。
/// 自动执行：登录后首次初始化→加载家庭列表→无家庭则自动创建→加载设备。
/// 认证由 AuthHttpClient 自动处理，无需手动注入 Token。
class HomeState extends ChangeNotifier {
  // ==================== 家庭列表 ====================

  List<HomeInfo> _homes = [];
  bool _initialized = false;

  // ==================== 当前家庭 ====================

  int _currentHomeId = 0;
  String _currentHomeName = '';
  String _currentRole = '';

  // ==================== 设备列表 ====================

  List<HomeDevice> _devices = [];
  bool _loading = false;
  String? _error;

  // ==================== Getters ====================

  List<HomeInfo> get homes => _homes;
  bool get initialized => _initialized;
  int get currentHomeId => _currentHomeId;
  String get currentHomeName => _currentHomeName;
  String get currentRole => _currentRole;
  bool get isOwnerOrAdmin =>
      _currentRole == 'owner' || _currentRole == 'admin';
  List<HomeDevice> get devices => _devices;
  bool get loading => _loading;
  String? get error => _error;
  bool get hasHome => _currentHomeId > 0;
  int get deviceCount => _devices.length;

  // ==================== 初始化 ====================

  /// 重置状态（退出登录时调用）
  void reset() {
    _homes = [];
    _initialized = false;
    _currentHomeId = 0;
    _currentHomeName = '';
    _currentRole = '';
    _devices = [];
    _loading = false;
    _error = null;
    notifyListeners();
  }

  /// 初始化家庭上下文：加载家庭列表，无则自动创建
  ///
  /// 首次调用完成所有初始化，之后可单独调用 [loadDevices] 刷新。
  ///
  /// 测试阶段：后端家庭接口未对接时，使用默认家庭确保设备绑定和列表流程可走通。
  Future<void> initHome() async {
    /// TODO: 家庭接口对接完成后取消下面的注释并删除测试兜底代码
    /// 测试阶段兜底：设置默认家庭，使设备绑定和列表流程可正常工作
    _currentHomeId = 1;
    _currentHomeName = '我的家';
    _currentRole = 'owner';
    _homes = [
      HomeInfo(homeId: 1, name: '我的家', ownerId: 0, role: 'owner'),
    ];
    _loading = false;
    _initialized = true;
    notifyListeners();
    return;
    /*
    _loading = true;
    _error = null;
    notifyListeners();

    // 1. 加载家庭列表
    final listResult = await HomeApiService.getMyHomes();
    if (!listResult.isSuccess) {
      _loading = false;
      _error = listResult.message;
      _initialized = true;
      notifyListeners();
      return;
    }

    _homes = listResult.homes;

    if (_homes.isEmpty) {
      // 2. 无家庭 → 自动创建
      final createResult = await HomeApiService.createHome(
        name: '我的家',
      );
      if (createResult.isSuccess) {
        _currentHomeId = createResult.homeId;
        _currentHomeName = createResult.name;
        _currentRole = 'owner';
        _homes = [
          HomeInfo(
            homeId: createResult.homeId,
            name: createResult.name,
            ownerId: 0,
            role: 'owner',
          ),
        ];
      } else {
        _loading = false;
        _error = createResult.message;
        _initialized = true;
        notifyListeners();
        return;
      }
    } else {
      // 3. 有家庭 → 选第一个
      _currentHomeId = _homes.first.homeId;
      _currentHomeName = _homes.first.name;
      _currentRole = _homes.first.role;
    }

    _initialized = true;
    _loading = false;
    notifyListeners();

    // 4. 自动加载设备
    if (_currentHomeId > 0) {
      await loadDevices();
    }
  */
  }

  /// 切换家庭
  Future<void> switchHome(int homeId) async {
    final found = _homes.where((h) => h.homeId == homeId).firstOrNull;
    if (found == null) return;

    _currentHomeId = found.homeId;
    _currentHomeName = found.name;
    _currentRole = found.role;
    notifyListeners();
    await loadDevices();
  }

  /// 创建新家庭
  Future<String?> createHome(String name) async {
    final result = await HomeApiService.createHome(
      name: name,
    );

    if (result.isSuccess) {
      // 重新加载家庭列表
      await initHome();
      return null; // 成功，无错误
    }
    return result.message;
  }

  // ==================== 设备管理 ====================

  /// 加载当前家庭的设备列表
  Future<void> loadDevices() async {
    if (_currentHomeId <= 0) {
      _error = '请先选择或创建家庭';
      notifyListeners();
      return;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    final result = await DeviceService.getDeviceList(
      homeId: _currentHomeId,
    );

    _loading = false;
    if (result.isSuccess) {
      _devices = result.devices;
      _error = null;
    } else {
      _error = result.message;
    }
    notifyListeners();
  }

  /// 刷新设备列表
  Future<void> refresh() async {
    await loadDevices();
  }

  /// 根据设备类型获取推荐操作按钮
  static DeviceActions getActionsForType(String? deviceType) {
    switch (deviceType) {
      case 'waterer':
        return DeviceActions(
          actionLabel: '换水',
          actionCommand: 'dispense',
          actionParams: {'amount': '100'},
          iconLabel: '饮水',
        );
      case 'feeder':
        return DeviceActions(
          actionLabel: '投食',
          actionCommand: 'feed',
          actionParams: {'amount': '50'},
          iconLabel: '喂食',
        );
      case 'litter':
        return DeviceActions(
          actionLabel: '清理',
          actionCommand: 'clean',
          actionParams: null,
          iconLabel: '清洁',
        );
      default:
        return DeviceActions(
          actionLabel: '控制',
          actionCommand: 'control',
          actionParams: null,
          iconLabel: '控制',
        );
    }
  }
}

/// 设备操作按钮定义
class DeviceActions {
  final String actionLabel;
  final String actionCommand;
  final Map<String, dynamic>? actionParams;
  final String iconLabel;

  DeviceActions({
    required this.actionLabel,
    required this.actionCommand,
    this.actionParams,
    required this.iconLabel,
  });
}
