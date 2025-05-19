// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'payment_query_extensions_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PaymentQueryExtensionsModel implements DiagnosticableTreeMixin {

 String get pkHemId; String get paidByName; String get paidToName; int get isMember; double get creditAvailable; double get eventPriceForMembers; double get eventPriceForNonMembers; String? get confByName; double get extrasPrice; String? get extrasDescription; double get discountAmountAvailable; int get discountPercentAvailable; int get isFollowing; String? get discountAvailableDescription; bool get isHashCredit;
/// Create a copy of PaymentQueryExtensionsModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaymentQueryExtensionsModelCopyWith<PaymentQueryExtensionsModel> get copyWith => _$PaymentQueryExtensionsModelCopyWithImpl<PaymentQueryExtensionsModel>(this as PaymentQueryExtensionsModel, _$identity);

  /// Serializes this PaymentQueryExtensionsModel to a JSON map.
  Map<String, dynamic> toJson();

@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'PaymentQueryExtensionsModel'))
    ..add(DiagnosticsProperty('pkHemId', pkHemId))..add(DiagnosticsProperty('paidByName', paidByName))..add(DiagnosticsProperty('paidToName', paidToName))..add(DiagnosticsProperty('isMember', isMember))..add(DiagnosticsProperty('creditAvailable', creditAvailable))..add(DiagnosticsProperty('eventPriceForMembers', eventPriceForMembers))..add(DiagnosticsProperty('eventPriceForNonMembers', eventPriceForNonMembers))..add(DiagnosticsProperty('confByName', confByName))..add(DiagnosticsProperty('extrasPrice', extrasPrice))..add(DiagnosticsProperty('extrasDescription', extrasDescription))..add(DiagnosticsProperty('discountAmountAvailable', discountAmountAvailable))..add(DiagnosticsProperty('discountPercentAvailable', discountPercentAvailable))..add(DiagnosticsProperty('isFollowing', isFollowing))..add(DiagnosticsProperty('discountAvailableDescription', discountAvailableDescription))..add(DiagnosticsProperty('isHashCredit', isHashCredit));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaymentQueryExtensionsModel&&(identical(other.pkHemId, pkHemId) || other.pkHemId == pkHemId)&&(identical(other.paidByName, paidByName) || other.paidByName == paidByName)&&(identical(other.paidToName, paidToName) || other.paidToName == paidToName)&&(identical(other.isMember, isMember) || other.isMember == isMember)&&(identical(other.creditAvailable, creditAvailable) || other.creditAvailable == creditAvailable)&&(identical(other.eventPriceForMembers, eventPriceForMembers) || other.eventPriceForMembers == eventPriceForMembers)&&(identical(other.eventPriceForNonMembers, eventPriceForNonMembers) || other.eventPriceForNonMembers == eventPriceForNonMembers)&&(identical(other.confByName, confByName) || other.confByName == confByName)&&(identical(other.extrasPrice, extrasPrice) || other.extrasPrice == extrasPrice)&&(identical(other.extrasDescription, extrasDescription) || other.extrasDescription == extrasDescription)&&(identical(other.discountAmountAvailable, discountAmountAvailable) || other.discountAmountAvailable == discountAmountAvailable)&&(identical(other.discountPercentAvailable, discountPercentAvailable) || other.discountPercentAvailable == discountPercentAvailable)&&(identical(other.isFollowing, isFollowing) || other.isFollowing == isFollowing)&&(identical(other.discountAvailableDescription, discountAvailableDescription) || other.discountAvailableDescription == discountAvailableDescription)&&(identical(other.isHashCredit, isHashCredit) || other.isHashCredit == isHashCredit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,pkHemId,paidByName,paidToName,isMember,creditAvailable,eventPriceForMembers,eventPriceForNonMembers,confByName,extrasPrice,extrasDescription,discountAmountAvailable,discountPercentAvailable,isFollowing,discountAvailableDescription,isHashCredit);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'PaymentQueryExtensionsModel(pkHemId: $pkHemId, paidByName: $paidByName, paidToName: $paidToName, isMember: $isMember, creditAvailable: $creditAvailable, eventPriceForMembers: $eventPriceForMembers, eventPriceForNonMembers: $eventPriceForNonMembers, confByName: $confByName, extrasPrice: $extrasPrice, extrasDescription: $extrasDescription, discountAmountAvailable: $discountAmountAvailable, discountPercentAvailable: $discountPercentAvailable, isFollowing: $isFollowing, discountAvailableDescription: $discountAvailableDescription, isHashCredit: $isHashCredit)';
}


}

