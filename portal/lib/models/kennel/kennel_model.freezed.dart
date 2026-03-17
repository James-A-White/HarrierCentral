// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'kennel_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$KennelModel {
  @UuidConverter()
  UuidValue get kennelPublicId;
  String get kennelName;
  String get kennelShortName;
  String get kennelUniqueShortName;
  String get kennelLogo;
  String get kennelDescription;
  int get excludeFromLeaderboard;
  String get cityName;
  String get regionName;
  String get countryName;
  String get continentName;
  int get kennelStatus;
  int get disseminateHashRunsDotOrg;
  int get disseminateAllowWebLinks;
  int get disseminationAudience;
  int get disseminateOnGlobalGoogleCalendar;
  int get canEditRunAttendence;
  int get kennelPinColor;
  double get defaultEventPriceForMembers;
  double get defaultEventPriceForNonMembers;
  DateTime get defaultRunStartTime;
  int get allowSelfPayment;
  int get allowNegativeCredit;
  @UuidConverter()
  UuidValue get cityId;
  @UuidConverter()
  UuidValue get provinceStateId;
  @UuidConverter()
  UuidValue get countryId;
  int get defaultRunTags1;
  int get defaultRunTags2;
  int get defaultRunTags3;
  int get membershipDurationInMonths;
  int get defaultDistancePreference;
  int get notificationMinutesBeforeRunForChatPushNotifications;
  int get notificationMinutesBeforeRunForCheckinReminder;
  String get extApiKey;
  double? get latitude;
  double? get longitude;
  double? get defaultLatitude;
  double? get defaultLongitude; //String? googleCalendarId,
  int? get publishToGoogleCalendar;
  String? get publishToGoogleCalendarAddresses;
  String? get mismanagementTeam;
  String? get kennelCoverPhoto;
  String? get countryFlag;
  String? get regionFlag;
  String? get cityFlag;
  String? get websiteBackgroundColor;
  String? get websiteBackgroundImage;
  String? get websiteTitleText;
  String? get websiteMenuBackgroundColor;
  String? get websiteMenuTextColor;
  String? get websiteWelcomeText;
  String? get websiteBodyTextColor;
  String? get websiteTitleTextColor;
  String? get websiteMismanagementDescription;
  String? get websiteMismanagementJson;
  String? get websiteExtraMenusJson;
  int? get websiteControlFlags;
  String? get websiteContactDetailsJson;
  String? get websiteBannerImage;
  String? get websiteUrlShortcode;
  String? get websiteTitleFont;
  String? get websiteBodyFont;
  String? get kennelAdminEmailList;
  String? get kennelWebsiteUrl;
  String? get kennelEventsUrl;
  String? get kennelHcEventsUrl;
  String? get bankScheme;
  String? get bankAccountNumber;
  String? get bankBic;
  String? get bankBeneficiary;
  String? get kennelPaymentScheme;
  String? get kennelPaymentUrl;
  DateTime? get kennelPaymentUrlExpires;
  double? get kennelPaymentMemberSurcharge;
  double? get kennelPaymentNonMemberSurcharge;
  String? get kennelPaymentScheme2;
  String? get kennelPaymentUrl2;
  DateTime? get kennelPaymentUrlExpires2;
  double? get kennelPaymentMemberSurcharge2;
  double? get kennelPaymentNonMemberSurcharge2;
  String? get kennelPaymentScheme3;
  String? get kennelPaymentUrl3;
  DateTime? get kennelPaymentUrlExpires3;
  double? get kennelPaymentMemberSurcharge3;
  double? get kennelPaymentNonMemberSurcharge3;
  DateTime? get runCountStartDate;
  int? get distancePreference;
  String? get kennelSearchTags;

  /// Create a copy of KennelModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $KennelModelCopyWith<KennelModel> get copyWith =>
      _$KennelModelCopyWithImpl<KennelModel>(this as KennelModel, _$identity);

  /// Serializes this KennelModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is KennelModel &&
            (identical(other.kennelPublicId, kennelPublicId) ||
                other.kennelPublicId == kennelPublicId) &&
            (identical(other.kennelName, kennelName) ||
                other.kennelName == kennelName) &&
            (identical(other.kennelShortName, kennelShortName) ||
                other.kennelShortName == kennelShortName) &&
            (identical(other.kennelUniqueShortName, kennelUniqueShortName) ||
                other.kennelUniqueShortName == kennelUniqueShortName) &&
            (identical(other.kennelLogo, kennelLogo) ||
                other.kennelLogo == kennelLogo) &&
            (identical(other.kennelDescription, kennelDescription) ||
                other.kennelDescription == kennelDescription) &&
            (identical(other.excludeFromLeaderboard, excludeFromLeaderboard) ||
                other.excludeFromLeaderboard == excludeFromLeaderboard) &&
            (identical(other.cityName, cityName) ||
                other.cityName == cityName) &&
            (identical(other.regionName, regionName) ||
                other.regionName == regionName) &&
            (identical(other.countryName, countryName) ||
                other.countryName == countryName) &&
            (identical(other.continentName, continentName) ||
                other.continentName == continentName) &&
            (identical(other.kennelStatus, kennelStatus) ||
                other.kennelStatus == kennelStatus) &&
            (identical(other.disseminateHashRunsDotOrg, disseminateHashRunsDotOrg) ||
                other.disseminateHashRunsDotOrg == disseminateHashRunsDotOrg) &&
            (identical(other.disseminateAllowWebLinks, disseminateAllowWebLinks) ||
                other.disseminateAllowWebLinks == disseminateAllowWebLinks) &&
            (identical(other.disseminationAudience, disseminationAudience) ||
                other.disseminationAudience == disseminationAudience) &&
            (identical(other.disseminateOnGlobalGoogleCalendar, disseminateOnGlobalGoogleCalendar) ||
                other.disseminateOnGlobalGoogleCalendar ==
                    disseminateOnGlobalGoogleCalendar) &&
            (identical(other.canEditRunAttendence, canEditRunAttendence) ||
                other.canEditRunAttendence == canEditRunAttendence) &&
            (identical(other.kennelPinColor, kennelPinColor) ||
                other.kennelPinColor == kennelPinColor) &&
            (identical(other.defaultEventPriceForMembers, defaultEventPriceForMembers) ||
                other.defaultEventPriceForMembers ==
                    defaultEventPriceForMembers) &&
            (identical(other.defaultEventPriceForNonMembers, defaultEventPriceForNonMembers) ||
                other.defaultEventPriceForNonMembers ==
                    defaultEventPriceForNonMembers) &&
            (identical(other.defaultRunStartTime, defaultRunStartTime) ||
                other.defaultRunStartTime == defaultRunStartTime) &&
            (identical(other.allowSelfPayment, allowSelfPayment) ||
                other.allowSelfPayment == allowSelfPayment) &&
            (identical(other.allowNegativeCredit, allowNegativeCredit) ||
                other.allowNegativeCredit == allowNegativeCredit) &&
            (identical(other.cityId, cityId) || other.cityId == cityId) &&
            (identical(other.provinceStateId, provinceStateId) ||
                other.provinceStateId == provinceStateId) &&
            (identical(other.countryId, countryId) ||
                other.countryId == countryId) &&
            (identical(other.defaultRunTags1, defaultRunTags1) ||
                other.defaultRunTags1 == defaultRunTags1) &&
            (identical(other.defaultRunTags2, defaultRunTags2) ||
                other.defaultRunTags2 == defaultRunTags2) &&
            (identical(other.defaultRunTags3, defaultRunTags3) ||
                other.defaultRunTags3 == defaultRunTags3) &&
            (identical(other.membershipDurationInMonths, membershipDurationInMonths) || other.membershipDurationInMonths == membershipDurationInMonths) &&
            (identical(other.defaultDistancePreference, defaultDistancePreference) || other.defaultDistancePreference == defaultDistancePreference) &&
            (identical(other.notificationMinutesBeforeRunForChatPushNotifications, notificationMinutesBeforeRunForChatPushNotifications) || other.notificationMinutesBeforeRunForChatPushNotifications == notificationMinutesBeforeRunForChatPushNotifications) &&
            (identical(other.notificationMinutesBeforeRunForCheckinReminder, notificationMinutesBeforeRunForCheckinReminder) || other.notificationMinutesBeforeRunForCheckinReminder == notificationMinutesBeforeRunForCheckinReminder) &&
            (identical(other.extApiKey, extApiKey) || other.extApiKey == extApiKey) &&
            (identical(other.latitude, latitude) || other.latitude == latitude) &&
            (identical(other.longitude, longitude) || other.longitude == longitude) &&
            (identical(other.defaultLatitude, defaultLatitude) || other.defaultLatitude == defaultLatitude) &&
            (identical(other.defaultLongitude, defaultLongitude) || other.defaultLongitude == defaultLongitude) &&
            (identical(other.publishToGoogleCalendar, publishToGoogleCalendar) || other.publishToGoogleCalendar == publishToGoogleCalendar) &&
            (identical(other.publishToGoogleCalendarAddresses, publishToGoogleCalendarAddresses) || other.publishToGoogleCalendarAddresses == publishToGoogleCalendarAddresses) &&
            (identical(other.mismanagementTeam, mismanagementTeam) || other.mismanagementTeam == mismanagementTeam) &&
            (identical(other.kennelCoverPhoto, kennelCoverPhoto) || other.kennelCoverPhoto == kennelCoverPhoto) &&
            (identical(other.countryFlag, countryFlag) || other.countryFlag == countryFlag) &&
            (identical(other.regionFlag, regionFlag) || other.regionFlag == regionFlag) &&
            (identical(other.cityFlag, cityFlag) || other.cityFlag == cityFlag) &&
            (identical(other.websiteBackgroundColor, websiteBackgroundColor) || other.websiteBackgroundColor == websiteBackgroundColor) &&
            (identical(other.websiteBackgroundImage, websiteBackgroundImage) || other.websiteBackgroundImage == websiteBackgroundImage) &&
            (identical(other.websiteTitleText, websiteTitleText) || other.websiteTitleText == websiteTitleText) &&
            (identical(other.websiteMenuBackgroundColor, websiteMenuBackgroundColor) || other.websiteMenuBackgroundColor == websiteMenuBackgroundColor) &&
            (identical(other.websiteMenuTextColor, websiteMenuTextColor) || other.websiteMenuTextColor == websiteMenuTextColor) &&
            (identical(other.websiteWelcomeText, websiteWelcomeText) || other.websiteWelcomeText == websiteWelcomeText) &&
            (identical(other.websiteBodyTextColor, websiteBodyTextColor) || other.websiteBodyTextColor == websiteBodyTextColor) &&
            (identical(other.websiteTitleTextColor, websiteTitleTextColor) || other.websiteTitleTextColor == websiteTitleTextColor) &&
            (identical(other.websiteMismanagementDescription, websiteMismanagementDescription) || other.websiteMismanagementDescription == websiteMismanagementDescription) &&
            (identical(other.websiteMismanagementJson, websiteMismanagementJson) || other.websiteMismanagementJson == websiteMismanagementJson) &&
            (identical(other.websiteExtraMenusJson, websiteExtraMenusJson) || other.websiteExtraMenusJson == websiteExtraMenusJson) &&
            (identical(other.websiteControlFlags, websiteControlFlags) || other.websiteControlFlags == websiteControlFlags) &&
            (identical(other.websiteContactDetailsJson, websiteContactDetailsJson) || other.websiteContactDetailsJson == websiteContactDetailsJson) &&
            (identical(other.websiteBannerImage, websiteBannerImage) || other.websiteBannerImage == websiteBannerImage) &&
            (identical(other.websiteUrlShortcode, websiteUrlShortcode) || other.websiteUrlShortcode == websiteUrlShortcode) &&
            (identical(other.websiteTitleFont, websiteTitleFont) || other.websiteTitleFont == websiteTitleFont) &&
            (identical(other.websiteBodyFont, websiteBodyFont) || other.websiteBodyFont == websiteBodyFont) &&
            (identical(other.kennelAdminEmailList, kennelAdminEmailList) || other.kennelAdminEmailList == kennelAdminEmailList) &&
            (identical(other.kennelWebsiteUrl, kennelWebsiteUrl) || other.kennelWebsiteUrl == kennelWebsiteUrl) &&
            (identical(other.kennelEventsUrl, kennelEventsUrl) || other.kennelEventsUrl == kennelEventsUrl) &&
            (identical(other.kennelHcEventsUrl, kennelHcEventsUrl) || other.kennelHcEventsUrl == kennelHcEventsUrl) &&
            (identical(other.bankScheme, bankScheme) || other.bankScheme == bankScheme) &&
            (identical(other.bankAccountNumber, bankAccountNumber) || other.bankAccountNumber == bankAccountNumber) &&
            (identical(other.bankBic, bankBic) || other.bankBic == bankBic) &&
            (identical(other.bankBeneficiary, bankBeneficiary) || other.bankBeneficiary == bankBeneficiary) &&
            (identical(other.kennelPaymentScheme, kennelPaymentScheme) || other.kennelPaymentScheme == kennelPaymentScheme) &&
            (identical(other.kennelPaymentUrl, kennelPaymentUrl) || other.kennelPaymentUrl == kennelPaymentUrl) &&
            (identical(other.kennelPaymentUrlExpires, kennelPaymentUrlExpires) || other.kennelPaymentUrlExpires == kennelPaymentUrlExpires) &&
            (identical(other.kennelPaymentMemberSurcharge, kennelPaymentMemberSurcharge) || other.kennelPaymentMemberSurcharge == kennelPaymentMemberSurcharge) &&
            (identical(other.kennelPaymentNonMemberSurcharge, kennelPaymentNonMemberSurcharge) || other.kennelPaymentNonMemberSurcharge == kennelPaymentNonMemberSurcharge) &&
            (identical(other.kennelPaymentScheme2, kennelPaymentScheme2) || other.kennelPaymentScheme2 == kennelPaymentScheme2) &&
            (identical(other.kennelPaymentUrl2, kennelPaymentUrl2) || other.kennelPaymentUrl2 == kennelPaymentUrl2) &&
            (identical(other.kennelPaymentUrlExpires2, kennelPaymentUrlExpires2) || other.kennelPaymentUrlExpires2 == kennelPaymentUrlExpires2) &&
            (identical(other.kennelPaymentMemberSurcharge2, kennelPaymentMemberSurcharge2) || other.kennelPaymentMemberSurcharge2 == kennelPaymentMemberSurcharge2) &&
            (identical(other.kennelPaymentNonMemberSurcharge2, kennelPaymentNonMemberSurcharge2) || other.kennelPaymentNonMemberSurcharge2 == kennelPaymentNonMemberSurcharge2) &&
            (identical(other.kennelPaymentScheme3, kennelPaymentScheme3) || other.kennelPaymentScheme3 == kennelPaymentScheme3) &&
            (identical(other.kennelPaymentUrl3, kennelPaymentUrl3) || other.kennelPaymentUrl3 == kennelPaymentUrl3) &&
            (identical(other.kennelPaymentUrlExpires3, kennelPaymentUrlExpires3) || other.kennelPaymentUrlExpires3 == kennelPaymentUrlExpires3) &&
            (identical(other.kennelPaymentMemberSurcharge3, kennelPaymentMemberSurcharge3) || other.kennelPaymentMemberSurcharge3 == kennelPaymentMemberSurcharge3) &&
            (identical(other.kennelPaymentNonMemberSurcharge3, kennelPaymentNonMemberSurcharge3) || other.kennelPaymentNonMemberSurcharge3 == kennelPaymentNonMemberSurcharge3) &&
            (identical(other.runCountStartDate, runCountStartDate) || other.runCountStartDate == runCountStartDate) &&
            (identical(other.distancePreference, distancePreference) || other.distancePreference == distancePreference) &&
            (identical(other.kennelSearchTags, kennelSearchTags) || other.kennelSearchTags == kennelSearchTags));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        kennelPublicId,
        kennelName,
        kennelShortName,
        kennelUniqueShortName,
        kennelLogo,
        kennelDescription,
        excludeFromLeaderboard,
        cityName,
        regionName,
        countryName,
        continentName,
        kennelStatus,
        disseminateHashRunsDotOrg,
        disseminateAllowWebLinks,
        disseminationAudience,
        disseminateOnGlobalGoogleCalendar,
        canEditRunAttendence,
        kennelPinColor,
        defaultEventPriceForMembers,
        defaultEventPriceForNonMembers,
        defaultRunStartTime,
        allowSelfPayment,
        allowNegativeCredit,
        cityId,
        provinceStateId,
        countryId,
        defaultRunTags1,
        defaultRunTags2,
        defaultRunTags3,
        membershipDurationInMonths,
        defaultDistancePreference,
        notificationMinutesBeforeRunForChatPushNotifications,
        notificationMinutesBeforeRunForCheckinReminder,
        extApiKey,
        latitude,
        longitude,
        defaultLatitude,
        defaultLongitude,
        publishToGoogleCalendar,
        publishToGoogleCalendarAddresses,
        mismanagementTeam,
        kennelCoverPhoto,
        countryFlag,
        regionFlag,
        cityFlag,
        websiteBackgroundColor,
        websiteBackgroundImage,
        websiteTitleText,
        websiteMenuBackgroundColor,
        websiteMenuTextColor,
        websiteWelcomeText,
        websiteBodyTextColor,
        websiteTitleTextColor,
        websiteMismanagementDescription,
        websiteMismanagementJson,
        websiteExtraMenusJson,
        websiteControlFlags,
        websiteContactDetailsJson,
        websiteBannerImage,
        websiteUrlShortcode,
        websiteTitleFont,
        websiteBodyFont,
        kennelAdminEmailList,
        kennelWebsiteUrl,
        kennelEventsUrl,
        kennelHcEventsUrl,
        bankScheme,
        bankAccountNumber,
        bankBic,
        bankBeneficiary,
        kennelPaymentScheme,
        kennelPaymentUrl,
        kennelPaymentUrlExpires,
        kennelPaymentMemberSurcharge,
        kennelPaymentNonMemberSurcharge,
        kennelPaymentScheme2,
        kennelPaymentUrl2,
        kennelPaymentUrlExpires2,
        kennelPaymentMemberSurcharge2,
        kennelPaymentNonMemberSurcharge2,
        kennelPaymentScheme3,
        kennelPaymentUrl3,
        kennelPaymentUrlExpires3,
        kennelPaymentMemberSurcharge3,
        kennelPaymentNonMemberSurcharge3,
        runCountStartDate,
        distancePreference,
        kennelSearchTags
      ]);

  @override
  String toString() {
    return 'KennelModel(kennelPublicId: $kennelPublicId, kennelName: $kennelName, kennelShortName: $kennelShortName, kennelUniqueShortName: $kennelUniqueShortName, kennelLogo: $kennelLogo, kennelDescription: $kennelDescription, excludeFromLeaderboard: $excludeFromLeaderboard, cityName: $cityName, regionName: $regionName, countryName: $countryName, continentName: $continentName, kennelStatus: $kennelStatus, disseminateHashRunsDotOrg: $disseminateHashRunsDotOrg, disseminateAllowWebLinks: $disseminateAllowWebLinks, disseminationAudience: $disseminationAudience, disseminateOnGlobalGoogleCalendar: $disseminateOnGlobalGoogleCalendar, canEditRunAttendence: $canEditRunAttendence, kennelPinColor: $kennelPinColor, defaultEventPriceForMembers: $defaultEventPriceForMembers, defaultEventPriceForNonMembers: $defaultEventPriceForNonMembers, defaultRunStartTime: $defaultRunStartTime, allowSelfPayment: $allowSelfPayment, allowNegativeCredit: $allowNegativeCredit, cityId: $cityId, provinceStateId: $provinceStateId, countryId: $countryId, defaultRunTags1: $defaultRunTags1, defaultRunTags2: $defaultRunTags2, defaultRunTags3: $defaultRunTags3, membershipDurationInMonths: $membershipDurationInMonths, defaultDistancePreference: $defaultDistancePreference, notificationMinutesBeforeRunForChatPushNotifications: $notificationMinutesBeforeRunForChatPushNotifications, notificationMinutesBeforeRunForCheckinReminder: $notificationMinutesBeforeRunForCheckinReminder, extApiKey: $extApiKey, latitude: $latitude, longitude: $longitude, defaultLatitude: $defaultLatitude, defaultLongitude: $defaultLongitude, publishToGoogleCalendar: $publishToGoogleCalendar, publishToGoogleCalendarAddresses: $publishToGoogleCalendarAddresses, mismanagementTeam: $mismanagementTeam, kennelCoverPhoto: $kennelCoverPhoto, countryFlag: $countryFlag, regionFlag: $regionFlag, cityFlag: $cityFlag, websiteBackgroundColor: $websiteBackgroundColor, websiteBackgroundImage: $websiteBackgroundImage, websiteTitleText: $websiteTitleText, websiteMenuBackgroundColor: $websiteMenuBackgroundColor, websiteMenuTextColor: $websiteMenuTextColor, websiteWelcomeText: $websiteWelcomeText, websiteBodyTextColor: $websiteBodyTextColor, websiteTitleTextColor: $websiteTitleTextColor, websiteMismanagementDescription: $websiteMismanagementDescription, websiteMismanagementJson: $websiteMismanagementJson, websiteExtraMenusJson: $websiteExtraMenusJson, websiteControlFlags: $websiteControlFlags, websiteContactDetailsJson: $websiteContactDetailsJson, websiteBannerImage: $websiteBannerImage, websiteUrlShortcode: $websiteUrlShortcode, websiteTitleFont: $websiteTitleFont, websiteBodyFont: $websiteBodyFont, kennelAdminEmailList: $kennelAdminEmailList, kennelWebsiteUrl: $kennelWebsiteUrl, kennelEventsUrl: $kennelEventsUrl, kennelHcEventsUrl: $kennelHcEventsUrl, bankScheme: $bankScheme, bankAccountNumber: $bankAccountNumber, bankBic: $bankBic, bankBeneficiary: $bankBeneficiary, kennelPaymentScheme: $kennelPaymentScheme, kennelPaymentUrl: $kennelPaymentUrl, kennelPaymentUrlExpires: $kennelPaymentUrlExpires, kennelPaymentMemberSurcharge: $kennelPaymentMemberSurcharge, kennelPaymentNonMemberSurcharge: $kennelPaymentNonMemberSurcharge, kennelPaymentScheme2: $kennelPaymentScheme2, kennelPaymentUrl2: $kennelPaymentUrl2, kennelPaymentUrlExpires2: $kennelPaymentUrlExpires2, kennelPaymentMemberSurcharge2: $kennelPaymentMemberSurcharge2, kennelPaymentNonMemberSurcharge2: $kennelPaymentNonMemberSurcharge2, kennelPaymentScheme3: $kennelPaymentScheme3, kennelPaymentUrl3: $kennelPaymentUrl3, kennelPaymentUrlExpires3: $kennelPaymentUrlExpires3, kennelPaymentMemberSurcharge3: $kennelPaymentMemberSurcharge3, kennelPaymentNonMemberSurcharge3: $kennelPaymentNonMemberSurcharge3, runCountStartDate: $runCountStartDate, distancePreference: $distancePreference, kennelSearchTags: $kennelSearchTags)';
  }
}

