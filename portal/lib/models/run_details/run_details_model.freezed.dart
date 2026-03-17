// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'run_details_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RunDetailsModel implements DiagnosticableTreeMixin {
  String get publicKennelId;
  DateTime get eventStartDatetime;
  int get isVisible;
  int get isCountedRun;
  int get isPromotedEvent;
  int get eventGeographicScope;
  int get eventNumber;
  String get eventName;
  String get eventDescription;
  int get extrasRsvpRequired;
  int get tags1;
  int get tags2;
  int get tags3;
  int get useFbLocation;
  int get useFbLatLon;
  int get useFbRunDetails;
  int get useFbImage;
  int get integrationEnabled;
  int get kenDisseminateHashRunsDotOrg;
  int get kenDisseminateAllowWebLinks;
  int get kenDisseminationAudience;
  String get countryId;
  String get countryName;
  String? get publicEventId;
  int? get evtDisseminationAudience;
  int? get evtDisseminateAllowWebLinks;
  int? get evtDisseminateHashRunsDotOrg;
  int? get evtDisseminateOnGlobalGoogleCalendar;
  int? get kenDisseminateOnGlobalGoogleCalendar;
  double? get cityLatitude;
  double? get cityLongitude;
  int? get doTrackHashCash;
  int? get inboundIntegrationId;
  String? get kennelName;
  String? get kennelCountryCodes;
  double? get kennelDefaultEventPriceForMembers;
  double? get kennelDefaultEventPriceForNonMembers;
  int? get digitsAfterDecimal;
  String? get currencySymbol;
  String? get extEventName;
  DateTime? get eventEndDatetime;
  DateTime? get extDataLastUpdated;
  DateTime? get extEventStartDatetime;
  double? get hcLatitude;
  double? get hcLongitude;
  double? get fbLatitude;
  double? get fbLongitude;
  double? get kenLatitude;
  double? get kenLongitude;
  String? get kennelLogo;
  String? get kennelShortName;
  String? get kennelUniqueShortName;
  double? get eventPriceForMembers;
  double? get eventPriceForNonMembers;
  String? get eventFacebookId;
  int? get absoluteEventNumber;
  int? get canEditRunAttendence;
  int? get maximumParticipantsAllowed;
  int? get minimumParticipantsRequired;
  int? get eventChatMessageCount;
  String? get eventImage;
  String? get extEventImage;
  String? get extEventDescription;
  String? get extLocationOneLineDesc;
  String? get extLocationPostCode;
  String? get extLocationCity;
  String? get extLocationStreet;
  String? get extLocationCountry;
  String? get extLocationRegion;
  String? get extLocationSubRegion;
  String? get locationOneLineDesc;
  String? get locationPostCode;
  String? get locationCity;
  String? get locationStreet;
  String? get locationCountry;
  String? get locationRegion;
  String? get locationSubRegion;
  String? get locationPhoneNumber;
  String? get hares;
  String? get eventPaymentScheme;
  String? get eventPaymentUrl;
  DateTime? get eventPaymentUrlExpires;
  num? get eventPriceForExtras;
  String? get extrasDescription;

  /// Create a copy of RunDetailsModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $RunDetailsModelCopyWith<RunDetailsModel> get copyWith =>
      _$RunDetailsModelCopyWithImpl<RunDetailsModel>(
          this as RunDetailsModel, _$identity);

  /// Serializes this RunDetailsModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'RunDetailsModel'))
      ..add(DiagnosticsProperty('publicKennelId', publicKennelId))
      ..add(DiagnosticsProperty('eventStartDatetime', eventStartDatetime))
      ..add(DiagnosticsProperty('isVisible', isVisible))
      ..add(DiagnosticsProperty('isCountedRun', isCountedRun))
      ..add(DiagnosticsProperty('isPromotedEvent', isPromotedEvent))
      ..add(DiagnosticsProperty('eventGeographicScope', eventGeographicScope))
      ..add(DiagnosticsProperty('eventNumber', eventNumber))
      ..add(DiagnosticsProperty('eventName', eventName))
      ..add(DiagnosticsProperty('eventDescription', eventDescription))
      ..add(DiagnosticsProperty('extrasRsvpRequired', extrasRsvpRequired))
      ..add(DiagnosticsProperty('tags1', tags1))
      ..add(DiagnosticsProperty('tags2', tags2))
      ..add(DiagnosticsProperty('tags3', tags3))
      ..add(DiagnosticsProperty('useFbLocation', useFbLocation))
      ..add(DiagnosticsProperty('useFbLatLon', useFbLatLon))
      ..add(DiagnosticsProperty('useFbRunDetails', useFbRunDetails))
      ..add(DiagnosticsProperty('useFbImage', useFbImage))
      ..add(DiagnosticsProperty('integrationEnabled', integrationEnabled))
      ..add(DiagnosticsProperty(
          'kenDisseminateHashRunsDotOrg', kenDisseminateHashRunsDotOrg))
      ..add(DiagnosticsProperty(
          'kenDisseminateAllowWebLinks', kenDisseminateAllowWebLinks))
      ..add(DiagnosticsProperty(
          'kenDisseminationAudience', kenDisseminationAudience))
      ..add(DiagnosticsProperty('countryId', countryId))
      ..add(DiagnosticsProperty('countryName', countryName))
      ..add(DiagnosticsProperty('publicEventId', publicEventId))
      ..add(DiagnosticsProperty(
          'evtDisseminationAudience', evtDisseminationAudience))
      ..add(DiagnosticsProperty(
          'evtDisseminateAllowWebLinks', evtDisseminateAllowWebLinks))
      ..add(DiagnosticsProperty(
          'evtDisseminateHashRunsDotOrg', evtDisseminateHashRunsDotOrg))
      ..add(DiagnosticsProperty('evtDisseminateOnGlobalGoogleCalendar',
          evtDisseminateOnGlobalGoogleCalendar))
      ..add(DiagnosticsProperty('kenDisseminateOnGlobalGoogleCalendar',
          kenDisseminateOnGlobalGoogleCalendar))
      ..add(DiagnosticsProperty('cityLatitude', cityLatitude))
      ..add(DiagnosticsProperty('cityLongitude', cityLongitude))
      ..add(DiagnosticsProperty('doTrackHashCash', doTrackHashCash))
      ..add(DiagnosticsProperty('inboundIntegrationId', inboundIntegrationId))
      ..add(DiagnosticsProperty('kennelName', kennelName))
      ..add(DiagnosticsProperty('kennelCountryCodes', kennelCountryCodes))
      ..add(DiagnosticsProperty('kennelDefaultEventPriceForMembers',
          kennelDefaultEventPriceForMembers))
      ..add(DiagnosticsProperty('kennelDefaultEventPriceForNonMembers',
          kennelDefaultEventPriceForNonMembers))
      ..add(DiagnosticsProperty('digitsAfterDecimal', digitsAfterDecimal))
      ..add(DiagnosticsProperty('currencySymbol', currencySymbol))
      ..add(DiagnosticsProperty('extEventName', extEventName))
      ..add(DiagnosticsProperty('eventEndDatetime', eventEndDatetime))
      ..add(DiagnosticsProperty('extDataLastUpdated', extDataLastUpdated))
      ..add(DiagnosticsProperty('extEventStartDatetime', extEventStartDatetime))
      ..add(DiagnosticsProperty('hcLatitude', hcLatitude))
      ..add(DiagnosticsProperty('hcLongitude', hcLongitude))
      ..add(DiagnosticsProperty('fbLatitude', fbLatitude))
      ..add(DiagnosticsProperty('fbLongitude', fbLongitude))
      ..add(DiagnosticsProperty('kenLatitude', kenLatitude))
      ..add(DiagnosticsProperty('kenLongitude', kenLongitude))
      ..add(DiagnosticsProperty('kennelLogo', kennelLogo))
      ..add(DiagnosticsProperty('kennelShortName', kennelShortName))
      ..add(DiagnosticsProperty('kennelUniqueShortName', kennelUniqueShortName))
      ..add(DiagnosticsProperty('eventPriceForMembers', eventPriceForMembers))
      ..add(DiagnosticsProperty(
          'eventPriceForNonMembers', eventPriceForNonMembers))
      ..add(DiagnosticsProperty('eventFacebookId', eventFacebookId))
      ..add(DiagnosticsProperty('absoluteEventNumber', absoluteEventNumber))
      ..add(DiagnosticsProperty('canEditRunAttendence', canEditRunAttendence))
      ..add(DiagnosticsProperty(
          'maximumParticipantsAllowed', maximumParticipantsAllowed))
      ..add(DiagnosticsProperty(
          'minimumParticipantsRequired', minimumParticipantsRequired))
      ..add(DiagnosticsProperty('eventChatMessageCount', eventChatMessageCount))
      ..add(DiagnosticsProperty('eventImage', eventImage))
      ..add(DiagnosticsProperty('extEventImage', extEventImage))
      ..add(DiagnosticsProperty('extEventDescription', extEventDescription))
      ..add(
          DiagnosticsProperty('extLocationOneLineDesc', extLocationOneLineDesc))
      ..add(DiagnosticsProperty('extLocationPostCode', extLocationPostCode))
      ..add(DiagnosticsProperty('extLocationCity', extLocationCity))
      ..add(DiagnosticsProperty('extLocationStreet', extLocationStreet))
      ..add(DiagnosticsProperty('extLocationCountry', extLocationCountry))
      ..add(DiagnosticsProperty('extLocationRegion', extLocationRegion))
      ..add(DiagnosticsProperty('extLocationSubRegion', extLocationSubRegion))
      ..add(DiagnosticsProperty('locationOneLineDesc', locationOneLineDesc))
      ..add(DiagnosticsProperty('locationPostCode', locationPostCode))
      ..add(DiagnosticsProperty('locationCity', locationCity))
      ..add(DiagnosticsProperty('locationStreet', locationStreet))
      ..add(DiagnosticsProperty('locationCountry', locationCountry))
      ..add(DiagnosticsProperty('locationRegion', locationRegion))
      ..add(DiagnosticsProperty('locationSubRegion', locationSubRegion))
      ..add(DiagnosticsProperty('locationPhoneNumber', locationPhoneNumber))
      ..add(DiagnosticsProperty('hares', hares))
      ..add(DiagnosticsProperty('eventPaymentScheme', eventPaymentScheme))
      ..add(DiagnosticsProperty('eventPaymentUrl', eventPaymentUrl))
      ..add(
          DiagnosticsProperty('eventPaymentUrlExpires', eventPaymentUrlExpires))
      ..add(DiagnosticsProperty('eventPriceForExtras', eventPriceForExtras))
      ..add(DiagnosticsProperty('extrasDescription', extrasDescription));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is RunDetailsModel &&
            (identical(other.publicKennelId, publicKennelId) ||
                other.publicKennelId == publicKennelId) &&
            (identical(other.eventStartDatetime, eventStartDatetime) ||
                other.eventStartDatetime == eventStartDatetime) &&
            (identical(other.isVisible, isVisible) ||
                other.isVisible == isVisible) &&
            (identical(other.isCountedRun, isCountedRun) ||
                other.isCountedRun == isCountedRun) &&
            (identical(other.isPromotedEvent, isPromotedEvent) ||
                other.isPromotedEvent == isPromotedEvent) &&
            (identical(other.eventGeographicScope, eventGeographicScope) ||
                other.eventGeographicScope == eventGeographicScope) &&
            (identical(other.eventNumber, eventNumber) ||
                other.eventNumber == eventNumber) &&
            (identical(other.eventName, eventName) ||
                other.eventName == eventName) &&
            (identical(other.eventDescription, eventDescription) ||
                other.eventDescription == eventDescription) &&
            (identical(other.extrasRsvpRequired, extrasRsvpRequired) ||
                other.extrasRsvpRequired == extrasRsvpRequired) &&
            (identical(other.tags1, tags1) || other.tags1 == tags1) &&
            (identical(other.tags2, tags2) || other.tags2 == tags2) &&
            (identical(other.tags3, tags3) || other.tags3 == tags3) &&
            (identical(other.useFbLocation, useFbLocation) ||
                other.useFbLocation == useFbLocation) &&
            (identical(other.useFbLatLon, useFbLatLon) ||
                other.useFbLatLon == useFbLatLon) &&
            (identical(other.useFbRunDetails, useFbRunDetails) ||
                other.useFbRunDetails == useFbRunDetails) &&
            (identical(other.useFbImage, useFbImage) ||
                other.useFbImage == useFbImage) &&
            (identical(other.integrationEnabled, integrationEnabled) ||
                other.integrationEnabled == integrationEnabled) &&
            (identical(other.kenDisseminateHashRunsDotOrg, kenDisseminateHashRunsDotOrg) ||
                other.kenDisseminateHashRunsDotOrg ==
                    kenDisseminateHashRunsDotOrg) &&
            (identical(other.kenDisseminateAllowWebLinks, kenDisseminateAllowWebLinks) ||
                other.kenDisseminateAllowWebLinks ==
                    kenDisseminateAllowWebLinks) &&
            (identical(other.kenDisseminationAudience, kenDisseminationAudience) ||
                other.kenDisseminationAudience == kenDisseminationAudience) &&
            (identical(other.countryId, countryId) ||
                other.countryId == countryId) &&
            (identical(other.countryName, countryName) ||
                other.countryName == countryName) &&
            (identical(other.publicEventId, publicEventId) ||
                other.publicEventId == publicEventId) &&
            (identical(other.evtDisseminationAudience, evtDisseminationAudience) ||
                other.evtDisseminationAudience == evtDisseminationAudience) &&
            (identical(other.evtDisseminateAllowWebLinks, evtDisseminateAllowWebLinks) ||
                other.evtDisseminateAllowWebLinks ==
                    evtDisseminateAllowWebLinks) &&
            (identical(other.evtDisseminateHashRunsDotOrg, evtDisseminateHashRunsDotOrg) ||
                other.evtDisseminateHashRunsDotOrg ==
                    evtDisseminateHashRunsDotOrg) &&
            (identical(other.evtDisseminateOnGlobalGoogleCalendar, evtDisseminateOnGlobalGoogleCalendar) ||
                other.evtDisseminateOnGlobalGoogleCalendar ==
                    evtDisseminateOnGlobalGoogleCalendar) &&
            (identical(other.kenDisseminateOnGlobalGoogleCalendar, kenDisseminateOnGlobalGoogleCalendar) ||
                other.kenDisseminateOnGlobalGoogleCalendar ==
                    kenDisseminateOnGlobalGoogleCalendar) &&
            (identical(other.cityLatitude, cityLatitude) ||
                other.cityLatitude == cityLatitude) &&
            (identical(other.cityLongitude, cityLongitude) ||
                other.cityLongitude == cityLongitude) &&
            (identical(other.doTrackHashCash, doTrackHashCash) || other.doTrackHashCash == doTrackHashCash) &&
            (identical(other.inboundIntegrationId, inboundIntegrationId) || other.inboundIntegrationId == inboundIntegrationId) &&
            (identical(other.kennelName, kennelName) || other.kennelName == kennelName) &&
            (identical(other.kennelCountryCodes, kennelCountryCodes) || other.kennelCountryCodes == kennelCountryCodes) &&
            (identical(other.kennelDefaultEventPriceForMembers, kennelDefaultEventPriceForMembers) || other.kennelDefaultEventPriceForMembers == kennelDefaultEventPriceForMembers) &&
            (identical(other.kennelDefaultEventPriceForNonMembers, kennelDefaultEventPriceForNonMembers) || other.kennelDefaultEventPriceForNonMembers == kennelDefaultEventPriceForNonMembers) &&
            (identical(other.digitsAfterDecimal, digitsAfterDecimal) || other.digitsAfterDecimal == digitsAfterDecimal) &&
            (identical(other.currencySymbol, currencySymbol) || other.currencySymbol == currencySymbol) &&
            (identical(other.extEventName, extEventName) || other.extEventName == extEventName) &&
            (identical(other.eventEndDatetime, eventEndDatetime) || other.eventEndDatetime == eventEndDatetime) &&
            (identical(other.extDataLastUpdated, extDataLastUpdated) || other.extDataLastUpdated == extDataLastUpdated) &&
            (identical(other.extEventStartDatetime, extEventStartDatetime) || other.extEventStartDatetime == extEventStartDatetime) &&
            (identical(other.hcLatitude, hcLatitude) || other.hcLatitude == hcLatitude) &&
            (identical(other.hcLongitude, hcLongitude) || other.hcLongitude == hcLongitude) &&
            (identical(other.fbLatitude, fbLatitude) || other.fbLatitude == fbLatitude) &&
            (identical(other.fbLongitude, fbLongitude) || other.fbLongitude == fbLongitude) &&
            (identical(other.kenLatitude, kenLatitude) || other.kenLatitude == kenLatitude) &&
            (identical(other.kenLongitude, kenLongitude) || other.kenLongitude == kenLongitude) &&
            (identical(other.kennelLogo, kennelLogo) || other.kennelLogo == kennelLogo) &&
            (identical(other.kennelShortName, kennelShortName) || other.kennelShortName == kennelShortName) &&
            (identical(other.kennelUniqueShortName, kennelUniqueShortName) || other.kennelUniqueShortName == kennelUniqueShortName) &&
            (identical(other.eventPriceForMembers, eventPriceForMembers) || other.eventPriceForMembers == eventPriceForMembers) &&
            (identical(other.eventPriceForNonMembers, eventPriceForNonMembers) || other.eventPriceForNonMembers == eventPriceForNonMembers) &&
            (identical(other.eventFacebookId, eventFacebookId) || other.eventFacebookId == eventFacebookId) &&
            (identical(other.absoluteEventNumber, absoluteEventNumber) || other.absoluteEventNumber == absoluteEventNumber) &&
            (identical(other.canEditRunAttendence, canEditRunAttendence) || other.canEditRunAttendence == canEditRunAttendence) &&
            (identical(other.maximumParticipantsAllowed, maximumParticipantsAllowed) || other.maximumParticipantsAllowed == maximumParticipantsAllowed) &&
            (identical(other.minimumParticipantsRequired, minimumParticipantsRequired) || other.minimumParticipantsRequired == minimumParticipantsRequired) &&
            (identical(other.eventChatMessageCount, eventChatMessageCount) || other.eventChatMessageCount == eventChatMessageCount) &&
            (identical(other.eventImage, eventImage) || other.eventImage == eventImage) &&
            (identical(other.extEventImage, extEventImage) || other.extEventImage == extEventImage) &&
            (identical(other.extEventDescription, extEventDescription) || other.extEventDescription == extEventDescription) &&
            (identical(other.extLocationOneLineDesc, extLocationOneLineDesc) || other.extLocationOneLineDesc == extLocationOneLineDesc) &&
            (identical(other.extLocationPostCode, extLocationPostCode) || other.extLocationPostCode == extLocationPostCode) &&
            (identical(other.extLocationCity, extLocationCity) || other.extLocationCity == extLocationCity) &&
            (identical(other.extLocationStreet, extLocationStreet) || other.extLocationStreet == extLocationStreet) &&
            (identical(other.extLocationCountry, extLocationCountry) || other.extLocationCountry == extLocationCountry) &&
            (identical(other.extLocationRegion, extLocationRegion) || other.extLocationRegion == extLocationRegion) &&
            (identical(other.extLocationSubRegion, extLocationSubRegion) || other.extLocationSubRegion == extLocationSubRegion) &&
            (identical(other.locationOneLineDesc, locationOneLineDesc) || other.locationOneLineDesc == locationOneLineDesc) &&
            (identical(other.locationPostCode, locationPostCode) || other.locationPostCode == locationPostCode) &&
            (identical(other.locationCity, locationCity) || other.locationCity == locationCity) &&
            (identical(other.locationStreet, locationStreet) || other.locationStreet == locationStreet) &&
            (identical(other.locationCountry, locationCountry) || other.locationCountry == locationCountry) &&
            (identical(other.locationRegion, locationRegion) || other.locationRegion == locationRegion) &&
            (identical(other.locationSubRegion, locationSubRegion) || other.locationSubRegion == locationSubRegion) &&
            (identical(other.locationPhoneNumber, locationPhoneNumber) || other.locationPhoneNumber == locationPhoneNumber) &&
            (identical(other.hares, hares) || other.hares == hares) &&
            (identical(other.eventPaymentScheme, eventPaymentScheme) || other.eventPaymentScheme == eventPaymentScheme) &&
            (identical(other.eventPaymentUrl, eventPaymentUrl) || other.eventPaymentUrl == eventPaymentUrl) &&
            (identical(other.eventPaymentUrlExpires, eventPaymentUrlExpires) || other.eventPaymentUrlExpires == eventPaymentUrlExpires) &&
            (identical(other.eventPriceForExtras, eventPriceForExtras) || other.eventPriceForExtras == eventPriceForExtras) &&
            (identical(other.extrasDescription, extrasDescription) || other.extrasDescription == extrasDescription));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        publicKennelId,
        eventStartDatetime,
        isVisible,
        isCountedRun,
        isPromotedEvent,
        eventGeographicScope,
        eventNumber,
        eventName,
        eventDescription,
        extrasRsvpRequired,
        tags1,
        tags2,
        tags3,
        useFbLocation,
        useFbLatLon,
        useFbRunDetails,
        useFbImage,
        integrationEnabled,
        kenDisseminateHashRunsDotOrg,
        kenDisseminateAllowWebLinks,
        kenDisseminationAudience,
        countryId,
        countryName,
        publicEventId,
        evtDisseminationAudience,
        evtDisseminateAllowWebLinks,
        evtDisseminateHashRunsDotOrg,
        evtDisseminateOnGlobalGoogleCalendar,
        kenDisseminateOnGlobalGoogleCalendar,
        cityLatitude,
        cityLongitude,
        doTrackHashCash,
        inboundIntegrationId,
        kennelName,
        kennelCountryCodes,
        kennelDefaultEventPriceForMembers,
        kennelDefaultEventPriceForNonMembers,
        digitsAfterDecimal,
        currencySymbol,
        extEventName,
        eventEndDatetime,
        extDataLastUpdated,
        extEventStartDatetime,
        hcLatitude,
        hcLongitude,
        fbLatitude,
        fbLongitude,
        kenLatitude,
        kenLongitude,
        kennelLogo,
        kennelShortName,
        kennelUniqueShortName,
        eventPriceForMembers,
        eventPriceForNonMembers,
        eventFacebookId,
        absoluteEventNumber,
        canEditRunAttendence,
        maximumParticipantsAllowed,
        minimumParticipantsRequired,
        eventChatMessageCount,
        eventImage,
        extEventImage,
        extEventDescription,
        extLocationOneLineDesc,
        extLocationPostCode,
        extLocationCity,
        extLocationStreet,
        extLocationCountry,
        extLocationRegion,
        extLocationSubRegion,
        locationOneLineDesc,
        locationPostCode,
        locationCity,
        locationStreet,
        locationCountry,
        locationRegion,
        locationSubRegion,
        locationPhoneNumber,
        hares,
        eventPaymentScheme,
        eventPaymentUrl,
        eventPaymentUrlExpires,
        eventPriceForExtras,
        extrasDescription
      ]);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'RunDetailsModel(publicKennelId: $publicKennelId, eventStartDatetime: $eventStartDatetime, isVisible: $isVisible, isCountedRun: $isCountedRun, isPromotedEvent: $isPromotedEvent, eventGeographicScope: $eventGeographicScope, eventNumber: $eventNumber, eventName: $eventName, eventDescription: $eventDescription, extrasRsvpRequired: $extrasRsvpRequired, tags1: $tags1, tags2: $tags2, tags3: $tags3, useFbLocation: $useFbLocation, useFbLatLon: $useFbLatLon, useFbRunDetails: $useFbRunDetails, useFbImage: $useFbImage, integrationEnabled: $integrationEnabled, kenDisseminateHashRunsDotOrg: $kenDisseminateHashRunsDotOrg, kenDisseminateAllowWebLinks: $kenDisseminateAllowWebLinks, kenDisseminationAudience: $kenDisseminationAudience, countryId: $countryId, countryName: $countryName, publicEventId: $publicEventId, evtDisseminationAudience: $evtDisseminationAudience, evtDisseminateAllowWebLinks: $evtDisseminateAllowWebLinks, evtDisseminateHashRunsDotOrg: $evtDisseminateHashRunsDotOrg, evtDisseminateOnGlobalGoogleCalendar: $evtDisseminateOnGlobalGoogleCalendar, kenDisseminateOnGlobalGoogleCalendar: $kenDisseminateOnGlobalGoogleCalendar, cityLatitude: $cityLatitude, cityLongitude: $cityLongitude, doTrackHashCash: $doTrackHashCash, inboundIntegrationId: $inboundIntegrationId, kennelName: $kennelName, kennelCountryCodes: $kennelCountryCodes, kennelDefaultEventPriceForMembers: $kennelDefaultEventPriceForMembers, kennelDefaultEventPriceForNonMembers: $kennelDefaultEventPriceForNonMembers, digitsAfterDecimal: $digitsAfterDecimal, currencySymbol: $currencySymbol, extEventName: $extEventName, eventEndDatetime: $eventEndDatetime, extDataLastUpdated: $extDataLastUpdated, extEventStartDatetime: $extEventStartDatetime, hcLatitude: $hcLatitude, hcLongitude: $hcLongitude, fbLatitude: $fbLatitude, fbLongitude: $fbLongitude, kenLatitude: $kenLatitude, kenLongitude: $kenLongitude, kennelLogo: $kennelLogo, kennelShortName: $kennelShortName, kennelUniqueShortName: $kennelUniqueShortName, eventPriceForMembers: $eventPriceForMembers, eventPriceForNonMembers: $eventPriceForNonMembers, eventFacebookId: $eventFacebookId, absoluteEventNumber: $absoluteEventNumber, canEditRunAttendence: $canEditRunAttendence, maximumParticipantsAllowed: $maximumParticipantsAllowed, minimumParticipantsRequired: $minimumParticipantsRequired, eventChatMessageCount: $eventChatMessageCount, eventImage: $eventImage, extEventImage: $extEventImage, extEventDescription: $extEventDescription, extLocationOneLineDesc: $extLocationOneLineDesc, extLocationPostCode: $extLocationPostCode, extLocationCity: $extLocationCity, extLocationStreet: $extLocationStreet, extLocationCountry: $extLocationCountry, extLocationRegion: $extLocationRegion, extLocationSubRegion: $extLocationSubRegion, locationOneLineDesc: $locationOneLineDesc, locationPostCode: $locationPostCode, locationCity: $locationCity, locationStreet: $locationStreet, locationCountry: $locationCountry, locationRegion: $locationRegion, locationSubRegion: $locationSubRegion, locationPhoneNumber: $locationPhoneNumber, hares: $hares, eventPaymentScheme: $eventPaymentScheme, eventPaymentUrl: $eventPaymentUrl, eventPaymentUrlExpires: $eventPaymentUrlExpires, eventPriceForExtras: $eventPriceForExtras, extrasDescription: $extrasDescription)';
  }
}