/// @nodoc
abstract mixin class $PaymentQueryExtensionsModelCopyWith<$Res>  {
  factory $PaymentQueryExtensionsModelCopyWith(PaymentQueryExtensionsModel value, $Res Function(PaymentQueryExtensionsModel) _then) = _$PaymentQueryExtensionsModelCopyWithImpl;
@useResult
$Res call({
 String pkHemId, String paidByName, String paidToName, int isMember, double creditAvailable, double eventPriceForMembers, double eventPriceForNonMembers, String? confByName, double extrasPrice, String? extrasDescription, double discountAmountAvailable, int discountPercentAvailable, int isFollowing, String? discountAvailableDescription, bool isHashCredit
});




}
/// @nodoc
class _$PaymentQueryExtensionsModelCopyWithImpl<$Res>
    implements $PaymentQueryExtensionsModelCopyWith<$Res> {
  _$PaymentQueryExtensionsModelCopyWithImpl(this._self, this._then);

  final PaymentQueryExtensionsModel _self;
  final $Res Function(PaymentQueryExtensionsModel) _then;

/// Create a copy of PaymentQueryExtensionsModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? pkHemId = null,Object? paidByName = null,Object? paidToName = null,Object? isMember = null,Object? creditAvailable = null,Object? eventPriceForMembers = null,Object? eventPriceForNonMembers = null,Object? confByName = freezed,Object? extrasPrice = null,Object? extrasDescription = freezed,Object? discountAmountAvailable = null,Object? discountPercentAvailable = null,Object? isFollowing = null,Object? discountAvailableDescription = freezed,Object? isHashCredit = null,}) {
  return _then(_self.copyWith(
pkHemId: null == pkHemId ? _self.pkHemId : pkHemId // ignore: cast_nullable_to_non_nullable
as String,paidByName: null == paidByName ? _self.paidByName : paidByName // ignore: cast_nullable_to_non_nullable
as String,paidToName: null == paidToName ? _self.paidToName : paidToName // ignore: cast_nullable_to_non_nullable
as String,isMember: null == isMember ? _self.isMember : isMember // ignore: cast_nullable_to_non_nullable
as int,creditAvailable: null == creditAvailable ? _self.creditAvailable : creditAvailable // ignore: cast_nullable_to_non_nullable
as double,eventPriceForMembers: null == eventPriceForMembers ? _self.eventPriceForMembers : eventPriceForMembers // ignore: cast_nullable_to_non_nullable
as double,eventPriceForNonMembers: null == eventPriceForNonMembers ? _self.eventPriceForNonMembers : eventPriceForNonMembers // ignore: cast_nullable_to_non_nullable
as double,confByName: freezed == confByName ? _self.confByName : confByName // ignore: cast_nullable_to_non_nullable
as String?,extrasPrice: null == extrasPrice ? _self.extrasPrice : extrasPrice // ignore: cast_nullable_to_non_nullable
as double,extrasDescription: freezed == extrasDescription ? _self.extrasDescription : extrasDescription // ignore: cast_nullable_to_non_nullable
as String?,discountAmountAvailable: null == discountAmountAvailable ? _self.discountAmountAvailable : discountAmountAvailable // ignore: cast_nullable_to_non_nullable
as double,discountPercentAvailable: null == discountPercentAvailable ? _self.discountPercentAvailable : discountPercentAvailable // ignore: cast_nullable_to_non_nullable
as int,isFollowing: null == isFollowing ? _self.isFollowing : isFollowing // ignore: cast_nullable_to_non_nullable
as int,discountAvailableDescription: freezed == discountAvailableDescription ? _self.discountAvailableDescription : discountAvailableDescription // ignore: cast_nullable_to_non_nullable
as String?,isHashCredit: null == isHashCredit ? _self.isHashCredit : isHashCredit // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _PaymentQueryExtensionsModel with DiagnosticableTreeMixin implements PaymentQueryExtensionsModel {
   _PaymentQueryExtensionsModel({required this.pkHemId, required this.paidByName, required this.paidToName, this.isMember = 0, this.creditAvailable = 0.0, this.eventPriceForMembers = 0.0, this.eventPriceForNonMembers = 0.0, this.confByName, this.extrasPrice = 0.0, this.extrasDescription, this.discountAmountAvailable = 0.0, this.discountPercentAvailable = 0, this.isFollowing = 0, this.discountAvailableDescription, this.isHashCredit = false});
  factory _PaymentQueryExtensionsModel.fromJson(Map<String, dynamic> json) => _$PaymentQueryExtensionsModelFromJson(json);

@override final  String pkHemId;
@override final  String paidByName;
@override final  String paidToName;
@override@JsonKey() final  int isMember;
@override@JsonKey() final  double creditAvailable;
@override@JsonKey() final  double eventPriceForMembers;
@override@JsonKey() final  double eventPriceForNonMembers;
@override final  String? confByName;
@override@JsonKey() final  double extrasPrice;
@override final  String? extrasDescription;
@override@JsonKey() final  double discountAmountAvailable;
@override@JsonKey() final  int discountPercentAvailable;
@override@JsonKey() final  int isFollowing;
@override final  String? discountAvailableDescription;
@override@JsonKey() final  bool isHashCredit;

/// Create a copy of PaymentQueryExtensionsModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PaymentQueryExtensionsModelCopyWith<_PaymentQueryExtensionsModel> get copyWith => __$PaymentQueryExtensionsModelCopyWithImpl<_PaymentQueryExtensionsModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PaymentQueryExtensionsModelToJson(this, );
}
@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'PaymentQueryExtensionsModel'))
    ..add(DiagnosticsProperty('pkHemId', pkHemId))..add(DiagnosticsProperty('paidByName', paidByName))..add(DiagnosticsProperty('paidToName', paidToName))..add(DiagnosticsProperty('isMember', isMember))..add(DiagnosticsProperty('creditAvailable', creditAvailable))..add(DiagnosticsProperty('eventPriceForMembers', eventPriceForMembers))..add(DiagnosticsProperty('eventPriceForNonMembers', eventPriceForNonMembers))..add(DiagnosticsProperty('confByName', confByName))..add(DiagnosticsProperty('extrasPrice', extrasPrice))..add(DiagnosticsProperty('extrasDescription', extrasDescription))..add(DiagnosticsProperty('discountAmountAvailable', discountAmountAvailable))..add(DiagnosticsProperty('discountPercentAvailable', discountPercentAvailable))..add(DiagnosticsProperty('isFollowing', isFollowing))..add(DiagnosticsProperty('discountAvailableDescription', discountAvailableDescription))..add(DiagnosticsProperty('isHashCredit', isHashCredit));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PaymentQueryExtensionsModel&&(identical(other.pkHemId, pkHemId) || other.pkHemId == pkHemId)&&(identical(other.paidByName, paidByName) || other.paidByName == paidByName)&&(identical(other.paidToName, paidToName) || other.paidToName == paidToName)&&(identical(other.isMember, isMember) || other.isMember == isMember)&&(identical(other.creditAvailable, creditAvailable) || other.creditAvailable == creditAvailable)&&(identical(other.eventPriceForMembers, eventPriceForMembers) || other.eventPriceForMembers == eventPriceForMembers)&&(identical(other.eventPriceForNonMembers, eventPriceForNonMembers) || other.eventPriceForNonMembers == eventPriceForNonMembers)&&(identical(other.confByName, confByName) || other.confByName == confByName)&&(identical(other.extrasPrice, extrasPrice) || other.extrasPrice == extrasPrice)&&(identical(other.extrasDescription, extrasDescription) || other.extrasDescription == extrasDescription)&&(identical(other.discountAmountAvailable, discountAmountAvailable) || other.discountAmountAvailable == discountAmountAvailable)&&(identical(other.discountPercentAvailable, discountPercentAvailable) || other.discountPercentAvailable == discountPercentAvailable)&&(identical(other.isFollowing, isFollowing) || other.isFollowing == isFollowing)&&(identical(other.discountAvailableDescription, discountAvailableDescription) || other.discountAvailableDescription == discountAvailableDescription)&&(identical(other.isHashCredit, isHashCredit) || other.isHashCredit == isHashCredit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,pkHemId,paidByName,paidToName,isMember,creditAvailable,eventPriceForMembers,eventPriceForNonMembers,confByName,extrasPrice,extrasDescription,discountAmountAvailable,discountPercentAvailable,isFollowing,discountAvailableDescription,isHashCredit);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'PaymentQueryExtensionsModel(pkHemId: $pkHemId, paidByName: $paidByName, paidToName: $paidToName, isMember: $isMember, creditAvailable: $creditAvailable, eventPriceForMembers: $eventPriceForMembers, eventPriceForNonMembers: $eventPriceForNonMembers, confByName: $confByName, extrasPrice: $extrasPrice, extrasDescription: $extrasDescription, discountAmountAvailable: $discountAmountAvailable, discountPercentAvailable: $discountPercentAvailable, isFollowing: $isFollowing, discountAvailableDescription: $discountAvailableDescription, isHashCredit: $isHashCredit)';
}


}

