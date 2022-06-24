// @dart=2.11
import 'package:geolocator/geolocator.dart';
import 'package:harrier_central/imports.dart';

import 'package:intl/intl.dart';

class RunDetailsQueryExtensions {
  RunDetailsQueryExtensions({
    this.daysUntilEvent,
    this.distToEvent,
    this.appAccessFlags,
    this.currencySymbol,
    this.digitsAfterDecimal,
    this.rsvpState,
    this.isPaid,
    this.isHare,
    this.attendenceState,
    this.isMember,
    this.following,
    this.notificationPreference,
    this.emailAlertPreference,
    this.distanceUnitsPref,
    this.searchRunsText,
    this.latitude,
    this.longitude,
    this.isMapAndDistanceValid,
    this.runClassification,
  });

  final num daysUntilEvent;
  num distToEvent;
  final int appAccessFlags;
  int digitsAfterDecimal;
  String currencySymbol;
  int rsvpState;
  int attendenceState;
  int isPaid;
  int isHare;
  int isMember;
  final int following;
  int notificationPreference;
  int emailAlertPreference;
  int distanceUnitsPref;
  //int userPrefs;
  String searchRunsText;
  num latitude;
  num longitude;
  bool isMapAndDistanceValid;
  int runClassification; // 1 if the run is from a Kennel user is following, 2 if the run is close by, 3 if it's another run

  static String getSearchDateString(DateTime eventStartDateTime) {
    final DateFormat df = DateFormat("' is' y ' is' EEEE ' is' LLLL d y ' is' LLL d y h:mm aaa HH:mm", 'en_US');
    String days = '';
    String weekend = '';
    String thisDay = '';

    final int deltaDays = eventStartDateTime.millisecondsSinceEpoch ~/ (86400 * 1000) - DateTime.now().millisecondsSinceEpoch ~/ (86400 * 1000);
    if (deltaDays < 0) {
      if (deltaDays == 1) {
        days = ' 1 day ago is yesterday ';
      } else {
        days = ' ${-deltaDays} days ago ';
      }
    } else if (deltaDays > 0) {
      if (deltaDays == 1) {
        days = ' in 1 day is tomorrow ';
      } else {
        days = ' in $deltaDays days ';
      }
    } else {
      days = ' is today ';
    }

    if ((deltaDays > 0) && (deltaDays < 7)) {
      switch (eventStartDateTime.weekday) {
        case DateTime.monday:
          thisDay = ' this Monday ';
          break;
        case DateTime.tuesday:
          thisDay = ' this Tuesday ';
          break;
        case DateTime.wednesday:
          thisDay = ' this Wednesday ';
          break;
        case DateTime.thursday:
          thisDay = ' this Thursday ';
          break;
        case DateTime.friday:
          thisDay = ' this Friday ';
          break;
        case DateTime.saturday:
          thisDay = ' this Saturday ';
          break;
        case DateTime.sunday:
          thisDay = ' this Sunday ';
          break;
      }
    }

    if ((eventStartDateTime.weekday == DateTime.sunday) || (eventStartDateTime.weekday == DateTime.saturday)) {
      weekend = ' is weekend ';
    }

    //final String test = ' ' + df.format(eventStartDateTime) + ' ' + days + weekend + thisDay;
    ////print(test);

    return ' ' + df.format(eventStartDateTime) + ' ' + days + weekend + thisDay;
  }

