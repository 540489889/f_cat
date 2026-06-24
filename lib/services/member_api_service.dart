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
        total: map['total'] ?? 0,
        current: map['current'] ?? 1,
      );
    }
    return AlbumListResult.fail(res.message);
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
