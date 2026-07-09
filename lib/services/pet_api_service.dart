import 'package:flutter/foundation.dart';
import 'api_client.dart';

/// 宠物信息 API 服务
///
/// 对接后端 /app/pet/** 系列接口。
class PetApiService {
  static final ApiClient _api = ApiClient.instance;

  /// 获取默认宠物信息
  static Future<void> getDefaultPet() async {
    debugPrint('===== 获取默认宠物 =====');
    final res = await _api.get('/app/pet/default');
    debugPrint('===== 默认宠物 API 返回 =====');
    debugPrint('isSuccess: ${res.isSuccess}');
    debugPrint('message: ${res.message}');
    debugPrint('data: ${res.data}');
  }

  /// 获取用户宠物列表
  static Future<List<PetInfo>?> listUserPets() async {
    debugPrint('===== 获取宠物列表 =====');
    final res = await _api.get('/app/pet/list');
    debugPrint('===== 宠物列表 API 返回 =====');
    debugPrint('isSuccess: ${res.isSuccess}');
    debugPrint('message: ${res.message}');
    debugPrint('data: ${res.data.toString().length > 800 ? res.data.toString().substring(0, 800) + '...(截断 ${res.data.toString().length})' : res.data}');
    if (res.isSuccess && res.data is List) {
      final list = (res.data as List)
          .map((e) => PetInfo.fromJson(e as Map<String, dynamic>))
          .toList();
      debugPrint('===== 解析到 ${list.length} 只宠物 =====');
      return list;
    }
    return null;
  }

  /// 获取宠物详情
  static Future<PetInfo?> getPetDetail(int petId) async {
    debugPrint('===== 获取宠物详情 petId=$petId =====');
    final res = await _api.get('/app/pet/detail/$petId');
    debugPrint('===== 宠物详情 API 返回 =====');
    debugPrint('isSuccess: ${res.isSuccess}');
    debugPrint('message: ${res.message}');
    debugPrint('data: ${res.data}');
    if (res.isSuccess && res.data is Map<String, dynamic>) {
      return PetInfo.fromJson(res.data as Map<String, dynamic>);
    }
    return null;
  }

