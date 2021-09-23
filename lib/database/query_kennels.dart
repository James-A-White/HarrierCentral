// @dart=2.11
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
    this.searchText,
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
  final String searchText;

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
      searchText: map['searchText'],
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
}

enum EnumKennelQueryType { topKennelPage, singleKennel }
enum EnumKennelQueryContext { user, kennelAdmin }

class QueryKennels {
  // it is important to have the beginning and end of the search field have a space
  // character to ensure that searches run properly.

  // note: the tilde characters at the beginning and end of the search field ensure
  // that the kennelName is searchable and whatever is at the end of the search field
  // is also searchable
  static String searchField = '''
               lower(
               "~ " || k.${G0<TableModel>().kennelsTableHelper.colKennelName} 
            || " " || k.${G0<TableModel>().kennelsTableHelper.colKennelShortName} 
            || " " || c.${G0<TableModel>().citiesTableHelper.colCityName} 
            || " " || r.${G0<TableModel>().regionsTableHelper.colRegionName} 
            || " " || n.${G0<TableModel>().countriesTableHelper.colCountryName} 
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
          as searchText
          ''';

  static List<KennelListAggregate> doFilter(String searchText, List<KennelListAggregate> allKennels) {
    List<KennelListAggregate> filteredKennels = <KennelListAggregate>[];
    if (allKennels != null) {
      filteredKennels.addAll(allKennels);

      // allow for comma separated search lists that act to narrow search results (i.e. logical AND)
      if ((searchText != null) && (searchText.isNotEmpty)) {
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

          //print('filtered at: ${DateTime.now().millisecondsSinceEpoch}');

          filteredKennels = filteredKennels.where((KennelListAggregate a) {
            for (String orItem in orItems) {
              if (orItem.trim().isEmpty) {
                continue;
              }
              orItem = ' ' + orItem.trim().toLowerCase();
              if (a.extensions.searchText.toLowerCase().contains(orItem)) {
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
          hkm.hkmId, 
          hkm.kennelNotificationPreference,
          hkm.kennelEmailAlertPreference,
          COALESCE(hkm.following,0) as following,
          COALESCE(hkm.appAccessFlags,0) as appAccessFlags,
          c.cityName || ', ' || CASE WHEN n.showRegion = 1 THEN r.regionName || ', ' ELSE '' END || n.countryName as location,
          (SELECT min(eventStartDatetime) from narrowEvents e where e.kennelId = k.kennelId and e.eventStartDatetime >= datetime('now','localtime') ) as nextRunDate,
          (SELECT max(eventStartDatetime) from narrowEvents e where e.kennelId = k.kennelId and e.eventStartDatetime <= datetime('now','localtime') ) as lastRunDate,
          n.digitsAfterDecimal,
          n.currencySymbol,
          COALESCE(k.DistancePreference,n.DistancePreference,0) as distanceUnitsPref,
          coalesce(k.${G0<TableModel>().kennelsTableHelper.colKennelLatitude},c.${G0<TableModel>().citiesTableHelper.colLatitude},$DEFAULT_LATITUDE) as cityLat,
          coalesce(k.${G0<TableModel>().kennelsTableHelper.colKennelLongitude},c.${G0<TableModel>().citiesTableHelper.colLongitude},$DEFAULT_LONGITUDE) as cityLon,
          $searchField
          FROM ${G0<TableModel>().kennelsTableHelper.getTableName(AppDomainType.user)} k
          INNER JOIN ${G0<TableModel>().citiesTableHelper.getTableName(AppDomainType.user)} c on c.cityId = k.cityId
          INNER JOIN ${G0<TableModel>().regionsTableHelper.getTableName(AppDomainType.user)} r on r.regionId = k.regionId
          INNER JOIN ${G0<TableModel>().countriesTableHelper.getTableName(AppDomainType.user)} n on n.countryId = k.countryId
          INNER JOIN ${G0<TableModel>().hashersTableHelper.getTableName(AppDomainType.user)} h on h.hasherId = "$hasherId"
          LEFT OUTER JOIN $hkmTable hkm on hkm.kennelId = k.kennelId and hkm.${G0<TableModel>().hasherKennelMapTableHelper.colUserId} = "$hasherId"
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
}