  static RunDetailsQueryExtensions fromMap(Map<String, dynamic> map, DateTime eventStartDateTime) {
    // make dates and tiems searchable

    int _distanceUnitsPref = getIntPref(IntPrefsEnum.hasherPreferences) & hasherPref_distanceMeasuredIn;
    if (_distanceUnitsPref == 0) {
      _distanceUnitsPref = null;
    }

    final RunDetailsQueryExtensions item = RunDetailsQueryExtensions(
      daysUntilEvent: map['daysUntilEvent'],
      digitsAfterDecimal: map['digitsAfterDecimal'],
      currencySymbol: map['currencySymbol'],
      appAccessFlags: map['appAccessFlags'],
      following: map['following'],
      rsvpState: map['rsvpState'],
      attendenceState: map['attendenceState'],
      isPaid: map['isPaid'],
      isHare: map['isHare'],
      isMember: map['isMember'],
      notificationPreference: map['notificationPreference'],
      emailAlertPreference: map['emailAlertPreference'],
      distanceUnitsPref: _distanceUnitsPref ?? map['distanceUnitsPref'],
      searchRunsText: map['searchRunsText'] + getSearchDateString(eventStartDateTime),
      latitude: map['latitude'] == null ? null : map['latitude'] + 0.0,
      longitude: map['longitude'] == null ? null : map['longitude'] + 0.0,
      isMapAndDistanceValid: map['isMapAndDistanceValid'] == 1,
      runClassification: map['runClassification'] == null ? 3 : map['runClassification'], // default to other run
    );
    return item;
  }
}

class RunDetailsAggregate {
  RunDetailsAggregate({
    this.event,
    this.kennel,
    this.extensions,
    this.paymentUrl,
  });

  final EventModel event;
  final KennelsModel kennel;
  final RunDetailsQueryExtensions extensions;
  final String paymentUrl;
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

