import 'package:flutter/material.dart';
import '../../services/api_client.dart';

class DeviceNewsPage extends StatefulWidget {
  final String type; // 'pet' | 'device' | 'announcement'
  const DeviceNewsPage({super.key, required this.type});

  @override
  State<DeviceNewsPage> createState() => _DeviceNewsPageState();
}

class _DeviceNewsPageState extends State<DeviceNewsPage> {
  final List<Map<String, dynamic>> _messages = [];
  final ScrollController _scrollCtrl = ScrollController();
  int _page = 1;
  bool _hasMore = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 50) {
      _loadMessages();
    }
  }

  Future<void> _loadMessages() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);
    try {
      final res = await ApiClient.instance.get(
        '/app/msg/list',
        queryParams: {'page': _page, 'pageSize': 20, 'type': widget.type},
      );
      if (res.isSuccess) {
        final data = res.data;
        List records = [];
        if (data is Map) {
          records = (data['records'] ?? data['list'] ?? []) as List;
        } else if (data is List) {
          records = data;
        }
        setState(() {
          _messages.addAll(records.map((e) => Map<String, dynamic>.from(e)));
          _hasMore = records.length >= 20;
          _page++;
        });
      }
    } catch (e) {
      // ignore
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _readAll() async {
    try {
      await ApiClient.instance.post('/app/msg/read/all', body: {'type': widget.type});
      setState(() {
        for (final m in _messages) {
          m['isRead'] = 1;
        }
      });
    } catch (e) {
      // ignore
    }
  }

  Future<void> _readOne(int index) async {
    final msg = _messages[index];
    if (msg['isRead'] == 1) return;
    try {
      await ApiClient.instance.post('/app/msg/read/${msg['id']}');
      setState(() => msg['isRead'] = 1);
    } catch (e) {
      // ignore
    }
  }

  String _formatTime(String? time) {
    if (time == null || time.isEmpty) return '';
    try {
      final dt = DateTime.parse(time);
      final now = DateTime.now();
      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
      return '${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return time;
    }
  }

  String get _title {
    switch (widget.type) {
      case 'pet': return '宠物消息';
      case 'notice': return '公告';
      default: return '设备消息';
    }
  }

  String get _emptyText {
    switch (widget.type) {
      case 'pet': return '暂无宠物消息';
      case 'notice': return '暂无公告';
      default: return '暂无设备消息';
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = _messages.any((m) => m['isRead'] != 1 && m['isRead'] != true);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_left, color: Colors.black87, size: 34),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        centerTitle: true,
        title: Text(_title, style: const TextStyle(color: Colors.black87, fontSize: 17, fontWeight: FontWeight.w500)),
        actions: [
          if (hasUnread)
            TextButton(
              onPressed: _readAll,
              child: const Text('全部已读', style: TextStyle(color: Color(0xFFFF7A47), fontSize: 14)),
            ),
        ],
      ),
      body: Container(
        color: const Color(0xFFF2F2F2),
        child: _messages.isEmpty && !_loading
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset('assets/images/icon/home-i-none.png', width: 120, height: 120),
                          const SizedBox(height: 16),
                          Text(_emptyText, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: _messages.length + (_loading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= _messages.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                    );
                  }
                  final msg = _messages[index];
                  final isRead = msg['isRead'] == 1 || msg['isRead'] == true;
                  final title = msg['title'] ?? msg['deviceName'] ?? '设备消息';
                  final content = msg['content'] ?? msg['message'] ?? '';
                  final time = _formatTime(msg['createTime'] ?? msg['sendTime'] ?? msg['time']?.toString() ?? '');

                  return GestureDetector(
                    onTap: () => _readOne(index),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 设备图标
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isRead ? const Color(0xFFF5F5F5) : const Color(0xFFFF7A47).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.devices_other,
                              color: isRead ? Colors.grey : const Color(0xFFFF7A47),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // 内容区域
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '【$title】',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: isRead ? FontWeight.w400 : FontWeight.w600,
                                    color: isRead ? const Color(0xFF999999) : const Color(0xFF222222),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  content,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 13, color: isRead ? const Color(0xFFBBBBBB) : const Color(0xFF666666), height: 1.4),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(time, style: const TextStyle(fontSize: 12, color: Color(0xFFBBBBBB))),
                                    const Text(
                                      '查看',
                                      style: TextStyle(fontSize: 13, color: Color(0xFFFF7A47), fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