/// @nodoc
abstract mixin class _$PaymentQueryExtensionsModelCopyWith<$Res> implements $PaymentQueryExtensionsModelCopyWith<$Res> {
  factory _$PaymentQueryExtensionsModelCopyWith(_PaymentQueryExtensionsModel value, $Res Function(_PaymentQueryExtensionsModel) _then) = __$PaymentQueryExtensionsModelCopyWithImpl;
@override @useResult
$Res call({
 String pkHemId, String paidByName, String paidToName, int isMember, double creditAvailable, double eventPriceForMembers, double eventPriceForNonMembers, String? confByName, double extrasPrice, String? extrasDescription, double discountAmountAvailable, int discountPercentAvailable, int isFollowing, String? discountAvailableDescription, bool isHashCredit
});




}
/// @nodoc
class __$PaymentQueryExtensionsModelCopyWithImpl<$Res>
    implements _$PaymentQueryExtensionsModelCopyWith<$Res> {
  __$PaymentQueryExtensionsModelCopyWithImpl(this._self, this._then);

  final _PaymentQueryExtensionsModel _self;
  final $Res Function(_PaymentQueryExtensionsModel) _then;

/// Create a copy of PaymentQueryExtensionsModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? pkHemId = null,Object? paidByName = null,Object? paidToName = null,Object? isMember = null,Object? creditAvailable = null,Object? eventPriceForMembers = null,Object? eventPriceForNonMembers = null,Object? confByName = freezed,Object? extrasPrice = null,Object? extrasDescription = freezed,Object? discountAmountAvailable = null,Object? discountPercentAvailable = null,Object? isFollowing = null,Object? discountAvailableDescription = freezed,Object? isHashCredit = null,}) {
  return _then(_PaymentQueryExtensionsModel(
pkHemId: null == pkHemId ? _self.pkHemId : pkHemId // ignore: cast_nullable_to_non_nullable
as String,paidByName: null == paidByName ? _self.paidByName : paidByName // ignore: cast_nullable_to_non_nullable
as String,paidToName: null == paidToName ? _self.paidToName : paidToName // ignore: cast_nullable_to_non_nullable
as String,isMember: null == isMember ? _self.isMember : isMember // ignore: cast_nullable_to_non_nullable
as int,creditAvailable: null == creditAvailable ? _self.creditAvailable : creditAvailable // ignore: cast_nullable_to_non_nullable
as double,eventPriceForMembers: null == eventPriceForMembers ? _self.eventPriceForMembers : eventPriceForMembers // ignore: cast_nullable_to_non_nullable
as double,eventPriceForNonMembers: null == eventPriceForNonMembers ? _self.eventPriceForNonMembers : eventPriceForNonMembers // ignore: cast_nullable_to_non_nullable
as double,confByName: freezed == confByName ? _self.confByName : confByName // ignore: cast_nullable_to_non_nullable
as String?,extrasPrice: null == extrasPrice ? _self.extrasPrice : extrasPrice // ignore: cast_nullable_to_non_nullable
as double,extrasDescription: freezed == extrasDescription ? _self.extrasDescription : extrasDescription // ignore: cast_nullable_to_non_nullable
as String?,discountAmountAvailable: null == discountAmountAvailable ? _self.discountAmountAvailable : discountAmountAvailable // ignore: cast_nullable_to_non_nullable
as double,discountPercentAvailable: null == discountPercentAvailable ? _self.discountPercentAvailable : discountPercentAvailable // ignore: cast_nullable_to_non_nullable
as int,isFollowing: null == isFollowing ? _self.isFollowing : isFollowing // ignore: cast_nullable_to_non_nullable
as int,discountAvailableDescription: freezed == discountAvailableDescription ? _self.discountAvailableDescription : discountAvailableDescription // ignore: cast_nullable_to_non_nullable
as String?,isHashCredit: null == isHashCredit ? _self.isHashCredit : isHashCredit // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
