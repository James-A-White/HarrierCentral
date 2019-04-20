import 'dart:convert';
import 'dart:core';

class RegionsModel {
  RegionsModel(
      {this.cityId,
      this.cityName,
      this.regionId,
      this.latitude,
      this.longitude,
      this.cityAscii,
      this.flagFile,
      this.removed,
      this.updatedAt});


  final String cityId;
  final String cityName;
  final String regionId;
  final num latitude;
  final num longitude;
  final String cityAscii;
  final String flagFile;
  final int removed;
  final DateTime updatedAt;

  static List<RegionsModel> itemsFromJson(String jsonResult) {
    final List<RegionsModel> items = <RegionsModel>[];

    RegionsModel item;

    json.decode(jsonResult).forEach(
      (dynamic jsonItem) {
        item = RegionsModel(
          cityId: jsonItem['cityId'].toString(),
          cityName: jsonItem['cityName'],
          regionId: jsonItem['regionId'].toString(),
          latitude: jsonItem['latitude'],
          longitude: jsonItem['longitude'],
          cityAscii: jsonItem['cityAscii'],
          flagFile: jsonItem['flagFile'],
          updatedAt: DateTime.parse(jsonItem['updatedAt']),
          removed: jsonItem['removed']
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