  static List<dynamic> doRunsFilter(String searchRunsText, List<dynamic> allRuns) {
    List<dynamic> filteredRuns = <dynamic>[];
    if (allRuns != null) {
      //filteredRuns.addAll(allRuns);

      // allow for comma separated search lists that act to narrow search results (i.e. logical AND)
      if ((searchRunsText != null) && (searchRunsText.isNotEmpty)) {
        final List<String> searchItems = searchRunsText.trim().toLowerCase().split(',');
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

          filteredRuns = allRuns.where((dynamic a) {
            for (String orItem in orItems) {
              if (orItem.trim().isEmpty) {
                continue;
              }
              orItem = ' ' + orItem.trim().toLowerCase();
              if (a.extensions.searchRunsText.toLowerCase().contains(orItem)) {
                return !negate;
              }
            }
            return negate;
          }).toList();
        }
      } else {
        filteredRuns.addAll(allRuns);
      }
    }
    return filteredRuns;
  }

  static Future<List<dynamic>> getRunDetailsAggregates(
    bool searchAllRuns, {
    String eventId,
    EnumRunQueryType queryType = EnumRunQueryType.topRunsPage,
  }) async {
    final List<dynamic> runs = <dynamic>[];

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
      final EventModel eventItem = G0<TableModel>().eventsTableHelper.fromMap(results[i]);
      final KennelsModel kennelItem = G0<TableModel>().kennelsTableHelper.fromMap(results[i]);

      num dist;
      if ((results[i]['latitude'] != null) && (results[i]['longitude'] != null)) {
        dist = Geolocator.distanceBetween(
          G0<DeviceInfo>().deviceLat,
          G0<DeviceInfo>().deviceLon,
          results[i]['latitude'] + .0,
          results[i]['longitude'] + .0,
        );
      } else {
        dist = Geolocator.distanceBetween(
          G0<DeviceInfo>().deviceLat,
          G0<DeviceInfo>().deviceLon,
          kennelItem.kennelLatitude + .0,
          kennelItem.kennelLongitude + .0,
        );
      }

      final RunDetailsQueryExtensions extensionsItem = RunDetailsQueryExtensions.fromMap(results[i], eventItem.eventStartDatetime);
      extensionsItem.distToEvent = dist;

      String paymentLinkUrl = '';

      if (((eventItem.eventPaymentUrl ?? '') != '') && ((eventItem.eventPaymentUrlExpires == null) || (eventItem.eventPaymentUrlExpires.isAfter(DateTime.now())))) {
        paymentLinkUrl = eventItem.eventPaymentUrl;
      } else if (((kennelItem.kennelPaymentUrl ?? '') != '') && ((kennelItem.kennelPaymentUrlExpires == null) || (kennelItem.kennelPaymentUrlExpires.isAfter(DateTime.now())))) {
        paymentLinkUrl = kennelItem.kennelPaymentUrl;
      }

      // final num julianNow = results[i]['nowJulian'];
      // final num eventJulian = results[i]['eventJulian'];

      //print('Julian now = $julianNow, Event julian = $eventJulian, EventName = ${eventItem.eventName}');

      num meters = 0;
      final int userDistPrefs = getIntPref(IntPrefsEnum.hasherPreferences) & hasherPref_distanceForAutoDisplay;

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

      // if the user has set their preferences to miles or
      // the user has set their preferences to "auto" and the
      // distance preference associated with the kennel is miles
      // then convert our range for runs from meters to miles.
      if (((userDistPrefs & hasherPref_distanceMeasuredIn) == 3) || (((userDistPrefs & hasherPref_distanceMeasuredIn) == 0) && (extensionsItem.distanceUnitsPref == 3))) {
        meters = meters * MILES_TO_METERS / 1000; // this calculation is correct!
      }

      if (((results[i]['latitude'] != null) && (results[i]['longitude'] != null)) && (extensionsItem.distToEvent < meters)) {
        // if the run is close, it's a class 1 run
        extensionsItem.runClassification = 1;
      } else if (extensionsItem.following == 1) {
        // if user is following a Kennel, it's a class 2 run
        extensionsItem.runClassification = 2;
      } else {
        // otherwise it's a class 3 run
        extensionsItem.runClassification = 3;
      }

      if ((searchAllRuns == true) || (extensionsItem.following >= 1) || ((extensionsItem.following == 0) && (dist < meters))) {
        final RunDetailsAggregate item = RunDetailsAggregate(event: eventItem, kennel: kennelItem, extensions: extensionsItem, paymentUrl: paymentLinkUrl);
        runs.add(item);
      }
    }
    return runs;
  }

  static Future<List<Map<String, dynamic>>> queryRuns(EnumRunQueryType queryType, EnumRunQueryContext queryContext, {String kennelId, bool searchAllRuns = true, String eventId}) async {
    String hkmTable;
    String hemTable;
    String paymentsTable;

    switch (queryContext) {
      case EnumRunQueryContext.user:
        hkmTable = G0<TableModel>().hasherKennelMapTableHelper.getTableName(AppDomainType.user);
        hemTable = G0<TableModel>().hasherEventMapTableHelper.getTableName(AppDomainType.user);
        paymentsTable = G0<TableModel>().paymentsTableHelper.getTableName(AppDomainType.user);
        break;
      case EnumRunQueryContext.kennelAdmin:
        hkmTable = G0<TableModel>().hasherKennelMapTableHelper.getTableName(AppDomainType.kennel);
        //hemTable = G0<TableModel>().hasherEventMapTableHelper.getTableName(AppDomainType.kennel);
        //paymentsTable = G0<TableModel>().paymentsTableHelper.getTableName(AppDomainType.kennel);
        break;
      case EnumRunQueryContext.eventAdmin:
        hkmTable = G0<TableModel>().hasherKennelMapTableHelper.getTableName(AppDomainType.event);
        hemTable = G0<TableModel>().hasherEventMapTableHelper.getTableName(AppDomainType.event);
        paymentsTable = G0<TableModel>().paymentsTableHelper.getTableName(AppDomainType.event);
        break;
    }

    final String userId = getStringPref(StringPrefsEnum.userId);

    String queryBase = '';

    if (queryContext == EnumRunQueryContext.kennelAdmin) {
      queryBase = ''' 
        SELECT  
          evt.*,
          k.*,

          case when evt.${G0<TableModel>().eventsTableHelper.colUseFbLatLon} = 0 then evt.${G0<TableModel>().eventsTableHelper.colHcLatitude} else evt.${G0<TableModel>().eventsTableHelper.colFbLatitude} end as latitude,
          case when evt.${G0<TableModel>().eventsTableHelper.colUseFbLatLon} = 0 then evt.${G0<TableModel>().eventsTableHelper.colHcLongitude} else evt.${G0<TableModel>().eventsTableHelper.colFbLongitude} end as longitude,
          case when ((evt.${G0<TableModel>().eventsTableHelper.colUseFbLatLon} = 0 AND evt.${G0<TableModel>().eventsTableHelper.colHcLongitude} IS NOT NULL) OR ((evt.${G0<TableModel>().eventsTableHelper.colUseFbLatLon} = 1 AND evt.${G0<TableModel>().eventsTableHelper.colFbLatitude} IS NOT NULL))) THEN 1 ELSE 0 END as isMapAndDistanceValid,

          coalesce(hkm.appAccessFlags,0) as appAccessFlags,
          coalesce(hkm.following,0) as following,
          0 as rsvpState,
          0 as attendenceState,
          0 as isPaid,
          0 as isHare,
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
          ''';
    } else {
      queryBase = ''' 
      
        SELECT  
          evt.*,
          k.*,

          case when evt.${G0<TableModel>().eventsTableHelper.colUseFbLatLon} = 0 then evt.${G0<TableModel>().eventsTableHelper.colHcLatitude} else evt.${G0<TableModel>().eventsTableHelper.colFbLatitude} end as latitude,
          case when evt.${G0<TableModel>().eventsTableHelper.colUseFbLatLon} = 0 then evt.${G0<TableModel>().eventsTableHelper.colHcLongitude} else evt.${G0<TableModel>().eventsTableHelper.colFbLongitude} end as longitude,
          case when ((evt.${G0<TableModel>().eventsTableHelper.colUseFbLatLon} = 0 AND evt.${G0<TableModel>().eventsTableHelper.colHcLongitude} IS NOT NULL) OR ((evt.${G0<TableModel>().eventsTableHelper.colUseFbLatLon} = 1 AND evt.${G0<TableModel>().eventsTableHelper.colFbLatitude} IS NOT NULL))) THEN 1 ELSE 0 END as isMapAndDistanceValid,

          coalesce(hkm.appAccessFlags,0) as appAccessFlags,
          coalesce(hkm.following,0) as following,
          coalesce(hem.rsvpState,0) as rsvpState,
          coalesce(hem.${G0<TableModel>().hasherEventMapTableHelper.colAttendenceState},0) as attendenceState,
          CASE WHEN coalesce(pay.paymentType,0) >= 2 THEN 1 ELSE 0 END as isPaid,
          coalesce(hem.isHare,0) as isHare,
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
            WHERE evt.${G0<TableModel>().eventsTableHelper.colEventStartDatetime} > datetime('now','localtime','-4 hours') and evt.${G0<TableModel>().eventsTableHelper.colIsVisible} = 1
            AND coalesce(hkm.following,0) != 2
            AND (
                  "${searchAllRuns.toString()}" == "true"
                  OR
                  (coalesce(hkm.following,0) <= 1) 
                  OR 
                  (coalesce(hem.rsvpState,0) >= 2)
                )
            ORDER BY evt.${G0<TableModel>().eventsTableHelper.colEventStartDatetime}, evt.${G0<TableModel>().eventsTableHelper.colEventNumber}
          ''';

    final String whereClauseForKennelDetailsPage = '''
            WHERE evt.${G0<TableModel>().eventsTableHelper.colEventStartDatetime} > datetime('now','localtime','-4 hours') and evt.${G0<TableModel>().eventsTableHelper.colIsVisible} = 1
            AND evt.${G0<TableModel>().eventsTableHelper.colKennelId} = "$kennelId"
            ORDER BY evt.${G0<TableModel>().eventsTableHelper.colEventStartDatetime}, evt.${G0<TableModel>().eventsTableHelper.colEventNumber}
            LIMIT 10
          ''';

    final String whereClauseForSingleRun = '''
            WHERE evt.${G0<TableModel>().eventsTableHelper.colEventId} = "$eventId"
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
}
