import 'package:flutter/material.dart';
import 'paysheet.dart' show presentPaysheet, StripePaymentResult;

/// A small, reusable Source Pay button.
class SourcePayButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final ButtonStyle style;
  final double minWidth;
  final double height;
  final String? publishableKey;
  final String? totalPriceLabel;
  final String method;
  final String? amount;
  final String? clientSecret;
  final Map<String, dynamic>? merchantArgs;
  final bool enableStripeJs;
  final void Function(StripePaymentResult?)? onResult;

  const SourcePayButton({
    super.key,
    this.onPressed,
    required this.style,
    this.minWidth = 68.0,
    this.height = 36.0,
    this.publishableKey,
    this.totalPriceLabel,
    this.method = 'card',
    this.amount,
    this.clientSecret,
    this.merchantArgs,
    this.enableStripeJs = false,
    this.onResult,
  });

  @override
  State<SourcePayButton> createState() => _SourcePayButtonState();
}

class _SourcePayButtonState extends State<SourcePayButton> {
  @override
  void initState() {
    super.initState();
  }

  Future<void> _handlePressed() async {
    final pk =
        widget.publishableKey ?? Source.present.defaultPublishableKey ?? '';

    final result = await presentPaysheet(
      context,
      publishableKey: pk,
      clientSecret: widget.clientSecret,
      method: widget.method,
      amount: widget.amount,
      merchantArgs: widget.merchantArgs,
      totalPriceLabel: widget.totalPriceLabel,
      enableStripeJs: widget.enableStripeJs,
    );

    if (widget.onResult != null) widget.onResult!(result);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ElevatedButton(
        onPressed: widget.onPressed ?? _handlePressed,
        style: widget.style.copyWith(
          backgroundColor: WidgetStateProperty.all(Colors.white),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
          ),
          textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 13.0)),
          minimumSize:
              WidgetStateProperty.all(Size(widget.minWidth, widget.height)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFFD700), width: 2.0),
              ),
              child: const Center(
                child: Text(
                  'S',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFD700),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 2.0),
            const Text('Pay'),
          ],
        ),
      ),
    );
  }
}

/// Singleton accessor for Source helpers (single-instance API).
class Source {
  Source._(this.defaultStyle);

  /// Single mutable instance used by callers.
  static final Source present = Source._(ElevatedButton.styleFrom());

  /// The default style applied to `SourcePayButton` instances when callers
  /// don't provide an explicit `style`.
  ButtonStyle defaultStyle;

  /// Optional package-level default publishable key used by the source button
  /// when callers do not pass an explicit `publishableKey`.
  String? defaultPublishableKey;

  /// Returns a `SourcePayButton` built with the instance `defaultStyle`.
  Widget sourcePayButton({
    Key? key,
    VoidCallback? onPressed,
    double minWidth = 68.0,
    double height = 36.0,
    String? totalPriceLabel,
  }) {
    return SourcePayButton(
      key: key,
      onPressed: onPressed,
      style: defaultStyle,
      minWidth: minWidth,
      height: height,
      totalPriceLabel: totalPriceLabel,
    );
  }

  /// Backwards-compatible snake_case alias.
  // ignore: non_constant_identifier_names
  Widget source_pay_button({
    Key? key,
    VoidCallback? onPressed,
    double minWidth = 68.0,
    double height = 36.0,
    String? totalPriceLabel,
  }) =>
      sourcePayButton(
        key: key,
        onPressed: onPressed,
        minWidth: minWidth,
        height: height,
        totalPriceLabel: totalPriceLabel,
      );
}
