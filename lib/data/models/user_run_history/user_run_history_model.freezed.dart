// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_run_history_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserRunHistoryModel implements DiagnosticableTreeMixin {

 String get eventId; String get eventName; int get eventNumber; String get kennelName; String get kennelShortName; String get currencySymbol; int get digitsAfterDecimal; String get kennelLogo; String get countryName; String get flagFile; DateTime get eventStartDatetime; int get canEditRunAttendence; String? get hemId; int get attendenceState; int get isHare; double? get creditAmount; double? get debitAmount; double? get creditAvailable; int? get paymentType; String? get extrasDescription; double? get extrasPrice; int? get doPayForExtras; int? get totalRunsThisKennel; int? get totalHaringThisKennel;@JsonKey(includeFromJson: false, includeToJson: false) bool get isUpdating;
/// Create a copy of UserRunHistoryModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserRunHistoryModelCopyWith<UserRunHistoryModel> get copyWith => _$UserRunHistoryModelCopyWithImpl<UserRunHistoryModel>(this as UserRunHistoryModel, _$identity);

  /// Serializes this UserRunHistoryModel to a JSON map.
  Map<String, dynamic> toJson();

@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'UserRunHistoryModel'))
    ..add(DiagnosticsProperty('eventId', eventId))..add(DiagnosticsProperty('eventName', eventName))..add(DiagnosticsProperty('eventNumber', eventNumber))..add(DiagnosticsProperty('kennelName', kennelName))..add(DiagnosticsProperty('kennelShortName', kennelShortName))..add(DiagnosticsProperty('currencySymbol', currencySymbol))..add(DiagnosticsProperty('digitsAfterDecimal', digitsAfterDecimal))..add(DiagnosticsProperty('kennelLogo', kennelLogo))..add(DiagnosticsProperty('countryName', countryName))..add(DiagnosticsProperty('flagFile', flagFile))..add(DiagnosticsProperty('eventStartDatetime', eventStartDatetime))..add(DiagnosticsProperty('canEditRunAttendence', canEditRunAttendence))..add(DiagnosticsProperty('hemId', hemId))..add(DiagnosticsProperty('attendenceState', attendenceState))..add(DiagnosticsProperty('isHare', isHare))..add(DiagnosticsProperty('creditAmount', creditAmount))..add(DiagnosticsProperty('debitAmount', debitAmount))..add(DiagnosticsProperty('creditAvailable', creditAvailable))..add(DiagnosticsProperty('paymentType', paymentType))..add(DiagnosticsProperty('extrasDescription', extrasDescription))..add(DiagnosticsProperty('extrasPrice', extrasPrice))..add(DiagnosticsProperty('doPayForExtras', doPayForExtras))..add(DiagnosticsProperty('totalRunsThisKennel', totalRunsThisKennel))..add(DiagnosticsProperty('totalHaringThisKennel', totalHaringThisKennel))..add(DiagnosticsProperty('isUpdating', isUpdating));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserRunHistoryModel&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.eventName, eventName) || other.eventName == eventName)&&(identical(other.eventNumber, eventNumber) || other.eventNumber == eventNumber)&&(identical(other.kennelName, kennelName) || other.kennelName == kennelName)&&(identical(other.kennelShortName, kennelShortName) || other.kennelShortName == kennelShortName)&&(identical(other.currencySymbol, currencySymbol) || other.currencySymbol == currencySymbol)&&(identical(other.digitsAfterDecimal, digitsAfterDecimal) || other.digitsAfterDecimal == digitsAfterDecimal)&&(identical(other.kennelLogo, kennelLogo) || other.kennelLogo == kennelLogo)&&(identical(other.countryName, countryName) || other.countryName == countryName)&&(identical(other.flagFile, flagFile) || other.flagFile == flagFile)&&(identical(other.eventStartDatetime, eventStartDatetime) || other.eventStartDatetime == eventStartDatetime)&&(identical(other.canEditRunAttendence, canEditRunAttendence) || other.canEditRunAttendence == canEditRunAttendence)&&(identical(other.hemId, hemId) || other.hemId == hemId)&&(identical(other.attendenceState, attendenceState) || other.attendenceState == attendenceState)&&(identical(other.isHare, isHare) || other.isHare == isHare)&&(identical(other.creditAmount, creditAmount) || other.creditAmount == creditAmount)&&(identical(other.debitAmount, debitAmount) || other.debitAmount == debitAmount)&&(identical(other.creditAvailable, creditAvailable) || other.creditAvailable == creditAvailable)&&(identical(other.paymentType, paymentType) || other.paymentType == paymentType)&&(identical(other.extrasDescription, extrasDescription) || other.extrasDescription == extrasDescription)&&(identical(other.extrasPrice, extrasPrice) || other.extrasPrice == extrasPrice)&&(identical(other.doPayForExtras, doPayForExtras) || other.doPayForExtras == doPayForExtras)&&(identical(other.totalRunsThisKennel, totalRunsThisKennel) || other.totalRunsThisKennel == totalRunsThisKennel)&&(identical(other.totalHaringThisKennel, totalHaringThisKennel) || other.totalHaringThisKennel == totalHaringThisKennel)&&(identical(other.isUpdating, isUpdating) || other.isUpdating == isUpdating));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,eventId,eventName,eventNumber,kennelName,kennelShortName,currencySymbol,digitsAfterDecimal,kennelLogo,countryName,flagFile,eventStartDatetime,canEditRunAttendence,hemId,attendenceState,isHare,creditAmount,debitAmount,creditAvailable,paymentType,extrasDescription,extrasPrice,doPayForExtras,totalRunsThisKennel,totalHaringThisKennel,isUpdating]);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'UserRunHistoryModel(eventId: $eventId, eventName: $eventName, eventNumber: $eventNumber, kennelName: $kennelName, kennelShortName: $kennelShortName, currencySymbol: $currencySymbol, digitsAfterDecimal: $digitsAfterDecimal, kennelLogo: $kennelLogo, countryName: $countryName, flagFile: $flagFile, eventStartDatetime: $eventStartDatetime, canEditRunAttendence: $canEditRunAttendence, hemId: $hemId, attendenceState: $attendenceState, isHare: $isHare, creditAmount: $creditAmount, debitAmount: $debitAmount, creditAvailable: $creditAvailable, paymentType: $paymentType, extrasDescription: $extrasDescription, extrasPrice: $extrasPrice, doPayForExtras: $doPayForExtras, totalRunsThisKennel: $totalRunsThisKennel, totalHaringThisKennel: $totalHaringThisKennel, isUpdating: $isUpdating)';
}


}

