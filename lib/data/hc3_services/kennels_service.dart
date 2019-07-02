import 'dart:async';
import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'package:harrier_central/database/database.dart';
import 'package:harrier_central/util/preferences.dart';

class KennelsModel {
  KennelsModel(
      {this.kennelId,
      this.cityId,
      this.regionId,
      this.countryId,
      this.kennelName,
      this.kennelShortName,
      this.kennelDescription,
      this.kennelLogo,
      this.kennelCoverPhoto,
      this.kennelWebsiteUrl,
      this.defaultEventCurrencyType,
      this.kennelStatus,
      this.allowNegativeCredit,
      this.kennelLatitude,
      this.kennelLongitude,
      this.defaultPriceForMembers,
      this.defaultPriceForNonMembers,
      this.membershipDurationInMonths,
      this.defaultRunStartTime,
      this.currencyCode,
      this.primaryCultureCode,
      this.currencySymbol,
      this.digitsAfterDecimal,
      this.bankScheme,
      this.bankAccountNumber,
      this.bankBic,
      this.bankBeneficiary,
      this.kennelPaymentUrl,
      this.kennelPaymentUrlExpires,
      this.updatedAt,
      this.removed});

  final String kennelId;
  final String cityId;
  final String regionId;
  final String countryId;
  final String kennelName;
  final String kennelShortName;
  final String kennelDescription;
  final String kennelLogo;
  final String kennelCoverPhoto;
  final String kennelWebsiteUrl;
  final String defaultEventCurrencyType;
  final int kennelStatus;
  final int allowNegativeCredit;
  final num kennelLatitude;
  final num kennelLongitude;
  final num defaultPriceForMembers;
  final num defaultPriceForNonMembers;
  final int membershipDurationInMonths;
  final DateTime defaultRunStartTime;
  final String currencyCode;
  final String primaryCultureCode;
  final String currencySymbol;
  final num digitsAfterDecimal;
  final String bankScheme;
  final String bankAccountNumber;
  final String bankBic;
  final String bankBeneficiary;
  final String kennelPaymentUrl;
  final DateTime kennelPaymentUrlExpires;
  final DateTime updatedAt;
  final int removed;

  static List<KennelsModel> itemsFromJson(String jsonResult) {
    final List<KennelsModel> items = <KennelsModel>[];

    KennelsModel item;

    json.decode(jsonResult).forEach(
      (dynamic jsonItem) {
        item = KennelsModel(
          kennelId: jsonItem['kennelId'],
          cityId: jsonItem['cityId'],
          regionId: jsonItem['regionId'],
          countryId: jsonItem['countryId'],
          kennelName: jsonItem['kennelName'],
          kennelShortName: jsonItem['kennelShortName'],
          kennelDescription: jsonItem['kennelDescription'],
          kennelLogo: jsonItem['kennelLogo'],
          kennelCoverPhoto: jsonItem['kennelCoverPhoto'],
          kennelWebsiteUrl: jsonItem['kennelWebsiteUrl'],
          defaultEventCurrencyType: jsonItem['defaultEventCurrencyType'],
          kennelStatus: jsonItem['kennelStatus'],
          allowNegativeCredit: jsonItem['allowNegativeCredit'],
          kennelLatitude: jsonItem['kennelLatitude'],
          kennelLongitude: jsonItem['kennelLongitude'],
          defaultPriceForMembers: jsonItem['defaultPriceForMembers'],
          defaultPriceForNonMembers: jsonItem['defaultPriceForNonMembers'],
          membershipDurationInMonths: jsonItem['membershipDurationInMonths'],
          defaultRunStartTime: DateTime.parse(jsonItem['defaultRunStartTime'].toString().substring(0, 19)),
          currencyCode: jsonItem['currencyCode'],
          primaryCultureCode: jsonItem['primaryCultureCode'],
          currencySymbol: jsonItem['currencySymbol'],
          digitsAfterDecimal: jsonItem['digitsAfterDecimal'],
          bankScheme: jsonItem['bankScheme'],
          bankAccountNumber: jsonItem['bankAccountNumber'],
          bankBic: jsonItem['bankBic'],
          bankBeneficiary: jsonItem['bankBeneficiary'],
          kennelPaymentUrl: jsonItem['kennelPaymentUrl'],
          kennelPaymentUrlExpires: jsonItem['kennelPaymentUrlExpires'],
          updatedAt: DateTime.parse(jsonItem['updatedAt'].toString().substring(0, 19)),
          removed: jsonItem['removed'],
        );

        items.add(item);
      },
    );

    if (items.isEmpty) {
      return null;
    }

    return items;
  }
}

class KennelsTableHelper {
  KennelsTableHelper._privateConstructor();

  static const String tableName = 'kennels';

