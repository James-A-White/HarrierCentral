import 'package:harrier_central/imports.dart';

import 'package:geolocator/geolocator.dart';

class AreWeAtRunResult {
  String eventId;
  String eventName;
  String eventImage;
  String kennelLogo;
  String kennelShortName;
  num eventNumber;
  num distanceInMeters;
  int attendenceState;
  bool selected;
}

class CommonQueries {
  static Future<String> getClosestEventInTime(String kennelId) async {
    String result = EMPTY_RESULT;
    try {
      final String sql = ''' 

          SELECT e.eventId,
          e.eventName,
          (julianday(eventStartDatetime) - julianday('now','localtime')) * 24 as deltaHours
          FROM ${G0<TableModel>().eventsTableHelper.getTableName(AppDomainType.user)} e
          WHERE e.kennelId = "$kennelId"
          ORDER BY abs(julianday('now') - julianday(eventStartDatetime)) ASC
          
          ''';

      final List<Map<String, dynamic>> results = await G0<Database>().rawQuery(sql);

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

  static Future<List<AreWeAtRunResult>> areWeAtRunStart() async {
    final List<AreWeAtRunResult> resultList = <AreWeAtRunResult>[];

    try {
      final String userId = getStringPref(StringPrefsEnum.userId);

      final String sql = ''' 

          SELECT e.${G0<TableModel>().eventsTableHelper.colEventId},
          e.${G0<TableModel>().eventsTableHelper.colEventName},
          case when e.${G0<TableModel>().eventsTableHelper.colUseFbLatLon} = 0 then e.${G0<TableModel>().eventsTableHelper.colHcLatitude} else e.${G0<TableModel>().eventsTableHelper.colFbLatitude} end as lat,
          case when e.${G0<TableModel>().eventsTableHelper.colUseFbLatLon} = 0 then e.${G0<TableModel>().eventsTableHelper.colHcLongitude} else e.${G0<TableModel>().eventsTableHelper.colFbLongitude} end as lon,
          e.${G0<TableModel>().eventsTableHelper.colEventImage} as eventImage,
          e.${G0<TableModel>().eventsTableHelper.colEventNumber} as eventNumber,
          k.${G0<TableModel>().kennelsTableHelper.colKennelLogo} as kennelLogo,
          k.${G0<TableModel>().kennelsTableHelper.colKennelShortName} as kennelShortName,
          (julianday(${G0<TableModel>().eventsTableHelper.colEventStartDatetime}) - julianday('now','localtime')) * 24 as deltaHours,
          coalesce(hem.${G0<TableModel>().hasherEventMapTableHelper.colAttendenceState},0) as attendenceState
          FROM ${G0<TableModel>().eventsTableHelper.getTableName(AppDomainType.user)} e
          INNER JOIN ${G0<TableModel>().kennelsTableHelper.getTableName(AppDomainType.user)} k on e.${G0<TableModel>().eventsTableHelper.colKennelId} = k.${G0<TableModel>().kennelsTableHelper.colKennelId}
          LEFT OUTER JOIN ${G0<TableModel>().hasherEventMapTableHelper.getTableName(AppDomainType.user)} hem on hem.${G0<TableModel>().hasherEventMapTableHelper.colUserId} = "$userId" AND hem.${G0<TableModel>().hasherEventMapTableHelper.colEventId} = e.${G0<TableModel>().eventsTableHelper.colEventId}
          WHERE ABS((julianday(${G0<TableModel>().eventsTableHelper.colEventStartDatetime}) - julianday('now','localtime')) * 24) <= $ALLOW_AUTO_CHECKIN_HOURS_BEFORE_EVENT
          ORDER BY abs(julianday('now') - julianday(${G0<TableModel>().eventsTableHelper.colEventStartDatetime})) ASC
          
          ''';

      final List<Map<String, dynamic>> queryResults = await G0<Database>().rawQuery(sql);

      final Geolocator locator = Geolocator();

      if (queryResults.isNotEmpty) {
        for (int i = 0; i < queryResults.length; i++) {
          if (queryResults[i]['lat'] != null) {
            final num dist = await locator.distanceBetween(G0<DeviceInfo>().deviceLat, G0<DeviceInfo>().deviceLon, queryResults[i]['lat'] + 0.0, queryResults[i]['lon'] + 0.0);

            if (dist.abs() > GEOFENCE_IN_METERS_AROUND_RUN_START_FOR_AUTO_CHECKIN) {
              continue;
            }

            final AreWeAtRunResult result = AreWeAtRunResult();

            result.eventId = queryResults[i]['eventId'];
            result.eventName = queryResults[i]['eventName'];
            result.eventImage = queryResults[i]['eventImage'];
            result.kennelLogo = queryResults[i]['kennelLogo'];
            result.eventNumber = queryResults[i]['eventNumber'];
            result.kennelShortName = queryResults[i]['kennelShortName'];
            result.distanceInMeters = dist;
            result.attendenceState = queryResults[i]['attendenceState'];
            result.selected = false;

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

            resultList.add(result);
          }
        }
      }
    } catch (e) {
      print(e);
    }
    return resultList;
  }

  static Future<String> getUserIdFromUqr(String uqr) async {
    uqr = uqr.toUpperCase();
    String result = 'none';
    try {
      final String sql = ''' 

          SELECT h.hasherId
          FROM ${G0<TableModel>().hashersTableHelper.getTableName(AppDomainType.user)} h
          WHERE upper(h.qrCode) = "$uqr"
          
          ''';

      final List<Map<String, dynamic>> results = await G0<Database>().rawQuery(sql);

      if (results.isNotEmpty) {
        result = results[0]['hasherId'];
      }
    } catch (e) {
      print(e);
    }
    return result;
  }

  static Future<RunAdminAggregate> getNewEvent(String kennelId, String userId, DateTime eventStart) async {
    RunAdminAggregate runDetailAggregate;
    try {
      const String dollarSign = r'$^';
      final String sql = '''

          SELECT 
          k.*,
          hkm.${G0<TableModel>().hasherKennelMapTableHelper.colAppAccessFlags},
          hkm.${G0<TableModel>().hasherKennelMapTableHelper.colMismanagementRoles},
          coalesce(k.${G0<TableModel>().kennelsTableHelper.colCurrencyCode},c.${G0<TableModel>().countriesTableHelper.colCurrencyCode},"USD") as curCode,
          coalesce(k.${G0<TableModel>().kennelsTableHelper.colDigitsAfterDecimal},c.${G0<TableModel>().countriesTableHelper.colDigitsAfterDecimal},2) as digAfterDec, 
          coalesce(k.${G0<TableModel>().kennelsTableHelper.colCurrencySymbol},c.${G0<TableModel>().countriesTableHelper.colCurrencySymbol},"$dollarSign") as curSym,
          coalesce(k.${G0<TableModel>().kennelsTableHelper.colDefaultPriceForMembers},0) as memberPrice,
          coalesce(k.${G0<TableModel>().kennelsTableHelper.colDefaultPriceForNonMembers},0) as nonMemberPrice
          FROM ${G0<TableModel>().kennelsTableHelper.getTableName(AppDomainType.user)} k
          LEFT OUTER JOIN ${G0<TableModel>().countriesTableHelper.getTableName(AppDomainType.user)} c on c.countryId = k.countryId
          LEFT OUTER JOIN ${G0<TableModel>().hasherKennelMapTableHelper.getTableName(AppDomainType.user)} hkm on "$kennelId" = hkm.kennelId,
          hashers h  
          WHERE k.${G0<TableModel>().kennelsTableHelper.colKennelId} = "$kennelId"
          AND hkm.userId = "$userId"
          AND h.hasherId = "$userId"
          
          ''';

      final List<Map<String, dynamic>> results = await G0<Database>().rawQuery(sql);

      if (results.isNotEmpty) {
        final KennelsModel kennel = G0<TableModel>().kennelsTableHelper.fromMap(results[0]);

        eventStart = eventStart.add(Duration(hours: kennel.defaultRunStartTime.hour - 12));
        eventStart = eventStart.add(Duration(minutes: kennel.defaultRunStartTime.minute));

        final EventModel eventItem = EventModel(
          eventStartDatetime: eventStart,
          kennelId: kennel.kennelId,
          hcLatitude: G0<DeviceInfo>().deviceLat,
          hcLongitude: G0<DeviceInfo>().deviceLon,
          isVisible: 1,
          isCountedRun: 1,
          isPromotedEvent: 0,
          eventGeographicScope: 1,
          useFbLatLon: 0,
          useFbRunDetails: 0,
          useFbLocation: 0,
          removed: 0,
        );

        final RunDetailQueryExtensions extensions = RunDetailQueryExtensions.fromMap(results[0]);

        String paymentLinkUrl = '';

        if (((kennel.kennelPaymentUrl ?? '') != '') && ((kennel.kennelPaymentUrlExpires == null) || (kennel.kennelPaymentUrlExpires.isAfter(DateTime.now())))) {
          paymentLinkUrl = kennel.kennelPaymentUrl;
        }

        extensions.paymentUrl = paymentLinkUrl;
        extensions.distToEvent = 0;

        runDetailAggregate = RunAdminAggregate(event: eventItem, extensions: extensions, kennel: kennel);
      }
    } catch (e) {
      print(e);
    }

    return runDetailAggregate;
  }

  static Future<RunAdminAggregate> getEventAdminInfoFromLocalCache(String eventId, String userId) async {
    RunAdminAggregate runAdminAggregate;
    try {
      const String dollarSign = r'$^';
      final String sql = '''
          SELECT e.*,
          k.*,
          case when e.${G0<TableModel>().eventsTableHelper.colUseFbLatLon} = 0 then e.${G0<TableModel>().eventsTableHelper.colHcLatitude} else e.${G0<TableModel>().eventsTableHelper.colFbLatitude} end as latitude,
          case when e.${G0<TableModel>().eventsTableHelper.colUseFbLatLon} = 0 then e.${G0<TableModel>().eventsTableHelper.colHcLongitude} else e.${G0<TableModel>().eventsTableHelper.colFbLongitude} end as longitude,
          case when ((e.${G0<TableModel>().eventsTableHelper.colUseFbLatLon} = 0 AND e.${G0<TableModel>().eventsTableHelper.colHcLongitude} IS NOT NULL) OR ((e.${G0<TableModel>().eventsTableHelper.colUseFbLatLon} = 1 AND e.${G0<TableModel>().eventsTableHelper.colFbLatitude} IS NOT NULL))) THEN 1 ELSE 0 END as isMapAndDistanceValid,
          hkm.${G0<TableModel>().hasherKennelMapTableHelper.colAppAccessFlags},
          hkm.${G0<TableModel>().hasherKennelMapTableHelper.colMismanagementRoles},
          coalesce(k.${G0<TableModel>().kennelsTableHelper.colCurrencyCode},c.${G0<TableModel>().countriesTableHelper.colCurrencyCode},"USD") as curCode,
          coalesce(k.${G0<TableModel>().kennelsTableHelper.colDigitsAfterDecimal},c.${G0<TableModel>().countriesTableHelper.colDigitsAfterDecimal},2) as digAfterDec, 
          coalesce(k.${G0<TableModel>().kennelsTableHelper.colCurrencySymbol},c.${G0<TableModel>().countriesTableHelper.colCurrencySymbol},"$dollarSign") as curSym,
          coalesce(e.${G0<TableModel>().eventsTableHelper.colEventPriceForMembers},k.${G0<TableModel>().kennelsTableHelper.colDefaultPriceForMembers},0) as memberPrice,
          coalesce(e.${G0<TableModel>().eventsTableHelper.colEventPriceForNonMembers},k.${G0<TableModel>().kennelsTableHelper.colDefaultPriceForNonMembers},0) as nonMemberPrice
          FROM ${G0<TableModel>().eventsTableHelper.getTableName(AppDomainType.user)} e
          INNER JOIN ${G0<TableModel>().kennelsTableHelper.getTableName(AppDomainType.user)} k on k.kennelId = e.kennelId
          LEFT OUTER JOIN ${G0<TableModel>().countriesTableHelper.getTableName(AppDomainType.user)} c on c.countryId = k.countryId
          LEFT OUTER JOIN ${G0<TableModel>().hasherKennelMapTableHelper.getTableName(AppDomainType.user)} hkm on e.kennelId = hkm.kennelId,
          hashers h  
          WHERE e.eventId = "$eventId"
          AND hkm.userId = "$userId"
          AND h.hasherId = "$userId" 
          ''';

      final List<Map<String, dynamic>> results = await G0<Database>().rawQuery(sql);

      final Geolocator locator = Geolocator();

      if (results.isNotEmpty) {
        final EventModel eventItem = G0<TableModel>().eventsTableHelper.fromMap(results[0]);
        final RunDetailQueryExtensions extensions = RunDetailQueryExtensions.fromMap(results[0]);
        final KennelsModel kennel = G0<TableModel>().kennelsTableHelper.fromMap(results[0]);
        String paymentLinkUrl = '';

        num dist;

        if (extensions.latitude != null) {
          dist = await locator.distanceBetween(
            G0<DeviceInfo>().deviceLat,
            G0<DeviceInfo>().deviceLon,
            extensions.latitude,
            extensions.longitude,
          );
        } else {
          dist = await locator.distanceBetween(
            G0<DeviceInfo>().deviceLat,
            G0<DeviceInfo>().deviceLon,
            kennel.kennelLatitude,
            kennel.kennelLongitude,
          );
        }
        extensions.distToEvent = dist;

        if (((eventItem.eventPaymentUrl ?? '') != '') && ((eventItem.eventPaymentUrlExpires == null) || (eventItem.eventPaymentUrlExpires.isAfter(DateTime.now())))) {
          paymentLinkUrl = eventItem.eventPaymentUrl;
        } else if (((kennel.kennelPaymentUrl ?? '') != '') && ((kennel.kennelPaymentUrlExpires == null) || (kennel.kennelPaymentUrlExpires.isAfter(DateTime.now())))) {
          paymentLinkUrl = kennel.kennelPaymentUrl;
        }

        extensions.paymentUrl = paymentLinkUrl;

        runAdminAggregate = RunAdminAggregate(event: eventItem, extensions: extensions, kennel: kennel);
      }
    } catch (e) {
      print(e);
    }

    return runAdminAggregate;
  }
}
