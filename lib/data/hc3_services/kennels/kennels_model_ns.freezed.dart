// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'kennels_model_ns.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$KennelsModel implements DiagnosticableTreeMixin {

 String get kennelId; String get publicKennelId; String get cityId; String get regionId; String get countryId; String get kennelName; String? get kennelSearchTags; String get kennelShortName; String get kennelUniqueShortName; String? get kennelDescription; String get kennelLogo; int get kennelPinColor; int get disseminateAllowWebLinks; String? get kennelCoverPhoto; String? get kennelWebsiteUrl; String? get defaultEventCurrencyType; String? get integrationType; int? get kennelInboundIntegrationId; String? get kennelEventsUrl; int get kennelStatus; int get canEditRunAttendence; int get allowNegativeCredit; int get allowSelfPayment; double? get kennelLatitude; double? get kennelLongitude; double get defaultPriceForMembers; double get defaultPriceForNonMembers; int get membershipDurationInMonths; DateTime get defaultRunStartTime; String? get currencyCode; String? get primaryCultureCode; String? get currencySymbol; int? get digitsAfterDecimal; String? get bankScheme; String? get bankAccountNumber; String? get bankBic; String? get bankBeneficiary; String? get kennelPaymentScheme; String? get kennelPaymentUrl; DateTime? get kennelPaymentUrlExpires; double? get kennelPaymentMemberSurcharge; double? get kennelPaymentNonMemberSurcharge; String? get kennelPaymentScheme2; String? get kennelPaymentUrl2; DateTime? get kennelPaymentUrlExpires2; double? get kennelPaymentMemberSurcharge2; double? get kennelPaymentNonMemberSurcharge2; String? get kennelPaymentScheme3; String? get kennelPaymentUrl3; DateTime? get kennelPaymentUrlExpires3; double? get kennelPaymentMemberSurcharge3; double? get kennelPaymentNonMemberSurcharge3; DateTime? get runCountStartDate; String? get kennelMismanagementTeam; int? get distancePreference; DateTime? get updatedAt; int? get removed;
/// Create a copy of KennelsModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KennelsModelCopyWith<KennelsModel> get copyWith => _$KennelsModelCopyWithImpl<KennelsModel>(this as KennelsModel, _$identity);

  /// Serializes this KennelsModel to a JSON map.
  Map<String, dynamic> toJson();

