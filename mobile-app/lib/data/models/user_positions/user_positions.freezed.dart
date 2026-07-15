// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_positions.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserPositionsPayload {

 String get eventId; String? get latestServerTimestampMs;// Per-kennel PackTrack trail-type config JSON, bundled by GetPositions on
// the full fetch only (null on incremental polls — the client caches it).
 String? get trailTypesConfigJson;// Official run window (epoch-ms) derived server-side from the admin AST/AEN
// boundary markers. Null on the unbounded side / when no marker is set.
// Drives the admin trim editor's handles and lets the timeline clamp.
 int? get trimStartMs; int? get trimEndMs; List<UserTrack> get users;
/// Create a copy of UserPositionsPayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserPositionsPayloadCopyWith<UserPositionsPayload> get copyWith => _$UserPositionsPayloadCopyWithImpl<UserPositionsPayload>(this as UserPositionsPayload, _$identity);

  /// Serializes this UserPositionsPayload to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserPositionsPayload&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.latestServerTimestampMs, latestServerTimestampMs) || other.latestServerTimestampMs == latestServerTimestampMs)&&(identical(other.trailTypesConfigJson, trailTypesConfigJson) || other.trailTypesConfigJson == trailTypesConfigJson)&&(identical(other.trimStartMs, trimStartMs) || other.trimStartMs == trimStartMs)&&(identical(other.trimEndMs, trimEndMs) || other.trimEndMs == trimEndMs)&&const DeepCollectionEquality().equals(other.users, users));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,eventId,latestServerTimestampMs,trailTypesConfigJson,trimStartMs,trimEndMs,const DeepCollectionEquality().hash(users));

@override
String toString() {
  return 'UserPositionsPayload(eventId: $eventId, latestServerTimestampMs: $latestServerTimestampMs, trailTypesConfigJson: $trailTypesConfigJson, trimStartMs: $trimStartMs, trimEndMs: $trimEndMs, users: $users)';
}


}

/// @nodoc
abstract mixin class $UserPositionsPayloadCopyWith<$Res>  {
  factory $UserPositionsPayloadCopyWith(UserPositionsPayload value, $Res Function(UserPositionsPayload) _then) = _$UserPositionsPayloadCopyWithImpl;
@useResult
$Res call({
 String eventId, String? latestServerTimestampMs, String? trailTypesConfigJson, int? trimStartMs, int? trimEndMs, List<UserTrack> users
});




}
/// @nodoc
class _$UserPositionsPayloadCopyWithImpl<$Res>
    implements $UserPositionsPayloadCopyWith<$Res> {
  _$UserPositionsPayloadCopyWithImpl(this._self, this._then);

  final UserPositionsPayload _self;
  final $Res Function(UserPositionsPayload) _then;

/// Create a copy of UserPositionsPayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? eventId = null,Object? latestServerTimestampMs = freezed,Object? trailTypesConfigJson = freezed,Object? trimStartMs = freezed,Object? trimEndMs = freezed,Object? users = null,}) {
  return _then(_self.copyWith(
eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,latestServerTimestampMs: freezed == latestServerTimestampMs ? _self.latestServerTimestampMs : latestServerTimestampMs // ignore: cast_nullable_to_non_nullable
as String?,trailTypesConfigJson: freezed == trailTypesConfigJson ? _self.trailTypesConfigJson : trailTypesConfigJson // ignore: cast_nullable_to_non_nullable
as String?,trimStartMs: freezed == trimStartMs ? _self.trimStartMs : trimStartMs // ignore: cast_nullable_to_non_nullable
as int?,trimEndMs: freezed == trimEndMs ? _self.trimEndMs : trimEndMs // ignore: cast_nullable_to_non_nullable
as int?,users: null == users ? _self.users : users // ignore: cast_nullable_to_non_nullable
as List<UserTrack>,
  ));
}

}


