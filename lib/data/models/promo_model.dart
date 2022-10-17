// @dart=2.11
import 'package:harrier_central/imports.dart';

class PromoModel {
  PromoModel({
    this.promotionId,
    this.kennelId,
    this.cityId,
    this.eventId,
    this.promoGroupId,
    this.promoPageNumber,
    this.promoName,
    this.promoStartDate,
    this.promoEndDate,
    this.promoDisplayButtons,
    this.promoImage,
    this.promoExternalUrl,
    this.promoPriority,
    this.promoLat,
    this.promoLon,
    this.promoGeographicScope,
    this.promoImageIsDark,
    this.promoDisplayTimeInMs,
  });

  String promotionId;
  String kennelId;
  String cityId;
  String eventId;
  String promoGroupId;
  int promoPageNumber;
  String promoName;
  DateTime promoStartDate;
  DateTime promoEndDate;
  int promoDisplayButtons;
  String promoImage;
  String promoExternalUrl;
  int promoPriority;
  double promoLat;
  double promoLon;
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
          promoPageNumber: jsonItem['promoGroupId'],
          promoName: jsonItem['promoName'],
          promoStartDate: DateTime.parse(jsonItem['promoStartDate'] ?? '2000-01-01 19:00:00'),
          promoEndDate: DateTime.parse(jsonItem['promoEndDate'] ?? '2000-01-01 19:00:00'),
          promoDisplayButtons: jsonItem['promoDisplayButtons'],
          promoImage: jsonItem['promoImage'],
          promoExternalUrl: jsonItem['promoExternalUrl'],
          promoPriority: jsonItem['prompPriority'],
          promoLat: jsonItem['promoLat'],
          promoLon: jsonItem['promoLon'],
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
