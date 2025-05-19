// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'are_we_at_run_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AreWeAtRunModel implements DiagnosticableTreeMixin {

 String get eventId; String get eventName; String? get eventImage; String get kennelId; String get kennelLogo; String get kennelShortName; int get eventNumber; double get distanceInMeters; double get deltaHours; double get kennelCredit; double get memberPrice; double get nonMemberPrice; double get extrasCost; double get discountAmount; double get discountPercent; int get attendenceState; int get digitsAfterDecimal; int get allowSelfPayment; String get currencySymbol; DateTime get membershipExpirationDate; String? get extrasDescription;
/// Create a copy of AreWeAtRunModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AreWeAtRunModelCopyWith<AreWeAtRunModel> get copyWith => _$AreWeAtRunModelCopyWithImpl<AreWeAtRunModel>(this as AreWeAtRunModel, _$identity);

  /// Serializes this AreWeAtRunModel to a JSON map.
  Map<String, dynamic> toJson();

@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'AreWeAtRunModel'))
    ..add(DiagnosticsProperty('eventId', eventId))..add(DiagnosticsProperty('eventName', eventName))..add(DiagnosticsProperty('eventImage', eventImage))..add(DiagnosticsProperty('kennelId', kennelId))..add(DiagnosticsProperty('kennelLogo', kennelLogo))..add(DiagnosticsProperty('kennelShortName', kennelShortName))..add(DiagnosticsProperty('eventNumber', eventNumber))..add(DiagnosticsProperty('distanceInMeters', distanceInMeters))..add(DiagnosticsProperty('deltaHours', deltaHours))..add(DiagnosticsProperty('kennelCredit', kennelCredit))..add(DiagnosticsProperty('memberPrice', memberPrice))..add(DiagnosticsProperty('nonMemberPrice', nonMemberPrice))..add(DiagnosticsProperty('extrasCost', extrasCost))..add(DiagnosticsProperty('discountAmount', discountAmount))..add(DiagnosticsProperty('discountPercent', discountPercent))..add(DiagnosticsProperty('attendenceState', attendenceState))..add(DiagnosticsProperty('digitsAfterDecimal', digitsAfterDecimal))..add(DiagnosticsProperty('allowSelfPayment', allowSelfPayment))..add(DiagnosticsProperty('currencySymbol', currencySymbol))..add(DiagnosticsProperty('membershipExpirationDate', membershipExpirationDate))..add(DiagnosticsProperty('extrasDescription', extrasDescription));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AreWeAtRunModel&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.eventName, eventName) || other.eventName == eventName)&&(identical(other.eventImage, eventImage) || other.eventImage == eventImage)&&(identical(other.kennelId, kennelId) || other.kennelId == kennelId)&&(identical(other.kennelLogo, kennelLogo) || other.kennelLogo == kennelLogo)&&(identical(other.kennelShortName, kennelShortName) || other.kennelShortName == kennelShortName)&&(identical(other.eventNumber, eventNumber) || other.eventNumber == eventNumber)&&(identical(other.distanceInMeters, distanceInMeters) || other.distanceInMeters == distanceInMeters)&&(identical(other.deltaHours, deltaHours) || other.deltaHours == deltaHours)&&(identical(other.kennelCredit, kennelCredit) || other.kennelCredit == kennelCredit)&&(identical(other.memberPrice, memberPrice) || other.memberPrice == memberPrice)&&(identical(other.nonMemberPrice, nonMemberPrice) || other.nonMemberPrice == nonMemberPrice)&&(identical(other.extrasCost, extrasCost) || other.extrasCost == extrasCost)&&(identical(other.discountAmount, discountAmount) || other.discountAmount == discountAmount)&&(identical(other.discountPercent, discountPercent) || other.discountPercent == discountPercent)&&(identical(other.attendenceState, attendenceState) || other.attendenceState == attendenceState)&&(identical(other.digitsAfterDecimal, digitsAfterDecimal) || other.digitsAfterDecimal == digitsAfterDecimal)&&(identical(other.allowSelfPayment, allowSelfPayment) || other.allowSelfPayment == allowSelfPayment)&&(identical(other.currencySymbol, currencySymbol) || other.currencySymbol == currencySymbol)&&(identical(other.membershipExpirationDate, membershipExpirationDate) || other.membershipExpirationDate == membershipExpirationDate)&&(identical(other.extrasDescription, extrasDescription) || other.extrasDescription == extrasDescription));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,eventId,eventName,eventImage,kennelId,kennelLogo,kennelShortName,eventNumber,distanceInMeters,deltaHours,kennelCredit,memberPrice,nonMemberPrice,extrasCost,discountAmount,discountPercent,attendenceState,digitsAfterDecimal,allowSelfPayment,currencySymbol,membershipExpirationDate,extrasDescription]);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'AreWeAtRunModel(eventId: $eventId, eventName: $eventName, eventImage: $eventImage, kennelId: $kennelId, kennelLogo: $kennelLogo, kennelShortName: $kennelShortName, eventNumber: $eventNumber, distanceInMeters: $distanceInMeters, deltaHours: $deltaHours, kennelCredit: $kennelCredit, memberPrice: $memberPrice, nonMemberPrice: $nonMemberPrice, extrasCost: $extrasCost, discountAmount: $discountAmount, discountPercent: $discountPercent, attendenceState: $attendenceState, digitsAfterDecimal: $digitsAfterDecimal, allowSelfPayment: $allowSelfPayment, currencySymbol: $currencySymbol, membershipExpirationDate: $membershipExpirationDate, extrasDescription: $extrasDescription)';
}


}