/// Adds pattern-matching-related methods to [UserPositionsPayload].
extension UserPositionsPayloadPatterns on UserPositionsPayload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserPositionsPayload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserPositionsPayload() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserPositionsPayload value)  $default,){
final _that = this;
switch (_that) {
case _UserPositionsPayload():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserPositionsPayload value)?  $default,){
final _that = this;
switch (_that) {
case _UserPositionsPayload() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String eventId,  String? latestServerTimestampMs,  String? trailTypesConfigJson,  int? trimStartMs,  int? trimEndMs,  List<UserTrack> users)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserPositionsPayload() when $default != null:
return $default(_that.eventId,_that.latestServerTimestampMs,_that.trailTypesConfigJson,_that.trimStartMs,_that.trimEndMs,_that.users);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String eventId,  String? latestServerTimestampMs,  String? trailTypesConfigJson,  int? trimStartMs,  int? trimEndMs,  List<UserTrack> users)  $default,) {final _that = this;
switch (_that) {
case _UserPositionsPayload():
return $default(_that.eventId,_that.latestServerTimestampMs,_that.trailTypesConfigJson,_that.trimStartMs,_that.trimEndMs,_that.users);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String eventId,  String? latestServerTimestampMs,  String? trailTypesConfigJson,  int? trimStartMs,  int? trimEndMs,  List<UserTrack> users)?  $default,) {final _that = this;
switch (_that) {
case _UserPositionsPayload() when $default != null:
return $default(_that.eventId,_that.latestServerTimestampMs,_that.trailTypesConfigJson,_that.trimStartMs,_that.trimEndMs,_that.users);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserPositionsPayload implements UserPositionsPayload {
  const _UserPositionsPayload({required this.eventId, this.latestServerTimestampMs, this.trailTypesConfigJson, this.trimStartMs, this.trimEndMs, required final  List<UserTrack> users}): _users = users;
  factory _UserPositionsPayload.fromJson(Map<String, dynamic> json) => _$UserPositionsPayloadFromJson(json);

@override final  String eventId;
@override final  String? latestServerTimestampMs;
// Per-kennel PackTrack trail-type config JSON, bundled by GetPositions on
// the full fetch only (null on incremental polls — the client caches it).
@override final  String? trailTypesConfigJson;
// Official run window (epoch-ms) derived server-side from the admin AST/AEN
// boundary markers. Null on the unbounded side / when no marker is set.
// Drives the admin trim editor's handles and lets the timeline clamp.
@override final  int? trimStartMs;
@override final  int? trimEndMs;
 final  List<UserTrack> _users;
@override List<UserTrack> get users {
  if (_users is EqualUnmodifiableListView) return _users;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_users);
}


/// Create a copy of UserPositionsPayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserPositionsPayloadCopyWith<_UserPositionsPayload> get copyWith => __$UserPositionsPayloadCopyWithImpl<_UserPositionsPayload>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserPositionsPayloadToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserPositionsPayload&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.latestServerTimestampMs, latestServerTimestampMs) || other.latestServerTimestampMs == latestServerTimestampMs)&&(identical(other.trailTypesConfigJson, trailTypesConfigJson) || other.trailTypesConfigJson == trailTypesConfigJson)&&(identical(other.trimStartMs, trimStartMs) || other.trimStartMs == trimStartMs)&&(identical(other.trimEndMs, trimEndMs) || other.trimEndMs == trimEndMs)&&const DeepCollectionEquality().equals(other._users, _users));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,eventId,latestServerTimestampMs,trailTypesConfigJson,trimStartMs,trimEndMs,const DeepCollectionEquality().hash(_users));

@override
String toString() {
  return 'UserPositionsPayload(eventId: $eventId, latestServerTimestampMs: $latestServerTimestampMs, trailTypesConfigJson: $trailTypesConfigJson, trimStartMs: $trimStartMs, trimEndMs: $trimEndMs, users: $users)';
}


}

/// @nodoc
abstract mixin class _$UserPositionsPayloadCopyWith<$Res> implements $UserPositionsPayloadCopyWith<$Res> {
  factory _$UserPositionsPayloadCopyWith(_UserPositionsPayload value, $Res Function(_UserPositionsPayload) _then) = __$UserPositionsPayloadCopyWithImpl;
@override @useResult
$Res call({
 String eventId, String? latestServerTimestampMs, String? trailTypesConfigJson, int? trimStartMs, int? trimEndMs, List<UserTrack> users
});




}
/// @nodoc
class __$UserPositionsPayloadCopyWithImpl<$Res>
    implements _$UserPositionsPayloadCopyWith<$Res> {
  __$UserPositionsPayloadCopyWithImpl(this._self, this._then);

  final _UserPositionsPayload _self;
  final $Res Function(_UserPositionsPayload) _then;

/// Create a copy of UserPositionsPayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? eventId = null,Object? latestServerTimestampMs = freezed,Object? trailTypesConfigJson = freezed,Object? trimStartMs = freezed,Object? trimEndMs = freezed,Object? users = null,}) {
  return _then(_UserPositionsPayload(
eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,latestServerTimestampMs: freezed == latestServerTimestampMs ? _self.latestServerTimestampMs : latestServerTimestampMs // ignore: cast_nullable_to_non_nullable
as String?,trailTypesConfigJson: freezed == trailTypesConfigJson ? _self.trailTypesConfigJson : trailTypesConfigJson // ignore: cast_nullable_to_non_nullable
as String?,trimStartMs: freezed == trimStartMs ? _self.trimStartMs : trimStartMs // ignore: cast_nullable_to_non_nullable
as int?,trimEndMs: freezed == trimEndMs ? _self.trimEndMs : trimEndMs // ignore: cast_nullable_to_non_nullable
as int?,users: null == users ? _self._users : users // ignore: cast_nullable_to_non_nullable
as List<UserTrack>,
  ));
}


}