/// @nodoc
abstract mixin class $UserRunHistoryModelCopyWith<$Res>  {
  factory $UserRunHistoryModelCopyWith(UserRunHistoryModel value, $Res Function(UserRunHistoryModel) _then) = _$UserRunHistoryModelCopyWithImpl;
@useResult
$Res call({
 String eventId, String eventName, int eventNumber, String kennelName, String kennelShortName, String currencySymbol, int digitsAfterDecimal, String kennelLogo, String countryName, String flagFile, DateTime eventStartDatetime, int canEditRunAttendence, String? hemId, int attendenceState, int isHare, double? creditAmount, double? debitAmount, double? creditAvailable, int? paymentType, String? extrasDescription, double? extrasPrice, int? doPayForExtras, int? totalRunsThisKennel, int? totalHaringThisKennel,@JsonKey(includeFromJson: false, includeToJson: false) bool isUpdating
});




}
/// @nodoc
class _$UserRunHistoryModelCopyWithImpl<$Res>
    implements $UserRunHistoryModelCopyWith<$Res> {
  _$UserRunHistoryModelCopyWithImpl(this._self, this._then);

  final UserRunHistoryModel _self;
  final $Res Function(UserRunHistoryModel) _then;

/// Create a copy of UserRunHistoryModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? eventId = null,Object? eventName = null,Object? eventNumber = null,Object? kennelName = null,Object? kennelShortName = null,Object? currencySymbol = null,Object? digitsAfterDecimal = null,Object? kennelLogo = null,Object? countryName = null,Object? flagFile = null,Object? eventStartDatetime = null,Object? canEditRunAttendence = null,Object? hemId = freezed,Object? attendenceState = null,Object? isHare = null,Object? creditAmount = freezed,Object? debitAmount = freezed,Object? creditAvailable = freezed,Object? paymentType = freezed,Object? extrasDescription = freezed,Object? extrasPrice = freezed,Object? doPayForExtras = freezed,Object? totalRunsThisKennel = freezed,Object? totalHaringThisKennel = freezed,Object? isUpdating = null,}) {
  return _then(_self.copyWith(
eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,eventName: null == eventName ? _self.eventName : eventName // ignore: cast_nullable_to_non_nullable
as String,eventNumber: null == eventNumber ? _self.eventNumber : eventNumber // ignore: cast_nullable_to_non_nullable
as int,kennelName: null == kennelName ? _self.kennelName : kennelName // ignore: cast_nullable_to_non_nullable
as String,kennelShortName: null == kennelShortName ? _self.kennelShortName : kennelShortName // ignore: cast_nullable_to_non_nullable
as String,currencySymbol: null == currencySymbol ? _self.currencySymbol : currencySymbol // ignore: cast_nullable_to_non_nullable
as String,digitsAfterDecimal: null == digitsAfterDecimal ? _self.digitsAfterDecimal : digitsAfterDecimal // ignore: cast_nullable_to_non_nullable
as int,kennelLogo: null == kennelLogo ? _self.kennelLogo : kennelLogo // ignore: cast_nullable_to_non_nullable
as String,countryName: null == countryName ? _self.countryName : countryName // ignore: cast_nullable_to_non_nullable
as String,flagFile: null == flagFile ? _self.flagFile : flagFile // ignore: cast_nullable_to_non_nullable
as String,eventStartDatetime: null == eventStartDatetime ? _self.eventStartDatetime : eventStartDatetime // ignore: cast_nullable_to_non_nullable
as DateTime,canEditRunAttendence: null == canEditRunAttendence ? _self.canEditRunAttendence : canEditRunAttendence // ignore: cast_nullable_to_non_nullable
as int,hemId: freezed == hemId ? _self.hemId : hemId // ignore: cast_nullable_to_non_nullable
as String?,attendenceState: null == attendenceState ? _self.attendenceState : attendenceState // ignore: cast_nullable_to_non_nullable
as int,isHare: null == isHare ? _self.isHare : isHare // ignore: cast_nullable_to_non_nullable
as int,creditAmount: freezed == creditAmount ? _self.creditAmount : creditAmount // ignore: cast_nullable_to_non_nullable
as double?,debitAmount: freezed == debitAmount ? _self.debitAmount : debitAmount // ignore: cast_nullable_to_non_nullable
as double?,creditAvailable: freezed == creditAvailable ? _self.creditAvailable : creditAvailable // ignore: cast_nullable_to_non_nullable
as double?,paymentType: freezed == paymentType ? _self.paymentType : paymentType // ignore: cast_nullable_to_non_nullable
as int?,extrasDescription: freezed == extrasDescription ? _self.extrasDescription : extrasDescription // ignore: cast_nullable_to_non_nullable
as String?,extrasPrice: freezed == extrasPrice ? _self.extrasPrice : extrasPrice // ignore: cast_nullable_to_non_nullable
as double?,doPayForExtras: freezed == doPayForExtras ? _self.doPayForExtras : doPayForExtras // ignore: cast_nullable_to_non_nullable
as int?,totalRunsThisKennel: freezed == totalRunsThisKennel ? _self.totalRunsThisKennel : totalRunsThisKennel // ignore: cast_nullable_to_non_nullable
as int?,totalHaringThisKennel: freezed == totalHaringThisKennel ? _self.totalHaringThisKennel : totalHaringThisKennel // ignore: cast_nullable_to_non_nullable
as int?,isUpdating: null == isUpdating ? _self.isUpdating : isUpdating // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [UserRunHistoryModel].
extension UserRunHistoryModelPatterns on UserRunHistoryModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserRunHistoryModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserRunHistoryModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserRunHistoryModel value)  $default,){
final _that = this;
switch (_that) {
case _UserRunHistoryModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserRunHistoryModel value)?  $default,){
final _that = this;
switch (_that) {
case _UserRunHistoryModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String eventId,  String eventName,  int eventNumber,  String kennelName,  String kennelShortName,  String currencySymbol,  int digitsAfterDecimal,  String kennelLogo,  String countryName,  String flagFile,  DateTime eventStartDatetime,  int canEditRunAttendence,  String? hemId,  int attendenceState,  int isHare,  double? creditAmount,  double? debitAmount,  double? creditAvailable,  int? paymentType,  String? extrasDescription,  double? extrasPrice,  int? doPayForExtras,  int? totalRunsThisKennel,  int? totalHaringThisKennel, @JsonKey(includeFromJson: false, includeToJson: false)  bool isUpdating)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserRunHistoryModel() when $default != null:
return $default(_that.eventId,_that.eventName,_that.eventNumber,_that.kennelName,_that.kennelShortName,_that.currencySymbol,_that.digitsAfterDecimal,_that.kennelLogo,_that.countryName,_that.flagFile,_that.eventStartDatetime,_that.canEditRunAttendence,_that.hemId,_that.attendenceState,_that.isHare,_that.creditAmount,_that.debitAmount,_that.creditAvailable,_that.paymentType,_that.extrasDescription,_that.extrasPrice,_that.doPayForExtras,_that.totalRunsThisKennel,_that.totalHaringThisKennel,_that.isUpdating);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String eventId,  String eventName,  int eventNumber,  String kennelName,  String kennelShortName,  String currencySymbol,  int digitsAfterDecimal,  String kennelLogo,  String countryName,  String flagFile,  DateTime eventStartDatetime,  int canEditRunAttendence,  String? hemId,  int attendenceState,  int isHare,  double? creditAmount,  double? debitAmount,  double? creditAvailable,  int? paymentType,  String? extrasDescription,  double? extrasPrice,  int? doPayForExtras,  int? totalRunsThisKennel,  int? totalHaringThisKennel, @JsonKey(includeFromJson: false, includeToJson: false)  bool isUpdating)  $default,) {final _that = this;
switch (_that) {
case _UserRunHistoryModel():
return $default(_that.eventId,_that.eventName,_that.eventNumber,_that.kennelName,_that.kennelShortName,_that.currencySymbol,_that.digitsAfterDecimal,_that.kennelLogo,_that.countryName,_that.flagFile,_that.eventStartDatetime,_that.canEditRunAttendence,_that.hemId,_that.attendenceState,_that.isHare,_that.creditAmount,_that.debitAmount,_that.creditAvailable,_that.paymentType,_that.extrasDescription,_that.extrasPrice,_that.doPayForExtras,_that.totalRunsThisKennel,_that.totalHaringThisKennel,_that.isUpdating);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String eventId,  String eventName,  int eventNumber,  String kennelName,  String kennelShortName,  String currencySymbol,  int digitsAfterDecimal,  String kennelLogo,  String countryName,  String flagFile,  DateTime eventStartDatetime,  int canEditRunAttendence,  String? hemId,  int attendenceState,  int isHare,  double? creditAmount,  double? debitAmount,  double? creditAvailable,  int? paymentType,  String? extrasDescription,  double? extrasPrice,  int? doPayForExtras,  int? totalRunsThisKennel,  int? totalHaringThisKennel, @JsonKey(includeFromJson: false, includeToJson: false)  bool isUpdating)?  $default,) {final _that = this;
switch (_that) {
case _UserRunHistoryModel() when $default != null:
return $default(_that.eventId,_that.eventName,_that.eventNumber,_that.kennelName,_that.kennelShortName,_that.currencySymbol,_that.digitsAfterDecimal,_that.kennelLogo,_that.countryName,_that.flagFile,_that.eventStartDatetime,_that.canEditRunAttendence,_that.hemId,_that.attendenceState,_that.isHare,_that.creditAmount,_that.debitAmount,_that.creditAvailable,_that.paymentType,_that.extrasDescription,_that.extrasPrice,_that.doPayForExtras,_that.totalRunsThisKennel,_that.totalHaringThisKennel,_that.isUpdating);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserRunHistoryModel with DiagnosticableTreeMixin implements UserRunHistoryModel {
   _UserRunHistoryModel({required this.eventId, required this.eventName, required this.eventNumber, required this.kennelName, required this.kennelShortName, required this.currencySymbol, required this.digitsAfterDecimal, required this.kennelLogo, required this.countryName, required this.flagFile, required this.eventStartDatetime, this.canEditRunAttendence = 0, this.hemId, this.attendenceState = 0, this.isHare = 0, this.creditAmount, this.debitAmount, this.creditAvailable, this.paymentType, this.extrasDescription, this.extrasPrice, this.doPayForExtras, this.totalRunsThisKennel, this.totalHaringThisKennel, @JsonKey(includeFromJson: false, includeToJson: false) this.isUpdating = false});
  factory _UserRunHistoryModel.fromJson(Map<String, dynamic> json) => _$UserRunHistoryModelFromJson(json);

@override final  String eventId;
@override final  String eventName;
@override final  int eventNumber;
@override final  String kennelName;
@override final  String kennelShortName;
@override final  String currencySymbol;
@override final  int digitsAfterDecimal;
@override final  String kennelLogo;
@override final  String countryName;
@override final  String flagFile;
@override final  DateTime eventStartDatetime;
@override@JsonKey() final  int canEditRunAttendence;
@override final  String? hemId;
@override@JsonKey() final  int attendenceState;
@override@JsonKey() final  int isHare;
@override final  double? creditAmount;
@override final  double? debitAmount;
@override final  double? creditAvailable;
@override final  int? paymentType;
@override final  String? extrasDescription;
@override final  double? extrasPrice;
@override final  int? doPayForExtras;
@override final  int? totalRunsThisKennel;
@override final  int? totalHaringThisKennel;
@override@JsonKey(includeFromJson: false, includeToJson: false) final  bool isUpdating;

/// Create a copy of UserRunHistoryModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserRunHistoryModelCopyWith<_UserRunHistoryModel> get copyWith => __$UserRunHistoryModelCopyWithImpl<_UserRunHistoryModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserRunHistoryModelToJson(this, );
}
@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'UserRunHistoryModel'))
    ..add(DiagnosticsProperty('eventId', eventId))..add(DiagnosticsProperty('eventName', eventName))..add(DiagnosticsProperty('eventNumber', eventNumber))..add(DiagnosticsProperty('kennelName', kennelName))..add(DiagnosticsProperty('kennelShortName', kennelShortName))..add(DiagnosticsProperty('currencySymbol', currencySymbol))..add(DiagnosticsProperty('digitsAfterDecimal', digitsAfterDecimal))..add(DiagnosticsProperty('kennelLogo', kennelLogo))..add(DiagnosticsProperty('countryName', countryName))..add(DiagnosticsProperty('flagFile', flagFile))..add(DiagnosticsProperty('eventStartDatetime', eventStartDatetime))..add(DiagnosticsProperty('canEditRunAttendence', canEditRunAttendence))..add(DiagnosticsProperty('hemId', hemId))..add(DiagnosticsProperty('attendenceState', attendenceState))..add(DiagnosticsProperty('isHare', isHare))..add(DiagnosticsProperty('creditAmount', creditAmount))..add(DiagnosticsProperty('debitAmount', debitAmount))..add(DiagnosticsProperty('creditAvailable', creditAvailable))..add(DiagnosticsProperty('paymentType', paymentType))..add(DiagnosticsProperty('extrasDescription', extrasDescription))..add(DiagnosticsProperty('extrasPrice', extrasPrice))..add(DiagnosticsProperty('doPayForExtras', doPayForExtras))..add(DiagnosticsProperty('totalRunsThisKennel', totalRunsThisKennel))..add(DiagnosticsProperty('totalHaringThisKennel', totalHaringThisKennel))..add(DiagnosticsProperty('isUpdating', isUpdating));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserRunHistoryModel&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.eventName, eventName) || other.eventName == eventName)&&(identical(other.eventNumber, eventNumber) || other.eventNumber == eventNumber)&&(identical(other.kennelName, kennelName) || other.kennelName == kennelName)&&(identical(other.kennelShortName, kennelShortName) || other.kennelShortName == kennelShortName)&&(identical(other.currencySymbol, currencySymbol) || other.currencySymbol == currencySymbol)&&(identical(other.digitsAfterDecimal, digitsAfterDecimal) || other.digitsAfterDecimal == digitsAfterDecimal)&&(identical(other.kennelLogo, kennelLogo) || other.kennelLogo == kennelLogo)&&(identical(other.countryName, countryName) || other.countryName == countryName)&&(identical(other.flagFile, flagFile) || other.flagFile == flagFile)&&(identical(other.eventStartDatetime, eventStartDatetime) || other.eventStartDatetime == eventStartDatetime)&&(identical(other.canEditRunAttendence, canEditRunAttendence) || other.canEditRunAttendence == canEditRunAttendence)&&(identical(other.hemId, hemId) || other.hemId == hemId)&&(identical(other.attendenceState, attendenceState) || other.attendenceState == attendenceState)&&(identical(other.isHare, isHare) || other.isHare == isHare)&&(identical(other.creditAmount, creditAmount) || other.creditAmount == creditAmount)&&(identical(other.debitAmount, debitAmount) || other.debitAmount == debitAmount)&&(identical(other.creditAvailable, creditAvailable) || other.creditAvailable == creditAvailable)&&(identical(other.paymentType, paymentType) || other.paymentType == paymentType)&&(identical(other.extrasDescription, extrasDescription) || other.extrasDescription == extrasDescription)&&(identical(other.extrasPrice, extrasPrice) || other.extrasPrice == extrasPrice)&&(identical(other.doPayForExtras, doPayForExtras) || other.doPayForExtras == doPayForExtras)&&(identical(other.totalRunsThisKennel, totalRunsThisKennel) || other.totalRunsThisKennel == totalRunsThisKennel)&&(identical(other.totalHaringThisKennel, totalHaringThisKennel) || other.totalHaringThisKennel == totalHaringThisKennel)&&(identical(other.isUpdating, isUpdating) || other.isUpdating == isUpdating));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,eventId,eventName,eventNumber,kennelName,kennelShortName,currencySymbol,digitsAfterDecimal,kennelLogo,countryName,flagFile,eventStartDatetime,canEditRunAttendence,hemId,attendenceState,isHare,creditAmount,debitAmount,creditAvailable,paymentType,extrasDescription,extrasPrice,doPayForExtras,totalRunsThisKennel,totalHaringThisKennel,isUpdating]);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'UserRunHistoryModel(eventId: $eventId, eventName: $eventName, eventNumber: $eventNumber, kennelName: $kennelName, kennelShortName: $kennelShortName, currencySymbol: $currencySymbol, digitsAfterDecimal: $digitsAfterDecimal, kennelLogo: $kennelLogo, countryName: $countryName, flagFile: $flagFile, eventStartDatetime: $eventStartDatetime, canEditRunAttendence: $canEditRunAttendence, hemId: $hemId, attendenceState: $attendenceState, isHare: $isHare, creditAmount: $creditAmount, debitAmount: $debitAmount, creditAvailable: $creditAvailable, paymentType: $paymentType, extrasDescription: $extrasDescription, extrasPrice: $extrasPrice, doPayForExtras: $doPayForExtras, totalRunsThisKennel: $totalRunsThisKennel, totalHaringThisKennel: $totalHaringThisKennel, isUpdating: $isUpdating)';
}


}