/// @nodoc
abstract mixin class $AreWeAtRunModelCopyWith<$Res>  {
  factory $AreWeAtRunModelCopyWith(AreWeAtRunModel value, $Res Function(AreWeAtRunModel) _then) = _$AreWeAtRunModelCopyWithImpl;
@useResult
$Res call({
 String eventId, String eventName, String? eventImage, String kennelId, String kennelLogo, String kennelShortName, int eventNumber, double distanceInMeters, double deltaHours, double kennelCredit, double memberPrice, double nonMemberPrice, double extrasCost, double discountAmount, double discountPercent, int attendenceState, int digitsAfterDecimal, int allowSelfPayment, String currencySymbol, DateTime membershipExpirationDate, String? extrasDescription
});




}
/// @nodoc
class _$AreWeAtRunModelCopyWithImpl<$Res>
    implements $AreWeAtRunModelCopyWith<$Res> {
  _$AreWeAtRunModelCopyWithImpl(this._self, this._then);

  final AreWeAtRunModel _self;
  final $Res Function(AreWeAtRunModel) _then;

/// Create a copy of AreWeAtRunModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? eventId = null,Object? eventName = null,Object? eventImage = freezed,Object? kennelId = null,Object? kennelLogo = null,Object? kennelShortName = null,Object? eventNumber = null,Object? distanceInMeters = null,Object? deltaHours = null,Object? kennelCredit = null,Object? memberPrice = null,Object? nonMemberPrice = null,Object? extrasCost = null,Object? discountAmount = null,Object? discountPercent = null,Object? attendenceState = null,Object? digitsAfterDecimal = null,Object? allowSelfPayment = null,Object? currencySymbol = null,Object? membershipExpirationDate = null,Object? extrasDescription = freezed,}) {
  return _then(_self.copyWith(
eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,eventName: null == eventName ? _self.eventName : eventName // ignore: cast_nullable_to_non_nullable
as String,eventImage: freezed == eventImage ? _self.eventImage : eventImage // ignore: cast_nullable_to_non_nullable
as String?,kennelId: null == kennelId ? _self.kennelId : kennelId // ignore: cast_nullable_to_non_nullable
as String,kennelLogo: null == kennelLogo ? _self.kennelLogo : kennelLogo // ignore: cast_nullable_to_non_nullable
as String,kennelShortName: null == kennelShortName ? _self.kennelShortName : kennelShortName // ignore: cast_nullable_to_non_nullable
as String,eventNumber: null == eventNumber ? _self.eventNumber : eventNumber // ignore: cast_nullable_to_non_nullable
as int,distanceInMeters: null == distanceInMeters ? _self.distanceInMeters : distanceInMeters // ignore: cast_nullable_to_non_nullable
as double,deltaHours: null == deltaHours ? _self.deltaHours : deltaHours // ignore: cast_nullable_to_non_nullable
as double,kennelCredit: null == kennelCredit ? _self.kennelCredit : kennelCredit // ignore: cast_nullable_to_non_nullable
as double,memberPrice: null == memberPrice ? _self.memberPrice : memberPrice // ignore: cast_nullable_to_non_nullable
as double,nonMemberPrice: null == nonMemberPrice ? _self.nonMemberPrice : nonMemberPrice // ignore: cast_nullable_to_non_nullable
as double,extrasCost: null == extrasCost ? _self.extrasCost : extrasCost // ignore: cast_nullable_to_non_nullable
as double,discountAmount: null == discountAmount ? _self.discountAmount : discountAmount // ignore: cast_nullable_to_non_nullable
as double,discountPercent: null == discountPercent ? _self.discountPercent : discountPercent // ignore: cast_nullable_to_non_nullable
as double,attendenceState: null == attendenceState ? _self.attendenceState : attendenceState // ignore: cast_nullable_to_non_nullable
as int,digitsAfterDecimal: null == digitsAfterDecimal ? _self.digitsAfterDecimal : digitsAfterDecimal // ignore: cast_nullable_to_non_nullable
as int,allowSelfPayment: null == allowSelfPayment ? _self.allowSelfPayment : allowSelfPayment // ignore: cast_nullable_to_non_nullable
as int,currencySymbol: null == currencySymbol ? _self.currencySymbol : currencySymbol // ignore: cast_nullable_to_non_nullable
as String,membershipExpirationDate: null == membershipExpirationDate ? _self.membershipExpirationDate : membershipExpirationDate // ignore: cast_nullable_to_non_nullable
as DateTime,extrasDescription: freezed == extrasDescription ? _self.extrasDescription : extrasDescription // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _AreWeAtRunModel with DiagnosticableTreeMixin implements AreWeAtRunModel {
   _AreWeAtRunModel({required this.eventId, required this.eventName, this.eventImage, required this.kennelId, required this.kennelLogo, required this.kennelShortName, required this.eventNumber, required this.distanceInMeters, required this.deltaHours, this.kennelCredit = 0.0, required this.memberPrice, required this.nonMemberPrice, required this.extrasCost, this.discountAmount = 0.0, this.discountPercent = 0.0, this.attendenceState = 0, this.digitsAfterDecimal = 2, this.allowSelfPayment = 0, this.currencySymbol = r'$^', required this.membershipExpirationDate, this.extrasDescription});
  factory _AreWeAtRunModel.fromJson(Map<String, dynamic> json) => _$AreWeAtRunModelFromJson(json);

@override final  String eventId;
@override final  String eventName;
@override final  String? eventImage;
@override final  String kennelId;
@override final  String kennelLogo;
@override final  String kennelShortName;
@override final  int eventNumber;
@override final  double distanceInMeters;
@override final  double deltaHours;
@override@JsonKey() final  double kennelCredit;
@override final  double memberPrice;
@override final  double nonMemberPrice;
@override final  double extrasCost;
@override@JsonKey() final  double discountAmount;
@override@JsonKey() final  double discountPercent;
@override@JsonKey() final  int attendenceState;
@override@JsonKey() final  int digitsAfterDecimal;
@override@JsonKey() final  int allowSelfPayment;
@override@JsonKey() final  String currencySymbol;
@override final  DateTime membershipExpirationDate;
@override final  String? extrasDescription;

/// Create a copy of AreWeAtRunModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AreWeAtRunModelCopyWith<_AreWeAtRunModel> get copyWith => __$AreWeAtRunModelCopyWithImpl<_AreWeAtRunModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AreWeAtRunModelToJson(this, );
}
@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'AreWeAtRunModel'))
    ..add(DiagnosticsProperty('eventId', eventId))..add(DiagnosticsProperty('eventName', eventName))..add(DiagnosticsProperty('eventImage', eventImage))..add(DiagnosticsProperty('kennelId', kennelId))..add(DiagnosticsProperty('kennelLogo', kennelLogo))..add(DiagnosticsProperty('kennelShortName', kennelShortName))..add(DiagnosticsProperty('eventNumber', eventNumber))..add(DiagnosticsProperty('distanceInMeters', distanceInMeters))..add(DiagnosticsProperty('deltaHours', deltaHours))..add(DiagnosticsProperty('kennelCredit', kennelCredit))..add(DiagnosticsProperty('memberPrice', memberPrice))..add(DiagnosticsProperty('nonMemberPrice', nonMemberPrice))..add(DiagnosticsProperty('extrasCost', extrasCost))..add(DiagnosticsProperty('discountAmount', discountAmount))..add(DiagnosticsProperty('discountPercent', discountPercent))..add(DiagnosticsProperty('attendenceState', attendenceState))..add(DiagnosticsProperty('digitsAfterDecimal', digitsAfterDecimal))..add(DiagnosticsProperty('allowSelfPayment', allowSelfPayment))..add(DiagnosticsProperty('currencySymbol', currencySymbol))..add(DiagnosticsProperty('membershipExpirationDate', membershipExpirationDate))..add(DiagnosticsProperty('extrasDescription', extrasDescription));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AreWeAtRunModel&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.eventName, eventName) || other.eventName == eventName)&&(identical(other.eventImage, eventImage) || other.eventImage == eventImage)&&(identical(other.kennelId, kennelId) || other.kennelId == kennelId)&&(identical(other.kennelLogo, kennelLogo) || other.kennelLogo == kennelLogo)&&(identical(other.kennelShortName, kennelShortName) || other.kennelShortName == kennelShortName)&&(identical(other.eventNumber, eventNumber) || other.eventNumber == eventNumber)&&(identical(other.distanceInMeters, distanceInMeters) || other.distanceInMeters == distanceInMeters)&&(identical(other.deltaHours, deltaHours) || other.deltaHours == deltaHours)&&(identical(other.kennelCredit, kennelCredit) || other.kennelCredit == kennelCredit)&&(identical(other.memberPrice, memberPrice) || other.memberPrice == memberPrice)&&(identical(other.nonMemberPrice, nonMemberPrice) || other.nonMemberPrice == nonMemberPrice)&&(identical(other.extrasCost, extrasCost) || other.extrasCost == extrasCost)&&(identical(other.discountAmount, discountAmount) || other.discountAmount == discountAmount)&&(identical(other.discountPercent, discountPercent) || other.discountPercent == discountPercent)&&(identical(other.attendenceState, attendenceState) || other.attendenceState == attendenceState)&&(identical(other.digitsAfterDecimal, digitsAfterDecimal) || other.digitsAfterDecimal == digitsAfterDecimal)&&(identical(other.allowSelfPayment, allowSelfPayment) || other.allowSelfPayment == allowSelfPayment)&&(identical(other.currencySymbol, currencySymbol) || other.currencySymbol == currencySymbol)&&(identical(other.membershipExpirationDate, membershipExpirationDate) || other.membershipExpirationDate == membershipExpirationDate)&&(identical(other.extrasDescription, extrasDescription) || other.extrasDescription == extrasDescription));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,eventId,eventName,eventImage,kennelId,kennelLogo,kennelShortName,eventNumber,distanceInMeters,deltaHours,kennelCredit,memberPrice,nonMemberPrice,extrasCost,discountAmount,discountPercent,attendenceState,digitsAfterDecimal,allowSelfPayment,currencySymbol,membershipExpirationDate,extrasDescription]);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'AreWeAtRunModel(eventId: $eventId, eventName: $eventName, eventImage: $eventImage, kennelId: $kennelId, kennelLogo: $kennelLogo, kennelShortName: $kennelShortName, eventNumber: $eventNumber, distanceInMeters: $distanceInMeters, deltaHours: $deltaHours, kennelCredit: $kennelCredit, memberPrice: $memberPrice, nonMemberPrice: $nonMemberPrice, extrasCost: $extrasCost, discountAmount: $discountAmount, discountPercent: $discountPercent, attendenceState: $attendenceState, digitsAfterDecimal: $digitsAfterDecimal, allowSelfPayment: $allowSelfPayment, currencySymbol: $currencySymbol, membershipExpirationDate: $membershipExpirationDate, extrasDescription: $extrasDescription)';
}


}

