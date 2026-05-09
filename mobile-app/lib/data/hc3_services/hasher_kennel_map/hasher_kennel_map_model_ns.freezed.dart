// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'hasher_kennel_map_model_ns.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HasherKennelMapModel implements DiagnosticableTreeMixin {

 String get hkmId; String get userId; String get kennelId; int get following; int get isMember; int get isHomeKennel; int get kennelNotificationPreference; int get kennelEmailAlertPreference; String? get authorizedDeviceList; int? get authorizedDeviceCount; int get userRoleFlags; int get appAccessFlags; int get hcTotalRunCount; int get hcHaringCount; int get historicalTotalRunCount; int get historicalHaringCount; int get historicalCountIsEstimate; double get kennelCredit; double get discountAmount; int get discountPercent; String get discountDescription; DateTime? get dateOfLastRun; DateTime? get membershipExpirationDate; DateTime? get memberSince; int? get isKennelFollowing; int get mismanagementRoles; String? get kennelUserPhoto; String? get kennelHashName; DateTime? get updatedAt; int? get removed;
/// Create a copy of HasherKennelMapModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HasherKennelMapModelCopyWith<HasherKennelMapModel> get copyWith => _$HasherKennelMapModelCopyWithImpl<HasherKennelMapModel>(this as HasherKennelMapModel, _$identity);

  /// Serializes this HasherKennelMapModel to a JSON map.
  Map<String, dynamic> toJson();

