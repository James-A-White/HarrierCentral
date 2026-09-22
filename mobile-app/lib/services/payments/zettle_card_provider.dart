import 'package:zettle_sdk/zettle_sdk.dart';

import 'package:harrier_central/services/payments/card_payment_provider.dart';
import 'package:harrier_central/util/boot_logger.dart';
import 'package:harrier_central/util/enums.dart';

/// Zettle by PayPal — the [CardPaymentMode.sdk] half of E8.F7.
///
/// The tap happens inside Harrier Central: the merchant authorises once by
/// OAuth and the SDK draws the payment sheet over our app. Money still settles
/// to the kennel's own Zettle account — Harrier Central is not the merchant of
/// record and never holds the funds — but unlike the SumUp hand-off we DO hold
/// the merchant's session, which is the trade this mode makes.
///
/// Three things about this integration are worth knowing before changing it:
///
/// 1. **`charge` takes no currency.** The amount is charged in whatever
///    currency the signed-in Zettle account settles in. If that is not the
///    kennel's `CurrencyCode` the hasher is charged the right number in the
///    wrong money, silently. The caller must check them against each other;
///    this class cannot, because the SDK does not say what the account's
///    currency is.
///
/// 2. **The result carries no merchant identity.** `PaymentResult` is
///    reference, amount, card brand, cardholder name and masked PAN — so the
///    wrong-account guard in E8.F7.S2 cannot run for Zettle the way it does
///    for SumUp, whose callback returns the merchant code. Until the plugin
///    exposes the account (a fork would; it is BSD-3), the guard for Zettle
///    has to be the authorisation step itself: whoever connects the kennel
///    chooses the account once, deliberately, on the config screen.
///
/// 3. **`referenceId` is OUR reference coming back, not Zettle's id.** That is
///    what we want — the same trick as SumUp's foreign transaction id — but it
///    means `PaymentReference` holds a value we minted, and the provider's own
///    transaction id is only in their export.
class ZettleCardProvider implements CardPaymentProvider {
  ZettleCardProvider({
    required this.clientId,
    required this.redirectUrl,
    this.devMode = false,
    ZettleSdk? sdk,
  }) : _sdk = sdk ?? ZettleSdk();

  final ZettleSdk _sdk;

  /// From Zettle's developer portal. Not a secret — it identifies the app in
  /// an OAuth flow the merchant completes themselves.
  final String clientId;

  /// Must match the scheme registered in Info.plist and AndroidManifest.
  final String redirectUrl;

  final bool devMode;

  bool _initialised = false;

  @override
  String get providerToken => CardPaymentProviders.zettle;

  @override
  CardPaymentMode get mode => CardPaymentMode.sdk;

  Future<void> _ensureInitialised() async {
    if (_initialised) return;
    await _sdk.initialize(
      ZettleConfig(
        clientId: clientId,
        redirectUrl: redirectUrl,
        isDevMode: devMode,
      ),
    );
    _initialised = true;
  }

  @override
  Future<bool> isReady() async {
    try {
      await _ensureInitialised();
      return await _sdk.isLoggedIn();
    } catch (e, s) {
      BootLogger.logError('[ERROR][PAY]', 'Zettle isReady failed: $e', s);
      return false;
    }
  }

  @override
  Future<bool> connect() async {
    try {
      await _ensureInitialised();
      if (await _sdk.isLoggedIn()) return true;
      await _sdk.login();
      return await _sdk.isLoggedIn();
    } catch (e, s) {
      BootLogger.logError('[ERROR][PAY]', 'Zettle login failed: $e', s);
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      await _ensureInitialised();
      await _sdk.logout();
    } catch (e, s) {
      BootLogger.logError('[ERROR][PAY]', 'Zettle logout failed: $e', s);
    }
  }

  @override
  Future<CardPaymentOutcome> takePayment({
    required int amountMinorUnits,
    required String reference,
    String? description,
  }) async {
    try {
      await _ensureInitialised();
    } catch (e, s) {
      BootLogger.logError('[ERROR][PAY]', 'Zettle initialise failed: $e', s);
      // Nothing was charged: the sheet never opened.
      return CardPaymentOutcome(
        status: CardPaymentStatus.failed,
        message: 'Card payments are not set up on this phone.',
      );
    }

    try {
      final PaymentResult result = await _sdk.charge(
        amount: amountMinorUnits,
        reference: reference,
      );
      return CardPaymentOutcome(
        status: CardPaymentStatus.paid,
        providerReference: result.referenceId ?? reference,
        cardBrand: result.cardBrand,
        maskedPan: result.obfuscatedPan,
      );
    } on ZettleException catch (e, s) {
      // Zettle said no. A decline or a cancel is a real answer: no money moved.
      BootLogger.logError('[ERROR][PAY]', 'Zettle charge refused: ${e.message}', s);
      return CardPaymentOutcome(
        status: CardPaymentStatus.failed,
        message: e.message,
      );
    } catch (e, s) {
      // Anything else and we genuinely do not know. The payment row stays
      // pending; recoverPayment or the reconciliation import settles it.
      BootLogger.logError('[ERROR][PAY]', 'Zettle charge outcome unknown: $e', s);
      return CardPaymentOutcome(
        status: CardPaymentStatus.unknown,
        providerReference: reference,
        message: '$e',
      );
    }
  }

  @override
  Future<CardPaymentOutcome> recoverPayment(String reference) async {
    try {
      await _ensureInitialised();
      final PaymentResult result = await _sdk.retrievePaymentInfo(reference);
      return CardPaymentOutcome(
        status: CardPaymentStatus.paid,
        providerReference: result.referenceId ?? reference,
        cardBrand: result.cardBrand,
        maskedPan: result.obfuscatedPan,
      );
    } on ZettleException catch (e) {
      // Zettle has no payment under that reference. It is not proof that none
      // was taken — an unsynced reader, or their own lag, looks identical —
      // so this stays unknown rather than becoming a failure.
      return CardPaymentOutcome(
        status: CardPaymentStatus.unknown,
        message: e.message,
      );
    } catch (e, s) {
      BootLogger.logError('[ERROR][PAY]', 'Zettle recover failed: $e', s);
      return CardPaymentOutcome(
        status: CardPaymentStatus.unknown,
        message: '$e',
      );
    }
  }
}
