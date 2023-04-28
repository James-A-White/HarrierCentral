// @dart=2.11
import 'package:geolocator/geolocator.dart';
import 'package:harrier_central/imports.dart';

class KennelListQueryExtenstions {
  KennelListQueryExtenstions({
    this.location,
    this.distToKennel,
    this.nextRunDate,
    this.lastRunDate,
    this.digitsAfterDecimal,
    this.currencySymbol,
    this.distanceUnitsPref,
    this.cityLat,
    this.cityLon,
    this.cityName,
    this.regionName,
    this.regionAbbreviation,
    this.countryName,
    this.searchKennelsText,
  });

  final String location;
  num distToKennel;
  final String nextRunDate;
  final String lastRunDate;
  final int digitsAfterDecimal;
  final String currencySymbol;
  final int distanceUnitsPref;
  num cityLat;
  num cityLon;
  String cityName;
  String regionName;
  String regionAbbreviation;
  String countryName;
  final String searchKennelsText;

  int followingRequested;
  int notificationsRequested;
  int emailAlertRequested;

  static KennelListQueryExtenstions fromMap(Map<String, dynamic> map) {
    final KennelListQueryExtenstions item = KennelListQueryExtenstions(
      location: map['location'],
      distToKennel: map['distToKennel'],
      nextRunDate: map['nextRunDate'],
      lastRunDate: map['lastRunDate'],
      digitsAfterDecimal: map['digitsAfterDecimal'],
      currencySymbol: map['currencySymbol'],
      distanceUnitsPref: map['distanceUnitsPref'],
      cityLat: map['cityLat'],
      cityLon: map['cityLon'],
      cityName: map['cityName'],
      regionName: map['regionName'],
      regionAbbreviation: map['regionAbbreviation'],
      countryName: map['countryName'],
      searchKennelsText: map['searchKennelsText'],
    );
    return item;
  }
}

class KennelListAggregate {
  KennelListAggregate({
    this.kennel,
    this.hkm,
    this.extensions,
    this.isHomeKennel,
  });

  final KennelsModel kennel;
  final HasherKennelMapModel hkm;
  final KennelListQueryExtenstions extensions;
  bool isHomeKennel;

  @override
  String toString() {
    return kennel?.kennelName ?? 'No kennel name';
  }
}

enum EnumKennelQueryType { topKennelPage, singleKennel }

enum EnumKennelQueryContext { user, kennelAdmin }

class QueryKennels {
  // the variable below is there to suppress a warning about defining classes with only static members
  int unusedVariableToSuppressWarning;
  // it is important to have the beginning and end of the search field have a space
  // character to ensure that searches run properly.

// || " " || coalesce(r.${G0<TableModel>().regionsTableHelper.colRegionAbbreviation},"")

  // note: the tilde characters at the beginning and end of the search field ensure
  // that the kennelName is searchable and whatever is at the end of the search field
  // is also searchable
  static String searchKennelsField = '''
               lower(
               "~ " || k.${G0<TableModel>().kennelsTableHelper.colKennelName} 
            || " " || k.${G0<TableModel>().kennelsTableHelper.colKennelShortName} 
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
              when n.${G0<TableModel>().countriesTableHelper.colContinentCode} = "EU" then "europe" 
              when n.${G0<TableModel>().countriesTableHelper.colContinentCode} = "AF" then "africa" 
              when n.${G0<TableModel>().countriesTableHelper.colContinentCode} = "AS" then "asia" 
              when n.${G0<TableModel>().countriesTableHelper.colContinentCode} = "NA" then "north america" 
              when n.${G0<TableModel>().countriesTableHelper.colContinentCode} = "SA" then "south america" 
              when n.${G0<TableModel>().countriesTableHelper.colContinentCode} = "OC" then "oceania" 
              when n.${G0<TableModel>().countriesTableHelper.colContinentCode} = "AN" then "antarctica" 
              else "" 
              end || " ~" 
            )
          as searchKennelsText
          ''';

