// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'event_model_ns.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EventModel implements DiagnosticableTreeMixin {

 String get eventId; String get publicEventId; DateTime get eventStartDatetime; String get kennelId; int get isVisible; int get isCountedRun; int get isPromotedEvent; int get eventGeographicScope; int get eventInboundIntegrationId; int get eventNumber; String get eventName; String get countryId; double? get hcLatitude; double? get hcLongitude; double? get fbLatitude; double? get fbLongitude; double? get eventPriceForMembers; double? get eventPriceForNonMembers; int? get evtDisseminateAllowWebLinks; String? get eventFacebookId; int? get absoluteEventNumber; int? get canEditRunAttendence; String? get eventImage; String? get eventDescription; String? get eventUrl; String? get locationOneLineDesc; String? get locationPostCode; String? get locationCity; String? get locationStreet; String? get locationCountry; String? get locationRegion; String? get locationSubRegion; String? get hares; String? get eventPaymentScheme; String? get eventPaymentUrl; DateTime? get eventPaymentUrlExpires; int? get unconfirmedBankXferCount; double? get eventPriceForExtras; String? get extrasDescription; int get doTrackHashCash; int get tags1; int get tags2; int get tags3; int get useFbLocation; int get useFbLatLon; int get useFbRunDetails; int get useFbImage; int? get removed; DateTime? get updatedAt;
/// Create a copy of EventModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EventModelCopyWith<EventModel> get copyWith => _$EventModelCopyWithImpl<EventModel>(this as EventModel, _$identity);

  /// Serializes this EventModel to a JSON map.
  Map<String, dynamic> toJson();

