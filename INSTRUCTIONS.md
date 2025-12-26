# LPE (Learmond Pay Element) with Source Implementation Instructions

## Overview
Learmond Pay Element (LPE) with Source provides a reusable Paysheet for any app framework. It uses a modal bottom sheet and a WebView to securely collect payment details and confirm payments. Built for modern payment flows.

## Main Operations
**LearmondPaySheet.show(...)**: Main entry point. Opens the payment sheet and returns a `PaymentResult`.
**PaymentResult**: Contains the payment result (success, status, paymentIntentId, error, rawResult).
**Supported methods**: 'card', 'us_bank', 'eu_bank', 'apple_pay', 'google_pay', 'source_pay'.
**WebView**: Used to render secure payment elements.

## How to Implement

### 1. Add Dependency
In your app's `pubspec.yaml`:
```yaml
dependencies:
  lpe_with_source: ^0.0.2+2
```

### 2. Import the Package
```dart
import 'package:lpe_with_source/lpe_with_source.dart';
```

### 3. Show the Payment Sheet
```dart
final result = await LearmondPaySheet.show(
  context: context,
  publishableKey: 'your_publishable_key',
  clientSecret: 'your_client_secret',
  method: 'card', // or 'us_bank', 'eu_bank', 'apple_pay', 'google_pay'
  title: 'Pay \$10.00',
);
if (result.success) {
  // Payment succeeded
}
```

### Using the single-line buttons widget (recommended)

For most apps we recommend embedding the `LearmondPayButtons` widget directly in your checkout UI. It renders a compact, consistent set of pay method buttons and wires them to both the paysheet and native pay flows:

```dart
LearmondPayButtons(
  publishableKey: 'pk_test_...', // optional fallback
  clientSecret: 'pi_test_client_secret', // optional
  merchantId: 'merchant.com.yourdomain', // required for Apple Pay
  amount: '10.00',
  currency: 'USD',
  onResult: (StripePaymentResult r) {
    if (r.success) {
      // Handle success (r.paymentIntentId or r.rawResult)
    } else {
      // Handle error r.error
    }
  },
)
```

Notes:
- The widget uses a responsive layout (three buttons on the first row, two centered buttons on the second row) and keeps consistent button sizing.
- Use `onResult` to process the returned `StripePaymentResult` whether the flow was web-based (card/bank) or native (apple/google). Native flows return raw tokens in `result.rawResult` which you MUST send to your server for verification.
- Do not rely on client-supplied amounts — always verify amounts server-side.

### Source button (styling-only) — new

This package also exposes a lightweight, styling-focused Source button API intended for apps that only want to present a consistent pay button and let the paysheet implementation handle the presentation.

- `Source.present`: a single mutable singleton that holds defaults used by the factory and buttons (for example `Source.present.defaultStyle` and `Source.present.defaultPublishableKey`).
- `Source.present.source_pay_button()`: a small factory that returns a `SourcePayButton` built with the singleton `defaultStyle`.
- `SourcePayButton`: the full widget you can instantiate when you need to pass per-button configuration such as `publishableKey`, `clientSecret`, `amount`, or `merchantArgs` (line items).

Examples

1) Using the simple factory (uses `Source.present` defaults):

```dart
// optionally set a default publishable key at app init or from a text field
Source.present.defaultPublishableKey = 'pk_test_...';

// place the factory button in your UI
Source.present.source_pay_button();
```

