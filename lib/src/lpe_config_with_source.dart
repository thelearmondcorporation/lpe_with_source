/// Global configuration for LPE (Learmond Pay Element).
///
/// Use `LpeWithSourceConfig.init(...)` at app startup to provide default values such
/// as Apple Pay merchant id or a Google Pay merchant id. These defaults are
/// used when individual calls do not provide explicit values.
class LpeWithSourceConfig {
  /// Apple merchant id used for presenting Apple Pay (e.g. 'merchant.com.example')
  static String? appleMerchantId;

  /// Google Pay merchant id (provider-specific merchant identifier).
  /// For Stripe flows this may be a value you obtain from the Google Pay
  /// console or from your payment provider configuration.
  static String? googleMerchantId;

  /// Initialize common settings. Call once at app startup.
  ///
  /// Accepts either `googleMerchantId` or the legacy `googleMerchantID` casing.
  static void init({
    String? appleMerchantId,
    String? googleMerchantId,
    String? googleMerchantID,
  }) {
    LpeWithSourceConfig.appleMerchantId = appleMerchantId;
    LpeWithSourceConfig.googleMerchantId = googleMerchantID ?? googleMerchantId;
  }
}