@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'EventModel'))
    ..add(DiagnosticsProperty('eventId', eventId))..add(DiagnosticsProperty('publicEventId', publicEventId))..add(DiagnosticsProperty('eventStartDatetime', eventStartDatetime))..add(DiagnosticsProperty('kennelId', kennelId))..add(DiagnosticsProperty('isVisible', isVisible))..add(DiagnosticsProperty('isCountedRun', isCountedRun))..add(DiagnosticsProperty('isPromotedEvent', isPromotedEvent))..add(DiagnosticsProperty('eventGeographicScope', eventGeographicScope))..add(DiagnosticsProperty('eventInboundIntegrationId', eventInboundIntegrationId))..add(DiagnosticsProperty('eventNumber', eventNumber))..add(DiagnosticsProperty('eventName', eventName))..add(DiagnosticsProperty('countryId', countryId))..add(DiagnosticsProperty('hcLatitude', hcLatitude))..add(DiagnosticsProperty('hcLongitude', hcLongitude))..add(DiagnosticsProperty('fbLatitude', fbLatitude))..add(DiagnosticsProperty('fbLongitude', fbLongitude))..add(DiagnosticsProperty('eventPriceForMembers', eventPriceForMembers))..add(DiagnosticsProperty('eventPriceForNonMembers', eventPriceForNonMembers))..add(DiagnosticsProperty('evtDisseminateAllowWebLinks', evtDisseminateAllowWebLinks))..add(DiagnosticsProperty('eventFacebookId', eventFacebookId))..add(DiagnosticsProperty('absoluteEventNumber', absoluteEventNumber))..add(DiagnosticsProperty('canEditRunAttendence', canEditRunAttendence))..add(DiagnosticsProperty('eventImage', eventImage))..add(DiagnosticsProperty('eventDescription', eventDescription))..add(DiagnosticsProperty('eventUrl', eventUrl))..add(DiagnosticsProperty('locationOneLineDesc', locationOneLineDesc))..add(DiagnosticsProperty('locationPostCode', locationPostCode))..add(DiagnosticsProperty('locationCity', locationCity))..add(DiagnosticsProperty('locationStreet', locationStreet))..add(DiagnosticsProperty('locationCountry', locationCountry))..add(DiagnosticsProperty('locationRegion', locationRegion))..add(DiagnosticsProperty('locationSubRegion', locationSubRegion))..add(DiagnosticsProperty('hares', hares))..add(DiagnosticsProperty('eventPaymentScheme', eventPaymentScheme))..add(DiagnosticsProperty('eventPaymentUrl', eventPaymentUrl))..add(DiagnosticsProperty('eventPaymentUrlExpires', eventPaymentUrlExpires))..add(DiagnosticsProperty('unconfirmedBankXferCount', unconfirmedBankXferCount))..add(DiagnosticsProperty('eventPriceForExtras', eventPriceForExtras))..add(DiagnosticsProperty('extrasDescription', extrasDescription))..add(DiagnosticsProperty('doTrackHashCash', doTrackHashCash))..add(DiagnosticsProperty('tags1', tags1))..add(DiagnosticsProperty('tags2', tags2))..add(DiagnosticsProperty('tags3', tags3))..add(DiagnosticsProperty('useFbLocation', useFbLocation))..add(DiagnosticsProperty('useFbLatLon', useFbLatLon))..add(DiagnosticsProperty('useFbRunDetails', useFbRunDetails))..add(DiagnosticsProperty('useFbImage', useFbImage))..add(DiagnosticsProperty('removed', removed))..add(DiagnosticsProperty('updatedAt', updatedAt));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EventModel&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.publicEventId, publicEventId) || other.publicEventId == publicEventId)&&(identical(other.eventStartDatetime, eventStartDatetime) || other.eventStartDatetime == eventStartDatetime)&&(identical(other.kennelId, kennelId) || other.kennelId == kennelId)&&(identical(other.isVisible, isVisible) || other.isVisible == isVisible)&&(identical(other.isCountedRun, isCountedRun) || other.isCountedRun == isCountedRun)&&(identical(other.isPromotedEvent, isPromotedEvent) || other.isPromotedEvent == isPromotedEvent)&&(identical(other.eventGeographicScope, eventGeographicScope) || other.eventGeographicScope == eventGeographicScope)&&(identical(other.eventInboundIntegrationId, eventInboundIntegrationId) || other.eventInboundIntegrationId == eventInboundIntegrationId)&&(identical(other.eventNumber, eventNumber) || other.eventNumber == eventNumber)&&(identical(other.eventName, eventName) || other.eventName == eventName)&&(identical(other.countryId, countryId) || other.countryId == countryId)&&(identical(other.hcLatitude, hcLatitude) || other.hcLatitude == hcLatitude)&&(identical(other.hcLongitude, hcLongitude) || other.hcLongitude == hcLongitude)&&(identical(other.fbLatitude, fbLatitude) || other.fbLatitude == fbLatitude)&&(identical(other.fbLongitude, fbLongitude) || other.fbLongitude == fbLongitude)&&(identical(other.eventPriceForMembers, eventPriceForMembers) || other.eventPriceForMembers == eventPriceForMembers)&&(identical(other.eventPriceForNonMembers, eventPriceForNonMembers) || other.eventPriceForNonMembers == eventPriceForNonMembers)&&(identical(other.evtDisseminateAllowWebLinks, evtDisseminateAllowWebLinks) || other.evtDisseminateAllowWebLinks == evtDisseminateAllowWebLinks)&&(identical(other.eventFacebookId, eventFacebookId) || other.eventFacebookId == eventFacebookId)&&(identical(other.absoluteEventNumber, absoluteEventNumber) || other.absoluteEventNumber == absoluteEventNumber)&&(identical(other.canEditRunAttendence, canEditRunAttendence) || other.canEditRunAttendence == canEditRunAttendence)&&(identical(other.eventImage, eventImage) || other.eventImage == eventImage)&&(identical(other.eventDescription, eventDescription) || other.eventDescription == eventDescription)&&(identical(other.eventUrl, eventUrl) || other.eventUrl == eventUrl)&&(identical(other.locationOneLineDesc, locationOneLineDesc) || other.locationOneLineDesc == locationOneLineDesc)&&(identical(other.locationPostCode, locationPostCode) || other.locationPostCode == locationPostCode)&&(identical(other.locationCity, locationCity) || other.locationCity == locationCity)&&(identical(other.locationStreet, locationStreet) || other.locationStreet == locationStreet)&&(identical(other.locationCountry, locationCountry) || other.locationCountry == locationCountry)&&(identical(other.locationRegion, locationRegion) || other.locationRegion == locationRegion)&&(identical(other.locationSubRegion, locationSubRegion) || other.locationSubRegion == locationSubRegion)&&(identical(other.hares, hares) || other.hares == hares)&&(identical(other.eventPaymentScheme, eventPaymentScheme) || other.eventPaymentScheme == eventPaymentScheme)&&(identical(other.eventPaymentUrl, eventPaymentUrl) || other.eventPaymentUrl == eventPaymentUrl)&&(identical(other.eventPaymentUrlExpires, eventPaymentUrlExpires) || other.eventPaymentUrlExpires == eventPaymentUrlExpires)&&(identical(other.unconfirmedBankXferCount, unconfirmedBankXferCount) || other.unconfirmedBankXferCount == unconfirmedBankXferCount)&&(identical(other.eventPriceForExtras, eventPriceForExtras) || other.eventPriceForExtras == eventPriceForExtras)&&(identical(other.extrasDescription, extrasDescription) || other.extrasDescription == extrasDescription)&&(identical(other.doTrackHashCash, doTrackHashCash) || other.doTrackHashCash == doTrackHashCash)&&(identical(other.tags1, tags1) || other.tags1 == tags1)&&(identical(other.tags2, tags2) || other.tags2 == tags2)&&(identical(other.tags3, tags3) || other.tags3 == tags3)&&(identical(other.useFbLocation, useFbLocation) || other.useFbLocation == useFbLocation)&&(identical(other.useFbLatLon, useFbLatLon) || other.useFbLatLon == useFbLatLon)&&(identical(other.useFbRunDetails, useFbRunDetails) || other.useFbRunDetails == useFbRunDetails)&&(identical(other.useFbImage, useFbImage) || other.useFbImage == useFbImage)&&(identical(other.removed, removed) || other.removed == removed)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,eventId,publicEventId,eventStartDatetime,kennelId,isVisible,isCountedRun,isPromotedEvent,eventGeographicScope,eventInboundIntegrationId,eventNumber,eventName,countryId,hcLatitude,hcLongitude,fbLatitude,fbLongitude,eventPriceForMembers,eventPriceForNonMembers,evtDisseminateAllowWebLinks,eventFacebookId,absoluteEventNumber,canEditRunAttendence,eventImage,eventDescription,eventUrl,locationOneLineDesc,locationPostCode,locationCity,locationStreet,locationCountry,locationRegion,locationSubRegion,hares,eventPaymentScheme,eventPaymentUrl,eventPaymentUrlExpires,unconfirmedBankXferCount,eventPriceForExtras,extrasDescription,doTrackHashCash,tags1,tags2,tags3,useFbLocation,useFbLatLon,useFbRunDetails,useFbImage,removed,updatedAt]);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'EventModel(eventId: $eventId, publicEventId: $publicEventId, eventStartDatetime: $eventStartDatetime, kennelId: $kennelId, isVisible: $isVisible, isCountedRun: $isCountedRun, isPromotedEvent: $isPromotedEvent, eventGeographicScope: $eventGeographicScope, eventInboundIntegrationId: $eventInboundIntegrationId, eventNumber: $eventNumber, eventName: $eventName, countryId: $countryId, hcLatitude: $hcLatitude, hcLongitude: $hcLongitude, fbLatitude: $fbLatitude, fbLongitude: $fbLongitude, eventPriceForMembers: $eventPriceForMembers, eventPriceForNonMembers: $eventPriceForNonMembers, evtDisseminateAllowWebLinks: $evtDisseminateAllowWebLinks, eventFacebookId: $eventFacebookId, absoluteEventNumber: $absoluteEventNumber, canEditRunAttendence: $canEditRunAttendence, eventImage: $eventImage, eventDescription: $eventDescription, eventUrl: $eventUrl, locationOneLineDesc: $locationOneLineDesc, locationPostCode: $locationPostCode, locationCity: $locationCity, locationStreet: $locationStreet, locationCountry: $locationCountry, locationRegion: $locationRegion, locationSubRegion: $locationSubRegion, hares: $hares, eventPaymentScheme: $eventPaymentScheme, eventPaymentUrl: $eventPaymentUrl, eventPaymentUrlExpires: $eventPaymentUrlExpires, unconfirmedBankXferCount: $unconfirmedBankXferCount, eventPriceForExtras: $eventPriceForExtras, extrasDescription: $extrasDescription, doTrackHashCash: $doTrackHashCash, tags1: $tags1, tags2: $tags2, tags3: $tags3, useFbLocation: $useFbLocation, useFbLatLon: $useFbLatLon, useFbRunDetails: $useFbRunDetails, useFbImage: $useFbImage, removed: $removed, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $EventModelCopyWith<$Res>  {
  factory $EventModelCopyWith(EventModel value, $Res Function(EventModel) _then) = _$EventModelCopyWithImpl;