2) Instantiating `SourcePayButton` directly to pass `merchantArgs` (line items):

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
  onResult: (result) { /* handle StripePaymentResult */ },
)
```

Notes:
- To show Line Items in native pay (Google Pay / Apple Pay) pass `merchantArgs['summaryItems']` as a `List` of maps with `label` (String) and `amountCents` (int). The native bridge will compute totals and render `displayItems` when available.
- The factory `Source.present.source_pay_button()` is intentionally minimal. If you need to pass `merchantArgs` or per-button overrides, construct a `SourcePayButton` directly as shown above.
- `presentPaysheet(...)` and `SourcePayButton` no longer require a publishable key; you may pass an empty key or set `Source.present.defaultPublishableKey` as a convenience. The underlying paysheet implementation will decide how to handle an omitted key.

### Embedding `LearmondPayButtons` into your UI (step-by-step)

1) Import the package:

```dart
import 'package:lpe/lpe.dart';
```

2) Add the widget where you want the pay buttons to appear (e.g., checkout, product page):

```dart
LearmondPayButtons(
  publishableKey: 'pk_test_...', // optional fallback
  clientSecret: 'pi_test_client_secret', // optional (used by web flows)
  merchantId: 'merchant.com.yourdomain', // required for Apple Pay
  amount: '10.00', // display amount; server must verify final amount
  currency: 'USD',
  onResult: (StripePaymentResult r) {
    if (r.success) {
      // Payment succeeded. You may have r.paymentIntentId or r.rawResult (native token)
    } else {
      // Handle error r.error
    }
  },
)
```

3) Pass dynamic values from your form (amount, merchantId, publishableKey, clientSecret). If you use `TextField` controllers, call `setState()` in `onChanged` so the widget rebuilds with the latest inputs.

4) Handling the `onResult` callback:
- For web-based card and bank flows `StripePaymentResult` usually includes `success`, `status`, and `paymentIntentId`.
- For native Apple/Google Pay flows the widget returns a `rawResult` containing the device token (Apple: `paymentDataBase64`; Google: `paymentToken`/`paymentDataJson`). **Send these tokens to your server** and finalize the payment there using your payment gateway's API.

5) Apple Pay & Google Pay setup reminders:
- iOS: enable Apple Pay in Xcode (`Signing & Capabilities`), add the Merchant ID, and test on a physical device using Apple Sandbox testers.
- Android: configure Google Pay console for production and test using `ENVIRONMENT_TEST` on a real Android device.

6) UX guidance:
- Show clear errors for native availability checks (e.g., "Apple Pay is not available on this device").
- UI: The plugin now displays the Apple icon followed by the text `Pay` (icon + label) for Apple Pay and uses the included Google Pay acceptance mark image for Google Pay. The GPay asset is included under `static/assets/GPay_Acceptance_Mark_800.png` and is bundled as a plugin asset. Buttons are white with consistent sizing by default.
 - Global initialization: You can set defaults for merchant ids used by native pay flows by calling:
   ```dart
   LpeConfig.init(
     appleMerchantId: 'merchant.com.yourdomain',
     googleGatewayMerchantId: 'yourGatewayMerchantId',
   );
   ```
   If you provide `merchantId` to `LearmondPayButtons` or directly to `LearmondNativePay.showNativePay`, those values take precedence.
- Provide a fallback flow (card) when native pay is unavailable.

7) Testing & security:
- Always verify amounts & tokens server-side and never finalize a charge from the client alone.
- Log debugging info but never print your secret keys in production logs.

If you want a concrete server-side example for exchanging Apple/Google tokens with Stripe or another gateway, see the server examples near the end of this file and adapt them to your provider.

### Connecting custom buttons to the paysheet logic

If you prefer custom-styled buttons or need programmatic control (for example to fetch a client secret before showing the sheet), follow these patterns.

Imports you'll likely need:

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lpe/lpe.dart';
```

Card / Bank (web paysheet)

1. Create a PaymentIntent on your server and return the `client_secret`.
2. Call `LearmondPaySheet.show(...)` and pass the `clientSecret`.

```dart
final resp = await http.post(
  Uri.parse('https://your-server.example/create-payment-intent'),
  body: jsonEncode({'amount_cents': 1000, 'currency': 'usd'}),
  headers: {'Content-Type': 'application/json'},
);
final clientSecret = jsonDecode(resp.body)['client_secret'];

final result = await LearmondPaySheet.show(
  context: context,
  publishableKey: 'pk_test_...',
  clientSecret: clientSecret,
  method: 'card',
  title: 'Pay \$10.00',
  amount: '10.00',
);
if (result.success) {
  // show confirmation
} else {
  // handle error
}
```

Native device pay (Apple Pay / Google Pay)

Call the native bridge directly and send the returned token to your server for verification and finalization:

```dart
final cents = (double.parse(amountString) * 100).round();
final res = await LearmondNativePay.showNativePay({
  'method': 'apple_pay',
  'merchantId': 'merchant.com.yourdomain',
  'amountCents': cents,
  'currency': 'USD',
});
if (!res.success) {
  // fallback or show error
} else {
  final token = res.rawResult?['paymentDataBase64'];
  await http.post(
    Uri.parse('https://your-server.example/device-pay'),
    body: jsonEncode({'method': 'apple_pay', 'token': token, 'amount_cents': cents}),
    headers: {'Content-Type': 'application/json'},
  );
}
```

Using `LearmondPayButtons`'s `onResult`

If you embed `LearmondPayButtons`, prefer handling payments in the `onResult` callback — the widget will call the correct flow for each method and return a `StripePaymentResult`. For native flows `r.rawResult` contains the device token to send to your server.

```dart
LearmondPayButtons(
  ...,
  onResult: (r) async {
    if (r.success) {
      if (r.rawResult != null) {
        // send r.rawResult to server for verification
      }
      // show success UI
    } else {
      // show r.error
    }
  },
)
```

