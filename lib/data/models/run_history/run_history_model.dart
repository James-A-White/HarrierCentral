import 'package:harrier_central/imports_null_safe.dart';

part 'run_history_model.freezed.dart';
part 'run_history_model.g.dart';

@freezed
class RunHistoryModel with _$RunHistoryModel implements BaseModel {
  factory RunHistoryModel({
    required int totalRunsThisKennel,
    required int totalHaringThisKennel,
    required int hcRunsThisKennel,
    required int hcHaringThisKennel,
    required String kennelName,
    required String kennelShortName,
    required String kennelId,
    required String kennelLogo,
    required String currencySymbol,
    required double kennelCredit,
    required int historicalHaringCount,
    required int historicalTotalRunCount,
    required int historicalCountIsEstimate,
    required int following,
    required int digitsAfterDecimal,
  }) = _RunHistoryModel;

  factory RunHistoryModel.fromJson(Map<String, dynamic> json) => _$RunHistoryModelFromJson(json);

  @override
  factory RunHistoryModel.fromMap(Map<String, dynamic> map) {
    return RunHistoryModel.fromJson(map);
  }
}
