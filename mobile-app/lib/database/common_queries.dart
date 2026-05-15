import 'package:geolocator/geolocator.dart';
import 'package:harrier_central/imports.dart';

class CommonQueries {
  // the variable below is there to suppress a warning about defining classes with only static members
  int? unusedVariableToSuppressWarning;

  static Future<int> countRecords(String tableName) async {
    final String query =
        '''
          SELECT COUNT(*) as Total
          FROM $tableName
          ''';

    final List<Map<String, dynamic>> results = await database.rawQuery(query);
    return results[0]['Total'];
  }

  static Future<int> countRemovedRecords(String tableName) async {
    final String query =
        '''
          SELECT COUNT(*) as Total
          FROM $tableName
          WHERE removed != 0
          ''';

    final List<Map<String, dynamic>> results = await database.rawQuery(query);
    return results[0]['Total'];
  }

  static Future<void> deleteRemovedRecords(String tableName) async {
    final String query =
        '''
          DELETE
          FROM $tableName
          WHERE removed != 0
          ''';

    await database.rawQuery(query);
    return;
  }

  static Future<String> getClosestEventInTime(String kennelId) async {
    String result = EMPTY_RESULT;

    final offsetFromGmtToLocal = Utilities.getSqfliteTimeOffset();

    try {
      final String sql =
          '''

          SELECT e.eventId,
          e.eventName,
          (julianday(eventStartDatetime) - julianday('now','$offsetFromGmtToLocal')) * 24 as deltaHours
          FROM ${EnumDataTables.events.commonTableName} e
          WHERE e.kennelId = "$kennelId"
          ORDER BY abs(julianday('now','$offsetFromGmtToLocal') - julianday(eventStartDatetime)) ASC
          
          ''';

      final List<Map<String, dynamic>> results = await database.rawQuery(sql);

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
      debugPrint('[CommonQueries.isAtRunNow] error: $e');
    }
    return result;
  }

