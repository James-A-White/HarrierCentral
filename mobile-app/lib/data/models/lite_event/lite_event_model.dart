import 'package:harrier_central/imports.dart';

part 'lite_event_model.freezed.dart';
part 'lite_event_model.g.dart';

@freezed
abstract class LiteEventModel with _$LiteEventModel implements BaseModel {
  factory LiteEventModel({
    required String eventId,
    @Default(1) int isVisible,
    @Default(1) int isCountedRun,
    int? absoluteEventNumber,
    String? externalIntegrationId,
    required String eventName,
    required int eventNumber,
    required DateTime eventStartDatetime,
    int? eventInboundIntegrationId,
    @Default(0) int appAccessFlags,
    @Default(0) int canEditRunAttendance,
  }) = _LiteEventModel;

  factory LiteEventModel.fromJson(Map<String, dynamic> json) =>
      _$LiteEventModelFromJson(json);

  @override
  factory LiteEventModel.fromMap(Map<String, dynamic> map) {
    return LiteEventModel.fromJson(map);
  }
}