/// @nodoc
abstract mixin class $RunDetailsModelCopyWith<$Res> {
  factory $RunDetailsModelCopyWith(
          RunDetailsModel value, $Res Function(RunDetailsModel) _then) =
      _$RunDetailsModelCopyWithImpl;
  @useResult
  $Res call(
      {String publicKennelId,
      DateTime eventStartDatetime,
      int isVisible,
      int isCountedRun,
      int isPromotedEvent,
      int eventGeographicScope,
      int eventNumber,
      String eventName,
      String eventDescription,
      int extrasRsvpRequired,
      int tags1,
      int tags2,
      int tags3,
      int useFbLocation,
      int useFbLatLon,
      int useFbRunDetails,
      int useFbImage,
      int integrationEnabled,
      int kenDisseminateHashRunsDotOrg,
      int kenDisseminateAllowWebLinks,
      int kenDisseminationAudience,
      String countryId,
      String countryName,
      String? publicEventId,
      int? evtDisseminationAudience,
      int? evtDisseminateAllowWebLinks,
      int? evtDisseminateHashRunsDotOrg,
      int? evtDisseminateOnGlobalGoogleCalendar,
      int? kenDisseminateOnGlobalGoogleCalendar,
      double? cityLatitude,
      double? cityLongitude,
      int? doTrackHashCash,
      int? inboundIntegrationId,
      String? kennelName,
      String? kennelCountryCodes,
      double? kennelDefaultEventPriceForMembers,
      double? kennelDefaultEventPriceForNonMembers,
      int? digitsAfterDecimal,
      String? currencySymbol,
      String? extEventName,
      DateTime? eventEndDatetime,
      DateTime? extDataLastUpdated,
      DateTime? extEventStartDatetime,
      double? hcLatitude,
      double? hcLongitude,
      double? fbLatitude,
      double? fbLongitude,
      double? kenLatitude,
      double? kenLongitude,
      String? kennelLogo,
      String? kennelShortName,
      String? kennelUniqueShortName,
      double? eventPriceForMembers,
      double? eventPriceForNonMembers,
      String? eventFacebookId,
      int? absoluteEventNumber,
      int? canEditRunAttendence,
      int? maximumParticipantsAllowed,
      int? minimumParticipantsRequired,
      int? eventChatMessageCount,
      String? eventImage,
      String? extEventImage,
      String? extEventDescription,
      String? extLocationOneLineDesc,
      String? extLocationPostCode,
      String? extLocationCity,
      String? extLocationStreet,
      String? extLocationCountry,
      String? extLocationRegion,
      String? extLocationSubRegion,
      String? locationOneLineDesc,
      String? locationPostCode,
      String? locationCity,
      String? locationStreet,
      String? locationCountry,
      String? locationRegion,
      String? locationSubRegion,
      String? locationPhoneNumber,
      String? hares,
      String? eventPaymentScheme,
      String? eventPaymentUrl,
      DateTime? eventPaymentUrlExpires,
      num? eventPriceForExtras,
      String? extrasDescription});
}

