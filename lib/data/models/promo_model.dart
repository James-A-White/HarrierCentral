import 'package:harrier_central/imports_null_safe.dart';

class PromoModel {
  PromoModel({
    required this.promotionId,
    this.kennelId,
    this.cityId,
    this.eventId,
    this.promoGroupId,
    required this.promoName,
    required this.promoStartDate,
    required this.promoEndDate,
    required this.promoDisplayButtons,
    required this.promoImage,
    required this.promoImageExtension,
    required this.promoOverlayTiming,
    this.promoExternalUrl,
    this.promoExternalUrlButtonText,
    required this.promoPriority,
    this.promoLat,
    this.promoLon,
    this.promoRadius,
    required this.promoGeographicScope,
    required this.promoDisplayTimingDotsShape,
    required this.promoDisplayTimingDotsToDisplay,
    required this.promoDisplayTimingDotsSize,
    required this.promoImageIsDark,
    required this.promoDisplayTimeInMs,
  });

  String promotionId;
  String? kennelId;
  String? cityId;
  String? eventId;
  String? promoGroupId;
  String promoName;
  DateTime promoStartDate;
  DateTime promoEndDate;
  int promoDisplayButtons;
  String promoImage;
  String promoImageExtension;
  String promoOverlayTiming;
  String? promoExternalUrl;
  String? promoExternalUrlButtonText;
  int promoPriority;
  double? promoLat;
  double? promoLon;
  double? promoRadius;
  String promoDisplayTimingDotsShape;
  int promoDisplayTimingDotsToDisplay;
  int promoDisplayTimingDotsSize;
  int promoGeographicScope;
  int promoImageIsDark;
  int promoDisplayTimeInMs;

  static List<PromoModel> itemsFromJson(String jsonResult) {
    final List<PromoModel> items = <PromoModel>[];

    PromoModel item;

    final dynamic jResult = json.decode(jsonResult);

    jResult[1].forEach(
      (dynamic jsonItem) {
        item = PromoModel(
          promotionId: jsonItem['promotionId'],
          kennelId: jsonItem['kennelId'],
          cityId: jsonItem['cityId'],
          eventId: jsonItem['eventId'],
          promoGroupId: jsonItem['promoGroupId'],
          promoName: jsonItem['promoName'],
          promoStartDate: DateTime.parse(jsonItem['promoStartDate'] ?? '2000-01-01 19:00:00'),
          promoEndDate: DateTime.parse(jsonItem['promoEndDate'] ?? '2000-01-01 19:00:00'),
          promoDisplayButtons: jsonItem['promoDisplayButtons'],
          promoImage: jsonItem['promoImage'],
          promoImageExtension: jsonItem['promoImageExtension'],
          promoOverlayTiming: jsonItem['promoOverlayTiming'],
          promoExternalUrl: jsonItem['promoExternalUrl'],
          promoExternalUrlButtonText: jsonItem['promoExternalUrlButtonText'],
          promoPriority: jsonItem['prompPriority'],
          promoLat: jsonItem['promoLat'],
          promoLon: jsonItem['promoLon'],
          promoRadius: jsonItem['promoRadius'],
          promoDisplayTimingDotsShape: jsonItem['promoDisplayTimingDotsShape'],
          promoDisplayTimingDotsToDisplay: jsonItem['promoDisplayTimingDotsToDisplay'],
          promoDisplayTimingDotsSize: jsonItem['promoDisplayTimingDotsSize'],
          promoGeographicScope: jsonItem['promoGeographicScope'],
          promoImageIsDark: jsonItem['promoImageIsDark'],
          promoDisplayTimeInMs: jsonItem['promoDisplayTimeInMs'],
        );

        items.add(item);
      },
    );

    return items;
  }
}
