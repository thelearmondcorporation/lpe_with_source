// Re-export the public paysheet API from the external `paysheet` package.
//
// The implementation previously lived here; it has been moved into the
// separate `paysheet` package. This file keeps the original public API
// surface stable for consumers of this package.
// Re-export the official `paysheet` package API endpoints for presenting the paysheet.
export 'package:paysheet/paysheet.dart'
    show showLpePaysheet, StripePaymentResult;

// Convenience wrapper that presents the paysheet using a provided
// `BuildContext`. This simply forwards to `showLpePaysheet` from the
// published `paysheet` package so callers don't need to import that
// package directly when presenting the paysheet.
import 'package:flutter/widgets.dart' show BuildContext;
import 'package:paysheet/paysheet.dart'
    show showLpePaysheet, StripePaymentResult;

Future<StripePaymentResult?> presentPaysheet(
  BuildContext context, {
  String? publishableKey,
  String? clientSecret,
  required String method,
  String? amount,
  Map<String, dynamic>? merchantArgs,
  String? totalPriceLabel,
  bool mountOnShow = false,
  bool enableStripeJs = false,
  void Function(StripePaymentResult)? onResult,
  Future<void> Function()? onPay,
}) {
  // Allow callers to omit the publishable key; forward an empty string to
  // the underlying implementation so the paysheet package can handle
  // uninitialized or styling-only usage.
  final mergedMerchantArgs = Map<String, dynamic>.from(merchantArgs ?? {});
  if (totalPriceLabel != null && totalPriceLabel.isNotEmpty) {
    mergedMerchantArgs['totalPriceLabel'] = totalPriceLabel;
  }

  // If caller supplied `summaryItems`, compute the summed amount (in cents)
  // and ensure the final summary item represents the total. This keeps the
  // native pay sheet consistent across platforms: display line items and
  // a final "Total" line with the computed amount.
  try {
    final supplied = mergedMerchantArgs['summaryItems'];
    if (supplied is List) {
      final newList = <Map<String, dynamic>>[];
      var computed = 0;
      for (final item in supplied) {
        if (item is Map) {
          final cents = (item['amountCents'] is num)
              ? (item['amountCents'] as num).toInt()
              : 0;
          computed += cents;
          newList.add(Map<String, dynamic>.from(item));
        }
      }
      final finalLabel = (mergedMerchantArgs['totalPriceLabel'] as String?) ??
          totalPriceLabel ??
          'Total';
      // If last item already matches the intended total label and amount,
      // reuse it; otherwise append a final total line.
      var shouldAppend = true;
      if (newList.isNotEmpty) {
        final last = newList.last;
        final lastLabel = last['label'] as String? ?? '';
        final lastCents = (last['amountCents'] is num)
            ? (last['amountCents'] as num).toInt()
            : 0;
        if (lastLabel == finalLabel && lastCents == computed) {
          shouldAppend = false;
        }
      }
      if (shouldAppend) {
        newList.add({'label': finalLabel, 'amountCents': computed});
      }
      mergedMerchantArgs['summaryItems'] = newList;
      mergedMerchantArgs['totalPriceLabel'] = finalLabel;
    }
  } catch (e) {
    // ignore and let underlying package/platform handle gracefully
  }
  return showLpePaysheet(
    context,
    publishableKey: publishableKey ?? '',
    clientSecret: clientSecret,
    method: method,
    amount: amount,
    merchantArgs: mergedMerchantArgs.isEmpty ? null : mergedMerchantArgs,
    mountOnShow: mountOnShow,
    enableStripeJs: enableStripeJs,
    onResult: onResult,
    onPay: onPay,
  );
}