  //static const num forceRequeryInterval = 1 * 86400000;
  static const num forceRequeryInterval = 1 * 1000;
  static const num cacheDuration = 365 * 3 * 86400000; // cause a force refresh of the cache every 3 years. This effectively prevents cache refreshes

  static const IntPrefsEnum lastUpdatedKey = IntPrefsEnum.lastUpdateKennelData;
  static const IntPrefsEnum lastCacheClearKey = IntPrefsEnum.lastCacheClearKennelData;

  static const String colId = 'id';
  static const String remoteDbId = 'kennelId';

  static const String colKennelId = 'kennelId';
  static const String colCityId = 'cityId';
  static const String colRegionId = 'regionId';
  static const String colCountryId = 'countryId';
  static const String colKennelName = 'kennelName';
  static const String colKennelShortName = 'kennelShortName';
  static const String colKennelDescription = 'kennelDescription';
  static const String colKennelLogo = 'kennelLogo';
  static const String colKennelCoverPhoto = 'kennelCoverPhoto';
  static const String colKennelWebsiteUrl = 'kennelWebsiteUrl';
  static const String colDefaultEventCurrencyType = 'defaultEventCurrencyType';
  static const String colKennelStatus = 'kennelStatus';
  static const String colAllowNegativeCredit = 'allowNegativeCredit';
  static const String colKennelLatitude = 'kennelLatitude';
  static const String colKennelLongitude = 'kennelLongitude';
  static const String colDefaultPriceForMembers = 'defaultPriceForMembers';
  static const String colDefaultPriceForNonMembers = 'defaultPriceForNonMembers';
  static const String colMembershipDurationInMonths = 'membershipDurationInMonths';
  static const String colDefaultRunStartTime = 'defaultRunStartTime';
  static const String colCurrencyCode= 'currencyCode';
  static const String colPrimaryCultureCode= 'primaryCultureCode';
  static const String colCurrencySymbol= 'currencySymbol';
  static const String colDigitsAfterDecimal= 'digitsAfterDecimal';
  static const String colBankScheme= 'bankScheme';
  static const String colBankAccountNumber= 'bankAccountNumber';
  static const String colBankBic= 'bankBic';
  static const String colBankBeneficiary= 'bankBeneficiary';
  static const String colKennelPaymentUrl= 'kennelPaymentUrl';
  static const String colKennelPaymentUrlExpires= 'kennelPaymentUrlExpires';
  static const String colUpdatedAt = 'updatedAt';
  static const String colRemoved = 'removed';

  static const String colUpdatedAtValue = 'updatedAtValue';

  // make this a singleton class

  static final KennelsTableHelper instance = KennelsTableHelper._privateConstructor();

