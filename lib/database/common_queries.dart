import 'package:geolocator/geolocator.dart';
import 'package:harrier_central/imports.dart';

class CommonQueries {
  // the variable below is there to suppress a warning about defining classes with only static members
  int? unusedVariableToSuppressWarning;

  static Future<int> countRecords(String tableName) async {
    final String query = '''
          SELECT COUNT(*) as Total
          FROM $tableName
          ''';

    final List<Map<String, dynamic>> results = await G0<Database>().rawQuery(
      query,
    );
    return results[0]['Total'];
  }

  static Future<int> countRemovedRecords(String tableName) async {
    final String query = '''
          SELECT COUNT(*) as Total
          FROM $tableName
          WHERE removed != 0
          ''';

    final List<Map<String, dynamic>> results = await G0<Database>().rawQuery(
      query,
    );
    return results[0]['Total'];
  }

  static Future<void> deleteRemovedRecords(String tableName) async {
    final String query = '''
          DELETE
          FROM $tableName
          WHERE removed != 0
          ''';

    await G0<Database>().rawQuery(query);
    return;
  }

  static Future<String> getClosestEventInTime(String kennelId) async {
    String result = EMPTY_RESULT;
    try {
      final String sql = '''

          SELECT e.eventId,
          e.eventName,
          (julianday(eventStartDatetime) - julianday('now','localtime')) * 24 as deltaHours
          FROM ${G0<TableModel>().eventsTableHelper.getTableName(AppDomainType.user)} e
          WHERE e.kennelId = "$kennelId"
          ORDER BY abs(julianday('now','localtime') - julianday(eventStartDatetime)) ASC
          
          ''';

      final List<Map<String, dynamic>> results = await G0<Database>().rawQuery(
        sql,
      );

      if (results.isNotEmpty) {
        for (int i = 0; i < results.length; i++) {
          if ((results[i]['deltaHours'] <=
                  ALLOW_CHECKIN_SCAN_HOURS_BEFORE_EVENT) &&
              (results[i]['deltaHours'] >=
                  -ALLOW_CHECKIN_SCAN_HOURS_AFTER_EVENT)) {
            result = results[i]['eventId'];
            break;
          } else if (results[i]['deltaHours'] >
              ALLOW_CHECKIN_SCAN_HOURS_BEFORE_EVENT) {
            result =
                (results[i]['deltaHours'] -
                        ALLOW_CHECKIN_SCAN_HOURS_BEFORE_EVENT)
                    .toString();
            break;
          }
        }
      }
    } catch (e) {
      //print(e);
    }
    return result;
  }

