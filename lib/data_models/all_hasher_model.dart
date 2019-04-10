import 'dart:convert';
import 'dart:core';

class AllHasherListModel {
  AllHasherListModel(
      {this.userId,
      this.firstName,
      this.lastName,
      this.displayName,
      this.hashName,
      this.photo,
      this.nameDisplayPref,
      this.updatedAt,
      this.removed});

  final String userId;
  final String firstName;
  final String lastName;
  final String displayName;
  final String hashName;
  final String photo;
  final int nameDisplayPref;
  final DateTime updatedAt;
  final int removed;

  static List<AllHasherListModel> itemsFromJson(String jsonResult) {
    final List<AllHasherListModel> items = <AllHasherListModel>[];

    AllHasherListModel item;

    json.decode(jsonResult).forEach(
      (dynamic jsonItem) {
        item = AllHasherListModel(
          userId: jsonItem['ui'].toString(),
          firstName: jsonItem['fn'],
          lastName: jsonItem['ln'],
          displayName: jsonItem['dn'],
          hashName: jsonItem['hn'],
          photo: jsonItem['p'],
          nameDisplayPref: jsonItem['dp'],
          updatedAt: DateTime.parse(jsonItem['ua']),
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
