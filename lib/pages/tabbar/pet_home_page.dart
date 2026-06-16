import 'package:flutter/material.dart';
import '../AI/index.dart';
import '../pet/add.dart';

class PetHomePage extends StatefulWidget {
  const PetHomePage({super.key});

  @override
  State<PetHomePage> createState() => _PetHomePageState();
}

class _PetHomePageState extends State<PetHomePage> {

  int _selectedPetIndex = 0;

  static final List<_PetData> _pets = [
    // _PetData(name: '超级小虎妞', age: '两岁', gender: '妹妹', avatar: 'assets/images/pet_avatar.png', breed: '虎斑猫'),
    // _PetData(name: '图图', age: '一岁', gender: '弟弟', avatar: 'assets/images/pet_avatar.png', breed: '英短'),
  ];

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
    // TODO: 接入真实数据源后替换为实际刷新逻辑
    await Future.delayed(const Duration(milliseconds: 800));
  }

  @override
  Widget build(BuildContext context) {
    if (_pets.isEmpty) {
      return _buildEmptyState();
    }

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
            RefreshIndicator(
              onRefresh: _onRefresh,
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 90),
                child: Column(
                children: [
                  // Padding(
                  //   padding: EdgeInsets.only(top: topPadding),
                  //   child: _buildTopSection(context),
                  // ),
                  _buildTopSection(context),
                  Transform.translate(
                    offset: const Offset(0, -50), //向上偏移 50
                    child: Column(
                      children: [
                        _buildDailyReportCard(),
                        const SizedBox(height: 14),
                        _buildInsightSection(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  // const SizedBox(height: 16),
                  // _buildDailyReportCard(),
                  // const SizedBox(height: 14),
                  // _buildInsightSection(),
                  // const SizedBox(height: 16),
                  // _buildActionButtons(),
                  // const SizedBox(height: 14),
                ],
              ),
            ),
          ),
          Positioned(
              left: 16,
              right: 16,
              bottom: 20,
              child: _buildAssistantBar(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EE),
      body: SafeArea(
        child: Column(
          children: [
            // 保留顶部标题
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '请添加宠物',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            // const Spacer(),
            const SizedBox(height: 30),
            // 居中卡片
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  // 插图
                  Image.asset(
                    'assets/images/icon/home-i-1.png',
                    width: 93,
                    height: 100,
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
                  // 立即添加宠物 按钮
                  SizedBox(
                    width: 200,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPetPage()));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF8A65),
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
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSection(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      // margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.only(top: topPadding, bottom: 18, left: 18, right: 18),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: _showPetSheet,
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        children: [
                          Text(
                            _pets[_selectedPetIndex].name,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.keyboard_arrow_down, size: 20, color: Colors.black54),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.cake, size: 16, color: Colors.black54),
                        const SizedBox(width: 4),
                        Text(_pets[_selectedPetIndex].age, style: const TextStyle(color: Colors.black54)),
                        const SizedBox(width: 10),
                        const Icon(Icons.circle, size: 6, color: Colors.black26),
                        const SizedBox(width: 10),
                        const Icon(Icons.circle, size: 6, color: Colors.black26),
                        const SizedBox(width: 10),
                        const Icon(Icons.person_outline, size: 16, color: Colors.black54),
                        const SizedBox(width: 4),
                        Text(_pets[_selectedPetIndex].gender, style: const TextStyle(color: Colors.black54)),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCF2E9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.location_on, size: 16, color: Color(0xFFFFA726)),
                    SizedBox(width: 4),
                    Text('重庆', style: TextStyle(color: Color(0xFFFFA726))),
                    SizedBox(width: 8),
                    Icon(Icons.wb_sunny, size: 16, color: Color(0xFFFFA726)),
                    SizedBox(width: 4),
                    Text('28°C', style: TextStyle(color: Color(0xFFFFA726))),
                  ],
                ),
              ),
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
                      style: TextStyle(fontSize: 13, color: Color(0xFFFF8A65)),
                    ),
                    Text(
                      '早上好呀~',
                      style: TextStyle(fontSize: 13, color: Color(0xFFFF8A65)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            height: 250,
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
                color: Color.fromARGB(255, 252, 124, 124),
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
                        child: const Icon(Icons.pets, color: Color(0xFFFF8A65), size: 28),
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
                  Icon(Icons.search, color: Color(0xFFFF8A65)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '智能洞察',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    '全部',
                    style: TextStyle(color: Color(0xFFFF8A65), fontWeight: FontWeight.w600),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFFFF8A65)),
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
                child: Icon(card.icon, color: const Color(0xFFFF8A65), size: 20),
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
                    color: Color(0xFFFF8A65),
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
                  border: Border.all(color: const Color(0xFFFF8A65)),
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
                icon: const Icon(Icons.mic, color: Color(0xFFFF8A65)),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF8A65),
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                '我的宠物',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            ...List.generate(_pets.length, (i) {
              final pet = _pets[i];
              final isSelected = i == _selectedPetIndex;
              return Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() => _selectedPetIndex = i);
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          ClipOval(
                            child: Image.asset(pet.avatar, width: 48, height: 48, fit: BoxFit.cover),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(pet.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                                const SizedBox(height: 4),
                                Text('${pet.breed} · ${pet.gender}', style: const TextStyle(fontSize: 13, color: Colors.black45)),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle, color: Color(0xFFFF8A65), size: 24),
                        ],
                      ),
                    ),
                  ),
                  if (i < _pets.length - 1)
                    const Divider(height: 1, indent: 76, color: Color(0xFFF5F5F5)),
                ],
              );
            }),
            // const Divider(height: 1, color: Color(0xFFF0F0F0)),
            // ListTile(
            //   leading: const Icon(Icons.home_outlined, color: Colors.black54),
            //   title: const Text('家庭管理', style: TextStyle(fontSize: 16)),
            //   trailing: const Icon(Icons.chevron_right, color: Colors.black26),
            //   onTap: () {
            //     Navigator.pop(ctx);
            //   },
            // ),
            const SizedBox(height: 8),
          ],
        ),
        ),
      ),
    );
  }
}

class _PetData {
  final String name;
  final String age;
  final String gender;
  final String avatar;
  final String breed;
  const _PetData({
    required this.name,
    required this.age,
    required this.gender,
    required this.avatar,
    required this.breed,
  });
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