/// @nodoc
abstract mixin class _$AreWeAtRunModelCopyWith<$Res> implements $AreWeAtRunModelCopyWith<$Res> {
  factory _$AreWeAtRunModelCopyWith(_AreWeAtRunModel value, $Res Function(_AreWeAtRunModel) _then) = __$AreWeAtRunModelCopyWithImpl;
@override @useResult
$Res call({
 String eventId, String eventName, String? eventImage, String kennelId, String kennelLogo, String kennelShortName, int eventNumber, double distanceInMeters, double deltaHours, double kennelCredit, double memberPrice, double nonMemberPrice, double extrasCost, double discountAmount, double discountPercent, int attendenceState, int digitsAfterDecimal, int allowSelfPayment, String currencySymbol, DateTime membershipExpirationDate, String? extrasDescription
});




}
/// @nodoc
class __$AreWeAtRunModelCopyWithImpl<$Res>
    implements _$AreWeAtRunModelCopyWith<$Res> {
  __$AreWeAtRunModelCopyWithImpl(this._self, this._then);

  final _AreWeAtRunModel _self;
  final $Res Function(_AreWeAtRunModel) _then;

/// Create a copy of AreWeAtRunModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? eventId = null,Object? eventName = null,Object? eventImage = freezed,Object? kennelId = null,Object? kennelLogo = null,Object? kennelShortName = null,Object? eventNumber = null,Object? distanceInMeters = null,Object? deltaHours = null,Object? kennelCredit = null,Object? memberPrice = null,Object? nonMemberPrice = null,Object? extrasCost = null,Object? discountAmount = null,Object? discountPercent = null,Object? attendenceState = null,Object? digitsAfterDecimal = null,Object? allowSelfPayment = null,Object? currencySymbol = null,Object? membershipExpirationDate = null,Object? extrasDescription = freezed,}) {
  return _then(_AreWeAtRunModel(
eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,eventName: null == eventName ? _self.eventName : eventName // ignore: cast_nullable_to_non_nullable
as String,eventImage: freezed == eventImage ? _self.eventImage : eventImage // ignore: cast_nullable_to_non_nullable
as String?,kennelId: null == kennelId ? _self.kennelId : kennelId // ignore: cast_nullable_to_non_nullable
as String,kennelLogo: null == kennelLogo ? _self.kennelLogo : kennelLogo // ignore: cast_nullable_to_non_nullable
as String,kennelShortName: null == kennelShortName ? _self.kennelShortName : kennelShortName // ignore: cast_nullable_to_non_nullable
as String,eventNumber: null == eventNumber ? _self.eventNumber : eventNumber // ignore: cast_nullable_to_non_nullable
as int,distanceInMeters: null == distanceInMeters ? _self.distanceInMeters : distanceInMeters // ignore: cast_nullable_to_non_nullable
as double,deltaHours: null == deltaHours ? _self.deltaHours : deltaHours // ignore: cast_nullable_to_non_nullable
as double,kennelCredit: null == kennelCredit ? _self.kennelCredit : kennelCredit // ignore: cast_nullable_to_non_nullable
as double,memberPrice: null == memberPrice ? _self.memberPrice : memberPrice // ignore: cast_nullable_to_non_nullable
as double,nonMemberPrice: null == nonMemberPrice ? _self.nonMemberPrice : nonMemberPrice // ignore: cast_nullable_to_non_nullable
as double,extrasCost: null == extrasCost ? _self.extrasCost : extrasCost // ignore: cast_nullable_to_non_nullable
as double,discountAmount: null == discountAmount ? _self.discountAmount : discountAmount // ignore: cast_nullable_to_non_nullable
as double,discountPercent: null == discountPercent ? _self.discountPercent : discountPercent // ignore: cast_nullable_to_non_nullable
as double,attendenceState: null == attendenceState ? _self.attendenceState : attendenceState // ignore: cast_nullable_to_non_nullable
as int,digitsAfterDecimal: null == digitsAfterDecimal ? _self.digitsAfterDecimal : digitsAfterDecimal // ignore: cast_nullable_to_non_nullable
as int,allowSelfPayment: null == allowSelfPayment ? _self.allowSelfPayment : allowSelfPayment // ignore: cast_nullable_to_non_nullable
as int,currencySymbol: null == currencySymbol ? _self.currencySymbol : currencySymbol // ignore: cast_nullable_to_non_nullable
as String,membershipExpirationDate: null == membershipExpirationDate ? _self.membershipExpirationDate : membershipExpirationDate // ignore: cast_nullable_to_non_nullable
as DateTime,extrasDescription: freezed == extrasDescription ? _self.extrasDescription : extrasDescription // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
