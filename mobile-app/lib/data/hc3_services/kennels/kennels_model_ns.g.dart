// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kennels_model_ns.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_KennelsModel _$KennelsModelFromJson(
  Map<String, dynamic> json,
) => _KennelsModel(
  kennelId: json['kennelId'] as String,
  publicKennelId: json['publicKennelId'] as String,
  cityId: json['cityId'] as String,
  regionId: json['regionId'] as String,
  countryId: json['countryId'] as String,
  kennelName: json['kennelName'] as String,
  kennelSearchTags: json['kennelSearchTags'] as String?,
  kennelShortName: json['kennelShortName'] as String,
  kennelUniqueShortName: json['kennelUniqueShortName'] as String,
  kennelDescription: json['kennelDescription'] as String?,
  kennelLogo: json['kennelLogo'] as String,
  kennelPinColor: (json['kennelPinColor'] as num).toInt(),
  disseminateAllowWebLinks: (json['disseminateAllowWebLinks'] as num).toInt(),
  allowCredit: (json['allowCredit'] as num?)?.toInt() ?? 1,
  kennelCoverPhoto: json['kennelCoverPhoto'] as String?,
  kennelWebsiteUrl: json['kennelWebsiteUrl'] as String?,
  defaultEventCurrencyType: json['defaultEventCurrencyType'] as String?,
  integrationType: json['integrationType'] as String?,
  kennelInboundIntegrationId: (json['kennelInboundIntegrationId'] as num?)
      ?.toInt(),
  kennelEventsUrl: json['kennelEventsUrl'] as String?,
  kennelStatus: (json['kennelStatus'] as num).toInt(),
  canEditRunAttendence: (json['canEditRunAttendence'] as num).toInt(),
  allowNegativeCredit: (json['allowNegativeCredit'] as num).toInt(),
  allowSelfPayment: (json['allowSelfPayment'] as num).toInt(),
  kennelLatitude: (json['kennelLatitude'] as num?)?.toDouble(),
  kennelLongitude: (json['kennelLongitude'] as num?)?.toDouble(),
  defaultPriceForMembers: (json['defaultPriceForMembers'] as num).toDouble(),
  defaultPriceForNonMembers: (json['defaultPriceForNonMembers'] as num)
      .toDouble(),
  membershipDurationInMonths: (json['membershipDurationInMonths'] as num)
      .toInt(),
  defaultRunStartTime: DateTime.parse(json['defaultRunStartTime'] as String),
  currencyCode: json['currencyCode'] as String?,
  primaryCultureCode: json['primaryCultureCode'] as String?,
  currencySymbol: json['currencySymbol'] as String?,
  digitsAfterDecimal: (json['digitsAfterDecimal'] as num?)?.toInt(),
  bankScheme: json['bankScheme'] as String?,
  bankAccountNumber: json['bankAccountNumber'] as String?,
  bankBic: json['bankBic'] as String?,
  bankBeneficiary: json['bankBeneficiary'] as String?,
  kennelPaymentScheme: json['kennelPaymentScheme'] as String?,
  kennelPaymentUrl: json['kennelPaymentUrl'] as String?,
  kennelPaymentUrlExpires: json['kennelPaymentUrlExpires'] == null
      ? null
      : DateTime.parse(json['kennelPaymentUrlExpires'] as String),
  kennelPaymentMemberSurcharge: (json['kennelPaymentMemberSurcharge'] as num?)
      ?.toDouble(),
  kennelPaymentNonMemberSurcharge:
      (json['kennelPaymentNonMemberSurcharge'] as num?)?.toDouble(),
  kennelPaymentScheme2: json['kennelPaymentScheme2'] as String?,
  kennelPaymentUrl2: json['kennelPaymentUrl2'] as String?,
  kennelPaymentUrlExpires2: json['kennelPaymentUrlExpires2'] == null
      ? null
      : DateTime.parse(json['kennelPaymentUrlExpires2'] as String),
  kennelPaymentMemberSurcharge2: (json['kennelPaymentMemberSurcharge2'] as num?)
      ?.toDouble(),
  kennelPaymentNonMemberSurcharge2:
      (json['kennelPaymentNonMemberSurcharge2'] as num?)?.toDouble(),
  kennelPaymentScheme3: json['kennelPaymentScheme3'] as String?,
  kennelPaymentUrl3: json['kennelPaymentUrl3'] as String?,
  kennelPaymentUrlExpires3: json['kennelPaymentUrlExpires3'] == null
      ? null
      : DateTime.parse(json['kennelPaymentUrlExpires3'] as String),
  kennelPaymentMemberSurcharge3: (json['kennelPaymentMemberSurcharge3'] as num?)
      ?.toDouble(),
  kennelPaymentNonMemberSurcharge3:
      (json['kennelPaymentNonMemberSurcharge3'] as num?)?.toDouble(),
  runCountStartDate: json['runCountStartDate'] == null
      ? null
      : DateTime.parse(json['runCountStartDate'] as String),
  kennelMismanagementTeam: json['kennelMismanagementTeam'] as String?,
  distancePreference: (json['distancePreference'] as num?)?.toInt(),
  trailSymbolsConfigJson: json['trailSymbolsConfigJson'] as String?,
  trailTypesConfigJson: json['trailTypesConfigJson'] as String?,
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
  removed: (json['removed'] as num?)?.toInt(),
);