@useResult
$Res call({
 String eventId, String publicEventId, DateTime eventStartDatetime, String kennelId, int isVisible, int isCountedRun, int isPromotedEvent, int eventGeographicScope, int eventInboundIntegrationId, int eventNumber, String eventName, String countryId, double? hcLatitude, double? hcLongitude, double? fbLatitude, double? fbLongitude, double? eventPriceForMembers, double? eventPriceForNonMembers, int? evtDisseminateAllowWebLinks, String? eventFacebookId, int? absoluteEventNumber, int? canEditRunAttendence, String? eventImage, String? eventDescription, String? eventUrl, String? locationOneLineDesc, String? locationPostCode, String? locationCity, String? locationStreet, String? locationCountry, String? locationRegion, String? locationSubRegion, String? hares, String? eventPaymentScheme, String? eventPaymentUrl, DateTime? eventPaymentUrlExpires, int? unconfirmedBankXferCount, double? eventPriceForExtras, String? extrasDescription, int doTrackHashCash, int tags1, int tags2, int tags3, int useFbLocation, int useFbLatLon, int useFbRunDetails, int useFbImage, int? removed, DateTime? updatedAt
});




}
/// @nodoc
class _$EventModelCopyWithImpl<$Res>
    implements $EventModelCopyWith<$Res> {
  _$EventModelCopyWithImpl(this._self, this._then);

  final EventModel _self;
  final $Res Function(EventModel) _then;

/// Create a copy of EventModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? eventId = null,Object? publicEventId = null,Object? eventStartDatetime = null,Object? kennelId = null,Object? isVisible = null,Object? isCountedRun = null,Object? isPromotedEvent = null,Object? eventGeographicScope = null,Object? eventInboundIntegrationId = null,Object? eventNumber = null,Object? eventName = null,Object? countryId = null,Object? hcLatitude = freezed,Object? hcLongitude = freezed,Object? fbLatitude = freezed,Object? fbLongitude = freezed,Object? eventPriceForMembers = freezed,Object? eventPriceForNonMembers = freezed,Object? evtDisseminateAllowWebLinks = freezed,Object? eventFacebookId = freezed,Object? absoluteEventNumber = freezed,Object? canEditRunAttendence = freezed,Object? eventImage = freezed,Object? eventDescription = freezed,Object? eventUrl = freezed,Object? locationOneLineDesc = freezed,Object? locationPostCode = freezed,Object? locationCity = freezed,Object? locationStreet = freezed,Object? locationCountry = freezed,Object? locationRegion = freezed,Object? locationSubRegion = freezed,Object? hares = freezed,Object? eventPaymentScheme = freezed,Object? eventPaymentUrl = freezed,Object? eventPaymentUrlExpires = freezed,Object? unconfirmedBankXferCount = freezed,Object? eventPriceForExtras = freezed,Object? extrasDescription = freezed,Object? doTrackHashCash = null,Object? tags1 = null,Object? tags2 = null,Object? tags3 = null,Object? useFbLocation = null,Object? useFbLatLon = null,Object? useFbRunDetails = null,Object? useFbImage = null,Object? removed = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,publicEventId: null == publicEventId ? _self.publicEventId : publicEventId // ignore: cast_nullable_to_non_nullable
as String,eventStartDatetime: null == eventStartDatetime ? _self.eventStartDatetime : eventStartDatetime // ignore: cast_nullable_to_non_nullable
as DateTime,kennelId: null == kennelId ? _self.kennelId : kennelId // ignore: cast_nullable_to_non_nullable
as String,isVisible: null == isVisible ? _self.isVisible : isVisible // ignore: cast_nullable_to_non_nullable
as int,isCountedRun: null == isCountedRun ? _self.isCountedRun : isCountedRun // ignore: cast_nullable_to_non_nullable
as int,isPromotedEvent: null == isPromotedEvent ? _self.isPromotedEvent : isPromotedEvent // ignore: cast_nullable_to_non_nullable
as int,eventGeographicScope: null == eventGeographicScope ? _self.eventGeographicScope : eventGeographicScope // ignore: cast_nullable_to_non_nullable
as int,eventInboundIntegrationId: null == eventInboundIntegrationId ? _self.eventInboundIntegrationId : eventInboundIntegrationId // ignore: cast_nullable_to_non_nullable
as int,eventNumber: null == eventNumber ? _self.eventNumber : eventNumber // ignore: cast_nullable_to_non_nullable
as int,eventName: null == eventName ? _self.eventName : eventName // ignore: cast_nullable_to_non_nullable
as String,countryId: null == countryId ? _self.countryId : countryId // ignore: cast_nullable_to_non_nullable
as String,hcLatitude: freezed == hcLatitude ? _self.hcLatitude : hcLatitude // ignore: cast_nullable_to_non_nullable
as double?,hcLongitude: freezed == hcLongitude ? _self.hcLongitude : hcLongitude // ignore: cast_nullable_to_non_nullable
as double?,fbLatitude: freezed == fbLatitude ? _self.fbLatitude : fbLatitude // ignore: cast_nullable_to_non_nullable
as double?,fbLongitude: freezed == fbLongitude ? _self.fbLongitude : fbLongitude // ignore: cast_nullable_to_non_nullable
as double?,eventPriceForMembers: freezed == eventPriceForMembers ? _self.eventPriceForMembers : eventPriceForMembers // ignore: cast_nullable_to_non_nullable
as double?,eventPriceForNonMembers: freezed == eventPriceForNonMembers ? _self.eventPriceForNonMembers : eventPriceForNonMembers // ignore: cast_nullable_to_non_nullable
as double?,evtDisseminateAllowWebLinks: freezed == evtDisseminateAllowWebLinks ? _self.evtDisseminateAllowWebLinks : evtDisseminateAllowWebLinks // ignore: cast_nullable_to_non_nullable
as int?,eventFacebookId: freezed == eventFacebookId ? _self.eventFacebookId : eventFacebookId // ignore: cast_nullable_to_non_nullable
as String?,absoluteEventNumber: freezed == absoluteEventNumber ? _self.absoluteEventNumber : absoluteEventNumber // ignore: cast_nullable_to_non_nullable
as int?,canEditRunAttendence: freezed == canEditRunAttendence ? _self.canEditRunAttendence : canEditRunAttendence // ignore: cast_nullable_to_non_nullable
as int?,eventImage: freezed == eventImage ? _self.eventImage : eventImage // ignore: cast_nullable_to_non_nullable
as String?,eventDescription: freezed == eventDescription ? _self.eventDescription : eventDescription // ignore: cast_nullable_to_non_nullable
as String?,eventUrl: freezed == eventUrl ? _self.eventUrl : eventUrl // ignore: cast_nullable_to_non_nullable
as String?,locationOneLineDesc: freezed == locationOneLineDesc ? _self.locationOneLineDesc : locationOneLineDesc // ignore: cast_nullable_to_non_nullable
as String?,locationPostCode: freezed == locationPostCode ? _self.locationPostCode : locationPostCode // ignore: cast_nullable_to_non_nullable
as String?,locationCity: freezed == locationCity ? _self.locationCity : locationCity // ignore: cast_nullable_to_non_nullable
as String?,locationStreet: freezed == locationStreet ? _self.locationStreet : locationStreet // ignore: cast_nullable_to_non_nullable
as String?,locationCountry: freezed == locationCountry ? _self.locationCountry : locationCountry // ignore: cast_nullable_to_non_nullable
as String?,locationRegion: freezed == locationRegion ? _self.locationRegion : locationRegion // ignore: cast_nullable_to_non_nullable
as String?,locationSubRegion: freezed == locationSubRegion ? _self.locationSubRegion : locationSubRegion // ignore: cast_nullable_to_non_nullable
as String?,hares: freezed == hares ? _self.hares : hares // ignore: cast_nullable_to_non_nullable
as String?,eventPaymentScheme: freezed == eventPaymentScheme ? _self.eventPaymentScheme : eventPaymentScheme // ignore: cast_nullable_to_non_nullable
as String?,eventPaymentUrl: freezed == eventPaymentUrl ? _self.eventPaymentUrl : eventPaymentUrl // ignore: cast_nullable_to_non_nullable
as String?,eventPaymentUrlExpires: freezed == eventPaymentUrlExpires ? _self.eventPaymentUrlExpires : eventPaymentUrlExpires // ignore: cast_nullable_to_non_nullable
as DateTime?,unconfirmedBankXferCount: freezed == unconfirmedBankXferCount ? _self.unconfirmedBankXferCount : unconfirmedBankXferCount // ignore: cast_nullable_to_non_nullable
as int?,eventPriceForExtras: freezed == eventPriceForExtras ? _self.eventPriceForExtras : eventPriceForExtras // ignore: cast_nullable_to_non_nullable
as double?,extrasDescription: freezed == extrasDescription ? _self.extrasDescription : extrasDescription // ignore: cast_nullable_to_non_nullable
as String?,doTrackHashCash: null == doTrackHashCash ? _self.doTrackHashCash : doTrackHashCash // ignore: cast_nullable_to_non_nullable
as int,tags1: null == tags1 ? _self.tags1 : tags1 // ignore: cast_nullable_to_non_nullable
as int,tags2: null == tags2 ? _self.tags2 : tags2 // ignore: cast_nullable_to_non_nullable
as int,tags3: null == tags3 ? _self.tags3 : tags3 // ignore: cast_nullable_to_non_nullable
as int,useFbLocation: null == useFbLocation ? _self.useFbLocation : useFbLocation // ignore: cast_nullable_to_non_nullable
as int,useFbLatLon: null == useFbLatLon ? _self.useFbLatLon : useFbLatLon // ignore: cast_nullable_to_non_nullable
as int,useFbRunDetails: null == useFbRunDetails ? _self.useFbRunDetails : useFbRunDetails // ignore: cast_nullable_to_non_nullable
as int,useFbImage: null == useFbImage ? _self.useFbImage : useFbImage // ignore: cast_nullable_to_non_nullable
as int,removed: freezed == removed ? _self.removed : removed // ignore: cast_nullable_to_non_nullable
as int?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _EventModel with DiagnosticableTreeMixin implements EventModel {
   _EventModel({required this.eventId, required this.publicEventId, required this.eventStartDatetime, required this.kennelId, required this.isVisible, required this.isCountedRun, required this.isPromotedEvent, required this.eventGeographicScope, required this.eventInboundIntegrationId, required this.eventNumber, required this.eventName, required this.countryId, this.hcLatitude, this.hcLongitude, this.fbLatitude, this.fbLongitude, this.eventPriceForMembers, this.eventPriceForNonMembers, this.evtDisseminateAllowWebLinks, this.eventFacebookId, this.absoluteEventNumber, this.canEditRunAttendence, this.eventImage, this.eventDescription, this.eventUrl, this.locationOneLineDesc, this.locationPostCode, this.locationCity, this.locationStreet, this.locationCountry, this.locationRegion, this.locationSubRegion, this.hares, this.eventPaymentScheme, this.eventPaymentUrl, this.eventPaymentUrlExpires, this.unconfirmedBankXferCount, this.eventPriceForExtras, this.extrasDescription, required this.doTrackHashCash, required this.tags1, required this.tags2, required this.tags3, required this.useFbLocation, required this.useFbLatLon, required this.useFbRunDetails, required this.useFbImage, this.removed, this.updatedAt});
  factory _EventModel.fromJson(Map<String, dynamic> json) => _$EventModelFromJson(json);

@override final  String eventId;
@override final  String publicEventId;
@override final  DateTime eventStartDatetime;
@override final  String kennelId;
@override final  int isVisible;
@override final  int isCountedRun;
@override final  int isPromotedEvent;
@override final  int eventGeographicScope;
@override final  int eventInboundIntegrationId;
@override final  int eventNumber;
@override final  String eventName;
@override final  String countryId;
@override final  double? hcLatitude;
@override final  double? hcLongitude;
@override final  double? fbLatitude;
@override final  double? fbLongitude;
@override final  double? eventPriceForMembers;
@override final  double? eventPriceForNonMembers;
@override final  int? evtDisseminateAllowWebLinks;
@override final  String? eventFacebookId;
@override final  int? absoluteEventNumber;
@override final  int? canEditRunAttendence;
@override final  String? eventImage;
@override final  String? eventDescription;
@override final  String? eventUrl;
@override final  String? locationOneLineDesc;
@override final  String? locationPostCode;
@override final  String? locationCity;
@override final  String? locationStreet;
@override final  String? locationCountry;
@override final  String? locationRegion;
@override final  String? locationSubRegion;
@override final  String? hares;
@override final  String? eventPaymentScheme;
@override final  String? eventPaymentUrl;
@override final  DateTime? eventPaymentUrlExpires;
@override final  int? unconfirmedBankXferCount;
@override final  double? eventPriceForExtras;
@override final  String? extrasDescription;
@override final  int doTrackHashCash;
@override final  int tags1;
@override final  int tags2;
@override final  int tags3;
@override final  int useFbLocation;
@override final  int useFbLatLon;
@override final  int useFbRunDetails;
@override final  int useFbImage;
@override final  int? removed;
@override final  DateTime? updatedAt;

/// Create a copy of EventModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EventModelCopyWith<_EventModel> get copyWith => __$EventModelCopyWithImpl<_EventModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EventModelToJson(this, );
}
@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'EventModel'))
    ..add(DiagnosticsProperty('eventId', eventId))..add(DiagnosticsProperty('publicEventId', publicEventId))..add(DiagnosticsProperty('eventStartDatetime', eventStartDatetime))..add(DiagnosticsProperty('kennelId', kennelId))..add(DiagnosticsProperty('isVisible', isVisible))..add(DiagnosticsProperty('isCountedRun', isCountedRun))..add(DiagnosticsProperty('isPromotedEvent', isPromotedEvent))..add(DiagnosticsProperty('eventGeographicScope', eventGeographicScope))..add(DiagnosticsProperty('eventInboundIntegrationId', eventInboundIntegrationId))..add(DiagnosticsProperty('eventNumber', eventNumber))..add(DiagnosticsProperty('eventName', eventName))..add(DiagnosticsProperty('countryId', countryId))..add(DiagnosticsProperty('hcLatitude', hcLatitude))..add(DiagnosticsProperty('hcLongitude', hcLongitude))..add(DiagnosticsProperty('fbLatitude', fbLatitude))..add(DiagnosticsProperty('fbLongitude', fbLongitude))..add(DiagnosticsProperty('eventPriceForMembers', eventPriceForMembers))..add(DiagnosticsProperty('eventPriceForNonMembers', eventPriceForNonMembers))..add(DiagnosticsProperty('evtDisseminateAllowWebLinks', evtDisseminateAllowWebLinks))..add(DiagnosticsProperty('eventFacebookId', eventFacebookId))..add(DiagnosticsProperty('absoluteEventNumber', absoluteEventNumber))..add(DiagnosticsProperty('canEditRunAttendence', canEditRunAttendence))..add(DiagnosticsProperty('eventImage', eventImage))..add(DiagnosticsProperty('eventDescription', eventDescription))..add(DiagnosticsProperty('eventUrl', eventUrl))..add(DiagnosticsProperty('locationOneLineDesc', locationOneLineDesc))..add(DiagnosticsProperty('locationPostCode', locationPostCode))..add(DiagnosticsProperty('locationCity', locationCity))..add(DiagnosticsProperty('locationStreet', locationStreet))..add(DiagnosticsProperty('locationCountry', locationCountry))..add(DiagnosticsProperty('locationRegion', locationRegion))..add(DiagnosticsProperty('locationSubRegion', locationSubRegion))..add(DiagnosticsProperty('hares', hares))..add(DiagnosticsProperty('eventPaymentScheme', eventPaymentScheme))..add(DiagnosticsProperty('eventPaymentUrl', eventPaymentUrl))..add(DiagnosticsProperty('eventPaymentUrlExpires', eventPaymentUrlExpires))..add(DiagnosticsProperty('unconfirmedBankXferCount', unconfirmedBankXferCount))..add(DiagnosticsProperty('eventPriceForExtras', eventPriceForExtras))..add(DiagnosticsProperty('extrasDescription', extrasDescription))..add(DiagnosticsProperty('doTrackHashCash', doTrackHashCash))..add(DiagnosticsProperty('tags1', tags1))..add(DiagnosticsProperty('tags2', tags2))..add(DiagnosticsProperty('tags3', tags3))..add(DiagnosticsProperty('useFbLocation', useFbLocation))..add(DiagnosticsProperty('useFbLatLon', useFbLatLon))..add(DiagnosticsProperty('useFbRunDetails', useFbRunDetails))..add(DiagnosticsProperty('useFbImage', useFbImage))..add(DiagnosticsProperty('removed', removed))..add(DiagnosticsProperty('updatedAt', updatedAt));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EventModel&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.publicEventId, publicEventId) || other.publicEventId == publicEventId)&&(identical(other.eventStartDatetime, eventStartDatetime) || other.eventStartDatetime == eventStartDatetime)&&(identical(other.kennelId, kennelId) || other.kennelId == kennelId)&&(identical(other.isVisible, isVisible) || other.isVisible == isVisible)&&(identical(other.isCountedRun, isCountedRun) || other.isCountedRun == isCountedRun)&&(identical(other.isPromotedEvent, isPromotedEvent) || other.isPromotedEvent == isPromotedEvent)&&(identical(other.eventGeographicScope, eventGeographicScope) || other.eventGeographicScope == eventGeographicScope)&&(identical(other.eventInboundIntegrationId, eventInboundIntegrationId) || other.eventInboundIntegrationId == eventInboundIntegrationId)&&(identical(other.eventNumber, eventNumber) || other.eventNumber == eventNumber)&&(identical(other.eventName, eventName) || other.eventName == eventName)&&(identical(other.countryId, countryId) || other.countryId == countryId)&&(identical(other.hcLatitude, hcLatitude) || other.hcLatitude == hcLatitude)&&(identical(other.hcLongitude, hcLongitude) || other.hcLongitude == hcLongitude)&&(identical(other.fbLatitude, fbLatitude) || other.fbLatitude == fbLatitude)&&(identical(other.fbLongitude, fbLongitude) || other.fbLongitude == fbLongitude)&&(identical(other.eventPriceForMembers, eventPriceForMembers) || other.eventPriceForMembers == eventPriceForMembers)&&(identical(other.eventPriceForNonMembers, eventPriceForNonMembers) || other.eventPriceForNonMembers == eventPriceForNonMembers)&&(identical(other.evtDisseminateAllowWebLinks, evtDisseminateAllowWebLinks) || other.evtDisseminateAllowWebLinks == evtDisseminateAllowWebLinks)&&(identical(other.eventFacebookId, eventFacebookId) || other.eventFacebookId == eventFacebookId)&&(identical(other.absoluteEventNumber, absoluteEventNumber) || other.absoluteEventNumber == absoluteEventNumber)&&(identical(other.canEditRunAttendence, canEditRunAttendence) || other.canEditRunAttendence == canEditRunAttendence)&&(identical(other.eventImage, eventImage) || other.eventImage == eventImage)&&(identical(other.eventDescription, eventDescription) || other.eventDescription == eventDescription)&&(identical(other.eventUrl, eventUrl) || other.eventUrl == eventUrl)&&(identical(other.locationOneLineDesc, locationOneLineDesc) || other.locationOneLineDesc == locationOneLineDesc)&&(identical(other.locationPostCode, locationPostCode) || other.locationPostCode == locationPostCode)&&(identical(other.locationCity, locationCity) || other.locationCity == locationCity)&&(identical(other.locationStreet, locationStreet) || other.locationStreet == locationStreet)&&(identical(other.locationCountry, locationCountry) || other.locationCountry == locationCountry)&&(identical(other.locationRegion, locationRegion) || other.locationRegion == locationRegion)&&(identical(other.locationSubRegion, locationSubRegion) || other.locationSubRegion == locationSubRegion)&&(identical(other.hares, hares) || other.hares == hares)&&(identical(other.eventPaymentScheme, eventPaymentScheme) || other.eventPaymentScheme == eventPaymentScheme)&&(identical(other.eventPaymentUrl, eventPaymentUrl) || other.eventPaymentUrl == eventPaymentUrl)&&(identical(other.eventPaymentUrlExpires, eventPaymentUrlExpires) || other.eventPaymentUrlExpires == eventPaymentUrlExpires)&&(identical(other.unconfirmedBankXferCount, unconfirmedBankXferCount) || other.unconfirmedBankXferCount == unconfirmedBankXferCount)&&(identical(other.eventPriceForExtras, eventPriceForExtras) || other.eventPriceForExtras == eventPriceForExtras)&&(identical(other.extrasDescription, extrasDescription) || other.extrasDescription == extrasDescription)&&(identical(other.doTrackHashCash, doTrackHashCash) || other.doTrackHashCash == doTrackHashCash)&&(identical(other.tags1, tags1) || other.tags1 == tags1)&&(identical(other.tags2, tags2) || other.tags2 == tags2)&&(identical(other.tags3, tags3) || other.tags3 == tags3)&&(identical(other.useFbLocation, useFbLocation) || other.useFbLocation == useFbLocation)&&(identical(other.useFbLatLon, useFbLatLon) || other.useFbLatLon == useFbLatLon)&&(identical(other.useFbRunDetails, useFbRunDetails) || other.useFbRunDetails == useFbRunDetails)&&(identical(other.useFbImage, useFbImage) || other.useFbImage == useFbImage)&&(identical(other.removed, removed) || other.removed == removed)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,eventId,publicEventId,eventStartDatetime,kennelId,isVisible,isCountedRun,isPromotedEvent,eventGeographicScope,eventInboundIntegrationId,eventNumber,eventName,countryId,hcLatitude,hcLongitude,fbLatitude,fbLongitude,eventPriceForMembers,eventPriceForNonMembers,evtDisseminateAllowWebLinks,eventFacebookId,absoluteEventNumber,canEditRunAttendence,eventImage,eventDescription,eventUrl,locationOneLineDesc,locationPostCode,locationCity,locationStreet,locationCountry,locationRegion,locationSubRegion,hares,eventPaymentScheme,eventPaymentUrl,eventPaymentUrlExpires,unconfirmedBankXferCount,eventPriceForExtras,extrasDescription,doTrackHashCash,tags1,tags2,tags3,useFbLocation,useFbLatLon,useFbRunDetails,useFbImage,removed,updatedAt]);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'EventModel(eventId: $eventId, publicEventId: $publicEventId, eventStartDatetime: $eventStartDatetime, kennelId: $kennelId, isVisible: $isVisible, isCountedRun: $isCountedRun, isPromotedEvent: $isPromotedEvent, eventGeographicScope: $eventGeographicScope, eventInboundIntegrationId: $eventInboundIntegrationId, eventNumber: $eventNumber, eventName: $eventName, countryId: $countryId, hcLatitude: $hcLatitude, hcLongitude: $hcLongitude, fbLatitude: $fbLatitude, fbLongitude: $fbLongitude, eventPriceForMembers: $eventPriceForMembers, eventPriceForNonMembers: $eventPriceForNonMembers, evtDisseminateAllowWebLinks: $evtDisseminateAllowWebLinks, eventFacebookId: $eventFacebookId, absoluteEventNumber: $absoluteEventNumber, canEditRunAttendence: $canEditRunAttendence, eventImage: $eventImage, eventDescription: $eventDescription, eventUrl: $eventUrl, locationOneLineDesc: $locationOneLineDesc, locationPostCode: $locationPostCode, locationCity: $locationCity, locationStreet: $locationStreet, locationCountry: $locationCountry, locationRegion: $locationRegion, locationSubRegion: $locationSubRegion, hares: $hares, eventPaymentScheme: $eventPaymentScheme, eventPaymentUrl: $eventPaymentUrl, eventPaymentUrlExpires: $eventPaymentUrlExpires, unconfirmedBankXferCount: $unconfirmedBankXferCount, eventPriceForExtras: $eventPriceForExtras, extrasDescription: $extrasDescription, doTrackHashCash: $doTrackHashCash, tags1: $tags1, tags2: $tags2, tags3: $tags3, useFbLocation: $useFbLocation, useFbLatLon: $useFbLatLon, useFbRunDetails: $useFbRunDetails, useFbImage: $useFbImage, removed: $removed, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$EventModelCopyWith<$Res> implements $EventModelCopyWith<$Res> {
  factory _$EventModelCopyWith(_EventModel value, $Res Function(_EventModel) _then) = __$EventModelCopyWithImpl;
