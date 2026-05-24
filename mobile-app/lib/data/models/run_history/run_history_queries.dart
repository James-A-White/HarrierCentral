import 'package:harrier_central/imports.dart';

class RunHistoryQueries {
  static Future<List<RunHistoryModel>> getRunHistory(
    String userId,
    String? kennelId,
  ) async {
    String query =
        '''
          SELECT 
          coalesce(hkm.${tableModel.hasherKennelMapTableHelper.colHistoricalTotalRunCount} + hkm.${tableModel.hasherKennelMapTableHelper.colHcTotalRunCount},0) as totalRunsThisKennel,
          coalesce(hkm.${tableModel.hasherKennelMapTableHelper.colHistoricalHaringCount} + ${tableModel.hasherKennelMapTableHelper.colHcHaringCount},0) as totalHaringThisKennel,

          coalesce(hkm.${tableModel.hasherKennelMapTableHelper.colHcTotalRunCount},0) as hcRunsThisKennel,
          coalesce(${tableModel.hasherKennelMapTableHelper.colHcHaringCount},0) as hcHaringThisKennel,

          k.${tableModel.kennelsTableHelper.colKennelShortName},
          k.${tableModel.kennelsTableHelper.colKennelName},
          k.${tableModel.kennelsTableHelper.colKennelId},
          k.${tableModel.kennelsTableHelper.colKennelLogo},
          coalesce(hkm.${tableModel.hasherKennelMapTableHelper.colHistoricalTotalRunCount},0) as ${tableModel.hasherKennelMapTableHelper.colHistoricalTotalRunCount},
          coalesce(hkm.${tableModel.hasherKennelMapTableHelper.colHistoricalHaringCount},0) as ${tableModel.hasherKennelMapTableHelper.colHistoricalHaringCount},
          coalesce(hkm.${tableModel.hasherKennelMapTableHelper.colHistoricalCountIsEstimate},0) as ${tableModel.hasherKennelMapTableHelper.colHistoricalCountIsEstimate},
          coalesce(hkm.${tableModel.hasherKennelMapTableHelper.colFollowing},0) as ${tableModel.hasherKennelMapTableHelper.colFollowing},
          coalesce(hkm.${tableModel.hasherKennelMapTableHelper.colKennelCredit},0) as kennelCredit,
          coalesce(k.${tableModel.kennelsTableHelper.colDigitsAfterDecimal},c.${tableModel.countriesTableHelper.colDigitsAfterDecimal}) as digitsAfterDecimal,
          coalesce(k.${tableModel.kennelsTableHelper.colCurrencySymbol},c.${tableModel.countriesTableHelper.colCurrencySymbol}) as currencySymbol
          FROM ${EnumDataTables.kennels.commonTableName} k
          INNER JOIN ${EnumDataTables.countries.commonTableName} c on c.${tableModel.countriesTableHelper.colCountryId} = k.${tableModel.kennelsTableHelper.colCountryId}
          LEFT OUTER JOIN ${EnumDataTables.hasherKennelMap.kennelTableName} hkm on hkm.${tableModel.hasherKennelMapTableHelper.colUserId} = "$userId"  and hkm.${tableModel.hasherKennelMapTableHelper.colKennelId} = k.${tableModel.kennelsTableHelper.colKennelId}
          
          ''';

    if (kennelId != null) {
      query +=
          'WHERE k.${tableModel.kennelsTableHelper.colKennelId} = "$kennelId"';
    }

    query += 'ORDER BY totalRunsThisKennel desc';

    final runHistoryList = <RunHistoryModel>[];

    try {
      final List<Map<String, dynamic>> results = await database.rawQuery(query);

      for (var item in results) {
        runHistoryList.add(RunHistoryModel.fromMap(item));
      }
    } catch (e, s) {
      debugPrint('[RunHistoryQueries.getRunHistory] error: $e');
      BootLogger.logError('[RunHistoryQueries.getRunHistory] userId=$userId kennelId=$kennelId', e, s);
    }

    return runHistoryList;
  }
}