Map<String, dynamic> _$KennelsModelToJson(
  _KennelsModel instance,
) => <String, dynamic>{
  'kennelId': instance.kennelId,
  'publicKennelId': instance.publicKennelId,
  'cityId': instance.cityId,
  'regionId': instance.regionId,
  'countryId': instance.countryId,
  'kennelName': instance.kennelName,
  'kennelSearchTags': instance.kennelSearchTags,
  'kennelShortName': instance.kennelShortName,
  'kennelUniqueShortName': instance.kennelUniqueShortName,
  'kennelDescription': instance.kennelDescription,
  'kennelLogo': instance.kennelLogo,
  'kennelPinColor': instance.kennelPinColor,
  'disseminateAllowWebLinks': instance.disseminateAllowWebLinks,
  'allowCredit': instance.allowCredit,
  'kennelCoverPhoto': instance.kennelCoverPhoto,
  'kennelWebsiteUrl': instance.kennelWebsiteUrl,
  'defaultEventCurrencyType': instance.defaultEventCurrencyType,
  'integrationType': instance.integrationType,
  'kennelInboundIntegrationId': instance.kennelInboundIntegrationId,
  'kennelEventsUrl': instance.kennelEventsUrl,
  'kennelStatus': instance.kennelStatus,
  'canEditRunAttendence': instance.canEditRunAttendence,
  'allowNegativeCredit': instance.allowNegativeCredit,
  'allowSelfPayment': instance.allowSelfPayment,
  'kennelLatitude': instance.kennelLatitude,
  'kennelLongitude': instance.kennelLongitude,
  'defaultPriceForMembers': instance.defaultPriceForMembers,
  'defaultPriceForNonMembers': instance.defaultPriceForNonMembers,
  'membershipDurationInMonths': instance.membershipDurationInMonths,
  'defaultRunStartTime': instance.defaultRunStartTime.toIso8601String(),
  'currencyCode': instance.currencyCode,
  'primaryCultureCode': instance.primaryCultureCode,
  'currencySymbol': instance.currencySymbol,
  'digitsAfterDecimal': instance.digitsAfterDecimal,
  'bankScheme': instance.bankScheme,
  'bankAccountNumber': instance.bankAccountNumber,
  'bankBic': instance.bankBic,
  'bankBeneficiary': instance.bankBeneficiary,
  'kennelPaymentScheme': instance.kennelPaymentScheme,
  'kennelPaymentUrl': instance.kennelPaymentUrl,
  'kennelPaymentUrlExpires': instance.kennelPaymentUrlExpires
      ?.toIso8601String(),
  'kennelPaymentMemberSurcharge': instance.kennelPaymentMemberSurcharge,
  'kennelPaymentNonMemberSurcharge': instance.kennelPaymentNonMemberSurcharge,
  'kennelPaymentScheme2': instance.kennelPaymentScheme2,
  'kennelPaymentUrl2': instance.kennelPaymentUrl2,
  'kennelPaymentUrlExpires2': instance.kennelPaymentUrlExpires2
      ?.toIso8601String(),
  'kennelPaymentMemberSurcharge2': instance.kennelPaymentMemberSurcharge2,
  'kennelPaymentNonMemberSurcharge2': instance.kennelPaymentNonMemberSurcharge2,
  'kennelPaymentScheme3': instance.kennelPaymentScheme3,
  'kennelPaymentUrl3': instance.kennelPaymentUrl3,
  'kennelPaymentUrlExpires3': instance.kennelPaymentUrlExpires3
      ?.toIso8601String(),
  'kennelPaymentMemberSurcharge3': instance.kennelPaymentMemberSurcharge3,
  'kennelPaymentNonMemberSurcharge3': instance.kennelPaymentNonMemberSurcharge3,
  'runCountStartDate': instance.runCountStartDate?.toIso8601String(),
  'kennelMismanagementTeam': instance.kennelMismanagementTeam,
  'distancePreference': instance.distancePreference,
  'trailSymbolsConfigJson': instance.trailSymbolsConfigJson,
  'trailTypesConfigJson': instance.trailTypesConfigJson,
  'updatedAt': instance.updatedAt?.toIso8601String(),
  'removed': instance.removed,
};
