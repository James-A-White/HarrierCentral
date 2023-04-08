import 'package:harrier_central/imports.dart';

class NotificationsModel {
  NotificationsModel({
    required this.notificationTag,
    required this.notificationType,
    required this.notificationStatus,
    required this.updatedAtInt,
  });

  final String notificationTag;
  final String notificationType;
  final int notificationStatus;
  final int updatedAtInt;

  static List<NotificationsModel> itemsFromJson(String jsonResult) {
    final List<NotificationsModel> items = <NotificationsModel>[];

    NotificationsModel item;

    json.decode(jsonResult).forEach(
      (dynamic jsonItem) {
        item = NotificationsModel(
            notificationTag: jsonItem['notificationTag'], notificationType: jsonItem['notificationType'], notificationStatus: jsonItem['notificationStatus'], updatedAtInt: jsonItem['updatedAtInt']);

        items.add(item);
      },
    );

    if (items.isEmpty) {
      return <NotificationsModel>[];
    }

    return items;
  }
}

class NotificationsTableHelper {
  NotificationsTableHelper._privateConstructor();

  static const String tableName = 'notifications';

  static const String colId = 'id';

  static const String colNotificationType = 'notificationType';
  static const String colNotificationTag = 'notificationTag';
  static const String colNotificationStatus = 'notificationStatus';
  static const String colUpdatedAtInt = 'updatedAtInt';

  // make this a singleton class

  static final NotificationsTableHelper instance = NotificationsTableHelper._privateConstructor();

  // SQL code to create the database table
  static Future<dynamic> createTable(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $tableName (
            $colId INTEGER PRIMARY KEY,

            $colNotificationType TEXT NOT NULL,
            $colNotificationTag TEXT NOT NULL UNIQUE,
            $colNotificationStatus INT,
            $colUpdatedAtInt INT
          )
          ''');

    await db.execute('CREATE INDEX idx_${tableName}_id ON $tableName($colNotificationTag);');
  }

  static Map<String, dynamic> toMap(NotificationsModel item) {
    final Map<String, dynamic> map = <String, dynamic>{
      NotificationsTableHelper.colNotificationType: item.notificationType,
      NotificationsTableHelper.colNotificationTag: item.notificationTag,
      NotificationsTableHelper.colNotificationStatus: item.notificationStatus,
      NotificationsTableHelper.colUpdatedAtInt: item.updatedAtInt,
    };

    return map;
  }

  static NotificationsModel fromMap(Map<String, dynamic> map) {
    final NotificationsModel item = NotificationsModel(
      notificationType: map[NotificationsTableHelper.colNotificationType],
      notificationTag: map[NotificationsTableHelper.colNotificationTag],
      notificationStatus: map[NotificationsTableHelper.colNotificationStatus],
      updatedAtInt: map[NotificationsTableHelper.colUpdatedAtInt],
    );

    return item;
  }

  static Future<void> recordNotificationStatus(String notificationType, String notificationTag, int status) async {
    //final String sql = 'INSERT INTO $tableName ($colNotificationType, $colNotificationTag, $colNotificationStatus, $colUpdatedAtInt) VALUES ("$notificationType","$notificationTag",$status,${DateTime.now().millisecondsSinceEpoch}) ON CONFLICT($colNotificationTag) DO UPDATE SET $colNotificationStatus = $status, $colUpdatedAtInt = ${DateTime.now().millisecondsSinceEpoch};';
    final String sql =
        'INSERT OR REPLACE INTO $tableName ($colNotificationType, $colNotificationTag, $colNotificationStatus, $colUpdatedAtInt) VALUES ("$notificationType","$notificationTag",$status,${DateTime.now().millisecondsSinceEpoch});';
    ////print(sql);
    await G0<Database>().rawQuery(sql);
  }
}
