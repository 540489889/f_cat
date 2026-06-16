import 'package:flutter/material.dart';
import 'package:city_pickers/city_pickers.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class AddressEditPage extends StatefulWidget {
  const AddressEditPage({super.key});

  @override
  State<AddressEditPage> createState() => _AddressEditPageState();
}

class _AddressEditPageState extends State<AddressEditPage> {
  final TextEditingController _regionController = TextEditingController();
  final TextEditingController _detailController = TextEditingController();
  final TextEditingController _doorController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isDefault = false;
  bool _isLocating = false;
  double _centerLat = 29.5320;
  double _centerLng = 106.5516;
  final MapController _mapController = MapController();

  @override
  void dispose() {
    _regionController.dispose();
    _detailController.dispose();
    _doorController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // ---------- 地区选择 (使用 city_pickers) ----------
  Future<void> _showRegionPicker() async {
    final result = await CityPickers.showCityPicker(
      context: context,
      showType: ShowType.pca, // 省/市/区三级
    );
    if (result != null) {
      _regionController.text = '${result.provinceName} ${result.cityName} ${result.areaName}';
    }
  }

  // ---------- 定位 ----------
  Future<void> _locateCurrentPosition() async {
    setState(() => _isLocating = true);
    // 模拟获取GPS坐标（实际项目接入定位SDK）
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() {
      _isLocating = false;
      _centerLat = 29.5320;
      _centerLng = 106.5516;
      _mapController.move(LatLng(_centerLat, _centerLng), 16);
      _regionController.text = '重庆市 重庆市 南岸区';
      if (_detailController.text.isEmpty) {
        _detailController.text = '光明路18号东原·翡翠明珠';
      }
    });
    _showToast('定位成功');
  }

  // ---------- 保存 ----------
  void _saveAddress() {
    final region = _regionController.text.trim();
    final detail = _detailController.text.trim();
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (region.isEmpty) {
      _showToast('请选择所在地区');
      return;
    }
    if (detail.isEmpty) {
      _showToast('请输入详细地址');
      return;
    }
    if (name.isEmpty) {
      _showToast('请输入收货人姓名');
      return;
    }
    if (phone.isEmpty) {
      _showToast('请输入手机号码');
      return;
    }
    if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(phone)) {
      _showToast('请输入正确的手机号码');
      return;
    }

    Navigator.of(context).pop({
      'region': region,
      'detail': detail,
      'door': _doorController.text.trim(),
      'name': name,
      'phone': phone,
      'isDefault': _isDefault,
    });
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 100, left: 40, right: 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
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
        title: const Text('新增收货地址', style: TextStyle(color: Colors.black87, fontSize: 17, fontWeight: FontWeight.w500)),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Map
                  Container(
                    height: 200,
                    width: double.infinity,
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        children: [
                          FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: LatLng(_centerLat, _centerLng),
                              initialZoom: 16,
                              interactionOptions: const InteractionOptions(
                                flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                              ),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://webrd01.is.autonavi.com/appmaptile?lang=zh_cn&size=1&scale=1&style=8&x={x}&y={y}&z={z}',
                                userAgentPackageName: 'com.example.app',
                                maxZoom: 18,
                              ),
                              // Center crosshair
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: LatLng(_centerLat, _centerLng),
                                    width: 36,
                                    height: 36,
                                    child: const Icon(Icons.location_on, color: Color(0xFFFF4D26), size: 36),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          // Loading overlay
                          if (_isLocating)
                            Container(
                              color: Colors.black12,
                              child: const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 32,
                                      height: 32,
                                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFFFF8A65)),
                                    ),
                                    SizedBox(height: 8),
                                    Text('定位中...', style: TextStyle(fontSize: 13, color: Colors.white)),
                                  ],
                                ),
                              ),
                            ),
                          // Bottom bar
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _locateCurrentPosition,
                              child: Container(
                                height: 40,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.gps_fixed, size: 16, color: Color(0xFFFF8A65)),
                                    SizedBox(width: 6),
                                    Text('获取当前定位地址', style: TextStyle(fontSize: 13, color: Color(0xFFFF8A65))),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Form section
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 收货信息 title
                        const Text('收货信息', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF222222))),
                        const SizedBox(height: 16),
                        // 所在地区
                        _buildFieldRow(
                          label: '所在地区',
                          hint: '请选择省/市/区',
                          controller: _regionController,
                          suffix: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                          onTap: _showRegionPicker,
                        ),
                        const Divider(height: 0.5, color: Color(0xFFEEEEEE)),
                        // 详细地址
                        _buildFieldRow(
                          label: '详细地址',
                          hint: '请输入详细地址',
                          controller: _detailController,
                          suffix: GestureDetector(
                            onTap: _locateCurrentPosition,
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(Icons.gps_fixed, size: 18, color: const Color(0xFFFF8A65).withValues(alpha: 0.6)),
                            ),
                          ),
                        ),
                        const Divider(height: 0.5, color: Color(0xFFEEEEEE)),
                        // 门牌号
                        _buildFieldRow(
                          label: '门牌号',
                          hint: '街道、门牌号等',
                          controller: _doorController,
                        ),
                        const Divider(height: 0.5, color: Color(0xFFEEEEEE)),
                        // 收货人
                        _buildFieldRow(
                          label: '收货人',
                          hint: '请输入收货人姓名',
                          controller: _nameController,
                        ),
                        const Divider(height: 0.5, color: Color(0xFFEEEEEE)),
                        // 手机号码
                        _buildFieldRow(
                          label: '手机号码',
                          hint: '请输入收货人手机号码',
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 设为默认收货地址
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Text('设为默认收货地址', style: TextStyle(fontSize: 14, color: Color(0xFF222222))),
                        const Spacer(),
                        SizedBox(
                          height: 24,
                          child: Switch(
                            value: _isDefault,
                            onChanged: (v) => setState(() => _isDefault = v),
                            activeThumbColor: const Color(0xFFFF8A65),
                            activeTrackColor: const Color(0xFFFF8A65).withValues(alpha: 0.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bottom button
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 34),
            color: Colors.white,
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF4D26),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                  ),
                  onPressed: _saveAddress,
                  child: const Text('保存并使用', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldRow({
    required String label,
    required String hint,
    required TextEditingController controller,
    Widget? suffix,
    VoidCallback? onTap,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 72,
              child: Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF333333))),
            ),
            Expanded(
              child: IgnorePointer(
                ignoring: onTap != null,
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  readOnly: onTap != null,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF222222)),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    hintText: hint,
                    hintStyle: const TextStyle(fontSize: 14, color: Color(0xFFCCCCCC)),
                  ),
                ),
              ),
            ),
            ?suffix,
          ],
        ),
      ),
    );
  }
}
