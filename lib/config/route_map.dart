import 'package:flutter/material.dart';
import '../pages/pet/figure.dart';
import '../pages/mall/details.dart';

/// 路由注册表
///
/// 后端传 pagePath 如 "addPet"、"productDetail?id=1"
/// App 通过本表查找并构建页面，无需在调用处 import
class AppRoutes {
  AppRoutes._();

  static final Map<String, WidgetBuilder> _routes = {
    'addPet': (_) => const PetFigurePage(),
    // 'productDetail' 需要参数，通过 query 传递
  };

  /// 根据 pagePath 跳转
  /// pagePath 格式: "addPet" 或 "productDetail?id=1"
  static Future<T?>? navigateTo<T>(BuildContext context, String pagePath) {
    final uri = Uri.tryParse(pagePath);
    if (uri == null) return null;

    final name = uri.hasScheme ? uri.path.replaceFirst('/', '') : pagePath.split('?').first;

    if (_routes.containsKey(name)) {
      return Navigator.of(context).push(
        MaterialPageRoute(builder: _routes[name]!),
      );
    }

    // 特殊路由
    if (name == 'productDetail') {
      final id = int.tryParse(uri.queryParameters['id'] ?? '');
      if (id != null) {
        return Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ProductDetailsPage(id: id)),
        );
      }
    }

    return null;
  }
}
