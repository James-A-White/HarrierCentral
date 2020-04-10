import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';

import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:ive_flutter_core/util/core_utilities.dart';
import 'package:harrier_central/util/globals.dart';
import 'package:harrier_central/data/hc3_services/sync_user_data_service.dart';
import 'package:harrier_central/database/tables.dart';
import 'package:ive_flutter_core/util/connection.dart';
import 'package:ive_flutter_core/database/base_service.dart';

import 'package:json_annotation/json_annotation.dart';

part 'events_service.g.dart';

@JsonSerializable(fieldRename: FieldRename.none)
class EventModel implements BaseModel {
  EventModel(
      {this.eventId,
      this.eventStartDatetime,
      this.kennelId,
      this.isVisible,
      this.isCountedRun,
      this.eventGeographicScope,
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

  factory EventModel.fromJson(Map<String, dynamic> json) => _$EventModelFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$EventModelToJson(this);

  final String eventId;
  final DateTime eventStartDatetime;
  final String kennelId;
  final int isVisible;
  final int isCountedRun;
  final int eventGeographicScope;
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
  final String colEventGeographicScope = 'eventGeographicScope';
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
  final String colLocationRegion = 'locationRegion';
  final String colLocationSubRegion = 'locationSubRegion';
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
  Future<dynamic> createTable(Database db, int version, TableType tableType) async {
    await db.execute('''
          CREATE TABLE $tableName (
            $colId INTEGER PRIMARY KEY,

            $colEventId TEXT NOT NULL,
            $colEventStartDatetime TEXT,
            $colKennelId TEXT NOT NULL,
            $colIsVisible INT,
            $colIsCountedRun INT,
            $colEventGeographicScope INT,
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

  // @override
  // Map<String, dynamic> toMap(dynamic item) {
  //   final Map<String, dynamic> map = _$EventModelToJson(item);
  //   return map;
  // }

  @override
  Map<String, dynamic> normalizeMap(Map<String, dynamic> map) {
    final Map<String, dynamic> outputMap = _$EventModelToJson(EventModel.fromJson(map));

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
    final EventModel item = EventModel.fromJson(map);

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

    final String accessToken = CoreUtilities.generateToken(userId, 'addEditEvent');

    final num _eventsLastUpdated = await getLastUpdatedTime(
      internalSqlDb,
      eventsTableHelper,
      Tables.getTableName(eventsTableHelper),
      eventsTableHelper.colUpdatedAtValue,
    );
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
    final String accessToken = CoreUtilities.generateToken(userId, 'rptApi_emailRunDetails', paramString: eventId);

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