/// @nodoc
abstract mixin class $KennelModelCopyWith<$Res> {
  factory $KennelModelCopyWith(
          KennelModel value, $Res Function(KennelModel) _then) =
      _$KennelModelCopyWithImpl;
  @useResult
  $Res call(
      {@UuidConverter() UuidValue kennelPublicId,
      String kennelName,
      String kennelShortName,
      String kennelUniqueShortName,
      String kennelLogo,
      String kennelDescription,
      int excludeFromLeaderboard,
      String cityName,
      String regionName,
      String countryName,
      String continentName,
      int kennelStatus,
      int disseminateHashRunsDotOrg,
      int disseminateAllowWebLinks,
      int disseminationAudience,
      int disseminateOnGlobalGoogleCalendar,
      int canEditRunAttendence,
      int kennelPinColor,
      double defaultEventPriceForMembers,
      double defaultEventPriceForNonMembers,
      DateTime defaultRunStartTime,
      int allowSelfPayment,
      int allowNegativeCredit,
      @UuidConverter() UuidValue cityId,
      @UuidConverter() UuidValue provinceStateId,
      @UuidConverter() UuidValue countryId,
      int defaultRunTags1,
      int defaultRunTags2,
      int defaultRunTags3,
      int membershipDurationInMonths,
      int defaultDistancePreference,
      int notificationMinutesBeforeRunForChatPushNotifications,
      int notificationMinutesBeforeRunForCheckinReminder,
      String extApiKey,
      double? latitude,
      double? longitude,
      double? defaultLatitude,
      double? defaultLongitude,
      int? publishToGoogleCalendar,
      String? publishToGoogleCalendarAddresses,
      String? mismanagementTeam,
      String? kennelCoverPhoto,
      String? countryFlag,
      String? regionFlag,
      String? cityFlag,
      String? websiteBackgroundColor,
      String? websiteBackgroundImage,
      String? websiteTitleText,
      String? websiteMenuBackgroundColor,
      String? websiteMenuTextColor,
      String? websiteWelcomeText,
      String? websiteBodyTextColor,
      String? websiteTitleTextColor,
      String? websiteMismanagementDescription,
      String? websiteMismanagementJson,
      String? websiteExtraMenusJson,
      int? websiteControlFlags,
      String? websiteContactDetailsJson,
      String? websiteBannerImage,
      String? websiteUrlShortcode,
      String? websiteTitleFont,
      String? websiteBodyFont,
      String? kennelAdminEmailList,
      String? kennelWebsiteUrl,
      String? kennelEventsUrl,
      String? kennelHcEventsUrl,
      String? bankScheme,
      String? bankAccountNumber,
      String? bankBic,
      String? bankBeneficiary,
      String? kennelPaymentScheme,
      String? kennelPaymentUrl,
      DateTime? kennelPaymentUrlExpires,
      double? kennelPaymentMemberSurcharge,
      double? kennelPaymentNonMemberSurcharge,
      String? kennelPaymentScheme2,
      String? kennelPaymentUrl2,
      DateTime? kennelPaymentUrlExpires2,
      double? kennelPaymentMemberSurcharge2,
      double? kennelPaymentNonMemberSurcharge2,
      String? kennelPaymentScheme3,
      String? kennelPaymentUrl3,
      DateTime? kennelPaymentUrlExpires3,
      double? kennelPaymentMemberSurcharge3,
      double? kennelPaymentNonMemberSurcharge3,
      DateTime? runCountStartDate,
      int? distancePreference,
      String? kennelSearchTags});
}

/// @nodoc
class _$KennelModelCopyWithImpl<$Res> implements $KennelModelCopyWith<$Res> {
  _$KennelModelCopyWithImpl(this._self, this._then);

  final KennelModel _self;
  final $Res Function(KennelModel) _then;

