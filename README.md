# lpe_with_source

Learmond Pay Element with Source— `lpe_with_source`

This package provides a styling-focused Source pay button and convenience
wrappers around the published `paysheet` UI so apps can present a
consistent paysheet and native device-pay flows.

## Quick start

Add the package to your `pubspec.yaml` and import the public barrel:

```dart
import 'package:lpe_with_source/lpe_with_source.dart';
```

The package re-exports the core paysheet helpers and common widgets:
- `presentPaysheet(...)` / `showLpePaysheet` — present the paysheet UI (publishable key is optional)
- `PaymentResult` — result type returned from the paysheet
- `LearmondPayButtons` — re-exported from `package:lpe` for the single-line pay buttons
- `Source` and `SourcePayButton` — the styling-first Source button API provided by this package

## Source button (recommended for styling-only integration)

This package exposes a single-instance `Source` helper to provide
default styles and convenience factories:

- `Source.present` — mutable singleton with `defaultStyle` and `defaultapiKey`.
- `Source.present.source_pay_button()` — returns a `SourcePayButton` built with the singleton defaults.

If you need per-button overrides, instantiate `SourcePayButton` directly:

```dart
SourcePayButton(
	style: Source.present.defaultStyle,
	amount: '24.99',
	merchantArgs: {
		'merchantName': 'My Store',
		'merchantInfo': 'Order #123',
		'summaryItems': [
			{'label': 'T-shirt', 'amountCents': 1999},
			{'label': 'Shipping', 'amountCents': 500},
		],
	},
	onResult: (result) { /* handle result */ },
)
```

Notes:
- `merchantArgs['summaryItems']` should be a `List` of maps with `label` (String) and `amountCents` (int). Native pay sheets will render these as Line Items.
- The package does not require a publishable key for styling. `presentPaysheet(...)` and `SourcePayButton` accept optional 

## LearmondPayButtons

If you want the bundled single-line pay buttons, you can import and use
`LearmondPayButtons` directly (this package re-exports it from `package:lpe`):

```dart
LearmondPayButtons(
	amount: '9.99',
	onResult: (r) { /* handle PaymentResult */ },
)
```

## Example app

See `lpe_with_source_test_app/` for a small demo that shows `SourcePayButton`
usage and how to pass `merchantArgs.summaryItems` to display Line Items in
native pay flows.

## Notes

- This package is intentionally styling-focused — it provides a consistent
	Source button and convenience re-exports. Use `presentPaysheet` or the
	`LearmondPayButtons` widget for presenting the paysheet and native device
	pay flows as appropriate.

---