import 'package:flutter/foundation.dart';
import 'api_client.dart';
import 'auth_service.dart';

/// 会员 API 服务
///
/// 对接后端 /app/member/** 系列接口。
class MemberApiService {
  static final ApiClient _api = ApiClient.instance;

  /// 获取会员信息
  static Future<MemberResult> getMemberInfo() async {
    final res = await _api.get('/app/member/info');
    debugPrint('===== 会员信息 API 返回 =====');
    debugPrint('isSuccess: ${res.isSuccess}');
    debugPrint('message: ${res.message}');
    debugPrint('data: ${res.data}');
    if (res.isSuccess) {
      final map = res.asMap;
      // 更新本地用户信息
      await AuthService.saveUserInfo(map);
      return MemberResult.ok(map);
    }
    return MemberResult.fail(res.message);
  }

  /// 获取用户相册列表（按分类分页）
  ///
  /// [type] 相册分类：image / video / daily
  /// [pageNum] 页码，默认1
  /// [pageSize] 分页大小，默认10
  static Future<AlbumListResult> getAlbumList({
    required String type,
    int pageNum = 1,
    int pageSize = 10,
  }) async {
    debugPrint('[相册API] 请求参数: type=$type, pageNum=$pageNum, pageSize=$pageSize');
    final res = await _api.get('/app/album/list', queryParams: {
      'type': type,
      'pageNum': pageNum,
      'pageSize': pageSize,
    });
    if (res.isSuccess) {
      final map = res.asMap;
      final records = (map['records'] as List<dynamic>?)
              ?.map((e) => AlbumInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      return AlbumListResult.ok(
        records: records,
        total: int.tryParse(map['total']?.toString() ?? '') ?? 0,
        current: int.tryParse(map['current']?.toString() ?? '') ?? 1,
      );
    }
    return AlbumListResult.fail(res.message);
  }
  /// 获取通知消息默认设置（0关，1开）
  static Future<NoticeResult> getNoticeSettings() async {
    final res = await _api.get('/app/member/notice');
    debugPrint('===== 通知设置 API 返回 =====');
    debugPrint('isSuccess: ${res.isSuccess}');
    debugPrint('message: ${res.message}');
    debugPrint('data: ${res.data}');
    if (res.isSuccess) {
      final map = res.asMap;
      return NoticeResult.ok(map);
    }
    return NoticeResult.fail(res.message);
  }

  /// 更新通知消息设置（0关，1开）
  static Future<NoticeResult> updateNoticeSettings({
    int? deviceMsg,
    int? petMsg,
    int? sysMsg,
    String clientId = '',
  }) async {
    final body = <String, dynamic>{
      'clientId': clientId,
    };
    if (deviceMsg != null) body['deviceMsg'] = deviceMsg;
    if (petMsg != null) body['petMsg'] = petMsg;
    if (sysMsg != null) body['sysMsg'] = sysMsg;

    debugPrint('[通知API] 更新通知设置: $body');
    final res = await _api.post('/app/member/noticeSet', body: body);
    debugPrint('[通知API] 更新通知设置 返回: isSuccess=${res.isSuccess}, message=${res.message}');
    if (res.isSuccess) {
      return NoticeResult.ok(res.asMap);
    }
    return NoticeResult.fail(res.message);
  }

  /// 更新会员信息
  ///
  /// [nickname] 昵称
  /// [headimg] 头像（预设名称或 base64）
  /// [birthday] 生日
  static Future<MemberUpdateResult> updateMemberInfo({
    String? nickname,
    String? headimg,
    DateTime? birthday,
  }) async {
    final body = <String, dynamic>{};
    if (nickname != null) body['nickname'] = nickname;
    if (headimg != null) body['headimg'] = headimg;
    if (birthday != null) body['birthday'] = birthday.toIso8601String();

    debugPrint('[会员API] 更新会员信息: $body');
    final res = await _api.post('/app/member/update', body: body);
    debugPrint('[会员API] 更新会员信息 返回: isSuccess=${res.isSuccess}, message=${res.message}');
    if (res.isSuccess) {
      final map = res.asMap;
      await AuthService.saveUserInfo(map);
      return MemberUpdateResult.ok(map);
    }
    return MemberUpdateResult.fail(res.message);
  }
}

/// 相册条目
class AlbumInfo {
  final int id;
  final int memberId;
  final int? deviceId;
  final int? petId;
  final String? org; // 原图
  final String? thumb; // 缩略图
  final String? type;
  final String? source;
  final int? status;
  final String? createTime;