/// @nodoc
abstract mixin class _$UserRunHistoryModelCopyWith<$Res> implements $UserRunHistoryModelCopyWith<$Res> {
  factory _$UserRunHistoryModelCopyWith(_UserRunHistoryModel value, $Res Function(_UserRunHistoryModel) _then) = __$UserRunHistoryModelCopyWithImpl;
@override @useResult
$Res call({
 String eventId, String eventName, int eventNumber, String kennelName, String kennelShortName, String currencySymbol, int digitsAfterDecimal, String kennelLogo, String countryName, String flagFile, DateTime eventStartDatetime, int canEditRunAttendence, String? hemId, int attendenceState, int isHare, double? creditAmount, double? debitAmount, double? creditAvailable, int? paymentType, String? extrasDescription, double? extrasPrice, int? doPayForExtras, int? totalRunsThisKennel, int? totalHaringThisKennel,@JsonKey(includeFromJson: false, includeToJson: false) bool isUpdating
});




}
/// @nodoc
class __$UserRunHistoryModelCopyWithImpl<$Res>
    implements _$UserRunHistoryModelCopyWith<$Res> {
  __$UserRunHistoryModelCopyWithImpl(this._self, this._then);

  final _UserRunHistoryModel _self;
  final $Res Function(_UserRunHistoryModel) _then;

/// Create a copy of UserRunHistoryModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? eventId = null,Object? eventName = null,Object? eventNumber = null,Object? kennelName = null,Object? kennelShortName = null,Object? currencySymbol = null,Object? digitsAfterDecimal = null,Object? kennelLogo = null,Object? countryName = null,Object? flagFile = null,Object? eventStartDatetime = null,Object? canEditRunAttendence = null,Object? hemId = freezed,Object? attendenceState = null,Object? isHare = null,Object? creditAmount = freezed,Object? debitAmount = freezed,Object? creditAvailable = freezed,Object? paymentType = freezed,Object? extrasDescription = freezed,Object? extrasPrice = freezed,Object? doPayForExtras = freezed,Object? totalRunsThisKennel = freezed,Object? totalHaringThisKennel = freezed,Object? isUpdating = null,}) {
  return _then(_UserRunHistoryModel(
eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,eventName: null == eventName ? _self.eventName : eventName // ignore: cast_nullable_to_non_nullable
as String,eventNumber: null == eventNumber ? _self.eventNumber : eventNumber // ignore: cast_nullable_to_non_nullable
as int,kennelName: null == kennelName ? _self.kennelName : kennelName // ignore: cast_nullable_to_non_nullable
as String,kennelShortName: null == kennelShortName ? _self.kennelShortName : kennelShortName // ignore: cast_nullable_to_non_nullable
as String,currencySymbol: null == currencySymbol ? _self.currencySymbol : currencySymbol // ignore: cast_nullable_to_non_nullable
as String,digitsAfterDecimal: null == digitsAfterDecimal ? _self.digitsAfterDecimal : digitsAfterDecimal // ignore: cast_nullable_to_non_nullable
as int,kennelLogo: null == kennelLogo ? _self.kennelLogo : kennelLogo // ignore: cast_nullable_to_non_nullable
as String,countryName: null == countryName ? _self.countryName : countryName // ignore: cast_nullable_to_non_nullable
as String,flagFile: null == flagFile ? _self.flagFile : flagFile // ignore: cast_nullable_to_non_nullable
as String,eventStartDatetime: null == eventStartDatetime ? _self.eventStartDatetime : eventStartDatetime // ignore: cast_nullable_to_non_nullable
as DateTime,canEditRunAttendence: null == canEditRunAttendence ? _self.canEditRunAttendence : canEditRunAttendence // ignore: cast_nullable_to_non_nullable
as int,hemId: freezed == hemId ? _self.hemId : hemId // ignore: cast_nullable_to_non_nullable
as String?,attendenceState: null == attendenceState ? _self.attendenceState : attendenceState // ignore: cast_nullable_to_non_nullable
as int,isHare: null == isHare ? _self.isHare : isHare // ignore: cast_nullable_to_non_nullable
as int,creditAmount: freezed == creditAmount ? _self.creditAmount : creditAmount // ignore: cast_nullable_to_non_nullable
as double?,debitAmount: freezed == debitAmount ? _self.debitAmount : debitAmount // ignore: cast_nullable_to_non_nullable
as double?,creditAvailable: freezed == creditAvailable ? _self.creditAvailable : creditAvailable // ignore: cast_nullable_to_non_nullable
as double?,paymentType: freezed == paymentType ? _self.paymentType : paymentType // ignore: cast_nullable_to_non_nullable
as int?,extrasDescription: freezed == extrasDescription ? _self.extrasDescription : extrasDescription // ignore: cast_nullable_to_non_nullable
as String?,extrasPrice: freezed == extrasPrice ? _self.extrasPrice : extrasPrice // ignore: cast_nullable_to_non_nullable
as double?,doPayForExtras: freezed == doPayForExtras ? _self.doPayForExtras : doPayForExtras // ignore: cast_nullable_to_non_nullable
as int?,totalRunsThisKennel: freezed == totalRunsThisKennel ? _self.totalRunsThisKennel : totalRunsThisKennel // ignore: cast_nullable_to_non_nullable
as int?,totalHaringThisKennel: freezed == totalHaringThisKennel ? _self.totalHaringThisKennel : totalHaringThisKennel // ignore: cast_nullable_to_non_nullable
as int?,isUpdating: null == isUpdating ? _self.isUpdating : isUpdating // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
