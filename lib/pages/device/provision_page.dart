import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import '../../models/device_info.dart';
import '../../models/provision_data.dart';
import '../../models/provision_status.dart';
import '../../services/ble_provisioning_service.dart';
import '../../services/device_service.dart';
import '../../services/home_state.dart';
import 'result_page.dart';
import 'wifi_picker_dialog.dart';

/// 配网页面阶段枚举
///
/// 页面根据不同阶段展示不同的 UI：
/// - [connecting] / [readingInfo] / [sending]：显示加载动画
/// - [inputWifi]：显示 WiFi 输入表单
/// - [waitingResult]：显示等待进度
enum _Stage {
  connecting,    /// 正在连接设备 + MTU 协商
  readingInfo,   /// 正在读取设备信息 (FFF1)
  inputWifi,     /// 等待用户输入 WiFi 信息
  sending,       /// 正在发送凭证 (FFF2)
  waitingResult, /// 等待配网结果 (监听 FFF3 Notify)
}

/// 配网页面 - BLE 配网全流程交互
///
/// 核心流程：
/// 1. 连接设备 + MTU 协商 (512)
/// 2. 发现 GATT 服务 + 订阅 CCCD
/// 3. 读取设备信息 (FFF1)
/// 4. 展示 WiFi 输入表单
/// 5. 写入 WiFi 凭证 (FFF2)
/// 6. 监听配网结果 (FFF3 Notify)
/// 7. 跳转到结果页面
class ProvisionPage extends StatefulWidget {
  /// 扫描结果，包含目标 BLE 设备引用
  final ScanResult scanResult;
  const ProvisionPage({super.key, required this.scanResult});

  @override
  State<ProvisionPage> createState() => _ProvisionPageState();
}

class _ProvisionPageState extends State<ProvisionPage> {
  /// BLE 配网服务实例
  final _service = BleProvisioningService();

  /// WiFi 名称输入控制器
  final _ssidCtrl = TextEditingController();

  /// WiFi 密码输入控制器
  final _passwordCtrl = TextEditingController();

  /// 当前配网阶段
  _Stage _stage = _Stage.connecting;

  /// 当前状态提示文字
  String _statusText = '正在连接设备...';

  /// 从设备读取的设备信息（可能为 null）
  DeviceInfo? _deviceInfo;

  /// 错误提示信息
  String? _errorMsg;

  /// 绑定设备失败的错误信息（配网成功后展示警告）
  String? _bindErrorMessage;

  /// 密码是否隐藏显示
  bool _obscurePassword = true;

  /// 配网状态通知订阅（FFF3 Notify）
  StreamSubscription<ProvisionStatus>? _statusSub;

  /// BLE 连接状态订阅（检测意外断开）
  StreamSubscription<BluetoothConnectionState>? _connSub;

  @override
  void initState() {
    super.initState();
    // 页面加载后立即启动 BLE 连接和初始化流程
    _connectAndSetup();
  }

  @override
  void dispose() {
    // 页面销毁时清理所有资源：取消订阅、释放控制器、断开 BLE
    _statusSub?.cancel();
    _connSub?.cancel();
    _ssidCtrl.dispose();
    _passwordCtrl.dispose();
    _service.disconnect();
    super.dispose();
  }

  /// BLE 连接和设备初始化流程
  ///
  /// 按顺序执行：
  /// ① 连接设备 + MTU 协商 (512)
  /// ② 发现 GATT 服务，缓存 Characteristic 引用
  /// ③ 订阅 FFF3 CCCD 通知（必须在写入凭证前完成）
  /// ④ 读取 FFF1 设备信息
  ///
  /// 全部完成后切换到 WiFi 输入表单阶段。
  Future<void> _connectAndSetup() async {
    try {
      // ① 连接设备 + MTU 协商
      _updateStage(_Stage.connecting, '正在连接设备...');
      await _service.connect(widget.scanResult.device);

      // 监听 BLE 连接状态变化
      // 配网成功后设备会主动关闭 BLE 断开连接，这是正常行为；
      // 其他阶段意外断开则报错。
      _connSub = _service.connectionStateStream.listen((state) {
        print('[配网] BLE 连接状态变化: $state, 当前阶段: $_stage');
        if (state == BluetoothConnectionState.disconnected) {
          if (_stage == _Stage.waitingResult) {
            // 配网等待阶段设备主动断开 BLE —— 可能已配网成功
            print('[配网] 设备主动断连,可能已完成配网');
            // 取消超时计时器
            // 等待 statusStream 处理结果,如果没有收到则显示提示
          } else if (_stage != _Stage.sending) {
            // 非发送阶段意外断开
            _setError('BLE 连接意外断开，请重试');
          }
        }
      });

      // ② 发现 GATT 服务，找到 FFF1/FFF2/FFF3 特征
      _updateStage(_Stage.connecting, '正在发现服务...');
      await _service.discoverServices();

      // ③ 订阅 FFF3 Notify (CCCD 0x2902 = 0x0001)
      // 必须在写入凭证前完成，否则收不到状态通知
      await _service.subscribeStatusNotify();

      // ④ 读取 FFF1 设备信息（SN、型号、固件版本）
      _updateStage(_Stage.readingInfo, '正在读取设备信息...');
      final info = await _service.readDeviceInfo();

      if (mounted) {
        setState(() {
          _deviceInfo = info;
          _stage = _Stage.inputWifi;       // 切换到 WiFi 输入阶段
          _statusText = '请输入 WiFi 信息';
        });
      }

      // 设备信息读取失败时，在 WiFi 表单中显示提示
      if (info == null && mounted) {
        setState(() {
          _errorMsg = '无法读取设备详细信息，配网完成后将自动同步';
        });
      }
    } catch (e) {
      print('[配网] 连接失败: $e');
      _setError('连接失败: $e');
    }
  }

