/// Global configuration for LPE (Learmond Pay Element).
///
/// Use `LpeWithSourceConfig.init(...)` at app startup to provide default values such
/// as Apple Pay merchant id or a Google Pay gateway merchant id. These
/// defaults are used when individual calls do not provide explicit values.
class LpeWithSourceConfig {
  /// Apple merchant id used for presenting Apple Pay (e.g. 'merchant.com.example')
  static String? appleMerchantId;

  /// Google Pay gateway merchant id (gateway-specific merchant identifier)
  /// For Stripe gateway flows this may be a value you obtain from Google Pay
  /// console or your gateway configuration.
  static String? googleGatewayMerchantId;

  /// Initialize common settings. Call once at app startup.
  static void init({String? appleMerchantId, String? googleGatewayMerchantId}) {
    LpeWithSourceConfig.appleMerchantId = appleMerchantId;
    LpeWithSourceConfig.googleGatewayMerchantId = googleGatewayMerchantId;
  }
}
