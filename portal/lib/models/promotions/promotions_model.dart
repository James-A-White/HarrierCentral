// package imports
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:hcportal/imports.dart';

part 'promotions_model.freezed.dart';
part 'promotions_model.g.dart';

@freezed
abstract class PromotionsModel with _$PromotionsModel {
  factory PromotionsModel({
    required String promotionId,
    required String promoName,
    required DateTime promoStartDate,
    required int promoDisplayButtons,
    required String promoImage,
    required String promoImageExtension,
    required String promoOverlayTiming,
    required int promoPriority,
    required int promoGeographicScope,
    required int promoImageIsDark,
    required int promoDisplayTimeInMs,
    required int promoDisplayTimingDotsToDisplay,
    required String promoDisplayTimingDotsShape,
    required int promoDisplayTimingDotsSize,
    required String promoType,
    required int promoIsDraft,
    String? promoGroupId,
    String? kennelId,
    String? cityId,
    String? eventId,
    String? userId,
    DateTime? promoEndDate,
    String? promoImageWide,
    String? promoImageTall,
    String? promoExternalUrl,
    String? promoExternalUrlButtonText,
    double? promoLat,
    double? promoLon,
    int? promoRadius,
  }) = _PromotionsModel;

  factory PromotionsModel.fromJson(Map<String, dynamic> json) =>
      _$PromotionsModelFromJson(json);

  factory PromotionsModel.empty() => _$PromotionsModelFromJson(
        json.decode('''
{
    "promotionId": "",
		"promoGroupId": null,
		"kennelId": null,
		"cityId": null,
		"eventId": null,
		"userId": null,
		"promoName": "<empty>",
		"promoStartDate": "2000-01-12T00:00:00.000Z",
		"promoEndDate": "2000-01-12T00:00:00.000Z",
		"promoDisplayButtons": 0,
		"promoImage": "",
		"promoImageExtension": "",
		"promoOverlayTiming": "",
		"promoImageWide": null,
		"promoImageTall": null,
		"promoExternalUrl": "",
		"promoExternalUrlButtonText": "",
		"promoPriority": 0,
		"promoLat": null,
		"promoLon": null,
    "promoRadius": null,
		"promoGeographicScope": 0,
		"promoImageIsDark": 0,
		"promoDisplayTimeInMs": 0,
		"promoDisplayTimingDotsToDisplay": 0,
		"promoDisplayTimingDotsShape": "chevron long",
		"promoDisplayTimingDotsSize": 20,
		"promoType": "empty",
    "promoIsDraft": 1
        }
        ''') as Map<String, dynamic>,
      );
}
