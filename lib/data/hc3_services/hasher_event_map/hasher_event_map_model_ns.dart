import 'package:harrier_central/imports_null_safe.dart';

part 'hasher_event_map_model_ns.freezed.dart';
part 'hasher_event_map_model_ns.g.dart';

@freezed
class HasherEventMapModel with _$HasherEventMapModel implements BaseModel {
  factory HasherEventMapModel({
    required String? hemId,
    required String? userId,
    required String? eventId,
    required String? hasherOwnEventId,
    required String? userStartEvent,
    required String? userEndEvent,
    required int? rsvpState,
    required int? attendenceState,
    required int? isHare,
    required int? eventNotificationPreference,
    required int? eventEmailAlertPreference,
    required int? totalHaring,
    required int? totalHaringThisKennel,
    required int? totalRuns,
    required int? totalRunsThisKennel,
    required num? eventCountOverride,
    required num? virginVisitorType,
    required String? displayName,
    required String? email,
    required String? phoneNumber,

    // these fields are cached from the event itself. This enables us to keep run count information without
    // having to have the actual run cached on the phone
    required String? hemEventName,
    required int? hemEventNumber,
    required DateTime hemEventStartDatetime,
    required num? hemCanEditRunAttendence,
    required String? hemEventKennelId,
    required int? hemEventIsCountedAndVisible,
    required String? hemKennelUserPhoto,
    required String? hemKennelHashName,
    required int? removed,
    required DateTime? updatedAt,
  }) = _HasherEventMapModel;

  factory HasherEventMapModel.fromJson(Map<String, dynamic> json) => _$HasherEventMapModelFromJson(json);
}
