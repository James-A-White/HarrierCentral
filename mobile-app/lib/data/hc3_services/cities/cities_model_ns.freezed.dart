// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cities_model_ns.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CitiesModel implements DiagnosticableTreeMixin {

 String get cityId; String get cityName; String? get citySearchTags; String get regionId; double get latitude; double get longitude; String get cityAscii; String get ianaTimeZone; String? get flagFile; int? get removed; DateTime? get updatedAt;
/// Create a copy of CitiesModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CitiesModelCopyWith<CitiesModel> get copyWith => _$CitiesModelCopyWithImpl<CitiesModel>(this as CitiesModel, _$identity);

  /// Serializes this CitiesModel to a JSON map.
  Map<String, dynamic> toJson();

@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'CitiesModel'))
    ..add(DiagnosticsProperty('cityId', cityId))..add(DiagnosticsProperty('cityName', cityName))..add(DiagnosticsProperty('citySearchTags', citySearchTags))..add(DiagnosticsProperty('regionId', regionId))..add(DiagnosticsProperty('latitude', latitude))..add(DiagnosticsProperty('longitude', longitude))..add(DiagnosticsProperty('cityAscii', cityAscii))..add(DiagnosticsProperty('ianaTimeZone', ianaTimeZone))..add(DiagnosticsProperty('flagFile', flagFile))..add(DiagnosticsProperty('removed', removed))..add(DiagnosticsProperty('updatedAt', updatedAt));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CitiesModel&&(identical(other.cityId, cityId) || other.cityId == cityId)&&(identical(other.cityName, cityName) || other.cityName == cityName)&&(identical(other.citySearchTags, citySearchTags) || other.citySearchTags == citySearchTags)&&(identical(other.regionId, regionId) || other.regionId == regionId)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.cityAscii, cityAscii) || other.cityAscii == cityAscii)&&(identical(other.ianaTimeZone, ianaTimeZone) || other.ianaTimeZone == ianaTimeZone)&&(identical(other.flagFile, flagFile) || other.flagFile == flagFile)&&(identical(other.removed, removed) || other.removed == removed)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,cityId,cityName,citySearchTags,regionId,latitude,longitude,cityAscii,ianaTimeZone,flagFile,removed,updatedAt);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'CitiesModel(cityId: $cityId, cityName: $cityName, citySearchTags: $citySearchTags, regionId: $regionId, latitude: $latitude, longitude: $longitude, cityAscii: $cityAscii, ianaTimeZone: $ianaTimeZone, flagFile: $flagFile, removed: $removed, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $CitiesModelCopyWith<$Res>  {
  factory $CitiesModelCopyWith(CitiesModel value, $Res Function(CitiesModel) _then) = _$CitiesModelCopyWithImpl;
