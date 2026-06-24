/// 家庭设备模型
///
/// 对应后端 /home/device/list 响应中的设备项。
/// 产品信息（deviceTitle/deviceType/deviceImglogo/deviceModel）实时来自 app_device，
/// IoT 实时状态（iotOnline/iotStatus/iotFirmwareVer/iotLastOnline）来自 pet-iot 平台。
class HomeDevice {
  final int id;
  final int homeId;
  final int deviceId;
  final String? sn;
  final String? deviceTitle;
  final String? deviceType;
  final String? deviceImglogo;
  final String? deviceModel;
  final String? alias;
  final String? room;
  final int status;
  final int boundBy;
  final String? bindTime;
  final String? updateTime;

  // IoT 实时状态（设备列表接口已自动合并）
  final bool? iotOnline;
  final String? iotStatus;
  final String? iotFirmwareVer;
  final String? iotLastOnline;

  HomeDevice({
    required this.id,
    required this.homeId,
    required this.deviceId,
    this.sn,
    this.deviceTitle,
    this.deviceType,
    this.deviceImglogo,
    this.deviceModel,
    this.alias,
    this.room,
    this.status = 1,
    this.boundBy = 0,
    this.bindTime,
    this.updateTime,
    this.iotOnline,
    this.iotStatus,
    this.iotFirmwareVer,
    this.iotLastOnline,
  });

  /// 显示名称：别名 > 产品标题 > 默认
  String get displayName => alias?.isNotEmpty == true
      ? alias!
      : (deviceTitle?.isNotEmpty == true ? deviceTitle! : '未知设备');

  /// 是否在线
  bool get isOnline => iotOnline == true;

  /// 是否已绑定 SN（即是否为 IoT 硬件设备）
  bool get hasSn => sn?.isNotEmpty == true;

  factory HomeDevice.fromJson(Map<String, dynamic> json) {
    return HomeDevice(
      id: json['id'] as int? ?? 0,
      homeId: json['homeId'] as int? ?? json['home_id'] as int? ?? 0,
      deviceId: json['deviceId'] as int? ?? json['device_id'] as int? ?? 0,
      sn: json['sn'] as String?,
      deviceTitle:
          json['deviceTitle'] as String? ?? json['device_title'] as String?,
      deviceType:
          json['deviceType'] as String? ?? json['device_type'] as String?,
      deviceImglogo:
          json['deviceImglogo'] as String? ?? json['device_imglogo'] as String?,
      deviceModel:
          json['deviceModel'] as String? ?? json['device_model'] as String?,
      alias: json['alias'] as String?,
      room: json['room'] as String?,
      status: json['status'] as int? ?? 1,
      boundBy: json['boundBy'] as int? ?? json['bound_by'] as int? ?? 0,
      bindTime:
          json['bindTime'] as String? ?? json['bind_time'] as String?,
      updateTime:
          json['updateTime'] as String? ?? json['update_time'] as String?,
      iotOnline: json['iotOnline'] as bool?,
      iotStatus: json['iotStatus'] as String?,
      iotFirmwareVer: json['iotFirmwareVer'] as String?,
      iotLastOnline: json['iotLastOnline'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'homeId': homeId,
        'deviceId': deviceId,
        'sn': sn,
        'deviceTitle': deviceTitle,
        'deviceType': deviceType,
        'deviceImglogo': deviceImglogo,
        'deviceModel': deviceModel,
        'alias': alias,
        'room': room,
        'status': status,
        'boundBy': boundBy,
        'iotOnline': iotOnline,
        'iotStatus': iotStatus,
        'iotFirmwareVer': iotFirmwareVer,
        'iotLastOnline': iotLastOnline,
      };

  @override
  String toString() =>
      'HomeDevice(id: $id, name: $displayName, sn: $sn, online: $isOnline)';
}
