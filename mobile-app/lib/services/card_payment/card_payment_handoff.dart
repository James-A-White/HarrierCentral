import 'package:harrier_central/imports.dart';

/// Taking a card at the trail by handing the amount to the kennel's own SumUp
/// app (E8.F7.S1, James 2026-09-26).
///
/// Harrier Central never touches the card or the money. It hands SumUp's app
/// an amount, a currency, a title and our payment id; SumUp takes the card
/// with whatever the Hash Cash's phone has — Tap to Pay on the phone, or a
/// Solo / Air reader paired with the SumUp app — and opens
/// `harriercentral://sumup-result?...` to say how it went.
///
/// The ledger side needs no new payment kind:
/// 1. **Before** leaving, a MARKER row is written (hcapp_processPayment 1.7.0:
///    paymentType 1 + provider `sumup` + our id). It reads "not paid" on every
///    client and moves no balance, and it is there even if SumUp never
///    answers.
/// 2. **Success**: an ordinary paymentType 3 with provider `sumup` and
///    SumUp's transaction code as the reference. The server cancels the marker
///    and records the money exactly as it does for cash.
/// 3. **Failure**: an ordinary "not paid", which cancels the marker.
///
/// Both answers have ids derived from the marker's, so SumUp returning twice
/// is a server-side replay that writes nothing.
///
/// What this CANNOT know: which SumUp account took the money. SumUp's
/// callback carries no merchant code, so the club's code is shown before the
/// hand-off and the provider export (E8.F7.S3) is where a payment taken on a
/// personal account is caught.
class CardPaymentHandoff {
  CardPaymentHandoff._();

  static const String provider = 'sumup';
  static const String callbackHost = 'sumup-result';
  static const String callbackUrl = 'harriercentral://$callbackHost';

  /// A hand-off nobody answered within this long is forgotten locally; its
  /// marker stays on the server as "not paid · sumup" for the Hash Cash.
  static const Duration forgetAfter = Duration(hours: 24);

  /// Whether this kennel takes card through SumUp from this build.
  static bool isOfferedFor(KennelsModel kennel) =>
      SUMUP_AFFILIATE_KEY.isNotEmpty &&
      (kennel.cardPaymentProvider ?? '').trim().toLowerCase() == provider;

  // ── Pure: the request and the answer ─────────────────────────────────────

  /// SumUp's Payment Switch request. iOS and Android differ: Android names
  /// the amount `total` (`amount` is deprecated there) and needs our app id
  /// and a single `callback`; iOS takes `amount` and separate success and
  /// failure callbacks.
  static Uri buildRequest({
    required String affiliateKey,
    required double amount,
    required int digitsAfterDecimal,
    required String currency,
    required String title,
    required String foreignTxId,
    required bool android,
    String appId = SUMUP_APP_ID,
  }) {
    final String amountText = amount.toStringAsFixed(
      digitsAfterDecimal.clamp(0, 3),
    );
    final Map<String, String> q = <String, String>{
      'affiliate-key': affiliateKey,
      'currency': currency.trim().toUpperCase(),
      'title': title,
      'foreign-tx-id': foreignTxId,
    };
    if (android) {
      q['app-id'] = appId;
      q['total'] = amountText;
      q['callback'] = callbackUrl;
    } else {
      q['amount'] = amountText;
      q['callbacksuccess'] = callbackUrl;
      q['callbackfail'] = callbackUrl;
    }
    return Uri(
      scheme: 'sumupmerchant',
      host: 'pay',
      path: '/1.0',
      queryParameters: q,
    );
  }

  static bool isCallback(Uri uri) =>
      uri.scheme.toLowerCase() == 'harriercentral' &&
      uri.host.toLowerCase() == callbackHost;

  /// Reads SumUp's answer. Null when it is not one.
  static SumUpResult? parseCallback(Uri uri) {
    if (!isCallback(uri)) return null;
    final Map<String, String> q = uri.queryParameters;
    final String status = (q['smp-status'] ?? '').toLowerCase();
    return SumUpResult(
      success: status == 'success',
      status: status,
      transactionCode: _blankToNull(q['smp-tx-code']),
      foreignTxId: _blankToNull(q['foreign-tx-id'])?.toLowerCase(),
      message: _blankToNull(q['smp-message']) ??
          _blankToNull(q['smp-failure-cause']),
    );
  }

