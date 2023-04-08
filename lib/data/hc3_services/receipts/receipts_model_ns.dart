import 'package:harrier_central/imports.dart';

part 'receipts_model_ns.freezed.dart';
part 'receipts_model_ns.g.dart';

@freezed
class ReceiptsModel with _$ReceiptsModel implements BaseModel {
  factory ReceiptsModel({
    required String receiptId,
    required String eventId,
    required String userId,
    @Default(0.0) double receiptAmount,
    @Default(0) int costCategory,
    DateTime? dateUploaded,
    String? imageUrl,
    String? receiptShortDescription,
    String? notes,
    String? reimbursedBy,
    String? reimbursedOn,
    double? reimbursedAmount,
    String? reimbursedNotes,
    int? removed,
    DateTime? updatedAt,
  }) = _ReceiptsModel;

  factory ReceiptsModel.fromJson(Map<String, dynamic> json) => _$ReceiptsModelFromJson(json);
}