  /// Create a copy of KennelModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? kennelPublicId = null,
    Object? kennelName = null,
    Object? kennelShortName = null,
    Object? kennelUniqueShortName = null,
    Object? kennelLogo = null,
    Object? kennelDescription = null,
    Object? excludeFromLeaderboard = null,
    Object? cityName = null,
    Object? regionName = null,
    Object? countryName = null,
    Object? continentName = null,
    Object? kennelStatus = null,
    Object? disseminateHashRunsDotOrg = null,
    Object? disseminateAllowWebLinks = null,
    Object? disseminationAudience = null,
    Object? disseminateOnGlobalGoogleCalendar = null,
    Object? canEditRunAttendence = null,
    Object? kennelPinColor = null,
    Object? defaultEventPriceForMembers = null,
    Object? defaultEventPriceForNonMembers = null,
    Object? defaultRunStartTime = null,
    Object? allowSelfPayment = null,
    Object? allowNegativeCredit = null,
    Object? cityId = null,
    Object? provinceStateId = null,
    Object? countryId = null,
    Object? defaultRunTags1 = null,
    Object? defaultRunTags2 = null,
    Object? defaultRunTags3 = null,
    Object? membershipDurationInMonths = null,
    Object? defaultDistancePreference = null,
    Object? notificationMinutesBeforeRunForChatPushNotifications = null,
    Object? notificationMinutesBeforeRunForCheckinReminder = null,
    Object? extApiKey = null,
    Object? latitude = freezed,
    Object? longitude = freezed,
    Object? defaultLatitude = freezed,
    Object? defaultLongitude = freezed,
    Object? publishToGoogleCalendar = freezed,
    Object? publishToGoogleCalendarAddresses = freezed,
    Object? mismanagementTeam = freezed,
    Object? kennelCoverPhoto = freezed,
    Object? countryFlag = freezed,
    Object? regionFlag = freezed,
    Object? cityFlag = freezed,
    Object? websiteBackgroundColor = freezed,
    Object? websiteBackgroundImage = freezed,
    Object? websiteTitleText = freezed,
    Object? websiteMenuBackgroundColor = freezed,
    Object? websiteMenuTextColor = freezed,
    Object? websiteWelcomeText = freezed,
    Object? websiteBodyTextColor = freezed,
    Object? websiteTitleTextColor = freezed,
    Object? websiteMismanagementDescription = freezed,
    Object? websiteMismanagementJson = freezed,
    Object? websiteExtraMenusJson = freezed,
    Object? websiteControlFlags = freezed,
    Object? websiteContactDetailsJson = freezed,
    Object? websiteBannerImage = freezed,
    Object? websiteUrlShortcode = freezed,
    Object? websiteTitleFont = freezed,
    Object? websiteBodyFont = freezed,
    Object? kennelAdminEmailList = freezed,
    Object? kennelWebsiteUrl = freezed,
    Object? kennelEventsUrl = freezed,
    Object? kennelHcEventsUrl = freezed,
    Object? bankScheme = freezed,
    Object? bankAccountNumber = freezed,
    Object? bankBic = freezed,
    Object? bankBeneficiary = freezed,
    Object? kennelPaymentScheme = freezed,
    Object? kennelPaymentUrl = freezed,
    Object? kennelPaymentUrlExpires = freezed,
    Object? kennelPaymentMemberSurcharge = freezed,
    Object? kennelPaymentNonMemberSurcharge = freezed,
    Object? kennelPaymentScheme2 = freezed,
    Object? kennelPaymentUrl2 = freezed,
    Object? kennelPaymentUrlExpires2 = freezed,
    Object? kennelPaymentMemberSurcharge2 = freezed,
    Object? kennelPaymentNonMemberSurcharge2 = freezed,
    Object? kennelPaymentScheme3 = freezed,
    Object? kennelPaymentUrl3 = freezed,
    Object? kennelPaymentUrlExpires3 = freezed,
    Object? kennelPaymentMemberSurcharge3 = freezed,
    Object? kennelPaymentNonMemberSurcharge3 = freezed,
    Object? runCountStartDate = freezed,
    Object? distancePreference = freezed,
    Object? kennelSearchTags = freezed,
  }) {
    return _then(_self.copyWith(
      kennelPublicId: null == kennelPublicId
          ? _self.kennelPublicId
          : kennelPublicId // ignore: cast_nullable_to_non_nullable
              as UuidValue,
      kennelName: null == kennelName
          ? _self.kennelName
          : kennelName // ignore: cast_nullable_to_non_nullable
              as String,
      kennelShortName: null == kennelShortName
          ? _self.kennelShortName
          : kennelShortName // ignore: cast_nullable_to_non_nullable
              as String,
      kennelUniqueShortName: null == kennelUniqueShortName
          ? _self.kennelUniqueShortName
          : kennelUniqueShortName // ignore: cast_nullable_to_non_nullable
              as String,
      kennelLogo: null == kennelLogo
          ? _self.kennelLogo
          : kennelLogo // ignore: cast_nullable_to_non_nullable
              as String,
      kennelDescription: null == kennelDescription
          ? _self.kennelDescription
          : kennelDescription // ignore: cast_nullable_to_non_nullable
              as String,
      excludeFromLeaderboard: null == excludeFromLeaderboard
          ? _self.excludeFromLeaderboard
          : excludeFromLeaderboard // ignore: cast_nullable_to_non_nullable
              as int,
      cityName: null == cityName
          ? _self.cityName
          : cityName // ignore: cast_nullable_to_non_nullable
              as String,
      regionName: null == regionName
          ? _self.regionName
          : regionName // ignore: cast_nullable_to_non_nullable
              as String,
      countryName: null == countryName
          ? _self.countryName
          : countryName // ignore: cast_nullable_to_non_nullable
              as String,
      continentName: null == continentName
          ? _self.continentName
          : continentName // ignore: cast_nullable_to_non_nullable
              as String,
      kennelStatus: null == kennelStatus
          ? _self.kennelStatus
          : kennelStatus // ignore: cast_nullable_to_non_nullable
              as int,
      disseminateHashRunsDotOrg: null == disseminateHashRunsDotOrg
          ? _self.disseminateHashRunsDotOrg
          : disseminateHashRunsDotOrg // ignore: cast_nullable_to_non_nullable
              as int,
      disseminateAllowWebLinks: null == disseminateAllowWebLinks
          ? _self.disseminateAllowWebLinks
          : disseminateAllowWebLinks // ignore: cast_nullable_to_non_nullable
              as int,
      disseminationAudience: null == disseminationAudience
          ? _self.disseminationAudience
          : disseminationAudience // ignore: cast_nullable_to_non_nullable
              as int,
      disseminateOnGlobalGoogleCalendar: null ==
              disseminateOnGlobalGoogleCalendar
          ? _self.disseminateOnGlobalGoogleCalendar
          : disseminateOnGlobalGoogleCalendar // ignore: cast_nullable_to_non_nullable
              as int,
      canEditRunAttendence: null == canEditRunAttendence
          ? _self.canEditRunAttendence
          : canEditRunAttendence // ignore: cast_nullable_to_non_nullable
              as int,
      kennelPinColor: null == kennelPinColor
          ? _self.kennelPinColor
          : kennelPinColor // ignore: cast_nullable_to_non_nullable
              as int,
      defaultEventPriceForMembers: null == defaultEventPriceForMembers
          ? _self.defaultEventPriceForMembers
          : defaultEventPriceForMembers // ignore: cast_nullable_to_non_nullable
              as double,
      defaultEventPriceForNonMembers: null == defaultEventPriceForNonMembers
          ? _self.defaultEventPriceForNonMembers
          : defaultEventPriceForNonMembers // ignore: cast_nullable_to_non_nullable
              as double,
      defaultRunStartTime: null == defaultRunStartTime
          ? _self.defaultRunStartTime
          : defaultRunStartTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      allowSelfPayment: null == allowSelfPayment
          ? _self.allowSelfPayment
          : allowSelfPayment // ignore: cast_nullable_to_non_nullable
              as int,
      allowNegativeCredit: null == allowNegativeCredit
          ? _self.allowNegativeCredit
          : allowNegativeCredit // ignore: cast_nullable_to_non_nullable
              as int,
      cityId: null == cityId
          ? _self.cityId
          : cityId // ignore: cast_nullable_to_non_nullable
              as UuidValue,
      provinceStateId: null == provinceStateId
          ? _self.provinceStateId
          : provinceStateId // ignore: cast_nullable_to_non_nullable
              as UuidValue,
      countryId: null == countryId
          ? _self.countryId
          : countryId // ignore: cast_nullable_to_non_nullable
              as UuidValue,
      defaultRunTags1: null == defaultRunTags1
          ? _self.defaultRunTags1
          : defaultRunTags1 // ignore: cast_nullable_to_non_nullable
              as int,
      defaultRunTags2: null == defaultRunTags2
          ? _self.defaultRunTags2
          : defaultRunTags2 // ignore: cast_nullable_to_non_nullable
              as int,
      defaultRunTags3: null == defaultRunTags3
          ? _self.defaultRunTags3
          : defaultRunTags3 // ignore: cast_nullable_to_non_nullable
              as int,
      membershipDurationInMonths: null == membershipDurationInMonths
          ? _self.membershipDurationInMonths
          : membershipDurationInMonths // ignore: cast_nullable_to_non_nullable
              as int,
      defaultDistancePreference: null == defaultDistancePreference
          ? _self.defaultDistancePreference
          : defaultDistancePreference // ignore: cast_nullable_to_non_nullable
              as int,
      notificationMinutesBeforeRunForChatPushNotifications: null ==
              notificationMinutesBeforeRunForChatPushNotifications
          ? _self.notificationMinutesBeforeRunForChatPushNotifications
          : notificationMinutesBeforeRunForChatPushNotifications // ignore: cast_nullable_to_non_nullable
              as int,
      notificationMinutesBeforeRunForCheckinReminder: null ==
              notificationMinutesBeforeRunForCheckinReminder
          ? _self.notificationMinutesBeforeRunForCheckinReminder
          : notificationMinutesBeforeRunForCheckinReminder // ignore: cast_nullable_to_non_nullable
              as int,
      extApiKey: null == extApiKey
          ? _self.extApiKey
          : extApiKey // ignore: cast_nullable_to_non_nullable
              as String,
      latitude: freezed == latitude
          ? _self.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double?,
      longitude: freezed == longitude
          ? _self.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double?,
      defaultLatitude: freezed == defaultLatitude
          ? _self.defaultLatitude
          : defaultLatitude // ignore: cast_nullable_to_non_nullable
              as double?,
      defaultLongitude: freezed == defaultLongitude
          ? _self.defaultLongitude
          : defaultLongitude // ignore: cast_nullable_to_non_nullable
              as double?,
      publishToGoogleCalendar: freezed == publishToGoogleCalendar
          ? _self.publishToGoogleCalendar
          : publishToGoogleCalendar // ignore: cast_nullable_to_non_nullable
              as int?,
      publishToGoogleCalendarAddresses: freezed ==
              publishToGoogleCalendarAddresses
          ? _self.publishToGoogleCalendarAddresses
          : publishToGoogleCalendarAddresses // ignore: cast_nullable_to_non_nullable
              as String?,
      mismanagementTeam: freezed == mismanagementTeam
          ? _self.mismanagementTeam
          : mismanagementTeam // ignore: cast_nullable_to_non_nullable
              as String?,
      kennelCoverPhoto: freezed == kennelCoverPhoto
          ? _self.kennelCoverPhoto
          : kennelCoverPhoto // ignore: cast_nullable_to_non_nullable
              as String?,
      countryFlag: freezed == countryFlag
          ? _self.countryFlag
          : countryFlag // ignore: cast_nullable_to_non_nullable
              as String?,
      regionFlag: freezed == regionFlag
          ? _self.regionFlag
          : regionFlag // ignore: cast_nullable_to_non_nullable
              as String?,
      cityFlag: freezed == cityFlag
          ? _self.cityFlag
          : cityFlag // ignore: cast_nullable_to_non_nullable
              as String?,
      websiteBackgroundColor: freezed == websiteBackgroundColor
          ? _self.websiteBackgroundColor
          : websiteBackgroundColor // ignore: cast_nullable_to_non_nullable
              as String?,
      websiteBackgroundImage: freezed == websiteBackgroundImage
          ? _self.websiteBackgroundImage
          : websiteBackgroundImage // ignore: cast_nullable_to_non_nullable
              as String?,
      websiteTitleText: freezed == websiteTitleText
          ? _self.websiteTitleText
          : websiteTitleText // ignore: cast_nullable_to_non_nullable
              as String?,
      websiteMenuBackgroundColor: freezed == websiteMenuBackgroundColor
          ? _self.websiteMenuBackgroundColor
          : websiteMenuBackgroundColor // ignore: cast_nullable_to_non_nullable
              as String?,
      websiteMenuTextColor: freezed == websiteMenuTextColor
          ? _self.websiteMenuTextColor
          : websiteMenuTextColor // ignore: cast_nullable_to_non_nullable
              as String?,
      websiteWelcomeText: freezed == websiteWelcomeText
          ? _self.websiteWelcomeText
          : websiteWelcomeText // ignore: cast_nullable_to_non_nullable
              as String?,
      websiteBodyTextColor: freezed == websiteBodyTextColor
          ? _self.websiteBodyTextColor
          : websiteBodyTextColor // ignore: cast_nullable_to_non_nullable
              as String?,
      websiteTitleTextColor: freezed == websiteTitleTextColor
          ? _self.websiteTitleTextColor
          : websiteTitleTextColor // ignore: cast_nullable_to_non_nullable
              as String?,
      websiteMismanagementDescription: freezed ==
              websiteMismanagementDescription
          ? _self.websiteMismanagementDescription
          : websiteMismanagementDescription // ignore: cast_nullable_to_non_nullable
              as String?,
      websiteMismanagementJson: freezed == websiteMismanagementJson
          ? _self.websiteMismanagementJson
          : websiteMismanagementJson // ignore: cast_nullable_to_non_nullable
              as String?,
      websiteExtraMenusJson: freezed == websiteExtraMenusJson
          ? _self.websiteExtraMenusJson
          : websiteExtraMenusJson // ignore: cast_nullable_to_non_nullable
              as String?,
      websiteControlFlags: freezed == websiteControlFlags
          ? _self.websiteControlFlags
          : websiteControlFlags // ignore: cast_nullable_to_non_nullable
              as int?,
      websiteContactDetailsJson: freezed == websiteContactDetailsJson
          ? _self.websiteContactDetailsJson
          : websiteContactDetailsJson // ignore: cast_nullable_to_non_nullable
              as String?,
      websiteBannerImage: freezed == websiteBannerImage
          ? _self.websiteBannerImage
          : websiteBannerImage // ignore: cast_nullable_to_non_nullable
              as String?,
      websiteUrlShortcode: freezed == websiteUrlShortcode
          ? _self.websiteUrlShortcode
          : websiteUrlShortcode // ignore: cast_nullable_to_non_nullable
              as String?,
      websiteTitleFont: freezed == websiteTitleFont
          ? _self.websiteTitleFont
          : websiteTitleFont // ignore: cast_nullable_to_non_nullable
              as String?,
      websiteBodyFont: freezed == websiteBodyFont
          ? _self.websiteBodyFont
          : websiteBodyFont // ignore: cast_nullable_to_non_nullable
              as String?,
      kennelAdminEmailList: freezed == kennelAdminEmailList
          ? _self.kennelAdminEmailList
          : kennelAdminEmailList // ignore: cast_nullable_to_non_nullable
              as String?,
      kennelWebsiteUrl: freezed == kennelWebsiteUrl
          ? _self.kennelWebsiteUrl
          : kennelWebsiteUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      kennelEventsUrl: freezed == kennelEventsUrl
          ? _self.kennelEventsUrl
          : kennelEventsUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      kennelHcEventsUrl: freezed == kennelHcEventsUrl
          ? _self.kennelHcEventsUrl
          : kennelHcEventsUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      bankScheme: freezed == bankScheme
          ? _self.bankScheme
          : bankScheme // ignore: cast_nullable_to_non_nullable
              as String?,
      bankAccountNumber: freezed == bankAccountNumber
          ? _self.bankAccountNumber
          : bankAccountNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      bankBic: freezed == bankBic
          ? _self.bankBic
          : bankBic // ignore: cast_nullable_to_non_nullable
              as String?,
      bankBeneficiary: freezed == bankBeneficiary
          ? _self.bankBeneficiary
          : bankBeneficiary // ignore: cast_nullable_to_non_nullable
              as String?,
      kennelPaymentScheme: freezed == kennelPaymentScheme
          ? _self.kennelPaymentScheme
          : kennelPaymentScheme // ignore: cast_nullable_to_non_nullable
              as String?,
      kennelPaymentUrl: freezed == kennelPaymentUrl
          ? _self.kennelPaymentUrl
          : kennelPaymentUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      kennelPaymentUrlExpires: freezed == kennelPaymentUrlExpires
          ? _self.kennelPaymentUrlExpires
          : kennelPaymentUrlExpires // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      kennelPaymentMemberSurcharge: freezed == kennelPaymentMemberSurcharge
          ? _self.kennelPaymentMemberSurcharge
          : kennelPaymentMemberSurcharge // ignore: cast_nullable_to_non_nullable
              as double?,
      kennelPaymentNonMemberSurcharge: freezed ==
              kennelPaymentNonMemberSurcharge
          ? _self.kennelPaymentNonMemberSurcharge
          : kennelPaymentNonMemberSurcharge // ignore: cast_nullable_to_non_nullable
              as double?,
      kennelPaymentScheme2: freezed == kennelPaymentScheme2
          ? _self.kennelPaymentScheme2
          : kennelPaymentScheme2 // ignore: cast_nullable_to_non_nullable
              as String?,
      kennelPaymentUrl2: freezed == kennelPaymentUrl2
          ? _self.kennelPaymentUrl2
          : kennelPaymentUrl2 // ignore: cast_nullable_to_non_nullable
              as String?,
      kennelPaymentUrlExpires2: freezed == kennelPaymentUrlExpires2
          ? _self.kennelPaymentUrlExpires2
          : kennelPaymentUrlExpires2 // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      kennelPaymentMemberSurcharge2: freezed == kennelPaymentMemberSurcharge2
          ? _self.kennelPaymentMemberSurcharge2
          : kennelPaymentMemberSurcharge2 // ignore: cast_nullable_to_non_nullable
              as double?,
      kennelPaymentNonMemberSurcharge2: freezed ==
              kennelPaymentNonMemberSurcharge2
          ? _self.kennelPaymentNonMemberSurcharge2
          : kennelPaymentNonMemberSurcharge2 // ignore: cast_nullable_to_non_nullable
              as double?,
      kennelPaymentScheme3: freezed == kennelPaymentScheme3
          ? _self.kennelPaymentScheme3
          : kennelPaymentScheme3 // ignore: cast_nullable_to_non_nullable
              as String?,
      kennelPaymentUrl3: freezed == kennelPaymentUrl3
          ? _self.kennelPaymentUrl3
          : kennelPaymentUrl3 // ignore: cast_nullable_to_non_nullable
              as String?,
      kennelPaymentUrlExpires3: freezed == kennelPaymentUrlExpires3
          ? _self.kennelPaymentUrlExpires3
          : kennelPaymentUrlExpires3 // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      kennelPaymentMemberSurcharge3: freezed == kennelPaymentMemberSurcharge3
          ? _self.kennelPaymentMemberSurcharge3
          : kennelPaymentMemberSurcharge3 // ignore: cast_nullable_to_non_nullable
              as double?,
      kennelPaymentNonMemberSurcharge3: freezed ==
              kennelPaymentNonMemberSurcharge3
          ? _self.kennelPaymentNonMemberSurcharge3
          : kennelPaymentNonMemberSurcharge3 // ignore: cast_nullable_to_non_nullable
              as double?,
      runCountStartDate: freezed == runCountStartDate
          ? _self.runCountStartDate
          : runCountStartDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      distancePreference: freezed == distancePreference
          ? _self.distancePreference
          : distancePreference // ignore: cast_nullable_to_non_nullable
              as int?,
      kennelSearchTags: freezed == kennelSearchTags
          ? _self.kennelSearchTags
          : kennelSearchTags // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [KennelModel].
extension KennelModelPatterns on KennelModel {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_KennelModel value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _KennelModel() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_KennelModel value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _KennelModel():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_KennelModel value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _KennelModel() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            @UuidConverter() UuidValue kennelPublicId,
            String kennelName,
            String kennelShortName,
            String kennelUniqueShortName,
            String kennelLogo,
            String kennelDescription,
            int excludeFromLeaderboard,
            String cityName,
            String regionName,
            String countryName,
            String continentName,
            int kennelStatus,
            int disseminateHashRunsDotOrg,
            int disseminateAllowWebLinks,
            int disseminationAudience,
            int disseminateOnGlobalGoogleCalendar,
            int canEditRunAttendence,
            int kennelPinColor,
            double defaultEventPriceForMembers,
            double defaultEventPriceForNonMembers,
            DateTime defaultRunStartTime,
            int allowSelfPayment,
            int allowNegativeCredit,
            @UuidConverter() UuidValue cityId,
            @UuidConverter() UuidValue provinceStateId,
            @UuidConverter() UuidValue countryId,
            int defaultRunTags1,
            int defaultRunTags2,
            int defaultRunTags3,
            int membershipDurationInMonths,
            int defaultDistancePreference,
            int notificationMinutesBeforeRunForChatPushNotifications,
            int notificationMinutesBeforeRunForCheckinReminder,
            String extApiKey,
            double? latitude,
            double? longitude,
            double? defaultLatitude,
            double? defaultLongitude,
            int? publishToGoogleCalendar,
            String? publishToGoogleCalendarAddresses,
            String? mismanagementTeam,
            String? kennelCoverPhoto,
            String? countryFlag,
            String? regionFlag,
            String? cityFlag,
            String? websiteBackgroundColor,
            String? websiteBackgroundImage,
            String? websiteTitleText,
            String? websiteMenuBackgroundColor,
            String? websiteMenuTextColor,
            String? websiteWelcomeText,
            String? websiteBodyTextColor,
            String? websiteTitleTextColor,
            String? websiteMismanagementDescription,
            String? websiteMismanagementJson,
            String? websiteExtraMenusJson,
            int? websiteControlFlags,
            String? websiteContactDetailsJson,
            String? websiteBannerImage,
            String? websiteUrlShortcode,
            String? websiteTitleFont,
            String? websiteBodyFont,
            String? kennelAdminEmailList,
            String? kennelWebsiteUrl,
            String? kennelEventsUrl,
            String? kennelHcEventsUrl,
            String? bankScheme,
            String? bankAccountNumber,
            String? bankBic,
            String? bankBeneficiary,
            String? kennelPaymentScheme,
            String? kennelPaymentUrl,
            DateTime? kennelPaymentUrlExpires,
            double? kennelPaymentMemberSurcharge,
            double? kennelPaymentNonMemberSurcharge,
            String? kennelPaymentScheme2,
            String? kennelPaymentUrl2,
            DateTime? kennelPaymentUrlExpires2,
            double? kennelPaymentMemberSurcharge2,
            double? kennelPaymentNonMemberSurcharge2,
            String? kennelPaymentScheme3,
            String? kennelPaymentUrl3,
            DateTime? kennelPaymentUrlExpires3,
            double? kennelPaymentMemberSurcharge3,
            double? kennelPaymentNonMemberSurcharge3,
            DateTime? runCountStartDate,
            int? distancePreference,
            String? kennelSearchTags)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _KennelModel() when $default != null:
        return $default(
            _that.kennelPublicId,
            _that.kennelName,
            _that.kennelShortName,
            _that.kennelUniqueShortName,
            _that.kennelLogo,
            _that.kennelDescription,
            _that.excludeFromLeaderboard,
            _that.cityName,
            _that.regionName,
            _that.countryName,
            _that.continentName,
            _that.kennelStatus,
            _that.disseminateHashRunsDotOrg,
            _that.disseminateAllowWebLinks,
            _that.disseminationAudience,
            _that.disseminateOnGlobalGoogleCalendar,
            _that.canEditRunAttendence,
            _that.kennelPinColor,
            _that.defaultEventPriceForMembers,
            _that.defaultEventPriceForNonMembers,
            _that.defaultRunStartTime,
            _that.allowSelfPayment,
            _that.allowNegativeCredit,
            _that.cityId,
            _that.provinceStateId,
            _that.countryId,
            _that.defaultRunTags1,
            _that.defaultRunTags2,
            _that.defaultRunTags3,
            _that.membershipDurationInMonths,
            _that.defaultDistancePreference,
            _that.notificationMinutesBeforeRunForChatPushNotifications,
            _that.notificationMinutesBeforeRunForCheckinReminder,
            _that.extApiKey,
            _that.latitude,
            _that.longitude,
            _that.defaultLatitude,
            _that.defaultLongitude,
            _that.publishToGoogleCalendar,
            _that.publishToGoogleCalendarAddresses,
            _that.mismanagementTeam,
            _that.kennelCoverPhoto,
            _that.countryFlag,
            _that.regionFlag,
            _that.cityFlag,
            _that.websiteBackgroundColor,
            _that.websiteBackgroundImage,
            _that.websiteTitleText,
            _that.websiteMenuBackgroundColor,
            _that.websiteMenuTextColor,
            _that.websiteWelcomeText,
            _that.websiteBodyTextColor,
            _that.websiteTitleTextColor,
            _that.websiteMismanagementDescription,
            _that.websiteMismanagementJson,
            _that.websiteExtraMenusJson,
            _that.websiteControlFlags,
            _that.websiteContactDetailsJson,
            _that.websiteBannerImage,
            _that.websiteUrlShortcode,
            _that.websiteTitleFont,
            _that.websiteBodyFont,
            _that.kennelAdminEmailList,
            _that.kennelWebsiteUrl,
            _that.kennelEventsUrl,
            _that.kennelHcEventsUrl,
            _that.bankScheme,
            _that.bankAccountNumber,
            _that.bankBic,
            _that.bankBeneficiary,
            _that.kennelPaymentScheme,
            _that.kennelPaymentUrl,
            _that.kennelPaymentUrlExpires,
            _that.kennelPaymentMemberSurcharge,
            _that.kennelPaymentNonMemberSurcharge,
            _that.kennelPaymentScheme2,
            _that.kennelPaymentUrl2,
            _that.kennelPaymentUrlExpires2,
            _that.kennelPaymentMemberSurcharge2,
            _that.kennelPaymentNonMemberSurcharge2,
            _that.kennelPaymentScheme3,
            _that.kennelPaymentUrl3,
            _that.kennelPaymentUrlExpires3,
            _that.kennelPaymentMemberSurcharge3,
            _that.kennelPaymentNonMemberSurcharge3,
            _that.runCountStartDate,
            _that.distancePreference,
            _that.kennelSearchTags);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            @UuidConverter() UuidValue kennelPublicId,
            String kennelName,
            String kennelShortName,
            String kennelUniqueShortName,
            String kennelLogo,
            String kennelDescription,
            int excludeFromLeaderboard,
            String cityName,
            String regionName,
            String countryName,
            String continentName,
            int kennelStatus,
            int disseminateHashRunsDotOrg,
            int disseminateAllowWebLinks,
            int disseminationAudience,
            int disseminateOnGlobalGoogleCalendar,
            int canEditRunAttendence,
            int kennelPinColor,
            double defaultEventPriceForMembers,
            double defaultEventPriceForNonMembers,
            DateTime defaultRunStartTime,
            int allowSelfPayment,
            int allowNegativeCredit,
            @UuidConverter() UuidValue cityId,
            @UuidConverter() UuidValue provinceStateId,
            @UuidConverter() UuidValue countryId,
            int defaultRunTags1,
            int defaultRunTags2,
            int defaultRunTags3,
            int membershipDurationInMonths,
            int defaultDistancePreference,
            int notificationMinutesBeforeRunForChatPushNotifications,
            int notificationMinutesBeforeRunForCheckinReminder,
            String extApiKey,
            double? latitude,
            double? longitude,
            double? defaultLatitude,
            double? defaultLongitude,
            int? publishToGoogleCalendar,
            String? publishToGoogleCalendarAddresses,
            String? mismanagementTeam,
            String? kennelCoverPhoto,
            String? countryFlag,
            String? regionFlag,
            String? cityFlag,
            String? websiteBackgroundColor,
            String? websiteBackgroundImage,
            String? websiteTitleText,
            String? websiteMenuBackgroundColor,
            String? websiteMenuTextColor,
            String? websiteWelcomeText,
            String? websiteBodyTextColor,
            String? websiteTitleTextColor,
            String? websiteMismanagementDescription,
            String? websiteMismanagementJson,
            String? websiteExtraMenusJson,
            int? websiteControlFlags,
            String? websiteContactDetailsJson,
            String? websiteBannerImage,
            String? websiteUrlShortcode,
            String? websiteTitleFont,
            String? websiteBodyFont,
            String? kennelAdminEmailList,
            String? kennelWebsiteUrl,
            String? kennelEventsUrl,
            String? kennelHcEventsUrl,
            String? bankScheme,
            String? bankAccountNumber,
            String? bankBic,
            String? bankBeneficiary,
            String? kennelPaymentScheme,
            String? kennelPaymentUrl,
            DateTime? kennelPaymentUrlExpires,
            double? kennelPaymentMemberSurcharge,
            double? kennelPaymentNonMemberSurcharge,
            String? kennelPaymentScheme2,
            String? kennelPaymentUrl2,
            DateTime? kennelPaymentUrlExpires2,
            double? kennelPaymentMemberSurcharge2,
            double? kennelPaymentNonMemberSurcharge2,
            String? kennelPaymentScheme3,
            String? kennelPaymentUrl3,
            DateTime? kennelPaymentUrlExpires3,
            double? kennelPaymentMemberSurcharge3,
            double? kennelPaymentNonMemberSurcharge3,
            DateTime? runCountStartDate,
            int? distancePreference,
            String? kennelSearchTags)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _KennelModel():
        return $default(
            _that.kennelPublicId,
            _that.kennelName,
            _that.kennelShortName,
            _that.kennelUniqueShortName,
            _that.kennelLogo,
            _that.kennelDescription,
            _that.excludeFromLeaderboard,
            _that.cityName,
            _that.regionName,
            _that.countryName,
            _that.continentName,
            _that.kennelStatus,
            _that.disseminateHashRunsDotOrg,
            _that.disseminateAllowWebLinks,
            _that.disseminationAudience,
            _that.disseminateOnGlobalGoogleCalendar,
            _that.canEditRunAttendence,
            _that.kennelPinColor,
            _that.defaultEventPriceForMembers,
            _that.defaultEventPriceForNonMembers,
            _that.defaultRunStartTime,
            _that.allowSelfPayment,
            _that.allowNegativeCredit,
            _that.cityId,
            _that.provinceStateId,
            _that.countryId,
            _that.defaultRunTags1,
            _that.defaultRunTags2,
            _that.defaultRunTags3,
            _that.membershipDurationInMonths,
            _that.defaultDistancePreference,
            _that.notificationMinutesBeforeRunForChatPushNotifications,
            _that.notificationMinutesBeforeRunForCheckinReminder,
            _that.extApiKey,
            _that.latitude,
            _that.longitude,
            _that.defaultLatitude,
            _that.defaultLongitude,
            _that.publishToGoogleCalendar,
            _that.publishToGoogleCalendarAddresses,
            _that.mismanagementTeam,
            _that.kennelCoverPhoto,
            _that.countryFlag,
            _that.regionFlag,
            _that.cityFlag,
            _that.websiteBackgroundColor,
            _that.websiteBackgroundImage,
            _that.websiteTitleText,
            _that.websiteMenuBackgroundColor,
            _that.websiteMenuTextColor,
            _that.websiteWelcomeText,
            _that.websiteBodyTextColor,
            _that.websiteTitleTextColor,
            _that.websiteMismanagementDescription,
            _that.websiteMismanagementJson,
            _that.websiteExtraMenusJson,
            _that.websiteControlFlags,
            _that.websiteContactDetailsJson,
            _that.websiteBannerImage,
            _that.websiteUrlShortcode,
            _that.websiteTitleFont,
            _that.websiteBodyFont,
            _that.kennelAdminEmailList,
            _that.kennelWebsiteUrl,
            _that.kennelEventsUrl,
            _that.kennelHcEventsUrl,
            _that.bankScheme,
            _that.bankAccountNumber,
            _that.bankBic,
            _that.bankBeneficiary,
            _that.kennelPaymentScheme,
            _that.kennelPaymentUrl,
            _that.kennelPaymentUrlExpires,
            _that.kennelPaymentMemberSurcharge,
            _that.kennelPaymentNonMemberSurcharge,
            _that.kennelPaymentScheme2,
            _that.kennelPaymentUrl2,
            _that.kennelPaymentUrlExpires2,
            _that.kennelPaymentMemberSurcharge2,
            _that.kennelPaymentNonMemberSurcharge2,
            _that.kennelPaymentScheme3,
            _that.kennelPaymentUrl3,
            _that.kennelPaymentUrlExpires3,
            _that.kennelPaymentMemberSurcharge3,
            _that.kennelPaymentNonMemberSurcharge3,
            _that.runCountStartDate,
            _that.distancePreference,
            _that.kennelSearchTags);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            @UuidConverter() UuidValue kennelPublicId,
            String kennelName,
            String kennelShortName,
            String kennelUniqueShortName,
            String kennelLogo,
            String kennelDescription,
            int excludeFromLeaderboard,
            String cityName,
            String regionName,
            String countryName,
            String continentName,
            int kennelStatus,
            int disseminateHashRunsDotOrg,
            int disseminateAllowWebLinks,
            int disseminationAudience,
            int disseminateOnGlobalGoogleCalendar,
            int canEditRunAttendence,
            int kennelPinColor,
            double defaultEventPriceForMembers,
            double defaultEventPriceForNonMembers,
            DateTime defaultRunStartTime,
            int allowSelfPayment,
            int allowNegativeCredit,
            @UuidConverter() UuidValue cityId,
            @UuidConverter() UuidValue provinceStateId,
            @UuidConverter() UuidValue countryId,
            int defaultRunTags1,
            int defaultRunTags2,
            int defaultRunTags3,
            int membershipDurationInMonths,
            int defaultDistancePreference,
            int notificationMinutesBeforeRunForChatPushNotifications,
            int notificationMinutesBeforeRunForCheckinReminder,
            String extApiKey,
            double? latitude,
            double? longitude,
            double? defaultLatitude,
            double? defaultLongitude,
            int? publishToGoogleCalendar,
            String? publishToGoogleCalendarAddresses,
            String? mismanagementTeam,
            String? kennelCoverPhoto,
            String? countryFlag,
            String? regionFlag,
            String? cityFlag,
            String? websiteBackgroundColor,
            String? websiteBackgroundImage,
            String? websiteTitleText,
            String? websiteMenuBackgroundColor,
            String? websiteMenuTextColor,
            String? websiteWelcomeText,
            String? websiteBodyTextColor,
            String? websiteTitleTextColor,
            String? websiteMismanagementDescription,
            String? websiteMismanagementJson,
            String? websiteExtraMenusJson,
            int? websiteControlFlags,
            String? websiteContactDetailsJson,
            String? websiteBannerImage,
            String? websiteUrlShortcode,
            String? websiteTitleFont,
            String? websiteBodyFont,
            String? kennelAdminEmailList,
            String? kennelWebsiteUrl,
            String? kennelEventsUrl,
            String? kennelHcEventsUrl,
            String? bankScheme,
            String? bankAccountNumber,
            String? bankBic,
            String? bankBeneficiary,
            String? kennelPaymentScheme,
            String? kennelPaymentUrl,
            DateTime? kennelPaymentUrlExpires,
            double? kennelPaymentMemberSurcharge,
            double? kennelPaymentNonMemberSurcharge,
            String? kennelPaymentScheme2,
            String? kennelPaymentUrl2,
            DateTime? kennelPaymentUrlExpires2,
            double? kennelPaymentMemberSurcharge2,
            double? kennelPaymentNonMemberSurcharge2,
            String? kennelPaymentScheme3,
            String? kennelPaymentUrl3,
            DateTime? kennelPaymentUrlExpires3,
            double? kennelPaymentMemberSurcharge3,
            double? kennelPaymentNonMemberSurcharge3,
            DateTime? runCountStartDate,
            int? distancePreference,
            String? kennelSearchTags)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _KennelModel() when $default != null:
        return $default(
            _that.kennelPublicId,
            _that.kennelName,
            _that.kennelShortName,
            _that.kennelUniqueShortName,
            _that.kennelLogo,
            _that.kennelDescription,
            _that.excludeFromLeaderboard,
            _that.cityName,
            _that.regionName,
            _that.countryName,
            _that.continentName,
            _that.kennelStatus,
            _that.disseminateHashRunsDotOrg,
            _that.disseminateAllowWebLinks,
            _that.disseminationAudience,
            _that.disseminateOnGlobalGoogleCalendar,
            _that.canEditRunAttendence,
            _that.kennelPinColor,
            _that.defaultEventPriceForMembers,
            _that.defaultEventPriceForNonMembers,
            _that.defaultRunStartTime,
            _that.allowSelfPayment,
            _that.allowNegativeCredit,
            _that.cityId,
            _that.provinceStateId,
            _that.countryId,
            _that.defaultRunTags1,
            _that.defaultRunTags2,
            _that.defaultRunTags3,
            _that.membershipDurationInMonths,
            _that.defaultDistancePreference,
            _that.notificationMinutesBeforeRunForChatPushNotifications,
            _that.notificationMinutesBeforeRunForCheckinReminder,
            _that.extApiKey,
            _that.latitude,
            _that.longitude,
            _that.defaultLatitude,
            _that.defaultLongitude,
            _that.publishToGoogleCalendar,
            _that.publishToGoogleCalendarAddresses,
            _that.mismanagementTeam,
            _that.kennelCoverPhoto,
            _that.countryFlag,
            _that.regionFlag,
            _that.cityFlag,
            _that.websiteBackgroundColor,
            _that.websiteBackgroundImage,
            _that.websiteTitleText,
            _that.websiteMenuBackgroundColor,
            _that.websiteMenuTextColor,
            _that.websiteWelcomeText,
            _that.websiteBodyTextColor,
            _that.websiteTitleTextColor,
            _that.websiteMismanagementDescription,
            _that.websiteMismanagementJson,
            _that.websiteExtraMenusJson,
            _that.websiteControlFlags,
            _that.websiteContactDetailsJson,
            _that.websiteBannerImage,
            _that.websiteUrlShortcode,
            _that.websiteTitleFont,
            _that.websiteBodyFont,
            _that.kennelAdminEmailList,
            _that.kennelWebsiteUrl,
            _that.kennelEventsUrl,
            _that.kennelHcEventsUrl,
            _that.bankScheme,
            _that.bankAccountNumber,
            _that.bankBic,
            _that.bankBeneficiary,
            _that.kennelPaymentScheme,
            _that.kennelPaymentUrl,
            _that.kennelPaymentUrlExpires,
            _that.kennelPaymentMemberSurcharge,
            _that.kennelPaymentNonMemberSurcharge,
            _that.kennelPaymentScheme2,
            _that.kennelPaymentUrl2,
            _that.kennelPaymentUrlExpires2,
            _that.kennelPaymentMemberSurcharge2,
            _that.kennelPaymentNonMemberSurcharge2,
            _that.kennelPaymentScheme3,
            _that.kennelPaymentUrl3,
            _that.kennelPaymentUrlExpires3,
            _that.kennelPaymentMemberSurcharge3,
            _that.kennelPaymentNonMemberSurcharge3,
            _that.runCountStartDate,
            _that.distancePreference,
            _that.kennelSearchTags);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _KennelModel implements KennelModel {
  _KennelModel(
      {@UuidConverter() required this.kennelPublicId,
      required this.kennelName,
      required this.kennelShortName,
      required this.kennelUniqueShortName,
      required this.kennelLogo,
      required this.kennelDescription,
      required this.excludeFromLeaderboard,
      required this.cityName,
      required this.regionName,
      required this.countryName,
      required this.continentName,
      required this.kennelStatus,
      required this.disseminateHashRunsDotOrg,
      required this.disseminateAllowWebLinks,
      required this.disseminationAudience,
      required this.disseminateOnGlobalGoogleCalendar,
      required this.canEditRunAttendence,
      required this.kennelPinColor,
      required this.defaultEventPriceForMembers,
      required this.defaultEventPriceForNonMembers,
      required this.defaultRunStartTime,
      required this.allowSelfPayment,
      required this.allowNegativeCredit,
      @UuidConverter() required this.cityId,
      @UuidConverter() required this.provinceStateId,
      @UuidConverter() required this.countryId,
      required this.defaultRunTags1,
      required this.defaultRunTags2,
      required this.defaultRunTags3,
      required this.membershipDurationInMonths,
      required this.defaultDistancePreference,
      required this.notificationMinutesBeforeRunForChatPushNotifications,
      required this.notificationMinutesBeforeRunForCheckinReminder,
      required this.extApiKey,
      this.latitude,
      this.longitude,
      this.defaultLatitude,
      this.defaultLongitude,
      this.publishToGoogleCalendar,
      this.publishToGoogleCalendarAddresses,
      this.mismanagementTeam,
      this.kennelCoverPhoto,
      this.countryFlag,
      this.regionFlag,
      this.cityFlag,
      this.websiteBackgroundColor,
      this.websiteBackgroundImage,
      this.websiteTitleText,
      this.websiteMenuBackgroundColor,
      this.websiteMenuTextColor,
      this.websiteWelcomeText,
      this.websiteBodyTextColor,
      this.websiteTitleTextColor,
      this.websiteMismanagementDescription,
      this.websiteMismanagementJson,
      this.websiteExtraMenusJson,
      this.websiteControlFlags,
      this.websiteContactDetailsJson,
      this.websiteBannerImage,
      this.websiteUrlShortcode,
      this.websiteTitleFont,
      this.websiteBodyFont,
      this.kennelAdminEmailList,
      this.kennelWebsiteUrl,
      this.kennelEventsUrl,
      this.kennelHcEventsUrl,
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
      this.distancePreference,
      this.kennelSearchTags});
  factory _KennelModel.fromJson(Map<String, dynamic> json) =>
      _$KennelModelFromJson(json);

  @override
  @UuidConverter()
  final UuidValue kennelPublicId;
  @override
  final String kennelName;
  @override
  final String kennelShortName;
  @override
  final String kennelUniqueShortName;
  @override
  final String kennelLogo;
  @override
  final String kennelDescription;
  @override
  final int excludeFromLeaderboard;
  @override
  final String cityName;
  @override
  final String regionName;
  @override
  final String countryName;
  @override
  final String continentName;
  @override
  final int kennelStatus;
  @override
  final int disseminateHashRunsDotOrg;
  @override
  final int disseminateAllowWebLinks;
  @override
  final int disseminationAudience;
  @override
  final int disseminateOnGlobalGoogleCalendar;
  @override
  final int canEditRunAttendence;
  @override
  final int kennelPinColor;
  @override
  final double defaultEventPriceForMembers;
  @override
  final double defaultEventPriceForNonMembers;
  @override
  final DateTime defaultRunStartTime;
  @override
  final int allowSelfPayment;
  @override
  final int allowNegativeCredit;
  @override
  @UuidConverter()
  final UuidValue cityId;
  @override
  @UuidConverter()
  final UuidValue provinceStateId;
  @override
  @UuidConverter()
  final UuidValue countryId;
  @override
  final int defaultRunTags1;
  @override
  final int defaultRunTags2;
  @override
  final int defaultRunTags3;
  @override
  final int membershipDurationInMonths;
  @override
  final int defaultDistancePreference;
  @override
  final int notificationMinutesBeforeRunForChatPushNotifications;
  @override
  final int notificationMinutesBeforeRunForCheckinReminder;
  @override
  final String extApiKey;
  @override
  final double? latitude;
  @override
  final double? longitude;
  @override
  final double? defaultLatitude;
  @override
  final double? defaultLongitude;
//String? googleCalendarId,
  @override
  final int? publishToGoogleCalendar;
  @override
  final String? publishToGoogleCalendarAddresses;
  @override
  final String? mismanagementTeam;
  @override
  final String? kennelCoverPhoto;
  @override
  final String? countryFlag;
  @override
  final String? regionFlag;
  @override
  final String? cityFlag;
  @override
  final String? websiteBackgroundColor;
  @override
  final String? websiteBackgroundImage;
  @override
  final String? websiteTitleText;
  @override
  final String? websiteMenuBackgroundColor;
  @override
  final String? websiteMenuTextColor;
  @override
  final String? websiteWelcomeText;
  @override
  final String? websiteBodyTextColor;
  @override
  final String? websiteTitleTextColor;
  @override
  final String? websiteMismanagementDescription;
  @override
  final String? websiteMismanagementJson;
  @override
  final String? websiteExtraMenusJson;
  @override
  final int? websiteControlFlags;
  @override
  final String? websiteContactDetailsJson;
  @override
  final String? websiteBannerImage;
  @override
  final String? websiteUrlShortcode;
  @override
  final String? websiteTitleFont;
  @override
  final String? websiteBodyFont;
  @override
  final String? kennelAdminEmailList;
  @override
  final String? kennelWebsiteUrl;
  @override
  final String? kennelEventsUrl;
  @override
  final String? kennelHcEventsUrl;
  @override
  final String? bankScheme;
  @override
  final String? bankAccountNumber;
  @override
  final String? bankBic;
  @override
  final String? bankBeneficiary;
  @override
  final String? kennelPaymentScheme;
  @override
  final String? kennelPaymentUrl;
  @override
  final DateTime? kennelPaymentUrlExpires;
  @override
  final double? kennelPaymentMemberSurcharge;
  @override
  final double? kennelPaymentNonMemberSurcharge;
  @override
  final String? kennelPaymentScheme2;
  @override
  final String? kennelPaymentUrl2;
  @override
  final DateTime? kennelPaymentUrlExpires2;
  @override
  final double? kennelPaymentMemberSurcharge2;
  @override
  final double? kennelPaymentNonMemberSurcharge2;
  @override
  final String? kennelPaymentScheme3;
  @override
  final String? kennelPaymentUrl3;
  @override
  final DateTime? kennelPaymentUrlExpires3;
  @override
  final double? kennelPaymentMemberSurcharge3;
  @override
  final double? kennelPaymentNonMemberSurcharge3;
  @override
  final DateTime? runCountStartDate;
  @override
  final int? distancePreference;
  @override
  final String? kennelSearchTags;

  /// Create a copy of KennelModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$KennelModelCopyWith<_KennelModel> get copyWith =>
      __$KennelModelCopyWithImpl<_KennelModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$KennelModelToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _KennelModel &&
            (identical(other.kennelPublicId, kennelPublicId) ||
                other.kennelPublicId == kennelPublicId) &&
            (identical(other.kennelName, kennelName) ||
                other.kennelName == kennelName) &&
            (identical(other.kennelShortName, kennelShortName) ||
                other.kennelShortName == kennelShortName) &&
            (identical(other.kennelUniqueShortName, kennelUniqueShortName) ||
                other.kennelUniqueShortName == kennelUniqueShortName) &&
            (identical(other.kennelLogo, kennelLogo) ||
                other.kennelLogo == kennelLogo) &&
            (identical(other.kennelDescription, kennelDescription) ||
                other.kennelDescription == kennelDescription) &&
            (identical(other.excludeFromLeaderboard, excludeFromLeaderboard) ||
                other.excludeFromLeaderboard == excludeFromLeaderboard) &&
            (identical(other.cityName, cityName) ||
                other.cityName == cityName) &&
            (identical(other.regionName, regionName) ||
                other.regionName == regionName) &&
            (identical(other.countryName, countryName) ||
                other.countryName == countryName) &&
            (identical(other.continentName, continentName) ||
                other.continentName == continentName) &&
            (identical(other.kennelStatus, kennelStatus) ||
                other.kennelStatus == kennelStatus) &&
            (identical(other.disseminateHashRunsDotOrg, disseminateHashRunsDotOrg) ||
                other.disseminateHashRunsDotOrg == disseminateHashRunsDotOrg) &&
            (identical(other.disseminateAllowWebLinks, disseminateAllowWebLinks) ||
                other.disseminateAllowWebLinks == disseminateAllowWebLinks) &&
            (identical(other.disseminationAudience, disseminationAudience) ||
                other.disseminationAudience == disseminationAudience) &&
            (identical(other.disseminateOnGlobalGoogleCalendar, disseminateOnGlobalGoogleCalendar) ||
                other.disseminateOnGlobalGoogleCalendar ==
                    disseminateOnGlobalGoogleCalendar) &&
            (identical(other.canEditRunAttendence, canEditRunAttendence) ||
                other.canEditRunAttendence == canEditRunAttendence) &&
            (identical(other.kennelPinColor, kennelPinColor) ||
                other.kennelPinColor == kennelPinColor) &&
            (identical(other.defaultEventPriceForMembers, defaultEventPriceForMembers) ||
                other.defaultEventPriceForMembers ==
                    defaultEventPriceForMembers) &&
            (identical(other.defaultEventPriceForNonMembers, defaultEventPriceForNonMembers) ||
                other.defaultEventPriceForNonMembers ==
                    defaultEventPriceForNonMembers) &&
            (identical(other.defaultRunStartTime, defaultRunStartTime) ||
                other.defaultRunStartTime == defaultRunStartTime) &&
            (identical(other.allowSelfPayment, allowSelfPayment) ||
                other.allowSelfPayment == allowSelfPayment) &&
            (identical(other.allowNegativeCredit, allowNegativeCredit) ||
                other.allowNegativeCredit == allowNegativeCredit) &&
            (identical(other.cityId, cityId) || other.cityId == cityId) &&
            (identical(other.provinceStateId, provinceStateId) ||
                other.provinceStateId == provinceStateId) &&
            (identical(other.countryId, countryId) ||
                other.countryId == countryId) &&
            (identical(other.defaultRunTags1, defaultRunTags1) ||
                other.defaultRunTags1 == defaultRunTags1) &&
            (identical(other.defaultRunTags2, defaultRunTags2) ||
                other.defaultRunTags2 == defaultRunTags2) &&
            (identical(other.defaultRunTags3, defaultRunTags3) ||
                other.defaultRunTags3 == defaultRunTags3) &&
            (identical(other.membershipDurationInMonths, membershipDurationInMonths) || other.membershipDurationInMonths == membershipDurationInMonths) &&
            (identical(other.defaultDistancePreference, defaultDistancePreference) || other.defaultDistancePreference == defaultDistancePreference) &&
            (identical(other.notificationMinutesBeforeRunForChatPushNotifications, notificationMinutesBeforeRunForChatPushNotifications) || other.notificationMinutesBeforeRunForChatPushNotifications == notificationMinutesBeforeRunForChatPushNotifications) &&
            (identical(other.notificationMinutesBeforeRunForCheckinReminder, notificationMinutesBeforeRunForCheckinReminder) || other.notificationMinutesBeforeRunForCheckinReminder == notificationMinutesBeforeRunForCheckinReminder) &&
            (identical(other.extApiKey, extApiKey) || other.extApiKey == extApiKey) &&
            (identical(other.latitude, latitude) || other.latitude == latitude) &&
            (identical(other.longitude, longitude) || other.longitude == longitude) &&
            (identical(other.defaultLatitude, defaultLatitude) || other.defaultLatitude == defaultLatitude) &&
            (identical(other.defaultLongitude, defaultLongitude) || other.defaultLongitude == defaultLongitude) &&
            (identical(other.publishToGoogleCalendar, publishToGoogleCalendar) || other.publishToGoogleCalendar == publishToGoogleCalendar) &&
            (identical(other.publishToGoogleCalendarAddresses, publishToGoogleCalendarAddresses) || other.publishToGoogleCalendarAddresses == publishToGoogleCalendarAddresses) &&
            (identical(other.mismanagementTeam, mismanagementTeam) || other.mismanagementTeam == mismanagementTeam) &&
            (identical(other.kennelCoverPhoto, kennelCoverPhoto) || other.kennelCoverPhoto == kennelCoverPhoto) &&
            (identical(other.countryFlag, countryFlag) || other.countryFlag == countryFlag) &&
            (identical(other.regionFlag, regionFlag) || other.regionFlag == regionFlag) &&
            (identical(other.cityFlag, cityFlag) || other.cityFlag == cityFlag) &&
            (identical(other.websiteBackgroundColor, websiteBackgroundColor) || other.websiteBackgroundColor == websiteBackgroundColor) &&
            (identical(other.websiteBackgroundImage, websiteBackgroundImage) || other.websiteBackgroundImage == websiteBackgroundImage) &&
            (identical(other.websiteTitleText, websiteTitleText) || other.websiteTitleText == websiteTitleText) &&
            (identical(other.websiteMenuBackgroundColor, websiteMenuBackgroundColor) || other.websiteMenuBackgroundColor == websiteMenuBackgroundColor) &&
            (identical(other.websiteMenuTextColor, websiteMenuTextColor) || other.websiteMenuTextColor == websiteMenuTextColor) &&
            (identical(other.websiteWelcomeText, websiteWelcomeText) || other.websiteWelcomeText == websiteWelcomeText) &&
            (identical(other.websiteBodyTextColor, websiteBodyTextColor) || other.websiteBodyTextColor == websiteBodyTextColor) &&
            (identical(other.websiteTitleTextColor, websiteTitleTextColor) || other.websiteTitleTextColor == websiteTitleTextColor) &&
            (identical(other.websiteMismanagementDescription, websiteMismanagementDescription) || other.websiteMismanagementDescription == websiteMismanagementDescription) &&
            (identical(other.websiteMismanagementJson, websiteMismanagementJson) || other.websiteMismanagementJson == websiteMismanagementJson) &&
            (identical(other.websiteExtraMenusJson, websiteExtraMenusJson) || other.websiteExtraMenusJson == websiteExtraMenusJson) &&
            (identical(other.websiteControlFlags, websiteControlFlags) || other.websiteControlFlags == websiteControlFlags) &&
            (identical(other.websiteContactDetailsJson, websiteContactDetailsJson) || other.websiteContactDetailsJson == websiteContactDetailsJson) &&
            (identical(other.websiteBannerImage, websiteBannerImage) || other.websiteBannerImage == websiteBannerImage) &&
            (identical(other.websiteUrlShortcode, websiteUrlShortcode) || other.websiteUrlShortcode == websiteUrlShortcode) &&
            (identical(other.websiteTitleFont, websiteTitleFont) || other.websiteTitleFont == websiteTitleFont) &&
            (identical(other.websiteBodyFont, websiteBodyFont) || other.websiteBodyFont == websiteBodyFont) &&
            (identical(other.kennelAdminEmailList, kennelAdminEmailList) || other.kennelAdminEmailList == kennelAdminEmailList) &&
            (identical(other.kennelWebsiteUrl, kennelWebsiteUrl) || other.kennelWebsiteUrl == kennelWebsiteUrl) &&
            (identical(other.kennelEventsUrl, kennelEventsUrl) || other.kennelEventsUrl == kennelEventsUrl) &&
            (identical(other.kennelHcEventsUrl, kennelHcEventsUrl) || other.kennelHcEventsUrl == kennelHcEventsUrl) &&
            (identical(other.bankScheme, bankScheme) || other.bankScheme == bankScheme) &&
            (identical(other.bankAccountNumber, bankAccountNumber) || other.bankAccountNumber == bankAccountNumber) &&
            (identical(other.bankBic, bankBic) || other.bankBic == bankBic) &&
            (identical(other.bankBeneficiary, bankBeneficiary) || other.bankBeneficiary == bankBeneficiary) &&
            (identical(other.kennelPaymentScheme, kennelPaymentScheme) || other.kennelPaymentScheme == kennelPaymentScheme) &&
            (identical(other.kennelPaymentUrl, kennelPaymentUrl) || other.kennelPaymentUrl == kennelPaymentUrl) &&
            (identical(other.kennelPaymentUrlExpires, kennelPaymentUrlExpires) || other.kennelPaymentUrlExpires == kennelPaymentUrlExpires) &&
            (identical(other.kennelPaymentMemberSurcharge, kennelPaymentMemberSurcharge) || other.kennelPaymentMemberSurcharge == kennelPaymentMemberSurcharge) &&
            (identical(other.kennelPaymentNonMemberSurcharge, kennelPaymentNonMemberSurcharge) || other.kennelPaymentNonMemberSurcharge == kennelPaymentNonMemberSurcharge) &&
            (identical(other.kennelPaymentScheme2, kennelPaymentScheme2) || other.kennelPaymentScheme2 == kennelPaymentScheme2) &&
            (identical(other.kennelPaymentUrl2, kennelPaymentUrl2) || other.kennelPaymentUrl2 == kennelPaymentUrl2) &&
            (identical(other.kennelPaymentUrlExpires2, kennelPaymentUrlExpires2) || other.kennelPaymentUrlExpires2 == kennelPaymentUrlExpires2) &&
            (identical(other.kennelPaymentMemberSurcharge2, kennelPaymentMemberSurcharge2) || other.kennelPaymentMemberSurcharge2 == kennelPaymentMemberSurcharge2) &&
            (identical(other.kennelPaymentNonMemberSurcharge2, kennelPaymentNonMemberSurcharge2) || other.kennelPaymentNonMemberSurcharge2 == kennelPaymentNonMemberSurcharge2) &&
            (identical(other.kennelPaymentScheme3, kennelPaymentScheme3) || other.kennelPaymentScheme3 == kennelPaymentScheme3) &&
            (identical(other.kennelPaymentUrl3, kennelPaymentUrl3) || other.kennelPaymentUrl3 == kennelPaymentUrl3) &&
            (identical(other.kennelPaymentUrlExpires3, kennelPaymentUrlExpires3) || other.kennelPaymentUrlExpires3 == kennelPaymentUrlExpires3) &&
            (identical(other.kennelPaymentMemberSurcharge3, kennelPaymentMemberSurcharge3) || other.kennelPaymentMemberSurcharge3 == kennelPaymentMemberSurcharge3) &&
            (identical(other.kennelPaymentNonMemberSurcharge3, kennelPaymentNonMemberSurcharge3) || other.kennelPaymentNonMemberSurcharge3 == kennelPaymentNonMemberSurcharge3) &&
            (identical(other.runCountStartDate, runCountStartDate) || other.runCountStartDate == runCountStartDate) &&
            (identical(other.distancePreference, distancePreference) || other.distancePreference == distancePreference) &&
            (identical(other.kennelSearchTags, kennelSearchTags) || other.kennelSearchTags == kennelSearchTags));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        kennelPublicId,
        kennelName,
        kennelShortName,
        kennelUniqueShortName,
        kennelLogo,
        kennelDescription,
        excludeFromLeaderboard,
        cityName,
        regionName,
        countryName,
        continentName,
        kennelStatus,
        disseminateHashRunsDotOrg,
        disseminateAllowWebLinks,
        disseminationAudience,
        disseminateOnGlobalGoogleCalendar,
        canEditRunAttendence,
        kennelPinColor,
        defaultEventPriceForMembers,
        defaultEventPriceForNonMembers,
        defaultRunStartTime,
        allowSelfPayment,
        allowNegativeCredit,
        cityId,
        provinceStateId,
        countryId,
        defaultRunTags1,
        defaultRunTags2,
        defaultRunTags3,
        membershipDurationInMonths,
        defaultDistancePreference,
        notificationMinutesBeforeRunForChatPushNotifications,
        notificationMinutesBeforeRunForCheckinReminder,
        extApiKey,
        latitude,
        longitude,
        defaultLatitude,
        defaultLongitude,
        publishToGoogleCalendar,
        publishToGoogleCalendarAddresses,
        mismanagementTeam,
        kennelCoverPhoto,
        countryFlag,
        regionFlag,
        cityFlag,
        websiteBackgroundColor,
        websiteBackgroundImage,
        websiteTitleText,
        websiteMenuBackgroundColor,
        websiteMenuTextColor,
        websiteWelcomeText,
        websiteBodyTextColor,
        websiteTitleTextColor,
        websiteMismanagementDescription,
        websiteMismanagementJson,
        websiteExtraMenusJson,
        websiteControlFlags,
        websiteContactDetailsJson,
        websiteBannerImage,
        websiteUrlShortcode,
        websiteTitleFont,
        websiteBodyFont,
        kennelAdminEmailList,
        kennelWebsiteUrl,
        kennelEventsUrl,
        kennelHcEventsUrl,
        bankScheme,
        bankAccountNumber,
        bankBic,
        bankBeneficiary,
        kennelPaymentScheme,
        kennelPaymentUrl,
        kennelPaymentUrlExpires,
        kennelPaymentMemberSurcharge,
        kennelPaymentNonMemberSurcharge,
        kennelPaymentScheme2,
        kennelPaymentUrl2,
        kennelPaymentUrlExpires2,
        kennelPaymentMemberSurcharge2,
        kennelPaymentNonMemberSurcharge2,
        kennelPaymentScheme3,
        kennelPaymentUrl3,
        kennelPaymentUrlExpires3,
        kennelPaymentMemberSurcharge3,
        kennelPaymentNonMemberSurcharge3,
        runCountStartDate,
        distancePreference,
        kennelSearchTags
      ]);

  @override
  String toString() {
    return 'KennelModel(kennelPublicId: $kennelPublicId, kennelName: $kennelName, kennelShortName: $kennelShortName, kennelUniqueShortName: $kennelUniqueShortName, kennelLogo: $kennelLogo, kennelDescription: $kennelDescription, excludeFromLeaderboard: $excludeFromLeaderboard, cityName: $cityName, regionName: $regionName, countryName: $countryName, continentName: $continentName, kennelStatus: $kennelStatus, disseminateHashRunsDotOrg: $disseminateHashRunsDotOrg, disseminateAllowWebLinks: $disseminateAllowWebLinks, disseminationAudience: $disseminationAudience, disseminateOnGlobalGoogleCalendar: $disseminateOnGlobalGoogleCalendar, canEditRunAttendence: $canEditRunAttendence, kennelPinColor: $kennelPinColor, defaultEventPriceForMembers: $defaultEventPriceForMembers, defaultEventPriceForNonMembers: $defaultEventPriceForNonMembers, defaultRunStartTime: $defaultRunStartTime, allowSelfPayment: $allowSelfPayment, allowNegativeCredit: $allowNegativeCredit, cityId: $cityId, provinceStateId: $provinceStateId, countryId: $countryId, defaultRunTags1: $defaultRunTags1, defaultRunTags2: $defaultRunTags2, defaultRunTags3: $defaultRunTags3, membershipDurationInMonths: $membershipDurationInMonths, defaultDistancePreference: $defaultDistancePreference, notificationMinutesBeforeRunForChatPushNotifications: $notificationMinutesBeforeRunForChatPushNotifications, notificationMinutesBeforeRunForCheckinReminder: $notificationMinutesBeforeRunForCheckinReminder, extApiKey: $extApiKey, latitude: $latitude, longitude: $longitude, defaultLatitude: $defaultLatitude, defaultLongitude: $defaultLongitude, publishToGoogleCalendar: $publishToGoogleCalendar, publishToGoogleCalendarAddresses: $publishToGoogleCalendarAddresses, mismanagementTeam: $mismanagementTeam, kennelCoverPhoto: $kennelCoverPhoto, countryFlag: $countryFlag, regionFlag: $regionFlag, cityFlag: $cityFlag, websiteBackgroundColor: $websiteBackgroundColor, websiteBackgroundImage: $websiteBackgroundImage, websiteTitleText: $websiteTitleText, websiteMenuBackgroundColor: $websiteMenuBackgroundColor, websiteMenuTextColor: $websiteMenuTextColor, websiteWelcomeText: $websiteWelcomeText, websiteBodyTextColor: $websiteBodyTextColor, websiteTitleTextColor: $websiteTitleTextColor, websiteMismanagementDescription: $websiteMismanagementDescription, websiteMismanagementJson: $websiteMismanagementJson, websiteExtraMenusJson: $websiteExtraMenusJson, websiteControlFlags: $websiteControlFlags, websiteContactDetailsJson: $websiteContactDetailsJson, websiteBannerImage: $websiteBannerImage, websiteUrlShortcode: $websiteUrlShortcode, websiteTitleFont: $websiteTitleFont, websiteBodyFont: $websiteBodyFont, kennelAdminEmailList: $kennelAdminEmailList, kennelWebsiteUrl: $kennelWebsiteUrl, kennelEventsUrl: $kennelEventsUrl, kennelHcEventsUrl: $kennelHcEventsUrl, bankScheme: $bankScheme, bankAccountNumber: $bankAccountNumber, bankBic: $bankBic, bankBeneficiary: $bankBeneficiary, kennelPaymentScheme: $kennelPaymentScheme, kennelPaymentUrl: $kennelPaymentUrl, kennelPaymentUrlExpires: $kennelPaymentUrlExpires, kennelPaymentMemberSurcharge: $kennelPaymentMemberSurcharge, kennelPaymentNonMemberSurcharge: $kennelPaymentNonMemberSurcharge, kennelPaymentScheme2: $kennelPaymentScheme2, kennelPaymentUrl2: $kennelPaymentUrl2, kennelPaymentUrlExpires2: $kennelPaymentUrlExpires2, kennelPaymentMemberSurcharge2: $kennelPaymentMemberSurcharge2, kennelPaymentNonMemberSurcharge2: $kennelPaymentNonMemberSurcharge2, kennelPaymentScheme3: $kennelPaymentScheme3, kennelPaymentUrl3: $kennelPaymentUrl3, kennelPaymentUrlExpires3: $kennelPaymentUrlExpires3, kennelPaymentMemberSurcharge3: $kennelPaymentMemberSurcharge3, kennelPaymentNonMemberSurcharge3: $kennelPaymentNonMemberSurcharge3, runCountStartDate: $runCountStartDate, distancePreference: $distancePreference, kennelSearchTags: $kennelSearchTags)';
  }
}

