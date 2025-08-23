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
    this.isKennelMember,
    this.originalProfilePhoto,
    this.originalDisplayName,
  });

  final String? location;
  double? distToKennel;
  final String? nextRunDate;
  final String? lastRunDate;
  final int? digitsAfterDecimal;
  final String? currencySymbol;
  final int? distanceUnitsPref;
  double? cityLat;
  double? cityLon;
  String? cityName;
  String? regionName;
  String? regionAbbreviation;
  String? countryName;
  final String? searchKennelsText;
  int? isKennelMember;
  int? followingRequested;
  int? notificationsRequested;
  int? emailAlertRequested;
  String? originalProfilePhoto;
  String? originalDisplayName;

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
      isKennelMember: map['isKennelMember'],
      originalProfilePhoto: map['originalProfilePhoto'],
      originalDisplayName: map['originalDisplayName'],
    );
    return item;
  }
}

class KennelListAggregate {
  KennelListAggregate({
    required this.kennel,
    required this.extensions,
    this.hkm,
    this.isHomeKennel = false,
  });

  final KennelsModel kennel;
  final KennelListQueryExtenstions extensions;
  HasherKennelMapModel? hkm;
  bool isHomeKennel;

  @override
  String toString() {
    return kennel.kennelName;
  }
}

enum EnumKennelQueryType { topKennelPage, singleKennel }

enum EnumKennelQueryContext { user, kennelAdmin }

class QueryKennels {
  // the variable below is there to suppress a warning about defining classes with only static members
  int? unusedVariableToSuppressWarning;
  // it is important to have the beginning and end of the search field have a space
  // character to ensure that searches run properly.

  // || " " || coalesce(r.${tableModel.regionsTableHelper.colRegionAbbreviation},"")

  // note: the tilde characters at the beginning and end of the search field ensure
  // that the kennelName is searchable and whatever is at the end of the search field
  // is also searchable
  static String searchKennelsField = '''
               lower(
               "~ " || k.${tableModel.kennelsTableHelper.colKennelName} 
            || " " || k.${tableModel.kennelsTableHelper.colKennelShortName} 
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
              when n.${tableModel.countriesTableHelper.colContinentCode} = "EU" then "europe" 
              when n.${tableModel.countriesTableHelper.colContinentCode} = "AF" then "africa" 
              when n.${tableModel.countriesTableHelper.colContinentCode} = "AS" then "asia" 
              when n.${tableModel.countriesTableHelper.colContinentCode} = "NA" then "north america" 
              when n.${tableModel.countriesTableHelper.colContinentCode} = "SA" then "south america" 
              when n.${tableModel.countriesTableHelper.colContinentCode} = "OC" then "oceania" 
              when n.${tableModel.countriesTableHelper.colContinentCode} = "AN" then "antarctica" 
              else "" 
              end || " ~" 
            )
          as searchKennelsText
          ''';

