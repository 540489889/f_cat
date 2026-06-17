import 'package:flutter/foundation.dart';
import 'api_client.dart';

/// Banner 广告 API 服务
///
/// 对接后端 /app/ad/** 系列接口。
class BannerApiService {
  static final ApiClient _api = ApiClient.instance;

  /// 根据位置获取广告列表
  /// position: 广告位置标识，如 'mall'
  static Future<BannerListResult> getAdsByPosition({
    String position = 'mall',
  }) async {
    final res = await _api.get('/app/ads/list/$position');
    debugPrint('===== Banner API 返回 (position=$position) =====');
    debugPrint('isSuccess: ${res.isSuccess}');
    debugPrint('message: ${res.message}');
    debugPrint('data: ${res.data}');
    if (res.isSuccess) {
      final list = res.asList;
      debugPrint('Banner 数量: ${list.length}');
      final banners = list
          .map((e) {
            debugPrint('  Banner: $e');
            return BannerItem.fromJson(e as Map<String, dynamic>);
          })
          .toList();
      return BannerListResult.ok(banners, res.message);
    }
    return BannerListResult.fail(res.message);
  }
}

/// Banner 列表结果
class BannerListResult {
  final bool isSuccess;
  final String message;
  final List<BannerItem> banners;

  BannerListResult._({required this.isSuccess, required this.message, required this.banners});

  factory BannerListResult.ok(List<BannerItem> banners, [String? msg]) =>
      BannerListResult._(isSuccess: true, message: msg ?? '成功', banners: banners);

  factory BannerListResult.fail([String? msg]) =>
      BannerListResult._(isSuccess: false, message: msg ?? '请求失败', banners: []);
}

/// Banner 数据模型
class BannerItem {
  final String image;
  final String linkType;
  final int? targetId;
  final String? url;

  BannerItem({required this.image, this.linkType = 'detail', this.targetId, this.url});

  factory BannerItem.fromJson(Map<String, dynamic> json) {
    final link = json['link'] as String?;
    String linkType = 'detail';
    int? targetId;
    String? url;

    if (link != null && link.isNotEmpty) {
      if (link.startsWith('http')) {
        linkType = 'h5';
        url = link;
      } else if (link.contains('productDetail')) {
        linkType = 'page';
        url = link;
      } else {
        linkType = 'page';
        url = link;
      }
    }

    return BannerItem(
      image: json['imgurl'] as String? ?? '',
      linkType: linkType,
      targetId: targetId,
      url: url,
    );
  }
}