@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'HasherKennelMapModel'))
    ..add(DiagnosticsProperty('hkmId', hkmId))..add(DiagnosticsProperty('userId', userId))..add(DiagnosticsProperty('kennelId', kennelId))..add(DiagnosticsProperty('following', following))..add(DiagnosticsProperty('isMember', isMember))..add(DiagnosticsProperty('isHomeKennel', isHomeKennel))..add(DiagnosticsProperty('kennelNotificationPreference', kennelNotificationPreference))..add(DiagnosticsProperty('kennelEmailAlertPreference', kennelEmailAlertPreference))..add(DiagnosticsProperty('authorizedDeviceList', authorizedDeviceList))..add(DiagnosticsProperty('authorizedDeviceCount', authorizedDeviceCount))..add(DiagnosticsProperty('userRoleFlags', userRoleFlags))..add(DiagnosticsProperty('appAccessFlags', appAccessFlags))..add(DiagnosticsProperty('hcTotalRunCount', hcTotalRunCount))..add(DiagnosticsProperty('hcHaringCount', hcHaringCount))..add(DiagnosticsProperty('historicalTotalRunCount', historicalTotalRunCount))..add(DiagnosticsProperty('historicalHaringCount', historicalHaringCount))..add(DiagnosticsProperty('historicalCountIsEstimate', historicalCountIsEstimate))..add(DiagnosticsProperty('kennelCredit', kennelCredit))..add(DiagnosticsProperty('discountAmount', discountAmount))..add(DiagnosticsProperty('discountPercent', discountPercent))..add(DiagnosticsProperty('discountDescription', discountDescription))..add(DiagnosticsProperty('dateOfLastRun', dateOfLastRun))..add(DiagnosticsProperty('membershipExpirationDate', membershipExpirationDate))..add(DiagnosticsProperty('memberSince', memberSince))..add(DiagnosticsProperty('isKennelFollowing', isKennelFollowing))..add(DiagnosticsProperty('mismanagementRoles', mismanagementRoles))..add(DiagnosticsProperty('kennelUserPhoto', kennelUserPhoto))..add(DiagnosticsProperty('kennelHashName', kennelHashName))..add(DiagnosticsProperty('updatedAt', updatedAt))..add(DiagnosticsProperty('removed', removed));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HasherKennelMapModel&&(identical(other.hkmId, hkmId) || other.hkmId == hkmId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.kennelId, kennelId) || other.kennelId == kennelId)&&(identical(other.following, following) || other.following == following)&&(identical(other.isMember, isMember) || other.isMember == isMember)&&(identical(other.isHomeKennel, isHomeKennel) || other.isHomeKennel == isHomeKennel)&&(identical(other.kennelNotificationPreference, kennelNotificationPreference) || other.kennelNotificationPreference == kennelNotificationPreference)&&(identical(other.kennelEmailAlertPreference, kennelEmailAlertPreference) || other.kennelEmailAlertPreference == kennelEmailAlertPreference)&&(identical(other.authorizedDeviceList, authorizedDeviceList) || other.authorizedDeviceList == authorizedDeviceList)&&(identical(other.authorizedDeviceCount, authorizedDeviceCount) || other.authorizedDeviceCount == authorizedDeviceCount)&&(identical(other.userRoleFlags, userRoleFlags) || other.userRoleFlags == userRoleFlags)&&(identical(other.appAccessFlags, appAccessFlags) || other.appAccessFlags == appAccessFlags)&&(identical(other.hcTotalRunCount, hcTotalRunCount) || other.hcTotalRunCount == hcTotalRunCount)&&(identical(other.hcHaringCount, hcHaringCount) || other.hcHaringCount == hcHaringCount)&&(identical(other.historicalTotalRunCount, historicalTotalRunCount) || other.historicalTotalRunCount == historicalTotalRunCount)&&(identical(other.historicalHaringCount, historicalHaringCount) || other.historicalHaringCount == historicalHaringCount)&&(identical(other.historicalCountIsEstimate, historicalCountIsEstimate) || other.historicalCountIsEstimate == historicalCountIsEstimate)&&(identical(other.kennelCredit, kennelCredit) || other.kennelCredit == kennelCredit)&&(identical(other.discountAmount, discountAmount) || other.discountAmount == discountAmount)&&(identical(other.discountPercent, discountPercent) || other.discountPercent == discountPercent)&&(identical(other.discountDescription, discountDescription) || other.discountDescription == discountDescription)&&(identical(other.dateOfLastRun, dateOfLastRun) || other.dateOfLastRun == dateOfLastRun)&&(identical(other.membershipExpirationDate, membershipExpirationDate) || other.membershipExpirationDate == membershipExpirationDate)&&(identical(other.memberSince, memberSince) || other.memberSince == memberSince)&&(identical(other.isKennelFollowing, isKennelFollowing) || other.isKennelFollowing == isKennelFollowing)&&(identical(other.mismanagementRoles, mismanagementRoles) || other.mismanagementRoles == mismanagementRoles)&&(identical(other.kennelUserPhoto, kennelUserPhoto) || other.kennelUserPhoto == kennelUserPhoto)&&(identical(other.kennelHashName, kennelHashName) || other.kennelHashName == kennelHashName)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.removed, removed) || other.removed == removed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,hkmId,userId,kennelId,following,isMember,isHomeKennel,kennelNotificationPreference,kennelEmailAlertPreference,authorizedDeviceList,authorizedDeviceCount,userRoleFlags,appAccessFlags,hcTotalRunCount,hcHaringCount,historicalTotalRunCount,historicalHaringCount,historicalCountIsEstimate,kennelCredit,discountAmount,discountPercent,discountDescription,dateOfLastRun,membershipExpirationDate,memberSince,isKennelFollowing,mismanagementRoles,kennelUserPhoto,kennelHashName,updatedAt,removed]);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'HasherKennelMapModel(hkmId: $hkmId, userId: $userId, kennelId: $kennelId, following: $following, isMember: $isMember, isHomeKennel: $isHomeKennel, kennelNotificationPreference: $kennelNotificationPreference, kennelEmailAlertPreference: $kennelEmailAlertPreference, authorizedDeviceList: $authorizedDeviceList, authorizedDeviceCount: $authorizedDeviceCount, userRoleFlags: $userRoleFlags, appAccessFlags: $appAccessFlags, hcTotalRunCount: $hcTotalRunCount, hcHaringCount: $hcHaringCount, historicalTotalRunCount: $historicalTotalRunCount, historicalHaringCount: $historicalHaringCount, historicalCountIsEstimate: $historicalCountIsEstimate, kennelCredit: $kennelCredit, discountAmount: $discountAmount, discountPercent: $discountPercent, discountDescription: $discountDescription, dateOfLastRun: $dateOfLastRun, membershipExpirationDate: $membershipExpirationDate, memberSince: $memberSince, isKennelFollowing: $isKennelFollowing, mismanagementRoles: $mismanagementRoles, kennelUserPhoto: $kennelUserPhoto, kennelHashName: $kennelHashName, updatedAt: $updatedAt, removed: $removed)';
}


}

