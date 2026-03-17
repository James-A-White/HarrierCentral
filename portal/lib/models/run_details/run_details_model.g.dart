// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'run_details_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RunDetailsModel _$RunDetailsModelFromJson(Map<String, dynamic> json) =>
    _RunDetailsModel(
      publicKennelId: json['publicKennelId'] as String,
      eventStartDatetime: DateTime.parse(json['eventStartDatetime'] as String),
      isVisible: (json['isVisible'] as num).toInt(),
      isCountedRun: (json['isCountedRun'] as num).toInt(),
      isPromotedEvent: (json['isPromotedEvent'] as num).toInt(),
      eventGeographicScope: (json['eventGeographicScope'] as num).toInt(),
      eventNumber: (json['eventNumber'] as num).toInt(),
      eventName: json['eventName'] as String,
      eventDescription: json['eventDescription'] as String,
      extrasRsvpRequired: (json['extrasRsvpRequired'] as num).toInt(),
      tags1: (json['tags1'] as num).toInt(),
      tags2: (json['tags2'] as num).toInt(),
      tags3: (json['tags3'] as num).toInt(),
      useFbLocation: (json['useFbLocation'] as num).toInt(),
      useFbLatLon: (json['useFbLatLon'] as num).toInt(),
      useFbRunDetails: (json['useFbRunDetails'] as num).toInt(),
      useFbImage: (json['useFbImage'] as num).toInt(),
      integrationEnabled: (json['integrationEnabled'] as num).toInt(),
      kenDisseminateHashRunsDotOrg:
          (json['kenDisseminateHashRunsDotOrg'] as num).toInt(),
      kenDisseminateAllowWebLinks:
          (json['kenDisseminateAllowWebLinks'] as num).toInt(),
      kenDisseminationAudience:
          (json['kenDisseminationAudience'] as num).toInt(),
      countryId: json['countryId'] as String,
      countryName: json['countryName'] as String,
      publicEventId: json['publicEventId'] as String?,
      evtDisseminationAudience:
          (json['evtDisseminationAudience'] as num?)?.toInt(),
      evtDisseminateAllowWebLinks:
          (json['evtDisseminateAllowWebLinks'] as num?)?.toInt(),
      evtDisseminateHashRunsDotOrg:
          (json['evtDisseminateHashRunsDotOrg'] as num?)?.toInt(),
      evtDisseminateOnGlobalGoogleCalendar:
          (json['evtDisseminateOnGlobalGoogleCalendar'] as num?)?.toInt(),
      kenDisseminateOnGlobalGoogleCalendar:
          (json['kenDisseminateOnGlobalGoogleCalendar'] as num?)?.toInt(),
      cityLatitude: (json['cityLatitude'] as num?)?.toDouble(),
      cityLongitude: (json['cityLongitude'] as num?)?.toDouble(),
      doTrackHashCash: (json['doTrackHashCash'] as num?)?.toInt(),
      inboundIntegrationId: (json['inboundIntegrationId'] as num?)?.toInt(),
      kennelName: json['kennelName'] as String?,
      kennelCountryCodes: json['kennelCountryCodes'] as String?,
      kennelDefaultEventPriceForMembers:
          (json['kennelDefaultEventPriceForMembers'] as num?)?.toDouble(),
      kennelDefaultEventPriceForNonMembers:
          (json['kennelDefaultEventPriceForNonMembers'] as num?)?.toDouble(),
      digitsAfterDecimal: (json['digitsAfterDecimal'] as num?)?.toInt(),
      currencySymbol: json['currencySymbol'] as String?,
      extEventName: json['extEventName'] as String?,
      eventEndDatetime: json['eventEndDatetime'] == null
          ? null
          : DateTime.parse(json['eventEndDatetime'] as String),
      extDataLastUpdated: json['extDataLastUpdated'] == null
          ? null
          : DateTime.parse(json['extDataLastUpdated'] as String),
      extEventStartDatetime: json['extEventStartDatetime'] == null
          ? null
          : DateTime.parse(json['extEventStartDatetime'] as String),
      hcLatitude: (json['hcLatitude'] as num?)?.toDouble(),
      hcLongitude: (json['hcLongitude'] as num?)?.toDouble(),
      fbLatitude: (json['fbLatitude'] as num?)?.toDouble(),
      fbLongitude: (json['fbLongitude'] as num?)?.toDouble(),
      kenLatitude: (json['kenLatitude'] as num?)?.toDouble(),
      kenLongitude: (json['kenLongitude'] as num?)?.toDouble(),
      kennelLogo: json['kennelLogo'] as String?,
      kennelShortName: json['kennelShortName'] as String?,
      kennelUniqueShortName: json['kennelUniqueShortName'] as String?,
      eventPriceForMembers: (json['eventPriceForMembers'] as num?)?.toDouble(),
      eventPriceForNonMembers:
          (json['eventPriceForNonMembers'] as num?)?.toDouble(),
      eventFacebookId: json['eventFacebookId'] as String?,
      absoluteEventNumber: (json['absoluteEventNumber'] as num?)?.toInt(),
      canEditRunAttendence: (json['canEditRunAttendence'] as num?)?.toInt(),
      maximumParticipantsAllowed:
          (json['maximumParticipantsAllowed'] as num?)?.toInt(),
      minimumParticipantsRequired:
          (json['minimumParticipantsRequired'] as num?)?.toInt(),
      eventChatMessageCount: (json['eventChatMessageCount'] as num?)?.toInt(),
      eventImage: json['eventImage'] as String?,
      extEventImage: json['extEventImage'] as String?,
      extEventDescription: json['extEventDescription'] as String?,
      extLocationOneLineDesc: json['extLocationOneLineDesc'] as String?,
      extLocationPostCode: json['extLocationPostCode'] as String?,
      extLocationCity: json['extLocationCity'] as String?,
      extLocationStreet: json['extLocationStreet'] as String?,
      extLocationCountry: json['extLocationCountry'] as String?,
      extLocationRegion: json['extLocationRegion'] as String?,
      extLocationSubRegion: json['extLocationSubRegion'] as String?,
      locationOneLineDesc: json['locationOneLineDesc'] as String?,
      locationPostCode: json['locationPostCode'] as String?,
      locationCity: json['locationCity'] as String?,
      locationStreet: json['locationStreet'] as String?,
      locationCountry: json['locationCountry'] as String?,
      locationRegion: json['locationRegion'] as String?,
      locationSubRegion: json['locationSubRegion'] as String?,
      locationPhoneNumber: json['locationPhoneNumber'] as String?,
      hares: json['hares'] as String?,
      eventPaymentScheme: json['eventPaymentScheme'] as String?,
      eventPaymentUrl: json['eventPaymentUrl'] as String?,
      eventPaymentUrlExpires: json['eventPaymentUrlExpires'] == null
          ? null
          : DateTime.parse(json['eventPaymentUrlExpires'] as String),
      eventPriceForExtras: json['eventPriceForExtras'] as num?,
      extrasDescription: json['extrasDescription'] as String?,
    );