UX tips

- Disable the button that launches a flow while an operation is in progress to prevent double submissions.
- Provide a clear fallback to card entry if native pay is unavailable.
- Always validate amounts and tokens on your server and never finalize charges from the client.

### 4. Handle the Result
- `result.success`: `true` if payment succeeded.
- `result.status`: Payment status string.
- `result.paymentIntentId`: Payment intent ID.
- `result.error`: Error message if any.
- `result.rawResult`: Full payment response.

### 5. Supported Payment Methods
- `'card'`: Card entry via secure payment element.
- `'us_bank'`: US bank account (ACH).
- `'eu_bank'`: EU bank (SEPA/IBAN).
- `'apple_pay'`, `'google_pay'`: Payment Request Button (if supported).
- `'source_pay'`,: Source Pay

### 6. Customization
- You can set `title`, `amount`, and `buttonLabel` for the sheet.
- The modal sheet size can be adjusted with `initialChildSize`, `minChildSize`, and `maxChildSize`.

### 7. Requirements
- You must provide a valid publishable key and client secret from your payment provider.
- Your backend should create payment intents and provide the client secret.

### 8. Example
See the README and example folder for a full integration.

See the README and the `example/` app for a full integration. To run the included example:

```bash
cd lpe/example
flutter pub get
flutter run
```

The example demonstrates embedding `LearmondPayButtons` with live input fields for amount, publishable key, client secret, and merchant ID.
## Native Pay (Apple Pay / Google Pay) — Setup & Usage

This package exposes a native MethodChannel bridge (`lpe/native_pay`) so apps can present device-native pay flows without performing on-device Stripe confirmation. The native flows return device tokens which your backend must exchange/confirm with your chosen payment gateway.

Summary of behavior
- iOS (Apple Pay): presents `PKPaymentAuthorizationController`, returns the Apple payment token as base64 (`raw.paymentDataBase64`) and metadata (transaction identifier, payment method). Does NOT use Stripe on-device.
- Android (Google Pay): launches Google Pay `PaymentDataRequest`, returns the tokenization payload (`raw.paymentToken`) and the full `paymentDataJson`. Does NOT use Stripe on-device.

Important: These native flows intentionally do not confirm payments on-device. Your server must accept the returned token and create/confirm a charge or PaymentIntent with your gateway.

1) iOS (Xcode) setup
- Add an Apple Merchant ID in Apple Developer portal (e.g. `merchant.com.yourdomain`).
- In Xcode enable the Apple Pay capability for your app target and add the Merchant ID to the entitlements.
- Ensure the app's bundle identifier is configured for Apple Pay and the provisioning profile includes the merchant.
- When calling the plugin from Dart pass `merchantId` in the `presentNativePay` args. Example:

```dart
final res = await LearmondNativePay.showNativePay({
  'method': 'apple_pay',
  'merchantId': 'merchant.com.yourdomain',
  'amountCents': 1000,
  'currency': 'USD',
  'country': 'US',
});
```

On success `res.raw['paymentDataBase64']` will contain the Apple payment token (PKPaymentToken.paymentData) encoded in base64.

Server-side handling (recommended): send the base64 token to your server; the server should decode and exchange the Apple token with your payment provider (e.g., create/confirm a PaymentIntent with Stripe, or call your gateway's Apple Pay verification endpoint). Do not attempt to finalize the charge from the client.

2) Android (Gradle / Google Pay) setup
- Add Google Play Services Wallet dependency to your app-level `build.gradle` only if you
  explicitly need to control the version. Most apps can rely on the plugin declaring this
  dependency; declare it at the app level only when you need a specific version. If you do, ensure the
  version is aligned with the plugin to avoid manifest/resource merge issues:

```gradle
dependencies {
  implementation 'com.google.android.gms:play-services-wallet:19.2.0' // keep versions aligned
}
```

If your build fails with manifest/resource merge errors that reference `play-services-wallet`, check
for duplicate declarations (plugin + app) and prefer a single declaration with aligned versions to
avoid conflicts.

- Configure Google Pay in the Google Pay Console for production. For testing use the `ENVIRONMENT_TEST` setup provided in the plugin.
- The plugin builds a `PaymentDataRequest` with `PAYMENT_GATEWAY` tokenization placeholders. Replace `gateway` / `gatewayMerchantId` with your payment gateway values (or implement direct tokenization if supported).

Example Dart call (Google Pay):

```dart
final res = await LearmondNativePay.showNativePay({
  'method': 'google_pay',
  'amountCents': 1000,
  'currency': 'USD',
});
```

