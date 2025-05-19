// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'approve_login_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ApproveLoginModel implements DiagnosticableTreeMixin {

 String? get apiVersion; int? get approvalCode; String? get loginMessage; String? get loginMessageTitle; int? get serverStatusCode; DateTime? get messageEndDate; int? get messageDisplayType; String? get iosDownloadLink; String? get androidDownloadLink; String? get imageRootUrl; int? get isBetaTester; String? get email; String? get homeKennelId; DateTime? get thirdPartyForceTokenRefresh; String? get splashSequenceRootName;
/// Create a copy of ApproveLoginModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ApproveLoginModelCopyWith<ApproveLoginModel> get copyWith => _$ApproveLoginModelCopyWithImpl<ApproveLoginModel>(this as ApproveLoginModel, _$identity);

  /// Serializes this ApproveLoginModel to a JSON map.
  Map<String, dynamic> toJson();

@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'ApproveLoginModel'))
    ..add(DiagnosticsProperty('apiVersion', apiVersion))..add(DiagnosticsProperty('approvalCode', approvalCode))..add(DiagnosticsProperty('loginMessage', loginMessage))..add(DiagnosticsProperty('loginMessageTitle', loginMessageTitle))..add(DiagnosticsProperty('serverStatusCode', serverStatusCode))..add(DiagnosticsProperty('messageEndDate', messageEndDate))..add(DiagnosticsProperty('messageDisplayType', messageDisplayType))..add(DiagnosticsProperty('iosDownloadLink', iosDownloadLink))..add(DiagnosticsProperty('androidDownloadLink', androidDownloadLink))..add(DiagnosticsProperty('imageRootUrl', imageRootUrl))..add(DiagnosticsProperty('isBetaTester', isBetaTester))..add(DiagnosticsProperty('email', email))..add(DiagnosticsProperty('homeKennelId', homeKennelId))..add(DiagnosticsProperty('thirdPartyForceTokenRefresh', thirdPartyForceTokenRefresh))..add(DiagnosticsProperty('splashSequenceRootName', splashSequenceRootName));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApproveLoginModel&&(identical(other.apiVersion, apiVersion) || other.apiVersion == apiVersion)&&(identical(other.approvalCode, approvalCode) || other.approvalCode == approvalCode)&&(identical(other.loginMessage, loginMessage) || other.loginMessage == loginMessage)&&(identical(other.loginMessageTitle, loginMessageTitle) || other.loginMessageTitle == loginMessageTitle)&&(identical(other.serverStatusCode, serverStatusCode) || other.serverStatusCode == serverStatusCode)&&(identical(other.messageEndDate, messageEndDate) || other.messageEndDate == messageEndDate)&&(identical(other.messageDisplayType, messageDisplayType) || other.messageDisplayType == messageDisplayType)&&(identical(other.iosDownloadLink, iosDownloadLink) || other.iosDownloadLink == iosDownloadLink)&&(identical(other.androidDownloadLink, androidDownloadLink) || other.androidDownloadLink == androidDownloadLink)&&(identical(other.imageRootUrl, imageRootUrl) || other.imageRootUrl == imageRootUrl)&&(identical(other.isBetaTester, isBetaTester) || other.isBetaTester == isBetaTester)&&(identical(other.email, email) || other.email == email)&&(identical(other.homeKennelId, homeKennelId) || other.homeKennelId == homeKennelId)&&(identical(other.thirdPartyForceTokenRefresh, thirdPartyForceTokenRefresh) || other.thirdPartyForceTokenRefresh == thirdPartyForceTokenRefresh)&&(identical(other.splashSequenceRootName, splashSequenceRootName) || other.splashSequenceRootName == splashSequenceRootName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,apiVersion,approvalCode,loginMessage,loginMessageTitle,serverStatusCode,messageEndDate,messageDisplayType,iosDownloadLink,androidDownloadLink,imageRootUrl,isBetaTester,email,homeKennelId,thirdPartyForceTokenRefresh,splashSequenceRootName);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'ApproveLoginModel(apiVersion: $apiVersion, approvalCode: $approvalCode, loginMessage: $loginMessage, loginMessageTitle: $loginMessageTitle, serverStatusCode: $serverStatusCode, messageEndDate: $messageEndDate, messageDisplayType: $messageDisplayType, iosDownloadLink: $iosDownloadLink, androidDownloadLink: $androidDownloadLink, imageRootUrl: $imageRootUrl, isBetaTester: $isBetaTester, email: $email, homeKennelId: $homeKennelId, thirdPartyForceTokenRefresh: $thirdPartyForceTokenRefresh, splashSequenceRootName: $splashSequenceRootName)';
}


}

