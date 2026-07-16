import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import 'package:media_kit/media_kit.dart' as media_kit;
import 'package:media_kit_video/media_kit_video.dart';
import 'package:video_player/video_player.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../../services/http_client.dart';
import '../../services/api_client.dart';
import '../../shared/route_observer.dart';
import '../AI/index.dart';
import '../pet/figure.dart';
import '../../services/pet_state.dart';
import '../../services/tab_index_notifier.dart';

class PetHomePage extends StatefulWidget {
  const PetHomePage({super.key});

  @override
  State<PetHomePage> createState() => _PetHomePageState();
}

class _PetHomePageState extends State<PetHomePage> with RouteAware {
  final ScrollController _scrollCtrl = ScrollController();
  bool _isInitialLoading = true;
  bool _showAssistantBar = false;
  double _headerOpacity = 0.0;
  bool _is3DMode = true;
  String _cityName = '定位中...';
  double? _latitude;
  double? _longitude;
  int? _temperature;
  String? _weatherCode;
  Map<String, dynamic>? _petShowData;
  int _currentCarouselPage = 0;
  final Map<int, Map<String, dynamic>> _petShowDataMap = {};
  int _loadingPetId = -1;
  // 预加载所有宠物的视频播放器
  final Map<int, VideoPlayerController> _videoPlayerMap = {};
  final Map<int, media_kit.Player> _mediaKitPlayerMap = {};
  final Map<int, VideoController> _mediaKitVideoControllerMap = {};
  final Map<int, StreamSubscription> _playerCompletedSubs = {};
  // 视频是否已"真正就绪"（初始化完成 + 首帧渲染延迟后），避免加载中画面被提前淡入
  final Map<int, bool> _videoReadyMap = {};
  TabIndexNotifier? _tabNotifier;
  bool _isHuawei = false;
  bool _isPetSheetOpen = false; // 顶部弹窗打开期间阻止 didPopNext 触发的刷新
  PetState? _petState; // 保存引用用于 dispose 中 removeListener

  bool get _currentVideoReady {
    final petId = _getCurrentPetId();
    if (petId == null) return false;
    if (_isHuawei) return _mediaKitPlayerMap.containsKey(petId);
    return _videoPlayerMap.containsKey(petId) && _videoPlayerMap[petId]!.value.isInitialized;
  }

