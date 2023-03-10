import 'package:harrier_central/imports_null_safe.dart';

part 'receipts_model_ns.freezed.dart';
part 'receipts_model_ns.g.dart';

@freezed
class ReceiptsModel with _$ReceiptsModel implements BaseModel {
  factory ReceiptsModel({
    required String? receiptId,
    required String? eventId,
    required String? userId,
    required num? receiptAmount,
    required int? costCategory,
    required DateTime dateUploaded,
    required String? imageUrl,
    required String? receiptShortDescription,
    required String? notes,
    required String? reimbursedBy,
    required String? reimbursedOn,
    required num? reimbursedAmount,
    required String? reimbursedNotes,
    required int? removed,
    required DateTime? updatedAt,
  }) = _ReceiptsModel;

  factory ReceiptsModel.fromJson(Map<String, dynamic> json) => _$ReceiptsModelFromJson(json);
}
