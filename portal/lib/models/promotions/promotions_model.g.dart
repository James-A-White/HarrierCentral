// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'promotions_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PromotionsModel _$PromotionsModelFromJson(Map<String, dynamic> json) =>
    _PromotionsModel(
      promotionId: json['promotionId'] as String,
      promoName: json['promoName'] as String,
      promoStartDate: DateTime.parse(json['promoStartDate'] as String),
      promoDisplayButtons: (json['promoDisplayButtons'] as num).toInt(),
      promoImage: json['promoImage'] as String,
      promoImageExtension: json['promoImageExtension'] as String,
      promoOverlayTiming: json['promoOverlayTiming'] as String,
      promoPriority: (json['promoPriority'] as num).toInt(),
      promoGeographicScope: (json['promoGeographicScope'] as num).toInt(),
      promoImageIsDark: (json['promoImageIsDark'] as num).toInt(),
      promoDisplayTimeInMs: (json['promoDisplayTimeInMs'] as num).toInt(),
      promoDisplayTimingDotsToDisplay:
          (json['promoDisplayTimingDotsToDisplay'] as num).toInt(),
      promoDisplayTimingDotsShape:
          json['promoDisplayTimingDotsShape'] as String,
      promoDisplayTimingDotsSize:
          (json['promoDisplayTimingDotsSize'] as num).toInt(),
      promoType: json['promoType'] as String,
      promoIsDraft: (json['promoIsDraft'] as num).toInt(),
      promoGroupId: json['promoGroupId'] as String?,
      kennelId: json['kennelId'] as String?,
      cityId: json['cityId'] as String?,
      eventId: json['eventId'] as String?,
      userId: json['userId'] as String?,
      promoEndDate: json['promoEndDate'] == null
          ? null
          : DateTime.parse(json['promoEndDate'] as String),
      promoImageWide: json['promoImageWide'] as String?,
      promoImageTall: json['promoImageTall'] as String?,
      promoExternalUrl: json['promoExternalUrl'] as String?,
      promoExternalUrlButtonText: json['promoExternalUrlButtonText'] as String?,
      promoLat: (json['promoLat'] as num?)?.toDouble(),
      promoLon: (json['promoLon'] as num?)?.toDouble(),
      promoRadius: (json['promoRadius'] as num?)?.toInt(),
    );

Map<String, dynamic> _$PromotionsModelToJson(_PromotionsModel instance) =>
    <String, dynamic>{
      'promotionId': instance.promotionId,
      'promoName': instance.promoName,
      'promoStartDate': instance.promoStartDate.toIso8601String(),
      'promoDisplayButtons': instance.promoDisplayButtons,
      'promoImage': instance.promoImage,
      'promoImageExtension': instance.promoImageExtension,
      'promoOverlayTiming': instance.promoOverlayTiming,
      'promoPriority': instance.promoPriority,
      'promoGeographicScope': instance.promoGeographicScope,
      'promoImageIsDark': instance.promoImageIsDark,
      'promoDisplayTimeInMs': instance.promoDisplayTimeInMs,
      'promoDisplayTimingDotsToDisplay':
          instance.promoDisplayTimingDotsToDisplay,
      'promoDisplayTimingDotsShape': instance.promoDisplayTimingDotsShape,
      'promoDisplayTimingDotsSize': instance.promoDisplayTimingDotsSize,
      'promoType': instance.promoType,
      'promoIsDraft': instance.promoIsDraft,
      'promoGroupId': instance.promoGroupId,
      'kennelId': instance.kennelId,
      'cityId': instance.cityId,
      'eventId': instance.eventId,
      'userId': instance.userId,
      'promoEndDate': instance.promoEndDate?.toIso8601String(),
      'promoImageWide': instance.promoImageWide,
      'promoImageTall': instance.promoImageTall,
      'promoExternalUrl': instance.promoExternalUrl,
      'promoExternalUrlButtonText': instance.promoExternalUrlButtonText,
      'promoLat': instance.promoLat,
      'promoLon': instance.promoLon,
      'promoRadius': instance.promoRadius,
    };