  /// The paid row's id and the cancel row's id, both derived from the
  /// marker's so a repeated answer is a replay, never a second payment.
  static String paidIdFor(String markerId) =>
      const Uuid().v5(Namespace.url.value, 'hc-card-paid:$markerId');
  static String cancelIdFor(String markerId) =>
      const Uuid().v5(Namespace.url.value, 'hc-card-cancel:$markerId');

  /// SumUp's transaction code as our payment reference (50 characters max on
  /// HC.Payment; `SU:` keeps it apart from the `HC:` references).
  static String? referenceFor(String? transactionCode) {
    final String code = (transactionCode ?? '').trim();
    if (code.isEmpty) return null;
    final String ref = 'SU:$code';
    return ref.length > 50 ? ref.substring(0, 50) : ref;
  }

  static String? _blankToNull(String? s) =>
      (s == null || s.trim().isEmpty) ? null : s.trim();

  // ── The flow ─────────────────────────────────────────────────────────────

  /// Hands [paid] (a paymentType 3 run-fee capture built as for cash) to
  /// SumUp for [amount]. Returns false when nothing was handed off.
  static Future<bool> start({
    required PendingPayment paid,
    required double amount,
    required int digitsAfterDecimal,
    required String currency,
    required String amountLabel,
    required String payerName,
    required String title,
    String? merchantCode,
  }) async {
    if (SUMUP_AFFILIATE_KEY.isEmpty) return false;

    final Uri probe = Uri(scheme: 'sumupmerchant', host: 'pay', path: '/1.0');
    if (!await canLaunchUrl(probe)) {
      await Utilities.showAlert(
        'SumUp app needed',
        'Card payments go through the SumUp app. Install it on this phone and '
            'sign in to the club\'s SumUp account, then try again.',
        'OK',
      );
      return false;
    }

    final String code = (merchantCode ?? '').trim();
    final bool? go = await Utilities.showAlert(
      'Take $amountLabel by card?',
      '$payerName pays $amountLabel with SumUp.\n\n'
          '${code.isEmpty ? 'Check the SumUp app is signed in to the CLUB\'s account.' : 'Check the SumUp app is signed in to the club\'s account, $code.'} '
          'A payment taken on a personal account goes to that account.',
      'Open SumUp',
      showCancelButton: true,
    );
    if (go != true) return false;

    final String markerId = paid.clientPaymentId.toLowerCase();
    final Map<String, dynamic> paidJson = paid.toJson()
      ..['clientPaymentId'] = paidIdFor(markerId)
      ..['paymentType'] = paymentCash.value
      ..['paymentProvider'] = provider;
    final Map<String, dynamic> markerJson = paid.toJson()
      ..['clientPaymentId'] = markerId
      ..['paymentType'] = paymentNotPaid.value
      ..['paymentProvider'] = provider
      ..['paymentReference'] = null
      ..['displayLabel'] = 'Card via SumUp started — $payerName';
    final Map<String, dynamic> cancelJson = paid.toJson()
      ..['clientPaymentId'] = cancelIdFor(markerId)
      ..['paymentType'] = paymentNotPaid.value
      ..['paymentProvider'] = null
      ..['paymentReference'] = null
      ..['displayLabel'] = 'Card via SumUp did not go through — $payerName';

    // The marker lands BEFORE the hand-off. Offline there is no point
    // leaving: SumUp needs a connection too, and a queued marker arriving
    // later would only confuse the list.
    final PaymentOutboxService outbox = Get.find<PaymentOutboxService>();
    final PaymentSubmitOutcome marked =
        await outbox.submit(PendingPayment.fromJson(markerJson));
    if (marked.queued) {
      await outbox.discard(markerId);
      showHcSnackbar(
        'No connection — a card payment needs one. Nothing was charged.',
        isError: true,
      );
      return false;
    }
    if (firstRow(marked.results) == null) return false;

    await _remember(markerId, <String, dynamic>{
      'paid': paidJson,
      'cancel': cancelJson,
      'payer': payerName,
      'amountLabel': amountLabel,
      'createdAtMs': DateTime.now().millisecondsSinceEpoch,
    });