  // TODO(James): Replace this with improved search from Leaderboards
  static List<KennelListAggregate> doFilter(
    String searchText,
    List<KennelListAggregate> allKennels,
  ) {
    List<KennelListAggregate> filteredKennels = <KennelListAggregate>[];
    //if (allKennels != null) {
    filteredKennels.addAll(allKennels);

    // allow for comma separated search lists that act to narrow search results (i.e. logical AND)
    if (searchText.isNotEmpty) {
      // searchText = '$searchText , ${removeDiacritics(searchText)}';
      final List<String> searchItems = searchText.trim().toLowerCase().split(
        ',',
      );
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

        filteredKennels =
            filteredKennels.where((KennelListAggregate a) {
              for (String orItem in orItems) {
                if (orItem.trim().isEmpty) {
                  continue;
                }
                orItem = ' ${orItem.trim().toLowerCase()}';

                if (((a.extensions.searchKennelsText ?? '')
                        .toLowerCase()
                        .contains(orItem)) ||
                    ((removeDiacritics(
                      (a.extensions.searchKennelsText ?? '').toLowerCase(),
                    )).contains(orItem))) {
                  return !negate;
                }
              }
              return negate;
            }).toList();
      }
    }
    //}
    return filteredKennels;
  }

  static Future<KennelListAggregate?> getSingleKennel(String kennelId) async {
    bool isHomeKennel = false;
    if (kennelId.toLowerCase() ==
        getStringPref(StringPrefsEnum.homeKennelId)?.toLowerCase()) {
      isHomeKennel = true;
    }

    KennelListAggregate? kennel;
    final String hasherId = getStringPref(StringPrefsEnum.userId)!;
    final List<Map<String, dynamic>> results = await QueryKennels.queryKennels(
      EnumKennelQueryType.singleKennel,
      EnumKennelQueryContext.user,
      hasherId: hasherId,
      kennelId: kennelId,
    );

    if (results.isNotEmpty) {
      double? dist;

      if ((deviceInfo.deviceLat != null) && (deviceInfo.deviceLon != null)) {
        dist = Geolocator.distanceBetween(
          deviceInfo.deviceLat!,
          deviceInfo.deviceLon!,
          results[0]['cityLat'],
          results[0]['cityLon'],
        );
      }

      final KennelsModel kennelItem = tableModel.kennelsTableHelper.fromMap(
        results[0],
      );
      final HasherKennelMapModel hkmItem = tableModel.hasherKennelMapTableHelper
          .fromMap(results[0]);
      final KennelListQueryExtenstions extensionsItem =
          KennelListQueryExtenstions.fromMap(results[0]);
      extensionsItem.distToKennel = dist;
      extensionsItem.followingRequested = -1;
      extensionsItem.notificationsRequested = -1;
      extensionsItem.emailAlertRequested = -1;

      kennel = KennelListAggregate(
        kennel: kennelItem,
        extensions: extensionsItem,
        hkm: hkmItem,
        isHomeKennel: isHomeKennel,
      );
    }
    return kennel;
  }

  static Future<List<Map<String, dynamic>>> queryKennels(
    EnumKennelQueryType queryType,
    EnumKennelQueryContext queryContext, {
    required String hasherId,
    String? kennelId,
  }) async {
    String hkmTable;

    switch (queryContext) {
      case EnumKennelQueryContext.user:
        hkmTable = tableModel.hasherKennelMapTableHelper.getTableName(
          AppDomainType.user,
        );
        break;
      case EnumKennelQueryContext.kennelAdmin:
        hkmTable = tableModel.hasherKennelMapTableHelper.getTableName(
          AppDomainType.kennel,
        );
        break;
    }

    final String queryBase = '''
      
        SELECT  
          k.*,           
          hkm.${tableModel.hasherKennelMapTableHelper.colHkmId},
          hkm.${tableModel.hasherKennelMapTableHelper.colUserId},
          hkm.${tableModel.hasherKennelMapTableHelper.colFollowing},
          hkm.${tableModel.hasherKennelMapTableHelper.colIsMember},
          hkm.${tableModel.hasherKennelMapTableHelper.colIsHomeKennel},
          hkm.${tableModel.hasherKennelMapTableHelper.colKennelNotificationPreference},
          hkm.${tableModel.hasherKennelMapTableHelper.colKennelEmailAlertPreference},
          hkm.${tableModel.hasherKennelMapTableHelper.colAuthorizedDeviceList},
          hkm.${tableModel.hasherKennelMapTableHelper.colAuthorizedDeviceCount},
          hkm.${tableModel.hasherKennelMapTableHelper.colUserRoleFlags},
          hkm.${tableModel.hasherKennelMapTableHelper.colAppAccessFlags},
          hkm.${tableModel.hasherKennelMapTableHelper.colHcTotalRunCount},
          hkm.${tableModel.hasherKennelMapTableHelper.colHcHaringCount},
          hkm.${tableModel.hasherKennelMapTableHelper.colHistoricalTotalRunCount},
          hkm.${tableModel.hasherKennelMapTableHelper.colHistoricalHaringCount},
          hkm.${tableModel.hasherKennelMapTableHelper.colHistoricalCountIsEstimate},
          hkm.${tableModel.hasherKennelMapTableHelper.colKennelCredit},
          hkm.${tableModel.hasherKennelMapTableHelper.colDiscountAmount},
          hkm.${tableModel.hasherKennelMapTableHelper.colDiscountPercent},
          hkm.${tableModel.hasherKennelMapTableHelper.colDiscountDescription},
          hkm.${tableModel.hasherKennelMapTableHelper.colDateOfLastRun},
          hkm.${tableModel.hasherKennelMapTableHelper.colMembershipExpirationDate},
          hkm.${tableModel.hasherKennelMapTableHelper.colMemberSince},
          hkm.${tableModel.hasherKennelMapTableHelper.colIsKennelFollowing},
          hkm.${tableModel.hasherKennelMapTableHelper.colMismanagementRoles},
          hkm.${tableModel.hasherKennelMapTableHelper.colKennelUserPhoto},
          hkm.${tableModel.hasherKennelMapTableHelper.colKennelHashName},

          h.${tableModel.hashersTableHelper.colPhoto} as originalProfilePhoto,
          h.${tableModel.hashersTableHelper.colDispName} as originalDisplayName,
          case when datetime(coalesce(hkm.${tableModel.hasherKennelMapTableHelper.colMembershipExpirationDate},"2000-01-01")) <= datetime('now') then 0 else 1 end as isKennelMember,
          COALESCE(hkm.${tableModel.hasherKennelMapTableHelper.colFollowing},0) as following,
          COALESCE(hkm.${tableModel.hasherKennelMapTableHelper.colAppAccessFlags},0) as appAccessFlags,
          c.${tableModel.citiesTableHelper.colCityName} || ', ' || CASE WHEN n.${tableModel.countriesTableHelper.colShowRegion} = 1 THEN r.${tableModel.regionsTableHelper.colRegionName} || ', ' ELSE '' END || n.${tableModel.countriesTableHelper.colCountryName} as location,
          c.${tableModel.citiesTableHelper.colCityName} as cityName,
          r.${tableModel.regionsTableHelper.colRegionName} as regionName,
          r.${tableModel.regionsTableHelper.colRegionAbbreviation} as regionAbbreviation,
          n.${tableModel.countriesTableHelper.colCountryName} as countryName,
          (SELECT min(${tableModel.eventsTableHelper.colEventStartDatetime}) from narrowEvents e where e.${tableModel.eventsTableHelper.colKennelId} = k.${tableModel.kennelsTableHelper.colKennelId} and datetime(e.${tableModel.eventsTableHelper.colEventStartDatetime}) >= datetime('now') and e.${tableModel.eventsTableHelper.colIsVisible} != 0 ) as nextRunDate,
          (SELECT max(${tableModel.eventsTableHelper.colEventStartDatetime}) from narrowEvents e where e.${tableModel.eventsTableHelper.colKennelId} = k.${tableModel.kennelsTableHelper.colKennelId} and datetime(e.${tableModel.eventsTableHelper.colEventStartDatetime}) <= datetime('now') and e.${tableModel.eventsTableHelper.colIsVisible} != 0 ) as lastRunDate,
          COALESCE(k.${tableModel.kennelsTableHelper.colDigitsAfterDecimal},n.${tableModel.countriesTableHelper.colDigitsAfterDecimal}) as ${tableModel.countriesTableHelper.colDigitsAfterDecimal},
          COALESCE(k.${tableModel.kennelsTableHelper.colCurrencySymbol},n.${tableModel.countriesTableHelper.colCurrencySymbol}) as ${tableModel.countriesTableHelper.colCurrencySymbol},
          COALESCE(k.${tableModel.kennelsTableHelper.colDistancePreference},n.${tableModel.countriesTableHelper.colDistancePreference},0) as distanceUnitsPref,
          COALESCE(k.${tableModel.kennelsTableHelper.colKennelLatitude},c.${tableModel.citiesTableHelper.colLatitude},$DEFAULT_LATITUDE) as cityLat,
          COALESCE(k.${tableModel.kennelsTableHelper.colKennelLongitude},c.${tableModel.citiesTableHelper.colLongitude},$DEFAULT_LONGITUDE) as cityLon,
          $searchKennelsField
          FROM ${tableModel.kennelsTableHelper.getTableName(AppDomainType.user)} k
          INNER JOIN ${tableModel.citiesTableHelper.getTableName(AppDomainType.user)} c on c.${tableModel.citiesTableHelper.colCityId} = k.${tableModel.kennelsTableHelper.colCityId}
          INNER JOIN ${tableModel.regionsTableHelper.getTableName(AppDomainType.user)} r on r.${tableModel.regionsTableHelper.colRegionId} = k.${tableModel.kennelsTableHelper.colRegionId}
          INNER JOIN ${tableModel.countriesTableHelper.getTableName(AppDomainType.user)} n on n.${tableModel.countriesTableHelper.colCountryId} = k.${tableModel.kennelsTableHelper.colCountryId}
          INNER JOIN ${tableModel.hashersTableHelper.getTableName(AppDomainType.user)} h on h.hasherId = "$hasherId"
          LEFT OUTER JOIN $hkmTable hkm on hkm.${tableModel.hasherKennelMapTableHelper.colKennelId} = k.${tableModel.kennelsTableHelper.colKennelId} and hkm.${tableModel.hasherKennelMapTableHelper.colUserId} = "$hasherId"
          WHERE k.${tableModel.kennelsTableHelper.colRemoved} = 0
          ''';

    final String whereClauseForSingleKenenel =
        kennelId == null
            ? ''
            : '''
            AND k.${tableModel.kennelsTableHelper.colKennelId} = "$kennelId" 
            
          ''';

    String query = queryBase;
    if (queryType == EnumKennelQueryType.singleKennel) {
      query = query + whereClauseForSingleKenenel;
    } else if (queryType == EnumKennelQueryType.topKennelPage) {
      // no where clause required
    } else {
      assert(false);
    }

    return database.rawQuery(query);
  }

  static Future<List<Map<String, dynamic>>> queryKennelGallery(
    String kennelId,
  ) async {
    final String query = '''
      
        SELECT  
          k.${tableModel.kennelsTableHelper.colKennelId},
          evt.${tableModel.eventsTableHelper.colEventImage},
          evt.${tableModel.eventsTableHelper.colEventNumber},
          evt.${tableModel.eventsTableHelper.colEventName},          
          evt.${tableModel.eventsTableHelper.colEventId},
          evt.${tableModel.eventsTableHelper.colEventStartDatetime}
          FROM ${tableModel.kennelsTableHelper.getTableName(AppDomainType.user)} k
          INNER JOIN ${tableModel.eventsTableHelper.getTableName(AppDomainType.user)} evt
          ON evt.${tableModel.eventsTableHelper.colKennelId} = k.${tableModel.kennelsTableHelper.colKennelId}
          WHERE k.${tableModel.kennelsTableHelper.colKennelId} = "$kennelId"
          AND k.${tableModel.kennelsTableHelper.colRemoved} = 0 
          ORDER BY evt.${tableModel.eventsTableHelper.colEventStartDatetime} desc
          ''';

    return database.rawQuery(query);
  }

  static Future<List<Map<String, dynamic>>> queryKennelDetails() async {
    String searchKennelsField = '''
               "~ "  || coalesce(k.${tableModel.kennelsTableHelper.colKennelShortName},"") 
            || " " || coalesce(k.${tableModel.kennelsTableHelper.colKennelName},"")   
            
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
              when n.${tableModel.countriesTableHelper.colContinentCode} = "EU" then "europe" 
              when n.${tableModel.countriesTableHelper.colContinentCode} = "AF" then "africa" 
              when n.${tableModel.countriesTableHelper.colContinentCode} = "AS" then "asia" 
              when n.${tableModel.countriesTableHelper.colContinentCode} = "NA" then "north america" 
              when n.${tableModel.countriesTableHelper.colContinentCode} = "SA" then "south america" 
              when n.${tableModel.countriesTableHelper.colContinentCode} = "OC" then "oceania" 
              when n.${tableModel.countriesTableHelper.colContinentCode} = "AN" then "antarctica" 
              else "" 
              end || " ~" 
          as searchText
          ''';

    final String query = '''
      
        SELECT  
          k.${tableModel.kennelsTableHelper.colKennelId},
          k.${tableModel.kennelsTableHelper.colKennelName},
          k.${tableModel.kennelsTableHelper.colKennelShortName},
          $searchKennelsField
          FROM ${tableModel.kennelsTableHelper.getTableName(AppDomainType.user)} k
          INNER JOIN ${tableModel.citiesTableHelper.getTableName(AppDomainType.user)} c
          ON k.${tableModel.kennelsTableHelper.colCityId} = c.${tableModel.citiesTableHelper.colCityId}
          INNER JOIN ${tableModel.regionsTableHelper.getTableName(AppDomainType.user)} r
          ON c.${tableModel.citiesTableHelper.colRegionId} = r.${tableModel.regionsTableHelper.colRegionId}
          INNER JOIN ${tableModel.countriesTableHelper.getTableName(AppDomainType.user)} n
          ON r.${tableModel.regionsTableHelper.colCountryId} = n.${tableModel.countriesTableHelper.colCountryId}
          WHERE k.${tableModel.kennelsTableHelper.colRemoved} = 0
          ''';

    return database.rawQuery(query);
  }
}