@useResult
$Res call({
 String cityId, String cityName, String? citySearchTags, String regionId, double latitude, double longitude, String cityAscii, String ianaTimeZone, String? flagFile, int? removed, DateTime? updatedAt
});




}
/// @nodoc
class _$CitiesModelCopyWithImpl<$Res>
    implements $CitiesModelCopyWith<$Res> {
  _$CitiesModelCopyWithImpl(this._self, this._then);

  final CitiesModel _self;
  final $Res Function(CitiesModel) _then;

/// Create a copy of CitiesModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? cityId = null,Object? cityName = null,Object? citySearchTags = freezed,Object? regionId = null,Object? latitude = null,Object? longitude = null,Object? cityAscii = null,Object? ianaTimeZone = null,Object? flagFile = freezed,Object? removed = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
cityId: null == cityId ? _self.cityId : cityId // ignore: cast_nullable_to_non_nullable
as String,cityName: null == cityName ? _self.cityName : cityName // ignore: cast_nullable_to_non_nullable
as String,citySearchTags: freezed == citySearchTags ? _self.citySearchTags : citySearchTags // ignore: cast_nullable_to_non_nullable
as String?,regionId: null == regionId ? _self.regionId : regionId // ignore: cast_nullable_to_non_nullable
as String,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,cityAscii: null == cityAscii ? _self.cityAscii : cityAscii // ignore: cast_nullable_to_non_nullable
as String,ianaTimeZone: null == ianaTimeZone ? _self.ianaTimeZone : ianaTimeZone // ignore: cast_nullable_to_non_nullable
as String,flagFile: freezed == flagFile ? _self.flagFile : flagFile // ignore: cast_nullable_to_non_nullable
as String?,removed: freezed == removed ? _self.removed : removed // ignore: cast_nullable_to_non_nullable
as int?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [CitiesModel].
extension CitiesModelPatterns on CitiesModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CitiesModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CitiesModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CitiesModel value)  $default,){
final _that = this;
switch (_that) {
case _CitiesModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CitiesModel value)?  $default,){
final _that = this;
switch (_that) {
case _CitiesModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String cityId,  String cityName,  String? citySearchTags,  String regionId,  double latitude,  double longitude,  String cityAscii,  String ianaTimeZone,  String? flagFile,  int? removed,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CitiesModel() when $default != null:
return $default(_that.cityId,_that.cityName,_that.citySearchTags,_that.regionId,_that.latitude,_that.longitude,_that.cityAscii,_that.ianaTimeZone,_that.flagFile,_that.removed,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String cityId,  String cityName,  String? citySearchTags,  String regionId,  double latitude,  double longitude,  String cityAscii,  String ianaTimeZone,  String? flagFile,  int? removed,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _CitiesModel():
return $default(_that.cityId,_that.cityName,_that.citySearchTags,_that.regionId,_that.latitude,_that.longitude,_that.cityAscii,_that.ianaTimeZone,_that.flagFile,_that.removed,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String cityId,  String cityName,  String? citySearchTags,  String regionId,  double latitude,  double longitude,  String cityAscii,  String ianaTimeZone,  String? flagFile,  int? removed,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _CitiesModel() when $default != null:
return $default(_that.cityId,_that.cityName,_that.citySearchTags,_that.regionId,_that.latitude,_that.longitude,_that.cityAscii,_that.ianaTimeZone,_that.flagFile,_that.removed,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CitiesModel with DiagnosticableTreeMixin implements CitiesModel {
  const _CitiesModel({required this.cityId, required this.cityName, this.citySearchTags, required this.regionId, required this.latitude, required this.longitude, required this.cityAscii, required this.ianaTimeZone, this.flagFile, this.removed, this.updatedAt});
  factory _CitiesModel.fromJson(Map<String, dynamic> json) => _$CitiesModelFromJson(json);

@override final  String cityId;
@override final  String cityName;
@override final  String? citySearchTags;
@override final  String regionId;
@override final  double latitude;
@override final  double longitude;
@override final  String cityAscii;
@override final  String ianaTimeZone;
@override final  String? flagFile;
@override final  int? removed;
@override final  DateTime? updatedAt;

/// Create a copy of CitiesModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CitiesModelCopyWith<_CitiesModel> get copyWith => __$CitiesModelCopyWithImpl<_CitiesModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CitiesModelToJson(this, );
}
@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'CitiesModel'))
    ..add(DiagnosticsProperty('cityId', cityId))..add(DiagnosticsProperty('cityName', cityName))..add(DiagnosticsProperty('citySearchTags', citySearchTags))..add(DiagnosticsProperty('regionId', regionId))..add(DiagnosticsProperty('latitude', latitude))..add(DiagnosticsProperty('longitude', longitude))..add(DiagnosticsProperty('cityAscii', cityAscii))..add(DiagnosticsProperty('ianaTimeZone', ianaTimeZone))..add(DiagnosticsProperty('flagFile', flagFile))..add(DiagnosticsProperty('removed', removed))..add(DiagnosticsProperty('updatedAt', updatedAt));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CitiesModel&&(identical(other.cityId, cityId) || other.cityId == cityId)&&(identical(other.cityName, cityName) || other.cityName == cityName)&&(identical(other.citySearchTags, citySearchTags) || other.citySearchTags == citySearchTags)&&(identical(other.regionId, regionId) || other.regionId == regionId)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.cityAscii, cityAscii) || other.cityAscii == cityAscii)&&(identical(other.ianaTimeZone, ianaTimeZone) || other.ianaTimeZone == ianaTimeZone)&&(identical(other.flagFile, flagFile) || other.flagFile == flagFile)&&(identical(other.removed, removed) || other.removed == removed)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,cityId,cityName,citySearchTags,regionId,latitude,longitude,cityAscii,ianaTimeZone,flagFile,removed,updatedAt);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'CitiesModel(cityId: $cityId, cityName: $cityName, citySearchTags: $citySearchTags, regionId: $regionId, latitude: $latitude, longitude: $longitude, cityAscii: $cityAscii, ianaTimeZone: $ianaTimeZone, flagFile: $flagFile, removed: $removed, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$CitiesModelCopyWith<$Res> implements $CitiesModelCopyWith<$Res> {
  factory _$CitiesModelCopyWith(_CitiesModel value, $Res Function(_CitiesModel) _then) = __$CitiesModelCopyWithImpl;
@override @useResult
$Res call({
 String cityId, String cityName, String? citySearchTags, String regionId, double latitude, double longitude, String cityAscii, String ianaTimeZone, String? flagFile, int? removed, DateTime? updatedAt
});




}
/// @nodoc
class __$CitiesModelCopyWithImpl<$Res>
    implements _$CitiesModelCopyWith<$Res> {
  __$CitiesModelCopyWithImpl(this._self, this._then);

  final _CitiesModel _self;
  final $Res Function(_CitiesModel) _then;

/// Create a copy of CitiesModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? cityId = null,Object? cityName = null,Object? citySearchTags = freezed,Object? regionId = null,Object? latitude = null,Object? longitude = null,Object? cityAscii = null,Object? ianaTimeZone = null,Object? flagFile = freezed,Object? removed = freezed,Object? updatedAt = freezed,}) {
  return _then(_CitiesModel(
cityId: null == cityId ? _self.cityId : cityId // ignore: cast_nullable_to_non_nullable
as String,cityName: null == cityName ? _self.cityName : cityName // ignore: cast_nullable_to_non_nullable
as String,citySearchTags: freezed == citySearchTags ? _self.citySearchTags : citySearchTags // ignore: cast_nullable_to_non_nullable
as String?,regionId: null == regionId ? _self.regionId : regionId // ignore: cast_nullable_to_non_nullable
as String,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,cityAscii: null == cityAscii ? _self.cityAscii : cityAscii // ignore: cast_nullable_to_non_nullable
as String,ianaTimeZone: null == ianaTimeZone ? _self.ianaTimeZone : ianaTimeZone // ignore: cast_nullable_to_non_nullable
as String,flagFile: freezed == flagFile ? _self.flagFile : flagFile // ignore: cast_nullable_to_non_nullable
as String?,removed: freezed == removed ? _self.removed : removed // ignore: cast_nullable_to_non_nullable
as int?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
