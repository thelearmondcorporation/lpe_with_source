/// Main library entry point for Learmond Pay Element (LPE).
///
/// Exports the payment sheet and result classes.
library lpe_with_source;

// Export configuration and the paysheet presentation helpers. The
// package's `src/paysheet.dart` now re-exports the official
// `paysheet` package endpoints and provides a `presentPaysheet`
// convenience wrapper which callers can use to present the UI.
export 'lpe_config_with_source.dart' show LpeWithSourceConfig;
export 'package:paysheet/paysheet.dart' show Paysheet, PaymentResult;
export 'source_pay_button.dart' show Source;
