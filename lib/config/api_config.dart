/// API 统一配置
///
/// 所有接口域名、超时等配置集中管理在这里。
/// 切换环境只需修改此文件。
class ApiConfig {
  ApiConfig._();

  /// 接口基础地址
  /// 开发环境：http://192.168.1.135:8080 ,192.168.1.164:8080
  /// 生产环境：https://app.jolipaw.pet
  static const String baseUrl = 'https://app.jolipaw.pet';

  /// LLM 服务地址（Smart Core AI 对话）
  static const String llmBaseUrl = 'http://47.95.7.133:8088';

  /// 请求超时（秒）
  static const int connectTimeout = 15;
  static const int receiveTimeout = 30;

  /// 静态资源H5页面地址
  static const String staticBase = 'http://static.jolipaw.pet';

  /// 关于我们
  static const String companyUrl = '$staticBase/company.html';

  /// 隐私政策
  static const String privacyUrl = '$staticBase/privacy_agreement.html';

  /// 用户协议
  static const String userAgreementUrl = '$staticBase/user_agreement.html';
}