  // SQL code to create the database table
  static Future<dynamic> createTable(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $tableName (
            $colId INTEGER PRIMARY KEY,

            $colKennelId TEXT NOT NULL,
            $colCityId TEXT NOT NULL,
            $colRegionId TEXT NOT NULL,
            $colCountryId TEXT NOT NULL,
            $colKennelName TEXT NOT NULL,
            $colKennelShortName TEXT NOT NULL,
            $colKennelDescription TEXT,
            $colKennelLogo TEXT,
            $colKennelCoverPhoto TEXT,
            $colKennelWebsiteUrl TEXT,
            $colDefaultEventCurrencyType TEXT,
            $colKennelStatus INT,
            $colAllowNegativeCredit INT,
            $colKennelLatitude NUM,
            $colKennelLongitude NUM,
            $colDefaultPriceForMembers NUM,
            $colDefaultPriceForNonMembers NUM,
            $colMembershipDurationInMonths INT,
            $colDefaultRunStartTime TEXT,
            $colCurrencyCode TEXT,
            $colPrimaryCultureCode TEXT,
            $colCurrencySymbol TEXT,
            $colDigitsAfterDecimal NUM,
            $colBankScheme TEXT,
            $colBankAccountNumber TEXT,
            $colBankBic TEXT,
            $colBankBeneficiary TEXT,
            $colKennelPaymentUrl TEXT,
            $colKennelPaymentUrlExpires TEXT,
            $colUpdatedAt TEXT,
            $colRemoved INT,

            $colUpdatedAtValue NUM NULL
          )
          ''');

    await db.execute('CREATE INDEX idx_${tableName}_id ON $tableName($remoteDbId);');
    await db.execute('CREATE INDEX idx_${tableName}_update_at_value ON $tableName($colUpdatedAtValue);');
  }

  static Map<String, dynamic> toMap(KennelsModel item) {
    final Map<String, dynamic> map = <String, dynamic>{
      KennelsTableHelper.colKennelId: item.kennelId,
      KennelsTableHelper.colCityId: item.cityId,
      KennelsTableHelper.colRegionId: item.regionId,
      KennelsTableHelper.colCountryId: item.countryId,
      KennelsTableHelper.colKennelName: item.kennelName,
      KennelsTableHelper.colKennelShortName: item.kennelShortName,
      KennelsTableHelper.colKennelDescription: item.kennelDescription,
      KennelsTableHelper.colKennelLogo: item.kennelLogo,
      KennelsTableHelper.colKennelCoverPhoto: item.kennelCoverPhoto,
      KennelsTableHelper.colKennelWebsiteUrl: item.kennelWebsiteUrl,
      KennelsTableHelper.colDefaultEventCurrencyType: item.defaultEventCurrencyType,
      KennelsTableHelper.colKennelStatus: item.kennelStatus,
      KennelsTableHelper.colAllowNegativeCredit: item.allowNegativeCredit,
      KennelsTableHelper.colKennelLatitude: item.kennelLatitude,
      KennelsTableHelper.colKennelLongitude: item.kennelLongitude,
      KennelsTableHelper.colDefaultPriceForMembers: item.defaultPriceForMembers,
      KennelsTableHelper.colDefaultPriceForNonMembers: item.defaultPriceForNonMembers,
      KennelsTableHelper.colMembershipDurationInMonths: item.membershipDurationInMonths,
      KennelsTableHelper.colDefaultRunStartTime: item.defaultRunStartTime,
      KennelsTableHelper.colCurrencyCode: item.currencyCode,
      KennelsTableHelper.colPrimaryCultureCode: item.primaryCultureCode,
      KennelsTableHelper.colCurrencySymbol: item.currencySymbol,
      KennelsTableHelper.colDigitsAfterDecimal: item.digitsAfterDecimal,
      KennelsTableHelper.colBankScheme: item.bankScheme,
      KennelsTableHelper.colBankAccountNumber: item.bankAccountNumber,
      KennelsTableHelper.colBankBic: item.bankBic,
      KennelsTableHelper.colBankBeneficiary: item.bankBeneficiary,
      KennelsTableHelper.colKennelPaymentUrl: item.kennelPaymentUrl,
      KennelsTableHelper.colKennelPaymentUrlExpires: item.kennelPaymentUrlExpires.toString(),
      KennelsTableHelper.colUpdatedAt: item.updatedAt.toString(),
      KennelsTableHelper.colRemoved: item.removed,
    };

    return map;
  }

  static KennelsModel fromMap(Map<String, dynamic> map) {
    final KennelsModel item = KennelsModel(
      kennelId: map[KennelsTableHelper.colKennelId],
      cityId: map[KennelsTableHelper.colCityId],
      regionId: map[KennelsTableHelper.colRegionId],
      countryId: map[KennelsTableHelper.colCountryId],
      kennelName: map[KennelsTableHelper.colKennelName],
      kennelShortName: map[KennelsTableHelper.colKennelShortName],
      kennelDescription: map[KennelsTableHelper.colKennelDescription],
      kennelLogo: map[KennelsTableHelper.colKennelLogo],
      kennelCoverPhoto: map[KennelsTableHelper.colKennelCoverPhoto],
      kennelWebsiteUrl: map[KennelsTableHelper.colKennelWebsiteUrl],
      defaultEventCurrencyType: map[KennelsTableHelper.colDefaultEventCurrencyType],
      kennelStatus: map[KennelsTableHelper.colKennelStatus],
      allowNegativeCredit: map[KennelsTableHelper.colAllowNegativeCredit],
      kennelLatitude: map[KennelsTableHelper.colKennelLatitude],
      kennelLongitude: map[KennelsTableHelper.colKennelLongitude],
      defaultPriceForMembers: map[KennelsTableHelper.colDefaultPriceForMembers],
      defaultPriceForNonMembers: map[KennelsTableHelper.colDefaultPriceForNonMembers],
      membershipDurationInMonths: map[KennelsTableHelper.colMembershipDurationInMonths],
      defaultRunStartTime: DateTime.parse(map[KennelsTableHelper.colDefaultRunStartTime].toString().substring(0, 19)),
      currencyCode: map[KennelsTableHelper.colCurrencyCode],
      primaryCultureCode: map[KennelsTableHelper.colPrimaryCultureCode],
      currencySymbol: map[KennelsTableHelper.colCurrencySymbol],
      digitsAfterDecimal: map[KennelsTableHelper.colDigitsAfterDecimal],
      bankScheme: map[KennelsTableHelper.colBankScheme],
      bankAccountNumber: map[KennelsTableHelper.colBankAccountNumber],
      bankBic: map[KennelsTableHelper.colBankBic],
      bankBeneficiary: map[KennelsTableHelper.colBankBeneficiary],
      kennelPaymentUrl: map[KennelsTableHelper.colKennelPaymentUrl],
      kennelPaymentUrlExpires: DateTime.parse((map[KennelsTableHelper.colKennelPaymentUrlExpires] ?? '2000-01-01 01:00:00').toString().substring(0, 19)),
      updatedAt: DateTime.parse(map[KennelsTableHelper.colUpdatedAt].toString().substring(0, 19)),
      removed: map[KennelsTableHelper.colRemoved],
    );

    return item;
  }
}

class KennelsService {
  static final KennelsTableHelper instance = KennelsTableHelper._privateConstructor();

  static Future<num> getLastUpdatedTime() async {
    final Database db = await DBProvider.db.database;
    final List<Map<String, dynamic>> table = await db.rawQuery('SELECT MAX(${KennelsTableHelper.colUpdatedAtValue}) AS maxDate FROM ${KennelsTableHelper.tableName}');
    final num timeValue = table.first['maxDate'];
    return timeValue;
  }

  Future<void> clearTable() async {
    final Database db = await DBProvider.db.database;
    await db.rawDelete('DELETE FROM ${KennelsTableHelper.tableName}').then((void dummy) {
      setIntPref(KennelsTableHelper.lastCacheClearKey, DateTime.now().millisecondsSinceEpoch);
    });
  }

  Future<void> updateDatabase(List<KennelsModel> items) async {
    final Database db = await DBProvider.db.database;

    for (int i = 0; i < items?.length ?? 0; i++) {
      final Map<String, dynamic> row = KennelsTableHelper.toMap(items[i]);

      final List<Map<String, dynamic>> table = await db.rawQuery('SELECT * FROM ${KennelsTableHelper.tableName} WHERE ${KennelsTableHelper.remoteDbId} = "${items[i].kennelId}"');
      if ((table == null) || (table.isEmpty)) {
        await db.transaction<dynamic>((Transaction txn) async {
          final int result = await txn.insert(KennelsTableHelper.tableName, row);
          print(result.toString() + ' inserted into to the ${KennelsTableHelper.tableName} table @ ${DateTime.now().millisecondsSinceEpoch.toString()}');
        });
      } else {
        final String rowId = table.first['id'].toString();

        await db.transaction<dynamic>((Transaction txn) async {
          final int result = await txn.update(KennelsTableHelper.tableName, row, where: 'id = $rowId');
          print(result.toString() + ' update to the ${KennelsTableHelper.tableName} table @ ${DateTime.now().millisecondsSinceEpoch.toString()}');
        });
      }
    }
  }

  Future<int> bulkUpdateDatabase(String rawResults, Database db, Function informUser) async {
    int updateCounter = 0;
    int insertCounter = 0;

    final List<dynamic> jsonResultSets = json.decode(rawResults);

    final int len = jsonResultSets.length;
    int lastPercentage = 0;

    print('Kennel records received from cloud = $len');

    for (int i = 0; i < jsonResultSets.length; i++) {
      final List<dynamic> jsonResults = jsonResultSets[i];

      for (int j = 0; j < jsonResults.length; j++) {
        final Map<String, dynamic> jsonItem = jsonResults[j];

        final int percentage = (100 * (j / jsonResults.length)).round();
        if ((percentage != lastPercentage) && (informUser != null)) {
          lastPercentage = percentage;
          informUser('Loading kennel data\r\n$percentage% complete');
        }

        jsonItem.addAll(<String, dynamic>{
          'updatedAtValue': DateTime.parse(jsonItem['updatedAt'].toString().substring(0, 19)).millisecondsSinceEpoch,
        });

        final String query = 'SELECT * FROM ${KennelsTableHelper.tableName} WHERE ${KennelsTableHelper.remoteDbId} = "${jsonItem['kennelId']}"';
        final List<Map<String, dynamic>> table = await db.rawQuery(query);

        if ((table == null) || (table.isEmpty)) {
          //print(table.length.toString());
          await db.transaction<dynamic>((Transaction txn) async {
            //final int result =
            await txn.insert(KennelsTableHelper.tableName, jsonItem);
            insertCounter++;
            // print(result.toString() +
            //     ' inserted into to the ${KennelsTableHelper.table} table @ ${DateTime.now().millisecondsSinceEpoch}');
          });
        } else {
          final String rowId = table.first['id'].toString();

          await db.transaction<dynamic>((Transaction txn) async {
            //final int result =
            await txn.update(KennelsTableHelper.tableName, jsonItem, where: 'id = $rowId');
            updateCounter++;
            // print(result.toString() +
            //     ' update to the ${KennelsTableHelper.table} table @ ${DateTime.now().millisecondsSinceEpoch}');
          });
        }
      }
    }

    print('$insertCounter kennel records inserted, $updateCounter kennel records updated');
    return insertCounter;
  }
}