/// @nodoc
abstract mixin class $HasherKennelMapModelCopyWith<$Res>  {
  factory $HasherKennelMapModelCopyWith(HasherKennelMapModel value, $Res Function(HasherKennelMapModel) _then) = _$HasherKennelMapModelCopyWithImpl;
@useResult
$Res call({
 String hkmId, String userId, String kennelId, int following, int isMember, int isHomeKennel, int kennelNotificationPreference, int kennelEmailAlertPreference, String? authorizedDeviceList, int? authorizedDeviceCount, int userRoleFlags, int appAccessFlags, int hcTotalRunCount, int hcHaringCount, int historicalTotalRunCount, int historicalHaringCount, int historicalCountIsEstimate, double kennelCredit, double discountAmount, int discountPercent, String discountDescription, DateTime? dateOfLastRun, DateTime? membershipExpirationDate, DateTime? memberSince, int? isKennelFollowing, int mismanagementRoles, String? kennelUserPhoto, String? kennelHashName, DateTime? updatedAt, int? removed
});




}
/// @nodoc
class _$HasherKennelMapModelCopyWithImpl<$Res>
    implements $HasherKennelMapModelCopyWith<$Res> {
  _$HasherKennelMapModelCopyWithImpl(this._self, this._then);

  final HasherKennelMapModel _self;
  final $Res Function(HasherKennelMapModel) _then;

/// Create a copy of HasherKennelMapModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? hkmId = null,Object? userId = null,Object? kennelId = null,Object? following = null,Object? isMember = null,Object? isHomeKennel = null,Object? kennelNotificationPreference = null,Object? kennelEmailAlertPreference = null,Object? authorizedDeviceList = freezed,Object? authorizedDeviceCount = freezed,Object? userRoleFlags = null,Object? appAccessFlags = null,Object? hcTotalRunCount = null,Object? hcHaringCount = null,Object? historicalTotalRunCount = null,Object? historicalHaringCount = null,Object? historicalCountIsEstimate = null,Object? kennelCredit = null,Object? discountAmount = null,Object? discountPercent = null,Object? discountDescription = null,Object? dateOfLastRun = freezed,Object? membershipExpirationDate = freezed,Object? memberSince = freezed,Object? isKennelFollowing = freezed,Object? mismanagementRoles = null,Object? kennelUserPhoto = freezed,Object? kennelHashName = freezed,Object? updatedAt = freezed,Object? removed = freezed,}) {
  return _then(_self.copyWith(
hkmId: null == hkmId ? _self.hkmId : hkmId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,kennelId: null == kennelId ? _self.kennelId : kennelId // ignore: cast_nullable_to_non_nullable
as String,following: null == following ? _self.following : following // ignore: cast_nullable_to_non_nullable
as int,isMember: null == isMember ? _self.isMember : isMember // ignore: cast_nullable_to_non_nullable
as int,isHomeKennel: null == isHomeKennel ? _self.isHomeKennel : isHomeKennel // ignore: cast_nullable_to_non_nullable
as int,kennelNotificationPreference: null == kennelNotificationPreference ? _self.kennelNotificationPreference : kennelNotificationPreference // ignore: cast_nullable_to_non_nullable
as int,kennelEmailAlertPreference: null == kennelEmailAlertPreference ? _self.kennelEmailAlertPreference : kennelEmailAlertPreference // ignore: cast_nullable_to_non_nullable
as int,authorizedDeviceList: freezed == authorizedDeviceList ? _self.authorizedDeviceList : authorizedDeviceList // ignore: cast_nullable_to_non_nullable
as String?,authorizedDeviceCount: freezed == authorizedDeviceCount ? _self.authorizedDeviceCount : authorizedDeviceCount // ignore: cast_nullable_to_non_nullable
as int?,userRoleFlags: null == userRoleFlags ? _self.userRoleFlags : userRoleFlags // ignore: cast_nullable_to_non_nullable
as int,appAccessFlags: null == appAccessFlags ? _self.appAccessFlags : appAccessFlags // ignore: cast_nullable_to_non_nullable
as int,hcTotalRunCount: null == hcTotalRunCount ? _self.hcTotalRunCount : hcTotalRunCount // ignore: cast_nullable_to_non_nullable
as int,hcHaringCount: null == hcHaringCount ? _self.hcHaringCount : hcHaringCount // ignore: cast_nullable_to_non_nullable
as int,historicalTotalRunCount: null == historicalTotalRunCount ? _self.historicalTotalRunCount : historicalTotalRunCount // ignore: cast_nullable_to_non_nullable
as int,historicalHaringCount: null == historicalHaringCount ? _self.historicalHaringCount : historicalHaringCount // ignore: cast_nullable_to_non_nullable
as int,historicalCountIsEstimate: null == historicalCountIsEstimate ? _self.historicalCountIsEstimate : historicalCountIsEstimate // ignore: cast_nullable_to_non_nullable
as int,kennelCredit: null == kennelCredit ? _self.kennelCredit : kennelCredit // ignore: cast_nullable_to_non_nullable
as double,discountAmount: null == discountAmount ? _self.discountAmount : discountAmount // ignore: cast_nullable_to_non_nullable
as double,discountPercent: null == discountPercent ? _self.discountPercent : discountPercent // ignore: cast_nullable_to_non_nullable
as int,discountDescription: null == discountDescription ? _self.discountDescription : discountDescription // ignore: cast_nullable_to_non_nullable
as String,dateOfLastRun: freezed == dateOfLastRun ? _self.dateOfLastRun : dateOfLastRun // ignore: cast_nullable_to_non_nullable
as DateTime?,membershipExpirationDate: freezed == membershipExpirationDate ? _self.membershipExpirationDate : membershipExpirationDate // ignore: cast_nullable_to_non_nullable
as DateTime?,memberSince: freezed == memberSince ? _self.memberSince : memberSince // ignore: cast_nullable_to_non_nullable
as DateTime?,isKennelFollowing: freezed == isKennelFollowing ? _self.isKennelFollowing : isKennelFollowing // ignore: cast_nullable_to_non_nullable
as int?,mismanagementRoles: null == mismanagementRoles ? _self.mismanagementRoles : mismanagementRoles // ignore: cast_nullable_to_non_nullable
as int,kennelUserPhoto: freezed == kennelUserPhoto ? _self.kennelUserPhoto : kennelUserPhoto // ignore: cast_nullable_to_non_nullable
as String?,kennelHashName: freezed == kennelHashName ? _self.kennelHashName : kennelHashName // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,removed: freezed == removed ? _self.removed : removed // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [HasherKennelMapModel].
extension HasherKennelMapModelPatterns on HasherKennelMapModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HasherKennelMapModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HasherKennelMapModel() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HasherKennelMapModel value)  $default,){
final _that = this;
switch (_that) {
case _HasherKennelMapModel():
return $default(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HasherKennelMapModel value)?  $default,){
final _that = this;
switch (_that) {
case _HasherKennelMapModel() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String hkmId,  String userId,  String kennelId,  int following,  int isMember,  int isHomeKennel,  int kennelNotificationPreference,  int kennelEmailAlertPreference,  String? authorizedDeviceList,  int? authorizedDeviceCount,  int userRoleFlags,  int appAccessFlags,  int hcTotalRunCount,  int hcHaringCount,  int historicalTotalRunCount,  int historicalHaringCount,  int historicalCountIsEstimate,  double kennelCredit,  double discountAmount,  int discountPercent,  String discountDescription,  DateTime? dateOfLastRun,  DateTime? membershipExpirationDate,  DateTime? memberSince,  int? isKennelFollowing,  int mismanagementRoles,  String? kennelUserPhoto,  String? kennelHashName,  DateTime? updatedAt,  int? removed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HasherKennelMapModel() when $default != null:
return $default(_that.hkmId,_that.userId,_that.kennelId,_that.following,_that.isMember,_that.isHomeKennel,_that.kennelNotificationPreference,_that.kennelEmailAlertPreference,_that.authorizedDeviceList,_that.authorizedDeviceCount,_that.userRoleFlags,_that.appAccessFlags,_that.hcTotalRunCount,_that.hcHaringCount,_that.historicalTotalRunCount,_that.historicalHaringCount,_that.historicalCountIsEstimate,_that.kennelCredit,_that.discountAmount,_that.discountPercent,_that.discountDescription,_that.dateOfLastRun,_that.membershipExpirationDate,_that.memberSince,_that.isKennelFollowing,_that.mismanagementRoles,_that.kennelUserPhoto,_that.kennelHashName,_that.updatedAt,_that.removed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String hkmId,  String userId,  String kennelId,  int following,  int isMember,  int isHomeKennel,  int kennelNotificationPreference,  int kennelEmailAlertPreference,  String? authorizedDeviceList,  int? authorizedDeviceCount,  int userRoleFlags,  int appAccessFlags,  int hcTotalRunCount,  int hcHaringCount,  int historicalTotalRunCount,  int historicalHaringCount,  int historicalCountIsEstimate,  double kennelCredit,  double discountAmount,  int discountPercent,  String discountDescription,  DateTime? dateOfLastRun,  DateTime? membershipExpirationDate,  DateTime? memberSince,  int? isKennelFollowing,  int mismanagementRoles,  String? kennelUserPhoto,  String? kennelHashName,  DateTime? updatedAt,  int? removed)  $default,) {final _that = this;
switch (_that) {
case _HasherKennelMapModel():
return $default(_that.hkmId,_that.userId,_that.kennelId,_that.following,_that.isMember,_that.isHomeKennel,_that.kennelNotificationPreference,_that.kennelEmailAlertPreference,_that.authorizedDeviceList,_that.authorizedDeviceCount,_that.userRoleFlags,_that.appAccessFlags,_that.hcTotalRunCount,_that.hcHaringCount,_that.historicalTotalRunCount,_that.historicalHaringCount,_that.historicalCountIsEstimate,_that.kennelCredit,_that.discountAmount,_that.discountPercent,_that.discountDescription,_that.dateOfLastRun,_that.membershipExpirationDate,_that.memberSince,_that.isKennelFollowing,_that.mismanagementRoles,_that.kennelUserPhoto,_that.kennelHashName,_that.updatedAt,_that.removed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String hkmId,  String userId,  String kennelId,  int following,  int isMember,  int isHomeKennel,  int kennelNotificationPreference,  int kennelEmailAlertPreference,  String? authorizedDeviceList,  int? authorizedDeviceCount,  int userRoleFlags,  int appAccessFlags,  int hcTotalRunCount,  int hcHaringCount,  int historicalTotalRunCount,  int historicalHaringCount,  int historicalCountIsEstimate,  double kennelCredit,  double discountAmount,  int discountPercent,  String discountDescription,  DateTime? dateOfLastRun,  DateTime? membershipExpirationDate,  DateTime? memberSince,  int? isKennelFollowing,  int mismanagementRoles,  String? kennelUserPhoto,  String? kennelHashName,  DateTime? updatedAt,  int? removed)?  $default,) {final _that = this;
switch (_that) {
case _HasherKennelMapModel() when $default != null:
return $default(_that.hkmId,_that.userId,_that.kennelId,_that.following,_that.isMember,_that.isHomeKennel,_that.kennelNotificationPreference,_that.kennelEmailAlertPreference,_that.authorizedDeviceList,_that.authorizedDeviceCount,_that.userRoleFlags,_that.appAccessFlags,_that.hcTotalRunCount,_that.hcHaringCount,_that.historicalTotalRunCount,_that.historicalHaringCount,_that.historicalCountIsEstimate,_that.kennelCredit,_that.discountAmount,_that.discountPercent,_that.discountDescription,_that.dateOfLastRun,_that.membershipExpirationDate,_that.memberSince,_that.isKennelFollowing,_that.mismanagementRoles,_that.kennelUserPhoto,_that.kennelHashName,_that.updatedAt,_that.removed);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HasherKennelMapModel with DiagnosticableTreeMixin implements HasherKennelMapModel {
   _HasherKennelMapModel({required this.hkmId, required this.userId, required this.kennelId, required this.following, required this.isMember, required this.isHomeKennel, required this.kennelNotificationPreference, required this.kennelEmailAlertPreference, this.authorizedDeviceList, this.authorizedDeviceCount, required this.userRoleFlags, required this.appAccessFlags, required this.hcTotalRunCount, required this.hcHaringCount, required this.historicalTotalRunCount, required this.historicalHaringCount, required this.historicalCountIsEstimate, required this.kennelCredit, required this.discountAmount, required this.discountPercent, required this.discountDescription, this.dateOfLastRun, this.membershipExpirationDate, this.memberSince, this.isKennelFollowing, required this.mismanagementRoles, this.kennelUserPhoto, this.kennelHashName, this.updatedAt, this.removed});
  factory _HasherKennelMapModel.fromJson(Map<String, dynamic> json) => _$HasherKennelMapModelFromJson(json);

@override final  String hkmId;
@override final  String userId;
@override final  String kennelId;
@override final  int following;
@override final  int isMember;
@override final  int isHomeKennel;
@override final  int kennelNotificationPreference;
@override final  int kennelEmailAlertPreference;
@override final  String? authorizedDeviceList;
@override final  int? authorizedDeviceCount;
@override final  int userRoleFlags;
@override final  int appAccessFlags;
@override final  int hcTotalRunCount;
@override final  int hcHaringCount;
@override final  int historicalTotalRunCount;
@override final  int historicalHaringCount;
@override final  int historicalCountIsEstimate;
@override final  double kennelCredit;
@override final  double discountAmount;
@override final  int discountPercent;
@override final  String discountDescription;
@override final  DateTime? dateOfLastRun;
@override final  DateTime? membershipExpirationDate;
@override final  DateTime? memberSince;
@override final  int? isKennelFollowing;
@override final  int mismanagementRoles;
@override final  String? kennelUserPhoto;
@override final  String? kennelHashName;
@override final  DateTime? updatedAt;
@override final  int? removed;

/// Create a copy of HasherKennelMapModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HasherKennelMapModelCopyWith<_HasherKennelMapModel> get copyWith => __$HasherKennelMapModelCopyWithImpl<_HasherKennelMapModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HasherKennelMapModelToJson(this, );
}
@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'HasherKennelMapModel'))
    ..add(DiagnosticsProperty('hkmId', hkmId))..add(DiagnosticsProperty('userId', userId))..add(DiagnosticsProperty('kennelId', kennelId))..add(DiagnosticsProperty('following', following))..add(DiagnosticsProperty('isMember', isMember))..add(DiagnosticsProperty('isHomeKennel', isHomeKennel))..add(DiagnosticsProperty('kennelNotificationPreference', kennelNotificationPreference))..add(DiagnosticsProperty('kennelEmailAlertPreference', kennelEmailAlertPreference))..add(DiagnosticsProperty('authorizedDeviceList', authorizedDeviceList))..add(DiagnosticsProperty('authorizedDeviceCount', authorizedDeviceCount))..add(DiagnosticsProperty('userRoleFlags', userRoleFlags))..add(DiagnosticsProperty('appAccessFlags', appAccessFlags))..add(DiagnosticsProperty('hcTotalRunCount', hcTotalRunCount))..add(DiagnosticsProperty('hcHaringCount', hcHaringCount))..add(DiagnosticsProperty('historicalTotalRunCount', historicalTotalRunCount))..add(DiagnosticsProperty('historicalHaringCount', historicalHaringCount))..add(DiagnosticsProperty('historicalCountIsEstimate', historicalCountIsEstimate))..add(DiagnosticsProperty('kennelCredit', kennelCredit))..add(DiagnosticsProperty('discountAmount', discountAmount))..add(DiagnosticsProperty('discountPercent', discountPercent))..add(DiagnosticsProperty('discountDescription', discountDescription))..add(DiagnosticsProperty('dateOfLastRun', dateOfLastRun))..add(DiagnosticsProperty('membershipExpirationDate', membershipExpirationDate))..add(DiagnosticsProperty('memberSince', memberSince))..add(DiagnosticsProperty('isKennelFollowing', isKennelFollowing))..add(DiagnosticsProperty('mismanagementRoles', mismanagementRoles))..add(DiagnosticsProperty('kennelUserPhoto', kennelUserPhoto))..add(DiagnosticsProperty('kennelHashName', kennelHashName))..add(DiagnosticsProperty('updatedAt', updatedAt))..add(DiagnosticsProperty('removed', removed));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HasherKennelMapModel&&(identical(other.hkmId, hkmId) || other.hkmId == hkmId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.kennelId, kennelId) || other.kennelId == kennelId)&&(identical(other.following, following) || other.following == following)&&(identical(other.isMember, isMember) || other.isMember == isMember)&&(identical(other.isHomeKennel, isHomeKennel) || other.isHomeKennel == isHomeKennel)&&(identical(other.kennelNotificationPreference, kennelNotificationPreference) || other.kennelNotificationPreference == kennelNotificationPreference)&&(identical(other.kennelEmailAlertPreference, kennelEmailAlertPreference) || other.kennelEmailAlertPreference == kennelEmailAlertPreference)&&(identical(other.authorizedDeviceList, authorizedDeviceList) || other.authorizedDeviceList == authorizedDeviceList)&&(identical(other.authorizedDeviceCount, authorizedDeviceCount) || other.authorizedDeviceCount == authorizedDeviceCount)&&(identical(other.userRoleFlags, userRoleFlags) || other.userRoleFlags == userRoleFlags)&&(identical(other.appAccessFlags, appAccessFlags) || other.appAccessFlags == appAccessFlags)&&(identical(other.hcTotalRunCount, hcTotalRunCount) || other.hcTotalRunCount == hcTotalRunCount)&&(identical(other.hcHaringCount, hcHaringCount) || other.hcHaringCount == hcHaringCount)&&(identical(other.historicalTotalRunCount, historicalTotalRunCount) || other.historicalTotalRunCount == historicalTotalRunCount)&&(identical(other.historicalHaringCount, historicalHaringCount) || other.historicalHaringCount == historicalHaringCount)&&(identical(other.historicalCountIsEstimate, historicalCountIsEstimate) || other.historicalCountIsEstimate == historicalCountIsEstimate)&&(identical(other.kennelCredit, kennelCredit) || other.kennelCredit == kennelCredit)&&(identical(other.discountAmount, discountAmount) || other.discountAmount == discountAmount)&&(identical(other.discountPercent, discountPercent) || other.discountPercent == discountPercent)&&(identical(other.discountDescription, discountDescription) || other.discountDescription == discountDescription)&&(identical(other.dateOfLastRun, dateOfLastRun) || other.dateOfLastRun == dateOfLastRun)&&(identical(other.membershipExpirationDate, membershipExpirationDate) || other.membershipExpirationDate == membershipExpirationDate)&&(identical(other.memberSince, memberSince) || other.memberSince == memberSince)&&(identical(other.isKennelFollowing, isKennelFollowing) || other.isKennelFollowing == isKennelFollowing)&&(identical(other.mismanagementRoles, mismanagementRoles) || other.mismanagementRoles == mismanagementRoles)&&(identical(other.kennelUserPhoto, kennelUserPhoto) || other.kennelUserPhoto == kennelUserPhoto)&&(identical(other.kennelHashName, kennelHashName) || other.kennelHashName == kennelHashName)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.removed, removed) || other.removed == removed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,hkmId,userId,kennelId,following,isMember,isHomeKennel,kennelNotificationPreference,kennelEmailAlertPreference,authorizedDeviceList,authorizedDeviceCount,userRoleFlags,appAccessFlags,hcTotalRunCount,hcHaringCount,historicalTotalRunCount,historicalHaringCount,historicalCountIsEstimate,kennelCredit,discountAmount,discountPercent,discountDescription,dateOfLastRun,membershipExpirationDate,memberSince,isKennelFollowing,mismanagementRoles,kennelUserPhoto,kennelHashName,updatedAt,removed]);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'HasherKennelMapModel(hkmId: $hkmId, userId: $userId, kennelId: $kennelId, following: $following, isMember: $isMember, isHomeKennel: $isHomeKennel, kennelNotificationPreference: $kennelNotificationPreference, kennelEmailAlertPreference: $kennelEmailAlertPreference, authorizedDeviceList: $authorizedDeviceList, authorizedDeviceCount: $authorizedDeviceCount, userRoleFlags: $userRoleFlags, appAccessFlags: $appAccessFlags, hcTotalRunCount: $hcTotalRunCount, hcHaringCount: $hcHaringCount, historicalTotalRunCount: $historicalTotalRunCount, historicalHaringCount: $historicalHaringCount, historicalCountIsEstimate: $historicalCountIsEstimate, kennelCredit: $kennelCredit, discountAmount: $discountAmount, discountPercent: $discountPercent, discountDescription: $discountDescription, dateOfLastRun: $dateOfLastRun, membershipExpirationDate: $membershipExpirationDate, memberSince: $memberSince, isKennelFollowing: $isKennelFollowing, mismanagementRoles: $mismanagementRoles, kennelUserPhoto: $kennelUserPhoto, kennelHashName: $kennelHashName, updatedAt: $updatedAt, removed: $removed)';
}


}

