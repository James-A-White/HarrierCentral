import 'dart:async';
import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'package:harrier_central/data/hc3_services/base_service.dart';
import 'package:harrier_central/util/preferences.dart';

class KennelsModel implements BaseModel {
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
      this.runCountStartDate,
      this.kennelMismanagementTeam,
      this.distancePreference,
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
  final DateTime runCountStartDate;
  final String kennelMismanagementTeam;
  final int distancePreference;
  final DateTime updatedAt;
  final int removed;

  @override
  List<KennelsModel> itemsFromJson(String jsonResult) {
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
          kennelPaymentUrlExpires: jsonItem['kennelPaymentUrlExpires'], // TODO(James): Investigate why this isn't being converted to a DateTime?
          runCountStartDate: DateTime.parse(jsonItem['runCountStartDate'].toString().substring(0, 19)),
          kennelMismanagementTeam: jsonItem['kennelMismanagementTeam'],
          distancePreference: jsonItem['distancePreference'],
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

class KennelsTableHelper implements BaseTableHelper {
  @override
  num forceRequeryInterval;

  @override
  num cacheDuration;

  @override
  String tableName = 'kennels';

  @override
  String getTableName(TableType type) {
    return tableName;
  }

  @override
  String remoteDbId = 'kennelId';

  final String colId = 'id';

  final String colKennelId = 'kennelId';
  final String colCityId = 'cityId';
  final String colRegionId = 'regionId';
  final String colCountryId = 'countryId';
  final String colKennelName = 'kennelName';
  final String colKennelShortName = 'kennelShortName';
  final String colKennelDescription = 'kennelDescription';
  final String colKennelLogo = 'kennelLogo';
  final String colKennelCoverPhoto = 'kennelCoverPhoto';
  final String colKennelWebsiteUrl = 'kennelWebsiteUrl';
  final String colDefaultEventCurrencyType = 'defaultEventCurrencyType';
  final String colKennelStatus = 'kennelStatus';
  final String colAllowNegativeCredit = 'allowNegativeCredit';
  final String colKennelLatitude = 'kennelLatitude';
  final String colKennelLongitude = 'kennelLongitude';
  final String colDefaultPriceForMembers = 'defaultPriceForMembers';
  final String colDefaultPriceForNonMembers = 'defaultPriceForNonMembers';
  final String colMembershipDurationInMonths = 'membershipDurationInMonths';
  final String colDefaultRunStartTime = 'defaultRunStartTime';
  final String colCurrencyCode = 'currencyCode';
  final String colPrimaryCultureCode = 'primaryCultureCode';
  final String colCurrencySymbol = 'currencySymbol';
  final String colDigitsAfterDecimal = 'digitsAfterDecimal';
  final String colBankScheme = 'bankScheme';
  final String colBankAccountNumber = 'bankAccountNumber';
  final String colBankBic = 'bankBic';
  final String colBankBeneficiary = 'bankBeneficiary';
  final String colKennelPaymentUrl = 'kennelPaymentUrl';
  final String colKennelPaymentUrlExpires = 'kennelPaymentUrlExpires';
  final String colRunCountStartDate = 'runCountStartDate';
  final String colKennelMismanagementTeam = 'kennelMismanagementTeam';
  final String colDistancePreference = 'distancePreference';
  final String colUpdatedAt = 'updatedAt';
  final String colRemoved = 'removed';

  final String colUpdatedAtValue = 'updatedAtValue';

  @override
  Future<dynamic> createTable(Database db, int version,TableType tableType) async {
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
            $colRunCountStartDate TEXT,
            $colKennelMismanagementTeam TEXT,
            $colDistancePreference INT,
            $colUpdatedAt TEXT,
            $colRemoved INT,

            $colUpdatedAtValue NUM NULL
          )
          ''');

    await db.execute('CREATE INDEX idx_${tableName}_id ON $tableName($remoteDbId);');
    await db.execute('CREATE INDEX idx_${tableName}_update_at_value ON $tableName($colUpdatedAtValue);');
  }

  @override
  Map<String, dynamic> toMap(dynamic item) {
    final Map<String, dynamic> map = <String, dynamic>{
      colKennelId: item.kennelId,
      colCityId: item.cityId,
      colRegionId: item.regionId,
      colCountryId: item.countryId,
      colKennelName: item.kennelName,
      colKennelShortName: item.kennelShortName,
      colKennelDescription: item.kennelDescription,
      colKennelLogo: item.kennelLogo,
      colKennelCoverPhoto: item.kennelCoverPhoto,
      colKennelWebsiteUrl: item.kennelWebsiteUrl,
      colDefaultEventCurrencyType: item.defaultEventCurrencyType,
      colKennelStatus: item.kennelStatus,
      colAllowNegativeCredit: item.allowNegativeCredit,
      colKennelLatitude: item.kennelLatitude,
      colKennelLongitude: item.kennelLongitude,
      colDefaultPriceForMembers: item.defaultPriceForMembers,
      colDefaultPriceForNonMembers: item.defaultPriceForNonMembers,
      colMembershipDurationInMonths: item.membershipDurationInMonths,
      colDefaultRunStartTime: item.defaultRunStartTime,
      colCurrencyCode: item.currencyCode,
      colPrimaryCultureCode: item.primaryCultureCode,
      colCurrencySymbol: item.currencySymbol,
      colDigitsAfterDecimal: item.digitsAfterDecimal,
      colBankScheme: item.bankScheme,
      colBankAccountNumber: item.bankAccountNumber,
      colBankBic: item.bankBic,
      colBankBeneficiary: item.bankBeneficiary,
      colKennelPaymentUrl: item.kennelPaymentUrl,
      colKennelPaymentUrlExpires: item.kennelPaymentUrlExpires.toString(),
      colRunCountStartDate: item.runCountStartDate.toString(),
      colKennelMismanagementTeam: item.kennelMismanagementTeam,
      colDistancePreference: item.distancePreference,
      colUpdatedAt: item.updatedAt.toString(),
      colRemoved: item.removed,
    };

    return map;
  }

  @override
  Map<String, dynamic> normalizeMap(Map<String, dynamic> inputMap) {
    final Map<String, dynamic> outputMap = <String, dynamic>{
      colKennelId: inputMap[colKennelId],
      colCityId: inputMap[colCityId],
      colRegionId: inputMap[colRegionId],
      colCountryId: inputMap[colCountryId],
      colKennelName: inputMap[colKennelName],
      colKennelShortName: inputMap[colKennelShortName],
      colKennelDescription: inputMap[colKennelDescription],
      colKennelLogo: inputMap[colKennelLogo],
      colKennelCoverPhoto: inputMap[colKennelCoverPhoto],
      colKennelWebsiteUrl: inputMap[colKennelWebsiteUrl],
      colDefaultEventCurrencyType: inputMap[colDefaultEventCurrencyType],
      colKennelStatus: inputMap[colKennelStatus],
      colAllowNegativeCredit: inputMap[colAllowNegativeCredit],
      colKennelLatitude: inputMap[colKennelLatitude],
      colKennelLongitude: inputMap[colKennelLongitude],
      colDefaultPriceForMembers: inputMap[colDefaultPriceForMembers],
      colDefaultPriceForNonMembers: inputMap[colDefaultPriceForNonMembers],
      colMembershipDurationInMonths: inputMap[colMembershipDurationInMonths],
      colDefaultRunStartTime: inputMap[colDefaultRunStartTime],
      colCurrencyCode: inputMap[colCurrencyCode],
      colPrimaryCultureCode: inputMap[colPrimaryCultureCode],
      colCurrencySymbol: inputMap[colCurrencySymbol],
      colDigitsAfterDecimal: inputMap[colDigitsAfterDecimal],
      colBankScheme: inputMap[colBankScheme],
      colBankAccountNumber: inputMap[colBankAccountNumber],
      colBankBic: inputMap[colBankBic],
      colBankBeneficiary: inputMap[colBankBeneficiary],
      colKennelPaymentUrl: inputMap[colKennelPaymentUrl],
      colKennelPaymentUrlExpires: inputMap[colKennelPaymentUrlExpires],
      colRunCountStartDate: inputMap[colRunCountStartDate],
      colKennelMismanagementTeam: inputMap[colKennelMismanagementTeam],
      colDistancePreference: inputMap[colDistancePreference],
      colUpdatedAt: inputMap[colUpdatedAt],
      colUpdatedAtValue: DateTime.parse(inputMap[colUpdatedAt].toString().substring(0, 19)).millisecondsSinceEpoch,
      colRemoved: inputMap[colRemoved],
    };

    return outputMap;
  }

  @override
  KennelsModel fromMap(Map<String, dynamic> map) {
    final KennelsModel item = KennelsModel(
      kennelId: map[colKennelId],
      cityId: map[colCityId],
      regionId: map[colRegionId],
      countryId: map[colCountryId],
      kennelName: map[colKennelName],
      kennelShortName: map[colKennelShortName],
      kennelDescription: map[colKennelDescription],
      kennelLogo: map[colKennelLogo],
      kennelCoverPhoto: map[colKennelCoverPhoto],
      kennelWebsiteUrl: map[colKennelWebsiteUrl],
      defaultEventCurrencyType: map[colDefaultEventCurrencyType],
      kennelStatus: map[colKennelStatus],
      allowNegativeCredit: map[colAllowNegativeCredit],
      kennelLatitude: map[colKennelLatitude],
      kennelLongitude: map[colKennelLongitude],
      defaultPriceForMembers: map[colDefaultPriceForMembers],
      defaultPriceForNonMembers: map[colDefaultPriceForNonMembers],
      membershipDurationInMonths: map[colMembershipDurationInMonths],
      defaultRunStartTime: DateTime.parse(map[colDefaultRunStartTime].toString().substring(0, 19)),
      currencyCode: map[colCurrencyCode],
      primaryCultureCode: map[colPrimaryCultureCode],
      currencySymbol: map[colCurrencySymbol],
      digitsAfterDecimal: map[colDigitsAfterDecimal],
      bankScheme: map[colBankScheme],
      bankAccountNumber: map[colBankAccountNumber],
      bankBic: map[colBankBic],
      bankBeneficiary: map[colBankBeneficiary],
      kennelPaymentUrl: map[colKennelPaymentUrl],
      kennelPaymentUrlExpires: DateTime.parse((map[colKennelPaymentUrlExpires] ?? '2000-01-01 01:00:00').toString().substring(0, 19)),
      runCountStartDate: map[colRunCountStartDate] == null ? null : DateTime.parse(map[colRunCountStartDate].toString().substring(0, 19)),
      kennelMismanagementTeam: map[colKennelMismanagementTeam],
      distancePreference: map[colDistancePreference],
      updatedAt: DateTime.parse(map[colUpdatedAt].toString().substring(0, 19)),
      removed: map[colRemoved],
    );

    return item;
  }
}
