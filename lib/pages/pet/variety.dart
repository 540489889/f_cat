import 'package:flutter/material.dart';
import '../../services/cates_api_service.dart';

class VarietyPage extends StatefulWidget {
  final String mark; // 'cat' 或 'dog'

  const VarietyPage({super.key, required this.mark});

  @override
  State<VarietyPage> createState() => _VarietyPageState();
}

class _VarietyPageState extends State<VarietyPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
  String _searchQuery = '';
  List<BreedItem> _hot = [];
  List<BreedItem> _allBreeds = [];
  Map<String, List<BreedItem>> _data = {};
  Map<String, List<BreedItem>> _filteredData = {};

  final Map<String, GlobalKey> _sectionKeys = {};
  List<String> get _sortedKeys => _filteredData.keys.toList()..sort();

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearch);
    _loadCates();
  }

  void _onSearch() {
    final q = _searchController.text.trim();
    if (q == _searchQuery) return;
    _searchQuery = q;
    _applyFilter();
  }

  void _applyFilter() {
    setState(() {
      _sectionKeys.clear();
      if (_searchQuery.isEmpty) {
        _filteredData = Map.from(_data);
      } else {
        _filteredData = {};
        for (final breed in _allBreeds) {
          if (breed.title.toLowerCase().contains(_searchQuery.toLowerCase())) {
            final letter = breed.title[0].toUpperCase();
            _filteredData.putIfAbsent(letter, () => []).add(breed);
          }
        }
      }
      for (final k in _filteredData.keys) {
        _sectionKeys[k] = GlobalKey();
      }
    });
  }

  Future<void> _loadCates() async {
    final result = await CatesApiService.getCatesTree(mark: widget.mark);
    if (!mounted) return;
    if (result.isSuccess && result.data != null) {
      final map = result.data!;
      final allBreeds = <BreedItem>[];
      final tempData = <String, List<BreedItem>>{};
      for (final entry in map.entries) {
        final letter = entry.key;
        final list = (entry.value as List<dynamic>?)
            ?.map((e) => BreedItem.fromJson(e as Map<String, dynamic>))
            .toList() ?? [];
        tempData[letter] = list;
        allBreeds.addAll(list);
      }
      // 热门品种取前 10 个
      setState(() {
        _isLoading = false;
        _allBreeds = allBreeds;
        _data = tempData;
        _hot = allBreeds.take(10).toList();
        _filteredData = Map.from(tempData);
        for (final k in _filteredData.keys) {
          _sectionKeys[k] = GlobalKey();
        }
      });
    } else {
      setState(() => _isLoading = false);
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
          icon: const Icon(Icons.keyboard_arrow_left, color: Colors.black87, size: 34),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        centerTitle: true,
        title: const Text('宠物信息', style: TextStyle(fontSize: 20,color: Colors.black87)),
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF8A65)))
        : Stack(
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
                        child: Row(children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: const InputDecoration(
                                icon: Icon(Icons.search, color: Colors.black26),
                                hintText: '搜索品种',
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          if (_searchQuery.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _searchController.clear();
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(8),
                                child: Icon(Icons.close, color: Colors.grey, size: 18),
                              ),
                            ),
                        ]),
                      ),
                      const SizedBox(height: 18),
                      // 搜索建议 / 热门品种
                      if (_searchQuery.isNotEmpty) ...[
                        const Text('搜索结果', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('找到 ${_allBreeds.where((b) => b.title.toLowerCase().contains(_searchQuery.toLowerCase())).length} 个品种', style: const TextStyle(color: Colors.black45, fontSize: 13)),
                      ] else ...[
                        const Text('热门品种', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _hot.map((b) => _buildChip(b.title, onTap: () => Navigator.pop(context, b.title))).toList(),
                        ),
                      ],
                    ],
                  ),
                ),

                // 分组列表（作为整体滚动的一部分）
                Container(
                  color: Colors.white,
                  child: Column(
                    children: _sortedKeys.map((key) {
                      final items = _filteredData[key]!;
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
                          ...items.map((item) => InkWell(
                                onTap: () => Navigator.pop(context, item.title),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    radius: 22,
                                    backgroundImage: NetworkImage(item.icon),
                                    backgroundColor: Colors.grey[200],
                                    onBackgroundImageError: (_, _) {},
                                  ),
                                  title: Text(item.title, style: const TextStyle(fontSize: 16)),
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
                children: _sortedKeys.map((k) {
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

  Widget _buildChip(String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFE8ECF0),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: const TextStyle(color: Color(0xFF333333), fontSize: 13)),
      ),
    );
  }

  void _scrollToSection(String key) async {
    final gk = _sectionKeys[key];
    if (gk == null) return;
    final ctx = gk.currentContext;
    if (ctx == null) return;
    await Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut, alignment: 0);
  }
}

/// 品种数据模型
class BreedItem {
  final int id;
  final String title;
  final String icon;

  BreedItem({required this.id, required this.title, required this.icon});

  factory BreedItem.fromJson(Map<String, dynamic> json) {
    return BreedItem(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
    );
  }
}
