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
               "~ " || coalesce(evt.${G0<TableModel>().eventsTableHelper.colEventName},"")
            || " is " || coalesce(k.${G0<TableModel>().kennelsTableHelper.colKennelShortName},"") 
            || " is " || coalesce(k.${G0<TableModel>().kennelsTableHelper.colKennelName},"")   
            || " " || coalesce(evt.${G0<TableModel>().eventsTableHelper.colEventDescription},"")
            || " " || coalesce(evt.${G0<TableModel>().eventsTableHelper.colHares},"")
            || " " || coalesce(evt.${G0<TableModel>().eventsTableHelper.colLocationCity},"")
            || " " || coalesce(evt.${G0<TableModel>().eventsTableHelper.colLocationCountry},"")
            || " " || coalesce(evt.${G0<TableModel>().eventsTableHelper.colLocationOneLineDesc},"")
            || " " || coalesce(evt.${G0<TableModel>().eventsTableHelper.colLocationPostCode},"")
            || " " || coalesce(evt.${G0<TableModel>().eventsTableHelper.colLocationRegion},"")
            || " " || coalesce(evt.${G0<TableModel>().eventsTableHelper.colLocationStreet},"")
            || " " || coalesce(evt.${G0<TableModel>().eventsTableHelper.colLocationSubRegion},"")
            || " " || case when evt.${G0<TableModel>().eventsTableHelper.colEventNumber} IS NOT NULL THEN cast(evt.${G0<TableModel>().eventsTableHelper.colEventNumber} as TEXT) END
            || " " || c.${G0<TableModel>().citiesTableHelper.colCityName} 
            || " " || r.${G0<TableModel>().regionsTableHelper.colRegionName}
            || " " || coalesce(r.${G0<TableModel>().regionsTableHelper.colRegionAbbreviation},"") 
            || " " || n.${G0<TableModel>().countriesTableHelper.colCountryName} 
            || " " || n.${G0<TableModel>().countriesTableHelper.colCountryCode} 
            || " " || replace(coalesce(c.${G0<TableModel>().citiesTableHelper.colCitySearchTags},""),","," ") 
            || " " || replace(coalesce(r.${G0<TableModel>().regionsTableHelper.colRegionSearchTags},""),","," ") 
            || " " || replace(coalesce(n.${G0<TableModel>().countriesTableHelper.colCountrySearchTags},""),","," ") 
            || " " || replace(coalesce(k.${G0<TableModel>().kennelsTableHelper.colKennelSearchTags},""),","," ") 
            || " " || 
              case 
              when evt.${G0<TableModel>().eventsTableHelper.colEventGeographicScope} = 1 THEN "not event is local" 
              when evt.${G0<TableModel>().eventsTableHelper.colEventGeographicScope} = 2 THEN "is event is local" 
              when evt.${G0<TableModel>().eventsTableHelper.colEventGeographicScope} = 3 THEN "is event is regional is state" 
              when evt.${G0<TableModel>().eventsTableHelper.colEventGeographicScope} = 4 THEN "is event is national is nash hash is nashhash" 
              when evt.${G0<TableModel>().eventsTableHelper.colEventGeographicScope} = 5 THEN "is event is continental is interhash" 
              when evt.${G0<TableModel>().eventsTableHelper.colEventGeographicScope} = 6 THEN "is event is global is world interhash" 
              when evt.${G0<TableModel>().eventsTableHelper.colEventGeographicScope} = 7 THEN "is event is other" 
              else "" 
              end 
            || " " || 
              case 
              when n.${G0<TableModel>().countriesTableHelper.colContinentCode} = "EU" then "europe" 
              when n.${G0<TableModel>().countriesTableHelper.colContinentCode} = "AF" then "africa" 
              when n.${G0<TableModel>().countriesTableHelper.colContinentCode} = "AS" then "asia" 
              when n.${G0<TableModel>().countriesTableHelper.colContinentCode} = "NA" then "north america" 
              when n.${G0<TableModel>().countriesTableHelper.colContinentCode} = "SA" then "south america" 
              when n.${G0<TableModel>().countriesTableHelper.colContinentCode} = "OC" then "oceania" 
              when n.${G0<TableModel>().countriesTableHelper.colContinentCode} = "AN" then "antarctica" 
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

    IveCoreUtilities.logTiming('Run query start', G0<AppModel>().appStartTime);
    final List<Map<String, dynamic>> results = await QueryRuns.queryRuns(
      queryType,
      EnumRunQueryContext.user,
      searchAllRuns: searchAllRuns,
      eventId: eventId,
    );

    IveCoreUtilities.logTiming('Run query end', G0<AppModel>().appStartTime);

    for (int i = 0; i < results.length; i++) {
      final EventModel eventItem = G0<TableModel>().eventsTableHelper.fromMap(
        results[i],
      );
      final KennelsModel kennelItem = G0<TableModel>().kennelsTableHelper
          .fromMap(results[i]);
      final CitiesModel cityItem = G0<TableModel>().citiesTableHelper.fromMap(
        results[i],
      );

      double? dist;
      if ((results[i]['evtLat'] != null) &&
          (results[i]['evtLon'] != null) &&
          (G0<DeviceInfo>().deviceLat != null) &&
          (G0<DeviceInfo>().deviceLon != null)) {
        dist = Geolocator.distanceBetween(
          G0<DeviceInfo>().deviceLat!,
          G0<DeviceInfo>().deviceLon!,
          results[i]['evtLat'],
          results[i]['evtLon'],
        );
      } else if ((kennelItem.kennelLatitude != null) &&
          (kennelItem.kennelLongitude != null) &&
          (G0<DeviceInfo>().deviceLat != null) &&
          (G0<DeviceInfo>().deviceLon != null)) {
        dist = Geolocator.distanceBetween(
          G0<DeviceInfo>().deviceLat!,
          G0<DeviceInfo>().deviceLon!,
          kennelItem.kennelLatitude!,
          kennelItem.kennelLongitude!,
        );
      } else if ((G0<DeviceInfo>().deviceLat != null) &&
          (G0<DeviceInfo>().deviceLon != null)) {
        dist = Geolocator.distanceBetween(
          G0<DeviceInfo>().deviceLat!,
          G0<DeviceInfo>().deviceLon!,
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
        hkmTable = G0<TableModel>().hasherKennelMapTableHelper.getTableName(
          AppDomainType.user,
        );
        hemTable = G0<TableModel>().hasherEventMapTableHelper.getTableName(
          AppDomainType.user,
        );
        paymentsTable = G0<TableModel>().paymentsTableHelper.getTableName(
          AppDomainType.user,
        );
        break;
      case EnumRunQueryContext.kennelAdmin:
        hkmTable = G0<TableModel>().hasherKennelMapTableHelper.getTableName(
          AppDomainType.kennel,
        );
        hemTable = G0<TableModel>().hasherEventMapTableHelper.getTableName(
          AppDomainType.user,
        );
        //paymentsTable = G0<TableModel>().paymentsTableHelper.getTableName(AppDomainType.kennel);
        break;
      case EnumRunQueryContext.eventAdmin:
        hkmTable = G0<TableModel>().hasherKennelMapTableHelper.getTableName(
          AppDomainType.event,
        );
        hemTable = G0<TableModel>().hasherEventMapTableHelper.getTableName(
          AppDomainType.event,
        );
        paymentsTable = G0<TableModel>().paymentsTableHelper.getTableName(
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

          case when evt.${G0<TableModel>().eventsTableHelper.colUseFbLatLon} = 0 then evt.${G0<TableModel>().eventsTableHelper.colHcLatitude} else coalesce(evt.${G0<TableModel>().eventsTableHelper.colFbLatitude},evt.${G0<TableModel>().eventsTableHelper.colHcLatitude}) end as evtLat,
          case when evt.${G0<TableModel>().eventsTableHelper.colUseFbLatLon} = 0 then evt.${G0<TableModel>().eventsTableHelper.colHcLongitude} else coalesce(evt.${G0<TableModel>().eventsTableHelper.colFbLongitude},evt.${G0<TableModel>().eventsTableHelper.colHcLongitude}) end as evtLon,
          case when ((evt.${G0<TableModel>().eventsTableHelper.colUseFbLatLon} = 0 AND evt.${G0<TableModel>().eventsTableHelper.colHcLongitude} IS NOT NULL) OR ((evt.${G0<TableModel>().eventsTableHelper.colUseFbLatLon} = 1 AND coalesce(evt.${G0<TableModel>().eventsTableHelper.colFbLatitude},evt.${G0<TableModel>().eventsTableHelper.colHcLongitude}) IS NOT NULL))) THEN 1 ELSE 0 END as isMapAndDistanceValid,

          coalesce(hkm.appAccessFlags,0) as appAccessFlags,
          coalesce(hkm.following,0) as following,
          coalesce(hem.${G0<TableModel>().hasherEventMapTableHelper.colRsvpState},0) as rsvpState,
          coalesce(hem.${G0<TableModel>().hasherEventMapTableHelper.colAttendenceState},0) as attendenceState,
          0 as isPaid,
          coalesce(hem.${G0<TableModel>().hasherEventMapTableHelper.colIsHare},0) as isHare,
          case when ((hkm.membershipExpirationDate IS NOT NULL) AND (julianday(hkm.membershipExpirationDate) >= julianday('now','localtime'))) then 1 else 0 end as isMember,
          coalesce(hkm.kennelNotificationPreference,0) as notificationPreference,
          coalesce(hkm.kennelEmailAlertPreference,0) as emailAlertPreference,
          COALESCE(k.${G0<TableModel>().kennelsTableHelper.colDigitsAfterDecimal},n.${G0<TableModel>().countriesTableHelper.colDigitsAfterDecimal}) as ${G0<TableModel>().countriesTableHelper.colDigitsAfterDecimal},
          COALESCE(k.${G0<TableModel>().kennelsTableHelper.colCurrencySymbol},n.${G0<TableModel>().countriesTableHelper.colCurrencySymbol}) as ${G0<TableModel>().countriesTableHelper.colCurrencySymbol},
          COALESCE(k.distancePreference,n.distancePreference,0) as distanceUnitsPref,
          CAST(julianday(evt.eventStartDatetime) + 0.5 AS INT) - CAST(julianday('now','localtime') + 0.5 AS INT) as daysUntilEvent,
          julianday(evt.eventStartDatetime) + 0.5 as eventJulian,
          julianday('now','localtime') + 0.5 as nowJulian,
          $searchRunsField
          FROM narrowEvents evt
          INNER JOIN kennels k on k.kennelId = evt.kennelId
          INNER JOIN ${G0<TableModel>().citiesTableHelper.getTableName(AppDomainType.user)} c on c.${G0<TableModel>().citiesTableHelper.colCityId} = k.${G0<TableModel>().kennelsTableHelper.colCityId}
          INNER JOIN ${G0<TableModel>().regionsTableHelper.getTableName(AppDomainType.user)} r on r.${G0<TableModel>().regionsTableHelper.colRegionId} = k.${G0<TableModel>().kennelsTableHelper.colRegionId}
          INNER JOIN ${G0<TableModel>().countriesTableHelper.getTableName(AppDomainType.user)} n on n.${G0<TableModel>().countriesTableHelper.colCountryId} = k.${G0<TableModel>().kennelsTableHelper.colCountryId}
          LEFT OUTER JOIN $hkmTable hkm on hkm.kennelId = evt.kennelId and hkm.userId = "$userId"
          LEFT OUTER JOIN $hemTable hem on hem.eventId = evt.eventId and hem.userId = "$userId"
          ''';
    } else {
      queryBase = '''
      
        SELECT  
          evt.*,
          k.*,
          c.*,

          case when evt.${G0<TableModel>().eventsTableHelper.colUseFbLatLon} = 0 then evt.${G0<TableModel>().eventsTableHelper.colHcLatitude} else coalesce(evt.${G0<TableModel>().eventsTableHelper.colFbLatitude},evt.${G0<TableModel>().eventsTableHelper.colHcLatitude}) end as evtLat,
          case when evt.${G0<TableModel>().eventsTableHelper.colUseFbLatLon} = 0 then evt.${G0<TableModel>().eventsTableHelper.colHcLongitude} else coalesce(evt.${G0<TableModel>().eventsTableHelper.colFbLongitude},evt.${G0<TableModel>().eventsTableHelper.colHcLongitude}) end as evtLon,
          case when ((evt.${G0<TableModel>().eventsTableHelper.colUseFbLatLon} = 0 AND evt.${G0<TableModel>().eventsTableHelper.colHcLongitude} IS NOT NULL) OR ((evt.${G0<TableModel>().eventsTableHelper.colUseFbLatLon} = 1 AND coalesce(evt.${G0<TableModel>().eventsTableHelper.colFbLatitude},evt.${G0<TableModel>().eventsTableHelper.colHcLongitude}) IS NOT NULL))) THEN 1 ELSE 0 END as isMapAndDistanceValid,

          coalesce(hkm.appAccessFlags,0) as appAccessFlags,
          coalesce(hkm.following,0) as following,
          coalesce(hem.${G0<TableModel>().hasherEventMapTableHelper.colRsvpState},0) as rsvpState,
          coalesce(hem.${G0<TableModel>().hasherEventMapTableHelper.colAttendenceState},0) as attendenceState,
          CASE WHEN coalesce(pay.paymentType,0) >= 2 THEN 1 ELSE 0 END as isPaid,
          coalesce(hem.${G0<TableModel>().hasherEventMapTableHelper.colIsHare},0) as isHare,
          case when ((hkm.membershipExpirationDate IS NOT NULL) AND (julianday(hkm.membershipExpirationDate) >= julianday('now','localtime'))) then 1 else 0 end as isMember,
          coalesce(hem.eventNotificationPreference,hkm.kennelNotificationPreference,0) as notificationPreference,
          coalesce(hem.eventEmailAlertPreference,hkm.kennelEmailAlertPreference,0) as emailAlertPreference,
          COALESCE(k.${G0<TableModel>().kennelsTableHelper.colDigitsAfterDecimal},n.${G0<TableModel>().countriesTableHelper.colDigitsAfterDecimal}) as ${G0<TableModel>().countriesTableHelper.colDigitsAfterDecimal},
          COALESCE(k.${G0<TableModel>().kennelsTableHelper.colCurrencySymbol},n.${G0<TableModel>().countriesTableHelper.colCurrencySymbol}) as ${G0<TableModel>().countriesTableHelper.colCurrencySymbol},
          COALESCE(k.distancePreference,n.distancePreference,0) as distanceUnitsPref,
          CAST(julianday(evt.eventStartDatetime) + 0.5 AS INT) - CAST(julianday('now','localtime') + 0.5 AS INT) as daysUntilEvent,
          julianday(evt.eventStartDatetime) + 0.5 as eventJulian,
          julianday('now','localtime') + 0.5 as nowJulian,
          $searchRunsField
          FROM narrowEvents evt
          INNER JOIN kennels k on k.kennelId = evt.kennelId
          INNER JOIN ${G0<TableModel>().citiesTableHelper.getTableName(AppDomainType.user)} c on c.${G0<TableModel>().citiesTableHelper.colCityId} = k.${G0<TableModel>().kennelsTableHelper.colCityId}
          INNER JOIN ${G0<TableModel>().regionsTableHelper.getTableName(AppDomainType.user)} r on r.${G0<TableModel>().regionsTableHelper.colRegionId} = k.${G0<TableModel>().kennelsTableHelper.colRegionId}
          INNER JOIN ${G0<TableModel>().countriesTableHelper.getTableName(AppDomainType.user)} n on n.${G0<TableModel>().countriesTableHelper.colCountryId} = k.${G0<TableModel>().kennelsTableHelper.colCountryId}
          LEFT OUTER JOIN $hkmTable hkm on hkm.kennelId = evt.kennelId and hkm.userId = "$userId"
          LEFT OUTER JOIN $hemTable hem on hem.eventId = evt.eventId and hem.userId = "$userId"
          LEFT OUTER JOIN $paymentsTable pay on pay.${G0<TableModel>().paymentsTableHelper.colHemId} = hem.${G0<TableModel>().hasherEventMapTableHelper.colHemId} AND pay.${G0<TableModel>().paymentsTableHelper.colCancelledBy} IS NULL
          ''';
    }

    final String whereClauseForTopRunsPage = '''
            WHERE datetime(evt.${G0<TableModel>().eventsTableHelper.colEventStartDatetime}) >= datetime('now','-4 hours') and evt.${G0<TableModel>().eventsTableHelper.colIsVisible} = 1
            AND coalesce(hkm.following,0) != 2
            AND evt.${G0<TableModel>().eventsTableHelper.colRemoved} = 0
            AND (
                  "${searchAllRuns.toString()}" == "true"
                  OR
                  (coalesce(hkm.following,0) <= 1) 
                  OR 
                  (coalesce(hem.rsvpState,0) >= 2)
                )
            ORDER BY evt.${G0<TableModel>().eventsTableHelper.colEventStartDatetime}, evt.${G0<TableModel>().eventsTableHelper.colEventNumber}
          ''';

    final String whereClauseForKennelDetailsPage =
        kennelId == null
            ? ''
            : '''
            WHERE datetime(evt.${G0<TableModel>().eventsTableHelper.colEventStartDatetime}) >= datetime('now','-4 hours') and evt.${G0<TableModel>().eventsTableHelper.colIsVisible} = 1
            AND evt.${G0<TableModel>().eventsTableHelper.colKennelId} = "$kennelId"
            AND evt.${G0<TableModel>().eventsTableHelper.colRemoved} = 0
            ORDER BY evt.${G0<TableModel>().eventsTableHelper.colEventStartDatetime}, evt.${G0<TableModel>().eventsTableHelper.colEventNumber}
          ''';

    final String whereClauseForSingleRun =
        eventId == null
            ? ''
            : '''
            WHERE evt.${G0<TableModel>().eventsTableHelper.colEventId} = "$eventId"
            AND evt.${G0<TableModel>().eventsTableHelper.colRemoved} = 0
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

    return G0<Database>().rawQuery(query);
  }

  static Future<List<Map<String, dynamic>>> queryPreviousRun(
    String? kennelId,
    DateTime eventStartDateTime,
  ) async {
    String query = '''
        SELECT  
          evt.${G0<TableModel>().eventsTableHelper.colEventName} as eventName,
          evt.${G0<TableModel>().eventsTableHelper.colEventId} as eventId
          FROM narrowEvents evt
          WHERE evt.${G0<TableModel>().eventsTableHelper.colKennelId} = "$kennelId"
          AND datetime(evt.${G0<TableModel>().eventsTableHelper.colEventStartDatetime}) < datetime('$eventStartDateTime') 
          AND evt.${G0<TableModel>().eventsTableHelper.colIsVisible} = 1
          ORDER BY evt.${G0<TableModel>().eventsTableHelper.colEventStartDatetime} DESC
          LIMIT 1
          ''';

    return G0<Database>().rawQuery(query);
  }
}