  /// 获取宠物今日数据
  static Future<List<PetTodayItem>?> getPetToday(int petId) async {
    debugPrint('===== 获取宠物今日数据 petId=$petId =====');
    final res = await _api.get('/app/pet/today/$petId');
    debugPrint('===== 宠物今日数据 API 返回 =====');
    debugPrint('isSuccess: ${res.isSuccess}');
    debugPrint('message: ${res.message}');
    debugPrint('data: ${res.data.toString().length > 800 ? res.data.toString().substring(0, 800) + '...(截断 ${res.data.toString().length})' : res.data}');
    if (res.isSuccess && res.data is List) {
      return (res.data as List)
          .map((e) => PetTodayItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return null;
  }

  /// 获取性格养成分析数据
  static Future<PetAnalysis?> getPetAnalysis(int petId) async {
    debugPrint('===== 获取性格分析 petId=$petId =====');
    final res = await _api.get('/app/pet/analysis/$petId');
    debugPrint('===== 性格分析 API 返回 =====');
    debugPrint('isSuccess: ${res.isSuccess}');
    debugPrint('message: ${res.message}');
    debugPrint('data: ${res.data}');
    if (res.isSuccess && res.data is Map<String, dynamic>) {
      final map = res.data as Map<String, dynamic>;
      final dataList = map['data'];
      List<AnalysisItem> items = [];
      if (dataList is List) {
        items = dataList.map((e) => AnalysisItem.fromJson(e as Map<String, dynamic>)).toList();
      }
      return PetAnalysis(
        notice: (map['notice'] ?? '').toString(),
        items: items,
      );
    }
    return null;
  }

  /// 更新宠物信息
  static Future<PetResult> updatePet({
    required int petId,
    required String nickname,
    required String type,
    required String variety,
    required String sex,
    required String sterilization,
    required String birthday,
    required double weight,
    String? headimg,
    String? imgs,
  }) async {
    final body = <String, dynamic>{
      'id': petId,
      'nickname': nickname,
      'type': type,
      'variety': variety,
      'sex': sex,
      'sterilization': sterilization,
      'birthday': birthday,
      'weight': weight,
      'headimg': headimg ?? '',
      'imgs': imgs ?? '',
    };
    debugPrint('===== 更新宠物 请求参数 =====');
    debugPrint('$body');
    final res = await _api.post('/app/pet/update', body: body);
    debugPrint('===== 更新宠物 API 返回 =====');
    debugPrint('isSuccess: ${res.isSuccess}');
    debugPrint('message: ${res.message}');
    debugPrint('data: ${res.data}');
    if (res.isSuccess) {
      return PetResult.ok(res.message);
    }
    return PetResult.fail(res.message);
  }

  /// 设置为默认宠物
  static Future<void> setDefaultPet(int petId) async {
    debugPrint('===== 设置默认宠物 petId=$petId =====');
    final res = await _api.post('/app/pet/setDefaultPet/$petId');
    debugPrint('===== 设置默认宠物 API 返回 =====');
    debugPrint('isSuccess: ${res.isSuccess}');
    debugPrint('message: ${res.message}');
    debugPrint('data: ${res.data}');
  }

  /// 删除宠物
  static Future<PetResult> deletePet(int petId) async {
    debugPrint('===== 删除宠物 petId=$petId =====');
    final res = await _api.post('/app/pet/remove/$petId');
    debugPrint('===== 删除宠物 API 返回 =====');
    debugPrint('isSuccess: ${res.isSuccess}');
    debugPrint('message: ${res.message}');
    if (res.isSuccess) {
      return PetResult.ok(res.message);
    }
    return PetResult.fail(res.message);
  }

  /// 添加宠物
  static Future<PetResult> addPet({
    required String nickname,
    required String type,
    required String variety,
    required String sex,
    required String sterilization,
    required String birthday,
    required double weight,
    String? headimg,
    String? imgFace,
    String? imgBody,
    String? imgWhole,
  }) async {
    final body = <String, dynamic>{
      'nickname': nickname,
      'type': type,
      'variety': variety,
      'sex': sex,
      'sterilization': sterilization,
      'birthday': birthday,
      'weight': weight,
      'headimg': headimg ?? '',
      'imgFace': imgFace ?? '',
      'imgBody': imgBody ?? '',
      'imgWhole': imgWhole ?? '',
    };
    debugPrint('===== 添加宠物 请求参数 =====');
    debugPrint('$body');
    final res = await _api.post('/app/pet/add', body: body);
    debugPrint('===== 添加宠物 API 返回 =====');
    debugPrint('isSuccess: ${res.isSuccess}');
    debugPrint('message: ${res.message}');
    debugPrint('data: ${res.data}');
    if (res.isSuccess) {
      return PetResult.ok(res.message);
    }
    return PetResult.fail(res.message);
  }
}

class PetResult {
  final bool isSuccess;
  final String message;

  PetResult._({required this.isSuccess, required this.message});

  factory PetResult.ok([String? msg]) =>
      PetResult._(isSuccess: true, message: msg ?? '添加成功');

  factory PetResult.fail([String? msg]) =>
      PetResult._(isSuccess: false, message: msg ?? '添加失败');
}

/// 宠物信息模型
class PetInfo {
  final int id;
  final int memberId;
  final String nickname;
  final String sex;
  final String sterilization;
  final String type;
  final String variety;
  final double weight;
  final String birthday;
  final String headimg;
  final String imgs;
  final String imgFace;
  final String imgBody;
  final String imgWhole;
  final int status;
  final bool isDefault;
  final Map<String, dynamic>? petUserShow;
  final String? createTime;
  final String? updateTime;

  PetInfo({
    required this.id,
    required this.memberId,
    required this.nickname,
    required this.sex,
    required this.sterilization,
    required this.type,
    required this.variety,
    required this.weight,
    required this.birthday,
    required this.headimg,
    required this.imgs,
    required this.imgFace,
    required this.imgBody,
    required this.imgWhole,
    required this.status,
    required this.isDefault,
    this.petUserShow,
    this.createTime,
    this.updateTime,
  });

  factory PetInfo.fromJson(Map<String, dynamic> json) {
    final imgFace = json['imgFace'] as String? ?? '';
    final imgBody = json['imgBody'] as String? ?? '';
    final imgWhole = json['imgWhole'] as String? ?? '';
    return PetInfo(
      id: json['id'] ?? 0,
      memberId: json['memberId'] ?? 0,
      nickname: json['nickname'] ?? '',
      sex: json['sex'] ?? '',
      sterilization: json['sterilization'] ?? '',
      type: json['type'] ?? '',
      variety: json['variety'] ?? '',
      weight: (json['weight'] ?? 0).toDouble(),
      birthday: json['birthday'] ?? '',
      headimg: json['headimg'] ?? '',
      imgs: json['imgs'] ?? '$imgFace,$imgBody,$imgWhole',
      imgFace: imgFace,
      imgBody: imgBody,
      imgWhole: imgWhole,
      status: json['status'] ?? 1,
      isDefault: json['default'] ?? false,
      petUserShow: json['petUserShow'] as Map<String, dynamic>?,
      createTime: json['createTime'],
      updateTime: json['updateTime'],
    );
  }

  /// 显示用的性别文案
  String get genderLabel => sex == 'male' ? 'GG' : 'MM';

  /// 计算年龄（基于 birthday 字段，格式 yyyy-MM-dd）
  String get ageLabel {
    if (birthday.isEmpty) return '/';
    try {
      final date = DateTime.tryParse(birthday);
      if (date == null) return '/';
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inDays <= 0) return '1天';
      if (diff.inDays < 30) return '${diff.inDays}天';
      if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}个月';
      return '${(diff.inDays / 365).floor()}岁';
    } catch (_) {
      return '/';
    }
  }
}