  static Future<List<AreWeAtRunModel>> areWeAtRunStart({
    String? eventId,
  }) async {
    final List<AreWeAtRunModel> resultList = <AreWeAtRunModel>[];

    try {
      final String? userId = getStringPref(StringPrefsEnum.userId);
      const String dollarSign = r'$^';

      String sql = '''
          SELECT e.${G0<TableModel>().eventsTableHelper.colEventId},
          e.${G0<TableModel>().eventsTableHelper.colEventName},
          case when e.${G0<TableModel>().eventsTableHelper.colUseFbLatLon} = 0 then e.${G0<TableModel>().eventsTableHelper.colHcLatitude} else coalesce(e.${G0<TableModel>().eventsTableHelper.colFbLatitude},e.${G0<TableModel>().eventsTableHelper.colHcLatitude}) end as lat,
          case when e.${G0<TableModel>().eventsTableHelper.colUseFbLatLon} = 0 then e.${G0<TableModel>().eventsTableHelper.colHcLongitude} else coalesce(e.${G0<TableModel>().eventsTableHelper.colFbLongitude},e.${G0<TableModel>().eventsTableHelper.colHcLongitude}) end as lon,
          e.${G0<TableModel>().eventsTableHelper.colEventImage} as eventImage,
          e.${G0<TableModel>().eventsTableHelper.colEventNumber} as eventNumber,
          k.${G0<TableModel>().kennelsTableHelper.colKennelId} as kennelId,
          k.${G0<TableModel>().kennelsTableHelper.colKennelLogo} as kennelLogo,
          k.${G0<TableModel>().kennelsTableHelper.colKennelShortName} as kennelShortName,
          k.${G0<TableModel>().kennelsTableHelper.colAllowSelfPayment} as allowSelfPayment,
          coalesce(k.${G0<TableModel>().kennelsTableHelper.colDigitsAfterDecimal},c.${G0<TableModel>().countriesTableHelper.colDigitsAfterDecimal},2) as digAfterDec, 
          coalesce(k.${G0<TableModel>().kennelsTableHelper.colCurrencySymbol},c.${G0<TableModel>().countriesTableHelper.colCurrencySymbol},"$dollarSign") as curSym,
          case when k.${G0<TableModel>().kennelsTableHelper.colAllowSelfPayment} != 0 then coalesce(hkm.${G0<TableModel>().hasherKennelMapTableHelper.colKennelCredit},0) else 0 end as kennelCredit,
          coalesce(hkm.${G0<TableModel>().hasherKennelMapTableHelper.colMembershipExpirationDate},'2000-01-01') as membershipExpirationDate,
          coalesce(hkm.${G0<TableModel>().hasherKennelMapTableHelper.colDiscountAmount},0) as discountAmount,
          coalesce(hkm.${G0<TableModel>().hasherKennelMapTableHelper.colDiscountPercent},0) as discountPercent,
          coalesce(e.${G0<TableModel>().eventsTableHelper.colEventPriceForExtras},0) as extrasCost,
          coalesce(e.${G0<TableModel>().eventsTableHelper.colExtrasDescription},'') as extrasDescription,
          coalesce(e.${G0<TableModel>().eventsTableHelper.colEventPriceForMembers},k.${G0<TableModel>().kennelsTableHelper.colDefaultPriceForMembers},0) as memberPrice,
          coalesce(e.${G0<TableModel>().eventsTableHelper.colEventPriceForNonMembers},k.${G0<TableModel>().kennelsTableHelper.colDefaultPriceForNonMembers},0) as nonMemberPrice,
          (julianday(${G0<TableModel>().eventsTableHelper.colEventStartDatetime}) - julianday('now','localtime')) * 24 as deltaHours,
          coalesce(hem.${G0<TableModel>().hasherEventMapTableHelper.colAttendenceState},0) as attendenceState
          FROM ${G0<TableModel>().eventsTableHelper.getTableName(AppDomainType.user)} e
          INNER JOIN ${G0<TableModel>().kennelsTableHelper.getTableName(AppDomainType.user)} k on e.${G0<TableModel>().eventsTableHelper.colKennelId} = k.${G0<TableModel>().kennelsTableHelper.colKennelId}
          LEFT OUTER JOIN ${G0<TableModel>().countriesTableHelper.getTableName(AppDomainType.user)} c on c.${G0<TableModel>().countriesTableHelper.colCountryId} = k.${G0<TableModel>().kennelsTableHelper.colCountryId}
          LEFT OUTER JOIN ${G0<TableModel>().hasherEventMapTableHelper.getTableName(AppDomainType.user)} hem on hem.${G0<TableModel>().hasherEventMapTableHelper.colUserId} = "$userId" AND hem.${G0<TableModel>().hasherEventMapTableHelper.colEventId} = e.${G0<TableModel>().eventsTableHelper.colEventId}
          LEFT OUTER JOIN ${G0<TableModel>().hasherKennelMapTableHelper.getTableName(AppDomainType.user)} hkm on hkm.${G0<TableModel>().hasherKennelMapTableHelper.colUserId} = "$userId" AND hkm.${G0<TableModel>().hasherKennelMapTableHelper.colKennelId} = e.${G0<TableModel>().eventsTableHelper.colKennelId}
          WHERE 
          ((julianday(${G0<TableModel>().eventsTableHelper.colEventStartDatetime}) - julianday('now','localtime')) * 24) <= $ALLOW_AUTO_CHECKIN_HOURS_BEFORE_EVENT
          AND ((julianday(${G0<TableModel>().eventsTableHelper.colEventStartDatetime}) - julianday('now','localtime')) * 24) >= ${-ALLOW_AUTO_CHECKIN_HOURS_AFTER_EVENT}
          AND e.${G0<TableModel>().eventsTableHelper.colIsVisible} = 1
          AND e.${G0<TableModel>().eventsTableHelper.colRemoved} = 0
          ''';

      if (eventId != null) {
        sql += '''
          AND e.${G0<TableModel>().eventsTableHelper.colEventId} = '${eventId.toLowerCase()}'
        ''';
      }

      sql += '''
          ORDER BY abs(julianday('now','localtime') - julianday(${G0<TableModel>().eventsTableHelper.colEventStartDatetime})) ASC
        ''';

      final List<Map<String, dynamic>> queryResults = await G0<Database>()
          .rawQuery(sql);

      if (queryResults.isNotEmpty) {
        int escape = 0;

        bool hasValidPosition = false;

        // start a 6-minute loop where we look for an updated position,
        // but only if we don't have an eventId. EventId will
        // be populated when the user clicks on a notification.
        // In this case, we want to always allow checkin regardless
        // of where they are located.
        while ((escape < 120) && !hasValidPosition && (eventId == null)) {
          final DateTime? lastLocationUpdate = getDatePref(
            DatePrefsEnum.lastLocationUpdate,
          );
          if ((lastLocationUpdate != null) &&
              (DateTime.now().difference(lastLocationUpdate).inMinutes.abs() <
                  15)) {
            hasValidPosition = true;
            continue;
          }
          escape++;
          await Future<dynamic>.delayed(const Duration(seconds: 3));
        }

        for (int i = 0; i < queryResults.length; i++) {
          double? dist;

          // if an eventId has not been provided,
          // check the distance and see if the user
          // is close to the run. If an eventId has
          // been provided because the user clicked
          // on a notification, ignore the distance
          if (hasValidPosition &&
              (eventId == null) &&
              (queryResults[i]['lat'] != null) &&
              (G0<DeviceInfo>().deviceLon != null) &&
              (G0<DeviceInfo>().deviceLon != null)) {
            dist = Geolocator.distanceBetween(
              G0<DeviceInfo>().deviceLat!.toDouble(),
              G0<DeviceInfo>().deviceLon!.toDouble(),
              queryResults[i]['lat'] + 0.0,
              queryResults[i]['lon'] + 0.0,
            );

            if (dist.abs() >
                GEOFENCE_IN_METERS_AROUND_RUN_START_FOR_AUTO_CHECKIN) {
              continue;
            }
          }

          if (queryResults[i]['attendenceState'] >= attendenceAtHash.value) {
            continue;
          }

          String? eventImage = queryResults[i]['eventImage'];

          if ((eventImage != null) &&
              (eventImage.isNotEmpty) &&
              (!eventImage.startsWith('http'))) {
            final String s =
                getStringPref(StringPrefsEnum.imageRootUrl) ??
                BASE_HCWEB_UPLOAD_URL;
            if (s.isNotEmpty) {
              eventImage = s + eventImage;
            }
          }

          final AreWeAtRunModel result = AreWeAtRunModel(
            eventId: queryResults[i]['eventId'],
            eventName: queryResults[i]['eventName'],
            eventImage: eventImage,
            kennelId: queryResults[i]['kennelId'],
            kennelLogo: queryResults[i]['kennelLogo'],
            eventNumber: queryResults[i]['eventNumber'],
            deltaHours: queryResults[i]['deltaHours'].toDouble(),
            kennelCredit: queryResults[i]['kennelCredit'].toDouble(),
            memberPrice: queryResults[i]['memberPrice'].toDouble(),
            nonMemberPrice: queryResults[i]['nonMemberPrice'].toDouble(),
            extrasCost: queryResults[i]['extrasCost'].toDouble(),
            extrasDescription: queryResults[i]['extrasDescription'],
            kennelShortName: queryResults[i]['kennelShortName'],
            allowSelfPayment: queryResults[i]['allowSelfPayment'],
            discountAmount: queryResults[i]['discountAmount'].toDouble(),
            discountPercent: queryResults[i]['discountPercent'].toDouble(),
            distanceInMeters: dist?.toDouble() ?? 0.0,
            attendenceState: queryResults[i]['attendenceState'],
            membershipExpirationDate:
                DateTime.tryParse(
                  queryResults[i]['membershipExpirationDate'],
                ) ??
                DateTime(2000, 1, 1),
            currencySymbol: queryResults[i]['curSym'],
            digitsAfterDecimal: queryResults[i]['digAfterDec'],
          );

          // NOTE: Event images can either be full URLs or they can be partial URLs in the case
          // when events have been uploaded directly to the DB using the HcWeb application.
          // For partial URLs we need to append the root URL. The Root URL is stored in the
          // Server settings table and copied into the string prefs on app startup.

          resultList.add(result);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
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

      final List<Map<String, dynamic>> results = await G0<Database>().rawQuery(
        sql,
      );

      if (results.isNotEmpty) {
        result = results[0]['hasherId'];
      }
    } catch (e) {
      //print(e);
    }
    return result;
  }

  static Future<RunAdminAggregate?> getNewEvent(
    String kennelId,
    String userId,
    DateTime eventStart,
  ) async {
    RunAdminAggregate? runDetailAggregate;
    try {
      const String dollarSign = r'$^';
      final String sql = '''

          SELECT 
          k.*,
          coalesce(hkm.${G0<TableModel>().hasherKennelMapTableHelper.colAppAccessFlags},0) as appAccessFlags,
          coalesce(hkm.${G0<TableModel>().hasherKennelMapTableHelper.colMismanagementRoles},0) as mismanagementRoles,
          coalesce(k.${G0<TableModel>().kennelsTableHelper.colCurrencyCode},c.${G0<TableModel>().countriesTableHelper.colCurrencyCode},"USD") as curCode,
          coalesce(k.${G0<TableModel>().kennelsTableHelper.colDigitsAfterDecimal},c.${G0<TableModel>().countriesTableHelper.colDigitsAfterDecimal},2) as digAfterDec, 
          coalesce(k.${G0<TableModel>().kennelsTableHelper.colCurrencySymbol},c.${G0<TableModel>().countriesTableHelper.colCurrencySymbol},"$dollarSign") as curSym,
          coalesce(k.${G0<TableModel>().kennelsTableHelper.colDefaultPriceForMembers},0) as memberPrice,
          coalesce(k.${G0<TableModel>().kennelsTableHelper.colDefaultPriceForNonMembers},0) as nonMemberPrice,
          coalesce(k.${G0<TableModel>().kennelsTableHelper.colKennelLatitude},city.${G0<TableModel>().citiesTableHelper.colLatitude}) as kenlLat,
          coalesce(k.${G0<TableModel>().kennelsTableHelper.colKennelLongitude},city.${G0<TableModel>().citiesTableHelper.colLongitude}) as kenlLon
          FROM ${G0<TableModel>().kennelsTableHelper.getTableName(AppDomainType.user)} k
          INNER JOIN ${G0<TableModel>().citiesTableHelper.getTableName(AppDomainType.user)} city on city.${G0<TableModel>().citiesTableHelper.colCityId} = k.${G0<TableModel>().kennelsTableHelper.colCityId}
          LEFT OUTER JOIN ${G0<TableModel>().countriesTableHelper.getTableName(AppDomainType.user)} c on c.countryId = k.countryId
          LEFT OUTER JOIN ${G0<TableModel>().hasherKennelMapTableHelper.getTableName(AppDomainType.user)} hkm on "$kennelId" = hkm.kennelId,
          hashers h  
          WHERE k.${G0<TableModel>().kennelsTableHelper.colKennelId} = "$kennelId"
          AND hkm.userId = "$userId"
          AND h.hasherId = "$userId"
          
          ''';

      final List<Map<String, dynamic>> results = await G0<Database>().rawQuery(
        sql,
      );

      if (results.isNotEmpty) {
        final KennelsModel kennel = G0<TableModel>().kennelsTableHelper.fromMap(
          results[0],
        );

        eventStart = eventStart.add(
          Duration(hours: kennel.defaultRunStartTime.hour - 12),
        );
        eventStart = eventStart.add(
          Duration(minutes: kennel.defaultRunStartTime.minute),
        );

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
          tags1: 0,
          tags2: 0,
          tags3: 0,
          eventId: GUID_EMPTY,
          doTrackHashCash: 1,
          eventName: '',
          useFbImage: 0,
          publicEventId: GUID_EMPTY,
          countryId: GUID_EMPTY,
          eventNumber: 0,
          eventInboundIntegrationId: 0,
          updatedAt: DateTime.now(),
        );

        final RunDetailQueryExtensions extensions =
            RunDetailQueryExtensions.fromMap(results[0]);

        String paymentLinkUrl = '';

        if (((kennel.kennelPaymentUrl ?? '') != '') &&
            ((kennel.kennelPaymentUrlExpires == null) ||
                (kennel.kennelPaymentUrlExpires!.isAfter(DateTime.now())))) {
          paymentLinkUrl = kennel.kennelPaymentUrl!;
        }

        extensions.paymentUrl = paymentLinkUrl;
        extensions.distToEvent = 0;

        runDetailAggregate = RunAdminAggregate(
          event: eventItem,
          extensions: extensions,
          kennel: kennel,
        );
      }
    } catch (e) {
      //print(e);
    }

    return runDetailAggregate;
  }

  static Future<RunAdminAggregate?> getEventAdminInfoFromLocalCache(
    String eventId,
    String userId,
  ) async {
    RunAdminAggregate? runAdminAggregate;
    try {
      const String dollarSign = r'$^';
      final String sql = '''
          SELECT e.*,
          k.*,
          case when e.${G0<TableModel>().eventsTableHelper.colUseFbLatLon} = 0 then e.${G0<TableModel>().eventsTableHelper.colHcLatitude} else coalesce(e.${G0<TableModel>().eventsTableHelper.colFbLatitude},e.${G0<TableModel>().eventsTableHelper.colHcLatitude}) end as latitude,
          case when e.${G0<TableModel>().eventsTableHelper.colUseFbLatLon} = 0 then e.${G0<TableModel>().eventsTableHelper.colHcLongitude} else coalesce(e.${G0<TableModel>().eventsTableHelper.colFbLongitude},e.${G0<TableModel>().eventsTableHelper.colHcLongitude}) end as longitude,
          case when ((e.${G0<TableModel>().eventsTableHelper.colUseFbLatLon} = 0 AND e.${G0<TableModel>().eventsTableHelper.colHcLongitude} IS NOT NULL) OR ((e.${G0<TableModel>().eventsTableHelper.colUseFbLatLon} = 1 AND coalesce(e.${G0<TableModel>().eventsTableHelper.colFbLatitude},e.${G0<TableModel>().eventsTableHelper.colHcLatitude}) IS NOT NULL))) THEN 1 ELSE 0 END as isMapAndDistanceValid,
          hkm.${G0<TableModel>().hasherKennelMapTableHelper.colAppAccessFlags},
          hkm.${G0<TableModel>().hasherKennelMapTableHelper.colMismanagementRoles},
          coalesce(k.${G0<TableModel>().kennelsTableHelper.colCurrencyCode},c.${G0<TableModel>().countriesTableHelper.colCurrencyCode},"USD") as curCode,
          coalesce(k.${G0<TableModel>().kennelsTableHelper.colDigitsAfterDecimal},c.${G0<TableModel>().countriesTableHelper.colDigitsAfterDecimal},2) as digAfterDec, 
          coalesce(k.${G0<TableModel>().kennelsTableHelper.colCurrencySymbol},c.${G0<TableModel>().countriesTableHelper.colCurrencySymbol},"$dollarSign") as curSym,
          coalesce(e.${G0<TableModel>().eventsTableHelper.colEventPriceForMembers},k.${G0<TableModel>().kennelsTableHelper.colDefaultPriceForMembers},0) as memberPrice,
          coalesce(e.${G0<TableModel>().eventsTableHelper.colEventPriceForNonMembers},k.${G0<TableModel>().kennelsTableHelper.colDefaultPriceForNonMembers},0) as nonMemberPrice,
          coalesce(k.${G0<TableModel>().kennelsTableHelper.colKennelLatitude},city.${G0<TableModel>().citiesTableHelper.colLatitude}) as kenlLat,
          coalesce(k.${G0<TableModel>().kennelsTableHelper.colKennelLongitude},city.${G0<TableModel>().citiesTableHelper.colLongitude}) as kenlLon
          FROM ${G0<TableModel>().eventsTableHelper.getTableName(AppDomainType.user)} e
          INNER JOIN ${G0<TableModel>().kennelsTableHelper.getTableName(AppDomainType.user)} k on k.kennelId = e.kennelId
          INNER JOIN ${G0<TableModel>().citiesTableHelper.getTableName(AppDomainType.user)} city on city.${G0<TableModel>().citiesTableHelper.colCityId} = k.${G0<TableModel>().kennelsTableHelper.colCityId}
          LEFT OUTER JOIN ${G0<TableModel>().countriesTableHelper.getTableName(AppDomainType.user)} c on c.countryId = k.countryId
          LEFT OUTER JOIN ${G0<TableModel>().hasherKennelMapTableHelper.getTableName(AppDomainType.user)} hkm on e.kennelId = hkm.kennelId AND hkm.userId = "$userId",
          hashers h  
          WHERE e.eventId = "$eventId"
          AND h.hasherId = "$userId" 
          ''';

      try {
        final List<Map<String, dynamic>> results = await G0<Database>()
            .rawQuery(sql);

        //final Geolocator locator = Geolocator();

        if (results.isNotEmpty) {
          final EventModel eventItem = G0<TableModel>().eventsTableHelper
              .fromMap(results[0]);
          final RunDetailQueryExtensions extensions =
              RunDetailQueryExtensions.fromMap(results[0]);
          final KennelsModel kennel = G0<TableModel>().kennelsTableHelper
              .fromMap(results[0]);
          String paymentLinkUrl = '';

          double? dist;

          if ((extensions.latitude != null) &&
              (extensions.longitude != null) &&
              (G0<DeviceInfo>().deviceLat != null) &&
              (G0<DeviceInfo>().deviceLon != null)) {
            dist = Geolocator.distanceBetween(
              G0<DeviceInfo>().deviceLat!,
              G0<DeviceInfo>().deviceLon!,
              extensions.latitude!,
              extensions.longitude!,
            );
          } else if ((kennel.kennelLatitude != null) &&
              (kennel.kennelLongitude != null) &&
              (G0<DeviceInfo>().deviceLat != null) &&
              (G0<DeviceInfo>().deviceLon != null)) {
            dist = Geolocator.distanceBetween(
              G0<DeviceInfo>().deviceLat!,
              G0<DeviceInfo>().deviceLon!,
              kennel.kennelLatitude!,
              kennel.kennelLongitude!,
            );
          }
          extensions.distToEvent = dist;

          if (((eventItem.eventPaymentUrl ?? '') != '') &&
              ((eventItem.eventPaymentUrlExpires == null) ||
                  (eventItem.eventPaymentUrlExpires!.isAfter(
                    DateTime.now(),
                  )))) {
            paymentLinkUrl = eventItem.eventPaymentUrl!;
          } else if (((kennel.kennelPaymentUrl ?? '') != '') &&
              ((kennel.kennelPaymentUrlExpires == null) ||
                  (kennel.kennelPaymentUrlExpires!.isAfter(DateTime.now())))) {
            paymentLinkUrl = kennel.kennelPaymentUrl!;
          }

          extensions.paymentUrl = paymentLinkUrl;

          runAdminAggregate = RunAdminAggregate(
            event: eventItem,
            extensions: extensions,
            kennel: kennel,
          );
        }
      } catch (e) {
        if (kDebugMode) {
          print(e);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }

    return runAdminAggregate;
  }
}