  static Future<List<AreWeAtRunModel>> isAtRunStart({String? eventId}) async {
    final List<AreWeAtRunModel> resultList = <AreWeAtRunModel>[];

    try {
      final String? userId = getStringPref(StringPrefsEnum.userId);
      const String dollarSign = r'$^';

      //final offsetFromGmtToLocal = Utilities.getSqfliteTimeOffset();

      String sql =
          '''
          SELECT e.${tableModel.eventsTableHelper.colEventId},
          e.${tableModel.eventsTableHelper.colEventName},
          case when e.${tableModel.eventsTableHelper.colUseFbLatLon} = 0 then e.${tableModel.eventsTableHelper.colHcLatitude} else coalesce(e.${tableModel.eventsTableHelper.colFbLatitude},e.${tableModel.eventsTableHelper.colHcLatitude}) end as lat,
          case when e.${tableModel.eventsTableHelper.colUseFbLatLon} = 0 then e.${tableModel.eventsTableHelper.colHcLongitude} else coalesce(e.${tableModel.eventsTableHelper.colFbLongitude},e.${tableModel.eventsTableHelper.colHcLongitude}) end as lon,
          e.${tableModel.eventsTableHelper.colEventImage} as eventImage,
          e.${tableModel.eventsTableHelper.colEventNumber} as eventNumber,
          k.${tableModel.kennelsTableHelper.colKennelId} as kennelId,
          k.${tableModel.kennelsTableHelper.colKennelLogo} as kennelLogo,
          k.${tableModel.kennelsTableHelper.colKennelShortName} as kennelShortName,
          k.${tableModel.kennelsTableHelper.colAllowSelfPayment} as allowSelfPayment,
          coalesce(k.${tableModel.kennelsTableHelper.colDigitsAfterDecimal},c.${tableModel.countriesTableHelper.colDigitsAfterDecimal},2) as digAfterDec, 
          coalesce(k.${tableModel.kennelsTableHelper.colCurrencySymbol},c.${tableModel.countriesTableHelper.colCurrencySymbol},"$dollarSign") as curSym,
          case when k.${tableModel.kennelsTableHelper.colAllowSelfPayment} != 0 then coalesce(hkm.${tableModel.hasherKennelMapTableHelper.colKennelCredit},0) else 0 end as kennelCredit,
          coalesce(hkm.${tableModel.hasherKennelMapTableHelper.colMembershipExpirationDate},'2000-01-01') as membershipExpirationDate,
          coalesce(hkm.${tableModel.hasherKennelMapTableHelper.colDiscountAmount},0) as discountAmount,
          coalesce(hkm.${tableModel.hasherKennelMapTableHelper.colDiscountPercent},0) as discountPercent,
          coalesce(e.${tableModel.eventsTableHelper.colEventPriceForExtras},0) as extrasCost,
          coalesce(e.${tableModel.eventsTableHelper.colExtrasDescription},'') as extrasDescription,
          coalesce(e.${tableModel.eventsTableHelper.colEventPriceForMembers},k.${tableModel.kennelsTableHelper.colDefaultPriceForMembers},0) as memberPrice,
          coalesce(e.${tableModel.eventsTableHelper.colEventPriceForNonMembers},k.${tableModel.kennelsTableHelper.colDefaultPriceForNonMembers},0) as nonMemberPrice,
          (julianday(${tableModel.eventsTableHelper.colEventStartDatetimeGmt}) - julianday('now')) * 24 as deltaHours,
          coalesce(hem.${tableModel.hasherEventMapTableHelper.colAttendenceState},0) as attendenceState
          FROM ${EnumDataTables.events.commonTableName} e
          INNER JOIN ${EnumDataTables.kennels.commonTableName} k on e.${tableModel.eventsTableHelper.colKennelId} = k.${tableModel.kennelsTableHelper.colKennelId}
          LEFT OUTER JOIN ${EnumDataTables.countries.commonTableName} c on c.${tableModel.countriesTableHelper.colCountryId} = k.${tableModel.kennelsTableHelper.colCountryId}
          LEFT OUTER JOIN ${EnumDataTables.hasherEventMap.commonTableName} hem on hem.${tableModel.hasherEventMapTableHelper.colUserId} = "$userId" AND hem.${tableModel.hasherEventMapTableHelper.colEventId} = e.${tableModel.eventsTableHelper.colEventId}
          LEFT OUTER JOIN ${EnumDataTables.hasherKennelMap.commonTableName} hkm on hkm.${tableModel.hasherKennelMapTableHelper.colUserId} = "$userId" AND hkm.${tableModel.hasherKennelMapTableHelper.colKennelId} = e.${tableModel.eventsTableHelper.colKennelId}
          WHERE 
          ((julianday(${tableModel.eventsTableHelper.colEventStartDatetimeGmt}) - julianday('now')) * 24) <= $ALLOW_AUTO_CHECKIN_HOURS_BEFORE_EVENT
          AND ((julianday(${tableModel.eventsTableHelper.colEventStartDatetimeGmt}) - julianday('now')) * 24) >= ${-ALLOW_AUTO_CHECKIN_HOURS_AFTER_EVENT}
          AND e.${tableModel.eventsTableHelper.colIsVisible} = 1
          AND e.${tableModel.eventsTableHelper.colRemoved} = 0
          ''';

      if (eventId != null) {
        sql +=
            '''
          AND e.${tableModel.eventsTableHelper.colEventId} = '${eventId.toLowerCase()}'
        ''';
      }

      sql +=
          '''
          ORDER BY abs(julianday('now') - julianday(${tableModel.eventsTableHelper.colEventStartDatetimeGmt})) ASC
        ''';

      final List<Map<String, dynamic>> queryResults = await database.rawQuery(
        sql,
      );

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
              (deviceInfo.deviceLon != null) &&
              (deviceInfo.deviceLon != null)) {
            dist = Geolocator.distanceBetween(
              deviceInfo.deviceLat!.toDouble(),
              deviceInfo.deviceLon!.toDouble(),
              queryResults[i]['lat'] + 0.0,
              queryResults[i]['lon'] + 0.0,
            );

            // print('${queryResults[i]['eventName']} - $dist');

            if (dist.abs() >
                GEOFENCE_IN_METERS_AROUND_RUN_START_FOR_AUTO_CHECKIN) {
              continue;
            }
          }

          // if there is not a specific event identified and there's no distance -
          // meaning that the lat / long of the run is null, ignore the run
          if ((eventId == null) && (dist == null)) {
            continue;
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
        debugPrint('');
      }
    }
    return resultList;
  }

  static Future<String> getUserIdFromUqr(String uqr) async {
    uqr = uqr.toUpperCase();
    String result = 'none';
    try {
      final String sql =
          '''

          SELECT h.hasherId
          FROM ${EnumDataTables.hashers.commonTableName} h
          WHERE upper(h.qrCode) = "$uqr"
          
          ''';

      final List<Map<String, dynamic>> results = await database.rawQuery(sql);

      if (results.isNotEmpty) {
        result = results[0]['hasherId'];
      }
    } catch (e) {
      debugPrint('[CommonQueries.getUserIdFromUqr] error: $e');
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
      final String sql =
          '''

          SELECT 
          k.*,
          coalesce(hkm.${tableModel.hasherKennelMapTableHelper.colAppAccessFlags},0) as appAccessFlags,
          coalesce(hkm.${tableModel.hasherKennelMapTableHelper.colMismanagementRoles},0) as mismanagementRoles,
          coalesce(k.${tableModel.kennelsTableHelper.colCurrencyCode},c.${tableModel.countriesTableHelper.colCurrencyCode},"USD") as curCode,
          coalesce(k.${tableModel.kennelsTableHelper.colDigitsAfterDecimal},c.${tableModel.countriesTableHelper.colDigitsAfterDecimal},2) as digAfterDec, 
          coalesce(k.${tableModel.kennelsTableHelper.colCurrencySymbol},c.${tableModel.countriesTableHelper.colCurrencySymbol},"$dollarSign") as curSym,
          coalesce(k.${tableModel.kennelsTableHelper.colDefaultPriceForMembers},0) as memberPrice,
          coalesce(k.${tableModel.kennelsTableHelper.colDefaultPriceForNonMembers},0) as nonMemberPrice,
          coalesce(k.${tableModel.kennelsTableHelper.colKennelLatitude},city.${tableModel.citiesTableHelper.colLatitude}) as kenlLat,
          coalesce(k.${tableModel.kennelsTableHelper.colKennelLongitude},city.${tableModel.citiesTableHelper.colLongitude}) as kenlLon
          FROM ${EnumDataTables.kennels.commonTableName} k
          INNER JOIN ${EnumDataTables.cities.commonTableName} city on city.${tableModel.citiesTableHelper.colCityId} = k.${tableModel.kennelsTableHelper.colCityId}
          LEFT OUTER JOIN ${EnumDataTables.countries.commonTableName} c on c.countryId = k.countryId
          LEFT OUTER JOIN ${EnumDataTables.hasherKennelMap.commonTableName} hkm on "$kennelId" = hkm.kennelId,
          ${EnumDataTables.hashers.commonTableName} h  
          WHERE k.${tableModel.kennelsTableHelper.colKennelId} = "$kennelId"
          AND hkm.userId = "$userId"
          AND h.hasherId = "$userId"
          
          ''';

      final List<Map<String, dynamic>> results = await database.rawQuery(sql);

      if (results.isNotEmpty) {
        final KennelsModel kennel = tableModel.kennelsTableHelper.fromMap(
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
          eventStartDatetimeGmt: eventStart.toUtc(),
          eventDescription: dollarSign,
          kennelId: kennel.kennelId,
          hcLatitude: deviceInfo.deviceLat,
          hcLongitude: deviceInfo.deviceLon,
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
      debugPrint('[CommonQueries.getNewEvent] error: $e');
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
      final String sql =
          '''
          SELECT e.*,
          k.*,
          case when e.${tableModel.eventsTableHelper.colUseFbLatLon} = 0 then e.${tableModel.eventsTableHelper.colHcLatitude} else coalesce(e.${tableModel.eventsTableHelper.colFbLatitude},e.${tableModel.eventsTableHelper.colHcLatitude}) end as latitude,
          case when e.${tableModel.eventsTableHelper.colUseFbLatLon} = 0 then e.${tableModel.eventsTableHelper.colHcLongitude} else coalesce(e.${tableModel.eventsTableHelper.colFbLongitude},e.${tableModel.eventsTableHelper.colHcLongitude}) end as longitude,
          case when ((e.${tableModel.eventsTableHelper.colUseFbLatLon} = 0 AND e.${tableModel.eventsTableHelper.colHcLongitude} IS NOT NULL) OR ((e.${tableModel.eventsTableHelper.colUseFbLatLon} = 1 AND coalesce(e.${tableModel.eventsTableHelper.colFbLatitude},e.${tableModel.eventsTableHelper.colHcLatitude}) IS NOT NULL))) THEN 1 ELSE 0 END as isMapAndDistanceValid,
          hkm.${tableModel.hasherKennelMapTableHelper.colAppAccessFlags},
          hkm.${tableModel.hasherKennelMapTableHelper.colMismanagementRoles},
          coalesce(k.${tableModel.kennelsTableHelper.colCurrencyCode},c.${tableModel.countriesTableHelper.colCurrencyCode},"USD") as curCode,
          coalesce(k.${tableModel.kennelsTableHelper.colDigitsAfterDecimal},c.${tableModel.countriesTableHelper.colDigitsAfterDecimal},2) as digAfterDec, 
          coalesce(k.${tableModel.kennelsTableHelper.colCurrencySymbol},c.${tableModel.countriesTableHelper.colCurrencySymbol},"$dollarSign") as curSym,
          coalesce(e.${tableModel.eventsTableHelper.colEventPriceForMembers},k.${tableModel.kennelsTableHelper.colDefaultPriceForMembers},0) as memberPrice,
          coalesce(e.${tableModel.eventsTableHelper.colEventPriceForNonMembers},k.${tableModel.kennelsTableHelper.colDefaultPriceForNonMembers},0) as nonMemberPrice,
          coalesce(k.${tableModel.kennelsTableHelper.colKennelLatitude},city.${tableModel.citiesTableHelper.colLatitude}) as kenlLat,
          coalesce(k.${tableModel.kennelsTableHelper.colKennelLongitude},city.${tableModel.citiesTableHelper.colLongitude}) as kenlLon
          FROM ${EnumDataTables.events.commonTableName} e
          INNER JOIN ${EnumDataTables.kennels.commonTableName} k on k.kennelId = e.kennelId
          INNER JOIN ${EnumDataTables.cities.commonTableName} city on city.${tableModel.citiesTableHelper.colCityId} = k.${tableModel.kennelsTableHelper.colCityId}
          LEFT OUTER JOIN ${EnumDataTables.countries.commonTableName} c on c.countryId = k.countryId
          LEFT OUTER JOIN ${EnumDataTables.hasherKennelMap.commonTableName} hkm on e.kennelId = hkm.kennelId AND hkm.userId = "$userId",
          ${EnumDataTables.hashers.commonTableName} h  
          WHERE e.eventId = "$eventId"
          AND h.hasherId = "$userId" 
          ''';

      try {
        final List<Map<String, dynamic>> results = await database.rawQuery(sql);

        //final Geolocator locator = Geolocator();

        if (results.isNotEmpty) {
          final EventModel eventItem = tableModel.eventsTableHelper.fromMap(
            results[0],
          );
          final RunDetailQueryExtensions extensions =
              RunDetailQueryExtensions.fromMap(results[0]);
          final KennelsModel kennel = tableModel.kennelsTableHelper.fromMap(
            results[0],
          );
          String paymentLinkUrl = '';

          double? dist;

          if ((extensions.latitude != null) &&
              (extensions.longitude != null) &&
              (deviceInfo.deviceLat != null) &&
              (deviceInfo.deviceLon != null)) {
            dist = Geolocator.distanceBetween(
              deviceInfo.deviceLat!,
              deviceInfo.deviceLon!,
              extensions.latitude!,
              extensions.longitude!,
            );
          } else if ((kennel.kennelLatitude != null) &&
              (kennel.kennelLongitude != null) &&
              (deviceInfo.deviceLat != null) &&
              (deviceInfo.deviceLon != null)) {
            dist = Geolocator.distanceBetween(
              deviceInfo.deviceLat!,
              deviceInfo.deviceLon!,
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
          debugPrint('');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('');
      }
    }

    return runAdminAggregate;
  }
}
