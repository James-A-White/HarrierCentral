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

class EventModel {
  EventModel(
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
      this.tags1,
      this.tags2,
      this.tags3,
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
  final int tags1;
  final int tags2;
  final int tags3;
  final int removed;
  final DateTime updatedAt;

  static List<EventModel> itemsFromJson(String jsonResult) {
    final List<EventModel> items = <EventModel>[];

    EventModel item;

    json.decode(jsonResult).forEach(
      (dynamic jsonItem) {
        item = EventModel(
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
            tags1: jsonItem['tags1'],
            tags2: jsonItem['tags2'],
            tags3: jsonItem['tags3'],
            updatedAt: DateTime.parse(jsonItem['updatedAt'].toString().substring(0, 19)),
            removed: jsonItem['removed']);

        // CUSTOMIZATION

        // NOTE: Event images can either be full URLs or they can be partial URLs in the case
        // when events have been uploaded directly to the DB using the HcWeb application.
        // For partial URLs we need to append the root URL. The Root URL is stored in the
        // Server settings table and copied into the string prefs on app startup.
        if ((item.eventImage != null) && (item.eventImage.isNotEmpty) && (!item.eventImage.startsWith('http'))) {
          final String s = getStringPref(StringPrefsEnum.imageRootUrl) ?? BASE_HCWEB_UPLOAD_URL;
          if ((s != null) && (s.isNotEmpty)) {
            item.eventImage = s + item.eventImage;
          }
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

class EventTableHelper {
  EventTableHelper._privateConstructor();

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
  static const String colTags1 = 'tags1';
  static const String colTags2 = 'tags2';
  static const String colTags3 = 'tags3';

  static const String colRemoved = 'removed';
  static const String colUpdatedAt = 'updatedAt';
  static const String colUpdatedAtValue = 'updatedAtValue';

  // make this a singleton class

  static final EventTableHelper instance = EventTableHelper._privateConstructor();

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
            $colTags1 INT,
            $colTags2 INT,
            $colTags3 INT,

            $colRemoved NUM,
            $colUpdatedAt TEXT,
            $colUpdatedAtValue NUM NULL
          )
          ''');

    await db.execute('CREATE INDEX idx_${tableName}_id ON $tableName($remoteDbId);');
    await db.execute('CREATE INDEX idx_${tableName}_update_at_value ON $tableName($colUpdatedAtValue);');
  }

  static Map<String, dynamic> toMap(EventModel item) {
    final Map<String, dynamic> map = <String, dynamic>{
      EventTableHelper.colEventId: item.eventId,
      EventTableHelper.colEventStartDatetime: item.eventStartDatetime.toString(),
      EventTableHelper.colKennelId: item.kennelId,
      EventTableHelper.colIsVisible: item.isVisible,
      EventTableHelper.colIsCountedRun: item.isCountedRun,
      EventTableHelper.colEventNumber: item.eventNumber,
      EventTableHelper.colEventName: item.eventName,
      EventTableHelper.colNarrowEventLatitude: item.narrowEventLatitude,
      EventTableHelper.colNarrowEventLongitude: item.narrowEventLongitude,
      EventTableHelper.colEventPriceForMembers: item.eventPriceForMembers,
      EventTableHelper.colEventPriceForNonMembers: item.eventPriceForNonMembers,
      EventTableHelper.colEventFacebookId: item.eventFacebookId,
      EventTableHelper.colAbsoluteEventNumber: item.absoluteEventNumber,
      EventTableHelper.colCanEditRunAttendence: item.canEditRunAttendence,
      EventTableHelper.colEventImage: item.eventImage,
      EventTableHelper.colEventDescription: item.eventDescription,
      EventTableHelper.colLocationOneLineDesc: item.locationOneLineDesc,
      EventTableHelper.colLocationPostCode: item.locationPostCode,
      EventTableHelper.colLocationCity: item.locationCity,
      EventTableHelper.colLocationStreet: item.locationStreet,
      EventTableHelper.colHares: item.hares,
      EventTableHelper.colEventPaymentUrl: item.eventPaymentUrl,
      EventTableHelper.colEventPaymentUrlExpires: item.eventPaymentUrlExpires.toString(),
      EventTableHelper.colUnconfirmedBankXferCount: item.unconfirmedBankXferCount,
      EventTableHelper.colEventPriceForExtras: item.eventPriceForExtras,
      EventTableHelper.colExtrasDescription: item.extrasDescription,
      EventTableHelper.colDoTrackHashCash: item.doTrackHashCash,
      EventTableHelper.colTags1: item.tags1,
      EventTableHelper.colTags2: item.tags2,
      EventTableHelper.colTags3: item.tags3,
      EventTableHelper.colUpdatedAt: item.updatedAt.toString(),
      EventTableHelper.colUpdatedAtValue: item.updatedAt.millisecondsSinceEpoch,
      EventTableHelper.colRemoved: item.removed
    };

    return map;
  }

  static Map<String, dynamic> normalizeMap(Map<String, dynamic> inputMap) {
    final Map<String, dynamic> outputMap = <String, dynamic>{
      EventTableHelper.colEventId: inputMap[EventTableHelper.colEventId],
      EventTableHelper.colEventStartDatetime: inputMap[EventTableHelper.colEventStartDatetime],
      EventTableHelper.colKennelId: inputMap[EventTableHelper.colKennelId],
      EventTableHelper.colIsVisible: inputMap[EventTableHelper.colIsVisible],
      EventTableHelper.colIsCountedRun: inputMap[EventTableHelper.colIsCountedRun],
      EventTableHelper.colEventNumber: inputMap[EventTableHelper.colEventNumber],
      EventTableHelper.colEventName: inputMap[EventTableHelper.colEventName],
      EventTableHelper.colNarrowEventLatitude: inputMap[EventTableHelper.colNarrowEventLatitude],
      EventTableHelper.colNarrowEventLongitude: inputMap[EventTableHelper.colNarrowEventLongitude],
      EventTableHelper.colEventPriceForMembers: inputMap[EventTableHelper.colEventPriceForMembers],
      EventTableHelper.colEventPriceForNonMembers: inputMap[EventTableHelper.colEventPriceForNonMembers],
      EventTableHelper.colEventFacebookId: inputMap[EventTableHelper.colEventFacebookId],
      EventTableHelper.colAbsoluteEventNumber: inputMap[EventTableHelper.colAbsoluteEventNumber],
      EventTableHelper.colCanEditRunAttendence: inputMap[EventTableHelper.colCanEditRunAttendence],
      EventTableHelper.colEventImage: inputMap[EventTableHelper.colEventImage],
      EventTableHelper.colEventDescription: inputMap[EventTableHelper.colEventDescription],
      EventTableHelper.colLocationOneLineDesc: inputMap[EventTableHelper.colLocationOneLineDesc],
      EventTableHelper.colLocationPostCode: inputMap[EventTableHelper.colLocationPostCode],
      EventTableHelper.colLocationCity: inputMap[EventTableHelper.colLocationCity],
      EventTableHelper.colLocationStreet: inputMap[EventTableHelper.colLocationStreet],
      EventTableHelper.colHares: inputMap[EventTableHelper.colHares],
      EventTableHelper.colEventPaymentUrl: inputMap[EventTableHelper.colEventPaymentUrl],
      EventTableHelper.colEventPaymentUrlExpires: inputMap[EventTableHelper.colEventPaymentUrlExpires],
      EventTableHelper.colUnconfirmedBankXferCount: inputMap[EventTableHelper.colUnconfirmedBankXferCount],
      EventTableHelper.colEventPriceForExtras: inputMap[EventTableHelper.colEventPriceForExtras],
      EventTableHelper.colExtrasDescription: inputMap[EventTableHelper.colExtrasDescription],
      EventTableHelper.colDoTrackHashCash: inputMap[EventTableHelper.colDoTrackHashCash],
      EventTableHelper.colTags1: inputMap[EventTableHelper.colTags1],
      EventTableHelper.colTags2: inputMap[EventTableHelper.colTags2],
      EventTableHelper.colTags3: inputMap[EventTableHelper.colTags3],
      EventTableHelper.colUpdatedAt: inputMap[EventTableHelper.colUpdatedAt],
      EventTableHelper.colUpdatedAtValue: DateTime.parse(inputMap[EventTableHelper.colUpdatedAt].toString().substring(0, 19)).millisecondsSinceEpoch,
      EventTableHelper.colRemoved: inputMap[EventTableHelper.colRemoved],
    };

    // NOTE: Event images can either be full URLs or they can be partial URLs in the case
    // when events have been uploaded directly to the DB using the HcWeb application.
    // For partial URLs we need to append the root URL. The Root URL is stored in the
    // Server settings table and copied into the string prefs on app startup.
    if ((outputMap['eventImage'] != null) && (outputMap['eventImage'].isNotEmpty) && (!outputMap['eventImage'].startsWith('http'))) {
      final String s = getStringPref(StringPrefsEnum.imageRootUrl) ?? BASE_HCWEB_UPLOAD_URL;
      if ((s != null) && (s.isNotEmpty)) {
        outputMap['eventImage'] = s + outputMap['eventImage'];
      }
    }

    return outputMap;
  }

  static EventModel fromMap(Map<String, dynamic> map) {
    final EventModel item = EventModel(
      eventId: map[EventTableHelper.colEventId],
      eventStartDatetime: DateTime.parse(map[EventTableHelper.colEventStartDatetime].toString().substring(0, 19)),
      kennelId: map[EventTableHelper.colKennelId],
      isVisible: map[EventTableHelper.colIsVisible],
      isCountedRun: map[EventTableHelper.colIsCountedRun],
      eventNumber: map[EventTableHelper.colEventNumber],
      eventName: map[EventTableHelper.colEventName],
      narrowEventLatitude: map[EventTableHelper.colNarrowEventLatitude],
      narrowEventLongitude: map[EventTableHelper.colNarrowEventLongitude],
      eventPriceForMembers: map[EventTableHelper.colEventPriceForMembers],
      eventPriceForNonMembers: map[EventTableHelper.colEventPriceForNonMembers],
      eventFacebookId: map[EventTableHelper.colEventFacebookId],
      absoluteEventNumber: map[EventTableHelper.colAbsoluteEventNumber],
      canEditRunAttendence: map[EventTableHelper.colCanEditRunAttendence],
      eventImage: map[EventTableHelper.colEventImage],
      eventDescription: map[EventTableHelper.colEventDescription],
      locationOneLineDesc: map[EventTableHelper.colLocationOneLineDesc],
      locationPostCode: map[EventTableHelper.colLocationPostCode],
      locationCity: map[EventTableHelper.colLocationCity],
      locationStreet: map[EventTableHelper.colLocationStreet],
      hares: map[EventTableHelper.colHares],
      eventPaymentUrl: map[EventTableHelper.colEventPaymentUrl],
      eventPaymentUrlExpires: DateTime.parse((map[EventTableHelper.colEventPaymentUrlExpires] ?? '2000-01-01 01:00:00').toString().substring(0, 19)),
      unconfirmedBankXferCount: map[EventTableHelper.colUnconfirmedBankXferCount],
      eventPriceForExtras: map[EventTableHelper.colEventPriceForExtras],
      extrasDescription: map[EventTableHelper.colExtrasDescription],
      doTrackHashCash: map[EventTableHelper.colDoTrackHashCash],
      tags1: map[EventTableHelper.colTags1],
      tags2: map[EventTableHelper.colTags2],
      tags3: map[EventTableHelper.colTags3],
      updatedAt: DateTime.parse(map[EventTableHelper.colUpdatedAt].toString().substring(0, 19)),
      removed: map[EventTableHelper.colRemoved],
    );

    // NOTE: Event images can either be full URLs or they can be partial URLs in the case
    // when events have been uploaded directly to the DB using the HcWeb application.
    // For partial URLs we need to append the root URL. The Root URL is stored in the
    // Server settings table and copied into the string prefs on app startup.
    if ((item.eventImage != null) && (item.eventImage.isNotEmpty) && (!item.eventImage.startsWith('http'))) {
      final String s = getStringPref(StringPrefsEnum.imageRootUrl) ?? BASE_HCWEB_UPLOAD_URL;
      if ((s != null) && (s.isNotEmpty)) {
        item.eventImage = s + item.eventImage;
      }
    }

    return item;
  }
}

class EventService {
  static final EventTableHelper instance = EventTableHelper._privateConstructor();

  static Future<num> getLastUpdatedTime() async {
    final Database db = await DBProvider.db.database;
    final List<Map<String, dynamic>> table = await db.rawQuery('SELECT MAX(${EventTableHelper.colUpdatedAtValue}) AS maxDate FROM ${EventTableHelper.tableName}');
    final num timeValue = table.first['maxDate'];
    return timeValue;
  }

  Future<void> clearTable() async {
    final Database db = await DBProvider.db.database;
    await db.rawDelete('DELETE FROM ${EventTableHelper.tableName}').then((void dummy) {
      setIntPref(EventTableHelper.lastCacheClearKey, DateTime.now().millisecondsSinceEpoch);
    });
  }

  Future<void> updateDatabase(List<EventModel> items) async {
    final Database db = await DBProvider.db.database;

    for (int i = 0; i < items?.length ?? 0; i++) {
      final Map<String, dynamic> row = EventTableHelper.toMap(items[i]);

      final List<Map<String, dynamic>> table = await db.rawQuery('SELECT * FROM ${EventTableHelper.tableName} WHERE ${EventTableHelper.remoteDbId} = "${items[i].eventId}"');
      if ((table == null) || (table.isEmpty)) {
        await db.transaction<dynamic>((Transaction txn) async {
          final int result = await txn.insert(EventTableHelper.tableName, row);
          print(result.toString() + ' inserted into to the ${EventTableHelper.tableName} table @ ${DateTime.now().millisecondsSinceEpoch.toString()}');
        });
      } else {
        final String rowId = table.first['id'].toString();

        await db.transaction<dynamic>((Transaction txn) async {
          final int result = await txn.update(EventTableHelper.tableName, row, where: 'id = $rowId');
          print(result.toString() + ' update to the ${EventTableHelper.tableName} table @ ${DateTime.now().millisecondsSinceEpoch.toString()}');
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
          final Map<String, dynamic> testMap = EventTableHelper.normalizeMap(jsonItem);
          doNormalizeMap = (testMap.length - 1) != jsonItem.length;
          if (doNormalizeMap) {
            print('Normalize map called for ${EventTableHelper.tableName}, # of fields on the wire = ${jsonItem.length}, # of fields in internal DB = ${testMap.length - 1}');
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

        final String query = 'SELECT * FROM ${EventTableHelper.tableName} WHERE ${EventTableHelper.remoteDbId} = "${jsonItem['eventId']}"';
        final List<Map<String, dynamic>> table = await db.rawQuery(query);

        if ((table == null) || (table.isEmpty)) {
          //print(table.length.toString());
          await db.transaction<dynamic>((Transaction txn) async {
            //final int result =
            await txn.insert(EventTableHelper.tableName, doNormalizeMap ? EventTableHelper.normalizeMap(jsonItem) : jsonItem);
            insertCounter++;
            // print(result.toString() +
            //     ' inserted into to the ${NarrowEventsTableHelper.table} table @ ${DateTime.now().millisecondsSinceEpoch}');
          });
        } else {
          final String rowId = table.first['id'].toString();

          await db.transaction<dynamic>((Transaction txn) async {
            //final int result =
            await txn.update(EventTableHelper.tableName, doNormalizeMap ? EventTableHelper.normalizeMap(jsonItem) : jsonItem, where: 'id = $rowId');
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

    final num _eventsLastUpdated = await EventService.getLastUpdatedTime();
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