@override @useResult
$Res call({
 String eventId, String publicEventId, DateTime eventStartDatetime, String kennelId, int isVisible, int isCountedRun, int isPromotedEvent, int eventGeographicScope, int eventInboundIntegrationId, int eventNumber, String eventName, String countryId, double? hcLatitude, double? hcLongitude, double? fbLatitude, double? fbLongitude, double? eventPriceForMembers, double? eventPriceForNonMembers, int? evtDisseminateAllowWebLinks, String? eventFacebookId, int? absoluteEventNumber, int? canEditRunAttendence, String? eventImage, String? eventDescription, String? eventUrl, String? locationOneLineDesc, String? locationPostCode, String? locationCity, String? locationStreet, String? locationCountry, String? locationRegion, String? locationSubRegion, String? hares, String? eventPaymentScheme, String? eventPaymentUrl, DateTime? eventPaymentUrlExpires, int? unconfirmedBankXferCount, double? eventPriceForExtras, String? extrasDescription, int doTrackHashCash, int tags1, int tags2, int tags3, int useFbLocation, int useFbLatLon, int useFbRunDetails, int useFbImage, int? removed, DateTime? updatedAt
});




}
/// @nodoc
class __$EventModelCopyWithImpl<$Res>
    implements _$EventModelCopyWith<$Res> {
  __$EventModelCopyWithImpl(this._self, this._then);

  final _EventModel _self;
  final $Res Function(_EventModel) _then;

/// Create a copy of EventModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? eventId = null,Object? publicEventId = null,Object? eventStartDatetime = null,Object? kennelId = null,Object? isVisible = null,Object? isCountedRun = null,Object? isPromotedEvent = null,Object? eventGeographicScope = null,Object? eventInboundIntegrationId = null,Object? eventNumber = null,Object? eventName = null,Object? countryId = null,Object? hcLatitude = freezed,Object? hcLongitude = freezed,Object? fbLatitude = freezed,Object? fbLongitude = freezed,Object? eventPriceForMembers = freezed,Object? eventPriceForNonMembers = freezed,Object? evtDisseminateAllowWebLinks = freezed,Object? eventFacebookId = freezed,Object? absoluteEventNumber = freezed,Object? canEditRunAttendence = freezed,Object? eventImage = freezed,Object? eventDescription = freezed,Object? eventUrl = freezed,Object? locationOneLineDesc = freezed,Object? locationPostCode = freezed,Object? locationCity = freezed,Object? locationStreet = freezed,Object? locationCountry = freezed,Object? locationRegion = freezed,Object? locationSubRegion = freezed,Object? hares = freezed,Object? eventPaymentScheme = freezed,Object? eventPaymentUrl = freezed,Object? eventPaymentUrlExpires = freezed,Object? unconfirmedBankXferCount = freezed,Object? eventPriceForExtras = freezed,Object? extrasDescription = freezed,Object? doTrackHashCash = null,Object? tags1 = null,Object? tags2 = null,Object? tags3 = null,Object? useFbLocation = null,Object? useFbLatLon = null,Object? useFbRunDetails = null,Object? useFbImage = null,Object? removed = freezed,Object? updatedAt = freezed,}) {
  return _then(_EventModel(
eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,publicEventId: null == publicEventId ? _self.publicEventId : publicEventId // ignore: cast_nullable_to_non_nullable
as String,eventStartDatetime: null == eventStartDatetime ? _self.eventStartDatetime : eventStartDatetime // ignore: cast_nullable_to_non_nullable
as DateTime,kennelId: null == kennelId ? _self.kennelId : kennelId // ignore: cast_nullable_to_non_nullable
as String,isVisible: null == isVisible ? _self.isVisible : isVisible // ignore: cast_nullable_to_non_nullable
as int,isCountedRun: null == isCountedRun ? _self.isCountedRun : isCountedRun // ignore: cast_nullable_to_non_nullable
as int,isPromotedEvent: null == isPromotedEvent ? _self.isPromotedEvent : isPromotedEvent // ignore: cast_nullable_to_non_nullable
as int,eventGeographicScope: null == eventGeographicScope ? _self.eventGeographicScope : eventGeographicScope // ignore: cast_nullable_to_non_nullable
as int,eventInboundIntegrationId: null == eventInboundIntegrationId ? _self.eventInboundIntegrationId : eventInboundIntegrationId // ignore: cast_nullable_to_non_nullable
as int,eventNumber: null == eventNumber ? _self.eventNumber : eventNumber // ignore: cast_nullable_to_non_nullable
as int,eventName: null == eventName ? _self.eventName : eventName // ignore: cast_nullable_to_non_nullable
as String,countryId: null == countryId ? _self.countryId : countryId // ignore: cast_nullable_to_non_nullable
as String,hcLatitude: freezed == hcLatitude ? _self.hcLatitude : hcLatitude // ignore: cast_nullable_to_non_nullable
as double?,hcLongitude: freezed == hcLongitude ? _self.hcLongitude : hcLongitude // ignore: cast_nullable_to_non_nullable
as double?,fbLatitude: freezed == fbLatitude ? _self.fbLatitude : fbLatitude // ignore: cast_nullable_to_non_nullable
as double?,fbLongitude: freezed == fbLongitude ? _self.fbLongitude : fbLongitude // ignore: cast_nullable_to_non_nullable
as double?,eventPriceForMembers: freezed == eventPriceForMembers ? _self.eventPriceForMembers : eventPriceForMembers // ignore: cast_nullable_to_non_nullable
as double?,eventPriceForNonMembers: freezed == eventPriceForNonMembers ? _self.eventPriceForNonMembers : eventPriceForNonMembers // ignore: cast_nullable_to_non_nullable
as double?,evtDisseminateAllowWebLinks: freezed == evtDisseminateAllowWebLinks ? _self.evtDisseminateAllowWebLinks : evtDisseminateAllowWebLinks // ignore: cast_nullable_to_non_nullable
as int?,eventFacebookId: freezed == eventFacebookId ? _self.eventFacebookId : eventFacebookId // ignore: cast_nullable_to_non_nullable
as String?,absoluteEventNumber: freezed == absoluteEventNumber ? _self.absoluteEventNumber : absoluteEventNumber // ignore: cast_nullable_to_non_nullable
as int?,canEditRunAttendence: freezed == canEditRunAttendence ? _self.canEditRunAttendence : canEditRunAttendence // ignore: cast_nullable_to_non_nullable
as int?,eventImage: freezed == eventImage ? _self.eventImage : eventImage // ignore: cast_nullable_to_non_nullable
as String?,eventDescription: freezed == eventDescription ? _self.eventDescription : eventDescription // ignore: cast_nullable_to_non_nullable
as String?,eventUrl: freezed == eventUrl ? _self.eventUrl : eventUrl // ignore: cast_nullable_to_non_nullable
as String?,locationOneLineDesc: freezed == locationOneLineDesc ? _self.locationOneLineDesc : locationOneLineDesc // ignore: cast_nullable_to_non_nullable
as String?,locationPostCode: freezed == locationPostCode ? _self.locationPostCode : locationPostCode // ignore: cast_nullable_to_non_nullable
as String?,locationCity: freezed == locationCity ? _self.locationCity : locationCity // ignore: cast_nullable_to_non_nullable
as String?,locationStreet: freezed == locationStreet ? _self.locationStreet : locationStreet // ignore: cast_nullable_to_non_nullable
as String?,locationCountry: freezed == locationCountry ? _self.locationCountry : locationCountry // ignore: cast_nullable_to_non_nullable
as String?,locationRegion: freezed == locationRegion ? _self.locationRegion : locationRegion // ignore: cast_nullable_to_non_nullable
as String?,locationSubRegion: freezed == locationSubRegion ? _self.locationSubRegion : locationSubRegion // ignore: cast_nullable_to_non_nullable
as String?,hares: freezed == hares ? _self.hares : hares // ignore: cast_nullable_to_non_nullable
as String?,eventPaymentScheme: freezed == eventPaymentScheme ? _self.eventPaymentScheme : eventPaymentScheme // ignore: cast_nullable_to_non_nullable
as String?,eventPaymentUrl: freezed == eventPaymentUrl ? _self.eventPaymentUrl : eventPaymentUrl // ignore: cast_nullable_to_non_nullable
as String?,eventPaymentUrlExpires: freezed == eventPaymentUrlExpires ? _self.eventPaymentUrlExpires : eventPaymentUrlExpires // ignore: cast_nullable_to_non_nullable
as DateTime?,unconfirmedBankXferCount: freezed == unconfirmedBankXferCount ? _self.unconfirmedBankXferCount : unconfirmedBankXferCount // ignore: cast_nullable_to_non_nullable
as int?,eventPriceForExtras: freezed == eventPriceForExtras ? _self.eventPriceForExtras : eventPriceForExtras // ignore: cast_nullable_to_non_nullable
as double?,extrasDescription: freezed == extrasDescription ? _self.extrasDescription : extrasDescription // ignore: cast_nullable_to_non_nullable
as String?,doTrackHashCash: null == doTrackHashCash ? _self.doTrackHashCash : doTrackHashCash // ignore: cast_nullable_to_non_nullable
as int,tags1: null == tags1 ? _self.tags1 : tags1 // ignore: cast_nullable_to_non_nullable
as int,tags2: null == tags2 ? _self.tags2 : tags2 // ignore: cast_nullable_to_non_nullable
as int,tags3: null == tags3 ? _self.tags3 : tags3 // ignore: cast_nullable_to_non_nullable
as int,useFbLocation: null == useFbLocation ? _self.useFbLocation : useFbLocation // ignore: cast_nullable_to_non_nullable
as int,useFbLatLon: null == useFbLatLon ? _self.useFbLatLon : useFbLatLon // ignore: cast_nullable_to_non_nullable
as int,useFbRunDetails: null == useFbRunDetails ? _self.useFbRunDetails : useFbRunDetails // ignore: cast_nullable_to_non_nullable
as int,useFbImage: null == useFbImage ? _self.useFbImage : useFbImage // ignore: cast_nullable_to_non_nullable
as int,removed: freezed == removed ? _self.removed : removed // ignore: cast_nullable_to_non_nullable
as int?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