/// @nodoc
class _$RunDetailsModelCopyWithImpl<$Res>
    implements $RunDetailsModelCopyWith<$Res> {
  _$RunDetailsModelCopyWithImpl(this._self, this._then);

  final RunDetailsModel _self;
  final $Res Function(RunDetailsModel) _then;

  /// Create a copy of RunDetailsModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? publicKennelId = null,
    Object? eventStartDatetime = null,
    Object? isVisible = null,
    Object? isCountedRun = null,
    Object? isPromotedEvent = null,
    Object? eventGeographicScope = null,
    Object? eventNumber = null,
    Object? eventName = null,
    Object? eventDescription = null,
    Object? extrasRsvpRequired = null,
    Object? tags1 = null,
    Object? tags2 = null,
    Object? tags3 = null,
    Object? useFbLocation = null,
    Object? useFbLatLon = null,
    Object? useFbRunDetails = null,
    Object? useFbImage = null,
    Object? integrationEnabled = null,
    Object? kenDisseminateHashRunsDotOrg = null,
    Object? kenDisseminateAllowWebLinks = null,
    Object? kenDisseminationAudience = null,
    Object? countryId = null,
    Object? countryName = null,
    Object? publicEventId = freezed,
    Object? evtDisseminationAudience = freezed,
    Object? evtDisseminateAllowWebLinks = freezed,
    Object? evtDisseminateHashRunsDotOrg = freezed,
    Object? evtDisseminateOnGlobalGoogleCalendar = freezed,
    Object? kenDisseminateOnGlobalGoogleCalendar = freezed,
    Object? cityLatitude = freezed,
    Object? cityLongitude = freezed,
    Object? doTrackHashCash = freezed,
    Object? inboundIntegrationId = freezed,
    Object? kennelName = freezed,
    Object? kennelCountryCodes = freezed,
    Object? kennelDefaultEventPriceForMembers = freezed,
    Object? kennelDefaultEventPriceForNonMembers = freezed,
    Object? digitsAfterDecimal = freezed,
    Object? currencySymbol = freezed,
    Object? extEventName = freezed,
    Object? eventEndDatetime = freezed,
    Object? extDataLastUpdated = freezed,
    Object? extEventStartDatetime = freezed,
    Object? hcLatitude = freezed,
    Object? hcLongitude = freezed,
    Object? fbLatitude = freezed,
    Object? fbLongitude = freezed,
    Object? kenLatitude = freezed,
    Object? kenLongitude = freezed,
    Object? kennelLogo = freezed,
    Object? kennelShortName = freezed,
    Object? kennelUniqueShortName = freezed,
    Object? eventPriceForMembers = freezed,
    Object? eventPriceForNonMembers = freezed,
    Object? eventFacebookId = freezed,
    Object? absoluteEventNumber = freezed,
    Object? canEditRunAttendence = freezed,
    Object? maximumParticipantsAllowed = freezed,
    Object? minimumParticipantsRequired = freezed,
    Object? eventChatMessageCount = freezed,
    Object? eventImage = freezed,
    Object? extEventImage = freezed,
    Object? extEventDescription = freezed,
    Object? extLocationOneLineDesc = freezed,
    Object? extLocationPostCode = freezed,
    Object? extLocationCity = freezed,
    Object? extLocationStreet = freezed,
    Object? extLocationCountry = freezed,
    Object? extLocationRegion = freezed,
    Object? extLocationSubRegion = freezed,
    Object? locationOneLineDesc = freezed,
    Object? locationPostCode = freezed,
    Object? locationCity = freezed,
    Object? locationStreet = freezed,
    Object? locationCountry = freezed,
    Object? locationRegion = freezed,
    Object? locationSubRegion = freezed,
    Object? locationPhoneNumber = freezed,
    Object? hares = freezed,
    Object? eventPaymentScheme = freezed,
    Object? eventPaymentUrl = freezed,
    Object? eventPaymentUrlExpires = freezed,
    Object? eventPriceForExtras = freezed,
    Object? extrasDescription = freezed,
  }) {
    return _then(_self.copyWith(
      publicKennelId: null == publicKennelId
          ? _self.publicKennelId
          : publicKennelId // ignore: cast_nullable_to_non_nullable
              as String,
      eventStartDatetime: null == eventStartDatetime
          ? _self.eventStartDatetime
          : eventStartDatetime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isVisible: null == isVisible
          ? _self.isVisible
          : isVisible // ignore: cast_nullable_to_non_nullable
              as int,
      isCountedRun: null == isCountedRun
          ? _self.isCountedRun
          : isCountedRun // ignore: cast_nullable_to_non_nullable
              as int,
      isPromotedEvent: null == isPromotedEvent
          ? _self.isPromotedEvent
          : isPromotedEvent // ignore: cast_nullable_to_non_nullable
              as int,
      eventGeographicScope: null == eventGeographicScope
          ? _self.eventGeographicScope
          : eventGeographicScope // ignore: cast_nullable_to_non_nullable
              as int,
      eventNumber: null == eventNumber
          ? _self.eventNumber
          : eventNumber // ignore: cast_nullable_to_non_nullable
              as int,
      eventName: null == eventName
          ? _self.eventName
          : eventName // ignore: cast_nullable_to_non_nullable
              as String,
      eventDescription: null == eventDescription
          ? _self.eventDescription
          : eventDescription // ignore: cast_nullable_to_non_nullable
              as String,
      extrasRsvpRequired: null == extrasRsvpRequired
          ? _self.extrasRsvpRequired
          : extrasRsvpRequired // ignore: cast_nullable_to_non_nullable
              as int,
      tags1: null == tags1
          ? _self.tags1
          : tags1 // ignore: cast_nullable_to_non_nullable
              as int,
      tags2: null == tags2
          ? _self.tags2
          : tags2 // ignore: cast_nullable_to_non_nullable
              as int,
      tags3: null == tags3
          ? _self.tags3
          : tags3 // ignore: cast_nullable_to_non_nullable
              as int,
      useFbLocation: null == useFbLocation
          ? _self.useFbLocation
          : useFbLocation // ignore: cast_nullable_to_non_nullable
              as int,
      useFbLatLon: null == useFbLatLon
          ? _self.useFbLatLon
          : useFbLatLon // ignore: cast_nullable_to_non_nullable
              as int,
      useFbRunDetails: null == useFbRunDetails
          ? _self.useFbRunDetails
          : useFbRunDetails // ignore: cast_nullable_to_non_nullable
              as int,
      useFbImage: null == useFbImage
          ? _self.useFbImage
          : useFbImage // ignore: cast_nullable_to_non_nullable
              as int,
      integrationEnabled: null == integrationEnabled
          ? _self.integrationEnabled
          : integrationEnabled // ignore: cast_nullable_to_non_nullable
              as int,
      kenDisseminateHashRunsDotOrg: null == kenDisseminateHashRunsDotOrg
          ? _self.kenDisseminateHashRunsDotOrg
          : kenDisseminateHashRunsDotOrg // ignore: cast_nullable_to_non_nullable
              as int,
      kenDisseminateAllowWebLinks: null == kenDisseminateAllowWebLinks
          ? _self.kenDisseminateAllowWebLinks
          : kenDisseminateAllowWebLinks // ignore: cast_nullable_to_non_nullable
              as int,
      kenDisseminationAudience: null == kenDisseminationAudience
          ? _self.kenDisseminationAudience
          : kenDisseminationAudience // ignore: cast_nullable_to_non_nullable
              as int,
      countryId: null == countryId
          ? _self.countryId
          : countryId // ignore: cast_nullable_to_non_nullable
              as String,
      countryName: null == countryName
          ? _self.countryName
          : countryName // ignore: cast_nullable_to_non_nullable
              as String,
      publicEventId: freezed == publicEventId
          ? _self.publicEventId
          : publicEventId // ignore: cast_nullable_to_non_nullable
              as String?,
      evtDisseminationAudience: freezed == evtDisseminationAudience
          ? _self.evtDisseminationAudience
          : evtDisseminationAudience // ignore: cast_nullable_to_non_nullable
              as int?,
      evtDisseminateAllowWebLinks: freezed == evtDisseminateAllowWebLinks
          ? _self.evtDisseminateAllowWebLinks
          : evtDisseminateAllowWebLinks // ignore: cast_nullable_to_non_nullable
              as int?,
      evtDisseminateHashRunsDotOrg: freezed == evtDisseminateHashRunsDotOrg
          ? _self.evtDisseminateHashRunsDotOrg
          : evtDisseminateHashRunsDotOrg // ignore: cast_nullable_to_non_nullable
              as int?,
      evtDisseminateOnGlobalGoogleCalendar: freezed ==
              evtDisseminateOnGlobalGoogleCalendar
          ? _self.evtDisseminateOnGlobalGoogleCalendar
          : evtDisseminateOnGlobalGoogleCalendar // ignore: cast_nullable_to_non_nullable
              as int?,
      kenDisseminateOnGlobalGoogleCalendar: freezed ==
              kenDisseminateOnGlobalGoogleCalendar
          ? _self.kenDisseminateOnGlobalGoogleCalendar
          : kenDisseminateOnGlobalGoogleCalendar // ignore: cast_nullable_to_non_nullable
              as int?,
      cityLatitude: freezed == cityLatitude
          ? _self.cityLatitude
          : cityLatitude // ignore: cast_nullable_to_non_nullable
              as double?,
      cityLongitude: freezed == cityLongitude
          ? _self.cityLongitude
          : cityLongitude // ignore: cast_nullable_to_non_nullable
              as double?,
      doTrackHashCash: freezed == doTrackHashCash
          ? _self.doTrackHashCash
          : doTrackHashCash // ignore: cast_nullable_to_non_nullable
              as int?,
      inboundIntegrationId: freezed == inboundIntegrationId
          ? _self.inboundIntegrationId
          : inboundIntegrationId // ignore: cast_nullable_to_non_nullable
              as int?,
      kennelName: freezed == kennelName
          ? _self.kennelName
          : kennelName // ignore: cast_nullable_to_non_nullable
              as String?,
      kennelCountryCodes: freezed == kennelCountryCodes
          ? _self.kennelCountryCodes
          : kennelCountryCodes // ignore: cast_nullable_to_non_nullable
              as String?,
      kennelDefaultEventPriceForMembers: freezed ==
              kennelDefaultEventPriceForMembers
          ? _self.kennelDefaultEventPriceForMembers
          : kennelDefaultEventPriceForMembers // ignore: cast_nullable_to_non_nullable
              as double?,
      kennelDefaultEventPriceForNonMembers: freezed ==
              kennelDefaultEventPriceForNonMembers
          ? _self.kennelDefaultEventPriceForNonMembers
          : kennelDefaultEventPriceForNonMembers // ignore: cast_nullable_to_non_nullable
              as double?,
      digitsAfterDecimal: freezed == digitsAfterDecimal
          ? _self.digitsAfterDecimal
          : digitsAfterDecimal // ignore: cast_nullable_to_non_nullable
              as int?,
      currencySymbol: freezed == currencySymbol
          ? _self.currencySymbol
          : currencySymbol // ignore: cast_nullable_to_non_nullable
              as String?,
      extEventName: freezed == extEventName
          ? _self.extEventName
          : extEventName // ignore: cast_nullable_to_non_nullable
              as String?,
      eventEndDatetime: freezed == eventEndDatetime
          ? _self.eventEndDatetime
          : eventEndDatetime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      extDataLastUpdated: freezed == extDataLastUpdated
          ? _self.extDataLastUpdated
          : extDataLastUpdated // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      extEventStartDatetime: freezed == extEventStartDatetime
          ? _self.extEventStartDatetime
          : extEventStartDatetime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      hcLatitude: freezed == hcLatitude
          ? _self.hcLatitude
          : hcLatitude // ignore: cast_nullable_to_non_nullable
              as double?,
      hcLongitude: freezed == hcLongitude
          ? _self.hcLongitude
          : hcLongitude // ignore: cast_nullable_to_non_nullable
              as double?,
      fbLatitude: freezed == fbLatitude
          ? _self.fbLatitude
          : fbLatitude // ignore: cast_nullable_to_non_nullable
              as double?,
      fbLongitude: freezed == fbLongitude
          ? _self.fbLongitude
          : fbLongitude // ignore: cast_nullable_to_non_nullable
              as double?,
      kenLatitude: freezed == kenLatitude
          ? _self.kenLatitude
          : kenLatitude // ignore: cast_nullable_to_non_nullable
              as double?,
      kenLongitude: freezed == kenLongitude
          ? _self.kenLongitude
          : kenLongitude // ignore: cast_nullable_to_non_nullable
              as double?,
      kennelLogo: freezed == kennelLogo
          ? _self.kennelLogo
          : kennelLogo // ignore: cast_nullable_to_non_nullable
              as String?,
      kennelShortName: freezed == kennelShortName
          ? _self.kennelShortName
          : kennelShortName // ignore: cast_nullable_to_non_nullable
              as String?,
      kennelUniqueShortName: freezed == kennelUniqueShortName
          ? _self.kennelUniqueShortName
          : kennelUniqueShortName // ignore: cast_nullable_to_non_nullable
              as String?,
      eventPriceForMembers: freezed == eventPriceForMembers
          ? _self.eventPriceForMembers
          : eventPriceForMembers // ignore: cast_nullable_to_non_nullable
              as double?,
      eventPriceForNonMembers: freezed == eventPriceForNonMembers
          ? _self.eventPriceForNonMembers
          : eventPriceForNonMembers // ignore: cast_nullable_to_non_nullable
              as double?,
      eventFacebookId: freezed == eventFacebookId
          ? _self.eventFacebookId
          : eventFacebookId // ignore: cast_nullable_to_non_nullable
              as String?,
      absoluteEventNumber: freezed == absoluteEventNumber
          ? _self.absoluteEventNumber
          : absoluteEventNumber // ignore: cast_nullable_to_non_nullable
              as int?,
      canEditRunAttendence: freezed == canEditRunAttendence
          ? _self.canEditRunAttendence
          : canEditRunAttendence // ignore: cast_nullable_to_non_nullable
              as int?,
      maximumParticipantsAllowed: freezed == maximumParticipantsAllowed
          ? _self.maximumParticipantsAllowed
          : maximumParticipantsAllowed // ignore: cast_nullable_to_non_nullable
              as int?,
      minimumParticipantsRequired: freezed == minimumParticipantsRequired
          ? _self.minimumParticipantsRequired
          : minimumParticipantsRequired // ignore: cast_nullable_to_non_nullable
              as int?,
      eventChatMessageCount: freezed == eventChatMessageCount
          ? _self.eventChatMessageCount
          : eventChatMessageCount // ignore: cast_nullable_to_non_nullable
              as int?,
      eventImage: freezed == eventImage
          ? _self.eventImage
          : eventImage // ignore: cast_nullable_to_non_nullable
              as String?,
      extEventImage: freezed == extEventImage
          ? _self.extEventImage
          : extEventImage // ignore: cast_nullable_to_non_nullable
              as String?,
      extEventDescription: freezed == extEventDescription
          ? _self.extEventDescription
          : extEventDescription // ignore: cast_nullable_to_non_nullable
              as String?,
      extLocationOneLineDesc: freezed == extLocationOneLineDesc
          ? _self.extLocationOneLineDesc
          : extLocationOneLineDesc // ignore: cast_nullable_to_non_nullable
              as String?,
      extLocationPostCode: freezed == extLocationPostCode
          ? _self.extLocationPostCode
          : extLocationPostCode // ignore: cast_nullable_to_non_nullable
              as String?,
      extLocationCity: freezed == extLocationCity
          ? _self.extLocationCity
          : extLocationCity // ignore: cast_nullable_to_non_nullable
              as String?,
      extLocationStreet: freezed == extLocationStreet
          ? _self.extLocationStreet
          : extLocationStreet // ignore: cast_nullable_to_non_nullable
              as String?,
      extLocationCountry: freezed == extLocationCountry
          ? _self.extLocationCountry
          : extLocationCountry // ignore: cast_nullable_to_non_nullable
              as String?,
      extLocationRegion: freezed == extLocationRegion
          ? _self.extLocationRegion
          : extLocationRegion // ignore: cast_nullable_to_non_nullable
              as String?,
      extLocationSubRegion: freezed == extLocationSubRegion
          ? _self.extLocationSubRegion
          : extLocationSubRegion // ignore: cast_nullable_to_non_nullable
              as String?,
      locationOneLineDesc: freezed == locationOneLineDesc
          ? _self.locationOneLineDesc
          : locationOneLineDesc // ignore: cast_nullable_to_non_nullable
              as String?,
      locationPostCode: freezed == locationPostCode
          ? _self.locationPostCode
          : locationPostCode // ignore: cast_nullable_to_non_nullable
              as String?,
      locationCity: freezed == locationCity
          ? _self.locationCity
          : locationCity // ignore: cast_nullable_to_non_nullable
              as String?,
      locationStreet: freezed == locationStreet
          ? _self.locationStreet
          : locationStreet // ignore: cast_nullable_to_non_nullable
              as String?,
      locationCountry: freezed == locationCountry
          ? _self.locationCountry
          : locationCountry // ignore: cast_nullable_to_non_nullable
              as String?,
      locationRegion: freezed == locationRegion
          ? _self.locationRegion
          : locationRegion // ignore: cast_nullable_to_non_nullable
              as String?,
      locationSubRegion: freezed == locationSubRegion
          ? _self.locationSubRegion
          : locationSubRegion // ignore: cast_nullable_to_non_nullable
              as String?,
      locationPhoneNumber: freezed == locationPhoneNumber
          ? _self.locationPhoneNumber
          : locationPhoneNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      hares: freezed == hares
          ? _self.hares
          : hares // ignore: cast_nullable_to_non_nullable
              as String?,
      eventPaymentScheme: freezed == eventPaymentScheme
          ? _self.eventPaymentScheme
          : eventPaymentScheme // ignore: cast_nullable_to_non_nullable
              as String?,
      eventPaymentUrl: freezed == eventPaymentUrl
          ? _self.eventPaymentUrl
          : eventPaymentUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      eventPaymentUrlExpires: freezed == eventPaymentUrlExpires
          ? _self.eventPaymentUrlExpires
          : eventPaymentUrlExpires // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      eventPriceForExtras: freezed == eventPriceForExtras
          ? _self.eventPriceForExtras
          : eventPriceForExtras // ignore: cast_nullable_to_non_nullable
              as num?,
      extrasDescription: freezed == extrasDescription
          ? _self.extrasDescription
          : extrasDescription // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [RunDetailsModel].
extension RunDetailsModelPatterns on RunDetailsModel {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_RunDetailsModel value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _RunDetailsModel() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_RunDetailsModel value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RunDetailsModel():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_RunDetailsModel value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RunDetailsModel() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            String publicKennelId,
            DateTime eventStartDatetime,
            int isVisible,
            int isCountedRun,
            int isPromotedEvent,
            int eventGeographicScope,
            int eventNumber,
            String eventName,
            String eventDescription,
            int extrasRsvpRequired,
            int tags1,
            int tags2,
            int tags3,
            int useFbLocation,
            int useFbLatLon,
            int useFbRunDetails,
            int useFbImage,
            int integrationEnabled,
            int kenDisseminateHashRunsDotOrg,
            int kenDisseminateAllowWebLinks,
            int kenDisseminationAudience,
            String countryId,
            String countryName,
            String? publicEventId,
            int? evtDisseminationAudience,
            int? evtDisseminateAllowWebLinks,
            int? evtDisseminateHashRunsDotOrg,
            int? evtDisseminateOnGlobalGoogleCalendar,
            int? kenDisseminateOnGlobalGoogleCalendar,
            double? cityLatitude,
            double? cityLongitude,
            int? doTrackHashCash,
            int? inboundIntegrationId,
            String? kennelName,
            String? kennelCountryCodes,
            double? kennelDefaultEventPriceForMembers,
            double? kennelDefaultEventPriceForNonMembers,
            int? digitsAfterDecimal,
            String? currencySymbol,
            String? extEventName,
            DateTime? eventEndDatetime,
            DateTime? extDataLastUpdated,
            DateTime? extEventStartDatetime,
            double? hcLatitude,
            double? hcLongitude,
            double? fbLatitude,
            double? fbLongitude,
            double? kenLatitude,
            double? kenLongitude,
            String? kennelLogo,
            String? kennelShortName,
            String? kennelUniqueShortName,
            double? eventPriceForMembers,
            double? eventPriceForNonMembers,
            String? eventFacebookId,
            int? absoluteEventNumber,
            int? canEditRunAttendence,
            int? maximumParticipantsAllowed,
            int? minimumParticipantsRequired,
            int? eventChatMessageCount,
            String? eventImage,
            String? extEventImage,
            String? extEventDescription,
            String? extLocationOneLineDesc,
            String? extLocationPostCode,
            String? extLocationCity,
            String? extLocationStreet,
            String? extLocationCountry,
            String? extLocationRegion,
            String? extLocationSubRegion,
            String? locationOneLineDesc,
            String? locationPostCode,
            String? locationCity,
            String? locationStreet,
            String? locationCountry,
            String? locationRegion,
            String? locationSubRegion,
            String? locationPhoneNumber,
            String? hares,
            String? eventPaymentScheme,
            String? eventPaymentUrl,
            DateTime? eventPaymentUrlExpires,
            num? eventPriceForExtras,
            String? extrasDescription)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _RunDetailsModel() when $default != null:
        return $default(
            _that.publicKennelId,
            _that.eventStartDatetime,
            _that.isVisible,
            _that.isCountedRun,
            _that.isPromotedEvent,
            _that.eventGeographicScope,
            _that.eventNumber,
            _that.eventName,
            _that.eventDescription,
            _that.extrasRsvpRequired,
            _that.tags1,
            _that.tags2,
            _that.tags3,
            _that.useFbLocation,
            _that.useFbLatLon,
            _that.useFbRunDetails,
            _that.useFbImage,
            _that.integrationEnabled,
            _that.kenDisseminateHashRunsDotOrg,
            _that.kenDisseminateAllowWebLinks,
            _that.kenDisseminationAudience,
            _that.countryId,
            _that.countryName,
            _that.publicEventId,
            _that.evtDisseminationAudience,
            _that.evtDisseminateAllowWebLinks,
            _that.evtDisseminateHashRunsDotOrg,
            _that.evtDisseminateOnGlobalGoogleCalendar,
            _that.kenDisseminateOnGlobalGoogleCalendar,
            _that.cityLatitude,
            _that.cityLongitude,
            _that.doTrackHashCash,
            _that.inboundIntegrationId,
            _that.kennelName,
            _that.kennelCountryCodes,
            _that.kennelDefaultEventPriceForMembers,
            _that.kennelDefaultEventPriceForNonMembers,
            _that.digitsAfterDecimal,
            _that.currencySymbol,
            _that.extEventName,
            _that.eventEndDatetime,
            _that.extDataLastUpdated,
            _that.extEventStartDatetime,
            _that.hcLatitude,
            _that.hcLongitude,
            _that.fbLatitude,
            _that.fbLongitude,
            _that.kenLatitude,
            _that.kenLongitude,
            _that.kennelLogo,
            _that.kennelShortName,
            _that.kennelUniqueShortName,
            _that.eventPriceForMembers,
            _that.eventPriceForNonMembers,
            _that.eventFacebookId,
            _that.absoluteEventNumber,
            _that.canEditRunAttendence,
            _that.maximumParticipantsAllowed,
            _that.minimumParticipantsRequired,
            _that.eventChatMessageCount,
            _that.eventImage,
            _that.extEventImage,
            _that.extEventDescription,
            _that.extLocationOneLineDesc,
            _that.extLocationPostCode,
            _that.extLocationCity,
            _that.extLocationStreet,
            _that.extLocationCountry,
            _that.extLocationRegion,
            _that.extLocationSubRegion,
            _that.locationOneLineDesc,
            _that.locationPostCode,
            _that.locationCity,
            _that.locationStreet,
            _that.locationCountry,
            _that.locationRegion,
            _that.locationSubRegion,
            _that.locationPhoneNumber,
            _that.hares,
            _that.eventPaymentScheme,
            _that.eventPaymentUrl,
            _that.eventPaymentUrlExpires,
            _that.eventPriceForExtras,
            _that.extrasDescription);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            String publicKennelId,
            DateTime eventStartDatetime,
            int isVisible,
            int isCountedRun,
            int isPromotedEvent,
            int eventGeographicScope,
            int eventNumber,
            String eventName,
            String eventDescription,
            int extrasRsvpRequired,
            int tags1,
            int tags2,
            int tags3,
            int useFbLocation,
            int useFbLatLon,
            int useFbRunDetails,
            int useFbImage,
            int integrationEnabled,
            int kenDisseminateHashRunsDotOrg,
            int kenDisseminateAllowWebLinks,
            int kenDisseminationAudience,
            String countryId,
            String countryName,
            String? publicEventId,
            int? evtDisseminationAudience,
            int? evtDisseminateAllowWebLinks,
            int? evtDisseminateHashRunsDotOrg,
            int? evtDisseminateOnGlobalGoogleCalendar,
            int? kenDisseminateOnGlobalGoogleCalendar,
            double? cityLatitude,
            double? cityLongitude,
            int? doTrackHashCash,
            int? inboundIntegrationId,
            String? kennelName,
            String? kennelCountryCodes,
            double? kennelDefaultEventPriceForMembers,
            double? kennelDefaultEventPriceForNonMembers,
            int? digitsAfterDecimal,
            String? currencySymbol,
            String? extEventName,
            DateTime? eventEndDatetime,
            DateTime? extDataLastUpdated,
            DateTime? extEventStartDatetime,
            double? hcLatitude,
            double? hcLongitude,
            double? fbLatitude,
            double? fbLongitude,
            double? kenLatitude,
            double? kenLongitude,
            String? kennelLogo,
            String? kennelShortName,
            String? kennelUniqueShortName,
            double? eventPriceForMembers,
            double? eventPriceForNonMembers,
            String? eventFacebookId,
            int? absoluteEventNumber,
            int? canEditRunAttendence,
            int? maximumParticipantsAllowed,
            int? minimumParticipantsRequired,
            int? eventChatMessageCount,
            String? eventImage,
            String? extEventImage,
            String? extEventDescription,
            String? extLocationOneLineDesc,
            String? extLocationPostCode,
            String? extLocationCity,
            String? extLocationStreet,
            String? extLocationCountry,
            String? extLocationRegion,
            String? extLocationSubRegion,
            String? locationOneLineDesc,
            String? locationPostCode,
            String? locationCity,
            String? locationStreet,
            String? locationCountry,
            String? locationRegion,
            String? locationSubRegion,
            String? locationPhoneNumber,
            String? hares,
            String? eventPaymentScheme,
            String? eventPaymentUrl,
            DateTime? eventPaymentUrlExpires,
            num? eventPriceForExtras,
            String? extrasDescription)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RunDetailsModel():
        return $default(
            _that.publicKennelId,
            _that.eventStartDatetime,
            _that.isVisible,
            _that.isCountedRun,
            _that.isPromotedEvent,
            _that.eventGeographicScope,
            _that.eventNumber,
            _that.eventName,
            _that.eventDescription,
            _that.extrasRsvpRequired,
            _that.tags1,
            _that.tags2,
            _that.tags3,
            _that.useFbLocation,
            _that.useFbLatLon,
            _that.useFbRunDetails,
            _that.useFbImage,
            _that.integrationEnabled,
            _that.kenDisseminateHashRunsDotOrg,
            _that.kenDisseminateAllowWebLinks,
            _that.kenDisseminationAudience,
            _that.countryId,
            _that.countryName,
            _that.publicEventId,
            _that.evtDisseminationAudience,
            _that.evtDisseminateAllowWebLinks,
            _that.evtDisseminateHashRunsDotOrg,
            _that.evtDisseminateOnGlobalGoogleCalendar,
            _that.kenDisseminateOnGlobalGoogleCalendar,
            _that.cityLatitude,
            _that.cityLongitude,
            _that.doTrackHashCash,
            _that.inboundIntegrationId,
            _that.kennelName,
            _that.kennelCountryCodes,
            _that.kennelDefaultEventPriceForMembers,
            _that.kennelDefaultEventPriceForNonMembers,
            _that.digitsAfterDecimal,
            _that.currencySymbol,
            _that.extEventName,
            _that.eventEndDatetime,
            _that.extDataLastUpdated,
            _that.extEventStartDatetime,
            _that.hcLatitude,
            _that.hcLongitude,
            _that.fbLatitude,
            _that.fbLongitude,
            _that.kenLatitude,
            _that.kenLongitude,
            _that.kennelLogo,
            _that.kennelShortName,
            _that.kennelUniqueShortName,
            _that.eventPriceForMembers,
            _that.eventPriceForNonMembers,
            _that.eventFacebookId,
            _that.absoluteEventNumber,
            _that.canEditRunAttendence,
            _that.maximumParticipantsAllowed,
            _that.minimumParticipantsRequired,
            _that.eventChatMessageCount,
            _that.eventImage,
            _that.extEventImage,
            _that.extEventDescription,
            _that.extLocationOneLineDesc,
            _that.extLocationPostCode,
            _that.extLocationCity,
            _that.extLocationStreet,
            _that.extLocationCountry,
            _that.extLocationRegion,
            _that.extLocationSubRegion,
            _that.locationOneLineDesc,
            _that.locationPostCode,
            _that.locationCity,
            _that.locationStreet,
            _that.locationCountry,
            _that.locationRegion,
            _that.locationSubRegion,
            _that.locationPhoneNumber,
            _that.hares,
            _that.eventPaymentScheme,
            _that.eventPaymentUrl,
            _that.eventPaymentUrlExpires,
            _that.eventPriceForExtras,
            _that.extrasDescription);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            String publicKennelId,
            DateTime eventStartDatetime,
            int isVisible,
            int isCountedRun,
            int isPromotedEvent,
            int eventGeographicScope,
            int eventNumber,
            String eventName,
            String eventDescription,
            int extrasRsvpRequired,
            int tags1,
            int tags2,
            int tags3,
            int useFbLocation,
            int useFbLatLon,
            int useFbRunDetails,
            int useFbImage,
            int integrationEnabled,
            int kenDisseminateHashRunsDotOrg,
            int kenDisseminateAllowWebLinks,
            int kenDisseminationAudience,
            String countryId,
            String countryName,
            String? publicEventId,
            int? evtDisseminationAudience,
            int? evtDisseminateAllowWebLinks,
            int? evtDisseminateHashRunsDotOrg,
            int? evtDisseminateOnGlobalGoogleCalendar,
            int? kenDisseminateOnGlobalGoogleCalendar,
            double? cityLatitude,
            double? cityLongitude,
            int? doTrackHashCash,
            int? inboundIntegrationId,
            String? kennelName,
            String? kennelCountryCodes,
            double? kennelDefaultEventPriceForMembers,
            double? kennelDefaultEventPriceForNonMembers,
            int? digitsAfterDecimal,
            String? currencySymbol,
            String? extEventName,
            DateTime? eventEndDatetime,
            DateTime? extDataLastUpdated,
            DateTime? extEventStartDatetime,
            double? hcLatitude,
            double? hcLongitude,
            double? fbLatitude,
            double? fbLongitude,
            double? kenLatitude,
            double? kenLongitude,
            String? kennelLogo,
            String? kennelShortName,
            String? kennelUniqueShortName,
            double? eventPriceForMembers,
            double? eventPriceForNonMembers,
            String? eventFacebookId,
            int? absoluteEventNumber,
            int? canEditRunAttendence,
            int? maximumParticipantsAllowed,
            int? minimumParticipantsRequired,
            int? eventChatMessageCount,
            String? eventImage,
            String? extEventImage,
            String? extEventDescription,
            String? extLocationOneLineDesc,
            String? extLocationPostCode,
            String? extLocationCity,
            String? extLocationStreet,
            String? extLocationCountry,
            String? extLocationRegion,
            String? extLocationSubRegion,
            String? locationOneLineDesc,
            String? locationPostCode,
            String? locationCity,
            String? locationStreet,
            String? locationCountry,
            String? locationRegion,
            String? locationSubRegion,
            String? locationPhoneNumber,
            String? hares,
            String? eventPaymentScheme,
            String? eventPaymentUrl,
            DateTime? eventPaymentUrlExpires,
            num? eventPriceForExtras,
            String? extrasDescription)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RunDetailsModel() when $default != null:
        return $default(
            _that.publicKennelId,
            _that.eventStartDatetime,
            _that.isVisible,
            _that.isCountedRun,
            _that.isPromotedEvent,
            _that.eventGeographicScope,
            _that.eventNumber,
            _that.eventName,
            _that.eventDescription,
            _that.extrasRsvpRequired,
            _that.tags1,
            _that.tags2,
            _that.tags3,
            _that.useFbLocation,
            _that.useFbLatLon,
            _that.useFbRunDetails,
            _that.useFbImage,
            _that.integrationEnabled,
            _that.kenDisseminateHashRunsDotOrg,
            _that.kenDisseminateAllowWebLinks,
            _that.kenDisseminationAudience,
            _that.countryId,
            _that.countryName,
            _that.publicEventId,
            _that.evtDisseminationAudience,
            _that.evtDisseminateAllowWebLinks,
            _that.evtDisseminateHashRunsDotOrg,
            _that.evtDisseminateOnGlobalGoogleCalendar,
            _that.kenDisseminateOnGlobalGoogleCalendar,
            _that.cityLatitude,
            _that.cityLongitude,
            _that.doTrackHashCash,
            _that.inboundIntegrationId,
            _that.kennelName,
            _that.kennelCountryCodes,
            _that.kennelDefaultEventPriceForMembers,
            _that.kennelDefaultEventPriceForNonMembers,
            _that.digitsAfterDecimal,
            _that.currencySymbol,
            _that.extEventName,
            _that.eventEndDatetime,
            _that.extDataLastUpdated,
            _that.extEventStartDatetime,
            _that.hcLatitude,
            _that.hcLongitude,
            _that.fbLatitude,
            _that.fbLongitude,
            _that.kenLatitude,
            _that.kenLongitude,
            _that.kennelLogo,
            _that.kennelShortName,
            _that.kennelUniqueShortName,
            _that.eventPriceForMembers,
            _that.eventPriceForNonMembers,
            _that.eventFacebookId,
            _that.absoluteEventNumber,
            _that.canEditRunAttendence,
            _that.maximumParticipantsAllowed,
            _that.minimumParticipantsRequired,
            _that.eventChatMessageCount,
            _that.eventImage,
            _that.extEventImage,
            _that.extEventDescription,
            _that.extLocationOneLineDesc,
            _that.extLocationPostCode,
            _that.extLocationCity,
            _that.extLocationStreet,
            _that.extLocationCountry,
            _that.extLocationRegion,
            _that.extLocationSubRegion,
            _that.locationOneLineDesc,
            _that.locationPostCode,
            _that.locationCity,
            _that.locationStreet,
            _that.locationCountry,
            _that.locationRegion,
            _that.locationSubRegion,
            _that.locationPhoneNumber,
            _that.hares,
            _that.eventPaymentScheme,
            _that.eventPaymentUrl,
            _that.eventPaymentUrlExpires,
            _that.eventPriceForExtras,
            _that.extrasDescription);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _RunDetailsModel with DiagnosticableTreeMixin implements RunDetailsModel {
  _RunDetailsModel(
      {required this.publicKennelId,
      required this.eventStartDatetime,
      required this.isVisible,
      required this.isCountedRun,
      required this.isPromotedEvent,
      required this.eventGeographicScope,
      required this.eventNumber,
      required this.eventName,
      required this.eventDescription,
      required this.extrasRsvpRequired,
      required this.tags1,
      required this.tags2,
      required this.tags3,
      required this.useFbLocation,
      required this.useFbLatLon,
      required this.useFbRunDetails,
      required this.useFbImage,
      required this.integrationEnabled,
      required this.kenDisseminateHashRunsDotOrg,
      required this.kenDisseminateAllowWebLinks,
      required this.kenDisseminationAudience,
      required this.countryId,
      required this.countryName,
      this.publicEventId,
      this.evtDisseminationAudience,
      this.evtDisseminateAllowWebLinks,
      this.evtDisseminateHashRunsDotOrg,
      this.evtDisseminateOnGlobalGoogleCalendar,
      this.kenDisseminateOnGlobalGoogleCalendar,
      this.cityLatitude,
      this.cityLongitude,
      this.doTrackHashCash,
      this.inboundIntegrationId,
      this.kennelName,
      this.kennelCountryCodes,
      this.kennelDefaultEventPriceForMembers,
      this.kennelDefaultEventPriceForNonMembers,
      this.digitsAfterDecimal,
      this.currencySymbol,
      this.extEventName,
      this.eventEndDatetime,
      this.extDataLastUpdated,
      this.extEventStartDatetime,
      this.hcLatitude,
      this.hcLongitude,
      this.fbLatitude,
      this.fbLongitude,
      this.kenLatitude,
      this.kenLongitude,
      this.kennelLogo,
      this.kennelShortName,
      this.kennelUniqueShortName,
      this.eventPriceForMembers,
      this.eventPriceForNonMembers,
      this.eventFacebookId,
      this.absoluteEventNumber,
      this.canEditRunAttendence,
      this.maximumParticipantsAllowed,
      this.minimumParticipantsRequired,
      this.eventChatMessageCount,
      this.eventImage,
      this.extEventImage,
      this.extEventDescription,
      this.extLocationOneLineDesc,
      this.extLocationPostCode,
      this.extLocationCity,
      this.extLocationStreet,
      this.extLocationCountry,
      this.extLocationRegion,
      this.extLocationSubRegion,
      this.locationOneLineDesc,
      this.locationPostCode,
      this.locationCity,
      this.locationStreet,
      this.locationCountry,
      this.locationRegion,
      this.locationSubRegion,
      this.locationPhoneNumber,
      this.hares,
      this.eventPaymentScheme,
      this.eventPaymentUrl,
      this.eventPaymentUrlExpires,
      this.eventPriceForExtras,
      this.extrasDescription});
  factory _RunDetailsModel.fromJson(Map<String, dynamic> json) =>
      _$RunDetailsModelFromJson(json);

  @override
  final String publicKennelId;
  @override
  final DateTime eventStartDatetime;
  @override
  final int isVisible;
  @override
  final int isCountedRun;
  @override
  final int isPromotedEvent;
  @override
  final int eventGeographicScope;
  @override
  final int eventNumber;
  @override
  final String eventName;
  @override
  final String eventDescription;
  @override
  final int extrasRsvpRequired;
  @override
  final int tags1;
  @override
  final int tags2;
  @override
  final int tags3;
  @override
  final int useFbLocation;
  @override
  final int useFbLatLon;
  @override
  final int useFbRunDetails;
  @override
  final int useFbImage;
  @override
  final int integrationEnabled;
  @override
  final int kenDisseminateHashRunsDotOrg;
  @override
  final int kenDisseminateAllowWebLinks;
  @override
  final int kenDisseminationAudience;
  @override
  final String countryId;
  @override
  final String countryName;
  @override
  final String? publicEventId;
  @override
  final int? evtDisseminationAudience;
  @override
  final int? evtDisseminateAllowWebLinks;
  @override
  final int? evtDisseminateHashRunsDotOrg;
  @override
  final int? evtDisseminateOnGlobalGoogleCalendar;
  @override
  final int? kenDisseminateOnGlobalGoogleCalendar;
  @override
  final double? cityLatitude;
  @override
  final double? cityLongitude;
  @override
  final int? doTrackHashCash;
  @override
  final int? inboundIntegrationId;
  @override
  final String? kennelName;
  @override
  final String? kennelCountryCodes;
  @override
  final double? kennelDefaultEventPriceForMembers;
  @override
  final double? kennelDefaultEventPriceForNonMembers;
  @override
  final int? digitsAfterDecimal;
  @override
  final String? currencySymbol;
  @override
  final String? extEventName;
  @override
  final DateTime? eventEndDatetime;
  @override
  final DateTime? extDataLastUpdated;
  @override
  final DateTime? extEventStartDatetime;
  @override
  final double? hcLatitude;
  @override
  final double? hcLongitude;
  @override
  final double? fbLatitude;
  @override
  final double? fbLongitude;
  @override
  final double? kenLatitude;
  @override
  final double? kenLongitude;
  @override
  final String? kennelLogo;
  @override
  final String? kennelShortName;
  @override
  final String? kennelUniqueShortName;
  @override
  final double? eventPriceForMembers;
  @override
  final double? eventPriceForNonMembers;
  @override
  final String? eventFacebookId;
  @override
  final int? absoluteEventNumber;
  @override
  final int? canEditRunAttendence;
  @override
  final int? maximumParticipantsAllowed;
  @override
  final int? minimumParticipantsRequired;
  @override
  final int? eventChatMessageCount;
  @override
  final String? eventImage;
  @override
  final String? extEventImage;
  @override
  final String? extEventDescription;
  @override
  final String? extLocationOneLineDesc;
  @override
  final String? extLocationPostCode;
  @override
  final String? extLocationCity;
  @override
  final String? extLocationStreet;
  @override
  final String? extLocationCountry;
  @override
  final String? extLocationRegion;
  @override
  final String? extLocationSubRegion;
  @override
  final String? locationOneLineDesc;
  @override
  final String? locationPostCode;
  @override
  final String? locationCity;
  @override
  final String? locationStreet;
  @override
  final String? locationCountry;
  @override
  final String? locationRegion;
  @override
  final String? locationSubRegion;
  @override
  final String? locationPhoneNumber;
  @override
  final String? hares;
  @override
  final String? eventPaymentScheme;
  @override
  final String? eventPaymentUrl;
  @override
  final DateTime? eventPaymentUrlExpires;
  @override
  final num? eventPriceForExtras;
  @override
  final String? extrasDescription;

  /// Create a copy of RunDetailsModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$RunDetailsModelCopyWith<_RunDetailsModel> get copyWith =>
      __$RunDetailsModelCopyWithImpl<_RunDetailsModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$RunDetailsModelToJson(
      this,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'RunDetailsModel'))
      ..add(DiagnosticsProperty('publicKennelId', publicKennelId))
      ..add(DiagnosticsProperty('eventStartDatetime', eventStartDatetime))
      ..add(DiagnosticsProperty('isVisible', isVisible))
      ..add(DiagnosticsProperty('isCountedRun', isCountedRun))
      ..add(DiagnosticsProperty('isPromotedEvent', isPromotedEvent))
      ..add(DiagnosticsProperty('eventGeographicScope', eventGeographicScope))
      ..add(DiagnosticsProperty('eventNumber', eventNumber))
      ..add(DiagnosticsProperty('eventName', eventName))
      ..add(DiagnosticsProperty('eventDescription', eventDescription))
      ..add(DiagnosticsProperty('extrasRsvpRequired', extrasRsvpRequired))
      ..add(DiagnosticsProperty('tags1', tags1))
      ..add(DiagnosticsProperty('tags2', tags2))
      ..add(DiagnosticsProperty('tags3', tags3))
      ..add(DiagnosticsProperty('useFbLocation', useFbLocation))
      ..add(DiagnosticsProperty('useFbLatLon', useFbLatLon))
      ..add(DiagnosticsProperty('useFbRunDetails', useFbRunDetails))
      ..add(DiagnosticsProperty('useFbImage', useFbImage))
      ..add(DiagnosticsProperty('integrationEnabled', integrationEnabled))
      ..add(DiagnosticsProperty(
          'kenDisseminateHashRunsDotOrg', kenDisseminateHashRunsDotOrg))
      ..add(DiagnosticsProperty(
          'kenDisseminateAllowWebLinks', kenDisseminateAllowWebLinks))
      ..add(DiagnosticsProperty(
          'kenDisseminationAudience', kenDisseminationAudience))
      ..add(DiagnosticsProperty('countryId', countryId))
      ..add(DiagnosticsProperty('countryName', countryName))
      ..add(DiagnosticsProperty('publicEventId', publicEventId))
      ..add(DiagnosticsProperty(
          'evtDisseminationAudience', evtDisseminationAudience))
      ..add(DiagnosticsProperty(
          'evtDisseminateAllowWebLinks', evtDisseminateAllowWebLinks))
      ..add(DiagnosticsProperty(
          'evtDisseminateHashRunsDotOrg', evtDisseminateHashRunsDotOrg))
      ..add(DiagnosticsProperty('evtDisseminateOnGlobalGoogleCalendar',
          evtDisseminateOnGlobalGoogleCalendar))
      ..add(DiagnosticsProperty('kenDisseminateOnGlobalGoogleCalendar',
          kenDisseminateOnGlobalGoogleCalendar))
      ..add(DiagnosticsProperty('cityLatitude', cityLatitude))
      ..add(DiagnosticsProperty('cityLongitude', cityLongitude))
      ..add(DiagnosticsProperty('doTrackHashCash', doTrackHashCash))
      ..add(DiagnosticsProperty('inboundIntegrationId', inboundIntegrationId))
      ..add(DiagnosticsProperty('kennelName', kennelName))
      ..add(DiagnosticsProperty('kennelCountryCodes', kennelCountryCodes))
      ..add(DiagnosticsProperty('kennelDefaultEventPriceForMembers',
          kennelDefaultEventPriceForMembers))
      ..add(DiagnosticsProperty('kennelDefaultEventPriceForNonMembers',
          kennelDefaultEventPriceForNonMembers))
      ..add(DiagnosticsProperty('digitsAfterDecimal', digitsAfterDecimal))
      ..add(DiagnosticsProperty('currencySymbol', currencySymbol))
      ..add(DiagnosticsProperty('extEventName', extEventName))
      ..add(DiagnosticsProperty('eventEndDatetime', eventEndDatetime))
      ..add(DiagnosticsProperty('extDataLastUpdated', extDataLastUpdated))
      ..add(DiagnosticsProperty('extEventStartDatetime', extEventStartDatetime))
      ..add(DiagnosticsProperty('hcLatitude', hcLatitude))
      ..add(DiagnosticsProperty('hcLongitude', hcLongitude))
      ..add(DiagnosticsProperty('fbLatitude', fbLatitude))
      ..add(DiagnosticsProperty('fbLongitude', fbLongitude))
      ..add(DiagnosticsProperty('kenLatitude', kenLatitude))
      ..add(DiagnosticsProperty('kenLongitude', kenLongitude))
      ..add(DiagnosticsProperty('kennelLogo', kennelLogo))
      ..add(DiagnosticsProperty('kennelShortName', kennelShortName))
      ..add(DiagnosticsProperty('kennelUniqueShortName', kennelUniqueShortName))
      ..add(DiagnosticsProperty('eventPriceForMembers', eventPriceForMembers))
      ..add(DiagnosticsProperty(
          'eventPriceForNonMembers', eventPriceForNonMembers))
      ..add(DiagnosticsProperty('eventFacebookId', eventFacebookId))
      ..add(DiagnosticsProperty('absoluteEventNumber', absoluteEventNumber))
      ..add(DiagnosticsProperty('canEditRunAttendence', canEditRunAttendence))
      ..add(DiagnosticsProperty(
          'maximumParticipantsAllowed', maximumParticipantsAllowed))
      ..add(DiagnosticsProperty(
          'minimumParticipantsRequired', minimumParticipantsRequired))
      ..add(DiagnosticsProperty('eventChatMessageCount', eventChatMessageCount))
      ..add(DiagnosticsProperty('eventImage', eventImage))
      ..add(DiagnosticsProperty('extEventImage', extEventImage))
      ..add(DiagnosticsProperty('extEventDescription', extEventDescription))
      ..add(
          DiagnosticsProperty('extLocationOneLineDesc', extLocationOneLineDesc))
      ..add(DiagnosticsProperty('extLocationPostCode', extLocationPostCode))
      ..add(DiagnosticsProperty('extLocationCity', extLocationCity))
      ..add(DiagnosticsProperty('extLocationStreet', extLocationStreet))
      ..add(DiagnosticsProperty('extLocationCountry', extLocationCountry))
      ..add(DiagnosticsProperty('extLocationRegion', extLocationRegion))
      ..add(DiagnosticsProperty('extLocationSubRegion', extLocationSubRegion))
      ..add(DiagnosticsProperty('locationOneLineDesc', locationOneLineDesc))
      ..add(DiagnosticsProperty('locationPostCode', locationPostCode))
      ..add(DiagnosticsProperty('locationCity', locationCity))
      ..add(DiagnosticsProperty('locationStreet', locationStreet))
      ..add(DiagnosticsProperty('locationCountry', locationCountry))
      ..add(DiagnosticsProperty('locationRegion', locationRegion))
      ..add(DiagnosticsProperty('locationSubRegion', locationSubRegion))
      ..add(DiagnosticsProperty('locationPhoneNumber', locationPhoneNumber))
      ..add(DiagnosticsProperty('hares', hares))
      ..add(DiagnosticsProperty('eventPaymentScheme', eventPaymentScheme))
      ..add(DiagnosticsProperty('eventPaymentUrl', eventPaymentUrl))
      ..add(
          DiagnosticsProperty('eventPaymentUrlExpires', eventPaymentUrlExpires))
      ..add(DiagnosticsProperty('eventPriceForExtras', eventPriceForExtras))
      ..add(DiagnosticsProperty('extrasDescription', extrasDescription));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _RunDetailsModel &&
            (identical(other.publicKennelId, publicKennelId) ||
                other.publicKennelId == publicKennelId) &&
            (identical(other.eventStartDatetime, eventStartDatetime) ||
                other.eventStartDatetime == eventStartDatetime) &&
            (identical(other.isVisible, isVisible) ||
                other.isVisible == isVisible) &&
            (identical(other.isCountedRun, isCountedRun) ||
                other.isCountedRun == isCountedRun) &&
            (identical(other.isPromotedEvent, isPromotedEvent) ||
                other.isPromotedEvent == isPromotedEvent) &&
            (identical(other.eventGeographicScope, eventGeographicScope) ||
                other.eventGeographicScope == eventGeographicScope) &&
            (identical(other.eventNumber, eventNumber) ||
                other.eventNumber == eventNumber) &&
            (identical(other.eventName, eventName) ||
                other.eventName == eventName) &&
            (identical(other.eventDescription, eventDescription) ||
                other.eventDescription == eventDescription) &&
            (identical(other.extrasRsvpRequired, extrasRsvpRequired) ||
                other.extrasRsvpRequired == extrasRsvpRequired) &&
            (identical(other.tags1, tags1) || other.tags1 == tags1) &&
            (identical(other.tags2, tags2) || other.tags2 == tags2) &&
            (identical(other.tags3, tags3) || other.tags3 == tags3) &&
            (identical(other.useFbLocation, useFbLocation) ||
                other.useFbLocation == useFbLocation) &&
            (identical(other.useFbLatLon, useFbLatLon) ||
                other.useFbLatLon == useFbLatLon) &&
            (identical(other.useFbRunDetails, useFbRunDetails) ||
                other.useFbRunDetails == useFbRunDetails) &&
            (identical(other.useFbImage, useFbImage) ||
                other.useFbImage == useFbImage) &&
            (identical(other.integrationEnabled, integrationEnabled) ||
                other.integrationEnabled == integrationEnabled) &&
            (identical(other.kenDisseminateHashRunsDotOrg, kenDisseminateHashRunsDotOrg) ||
                other.kenDisseminateHashRunsDotOrg ==
                    kenDisseminateHashRunsDotOrg) &&
            (identical(other.kenDisseminateAllowWebLinks, kenDisseminateAllowWebLinks) ||
                other.kenDisseminateAllowWebLinks ==
                    kenDisseminateAllowWebLinks) &&
            (identical(other.kenDisseminationAudience, kenDisseminationAudience) ||
                other.kenDisseminationAudience == kenDisseminationAudience) &&
            (identical(other.countryId, countryId) ||
                other.countryId == countryId) &&
            (identical(other.countryName, countryName) ||
                other.countryName == countryName) &&
            (identical(other.publicEventId, publicEventId) ||
                other.publicEventId == publicEventId) &&
            (identical(other.evtDisseminationAudience, evtDisseminationAudience) ||
                other.evtDisseminationAudience == evtDisseminationAudience) &&
            (identical(other.evtDisseminateAllowWebLinks, evtDisseminateAllowWebLinks) ||
                other.evtDisseminateAllowWebLinks ==
                    evtDisseminateAllowWebLinks) &&
            (identical(other.evtDisseminateHashRunsDotOrg, evtDisseminateHashRunsDotOrg) ||
                other.evtDisseminateHashRunsDotOrg ==
                    evtDisseminateHashRunsDotOrg) &&
            (identical(other.evtDisseminateOnGlobalGoogleCalendar, evtDisseminateOnGlobalGoogleCalendar) ||
                other.evtDisseminateOnGlobalGoogleCalendar ==
                    evtDisseminateOnGlobalGoogleCalendar) &&
            (identical(other.kenDisseminateOnGlobalGoogleCalendar, kenDisseminateOnGlobalGoogleCalendar) ||
                other.kenDisseminateOnGlobalGoogleCalendar ==
                    kenDisseminateOnGlobalGoogleCalendar) &&
            (identical(other.cityLatitude, cityLatitude) ||
                other.cityLatitude == cityLatitude) &&
            (identical(other.cityLongitude, cityLongitude) ||
                other.cityLongitude == cityLongitude) &&
            (identical(other.doTrackHashCash, doTrackHashCash) || other.doTrackHashCash == doTrackHashCash) &&
            (identical(other.inboundIntegrationId, inboundIntegrationId) || other.inboundIntegrationId == inboundIntegrationId) &&
            (identical(other.kennelName, kennelName) || other.kennelName == kennelName) &&
            (identical(other.kennelCountryCodes, kennelCountryCodes) || other.kennelCountryCodes == kennelCountryCodes) &&
            (identical(other.kennelDefaultEventPriceForMembers, kennelDefaultEventPriceForMembers) || other.kennelDefaultEventPriceForMembers == kennelDefaultEventPriceForMembers) &&
            (identical(other.kennelDefaultEventPriceForNonMembers, kennelDefaultEventPriceForNonMembers) || other.kennelDefaultEventPriceForNonMembers == kennelDefaultEventPriceForNonMembers) &&
            (identical(other.digitsAfterDecimal, digitsAfterDecimal) || other.digitsAfterDecimal == digitsAfterDecimal) &&
            (identical(other.currencySymbol, currencySymbol) || other.currencySymbol == currencySymbol) &&
            (identical(other.extEventName, extEventName) || other.extEventName == extEventName) &&
            (identical(other.eventEndDatetime, eventEndDatetime) || other.eventEndDatetime == eventEndDatetime) &&
            (identical(other.extDataLastUpdated, extDataLastUpdated) || other.extDataLastUpdated == extDataLastUpdated) &&
            (identical(other.extEventStartDatetime, extEventStartDatetime) || other.extEventStartDatetime == extEventStartDatetime) &&
            (identical(other.hcLatitude, hcLatitude) || other.hcLatitude == hcLatitude) &&
            (identical(other.hcLongitude, hcLongitude) || other.hcLongitude == hcLongitude) &&
            (identical(other.fbLatitude, fbLatitude) || other.fbLatitude == fbLatitude) &&
            (identical(other.fbLongitude, fbLongitude) || other.fbLongitude == fbLongitude) &&
            (identical(other.kenLatitude, kenLatitude) || other.kenLatitude == kenLatitude) &&
            (identical(other.kenLongitude, kenLongitude) || other.kenLongitude == kenLongitude) &&
            (identical(other.kennelLogo, kennelLogo) || other.kennelLogo == kennelLogo) &&
            (identical(other.kennelShortName, kennelShortName) || other.kennelShortName == kennelShortName) &&
            (identical(other.kennelUniqueShortName, kennelUniqueShortName) || other.kennelUniqueShortName == kennelUniqueShortName) &&
            (identical(other.eventPriceForMembers, eventPriceForMembers) || other.eventPriceForMembers == eventPriceForMembers) &&
            (identical(other.eventPriceForNonMembers, eventPriceForNonMembers) || other.eventPriceForNonMembers == eventPriceForNonMembers) &&
            (identical(other.eventFacebookId, eventFacebookId) || other.eventFacebookId == eventFacebookId) &&
            (identical(other.absoluteEventNumber, absoluteEventNumber) || other.absoluteEventNumber == absoluteEventNumber) &&
            (identical(other.canEditRunAttendence, canEditRunAttendence) || other.canEditRunAttendence == canEditRunAttendence) &&
            (identical(other.maximumParticipantsAllowed, maximumParticipantsAllowed) || other.maximumParticipantsAllowed == maximumParticipantsAllowed) &&
            (identical(other.minimumParticipantsRequired, minimumParticipantsRequired) || other.minimumParticipantsRequired == minimumParticipantsRequired) &&
            (identical(other.eventChatMessageCount, eventChatMessageCount) || other.eventChatMessageCount == eventChatMessageCount) &&
            (identical(other.eventImage, eventImage) || other.eventImage == eventImage) &&
            (identical(other.extEventImage, extEventImage) || other.extEventImage == extEventImage) &&
            (identical(other.extEventDescription, extEventDescription) || other.extEventDescription == extEventDescription) &&
            (identical(other.extLocationOneLineDesc, extLocationOneLineDesc) || other.extLocationOneLineDesc == extLocationOneLineDesc) &&
            (identical(other.extLocationPostCode, extLocationPostCode) || other.extLocationPostCode == extLocationPostCode) &&
            (identical(other.extLocationCity, extLocationCity) || other.extLocationCity == extLocationCity) &&
            (identical(other.extLocationStreet, extLocationStreet) || other.extLocationStreet == extLocationStreet) &&
            (identical(other.extLocationCountry, extLocationCountry) || other.extLocationCountry == extLocationCountry) &&
            (identical(other.extLocationRegion, extLocationRegion) || other.extLocationRegion == extLocationRegion) &&
            (identical(other.extLocationSubRegion, extLocationSubRegion) || other.extLocationSubRegion == extLocationSubRegion) &&
            (identical(other.locationOneLineDesc, locationOneLineDesc) || other.locationOneLineDesc == locationOneLineDesc) &&
            (identical(other.locationPostCode, locationPostCode) || other.locationPostCode == locationPostCode) &&
            (identical(other.locationCity, locationCity) || other.locationCity == locationCity) &&
            (identical(other.locationStreet, locationStreet) || other.locationStreet == locationStreet) &&
            (identical(other.locationCountry, locationCountry) || other.locationCountry == locationCountry) &&
            (identical(other.locationRegion, locationRegion) || other.locationRegion == locationRegion) &&
            (identical(other.locationSubRegion, locationSubRegion) || other.locationSubRegion == locationSubRegion) &&
            (identical(other.locationPhoneNumber, locationPhoneNumber) || other.locationPhoneNumber == locationPhoneNumber) &&
            (identical(other.hares, hares) || other.hares == hares) &&
            (identical(other.eventPaymentScheme, eventPaymentScheme) || other.eventPaymentScheme == eventPaymentScheme) &&
            (identical(other.eventPaymentUrl, eventPaymentUrl) || other.eventPaymentUrl == eventPaymentUrl) &&
            (identical(other.eventPaymentUrlExpires, eventPaymentUrlExpires) || other.eventPaymentUrlExpires == eventPaymentUrlExpires) &&
            (identical(other.eventPriceForExtras, eventPriceForExtras) || other.eventPriceForExtras == eventPriceForExtras) &&
            (identical(other.extrasDescription, extrasDescription) || other.extrasDescription == extrasDescription));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        publicKennelId,
        eventStartDatetime,
        isVisible,
        isCountedRun,
        isPromotedEvent,
        eventGeographicScope,
        eventNumber,
        eventName,
        eventDescription,
        extrasRsvpRequired,
        tags1,
        tags2,
        tags3,
        useFbLocation,
        useFbLatLon,
        useFbRunDetails,
        useFbImage,
        integrationEnabled,
        kenDisseminateHashRunsDotOrg,
        kenDisseminateAllowWebLinks,
        kenDisseminationAudience,
        countryId,
        countryName,
        publicEventId,
        evtDisseminationAudience,
        evtDisseminateAllowWebLinks,
        evtDisseminateHashRunsDotOrg,
        evtDisseminateOnGlobalGoogleCalendar,
        kenDisseminateOnGlobalGoogleCalendar,
        cityLatitude,
        cityLongitude,
        doTrackHashCash,
        inboundIntegrationId,
        kennelName,
        kennelCountryCodes,
        kennelDefaultEventPriceForMembers,
        kennelDefaultEventPriceForNonMembers,
        digitsAfterDecimal,
        currencySymbol,
        extEventName,
        eventEndDatetime,
        extDataLastUpdated,
        extEventStartDatetime,
        hcLatitude,
        hcLongitude,
        fbLatitude,
        fbLongitude,
        kenLatitude,
        kenLongitude,
        kennelLogo,
        kennelShortName,
        kennelUniqueShortName,
        eventPriceForMembers,
        eventPriceForNonMembers,
        eventFacebookId,
        absoluteEventNumber,
        canEditRunAttendence,
        maximumParticipantsAllowed,
        minimumParticipantsRequired,
        eventChatMessageCount,
        eventImage,
        extEventImage,
        extEventDescription,
        extLocationOneLineDesc,
        extLocationPostCode,
        extLocationCity,
        extLocationStreet,
        extLocationCountry,
        extLocationRegion,
        extLocationSubRegion,
        locationOneLineDesc,
        locationPostCode,
        locationCity,
        locationStreet,
        locationCountry,
        locationRegion,
        locationSubRegion,
        locationPhoneNumber,
        hares,
        eventPaymentScheme,
        eventPaymentUrl,
        eventPaymentUrlExpires,
        eventPriceForExtras,
        extrasDescription
      ]);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'RunDetailsModel(publicKennelId: $publicKennelId, eventStartDatetime: $eventStartDatetime, isVisible: $isVisible, isCountedRun: $isCountedRun, isPromotedEvent: $isPromotedEvent, eventGeographicScope: $eventGeographicScope, eventNumber: $eventNumber, eventName: $eventName, eventDescription: $eventDescription, extrasRsvpRequired: $extrasRsvpRequired, tags1: $tags1, tags2: $tags2, tags3: $tags3, useFbLocation: $useFbLocation, useFbLatLon: $useFbLatLon, useFbRunDetails: $useFbRunDetails, useFbImage: $useFbImage, integrationEnabled: $integrationEnabled, kenDisseminateHashRunsDotOrg: $kenDisseminateHashRunsDotOrg, kenDisseminateAllowWebLinks: $kenDisseminateAllowWebLinks, kenDisseminationAudience: $kenDisseminationAudience, countryId: $countryId, countryName: $countryName, publicEventId: $publicEventId, evtDisseminationAudience: $evtDisseminationAudience, evtDisseminateAllowWebLinks: $evtDisseminateAllowWebLinks, evtDisseminateHashRunsDotOrg: $evtDisseminateHashRunsDotOrg, evtDisseminateOnGlobalGoogleCalendar: $evtDisseminateOnGlobalGoogleCalendar, kenDisseminateOnGlobalGoogleCalendar: $kenDisseminateOnGlobalGoogleCalendar, cityLatitude: $cityLatitude, cityLongitude: $cityLongitude, doTrackHashCash: $doTrackHashCash, inboundIntegrationId: $inboundIntegrationId, kennelName: $kennelName, kennelCountryCodes: $kennelCountryCodes, kennelDefaultEventPriceForMembers: $kennelDefaultEventPriceForMembers, kennelDefaultEventPriceForNonMembers: $kennelDefaultEventPriceForNonMembers, digitsAfterDecimal: $digitsAfterDecimal, currencySymbol: $currencySymbol, extEventName: $extEventName, eventEndDatetime: $eventEndDatetime, extDataLastUpdated: $extDataLastUpdated, extEventStartDatetime: $extEventStartDatetime, hcLatitude: $hcLatitude, hcLongitude: $hcLongitude, fbLatitude: $fbLatitude, fbLongitude: $fbLongitude, kenLatitude: $kenLatitude, kenLongitude: $kenLongitude, kennelLogo: $kennelLogo, kennelShortName: $kennelShortName, kennelUniqueShortName: $kennelUniqueShortName, eventPriceForMembers: $eventPriceForMembers, eventPriceForNonMembers: $eventPriceForNonMembers, eventFacebookId: $eventFacebookId, absoluteEventNumber: $absoluteEventNumber, canEditRunAttendence: $canEditRunAttendence, maximumParticipantsAllowed: $maximumParticipantsAllowed, minimumParticipantsRequired: $minimumParticipantsRequired, eventChatMessageCount: $eventChatMessageCount, eventImage: $eventImage, extEventImage: $extEventImage, extEventDescription: $extEventDescription, extLocationOneLineDesc: $extLocationOneLineDesc, extLocationPostCode: $extLocationPostCode, extLocationCity: $extLocationCity, extLocationStreet: $extLocationStreet, extLocationCountry: $extLocationCountry, extLocationRegion: $extLocationRegion, extLocationSubRegion: $extLocationSubRegion, locationOneLineDesc: $locationOneLineDesc, locationPostCode: $locationPostCode, locationCity: $locationCity, locationStreet: $locationStreet, locationCountry: $locationCountry, locationRegion: $locationRegion, locationSubRegion: $locationSubRegion, locationPhoneNumber: $locationPhoneNumber, hares: $hares, eventPaymentScheme: $eventPaymentScheme, eventPaymentUrl: $eventPaymentUrl, eventPaymentUrlExpires: $eventPaymentUrlExpires, eventPriceForExtras: $eventPriceForExtras, extrasDescription: $extrasDescription)';
  }
}