    final Uri request = buildRequest(
      affiliateKey: SUMUP_AFFILIATE_KEY,
      amount: amount,
      digitsAfterDecimal: digitsAfterDecimal,
      currency: currency,
      title: title,
      foreignTxId: markerId,
      android: GetPlatform.isAndroid,
    );
    BootLogger.logBreadcrumb('[CardPayment] handing $markerId to SumUp');
    final bool launched = await launchUrl(
      request,
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      await _answer(markerId, success: false, reason: 'SumUp did not open');
      return false;
    }
    return true;
  }

  /// SumUp's answer, from DeepLinkService. Safe to call more than once.
  static Future<void> handleCallback(Uri uri) async {
    final SumUpResult? r = parseCallback(uri);
    if (r == null) return;
    BootLogger.logBreadcrumb(
      '[CardPayment] SumUp answered ${r.status} for ${r.foreignTxId}',
    );
    final String? markerId = r.foreignTxId;
    if (markerId == null) {
      showHcSnackbar(
        'SumUp sent back a result Harrier Central cannot match. Check the '
        'SumUp app for the payment.',
        isError: true,
      );
      return;
    }
    await _answer(
      markerId,
      success: r.success,
      transactionCode: r.transactionCode,
      reason: r.message,
    );
  }

  static Future<void> _answer(
    String markerId, {
    required bool success,
    String? transactionCode,
    String? reason,
  }) async {
    final Map<String, dynamic>? ctx = _recall(markerId);
    if (ctx == null) {
      // Already answered (SumUp returned twice), or the app was reinstalled.
      // The server rows are the truth either way.
      BootLogger.logBreadcrumb('[CardPayment] no hand-off $markerId on this phone');
      return;
    }
    final String payer = ctx['payer'] as String? ?? 'the hasher';
    final String amountLabel = ctx['amountLabel'] as String? ?? '';
    final Map<String, dynamic> json = Map<String, dynamic>.from(
      (success ? ctx['paid'] : ctx['cancel']) as Map,
    );
    if (success) json['paymentReference'] = referenceFor(transactionCode);

    final PaymentSubmitOutcome outcome = await Get.find<PaymentOutboxService>()
        .submit(PendingPayment.fromJson(json));
    await _forget(markerId);

    if (success) {
      showHcSnackbar(
        outcome.queued
            ? 'Card payment of $amountLabel for $payer taken — it will be '
                  'recorded when the connection is back.'
            : 'Card payment of $amountLabel for $payer recorded.',
      );
    } else {
      showHcSnackbar(
        'Card payment for $payer did not go through'
        '${(reason ?? '').isEmpty ? '' : ' ($reason)'}. Nothing was recorded.',
        isError: true,
      );
    }

    if (Get.isRegistered<CheckInPackController>()) {
      final CheckInPackController c = Get.find<CheckInPackController>();
      if (!c.isClosed) await c.refreshPackListFromTables(false);
    }
  }

  // ── Hand-offs awaiting an answer, kept across an app restart ─────────────

  static Map<String, dynamic> _all() {
    try {
      final String raw = getStringPref(StringPrefsEnum.cardHandoffJson) ?? '';
      if (raw.isEmpty) return <String, dynamic>{};
      final Map<String, dynamic> m = Map<String, dynamic>.from(
        jsonDecode(raw) as Map,
      );
      final int cutoff =
          DateTime.now().subtract(forgetAfter).millisecondsSinceEpoch;
      m.removeWhere(
        (String _, dynamic v) =>
            ((v as Map)['createdAtMs'] as num? ?? 0) < cutoff,
      );
      return m;
    } catch (e, s) {
      BootLogger.logError('[CardPayment]', 'hand-off store unreadable: $e', s);
      return <String, dynamic>{};
    }
  }

  static Map<String, dynamic>? _recall(String markerId) {
    final dynamic v = _all()[markerId.toLowerCase()];
    return v == null ? null : Map<String, dynamic>.from(v as Map);
  }

  static Future<void> _remember(String id, Map<String, dynamic> ctx) async {
    final Map<String, dynamic> m = _all()..[id.toLowerCase()] = ctx;
    await setStringPref(StringPrefsEnum.cardHandoffJson, jsonEncode(m));
  }

  static Future<void> _forget(String id) async {
    final Map<String, dynamic> m = _all()..remove(id.toLowerCase());
    await setStringPref(StringPrefsEnum.cardHandoffJson, jsonEncode(m));
  }
}

/// SumUp's answer to a Payment Switch request.
class SumUpResult {
  const SumUpResult({
    required this.success,
    required this.status,
    this.transactionCode,
    this.foreignTxId,
    this.message,
  });

  final bool success;

  /// `success`, `failed` or `invalidstate`, as SumUp sent it.
  final String status;
  final String? transactionCode;
  final String? foreignTxId;
  final String? message;
}
