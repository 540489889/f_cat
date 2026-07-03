import 'package:flutter/material.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'details.dart';
import '../../services/order_api_service.dart';
import '../../shared/throttle.dart';

class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key});

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> {
  List<OrderItem> _orders = [];
  bool _isLoading = true;
  String? _errorMsg;
  int _statusFilter = 0; // 0=全部
  int _currentPage = 1;
  bool _hasMore = true;
  late EasyRefreshController _easyController;
  final _cancelThrottle = ActionThrottle();
  final _deleteThrottle = ActionThrottle();

  @override
  void initState() {
    super.initState();
    _easyController = EasyRefreshController(
      controlFinishRefresh: true,
      controlFinishLoad: true,
    );
    _loadOrders();
  }

  @override
  void dispose() {
    _easyController.dispose();
    super.dispose();
  }

  Future<void> _cancelOrder(int index) async {
    await _cancelThrottle.run(() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('取消订单'),
        content: const Text('确定要取消该订单吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('暂不', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确定', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final order = _orders[index];
    final result = await OrderApiService.cancelOrder(orderId: order.id);
    if (!mounted) return;
    if (result.isSuccess) {
      _loadOrders(refresh: true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    }
    });
  }

  Future<void> _deleteOrder(int index) async {
    await _deleteThrottle.run(() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('删除订单'),
        content: const Text('确定要删除该订单吗？删除后不可恢复。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消', style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('删除', style: TextStyle(color: Color(0xFFE53935)))),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final order = _orders[index];
    final result = await OrderApiService.deleteOrder(orderId: order.id);
    if (!mounted) return;
    if (result.isSuccess) {
      _loadOrders(refresh: true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    }
    });
  }

  Future<void> _loadOrders({bool refresh = false}) async {
    final page = refresh ? 1 : _currentPage;
    if (!refresh && !_hasMore) return;

    if (refresh) {
      setState(() {
        _isLoading = true;
        _errorMsg = null;
      });
    }
    final result = await OrderApiService.getOrderList(
      pageNum: page,
      pageSize: 10,
      status: _statusFilter == 0 ? null : _statusFilter - 1,
    );
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result.isSuccess) {
        if (refresh) {
          _orders = result.orders;
          _currentPage = 2;
          _hasMore = result.orders.length >= 10;
        } else {
          final existedIds = _orders.map((e) => e.id).toSet();
          final newItems = result.orders.where((e) => !existedIds.contains(e.id)).toList();
          _orders.addAll(newItems);
          _currentPage = page + 1;
          _hasMore = newItems.isNotEmpty && result.orders.length >= 10;
        }
      } else {
        if (_orders.isEmpty) _errorMsg = result.message;
      }
    });
  }

  Future<void> _onRefresh() async {
    await _loadOrders(refresh: true);
    _easyController.finishRefresh();
    _easyController.resetFooter();
  }

  Future<void> _onLoad() async {
    if (!_hasMore) {
      _easyController.finishLoad(IndicatorResult.noMore);
      return;
    }
    await _loadOrders();
    _easyController.finishLoad(_hasMore ? IndicatorResult.success : IndicatorResult.noMore);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_left, color: Colors.black87, size: 34),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        centerTitle: true,
        title: const Text('我的订单', style: TextStyle(color: Colors.black87, fontSize: 17, fontWeight: FontWeight.w500)),
      ),
      body: Column(
        children: [
          // Status tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: ['全部', '待付款', '已付款', '已发货', '已完成'].asMap().entries.map((e) {
                final i = e.key;
                final label = e.value;
                final isActive = _statusFilter == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (_statusFilter != i) {
                        setState(() => _statusFilter = i);
                        _loadOrders(refresh: true);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                          color: isActive ? const Color(0xFFFF7A47) : const Color(0xFF666666),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 0.5, color: Color(0xFFEEEEEE)),
          // Order list
          Expanded(
            child: _isLoading && _orders.isEmpty
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF7A47)))
                : _errorMsg != null && _orders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_errorMsg!, style: const TextStyle(color: Color(0xFF999999))),
                            const SizedBox(height: 12),
                            TextButton(onPressed: () => _loadOrders(refresh: true), child: const Text('点此重试')),
                          ],
                        ),
                      )
                    : _orders.isEmpty
                        ? EasyRefresh(
                            controller: _easyController,
                            header: ClassicHeader(
                              clamping: false,
                              backgroundColor: const Color(0xFFF5F5F5),
                              mainAxisAlignment: MainAxisAlignment.center,
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
                            onRefresh: _onRefresh,
                            child: ListView(
                              children: const [
                                SizedBox(height: 80),
                                Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.inbox_outlined, size: 64, color: Color(0xFFDDDDDD)),
                                      SizedBox(height: 12),
                                      Text('暂无订单', style: TextStyle(color: Color(0xFF999999), fontSize: 15)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : EasyRefresh(
                            controller: _easyController,
                            header: ClassicHeader(
                              clamping: false,
                              backgroundColor: const Color(0xFFF5F5F5),
                              mainAxisAlignment: MainAxisAlignment.center,
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
                            footer: ClassicFooter(
                              clamping: false,
                              backgroundColor: const Color(0xFFF5F5F5),
                              mainAxisAlignment: MainAxisAlignment.start,
                              showMessage: true,
                              showText: true,
                              dragText: '上拉加载',
                              armedText: '释放加载',
                              readyText: '加载中...',
                              processingText: '加载中...',
                              processedText: '加载成功',
                              noMoreText: '没有更多了',
                              failedText: '加载失败',
                              messageText: '最后更新于 %T',
                            ),
                            onRefresh: _onRefresh,
                            onLoad: _onLoad,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: _orders.length,
                              itemBuilder: (_, i) => _OrderCard(
                                order: _orders[i],
                                onCancel: () => _cancelOrder(i),
                                onDelete: () => _deleteOrder(i),
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderItem order;
  final VoidCallback? onCancel;
  final VoidCallback? onDelete;

  const _OrderCard({required this.order, this.onCancel, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: order no + status
          Row(
            children: [
              Text('订单号：${order.sn}', style: const TextStyle(fontSize: 13, color: Color(0xFF666666))),
              const Spacer(),
              Text(order.statusLabel, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: order.statusColor)),
            ],
          ),
          const Divider(height: 24, color: Color(0xFFEEEEEE)),
          // Body: image + title + model + subtitle + price
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (order.image != null && order.image!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(order.image!, width: 72, height: 72, fit: BoxFit.cover, errorBuilder: (_, _, _) => Container(width: 72, height: 72, color: const Color(0xFFF0F0F0))),
                ),
              if (order.image != null && order.image!.isNotEmpty) const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.title ?? '宠物用品', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF222222)), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    if (order.model != null && order.model!.isNotEmpty)
                      Text('型号：${order.model}', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    if (order.subtitle != null && order.subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(color: const Color(0xFFFFE6E6), borderRadius: BorderRadius.circular(3)),
                        child: Text(order.subtitle!, style: const TextStyle(fontSize: 10, color: Color(0xFFFF2D2D))),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('共${order.quantity}件', style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
              const Spacer(),
              Text('合计：', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              Text('¥${order.totalPrice.toStringAsFixed(0)}.00', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF222222))),
            ],
          ),
          const SizedBox(height: 12),
          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (order.status == 0) ...[
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF999999),
                    side: const BorderSide(color: Color(0xFFDDDDDD)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: onCancel,
                  child: const Text('取消订单', style: TextStyle(fontSize: 13)),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF4D26),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => ProductDetailsPage(id: order.deviceId)),
                    );
                  },
                  child: const Text('去支付', style: TextStyle(fontSize: 12)),
                ),
              ],
              if (order.status == -1)
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE53935),
                    side: const BorderSide(color: Color(0xFFE53935)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: onDelete,
                  child: const Text('删除订单', style: TextStyle(fontSize: 13)),
                ),
              if (order.status == 2)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7A47),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {},
                  child: const Text('确认收货', style: TextStyle(fontSize: 12)),
                ),
              if (order.status == 1 || order.status == 3)
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFF7A47),
                    side: const BorderSide(color: Color(0xFFFF7A47)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => ProductDetailsPage(id: order.deviceId)),
                    );
                  },
                  child: const Text('再次购买', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
