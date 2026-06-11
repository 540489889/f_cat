import 'package:flutter/material.dart';
import '../../models/home_device.dart';
import '../../services/device_service.dart';
import '../../services/home_state.dart';

/// 设备详情页
class DeviceDetailPage extends StatefulWidget {
  final int homeDeviceId;
  final String? initialTitle;

  const DeviceDetailPage({
    super.key,
    required this.homeDeviceId,
    this.initialTitle,
  });

  @override
  State<DeviceDetailPage> createState() => _DeviceDetailPageState();
}

class _DeviceDetailPageState extends State<DeviceDetailPage> {
  HomeDevice? _device;
  bool _loading = true;
  String? _error;
  List<DeviceDataPoint> _latestData = [];
  bool _controlling = false;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await DeviceService.getDeviceDetail(
      id: widget.homeDeviceId,
    );

    if (!mounted) return;

    setState(() {
      _loading = false;
      if (result.isSuccess) {
        _device = result.device;
      } else {
        _error = result.message;
      }
    });

    // 加载最新数据
    if (result.isSuccess && result.device?.hasSn == true) {
      _loadLatestData();
    }
  }

  Future<void> _loadLatestData() async {
    final result = await DeviceService.getLatestData(
      homeDeviceId: widget.homeDeviceId,
    );
    if (!mounted) return;
    if (result.isSuccess) {
      setState(() => _latestData = result.data);
    }
  }

  Future<void> _sendCommand(String command,
      {Map<String, dynamic>? params}) async {
    setState(() => _controlling = true);

    final result = await DeviceService.sendCommand(
      homeDeviceId: widget.homeDeviceId,
      command: command,
      params: params,
    );

    if (!mounted) return;

    setState(() => _controlling = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.isSuccess ? '指令已下发' : result.message),
        backgroundColor: result.isSuccess ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _device?.displayName ?? widget.initialTitle ?? '设备详情',
          style: const TextStyle(color: Colors.black87),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _device == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDetail,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }
    if (_device == null) {
      return const Center(child: Text('设备信息为空'));
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _loadDetail();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(),
            const SizedBox(height: 16),
            if (_device!.hasSn) _buildStatusCard(),
            if (_device!.hasSn) const SizedBox(height: 16),
            if (_device!.hasSn) _buildControlCard(),
            if (_device!.hasSn && _latestData.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildDataCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    final d = _device!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // 设备图片
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: d.deviceImglogo?.isNotEmpty == true
                      ? Image.network(
                          d.deviceImglogo!,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[200],
                            child: const Icon(Icons.devices,
                                size: 40, color: Colors.grey),
                          ),
                        )
                      : Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[200],
                          child: const Icon(Icons.devices,
                              size: 40, color: Colors.grey),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d.displayName,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      if (d.deviceTitle != null &&
                          d.deviceTitle != d.alias)
                        Text(
                          d.deviceTitle!,
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey[600]),
                        ),
                      const SizedBox(height: 8),
                      _buildInfoRow('型号', d.deviceModel ?? '-'),
                      _buildInfoRow('房间', d.room ?? '-'),
                      _buildInfoRow('SN', d.sn ?? '未绑定'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Text(label,
                style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 13),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final d = _device!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('设备状态',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: d.isOnline ? const Color(0xFF4CAF50) : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  d.isOnline ? '在线' : '离线',
                  style: TextStyle(
                    fontSize: 14,
                    color: d.isOnline ? const Color(0xFF4CAF50) : Colors.grey,
                  ),
                ),
                const Spacer(),
                if (d.iotFirmwareVer != null)
                  Text(
                    '固件 v${d.iotFirmwareVer}',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
              ],
            ),
            if (d.iotLastOnline != null) ...[
              const SizedBox(height: 8),
              Text(
                '最后在线：${d.iotLastOnline}',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildControlCard() {
    final actions = HomeState.getActionsForType(_device!.deviceType);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('设备控制',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlButton(
                  label: actions.actionLabel,
                  icon: Icons.play_circle_fill,
                  onPressed:
                      _device!.isOnline ? () => _sendCommand(actions.actionCommand,
                          params: actions.actionParams) : null,
                  loading: _controlling,
                ),
                _buildControlButton(
                  label: '详情',
                  icon: Icons.info_outline,
                  onPressed: () => _sendCommand('status'),
                  loading: _controlling,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required String label,
    required IconData icon,
    VoidCallback? onPressed,
    bool loading = false,
  }) {
    return Column(
      children: [
        SizedBox(
          width: 64,
          height: 64,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF8A65),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              padding: EdgeInsets.zero,
            ),
            child: loading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Icon(icon, color: Colors.white, size: 28),
          ),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.black87)),
      ],
    );
  }

  Widget _buildDataCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('最新数据',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ..._latestData.map((dp) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 100,
                        child: Text(dp.metric,
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey[600])),
                      ),
                      Text(dp.value,
                          style: const TextStyle(fontSize: 14)),
                      const Spacer(),
                      Text(dp.timestamp,
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[400])),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