  /// 更新页面阶段和状态提示文字
  void _updateStage(_Stage stage, String text) {
    if (mounted) {
      setState(() {
        _stage = stage;
        _statusText = text;
      });
    }
  }

  /// 设置错误信息并回到 WiFi 输入阶段
  void _setError(String msg) {
    if (mounted) {
      setState(() {
        _errorMsg = msg;
        _stage = _Stage.inputWifi;
      });
    }
  }

  /// 打开 WiFi 选择弹窗
  ///
  /// 调用 [WifiPickerDialog.show] 弹出原生 WiFi 扫描列表，
  /// 用户选择后自动填入 SSID 输入框。
  Future<void> _pickWifi() async {
    final ssid = await WifiPickerDialog.show(context);
    if (ssid != null && mounted) {
      _ssidCtrl.text = ssid;
    }
  }

  /// 发送 WiFi 配网凭证并监听结果
  ///
  /// 流程:
  /// ⑤ 构造 [ProvisionData] 并写入 FFF2(JSON 格式)
  /// ⑥ 监听 FFF3 Notify 通知,根据状态跳转结果页
  ///
  /// 超时机制:25 秒内未收到结果,视为配网失败。
  Future<void> _sendProvision() async {
    final ssid = _ssidCtrl.text.trim();
    final password = _passwordCtrl.text;
  
    // 基本输入校验
    if (ssid.isEmpty || password.isEmpty) {
      _setError('WiFi 名称和密码不能为空');
      return;
    }
  
    setState(() {
      _errorMsg = null;
    });
  
    // 立即触发设备绑定（与配网流程并行）
    _startBindDevice();

    try {
      // 检查设备是否仍然连接(设备等待凭证超时 30 秒后会主动断开)
      _updateStage(_Stage.sending, '正在检查连接状态...');
      final connState = await _service.getConnectionState();
        
      if (connState != BluetoothConnectionState.connected) {
        // 设备已断开,需要重新连接
        print('[配网] 设备已断开,正在重新连接...');
        _updateStage(_Stage.connecting, '设备已超时断开,正在重新连接...');
          
        // 取消旧的连接状态订阅
        await _connSub?.cancel();
        _connSub = null;
          
        try {
          // 重新连接设备(增加超时保护)
          await _service.connect(widget.scanResult.device);
          await _service.discoverServices();
          await _service.subscribeStatusNotify();
            
          // 重新监听连接状态
          _connSub = _service.connectionStateStream.listen((state) {
            if (state == BluetoothConnectionState.disconnected &&
                _stage == _Stage.waitingResult) {
              // 配网完成后设备主动断开 BLE —— 正常行为
              print('[配网] 设备主动断连,配网可能已完成');
            } else if (state == BluetoothConnectionState.disconnected &&
                _stage != _Stage.waitingResult) {
              _setError('BLE 连接意外断开,请重试');
            }
          });
          
          print('[配网] 重连成功');
        } catch (reconnectError) {
          // 重连失败,可能是设备已完成配网并关闭 BLE
          print('[配网] 重连失败: $reconnectError');
          print('[配网] 设备可能已完成配网,建议用户检查设备是否正常联网');
          
          // 提示用户设备可能已配网成功
          if (mounted) {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('设备连接超时'),
                content: const Text(
                  '设备已断开 BLE 连接,可能已完成配网。\n\n'
                  '请检查设备指示灯是否停止闪烁,或尝试在设备列表中查看设备状态。\n\n'
                  '如果设备仍未联网,请重新开始配网流程。',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      // 返回首页
                      Navigator.of(context).popUntil((r) => r.isFirst);
                    },
                    child: const Text('返回首页'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _setError('重连失败,请重新点击“开始配网”');
                    },
                    child: const Text('重新配网'),
                  ),
                ],
              ),
            );
          }
          return; // 退出 _sendProvision
        }
      }
  
      // ⑤ 构造配网数据并写入 FFF2
      _updateStage(_Stage.sending, '正在发送 WiFi 凭证...');
      final data = ProvisionData(
        ssid: ssid,
        password: password,
        authUrl: 'https://api.jolipaw.com',       // 设备认证 API
        mqttBroker: 'mqtt.jolipaw.com',            // MQTT 消息服务器
        timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unix 时间戳(秒)
      );
      
      // 打印配网信息(调试用)
      print('[配网] 发送配网数据:');
      print('[配网]   SSID: $ssid');
      print('[配网]   密码长度: ${password.length} 字符');
      print('[配网]   时间戳: ${data.timestamp}');
      
      await _service.writeProvisionData(data);

      // ⑥ 凭证已发送，进入等待结果阶段
      _updateStage(_Stage.waitingResult, '凭证已发送，等待设备连接WiFi...');

      // 设置整体超时计时器（25 秒 = WiFi 15s 超时 + 余量）
      Timer? timeoutTimer = Timer(BleProvisioningService.provTimeout, () async {
        if (mounted && _stage == _Stage.waitingResult) {
          // 超时未收到结果，但设备已断连，可能已配网成功
          print('[配网] 超时未收到结果,设备可能已配网成功并断连');
          // 超时也要尝试绑定
          await _retryBindAfterProvision('');
          _navigateToResult(ProvisionStatus(
            type: ProvisionStatusType.wifiConnected,  // 假设成功,让用户确认
            sn: _deviceInfo?.sn ?? '',
            wifiConnected: true,
            ip: '请检查设备屏幕或路由器',
            reason: null,
          ));
        }
      });

      // 监听 FFF3 Notify 通知，根据状态分流处理
      _statusSub = _service.statusStream.listen((status) async {
        print('[配网] 收到状态通知: ${status.type}');
        switch (status.type) {
          case ProvisionStatusType.provReceived:
            // 设备已收到凭证，正在连接 WiFi —— 更新提示文字
            _updateStage(_Stage.waitingResult, '设备已收到凭证，正在连接 WiFi...');
            break;
          case ProvisionStatusType.wifiConnected:
            // WiFi 连接成功 —— 取消超时计时器，跳转成功页
            print('[配网] 配网成功,取消超时计时器');
            timeoutTimer.cancel();
            // 使用 FFF3 通知中的 SN 重试绑定（设备直推，比 BLE 读取更可靠）
            // 等待绑定完成后再跳转结果页，确保 _bindErrorMessage 已更新
            await _retryBindAfterProvision(status.sn);
            _navigateToResult(status);
            break;
          case ProvisionStatusType.wifiFailed:
            // WiFi 连接失败 —— 取消超时计时器，跳转失败页
            print('[配网] 配网失败: ${status.reason}');
            timeoutTimer.cancel();
            _navigateToResult(status);
            break;
          case ProvisionStatusType.invalidData:
            // 设备返回数据无效 —— 回到输入表单，允许用户重试
            print('[配网] 数据无效');
            timeoutTimer.cancel();
            _setError('设备返回数据无效，请检查格式后重试');
            break;
          case ProvisionStatusType.unknown:
            // 未知状态 —— 忽略
            print('[配网] 未知状态');
            break;
        }
      }, onError: (error) {
        print('[配网] statusStream 错误: $error');
      }, onDone: () async {
        print('[配网] statusStream 关闭');
        // 如果设备已断连且处于 waitingResult 阶段,显示成功提示
        if (_stage == _Stage.waitingResult) {
          print('[配网] 设备断连,可能已配网成功');
          timeoutTimer.cancel();
          // 始终尝试绑定（多源获取 SN，不依赖 FFF1）
          await _retryBindAfterProvision('');
          _navigateToResult(ProvisionStatus(
            type: ProvisionStatusType.wifiConnected,
            sn: _deviceInfo?.sn ?? '',
            wifiConnected: true,
            ip: '请检查设备屏幕或路由器',
            reason: null,
          ));
        }
      });
    } catch (e) {
      print('[配网] 发送失败: $e');
      _setError('发送失败: $e');
    }
  }

  /// 立即尝试绑定设备（与配网流程并行执行）
  ///
  /// 使用 FFF1 读到的 SN 预绑定。若 SN 不可用，绑定交由状态通知阶段处理。
  void _startBindDevice() {
    final sn = _deviceInfo?.sn ?? '';
    if (sn.isEmpty || sn == '未知') {
      print('[配网] SN 不可用，跳过预绑定，等待 FFF3 通知');
      return;
    }
  
    if (!mounted) return;
    final homeId = context.read<HomeState>().currentHomeId;
    if (homeId <= 0) {
      print('[配网] 未选择家庭，跳过预绑定');
      return;
    }
  
    // 安全获取 BLE 连接 MAC 地址（兼容不同平台）
    String macAddress = '';
    try {
      macAddress = widget.scanResult.device.remoteId.str;
    } catch (e) {
      print('[配网] 获取 MAC 地址失败（不影响绑定）: $e');
    }

    // 设备类型映射
    // 默认 deviceType=2（DEVICE_TYPE_WATERER），当前开发板固定为此类型；
    // TODO: 真机接入时，deviceType 应从 _deviceInfo.model 动态映射，
    //       若映射失败应阻止注册，不可使用默认值 0（UNSPECIFIED）。
    int deviceType = 2;
    final model = _deviceInfo?.model ?? '';
    if (model == 'waterer') {
      deviceType = 2;
    } else if (model == 'feeder') deviceType = 1;
    else if (model == 'litterbox') deviceType = 3;

    final firmwareVersion = _deviceInfo?.fwVer ?? '';

    // 异步绑定（含注册参数），不阻塞配网流程
    DeviceService.bindBySn(
      homeId: homeId,
      sn: sn,
      macAddress: macAddress,
      deviceType: deviceType,
      firmwareVersion: firmwareVersion,
    ).then((result) {
      if (!mounted) return;
      if (result.isSuccess) {
        print('[配网] 预绑定成功: $sn');
      } else {
        print('[配网] 预绑定失败: ${result.message}');
        setState(() {
          _bindErrorMessage = result.message;
        });
      }
    }).catchError((e) {
      print('[配网] 预绑定异常: $e');
      if (!mounted) return;
      setState(() {
        _bindErrorMessage = '绑定请求异常: $e';
      });
    });
  }

  /// 配网成功后尝试绑定设备
  ///
  /// 从多个来源获取 SN（FFF3 通知 > FFF1 读取 > 广播名 > MAC 地址），
  /// 确保绑定请求始终发送给服务器。返回绑定是否成功。
  Future<bool> _retryBindAfterProvision(String notifySn) async {
    if (!mounted) return false;
    final homeId = context.read<HomeState>().currentHomeId;
    if (homeId <= 0) return false;

    // 多源获取 SN：FFF3 通知 > FFF1 读取 > 广播名 > MAC 地址
    String sn = notifySn;
    if (sn.isEmpty || sn == '未知') {
      sn = _deviceInfo?.sn ?? '';
    }
    if (sn.isEmpty || sn == '未知') {
      // 从广播名提取（PetDevice_XXXX → XXXX）
      final advName = widget.scanResult.device.advName;
      final platName = widget.scanResult.device.platformName;
      final name = advName.isNotEmpty ? advName : platName;
      if (name.startsWith('PetDevice_')) {
        sn = name.substring('PetDevice_'.length);
      }
    }
    if (sn.isEmpty || sn == '未知') {
      // 最后手段：用 BLE MAC 地址作为 SN
      sn = widget.scanResult.device.remoteId.str;
    }

    print('[配网] 绑定 SN: $sn');

    // 安全获取 BLE 连接 MAC 地址
    String macAddress = '';
    try {
      macAddress = widget.scanResult.device.remoteId.str;
    } catch (e) {}

    // 设备类型映射
    int deviceType = 2;
    final model = _deviceInfo?.model ?? '';
    if (model == 'waterer') {
      deviceType = 2;
    } else if (model == 'feeder') deviceType = 1;
    else if (model == 'litterbox') deviceType = 3;

    final firmwareVersion = _deviceInfo?.fwVer ?? '';

    try {
      final result = await DeviceService.bindBySn(
        homeId: homeId,
        sn: sn,
        macAddress: macAddress,
        deviceType: deviceType,
        firmwareVersion: firmwareVersion,
      );
      if (result.isSuccess) {
        print('[配网] 配网后绑定成功: $sn');
        return true;
      } else {
        print('[配网] 配网后绑定失败: ${result.message}');
        if (mounted) {
          setState(() {
            _bindErrorMessage = result.message;
          });
        }
        return false;
      }
    } catch (e) {
      print('[配网] 配网后绑定异常: $e');
      if (mounted) {
        setState(() {
          _bindErrorMessage = '绑定请求异常: $e';
        });
      }
      return false;
    }
  }

  /// 跳转到配网结果页面
  ///
  /// 使用 pushReplacement 替换当前页面，防止用户返回配网页。
  void _navigateToResult(ProvisionStatus status) {
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ResultPage(
          status: status,
          deviceInfo: _deviceInfo,
          bindErrorMessage: _bindErrorMessage,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deviceName = widget.scanResult.device.platformName;

    return Scaffold(
      appBar: AppBar(
        title: Text(deviceName),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _buildBody(),
    );
  }

  /// 根据当前阶段构建页面内容
  ///
  /// - connecting / readingInfo / sending → 加载动画
  /// - waitingResult → 等待进度动画
  /// - inputWifi → WiFi 输入表单（可能包含错误提示）
  Widget _buildBody() {
    // 错误状态时继续显示 WiFi 输入表单 + 错误信息
    if (_errorMsg != null && _stage == _Stage.inputWifi) {
      // _buildWifiForm 内部会处理错误提示的显示
    }

    switch (_stage) {
      case _Stage.connecting:
      case _Stage.readingInfo:
      case _Stage.sending:
        return _buildLoading();   // 加载中（连接/读设备/发送凭证）
      case _Stage.waitingResult:
        return _buildWaiting();   // 等待设备配网结果
      case _Stage.inputWifi:
        return _buildWifiForm();  // WiFi 输入表单
    }
  }

  /// 构建加载中页面（连接/发现服务/发送凭证阶段）
  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(_statusText, style: const TextStyle(fontSize: 16)),
          if (_deviceInfo != null) ...[
            const SizedBox(height: 24),
            _buildDeviceInfoCard(),
          ],
        ],
      ),
    );
  }

  /// 构建等待配网结果页面（凭证已发送，等待设备 Notify）
  Widget _buildWaiting() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: 20),
            Text(_statusText,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('WiFi 连接超时约 15 秒，请耐心等待',
                style: TextStyle(fontSize: 13, color: Colors.grey[500])),
            if (_deviceInfo != null) ...[
              const SizedBox(height: 24),
              _buildDeviceInfoCard(),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建 WiFi 输入表单
  ///
  /// 包含：设备信息卡片、错误提示、WiFi 名称输入（带扫描按钮）、
  /// WiFi 密码输入（带显示/隐藏切换）、“开始配网”按钮。
  Widget _buildWifiForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 设备信息卡片
          if (_deviceInfo != null) ...[
            _buildDeviceInfoCard(),
            const SizedBox(height: 24),
          ] else ...[
            // 读取失败时显示基本设备信息
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.orange, size: 40),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.scanResult.device.platformName,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('设备信息暂不可用',
                                  style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // 错误提示
          if (_errorMsg != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_errorMsg!,
                        style: TextStyle(color: Colors.red.shade700, fontSize: 14)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // WiFi 名称
          const Text('WiFi 名称', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _ssidCtrl,
            decoration: InputDecoration(
              hintText: '请选择或输入 WiFi 名称',
              prefixIcon: const Icon(Icons.wifi),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                tooltip: '扫描 WiFi',
                onPressed: _pickWifi,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // WiFi 密码
          const Text('WiFi 密码', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _passwordCtrl,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              hintText: '请输入 WiFi 密码',
              prefixIcon: const Icon(Icons.lock),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text('仅支持 2.4GHz WiFi (WPA2-PSK)',
              style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          const SizedBox(height: 24),

          // 发送按钮
          FilledButton.icon(
            onPressed: _sendProvision,
            icon: const Icon(Icons.send),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text('开始配网', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建设备信息卡片
  ///
  /// 展示从 FFF1 读取的设备信息：序列号、型号、固件版本。
  /// 型号为 "waterer" 时显示为中文“饮水机”。
  Widget _buildDeviceInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.devices, size: 20, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Text('设备信息', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const Divider(height: 20),
            _infoRow('序列号', _deviceInfo!.sn),
            _infoRow('型号', _deviceInfo!.model == 'waterer' ? '饮水机' : _deviceInfo!.model),
            _infoRow('固件版本', _deviceInfo!.fwVer),
          ],
        ),
      ),
    );
  }

  /// 构建信息行（label: value 左右布局）
  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
