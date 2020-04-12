
import 'package:geolocator/geolocator.dart';

import 'package:harrier_central/util/globals.dart';
import 'package:harrier_central/util/enums.dart';
import 'package:harrier_central/util/constants.dart';

import 'package:ive_flutter_core/util/core_utilities.dart';
import 'package:harrier_central/database/tables.dart';

class AreWeAtRunResult {
  String eventId;
  String eventName;
  String eventImage;
  String kennelLogo;
  String kennelShortName;
  num eventNumber;
  num distanceInMeters;
}

class CommonQueries {
  static Future<String> getClosestEventInTime(String kennelId) async {
    String result = EMPTY_RESULT;
    try {

      final String sql = ''' 

          SELECT e.eventId,
          e.eventName,
          (julianday(eventStartDatetime) - julianday('now','localtime')) * 24 as deltaHours
          FROM ${eventsTableHelper.getTableName(AppDomainType.user)} e
          WHERE e.kennelId = "$kennelId"
          ORDER BY abs(julianday('now') - julianday(eventStartDatetime)) ASC
          
          ''';

      final List<Map<String, dynamic>> results = await internalSqlDb.rawQuery(sql);

      if (results.isNotEmpty) {
        for (int i = 0; i < results.length; i++) {
          if ((results[i]['deltaHours'] <= ALLOW_CHECKIN_SCAN_HOURS_BEFORE_EVENT) && (results[i]['deltaHours'] >= -ALLOW_CHECKIN_SCAN_HOURS_AFTER_EVENT)) {
            result = results[i]['eventId'];
            break;
          } else if (results[i]['deltaHours'] > ALLOW_CHECKIN_SCAN_HOURS_BEFORE_EVENT) {
            result = (results[i]['deltaHours'] - ALLOW_CHECKIN_SCAN_HOURS_BEFORE_EVENT).toString();
            break;
          }
        }
      }
    } catch (e) {
      print(e);
    }
    return result;
  }

  static Future<AreWeAtRunResult> areWeAtRunStart() async {
    final AreWeAtRunResult result = AreWeAtRunResult();
    result.eventId = EMPTY_RESULT;

    try {

      final String userId = getStringPref(StringPrefsEnum.userId);

      final String sql = ''' 

          SELECT e.${eventsTableHelper.colEventId},
          e.${eventsTableHelper.colEventName},
          e.${eventsTableHelper.colNarrowEventLatitude} as lat,
          e.${eventsTableHelper.colNarrowEventLongitude} as lon,
          e.${eventsTableHelper.colEventImage} as eventImage,
          e.${eventsTableHelper.colEventNumber} as eventNumber,
          k.${kennelsTableHelper.colKennelLogo} as kennelLogo,
          k.${kennelsTableHelper.colKennelShortName} as kennelShortName,
          (julianday(${eventsTableHelper.colEventStartDatetime}) - julianday('now','localtime')) * 24 as deltaHours
          FROM ${eventsTableHelper.getTableName(AppDomainType.user)} e
          INNER JOIN ${kennelsTableHelper.getTableName(AppDomainType.user)} k on e.${eventsTableHelper.colKennelId} = k.${kennelsTableHelper.colKennelId}
          LEFT OUTER JOIN ${hasherEventMapTableHelper.getTableName(AppDomainType.user)} hem on hem.${hasherEventMapTableHelper.colUserId} = "$userId" AND hem.${hasherEventMapTableHelper.colEventId} = e.${eventsTableHelper.colEventId}
          WHERE ABS((julianday(${eventsTableHelper.colEventStartDatetime}) - julianday('now','localtime')) * 24) <= $ALLOW_AUTO_CHECKIN_HOURS_BEFORE_EVENT
          AND COALESCE(hem.${hasherEventMapTableHelper.colAttendenceState},0) < ${attendenceAtHash.value}
          ORDER BY abs(julianday('now') - julianday(${eventsTableHelper.colEventStartDatetime})) ASC
          
          ''';

      final List<Map<String, dynamic>> queryResults = await internalSqlDb.rawQuery(sql);

      final Geolocator locator = Geolocator();

      num closestRun = 99999999.0;

      if (queryResults.isNotEmpty) {
        for (int i = 0; i < queryResults.length; i++) {
          final num dist = await locator.distanceBetween(CoreUtilities.unInt(deviceLat), CoreUtilities.unInt(deviceLon), CoreUtilities.unInt(queryResults[i]['lat']), CoreUtilities.unInt(queryResults[i]['lon']));
          if (closestRun < dist) {
            continue;
          }

          closestRun = dist;

          result.eventId = queryResults[i]['eventId'];
          result.eventName = queryResults[i]['eventName'];
          result.eventImage = queryResults[i]['eventImage'];
          result.kennelLogo = queryResults[i]['kennelLogo'];
          result.eventNumber = queryResults[i]['eventNumber'];
          result.kennelShortName = queryResults[i]['kennelShortName'];
          result.distanceInMeters = dist;

          // NOTE: Event images can either be full URLs or they can be partial URLs in the case
          // when events have been uploaded directly to the DB using the HcWeb application.
          // For partial URLs we need to append the root URL. The Root URL is stored in the
          // Server settings table and copied into the string prefs on app startup.
          if ((result.eventImage != null) && (result.eventImage.isNotEmpty) && (!result.eventImage.startsWith('http'))) {
            final String s = getStringPref(StringPrefsEnum.imageRootUrl) ?? BASE_HCWEB_UPLOAD_URL;
            if ((s != null) && (s.isNotEmpty)) {
              result.eventImage = s + result.eventImage;
            }
          }
        }
      }
    } catch (e) {
      print(e);
    }
    return result;
  }

  static Future<String> getUserIdFromUqr(String uqr) async {
    uqr = uqr.toUpperCase();
    String result = 'none';
    try {

      final String sql = ''' 

          SELECT h.hasherId
          FROM ${hashersTableHelper.getTableName(AppDomainType.user)} h
          WHERE upper(h.qrCode) = "$uqr"
          
          ''';

      final List<Map<String, dynamic>> results = await internalSqlDb.rawQuery(sql);

      if (results.isNotEmpty) {
        result = results[0]['hasherId'];
      }
    } catch (e) {
      print(e);
    }
    return result;
  }
}
