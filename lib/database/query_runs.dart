import 'package:geolocator/geolocator.dart';
import 'package:harrier_central/imports.dart';

//import 'package:intl/intl.dart';

// class RunQueryExtensionsModel {
//   RunQueryExtensionsModel({
//     this.daysUntilEvent,
//     this.distToEvent,
//     this.appAccessFlags,
//     this.currencySymbol,
//     this.digitsAfterDecimal,
//     this.rsvpState,
//     this.isPaid,
//     this.isHare,
//     this.attendenceState,
//     this.isMember,
//     this.following,
//     this.notificationPreference,
//     this.emailAlertPreference,
//     this.distanceUnitsPref,
//     this.searchRunsText,
//     this.latitude,
//     this.longitude,
//     this.isMapAndDistanceValid,
//     this.runClassification,
//   });

//   final num? daysUntilEvent;
//   double? distToEvent;
//   final int? appAccessFlags;
//   int? digitsAfterDecimal;
//   String? currencySymbol;
//   int? rsvpState;
//   int? attendenceState;
//   int? isPaid;
//   int? isHare;
//   int? isMember;
//   final int? following;
//   int? notificationPreference;
//   int? emailAlertPreference;
//   int? distanceUnitsPref;
//   //int userPrefs;
//   String? searchRunsText;
//   double? latitude;
//   double? longitude;
//   bool? isMapAndDistanceValid;
//   int? runClassification; // 1 if the run is from a Kennel user is following, 2 if the run is close by, 3 if it's another run

//   static RunQueryExtensionsModel fromMap(Map<String, dynamic> map, DateTime? eventStartDateTime) {
//     // make dates and times searchable

//     int? distanceUnitsPref = (getIntPref(IntPrefsEnum.hasherPreferences) ?? 0) & hasherPref_distanceMeasuredIn;
//     if (distanceUnitsPref == 0) {
//       distanceUnitsPref = null;
//     }

//     final RunQueryExtensionsModel item = RunQueryExtensionsModel(
//       daysUntilEvent: map['daysUntilEvent'],
//       digitsAfterDecimal: map['digitsAfterDecimal'],
//       currencySymbol: map['currencySymbol'],
//       appAccessFlags: map['appAccessFlags'],
//       following: map['following'],
//       rsvpState: map['rsvpState'],
//       attendenceState: map['attendenceState'],
//       isPaid: map['isPaid'],
//       isHare: map['isHare'],
//       isMember: map['isMember'],
//       notificationPreference: map['notificationPreference'],
//       emailAlertPreference: map['emailAlertPreference'],
//       distanceUnitsPref: distanceUnitsPref ?? map['distanceUnitsPref'],
//       searchRunsText: map['searchRunsText'] + getSearchDateString(eventStartDateTime),
//       latitude: map['evtLat'] == null ? null : map['evtLat'] + 0.0,
//       longitude: map['evtLon'] == null ? null : map['evtLon'] + 0.0,
//       isMapAndDistanceValid: map['isMapAndDistanceValid'] == 1,
//       runClassification: map['runClassification'] ?? 3, // default to other run
//     );
//     return item;
//   }
// }

class RunDetailsAggregate {
  RunDetailsAggregate({
    required this.event,
    required this.kennel,
    required this.extensions,
    this.paymentUrl,
  });

  final EventModel event;
  final KennelsModel kennel;
  RunQueryExtensionsModel extensions;
  final String? paymentUrl;
}

enum EnumRunQueryType { topRunsPage, kennelDetailPage, singleRun }

enum EnumRunQueryContext { user, kennelAdmin, eventAdmin }

class QueryRuns {
  // it is important to have the beginning and end of the search field have a space
  // character to ensure that searches run properly.

  num dummyVariableToSuppressWarning = 0;

