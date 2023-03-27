import 'package:harrier_central/imports_null_safe.dart';

part 'lite_event_model.freezed.dart';
part 'lite_event_model.g.dart';

@freezed
class LiteEventModel with _$LiteEventModel implements BaseModel {
  factory LiteEventModel({
    required String eventId,
    required int isVisible,
    required int isCountedRun,
    int? absoluteEventNumber,
    String? externalIntegrationId,
    required String eventName,
    required int eventNumber,
    DateTime? eventStartDatetime,
    int? eventInboundIntegrationId,
    required int appAccessFlags,
    required int canEditRunAttendance,
  }) = _LiteEventModel;

  factory LiteEventModel.fromJson(Map<String, dynamic> json) => _$LiteEventModelFromJson(json);

  @override
  factory LiteEventModel.fromMap(Map<String, dynamic> map) {
    return LiteEventModel.fromJson(map);
  }
}
