## 0.0.2+4

* Initial release of LPE (Learmond Pay Element) with Source Pay.
* Provides a reusable payment sheet for Flutter apps.
* Built on Stripe.
* Supports card, US bank, EU bank, Apple Pay, and Google Pay payments.
* Modal bottom sheet UI and secure WebView-based payment collection.
* Easy API for payment confirmation and result handling.
* Uses Native Apple Pay and Google Pay functions. 
* Includes Source Pay to call Source Pay API.
* Add `LearmondPayButtons` - a single-line widget that renders Card/Bank and native pay buttons in a 3+2 layout (3 buttons on the top row (Card, US Bank, EU Bank), 2 centered on the bottom row (Apple Pay, Google Pay)).
* Features individual Source Pay button.
* Call LPE_config.init to set your apple and google merchant IDs.
* Consistent button sizing and layout. 
* Improved README and INSTRUCTIONS with widget usage examples and setup notes for Apple/Google native pay.