  static String searchRunsField = '''
               "~ " || coalesce(evt.${tableModel.eventsTableHelper.colEventName},"")
            || " is " || coalesce(k.${tableModel.kennelsTableHelper.colKennelShortName},"") 
            || " is " || coalesce(k.${tableModel.kennelsTableHelper.colKennelName},"")   
            || " " || coalesce(evt.${tableModel.eventsTableHelper.colEventDescription},"")
            || " " || coalesce(evt.${tableModel.eventsTableHelper.colHares},"")
            || " " || coalesce(evt.${tableModel.eventsTableHelper.colLocationCity},"")
            || " " || coalesce(evt.${tableModel.eventsTableHelper.colLocationCountry},"")
            || " " || coalesce(evt.${tableModel.eventsTableHelper.colLocationOneLineDesc},"")
            || " " || coalesce(evt.${tableModel.eventsTableHelper.colLocationPostCode},"")
            || " " || coalesce(evt.${tableModel.eventsTableHelper.colLocationRegion},"")
            || " " || coalesce(evt.${tableModel.eventsTableHelper.colLocationStreet},"")
            || " " || coalesce(evt.${tableModel.eventsTableHelper.colLocationSubRegion},"")
            || " " || case when evt.${tableModel.eventsTableHelper.colEventNumber} IS NOT NULL THEN cast(evt.${tableModel.eventsTableHelper.colEventNumber} as TEXT) END
            || " " || c.${tableModel.citiesTableHelper.colCityName} 
            || " " || r.${tableModel.regionsTableHelper.colRegionName}
            || " " || coalesce(r.${tableModel.regionsTableHelper.colRegionAbbreviation},"") 
            || " " || n.${tableModel.countriesTableHelper.colCountryName} 
            || " " || n.${tableModel.countriesTableHelper.colCountryCode} 
            || " " || replace(coalesce(c.${tableModel.citiesTableHelper.colCitySearchTags},""),","," ") 
            || " " || replace(coalesce(r.${tableModel.regionsTableHelper.colRegionSearchTags},""),","," ") 
            || " " || replace(coalesce(n.${tableModel.countriesTableHelper.colCountrySearchTags},""),","," ") 
            || " " || replace(coalesce(k.${tableModel.kennelsTableHelper.colKennelSearchTags},""),","," ") 
            || " " || 
              case 
              when evt.${tableModel.eventsTableHelper.colEventGeographicScope} = 1 THEN "not event is local" 
              when evt.${tableModel.eventsTableHelper.colEventGeographicScope} = 2 THEN "is event is local" 
              when evt.${tableModel.eventsTableHelper.colEventGeographicScope} = 3 THEN "is event is regional is state" 
              when evt.${tableModel.eventsTableHelper.colEventGeographicScope} = 4 THEN "is event is national is nash hash is nashhash" 
              when evt.${tableModel.eventsTableHelper.colEventGeographicScope} = 5 THEN "is event is continental is interhash" 
              when evt.${tableModel.eventsTableHelper.colEventGeographicScope} = 6 THEN "is event is global is world interhash" 
              when evt.${tableModel.eventsTableHelper.colEventGeographicScope} = 7 THEN "is event is other" 
              else "" 
              end 
            || " " || 
              case 
              when n.${tableModel.countriesTableHelper.colContinentCode} = "EU" then "europe" 
              when n.${tableModel.countriesTableHelper.colContinentCode} = "AF" then "africa" 
              when n.${tableModel.countriesTableHelper.colContinentCode} = "AS" then "asia" 
              when n.${tableModel.countriesTableHelper.colContinentCode} = "NA" then "north america" 
              when n.${tableModel.countriesTableHelper.colContinentCode} = "SA" then "south america" 
              when n.${tableModel.countriesTableHelper.colContinentCode} = "OC" then "oceania" 
              when n.${tableModel.countriesTableHelper.colContinentCode} = "AN" then "antarctica" 
              else "" 
              end || " ~" 
          as searchRunsText
          ''';

