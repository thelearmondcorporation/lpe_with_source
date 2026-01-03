/// Public package entry for `lpe_with_source`.
///
/// Main library entry point for Learmond Pay Element (LPE) with the Source
/// styling helpers bundled by this package. Consumers should import
/// `package:lpe_with_source/lpe_with_source.dart` to access the paysheet
/// helpers, the Source styling API, and the common pay button widget.
///
/// Re-exported widget: `LearmondPayButtons` — A small widget that renders a
/// row/wrap of payment method buttons (card, bank, Apple Pay, Google Pay).
///
/// Constructor (summary):
/// ```dart
/// const LearmondPayButtons({
///   Key? key,
///   String? apiKey,
///   String? clientSecret,
///   String? merchantId,
///   Map<String,dynamic>? merchantArgs,
///   String? merchantName,
///   String? merchantInfo,
///   List<SummaryLineItem>? summaryItems,
///   String? googleMerchantId,
///   String amount = '0.00',
///   String currency = 'USD',
///   void Function(PaymentResult)? onResult,
///   bool showNativePay = true,
///   ButtonStyle? buttonStyle,
/// })
/// ```
///
/// Important properties:
/// - `amount` (`String`, default `'0.00'`): human-readable amount shown on
///   the buttons (for example, `'9.99'`).
/// - `buttonStyle` (`ButtonStyle?`): optional style forwarded to underlying
///   material buttons.
/// - `clientSecret` (`String?`): optional client secret used to pre-fill
///   payment-intent flows when presenting the paysheet.
///
/// For full API details see the `lpe` package documentation (this export
/// forwards to `package:lpe`).
library lpe_with_source;

export 'src/lpe_with_source.dart';
export 'src/lpe_config_with_source.dart' show LpeWithSourceConfig;
export 'src/source_pay_button.dart' show Source, SourcePayButton;

/// Re-export the `LearmondPayButtons` widget from the `lpe` package so
/// callers can import the buttons alongside the Source API from the
/// package root.
export 'package:lpe/lpe.dart' show LearmondPayButtons;

/// Also re-export the underlying `paysheet` package so callers can access
/// its public types and helpers directly from this package root.
export 'package:paysheet/paysheet.dart' show Paysheet, PaymentResult;
