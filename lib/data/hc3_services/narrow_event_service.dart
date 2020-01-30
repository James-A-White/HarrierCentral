import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';

import 'package:harrier_central/database/database.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/util/utilities.dart';
import 'package:harrier_central/util/globals.dart';
import 'package:harrier_central/data/hc3_services/sync_user_data_service.dart';
import 'package:harrier_central/util/enums.dart';

class NarrowEventsModel {
  NarrowEventsModel(
      {this.eventId,
      this.eventStartDatetime,
      this.kennelId,
      this.isVisible,
      this.isCountedRun,
      this.eventNumber,
      this.eventName,
      this.narrowEventLatitude,
      this.narrowEventLongitude,
      this.eventPriceForMembers,
      this.eventPriceForNonMembers,
      this.eventFacebookId,
      this.absoluteEventNumber,
      this.canEditRunAttendence,
      this.eventImage,
      this.eventDescription,
      this.locationOneLineDesc,
      this.locationPostCode,
      this.locationCity,
      this.locationStreet,
      this.hares,
      this.eventPaymentUrl,
      this.eventPaymentUrlExpires,
      this.unconfirmedBankXferCount,
      this.eventPriceForExtras,
      this.extrasDescription,
      this.doTrackHashCash,
      this.removed,
      this.updatedAt});

  final String eventId;
  final DateTime eventStartDatetime;
  final String kennelId;
  final int isVisible;
  final int isCountedRun;
  final int eventNumber;
  final String eventName;
  final num narrowEventLatitude;
  final num narrowEventLongitude;
  final num eventPriceForMembers;
  final num eventPriceForNonMembers;
  final String eventFacebookId;
  final num absoluteEventNumber;
  final num canEditRunAttendence;
  String eventImage;
  final String eventDescription;
  final String locationOneLineDesc;
  final String locationPostCode;
  final String locationCity;
  final String locationStreet;
  final String hares;
  final String eventPaymentUrl;
  final DateTime eventPaymentUrlExpires;
  final int unconfirmedBankXferCount;
  final num eventPriceForExtras;
  final String extrasDescription;
  final int doTrackHashCash;
  final int removed;
  final DateTime updatedAt;

  static List<NarrowEventsModel> itemsFromJson(String jsonResult) {
    final List<NarrowEventsModel> items = <NarrowEventsModel>[];

    NarrowEventsModel item;

    json.decode(jsonResult).forEach(
      (dynamic jsonItem) {
        item = NarrowEventsModel(
            eventId: jsonItem['eventId'],
            eventStartDatetime: jsonItem['eventStartDatetime'],
            kennelId: jsonItem['kennelId'],
            isVisible: jsonItem['isVisible'],
            isCountedRun: jsonItem['isCountedRun'],
            eventNumber: jsonItem['eventNumber'],
            eventName: jsonItem['eventName'],
            narrowEventLatitude: jsonItem['narrowEventLatitude'],
            narrowEventLongitude: jsonItem['narrowEventLongitude'],
            eventPriceForMembers: jsonItem['eventPriceForMembers'],
            eventPriceForNonMembers: jsonItem['eventPriceForNonMembers'],
            eventFacebookId: jsonItem['eventFacebookId'],
            absoluteEventNumber: jsonItem['absoluteEventNumber'],
            canEditRunAttendence: jsonItem['canEditRunAttendence'],
            eventImage: jsonItem['eventImage'],
            eventDescription: jsonItem['eventDescription'],
            locationOneLineDesc: jsonItem['locationOneLineDesc'],
            locationPostCode: jsonItem['locationPostCode'],
            locationCity: jsonItem['locationCity'],
            locationStreet: jsonItem['locationStreet'],
            hares: jsonItem['hares'],
            eventPaymentUrl: jsonItem['eventPaymentUrl'],
            eventPaymentUrlExpires: jsonItem['eventPaymentUrlExpires'],
            unconfirmedBankXferCount: jsonItem['unconfirmedBankXferCount'],
            eventPriceForExtras: jsonItem['eventPriceForExtras'],
            extrasDescription: jsonItem['extrasDescription'],
            doTrackHashCash: jsonItem['doTrackHashCash'],
            updatedAt: DateTime.parse(jsonItem['updatedAt'].toString().substring(0, 19)),
            removed: jsonItem['removed']);

        // CUSTOMIZATION

        if (!item.eventImage.startsWith('http')) {
          item.eventImage = getStringPref(StringPrefsEnum.imageRootUrl) + item.eventImage;
        }

        items.add(item);
      },
    );

    if (items.isEmpty) {
      return null;
    }

    return items;
  }
}