On success `res.raw['paymentToken']` will contain the tokenization `token` string; `res.raw['paymentDataJson']` has the full JSON returned by Google Pay. Send the `paymentToken`/JSON to your server for verification and processing.

3) Backend: exchanging device tokens
- Apple Pay: decode `paymentDataBase64` then call your payment processor's Apple Pay endpoint to create/confirm a payment. Example with Stripe (server-side): use `stripe.tokens.create({client_secret, ...})` or create a PaymentMethod from the Apple Pay token and confirm a PaymentIntent server-side.
- Google Pay: the tokenization payload returned must be exchanged with the gateway. If using `PAYMENT_GATEWAY` tokenization with Stripe, you'll receive a Stripe token payload that the server can use to create/confirm a PaymentIntent.
- Always validate amounts and metadata server-side and never rely on client-supplied amount values for final charge amounts.

4) Plugin registration & pubspec
- The `lpe` package declares plugin platforms in `pubspec.yaml` (android package `com.learmond.lpe`, plugin class `LearmondNativePayPlugin`). Ensure the package structure matches the `package` value on Android and `ios/Classes` contains the Swift file.
- Confirm the `example/` app demonstrates calling `LearmondNativePay.showNativePay(...)` for both methods.

Optional: initialize global merchant ids
--------------------------------------
If you prefer to set default merchant ids (Apple or Google) application-wide, you may call `LpeConfig.init` at app startup before calling `runApp(...)`. `LearmondPayButtons` will use these defaults for native pay flows when explicit merchant ids are not supplied.

Example:

```dart
void main() {
  // IMPORTANT: Do NOT commit real merchant IDs in your app's source if the
  // repository is public or the package will be published. Use placeholders
  // during development and set real values via CI or private configuration
  // at build/deploy time.
  // LpeConfig.init(
  //   appleMerchantId: 'merchant.com.example',
  //   googleGatewayMerchantId: 'yourGatewayMerchantId',
  // );
  runApp(const MyApp());
}
```

5) Fallbacks & UX
- The package also provides a WebView-based Payment Request Button as a fallback. If native availability checks fail, detect and gracefully fall back to the WebView flow.
- Surface clear messages to users when native pay is unavailable (e.g., "Apple Pay is not available — add a card to Wallet" or "Google Pay not configured on this device").

## Example server snippet (Node/Express) — receive Apple/Google token and confirm with Stripe
This is a simple example that shows how your server might accept the token and confirm a PaymentIntent with Stripe. Adjust to your gateway.

```js
// POST /api/device-pay
// body: { method: 'apple_pay'|'google_pay', token: '<token>', amount_cents: 1000, currency: 'usd' }
app.post('/api/device-pay', async (req, res) => {
  const { method, token, amount_cents, currency } = req.body;
  try {
    // Create PaymentIntent server-side and confirm with the token as payment_method
    const pi = await stripe.paymentIntents.create({
      amount: amount_cents,
      currency,
      payment_method_data: {
        type: 'card',
        // If your gateway supports direct tokenized device payment objects,
        // attach the token payload here according to the gateway's API.
      },
      confirm: true,
    });
    res.json({ success: true, paymentIntent: pi });
  } catch (e) {
    res.status(500).json({ success: false, error: e.message });
  }
});
```

Note: The exact server-side flow depends on your gateway. For Stripe you may need to create a `PaymentMethod` from the device token or use `stripe.tokens.create` with the token payload first.

## QA & Testing Recommendations
- Test Apple Pay on a real iOS device with Apple Sandbox tester accounts or cards.
- Test Google Pay on a real Android device with Google Pay configured; use `ENVIRONMENT_TEST` for early testing.
- Verify the `example/` app demonstrates both device flows and the fallback WebView flow.
- Log debug info (careful not to print secrets) to help troubleshoot device availability issues.

## Advanced
The package uses a WebView to securely render payment elements and handle payment confirmation.
Communication between Flutter and JS is handled via `window.flutter_inappwebview.callHandler('paymentCallback', {...})`.
- You can extend or customize the UI by modifying the modal sheet or WebView widget.

### Troubleshooting

- If `flutter analyze` reports `The name 'LpeConfig' is defined in the libraries ... ambiguous_export`, check `lib/lpe.dart` and ensure it's exporting symbols explicitly via `show` or by only exporting the files needed. For example:

  ```dart
  export 'lpe_config.dart' show LpeConfig;
  export 'paysheet.dart' show LearmondPaySheet, LearmondNativePay, LearmondPayButtons, StripePaymentResult;
  ```

## License
MIT

## Author
The Learmond Corporation
