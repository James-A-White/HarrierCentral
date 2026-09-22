import 'package:harrier_central/util/enums.dart';

/// How a provider is reached. This — not the provider's name — is what the
/// seam exists for (E8.F7.S2).
///
/// * [handoff] — SumUp. We open THEIR app with an amount and a reference, the
///   tap happens on their screen, and a callback brings the result back. We
///   hold one app-wide affiliate key, no merchant credentials, and never see
///   a card.
/// * [sdk] — Zettle. Their SDK runs inside THIS app, the merchant authorises
///   once by OAuth, and the tap happens on our screen.
///
/// A design that assumed one of these would have to be torn up for the other,
/// so both are described by the same interface and produce the same
/// [CardPaymentOutcome].
enum CardPaymentMode { handoff, sdk }

/// What happened, from Harrier Central's point of view rather than the
/// provider's.
enum CardPaymentStatus {
  /// The provider confirmed the money moved.
  paid,

  /// The provider said no — declined, cancelled, reader failure.
  failed,

  /// We do not know. The app was killed, the callback never arrived, the
  /// result could not be read. **This is not a failure**: the money may well
  /// have moved, and the pending payment row must stay pending until a
  /// recovery or the reconciliation import settles it.
  unknown,
}

/// The result of asking a provider for money, in our terms.
class CardPaymentOutcome {
  const CardPaymentOutcome({
    required this.status,
    this.providerReference,
    this.merchantId,
    this.cardBrand,
    this.maskedPan,
    this.message,
  });

  final CardPaymentStatus status;

  /// What the provider calls this transaction. Stored on
  /// HC.Payment.PaymentReference and used to join their statement to our
  /// ledger.
  final String? providerReference;

  /// Which merchant account took the money, where the provider tells us.
  ///
  /// Compared against HC.Kennel.PaymentMerchantCode so a payment taken on a
  /// Hash Cash's PERSONAL account is refused rather than confirmed. **Null
  /// means the provider did not say**, and the guard cannot run — see
  /// [ZettleCardProvider] for why that is the case today.
  final String? merchantId;

  final String? cardBrand;
  final String? maskedPan;

  /// Why it failed or why it is unknown, for the log and the Hash Cash.
  final String? message;

  bool get isPaid => status == CardPaymentStatus.paid;
}

/// Taking a card payment, whichever app actually does it.
///
/// Implementations must never move money without a pending HC.Payment row
/// already written: once we hand off — or open a reader sheet — we may never
/// get control back, and a payment nobody recorded is a hole in the club's
/// accounts rather than a missing tick.
abstract class CardPaymentProvider {
  /// The token this provider is known by, everywhere: the kennel's
  /// HC.Kennel.CardPaymentProvider, the HC.Payment.PaymentProvider written
  /// with each payment, and the provider's own export. Lowercase — see
  /// [CardPaymentProviders].
  String get providerToken;

  CardPaymentMode get mode;

  /// Whether this provider can take a payment right now: configured,
  /// authorised, and with whatever hardware it needs.
  Future<bool> isReady();

  /// Ask the merchant to authorise, if this provider needs it. A [handoff]
  /// provider has nothing to do here — the club is signed into its own app.
  Future<bool> connect();

  /// Take [amountMinorUnits] against [reference], which is the
  /// `clientPaymentId` of the pending payment row. Passing our own id to the
  /// provider is what lets their statement be joined to our ledger later.
  Future<CardPaymentOutcome> takePayment({
    required int amountMinorUnits,
    required String reference,
    String? description,
  });

  /// Ask the provider what became of [reference] after the fact.
  ///
  /// This is how a [CardPaymentStatus.unknown] is resolved without waiting for
  /// the reconciliation import — where the provider offers it at all. A
  /// provider that cannot answer returns [CardPaymentStatus.unknown] again,
  /// and the row stays pending.
  Future<CardPaymentOutcome> recoverPayment(String reference);
}