class NarrowEventsTableHelper {
  NarrowEventsTableHelper._privateConstructor();

  static const String tableName = 'narrowEvents';
  //static const num forceRequeryInterval = 1 * 86400000;
  static const num forceRequeryInterval = 1 * 1000;
  static const num cacheDuration = 365 * 3 * 86400000; // cause a force refresh of the cache every 3 years. This effectively prevents cache refreshes

  static const IntPrefsEnum lastUpdatedKey = IntPrefsEnum.lastUpdateNarrowEventsData;
  static const IntPrefsEnum lastCacheClearKey = IntPrefsEnum.lastCacheClearNarrowEventsData;

  static const String colId = 'id';
  static const String remoteDbId = 'eventId';

  static const String colEventId = 'eventId';
  static const String colEventStartDatetime = 'eventStartDatetime';
  static const String colKennelId = 'kennelId';
  static const String colIsVisible = 'isVisible';
  static const String colIsCountedRun = 'isCountedRun';
  static const String colEventNumber = 'eventNumber';
  static const String colEventName = 'eventName';
  static const String colNarrowEventLatitude = 'narrowEventLatitude';
  static const String colNarrowEventLongitude = 'narrowEventLongitude';
  static const String colEventPriceForMembers = 'eventPriceForMembers';
  static const String colEventPriceForNonMembers = 'eventPriceForNonMembers';
  static const String colEventFacebookId = 'eventFacebookId';
  static const String colAbsoluteEventNumber = 'absoluteEventNumber';
  static const String colCanEditRunAttendence = 'canEditRunAttendence';
  static const String colEventImage = 'eventImage';
  static const String colEventDescription = 'eventDescription';
  static const String colLocationOneLineDesc = 'locationOneLineDesc';
  static const String colLocationPostCode = 'locationPostCode';
  static const String colLocationCity = 'locationCity';
  static const String colLocationStreet = 'locationStreet';
  static const String colHares = 'hares';
  static const String colEventPaymentUrl = 'eventPaymentUrl';
  static const String colEventPaymentUrlExpires = 'eventPaymentUrlExpires';
  static const String colUnconfirmedBankXferCount = 'unconfirmedBankXferCount';
  static const String colEventPriceForExtras = 'eventPriceForExtras';
  static const String colExtrasDescription = 'extrasDescription';
  static const String colDoTrackHashCash = 'doTrackHashCash';

  static const String colRemoved = 'removed';
  static const String colUpdatedAt = 'updatedAt';
  static const String colUpdatedAtValue = 'updatedAtValue';

  // make this a singleton class

  static final NarrowEventsTableHelper instance = NarrowEventsTableHelper._privateConstructor();

