import 'package:harrier_central/imports_null_safe.dart';

part 'event_model_ns.freezed.dart';
part 'event_model_ns.g.dart';

@freezed
class EventModel with _$EventModel implements BaseModel {
  factory EventModel({
    required String eventId,
    required String publicEventId,
    DateTime? eventStartDatetime,
    required String kennelId,
    required int isVisible,
    required int isCountedRun,
    required int isPromotedEvent,
    required int eventGeographicScope,
    required int eventInboundIntegrationId,
    required int eventNumber,
    required String eventName,
    num? hcLatitude,
    num? hcLongitude,
    num? fbLatitude,
    num? fbLongitude,
    num? eventPriceForMembers,
    num? eventPriceForNonMembers,
    int? evtDisseminateAllowWebLinks,
    String? eventFacebookId,
    num? absoluteEventNumber,
    num? canEditRunAttendence,
    String? eventImage,
    String? eventDescription,
    String? eventUrl,
    String? locationOneLineDesc,
    String? locationPostCode,
    String? locationCity,
    String? locationStreet,
    String? locationCountry,
    String? locationRegion,
    String? locationSubRegion,
    String? hares,
    String? eventPaymentScheme,
    String? eventPaymentUrl,
    DateTime? eventPaymentUrlExpires,
    int? unconfirmedBankXferCount,
    num? eventPriceForExtras,
    String? extrasDescription,
    required int doTrackHashCash,
    required int tags1,
    required int tags2,
    required int tags3,
    required int useFbLocation,
    required int useFbLatLon,
    required int useFbRunDetails,
    required int useFbImage,
    required int removed,
    required DateTime updatedAt,
  }) = _EventModel;

  factory EventModel.fromJson(Map<String, dynamic> json) => _$EventModelFromJson(json);

  @override
  factory EventModel.fromMap(Map<String, dynamic> map) {
    return EventModel.fromJson(map);
  }
}
