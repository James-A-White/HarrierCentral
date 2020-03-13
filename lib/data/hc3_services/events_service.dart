import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';

import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/util/utilities.dart';
import 'package:harrier_central/util/globals.dart';
import 'package:harrier_central/data/hc3_services/sync_user_data_service.dart';
import 'package:harrier_central/util/enums.dart';
import 'package:harrier_central/data/hc3_services/base_service.dart';

class EventModel implements BaseModel {
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
      this.locationCountry,
      this.locationRegion,
      this.locationSubRegion,
      this.hares,
      this.eventPaymentScheme,
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
  final String locationCountry;
  final String locationRegion;
  final String locationSubRegion;
  String hares;
  final String eventPaymentScheme;
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

  @override
  List<EventModel> itemsFromJson(String jsonResult) {
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
            locationCountry: jsonItem['locationCountry'],
            locationRegion: jsonItem['locationRegion'],
            locationSubRegion: jsonItem['locationSubRegion'],
            hares: jsonItem['hares'],
            eventPaymentScheme: jsonItem['eventPaymentScheme'],
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

class EventsTableHelper with BaseFields implements BaseTableHelper {
  EventsTableHelper();

  @override
  num forceRequeryInterval;

  @override
  num cacheDuration;

  @override
  String tableName = 'narrowEvents';

  @override
  String getTableName(TableType type) {
    return tableName;
  }

  @override
  String remoteDbId = 'eventId';

  final String colEventId = 'eventId';
  final String colEventStartDatetime = 'eventStartDatetime';
  final String colKennelId = 'kennelId';
  final String colIsVisible = 'isVisible';
  final String colIsCountedRun = 'isCountedRun';
  final String colEventNumber = 'eventNumber';
  final String colEventName = 'eventName';
  final String colNarrowEventLatitude = 'narrowEventLatitude';
  final String colNarrowEventLongitude = 'narrowEventLongitude';
  final String colEventPriceForMembers = 'eventPriceForMembers';
  final String colEventPriceForNonMembers = 'eventPriceForNonMembers';
  final String colEventFacebookId = 'eventFacebookId';
  final String colAbsoluteEventNumber = 'absoluteEventNumber';
  final String colCanEditRunAttendence = 'canEditRunAttendence';
  final String colEventImage = 'eventImage';
  final String colEventDescription = 'eventDescription';
  final String colLocationOneLineDesc = 'locationOneLineDesc';
  final String colLocationPostCode = 'locationPostCode';
  final String colLocationCity = 'locationCity';
  final String colLocationStreet = 'locationStreet';
  final String colLocationCountry = 'locationCountry';
  final String colLocationRegion= 'locationRegion';
  final String colLocationSubRegion= 'locationSubRegion';
  final String colHares = 'hares';
  final String colEventPaymentScheme = 'eventPaymentScheme';
  final String colEventPaymentUrl = 'eventPaymentUrl';
  final String colEventPaymentUrlExpires = 'eventPaymentUrlExpires';
  final String colUnconfirmedBankXferCount = 'unconfirmedBankXferCount';
  final String colEventPriceForExtras = 'eventPriceForExtras';
  final String colExtrasDescription = 'extrasDescription';
  final String colDoTrackHashCash = 'doTrackHashCash';
  final String colTags1 = 'tags1';
  final String colTags2 = 'tags2';
  final String colTags3 = 'tags3';

  @override
  Future<dynamic> createTable(Database db, int version,TableType tableType) async {
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
            $colLocationCountry TEXT,
            $colLocationRegion TEXT,
            $colLocationSubRegion TEXT,
            $colHares TEXT,
            $colEventPaymentScheme TEXT,
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

  @override
  Map<String, dynamic> toMap(dynamic item) {
    final Map<String, dynamic> map = <String, dynamic>{
      colEventId: item.eventId,
      colEventStartDatetime: item.eventStartDatetime.toString(),
      colKennelId: item.kennelId,
      colIsVisible: item.isVisible,
      colIsCountedRun: item.isCountedRun,
      colEventNumber: item.eventNumber,
      colEventName: item.eventName,
      colNarrowEventLatitude: item.narrowEventLatitude,
      colNarrowEventLongitude: item.narrowEventLongitude,
      colEventPriceForMembers: item.eventPriceForMembers,
      colEventPriceForNonMembers: item.eventPriceForNonMembers,
      colEventFacebookId: item.eventFacebookId,
      colAbsoluteEventNumber: item.absoluteEventNumber,
      colCanEditRunAttendence: item.canEditRunAttendence,
      colEventImage: item.eventImage,
      colEventDescription: item.eventDescription,
      colLocationOneLineDesc: item.locationOneLineDesc,
      colLocationPostCode: item.locationPostCode,
      colLocationCity: item.locationCity,
      colLocationStreet: item.locationStreet,
      colLocationCountry: item.locationCountry,
      colLocationRegion: item.locationRegion,
      colLocationSubRegion: item.locationSubRegion,
      colHares: item.hares,
      colEventPaymentScheme: item.eventPaymentScheme,
      colEventPaymentUrl: item.eventPaymentUrl,
      colEventPaymentUrlExpires: item.eventPaymentUrlExpires.toString(),
      colUnconfirmedBankXferCount: item.unconfirmedBankXferCount,
      colEventPriceForExtras: item.eventPriceForExtras,
      colExtrasDescription: item.extrasDescription,
      colDoTrackHashCash: item.doTrackHashCash,
      colTags1: item.tags1,
      colTags2: item.tags2,
      colTags3: item.tags3,
      colUpdatedAt: item.updatedAt.toString(),
      colUpdatedAtValue: item.updatedAt.millisecondsSinceEpoch,
      colRemoved: item.removed
    };

    return map;
  }

  @override
  Map<String, dynamic> normalizeMap(Map<String, dynamic> inputMap) {
    final Map<String, dynamic> outputMap = <String, dynamic>{
      colEventId: inputMap[colEventId],
      colEventStartDatetime: inputMap[colEventStartDatetime],
      colKennelId: inputMap[colKennelId],
      colIsVisible: inputMap[colIsVisible],
      colIsCountedRun: inputMap[colIsCountedRun],
      colEventNumber: inputMap[colEventNumber],
      colEventName: inputMap[colEventName],
      colNarrowEventLatitude: inputMap[colNarrowEventLatitude],
      colNarrowEventLongitude: inputMap[colNarrowEventLongitude],
      colEventPriceForMembers: inputMap[colEventPriceForMembers],
      colEventPriceForNonMembers: inputMap[colEventPriceForNonMembers],
      colEventFacebookId: inputMap[colEventFacebookId],
      colAbsoluteEventNumber: inputMap[colAbsoluteEventNumber],
      colCanEditRunAttendence: inputMap[colCanEditRunAttendence],
      colEventImage: inputMap[colEventImage],
      colEventDescription: inputMap[colEventDescription],
      colLocationOneLineDesc: inputMap[colLocationOneLineDesc],
      colLocationPostCode: inputMap[colLocationPostCode],
      colLocationCity: inputMap[colLocationCity],
      colLocationStreet: inputMap[colLocationStreet],
      colLocationCountry: inputMap[colLocationCountry],
      colLocationRegion: inputMap[colLocationRegion],
      colLocationSubRegion: inputMap[colLocationSubRegion],
      colHares: inputMap[colHares],
      colEventPaymentScheme: inputMap[colEventPaymentScheme],
      colEventPaymentUrl: inputMap[colEventPaymentUrl],
      colEventPaymentUrlExpires: inputMap[colEventPaymentUrlExpires],
      colUnconfirmedBankXferCount: inputMap[colUnconfirmedBankXferCount],
      colEventPriceForExtras: inputMap[colEventPriceForExtras],
      colExtrasDescription: inputMap[colExtrasDescription],
      colDoTrackHashCash: inputMap[colDoTrackHashCash],
      colTags1: inputMap[colTags1],
      colTags2: inputMap[colTags2],
      colTags3: inputMap[colTags3],
      colUpdatedAt: inputMap[colUpdatedAt],
      colUpdatedAtValue: DateTime.parse(inputMap[colUpdatedAt].toString().substring(0, 19)).millisecondsSinceEpoch,
      colRemoved: inputMap[colRemoved],
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

  @override
  EventModel fromMap(Map<String, dynamic> map) {
    final EventModel item = EventModel(
      eventId: map[colEventId],
      eventStartDatetime: DateTime.parse(map[colEventStartDatetime].toString().substring(0, 19)),
      kennelId: map[colKennelId],
      isVisible: map[colIsVisible],
      isCountedRun: map[colIsCountedRun],
      eventNumber: map[colEventNumber],
      eventName: map[colEventName],
      narrowEventLatitude: map[colNarrowEventLatitude],
      narrowEventLongitude: map[colNarrowEventLongitude],
      eventPriceForMembers: map[colEventPriceForMembers],
      eventPriceForNonMembers: map[colEventPriceForNonMembers],
      eventFacebookId: map[colEventFacebookId],
      absoluteEventNumber: map[colAbsoluteEventNumber],
      canEditRunAttendence: map[colCanEditRunAttendence],
      eventImage: map[colEventImage],
      eventDescription: map[colEventDescription],
      locationOneLineDesc: map[colLocationOneLineDesc],
      locationPostCode: map[colLocationPostCode],
      locationCity: map[colLocationCity],
      locationStreet: map[colLocationStreet],
      locationCountry: map[colLocationCountry],
      locationRegion: map[colLocationRegion],
      locationSubRegion: map[colLocationSubRegion],
      hares: map[colHares],
      eventPaymentScheme: map[colEventPaymentScheme],
      eventPaymentUrl: map[colEventPaymentUrl],
      eventPaymentUrlExpires: DateTime.parse((map[colEventPaymentUrlExpires] ?? '2000-01-01 01:00:00').toString().substring(0, 19)),
      unconfirmedBankXferCount: map[colUnconfirmedBankXferCount],
      eventPriceForExtras: map[colEventPriceForExtras],
      extrasDescription: map[colExtrasDescription],
      doTrackHashCash: map[colDoTrackHashCash],
      tags1: map[colTags1],
      tags2: map[colTags2],
      tags3: map[colTags3],
      updatedAt: DateTime.parse(map[colUpdatedAt].toString().substring(0, 19)),
      removed: map[colRemoved],
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

class EventsService extends BaseService {
  Future<void> updateEventDetails(String eventId, {bool isVisible, bool isCountedRun, int absoluteEventNumber}) async {
    if (globalConnectionStatus == connectionStatus_notConnected) {
      return;
      // TODO(James): fix this so we can return a bool
      //return false;
    }

    final String userId = getStringPref(StringPrefsEnum.userId);

    final String accessToken = Utilities.generateToken(userId, 'addEditEvent');

    final num _eventsLastUpdated = await getLastUpdatedTime(eventsTableHelper, eventsTableHelper.colUpdatedAtValue);
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

  Future<Map<String, String>> sendRunDetailsByEmail({String eventId, String emailBody = ''}) async {
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