  AlbumInfo({
    required this.id,
    required this.memberId,
    this.deviceId,
    this.petId,
    this.org,
    this.thumb,
    this.type,
    this.source,
    this.status,
    this.createTime,
  });

  factory AlbumInfo.fromJson(Map<String, dynamic> json) => AlbumInfo(
        id: json['id'] ?? 0,
        memberId: json['memberId'] ?? 0,
        deviceId: json['deviceId'],
        petId: json['petId'],
        org: json['org'],
        thumb: json['thumb'],
        type: json['type'],
        source: json['source'],
        status: json['status'],
        createTime: json['createTime'],
      );

  /// 优先使用缩略图，没有则用原图(source是图片URL，org是来源标签如APP/DEVICE)
  String get displayUrl => (thumb != null && thumb!.isNotEmpty) ? thumb! : (source ?? '');
}

class MemberResult {
  final bool isSuccess;
  final String message;
  final Map<String, dynamic>? data;

  MemberResult._({required this.isSuccess, required this.message, this.data});

  factory MemberResult.ok(Map<String, dynamic> data) =>
      MemberResult._(isSuccess: true, message: '成功', data: data);

  factory MemberResult.fail([String? msg]) =>
      MemberResult._(isSuccess: false, message: msg ?? '请求失败');
}

class AlbumListResult {
  final bool isSuccess;
  final String message;
  final List<AlbumInfo> records;
  final int total;
  final int current;

  AlbumListResult._({
    required this.isSuccess,
    required this.message,
    this.records = const [],
    this.total = 0,
    this.current = 1,
  });

  factory AlbumListResult.ok({
    required List<AlbumInfo> records,
    required int total,
    required int current,
  }) =>
      AlbumListResult._(
        isSuccess: true,
        message: '成功',
        records: records,
        total: total,
        current: current,
      );

  factory AlbumListResult.fail([String? msg]) =>
      AlbumListResult._(isSuccess: false, message: msg ?? '请求失败');

  /// 是否还有更多数据（兼容total为0的后端bug：当返回数据达到pageSize时也认为有更多）
  bool hasMore(int pageSize) => records.length >= pageSize;
}

class MemberUpdateResult {
  final bool isSuccess;
  final String message;
  final Map<String, dynamic>? data;

  MemberUpdateResult._({required this.isSuccess, required this.message, this.data});

  factory MemberUpdateResult.ok(Map<String, dynamic>? data) =>
      MemberUpdateResult._(isSuccess: true, message: '更新成功', data: data);

  factory MemberUpdateResult.fail([String? msg]) =>
      MemberUpdateResult._(isSuccess: false, message: msg ?? '更新失败');
}

class NoticeResult {
  final bool isSuccess;
  final String message;
  final Map<String, dynamic>? data;

  NoticeResult._({required this.isSuccess, required this.message, this.data});

  factory NoticeResult.ok(Map<String, dynamic> data) =>
      NoticeResult._(isSuccess: true, message: '成功', data: data);

  factory NoticeResult.fail([String? msg]) =>
      NoticeResult._(isSuccess: false, message: msg ?? '请求失败');

  /// 0/1 → bool
  bool get pushEnabled => (data?['petMsg'] ?? 1) == 1;
  bool get deviceEnabled => (data?['deviceMsg'] ?? 1) == 1;
  bool get systemEnabled => (data?['sysMsg'] ?? 1) == 1;
}
