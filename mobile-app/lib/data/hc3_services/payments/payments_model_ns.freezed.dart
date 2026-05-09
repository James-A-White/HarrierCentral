// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'payments_model_ns.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PaymentsModel implements DiagnosticableTreeMixin {

 String get paymentId; String get kennelId; String get paidBy; String get hemId; String get eventId; String get paidTo; double get creditAmount; double get debitAmount; double? get creditAvailable; DateTime get paidDate; int get paymentType; int get productType; DateTime? get cancelledDate; String? get cancelledBy; DateTime? get confirmedDate; String? get confirmedBy; String? get paymentReference; String? get notes; int get doPayForExtras; double get surcharge; String? get paymentProvider; double get discountAmount; int get discountPercent; String get discountDescription; String get specialRunPriceReason; int? get removed; DateTime? get updatedAt;
/// Create a copy of PaymentsModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaymentsModelCopyWith<PaymentsModel> get copyWith => _$PaymentsModelCopyWithImpl<PaymentsModel>(this as PaymentsModel, _$identity);

  /// Serializes this PaymentsModel to a JSON map.
  Map<String, dynamic> toJson();

@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'PaymentsModel'))
    ..add(DiagnosticsProperty('paymentId', paymentId))..add(DiagnosticsProperty('kennelId', kennelId))..add(DiagnosticsProperty('paidBy', paidBy))..add(DiagnosticsProperty('hemId', hemId))..add(DiagnosticsProperty('eventId', eventId))..add(DiagnosticsProperty('paidTo', paidTo))..add(DiagnosticsProperty('creditAmount', creditAmount))..add(DiagnosticsProperty('debitAmount', debitAmount))..add(DiagnosticsProperty('creditAvailable', creditAvailable))..add(DiagnosticsProperty('paidDate', paidDate))..add(DiagnosticsProperty('paymentType', paymentType))..add(DiagnosticsProperty('productType', productType))..add(DiagnosticsProperty('cancelledDate', cancelledDate))..add(DiagnosticsProperty('cancelledBy', cancelledBy))..add(DiagnosticsProperty('confirmedDate', confirmedDate))..add(DiagnosticsProperty('confirmedBy', confirmedBy))..add(DiagnosticsProperty('paymentReference', paymentReference))..add(DiagnosticsProperty('notes', notes))..add(DiagnosticsProperty('doPayForExtras', doPayForExtras))..add(DiagnosticsProperty('surcharge', surcharge))..add(DiagnosticsProperty('paymentProvider', paymentProvider))..add(DiagnosticsProperty('discountAmount', discountAmount))..add(DiagnosticsProperty('discountPercent', discountPercent))..add(DiagnosticsProperty('discountDescription', discountDescription))..add(DiagnosticsProperty('specialRunPriceReason', specialRunPriceReason))..add(DiagnosticsProperty('removed', removed))..add(DiagnosticsProperty('updatedAt', updatedAt));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaymentsModel&&(identical(other.paymentId, paymentId) || other.paymentId == paymentId)&&(identical(other.kennelId, kennelId) || other.kennelId == kennelId)&&(identical(other.paidBy, paidBy) || other.paidBy == paidBy)&&(identical(other.hemId, hemId) || other.hemId == hemId)&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.paidTo, paidTo) || other.paidTo == paidTo)&&(identical(other.creditAmount, creditAmount) || other.creditAmount == creditAmount)&&(identical(other.debitAmount, debitAmount) || other.debitAmount == debitAmount)&&(identical(other.creditAvailable, creditAvailable) || other.creditAvailable == creditAvailable)&&(identical(other.paidDate, paidDate) || other.paidDate == paidDate)&&(identical(other.paymentType, paymentType) || other.paymentType == paymentType)&&(identical(other.productType, productType) || other.productType == productType)&&(identical(other.cancelledDate, cancelledDate) || other.cancelledDate == cancelledDate)&&(identical(other.cancelledBy, cancelledBy) || other.cancelledBy == cancelledBy)&&(identical(other.confirmedDate, confirmedDate) || other.confirmedDate == confirmedDate)&&(identical(other.confirmedBy, confirmedBy) || other.confirmedBy == confirmedBy)&&(identical(other.paymentReference, paymentReference) || other.paymentReference == paymentReference)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.doPayForExtras, doPayForExtras) || other.doPayForExtras == doPayForExtras)&&(identical(other.surcharge, surcharge) || other.surcharge == surcharge)&&(identical(other.paymentProvider, paymentProvider) || other.paymentProvider == paymentProvider)&&(identical(other.discountAmount, discountAmount) || other.discountAmount == discountAmount)&&(identical(other.discountPercent, discountPercent) || other.discountPercent == discountPercent)&&(identical(other.discountDescription, discountDescription) || other.discountDescription == discountDescription)&&(identical(other.specialRunPriceReason, specialRunPriceReason) || other.specialRunPriceReason == specialRunPriceReason)&&(identical(other.removed, removed) || other.removed == removed)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,paymentId,kennelId,paidBy,hemId,eventId,paidTo,creditAmount,debitAmount,creditAvailable,paidDate,paymentType,productType,cancelledDate,cancelledBy,confirmedDate,confirmedBy,paymentReference,notes,doPayForExtras,surcharge,paymentProvider,discountAmount,discountPercent,discountDescription,specialRunPriceReason,removed,updatedAt]);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'PaymentsModel(paymentId: $paymentId, kennelId: $kennelId, paidBy: $paidBy, hemId: $hemId, eventId: $eventId, paidTo: $paidTo, creditAmount: $creditAmount, debitAmount: $debitAmount, creditAvailable: $creditAvailable, paidDate: $paidDate, paymentType: $paymentType, productType: $productType, cancelledDate: $cancelledDate, cancelledBy: $cancelledBy, confirmedDate: $confirmedDate, confirmedBy: $confirmedBy, paymentReference: $paymentReference, notes: $notes, doPayForExtras: $doPayForExtras, surcharge: $surcharge, paymentProvider: $paymentProvider, discountAmount: $discountAmount, discountPercent: $discountPercent, discountDescription: $discountDescription, specialRunPriceReason: $specialRunPriceReason, removed: $removed, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $PaymentsModelCopyWith<$Res>  {
  factory $PaymentsModelCopyWith(PaymentsModel value, $Res Function(PaymentsModel) _then) = _$PaymentsModelCopyWithImpl;
