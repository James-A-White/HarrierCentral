import 'package:harrier_central/imports.dart';

/// One payment request captured on this phone, kept in the payment outbox
/// until the server acknowledges it (see PaymentOutboxService).
///
/// [clientPaymentId] doubles as the server-side Payment row's id — the SP's
/// idempotency key (processPayment 1.5.0). Every retry sends the SAME id, so
/// a request whose response was lost can be re-sent safely: the server
/// answers "already processed" instead of recording a second charge.
///
/// The access token is NOT stored — it is minted fresh on every send attempt
/// from the device secret plus [hasherEventMapId] and [paymentAmount], both
/// of which are persisted here, so a retry hours later still authenticates.
class PendingPayment {
  PendingPayment({
    required this.clientPaymentId,
    required this.createdAtMs,
    required this.eventId,
    required this.hasherId,
    required this.hasherEventMapId,
    required this.paymentType,
    required this.paymentAmount,
    required this.minimumAttendenceValue,
    required this.doPayForExtrasValue,
    required this.appDomainTypeStr,
    required this.productTypeValue,
    required this.displayLabel,
    this.surcharge,
    this.paymentProvider,
    this.paymentReference,
    this.specialRunPrice,
    this.specialRunPriceReason,
    this.useSpecialPriceAsDefault,
    this.notes,
    this.alsoPayRunFee = false,
    this.attempts = 0,
  });

  /// Lowercase UUID, generated at capture. Server-side Payment.id.
  final String clientPaymentId;
  final int createdAtMs;

  final String eventId;
  final String? hasherId;
  final String? hasherEventMapId;
  final int paymentType;
  final double paymentAmount;
  final int minimumAttendenceValue;
  final int doPayForExtrasValue;

  /// AppDomainType.toString() — parsed back via [appDomainType].
  final String appDomainTypeStr;
  final int productTypeValue;

  final double? surcharge;
  final String? paymentProvider;
  final String? paymentReference;
  final double? specialRunPrice;
  final String? specialRunPriceReason;
  final bool? useSpecialPriceAsDefault;
  final String? notes;
  final bool alsoPayRunFee;

  /// Human line for snackbars/banners, e.g. "Opee — cash £5 (run fee)".
  final String displayLabel;

  int attempts;

  AppDomainType get appDomainType => AppDomainType.values.firstWhere(
    (AppDomainType e) => e.toString() == appDomainTypeStr,
    orElse: () => AppDomainType.event,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'clientPaymentId': clientPaymentId,
    'createdAtMs': createdAtMs,
    'eventId': eventId,
    'hasherId': hasherId,
    'hasherEventMapId': hasherEventMapId,
    'paymentType': paymentType,
    'paymentAmount': paymentAmount,
    'minimumAttendenceValue': minimumAttendenceValue,
    'doPayForExtrasValue': doPayForExtrasValue,
    'appDomainTypeStr': appDomainTypeStr,
    'productTypeValue': productTypeValue,
    'surcharge': surcharge,
    'paymentProvider': paymentProvider,
    'paymentReference': paymentReference,
    'specialRunPrice': specialRunPrice,
    'specialRunPriceReason': specialRunPriceReason,
    'useSpecialPriceAsDefault': useSpecialPriceAsDefault,
    'notes': notes,
    'alsoPayRunFee': alsoPayRunFee,
    'displayLabel': displayLabel,
    'attempts': attempts,
  };

  factory PendingPayment.fromJson(Map<String, dynamic> json) => PendingPayment(
    clientPaymentId: json['clientPaymentId'] as String,
    createdAtMs: (json['createdAtMs'] as num).toInt(),
    eventId: json['eventId'] as String,
    hasherId: json['hasherId'] as String?,
    hasherEventMapId: json['hasherEventMapId'] as String?,
    paymentType: (json['paymentType'] as num).toInt(),
    paymentAmount: (json['paymentAmount'] as num).toDouble(),
    minimumAttendenceValue: (json['minimumAttendenceValue'] as num).toInt(),
    doPayForExtrasValue: (json['doPayForExtrasValue'] as num).toInt(),
    appDomainTypeStr: json['appDomainTypeStr'] as String,
    productTypeValue: (json['productTypeValue'] as num).toInt(),
    surcharge: (json['surcharge'] as num?)?.toDouble(),
    paymentProvider: json['paymentProvider'] as String?,
    paymentReference: json['paymentReference'] as String?,
    specialRunPrice: (json['specialRunPrice'] as num?)?.toDouble(),
    specialRunPriceReason: json['specialRunPriceReason'] as String?,
    useSpecialPriceAsDefault: json['useSpecialPriceAsDefault'] as bool?,
    notes: json['notes'] as String?,
    alsoPayRunFee: json['alsoPayRunFee'] == true,
    displayLabel: (json['displayLabel'] as String?) ?? 'payment',
    attempts: (json['attempts'] as num?)?.toInt() ?? 0,
  );
}

/// Outcome of one send attempt for a [PendingPayment].
class PaymentSendResult {
  PaymentSendResult(this.rawResponse, this.results);

  /// The sendHttpPost return value: response JSON on success, an
  /// `HC_ERROR_*` sentinel otherwise.
  final String rawResponse;

  /// Parsed sync/adHocData results when [delivered]; empty otherwise.
  final List<dynamic> results;

  /// The server acknowledged the payment (recorded now, or an idempotent
  /// replay of one recorded earlier). This is the ONLY state that removes
  /// an entry from the outbox.
  bool get delivered => !rawResponse.startsWith(ERROR_PREFIX);

  /// The request may never have reached the server (no connection, timeout,
  /// transport failure, exhausted retries). Safe to retry later — the
  /// idempotency key makes a duplicate send harmless.
  bool get transportFailure =>
      rawResponse == ERROR_NO_CONNECTION ||
      rawResponse == ERROR_UNKNOWN_HTTP_ERROR;

  /// The server actively rejected the request (validation/auth error). A
  /// retry will fail the same way — the entry must NOT stay queued.
  bool get rejected => !delivered && !transportFailure;
}
