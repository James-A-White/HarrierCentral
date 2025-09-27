// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'countries_model_ns.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CountriesModel implements DiagnosticableTreeMixin {

 String get countryId; String get countryCode; double get latitude; double get longitude; String get countryName; String? get countrySearchTags; String get continentCode; String? get flagFile; String get currencyCode; String get primaryCultureCode; int get showRegion; String? get currencySymbol; int? get digitsAfterDecimal; int? get distancePreference; int? get removed; DateTime? get updatedAt;
/// Create a copy of CountriesModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CountriesModelCopyWith<CountriesModel> get copyWith => _$CountriesModelCopyWithImpl<CountriesModel>(this as CountriesModel, _$identity);

  /// Serializes this CountriesModel to a JSON map.
  Map<String, dynamic> toJson();

@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'CountriesModel'))
    ..add(DiagnosticsProperty('countryId', countryId))..add(DiagnosticsProperty('countryCode', countryCode))..add(DiagnosticsProperty('latitude', latitude))..add(DiagnosticsProperty('longitude', longitude))..add(DiagnosticsProperty('countryName', countryName))..add(DiagnosticsProperty('countrySearchTags', countrySearchTags))..add(DiagnosticsProperty('continentCode', continentCode))..add(DiagnosticsProperty('flagFile', flagFile))..add(DiagnosticsProperty('currencyCode', currencyCode))..add(DiagnosticsProperty('primaryCultureCode', primaryCultureCode))..add(DiagnosticsProperty('showRegion', showRegion))..add(DiagnosticsProperty('currencySymbol', currencySymbol))..add(DiagnosticsProperty('digitsAfterDecimal', digitsAfterDecimal))..add(DiagnosticsProperty('distancePreference', distancePreference))..add(DiagnosticsProperty('removed', removed))..add(DiagnosticsProperty('updatedAt', updatedAt));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CountriesModel&&(identical(other.countryId, countryId) || other.countryId == countryId)&&(identical(other.countryCode, countryCode) || other.countryCode == countryCode)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.countryName, countryName) || other.countryName == countryName)&&(identical(other.countrySearchTags, countrySearchTags) || other.countrySearchTags == countrySearchTags)&&(identical(other.continentCode, continentCode) || other.continentCode == continentCode)&&(identical(other.flagFile, flagFile) || other.flagFile == flagFile)&&(identical(other.currencyCode, currencyCode) || other.currencyCode == currencyCode)&&(identical(other.primaryCultureCode, primaryCultureCode) || other.primaryCultureCode == primaryCultureCode)&&(identical(other.showRegion, showRegion) || other.showRegion == showRegion)&&(identical(other.currencySymbol, currencySymbol) || other.currencySymbol == currencySymbol)&&(identical(other.digitsAfterDecimal, digitsAfterDecimal) || other.digitsAfterDecimal == digitsAfterDecimal)&&(identical(other.distancePreference, distancePreference) || other.distancePreference == distancePreference)&&(identical(other.removed, removed) || other.removed == removed)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,countryId,countryCode,latitude,longitude,countryName,countrySearchTags,continentCode,flagFile,currencyCode,primaryCultureCode,showRegion,currencySymbol,digitsAfterDecimal,distancePreference,removed,updatedAt);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'CountriesModel(countryId: $countryId, countryCode: $countryCode, latitude: $latitude, longitude: $longitude, countryName: $countryName, countrySearchTags: $countrySearchTags, continentCode: $continentCode, flagFile: $flagFile, currencyCode: $currencyCode, primaryCultureCode: $primaryCultureCode, showRegion: $showRegion, currencySymbol: $currencySymbol, digitsAfterDecimal: $digitsAfterDecimal, distancePreference: $distancePreference, removed: $removed, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $CountriesModelCopyWith<$Res>  {
  factory $CountriesModelCopyWith(CountriesModel value, $Res Function(CountriesModel) _then) = _$CountriesModelCopyWithImpl;