/// 宠物今日数据项
class PetTodayItem {
  final String icon;
  final double rate;
  final String rateTxt;
  final String title;
  final String unit;
  final num value;

  PetTodayItem({
    required this.icon,
    required this.rate,
    required this.rateTxt,
    required this.title,
    required this.unit,
    required this.value,
  });

  factory PetTodayItem.fromJson(Map<String, dynamic> json) {
    final rawValue = json['value'] ?? 0;
    return PetTodayItem(
      icon: json['icon'] ?? '',
      rate: (json['rate'] ?? 0).toDouble(),
      rateTxt: json['rateTxt'] ?? '',
      title: json['title'] ?? '',
      unit: json['unit'] ?? '',
      value: rawValue is num ? rawValue : num.tryParse(rawValue.toString()) ?? 0,
    );
  }

  /// 格式化显示值（含单位）
  String get displayValue {
    if (value is int) return '$value $unit';
    if (value == value.toInt()) return '${value.toInt()} $unit';
    return '$value $unit';
  }
}

/// 性格养成分析数据
class PetAnalysis {
  final String notice;
  final List<AnalysisItem> items;

  PetAnalysis({required this.notice, required this.items});
}

/// 性格养成分析项
class AnalysisItem {
  final String icon;
  final String title;
  final int value;

  AnalysisItem({required this.icon, required this.title, required this.value});

  factory AnalysisItem.fromJson(Map<String, dynamic> json) {
    return AnalysisItem(
      icon: json['icon'] ?? '',
      title: json['title'] ?? '',
      value: (json['value'] ?? 0) is int ? json['value'] : int.tryParse(json['value'].toString()) ?? 0,
    );
  }
}
