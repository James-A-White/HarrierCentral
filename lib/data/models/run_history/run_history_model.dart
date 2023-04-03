import 'package:harrier_central/imports_null_safe.dart';

part 'run_history_model.freezed.dart';
part 'run_history_model.g.dart';

@freezed
class RunHistoryModel with _$RunHistoryModel implements BaseModel {
  factory RunHistoryModel({
    @Default(0) int totalRunsThisKennel,
    @Default(0) int totalHaringThisKennel,
    @Default(0) int hcRunsThisKennel,
    @Default(0) int hcHaringThisKennel,
    required String kennelName,
    required String kennelShortName,
    required String kennelId,
    required String kennelLogo,
    @Default(r'$^') String currencySymbol,
    @Default(0.0) double kennelCredit,
    @Default(0) int historicalHaringCount,
    @Default(0) int historicalTotalRunCount,
    @Default(0) int historicalCountIsEstimate,
    @Default(0) int following,
    @Default(2) int digitsAfterDecimal,
  }) = _RunHistoryModel;

  factory RunHistoryModel.fromJson(Map<String, dynamic> json) => _$RunHistoryModelFromJson(json);

  @override
  factory RunHistoryModel.fromMap(Map<String, dynamic> map) {
    return RunHistoryModel.fromJson(map);
  }
}