/// @nodoc
abstract mixin class _$KennelModelCopyWith<$Res>
    implements $KennelModelCopyWith<$Res> {
  factory _$KennelModelCopyWith(
          _KennelModel value, $Res Function(_KennelModel) _then) =
      __$KennelModelCopyWithImpl;
  @override
  @useResult
  $Res call(
      {@UuidConverter() UuidValue kennelPublicId,
      String kennelName,
      String kennelShortName,
      String kennelUniqueShortName,
      String kennelLogo,
      String kennelDescription,
      int excludeFromLeaderboard,
      String cityName,
      String regionName,
      String countryName,
      String continentName,
      int kennelStatus,
      int disseminateHashRunsDotOrg,
      int disseminateAllowWebLinks,
      int disseminationAudience,
      int disseminateOnGlobalGoogleCalendar,
      int canEditRunAttendence,
      int kennelPinColor,
      double defaultEventPriceForMembers,
      double defaultEventPriceForNonMembers,
      DateTime defaultRunStartTime,
      int allowSelfPayment,
      int allowNegativeCredit,
      @UuidConverter() UuidValue cityId,
      @UuidConverter() UuidValue provinceStateId,
      @UuidConverter() UuidValue countryId,
      int defaultRunTags1,
      int defaultRunTags2,
      int defaultRunTags3,
      int membershipDurationInMonths,
      int defaultDistancePreference,
      int notificationMinutesBeforeRunForChatPushNotifications,
      int notificationMinutesBeforeRunForCheckinReminder,
      String extApiKey,
      double? latitude,
      double? longitude,
      double? defaultLatitude,
      double? defaultLongitude,
      int? publishToGoogleCalendar,
      String? publishToGoogleCalendarAddresses,
      String? mismanagementTeam,
      String? kennelCoverPhoto,
      String? countryFlag,
      String? regionFlag,
      String? cityFlag,
      String? websiteBackgroundColor,
      String? websiteBackgroundImage,
      String? websiteTitleText,
      String? websiteMenuBackgroundColor,
      String? websiteMenuTextColor,
      String? websiteWelcomeText,
      String? websiteBodyTextColor,
      String? websiteTitleTextColor,
      String? websiteMismanagementDescription,
      String? websiteMismanagementJson,
      String? websiteExtraMenusJson,
      int? websiteControlFlags,
      String? websiteContactDetailsJson,
      String? websiteBannerImage,
      String? websiteUrlShortcode,
      String? websiteTitleFont,
      String? websiteBodyFont,
      String? kennelAdminEmailList,
      String? kennelWebsiteUrl,
      String? kennelEventsUrl,
      String? kennelHcEventsUrl,
      String? bankScheme,
      String? bankAccountNumber,
      String? bankBic,
      String? bankBeneficiary,
      String? kennelPaymentScheme,
      String? kennelPaymentUrl,
      DateTime? kennelPaymentUrlExpires,
      double? kennelPaymentMemberSurcharge,
      double? kennelPaymentNonMemberSurcharge,
      String? kennelPaymentScheme2,
      String? kennelPaymentUrl2,
      DateTime? kennelPaymentUrlExpires2,
      double? kennelPaymentMemberSurcharge2,
      double? kennelPaymentNonMemberSurcharge2,
      String? kennelPaymentScheme3,
      String? kennelPaymentUrl3,
      DateTime? kennelPaymentUrlExpires3,
      double? kennelPaymentMemberSurcharge3,
      double? kennelPaymentNonMemberSurcharge3,
      DateTime? runCountStartDate,
      int? distancePreference,
      String? kennelSearchTags});
}