  static List<dynamic> doRunsFilter(
    String searchRunsText,
    List<dynamic> allRuns,
  ) {
    List<dynamic> filteredRuns = <dynamic>[];

    // allow for comma separated search lists that act to narrow search results (i.e. logical AND)
    if (searchRunsText.isNotEmpty) {
      // searchRunsText = '$searchRunsText , ${removeDiacritics(searchRunsText)}';
      final List<String> searchItems = searchRunsText
          .trim()
          .toLowerCase()
          .split(',');
      for (String st in searchItems) {
        if (st.trim().isEmpty) {
          continue;
        }
        bool negate = false;
        if (st.trim().toLowerCase().startsWith('not ')) {
          negate = true;
          st = st.substring(4);
        }
        final List<String> orItems = st.split('+');

        ////print('filtered at: ${DateTime.now().millisecondsSinceEpoch}');

        filteredRuns.addAll(
          allRuns.where((dynamic a) {
            for (String orItem in orItems) {
              if (orItem.trim().isEmpty) {
                continue;
              }
              orItem = ' ${orItem.trim().toLowerCase()}';
              if ((a.extensions.searchRunsText.toLowerCase().contains(
                    orItem,
                  )) ||
                  (removeDiacritics(
                    a.extensions.searchRunsText.toLowerCase(),
                  ).contains(orItem))) {
                return !negate;
              }
            }
            return negate;
          }).toList(),
        );
      }
    } else {
      filteredRuns.addAll(allRuns);
    }

    // filteredRuns.clear();
    // filteredRuns.addAll(allRuns);

    return filteredRuns;
  }

  static Future<List<RunDetailsAggregate>> getRunDetailsAggregates(
    bool searchAllRuns, {
    String? eventId,
    EnumRunQueryType queryType = EnumRunQueryType.topRunsPage,
  }) async {
    final List<RunDetailsAggregate> runs = <RunDetailsAggregate>[];

    //final Geolocator locator = Geolocator();

    IveCoreUtilities.logTiming('Run query start', appModel.appStartTime);
    final List<Map<String, dynamic>> results = await QueryRuns.queryRuns(
      queryType,
      EnumRunQueryContext.user,
      searchAllRuns: searchAllRuns,
      eventId: eventId,
    );

    IveCoreUtilities.logTiming('Run query end', appModel.appStartTime);

    for (int i = 0; i < results.length; i++) {
      final EventModel eventItem = tableModel.eventsTableHelper.fromMap(
        results[i],
      );
      final KennelsModel kennelItem = tableModel.kennelsTableHelper.fromMap(
        results[i],
      );
      final CitiesModel cityItem = tableModel.citiesTableHelper.fromMap(
        results[i],
      );

      double? dist;
      if ((results[i]['evtLat'] != null) &&
          (results[i]['evtLon'] != null) &&
          (deviceInfo.deviceLat != null) &&
          (deviceInfo.deviceLon != null)) {
        dist = Geolocator.distanceBetween(
          deviceInfo.deviceLat!,
          deviceInfo.deviceLon!,
          results[i]['evtLat'],
          results[i]['evtLon'],
        );
      } else if ((kennelItem.kennelLatitude != null) &&
          (kennelItem.kennelLongitude != null) &&
          (deviceInfo.deviceLat != null) &&
          (deviceInfo.deviceLon != null)) {
        dist = Geolocator.distanceBetween(
          deviceInfo.deviceLat!,
          deviceInfo.deviceLon!,
          kennelItem.kennelLatitude!,
          kennelItem.kennelLongitude!,
        );
      } else if ((deviceInfo.deviceLat != null) &&
          (deviceInfo.deviceLon != null)) {
        dist = Geolocator.distanceBetween(
          deviceInfo.deviceLat!,
          deviceInfo.deviceLon!,
          cityItem.latitude,
          cityItem.longitude,
        );
      }

      double meters = 0;
      final int userDistPrefs =
          (getIntPref(IntPrefsEnum.hasherPreferences) ?? 0) &
          hasherPref_distanceForAutoDisplay;

      switch (userDistPrefs) {
        case hasherPref_0:
          meters = 0;
          break;
        case hasherPref_10:
          meters = 10000;
          break;
        case hasherPref_25:
          meters = 25000;
          break;
        case hasherPref_50:
          meters = 50000;
          break;
        case hasherPref_75:
          meters = 75000;
          break;
        case hasherPref_100:
          meters = 100000;
          break;
        case hasherPref_150:
          meters = 150000;
          break;
        case hasherPref_250:
          meters = 250000;
          break;
        case hasherPref_500:
          meters = 500000;
          break;
        default:
          meters = 50000;
          break;
      }

      String userFriendlyLocation = Utilities.getUserFriendlyLocation(
        eventItem,
      );

      final RunQueryExtensionsModel extensionsItem =
          RunQueryExtensionsModel.fromJsonWithDateSearchText(
            results[i],
            eventItem.eventStartDatetime,
            dist,
            meters: meters,
            userFriendlyLocation: userFriendlyLocation,
          );

      String paymentLinkUrl = '';

      if (((eventItem.eventPaymentUrl ?? '') != '') &&
          ((eventItem.eventPaymentUrlExpires == null) ||
              (eventItem.eventPaymentUrlExpires!.isAfter(DateTime.now())))) {
        paymentLinkUrl = eventItem.eventPaymentUrl!;
      } else if (((kennelItem.kennelPaymentUrl ?? '') != '') &&
          ((kennelItem.kennelPaymentUrlExpires == null) ||
              (kennelItem.kennelPaymentUrlExpires!.isAfter(DateTime.now())))) {
        paymentLinkUrl = kennelItem.kennelPaymentUrl!;
      }

      if ((searchAllRuns == true) ||
          (extensionsItem.following >= 1) ||
          ((extensionsItem.following == 0) &&
              ((dist ?? 999999999.0) < meters))) {
        final RunDetailsAggregate item = RunDetailsAggregate(
          event: eventItem,
          kennel: kennelItem,
          extensions: extensionsItem,
          paymentUrl: paymentLinkUrl,
        );
        runs.add(item);
      }
    }
    return runs;
  }

