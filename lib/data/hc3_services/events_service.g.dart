// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'events_service.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EventModel _$EventModelFromJson(Map<String, dynamic> json) {
  return EventModel(
    eventId: json['eventId'] as String,
    eventStartDatetime: json['eventStartDatetime'] == null
        ? null
        : DateTime.parse(json['eventStartDatetime'] as String),
    kennelId: json['kennelId'] as String,
    isVisible: json['isVisible'] as int,
    isCountedRun: json['isCountedRun'] as int,
    eventGeographicScope: json['eventGeographicScope'] as int,
    eventNumber: json['eventNumber'] as int,
    eventName: json['eventName'] as String,
    narrowEventLatitude: json['narrowEventLatitude'] as num,
    narrowEventLongitude: json['narrowEventLongitude'] as num,
    eventPriceForMembers: json['eventPriceForMembers'] as num,
    eventPriceForNonMembers: json['eventPriceForNonMembers'] as num,
    eventFacebookId: json['eventFacebookId'] as String,
    absoluteEventNumber: json['absoluteEventNumber'] as num,
    canEditRunAttendence: json['canEditRunAttendence'] as num,
    eventImage: json['eventImage'] as String,
    eventDescription: json['eventDescription'] as String,
    locationOneLineDesc: json['locationOneLineDesc'] as String,
    locationPostCode: json['locationPostCode'] as String,
    locationCity: json['locationCity'] as String,
    locationStreet: json['locationStreet'] as String,
    locationCountry: json['locationCountry'] as String,
    locationRegion: json['locationRegion'] as String,
    locationSubRegion: json['locationSubRegion'] as String,
    hares: json['hares'] as String,
    eventPaymentScheme: json['eventPaymentScheme'] as String,
    eventPaymentUrl: json['eventPaymentUrl'] as String,
    eventPaymentUrlExpires: json['eventPaymentUrlExpires'] == null
        ? null
        : DateTime.parse(json['eventPaymentUrlExpires'] as String),
    unconfirmedBankXferCount: json['unconfirmedBankXferCount'] as int,
    eventPriceForExtras: json['eventPriceForExtras'] as num,
    extrasDescription: json['extrasDescription'] as String,
    doTrackHashCash: json['doTrackHashCash'] as int,
    tags1: json['tags1'] as int,
    tags2: json['tags2'] as int,
    tags3: json['tags3'] as int,
    removed: json['removed'] as int,
    updatedAt: json['updatedAt'] == null
        ? null
        : DateTime.parse(json['updatedAt'] as String),
  );
}

Map<String, dynamic> _$EventModelToJson(EventModel instance) =>
    <String, dynamic>{
      'eventId': instance.eventId,
      'eventStartDatetime': instance.eventStartDatetime?.toIso8601String(),
      'kennelId': instance.kennelId,
      'isVisible': instance.isVisible,
      'isCountedRun': instance.isCountedRun,
      'eventGeographicScope': instance.eventGeographicScope,
      'eventNumber': instance.eventNumber,
      'eventName': instance.eventName,
      'narrowEventLatitude': instance.narrowEventLatitude,
      'narrowEventLongitude': instance.narrowEventLongitude,
      'eventPriceForMembers': instance.eventPriceForMembers,
      'eventPriceForNonMembers': instance.eventPriceForNonMembers,
      'eventFacebookId': instance.eventFacebookId,
      'absoluteEventNumber': instance.absoluteEventNumber,
      'canEditRunAttendence': instance.canEditRunAttendence,
      'eventImage': instance.eventImage,
      'eventDescription': instance.eventDescription,
      'locationOneLineDesc': instance.locationOneLineDesc,
      'locationPostCode': instance.locationPostCode,
      'locationCity': instance.locationCity,
      'locationStreet': instance.locationStreet,
      'locationCountry': instance.locationCountry,
      'locationRegion': instance.locationRegion,
      'locationSubRegion': instance.locationSubRegion,
      'hares': instance.hares,
      'eventPaymentScheme': instance.eventPaymentScheme,
      'eventPaymentUrl': instance.eventPaymentUrl,
      'eventPaymentUrlExpires':
          instance.eventPaymentUrlExpires?.toIso8601String(),
      'unconfirmedBankXferCount': instance.unconfirmedBankXferCount,
      'eventPriceForExtras': instance.eventPriceForExtras,
      'extrasDescription': instance.extrasDescription,
      'doTrackHashCash': instance.doTrackHashCash,
      'tags1': instance.tags1,
      'tags2': instance.tags2,
      'tags3': instance.tags3,
      'removed': instance.removed,
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