@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'KennelsModel'))
    ..add(DiagnosticsProperty('kennelId', kennelId))..add(DiagnosticsProperty('publicKennelId', publicKennelId))..add(DiagnosticsProperty('cityId', cityId))..add(DiagnosticsProperty('regionId', regionId))..add(DiagnosticsProperty('countryId', countryId))..add(DiagnosticsProperty('kennelName', kennelName))..add(DiagnosticsProperty('kennelSearchTags', kennelSearchTags))..add(DiagnosticsProperty('kennelShortName', kennelShortName))..add(DiagnosticsProperty('kennelUniqueShortName', kennelUniqueShortName))..add(DiagnosticsProperty('kennelDescription', kennelDescription))..add(DiagnosticsProperty('kennelLogo', kennelLogo))..add(DiagnosticsProperty('kennelPinColor', kennelPinColor))..add(DiagnosticsProperty('disseminateAllowWebLinks', disseminateAllowWebLinks))..add(DiagnosticsProperty('kennelCoverPhoto', kennelCoverPhoto))..add(DiagnosticsProperty('kennelWebsiteUrl', kennelWebsiteUrl))..add(DiagnosticsProperty('defaultEventCurrencyType', defaultEventCurrencyType))..add(DiagnosticsProperty('integrationType', integrationType))..add(DiagnosticsProperty('kennelInboundIntegrationId', kennelInboundIntegrationId))..add(DiagnosticsProperty('kennelEventsUrl', kennelEventsUrl))..add(DiagnosticsProperty('kennelStatus', kennelStatus))..add(DiagnosticsProperty('canEditRunAttendence', canEditRunAttendence))..add(DiagnosticsProperty('allowNegativeCredit', allowNegativeCredit))..add(DiagnosticsProperty('allowSelfPayment', allowSelfPayment))..add(DiagnosticsProperty('kennelLatitude', kennelLatitude))..add(DiagnosticsProperty('kennelLongitude', kennelLongitude))..add(DiagnosticsProperty('defaultPriceForMembers', defaultPriceForMembers))..add(DiagnosticsProperty('defaultPriceForNonMembers', defaultPriceForNonMembers))..add(DiagnosticsProperty('membershipDurationInMonths', membershipDurationInMonths))..add(DiagnosticsProperty('defaultRunStartTime', defaultRunStartTime))..add(DiagnosticsProperty('currencyCode', currencyCode))..add(DiagnosticsProperty('primaryCultureCode', primaryCultureCode))..add(DiagnosticsProperty('currencySymbol', currencySymbol))..add(DiagnosticsProperty('digitsAfterDecimal', digitsAfterDecimal))..add(DiagnosticsProperty('bankScheme', bankScheme))..add(DiagnosticsProperty('bankAccountNumber', bankAccountNumber))..add(DiagnosticsProperty('bankBic', bankBic))..add(DiagnosticsProperty('bankBeneficiary', bankBeneficiary))..add(DiagnosticsProperty('kennelPaymentScheme', kennelPaymentScheme))..add(DiagnosticsProperty('kennelPaymentUrl', kennelPaymentUrl))..add(DiagnosticsProperty('kennelPaymentUrlExpires', kennelPaymentUrlExpires))..add(DiagnosticsProperty('kennelPaymentMemberSurcharge', kennelPaymentMemberSurcharge))..add(DiagnosticsProperty('kennelPaymentNonMemberSurcharge', kennelPaymentNonMemberSurcharge))..add(DiagnosticsProperty('kennelPaymentScheme2', kennelPaymentScheme2))..add(DiagnosticsProperty('kennelPaymentUrl2', kennelPaymentUrl2))..add(DiagnosticsProperty('kennelPaymentUrlExpires2', kennelPaymentUrlExpires2))..add(DiagnosticsProperty('kennelPaymentMemberSurcharge2', kennelPaymentMemberSurcharge2))..add(DiagnosticsProperty('kennelPaymentNonMemberSurcharge2', kennelPaymentNonMemberSurcharge2))..add(DiagnosticsProperty('kennelPaymentScheme3', kennelPaymentScheme3))..add(DiagnosticsProperty('kennelPaymentUrl3', kennelPaymentUrl3))..add(DiagnosticsProperty('kennelPaymentUrlExpires3', kennelPaymentUrlExpires3))..add(DiagnosticsProperty('kennelPaymentMemberSurcharge3', kennelPaymentMemberSurcharge3))..add(DiagnosticsProperty('kennelPaymentNonMemberSurcharge3', kennelPaymentNonMemberSurcharge3))..add(DiagnosticsProperty('runCountStartDate', runCountStartDate))..add(DiagnosticsProperty('kennelMismanagementTeam', kennelMismanagementTeam))..add(DiagnosticsProperty('distancePreference', distancePreference))..add(DiagnosticsProperty('updatedAt', updatedAt))..add(DiagnosticsProperty('removed', removed));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KennelsModel&&(identical(other.kennelId, kennelId) || other.kennelId == kennelId)&&(identical(other.publicKennelId, publicKennelId) || other.publicKennelId == publicKennelId)&&(identical(other.cityId, cityId) || other.cityId == cityId)&&(identical(other.regionId, regionId) || other.regionId == regionId)&&(identical(other.countryId, countryId) || other.countryId == countryId)&&(identical(other.kennelName, kennelName) || other.kennelName == kennelName)&&(identical(other.kennelSearchTags, kennelSearchTags) || other.kennelSearchTags == kennelSearchTags)&&(identical(other.kennelShortName, kennelShortName) || other.kennelShortName == kennelShortName)&&(identical(other.kennelUniqueShortName, kennelUniqueShortName) || other.kennelUniqueShortName == kennelUniqueShortName)&&(identical(other.kennelDescription, kennelDescription) || other.kennelDescription == kennelDescription)&&(identical(other.kennelLogo, kennelLogo) || other.kennelLogo == kennelLogo)&&(identical(other.kennelPinColor, kennelPinColor) || other.kennelPinColor == kennelPinColor)&&(identical(other.disseminateAllowWebLinks, disseminateAllowWebLinks) || other.disseminateAllowWebLinks == disseminateAllowWebLinks)&&(identical(other.kennelCoverPhoto, kennelCoverPhoto) || other.kennelCoverPhoto == kennelCoverPhoto)&&(identical(other.kennelWebsiteUrl, kennelWebsiteUrl) || other.kennelWebsiteUrl == kennelWebsiteUrl)&&(identical(other.defaultEventCurrencyType, defaultEventCurrencyType) || other.defaultEventCurrencyType == defaultEventCurrencyType)&&(identical(other.integrationType, integrationType) || other.integrationType == integrationType)&&(identical(other.kennelInboundIntegrationId, kennelInboundIntegrationId) || other.kennelInboundIntegrationId == kennelInboundIntegrationId)&&(identical(other.kennelEventsUrl, kennelEventsUrl) || other.kennelEventsUrl == kennelEventsUrl)&&(identical(other.kennelStatus, kennelStatus) || other.kennelStatus == kennelStatus)&&(identical(other.canEditRunAttendence, canEditRunAttendence) || other.canEditRunAttendence == canEditRunAttendence)&&(identical(other.allowNegativeCredit, allowNegativeCredit) || other.allowNegativeCredit == allowNegativeCredit)&&(identical(other.allowSelfPayment, allowSelfPayment) || other.allowSelfPayment == allowSelfPayment)&&(identical(other.kennelLatitude, kennelLatitude) || other.kennelLatitude == kennelLatitude)&&(identical(other.kennelLongitude, kennelLongitude) || other.kennelLongitude == kennelLongitude)&&(identical(other.defaultPriceForMembers, defaultPriceForMembers) || other.defaultPriceForMembers == defaultPriceForMembers)&&(identical(other.defaultPriceForNonMembers, defaultPriceForNonMembers) || other.defaultPriceForNonMembers == defaultPriceForNonMembers)&&(identical(other.membershipDurationInMonths, membershipDurationInMonths) || other.membershipDurationInMonths == membershipDurationInMonths)&&(identical(other.defaultRunStartTime, defaultRunStartTime) || other.defaultRunStartTime == defaultRunStartTime)&&(identical(other.currencyCode, currencyCode) || other.currencyCode == currencyCode)&&(identical(other.primaryCultureCode, primaryCultureCode) || other.primaryCultureCode == primaryCultureCode)&&(identical(other.currencySymbol, currencySymbol) || other.currencySymbol == currencySymbol)&&(identical(other.digitsAfterDecimal, digitsAfterDecimal) || other.digitsAfterDecimal == digitsAfterDecimal)&&(identical(other.bankScheme, bankScheme) || other.bankScheme == bankScheme)&&(identical(other.bankAccountNumber, bankAccountNumber) || other.bankAccountNumber == bankAccountNumber)&&(identical(other.bankBic, bankBic) || other.bankBic == bankBic)&&(identical(other.bankBeneficiary, bankBeneficiary) || other.bankBeneficiary == bankBeneficiary)&&(identical(other.kennelPaymentScheme, kennelPaymentScheme) || other.kennelPaymentScheme == kennelPaymentScheme)&&(identical(other.kennelPaymentUrl, kennelPaymentUrl) || other.kennelPaymentUrl == kennelPaymentUrl)&&(identical(other.kennelPaymentUrlExpires, kennelPaymentUrlExpires) || other.kennelPaymentUrlExpires == kennelPaymentUrlExpires)&&(identical(other.kennelPaymentMemberSurcharge, kennelPaymentMemberSurcharge) || other.kennelPaymentMemberSurcharge == kennelPaymentMemberSurcharge)&&(identical(other.kennelPaymentNonMemberSurcharge, kennelPaymentNonMemberSurcharge) || other.kennelPaymentNonMemberSurcharge == kennelPaymentNonMemberSurcharge)&&(identical(other.kennelPaymentScheme2, kennelPaymentScheme2) || other.kennelPaymentScheme2 == kennelPaymentScheme2)&&(identical(other.kennelPaymentUrl2, kennelPaymentUrl2) || other.kennelPaymentUrl2 == kennelPaymentUrl2)&&(identical(other.kennelPaymentUrlExpires2, kennelPaymentUrlExpires2) || other.kennelPaymentUrlExpires2 == kennelPaymentUrlExpires2)&&(identical(other.kennelPaymentMemberSurcharge2, kennelPaymentMemberSurcharge2) || other.kennelPaymentMemberSurcharge2 == kennelPaymentMemberSurcharge2)&&(identical(other.kennelPaymentNonMemberSurcharge2, kennelPaymentNonMemberSurcharge2) || other.kennelPaymentNonMemberSurcharge2 == kennelPaymentNonMemberSurcharge2)&&(identical(other.kennelPaymentScheme3, kennelPaymentScheme3) || other.kennelPaymentScheme3 == kennelPaymentScheme3)&&(identical(other.kennelPaymentUrl3, kennelPaymentUrl3) || other.kennelPaymentUrl3 == kennelPaymentUrl3)&&(identical(other.kennelPaymentUrlExpires3, kennelPaymentUrlExpires3) || other.kennelPaymentUrlExpires3 == kennelPaymentUrlExpires3)&&(identical(other.kennelPaymentMemberSurcharge3, kennelPaymentMemberSurcharge3) || other.kennelPaymentMemberSurcharge3 == kennelPaymentMemberSurcharge3)&&(identical(other.kennelPaymentNonMemberSurcharge3, kennelPaymentNonMemberSurcharge3) || other.kennelPaymentNonMemberSurcharge3 == kennelPaymentNonMemberSurcharge3)&&(identical(other.runCountStartDate, runCountStartDate) || other.runCountStartDate == runCountStartDate)&&(identical(other.kennelMismanagementTeam, kennelMismanagementTeam) || other.kennelMismanagementTeam == kennelMismanagementTeam)&&(identical(other.distancePreference, distancePreference) || other.distancePreference == distancePreference)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.removed, removed) || other.removed == removed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,kennelId,publicKennelId,cityId,regionId,countryId,kennelName,kennelSearchTags,kennelShortName,kennelUniqueShortName,kennelDescription,kennelLogo,kennelPinColor,disseminateAllowWebLinks,kennelCoverPhoto,kennelWebsiteUrl,defaultEventCurrencyType,integrationType,kennelInboundIntegrationId,kennelEventsUrl,kennelStatus,canEditRunAttendence,allowNegativeCredit,allowSelfPayment,kennelLatitude,kennelLongitude,defaultPriceForMembers,defaultPriceForNonMembers,membershipDurationInMonths,defaultRunStartTime,currencyCode,primaryCultureCode,currencySymbol,digitsAfterDecimal,bankScheme,bankAccountNumber,bankBic,bankBeneficiary,kennelPaymentScheme,kennelPaymentUrl,kennelPaymentUrlExpires,kennelPaymentMemberSurcharge,kennelPaymentNonMemberSurcharge,kennelPaymentScheme2,kennelPaymentUrl2,kennelPaymentUrlExpires2,kennelPaymentMemberSurcharge2,kennelPaymentNonMemberSurcharge2,kennelPaymentScheme3,kennelPaymentUrl3,kennelPaymentUrlExpires3,kennelPaymentMemberSurcharge3,kennelPaymentNonMemberSurcharge3,runCountStartDate,kennelMismanagementTeam,distancePreference,updatedAt,removed]);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'KennelsModel(kennelId: $kennelId, publicKennelId: $publicKennelId, cityId: $cityId, regionId: $regionId, countryId: $countryId, kennelName: $kennelName, kennelSearchTags: $kennelSearchTags, kennelShortName: $kennelShortName, kennelUniqueShortName: $kennelUniqueShortName, kennelDescription: $kennelDescription, kennelLogo: $kennelLogo, kennelPinColor: $kennelPinColor, disseminateAllowWebLinks: $disseminateAllowWebLinks, kennelCoverPhoto: $kennelCoverPhoto, kennelWebsiteUrl: $kennelWebsiteUrl, defaultEventCurrencyType: $defaultEventCurrencyType, integrationType: $integrationType, kennelInboundIntegrationId: $kennelInboundIntegrationId, kennelEventsUrl: $kennelEventsUrl, kennelStatus: $kennelStatus, canEditRunAttendence: $canEditRunAttendence, allowNegativeCredit: $allowNegativeCredit, allowSelfPayment: $allowSelfPayment, kennelLatitude: $kennelLatitude, kennelLongitude: $kennelLongitude, defaultPriceForMembers: $defaultPriceForMembers, defaultPriceForNonMembers: $defaultPriceForNonMembers, membershipDurationInMonths: $membershipDurationInMonths, defaultRunStartTime: $defaultRunStartTime, currencyCode: $currencyCode, primaryCultureCode: $primaryCultureCode, currencySymbol: $currencySymbol, digitsAfterDecimal: $digitsAfterDecimal, bankScheme: $bankScheme, bankAccountNumber: $bankAccountNumber, bankBic: $bankBic, bankBeneficiary: $bankBeneficiary, kennelPaymentScheme: $kennelPaymentScheme, kennelPaymentUrl: $kennelPaymentUrl, kennelPaymentUrlExpires: $kennelPaymentUrlExpires, kennelPaymentMemberSurcharge: $kennelPaymentMemberSurcharge, kennelPaymentNonMemberSurcharge: $kennelPaymentNonMemberSurcharge, kennelPaymentScheme2: $kennelPaymentScheme2, kennelPaymentUrl2: $kennelPaymentUrl2, kennelPaymentUrlExpires2: $kennelPaymentUrlExpires2, kennelPaymentMemberSurcharge2: $kennelPaymentMemberSurcharge2, kennelPaymentNonMemberSurcharge2: $kennelPaymentNonMemberSurcharge2, kennelPaymentScheme3: $kennelPaymentScheme3, kennelPaymentUrl3: $kennelPaymentUrl3, kennelPaymentUrlExpires3: $kennelPaymentUrlExpires3, kennelPaymentMemberSurcharge3: $kennelPaymentMemberSurcharge3, kennelPaymentNonMemberSurcharge3: $kennelPaymentNonMemberSurcharge3, runCountStartDate: $runCountStartDate, kennelMismanagementTeam: $kennelMismanagementTeam, distancePreference: $distancePreference, updatedAt: $updatedAt, removed: $removed)';
}


}