/// @nodoc
abstract mixin class _$RunDetailsModelCopyWith<$Res>
    implements $RunDetailsModelCopyWith<$Res> {
  factory _$RunDetailsModelCopyWith(
          _RunDetailsModel value, $Res Function(_RunDetailsModel) _then) =
      __$RunDetailsModelCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String publicKennelId,
      DateTime eventStartDatetime,
      int isVisible,
      int isCountedRun,
      int isPromotedEvent,
      int eventGeographicScope,
      int eventNumber,
      String eventName,
      String eventDescription,
      int extrasRsvpRequired,
      int tags1,
      int tags2,
      int tags3,
      int useFbLocation,
      int useFbLatLon,
      int useFbRunDetails,
      int useFbImage,
      int integrationEnabled,
      int kenDisseminateHashRunsDotOrg,
      int kenDisseminateAllowWebLinks,
      int kenDisseminationAudience,
      String countryId,
      String countryName,
      String? publicEventId,
      int? evtDisseminationAudience,
      int? evtDisseminateAllowWebLinks,
      int? evtDisseminateHashRunsDotOrg,
      int? evtDisseminateOnGlobalGoogleCalendar,
      int? kenDisseminateOnGlobalGoogleCalendar,
      double? cityLatitude,
      double? cityLongitude,
      int? doTrackHashCash,
      int? inboundIntegrationId,
      String? kennelName,
      String? kennelCountryCodes,
      double? kennelDefaultEventPriceForMembers,
      double? kennelDefaultEventPriceForNonMembers,
      int? digitsAfterDecimal,
      String? currencySymbol,
      String? extEventName,
      DateTime? eventEndDatetime,
      DateTime? extDataLastUpdated,
      DateTime? extEventStartDatetime,
      double? hcLatitude,
      double? hcLongitude,
      double? fbLatitude,
      double? fbLongitude,
      double? kenLatitude,
      double? kenLongitude,
      String? kennelLogo,
      String? kennelShortName,
      String? kennelUniqueShortName,
      double? eventPriceForMembers,
      double? eventPriceForNonMembers,
      String? eventFacebookId,
      int? absoluteEventNumber,
      int? canEditRunAttendence,
      int? maximumParticipantsAllowed,
      int? minimumParticipantsRequired,
      int? eventChatMessageCount,
      String? eventImage,
      String? extEventImage,
      String? extEventDescription,
      String? extLocationOneLineDesc,
      String? extLocationPostCode,
      String? extLocationCity,
      String? extLocationStreet,
      String? extLocationCountry,
      String? extLocationRegion,
      String? extLocationSubRegion,
      String? locationOneLineDesc,
      String? locationPostCode,
      String? locationCity,
      String? locationStreet,
      String? locationCountry,
      String? locationRegion,
      String? locationSubRegion,
      String? locationPhoneNumber,
      String? hares,
      String? eventPaymentScheme,
      String? eventPaymentUrl,
      DateTime? eventPaymentUrlExpires,
      num? eventPriceForExtras,
      String? extrasDescription});
}