  static Future<List<Map<String, dynamic>>> queryRuns(
    EnumRunQueryType queryType,
    EnumRunQueryContext queryContext, {
    String? kennelId,
    bool searchAllRuns = true,
    String? eventId,
  }) async {
    String hkmTable;
    String hemTable;
    String paymentsTable = '';

    switch (queryContext) {
      case EnumRunQueryContext.user:
        hkmTable = tableModel.hasherKennelMapTableHelper.getTableName(
          AppDomainType.user,
        );
        hemTable = tableModel.hasherEventMapTableHelper.getTableName(
          AppDomainType.user,
        );
        paymentsTable = tableModel.paymentsTableHelper.getTableName(
          AppDomainType.user,
        );
        break;
      case EnumRunQueryContext.kennelAdmin:
        hkmTable = tableModel.hasherKennelMapTableHelper.getTableName(
          AppDomainType.kennel,
        );
        hemTable = tableModel.hasherEventMapTableHelper.getTableName(
          AppDomainType.user,
        );
        //paymentsTable = tableModel.paymentsTableHelper.getTableName(AppDomainType.kennel);
        break;
      case EnumRunQueryContext.eventAdmin:
        hkmTable = tableModel.hasherKennelMapTableHelper.getTableName(
          AppDomainType.event,
        );
        hemTable = tableModel.hasherEventMapTableHelper.getTableName(
          AppDomainType.event,
        );
        paymentsTable = tableModel.paymentsTableHelper.getTableName(
          AppDomainType.event,
        );
        break;
    }

    final String userId = getStringPref(StringPrefsEnum.userId)!;

    String queryBase = '';

    if (queryContext == EnumRunQueryContext.kennelAdmin) {
      queryBase = '''
        SELECT  
          evt.*,
          k.*,
          c.*,

          case when evt.${tableModel.eventsTableHelper.colUseFbLatLon} = 0 then evt.${tableModel.eventsTableHelper.colHcLatitude} else coalesce(evt.${tableModel.eventsTableHelper.colFbLatitude},evt.${tableModel.eventsTableHelper.colHcLatitude}) end as evtLat,
          case when evt.${tableModel.eventsTableHelper.colUseFbLatLon} = 0 then evt.${tableModel.eventsTableHelper.colHcLongitude} else coalesce(evt.${tableModel.eventsTableHelper.colFbLongitude},evt.${tableModel.eventsTableHelper.colHcLongitude}) end as evtLon,
          case when ((evt.${tableModel.eventsTableHelper.colUseFbLatLon} = 0 AND evt.${tableModel.eventsTableHelper.colHcLongitude} IS NOT NULL) OR ((evt.${tableModel.eventsTableHelper.colUseFbLatLon} = 1 AND coalesce(evt.${tableModel.eventsTableHelper.colFbLatitude},evt.${tableModel.eventsTableHelper.colHcLongitude}) IS NOT NULL))) THEN 1 ELSE 0 END as isMapAndDistanceValid,

          coalesce(hkm.appAccessFlags,0) as appAccessFlags,
          coalesce(hkm.following,0) as following,
          coalesce(hem.${tableModel.hasherEventMapTableHelper.colRsvpState},0) as rsvpState,
          coalesce(hem.${tableModel.hasherEventMapTableHelper.colAttendenceState},0) as attendenceState,
          0 as isPaid,
          coalesce(hem.${tableModel.hasherEventMapTableHelper.colIsHare},0) as isHare,
          case when ((hkm.membershipExpirationDate IS NOT NULL) AND (julianday(hkm.membershipExpirationDate) >= julianday('now','localtime'))) then 1 else 0 end as isMember,
          coalesce(hkm.kennelNotificationPreference,0) as notificationPreference,
          coalesce(hkm.kennelEmailAlertPreference,0) as emailAlertPreference,
          COALESCE(k.${tableModel.kennelsTableHelper.colDigitsAfterDecimal},n.${tableModel.countriesTableHelper.colDigitsAfterDecimal}) as ${tableModel.countriesTableHelper.colDigitsAfterDecimal},
          COALESCE(k.${tableModel.kennelsTableHelper.colCurrencySymbol},n.${tableModel.countriesTableHelper.colCurrencySymbol}) as ${tableModel.countriesTableHelper.colCurrencySymbol},
          COALESCE(k.distancePreference,n.distancePreference,0) as distanceUnitsPref,
          CAST(julianday(evt.eventStartDatetime) + 0.5 AS INT) - CAST(julianday('now','localtime') + 0.5 AS INT) as daysUntilEvent,
          julianday(evt.eventStartDatetime) + 0.5 as eventJulian,
          julianday('now','localtime') + 0.5 as nowJulian,
          $searchRunsField
          FROM narrowEvents evt
          INNER JOIN kennels k on k.kennelId = evt.kennelId
          INNER JOIN ${tableModel.citiesTableHelper.getTableName(AppDomainType.user)} c on c.${tableModel.citiesTableHelper.colCityId} = k.${tableModel.kennelsTableHelper.colCityId}
          INNER JOIN ${tableModel.regionsTableHelper.getTableName(AppDomainType.user)} r on r.${tableModel.regionsTableHelper.colRegionId} = k.${tableModel.kennelsTableHelper.colRegionId}
          INNER JOIN ${tableModel.countriesTableHelper.getTableName(AppDomainType.user)} n on n.${tableModel.countriesTableHelper.colCountryId} = k.${tableModel.kennelsTableHelper.colCountryId}
          LEFT OUTER JOIN $hkmTable hkm on hkm.kennelId = evt.kennelId and hkm.userId = "$userId"
          LEFT OUTER JOIN $hemTable hem on hem.eventId = evt.eventId and hem.userId = "$userId"
          ''';
    } else {
      queryBase = '''
      
        SELECT  
          evt.*,
          k.*,
          c.*,

          case when evt.${tableModel.eventsTableHelper.colUseFbLatLon} = 0 then evt.${tableModel.eventsTableHelper.colHcLatitude} else coalesce(evt.${tableModel.eventsTableHelper.colFbLatitude},evt.${tableModel.eventsTableHelper.colHcLatitude}) end as evtLat,
          case when evt.${tableModel.eventsTableHelper.colUseFbLatLon} = 0 then evt.${tableModel.eventsTableHelper.colHcLongitude} else coalesce(evt.${tableModel.eventsTableHelper.colFbLongitude},evt.${tableModel.eventsTableHelper.colHcLongitude}) end as evtLon,
          case when ((evt.${tableModel.eventsTableHelper.colUseFbLatLon} = 0 AND evt.${tableModel.eventsTableHelper.colHcLongitude} IS NOT NULL) OR ((evt.${tableModel.eventsTableHelper.colUseFbLatLon} = 1 AND coalesce(evt.${tableModel.eventsTableHelper.colFbLatitude},evt.${tableModel.eventsTableHelper.colHcLongitude}) IS NOT NULL))) THEN 1 ELSE 0 END as isMapAndDistanceValid,

          coalesce(hkm.appAccessFlags,0) as appAccessFlags,
          coalesce(hkm.following,0) as following,
          coalesce(hem.${tableModel.hasherEventMapTableHelper.colRsvpState},0) as rsvpState,
          coalesce(hem.${tableModel.hasherEventMapTableHelper.colAttendenceState},0) as attendenceState,
          CASE WHEN coalesce(pay.paymentType,0) >= 2 THEN 1 ELSE 0 END as isPaid,
          coalesce(hem.${tableModel.hasherEventMapTableHelper.colIsHare},0) as isHare,
          case when ((hkm.membershipExpirationDate IS NOT NULL) AND (julianday(hkm.membershipExpirationDate) >= julianday('now','localtime'))) then 1 else 0 end as isMember,
          coalesce(hem.eventNotificationPreference,hkm.kennelNotificationPreference,0) as notificationPreference,
          coalesce(hem.eventEmailAlertPreference,hkm.kennelEmailAlertPreference,0) as emailAlertPreference,
          COALESCE(k.${tableModel.kennelsTableHelper.colDigitsAfterDecimal},n.${tableModel.countriesTableHelper.colDigitsAfterDecimal}) as ${tableModel.countriesTableHelper.colDigitsAfterDecimal},
          COALESCE(k.${tableModel.kennelsTableHelper.colCurrencySymbol},n.${tableModel.countriesTableHelper.colCurrencySymbol}) as ${tableModel.countriesTableHelper.colCurrencySymbol},
          COALESCE(k.distancePreference,n.distancePreference,0) as distanceUnitsPref,
          CAST(julianday(evt.eventStartDatetime) + 0.5 AS INT) - CAST(julianday('now','localtime') + 0.5 AS INT) as daysUntilEvent,
          julianday(evt.eventStartDatetime) + 0.5 as eventJulian,
          julianday('now','localtime') + 0.5 as nowJulian,
          $searchRunsField
          FROM narrowEvents evt
          INNER JOIN kennels k on k.kennelId = evt.kennelId
          INNER JOIN ${tableModel.citiesTableHelper.getTableName(AppDomainType.user)} c on c.${tableModel.citiesTableHelper.colCityId} = k.${tableModel.kennelsTableHelper.colCityId}
          INNER JOIN ${tableModel.regionsTableHelper.getTableName(AppDomainType.user)} r on r.${tableModel.regionsTableHelper.colRegionId} = k.${tableModel.kennelsTableHelper.colRegionId}
          INNER JOIN ${tableModel.countriesTableHelper.getTableName(AppDomainType.user)} n on n.${tableModel.countriesTableHelper.colCountryId} = k.${tableModel.kennelsTableHelper.colCountryId}
          LEFT OUTER JOIN $hkmTable hkm on hkm.kennelId = evt.kennelId and hkm.userId = "$userId"
          LEFT OUTER JOIN $hemTable hem on hem.eventId = evt.eventId and hem.userId = "$userId"
          LEFT OUTER JOIN $paymentsTable pay on pay.${tableModel.paymentsTableHelper.colHemId} = hem.${tableModel.hasherEventMapTableHelper.colHemId} AND pay.${tableModel.paymentsTableHelper.colCancelledBy} IS NULL
          ''';
    }

    final String whereClauseForTopRunsPage = '''
            WHERE datetime(evt.${tableModel.eventsTableHelper.colEventStartDatetime}) >= datetime('now','-4 hours') and evt.${tableModel.eventsTableHelper.colIsVisible} = 1
            AND coalesce(hkm.following,0) != 2
            AND evt.${tableModel.eventsTableHelper.colRemoved} = 0
            AND (
                  "${searchAllRuns.toString()}" == "true"
                  OR
                  (coalesce(hkm.following,0) <= 1) 
                  OR 
                  (coalesce(hem.rsvpState,0) >= 2)
                )
            ORDER BY evt.${tableModel.eventsTableHelper.colEventStartDatetime}, evt.${tableModel.eventsTableHelper.colEventNumber}
          ''';

    final String whereClauseForKennelDetailsPage =
        kennelId == null
            ? ''
            : '''
            WHERE datetime(evt.${tableModel.eventsTableHelper.colEventStartDatetime}) >= datetime('now','-4 hours') and evt.${tableModel.eventsTableHelper.colIsVisible} = 1
            AND evt.${tableModel.eventsTableHelper.colKennelId} = "$kennelId"
            AND evt.${tableModel.eventsTableHelper.colRemoved} = 0
            ORDER BY evt.${tableModel.eventsTableHelper.colEventStartDatetime}, evt.${tableModel.eventsTableHelper.colEventNumber}
          ''';

    final String whereClauseForSingleRun =
        eventId == null
            ? ''
            : '''
            WHERE evt.${tableModel.eventsTableHelper.colEventId} = "$eventId"
            AND evt.${tableModel.eventsTableHelper.colRemoved} = 0
          ''';

    String query = queryBase;
    if (queryType == EnumRunQueryType.topRunsPage) {
      query = query + whereClauseForTopRunsPage;
    } else if (queryType == EnumRunQueryType.kennelDetailPage) {
      query = query + whereClauseForKennelDetailsPage;
    } else if (queryType == EnumRunQueryType.singleRun) {
      query = query + whereClauseForSingleRun;
    } else {
      assert(false);
    }

    return database.rawQuery(query);
  }

  static Future<List<Map<String, dynamic>>> queryPreviousRun(
    String? kennelId,
    DateTime eventStartDateTime,
  ) async {
    String query = '''
        SELECT  
          evt.${tableModel.eventsTableHelper.colEventName} as eventName,
          evt.${tableModel.eventsTableHelper.colEventId} as eventId
          FROM narrowEvents evt
          WHERE evt.${tableModel.eventsTableHelper.colKennelId} = "$kennelId"
          AND datetime(evt.${tableModel.eventsTableHelper.colEventStartDatetime}) < datetime('$eventStartDateTime') 
          AND evt.${tableModel.eventsTableHelper.colIsVisible} = 1
          ORDER BY evt.${tableModel.eventsTableHelper.colEventStartDatetime} DESC
          LIMIT 1
          ''';

    return database.rawQuery(query);
  }
}
