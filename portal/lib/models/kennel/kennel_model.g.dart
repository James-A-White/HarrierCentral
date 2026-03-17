// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kennel_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_KennelModel _$KennelModelFromJson(Map<String, dynamic> json) => _KennelModel(
      kennelPublicId:
          const UuidConverter().fromJson(json['kennelPublicId'] as String),
      kennelName: json['kennelName'] as String,
      kennelShortName: json['kennelShortName'] as String,
      kennelUniqueShortName: json['kennelUniqueShortName'] as String,
      kennelLogo: json['kennelLogo'] as String,
      kennelDescription: json['kennelDescription'] as String,
      excludeFromLeaderboard: (json['excludeFromLeaderboard'] as num).toInt(),
      cityName: json['cityName'] as String,
      regionName: json['regionName'] as String,
      countryName: json['countryName'] as String,
      continentName: json['continentName'] as String,
      kennelStatus: (json['kennelStatus'] as num).toInt(),
      disseminateHashRunsDotOrg:
          (json['disseminateHashRunsDotOrg'] as num).toInt(),
      disseminateAllowWebLinks:
          (json['disseminateAllowWebLinks'] as num).toInt(),
      disseminationAudience: (json['disseminationAudience'] as num).toInt(),
      disseminateOnGlobalGoogleCalendar:
          (json['disseminateOnGlobalGoogleCalendar'] as num).toInt(),
      canEditRunAttendence: (json['canEditRunAttendence'] as num).toInt(),
      kennelPinColor: (json['kennelPinColor'] as num).toInt(),
      defaultEventPriceForMembers:
          (json['defaultEventPriceForMembers'] as num).toDouble(),
      defaultEventPriceForNonMembers:
          (json['defaultEventPriceForNonMembers'] as num).toDouble(),
      defaultRunStartTime:
          DateTime.parse(json['defaultRunStartTime'] as String),
      allowSelfPayment: (json['allowSelfPayment'] as num).toInt(),
      allowNegativeCredit: (json['allowNegativeCredit'] as num).toInt(),
      cityId: const UuidConverter().fromJson(json['cityId'] as String),
      provinceStateId:
          const UuidConverter().fromJson(json['provinceStateId'] as String),
      countryId: const UuidConverter().fromJson(json['countryId'] as String),
      defaultRunTags1: (json['defaultRunTags1'] as num).toInt(),
      defaultRunTags2: (json['defaultRunTags2'] as num).toInt(),
      defaultRunTags3: (json['defaultRunTags3'] as num).toInt(),
      membershipDurationInMonths:
          (json['membershipDurationInMonths'] as num).toInt(),
      defaultDistancePreference:
          (json['defaultDistancePreference'] as num).toInt(),
      notificationMinutesBeforeRunForChatPushNotifications:
          (json['notificationMinutesBeforeRunForChatPushNotifications'] as num)
              .toInt(),
      notificationMinutesBeforeRunForCheckinReminder:
          (json['notificationMinutesBeforeRunForCheckinReminder'] as num)
              .toInt(),
      extApiKey: json['extApiKey'] as String,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      defaultLatitude: (json['defaultLatitude'] as num?)?.toDouble(),
      defaultLongitude: (json['defaultLongitude'] as num?)?.toDouble(),
      publishToGoogleCalendar:
          (json['publishToGoogleCalendar'] as num?)?.toInt(),
      publishToGoogleCalendarAddresses:
          json['publishToGoogleCalendarAddresses'] as String?,
      mismanagementTeam: json['mismanagementTeam'] as String?,
      kennelCoverPhoto: json['kennelCoverPhoto'] as String?,
      countryFlag: json['countryFlag'] as String?,
      regionFlag: json['regionFlag'] as String?,
      cityFlag: json['cityFlag'] as String?,
      websiteBackgroundColor: json['websiteBackgroundColor'] as String?,
      websiteBackgroundImage: json['websiteBackgroundImage'] as String?,
      websiteTitleText: json['websiteTitleText'] as String?,
      websiteMenuBackgroundColor: json['websiteMenuBackgroundColor'] as String?,
      websiteMenuTextColor: json['websiteMenuTextColor'] as String?,
      websiteWelcomeText: json['websiteWelcomeText'] as String?,
      websiteBodyTextColor: json['websiteBodyTextColor'] as String?,
      websiteTitleTextColor: json['websiteTitleTextColor'] as String?,
      websiteMismanagementDescription:
          json['websiteMismanagementDescription'] as String?,
      websiteMismanagementJson: json['websiteMismanagementJson'] as String?,
      websiteExtraMenusJson: json['websiteExtraMenusJson'] as String?,
      websiteControlFlags: (json['websiteControlFlags'] as num?)?.toInt(),
      websiteContactDetailsJson: json['websiteContactDetailsJson'] as String?,
      websiteBannerImage: json['websiteBannerImage'] as String?,
      websiteUrlShortcode: json['websiteUrlShortcode'] as String?,
      websiteTitleFont: json['websiteTitleFont'] as String?,
      websiteBodyFont: json['websiteBodyFont'] as String?,
      kennelAdminEmailList: json['kennelAdminEmailList'] as String?,
      kennelWebsiteUrl: json['kennelWebsiteUrl'] as String?,
      kennelEventsUrl: json['kennelEventsUrl'] as String?,
      kennelHcEventsUrl: json['kennelHcEventsUrl'] as String?,
      bankScheme: json['bankScheme'] as String?,
      bankAccountNumber: json['bankAccountNumber'] as String?,
      bankBic: json['bankBic'] as String?,
      bankBeneficiary: json['bankBeneficiary'] as String?,
      kennelPaymentScheme: json['kennelPaymentScheme'] as String?,
      kennelPaymentUrl: json['kennelPaymentUrl'] as String?,
      kennelPaymentUrlExpires: json['kennelPaymentUrlExpires'] == null
          ? null
          : DateTime.parse(json['kennelPaymentUrlExpires'] as String),
      kennelPaymentMemberSurcharge:
          (json['kennelPaymentMemberSurcharge'] as num?)?.toDouble(),
      kennelPaymentNonMemberSurcharge:
          (json['kennelPaymentNonMemberSurcharge'] as num?)?.toDouble(),
      kennelPaymentScheme2: json['kennelPaymentScheme2'] as String?,
      kennelPaymentUrl2: json['kennelPaymentUrl2'] as String?,
      kennelPaymentUrlExpires2: json['kennelPaymentUrlExpires2'] == null
          ? null
          : DateTime.parse(json['kennelPaymentUrlExpires2'] as String),
      kennelPaymentMemberSurcharge2:
          (json['kennelPaymentMemberSurcharge2'] as num?)?.toDouble(),
      kennelPaymentNonMemberSurcharge2:
          (json['kennelPaymentNonMemberSurcharge2'] as num?)?.toDouble(),
      kennelPaymentScheme3: json['kennelPaymentScheme3'] as String?,
      kennelPaymentUrl3: json['kennelPaymentUrl3'] as String?,
      kennelPaymentUrlExpires3: json['kennelPaymentUrlExpires3'] == null
          ? null
          : DateTime.parse(json['kennelPaymentUrlExpires3'] as String),
      kennelPaymentMemberSurcharge3:
          (json['kennelPaymentMemberSurcharge3'] as num?)?.toDouble(),
      kennelPaymentNonMemberSurcharge3:
          (json['kennelPaymentNonMemberSurcharge3'] as num?)?.toDouble(),
      runCountStartDate: json['runCountStartDate'] == null
          ? null
          : DateTime.parse(json['runCountStartDate'] as String),
      distancePreference: (json['distancePreference'] as num?)?.toInt(),
      kennelSearchTags: json['kennelSearchTags'] as String?,
    );