/// @nodoc
class __$RunDetailsModelCopyWithImpl<$Res>
    implements _$RunDetailsModelCopyWith<$Res> {
  __$RunDetailsModelCopyWithImpl(this._self, this._then);

  final _RunDetailsModel _self;
  final $Res Function(_RunDetailsModel) _then;

  /// Create a copy of RunDetailsModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? publicKennelId = null,
    Object? eventStartDatetime = null,
    Object? isVisible = null,
    Object? isCountedRun = null,
    Object? isPromotedEvent = null,
    Object? eventGeographicScope = null,
    Object? eventNumber = null,
    Object? eventName = null,
    Object? eventDescription = null,
    Object? extrasRsvpRequired = null,
    Object? tags1 = null,
    Object? tags2 = null,
    Object? tags3 = null,
    Object? useFbLocation = null,
    Object? useFbLatLon = null,
    Object? useFbRunDetails = null,
    Object? useFbImage = null,
    Object? integrationEnabled = null,
    Object? kenDisseminateHashRunsDotOrg = null,
    Object? kenDisseminateAllowWebLinks = null,
    Object? kenDisseminationAudience = null,
    Object? countryId = null,
    Object? countryName = null,
    Object? publicEventId = freezed,
    Object? evtDisseminationAudience = freezed,
    Object? evtDisseminateAllowWebLinks = freezed,
    Object? evtDisseminateHashRunsDotOrg = freezed,
    Object? evtDisseminateOnGlobalGoogleCalendar = freezed,
    Object? kenDisseminateOnGlobalGoogleCalendar = freezed,
    Object? cityLatitude = freezed,
    Object? cityLongitude = freezed,
    Object? doTrackHashCash = freezed,
    Object? inboundIntegrationId = freezed,
    Object? kennelName = freezed,
    Object? kennelCountryCodes = freezed,
    Object? kennelDefaultEventPriceForMembers = freezed,
    Object? kennelDefaultEventPriceForNonMembers = freezed,
    Object? digitsAfterDecimal = freezed,
    Object? currencySymbol = freezed,
    Object? extEventName = freezed,
    Object? eventEndDatetime = freezed,
    Object? extDataLastUpdated = freezed,
    Object? extEventStartDatetime = freezed,
    Object? hcLatitude = freezed,
    Object? hcLongitude = freezed,
    Object? fbLatitude = freezed,
    Object? fbLongitude = freezed,
    Object? kenLatitude = freezed,
    Object? kenLongitude = freezed,
    Object? kennelLogo = freezed,
    Object? kennelShortName = freezed,
    Object? kennelUniqueShortName = freezed,
    Object? eventPriceForMembers = freezed,
    Object? eventPriceForNonMembers = freezed,
    Object? eventFacebookId = freezed,
    Object? absoluteEventNumber = freezed,
    Object? canEditRunAttendence = freezed,
    Object? maximumParticipantsAllowed = freezed,
    Object? minimumParticipantsRequired = freezed,
    Object? eventChatMessageCount = freezed,
    Object? eventImage = freezed,
    Object? extEventImage = freezed,
    Object? extEventDescription = freezed,
    Object? extLocationOneLineDesc = freezed,
    Object? extLocationPostCode = freezed,
    Object? extLocationCity = freezed,
    Object? extLocationStreet = freezed,
    Object? extLocationCountry = freezed,
    Object? extLocationRegion = freezed,
    Object? extLocationSubRegion = freezed,
    Object? locationOneLineDesc = freezed,
    Object? locationPostCode = freezed,
    Object? locationCity = freezed,
    Object? locationStreet = freezed,
    Object? locationCountry = freezed,
    Object? locationRegion = freezed,
    Object? locationSubRegion = freezed,
    Object? locationPhoneNumber = freezed,
    Object? hares = freezed,
    Object? eventPaymentScheme = freezed,
    Object? eventPaymentUrl = freezed,
    Object? eventPaymentUrlExpires = freezed,
    Object? eventPriceForExtras = freezed,
    Object? extrasDescription = freezed,
  }) {
    return _then(_RunDetailsModel(
      publicKennelId: null == publicKennelId
          ? _self.publicKennelId
          : publicKennelId // ignore: cast_nullable_to_non_nullable
              as String,
      eventStartDatetime: null == eventStartDatetime
          ? _self.eventStartDatetime
          : eventStartDatetime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isVisible: null == isVisible
          ? _self.isVisible
          : isVisible // ignore: cast_nullable_to_non_nullable
              as int,
      isCountedRun: null == isCountedRun
          ? _self.isCountedRun
          : isCountedRun // ignore: cast_nullable_to_non_nullable
              as int,
      isPromotedEvent: null == isPromotedEvent
          ? _self.isPromotedEvent
          : isPromotedEvent // ignore: cast_nullable_to_non_nullable
              as int,
      eventGeographicScope: null == eventGeographicScope
          ? _self.eventGeographicScope
          : eventGeographicScope // ignore: cast_nullable_to_non_nullable
              as int,
      eventNumber: null == eventNumber
          ? _self.eventNumber
          : eventNumber // ignore: cast_nullable_to_non_nullable
              as int,
      eventName: null == eventName
          ? _self.eventName
          : eventName // ignore: cast_nullable_to_non_nullable
              as String,
      eventDescription: null == eventDescription
          ? _self.eventDescription
          : eventDescription // ignore: cast_nullable_to_non_nullable
              as String,
      extrasRsvpRequired: null == extrasRsvpRequired
          ? _self.extrasRsvpRequired
          : extrasRsvpRequired // ignore: cast_nullable_to_non_nullable
              as int,
      tags1: null == tags1
          ? _self.tags1
          : tags1 // ignore: cast_nullable_to_non_nullable
              as int,
      tags2: null == tags2
          ? _self.tags2
          : tags2 // ignore: cast_nullable_to_non_nullable
              as int,
      tags3: null == tags3
          ? _self.tags3
          : tags3 // ignore: cast_nullable_to_non_nullable
              as int,
      useFbLocation: null == useFbLocation
          ? _self.useFbLocation
          : useFbLocation // ignore: cast_nullable_to_non_nullable
              as int,
      useFbLatLon: null == useFbLatLon
          ? _self.useFbLatLon
          : useFbLatLon // ignore: cast_nullable_to_non_nullable
              as int,
      useFbRunDetails: null == useFbRunDetails
          ? _self.useFbRunDetails
          : useFbRunDetails // ignore: cast_nullable_to_non_nullable
              as int,
      useFbImage: null == useFbImage
          ? _self.useFbImage
          : useFbImage // ignore: cast_nullable_to_non_nullable
              as int,
      integrationEnabled: null == integrationEnabled
          ? _self.integrationEnabled
          : integrationEnabled // ignore: cast_nullable_to_non_nullable
              as int,
      kenDisseminateHashRunsDotOrg: null == kenDisseminateHashRunsDotOrg
          ? _self.kenDisseminateHashRunsDotOrg
          : kenDisseminateHashRunsDotOrg // ignore: cast_nullable_to_non_nullable
              as int,
      kenDisseminateAllowWebLinks: null == kenDisseminateAllowWebLinks
          ? _self.kenDisseminateAllowWebLinks
          : kenDisseminateAllowWebLinks // ignore: cast_nullable_to_non_nullable
              as int,
      kenDisseminationAudience: null == kenDisseminationAudience
          ? _self.kenDisseminationAudience
          : kenDisseminationAudience // ignore: cast_nullable_to_non_nullable
              as int,
      countryId: null == countryId
          ? _self.countryId
          : countryId // ignore: cast_nullable_to_non_nullable
              as String,
      countryName: null == countryName
          ? _self.countryName
          : countryName // ignore: cast_nullable_to_non_nullable
              as String,
      publicEventId: freezed == publicEventId
          ? _self.publicEventId
          : publicEventId // ignore: cast_nullable_to_non_nullable
              as String?,
      evtDisseminationAudience: freezed == evtDisseminationAudience
          ? _self.evtDisseminationAudience
          : evtDisseminationAudience // ignore: cast_nullable_to_non_nullable
              as int?,
      evtDisseminateAllowWebLinks: freezed == evtDisseminateAllowWebLinks
          ? _self.evtDisseminateAllowWebLinks
          : evtDisseminateAllowWebLinks // ignore: cast_nullable_to_non_nullable
              as int?,
      evtDisseminateHashRunsDotOrg: freezed == evtDisseminateHashRunsDotOrg
          ? _self.evtDisseminateHashRunsDotOrg
          : evtDisseminateHashRunsDotOrg // ignore: cast_nullable_to_non_nullable
              as int?,
      evtDisseminateOnGlobalGoogleCalendar: freezed ==
              evtDisseminateOnGlobalGoogleCalendar
          ? _self.evtDisseminateOnGlobalGoogleCalendar
          : evtDisseminateOnGlobalGoogleCalendar // ignore: cast_nullable_to_non_nullable
              as int?,
      kenDisseminateOnGlobalGoogleCalendar: freezed ==
              kenDisseminateOnGlobalGoogleCalendar
          ? _self.kenDisseminateOnGlobalGoogleCalendar
          : kenDisseminateOnGlobalGoogleCalendar // ignore: cast_nullable_to_non_nullable
              as int?,
      cityLatitude: freezed == cityLatitude
          ? _self.cityLatitude
          : cityLatitude // ignore: cast_nullable_to_non_nullable
              as double?,
      cityLongitude: freezed == cityLongitude
          ? _self.cityLongitude
          : cityLongitude // ignore: cast_nullable_to_non_nullable
              as double?,
      doTrackHashCash: freezed == doTrackHashCash
          ? _self.doTrackHashCash
          : doTrackHashCash // ignore: cast_nullable_to_non_nullable
              as int?,
      inboundIntegrationId: freezed == inboundIntegrationId
          ? _self.inboundIntegrationId
          : inboundIntegrationId // ignore: cast_nullable_to_non_nullable
              as int?,
      kennelName: freezed == kennelName
          ? _self.kennelName
          : kennelName // ignore: cast_nullable_to_non_nullable
              as String?,
      kennelCountryCodes: freezed == kennelCountryCodes
          ? _self.kennelCountryCodes
          : kennelCountryCodes // ignore: cast_nullable_to_non_nullable
              as String?,
      kennelDefaultEventPriceForMembers: freezed ==
              kennelDefaultEventPriceForMembers
          ? _self.kennelDefaultEventPriceForMembers
          : kennelDefaultEventPriceForMembers // ignore: cast_nullable_to_non_nullable
              as double?,
      kennelDefaultEventPriceForNonMembers: freezed ==
              kennelDefaultEventPriceForNonMembers
          ? _self.kennelDefaultEventPriceForNonMembers
          : kennelDefaultEventPriceForNonMembers // ignore: cast_nullable_to_non_nullable
              as double?,
      digitsAfterDecimal: freezed == digitsAfterDecimal
          ? _self.digitsAfterDecimal
          : digitsAfterDecimal // ignore: cast_nullable_to_non_nullable
              as int?,
      currencySymbol: freezed == currencySymbol
          ? _self.currencySymbol
          : currencySymbol // ignore: cast_nullable_to_non_nullable
              as String?,
      extEventName: freezed == extEventName
          ? _self.extEventName
          : extEventName // ignore: cast_nullable_to_non_nullable
              as String?,
      eventEndDatetime: freezed == eventEndDatetime
          ? _self.eventEndDatetime
          : eventEndDatetime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      extDataLastUpdated: freezed == extDataLastUpdated
          ? _self.extDataLastUpdated
          : extDataLastUpdated // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      extEventStartDatetime: freezed == extEventStartDatetime
          ? _self.extEventStartDatetime
          : extEventStartDatetime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      hcLatitude: freezed == hcLatitude
          ? _self.hcLatitude
          : hcLatitude // ignore: cast_nullable_to_non_nullable
              as double?,
      hcLongitude: freezed == hcLongitude
          ? _self.hcLongitude
          : hcLongitude // ignore: cast_nullable_to_non_nullable
              as double?,
      fbLatitude: freezed == fbLatitude
          ? _self.fbLatitude
          : fbLatitude // ignore: cast_nullable_to_non_nullable
              as double?,
      fbLongitude: freezed == fbLongitude
          ? _self.fbLongitude
          : fbLongitude // ignore: cast_nullable_to_non_nullable
              as double?,
      kenLatitude: freezed == kenLatitude
          ? _self.kenLatitude
          : kenLatitude // ignore: cast_nullable_to_non_nullable
              as double?,
      kenLongitude: freezed == kenLongitude
          ? _self.kenLongitude
          : kenLongitude // ignore: cast_nullable_to_non_nullable
              as double?,
      kennelLogo: freezed == kennelLogo
          ? _self.kennelLogo
          : kennelLogo // ignore: cast_nullable_to_non_nullable
              as String?,
      kennelShortName: freezed == kennelShortName
          ? _self.kennelShortName
          : kennelShortName // ignore: cast_nullable_to_non_nullable
              as String?,
      kennelUniqueShortName: freezed == kennelUniqueShortName
          ? _self.kennelUniqueShortName
          : kennelUniqueShortName // ignore: cast_nullable_to_non_nullable
              as String?,
      eventPriceForMembers: freezed == eventPriceForMembers
          ? _self.eventPriceForMembers
          : eventPriceForMembers // ignore: cast_nullable_to_non_nullable
              as double?,
      eventPriceForNonMembers: freezed == eventPriceForNonMembers
          ? _self.eventPriceForNonMembers
          : eventPriceForNonMembers // ignore: cast_nullable_to_non_nullable
              as double?,
      eventFacebookId: freezed == eventFacebookId
          ? _self.eventFacebookId
          : eventFacebookId // ignore: cast_nullable_to_non_nullable
              as String?,
      absoluteEventNumber: freezed == absoluteEventNumber
          ? _self.absoluteEventNumber
          : absoluteEventNumber // ignore: cast_nullable_to_non_nullable
              as int?,
      canEditRunAttendence: freezed == canEditRunAttendence
          ? _self.canEditRunAttendence
          : canEditRunAttendence // ignore: cast_nullable_to_non_nullable
              as int?,
      maximumParticipantsAllowed: freezed == maximumParticipantsAllowed
          ? _self.maximumParticipantsAllowed
          : maximumParticipantsAllowed // ignore: cast_nullable_to_non_nullable
              as int?,
      minimumParticipantsRequired: freezed == minimumParticipantsRequired
          ? _self.minimumParticipantsRequired
          : minimumParticipantsRequired // ignore: cast_nullable_to_non_nullable
              as int?,
      eventChatMessageCount: freezed == eventChatMessageCount
          ? _self.eventChatMessageCount
          : eventChatMessageCount // ignore: cast_nullable_to_non_nullable
              as int?,
      eventImage: freezed == eventImage
          ? _self.eventImage
          : eventImage // ignore: cast_nullable_to_non_nullable
              as String?,
      extEventImage: freezed == extEventImage
          ? _self.extEventImage
          : extEventImage // ignore: cast_nullable_to_non_nullable
              as String?,
      extEventDescription: freezed == extEventDescription
          ? _self.extEventDescription
          : extEventDescription // ignore: cast_nullable_to_non_nullable
              as String?,
      extLocationOneLineDesc: freezed == extLocationOneLineDesc
          ? _self.extLocationOneLineDesc
          : extLocationOneLineDesc // ignore: cast_nullable_to_non_nullable
              as String?,
      extLocationPostCode: freezed == extLocationPostCode
          ? _self.extLocationPostCode
          : extLocationPostCode // ignore: cast_nullable_to_non_nullable
              as String?,
      extLocationCity: freezed == extLocationCity
          ? _self.extLocationCity
          : extLocationCity // ignore: cast_nullable_to_non_nullable
              as String?,
      extLocationStreet: freezed == extLocationStreet
          ? _self.extLocationStreet
          : extLocationStreet // ignore: cast_nullable_to_non_nullable
              as String?,
      extLocationCountry: freezed == extLocationCountry
          ? _self.extLocationCountry
          : extLocationCountry // ignore: cast_nullable_to_non_nullable
              as String?,
      extLocationRegion: freezed == extLocationRegion
          ? _self.extLocationRegion
          : extLocationRegion // ignore: cast_nullable_to_non_nullable
              as String?,
      extLocationSubRegion: freezed == extLocationSubRegion
          ? _self.extLocationSubRegion
          : extLocationSubRegion // ignore: cast_nullable_to_non_nullable
              as String?,
      locationOneLineDesc: freezed == locationOneLineDesc
          ? _self.locationOneLineDesc
          : locationOneLineDesc // ignore: cast_nullable_to_non_nullable
              as String?,
      locationPostCode: freezed == locationPostCode
          ? _self.locationPostCode
          : locationPostCode // ignore: cast_nullable_to_non_nullable
              as String?,
      locationCity: freezed == locationCity
          ? _self.locationCity
          : locationCity // ignore: cast_nullable_to_non_nullable
              as String?,
      locationStreet: freezed == locationStreet
          ? _self.locationStreet
          : locationStreet // ignore: cast_nullable_to_non_nullable
              as String?,
      locationCountry: freezed == locationCountry
          ? _self.locationCountry
          : locationCountry // ignore: cast_nullable_to_non_nullable
              as String?,
      locationRegion: freezed == locationRegion
          ? _self.locationRegion
          : locationRegion // ignore: cast_nullable_to_non_nullable
              as String?,
      locationSubRegion: freezed == locationSubRegion
          ? _self.locationSubRegion
          : locationSubRegion // ignore: cast_nullable_to_non_nullable
              as String?,
      locationPhoneNumber: freezed == locationPhoneNumber
          ? _self.locationPhoneNumber
          : locationPhoneNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      hares: freezed == hares
          ? _self.hares
          : hares // ignore: cast_nullable_to_non_nullable
              as String?,
      eventPaymentScheme: freezed == eventPaymentScheme
          ? _self.eventPaymentScheme
          : eventPaymentScheme // ignore: cast_nullable_to_non_nullable
              as String?,
      eventPaymentUrl: freezed == eventPaymentUrl
          ? _self.eventPaymentUrl
          : eventPaymentUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      eventPaymentUrlExpires: freezed == eventPaymentUrlExpires
          ? _self.eventPaymentUrlExpires
          : eventPaymentUrlExpires // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      eventPriceForExtras: freezed == eventPriceForExtras
          ? _self.eventPriceForExtras
          : eventPriceForExtras // ignore: cast_nullable_to_non_nullable
              as num?,
      extrasDescription: freezed == extrasDescription
          ? _self.extrasDescription
          : extrasDescription // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on
