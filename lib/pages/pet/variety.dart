import 'package:flutter/material.dart';

class VarietyPage extends StatefulWidget {
  const VarietyPage({super.key});

  @override
  State<VarietyPage> createState() => _VarietyPageState();
}

class _VarietyPageState extends State<VarietyPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _hot = [
    '中华田园猫', '英国短毛猫', '布偶猫', '英短金渐层', '英短银渐层', '英国长毛猫', '美国短毛猫', '德文卷毛猫', '中国狸花猫', '缅因猫'
  ];

  final Map<String, List<String>> _data = {
    'A': ['埃及猫', '阿比西尼亚猫', '奥西猫'],
    'B': ['布偶猫', '波斯猫', '伯曼猫', '巴厘猫', '波米拉猫'],
    'C': ['长毛猫示例'],
    'D': ['德文卷毛猫'],
    'E': ['中华田园猫', '英国短毛猫', '布偶猫', '英短金渐层', '英短银渐层', '英国长毛猫', '美国短毛猫', '德文卷毛猫', '中国狸花猫', '缅因猫']
  };

  final Map<String, GlobalKey> _sectionKeys = {};

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    for (final k in _data.keys) {
      _sectionKeys[k] = GlobalKey();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        centerTitle: true,
        title: const Text('宠物信息', style: TextStyle(color: Colors.black87)),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 搜索框
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            icon: Icon(Icons.search, color: Colors.black26),
                            hintText: '搜索',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      // 热门品种
                      const Text('热门品种', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _hot.map((s) => _buildChip(s)).toList(),
                      ),
                    ],
                  ),
                ),

                // 分组列表（作为整体滚动的一部分）
                Container(
                  color: Colors.white,
                  child: Column(
                    children: _data.keys.map((key) {
                      final items = _data[key]!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            key: _sectionKeys[key],
                            width: double.infinity,
                            color: const Color(0xFFF5F9FD),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Text(key, style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          ...items.map((name) => InkWell(
                                onTap: () => Navigator.pop(context, name),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    radius: 22,
                                    backgroundImage: NetworkImage('https://placekitten.com/80/80'),
                                    backgroundColor: Colors.grey[200],
                                  ),
                                  title: Text(name, style: const TextStyle(fontSize: 16)),
                                ),
                              ))
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // 右侧字母索引（视觉）
          Positioned(
            right: 4,
            top: 120,
            bottom: 20,
            child: Container(
              color: Colors.transparent,
              width: 36,
              alignment: Alignment.center,
              child: Column(
                
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: _data.keys.map((k) {
                  return Listener(
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: (_) => _scrollToSection(k),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Text(k, style: const TextStyle(color: Colors.blue, fontSize: 12)),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: const TextStyle(color: Colors.black87)),
    );
  }

  void _scrollToSection(String key) async {
    final gk = _sectionKeys[key];
    if (gk == null) return;
    final ctx = gk.currentContext;
    if (ctx == null) return;
    await Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut, alignment: 0);
  }

  Widget _buildList() {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: _data.keys.length,
      itemBuilder: (context, idx) {
        final key = _data.keys.elementAt(idx);
        final items = _data[key]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              color: const Color(0xFFF5F9FD),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(key, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            ...items.map((name) => ListTile(
                  leading: CircleAvatar(
                    radius: 22,
                    backgroundImage: NetworkImage('https://placekitten.com/80/80'),
                    backgroundColor: Colors.grey[200],
                  ),
                  title: Text(name, style: const TextStyle(fontSize: 16)),
                ))
          ],
        );
      },
    );
  }
}