@useResult
$Res call({
 String paymentId, String kennelId, String paidBy, String hemId, String eventId, String paidTo, double creditAmount, double debitAmount, double? creditAvailable, DateTime paidDate, int paymentType, int productType, DateTime? cancelledDate, String? cancelledBy, DateTime? confirmedDate, String? confirmedBy, String? paymentReference, String? notes, int doPayForExtras, double surcharge, String? paymentProvider, double discountAmount, int discountPercent, String discountDescription, String specialRunPriceReason, int? removed, DateTime? updatedAt
});




}
/// @nodoc
class _$PaymentsModelCopyWithImpl<$Res>
    implements $PaymentsModelCopyWith<$Res> {
  _$PaymentsModelCopyWithImpl(this._self, this._then);

  final PaymentsModel _self;
  final $Res Function(PaymentsModel) _then;

/// Create a copy of PaymentsModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? paymentId = null,Object? kennelId = null,Object? paidBy = null,Object? hemId = null,Object? eventId = null,Object? paidTo = null,Object? creditAmount = null,Object? debitAmount = null,Object? creditAvailable = freezed,Object? paidDate = null,Object? paymentType = null,Object? productType = null,Object? cancelledDate = freezed,Object? cancelledBy = freezed,Object? confirmedDate = freezed,Object? confirmedBy = freezed,Object? paymentReference = freezed,Object? notes = freezed,Object? doPayForExtras = null,Object? surcharge = null,Object? paymentProvider = freezed,Object? discountAmount = null,Object? discountPercent = null,Object? discountDescription = null,Object? specialRunPriceReason = null,Object? removed = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
paymentId: null == paymentId ? _self.paymentId : paymentId // ignore: cast_nullable_to_non_nullable
as String,kennelId: null == kennelId ? _self.kennelId : kennelId // ignore: cast_nullable_to_non_nullable
as String,paidBy: null == paidBy ? _self.paidBy : paidBy // ignore: cast_nullable_to_non_nullable
as String,hemId: null == hemId ? _self.hemId : hemId // ignore: cast_nullable_to_non_nullable
as String,eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,paidTo: null == paidTo ? _self.paidTo : paidTo // ignore: cast_nullable_to_non_nullable
as String,creditAmount: null == creditAmount ? _self.creditAmount : creditAmount // ignore: cast_nullable_to_non_nullable
as double,debitAmount: null == debitAmount ? _self.debitAmount : debitAmount // ignore: cast_nullable_to_non_nullable
as double,creditAvailable: freezed == creditAvailable ? _self.creditAvailable : creditAvailable // ignore: cast_nullable_to_non_nullable
as double?,paidDate: null == paidDate ? _self.paidDate : paidDate // ignore: cast_nullable_to_non_nullable
as DateTime,paymentType: null == paymentType ? _self.paymentType : paymentType // ignore: cast_nullable_to_non_nullable
as int,productType: null == productType ? _self.productType : productType // ignore: cast_nullable_to_non_nullable
as int,cancelledDate: freezed == cancelledDate ? _self.cancelledDate : cancelledDate // ignore: cast_nullable_to_non_nullable
as DateTime?,cancelledBy: freezed == cancelledBy ? _self.cancelledBy : cancelledBy // ignore: cast_nullable_to_non_nullable
as String?,confirmedDate: freezed == confirmedDate ? _self.confirmedDate : confirmedDate // ignore: cast_nullable_to_non_nullable
as DateTime?,confirmedBy: freezed == confirmedBy ? _self.confirmedBy : confirmedBy // ignore: cast_nullable_to_non_nullable
as String?,paymentReference: freezed == paymentReference ? _self.paymentReference : paymentReference // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,doPayForExtras: null == doPayForExtras ? _self.doPayForExtras : doPayForExtras // ignore: cast_nullable_to_non_nullable
as int,surcharge: null == surcharge ? _self.surcharge : surcharge // ignore: cast_nullable_to_non_nullable
as double,paymentProvider: freezed == paymentProvider ? _self.paymentProvider : paymentProvider // ignore: cast_nullable_to_non_nullable
as String?,discountAmount: null == discountAmount ? _self.discountAmount : discountAmount // ignore: cast_nullable_to_non_nullable
as double,discountPercent: null == discountPercent ? _self.discountPercent : discountPercent // ignore: cast_nullable_to_non_nullable
as int,discountDescription: null == discountDescription ? _self.discountDescription : discountDescription // ignore: cast_nullable_to_non_nullable
as String,specialRunPriceReason: null == specialRunPriceReason ? _self.specialRunPriceReason : specialRunPriceReason // ignore: cast_nullable_to_non_nullable
as String,removed: freezed == removed ? _self.removed : removed // ignore: cast_nullable_to_non_nullable
as int?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [PaymentsModel].
extension PaymentsModelPatterns on PaymentsModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PaymentsModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PaymentsModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PaymentsModel value)  $default,){
final _that = this;
switch (_that) {
case _PaymentsModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PaymentsModel value)?  $default,){
final _that = this;
switch (_that) {
case _PaymentsModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String paymentId,  String kennelId,  String paidBy,  String hemId,  String eventId,  String paidTo,  double creditAmount,  double debitAmount,  double? creditAvailable,  DateTime paidDate,  int paymentType,  int productType,  DateTime? cancelledDate,  String? cancelledBy,  DateTime? confirmedDate,  String? confirmedBy,  String? paymentReference,  String? notes,  int doPayForExtras,  double surcharge,  String? paymentProvider,  double discountAmount,  int discountPercent,  String discountDescription,  String specialRunPriceReason,  int? removed,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PaymentsModel() when $default != null:
return $default(_that.paymentId,_that.kennelId,_that.paidBy,_that.hemId,_that.eventId,_that.paidTo,_that.creditAmount,_that.debitAmount,_that.creditAvailable,_that.paidDate,_that.paymentType,_that.productType,_that.cancelledDate,_that.cancelledBy,_that.confirmedDate,_that.confirmedBy,_that.paymentReference,_that.notes,_that.doPayForExtras,_that.surcharge,_that.paymentProvider,_that.discountAmount,_that.discountPercent,_that.discountDescription,_that.specialRunPriceReason,_that.removed,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String paymentId,  String kennelId,  String paidBy,  String hemId,  String eventId,  String paidTo,  double creditAmount,  double debitAmount,  double? creditAvailable,  DateTime paidDate,  int paymentType,  int productType,  DateTime? cancelledDate,  String? cancelledBy,  DateTime? confirmedDate,  String? confirmedBy,  String? paymentReference,  String? notes,  int doPayForExtras,  double surcharge,  String? paymentProvider,  double discountAmount,  int discountPercent,  String discountDescription,  String specialRunPriceReason,  int? removed,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _PaymentsModel():
return $default(_that.paymentId,_that.kennelId,_that.paidBy,_that.hemId,_that.eventId,_that.paidTo,_that.creditAmount,_that.debitAmount,_that.creditAvailable,_that.paidDate,_that.paymentType,_that.productType,_that.cancelledDate,_that.cancelledBy,_that.confirmedDate,_that.confirmedBy,_that.paymentReference,_that.notes,_that.doPayForExtras,_that.surcharge,_that.paymentProvider,_that.discountAmount,_that.discountPercent,_that.discountDescription,_that.specialRunPriceReason,_that.removed,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String paymentId,  String kennelId,  String paidBy,  String hemId,  String eventId,  String paidTo,  double creditAmount,  double debitAmount,  double? creditAvailable,  DateTime paidDate,  int paymentType,  int productType,  DateTime? cancelledDate,  String? cancelledBy,  DateTime? confirmedDate,  String? confirmedBy,  String? paymentReference,  String? notes,  int doPayForExtras,  double surcharge,  String? paymentProvider,  double discountAmount,  int discountPercent,  String discountDescription,  String specialRunPriceReason,  int? removed,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _PaymentsModel() when $default != null:
return $default(_that.paymentId,_that.kennelId,_that.paidBy,_that.hemId,_that.eventId,_that.paidTo,_that.creditAmount,_that.debitAmount,_that.creditAvailable,_that.paidDate,_that.paymentType,_that.productType,_that.cancelledDate,_that.cancelledBy,_that.confirmedDate,_that.confirmedBy,_that.paymentReference,_that.notes,_that.doPayForExtras,_that.surcharge,_that.paymentProvider,_that.discountAmount,_that.discountPercent,_that.discountDescription,_that.specialRunPriceReason,_that.removed,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PaymentsModel with DiagnosticableTreeMixin implements PaymentsModel {
   _PaymentsModel({required this.paymentId, required this.kennelId, required this.paidBy, required this.hemId, required this.eventId, required this.paidTo, required this.creditAmount, required this.debitAmount, this.creditAvailable, required this.paidDate, required this.paymentType, required this.productType, this.cancelledDate, this.cancelledBy, this.confirmedDate, this.confirmedBy, this.paymentReference, this.notes, required this.doPayForExtras, required this.surcharge, this.paymentProvider, required this.discountAmount, required this.discountPercent, required this.discountDescription, required this.specialRunPriceReason, this.removed, this.updatedAt});
  factory _PaymentsModel.fromJson(Map<String, dynamic> json) => _$PaymentsModelFromJson(json);

@override final  String paymentId;
@override final  String kennelId;
@override final  String paidBy;
@override final  String hemId;
@override final  String eventId;
@override final  String paidTo;
@override final  double creditAmount;
@override final  double debitAmount;
@override final  double? creditAvailable;
@override final  DateTime paidDate;
@override final  int paymentType;
@override final  int productType;
@override final  DateTime? cancelledDate;
@override final  String? cancelledBy;
@override final  DateTime? confirmedDate;
@override final  String? confirmedBy;
@override final  String? paymentReference;
@override final  String? notes;
@override final  int doPayForExtras;
@override final  double surcharge;
@override final  String? paymentProvider;
@override final  double discountAmount;
@override final  int discountPercent;
@override final  String discountDescription;
@override final  String specialRunPriceReason;
@override final  int? removed;
@override final  DateTime? updatedAt;

/// Create a copy of PaymentsModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PaymentsModelCopyWith<_PaymentsModel> get copyWith => __$PaymentsModelCopyWithImpl<_PaymentsModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PaymentsModelToJson(this, );
}
@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'PaymentsModel'))
    ..add(DiagnosticsProperty('paymentId', paymentId))..add(DiagnosticsProperty('kennelId', kennelId))..add(DiagnosticsProperty('paidBy', paidBy))..add(DiagnosticsProperty('hemId', hemId))..add(DiagnosticsProperty('eventId', eventId))..add(DiagnosticsProperty('paidTo', paidTo))..add(DiagnosticsProperty('creditAmount', creditAmount))..add(DiagnosticsProperty('debitAmount', debitAmount))..add(DiagnosticsProperty('creditAvailable', creditAvailable))..add(DiagnosticsProperty('paidDate', paidDate))..add(DiagnosticsProperty('paymentType', paymentType))..add(DiagnosticsProperty('productType', productType))..add(DiagnosticsProperty('cancelledDate', cancelledDate))..add(DiagnosticsProperty('cancelledBy', cancelledBy))..add(DiagnosticsProperty('confirmedDate', confirmedDate))..add(DiagnosticsProperty('confirmedBy', confirmedBy))..add(DiagnosticsProperty('paymentReference', paymentReference))..add(DiagnosticsProperty('notes', notes))..add(DiagnosticsProperty('doPayForExtras', doPayForExtras))..add(DiagnosticsProperty('surcharge', surcharge))..add(DiagnosticsProperty('paymentProvider', paymentProvider))..add(DiagnosticsProperty('discountAmount', discountAmount))..add(DiagnosticsProperty('discountPercent', discountPercent))..add(DiagnosticsProperty('discountDescription', discountDescription))..add(DiagnosticsProperty('specialRunPriceReason', specialRunPriceReason))..add(DiagnosticsProperty('removed', removed))..add(DiagnosticsProperty('updatedAt', updatedAt));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PaymentsModel&&(identical(other.paymentId, paymentId) || other.paymentId == paymentId)&&(identical(other.kennelId, kennelId) || other.kennelId == kennelId)&&(identical(other.paidBy, paidBy) || other.paidBy == paidBy)&&(identical(other.hemId, hemId) || other.hemId == hemId)&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.paidTo, paidTo) || other.paidTo == paidTo)&&(identical(other.creditAmount, creditAmount) || other.creditAmount == creditAmount)&&(identical(other.debitAmount, debitAmount) || other.debitAmount == debitAmount)&&(identical(other.creditAvailable, creditAvailable) || other.creditAvailable == creditAvailable)&&(identical(other.paidDate, paidDate) || other.paidDate == paidDate)&&(identical(other.paymentType, paymentType) || other.paymentType == paymentType)&&(identical(other.productType, productType) || other.productType == productType)&&(identical(other.cancelledDate, cancelledDate) || other.cancelledDate == cancelledDate)&&(identical(other.cancelledBy, cancelledBy) || other.cancelledBy == cancelledBy)&&(identical(other.confirmedDate, confirmedDate) || other.confirmedDate == confirmedDate)&&(identical(other.confirmedBy, confirmedBy) || other.confirmedBy == confirmedBy)&&(identical(other.paymentReference, paymentReference) || other.paymentReference == paymentReference)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.doPayForExtras, doPayForExtras) || other.doPayForExtras == doPayForExtras)&&(identical(other.surcharge, surcharge) || other.surcharge == surcharge)&&(identical(other.paymentProvider, paymentProvider) || other.paymentProvider == paymentProvider)&&(identical(other.discountAmount, discountAmount) || other.discountAmount == discountAmount)&&(identical(other.discountPercent, discountPercent) || other.discountPercent == discountPercent)&&(identical(other.discountDescription, discountDescription) || other.discountDescription == discountDescription)&&(identical(other.specialRunPriceReason, specialRunPriceReason) || other.specialRunPriceReason == specialRunPriceReason)&&(identical(other.removed, removed) || other.removed == removed)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,paymentId,kennelId,paidBy,hemId,eventId,paidTo,creditAmount,debitAmount,creditAvailable,paidDate,paymentType,productType,cancelledDate,cancelledBy,confirmedDate,confirmedBy,paymentReference,notes,doPayForExtras,surcharge,paymentProvider,discountAmount,discountPercent,discountDescription,specialRunPriceReason,removed,updatedAt]);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'PaymentsModel(paymentId: $paymentId, kennelId: $kennelId, paidBy: $paidBy, hemId: $hemId, eventId: $eventId, paidTo: $paidTo, creditAmount: $creditAmount, debitAmount: $debitAmount, creditAvailable: $creditAvailable, paidDate: $paidDate, paymentType: $paymentType, productType: $productType, cancelledDate: $cancelledDate, cancelledBy: $cancelledBy, confirmedDate: $confirmedDate, confirmedBy: $confirmedBy, paymentReference: $paymentReference, notes: $notes, doPayForExtras: $doPayForExtras, surcharge: $surcharge, paymentProvider: $paymentProvider, discountAmount: $discountAmount, discountPercent: $discountPercent, discountDescription: $discountDescription, specialRunPriceReason: $specialRunPriceReason, removed: $removed, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$PaymentsModelCopyWith<$Res> implements $PaymentsModelCopyWith<$Res> {
  factory _$PaymentsModelCopyWith(_PaymentsModel value, $Res Function(_PaymentsModel) _then) = __$PaymentsModelCopyWithImpl;
