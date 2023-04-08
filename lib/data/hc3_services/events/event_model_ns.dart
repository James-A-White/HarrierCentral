import 'package:harrier_central/imports.dart';

part 'event_model_ns.freezed.dart';
part 'event_model_ns.g.dart';

@freezed
class EventModel with _$EventModel implements BaseModel {
  factory EventModel({
    required String eventId,
    required String publicEventId,
    required DateTime eventStartDatetime,
    required String kennelId,
    required int isVisible,
    required int isCountedRun,
    required int isPromotedEvent,
    required int eventGeographicScope,
    required int eventInboundIntegrationId,
    required int eventNumber,
    required String eventName,
    double? hcLatitude,
    double? hcLongitude,
    double? fbLatitude,
    double? fbLongitude,
    double? eventPriceForMembers,
    double? eventPriceForNonMembers,
    int? evtDisseminateAllowWebLinks,
    String? eventFacebookId,
    int? absoluteEventNumber,
    int? canEditRunAttendence,
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
    double? eventPriceForExtras,
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