/// @nodoc
mixin _$UserTrack {

 String get id; List<TrackPoint> get positions;
/// Create a copy of UserTrack
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserTrackCopyWith<UserTrack> get copyWith => _$UserTrackCopyWithImpl<UserTrack>(this as UserTrack, _$identity);

  /// Serializes this UserTrack to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserTrack&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other.positions, positions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,const DeepCollectionEquality().hash(positions));

@override
String toString() {
  return 'UserTrack(id: $id, positions: $positions)';
}


}

/// @nodoc
abstract mixin class $UserTrackCopyWith<$Res>  {
  factory $UserTrackCopyWith(UserTrack value, $Res Function(UserTrack) _then) = _$UserTrackCopyWithImpl;
@useResult
$Res call({
 String id, List<TrackPoint> positions
});




}
/// @nodoc
class _$UserTrackCopyWithImpl<$Res>
    implements $UserTrackCopyWith<$Res> {
  _$UserTrackCopyWithImpl(this._self, this._then);

  final UserTrack _self;
  final $Res Function(UserTrack) _then;

/// Create a copy of UserTrack
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? positions = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,positions: null == positions ? _self.positions : positions // ignore: cast_nullable_to_non_nullable
as List<TrackPoint>,
  ));
}

}


/// Adds pattern-matching-related methods to [UserTrack].
extension UserTrackPatterns on UserTrack {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserTrack value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserTrack() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserTrack value)  $default,){
final _that = this;
switch (_that) {
case _UserTrack():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserTrack value)?  $default,){
final _that = this;
switch (_that) {
case _UserTrack() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  List<TrackPoint> positions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserTrack() when $default != null:
return $default(_that.id,_that.positions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  List<TrackPoint> positions)  $default,) {final _that = this;
switch (_that) {
case _UserTrack():
return $default(_that.id,_that.positions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  List<TrackPoint> positions)?  $default,) {final _that = this;
switch (_that) {
case _UserTrack() when $default != null:
return $default(_that.id,_that.positions);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserTrack implements UserTrack {
  const _UserTrack({required this.id, required final  List<TrackPoint> positions}): _positions = positions;
  factory _UserTrack.fromJson(Map<String, dynamic> json) => _$UserTrackFromJson(json);

@override final  String id;
 final  List<TrackPoint> _positions;
@override List<TrackPoint> get positions {
  if (_positions is EqualUnmodifiableListView) return _positions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_positions);
}


/// Create a copy of UserTrack
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserTrackCopyWith<_UserTrack> get copyWith => __$UserTrackCopyWithImpl<_UserTrack>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserTrackToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserTrack&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other._positions, _positions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,const DeepCollectionEquality().hash(_positions));

@override
String toString() {
  return 'UserTrack(id: $id, positions: $positions)';
}


}

/// @nodoc
abstract mixin class _$UserTrackCopyWith<$Res> implements $UserTrackCopyWith<$Res> {
  factory _$UserTrackCopyWith(_UserTrack value, $Res Function(_UserTrack) _then) = __$UserTrackCopyWithImpl;
@override @useResult
$Res call({
 String id, List<TrackPoint> positions
});




}
/// @nodoc
class __$UserTrackCopyWithImpl<$Res>
    implements _$UserTrackCopyWith<$Res> {
  __$UserTrackCopyWithImpl(this._self, this._then);

  final _UserTrack _self;
  final $Res Function(_UserTrack) _then;

/// Create a copy of UserTrack
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? positions = null,}) {
  return _then(_UserTrack(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,positions: null == positions ? _self._positions : positions // ignore: cast_nullable_to_non_nullable
as List<TrackPoint>,
  ));
}


}


/// @nodoc
mixin _$TrackPoint {

 double get lat; double get lng; double get acc; double? get alt;@JsonKey(name: 'timestampMs') int get timestampMs; String? get type;
/// Create a copy of TrackPoint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrackPointCopyWith<TrackPoint> get copyWith => _$TrackPointCopyWithImpl<TrackPoint>(this as TrackPoint, _$identity);

  /// Serializes this TrackPoint to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrackPoint&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.acc, acc) || other.acc == acc)&&(identical(other.alt, alt) || other.alt == alt)&&(identical(other.timestampMs, timestampMs) || other.timestampMs == timestampMs)&&(identical(other.type, type) || other.type == type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,lat,lng,acc,alt,timestampMs,type);

@override
String toString() {
  return 'TrackPoint(lat: $lat, lng: $lng, acc: $acc, alt: $alt, timestampMs: $timestampMs, type: $type)';
}


}

