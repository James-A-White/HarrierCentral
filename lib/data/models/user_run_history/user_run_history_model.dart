import 'package:harrier_central/imports.dart';

part 'user_run_history_model.freezed.dart';
part 'user_run_history_model.g.dart';

@freezed
abstract class UserRunHistoryModel
    with _$UserRunHistoryModel
    implements BaseModel {
  factory UserRunHistoryModel({
    required String eventId,
    required String eventName,
    required int eventNumber,
    required String kennelName,
    required String kennelShortName,
    required String currencySymbol,
    required int digitsAfterDecimal,
    required String kennelLogo,
    required String countryName,
    required String flagFile,
    required DateTime eventStartDatetime,
    @Default(0) int canEditRunAttendence,
    String? hemId,
    @Default(0) int attendenceState,
    @Default(0) int isHare,
    double? creditAmount,
    double? debitAmount,
    double? creditAvailable,
    int? paymentType,
    String? extrasDescription,
    double? extrasPrice,
    int? doPayForExtras,
    int? totalRunsThisKennel,
    int? totalHaringThisKennel,
    @JsonKey(includeFromJson: false, includeToJson: false)
    @Default(false)
    bool isUpdating,
  }) = _UserRunHistoryModel;

  factory UserRunHistoryModel.fromJson(Map<String, dynamic> json) =>
      _$UserRunHistoryModelFromJson(json);

  @override
  factory UserRunHistoryModel.fromMap(Map<String, dynamic> map) {
    return UserRunHistoryModel.fromJson(map);
  }
}