/// @nodoc
abstract mixin class $ApproveLoginModelCopyWith<$Res>  {
  factory $ApproveLoginModelCopyWith(ApproveLoginModel value, $Res Function(ApproveLoginModel) _then) = _$ApproveLoginModelCopyWithImpl;
@useResult
$Res call({
 String? apiVersion, int? approvalCode, String? loginMessage, String? loginMessageTitle, int? serverStatusCode, DateTime? messageEndDate, int? messageDisplayType, String? iosDownloadLink, String? androidDownloadLink, String? imageRootUrl, int? isBetaTester, String? email, String? homeKennelId, DateTime? thirdPartyForceTokenRefresh, String? splashSequenceRootName
});




}
/// @nodoc
class _$ApproveLoginModelCopyWithImpl<$Res>
    implements $ApproveLoginModelCopyWith<$Res> {
  _$ApproveLoginModelCopyWithImpl(this._self, this._then);

  final ApproveLoginModel _self;
  final $Res Function(ApproveLoginModel) _then;

/// Create a copy of ApproveLoginModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? apiVersion = freezed,Object? approvalCode = freezed,Object? loginMessage = freezed,Object? loginMessageTitle = freezed,Object? serverStatusCode = freezed,Object? messageEndDate = freezed,Object? messageDisplayType = freezed,Object? iosDownloadLink = freezed,Object? androidDownloadLink = freezed,Object? imageRootUrl = freezed,Object? isBetaTester = freezed,Object? email = freezed,Object? homeKennelId = freezed,Object? thirdPartyForceTokenRefresh = freezed,Object? splashSequenceRootName = freezed,}) {
  return _then(_self.copyWith(
apiVersion: freezed == apiVersion ? _self.apiVersion : apiVersion // ignore: cast_nullable_to_non_nullable
as String?,approvalCode: freezed == approvalCode ? _self.approvalCode : approvalCode // ignore: cast_nullable_to_non_nullable
as int?,loginMessage: freezed == loginMessage ? _self.loginMessage : loginMessage // ignore: cast_nullable_to_non_nullable
as String?,loginMessageTitle: freezed == loginMessageTitle ? _self.loginMessageTitle : loginMessageTitle // ignore: cast_nullable_to_non_nullable
as String?,serverStatusCode: freezed == serverStatusCode ? _self.serverStatusCode : serverStatusCode // ignore: cast_nullable_to_non_nullable
as int?,messageEndDate: freezed == messageEndDate ? _self.messageEndDate : messageEndDate // ignore: cast_nullable_to_non_nullable
as DateTime?,messageDisplayType: freezed == messageDisplayType ? _self.messageDisplayType : messageDisplayType // ignore: cast_nullable_to_non_nullable
as int?,iosDownloadLink: freezed == iosDownloadLink ? _self.iosDownloadLink : iosDownloadLink // ignore: cast_nullable_to_non_nullable
as String?,androidDownloadLink: freezed == androidDownloadLink ? _self.androidDownloadLink : androidDownloadLink // ignore: cast_nullable_to_non_nullable
as String?,imageRootUrl: freezed == imageRootUrl ? _self.imageRootUrl : imageRootUrl // ignore: cast_nullable_to_non_nullable
as String?,isBetaTester: freezed == isBetaTester ? _self.isBetaTester : isBetaTester // ignore: cast_nullable_to_non_nullable
as int?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,homeKennelId: freezed == homeKennelId ? _self.homeKennelId : homeKennelId // ignore: cast_nullable_to_non_nullable
as String?,thirdPartyForceTokenRefresh: freezed == thirdPartyForceTokenRefresh ? _self.thirdPartyForceTokenRefresh : thirdPartyForceTokenRefresh // ignore: cast_nullable_to_non_nullable
as DateTime?,splashSequenceRootName: freezed == splashSequenceRootName ? _self.splashSequenceRootName : splashSequenceRootName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _ApproveLoginModel with DiagnosticableTreeMixin implements ApproveLoginModel {
   _ApproveLoginModel({this.apiVersion, this.approvalCode, this.loginMessage, this.loginMessageTitle, this.serverStatusCode, this.messageEndDate, this.messageDisplayType, this.iosDownloadLink, this.androidDownloadLink, this.imageRootUrl, this.isBetaTester, this.email, this.homeKennelId, this.thirdPartyForceTokenRefresh, this.splashSequenceRootName});
  factory _ApproveLoginModel.fromJson(Map<String, dynamic> json) => _$ApproveLoginModelFromJson(json);

@override final  String? apiVersion;
@override final  int? approvalCode;
@override final  String? loginMessage;
@override final  String? loginMessageTitle;
@override final  int? serverStatusCode;
@override final  DateTime? messageEndDate;
@override final  int? messageDisplayType;
@override final  String? iosDownloadLink;
@override final  String? androidDownloadLink;
@override final  String? imageRootUrl;
@override final  int? isBetaTester;
@override final  String? email;
@override final  String? homeKennelId;
@override final  DateTime? thirdPartyForceTokenRefresh;
@override final  String? splashSequenceRootName;

/// Create a copy of ApproveLoginModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ApproveLoginModelCopyWith<_ApproveLoginModel> get copyWith => __$ApproveLoginModelCopyWithImpl<_ApproveLoginModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ApproveLoginModelToJson(this, );
}
@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'ApproveLoginModel'))
    ..add(DiagnosticsProperty('apiVersion', apiVersion))..add(DiagnosticsProperty('approvalCode', approvalCode))..add(DiagnosticsProperty('loginMessage', loginMessage))..add(DiagnosticsProperty('loginMessageTitle', loginMessageTitle))..add(DiagnosticsProperty('serverStatusCode', serverStatusCode))..add(DiagnosticsProperty('messageEndDate', messageEndDate))..add(DiagnosticsProperty('messageDisplayType', messageDisplayType))..add(DiagnosticsProperty('iosDownloadLink', iosDownloadLink))..add(DiagnosticsProperty('androidDownloadLink', androidDownloadLink))..add(DiagnosticsProperty('imageRootUrl', imageRootUrl))..add(DiagnosticsProperty('isBetaTester', isBetaTester))..add(DiagnosticsProperty('email', email))..add(DiagnosticsProperty('homeKennelId', homeKennelId))..add(DiagnosticsProperty('thirdPartyForceTokenRefresh', thirdPartyForceTokenRefresh))..add(DiagnosticsProperty('splashSequenceRootName', splashSequenceRootName));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ApproveLoginModel&&(identical(other.apiVersion, apiVersion) || other.apiVersion == apiVersion)&&(identical(other.approvalCode, approvalCode) || other.approvalCode == approvalCode)&&(identical(other.loginMessage, loginMessage) || other.loginMessage == loginMessage)&&(identical(other.loginMessageTitle, loginMessageTitle) || other.loginMessageTitle == loginMessageTitle)&&(identical(other.serverStatusCode, serverStatusCode) || other.serverStatusCode == serverStatusCode)&&(identical(other.messageEndDate, messageEndDate) || other.messageEndDate == messageEndDate)&&(identical(other.messageDisplayType, messageDisplayType) || other.messageDisplayType == messageDisplayType)&&(identical(other.iosDownloadLink, iosDownloadLink) || other.iosDownloadLink == iosDownloadLink)&&(identical(other.androidDownloadLink, androidDownloadLink) || other.androidDownloadLink == androidDownloadLink)&&(identical(other.imageRootUrl, imageRootUrl) || other.imageRootUrl == imageRootUrl)&&(identical(other.isBetaTester, isBetaTester) || other.isBetaTester == isBetaTester)&&(identical(other.email, email) || other.email == email)&&(identical(other.homeKennelId, homeKennelId) || other.homeKennelId == homeKennelId)&&(identical(other.thirdPartyForceTokenRefresh, thirdPartyForceTokenRefresh) || other.thirdPartyForceTokenRefresh == thirdPartyForceTokenRefresh)&&(identical(other.splashSequenceRootName, splashSequenceRootName) || other.splashSequenceRootName == splashSequenceRootName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,apiVersion,approvalCode,loginMessage,loginMessageTitle,serverStatusCode,messageEndDate,messageDisplayType,iosDownloadLink,androidDownloadLink,imageRootUrl,isBetaTester,email,homeKennelId,thirdPartyForceTokenRefresh,splashSequenceRootName);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'ApproveLoginModel(apiVersion: $apiVersion, approvalCode: $approvalCode, loginMessage: $loginMessage, loginMessageTitle: $loginMessageTitle, serverStatusCode: $serverStatusCode, messageEndDate: $messageEndDate, messageDisplayType: $messageDisplayType, iosDownloadLink: $iosDownloadLink, androidDownloadLink: $androidDownloadLink, imageRootUrl: $imageRootUrl, isBetaTester: $isBetaTester, email: $email, homeKennelId: $homeKennelId, thirdPartyForceTokenRefresh: $thirdPartyForceTokenRefresh, splashSequenceRootName: $splashSequenceRootName)';
}


}