/// @nodoc
abstract mixin class _$HasherKennelMapModelCopyWith<$Res> implements $HasherKennelMapModelCopyWith<$Res> {
  factory _$HasherKennelMapModelCopyWith(_HasherKennelMapModel value, $Res Function(_HasherKennelMapModel) _then) = __$HasherKennelMapModelCopyWithImpl;
@override @useResult
$Res call({
 String hkmId, String userId, String kennelId, int following, int isMember, int isHomeKennel, int kennelNotificationPreference, int kennelEmailAlertPreference, String? authorizedDeviceList, int? authorizedDeviceCount, int userRoleFlags, int appAccessFlags, int hcTotalRunCount, int hcHaringCount, int historicalTotalRunCount, int historicalHaringCount, int historicalCountIsEstimate, double kennelCredit, double discountAmount, int discountPercent, String discountDescription, DateTime? dateOfLastRun, DateTime? membershipExpirationDate, DateTime? memberSince, int? isKennelFollowing, int mismanagementRoles, String? kennelUserPhoto, String? kennelHashName, DateTime? updatedAt, int? removed
});




}
/// @nodoc
class __$HasherKennelMapModelCopyWithImpl<$Res>
    implements _$HasherKennelMapModelCopyWith<$Res> {
  __$HasherKennelMapModelCopyWithImpl(this._self, this._then);

  final _HasherKennelMapModel _self;
  final $Res Function(_HasherKennelMapModel) _then;

/// Create a copy of HasherKennelMapModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? hkmId = null,Object? userId = null,Object? kennelId = null,Object? following = null,Object? isMember = null,Object? isHomeKennel = null,Object? kennelNotificationPreference = null,Object? kennelEmailAlertPreference = null,Object? authorizedDeviceList = freezed,Object? authorizedDeviceCount = freezed,Object? userRoleFlags = null,Object? appAccessFlags = null,Object? hcTotalRunCount = null,Object? hcHaringCount = null,Object? historicalTotalRunCount = null,Object? historicalHaringCount = null,Object? historicalCountIsEstimate = null,Object? kennelCredit = null,Object? discountAmount = null,Object? discountPercent = null,Object? discountDescription = null,Object? dateOfLastRun = freezed,Object? membershipExpirationDate = freezed,Object? memberSince = freezed,Object? isKennelFollowing = freezed,Object? mismanagementRoles = null,Object? kennelUserPhoto = freezed,Object? kennelHashName = freezed,Object? updatedAt = freezed,Object? removed = freezed,}) {
  return _then(_HasherKennelMapModel(
hkmId: null == hkmId ? _self.hkmId : hkmId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,kennelId: null == kennelId ? _self.kennelId : kennelId // ignore: cast_nullable_to_non_nullable
as String,following: null == following ? _self.following : following // ignore: cast_nullable_to_non_nullable
as int,isMember: null == isMember ? _self.isMember : isMember // ignore: cast_nullable_to_non_nullable
as int,isHomeKennel: null == isHomeKennel ? _self.isHomeKennel : isHomeKennel // ignore: cast_nullable_to_non_nullable
as int,kennelNotificationPreference: null == kennelNotificationPreference ? _self.kennelNotificationPreference : kennelNotificationPreference // ignore: cast_nullable_to_non_nullable
as int,kennelEmailAlertPreference: null == kennelEmailAlertPreference ? _self.kennelEmailAlertPreference : kennelEmailAlertPreference // ignore: cast_nullable_to_non_nullable
as int,authorizedDeviceList: freezed == authorizedDeviceList ? _self.authorizedDeviceList : authorizedDeviceList // ignore: cast_nullable_to_non_nullable
as String?,authorizedDeviceCount: freezed == authorizedDeviceCount ? _self.authorizedDeviceCount : authorizedDeviceCount // ignore: cast_nullable_to_non_nullable
as int?,userRoleFlags: null == userRoleFlags ? _self.userRoleFlags : userRoleFlags // ignore: cast_nullable_to_non_nullable
as int,appAccessFlags: null == appAccessFlags ? _self.appAccessFlags : appAccessFlags // ignore: cast_nullable_to_non_nullable
as int,hcTotalRunCount: null == hcTotalRunCount ? _self.hcTotalRunCount : hcTotalRunCount // ignore: cast_nullable_to_non_nullable
as int,hcHaringCount: null == hcHaringCount ? _self.hcHaringCount : hcHaringCount // ignore: cast_nullable_to_non_nullable
as int,historicalTotalRunCount: null == historicalTotalRunCount ? _self.historicalTotalRunCount : historicalTotalRunCount // ignore: cast_nullable_to_non_nullable
as int,historicalHaringCount: null == historicalHaringCount ? _self.historicalHaringCount : historicalHaringCount // ignore: cast_nullable_to_non_nullable
as int,historicalCountIsEstimate: null == historicalCountIsEstimate ? _self.historicalCountIsEstimate : historicalCountIsEstimate // ignore: cast_nullable_to_non_nullable
as int,kennelCredit: null == kennelCredit ? _self.kennelCredit : kennelCredit // ignore: cast_nullable_to_non_nullable
as double,discountAmount: null == discountAmount ? _self.discountAmount : discountAmount // ignore: cast_nullable_to_non_nullable
as double,discountPercent: null == discountPercent ? _self.discountPercent : discountPercent // ignore: cast_nullable_to_non_nullable
as int,discountDescription: null == discountDescription ? _self.discountDescription : discountDescription // ignore: cast_nullable_to_non_nullable
as String,dateOfLastRun: freezed == dateOfLastRun ? _self.dateOfLastRun : dateOfLastRun // ignore: cast_nullable_to_non_nullable
as DateTime?,membershipExpirationDate: freezed == membershipExpirationDate ? _self.membershipExpirationDate : membershipExpirationDate // ignore: cast_nullable_to_non_nullable
as DateTime?,memberSince: freezed == memberSince ? _self.memberSince : memberSince // ignore: cast_nullable_to_non_nullable
as DateTime?,isKennelFollowing: freezed == isKennelFollowing ? _self.isKennelFollowing : isKennelFollowing // ignore: cast_nullable_to_non_nullable
as int?,mismanagementRoles: null == mismanagementRoles ? _self.mismanagementRoles : mismanagementRoles // ignore: cast_nullable_to_non_nullable
as int,kennelUserPhoto: freezed == kennelUserPhoto ? _self.kennelUserPhoto : kennelUserPhoto // ignore: cast_nullable_to_non_nullable
as String?,kennelHashName: freezed == kennelHashName ? _self.kennelHashName : kennelHashName // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,removed: freezed == removed ? _self.removed : removed // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
