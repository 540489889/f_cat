import 'package:flutter/material.dart';
import '../../models/device_info.dart';
import '../../models/provision_status.dart';

/// 配网结果页面
///
/// 展示配网最终结果：
/// - 成功：显示绿色对勾、设备 IP、设备信息，提供"返回首页"按钮
/// - 失败：显示红色错误图标、失败原因、设备信息，提供"重新配网"和"返回首页"按钮
///
/// 该页面通过 pushReplacement 进入，无法通过返回键回到配网页面。
/// 设备绑定已在配网点击时触发，此处不再绑定。
class ResultPage extends StatelessWidget {
  /// 配网状态结果（包含类型、SN、IP、失败原因等）
  final ProvisionStatus status;

  /// 设备信息（从 FFF1 读取，可能为 null）
  final DeviceInfo? deviceInfo;

  /// 绑定设备失败的错误信息（配网成功后展示警告）
  final String? bindErrorMessage;

  const ResultPage({
    super.key,
    required this.status,
    this.deviceInfo,
    this.bindErrorMessage,
  });

  bool get _isSuccess => status.type == ProvisionStatusType.wifiConnected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSuccess ? '配网成功' : '配网失败'),
        backgroundColor: _isSuccess ? Colors.green.shade600 : Colors.red.shade600,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 大图标
              Icon(
                _isSuccess ? Icons.check_circle : Icons.error,
                size: 96,
                color: _isSuccess ? Colors.green : Colors.red,
              ),
              const SizedBox(height: 24),

              // 主标题
              Text(
                _isSuccess ? '设备配网成功！' : '配网失败',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _isSuccess ? Colors.green.shade800 : Colors.red.shade800,
                    ),
              ),
              const SizedBox(height: 12),

              // 描述文字
              if (_isSuccess) ...[
                Text(
                  '设备已连接到 WiFi，即将开始正常工作',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                // 绑定失败警告
                if (bindErrorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('设备绑定失败',
                                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.orange.shade900, fontSize: 14)),
                              const SizedBox(height: 4),
                              Text(bindErrorMessage!,
                                  style: TextStyle(fontSize: 13, color: Colors.orange.shade800)),
                              const SizedBox(height: 4),
                              Text('设备已联网，但未绑定到家庭。请在设备列表中手动绑定。',
                                  style: TextStyle(fontSize: 12, color: Colors.orange.shade700)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Text(
                    status.failReasonText,
                    style: TextStyle(fontSize: 14, color: Colors.orange.shade900, height: 1.5),
                    textAlign: TextAlign.left,
                  ),
                ),
              ],
              const SizedBox(height: 32),

              // 详细信息卡片
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('详细信息',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      const Divider(height: 20),
                      if (deviceInfo != null) ...[
                        _infoRow(context, '设备 SN', deviceInfo!.sn),
                        _infoRow(context, '型号', deviceInfo!.model == 'waterer' ? '饮水机' : deviceInfo!.model),
                        _infoRow(context, '固件版本', deviceInfo!.fwVer),
                      ],
                      if (_isSuccess) ...[
                        _infoRow(context, 'IP 地址', status.ip),
                      ] else if (status.reason != null) ...[
                        _infoRow(context, '错误码', status.reason!),
                        const SizedBox(height: 8),
                        Text(
                          '设备支持 2.4GHz WiFi (WPA2-PSK)\n'
                          '请确保使用正确的网络和密码',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // 操作按钮
              if (_isSuccess)
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                  icon: const Icon(Icons.home),
                  label: const Text('返回首页'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                )
              else ...[
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('重新配网'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                  child: const Text('返回首页'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 构建信息行（label: value 左右布局）
  Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          Flexible(
            child: Text(value,
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}
