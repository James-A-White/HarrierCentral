// @dart=2.11
import 'package:harrier_central/imports.dart';

class PromoModel {
  PromoModel({
    this.promotionId,
    this.kennelId,
    this.cityId,
    this.eventId,
    this.promoGroupId,
    this.promoName,
    this.promoStartDate,
    this.promoEndDate,
    this.promoDisplayButtons,
    this.promoImage,
    this.promoImageExtension,
    this.promoOverlayTiming,
    this.promoExternalUrl,
    this.promoPriority,
    this.promoLat,
    this.promoLon,
    this.promoGeographicScope,
    this.promoDisplayTimingDotsShape,
    this.promoDisplayTimingDotsToDisplay,
    this.promoDisplayTimingDotsSize,
    this.promoImageIsDark,
    this.promoDisplayTimeInMs,
  });

  String promotionId;
  String kennelId;
  String cityId;
  String eventId;
  String promoGroupId;
  String promoName;
  DateTime promoStartDate;
  DateTime promoEndDate;
  int promoDisplayButtons;
  String promoImage;
  String promoImageExtension;
  String promoOverlayTiming;
  String promoExternalUrl;
  int promoPriority;
  double promoLat;
  double promoLon;
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
          promoPriority: jsonItem['prompPriority'],
          promoLat: jsonItem['promoLat'],
          promoLon: jsonItem['promoLon'],
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

    if (items.isEmpty) {
      return null;
    }

    return items;
  }
}