@useResult
$Res call({
 String countryId, String countryCode, double latitude, double longitude, String countryName, String? countrySearchTags, String continentCode, String? flagFile, String currencyCode, String primaryCultureCode, int showRegion, String? currencySymbol, int? digitsAfterDecimal, int? distancePreference, int? removed, DateTime? updatedAt
});




}
/// @nodoc
class _$CountriesModelCopyWithImpl<$Res>
    implements $CountriesModelCopyWith<$Res> {
  _$CountriesModelCopyWithImpl(this._self, this._then);

  final CountriesModel _self;
  final $Res Function(CountriesModel) _then;

/// Create a copy of CountriesModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? countryId = null,Object? countryCode = null,Object? latitude = null,Object? longitude = null,Object? countryName = null,Object? countrySearchTags = freezed,Object? continentCode = null,Object? flagFile = freezed,Object? currencyCode = null,Object? primaryCultureCode = null,Object? showRegion = null,Object? currencySymbol = freezed,Object? digitsAfterDecimal = freezed,Object? distancePreference = freezed,Object? removed = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
countryId: null == countryId ? _self.countryId : countryId // ignore: cast_nullable_to_non_nullable
as String,countryCode: null == countryCode ? _self.countryCode : countryCode // ignore: cast_nullable_to_non_nullable
as String,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,countryName: null == countryName ? _self.countryName : countryName // ignore: cast_nullable_to_non_nullable
as String,countrySearchTags: freezed == countrySearchTags ? _self.countrySearchTags : countrySearchTags // ignore: cast_nullable_to_non_nullable
as String?,continentCode: null == continentCode ? _self.continentCode : continentCode // ignore: cast_nullable_to_non_nullable
as String,flagFile: freezed == flagFile ? _self.flagFile : flagFile // ignore: cast_nullable_to_non_nullable
as String?,currencyCode: null == currencyCode ? _self.currencyCode : currencyCode // ignore: cast_nullable_to_non_nullable
as String,primaryCultureCode: null == primaryCultureCode ? _self.primaryCultureCode : primaryCultureCode // ignore: cast_nullable_to_non_nullable
as String,showRegion: null == showRegion ? _self.showRegion : showRegion // ignore: cast_nullable_to_non_nullable
as int,currencySymbol: freezed == currencySymbol ? _self.currencySymbol : currencySymbol // ignore: cast_nullable_to_non_nullable
as String?,digitsAfterDecimal: freezed == digitsAfterDecimal ? _self.digitsAfterDecimal : digitsAfterDecimal // ignore: cast_nullable_to_non_nullable
as int?,distancePreference: freezed == distancePreference ? _self.distancePreference : distancePreference // ignore: cast_nullable_to_non_nullable
as int?,removed: freezed == removed ? _self.removed : removed // ignore: cast_nullable_to_non_nullable
as int?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [CountriesModel].
extension CountriesModelPatterns on CountriesModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CountriesModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CountriesModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CountriesModel value)  $default,){
final _that = this;
switch (_that) {
case _CountriesModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CountriesModel value)?  $default,){
final _that = this;
switch (_that) {
case _CountriesModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String countryId,  String countryCode,  double latitude,  double longitude,  String countryName,  String? countrySearchTags,  String continentCode,  String? flagFile,  String currencyCode,  String primaryCultureCode,  int showRegion,  String? currencySymbol,  int? digitsAfterDecimal,  int? distancePreference,  int? removed,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CountriesModel() when $default != null:
return $default(_that.countryId,_that.countryCode,_that.latitude,_that.longitude,_that.countryName,_that.countrySearchTags,_that.continentCode,_that.flagFile,_that.currencyCode,_that.primaryCultureCode,_that.showRegion,_that.currencySymbol,_that.digitsAfterDecimal,_that.distancePreference,_that.removed,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String countryId,  String countryCode,  double latitude,  double longitude,  String countryName,  String? countrySearchTags,  String continentCode,  String? flagFile,  String currencyCode,  String primaryCultureCode,  int showRegion,  String? currencySymbol,  int? digitsAfterDecimal,  int? distancePreference,  int? removed,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _CountriesModel():
return $default(_that.countryId,_that.countryCode,_that.latitude,_that.longitude,_that.countryName,_that.countrySearchTags,_that.continentCode,_that.flagFile,_that.currencyCode,_that.primaryCultureCode,_that.showRegion,_that.currencySymbol,_that.digitsAfterDecimal,_that.distancePreference,_that.removed,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String countryId,  String countryCode,  double latitude,  double longitude,  String countryName,  String? countrySearchTags,  String continentCode,  String? flagFile,  String currencyCode,  String primaryCultureCode,  int showRegion,  String? currencySymbol,  int? digitsAfterDecimal,  int? distancePreference,  int? removed,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _CountriesModel() when $default != null:
return $default(_that.countryId,_that.countryCode,_that.latitude,_that.longitude,_that.countryName,_that.countrySearchTags,_that.continentCode,_that.flagFile,_that.currencyCode,_that.primaryCultureCode,_that.showRegion,_that.currencySymbol,_that.digitsAfterDecimal,_that.distancePreference,_that.removed,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CountriesModel with DiagnosticableTreeMixin implements CountriesModel {
   _CountriesModel({required this.countryId, required this.countryCode, required this.latitude, required this.longitude, required this.countryName, this.countrySearchTags, required this.continentCode, this.flagFile, required this.currencyCode, required this.primaryCultureCode, required this.showRegion, this.currencySymbol, this.digitsAfterDecimal, this.distancePreference, this.removed, this.updatedAt});
  factory _CountriesModel.fromJson(Map<String, dynamic> json) => _$CountriesModelFromJson(json);

@override final  String countryId;
@override final  String countryCode;
@override final  double latitude;
@override final  double longitude;
@override final  String countryName;
@override final  String? countrySearchTags;
@override final  String continentCode;
@override final  String? flagFile;
@override final  String currencyCode;
@override final  String primaryCultureCode;
@override final  int showRegion;
@override final  String? currencySymbol;
@override final  int? digitsAfterDecimal;
@override final  int? distancePreference;
@override final  int? removed;
@override final  DateTime? updatedAt;

/// Create a copy of CountriesModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CountriesModelCopyWith<_CountriesModel> get copyWith => __$CountriesModelCopyWithImpl<_CountriesModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CountriesModelToJson(this, );
}
@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'CountriesModel'))
    ..add(DiagnosticsProperty('countryId', countryId))..add(DiagnosticsProperty('countryCode', countryCode))..add(DiagnosticsProperty('latitude', latitude))..add(DiagnosticsProperty('longitude', longitude))..add(DiagnosticsProperty('countryName', countryName))..add(DiagnosticsProperty('countrySearchTags', countrySearchTags))..add(DiagnosticsProperty('continentCode', continentCode))..add(DiagnosticsProperty('flagFile', flagFile))..add(DiagnosticsProperty('currencyCode', currencyCode))..add(DiagnosticsProperty('primaryCultureCode', primaryCultureCode))..add(DiagnosticsProperty('showRegion', showRegion))..add(DiagnosticsProperty('currencySymbol', currencySymbol))..add(DiagnosticsProperty('digitsAfterDecimal', digitsAfterDecimal))..add(DiagnosticsProperty('distancePreference', distancePreference))..add(DiagnosticsProperty('removed', removed))..add(DiagnosticsProperty('updatedAt', updatedAt));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CountriesModel&&(identical(other.countryId, countryId) || other.countryId == countryId)&&(identical(other.countryCode, countryCode) || other.countryCode == countryCode)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.countryName, countryName) || other.countryName == countryName)&&(identical(other.countrySearchTags, countrySearchTags) || other.countrySearchTags == countrySearchTags)&&(identical(other.continentCode, continentCode) || other.continentCode == continentCode)&&(identical(other.flagFile, flagFile) || other.flagFile == flagFile)&&(identical(other.currencyCode, currencyCode) || other.currencyCode == currencyCode)&&(identical(other.primaryCultureCode, primaryCultureCode) || other.primaryCultureCode == primaryCultureCode)&&(identical(other.showRegion, showRegion) || other.showRegion == showRegion)&&(identical(other.currencySymbol, currencySymbol) || other.currencySymbol == currencySymbol)&&(identical(other.digitsAfterDecimal, digitsAfterDecimal) || other.digitsAfterDecimal == digitsAfterDecimal)&&(identical(other.distancePreference, distancePreference) || other.distancePreference == distancePreference)&&(identical(other.removed, removed) || other.removed == removed)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,countryId,countryCode,latitude,longitude,countryName,countrySearchTags,continentCode,flagFile,currencyCode,primaryCultureCode,showRegion,currencySymbol,digitsAfterDecimal,distancePreference,removed,updatedAt);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'CountriesModel(countryId: $countryId, countryCode: $countryCode, latitude: $latitude, longitude: $longitude, countryName: $countryName, countrySearchTags: $countrySearchTags, continentCode: $continentCode, flagFile: $flagFile, currencyCode: $currencyCode, primaryCultureCode: $primaryCultureCode, showRegion: $showRegion, currencySymbol: $currencySymbol, digitsAfterDecimal: $digitsAfterDecimal, distancePreference: $distancePreference, removed: $removed, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$CountriesModelCopyWith<$Res> implements $CountriesModelCopyWith<$Res> {
  factory _$CountriesModelCopyWith(_CountriesModel value, $Res Function(_CountriesModel) _then) = __$CountriesModelCopyWithImpl;
