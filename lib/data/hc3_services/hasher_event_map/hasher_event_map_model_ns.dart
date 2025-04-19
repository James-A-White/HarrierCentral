import 'package:harrier_central/imports.dart';

part 'hasher_event_map_model_ns.freezed.dart';
part 'hasher_event_map_model_ns.g.dart';

@freezed
abstract class HasherEventMapModel
    with _$HasherEventMapModel
    implements BaseModel {
  factory HasherEventMapModel({
    required String hemId,
    required String userId,
    required String eventId,
    String? hasherOwnEventId,
    String? userStartEvent,
    String? userEndEvent,
    required int rsvpState,
    required int attendenceState,
    required int isHare,
    int? eventNotificationPreference,
    int? eventEmailAlertPreference,
    int? totalHaring,
    int? totalHaringThisKennel,
    int? totalRuns,
    int? totalRunsThisKennel,
    int? eventCountOverride,
    required int virginVisitorType,
    String? displayName,
    String? email,
    String? phoneNumber,

    // these fields are cached from the event itself. This enables us to keep run count information without
    // having to have the actual run cached on the phone
    String? hemEventName,
    int? hemEventNumber,
    required DateTime hemEventStartDatetime,
    int? hemCanEditRunAttendence,
    String? hemEventKennelId,
    int? hemEventIsCountedAndVisible,
    String? hemKennelUserPhoto,
    String? hemKennelHashName,
    int? removed,
    DateTime? updatedAt,
  }) = _HasherEventMapModel;

  factory HasherEventMapModel.fromJson(Map<String, dynamic> json) =>
      _$HasherEventMapModelFromJson(json);
}