/// @nodoc
class __$KennelModelCopyWithImpl<$Res> implements _$KennelModelCopyWith<$Res> {
  __$KennelModelCopyWithImpl(this._self, this._then);

  final _KennelModel _self;
  final $Res Function(_KennelModel) _then;

  /// Create a copy of KennelModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? kennelPublicId = null,
    Object? kennelName = null,
    Object? kennelShortName = null,
    Object? kennelUniqueShortName = null,
    Object? kennelLogo = null,
    Object? kennelDescription = null,
    Object? excludeFromLeaderboard = null,
    Object? cityName = null,
    Object? regionName = null,
    Object? countryName = null,
    Object? continentName = null,
    Object? kennelStatus = null,
    Object? disseminateHashRunsDotOrg = null,
    Object? disseminateAllowWebLinks = null,
    Object? disseminationAudience = null,
    Object? disseminateOnGlobalGoogleCalendar = null,
    Object? canEditRunAttendence = null,
    Object? kennelPinColor = null,
    Object? defaultEventPriceForMembers = null,
    Object? defaultEventPriceForNonMembers = null,
    Object? defaultRunStartTime = null,
    Object? allowSelfPayment = null,
    Object? allowNegativeCredit = null,
    Object? cityId = null,
    Object? provinceStateId = null,
    Object? countryId = null,
    Object? defaultRunTags1 = null,
    Object? defaultRunTags2 = null,
    Object? defaultRunTags3 = null,
    Object? membershipDurationInMonths = null,
    Object? defaultDistancePreference = null,
    Object? notificationMinutesBeforeRunForChatPushNotifications = null,
    Object? notificationMinutesBeforeRunForCheckinReminder = null,
    Object? extApiKey = null,
    Object? latitude = freezed,
    Object? longitude = freezed,
    Object? defaultLatitude = freezed,
    Object? defaultLongitude = freezed,
    Object? publishToGoogleCalendar = freezed,
    Object? publishToGoogleCalendarAddresses = freezed,
    Object? mismanagementTeam = freezed,
    Object? kennelCoverPhoto = freezed,
    Object? countryFlag = freezed,
    Object? regionFlag = freezed,
    Object? cityFlag = freezed,
    Object? websiteBackgroundColor = freezed,
    Object? websiteBackgroundImage = freezed,
    Object? websiteTitleText = freezed,
    Object? websiteMenuBackgroundColor = freezed,
    Object? websiteMenuTextColor = freezed,
    Object? websiteWelcomeText = freezed,
    Object? websiteBodyTextColor = freezed,
    Object? websiteTitleTextColor = freezed,
    Object? websiteMismanagementDescription = freezed,
    Object? websiteMismanagementJson = freezed,
    Object? websiteExtraMenusJson = freezed,
    Object? websiteControlFlags = freezed,
    Object? websiteContactDetailsJson = freezed,
    Object? websiteBannerImage = freezed,
    Object? websiteUrlShortcode = freezed,
    Object? websiteTitleFont = freezed,
    Object? websiteBodyFont = freezed,
    Object? kennelAdminEmailList = freezed,
    Object? kennelWebsiteUrl = freezed,
    Object? kennelEventsUrl = freezed,
    Object? kennelHcEventsUrl = freezed,
    Object? bankScheme = freezed,
    Object? bankAccountNumber = freezed,
    Object? bankBic = freezed,
    Object? bankBeneficiary = freezed,
    Object? kennelPaymentScheme = freezed,
    Object? kennelPaymentUrl = freezed,
    Object? kennelPaymentUrlExpires = freezed,
    Object? kennelPaymentMemberSurcharge = freezed,
    Object? kennelPaymentNonMemberSurcharge = freezed,
    Object? kennelPaymentScheme2 = freezed,
    Object? kennelPaymentUrl2 = freezed,
    Object? kennelPaymentUrlExpires2 = freezed,
    Object? kennelPaymentMemberSurcharge2 = freezed,
    Object? kennelPaymentNonMemberSurcharge2 = freezed,
    Object? kennelPaymentScheme3 = freezed,
    Object? kennelPaymentUrl3 = freezed,
    Object? kennelPaymentUrlExpires3 = freezed,
    Object? kennelPaymentMemberSurcharge3 = freezed,
    Object? kennelPaymentNonMemberSurcharge3 = freezed,
    Object? runCountStartDate = freezed,
    Object? distancePreference = freezed,
    Object? kennelSearchTags = freezed,
  }) {
    return _then(_KennelModel(
      kennelPublicId: null == kennelPublicId
          ? _self.kennelPublicId
          : kennelPublicId // ignore: cast_nullable_to_non_nullable
              as UuidValue,
      kennelName: null == kennelName
          ? _self.kennelName
          : kennelName // ignore: cast_nullable_to_non_nullable
              as String,
      kennelShortName: null == kennelShortName
          ? _self.kennelShortName
          : kennelShortName // ignore: cast_nullable_to_non_nullable
              as String,
      kennelUniqueShortName: null == kennelUniqueShortName
          ? _self.kennelUniqueShortName
          : kennelUniqueShortName // ignore: cast_nullable_to_non_nullable
              as String,
      kennelLogo: null == kennelLogo
          ? _self.kennelLogo
          : kennelLogo // ignore: cast_nullable_to_non_nullable
              as String,
      kennelDescription: null == kennelDescription
          ? _self.kennelDescription
          : kennelDescription // ignore: cast_nullable_to_non_nullable
              as String,
      excludeFromLeaderboard: null == excludeFromLeaderboard
          ? _self.excludeFromLeaderboard
          : excludeFromLeaderboard // ignore: cast_nullable_to_non_nullable
              as int,
      cityName: null == cityName
          ? _self.cityName
          : cityName // ignore: cast_nullable_to_non_nullable
              as String,
      regionName: null == regionName
          ? _self.regionName
          : regionName // ignore: cast_nullable_to_non_nullable
              as String,
      countryName: null == countryName
          ? _self.countryName
          : countryName // ignore: cast_nullable_to_non_nullable
              as String,
      continentName: null == continentName
          ? _self.continentName
          : continentName // ignore: cast_nullable_to_non_nullable
              as String,
      kennelStatus: null == kennelStatus
          ? _self.kennelStatus
          : kennelStatus // ignore: cast_nullable_to_non_nullable
              as int,
      disseminateHashRunsDotOrg: null == disseminateHashRunsDotOrg
          ? _self.disseminateHashRunsDotOrg
          : disseminateHashRunsDotOrg // ignore: cast_nullable_to_non_nullable
              as int,
      disseminateAllowWebLinks: null == disseminateAllowWebLinks
          ? _self.disseminateAllowWebLinks
          : disseminateAllowWebLinks // ignore: cast_nullable_to_non_nullable
              as int,
      disseminationAudience: null == disseminationAudience
          ? _self.disseminationAudience
          : disseminationAudience // ignore: cast_nullable_to_non_nullable
              as int,
      disseminateOnGlobalGoogleCalendar: null ==
              disseminateOnGlobalGoogleCalendar
          ? _self.disseminateOnGlobalGoogleCalendar
          : disseminateOnGlobalGoogleCalendar // ignore: cast_nullable_to_non_nullable
              as int,
      canEditRunAttendence: null == canEditRunAttendence
          ? _self.canEditRunAttendence
          : canEditRunAttendence // ignore: cast_nullable_to_non_nullable
              as int,
      kennelPinColor: null == kennelPinColor
          ? _self.kennelPinColor
          : kennelPinColor // ignore: cast_nullable_to_non_nullable
              as int,
      defaultEventPriceForMembers: null == defaultEventPriceForMembers
          ? _self.defaultEventPriceForMembers
          : defaultEventPriceForMembers // ignore: cast_nullable_to_non_nullable
              as double,
      defaultEventPriceForNonMembers: null == defaultEventPriceForNonMembers
          ? _self.defaultEventPriceForNonMembers
          : defaultEventPriceForNonMembers // ignore: cast_nullable_to_non_nullable
              as double,
      defaultRunStartTime: null == defaultRunStartTime
          ? _self.defaultRunStartTime
          : defaultRunStartTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      allowSelfPayment: null == allowSelfPayment
          ? _self.allowSelfPayment
          : allowSelfPayment // ignore: cast_nullable_to_non_nullable
              as int,
      allowNegativeCredit: null == allowNegativeCredit
          ? _self.allowNegativeCredit
          : allowNegativeCredit // ignore: cast_nullable_to_non_nullable
              as int,
      cityId: null == cityId
          ? _self.cityId
          : cityId // ignore: cast_nullable_to_non_nullable
              as UuidValue,
      provinceStateId: null == provinceStateId
          ? _self.provinceStateId
          : provinceStateId // ignore: cast_nullable_to_non_nullable
              as UuidValue,
      countryId: null == countryId
          ? _self.countryId
          : countryId // ignore: cast_nullable_to_non_nullable
              as UuidValue,
      defaultRunTags1: null == defaultRunTags1
          ? _self.defaultRunTags1
          : defaultRunTags1 // ignore: cast_nullable_to_non_nullable
              as int,
      defaultRunTags2: null == defaultRunTags2
          ? _self.defaultRunTags2
          : defaultRunTags2 // ignore: cast_nullable_to_non_nullable
              as int,
      defaultRunTags3: null == defaultRunTags3
          ? _self.defaultRunTags3
          : defaultRunTags3 // ignore: cast_nullable_to_non_nullable
              as int,
      membershipDurationInMonths: null == membershipDurationInMonths
          ? _self.membershipDurationInMonths
          : membershipDurationInMonths // ignore: cast_nullable_to_non_nullable
              as int,
      defaultDistancePreference: null == defaultDistancePreference
          ? _self.defaultDistancePreference
          : defaultDistancePreference // ignore: cast_nullable_to_non_nullable
              as int,
      notificationMinutesBeforeRunForChatPushNotifications: null ==
              notificationMinutesBeforeRunForChatPushNotifications
          ? _self.notificationMinutesBeforeRunForChatPushNotifications
          : notificationMinutesBeforeRunForChatPushNotifications // ignore: cast_nullable_to_non_nullable
              as int,
      notificationMinutesBeforeRunForCheckinReminder: null ==
              notificationMinutesBeforeRunForCheckinReminder
          ? _self.notificationMinutesBeforeRunForCheckinReminder
          : notificationMinutesBeforeRunForCheckinReminder // ignore: cast_nullable_to_non_nullable
              as int,
      extApiKey: null == extApiKey
          ? _self.extApiKey
          : extApiKey // ignore: cast_nullable_to_non_nullable
              as String,
      latitude: freezed == latitude
          ? _self.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double?,
      longitude: freezed == longitude
          ? _self.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double?,
      defaultLatitude: freezed == defaultLatitude
          ? _self.defaultLatitude
          : defaultLatitude // ignore: cast_nullable_to_non_nullable
              as double?,
      defaultLongitude: freezed == defaultLongitude
          ? _self.defaultLongitude
          : defaultLongitude // ignore: cast_nullable_to_non_nullable
              as double?,
      publishToGoogleCalendar: freezed == publishToGoogleCalendar
          ? _self.publishToGoogleCalendar
          : publishToGoogleCalendar // ignore: cast_nullable_to_non_nullable
              as int?,
      publishToGoogleCalendarAddresses: freezed ==
              publishToGoogleCalendarAddresses
          ? _self.publishToGoogleCalendarAddresses
          : publishToGoogleCalendarAddresses // ignore: cast_nullable_to_non_nullable
              as String?,
      mismanagementTeam: freezed == mismanagementTeam
          ? _self.mismanagementTeam
          : mismanagementTeam // ignore: cast_nullable_to_non_nullable
              as String?,
      kennelCoverPhoto: freezed == kennelCoverPhoto
          ? _self.kennelCoverPhoto
          : kennelCoverPhoto // ignore: cast_nullable_to_non_nullable
              as String?,
      countryFlag: freezed == countryFlag
          ? _self.countryFlag
          : countryFlag // ignore: cast_nullable_to_non_nullable
              as String?,
      regionFlag: freezed == regionFlag
          ? _self.regionFlag
          : regionFlag // ignore: cast_nullable_to_non_nullable
              as String?,
      cityFlag: freezed == cityFlag
          ? _self.cityFlag
          : cityFlag // ignore: cast_nullable_to_non_nullable
              as String?,
      websiteBackgroundColor: freezed == websiteBackgroundColor
          ? _self.websiteBackgroundColor
          : websiteBackgroundColor // ignore: cast_nullable_to_non_nullable
              as String?,
      websiteBackgroundImage: freezed == websiteBackgroundImage
          ? _self.websiteBackgroundImage
          : websiteBackgroundImage // ignore: cast_nullable_to_non_nullable
              as String?,
      websiteTitleText: freezed == websiteTitleText
          ? _self.websiteTitleText
          : websiteTitleText // ignore: cast_nullable_to_non_nullable
              as String?,
      websiteMenuBackgroundColor: freezed == websiteMenuBackgroundColor
          ? _self.websiteMenuBackgroundColor
          : websiteMenuBackgroundColor // ignore: cast_nullable_to_non_nullable
              as String?,
      websiteMenuTextColor: freezed == websiteMenuTextColor
          ? _self.websiteMenuTextColor
          : websiteMenuTextColor // ignore: cast_nullable_to_non_nullable
              as String?,
      websiteWelcomeText: freezed == websiteWelcomeText
          ? _self.websiteWelcomeText
          : websiteWelcomeText // ignore: cast_nullable_to_non_nullable
              as String?,
      websiteBodyTextColor: freezed == websiteBodyTextColor
          ? _self.websiteBodyTextColor
          : websiteBodyTextColor // ignore: cast_nullable_to_non_nullable
              as String?,
      websiteTitleTextColor: freezed == websiteTitleTextColor
          ? _self.websiteTitleTextColor
          : websiteTitleTextColor // ignore: cast_nullable_to_non_nullable
              as String?,
      websiteMismanagementDescription: freezed ==
              websiteMismanagementDescription
          ? _self.websiteMismanagementDescription
          : websiteMismanagementDescription // ignore: cast_nullable_to_non_nullable
              as String?,
      websiteMismanagementJson: freezed == websiteMismanagementJson
          ? _self.websiteMismanagementJson
          : websiteMismanagementJson // ignore: cast_nullable_to_non_nullable
              as String?,
      websiteExtraMenusJson: freezed == websiteExtraMenusJson
          ? _self.websiteExtraMenusJson
          : websiteExtraMenusJson // ignore: cast_nullable_to_non_nullable
              as String?,
      websiteControlFlags: freezed == websiteControlFlags
          ? _self.websiteControlFlags
          : websiteControlFlags // ignore: cast_nullable_to_non_nullable
              as int?,
      websiteContactDetailsJson: freezed == websiteContactDetailsJson
          ? _self.websiteContactDetailsJson
          : websiteContactDetailsJson // ignore: cast_nullable_to_non_nullable
              as String?,
      websiteBannerImage: freezed == websiteBannerImage
          ? _self.websiteBannerImage
          : websiteBannerImage // ignore: cast_nullable_to_non_nullable
              as String?,
      websiteUrlShortcode: freezed == websiteUrlShortcode
          ? _self.websiteUrlShortcode
          : websiteUrlShortcode // ignore: cast_nullable_to_non_nullable
              as String?,
      websiteTitleFont: freezed == websiteTitleFont
          ? _self.websiteTitleFont
          : websiteTitleFont // ignore: cast_nullable_to_non_nullable
              as String?,
      websiteBodyFont: freezed == websiteBodyFont
          ? _self.websiteBodyFont
          : websiteBodyFont // ignore: cast_nullable_to_non_nullable
              as String?,
      kennelAdminEmailList: freezed == kennelAdminEmailList
          ? _self.kennelAdminEmailList
          : kennelAdminEmailList // ignore: cast_nullable_to_non_nullable
              as String?,
      kennelWebsiteUrl: freezed == kennelWebsiteUrl
          ? _self.kennelWebsiteUrl
          : kennelWebsiteUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      kennelEventsUrl: freezed == kennelEventsUrl
          ? _self.kennelEventsUrl
          : kennelEventsUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      kennelHcEventsUrl: freezed == kennelHcEventsUrl
          ? _self.kennelHcEventsUrl
          : kennelHcEventsUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      bankScheme: freezed == bankScheme
          ? _self.bankScheme
          : bankScheme // ignore: cast_nullable_to_non_nullable
              as String?,
      bankAccountNumber: freezed == bankAccountNumber
          ? _self.bankAccountNumber
          : bankAccountNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      bankBic: freezed == bankBic
          ? _self.bankBic
          : bankBic // ignore: cast_nullable_to_non_nullable
              as String?,
      bankBeneficiary: freezed == bankBeneficiary
          ? _self.bankBeneficiary
          : bankBeneficiary // ignore: cast_nullable_to_non_nullable
              as String?,
      kennelPaymentScheme: freezed == kennelPaymentScheme
          ? _self.kennelPaymentScheme
          : kennelPaymentScheme // ignore: cast_nullable_to_non_nullable
              as String?,
      kennelPaymentUrl: freezed == kennelPaymentUrl
          ? _self.kennelPaymentUrl
          : kennelPaymentUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      kennelPaymentUrlExpires: freezed == kennelPaymentUrlExpires
          ? _self.kennelPaymentUrlExpires
          : kennelPaymentUrlExpires // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      kennelPaymentMemberSurcharge: freezed == kennelPaymentMemberSurcharge
          ? _self.kennelPaymentMemberSurcharge
          : kennelPaymentMemberSurcharge // ignore: cast_nullable_to_non_nullable
              as double?,
      kennelPaymentNonMemberSurcharge: freezed ==
              kennelPaymentNonMemberSurcharge
          ? _self.kennelPaymentNonMemberSurcharge
          : kennelPaymentNonMemberSurcharge // ignore: cast_nullable_to_non_nullable
              as double?,
      kennelPaymentScheme2: freezed == kennelPaymentScheme2
          ? _self.kennelPaymentScheme2
          : kennelPaymentScheme2 // ignore: cast_nullable_to_non_nullable
              as String?,
      kennelPaymentUrl2: freezed == kennelPaymentUrl2
          ? _self.kennelPaymentUrl2
          : kennelPaymentUrl2 // ignore: cast_nullable_to_non_nullable
              as String?,
      kennelPaymentUrlExpires2: freezed == kennelPaymentUrlExpires2
          ? _self.kennelPaymentUrlExpires2
          : kennelPaymentUrlExpires2 // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      kennelPaymentMemberSurcharge2: freezed == kennelPaymentMemberSurcharge2
          ? _self.kennelPaymentMemberSurcharge2
          : kennelPaymentMemberSurcharge2 // ignore: cast_nullable_to_non_nullable
              as double?,
      kennelPaymentNonMemberSurcharge2: freezed ==
              kennelPaymentNonMemberSurcharge2
          ? _self.kennelPaymentNonMemberSurcharge2
          : kennelPaymentNonMemberSurcharge2 // ignore: cast_nullable_to_non_nullable
              as double?,
      kennelPaymentScheme3: freezed == kennelPaymentScheme3
          ? _self.kennelPaymentScheme3
          : kennelPaymentScheme3 // ignore: cast_nullable_to_non_nullable
              as String?,
      kennelPaymentUrl3: freezed == kennelPaymentUrl3
          ? _self.kennelPaymentUrl3
          : kennelPaymentUrl3 // ignore: cast_nullable_to_non_nullable
              as String?,
      kennelPaymentUrlExpires3: freezed == kennelPaymentUrlExpires3
          ? _self.kennelPaymentUrlExpires3
          : kennelPaymentUrlExpires3 // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      kennelPaymentMemberSurcharge3: freezed == kennelPaymentMemberSurcharge3
          ? _self.kennelPaymentMemberSurcharge3
          : kennelPaymentMemberSurcharge3 // ignore: cast_nullable_to_non_nullable
              as double?,
      kennelPaymentNonMemberSurcharge3: freezed ==
              kennelPaymentNonMemberSurcharge3
          ? _self.kennelPaymentNonMemberSurcharge3
          : kennelPaymentNonMemberSurcharge3 // ignore: cast_nullable_to_non_nullable
              as double?,
      runCountStartDate: freezed == runCountStartDate
          ? _self.runCountStartDate
          : runCountStartDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      distancePreference: freezed == distancePreference
          ? _self.distancePreference
          : distancePreference // ignore: cast_nullable_to_non_nullable
              as int?,
      kennelSearchTags: freezed == kennelSearchTags
          ? _self.kennelSearchTags
          : kennelSearchTags // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on
