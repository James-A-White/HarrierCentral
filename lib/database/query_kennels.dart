
import 'package:harrier_central/util/globals.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/data/hc3_services/kennels_service.dart';
import 'package:harrier_central/data/hc3_services/hasher_kennel_map_service.dart';
import 'package:harrier_central/database/tables.dart';

class KennelListQueryExtenstions {
  KennelListQueryExtenstions({
    this.location,
    this.distToKennel,
    this.nextRunDate,
    this.lastRunDate,
    this.digitsAfterDecimal,
    this.currencySymbol,
    this.isHomeKennel,
    this.distancePreference,
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
  int isHomeKennel;
  int distancePreference;
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
        isHomeKennel: map['isHomeKennel'],
        distancePreference: map['distancePreference'],
        cityLat: map['cityLat'],
        cityLon: map['cityLon'],
        searchText: map['searchText']);
    return item;
  }
}

class KennelListAggregate {
  KennelListAggregate({
    this.kennel,
    this.hkm,
    this.extensions,
  });

  final KennelsModel kennel;
  final HasherKennelMapModel hkm;
  final KennelListQueryExtenstions extensions;
}

enum EnumKennelQueryType { topKennelPage, singleKennel }
enum EnumKennelQueryContext { user, kennelAdmin }

class QueryKennels {
  // it is important to have the beginning and end of the search field have a space
  // character to ensure that searches run properly.

  static String searchField = '''
               lower(k.${kennelsTableHelper.colKennelName} 
            || " " || k.${kennelsTableHelper.colKennelShortName} 
            || " " || c.${citiesTableHelper.colCityName} 
            || " " || r.${regionsTableHelper.colRegionName} 
            || " " || n.${countriesTableHelper.colCountryName} 
            || " " || 
              case 
              when n.${countriesTableHelper.colContinentCode} = "EU" then "europe" 
              when n.${countriesTableHelper.colContinentCode} = "AF" then "africa" 
              when n.${countriesTableHelper.colContinentCode} = "AS" then "asia" 
              when n.${countriesTableHelper.colContinentCode} = "NA" then "north america" 
              when n.${countriesTableHelper.colContinentCode} = "SA" then "south america" 
              when n.${countriesTableHelper.colContinentCode} = "OC" then "oceania" 
              when n.${countriesTableHelper.colContinentCode} = "AN" then "antarctica" 
              else "" 
              end
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
        hkmTable = hasherKennelMapTableHelper.getTableName(TableType.hkmUser);
        break;
      case EnumKennelQueryContext.kennelAdmin:
        hkmTable = hasherKennelMapTableHelper.getTableName(TableType.hkmKennelAdmin);
        break;
    }

    final String queryBase = ''' 
      
        SELECT  
          k.*, 
          hkm.hkmId, 
          hkm.kennelNotificationPreference,
          hkm.kennelEmailAlertPreference,
          COALESCE(hkm.following,0) as following,
          COALESCE(hkm.mismanagementRoleFlags,0) as mismanagementRoleFlags,
          c.cityName || ', ' || CASE WHEN n.showRegion = 1 THEN r.regionName || ', ' ELSE '' END || n.countryName as location,
          (SELECT min(eventStartDatetime) from narrowEvents e where e.kennelId = k.kennelId and e.eventStartDatetime >= datetime('now','localtime') ) as nextRunDate,
          (SELECT max(eventStartDatetime) from narrowEvents e where e.kennelId = k.kennelId and e.eventStartDatetime <= datetime('now','localtime') ) as lastRunDate,
          n.digitsAfterDecimal,
          n.currencySymbol,
          coalesce(k.${kennelsTableHelper.colKennelLatitude},c.${citiesTableHelper.colLatitude},$DEFAULT_LATITUDE) as cityLat,
          coalesce(k.${kennelsTableHelper.colKennelLongitude},c.${citiesTableHelper.colLongitude},$DEFAULT_LONGITUDE) as cityLon,
          CASE WHEN ((h.homeKennelId IS NOT NULL) AND (h.homeKennelId = k.kennelId)) then 1 else 0 end as isHomeKennel,
          CASE WHEN h.preferences & 0x00000003 = 0 THEN COALESCE(k.distancePreference,n.distancePreference,0) ELSE (h.preferences & 0x00000003) - 2 END as distancePreference,
          $searchField
          FROM ${kennelsTableHelper.tableName} k
          INNER JOIN ${citiesTableHelper.tableName} c on c.cityId = k.cityId
          INNER JOIN ${regionsTableHelper.tableName} r on r.regionId = k.regionId
          INNER JOIN ${countriesTableHelper.tableName} n on n.countryId = k.countryId
          INNER JOIN ${hashersTableHelper.tableName} h on h.hasherId = "$hasherId"
          LEFT OUTER JOIN $hkmTable hkm on hkm.kennelId = k.kennelId and hkm.${hasherKennelMapTableHelper.colUserId} = "$hasherId"
          ''';

    final String whereClauseForSingleKenenel = '''
            WHERE k.${kennelsTableHelper.colKennelId} = "$kennelId"
          ''';

    String query = queryBase;
    if (queryType == EnumKennelQueryType.singleKennel) {
      query = query + whereClauseForSingleKenenel;
    } else if (queryType == EnumKennelQueryType.topKennelPage) {
      // no where clause required
    } else {
      assert(false);
    }

    return internalSqlDb.rawQuery(query);
  }
}
