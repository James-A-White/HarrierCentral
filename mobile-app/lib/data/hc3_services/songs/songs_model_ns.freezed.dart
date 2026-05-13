// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'songs_model_ns.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SongsModel implements DiagnosticableTreeMixin {

 String get songId; String get songName; String? get tuneOf; int get bawdyRating; String? get notes; String? get actions; String? get variants; String? get imageUrl; String? get audioUrl; int get autoAddToKennel; int get rank; String? get addedByKennelId; String? get addedByUserId; String get lyrics; String? get tags; int? get removed; DateTime? get updatedAt;
/// Create a copy of SongsModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SongsModelCopyWith<SongsModel> get copyWith => _$SongsModelCopyWithImpl<SongsModel>(this as SongsModel, _$identity);

  /// Serializes this SongsModel to a JSON map.
  Map<String, dynamic> toJson();

@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'SongsModel'))
    ..add(DiagnosticsProperty('songId', songId))..add(DiagnosticsProperty('songName', songName))..add(DiagnosticsProperty('tuneOf', tuneOf))..add(DiagnosticsProperty('bawdyRating', bawdyRating))..add(DiagnosticsProperty('notes', notes))..add(DiagnosticsProperty('actions', actions))..add(DiagnosticsProperty('variants', variants))..add(DiagnosticsProperty('imageUrl', imageUrl))..add(DiagnosticsProperty('audioUrl', audioUrl))..add(DiagnosticsProperty('autoAddToKennel', autoAddToKennel))..add(DiagnosticsProperty('rank', rank))..add(DiagnosticsProperty('addedByKennelId', addedByKennelId))..add(DiagnosticsProperty('addedByUserId', addedByUserId))..add(DiagnosticsProperty('lyrics', lyrics))..add(DiagnosticsProperty('tags', tags))..add(DiagnosticsProperty('removed', removed))..add(DiagnosticsProperty('updatedAt', updatedAt));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SongsModel&&(identical(other.songId, songId) || other.songId == songId)&&(identical(other.songName, songName) || other.songName == songName)&&(identical(other.tuneOf, tuneOf) || other.tuneOf == tuneOf)&&(identical(other.bawdyRating, bawdyRating) || other.bawdyRating == bawdyRating)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.actions, actions) || other.actions == actions)&&(identical(other.variants, variants) || other.variants == variants)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.audioUrl, audioUrl) || other.audioUrl == audioUrl)&&(identical(other.autoAddToKennel, autoAddToKennel) || other.autoAddToKennel == autoAddToKennel)&&(identical(other.rank, rank) || other.rank == rank)&&(identical(other.addedByKennelId, addedByKennelId) || other.addedByKennelId == addedByKennelId)&&(identical(other.addedByUserId, addedByUserId) || other.addedByUserId == addedByUserId)&&(identical(other.lyrics, lyrics) || other.lyrics == lyrics)&&(identical(other.tags, tags) || other.tags == tags)&&(identical(other.removed, removed) || other.removed == removed)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,songId,songName,tuneOf,bawdyRating,notes,actions,variants,imageUrl,audioUrl,autoAddToKennel,rank,addedByKennelId,addedByUserId,lyrics,tags,removed,updatedAt);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'SongsModel(songId: $songId, songName: $songName, tuneOf: $tuneOf, bawdyRating: $bawdyRating, notes: $notes, actions: $actions, variants: $variants, imageUrl: $imageUrl, audioUrl: $audioUrl, autoAddToKennel: $autoAddToKennel, rank: $rank, addedByKennelId: $addedByKennelId, addedByUserId: $addedByUserId, lyrics: $lyrics, tags: $tags, removed: $removed, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $SongsModelCopyWith<$Res>  {
  factory $SongsModelCopyWith(SongsModel value, $Res Function(SongsModel) _then) = _$SongsModelCopyWithImpl;
