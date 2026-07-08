/// Web stub for AliAuth - no-op implementation
/// Real functionality is mobile-only (native SDK)
class AliAuthPluginWebApi {
  Future<String?> getConnection() async => null;
  Future<void> setLoggerEnable(bool isEnable) async {}
  Future<String?> getVersion() async => '0.0.0';
  Future<void> checkAuthAvailable(
    String accessToken,
    String jwtToken,
    Function(dynamic status) success,
    Function(dynamic status) error,
  ) async {
    error('Web not supported');
  }

  Future<void> getVerifyToken(
    Function(dynamic status) success,
    Function(dynamic status) error,
  ) async {
    error('Web not supported');
  }
}