  // SQL code to create the database table
  static Future<dynamic> createTable(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $tableName (
            $colId INTEGER PRIMARY KEY,

            $colEventId TEXT NOT NULL,
            $colEventStartDatetime TEXT,
            $colKennelId TEXT NOT NULL,
            $colIsVisible INT,
            $colIsCountedRun INT,
            $colEventNumber INT,
            $colEventName TEXT,
            $colNarrowEventLatitude NUM,
            $colNarrowEventLongitude NUM,
            $colEventPriceForMembers NUM,
            $colEventPriceForNonMembers NUM,
            $colEventFacebookId TEXT,
            $colAbsoluteEventNumber NUM,
            $colCanEditRunAttendence NUM,
            $colEventImage TEXT,
            $colEventDescription TEXT,
            $colLocationOneLineDesc TEXT,
            $colLocationPostCode TEXT,
            $colLocationCity TEXT,
            $colLocationStreet TEXT,
            $colHares TEXT,
            $colEventPaymentUrl TEXT,
            $colEventPaymentUrlExpires TEXT,
            $colUnconfirmedBankXferCount INT,
            $colEventPriceForExtras NUM,
            $colExtrasDescription TEXT,
            $colDoTrackHashCash INT,

            $colRemoved NUM,
            $colUpdatedAt TEXT,
            $colUpdatedAtValue NUM NULL
          )
          ''');

    await db.execute('CREATE INDEX idx_${tableName}_id ON $tableName($remoteDbId);');
    await db.execute('CREATE INDEX idx_${tableName}_update_at_value ON $tableName($colUpdatedAtValue);');
  }

  static Map<String, dynamic> toMap(NarrowEventsModel item) {
    final Map<String, dynamic> map = <String, dynamic>{
      NarrowEventsTableHelper.colEventId: item.eventId,
      NarrowEventsTableHelper.colEventStartDatetime: item.eventStartDatetime.toString(),
      NarrowEventsTableHelper.colKennelId: item.kennelId,
      NarrowEventsTableHelper.colIsVisible: item.isVisible,
      NarrowEventsTableHelper.colIsCountedRun: item.isCountedRun,
      NarrowEventsTableHelper.colEventNumber: item.eventNumber,
      NarrowEventsTableHelper.colEventName: item.eventName,
      NarrowEventsTableHelper.colNarrowEventLatitude: item.narrowEventLatitude,
      NarrowEventsTableHelper.colNarrowEventLongitude: item.narrowEventLongitude,
      NarrowEventsTableHelper.colEventPriceForMembers: item.eventPriceForMembers,
      NarrowEventsTableHelper.colEventPriceForNonMembers: item.eventPriceForNonMembers,
      NarrowEventsTableHelper.colEventFacebookId: item.eventFacebookId,
      NarrowEventsTableHelper.colAbsoluteEventNumber: item.absoluteEventNumber,
      NarrowEventsTableHelper.colCanEditRunAttendence: item.canEditRunAttendence,
      NarrowEventsTableHelper.colEventImage: item.eventImage,
      NarrowEventsTableHelper.colEventDescription: item.eventDescription,
      NarrowEventsTableHelper.colLocationOneLineDesc: item.locationOneLineDesc,
      NarrowEventsTableHelper.colLocationPostCode: item.locationPostCode,
      NarrowEventsTableHelper.colLocationCity: item.locationCity,
      NarrowEventsTableHelper.colLocationStreet: item.locationStreet,
      NarrowEventsTableHelper.colHares: item.hares,
      NarrowEventsTableHelper.colEventPaymentUrl: item.eventPaymentUrl,
      NarrowEventsTableHelper.colEventPaymentUrlExpires: item.eventPaymentUrlExpires.toString(),
      NarrowEventsTableHelper.colUnconfirmedBankXferCount: item.unconfirmedBankXferCount,
      NarrowEventsTableHelper.colEventPriceForExtras: item.eventPriceForExtras,
      NarrowEventsTableHelper.colExtrasDescription: item.extrasDescription,
      NarrowEventsTableHelper.colDoTrackHashCash: item.doTrackHashCash,
      NarrowEventsTableHelper.colUpdatedAt: item.updatedAt.toString(),
      NarrowEventsTableHelper.colUpdatedAtValue: item.updatedAt.millisecondsSinceEpoch,
      NarrowEventsTableHelper.colRemoved: item.removed
    };

    return map;
  }

  static Map<String, dynamic> normalizeMap(Map<String, dynamic> inputMap) {
    final Map<String, dynamic> outputMap = <String, dynamic>{
      NarrowEventsTableHelper.colEventId: inputMap[NarrowEventsTableHelper.colEventId],
      NarrowEventsTableHelper.colEventStartDatetime: inputMap[NarrowEventsTableHelper.colEventStartDatetime],
      NarrowEventsTableHelper.colKennelId: inputMap[NarrowEventsTableHelper.colKennelId],
      NarrowEventsTableHelper.colIsVisible: inputMap[NarrowEventsTableHelper.colIsVisible],
      NarrowEventsTableHelper.colIsCountedRun: inputMap[NarrowEventsTableHelper.colIsCountedRun],
      NarrowEventsTableHelper.colEventNumber: inputMap[NarrowEventsTableHelper.colEventNumber],
      NarrowEventsTableHelper.colEventName: inputMap[NarrowEventsTableHelper.colEventName],
      NarrowEventsTableHelper.colNarrowEventLatitude: inputMap[NarrowEventsTableHelper.colNarrowEventLatitude],
      NarrowEventsTableHelper.colNarrowEventLongitude: inputMap[NarrowEventsTableHelper.colNarrowEventLongitude],
      NarrowEventsTableHelper.colEventPriceForMembers: inputMap[NarrowEventsTableHelper.colEventPriceForMembers],
      NarrowEventsTableHelper.colEventPriceForNonMembers: inputMap[NarrowEventsTableHelper.colEventPriceForNonMembers],
      NarrowEventsTableHelper.colEventFacebookId: inputMap[NarrowEventsTableHelper.colEventFacebookId],
      NarrowEventsTableHelper.colAbsoluteEventNumber: inputMap[NarrowEventsTableHelper.colAbsoluteEventNumber],
      NarrowEventsTableHelper.colCanEditRunAttendence: inputMap[NarrowEventsTableHelper.colCanEditRunAttendence],
      NarrowEventsTableHelper.colEventImage: inputMap[NarrowEventsTableHelper.colEventImage],
      NarrowEventsTableHelper.colEventDescription: inputMap[NarrowEventsTableHelper.colEventDescription],
      NarrowEventsTableHelper.colLocationOneLineDesc: inputMap[NarrowEventsTableHelper.colLocationOneLineDesc],
      NarrowEventsTableHelper.colLocationPostCode: inputMap[NarrowEventsTableHelper.colLocationPostCode],
      NarrowEventsTableHelper.colLocationCity: inputMap[NarrowEventsTableHelper.colLocationCity],
      NarrowEventsTableHelper.colLocationStreet: inputMap[NarrowEventsTableHelper.colLocationStreet],
      NarrowEventsTableHelper.colHares: inputMap[NarrowEventsTableHelper.colHares],
      NarrowEventsTableHelper.colEventPaymentUrl: inputMap[NarrowEventsTableHelper.colEventPaymentUrl],
      NarrowEventsTableHelper.colEventPaymentUrlExpires: inputMap[NarrowEventsTableHelper.colEventPaymentUrlExpires],
      NarrowEventsTableHelper.colUnconfirmedBankXferCount: inputMap[NarrowEventsTableHelper.colUnconfirmedBankXferCount],
      NarrowEventsTableHelper.colEventPriceForExtras: inputMap[NarrowEventsTableHelper.colEventPriceForExtras],
      NarrowEventsTableHelper.colExtrasDescription: inputMap[NarrowEventsTableHelper.colExtrasDescription],
      NarrowEventsTableHelper.colDoTrackHashCash: inputMap[NarrowEventsTableHelper.colDoTrackHashCash],
      NarrowEventsTableHelper.colUpdatedAt: inputMap[NarrowEventsTableHelper.colUpdatedAt],
      NarrowEventsTableHelper.colUpdatedAtValue: DateTime.parse(inputMap[NarrowEventsTableHelper.colUpdatedAt].toString().substring(0, 19)).millisecondsSinceEpoch,
      NarrowEventsTableHelper.colRemoved: inputMap[NarrowEventsTableHelper.colRemoved],
    };

    if (!outputMap['eventImage'].startsWith('http')) {
      outputMap['eventImage'] = getStringPref(StringPrefsEnum.imageRootUrl) + outputMap['eventImage'];
    }

    return outputMap;
  }

  static NarrowEventsModel fromMap(Map<String, dynamic> map) {
    final NarrowEventsModel item = NarrowEventsModel(
      eventId: map[NarrowEventsTableHelper.colEventId],
      eventStartDatetime: DateTime.parse(map[NarrowEventsTableHelper.colEventStartDatetime].toString().substring(0, 19)),
      kennelId: map[NarrowEventsTableHelper.colKennelId],
      isVisible: map[NarrowEventsTableHelper.colIsVisible],
      isCountedRun: map[NarrowEventsTableHelper.colIsCountedRun],
      eventNumber: map[NarrowEventsTableHelper.colEventNumber],
      eventName: map[NarrowEventsTableHelper.colEventName],
      narrowEventLatitude: map[NarrowEventsTableHelper.colNarrowEventLatitude],
      narrowEventLongitude: map[NarrowEventsTableHelper.colNarrowEventLongitude],
      eventPriceForMembers: map[NarrowEventsTableHelper.colEventPriceForMembers],
      eventPriceForNonMembers: map[NarrowEventsTableHelper.colEventPriceForNonMembers],
      eventFacebookId: map[NarrowEventsTableHelper.colEventFacebookId],
      absoluteEventNumber: map[NarrowEventsTableHelper.colAbsoluteEventNumber],
      canEditRunAttendence: map[NarrowEventsTableHelper.colCanEditRunAttendence],
      eventImage: map[NarrowEventsTableHelper.colEventImage],
      eventDescription: map[NarrowEventsTableHelper.colEventDescription],
      locationOneLineDesc: map[NarrowEventsTableHelper.colLocationOneLineDesc],
      locationPostCode: map[NarrowEventsTableHelper.colLocationPostCode],
      locationCity: map[NarrowEventsTableHelper.colLocationCity],
      locationStreet: map[NarrowEventsTableHelper.colLocationStreet],
      hares: map[NarrowEventsTableHelper.colHares],
      eventPaymentUrl: map[NarrowEventsTableHelper.colEventPaymentUrl],
      eventPaymentUrlExpires: DateTime.parse((map[NarrowEventsTableHelper.colEventPaymentUrlExpires] ?? '2000-01-01 01:00:00').toString().substring(0, 19)),
      unconfirmedBankXferCount: map[NarrowEventsTableHelper.colUnconfirmedBankXferCount],
      eventPriceForExtras: map[NarrowEventsTableHelper.colEventPriceForExtras],
      extrasDescription: map[NarrowEventsTableHelper.colExtrasDescription],
      doTrackHashCash: map[NarrowEventsTableHelper.colDoTrackHashCash],
      updatedAt: DateTime.parse(map[NarrowEventsTableHelper.colUpdatedAt].toString().substring(0, 19)),
      removed: map[NarrowEventsTableHelper.colRemoved],
    );

    if (!item.eventImage.startsWith('http')) {
      item.eventImage = getStringPref(StringPrefsEnum.imageRootUrl) + item.eventImage;
    }

    return item;
  }
}

class NarrowEventsService {
  static final NarrowEventsTableHelper instance = NarrowEventsTableHelper._privateConstructor();

  static Future<num> getLastUpdatedTime() async {
    final Database db = await DBProvider.db.database;
    final List<Map<String, dynamic>> table = await db.rawQuery('SELECT MAX(${NarrowEventsTableHelper.colUpdatedAtValue}) AS maxDate FROM ${NarrowEventsTableHelper.tableName}');
    final num timeValue = table.first['maxDate'];
    return timeValue;
  }

  Future<void> clearTable() async {
    final Database db = await DBProvider.db.database;
    await db.rawDelete('DELETE FROM ${NarrowEventsTableHelper.tableName}').then((void dummy) {
      setIntPref(NarrowEventsTableHelper.lastCacheClearKey, DateTime.now().millisecondsSinceEpoch);
    });
  }

  Future<void> updateDatabase(List<NarrowEventsModel> items) async {
    final Database db = await DBProvider.db.database;

    for (int i = 0; i < items?.length ?? 0; i++) {
      final Map<String, dynamic> row = NarrowEventsTableHelper.toMap(items[i]);

      final List<Map<String, dynamic>> table = await db.rawQuery('SELECT * FROM ${NarrowEventsTableHelper.tableName} WHERE ${NarrowEventsTableHelper.remoteDbId} = "${items[i].eventId}"');
      if ((table == null) || (table.isEmpty)) {
        await db.transaction<dynamic>((Transaction txn) async {
          final int result = await txn.insert(NarrowEventsTableHelper.tableName, row);
          print(result.toString() + ' inserted into to the ${NarrowEventsTableHelper.tableName} table @ ${DateTime.now().millisecondsSinceEpoch.toString()}');
        });
      } else {
        final String rowId = table.first['id'].toString();

        await db.transaction<dynamic>((Transaction txn) async {
          final int result = await txn.update(NarrowEventsTableHelper.tableName, row, where: 'id = $rowId');
          print(result.toString() + ' update to the ${NarrowEventsTableHelper.tableName} table @ ${DateTime.now().millisecondsSinceEpoch.toString()}');
        });
      }
    }
  }

  Future<int> bulkUpdateDatabase(String rawResults, Database db, Function informUser) async {
    int updateCounter = 0;
    int insertCounter = 0;

    bool doNormalizeMap;

    final List<dynamic> jsonResultSets = json.decode(rawResults);

    final int len = jsonResultSets.length;
    int lastPercentage = 0;

    print('Event recordsets received from cloud = $len');

    for (int i = 0; i < jsonResultSets.length; i++) {
      final List<dynamic> jsonResults = jsonResultSets[i];

      for (int j = 0; j < jsonResults.length; j++) {
        final Map<String, dynamic> jsonItem = jsonResults[j];

        if (doNormalizeMap == null) {
          final Map<String, dynamic> testMap = NarrowEventsTableHelper.normalizeMap(jsonItem);
          doNormalizeMap = (testMap.length - 1) != jsonItem.length;
          if (doNormalizeMap) {
            print('Normalize map called for ${NarrowEventsTableHelper.tableName}, # of fields on the wire = ${jsonItem.length}, # of fields in internal DB = ${testMap.length - 1}');
          }
        }

        final int percentage = (100 * (j / jsonResults.length)).round();
        if ((percentage != lastPercentage) && (informUser != null)) {
          lastPercentage = percentage;
          informUser('Loading event data\r\n$percentage% complete');
        }

        jsonItem.addAll(<String, dynamic>{
          'updatedAtValue': DateTime.parse(jsonItem['updatedAt'].toString().substring(0, 19)).millisecondsSinceEpoch,
        });

        final String query = 'SELECT * FROM ${NarrowEventsTableHelper.tableName} WHERE ${NarrowEventsTableHelper.remoteDbId} = "${jsonItem['eventId']}"';
        final List<Map<String, dynamic>> table = await db.rawQuery(query);

        if ((table == null) || (table.isEmpty)) {
          //print(table.length.toString());
          await db.transaction<dynamic>((Transaction txn) async {
            //final int result =
            await txn.insert(NarrowEventsTableHelper.tableName, doNormalizeMap ? NarrowEventsTableHelper.normalizeMap(jsonItem) : jsonItem);
            insertCounter++;
            // print(result.toString() +
            //     ' inserted into to the ${NarrowEventsTableHelper.table} table @ ${DateTime.now().millisecondsSinceEpoch}');
          });
        } else {
          final String rowId = table.first['id'].toString();

          await db.transaction<dynamic>((Transaction txn) async {
            //final int result =
            await txn.update(NarrowEventsTableHelper.tableName, doNormalizeMap ? NarrowEventsTableHelper.normalizeMap(jsonItem) : jsonItem, where: 'id = $rowId');
            updateCounter++;
            // print(result.toString() +
            //     ' update to the ${NarrowEventsTableHelper.table} table @ ${DateTime.now().millisecondsSinceEpoch}');
          });
        }
      }
    }

    print('$insertCounter event records inserted, $updateCounter event records updated');
    return insertCounter;
  }

  // ============ Functions go here =============

  Future<void> updateEventDetails(String eventId, {bool isVisible, bool isCountedRun, int absoluteEventNumber}) async {
    if (globalConnectionStatus == connectionStatus_notConnected) {
      return;
      // TODO(James): fix this so we can return a bool
      //return false;
    }

    final String userId = getStringPref(StringPrefsEnum.userId);

    final String accessToken = Utilities.generateToken(userId, 'addEditEvent');

    final num _eventsLastUpdated = await NarrowEventsService.getLastUpdatedTime();
    final DateTime eventUpdatedAfter = _eventsLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMillisecondsSinceEpoch(_eventsLastUpdated + 1000);

    final Map<String, String> bodyMap = <String, String>{'userId': userId, 'accessToken': accessToken, 'narrowEventsUpdatedAfter': eventUpdatedAfter.toString(), 'eventId': eventId};
    if (isVisible != null) {
      bodyMap.addAll(<String, String>{'isVisible': isVisible ? '1' : '0'});
    }

    if (isCountedRun != null) {
      bodyMap.addAll(<String, String>{'isCountedRun': isCountedRun ? '1' : '0'});
    }

    if (absoluteEventNumber != null) {
      bodyMap.addAll(<String, String>{'absoluteEventNumber': absoluteEventNumber.toString()});
    }

    final String body = jsonEncode(bodyMap);

    final http.Response response = await http
        .post(BASE_API_URL + 'hc3_add_edit_event', headers: <String, String>{'content-type': 'application/json'}, body: body
            // Send authorization headers to your backend
            //headers: {HttpHeaders.authorizationHeader: 'Basic your_api_token_here'},
            )
        .catchError(
      (dynamic error) {
        return false;
      },
    );

    await SyncUserDataService.updateSqlTablesWithResultsFromBackendApiCall(response.body);

    return;
  }

  static Future<Map<String, String>> sendRunDetailsByEmail({String eventId, String emailBody = ''}) async {
    final String userId = getStringPref(StringPrefsEnum.userId);
    final String accessToken = Utilities.generateToken(userId, 'rptApi_emailRunDetails', paramString: eventId);

    final String body = jsonEncode(<String, String>{'userId': userId, 'accessToken': accessToken, 'eventId': eventId, 'emailBody': emailBody});

    print(body);

    final http.Response response = await http
        .post(EMAIL_RUN_DETAILS_TO_PACK_API_URL, headers: <String, String>{'content-type': 'application/json'}, body: body
            // Send authorization headers to your backend
            //headers: {HttpHeaders.authorizationHeader: 'Basic your_api_token_here'},
            )
        .catchError(
      (dynamic error) {
        return <String, String>{'result': 'error', 'email': ''};
      },
    );

    return <String, String>{'result': response.body};
  }
}