  int? _getCurrentPetId() {
    final petState = context.read<PetState>();
    if (_currentCarouselPage < petState.pets.length) {
      return petState.pets[_currentCarouselPage].id;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _petState = context.read<PetState>();
    _scrollCtrl.addListener(() {
      if (!_scrollCtrl.hasClients) return;
      final pixels = _scrollCtrl.position.pixels;
      final show = pixels > 200;
      if (_showAssistantBar != show) setState(() => _showAssistantBar = show);
      // 标题栏透明度：滚动 100~350px 从 0 过渡到 1
      final opacity = (pixels - 100).clamp(0, 250) / 250.0;
      if ((opacity - _headerOpacity).abs() > 0.01) {
        setState(() => _headerOpacity = opacity);
      }
    });
    _initLocation();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _detectDevice();
      if (!mounted) return;
      _setupPetStateListener();
      _setupTabListener();
    });
  }

  void _setupPetStateListener() {
    final petState = context.read<PetState>();
    // 先检查 PetState 是否已加载
    _tryLoadPetShow(petState);
    // 未加载则监听变化
    if (!petState.isLoaded) {
      petState.addListener(_onPetStateReady);
    }
  }

  void _onPetStateReady() {
    if (!mounted) return;
    final petState = context.read<PetState>();
    if (petState.isLoaded) {
      petState.removeListener(_onPetStateReady);
      _tryLoadPetShow(petState);
    }
  }

  void _tryLoadPetShow(PetState petState) {
    if (petState.pets.isNotEmpty && _petShowData == null) {
      final defaultIdx = petState.pets.indexWhere((p) => p.isDefault);
      final startIdx = defaultIdx >= 0 ? defaultIdx : 0;
      _loadPetShow(petState.pets[startIdx].id);
      // 立即开始预加载所有宠物的视频
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadAllPetShowData(petState.pets);
      });
    }
  }

  Future<void> _loadAllPetShowData(List<dynamic> pets) async {
    for (final pet in pets) {
      final petId = pet.id;
      if (petId <= 0 || _petShowDataMap.containsKey(petId)) continue;
      if (_loadingPetId == petId) continue;
      _loadingPetId = petId;
      try {
        final res = await ApiClient.instance.get('/app/pet/show/$petId');
        if (res.isSuccess && res.isMap && mounted) {
          final data = res.asMap;
          _petShowDataMap[petId] = data;
          _preloadPetVideo(petId, data);
        }
      } catch (_) {}
      _loadingPetId = -1;
    }
  }

  void _preloadPetVideo(int petId, Map<String, dynamic> data) {
    final url = data['mediaUrl'] as String?;
    if (url == null || url.isEmpty) return;
    if (_videoPlayerMap.containsKey(petId) || _mediaKitPlayerMap.containsKey(petId)) return;

    if (!_isHuawei) {
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      // 先放入 map 让 VideoPlayer 组件挂载，初始化完成后再淡入，避免黑屏
      setState(() => _videoPlayerMap[petId] = controller);
      controller.initialize().then((_) {
        if (!mounted) return;
        controller.setVolume(0);
        controller.setLooping(true);
        if (petId == _getCurrentPetId()) controller.play();
        // 初始化完成后触发重建：视频层 opacity 依赖 controller.value.isInitialized，
        // 若此处不 setState，build 会一直停留在旧的 false，导致视频层永远不显示
        if (mounted) setState(() {});
        // 监听视频播放进度：当真正开始播放（已渲染首帧、不在缓冲）时才淡入，
        // 比固定延迟更精准，可避免淡入到"加载中"画面
        void Function()? listener;
        listener = () {
          final v = controller.value;
          if (v.isPlaying && !v.isBuffering && v.position > Duration.zero) {
            if (!mounted) return;
            setState(() => _videoReadyMap[petId] = true);
            final l = listener;
            if (l != null) controller.removeListener(l);
          }
        };
        controller.addListener(listener);
        // 兜底：若首帧事件因某些时序未触发（如切换宠物后），2s 后强制淡入，
        // 避免视频永远停在背景图、看起来"未播放"
        Future.delayed(const Duration(milliseconds: 2000), () {
          if (!mounted) return;
          if (_videoReadyMap[petId] != true) {
            setState(() => _videoReadyMap[petId] = true);
          }
        });
      }).catchError((e) {
        print('[video] 预加载失败 petId=$petId: $e');
      });
    } else {
      final player = media_kit.Player();
      final vc = VideoController(player);
      player.open(media_kit.Media(url));
      player.setVolume(0);
      if (petId == _getCurrentPetId()) player.play();
      final sub = player.stream.completed.listen((_) {
        if (!mounted) return;
        player.seek(Duration.zero);
        player.play();
      });
      // 监听播放开始：playing=true 说明 player 已开始工作，再等 2s 确保首帧解码完成
      player.stream.playing.listen((isPlaying) {
        if (isPlaying && mounted && _videoReadyMap[petId] != true) {
          Future.delayed(const Duration(seconds: 5), () {
            if (mounted) setState(() => _videoReadyMap[petId] = true);
          });
        }
      });
      // 立即放入 map，由底层图片兜底，视频就绪后自然覆盖
      setState(() {
        _mediaKitPlayerMap[petId] = player;
        _mediaKitVideoControllerMap[petId] = vc;
        _playerCompletedSubs[petId] = sub;
      });
    }
  }

  void _syncActiveVideo(int activePetId) {
    // 目标视频若已初始化完成，可立即标记就绪（切换时直接淡入，不依赖首帧监听时序）
    bool targetReady = false;
    for (final entry in _videoPlayerMap.entries) {
      // 未初始化完成时不要调用 play/pause，避免异常
      if (!entry.value.value.isInitialized) continue;
      if (entry.key == activePetId) {
        entry.value.play();
        targetReady = true;
      } else {
        entry.value.pause();
      }
    }
    for (final entry in _mediaKitPlayerMap.entries) {
      if (entry.key == activePetId) {
        entry.value.seek(Duration.zero);
        entry.value.play();
      } else {
        entry.value.pause();
      }
    }
    // 切换后：已初始化完成的视频立即标记就绪并重建；未完成的由初始化完成逻辑处理
    if (mounted) {
      setState(() {
        if (targetReady) _videoReadyMap[activePetId] = true;
      });
    }
  }

  Future<void> _detectDevice() async {
    try {
      final info = await DeviceInfoPlugin().androidInfo;
      final manufacturer = info.manufacturer.toLowerCase();
      _isHuawei = manufacturer.contains('huawei');
    } catch (_) {
      _isHuawei = false;
    }
  }

  void _setupTabListener() {
    final notifier = context.read<TabIndexNotifier>();
    _tabNotifier = notifier;
    notifier.addListener(_onTabChanged);
    _onTabChanged();
  }

  void _onTabChanged() {
    final active = _tabNotifier?.index == 0;
    if (active) {
      final petId = _getCurrentPetId();
      if (petId != null) _syncActiveVideo(petId);
    } else {
      for (final c in _videoPlayerMap.values) {
        c.pause();
      }
      for (final p in _mediaKitPlayerMap.values) {
        p.pause();
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPopNext() {
    // 顶部宠物选择弹窗关闭时不刷新，避免把刚切到的视频切回默认宠物
    if (_isPetSheetOpen) return;
    // 从 push 的页面返回时，刷新宠物列表
    _refreshOnReturn();
  }

  /// 从其他页面返回时刷新宠物列表和展示数据
  Future<void> _refreshOnReturn() async {
    await context.read<PetState>().refresh();
    if (!mounted) return;
    final petState = context.read<PetState>();
    if (petState.isLoaded && petState.pets.isNotEmpty) {
      _petShowDataMap.clear();
      _petShowData = null;
      _loadPetShow(petState.pets[0].id);
      _loadAllPetShowData(petState.pets);
    }
  }


  Future<void> _initLocation() async {
    await _loadCity();
    _loadWeather();
  }

  Future<void> _loadCity() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) setState(() => _cityName = '无权限');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _cityName = '无权限');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
      );
      _latitude = position.latitude;
      _longitude = position.longitude;
      final placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final city = placemarks.first.locality ?? placemarks.first.subAdministrativeArea ?? '';
        if (mounted && city.isNotEmpty) setState(() => _cityName = city);
      }
    } catch (_) {
      if (mounted) setState(() => _cityName = '未知');
    }
  }

  Future<void> _loadWeather() async {
    try {
      if (_latitude == null || _longitude == null) {
        print('[Weather] ⚠ 无定位坐标，跳过天气请求');
        return;
      }
      final uri = Uri.parse('https://app.jolipaw.pet/app/common/weather');
      final body = jsonEncode({'latitude': _latitude, 'longitude': _longitude});
      print('[Weather] ▶ 请求地址: $uri');
      print('[Weather] ▶ 请求体: $body');
      final response = await AuthHttpClient.instance.post(uri, body: body).timeout(const Duration(seconds: 10));
      print('[Weather] ◀ 状态码: ${response.statusCode}');
      print('[Weather] ◀ 响应体: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final code = data['code'];
        print('[Weather] ◀ code=$code, data=${data['data']}');
        if (code == 0 || code == 200) {
          final weather = data['data'] as Map<String, dynamic>?;
          // 温度：API 返回 "29.44°C" 格式字符串，提取数值部分
          final tempRaw = weather?['temperature'] ?? weather?['temp'];
          int? tempInt;
          if (tempRaw != null) {
            final tempStr = tempRaw.toString().replaceAll(RegExp(r'[^0-9.]'), '');
            tempInt = double.tryParse(tempStr)?.round();
          }
          // 天气代码：API 返回 skycon 字段
          final wCode = weather?['skycon'] ?? weather?['weather_code'] ?? weather?['type'];
          print('[Weather]  📊 解析: temperature=$tempRaw → $tempInt, skycon=$wCode');
          if (mounted) {
            setState(() {
              if (tempInt != null) _temperature = tempInt;
              if (wCode != null) _weatherCode = wCode.toString();
            });
            print('[Weather] ✔ 更新完成: _temperature=$_temperature, _weatherCode=$_weatherCode');
          }
        }
      }
    } catch (e) {
      print('[Weather] ✖ 加载失败: $e');
    }
  }



  static const _statusChips = [
    _ChipData(label: '状态很好', color: Color(0xFFD4F1D9), icon: Icons.favorite),
    _ChipData(label: '乖巧粘人', color: Color(0xFFFFE5E5), icon: Icons.favorite_border),
  ];

  static const _insightCards = [
    _InsightCardData(
      title: '本周饮水趋势下降15%',
      subtitle:
          '结合近期气温下降属于正常季节性波动。但如果持续下降超过3天，建议关注。',
      badge: '今天',
      color: Color(0xFFE7F2FF),
      icon: Icons.water_drop,
      date: '4月30日 09:00',
    ),
    _InsightCardData(
      title: '超级小虎妞连续7天饮食达标',
      subtitle: '健康习惯正在养成中，请多注意呵护~',
      badge: '昨天',
      color: Color(0xFFFFF4E6),
      icon: Icons.emoji_food_beverage,
      date: '4月29日 09:00',
    ),
    _InsightCardData(
      title: '明日预计降温',
      subtitle: '据天气预报，明日气温将降至8°C左右，建议开启饮水机加温功能。',
      badge: '1天前',
      color: Color(0xFFFFE8F0),
      icon: Icons.thermostat,
      date: '4月28日 09:00',
    ),
  ];



  Future<void> _loadPetShow(int petId) async {
    if (_petShowDataMap.containsKey(petId)) {
      final data = _petShowDataMap[petId]!;
      setState(() => _petShowData = data);
      _preloadPetVideo(petId, data);
      _syncActiveVideo(petId);
      return;
    }
    try {
      final res = await ApiClient.instance.get('/app/pet/show/$petId');
      if (res.isSuccess && res.isMap && mounted) {
        final data = res.asMap;
        _petShowDataMap[petId] = data;
        _preloadPetVideo(petId, data);
        setState(() => _petShowData = data);
        _syncActiveVideo(petId);
      }
    } catch (e) {
      // ignore
    }
  }

  IconData get _weatherIcon {
    switch (_weatherCode) {
      case 'cloudy':
        return Icons.cloud;
      case 'rainy':
        return Icons.water_drop;
      case 'snowy':
        return Icons.ac_unit;
      case 'sunny':
      default:
        return Icons.wb_sunny;
    }
  }

  String get _weatherText {
    if (_temperature == null) return '--°C';
    return '$_temperature°C';
  }

  @override
  Widget build(BuildContext context) {
    final petState = context.watch<PetState>();
    final pets = petState.pets;

    // 已确认无宠物 → 显示添加宠物页面
    if (petState.isLoaded && pets.isEmpty) {
      return _buildEmptyState();
    }

    // 首次加载完数据后标记，刷新期间不隐藏内容避免闪烁
    if (petState.isLoaded && _isInitialLoading) {
      _isInitialLoading = false;
    }
    final loading = _isInitialLoading;

    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFFF5F0EE),
      body: SafeArea(
        top: false,
        bottom: true,
        left: false,
        right: false,
        child: Stack(
          children: [
            // 可滚动内容区域（撑满全屏，标题栏悬浮在上方）
            Column(
          children: [
            Expanded(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CustomScrollView(
                          controller: _scrollCtrl,
                          slivers: [
                            if (loading)
                              SliverToBoxAdapter(child: _buildTopSectionLoading())
                            else
                              SliverToBoxAdapter(child: _buildTopSection(context)),
                            if (!loading) ...[
                              SliverToBoxAdapter(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildDailyReportCard(),
                                    const SizedBox(height: 14),
                                    _buildInsightSection(),
                                    const SizedBox(height: 16),
                                  ],
                                ),
                              ),
                              const SliverPadding(padding: EdgeInsets.only(bottom: 140)),
                            ],
                          ],
                        ),
                      // Assistant bar：滚动超过标题高度后显示，带动画
                      if (!loading)
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          left: 16,
                          right: 16,
                          bottom: _showAssistantBar ? 20 : -120,
                          child: AnimatedOpacity(
                            opacity: _showAssistantBar ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeInOut,
                            child: IgnorePointer(
                              ignoring: !_showAssistantBar,
                              child: _buildAssistantBar(),
                            ),
                          ),
                        ),
                      if (loading)
                        Container(
                          color: Colors.transparent,
                          child: const Center(
                            child: CircularProgressIndicator(color: Color(0xFFFF7A47)),
                          ),
                        ),
                    ],
                  ),
                ),
          ],
        ),
            // 悬浮标题栏
            if (!loading) _buildHeaderOverlay(context, petState),
          ],
    ),
      ),
    );
  }

  void _toggle3DMode() {
    setState(() => _is3DMode = !_is3DMode);
  }

  @override
  void dispose() {
    _tabNotifier?.removeListener(_onTabChanged);
    routeObserver.unsubscribe(this);
    _petState?.removeListener(_onPetStateReady);
    for (final sub in _playerCompletedSubs.values) {
      sub.cancel();
    }
    _playerCompletedSubs.clear();
    for (final c in _videoPlayerMap.values) {
      c.dispose();
    }
    _videoPlayerMap.clear();
    for (final p in _mediaKitPlayerMap.values) {
      p.dispose();
    }
    _mediaKitPlayerMap.clear();
    _mediaKitVideoControllerMap.clear();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Widget _buildEmptyState() {
    final topPadding = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        top: false,
        bottom: true,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 顶部区域 
              Container(
                padding: EdgeInsets.only(top: topPadding, bottom: 18, left: 18, right: 18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x332F2F2F),
                      Color(0x002F2F2F),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(0),
                  boxShadow: [
                    const BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.04),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '请添加宠物',
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(width: 6),
                                  // Icon(Icons.keyboard_arrow_down, size: 20, color: Colors.black54),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0x142F2F2F),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on, size: 16, color: Color(0xFFFFFFFF)),
                              const SizedBox(width: 4),
                              Text(_cityName, style: const TextStyle(color: Color(0xFFFFFFFF))),
                              const SizedBox(width: 8),
                              Icon(Icons.wb_sunny, size: 16, color: Color(0xFFFFFFFF)),
                              SizedBox(width: 4),
                              Text('28°C', style: TextStyle(color: Color(0xFFFFFFFF))),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                      Row(
                      children: [
                        Image.asset('assets/images/icon/s1.png', width: 16, height: 16),
                        SizedBox(width: 4),
                        Text('--', style: TextStyle(color: Colors.black54)),
                        SizedBox(width: 10),
                        Image.asset('assets/images/icon/s2.png', width: 16, height: 16),
                        Text('--', style: TextStyle(color: Colors.black54)),
                        SizedBox(width: 10),
                        Icon(Icons.female, size: 20, color: Colors.black54),
                        SizedBox(width: 4),
                        Text('--', style: TextStyle(color: Colors.black54)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              // 中间插图 + 创建提示
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/icon/home-i-0.png',
                      width: 132,
                      height: 132,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      '请先创建宠物资料',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '创建宠物资料，记录萌宠的美好生活~',
                      style: TextStyle(fontSize: 14, color: Colors.black45),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: 200,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: () async {
                          final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const PetFigurePage()));
                          if (result == true) {
                            context.read<PetState>().refresh();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF7A47),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(23),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          '立即添加宠物',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFFDF5F1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 28, color: const Color(0xFFFF7A47)),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildTopSectionLoading() {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          const BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.04),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
    );
  }

  /// 顶部标题栏（默认在内容中，滚动后悬浮在顶部）
  Widget _buildHeaderOverlay(BuildContext context, PetState petState) {
    final bgColor = Color.lerp(
      Colors.transparent,
      const Color(0xFFE2DEDB),
      _headerOpacity,
    )!;
    final borderColor = Color.lerp(
      Colors.transparent,
      const Color(0xFFD5CFCC),
      _headerOpacity,
    )!;
    // _headerOpacity=0 时完全隐藏（向上移出屏幕）
    final slideOffset = -70.0 * (1.0 - _headerOpacity.clamp(0.0, 1.0));
    return Transform.translate(
      offset: Offset(0, slideOffset),
      child: Opacity(
        opacity: _headerOpacity.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            border: Border(bottom: BorderSide(color: borderColor, width: 0.5)),
          ),
          child: _buildFixedHeader(context, petState),
        ),
      ),
    );
  }

  /// 固定在顶部的标题栏：宠物名称 + 天气
  Widget _buildFixedHeader(BuildContext context, PetState petState) {
    final pets = petState.pets;
    final pageIdx = _currentCarouselPage.clamp(0, pets.length - 1);
    if (pets.isEmpty || pageIdx >= pets.length) return const SizedBox.shrink();

    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.only(top: topPadding + 8, bottom: 8, left: 16, right: 16),
      color: Colors.transparent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _showPetSheet,
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Text(
                    pets[pageIdx].nickname,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.keyboard_arrow_down, size: 20, color: Colors.black54),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0x142F2F2F),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Color(0xFFFFFFFF)),
                const SizedBox(width: 4),
                Text(_cityName, style: const TextStyle(color: Color(0xFFFFFFFF))),
                const SizedBox(width: 8),
                Icon(_weatherIcon, size: 16, color: const Color(0xFFFFFFFF)),
                const SizedBox(width: 4),
                Text(_weatherText, style: const TextStyle(color: Color(0xFFFFFFFF))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSection(BuildContext context) {
    final petState = context.watch<PetState>();
    final pets = petState.pets;

    return Container(
      height: 380,
      decoration: BoxDecoration(
        color: const Color(0xFFE2DEDB),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (!mounted) return;
          final velocity = details.primaryVelocity ?? 0;
          if (velocity < -50 && _currentCarouselPage < pets.length - 1) {
            final next = _currentCarouselPage + 1;
            setState(() => _currentCarouselPage = next);
            _loadPetShow(pets[next].id);
          } else if (velocity > 50 && _currentCarouselPage > 0) {
            final prev = _currentCarouselPage - 1;
            setState(() => _currentCarouselPage = prev);
            _loadPetShow(pets[prev].id);
          }
        },
        child: Stack(
          children: List.generate(pets.length, (index) {
            final isActive = index == _currentCarouselPage;
            return AnimatedOpacity(
              key: ValueKey('pet_${pets[index].id}'),
              opacity: isActive ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 350),
              child: isActive || _petShowDataMap.containsKey(pets[index].id)
                  ? _buildPetPageContent(pets[index], petState)
                  : const SizedBox(),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildPetPageContent(dynamic pet, PetState petState) {
    final petId = pet.id;
    final showData = _petShowDataMap[petId] ?? _petShowData;
    final mediaUrl = showData?['mediaUrl'] as String?;
    final isVideo = mediaUrl != null && mediaUrl.isNotEmpty;
    // 优先用 /show 接口的 imgUrl，接口未返回时用宠物列表自带的 petUserShow.imgUrl
    final imgUrl = (showData?['imgUrl'] as String?) ?? (pet.petUserShow?['imgUrl'] as String?);
    // 接口返回的气泡台词（宠物心情/状态短句）
    final rawWords = pet.petUserShow?['words'];
    final List<String> words = rawWords is List
        ? rawWords.map((e) => e.toString()).toList()
        : const <String>[];

    final vpController = _videoPlayerMap[petId];
    final mkVideoController = _mediaKitVideoControllerMap[petId];




    return Stack(
      children: [
        // 底层图片始终存在：视频未就绪时展示，避免切换瞬间黑屏
        if (imgUrl != null && imgUrl.isNotEmpty)
          Positioned.fill(
            child: Image.network(
              imgUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox(),
            ),
          )
        else if (showData != null)
          Positioned.fill(
            child: Image.asset('assets/images/cat-bg.png', fit: BoxFit.cover),
          ),

        // 视频层：初始化完成后再淡入覆盖在图片之上
        if (isVideo && !_isHuawei && vpController != null)
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: (vpController.value.isInitialized && _videoReadyMap[petId] == true) ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 500),
              child: AbsorbPointer(child: VideoPlayer(vpController)),
            ),
          )
        else if (isVideo && _isHuawei && mkVideoController != null)
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: (_videoReadyMap[petId] == true) ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 400),
              child: AbsorbPointer(
                child: Video(
                  key: ValueKey('mkv_$petId'),
                  controller: mkVideoController,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

        Column(
          children: [
            _buildFixedHeader(context, petState),
            Padding(
              padding: const EdgeInsets.only(bottom: 18, left: 18, right: 18),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Image.asset('assets/images/icon/s1.png', width: 16, height: 16),
                      const SizedBox(width: 4),
                      Text(pet.ageLabel, style: const TextStyle(color: Colors.black54)),
                      const SizedBox(width: 10),
                      Image.asset('assets/images/icon/s2.png', width: 16, height: 16),
                      const SizedBox(width: 8),
                      Text(pet.variety, style: const TextStyle(color: Colors.black54)),
                      const SizedBox(width: 8),
                      const Icon(Icons.person_outline, size: 16, color: Colors.black54),
                      const SizedBox(width: 4),
                      Text(pet.genderLabel, style: const TextStyle(color: Colors.black54)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _buildBubbleChips(pet).asMap().entries.map((e) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _buildStatusChip(e.value, index: e.key),
                                ))
                            .toList(),
                      ),
                      const Spacer(),
                      Container(
                        width: 132,
                        height: 72,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Opacity(
                                opacity: 0.5,
                                child: Image.asset(
                                  'assets/images/icon/hello.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Text('Hi~主人',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFFFF7A47),
                                          fontWeight: FontWeight.w600)),
                                  Text(
                                    words.isNotEmpty ? words.first : '早上好呀~',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFFFF7A47)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusChip(_ChipData chip, {int index = 0}) {
    return _BubbleChip(chip: chip, index: index);
  }

  /// 根据接口返回的 words 生成气泡芯片；为空时回退到默认标签
  List<_ChipData> _buildBubbleChips(dynamic pet) {
    final rawWords = pet.petUserShow?['words'];
    final List<String> words = rawWords is List
        ? rawWords.map((e) => e.toString()).toList()
        : const <String>[];
    if (words.isEmpty) return _statusChips;
    const colors = [
      Color(0xFFD4F1D9),
      Color(0xFFFFE5E5),
      Color(0xFFE7F2FF),
      Color(0xFFFFF4E6),
      Color(0xFFFFE8F0),
    ];
    const icons = [
      Icons.chat_bubble_outline,
      Icons.favorite,
      Icons.pets,
      Icons.emoji_emotions,
      Icons.lightbulb,
    ];
    return words.asMap().entries.map((e) => _ChipData(
          label: e.value,
          color: colors[e.key % colors.length],
          icon: icons[e.key % icons.length],
        )).toList();
  }

  Widget _buildDailyReportCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            const BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.05),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              // color: const Color.fromARGB(255, 252, 124, 124),
               decoration: BoxDecoration(
                color: Color(0xFFFF7E4D),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),   // 左上圆角
                    topRight: Radius.circular(16),  // 右上圆角
                    
                  ),
                boxShadow: [
                  const BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.05),
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    Image.asset(
                      "assets/images/icon/t1.png",
                      width: 24,
                      height: 24,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '今日早报',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFFFFFFFF),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      '全部',
                      style: TextStyle(
                        color: Color(0xFFFFFFFF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFFFFFFFF)),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF4F4F4)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF2E8),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.pets, color: Color(0xFFFF7A47), size: 28),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          '铲屎官～，昨天吱吱喝180ml水，炖了280g饭，运动125 min，乖乖拉了3次便便，我是超懂事的小宝贝呀~',
                          style: TextStyle(fontSize: 14, height: 1.6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: const [
                      _TagChip(label: '#干饭王'),
                      _TagChip(label: '#午后慵懒'),
                      _TagChip(label: '#运动健将'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    '4月31日 09:00',
                    style: TextStyle(fontSize: 12, color: Color(0xFFB0B0B0)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            const BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.05),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: const [
                  Icon(Icons.search, color: Color(0xFFFF7A47)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '智能洞察',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    '全部',
                    style: TextStyle(color: Color(0xFFFF7A47), fontWeight: FontWeight.w600),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFFFF7A47)),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF4F4F4)),
            ..._insightCards.map((card) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: _buildInsightCard(card),
                )),
                
          ],
        ),
      ),
    );
  }

  Widget _buildInsightCard(_InsightCardData card) {
    return Container(
      decoration: BoxDecoration(
        color: card.color,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(card.icon, color: const Color(0xFFFF7A47), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  card.title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  card.badge,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFFF7A47),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            card.subtitle,
            style: const TextStyle(fontSize: 13, color: Color(0xFF5F5F5F), height: 1.6),
          ),
          const SizedBox(height: 12),
          Text(
            card.date,
            style: const TextStyle(fontSize: 11, color: Color(0xFF9C9C9C)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final labels = ['水量分析', '饮食建议', '今日心情', '更多'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: labels
            .map(
              (label) => Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      const BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.04),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      label,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF5F5F5F), fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildAssistantBar() {
    final labels = ['水量分析', '饮食建议', '今日心情', '更多'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            const BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.2), // 阴影颜色
                blurRadius: 10, // 阴影模糊度（调大才会散开）
                spreadRadius: 2, // 阴影扩散范围（让阴影更大）
                offset: Offset(0, 0), // 偏移 X=0 Y=0 → 阴影居中、四周均匀
            ),
          ],
        ),
        
        child:Column(
          children: [
             Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: labels
                    .map(
                      (label) => Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF4E6),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              const BoxShadow(
                                color: Color.fromRGBO(0, 0, 0, 0.04),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              label,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF5F5F5F), fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
          const SizedBox(height: 12), // 两行之间的间距
            Builder(
              builder: (context) => GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AIPage()),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFFF7A47)),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Row(
            children: [
              Container(
                // width: 32,
                // height: 32,
                decoration: BoxDecoration(
                  // color: const Color(0xFFFFF2E8),
                  // borderRadius: BorderRadius.circular(14),
                ),
                child: Image.asset('assets/images/icon/bluetooth-ico.png', width: 30, height: 30),
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  '有什么问题都可以问我哦~',
                  style: TextStyle(fontSize: 12, color: Color(0xFF5F5F5F)),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.mic, color: Color(0xFFFF7A47)),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF7A47),
                  shape: BoxShape.circle,
                ),
                child: Image.asset('assets/images/icon/send-1.png', width: 20, height: 20),
              ),
            ],
          ),
              ),
            ), // GestureDetector
            ), // Builder
          ]
        )
        
        
      ),
    );
  }
  Future<void> _showPetSheet() async {
    final petState = context.read<PetState>();
    final pets = petState.pets;
    final selectedIdx = _currentCarouselPage;

    _isPetSheetOpen = true;
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'pet-selector',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, _, _) => Stack(
        children: [
          Positioned(
            top: MediaQuery.of(context).padding.top + 40,
            left: 16,
            right: 16,
            child: Material(
              color: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromRGBO(0, 0, 0, 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(pets.length, (i) {
                      final pet = pets[i];
                      final isSelected = i == selectedIdx;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _currentCarouselPage = i);
                          _loadPetShow(pets[i].id);
                          Navigator.pop(ctx);
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0x0AFF8A65) : Colors.transparent,
                          ),
                          child: Row(
                            children: [
                              ClipOval(
                                child: pet.headimg.isNotEmpty
                                    ? Image.network(
                                        pet.headimg,
                                        width: 44,
                                        height: 44,
                                        fit: BoxFit.cover,
                                        errorBuilder: (ctx, err, stack) => Image.asset(
                                          'assets/images/icon/home-i-0.png',
                                          width: 44,
                                          height: 44,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Image.asset(
                                        'assets/images/icon/home-i-0.png',
                                        width: 44,
                                        height: 44,
                                        fit: BoxFit.cover,
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  pet.nickname,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: isSelected ? const Color(0xFFFF7A47) : const Color(0xFF2F2F2F),
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFF7A47),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check, color: Colors.white, size: 14),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      transitionBuilder: (ctx, anim, _, child) {
        return FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.1),
              end: Offset.zero,
            ).animate(anim),
            child: child,
          ),
        );
      },
    );
    if (mounted) _isPetSheetOpen = false;
  }
}

class _BubbleChip extends StatefulWidget {
  final _ChipData chip;
  final int index;
  const _BubbleChip({required this.chip, this.index = 0});

  @override
  State<_BubbleChip> createState() => _BubbleChipState();
}

class _BubbleChipState extends State<_BubbleChip> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _floatAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _floatAnim = Tween<double>(begin: -3.0, end: 3.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
    // 每个气泡错开启动时间
    Future.delayed(Duration(milliseconds: widget.index * 500), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnim.value),
          child: Transform.scale(
            scale: _scaleAnim.value,
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              widget.chip.color.withValues(alpha: 0.9),
              widget.chip.color.withValues(alpha: 0.68),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.6),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.chip.color.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.chip.icon, size: 13, color: const Color(0xFF4A4A4A)),
            const SizedBox(width: 5),
            Text(
              widget.chip.label,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF4A4A4A),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipData {
  final String label;
  final Color color;
  final IconData icon;

  const _ChipData({required this.label, required this.color, required this.icon});
}

class _InsightCardData {
  final String title;
  final String subtitle;
  final String badge;
  final Color color;
  final IconData icon;
  final String date;

  const _InsightCardData({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.color,
    required this.icon,
    required this.date,
  });
}

class _TagChip extends StatelessWidget {
  final String label;
  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3EF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, color: Color(0xFF7F7F7F)),
      ),
    );
  }
}