@override @useResult
$Res call({
 String paymentId, String kennelId, String paidBy, String hemId, String eventId, String paidTo, double creditAmount, double debitAmount, double? creditAvailable, DateTime paidDate, int paymentType, int productType, DateTime? cancelledDate, String? cancelledBy, DateTime? confirmedDate, String? confirmedBy, String? paymentReference, String? notes, int doPayForExtras, double surcharge, String? paymentProvider, double discountAmount, int discountPercent, String discountDescription, String specialRunPriceReason, int? removed, DateTime? updatedAt
});




}
/// @nodoc
class __$PaymentsModelCopyWithImpl<$Res>
    implements _$PaymentsModelCopyWith<$Res> {
  __$PaymentsModelCopyWithImpl(this._self, this._then);

  final _PaymentsModel _self;
  final $Res Function(_PaymentsModel) _then;

/// Create a copy of PaymentsModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? paymentId = null,Object? kennelId = null,Object? paidBy = null,Object? hemId = null,Object? eventId = null,Object? paidTo = null,Object? creditAmount = null,Object? debitAmount = null,Object? creditAvailable = freezed,Object? paidDate = null,Object? paymentType = null,Object? productType = null,Object? cancelledDate = freezed,Object? cancelledBy = freezed,Object? confirmedDate = freezed,Object? confirmedBy = freezed,Object? paymentReference = freezed,Object? notes = freezed,Object? doPayForExtras = null,Object? surcharge = null,Object? paymentProvider = freezed,Object? discountAmount = null,Object? discountPercent = null,Object? discountDescription = null,Object? specialRunPriceReason = null,Object? removed = freezed,Object? updatedAt = freezed,}) {
  return _then(_PaymentsModel(
paymentId: null == paymentId ? _self.paymentId : paymentId // ignore: cast_nullable_to_non_nullable
as String,kennelId: null == kennelId ? _self.kennelId : kennelId // ignore: cast_nullable_to_non_nullable
as String,paidBy: null == paidBy ? _self.paidBy : paidBy // ignore: cast_nullable_to_non_nullable
as String,hemId: null == hemId ? _self.hemId : hemId // ignore: cast_nullable_to_non_nullable
as String,eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,paidTo: null == paidTo ? _self.paidTo : paidTo // ignore: cast_nullable_to_non_nullable
as String,creditAmount: null == creditAmount ? _self.creditAmount : creditAmount // ignore: cast_nullable_to_non_nullable
as double,debitAmount: null == debitAmount ? _self.debitAmount : debitAmount // ignore: cast_nullable_to_non_nullable
as double,creditAvailable: freezed == creditAvailable ? _self.creditAvailable : creditAvailable // ignore: cast_nullable_to_non_nullable
as double?,paidDate: null == paidDate ? _self.paidDate : paidDate // ignore: cast_nullable_to_non_nullable
as DateTime,paymentType: null == paymentType ? _self.paymentType : paymentType // ignore: cast_nullable_to_non_nullable
as int,productType: null == productType ? _self.productType : productType // ignore: cast_nullable_to_non_nullable
as int,cancelledDate: freezed == cancelledDate ? _self.cancelledDate : cancelledDate // ignore: cast_nullable_to_non_nullable
as DateTime?,cancelledBy: freezed == cancelledBy ? _self.cancelledBy : cancelledBy // ignore: cast_nullable_to_non_nullable
as String?,confirmedDate: freezed == confirmedDate ? _self.confirmedDate : confirmedDate // ignore: cast_nullable_to_non_nullable
as DateTime?,confirmedBy: freezed == confirmedBy ? _self.confirmedBy : confirmedBy // ignore: cast_nullable_to_non_nullable
as String?,paymentReference: freezed == paymentReference ? _self.paymentReference : paymentReference // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,doPayForExtras: null == doPayForExtras ? _self.doPayForExtras : doPayForExtras // ignore: cast_nullable_to_non_nullable
as int,surcharge: null == surcharge ? _self.surcharge : surcharge // ignore: cast_nullable_to_non_nullable
as double,paymentProvider: freezed == paymentProvider ? _self.paymentProvider : paymentProvider // ignore: cast_nullable_to_non_nullable
as String?,discountAmount: null == discountAmount ? _self.discountAmount : discountAmount // ignore: cast_nullable_to_non_nullable
as double,discountPercent: null == discountPercent ? _self.discountPercent : discountPercent // ignore: cast_nullable_to_non_nullable
as int,discountDescription: null == discountDescription ? _self.discountDescription : discountDescription // ignore: cast_nullable_to_non_nullable
as String,specialRunPriceReason: null == specialRunPriceReason ? _self.specialRunPriceReason : specialRunPriceReason // ignore: cast_nullable_to_non_nullable
as String,removed: freezed == removed ? _self.removed : removed // ignore: cast_nullable_to_non_nullable
as int?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