/// @nodoc
abstract mixin class _$ApproveLoginModelCopyWith<$Res> implements $ApproveLoginModelCopyWith<$Res> {
  factory _$ApproveLoginModelCopyWith(_ApproveLoginModel value, $Res Function(_ApproveLoginModel) _then) = __$ApproveLoginModelCopyWithImpl;
@override @useResult
$Res call({
 String? apiVersion, int? approvalCode, String? loginMessage, String? loginMessageTitle, int? serverStatusCode, DateTime? messageEndDate, int? messageDisplayType, String? iosDownloadLink, String? androidDownloadLink, String? imageRootUrl, int? isBetaTester, String? email, String? homeKennelId, DateTime? thirdPartyForceTokenRefresh, String? splashSequenceRootName
});




}
/// @nodoc
class __$ApproveLoginModelCopyWithImpl<$Res>
    implements _$ApproveLoginModelCopyWith<$Res> {
  __$ApproveLoginModelCopyWithImpl(this._self, this._then);

  final _ApproveLoginModel _self;
  final $Res Function(_ApproveLoginModel) _then;

/// Create a copy of ApproveLoginModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? apiVersion = freezed,Object? approvalCode = freezed,Object? loginMessage = freezed,Object? loginMessageTitle = freezed,Object? serverStatusCode = freezed,Object? messageEndDate = freezed,Object? messageDisplayType = freezed,Object? iosDownloadLink = freezed,Object? androidDownloadLink = freezed,Object? imageRootUrl = freezed,Object? isBetaTester = freezed,Object? email = freezed,Object? homeKennelId = freezed,Object? thirdPartyForceTokenRefresh = freezed,Object? splashSequenceRootName = freezed,}) {
  return _then(_ApproveLoginModel(
apiVersion: freezed == apiVersion ? _self.apiVersion : apiVersion // ignore: cast_nullable_to_non_nullable
as String?,approvalCode: freezed == approvalCode ? _self.approvalCode : approvalCode // ignore: cast_nullable_to_non_nullable
as int?,loginMessage: freezed == loginMessage ? _self.loginMessage : loginMessage // ignore: cast_nullable_to_non_nullable
as String?,loginMessageTitle: freezed == loginMessageTitle ? _self.loginMessageTitle : loginMessageTitle // ignore: cast_nullable_to_non_nullable
as String?,serverStatusCode: freezed == serverStatusCode ? _self.serverStatusCode : serverStatusCode // ignore: cast_nullable_to_non_nullable
as int?,messageEndDate: freezed == messageEndDate ? _self.messageEndDate : messageEndDate // ignore: cast_nullable_to_non_nullable
as DateTime?,messageDisplayType: freezed == messageDisplayType ? _self.messageDisplayType : messageDisplayType // ignore: cast_nullable_to_non_nullable
as int?,iosDownloadLink: freezed == iosDownloadLink ? _self.iosDownloadLink : iosDownloadLink // ignore: cast_nullable_to_non_nullable
as String?,androidDownloadLink: freezed == androidDownloadLink ? _self.androidDownloadLink : androidDownloadLink // ignore: cast_nullable_to_non_nullable
as String?,imageRootUrl: freezed == imageRootUrl ? _self.imageRootUrl : imageRootUrl // ignore: cast_nullable_to_non_nullable
as String?,isBetaTester: freezed == isBetaTester ? _self.isBetaTester : isBetaTester // ignore: cast_nullable_to_non_nullable
as int?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,homeKennelId: freezed == homeKennelId ? _self.homeKennelId : homeKennelId // ignore: cast_nullable_to_non_nullable
as String?,thirdPartyForceTokenRefresh: freezed == thirdPartyForceTokenRefresh ? _self.thirdPartyForceTokenRefresh : thirdPartyForceTokenRefresh // ignore: cast_nullable_to_non_nullable
as DateTime?,splashSequenceRootName: freezed == splashSequenceRootName ? _self.splashSequenceRootName : splashSequenceRootName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
