import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../services/member_api_service.dart';

class AlbumPage extends StatefulWidget {
  const AlbumPage({super.key});

  @override
  State<AlbumPage> createState() => _AlbumPageState();
}

class _AlbumPageState extends State<AlbumPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabTypes = ['image', 'video', 'daily'];

  final Map<String, List<AlbumInfo>> _albums = {
    'image': [],
    'video': [],
    'daily': [],
  };
  final Map<String, int> _currentPage = {
    'image': 1,
    'video': 1,
    'daily': 1,
  };
  final Map<String, bool> _loading = {
    'image': false,
    'video': false,
    'daily': false,
  };
  final Map<String, bool> _hasMore = {
    'image': true,
    'video': true,
    'daily': true,
  };

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _scrollController.addListener(_onScroll);
    _loadData('image', refresh: true);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  int get _currentIndex => _tabController.index;
  String get _currentType => _tabTypes[_currentIndex];

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      if (_albums[_currentType]!.isEmpty) {
        _loadData(_currentType, refresh: true);
      }
      setState(() {});
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      _loadMore();
    }
  }

  Future<void> _loadData(String type, {bool refresh = false}) async {
    if (_loading[type] == true) return;
    if (!refresh && !_hasMore[type]!) return;

    setState(() => _loading[type] = true);
    final page = refresh ? 1 : (_currentPage[type] ?? 1);

    final result = await MemberApiService.getAlbumList(
      type: type,
      pageNum: page,
      pageSize: 10,
    );

    if (!mounted) return;

    setState(() {
      _loading[type] = false;
      if (result.isSuccess) {
        if (refresh) {
          _albums[type] = result.records;
        } else {
          _albums[type]!.addAll(result.records);
        }
        _currentPage[type] = result.current;
        _hasMore[type] = result.hasMore(10);
      }
    });
  }

  Future<void> _onRefresh() async {
    await _loadData(_currentType, refresh: true);
  }

  void _loadMore() {
    _loadData(_currentType);
  }

  /// 按月份分组
  Map<String, List<AlbumInfo>> _groupByMonth(List<AlbumInfo> list) {
    final Map<String, List<AlbumInfo>> grouped = {};
    for (final item in list) {
      final timeStr = item.createTime ?? '';
      String key;
      try {
        final dt = DateTime.parse(timeStr);
        // 去掉时间部分的时间，只保留日期部分用于格式化
        key = '${dt.year}年${dt.month}月';
      } catch (_) {
        key = '未知时间';
      }
      grouped.putIfAbsent(key, () => []).add(item);
    }
    return grouped;
  }

  String _formatTimestamp(String? createTime) {
    if (createTime == null || createTime.isEmpty) return '';
    try {
      final dt = DateTime.parse(createTime);
      final month = dt.month.toString().padLeft(2, '0');
      final day = dt.day.toString().padLeft(2, '0');
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      final second = dt.second.toString().padLeft(2, '0');
      return '$month/$day $hour:$minute:$second';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_left,
              color: Color(0xFF222222), size: 34),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        centerTitle: true,
        title: const Text(
          '我的相册',
          style: TextStyle(
              color: Color(0xFF222222), fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                dividerColor: Colors.transparent,
                  indicatorColor: const Color(0xFFFF7A47),
                  labelColor: const Color(0xFF222222),
                  unselectedLabelColor: const Color(0xFF9E9E9E),
                  labelStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                  tabs: const [
                    Tab(text: '图片'),
                    Tab(text: '视频'),
                    Tab(text: '每日精彩'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildContentPage('image'),
                    _buildContentPage('video'),
                    _buildContentPage('daily'),
                  ],
                ),
              ),
            ],
          ),
      ),
    );
  }

  Widget _buildContentPage(String type) {
    final albums = _albums[type] ?? [];
    final isLoading = _loading[type] ?? false;
    final isVideo = type == 'video';

    if (albums.isEmpty && isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (albums.isEmpty) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        color: const Color(0xFFFF7A47),
        child: ListView(
          children: const [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image(image: AssetImage('assets/images/icon/home-i-none.png'), width: 80, height: 80),
                  SizedBox(height: 12),
                  Text('暂无数据',
                      style: TextStyle(color: Color(0xFF999999), fontSize: 15)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final grouped = _groupByMonth(albums);
    final months = grouped.keys.toList();

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: const Color(0xFFFF7A47),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: 40),
        itemCount: months.length + (isLoading ? 1 : 0),
        itemBuilder: (context, sectionIndex) {
          if (sectionIndex >= months.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final month = months[sectionIndex];
          final items = grouped[month]!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  month,
                  style: const TextStyle(
                      fontSize: 14, color: Color(0xFF222222)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final album = items[index];
                    return _ImageCard(
                      imageUrl: album.displayUrl,
                      isVideo: isVideo,
                      timestamp: _formatTimestamp(album.createTime),
                      sourceUrl: album.source,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

}

class _ImageCard extends StatelessWidget {
  final String imageUrl;
  final String timestamp;
  final bool isVideo;
  final String? sourceUrl;

  const _ImageCard({
    required this.imageUrl,
    required this.timestamp,
    this.isVideo = false,
    this.sourceUrl,
  });

  void _openPreview(BuildContext context) {
    if (isVideo && sourceUrl != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _VideoPlayerPage(videoUrl: sourceUrl!),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              maxScale: 4,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.broken_image,
                  color: Colors.white54,
                  size: 64,
                ),
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: progress.expectedTotalBytes != null
                          ? progress.cumulativeBytesLoaded /
                              progress.expectedTotalBytes!
                          : null,
                      color: Colors.white,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openPreview(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  Container(color: Colors.grey[200]),
            ),
            if (isVideo)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow, color: Colors.white, size: 18),
                ),
              ),
            if (timestamp.isNotEmpty)
              Positioned(
                left: 4,
                bottom: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    timestamp,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _VideoPlayerPage extends StatefulWidget {
  final String videoUrl;
  const _VideoPlayerPage({required this.videoUrl});

  @override
  State<_VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<_VideoPlayerPage> {
  late final Player _player;
  late final VideoController _controller;
  bool _initialized = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);
    _player.stream.error.listen((_) {
      if (mounted) setState(() => _error = true);
    });
    _init();
  }

  Future<void> _init() async {
    try {
      await _player.open(Media(widget.videoUrl));
      if (mounted) {
        setState(() => _initialized = true);
      }
    } catch (e) {
      debugPrint('[Video] init error: $e');
      if (mounted) setState(() => _error = true);
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.white54, size: 48),
            SizedBox(height: 12),
            Text('视频加载失败', style: TextStyle(color: Colors.white54, fontSize: 15)),
          ],
        ),
      );
    }
    if (!_initialized) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    return Video(
      controller: _controller,
      controls: (state) => MaterialVideoControls(state),
    );
  }
}
