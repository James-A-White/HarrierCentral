import 'package:harrier_central/imports.dart';

part 'promo_model.freezed.dart';
part 'promo_model.g.dart';

@freezed
class PromoModel with _$PromoModel implements BaseModel {
  factory PromoModel({
    required String promotionId,
    String? kennelId,
    String? cityId,
    String? eventId,
    String? promoGroupId,
    required String promoName,
    required DateTime promoStartDate,
    required DateTime promoEndDate,
    required int promoDisplayButtons,
    required String promoImage,
    required String promoImageExtension,
    required String promoOverlayTiming,
    String? promoExternalUrl,
    String? promoExternalUrlButtonText,
    required int promoPriority,
    double? promoLat,
    double? promoLon,
    double? promoRadius,
    required String promoDisplayTimingDotsShape,
    required int promoDisplayTimingDotsToDisplay,
    required int promoDisplayTimingDotsSize,
    required int promoGeographicScope,
    required int promoImageIsDark,
    required int promoDisplayTimeInMs,
  }) = _PromoModel;

  factory PromoModel.fromJson(Map<String, dynamic> json) => _$PromoModelFromJson(json);

  @override
  factory PromoModel.fromMap(Map<String, dynamic> map) {
    return PromoModel.fromJson(map);
  }
}






  

//   static List<PromoModel> itemsFromJson(String jsonResult) {
//     final List<PromoModel> items = <PromoModel>[];

//     PromoModel item;

//     final dynamic jResult = json.decode(jsonResult);

//     jResult[1].forEach(
//       (dynamic jsonItem) {
//         item = PromoModel(
//           promotionId: jsonItem['promotionId'],
//           kennelId: jsonItem['kennelId'],
//           cityId: jsonItem['cityId'],
//           eventId: jsonItem['eventId'],
//           promoGroupId: jsonItem['promoGroupId'],
//           promoName: jsonItem['promoName'],
//           promoStartDate: DateTime.parse(jsonItem['promoStartDate'] ?? '2000-01-01 19:00:00'),
//           promoEndDate: DateTime.parse(jsonItem['promoEndDate'] ?? '2000-01-01 19:00:00'),
//           promoDisplayButtons: jsonItem['promoDisplayButtons'],
//           promoImage: jsonItem['promoImage'],
//           promoImageExtension: jsonItem['promoImageExtension'],
//           promoOverlayTiming: jsonItem['promoOverlayTiming'],
//           promoExternalUrl: jsonItem['promoExternalUrl'],
//           promoExternalUrlButtonText: jsonItem['promoExternalUrlButtonText'],
//           promoPriority: jsonItem['prompPriority'],
//           promoLat: jsonItem['promoLat'],
//           promoLon: jsonItem['promoLon'],
//           promoRadius: jsonItem['promoRadius'],
//           promoDisplayTimingDotsShape: jsonItem['promoDisplayTimingDotsShape'],
//           promoDisplayTimingDotsToDisplay: jsonItem['promoDisplayTimingDotsToDisplay'],
//           promoDisplayTimingDotsSize: jsonItem['promoDisplayTimingDotsSize'],
//           promoGeographicScope: jsonItem['promoGeographicScope'],
//           promoImageIsDark: jsonItem['promoImageIsDark'],
//           promoDisplayTimeInMs: jsonItem['promoDisplayTimeInMs'],
//         );

//         items.add(item);
//       },
//     );

//     return items;
//   }
// }