@useResult
$Res call({
 String songId, String songName, String? tuneOf, int bawdyRating, String? notes, String? actions, String? variants, String? imageUrl, String? audioUrl, int autoAddToKennel, int rank, String? addedByKennelId, String? addedByUserId, String lyrics, String? tags, int? removed, DateTime? updatedAt
});




}
/// @nodoc
class _$SongsModelCopyWithImpl<$Res>
    implements $SongsModelCopyWith<$Res> {
  _$SongsModelCopyWithImpl(this._self, this._then);

  final SongsModel _self;
  final $Res Function(SongsModel) _then;

/// Create a copy of SongsModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? songId = null,Object? songName = null,Object? tuneOf = freezed,Object? bawdyRating = null,Object? notes = freezed,Object? actions = freezed,Object? variants = freezed,Object? imageUrl = freezed,Object? audioUrl = freezed,Object? autoAddToKennel = null,Object? rank = null,Object? addedByKennelId = freezed,Object? addedByUserId = freezed,Object? lyrics = null,Object? tags = freezed,Object? removed = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
songId: null == songId ? _self.songId : songId // ignore: cast_nullable_to_non_nullable
as String,songName: null == songName ? _self.songName : songName // ignore: cast_nullable_to_non_nullable
as String,tuneOf: freezed == tuneOf ? _self.tuneOf : tuneOf // ignore: cast_nullable_to_non_nullable
as String?,bawdyRating: null == bawdyRating ? _self.bawdyRating : bawdyRating // ignore: cast_nullable_to_non_nullable
as int,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,actions: freezed == actions ? _self.actions : actions // ignore: cast_nullable_to_non_nullable
as String?,variants: freezed == variants ? _self.variants : variants // ignore: cast_nullable_to_non_nullable
as String?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,audioUrl: freezed == audioUrl ? _self.audioUrl : audioUrl // ignore: cast_nullable_to_non_nullable
as String?,autoAddToKennel: null == autoAddToKennel ? _self.autoAddToKennel : autoAddToKennel // ignore: cast_nullable_to_non_nullable
as int,rank: null == rank ? _self.rank : rank // ignore: cast_nullable_to_non_nullable
as int,addedByKennelId: freezed == addedByKennelId ? _self.addedByKennelId : addedByKennelId // ignore: cast_nullable_to_non_nullable
as String?,addedByUserId: freezed == addedByUserId ? _self.addedByUserId : addedByUserId // ignore: cast_nullable_to_non_nullable
as String?,lyrics: null == lyrics ? _self.lyrics : lyrics // ignore: cast_nullable_to_non_nullable
as String,tags: freezed == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as String?,removed: freezed == removed ? _self.removed : removed // ignore: cast_nullable_to_non_nullable
as int?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [SongsModel].
extension SongsModelPatterns on SongsModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SongsModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SongsModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SongsModel value)  $default,){
final _that = this;
switch (_that) {
case _SongsModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SongsModel value)?  $default,){
final _that = this;
switch (_that) {
case _SongsModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String songId,  String songName,  String? tuneOf,  int bawdyRating,  String? notes,  String? actions,  String? variants,  String? imageUrl,  String? audioUrl,  int autoAddToKennel,  int rank,  String? addedByKennelId,  String? addedByUserId,  String lyrics,  String? tags,  int? removed,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SongsModel() when $default != null:
return $default(_that.songId,_that.songName,_that.tuneOf,_that.bawdyRating,_that.notes,_that.actions,_that.variants,_that.imageUrl,_that.audioUrl,_that.autoAddToKennel,_that.rank,_that.addedByKennelId,_that.addedByUserId,_that.lyrics,_that.tags,_that.removed,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String songId,  String songName,  String? tuneOf,  int bawdyRating,  String? notes,  String? actions,  String? variants,  String? imageUrl,  String? audioUrl,  int autoAddToKennel,  int rank,  String? addedByKennelId,  String? addedByUserId,  String lyrics,  String? tags,  int? removed,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _SongsModel():
return $default(_that.songId,_that.songName,_that.tuneOf,_that.bawdyRating,_that.notes,_that.actions,_that.variants,_that.imageUrl,_that.audioUrl,_that.autoAddToKennel,_that.rank,_that.addedByKennelId,_that.addedByUserId,_that.lyrics,_that.tags,_that.removed,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String songId,  String songName,  String? tuneOf,  int bawdyRating,  String? notes,  String? actions,  String? variants,  String? imageUrl,  String? audioUrl,  int autoAddToKennel,  int rank,  String? addedByKennelId,  String? addedByUserId,  String lyrics,  String? tags,  int? removed,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _SongsModel() when $default != null:
return $default(_that.songId,_that.songName,_that.tuneOf,_that.bawdyRating,_that.notes,_that.actions,_that.variants,_that.imageUrl,_that.audioUrl,_that.autoAddToKennel,_that.rank,_that.addedByKennelId,_that.addedByUserId,_that.lyrics,_that.tags,_that.removed,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SongsModel with DiagnosticableTreeMixin implements SongsModel {
   _SongsModel({required this.songId, required this.songName, this.tuneOf, required this.bawdyRating, this.notes, this.actions, this.variants, this.imageUrl, this.audioUrl, required this.autoAddToKennel, required this.rank, this.addedByKennelId, this.addedByUserId, required this.lyrics, this.tags, this.removed, this.updatedAt});
  factory _SongsModel.fromJson(Map<String, dynamic> json) => _$SongsModelFromJson(json);

@override final  String songId;
@override final  String songName;
@override final  String? tuneOf;
@override final  int bawdyRating;
@override final  String? notes;
@override final  String? actions;
@override final  String? variants;
@override final  String? imageUrl;
@override final  String? audioUrl;
@override final  int autoAddToKennel;
@override final  int rank;
@override final  String? addedByKennelId;
@override final  String? addedByUserId;
@override final  String lyrics;
@override final  String? tags;
@override final  int? removed;
@override final  DateTime? updatedAt;

/// Create a copy of SongsModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SongsModelCopyWith<_SongsModel> get copyWith => __$SongsModelCopyWithImpl<_SongsModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SongsModelToJson(this, );
}
@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'SongsModel'))
    ..add(DiagnosticsProperty('songId', songId))..add(DiagnosticsProperty('songName', songName))..add(DiagnosticsProperty('tuneOf', tuneOf))..add(DiagnosticsProperty('bawdyRating', bawdyRating))..add(DiagnosticsProperty('notes', notes))..add(DiagnosticsProperty('actions', actions))..add(DiagnosticsProperty('variants', variants))..add(DiagnosticsProperty('imageUrl', imageUrl))..add(DiagnosticsProperty('audioUrl', audioUrl))..add(DiagnosticsProperty('autoAddToKennel', autoAddToKennel))..add(DiagnosticsProperty('rank', rank))..add(DiagnosticsProperty('addedByKennelId', addedByKennelId))..add(DiagnosticsProperty('addedByUserId', addedByUserId))..add(DiagnosticsProperty('lyrics', lyrics))..add(DiagnosticsProperty('tags', tags))..add(DiagnosticsProperty('removed', removed))..add(DiagnosticsProperty('updatedAt', updatedAt));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SongsModel&&(identical(other.songId, songId) || other.songId == songId)&&(identical(other.songName, songName) || other.songName == songName)&&(identical(other.tuneOf, tuneOf) || other.tuneOf == tuneOf)&&(identical(other.bawdyRating, bawdyRating) || other.bawdyRating == bawdyRating)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.actions, actions) || other.actions == actions)&&(identical(other.variants, variants) || other.variants == variants)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.audioUrl, audioUrl) || other.audioUrl == audioUrl)&&(identical(other.autoAddToKennel, autoAddToKennel) || other.autoAddToKennel == autoAddToKennel)&&(identical(other.rank, rank) || other.rank == rank)&&(identical(other.addedByKennelId, addedByKennelId) || other.addedByKennelId == addedByKennelId)&&(identical(other.addedByUserId, addedByUserId) || other.addedByUserId == addedByUserId)&&(identical(other.lyrics, lyrics) || other.lyrics == lyrics)&&(identical(other.tags, tags) || other.tags == tags)&&(identical(other.removed, removed) || other.removed == removed)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,songId,songName,tuneOf,bawdyRating,notes,actions,variants,imageUrl,audioUrl,autoAddToKennel,rank,addedByKennelId,addedByUserId,lyrics,tags,removed,updatedAt);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'SongsModel(songId: $songId, songName: $songName, tuneOf: $tuneOf, bawdyRating: $bawdyRating, notes: $notes, actions: $actions, variants: $variants, imageUrl: $imageUrl, audioUrl: $audioUrl, autoAddToKennel: $autoAddToKennel, rank: $rank, addedByKennelId: $addedByKennelId, addedByUserId: $addedByUserId, lyrics: $lyrics, tags: $tags, removed: $removed, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$SongsModelCopyWith<$Res> implements $SongsModelCopyWith<$Res> {
  factory _$SongsModelCopyWith(_SongsModel value, $Res Function(_SongsModel) _then) = __$SongsModelCopyWithImpl;