@override @useResult
$Res call({
 String countryId, String countryCode, double latitude, double longitude, String countryName, String? countrySearchTags, String continentCode, String? flagFile, String currencyCode, String primaryCultureCode, int showRegion, String? currencySymbol, int? digitsAfterDecimal, int? distancePreference, int? removed, DateTime? updatedAt
});




}
/// @nodoc
class __$CountriesModelCopyWithImpl<$Res>
    implements _$CountriesModelCopyWith<$Res> {
  __$CountriesModelCopyWithImpl(this._self, this._then);

  final _CountriesModel _self;
  final $Res Function(_CountriesModel) _then;

/// Create a copy of CountriesModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? countryId = null,Object? countryCode = null,Object? latitude = null,Object? longitude = null,Object? countryName = null,Object? countrySearchTags = freezed,Object? continentCode = null,Object? flagFile = freezed,Object? currencyCode = null,Object? primaryCultureCode = null,Object? showRegion = null,Object? currencySymbol = freezed,Object? digitsAfterDecimal = freezed,Object? distancePreference = freezed,Object? removed = freezed,Object? updatedAt = freezed,}) {
  return _then(_CountriesModel(
countryId: null == countryId ? _self.countryId : countryId // ignore: cast_nullable_to_non_nullable
as String,countryCode: null == countryCode ? _self.countryCode : countryCode // ignore: cast_nullable_to_non_nullable
as String,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,countryName: null == countryName ? _self.countryName : countryName // ignore: cast_nullable_to_non_nullable
as String,countrySearchTags: freezed == countrySearchTags ? _self.countrySearchTags : countrySearchTags // ignore: cast_nullable_to_non_nullable
as String?,continentCode: null == continentCode ? _self.continentCode : continentCode // ignore: cast_nullable_to_non_nullable
as String,flagFile: freezed == flagFile ? _self.flagFile : flagFile // ignore: cast_nullable_to_non_nullable
as String?,currencyCode: null == currencyCode ? _self.currencyCode : currencyCode // ignore: cast_nullable_to_non_nullable
as String,primaryCultureCode: null == primaryCultureCode ? _self.primaryCultureCode : primaryCultureCode // ignore: cast_nullable_to_non_nullable
as String,showRegion: null == showRegion ? _self.showRegion : showRegion // ignore: cast_nullable_to_non_nullable
as int,currencySymbol: freezed == currencySymbol ? _self.currencySymbol : currencySymbol // ignore: cast_nullable_to_non_nullable
as String?,digitsAfterDecimal: freezed == digitsAfterDecimal ? _self.digitsAfterDecimal : digitsAfterDecimal // ignore: cast_nullable_to_non_nullable
as int?,distancePreference: freezed == distancePreference ? _self.distancePreference : distancePreference // ignore: cast_nullable_to_non_nullable
as int?,removed: freezed == removed ? _self.removed : removed // ignore: cast_nullable_to_non_nullable
as int?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