Map<String, dynamic> _$KennelModelToJson(_KennelModel instance) =>
    <String, dynamic>{
      'kennelPublicId': const UuidConverter().toJson(instance.kennelPublicId),
      'kennelName': instance.kennelName,
      'kennelShortName': instance.kennelShortName,
      'kennelUniqueShortName': instance.kennelUniqueShortName,
      'kennelLogo': instance.kennelLogo,
      'kennelDescription': instance.kennelDescription,
      'excludeFromLeaderboard': instance.excludeFromLeaderboard,
      'cityName': instance.cityName,
      'regionName': instance.regionName,
      'countryName': instance.countryName,
      'continentName': instance.continentName,
      'kennelStatus': instance.kennelStatus,
      'disseminateHashRunsDotOrg': instance.disseminateHashRunsDotOrg,
      'disseminateAllowWebLinks': instance.disseminateAllowWebLinks,
      'disseminationAudience': instance.disseminationAudience,
      'disseminateOnGlobalGoogleCalendar':
          instance.disseminateOnGlobalGoogleCalendar,
      'canEditRunAttendence': instance.canEditRunAttendence,
      'kennelPinColor': instance.kennelPinColor,
      'defaultEventPriceForMembers': instance.defaultEventPriceForMembers,
      'defaultEventPriceForNonMembers': instance.defaultEventPriceForNonMembers,
      'defaultRunStartTime': instance.defaultRunStartTime.toIso8601String(),
      'allowSelfPayment': instance.allowSelfPayment,
      'allowNegativeCredit': instance.allowNegativeCredit,
      'cityId': const UuidConverter().toJson(instance.cityId),
      'provinceStateId': const UuidConverter().toJson(instance.provinceStateId),
      'countryId': const UuidConverter().toJson(instance.countryId),
      'defaultRunTags1': instance.defaultRunTags1,
      'defaultRunTags2': instance.defaultRunTags2,
      'defaultRunTags3': instance.defaultRunTags3,
      'membershipDurationInMonths': instance.membershipDurationInMonths,
      'defaultDistancePreference': instance.defaultDistancePreference,
      'notificationMinutesBeforeRunForChatPushNotifications':
          instance.notificationMinutesBeforeRunForChatPushNotifications,
      'notificationMinutesBeforeRunForCheckinReminder':
          instance.notificationMinutesBeforeRunForCheckinReminder,
      'extApiKey': instance.extApiKey,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'defaultLatitude': instance.defaultLatitude,
      'defaultLongitude': instance.defaultLongitude,
      'publishToGoogleCalendar': instance.publishToGoogleCalendar,
      'publishToGoogleCalendarAddresses':
          instance.publishToGoogleCalendarAddresses,
      'mismanagementTeam': instance.mismanagementTeam,
      'kennelCoverPhoto': instance.kennelCoverPhoto,
      'countryFlag': instance.countryFlag,
      'regionFlag': instance.regionFlag,
      'cityFlag': instance.cityFlag,
      'websiteBackgroundColor': instance.websiteBackgroundColor,
      'websiteBackgroundImage': instance.websiteBackgroundImage,
      'websiteTitleText': instance.websiteTitleText,
      'websiteMenuBackgroundColor': instance.websiteMenuBackgroundColor,
      'websiteMenuTextColor': instance.websiteMenuTextColor,
      'websiteWelcomeText': instance.websiteWelcomeText,
      'websiteBodyTextColor': instance.websiteBodyTextColor,
      'websiteTitleTextColor': instance.websiteTitleTextColor,
      'websiteMismanagementDescription':
          instance.websiteMismanagementDescription,
      'websiteMismanagementJson': instance.websiteMismanagementJson,
      'websiteExtraMenusJson': instance.websiteExtraMenusJson,
      'websiteControlFlags': instance.websiteControlFlags,
      'websiteContactDetailsJson': instance.websiteContactDetailsJson,
      'websiteBannerImage': instance.websiteBannerImage,
      'websiteUrlShortcode': instance.websiteUrlShortcode,
      'websiteTitleFont': instance.websiteTitleFont,
      'websiteBodyFont': instance.websiteBodyFont,
      'kennelAdminEmailList': instance.kennelAdminEmailList,
      'kennelWebsiteUrl': instance.kennelWebsiteUrl,
      'kennelEventsUrl': instance.kennelEventsUrl,
      'kennelHcEventsUrl': instance.kennelHcEventsUrl,
      'bankScheme': instance.bankScheme,
      'bankAccountNumber': instance.bankAccountNumber,
      'bankBic': instance.bankBic,
      'bankBeneficiary': instance.bankBeneficiary,
      'kennelPaymentScheme': instance.kennelPaymentScheme,
      'kennelPaymentUrl': instance.kennelPaymentUrl,
      'kennelPaymentUrlExpires':
          instance.kennelPaymentUrlExpires?.toIso8601String(),
      'kennelPaymentMemberSurcharge': instance.kennelPaymentMemberSurcharge,
      'kennelPaymentNonMemberSurcharge':
          instance.kennelPaymentNonMemberSurcharge,
      'kennelPaymentScheme2': instance.kennelPaymentScheme2,
      'kennelPaymentUrl2': instance.kennelPaymentUrl2,
      'kennelPaymentUrlExpires2':
          instance.kennelPaymentUrlExpires2?.toIso8601String(),
      'kennelPaymentMemberSurcharge2': instance.kennelPaymentMemberSurcharge2,
      'kennelPaymentNonMemberSurcharge2':
          instance.kennelPaymentNonMemberSurcharge2,
      'kennelPaymentScheme3': instance.kennelPaymentScheme3,
      'kennelPaymentUrl3': instance.kennelPaymentUrl3,
      'kennelPaymentUrlExpires3':
          instance.kennelPaymentUrlExpires3?.toIso8601String(),
      'kennelPaymentMemberSurcharge3': instance.kennelPaymentMemberSurcharge3,
      'kennelPaymentNonMemberSurcharge3':
          instance.kennelPaymentNonMemberSurcharge3,
      'runCountStartDate': instance.runCountStartDate?.toIso8601String(),
      'distancePreference': instance.distancePreference,
      'kennelSearchTags': instance.kennelSearchTags,
    };