/// @nodoc
abstract mixin class $TrackPointCopyWith<$Res>  {
  factory $TrackPointCopyWith(TrackPoint value, $Res Function(TrackPoint) _then) = _$TrackPointCopyWithImpl;
@useResult
$Res call({
 double lat, double lng, double acc, double? alt,@JsonKey(name: 'timestampMs') int timestampMs, String? type
});




}
/// @nodoc
class _$TrackPointCopyWithImpl<$Res>
    implements $TrackPointCopyWith<$Res> {
  _$TrackPointCopyWithImpl(this._self, this._then);

  final TrackPoint _self;
  final $Res Function(TrackPoint) _then;

/// Create a copy of TrackPoint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? lat = null,Object? lng = null,Object? acc = null,Object? alt = freezed,Object? timestampMs = null,Object? type = freezed,}) {
  return _then(_self.copyWith(
lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,acc: null == acc ? _self.acc : acc // ignore: cast_nullable_to_non_nullable
as double,alt: freezed == alt ? _self.alt : alt // ignore: cast_nullable_to_non_nullable
as double?,timestampMs: null == timestampMs ? _self.timestampMs : timestampMs // ignore: cast_nullable_to_non_nullable
as int,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [TrackPoint].
extension TrackPointPatterns on TrackPoint {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TrackPoint value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TrackPoint() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TrackPoint value)  $default,){
final _that = this;
switch (_that) {
case _TrackPoint():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TrackPoint value)?  $default,){
final _that = this;
switch (_that) {
case _TrackPoint() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double lat,  double lng,  double acc,  double? alt, @JsonKey(name: 'timestampMs')  int timestampMs,  String? type)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TrackPoint() when $default != null:
return $default(_that.lat,_that.lng,_that.acc,_that.alt,_that.timestampMs,_that.type);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double lat,  double lng,  double acc,  double? alt, @JsonKey(name: 'timestampMs')  int timestampMs,  String? type)  $default,) {final _that = this;
switch (_that) {
case _TrackPoint():
return $default(_that.lat,_that.lng,_that.acc,_that.alt,_that.timestampMs,_that.type);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double lat,  double lng,  double acc,  double? alt, @JsonKey(name: 'timestampMs')  int timestampMs,  String? type)?  $default,) {final _that = this;
switch (_that) {
case _TrackPoint() when $default != null:
return $default(_that.lat,_that.lng,_that.acc,_that.alt,_that.timestampMs,_that.type);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TrackPoint implements TrackPoint {
  const _TrackPoint({required this.lat, required this.lng, required this.acc, this.alt, @JsonKey(name: 'timestampMs') required this.timestampMs, this.type});
  factory _TrackPoint.fromJson(Map<String, dynamic> json) => _$TrackPointFromJson(json);

@override final  double lat;
@override final  double lng;
@override final  double acc;
@override final  double? alt;
@override@JsonKey(name: 'timestampMs') final  int timestampMs;
@override final  String? type;

/// Create a copy of TrackPoint
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrackPointCopyWith<_TrackPoint> get copyWith => __$TrackPointCopyWithImpl<_TrackPoint>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TrackPointToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TrackPoint&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.acc, acc) || other.acc == acc)&&(identical(other.alt, alt) || other.alt == alt)&&(identical(other.timestampMs, timestampMs) || other.timestampMs == timestampMs)&&(identical(other.type, type) || other.type == type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,lat,lng,acc,alt,timestampMs,type);

@override
String toString() {
  return 'TrackPoint(lat: $lat, lng: $lng, acc: $acc, alt: $alt, timestampMs: $timestampMs, type: $type)';
}


}

/// @nodoc
abstract mixin class _$TrackPointCopyWith<$Res> implements $TrackPointCopyWith<$Res> {
  factory _$TrackPointCopyWith(_TrackPoint value, $Res Function(_TrackPoint) _then) = __$TrackPointCopyWithImpl;
@override @useResult
$Res call({
 double lat, double lng, double acc, double? alt,@JsonKey(name: 'timestampMs') int timestampMs, String? type
});




}
/// @nodoc
class __$TrackPointCopyWithImpl<$Res>
    implements _$TrackPointCopyWith<$Res> {
  __$TrackPointCopyWithImpl(this._self, this._then);

  final _TrackPoint _self;
  final $Res Function(_TrackPoint) _then;

/// Create a copy of TrackPoint
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? lat = null,Object? lng = null,Object? acc = null,Object? alt = freezed,Object? timestampMs = null,Object? type = freezed,}) {
  return _then(_TrackPoint(
lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,acc: null == acc ? _self.acc : acc // ignore: cast_nullable_to_non_nullable
as double,alt: freezed == alt ? _self.alt : alt // ignore: cast_nullable_to_non_nullable
as double?,timestampMs: null == timestampMs ? _self.timestampMs : timestampMs // ignore: cast_nullable_to_non_nullable
as int,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