  static List<KennelListAggregate> doFilter(String searchText, List<KennelListAggregate> allKennels) {
    List<KennelListAggregate> filteredKennels = <KennelListAggregate>[];
    if (allKennels != null) {
      filteredKennels.addAll(allKennels);

      // allow for comma separated search lists that act to narrow search results (i.e. logical AND)
      if ((searchText != null) && (searchText.isNotEmpty)) {
        // searchText = '$searchText , ${removeDiacritics(searchText)}';
        final List<String> searchItems = searchText.trim().toLowerCase().split(',');
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

          filteredKennels = filteredKennels.where((KennelListAggregate a) {
            for (String orItem in orItems) {
              if (orItem.trim().isEmpty) {
                continue;
              }
              orItem = ' ${orItem.trim().toLowerCase()}';
              if ((a.extensions.searchKennelsText.toLowerCase().contains(orItem)) || (removeDiacritics(a.extensions.searchKennelsText.toLowerCase())).contains(orItem)) {
                return !negate;
              }
            }
            return negate;
          }).toList();
        }
      }
    }
    return filteredKennels;
  }

  static Future<KennelListAggregate> getSingleKennel(String kennelId) async {
    bool isHomeKennel = false;
    if (kennelId == getStringPref(StringPrefsEnum.homeKennelId)) {
      isHomeKennel = true;
    }

    KennelListAggregate kennel;
    final String hasherId = getStringPref(StringPrefsEnum.userId);
    final List<Map<String, dynamic>> results = await QueryKennels.queryKennels(EnumKennelQueryType.singleKennel, EnumKennelQueryContext.user, hasherId: hasherId, kennelId: kennelId);

    if (results.isNotEmpty) {
      final num dist = Geolocator.distanceBetween(G0<DeviceInfo>().deviceLat, G0<DeviceInfo>().deviceLon, results[0]['cityLat'] + .0, results[0]['cityLon'] + .0);

      final KennelsModel kennelItem = G0<TableModel>().kennelsTableHelper.fromMap(results[0]);
      final HasherKennelMapModel hkmItem = G0<TableModel>().hasherKennelMapTableHelper.fromMap(results[0]);
      final KennelListQueryExtenstions extensionsItem = KennelListQueryExtenstions.fromMap(results[0]);
      extensionsItem.distToKennel = dist;
      extensionsItem.followingRequested = -1;
      extensionsItem.notificationsRequested = -1;
      extensionsItem.emailAlertRequested = -1;

      kennel = KennelListAggregate(kennel: kennelItem, extensions: extensionsItem, hkm: hkmItem, isHomeKennel: isHomeKennel);
    }
    return kennel;
  }

  static Future<List<Map<String, dynamic>>> queryKennels(EnumKennelQueryType queryType, EnumKennelQueryContext queryContext, {String hasherId, String kennelId}) async {
    String hkmTable;

    switch (queryContext) {
      case EnumKennelQueryContext.user:
        hkmTable = G0<TableModel>().hasherKennelMapTableHelper.getTableName(AppDomainType.user);
        break;
      case EnumKennelQueryContext.kennelAdmin:
        hkmTable = G0<TableModel>().hasherKennelMapTableHelper.getTableName(AppDomainType.kennel);
        break;
    }

    final String queryBase = ''' 
      
        SELECT  
          k.*, 
          hkm.${G0<TableModel>().hasherKennelMapTableHelper.colHkmId}, 
          hkm.${G0<TableModel>().hasherKennelMapTableHelper.colKennelCredit}, 
          hkm.${G0<TableModel>().hasherKennelMapTableHelper.colHcHaringCount}, 
          hkm.${G0<TableModel>().hasherKennelMapTableHelper.colHcTotalRunCount}, 
          hkm.${G0<TableModel>().hasherKennelMapTableHelper.colHistoricalHaringCount}, 
          hkm.${G0<TableModel>().hasherKennelMapTableHelper.colHistoricalTotalRunCount}, 
          hkm.${G0<TableModel>().hasherKennelMapTableHelper.colHistoricalCountIsEstimate}, 
          hkm.${G0<TableModel>().hasherKennelMapTableHelper.colDateOfLastRun}, 
          hkm.${G0<TableModel>().hasherKennelMapTableHelper.colKennelNotificationPreference},
          hkm.${G0<TableModel>().hasherKennelMapTableHelper.colKennelEmailAlertPreference},
          COALESCE(hkm.${G0<TableModel>().hasherKennelMapTableHelper.colFollowing},0) as following,
          COALESCE(hkm.${G0<TableModel>().hasherKennelMapTableHelper.colAppAccessFlags},0) as appAccessFlags,
          c.${G0<TableModel>().citiesTableHelper.colCityName} || ', ' || CASE WHEN n.${G0<TableModel>().countriesTableHelper.colShowRegion} = 1 THEN r.${G0<TableModel>().regionsTableHelper.colRegionName} || ', ' ELSE '' END || n.${G0<TableModel>().countriesTableHelper.colCountryName} as location,
          c.${G0<TableModel>().citiesTableHelper.colCityName} as cityName,
          r.${G0<TableModel>().regionsTableHelper.colRegionName} as regionName,
          r.${G0<TableModel>().regionsTableHelper.colRegionAbbreviation} as regionAbbreviation,
          n.${G0<TableModel>().countriesTableHelper.colCountryName} as countryName,
          (SELECT min(${G0<TableModel>().eventsTableHelper.colEventStartDatetime}) from narrowEvents e where e.${G0<TableModel>().eventsTableHelper.colKennelId} = k.${G0<TableModel>().kennelsTableHelper.colKennelId} and datetime(e.${G0<TableModel>().eventsTableHelper.colEventStartDatetime}) >= datetime('now') and e.${G0<TableModel>().eventsTableHelper.colIsVisible} != 0 ) as nextRunDate,
          (SELECT max(${G0<TableModel>().eventsTableHelper.colEventStartDatetime}) from narrowEvents e where e.${G0<TableModel>().eventsTableHelper.colKennelId} = k.${G0<TableModel>().kennelsTableHelper.colKennelId} and datetime(e.${G0<TableModel>().eventsTableHelper.colEventStartDatetime}) <= datetime('now') and e.${G0<TableModel>().eventsTableHelper.colIsVisible} != 0 ) as lastRunDate,
          COALESCE(k.${G0<TableModel>().kennelsTableHelper.colDigitsAfterDecimal},n.${G0<TableModel>().countriesTableHelper.colDigitsAfterDecimal}) as ${G0<TableModel>().countriesTableHelper.colDigitsAfterDecimal},
          COALESCE(k.${G0<TableModel>().kennelsTableHelper.colCurrencySymbol},n.${G0<TableModel>().countriesTableHelper.colCurrencySymbol}) as ${G0<TableModel>().countriesTableHelper.colCurrencySymbol},
          COALESCE(k.${G0<TableModel>().kennelsTableHelper.colDistancePreference},n.${G0<TableModel>().countriesTableHelper.colDistancePreference},0) as distanceUnitsPref,
          COALESCE(k.${G0<TableModel>().kennelsTableHelper.colKennelLatitude},c.${G0<TableModel>().citiesTableHelper.colLatitude},$DEFAULT_LATITUDE) as cityLat,
          COALESCE(k.${G0<TableModel>().kennelsTableHelper.colKennelLongitude},c.${G0<TableModel>().citiesTableHelper.colLongitude},$DEFAULT_LONGITUDE) as cityLon,
          $searchKennelsField
          FROM ${G0<TableModel>().kennelsTableHelper.getTableName(AppDomainType.user)} k
          INNER JOIN ${G0<TableModel>().citiesTableHelper.getTableName(AppDomainType.user)} c on c.${G0<TableModel>().citiesTableHelper.colCityId} = k.${G0<TableModel>().kennelsTableHelper.colCityId}
          INNER JOIN ${G0<TableModel>().regionsTableHelper.getTableName(AppDomainType.user)} r on r.${G0<TableModel>().regionsTableHelper.colRegionId} = k.${G0<TableModel>().kennelsTableHelper.colRegionId}
          INNER JOIN ${G0<TableModel>().countriesTableHelper.getTableName(AppDomainType.user)} n on n.${G0<TableModel>().countriesTableHelper.colCountryId} = k.${G0<TableModel>().kennelsTableHelper.colCountryId}
          INNER JOIN ${G0<TableModel>().hashersTableHelper.getTableName(AppDomainType.user)} h on h.hasherId = "$hasherId"
          LEFT OUTER JOIN $hkmTable hkm on hkm.${G0<TableModel>().hasherKennelMapTableHelper.colKennelId} = k.${G0<TableModel>().kennelsTableHelper.colKennelId} and hkm.${G0<TableModel>().hasherKennelMapTableHelper.colUserId} = "$hasherId"
          ''';

    final String whereClauseForSingleKenenel = '''
            WHERE k.${G0<TableModel>().kennelsTableHelper.colKennelId} = "$kennelId"
          ''';

    String query = queryBase;
    if (queryType == EnumKennelQueryType.singleKennel) {
      query = query + whereClauseForSingleKenenel;
    } else if (queryType == EnumKennelQueryType.topKennelPage) {
      // no where clause required
    } else {
      assert(false);
    }

    return G0<Database>().rawQuery(query);
  }

  static Future<List<Map<String, dynamic>>> queryKennelGallery(String kennelId) async {
    final String query = ''' 
      
        SELECT  
          k.${G0<TableModel>().kennelsTableHelper.colKennelId},
          evt.${G0<TableModel>().eventsTableHelper.colEventImage},
          evt.${G0<TableModel>().eventsTableHelper.colEventNumber},
          evt.${G0<TableModel>().eventsTableHelper.colEventName},          
          evt.${G0<TableModel>().eventsTableHelper.colEventId},
          evt.${G0<TableModel>().eventsTableHelper.colEventStartDatetime}
          FROM ${G0<TableModel>().kennelsTableHelper.getTableName(AppDomainType.user)} k
          INNER JOIN ${G0<TableModel>().eventsTableHelper.getTableName(AppDomainType.user)} evt
          ON evt.${G0<TableModel>().eventsTableHelper.colKennelId} = k.${G0<TableModel>().kennelsTableHelper.colKennelId}
          WHERE k.${G0<TableModel>().kennelsTableHelper.colKennelId} = "$kennelId"
          ORDER BY evt.${G0<TableModel>().eventsTableHelper.colEventStartDatetime} desc
          ''';

    return G0<Database>().rawQuery(query);
  }

  static Future<List<Map<String, dynamic>>> queryKennelDetails() async {
    String searchKennelsField = '''
               "~ "  || coalesce(k.${G0<TableModel>().kennelsTableHelper.colKennelShortName},"") 
            || " " || coalesce(k.${G0<TableModel>().kennelsTableHelper.colKennelName},"")   
            
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
              when n.${G0<TableModel>().countriesTableHelper.colContinentCode} = "EU" then "europe" 
              when n.${G0<TableModel>().countriesTableHelper.colContinentCode} = "AF" then "africa" 
              when n.${G0<TableModel>().countriesTableHelper.colContinentCode} = "AS" then "asia" 
              when n.${G0<TableModel>().countriesTableHelper.colContinentCode} = "NA" then "north america" 
              when n.${G0<TableModel>().countriesTableHelper.colContinentCode} = "SA" then "south america" 
              when n.${G0<TableModel>().countriesTableHelper.colContinentCode} = "OC" then "oceania" 
              when n.${G0<TableModel>().countriesTableHelper.colContinentCode} = "AN" then "antarctica" 
              else "" 
              end || " ~" 
          as searchText
          ''';

    final String query = ''' 
      
        SELECT  
          k.${G0<TableModel>().kennelsTableHelper.colKennelId},
          k.${G0<TableModel>().kennelsTableHelper.colKennelName},
          k.${G0<TableModel>().kennelsTableHelper.colKennelShortName},
          $searchKennelsField
          FROM ${G0<TableModel>().kennelsTableHelper.getTableName(AppDomainType.user)} k
          INNER JOIN ${G0<TableModel>().citiesTableHelper.getTableName(AppDomainType.user)} c
          ON k.${G0<TableModel>().kennelsTableHelper.colCityId} = c.${G0<TableModel>().citiesTableHelper.colCityId}
          INNER JOIN ${G0<TableModel>().regionsTableHelper.getTableName(AppDomainType.user)} r
          ON c.${G0<TableModel>().citiesTableHelper.colRegionId} = r.${G0<TableModel>().regionsTableHelper.colRegionId}
          INNER JOIN ${G0<TableModel>().countriesTableHelper.getTableName(AppDomainType.user)} n
          ON r.${G0<TableModel>().regionsTableHelper.colCountryId} = n.${G0<TableModel>().countriesTableHelper.colCountryId}
          ''';

    return G0<Database>().rawQuery(query);
  }
}