/// @nodoc
abstract mixin class $KennelsModelCopyWith<$Res>  {
  factory $KennelsModelCopyWith(KennelsModel value, $Res Function(KennelsModel) _then) = _$KennelsModelCopyWithImpl;
@useResult
$Res call({
 String kennelId, String publicKennelId, String cityId, String regionId, String countryId, String kennelName, String? kennelSearchTags, String kennelShortName, String kennelUniqueShortName, String? kennelDescription, String kennelLogo, int kennelPinColor, int disseminateAllowWebLinks, String? kennelCoverPhoto, String? kennelWebsiteUrl, String? defaultEventCurrencyType, String? integrationType, int? kennelInboundIntegrationId, String? kennelEventsUrl, int kennelStatus, int canEditRunAttendence, int allowNegativeCredit, int allowSelfPayment, double? kennelLatitude, double? kennelLongitude, double defaultPriceForMembers, double defaultPriceForNonMembers, int membershipDurationInMonths, DateTime defaultRunStartTime, String? currencyCode, String? primaryCultureCode, String? currencySymbol, int? digitsAfterDecimal, String? bankScheme, String? bankAccountNumber, String? bankBic, String? bankBeneficiary, String? kennelPaymentScheme, String? kennelPaymentUrl, DateTime? kennelPaymentUrlExpires, double? kennelPaymentMemberSurcharge, double? kennelPaymentNonMemberSurcharge, String? kennelPaymentScheme2, String? kennelPaymentUrl2, DateTime? kennelPaymentUrlExpires2, double? kennelPaymentMemberSurcharge2, double? kennelPaymentNonMemberSurcharge2, String? kennelPaymentScheme3, String? kennelPaymentUrl3, DateTime? kennelPaymentUrlExpires3, double? kennelPaymentMemberSurcharge3, double? kennelPaymentNonMemberSurcharge3, DateTime? runCountStartDate, String? kennelMismanagementTeam, int? distancePreference, DateTime? updatedAt, int? removed
});




}
/// @nodoc
class _$KennelsModelCopyWithImpl<$Res>
    implements $KennelsModelCopyWith<$Res> {
  _$KennelsModelCopyWithImpl(this._self, this._then);

  final KennelsModel _self;
  final $Res Function(KennelsModel) _then;

/// Create a copy of KennelsModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kennelId = null,Object? publicKennelId = null,Object? cityId = null,Object? regionId = null,Object? countryId = null,Object? kennelName = null,Object? kennelSearchTags = freezed,Object? kennelShortName = null,Object? kennelUniqueShortName = null,Object? kennelDescription = freezed,Object? kennelLogo = null,Object? kennelPinColor = null,Object? disseminateAllowWebLinks = null,Object? kennelCoverPhoto = freezed,Object? kennelWebsiteUrl = freezed,Object? defaultEventCurrencyType = freezed,Object? integrationType = freezed,Object? kennelInboundIntegrationId = freezed,Object? kennelEventsUrl = freezed,Object? kennelStatus = null,Object? canEditRunAttendence = null,Object? allowNegativeCredit = null,Object? allowSelfPayment = null,Object? kennelLatitude = freezed,Object? kennelLongitude = freezed,Object? defaultPriceForMembers = null,Object? defaultPriceForNonMembers = null,Object? membershipDurationInMonths = null,Object? defaultRunStartTime = null,Object? currencyCode = freezed,Object? primaryCultureCode = freezed,Object? currencySymbol = freezed,Object? digitsAfterDecimal = freezed,Object? bankScheme = freezed,Object? bankAccountNumber = freezed,Object? bankBic = freezed,Object? bankBeneficiary = freezed,Object? kennelPaymentScheme = freezed,Object? kennelPaymentUrl = freezed,Object? kennelPaymentUrlExpires = freezed,Object? kennelPaymentMemberSurcharge = freezed,Object? kennelPaymentNonMemberSurcharge = freezed,Object? kennelPaymentScheme2 = freezed,Object? kennelPaymentUrl2 = freezed,Object? kennelPaymentUrlExpires2 = freezed,Object? kennelPaymentMemberSurcharge2 = freezed,Object? kennelPaymentNonMemberSurcharge2 = freezed,Object? kennelPaymentScheme3 = freezed,Object? kennelPaymentUrl3 = freezed,Object? kennelPaymentUrlExpires3 = freezed,Object? kennelPaymentMemberSurcharge3 = freezed,Object? kennelPaymentNonMemberSurcharge3 = freezed,Object? runCountStartDate = freezed,Object? kennelMismanagementTeam = freezed,Object? distancePreference = freezed,Object? updatedAt = freezed,Object? removed = freezed,}) {
  return _then(_self.copyWith(
kennelId: null == kennelId ? _self.kennelId : kennelId // ignore: cast_nullable_to_non_nullable
as String,publicKennelId: null == publicKennelId ? _self.publicKennelId : publicKennelId // ignore: cast_nullable_to_non_nullable
as String,cityId: null == cityId ? _self.cityId : cityId // ignore: cast_nullable_to_non_nullable
as String,regionId: null == regionId ? _self.regionId : regionId // ignore: cast_nullable_to_non_nullable
as String,countryId: null == countryId ? _self.countryId : countryId // ignore: cast_nullable_to_non_nullable
as String,kennelName: null == kennelName ? _self.kennelName : kennelName // ignore: cast_nullable_to_non_nullable
as String,kennelSearchTags: freezed == kennelSearchTags ? _self.kennelSearchTags : kennelSearchTags // ignore: cast_nullable_to_non_nullable
as String?,kennelShortName: null == kennelShortName ? _self.kennelShortName : kennelShortName // ignore: cast_nullable_to_non_nullable
as String,kennelUniqueShortName: null == kennelUniqueShortName ? _self.kennelUniqueShortName : kennelUniqueShortName // ignore: cast_nullable_to_non_nullable
as String,kennelDescription: freezed == kennelDescription ? _self.kennelDescription : kennelDescription // ignore: cast_nullable_to_non_nullable
as String?,kennelLogo: null == kennelLogo ? _self.kennelLogo : kennelLogo // ignore: cast_nullable_to_non_nullable
as String,kennelPinColor: null == kennelPinColor ? _self.kennelPinColor : kennelPinColor // ignore: cast_nullable_to_non_nullable
as int,disseminateAllowWebLinks: null == disseminateAllowWebLinks ? _self.disseminateAllowWebLinks : disseminateAllowWebLinks // ignore: cast_nullable_to_non_nullable
as int,kennelCoverPhoto: freezed == kennelCoverPhoto ? _self.kennelCoverPhoto : kennelCoverPhoto // ignore: cast_nullable_to_non_nullable
as String?,kennelWebsiteUrl: freezed == kennelWebsiteUrl ? _self.kennelWebsiteUrl : kennelWebsiteUrl // ignore: cast_nullable_to_non_nullable
as String?,defaultEventCurrencyType: freezed == defaultEventCurrencyType ? _self.defaultEventCurrencyType : defaultEventCurrencyType // ignore: cast_nullable_to_non_nullable
as String?,integrationType: freezed == integrationType ? _self.integrationType : integrationType // ignore: cast_nullable_to_non_nullable
as String?,kennelInboundIntegrationId: freezed == kennelInboundIntegrationId ? _self.kennelInboundIntegrationId : kennelInboundIntegrationId // ignore: cast_nullable_to_non_nullable
as int?,kennelEventsUrl: freezed == kennelEventsUrl ? _self.kennelEventsUrl : kennelEventsUrl // ignore: cast_nullable_to_non_nullable
as String?,kennelStatus: null == kennelStatus ? _self.kennelStatus : kennelStatus // ignore: cast_nullable_to_non_nullable
as int,canEditRunAttendence: null == canEditRunAttendence ? _self.canEditRunAttendence : canEditRunAttendence // ignore: cast_nullable_to_non_nullable
as int,allowNegativeCredit: null == allowNegativeCredit ? _self.allowNegativeCredit : allowNegativeCredit // ignore: cast_nullable_to_non_nullable
as int,allowSelfPayment: null == allowSelfPayment ? _self.allowSelfPayment : allowSelfPayment // ignore: cast_nullable_to_non_nullable
as int,kennelLatitude: freezed == kennelLatitude ? _self.kennelLatitude : kennelLatitude // ignore: cast_nullable_to_non_nullable
as double?,kennelLongitude: freezed == kennelLongitude ? _self.kennelLongitude : kennelLongitude // ignore: cast_nullable_to_non_nullable
as double?,defaultPriceForMembers: null == defaultPriceForMembers ? _self.defaultPriceForMembers : defaultPriceForMembers // ignore: cast_nullable_to_non_nullable
as double,defaultPriceForNonMembers: null == defaultPriceForNonMembers ? _self.defaultPriceForNonMembers : defaultPriceForNonMembers // ignore: cast_nullable_to_non_nullable
as double,membershipDurationInMonths: null == membershipDurationInMonths ? _self.membershipDurationInMonths : membershipDurationInMonths // ignore: cast_nullable_to_non_nullable
as int,defaultRunStartTime: null == defaultRunStartTime ? _self.defaultRunStartTime : defaultRunStartTime // ignore: cast_nullable_to_non_nullable
as DateTime,currencyCode: freezed == currencyCode ? _self.currencyCode : currencyCode // ignore: cast_nullable_to_non_nullable
as String?,primaryCultureCode: freezed == primaryCultureCode ? _self.primaryCultureCode : primaryCultureCode // ignore: cast_nullable_to_non_nullable
as String?,currencySymbol: freezed == currencySymbol ? _self.currencySymbol : currencySymbol // ignore: cast_nullable_to_non_nullable
as String?,digitsAfterDecimal: freezed == digitsAfterDecimal ? _self.digitsAfterDecimal : digitsAfterDecimal // ignore: cast_nullable_to_non_nullable
as int?,bankScheme: freezed == bankScheme ? _self.bankScheme : bankScheme // ignore: cast_nullable_to_non_nullable
as String?,bankAccountNumber: freezed == bankAccountNumber ? _self.bankAccountNumber : bankAccountNumber // ignore: cast_nullable_to_non_nullable
as String?,bankBic: freezed == bankBic ? _self.bankBic : bankBic // ignore: cast_nullable_to_non_nullable
as String?,bankBeneficiary: freezed == bankBeneficiary ? _self.bankBeneficiary : bankBeneficiary // ignore: cast_nullable_to_non_nullable
as String?,kennelPaymentScheme: freezed == kennelPaymentScheme ? _self.kennelPaymentScheme : kennelPaymentScheme // ignore: cast_nullable_to_non_nullable
as String?,kennelPaymentUrl: freezed == kennelPaymentUrl ? _self.kennelPaymentUrl : kennelPaymentUrl // ignore: cast_nullable_to_non_nullable
as String?,kennelPaymentUrlExpires: freezed == kennelPaymentUrlExpires ? _self.kennelPaymentUrlExpires : kennelPaymentUrlExpires // ignore: cast_nullable_to_non_nullable
as DateTime?,kennelPaymentMemberSurcharge: freezed == kennelPaymentMemberSurcharge ? _self.kennelPaymentMemberSurcharge : kennelPaymentMemberSurcharge // ignore: cast_nullable_to_non_nullable
as double?,kennelPaymentNonMemberSurcharge: freezed == kennelPaymentNonMemberSurcharge ? _self.kennelPaymentNonMemberSurcharge : kennelPaymentNonMemberSurcharge // ignore: cast_nullable_to_non_nullable
as double?,kennelPaymentScheme2: freezed == kennelPaymentScheme2 ? _self.kennelPaymentScheme2 : kennelPaymentScheme2 // ignore: cast_nullable_to_non_nullable
as String?,kennelPaymentUrl2: freezed == kennelPaymentUrl2 ? _self.kennelPaymentUrl2 : kennelPaymentUrl2 // ignore: cast_nullable_to_non_nullable
as String?,kennelPaymentUrlExpires2: freezed == kennelPaymentUrlExpires2 ? _self.kennelPaymentUrlExpires2 : kennelPaymentUrlExpires2 // ignore: cast_nullable_to_non_nullable
as DateTime?,kennelPaymentMemberSurcharge2: freezed == kennelPaymentMemberSurcharge2 ? _self.kennelPaymentMemberSurcharge2 : kennelPaymentMemberSurcharge2 // ignore: cast_nullable_to_non_nullable
as double?,kennelPaymentNonMemberSurcharge2: freezed == kennelPaymentNonMemberSurcharge2 ? _self.kennelPaymentNonMemberSurcharge2 : kennelPaymentNonMemberSurcharge2 // ignore: cast_nullable_to_non_nullable
as double?,kennelPaymentScheme3: freezed == kennelPaymentScheme3 ? _self.kennelPaymentScheme3 : kennelPaymentScheme3 // ignore: cast_nullable_to_non_nullable
as String?,kennelPaymentUrl3: freezed == kennelPaymentUrl3 ? _self.kennelPaymentUrl3 : kennelPaymentUrl3 // ignore: cast_nullable_to_non_nullable
as String?,kennelPaymentUrlExpires3: freezed == kennelPaymentUrlExpires3 ? _self.kennelPaymentUrlExpires3 : kennelPaymentUrlExpires3 // ignore: cast_nullable_to_non_nullable
as DateTime?,kennelPaymentMemberSurcharge3: freezed == kennelPaymentMemberSurcharge3 ? _self.kennelPaymentMemberSurcharge3 : kennelPaymentMemberSurcharge3 // ignore: cast_nullable_to_non_nullable
as double?,kennelPaymentNonMemberSurcharge3: freezed == kennelPaymentNonMemberSurcharge3 ? _self.kennelPaymentNonMemberSurcharge3 : kennelPaymentNonMemberSurcharge3 // ignore: cast_nullable_to_non_nullable
as double?,runCountStartDate: freezed == runCountStartDate ? _self.runCountStartDate : runCountStartDate // ignore: cast_nullable_to_non_nullable
as DateTime?,kennelMismanagementTeam: freezed == kennelMismanagementTeam ? _self.kennelMismanagementTeam : kennelMismanagementTeam // ignore: cast_nullable_to_non_nullable
as String?,distancePreference: freezed == distancePreference ? _self.distancePreference : distancePreference // ignore: cast_nullable_to_non_nullable
as int?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,removed: freezed == removed ? _self.removed : removed // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _KennelsModel with DiagnosticableTreeMixin implements KennelsModel {
   _KennelsModel({required this.kennelId, required this.publicKennelId, required this.cityId, required this.regionId, required this.countryId, required this.kennelName, this.kennelSearchTags, required this.kennelShortName, required this.kennelUniqueShortName, this.kennelDescription, required this.kennelLogo, required this.kennelPinColor, required this.disseminateAllowWebLinks, this.kennelCoverPhoto, this.kennelWebsiteUrl, this.defaultEventCurrencyType, this.integrationType, this.kennelInboundIntegrationId, this.kennelEventsUrl, required this.kennelStatus, required this.canEditRunAttendence, required this.allowNegativeCredit, required this.allowSelfPayment, this.kennelLatitude, this.kennelLongitude, required this.defaultPriceForMembers, required this.defaultPriceForNonMembers, required this.membershipDurationInMonths, required this.defaultRunStartTime, this.currencyCode, this.primaryCultureCode, this.currencySymbol, this.digitsAfterDecimal, this.bankScheme, this.bankAccountNumber, this.bankBic, this.bankBeneficiary, this.kennelPaymentScheme, this.kennelPaymentUrl, this.kennelPaymentUrlExpires, this.kennelPaymentMemberSurcharge, this.kennelPaymentNonMemberSurcharge, this.kennelPaymentScheme2, this.kennelPaymentUrl2, this.kennelPaymentUrlExpires2, this.kennelPaymentMemberSurcharge2, this.kennelPaymentNonMemberSurcharge2, this.kennelPaymentScheme3, this.kennelPaymentUrl3, this.kennelPaymentUrlExpires3, this.kennelPaymentMemberSurcharge3, this.kennelPaymentNonMemberSurcharge3, this.runCountStartDate, this.kennelMismanagementTeam, this.distancePreference, this.updatedAt, this.removed});
  factory _KennelsModel.fromJson(Map<String, dynamic> json) => _$KennelsModelFromJson(json);

@override final  String kennelId;
@override final  String publicKennelId;
@override final  String cityId;
@override final  String regionId;
@override final  String countryId;
@override final  String kennelName;
@override final  String? kennelSearchTags;
@override final  String kennelShortName;
@override final  String kennelUniqueShortName;
@override final  String? kennelDescription;
@override final  String kennelLogo;
@override final  int kennelPinColor;
@override final  int disseminateAllowWebLinks;
@override final  String? kennelCoverPhoto;
@override final  String? kennelWebsiteUrl;
@override final  String? defaultEventCurrencyType;
@override final  String? integrationType;
@override final  int? kennelInboundIntegrationId;
@override final  String? kennelEventsUrl;
@override final  int kennelStatus;
@override final  int canEditRunAttendence;
@override final  int allowNegativeCredit;
@override final  int allowSelfPayment;
@override final  double? kennelLatitude;
@override final  double? kennelLongitude;
@override final  double defaultPriceForMembers;
@override final  double defaultPriceForNonMembers;
@override final  int membershipDurationInMonths;
@override final  DateTime defaultRunStartTime;
@override final  String? currencyCode;
@override final  String? primaryCultureCode;
@override final  String? currencySymbol;
@override final  int? digitsAfterDecimal;
@override final  String? bankScheme;
@override final  String? bankAccountNumber;
@override final  String? bankBic;
@override final  String? bankBeneficiary;
@override final  String? kennelPaymentScheme;
@override final  String? kennelPaymentUrl;
@override final  DateTime? kennelPaymentUrlExpires;
@override final  double? kennelPaymentMemberSurcharge;
@override final  double? kennelPaymentNonMemberSurcharge;
@override final  String? kennelPaymentScheme2;
@override final  String? kennelPaymentUrl2;
@override final  DateTime? kennelPaymentUrlExpires2;
@override final  double? kennelPaymentMemberSurcharge2;
@override final  double? kennelPaymentNonMemberSurcharge2;
@override final  String? kennelPaymentScheme3;
@override final  String? kennelPaymentUrl3;
@override final  DateTime? kennelPaymentUrlExpires3;
@override final  double? kennelPaymentMemberSurcharge3;
@override final  double? kennelPaymentNonMemberSurcharge3;
@override final  DateTime? runCountStartDate;
@override final  String? kennelMismanagementTeam;
@override final  int? distancePreference;
@override final  DateTime? updatedAt;
@override final  int? removed;

/// Create a copy of KennelsModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$KennelsModelCopyWith<_KennelsModel> get copyWith => __$KennelsModelCopyWithImpl<_KennelsModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$KennelsModelToJson(this, );
}
@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'KennelsModel'))
    ..add(DiagnosticsProperty('kennelId', kennelId))..add(DiagnosticsProperty('publicKennelId', publicKennelId))..add(DiagnosticsProperty('cityId', cityId))..add(DiagnosticsProperty('regionId', regionId))..add(DiagnosticsProperty('countryId', countryId))..add(DiagnosticsProperty('kennelName', kennelName))..add(DiagnosticsProperty('kennelSearchTags', kennelSearchTags))..add(DiagnosticsProperty('kennelShortName', kennelShortName))..add(DiagnosticsProperty('kennelUniqueShortName', kennelUniqueShortName))..add(DiagnosticsProperty('kennelDescription', kennelDescription))..add(DiagnosticsProperty('kennelLogo', kennelLogo))..add(DiagnosticsProperty('kennelPinColor', kennelPinColor))..add(DiagnosticsProperty('disseminateAllowWebLinks', disseminateAllowWebLinks))..add(DiagnosticsProperty('kennelCoverPhoto', kennelCoverPhoto))..add(DiagnosticsProperty('kennelWebsiteUrl', kennelWebsiteUrl))..add(DiagnosticsProperty('defaultEventCurrencyType', defaultEventCurrencyType))..add(DiagnosticsProperty('integrationType', integrationType))..add(DiagnosticsProperty('kennelInboundIntegrationId', kennelInboundIntegrationId))..add(DiagnosticsProperty('kennelEventsUrl', kennelEventsUrl))..add(DiagnosticsProperty('kennelStatus', kennelStatus))..add(DiagnosticsProperty('canEditRunAttendence', canEditRunAttendence))..add(DiagnosticsProperty('allowNegativeCredit', allowNegativeCredit))..add(DiagnosticsProperty('allowSelfPayment', allowSelfPayment))..add(DiagnosticsProperty('kennelLatitude', kennelLatitude))..add(DiagnosticsProperty('kennelLongitude', kennelLongitude))..add(DiagnosticsProperty('defaultPriceForMembers', defaultPriceForMembers))..add(DiagnosticsProperty('defaultPriceForNonMembers', defaultPriceForNonMembers))..add(DiagnosticsProperty('membershipDurationInMonths', membershipDurationInMonths))..add(DiagnosticsProperty('defaultRunStartTime', defaultRunStartTime))..add(DiagnosticsProperty('currencyCode', currencyCode))..add(DiagnosticsProperty('primaryCultureCode', primaryCultureCode))..add(DiagnosticsProperty('currencySymbol', currencySymbol))..add(DiagnosticsProperty('digitsAfterDecimal', digitsAfterDecimal))..add(DiagnosticsProperty('bankScheme', bankScheme))..add(DiagnosticsProperty('bankAccountNumber', bankAccountNumber))..add(DiagnosticsProperty('bankBic', bankBic))..add(DiagnosticsProperty('bankBeneficiary', bankBeneficiary))..add(DiagnosticsProperty('kennelPaymentScheme', kennelPaymentScheme))..add(DiagnosticsProperty('kennelPaymentUrl', kennelPaymentUrl))..add(DiagnosticsProperty('kennelPaymentUrlExpires', kennelPaymentUrlExpires))..add(DiagnosticsProperty('kennelPaymentMemberSurcharge', kennelPaymentMemberSurcharge))..add(DiagnosticsProperty('kennelPaymentNonMemberSurcharge', kennelPaymentNonMemberSurcharge))..add(DiagnosticsProperty('kennelPaymentScheme2', kennelPaymentScheme2))..add(DiagnosticsProperty('kennelPaymentUrl2', kennelPaymentUrl2))..add(DiagnosticsProperty('kennelPaymentUrlExpires2', kennelPaymentUrlExpires2))..add(DiagnosticsProperty('kennelPaymentMemberSurcharge2', kennelPaymentMemberSurcharge2))..add(DiagnosticsProperty('kennelPaymentNonMemberSurcharge2', kennelPaymentNonMemberSurcharge2))..add(DiagnosticsProperty('kennelPaymentScheme3', kennelPaymentScheme3))..add(DiagnosticsProperty('kennelPaymentUrl3', kennelPaymentUrl3))..add(DiagnosticsProperty('kennelPaymentUrlExpires3', kennelPaymentUrlExpires3))..add(DiagnosticsProperty('kennelPaymentMemberSurcharge3', kennelPaymentMemberSurcharge3))..add(DiagnosticsProperty('kennelPaymentNonMemberSurcharge3', kennelPaymentNonMemberSurcharge3))..add(DiagnosticsProperty('runCountStartDate', runCountStartDate))..add(DiagnosticsProperty('kennelMismanagementTeam', kennelMismanagementTeam))..add(DiagnosticsProperty('distancePreference', distancePreference))..add(DiagnosticsProperty('updatedAt', updatedAt))..add(DiagnosticsProperty('removed', removed));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _KennelsModel&&(identical(other.kennelId, kennelId) || other.kennelId == kennelId)&&(identical(other.publicKennelId, publicKennelId) || other.publicKennelId == publicKennelId)&&(identical(other.cityId, cityId) || other.cityId == cityId)&&(identical(other.regionId, regionId) || other.regionId == regionId)&&(identical(other.countryId, countryId) || other.countryId == countryId)&&(identical(other.kennelName, kennelName) || other.kennelName == kennelName)&&(identical(other.kennelSearchTags, kennelSearchTags) || other.kennelSearchTags == kennelSearchTags)&&(identical(other.kennelShortName, kennelShortName) || other.kennelShortName == kennelShortName)&&(identical(other.kennelUniqueShortName, kennelUniqueShortName) || other.kennelUniqueShortName == kennelUniqueShortName)&&(identical(other.kennelDescription, kennelDescription) || other.kennelDescription == kennelDescription)&&(identical(other.kennelLogo, kennelLogo) || other.kennelLogo == kennelLogo)&&(identical(other.kennelPinColor, kennelPinColor) || other.kennelPinColor == kennelPinColor)&&(identical(other.disseminateAllowWebLinks, disseminateAllowWebLinks) || other.disseminateAllowWebLinks == disseminateAllowWebLinks)&&(identical(other.kennelCoverPhoto, kennelCoverPhoto) || other.kennelCoverPhoto == kennelCoverPhoto)&&(identical(other.kennelWebsiteUrl, kennelWebsiteUrl) || other.kennelWebsiteUrl == kennelWebsiteUrl)&&(identical(other.defaultEventCurrencyType, defaultEventCurrencyType) || other.defaultEventCurrencyType == defaultEventCurrencyType)&&(identical(other.integrationType, integrationType) || other.integrationType == integrationType)&&(identical(other.kennelInboundIntegrationId, kennelInboundIntegrationId) || other.kennelInboundIntegrationId == kennelInboundIntegrationId)&&(identical(other.kennelEventsUrl, kennelEventsUrl) || other.kennelEventsUrl == kennelEventsUrl)&&(identical(other.kennelStatus, kennelStatus) || other.kennelStatus == kennelStatus)&&(identical(other.canEditRunAttendence, canEditRunAttendence) || other.canEditRunAttendence == canEditRunAttendence)&&(identical(other.allowNegativeCredit, allowNegativeCredit) || other.allowNegativeCredit == allowNegativeCredit)&&(identical(other.allowSelfPayment, allowSelfPayment) || other.allowSelfPayment == allowSelfPayment)&&(identical(other.kennelLatitude, kennelLatitude) || other.kennelLatitude == kennelLatitude)&&(identical(other.kennelLongitude, kennelLongitude) || other.kennelLongitude == kennelLongitude)&&(identical(other.defaultPriceForMembers, defaultPriceForMembers) || other.defaultPriceForMembers == defaultPriceForMembers)&&(identical(other.defaultPriceForNonMembers, defaultPriceForNonMembers) || other.defaultPriceForNonMembers == defaultPriceForNonMembers)&&(identical(other.membershipDurationInMonths, membershipDurationInMonths) || other.membershipDurationInMonths == membershipDurationInMonths)&&(identical(other.defaultRunStartTime, defaultRunStartTime) || other.defaultRunStartTime == defaultRunStartTime)&&(identical(other.currencyCode, currencyCode) || other.currencyCode == currencyCode)&&(identical(other.primaryCultureCode, primaryCultureCode) || other.primaryCultureCode == primaryCultureCode)&&(identical(other.currencySymbol, currencySymbol) || other.currencySymbol == currencySymbol)&&(identical(other.digitsAfterDecimal, digitsAfterDecimal) || other.digitsAfterDecimal == digitsAfterDecimal)&&(identical(other.bankScheme, bankScheme) || other.bankScheme == bankScheme)&&(identical(other.bankAccountNumber, bankAccountNumber) || other.bankAccountNumber == bankAccountNumber)&&(identical(other.bankBic, bankBic) || other.bankBic == bankBic)&&(identical(other.bankBeneficiary, bankBeneficiary) || other.bankBeneficiary == bankBeneficiary)&&(identical(other.kennelPaymentScheme, kennelPaymentScheme) || other.kennelPaymentScheme == kennelPaymentScheme)&&(identical(other.kennelPaymentUrl, kennelPaymentUrl) || other.kennelPaymentUrl == kennelPaymentUrl)&&(identical(other.kennelPaymentUrlExpires, kennelPaymentUrlExpires) || other.kennelPaymentUrlExpires == kennelPaymentUrlExpires)&&(identical(other.kennelPaymentMemberSurcharge, kennelPaymentMemberSurcharge) || other.kennelPaymentMemberSurcharge == kennelPaymentMemberSurcharge)&&(identical(other.kennelPaymentNonMemberSurcharge, kennelPaymentNonMemberSurcharge) || other.kennelPaymentNonMemberSurcharge == kennelPaymentNonMemberSurcharge)&&(identical(other.kennelPaymentScheme2, kennelPaymentScheme2) || other.kennelPaymentScheme2 == kennelPaymentScheme2)&&(identical(other.kennelPaymentUrl2, kennelPaymentUrl2) || other.kennelPaymentUrl2 == kennelPaymentUrl2)&&(identical(other.kennelPaymentUrlExpires2, kennelPaymentUrlExpires2) || other.kennelPaymentUrlExpires2 == kennelPaymentUrlExpires2)&&(identical(other.kennelPaymentMemberSurcharge2, kennelPaymentMemberSurcharge2) || other.kennelPaymentMemberSurcharge2 == kennelPaymentMemberSurcharge2)&&(identical(other.kennelPaymentNonMemberSurcharge2, kennelPaymentNonMemberSurcharge2) || other.kennelPaymentNonMemberSurcharge2 == kennelPaymentNonMemberSurcharge2)&&(identical(other.kennelPaymentScheme3, kennelPaymentScheme3) || other.kennelPaymentScheme3 == kennelPaymentScheme3)&&(identical(other.kennelPaymentUrl3, kennelPaymentUrl3) || other.kennelPaymentUrl3 == kennelPaymentUrl3)&&(identical(other.kennelPaymentUrlExpires3, kennelPaymentUrlExpires3) || other.kennelPaymentUrlExpires3 == kennelPaymentUrlExpires3)&&(identical(other.kennelPaymentMemberSurcharge3, kennelPaymentMemberSurcharge3) || other.kennelPaymentMemberSurcharge3 == kennelPaymentMemberSurcharge3)&&(identical(other.kennelPaymentNonMemberSurcharge3, kennelPaymentNonMemberSurcharge3) || other.kennelPaymentNonMemberSurcharge3 == kennelPaymentNonMemberSurcharge3)&&(identical(other.runCountStartDate, runCountStartDate) || other.runCountStartDate == runCountStartDate)&&(identical(other.kennelMismanagementTeam, kennelMismanagementTeam) || other.kennelMismanagementTeam == kennelMismanagementTeam)&&(identical(other.distancePreference, distancePreference) || other.distancePreference == distancePreference)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.removed, removed) || other.removed == removed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,kennelId,publicKennelId,cityId,regionId,countryId,kennelName,kennelSearchTags,kennelShortName,kennelUniqueShortName,kennelDescription,kennelLogo,kennelPinColor,disseminateAllowWebLinks,kennelCoverPhoto,kennelWebsiteUrl,defaultEventCurrencyType,integrationType,kennelInboundIntegrationId,kennelEventsUrl,kennelStatus,canEditRunAttendence,allowNegativeCredit,allowSelfPayment,kennelLatitude,kennelLongitude,defaultPriceForMembers,defaultPriceForNonMembers,membershipDurationInMonths,defaultRunStartTime,currencyCode,primaryCultureCode,currencySymbol,digitsAfterDecimal,bankScheme,bankAccountNumber,bankBic,bankBeneficiary,kennelPaymentScheme,kennelPaymentUrl,kennelPaymentUrlExpires,kennelPaymentMemberSurcharge,kennelPaymentNonMemberSurcharge,kennelPaymentScheme2,kennelPaymentUrl2,kennelPaymentUrlExpires2,kennelPaymentMemberSurcharge2,kennelPaymentNonMemberSurcharge2,kennelPaymentScheme3,kennelPaymentUrl3,kennelPaymentUrlExpires3,kennelPaymentMemberSurcharge3,kennelPaymentNonMemberSurcharge3,runCountStartDate,kennelMismanagementTeam,distancePreference,updatedAt,removed]);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'KennelsModel(kennelId: $kennelId, publicKennelId: $publicKennelId, cityId: $cityId, regionId: $regionId, countryId: $countryId, kennelName: $kennelName, kennelSearchTags: $kennelSearchTags, kennelShortName: $kennelShortName, kennelUniqueShortName: $kennelUniqueShortName, kennelDescription: $kennelDescription, kennelLogo: $kennelLogo, kennelPinColor: $kennelPinColor, disseminateAllowWebLinks: $disseminateAllowWebLinks, kennelCoverPhoto: $kennelCoverPhoto, kennelWebsiteUrl: $kennelWebsiteUrl, defaultEventCurrencyType: $defaultEventCurrencyType, integrationType: $integrationType, kennelInboundIntegrationId: $kennelInboundIntegrationId, kennelEventsUrl: $kennelEventsUrl, kennelStatus: $kennelStatus, canEditRunAttendence: $canEditRunAttendence, allowNegativeCredit: $allowNegativeCredit, allowSelfPayment: $allowSelfPayment, kennelLatitude: $kennelLatitude, kennelLongitude: $kennelLongitude, defaultPriceForMembers: $defaultPriceForMembers, defaultPriceForNonMembers: $defaultPriceForNonMembers, membershipDurationInMonths: $membershipDurationInMonths, defaultRunStartTime: $defaultRunStartTime, currencyCode: $currencyCode, primaryCultureCode: $primaryCultureCode, currencySymbol: $currencySymbol, digitsAfterDecimal: $digitsAfterDecimal, bankScheme: $bankScheme, bankAccountNumber: $bankAccountNumber, bankBic: $bankBic, bankBeneficiary: $bankBeneficiary, kennelPaymentScheme: $kennelPaymentScheme, kennelPaymentUrl: $kennelPaymentUrl, kennelPaymentUrlExpires: $kennelPaymentUrlExpires, kennelPaymentMemberSurcharge: $kennelPaymentMemberSurcharge, kennelPaymentNonMemberSurcharge: $kennelPaymentNonMemberSurcharge, kennelPaymentScheme2: $kennelPaymentScheme2, kennelPaymentUrl2: $kennelPaymentUrl2, kennelPaymentUrlExpires2: $kennelPaymentUrlExpires2, kennelPaymentMemberSurcharge2: $kennelPaymentMemberSurcharge2, kennelPaymentNonMemberSurcharge2: $kennelPaymentNonMemberSurcharge2, kennelPaymentScheme3: $kennelPaymentScheme3, kennelPaymentUrl3: $kennelPaymentUrl3, kennelPaymentUrlExpires3: $kennelPaymentUrlExpires3, kennelPaymentMemberSurcharge3: $kennelPaymentMemberSurcharge3, kennelPaymentNonMemberSurcharge3: $kennelPaymentNonMemberSurcharge3, runCountStartDate: $runCountStartDate, kennelMismanagementTeam: $kennelMismanagementTeam, distancePreference: $distancePreference, updatedAt: $updatedAt, removed: $removed)';
}


}

