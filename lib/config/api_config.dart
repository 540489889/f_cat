/// API 统一配置
///
/// 所有接口域名、超时等配置集中管理在这里。
/// 切换环境只需修改此文件。
class ApiConfig {
  ApiConfig._();

  /// 接口基础地址
  /// 开发环境：http://192.168.1.135:8080
  /// 生产环境：https://app.jolipaw.pet
  static const String baseUrl = 'https://app.jolipaw.pet';

  /// 请求超时（秒）
  static const int connectTimeout = 15;
  static const int receiveTimeout = 30;
}