Map<String, dynamic> _$RunDetailsModelToJson(_RunDetailsModel instance) =>
    <String, dynamic>{
      'publicKennelId': instance.publicKennelId,
      'eventStartDatetime': instance.eventStartDatetime.toIso8601String(),
      'isVisible': instance.isVisible,
      'isCountedRun': instance.isCountedRun,
      'isPromotedEvent': instance.isPromotedEvent,
      'eventGeographicScope': instance.eventGeographicScope,
      'eventNumber': instance.eventNumber,
      'eventName': instance.eventName,
      'eventDescription': instance.eventDescription,
      'extrasRsvpRequired': instance.extrasRsvpRequired,
      'tags1': instance.tags1,
      'tags2': instance.tags2,
      'tags3': instance.tags3,
      'useFbLocation': instance.useFbLocation,
      'useFbLatLon': instance.useFbLatLon,
      'useFbRunDetails': instance.useFbRunDetails,
      'useFbImage': instance.useFbImage,
      'integrationEnabled': instance.integrationEnabled,
      'kenDisseminateHashRunsDotOrg': instance.kenDisseminateHashRunsDotOrg,
      'kenDisseminateAllowWebLinks': instance.kenDisseminateAllowWebLinks,
      'kenDisseminationAudience': instance.kenDisseminationAudience,
      'countryId': instance.countryId,
      'countryName': instance.countryName,
      'publicEventId': instance.publicEventId,
      'evtDisseminationAudience': instance.evtDisseminationAudience,
      'evtDisseminateAllowWebLinks': instance.evtDisseminateAllowWebLinks,
      'evtDisseminateHashRunsDotOrg': instance.evtDisseminateHashRunsDotOrg,
      'evtDisseminateOnGlobalGoogleCalendar':
          instance.evtDisseminateOnGlobalGoogleCalendar,
      'kenDisseminateOnGlobalGoogleCalendar':
          instance.kenDisseminateOnGlobalGoogleCalendar,
      'cityLatitude': instance.cityLatitude,
      'cityLongitude': instance.cityLongitude,
      'doTrackHashCash': instance.doTrackHashCash,
      'inboundIntegrationId': instance.inboundIntegrationId,
      'kennelName': instance.kennelName,
      'kennelCountryCodes': instance.kennelCountryCodes,
      'kennelDefaultEventPriceForMembers':
          instance.kennelDefaultEventPriceForMembers,
      'kennelDefaultEventPriceForNonMembers':
          instance.kennelDefaultEventPriceForNonMembers,
      'digitsAfterDecimal': instance.digitsAfterDecimal,
      'currencySymbol': instance.currencySymbol,
      'extEventName': instance.extEventName,
      'eventEndDatetime': instance.eventEndDatetime?.toIso8601String(),
      'extDataLastUpdated': instance.extDataLastUpdated?.toIso8601String(),
      'extEventStartDatetime':
          instance.extEventStartDatetime?.toIso8601String(),
      'hcLatitude': instance.hcLatitude,
      'hcLongitude': instance.hcLongitude,
      'fbLatitude': instance.fbLatitude,
      'fbLongitude': instance.fbLongitude,
      'kenLatitude': instance.kenLatitude,
      'kenLongitude': instance.kenLongitude,
      'kennelLogo': instance.kennelLogo,
      'kennelShortName': instance.kennelShortName,
      'kennelUniqueShortName': instance.kennelUniqueShortName,
      'eventPriceForMembers': instance.eventPriceForMembers,
      'eventPriceForNonMembers': instance.eventPriceForNonMembers,
      'eventFacebookId': instance.eventFacebookId,
      'absoluteEventNumber': instance.absoluteEventNumber,
      'canEditRunAttendence': instance.canEditRunAttendence,
      'maximumParticipantsAllowed': instance.maximumParticipantsAllowed,
      'minimumParticipantsRequired': instance.minimumParticipantsRequired,
      'eventChatMessageCount': instance.eventChatMessageCount,
      'eventImage': instance.eventImage,
      'extEventImage': instance.extEventImage,
      'extEventDescription': instance.extEventDescription,
      'extLocationOneLineDesc': instance.extLocationOneLineDesc,
      'extLocationPostCode': instance.extLocationPostCode,
      'extLocationCity': instance.extLocationCity,
      'extLocationStreet': instance.extLocationStreet,
      'extLocationCountry': instance.extLocationCountry,
      'extLocationRegion': instance.extLocationRegion,
      'extLocationSubRegion': instance.extLocationSubRegion,
      'locationOneLineDesc': instance.locationOneLineDesc,
      'locationPostCode': instance.locationPostCode,
      'locationCity': instance.locationCity,
      'locationStreet': instance.locationStreet,
      'locationCountry': instance.locationCountry,
      'locationRegion': instance.locationRegion,
      'locationSubRegion': instance.locationSubRegion,
      'locationPhoneNumber': instance.locationPhoneNumber,
      'hares': instance.hares,
      'eventPaymentScheme': instance.eventPaymentScheme,
      'eventPaymentUrl': instance.eventPaymentUrl,
      'eventPaymentUrlExpires':
          instance.eventPaymentUrlExpires?.toIso8601String(),
      'eventPriceForExtras': instance.eventPriceForExtras,
      'extrasDescription': instance.extrasDescription,
    };