/// @nodoc
abstract mixin class _$KennelsModelCopyWith<$Res> implements $KennelsModelCopyWith<$Res> {
  factory _$KennelsModelCopyWith(_KennelsModel value, $Res Function(_KennelsModel) _then) = __$KennelsModelCopyWithImpl;
@override @useResult
$Res call({
 String kennelId, String publicKennelId, String cityId, String regionId, String countryId, String kennelName, String? kennelSearchTags, String kennelShortName, String kennelUniqueShortName, String? kennelDescription, String kennelLogo, int kennelPinColor, int disseminateAllowWebLinks, String? kennelCoverPhoto, String? kennelWebsiteUrl, String? defaultEventCurrencyType, String? integrationType, int? kennelInboundIntegrationId, String? kennelEventsUrl, int kennelStatus, int canEditRunAttendence, int allowNegativeCredit, int allowSelfPayment, double? kennelLatitude, double? kennelLongitude, double defaultPriceForMembers, double defaultPriceForNonMembers, int membershipDurationInMonths, DateTime defaultRunStartTime, String? currencyCode, String? primaryCultureCode, String? currencySymbol, int? digitsAfterDecimal, String? bankScheme, String? bankAccountNumber, String? bankBic, String? bankBeneficiary, String? kennelPaymentScheme, String? kennelPaymentUrl, DateTime? kennelPaymentUrlExpires, double? kennelPaymentMemberSurcharge, double? kennelPaymentNonMemberSurcharge, String? kennelPaymentScheme2, String? kennelPaymentUrl2, DateTime? kennelPaymentUrlExpires2, double? kennelPaymentMemberSurcharge2, double? kennelPaymentNonMemberSurcharge2, String? kennelPaymentScheme3, String? kennelPaymentUrl3, DateTime? kennelPaymentUrlExpires3, double? kennelPaymentMemberSurcharge3, double? kennelPaymentNonMemberSurcharge3, DateTime? runCountStartDate, String? kennelMismanagementTeam, int? distancePreference, DateTime? updatedAt, int? removed
});




}
/// @nodoc
class __$KennelsModelCopyWithImpl<$Res>
    implements _$KennelsModelCopyWith<$Res> {
  __$KennelsModelCopyWithImpl(this._self, this._then);

  final _KennelsModel _self;
  final $Res Function(_KennelsModel) _then;

/// Create a copy of KennelsModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kennelId = null,Object? publicKennelId = null,Object? cityId = null,Object? regionId = null,Object? countryId = null,Object? kennelName = null,Object? kennelSearchTags = freezed,Object? kennelShortName = null,Object? kennelUniqueShortName = null,Object? kennelDescription = freezed,Object? kennelLogo = null,Object? kennelPinColor = null,Object? disseminateAllowWebLinks = null,Object? kennelCoverPhoto = freezed,Object? kennelWebsiteUrl = freezed,Object? defaultEventCurrencyType = freezed,Object? integrationType = freezed,Object? kennelInboundIntegrationId = freezed,Object? kennelEventsUrl = freezed,Object? kennelStatus = null,Object? canEditRunAttendence = null,Object? allowNegativeCredit = null,Object? allowSelfPayment = null,Object? kennelLatitude = freezed,Object? kennelLongitude = freezed,Object? defaultPriceForMembers = null,Object? defaultPriceForNonMembers = null,Object? membershipDurationInMonths = null,Object? defaultRunStartTime = null,Object? currencyCode = freezed,Object? primaryCultureCode = freezed,Object? currencySymbol = freezed,Object? digitsAfterDecimal = freezed,Object? bankScheme = freezed,Object? bankAccountNumber = freezed,Object? bankBic = freezed,Object? bankBeneficiary = freezed,Object? kennelPaymentScheme = freezed,Object? kennelPaymentUrl = freezed,Object? kennelPaymentUrlExpires = freezed,Object? kennelPaymentMemberSurcharge = freezed,Object? kennelPaymentNonMemberSurcharge = freezed,Object? kennelPaymentScheme2 = freezed,Object? kennelPaymentUrl2 = freezed,Object? kennelPaymentUrlExpires2 = freezed,Object? kennelPaymentMemberSurcharge2 = freezed,Object? kennelPaymentNonMemberSurcharge2 = freezed,Object? kennelPaymentScheme3 = freezed,Object? kennelPaymentUrl3 = freezed,Object? kennelPaymentUrlExpires3 = freezed,Object? kennelPaymentMemberSurcharge3 = freezed,Object? kennelPaymentNonMemberSurcharge3 = freezed,Object? runCountStartDate = freezed,Object? kennelMismanagementTeam = freezed,Object? distancePreference = freezed,Object? updatedAt = freezed,Object? removed = freezed,}) {
  return _then(_KennelsModel(
kennelId: null == kennelId ? _self.kennelId : kennelId // ignore: cast_nullable_to_non_nullable
as String,publicKennelId: null == publicKennelId ? _self.publicKennelId : publicKennelId // ignore: cast_nullable_to_non_nullable
as String,cityId: null == cityId ? _self.cityId : cityId // ignore: cast_nullable_to_non_nullable
as String,regionId: null == regionId ? _self.regionId : regionId // ignore: cast_nullable_to_non_nullable
as String,countryId: null == countryId ? _self.countryId : countryId // ignore: cast_nullable_to_non_nullable
as String,kennelName: null == kennelName ? _self.kennelName : kennelName // ignore: cast_nullable_to_non_nullable
as String,kennelSearchTags: freezed == kennelSearchTags ? _self.kennelSearchTags : kennelSearchTags // ignore: cast_nullable_to_non_nullable
as String?,kennelShortName: null == kennelShortName ? _self.kennelShortName : kennelShortName // ignore: cast_nullable_to_non_nullable
as String,kennelUniqueShortName: null == kennelUniqueShortName ? _self.kennelUniqueShortName : kennelUniqueShortName // ignore: cast_nullable_to_non_nullable
as String,kennelDescription: freezed == kennelDescription ? _self.kennelDescription : kennelDescription // ignore: cast_nullable_to_non_nullable
as String?,kennelLogo: null == kennelLogo ? _self.kennelLogo : kennelLogo // ignore: cast_nullable_to_non_nullable
as String,kennelPinColor: null == kennelPinColor ? _self.kennelPinColor : kennelPinColor // ignore: cast_nullable_to_non_nullable
as int,disseminateAllowWebLinks: null == disseminateAllowWebLinks ? _self.disseminateAllowWebLinks : disseminateAllowWebLinks // ignore: cast_nullable_to_non_nullable
as int,kennelCoverPhoto: freezed == kennelCoverPhoto ? _self.kennelCoverPhoto : kennelCoverPhoto // ignore: cast_nullable_to_non_nullable
as String?,kennelWebsiteUrl: freezed == kennelWebsiteUrl ? _self.kennelWebsiteUrl : kennelWebsiteUrl // ignore: cast_nullable_to_non_nullable
as String?,defaultEventCurrencyType: freezed == defaultEventCurrencyType ? _self.defaultEventCurrencyType : defaultEventCurrencyType // ignore: cast_nullable_to_non_nullable
as String?,integrationType: freezed == integrationType ? _self.integrationType : integrationType // ignore: cast_nullable_to_non_nullable
as String?,kennelInboundIntegrationId: freezed == kennelInboundIntegrationId ? _self.kennelInboundIntegrationId : kennelInboundIntegrationId // ignore: cast_nullable_to_non_nullable
as int?,kennelEventsUrl: freezed == kennelEventsUrl ? _self.kennelEventsUrl : kennelEventsUrl // ignore: cast_nullable_to_non_nullable
as String?,kennelStatus: null == kennelStatus ? _self.kennelStatus : kennelStatus // ignore: cast_nullable_to_non_nullable
as int,canEditRunAttendence: null == canEditRunAttendence ? _self.canEditRunAttendence : canEditRunAttendence // ignore: cast_nullable_to_non_nullable
as int,allowNegativeCredit: null == allowNegativeCredit ? _self.allowNegativeCredit : allowNegativeCredit // ignore: cast_nullable_to_non_nullable
as int,allowSelfPayment: null == allowSelfPayment ? _self.allowSelfPayment : allowSelfPayment // ignore: cast_nullable_to_non_nullable
as int,kennelLatitude: freezed == kennelLatitude ? _self.kennelLatitude : kennelLatitude // ignore: cast_nullable_to_non_nullable
as double?,kennelLongitude: freezed == kennelLongitude ? _self.kennelLongitude : kennelLongitude // ignore: cast_nullable_to_non_nullable
as double?,defaultPriceForMembers: null == defaultPriceForMembers ? _self.defaultPriceForMembers : defaultPriceForMembers // ignore: cast_nullable_to_non_nullable
as double,defaultPriceForNonMembers: null == defaultPriceForNonMembers ? _self.defaultPriceForNonMembers : defaultPriceForNonMembers // ignore: cast_nullable_to_non_nullable
as double,membershipDurationInMonths: null == membershipDurationInMonths ? _self.membershipDurationInMonths : membershipDurationInMonths // ignore: cast_nullable_to_non_nullable
as int,defaultRunStartTime: null == defaultRunStartTime ? _self.defaultRunStartTime : defaultRunStartTime // ignore: cast_nullable_to_non_nullable
as DateTime,currencyCode: freezed == currencyCode ? _self.currencyCode : currencyCode // ignore: cast_nullable_to_non_nullable
as String?,primaryCultureCode: freezed == primaryCultureCode ? _self.primaryCultureCode : primaryCultureCode // ignore: cast_nullable_to_non_nullable
as String?,currencySymbol: freezed == currencySymbol ? _self.currencySymbol : currencySymbol // ignore: cast_nullable_to_non_nullable
as String?,digitsAfterDecimal: freezed == digitsAfterDecimal ? _self.digitsAfterDecimal : digitsAfterDecimal // ignore: cast_nullable_to_non_nullable
as int?,bankScheme: freezed == bankScheme ? _self.bankScheme : bankScheme // ignore: cast_nullable_to_non_nullable
as String?,bankAccountNumber: freezed == bankAccountNumber ? _self.bankAccountNumber : bankAccountNumber // ignore: cast_nullable_to_non_nullable
as String?,bankBic: freezed == bankBic ? _self.bankBic : bankBic // ignore: cast_nullable_to_non_nullable
as String?,bankBeneficiary: freezed == bankBeneficiary ? _self.bankBeneficiary : bankBeneficiary // ignore: cast_nullable_to_non_nullable
as String?,kennelPaymentScheme: freezed == kennelPaymentScheme ? _self.kennelPaymentScheme : kennelPaymentScheme // ignore: cast_nullable_to_non_nullable
as String?,kennelPaymentUrl: freezed == kennelPaymentUrl ? _self.kennelPaymentUrl : kennelPaymentUrl // ignore: cast_nullable_to_non_nullable
as String?,kennelPaymentUrlExpires: freezed == kennelPaymentUrlExpires ? _self.kennelPaymentUrlExpires : kennelPaymentUrlExpires // ignore: cast_nullable_to_non_nullable
as DateTime?,kennelPaymentMemberSurcharge: freezed == kennelPaymentMemberSurcharge ? _self.kennelPaymentMemberSurcharge : kennelPaymentMemberSurcharge // ignore: cast_nullable_to_non_nullable
as double?,kennelPaymentNonMemberSurcharge: freezed == kennelPaymentNonMemberSurcharge ? _self.kennelPaymentNonMemberSurcharge : kennelPaymentNonMemberSurcharge // ignore: cast_nullable_to_non_nullable
as double?,kennelPaymentScheme2: freezed == kennelPaymentScheme2 ? _self.kennelPaymentScheme2 : kennelPaymentScheme2 // ignore: cast_nullable_to_non_nullable
as String?,kennelPaymentUrl2: freezed == kennelPaymentUrl2 ? _self.kennelPaymentUrl2 : kennelPaymentUrl2 // ignore: cast_nullable_to_non_nullable
as String?,kennelPaymentUrlExpires2: freezed == kennelPaymentUrlExpires2 ? _self.kennelPaymentUrlExpires2 : kennelPaymentUrlExpires2 // ignore: cast_nullable_to_non_nullable
as DateTime?,kennelPaymentMemberSurcharge2: freezed == kennelPaymentMemberSurcharge2 ? _self.kennelPaymentMemberSurcharge2 : kennelPaymentMemberSurcharge2 // ignore: cast_nullable_to_non_nullable
as double?,kennelPaymentNonMemberSurcharge2: freezed == kennelPaymentNonMemberSurcharge2 ? _self.kennelPaymentNonMemberSurcharge2 : kennelPaymentNonMemberSurcharge2 // ignore: cast_nullable_to_non_nullable
as double?,kennelPaymentScheme3: freezed == kennelPaymentScheme3 ? _self.kennelPaymentScheme3 : kennelPaymentScheme3 // ignore: cast_nullable_to_non_nullable
as String?,kennelPaymentUrl3: freezed == kennelPaymentUrl3 ? _self.kennelPaymentUrl3 : kennelPaymentUrl3 // ignore: cast_nullable_to_non_nullable
as String?,kennelPaymentUrlExpires3: freezed == kennelPaymentUrlExpires3 ? _self.kennelPaymentUrlExpires3 : kennelPaymentUrlExpires3 // ignore: cast_nullable_to_non_nullable
as DateTime?,kennelPaymentMemberSurcharge3: freezed == kennelPaymentMemberSurcharge3 ? _self.kennelPaymentMemberSurcharge3 : kennelPaymentMemberSurcharge3 // ignore: cast_nullable_to_non_nullable
as double?,kennelPaymentNonMemberSurcharge3: freezed == kennelPaymentNonMemberSurcharge3 ? _self.kennelPaymentNonMemberSurcharge3 : kennelPaymentNonMemberSurcharge3 // ignore: cast_nullable_to_non_nullable
as double?,runCountStartDate: freezed == runCountStartDate ? _self.runCountStartDate : runCountStartDate // ignore: cast_nullable_to_non_nullable
as DateTime?,kennelMismanagementTeam: freezed == kennelMismanagementTeam ? _self.kennelMismanagementTeam : kennelMismanagementTeam // ignore: cast_nullable_to_non_nullable
as String?,distancePreference: freezed == distancePreference ? _self.distancePreference : distancePreference // ignore: cast_nullable_to_non_nullable
as int?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,removed: freezed == removed ? _self.removed : removed // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
