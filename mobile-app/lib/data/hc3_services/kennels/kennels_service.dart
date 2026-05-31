import 'package:harrier_central/imports.dart';

class KennelsTableHelper extends BaseTableHelper<AppDomainType>
    with BaseFields {
  KennelsTableHelper() {
    remoteDbId = 'kennelId';
    humanReadableTableName = 'Kennels';
    pageSize = SyncUserDataService.pageSize_kennelsTable;
    tableFlag = EnumDataTables.kennels.flag;
  }

  @override
  String getTableName(AppDomainType appDomainType) {
    // Kennels are stored in a single shared table across all domain types.
    // The kennel admin sync (AppDomainType.kennel) writes to the same table
    // as the user sync, so we always return commonTableName.
    return EnumDataTables.kennels.commonTableName;
  }

  final String colKennelId = 'kennelId';
  final String colPublicKennelId = 'publicKennelId';
  final String colCityId = 'cityId';
  final String colRegionId = 'regionId';
  final String colCountryId = 'countryId';
  final String colKennelName = 'kennelName';
  final String colKennelSearchTags = 'kennelSearchTags';
  final String colKennelShortName = 'kennelShortName';
  final String colKennelUniqueShortName = 'kennelUniqueShortName';
  final String colKennelDescription = 'kennelDescription';
  final String colKennelLogo = 'kennelLogo';
  final String colKennelPinColor = 'kennelPinColor';
  final String colDisseminateAllowWebLinks = 'disseminateAllowWebLinks';
  final String colKennelCoverPhoto = 'kennelCoverPhoto';
  final String colKennelWebsiteUrl = 'kennelWebsiteUrl';
  final String colDefaultEventCurrencyType = 'defaultEventCurrencyType';
  final String colIntegrationType = 'integrationType';
  final String colKennelInboundIntegrationId = 'kennelInboundIntegrationId';
  final String colKennelEventsUrl = 'kennelEventsUrl';
  final String colKennelStatus = 'kennelStatus';
  final String colCanEditRunAttendence = 'canEditRunAttendence';
  final String colAllowNegativeCredit = 'allowNegativeCredit';
  final String colAllowSelfPayment = 'allowSelfPayment';
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
  final String colKennelPaymentScheme = 'kennelPaymentScheme';
  final String colKennelPaymentUrl = 'kennelPaymentUrl';
  final String colKennelPaymentUrlExpires = 'kennelPaymentUrlExpires';
  final String colKennelPaymentMemberSurcharge = 'kennelPaymentMemberSurcharge';
  final String colKennelPaymentNonMemberSurcharge =
      'kennelPaymentNonMemberSurcharge';
  final String colKennelPaymentScheme2 = 'kennelPaymentScheme2';
  final String colKennelPaymentUrl2 = 'kennelPaymentUrl2';
  final String colKennelPaymentUrlExpires2 = 'kennelPaymentUrlExpires2';
  final String colKennelPaymentMemberSurcharge2 =
      'kennelPaymentMemberSurcharge2';
  final String colKennelPaymentNonMemberSurcharge2 =
      'kennelPaymentNonMemberSurcharge2';
  final String colKennelPaymentScheme3 = 'kennelPaymentScheme3';
  final String colKennelPaymentUrl3 = 'kennelPaymentUrl3';
  final String colKennelPaymentUrlExpires3 = 'kennelPaymentUrlExpires3';
  final String colKennelPaymentMemberSurcharge3 =
      'kennelPaymentMemberSurcharge3';
  final String colKennelPaymentNonMemberSurcharge3 =
      'kennelPaymentNonMemberSurcharge3';
  final String colRunCountStartDate = 'runCountStartDate';
  final String colKennelMismanagementTeam = 'kennelMismanagementTeam';
  final String colDistancePreference = 'distancePreference';
  final String colTrailSymbolsConfigJson = 'trailSymbolsConfigJson';

  @override
  Future<dynamic> createTable(
    Database db,
    int version,
    dynamic appDomainType,
  ) async {
    final String tableName = getTableName(appDomainType);
    await db.execute('''
          CREATE TABLE $tableName (
            $colId INTEGER PRIMARY KEY,
            $colKennelId TEXT NOT NULL,
            $colPublicKennelId TEXT NOT NULL,
            $colCityId TEXT NOT NULL,
            $colRegionId TEXT NOT NULL,
            $colCountryId TEXT NOT NULL,
            $colKennelName TEXT NOT NULL,
            $colKennelSearchTags TEXT,
            $colKennelShortName TEXT NOT NULL,
            $colKennelUniqueShortName TEXT NOT NULL,
            $colKennelDescription TEXT,
            $colKennelLogo TEXT NOT NULL,
            $colKennelPinColor INT NOT NULL,
            $colDisseminateAllowWebLinks INT DEFAULT 0 NOT NULL,
            $colKennelCoverPhoto TEXT,
            $colKennelWebsiteUrl TEXT,
            $colDefaultEventCurrencyType TEXT,
            $colIntegrationType TEXT,
            $colKennelInboundIntegrationId INT,
            $colKennelEventsUrl TEXT,
            $colKennelStatus INT NOT NULL,
            $colCanEditRunAttendence INT NOT NULL,
            $colAllowNegativeCredit INT NOT NULL,
            $colAllowSelfPayment INT NOT NULL,
            $colKennelLatitude NUM,
            $colKennelLongitude NUM,
            $colDefaultPriceForMembers NUM NOT NULL,
            $colDefaultPriceForNonMembers NUM NOT NULL,
            $colMembershipDurationInMonths INT NOT NULL,
            $colDefaultRunStartTime TEXT NOT NULL,
            $colCurrencyCode TEXT,
            $colPrimaryCultureCode TEXT,
            $colCurrencySymbol TEXT,
            $colDigitsAfterDecimal NUM,
            $colBankScheme TEXT,
            $colBankAccountNumber TEXT,
            $colBankBic TEXT,
            $colBankBeneficiary TEXT,
            $colKennelPaymentScheme TEXT,
            $colKennelPaymentUrl TEXT,
            $colKennelPaymentUrlExpires TEXT,
            $colKennelPaymentMemberSurcharge NUM,
            $colKennelPaymentNonMemberSurcharge NUM,
            $colKennelPaymentScheme2 TEXT,
            $colKennelPaymentUrl2 TEXT,
            $colKennelPaymentUrlExpires2 TEXT,
            $colKennelPaymentMemberSurcharge2 NUM,
            $colKennelPaymentNonMemberSurcharge2 NUM,
            $colKennelPaymentScheme3 TEXT,
            $colKennelPaymentUrl3 TEXT,
            $colKennelPaymentUrlExpires3 TEXT,
            $colKennelPaymentMemberSurcharge3 NUM,
            $colKennelPaymentNonMemberSurcharge3 NUM,
            $colRunCountStartDate TEXT,
            $colKennelMismanagementTeam TEXT,
            $colDistancePreference INT,
            $colUpdatedAt TEXT NOT NULL,
            $colRemoved INT NOT NULL,
            $colUpdatedAtValue INT NULL
          )
          ''');
  }

  @override
  Future<void> createIndexes(
    Database db,
    int version,
    dynamic appDomainType,
  ) async {
    await db.execute(
      'CREATE INDEX idx_${getTableName(appDomainType)}_id ON ${getTableName(appDomainType)}($remoteDbId);',
    );
    await db.execute(
      'CREATE INDEX idx_${getTableName(appDomainType)}_update_at_value ON ${getTableName(appDomainType)}($colUpdatedAtValue);',
    );
  }

  // @override
  // Map<String, dynamic> toMap(dynamic item) {
  //   final Map<String,dynamic> map = _$KennelsModelToJson(item);
  //   return map;
  // }

  @override
  Map<String, dynamic> normalizeMap(Map<String, dynamic> inputMap) {
    return KennelsModel.fromJson(inputMap).toJson();
  }

  @override
  KennelsModel fromMap(Map<String, dynamic> map) {
    return KennelsModel.fromJson(map);
  }
}
