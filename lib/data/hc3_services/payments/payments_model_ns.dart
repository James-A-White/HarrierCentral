import 'package:harrier_central/imports.dart';

part 'payments_model_ns.freezed.dart';
part 'payments_model_ns.g.dart';

@freezed
class PaymentsModel with _$PaymentsModel implements BaseModel {
  factory PaymentsModel({
    required String paymentId,
    required String kennelId,
    required String paidBy,
    required String hemId,
    required String eventId,
    required String paidTo,
    required double creditAmount,
    required double debitAmount,
    double? creditAvailable,
    required DateTime paidDate,
    required int paymentType,
    required int productType,
    DateTime? cancelledDate,
    String? cancelledBy,
    DateTime? confirmedDate,
    String? confirmedBy,
    String? paymentReference,
    String? notes,
    required int doPayForExtras,
    required double surcharge,
    String? paymentProvider,
    required double discountAmount,
    required int discountPercent,
    required String discountDescription,
    required String specialRunPriceReason,
    int? removed,
    DateTime? updatedAt,
  }) = _PaymentsModel;

  factory PaymentsModel.fromJson(Map<String, dynamic> json) => _$PaymentsModelFromJson(json);
}
