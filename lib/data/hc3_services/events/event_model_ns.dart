import 'package:harrier_central/imports_null_safe.dart';

part 'event_model_ns.freezed.dart';
part 'event_model_ns.g.dart';

@freezed
class EventModel with _$EventModel implements BaseModel {
  factory EventModel({
    required String? eventId,
    required String? publicEventId,
    required DateTime? eventStartDatetime,
    required String? kennelId,
    required int? isVisible,
    required int? isCountedRun,
    required int? isPromotedEvent,
    required int? eventGeographicScope,
    required int? eventInboundIntegrationId,
    required int? eventNumber,
    required String? eventName,
    required num? hcLatitude,
    required num? hcLongitude,
    required num? fbLatitude,
    required num? fbLongitude,
    required num? eventPriceForMembers,
    required num? eventPriceForNonMembers,
    required int? evtDisseminateAllowWebLinks,
    required String? eventFacebookId,
    required num? absoluteEventNumber,
    required num? canEditRunAttendence,
    required String? eventImage,
    required String? eventDescription,
    required String? eventUrl,
    required String? locationOneLineDesc,
    required String? locationPostCode,
    required String? locationCity,
    required String? locationStreet,
    required String? locationCountry,
    required String? locationRegion,
    required String? locationSubRegion,
    required String? hares,
    required String? eventPaymentScheme,
    required String? eventPaymentUrl,
    required DateTime? eventPaymentUrlExpires,
    required int? unconfirmedBankXferCount,
    required num? eventPriceForExtras,
    required String? extrasDescription,
    required int? doTrackHashCash,
    required int? tags1,
    required int? tags2,
    required int? tags3,
    required int? useFbLocation,
    required int? useFbLatLon,
    required int? useFbRunDetails,
    required int? useFbImage,
    required int? removed,
    required DateTime? updatedAt,
  }) = _EventModel;

  factory EventModel.fromJson(Map<String, dynamic> json) => _$EventModelFromJson(json);

  @override
  factory EventModel.fromMap(Map<String, dynamic> map) {
    return EventModel.fromJson(map);
  }
}
