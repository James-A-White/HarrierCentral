// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_event_location.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserEventLocation implements DiagnosticableTreeMixin {

 String get timestamp; double get lat; double get lng; double get accuracy;
/// Create a copy of UserEventLocation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserEventLocationCopyWith<UserEventLocation> get copyWith => _$UserEventLocationCopyWithImpl<UserEventLocation>(this as UserEventLocation, _$identity);

  /// Serializes this UserEventLocation to a JSON map.
  Map<String, dynamic> toJson();

@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'UserEventLocation'))
    ..add(DiagnosticsProperty('timestamp', timestamp))..add(DiagnosticsProperty('lat', lat))..add(DiagnosticsProperty('lng', lng))..add(DiagnosticsProperty('accuracy', accuracy));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserEventLocation&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.accuracy, accuracy) || other.accuracy == accuracy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,timestamp,lat,lng,accuracy);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'UserEventLocation(timestamp: $timestamp, lat: $lat, lng: $lng, accuracy: $accuracy)';
}


}

/// @nodoc
abstract mixin class $UserEventLocationCopyWith<$Res>  {
  factory $UserEventLocationCopyWith(UserEventLocation value, $Res Function(UserEventLocation) _then) = _$UserEventLocationCopyWithImpl;
@useResult
$Res call({
 String timestamp, double lat, double lng, double accuracy
});




}
/// @nodoc
class _$UserEventLocationCopyWithImpl<$Res>
    implements $UserEventLocationCopyWith<$Res> {
  _$UserEventLocationCopyWithImpl(this._self, this._then);

  final UserEventLocation _self;
  final $Res Function(UserEventLocation) _then;

/// Create a copy of UserEventLocation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? timestamp = null,Object? lat = null,Object? lng = null,Object? accuracy = null,}) {
  return _then(_self.copyWith(
timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as String,lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,accuracy: null == accuracy ? _self.accuracy : accuracy // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [UserEventLocation].
extension UserEventLocationPatterns on UserEventLocation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserEventLocation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserEventLocation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserEventLocation value)  $default,){
final _that = this;
switch (_that) {
case _UserEventLocation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserEventLocation value)?  $default,){
final _that = this;
switch (_that) {
case _UserEventLocation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String timestamp,  double lat,  double lng,  double accuracy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserEventLocation() when $default != null:
return $default(_that.timestamp,_that.lat,_that.lng,_that.accuracy);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String timestamp,  double lat,  double lng,  double accuracy)  $default,) {final _that = this;
switch (_that) {
case _UserEventLocation():
return $default(_that.timestamp,_that.lat,_that.lng,_that.accuracy);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String timestamp,  double lat,  double lng,  double accuracy)?  $default,) {final _that = this;
switch (_that) {
case _UserEventLocation() when $default != null:
return $default(_that.timestamp,_that.lat,_that.lng,_that.accuracy);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserEventLocation with DiagnosticableTreeMixin implements UserEventLocation {
   _UserEventLocation({required this.timestamp, required this.lat, required this.lng, required this.accuracy});
  factory _UserEventLocation.fromJson(Map<String, dynamic> json) => _$UserEventLocationFromJson(json);

@override final  String timestamp;
@override final  double lat;
@override final  double lng;
@override final  double accuracy;

/// Create a copy of UserEventLocation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserEventLocationCopyWith<_UserEventLocation> get copyWith => __$UserEventLocationCopyWithImpl<_UserEventLocation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserEventLocationToJson(this, );
}
@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'UserEventLocation'))
    ..add(DiagnosticsProperty('timestamp', timestamp))..add(DiagnosticsProperty('lat', lat))..add(DiagnosticsProperty('lng', lng))..add(DiagnosticsProperty('accuracy', accuracy));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserEventLocation&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.accuracy, accuracy) || other.accuracy == accuracy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,timestamp,lat,lng,accuracy);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'UserEventLocation(timestamp: $timestamp, lat: $lat, lng: $lng, accuracy: $accuracy)';
}


}

/// @nodoc
abstract mixin class _$UserEventLocationCopyWith<$Res> implements $UserEventLocationCopyWith<$Res> {
  factory _$UserEventLocationCopyWith(_UserEventLocation value, $Res Function(_UserEventLocation) _then) = __$UserEventLocationCopyWithImpl;
@override @useResult
$Res call({
 String timestamp, double lat, double lng, double accuracy
});




}
/// @nodoc
class __$UserEventLocationCopyWithImpl<$Res>
    implements _$UserEventLocationCopyWith<$Res> {
  __$UserEventLocationCopyWithImpl(this._self, this._then);

  final _UserEventLocation _self;
  final $Res Function(_UserEventLocation) _then;

/// Create a copy of UserEventLocation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? timestamp = null,Object? lat = null,Object? lng = null,Object? accuracy = null,}) {
  return _then(_UserEventLocation(
timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as String,lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,accuracy: null == accuracy ? _self.accuracy : accuracy // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
