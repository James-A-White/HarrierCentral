// @dart=2.11
import 'package:harrier_central/imports.dart';

part 'kennels_service.g.dart';

@JsonSerializable(fieldRename: FieldRename.none)
class KennelsModel implements BaseModel {
  KennelsModel(
      {this.kennelId,
      this.publicKennelId,
      this.cityId,
      this.regionId,
      this.countryId,
      this.kennelName,
      this.kennelSearchTags,
      this.kennelShortName,
      this.kennelDescription,
      this.kennelLogo,
      this.kennelPinColor,
      this.disseminateAllowWebLinks,
      this.kennelCoverPhoto,
      this.kennelWebsiteUrl,
      this.defaultEventCurrencyType,
      this.integrationType,
      this.kennelInboundIntegrationId,
      this.kennelEventsUrl,
      this.kennelStatus,
      this.canEditRunAttendence,
      this.allowNegativeCredit,
      this.allowSelfPayment,
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
      this.kennelPaymentScheme,
      this.kennelPaymentUrl,
      this.kennelPaymentUrlExpires,
      this.kennelPaymentMemberSurcharge,
      this.kennelPaymentNonMemberSurcharge,
      this.kennelPaymentScheme2,
      this.kennelPaymentUrl2,
      this.kennelPaymentUrlExpires2,
      this.kennelPaymentMemberSurcharge2,
      this.kennelPaymentNonMemberSurcharge2,
      this.kennelPaymentScheme3,
      this.kennelPaymentUrl3,
      this.kennelPaymentUrlExpires3,
      this.kennelPaymentMemberSurcharge3,
      this.kennelPaymentNonMemberSurcharge3,
      this.runCountStartDate,
      this.kennelMismanagementTeam,
      this.distancePreference,
      this.updatedAt,
      this.removed});

  factory KennelsModel.fromJson(Map<String, dynamic> json) => _$KennelsModelFromJson(json);

  Map<String, dynamic> toJson() => _$KennelsModelToJson(this);

  final String kennelId;
  final String publicKennelId;
  final String cityId;
  final String regionId;
  final String countryId;
  final String kennelName;
  final String kennelSearchTags;
  final String kennelShortName;
  final String kennelDescription;
  final String kennelLogo;
  final int kennelPinColor;
  final int disseminateAllowWebLinks;
  final String kennelCoverPhoto;
  final String kennelWebsiteUrl;
  final String defaultEventCurrencyType;

  final String integrationType;
  final int kennelInboundIntegrationId;
  final String kennelEventsUrl;

  final int kennelStatus;
  final int canEditRunAttendence;
  final int allowNegativeCredit;
  final int allowSelfPayment;
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
  final String kennelPaymentScheme;
  final String kennelPaymentUrl;
  final DateTime kennelPaymentUrlExpires;
  final num kennelPaymentMemberSurcharge;
  final num kennelPaymentNonMemberSurcharge;
  final String kennelPaymentScheme2;
  final String kennelPaymentUrl2;
  final DateTime kennelPaymentUrlExpires2;
  final num kennelPaymentMemberSurcharge2;
  final num kennelPaymentNonMemberSurcharge2;
  final String kennelPaymentScheme3;
  final String kennelPaymentUrl3;
  final DateTime kennelPaymentUrlExpires3;
  final num kennelPaymentMemberSurcharge3;
  final num kennelPaymentNonMemberSurcharge3;
  final DateTime runCountStartDate;
  final String kennelMismanagementTeam;
  final int distancePreference;
  final DateTime updatedAt;
  final int removed;
}

class KennelsTableHelper extends BaseTableHelper with BaseFields {
  KennelsTableHelper() {
    remoteDbId = 'kennelId';
    humanReadableTableName = 'Kennels';
    pageSize = SyncUserDataService.pageSize_kennelsTable;
    tableFlag = SyncUserDataService.flagKennelsTable;
  }

  @override
  String getTableName(dynamic appDomainType) {
    String tableName;
    switch (appDomainType) {
      // case AppDomainType.event:
      //   break;
      // case AppDomainType.kennel:
      //   break;
      // case AppDomainType.user:
      //   tableName = 'hashers';
      //   break;
      default:
        tableName = 'kennels';
    }
    return tableName;
  }

  final String colKennelId = 'kennelId';
  final String colPublicKennelId = 'publicKennelId';
  final String colCityId = 'cityId';
  final String colRegionId = 'regionId';
  final String colCountryId = 'countryId';
  final String colKennelName = 'kennelName';
  final String colKennelSearchTags = 'kennelSearchTags';
  final String colKennelShortName = 'kennelShortName';
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
  final String colKennelPaymentNonMemberSurcharge = 'kennelPaymentNonMemberSurcharge';
  final String colKennelPaymentScheme2 = 'kennelPaymentScheme2';
  final String colKennelPaymentUrl2 = 'kennelPaymentUrl2';
  final String colKennelPaymentUrlExpires2 = 'kennelPaymentUrlExpires2';
  final String colKennelPaymentMemberSurcharge2 = 'kennelPaymentMemberSurcharge2';
  final String colKennelPaymentNonMemberSurcharge2 = 'kennelPaymentNonMemberSurcharge2';
  final String colKennelPaymentScheme3 = 'kennelPaymentScheme3';
  final String colKennelPaymentUrl3 = 'kennelPaymentUrl3';
  final String colKennelPaymentUrlExpires3 = 'kennelPaymentUrlExpires3';
  final String colKennelPaymentMemberSurcharge3 = 'kennelPaymentMemberSurcharge3';
  final String colKennelPaymentNonMemberSurcharge3 = 'kennelPaymentNonMemberSurcharge3';
  final String colRunCountStartDate = 'runCountStartDate';
  final String colKennelMismanagementTeam = 'kennelMismanagementTeam';
  final String colDistancePreference = 'distancePreference';

  @override
  Future<dynamic> createTable(Database db, int version, dynamic appDomainType) async {
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
            $colKennelDescription TEXT,
            $colKennelLogo TEXT,
            $colKennelPinColor INT,
            $colDisseminateAllowWebLinks INT DEFAULT 0 NOT NULL,
            $colKennelCoverPhoto TEXT,
            $colKennelWebsiteUrl TEXT,
            $colDefaultEventCurrencyType TEXT,
            $colIntegrationType TEXT,
            $colKennelInboundIntegrationId INT,
            $colKennelEventsUrl TEXT,
            $colKennelStatus INT,
            $colCanEditRunAttendence INT,
            $colAllowNegativeCredit INT,
            $colAllowSelfPayment INT,
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
            $colUpdatedAt TEXT,
            $colRemoved INT,

            $colUpdatedAtValue NUM NULL
          )
          ''');
  }

  @override
  Future<void> createIndexes(Database db, int version, dynamic appDomainType) async {
    await db.execute('CREATE INDEX idx_${getTableName(appDomainType)}_id ON ${getTableName(appDomainType)}($remoteDbId);');
    await db.execute('CREATE INDEX idx_${getTableName(appDomainType)}_update_at_value ON ${getTableName(appDomainType)}($colUpdatedAtValue);');
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
