import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:easy_refresh/easy_refresh.dart';
import '../../services/http_client.dart';
import '../AI/index.dart';
import '../pet/add.dart';
import '../../services/pet_state.dart';

class PetHomePage extends StatefulWidget {
  const PetHomePage({super.key});

  @override
  State<PetHomePage> createState() => _PetHomePageState();
}

class _PetHomePageState extends State<PetHomePage> {
  late EasyRefreshController _easyController;
  final ScrollController _scrollCtrl = ScrollController();
  bool _isInitialLoading = true;
  bool _showAssistantBar = false;
  String _cityName = '定位中...';
  double? _latitude;
  double? _longitude;
  int? _temperature;
  String? _weatherCode; // sunny / cloudy / rainy / snowy

  @override
  void initState() {
    super.initState();
    _easyController = EasyRefreshController(
      controlFinishRefresh: true,
      controlFinishLoad: true,
    );
    _scrollCtrl.addListener(() {
      if (!_scrollCtrl.hasClients) return;
      final show = _scrollCtrl.position.pixels > 200;
      if (_showAssistantBar != show) setState(() => _showAssistantBar = show);
    });
    _initLocation();
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
          final temp = weather?['temperature'] ?? weather?['temp'];
          final wCode = weather?['weather_code'] ?? weather?['type'];
          print('[Weather]  📊 解析: temperature=$temp, weather_code=$wCode');
          if (mounted) {
            setState(() {
              if (temp != null) _temperature = (temp is int) ? temp : temp.toInt();
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



  Future<void> _onRefresh() async {
    await context.read<PetState>().refresh();
    if (mounted) _easyController.finishRefresh();
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
        child: Column(
          children: [
            // 固定标题栏
            if (!loading) _buildFixedHeader(context, petState),
            // 可滚动内容区域
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  EasyRefresh(
                    controller: _easyController,
                    header: ClassicHeader(
                      backgroundColor: const Color(0xFFE2DEDB),
                      showMessage: true,
                      showText: true,
                      dragText: '下拉刷新',
                      armedText: '释放刷新',
                      readyText: '刷新中...',
                      processingText: '刷新中...',
                      processedText: '刷新成功',
                      failedText: '刷新失败',
                      noMoreText: '没有更多',
                      messageText: '最后更新于 %T',
                    ),
                    onRefresh: () async {
                      await _onRefresh();
                      _easyController.finishRefresh();
                      _easyController.resetFooter();
                    },
                    child: CustomScrollView(
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
                  ),
                  // Assistant bar：滚动超过标题高度后显示，带动画
                  if (!loading)
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 350),
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
                      color: const Color(0xFFE2DEDB),
                      child: const Center(
                        child: CircularProgressIndicator(color: Color(0xFFFF7A47)),
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

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _easyController.dispose();
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
                          final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPetPage()));
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

  /// 固定在顶部的标题栏：宠物名称 + 天气
  Widget _buildFixedHeader(BuildContext context, PetState petState) {
    final pets = petState.pets;
    final selectedIdx = petState.selectedIndex;
    if (pets.isEmpty || selectedIdx >= pets.length) return const SizedBox.shrink();

    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.only(top: topPadding + 8, bottom: 8, left: 16, right: 16),
      color: const Color(0xFFE2DEDB),
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
                    pets[selectedIdx].nickname,
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
    final topPadding = MediaQuery.of(context).padding.top;
    final petState = context.watch<PetState>();
    final pets = petState.pets;
    final selectedIdx = petState.selectedIndex;
    return Container(
      // margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.only(top: 0, bottom: 18, left: 18, right: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(0),
        image: const DecorationImage(
          image: AssetImage('assets/images/cat-bg.png'),
          fit: BoxFit.cover,
        ),
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
          const SizedBox(height: 10),
          Row(
            children: [
              Image.asset('assets/images/icon/s1.png', width: 16, height: 16),
              const SizedBox(width: 4),
              Text(pets[selectedIdx].ageLabel, style: const TextStyle(color: Colors.black54)),
              const SizedBox(width: 10),
              Image.asset('assets/images/icon/s2.png', width: 16, height: 16),
              const SizedBox(width: 8),
              Text(pets[selectedIdx].variety, style: const TextStyle(color: Colors.black54)),
              const SizedBox(width: 8),
              const Icon(Icons.person_outline, size: 16, color: Colors.black54),
              const SizedBox(width: 4),
              Text(pets[selectedIdx].genderLabel, style: const TextStyle(color: Colors.black54)),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _statusChips
                    .map((chip) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _buildStatusChip(chip),
                        ))
                    .toList(),
              ),
              const Spacer(),
              Container(
                width: 120,
                height: 62,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/icon/hello.png'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Hi~主人',
                      style: TextStyle(fontSize: 13, color: Color(0xFFFF7A47)),
                    ),
                    Text(
                      '早上好呀~',
                      style: TextStyle(fontSize: 13, color: Color(0xFFFF7A47)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            height: 225,
            // decoration: BoxDecoration(
            //   color: const Color(0xFFFDF5F1),
            //   borderRadius: BorderRadius.circular(28),
            // ),
            // child: const Center(
            //   child: Icon(
            //     Icons.pets,
            //     size: 180,
            //     color: Color(0xFFFFA726),
            //   ),
            // ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(_ChipData chip) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: chip.color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(chip.icon, size: 14, color: const Color(0xFF5F5F5F)),
          const SizedBox(width: 6),
          Text(
            chip.label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF5F5F5F)),
          ),
        ],
      ),
    );
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
  void _showPetSheet() {
    final petState = context.read<PetState>();
    final pets = petState.pets;
    final selectedIdx = petState.selectedIndex;

    showGeneralDialog(
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
                          Navigator.pop(ctx);
                          petState.selectPet(i);
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