@override @useResult
$Res call({
 String songId, String songName, String? tuneOf, int bawdyRating, String? notes, String? actions, String? variants, String? imageUrl, String? audioUrl, int autoAddToKennel, int rank, String? addedByKennelId, String? addedByUserId, String lyrics, String? tags, int? removed, DateTime? updatedAt
});




}
/// @nodoc
class __$SongsModelCopyWithImpl<$Res>
    implements _$SongsModelCopyWith<$Res> {
  __$SongsModelCopyWithImpl(this._self, this._then);

  final _SongsModel _self;
  final $Res Function(_SongsModel) _then;

/// Create a copy of SongsModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? songId = null,Object? songName = null,Object? tuneOf = freezed,Object? bawdyRating = null,Object? notes = freezed,Object? actions = freezed,Object? variants = freezed,Object? imageUrl = freezed,Object? audioUrl = freezed,Object? autoAddToKennel = null,Object? rank = null,Object? addedByKennelId = freezed,Object? addedByUserId = freezed,Object? lyrics = null,Object? tags = freezed,Object? removed = freezed,Object? updatedAt = freezed,}) {
  return _then(_SongsModel(
songId: null == songId ? _self.songId : songId // ignore: cast_nullable_to_non_nullable
as String,songName: null == songName ? _self.songName : songName // ignore: cast_nullable_to_non_nullable
as String,tuneOf: freezed == tuneOf ? _self.tuneOf : tuneOf // ignore: cast_nullable_to_non_nullable
as String?,bawdyRating: null == bawdyRating ? _self.bawdyRating : bawdyRating // ignore: cast_nullable_to_non_nullable
as int,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,actions: freezed == actions ? _self.actions : actions // ignore: cast_nullable_to_non_nullable
as String?,variants: freezed == variants ? _self.variants : variants // ignore: cast_nullable_to_non_nullable
as String?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,audioUrl: freezed == audioUrl ? _self.audioUrl : audioUrl // ignore: cast_nullable_to_non_nullable
as String?,autoAddToKennel: null == autoAddToKennel ? _self.autoAddToKennel : autoAddToKennel // ignore: cast_nullable_to_non_nullable
as int,rank: null == rank ? _self.rank : rank // ignore: cast_nullable_to_non_nullable
as int,addedByKennelId: freezed == addedByKennelId ? _self.addedByKennelId : addedByKennelId // ignore: cast_nullable_to_non_nullable
as String?,addedByUserId: freezed == addedByUserId ? _self.addedByUserId : addedByUserId // ignore: cast_nullable_to_non_nullable
as String?,lyrics: null == lyrics ? _self.lyrics : lyrics // ignore: cast_nullable_to_non_nullable
as String,tags: freezed == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as String?,removed: freezed == removed ? _self.removed : removed // ignore: cast_nullable_to_non_nullable
as int?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
