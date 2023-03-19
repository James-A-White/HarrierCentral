// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'promo_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$_PromoModel _$$_PromoModelFromJson(Map<String, dynamic> json) =>
    _$_PromoModel(
      promotionId: json['promotionId'] as String,
      kennelId: json['kennelId'] as String?,
      cityId: json['cityId'] as String?,
      eventId: json['eventId'] as String?,
      promoGroupId: json['promoGroupId'] as String?,
      promoName: json['promoName'] as String,
      promoStartDate: DateTime.parse(json['promoStartDate'] as String),
      promoEndDate: DateTime.parse(json['promoEndDate'] as String),
      promoDisplayButtons: json['promoDisplayButtons'] as int,
      promoImage: json['promoImage'] as String,
      promoImageExtension: json['promoImageExtension'] as String,
      promoOverlayTiming: json['promoOverlayTiming'] as String,
      promoExternalUrl: json['promoExternalUrl'] as String?,
      promoExternalUrlButtonText: json['promoExternalUrlButtonText'] as String?,
      promoPriority: json['promoPriority'] as int,
      promoLat: (json['promoLat'] as num?)?.toDouble(),
      promoLon: (json['promoLon'] as num?)?.toDouble(),
      promoRadius: (json['promoRadius'] as num?)?.toDouble(),
      promoDisplayTimingDotsShape:
          json['promoDisplayTimingDotsShape'] as String,
      promoDisplayTimingDotsToDisplay:
          json['promoDisplayTimingDotsToDisplay'] as int,
      promoDisplayTimingDotsSize: json['promoDisplayTimingDotsSize'] as int,
      promoGeographicScope: json['promoGeographicScope'] as int,
      promoImageIsDark: json['promoImageIsDark'] as int,
      promoDisplayTimeInMs: json['promoDisplayTimeInMs'] as int,
    );

Map<String, dynamic> _$$_PromoModelToJson(_$_PromoModel instance) =>
    <String, dynamic>{
      'promotionId': instance.promotionId,
      'kennelId': instance.kennelId,
      'cityId': instance.cityId,
      'eventId': instance.eventId,
      'promoGroupId': instance.promoGroupId,
      'promoName': instance.promoName,
      'promoStartDate': instance.promoStartDate.toIso8601String(),
      'promoEndDate': instance.promoEndDate.toIso8601String(),
      'promoDisplayButtons': instance.promoDisplayButtons,
      'promoImage': instance.promoImage,
      'promoImageExtension': instance.promoImageExtension,
      'promoOverlayTiming': instance.promoOverlayTiming,
      'promoExternalUrl': instance.promoExternalUrl,
      'promoExternalUrlButtonText': instance.promoExternalUrlButtonText,
      'promoPriority': instance.promoPriority,
      'promoLat': instance.promoLat,
      'promoLon': instance.promoLon,
      'promoRadius': instance.promoRadius,
      'promoDisplayTimingDotsShape': instance.promoDisplayTimingDotsShape,
      'promoDisplayTimingDotsToDisplay':
          instance.promoDisplayTimingDotsToDisplay,
      'promoDisplayTimingDotsSize': instance.promoDisplayTimingDotsSize,
      'promoGeographicScope': instance.promoGeographicScope,
      'promoImageIsDark': instance.promoImageIsDark,
      'promoDisplayTimeInMs': instance.promoDisplayTimeInMs,
    };
