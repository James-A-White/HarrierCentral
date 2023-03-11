import 'package:harrier_central/imports_null_safe.dart';

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
    required num creditAmount,
    required num debitAmount,
    required num creditAvailable,
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
    required num surcharge,
    String? paymentProvider,
    required num discountAmount,
    required int discountPercent,
    required String discountDescription,
    required String specialRunPriceReason,
    required int removed,
    required DateTime updatedAt,
  }) = _PaymentsModel;

  factory PaymentsModel.fromJson(Map<String, dynamic> json) => _$PaymentsModelFromJson(json);
}
