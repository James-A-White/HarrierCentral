import 'package:harrier_central/imports.dart';

class RunHistoryQueries {
  static Future<List<RunHistoryModel>> getRunHistory(
      String userId, String? kennelId) async {
    final appDomain = AppDomainType.kennel;

    String query = '''
          SELECT 
          coalesce(hkm.${G0<TableModel>().hasherKennelMapTableHelper.colHistoricalTotalRunCount} + hkm.${G0<TableModel>().hasherKennelMapTableHelper.colHcTotalRunCount},0) as totalRunsThisKennel,
          coalesce(hkm.${G0<TableModel>().hasherKennelMapTableHelper.colHistoricalHaringCount} + ${G0<TableModel>().hasherKennelMapTableHelper.colHcHaringCount},0) as totalHaringThisKennel,

          coalesce(hkm.${G0<TableModel>().hasherKennelMapTableHelper.colHcTotalRunCount},0) as hcRunsThisKennel,
          coalesce(${G0<TableModel>().hasherKennelMapTableHelper.colHcHaringCount},0) as hcHaringThisKennel,

          k.${G0<TableModel>().kennelsTableHelper.colKennelShortName},
          k.${G0<TableModel>().kennelsTableHelper.colKennelName},
          k.${G0<TableModel>().kennelsTableHelper.colKennelId},
          k.${G0<TableModel>().kennelsTableHelper.colKennelLogo},
          coalesce(hkm.${G0<TableModel>().hasherKennelMapTableHelper.colHistoricalTotalRunCount},0) as ${G0<TableModel>().hasherKennelMapTableHelper.colHistoricalTotalRunCount},
          coalesce(hkm.${G0<TableModel>().hasherKennelMapTableHelper.colHistoricalHaringCount},0) as ${G0<TableModel>().hasherKennelMapTableHelper.colHistoricalHaringCount},
          coalesce(hkm.${G0<TableModel>().hasherKennelMapTableHelper.colHistoricalCountIsEstimate},0) as ${G0<TableModel>().hasherKennelMapTableHelper.colHistoricalCountIsEstimate},
          coalesce(hkm.${G0<TableModel>().hasherKennelMapTableHelper.colFollowing},0) as ${G0<TableModel>().hasherKennelMapTableHelper.colFollowing},
          coalesce(hkm.${G0<TableModel>().hasherKennelMapTableHelper.colKennelCredit},0) as kennelCredit,
          coalesce(k.${G0<TableModel>().kennelsTableHelper.colDigitsAfterDecimal},c.${G0<TableModel>().countriesTableHelper.colDigitsAfterDecimal}) as digitsAfterDecimal,
          coalesce(k.${G0<TableModel>().kennelsTableHelper.colCurrencySymbol},c.${G0<TableModel>().countriesTableHelper.colCurrencySymbol}) as currencySymbol
          FROM ${G0<TableModel>().kennelsTableHelper.getTableName(appDomain)} k
          INNER JOIN ${G0<TableModel>().countriesTableHelper.getTableName(appDomain)} c on c.${G0<TableModel>().countriesTableHelper.colCountryId} = k.${G0<TableModel>().kennelsTableHelper.colCountryId}
          LEFT OUTER JOIN ${G0<TableModel>().hasherKennelMapTableHelper.getTableName(appDomain)} hkm on hkm.${G0<TableModel>().hasherKennelMapTableHelper.colUserId} = "$userId"  and hkm.${G0<TableModel>().hasherKennelMapTableHelper.colKennelId} = k.${G0<TableModel>().kennelsTableHelper.colKennelId}
          
          ''';

    if (kennelId != null) {
      query +=
          'WHERE k.${G0<TableModel>().kennelsTableHelper.colKennelId} = "$kennelId"';
    }

    query += 'ORDER BY totalRunsThisKennel desc';

    final runHistoryList = <RunHistoryModel>[];

    try {
      final List<Map<String, dynamic>> results =
          await G0<Database>().rawQuery(query);

      for (var item in results) {
        runHistoryList.add(RunHistoryModel.fromMap(item));
      }
    } catch (e) {
      //print(e);
    }

    return runHistoryList;
  }
}
