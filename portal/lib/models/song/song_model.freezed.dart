// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'song_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SongModel implements DiagnosticableTreeMixin {
  String get id;
  String get SongName;
  String? get TuneOf;
  int? get BawdyRating;
  String? get Notes;
  String? get Actions;
  String? get Variants;
  String? get ImageUrl;
  String? get AudioUrl;
  int? get AutoAddToKennel;
  int? get Rank;
  String? get AddedBy_KennelId;
  String? get AddedBy_UserId;
  String? get Lyrics;
  String? get Tags;
  DateTime? get createdAt;
  int get isInKennel;

  /// Create a copy of SongModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SongModelCopyWith<SongModel> get copyWith =>
      _$SongModelCopyWithImpl<SongModel>(this as SongModel, _$identity);

  /// Serializes this SongModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'SongModel'))
      ..add(DiagnosticsProperty('id', id))
      ..add(DiagnosticsProperty('SongName', SongName))
      ..add(DiagnosticsProperty('TuneOf', TuneOf))
      ..add(DiagnosticsProperty('BawdyRating', BawdyRating))
      ..add(DiagnosticsProperty('Notes', Notes))
      ..add(DiagnosticsProperty('Actions', Actions))
      ..add(DiagnosticsProperty('Variants', Variants))
      ..add(DiagnosticsProperty('ImageUrl', ImageUrl))
      ..add(DiagnosticsProperty('AudioUrl', AudioUrl))
      ..add(DiagnosticsProperty('AutoAddToKennel', AutoAddToKennel))
      ..add(DiagnosticsProperty('Rank', Rank))
      ..add(DiagnosticsProperty('AddedBy_KennelId', AddedBy_KennelId))
      ..add(DiagnosticsProperty('AddedBy_UserId', AddedBy_UserId))
      ..add(DiagnosticsProperty('Lyrics', Lyrics))
      ..add(DiagnosticsProperty('Tags', Tags))
      ..add(DiagnosticsProperty('createdAt', createdAt))
      ..add(DiagnosticsProperty('isInKennel', isInKennel));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SongModel &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.SongName, SongName) ||
                other.SongName == SongName) &&
            (identical(other.TuneOf, TuneOf) || other.TuneOf == TuneOf) &&
            (identical(other.BawdyRating, BawdyRating) ||
                other.BawdyRating == BawdyRating) &&
            (identical(other.Notes, Notes) || other.Notes == Notes) &&
            (identical(other.Actions, Actions) || other.Actions == Actions) &&
            (identical(other.Variants, Variants) ||
                other.Variants == Variants) &&
            (identical(other.ImageUrl, ImageUrl) ||
                other.ImageUrl == ImageUrl) &&
            (identical(other.AudioUrl, AudioUrl) ||
                other.AudioUrl == AudioUrl) &&
            (identical(other.AutoAddToKennel, AutoAddToKennel) ||
                other.AutoAddToKennel == AutoAddToKennel) &&
            (identical(other.Rank, Rank) || other.Rank == Rank) &&
            (identical(other.AddedBy_KennelId, AddedBy_KennelId) ||
                other.AddedBy_KennelId == AddedBy_KennelId) &&
            (identical(other.AddedBy_UserId, AddedBy_UserId) ||
                other.AddedBy_UserId == AddedBy_UserId) &&
            (identical(other.Lyrics, Lyrics) || other.Lyrics == Lyrics) &&
            (identical(other.Tags, Tags) || other.Tags == Tags) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.isInKennel, isInKennel) ||
                other.isInKennel == isInKennel));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      SongName,
      TuneOf,
      BawdyRating,
      Notes,
      Actions,
      Variants,
      ImageUrl,
      AudioUrl,
      AutoAddToKennel,
      Rank,
      AddedBy_KennelId,
      AddedBy_UserId,
      Lyrics,
      Tags,
      createdAt,
      isInKennel);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'SongModel(id: $id, SongName: $SongName, TuneOf: $TuneOf, BawdyRating: $BawdyRating, Notes: $Notes, Actions: $Actions, Variants: $Variants, ImageUrl: $ImageUrl, AudioUrl: $AudioUrl, AutoAddToKennel: $AutoAddToKennel, Rank: $Rank, AddedBy_KennelId: $AddedBy_KennelId, AddedBy_UserId: $AddedBy_UserId, Lyrics: $Lyrics, Tags: $Tags, createdAt: $createdAt, isInKennel: $isInKennel)';
  }
}

/// @nodoc
abstract mixin class $SongModelCopyWith<$Res> {
  factory $SongModelCopyWith(SongModel value, $Res Function(SongModel) _then) =
      _$SongModelCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String SongName,
      String? TuneOf,
      int? BawdyRating,
      String? Notes,
      String? Actions,
      String? Variants,
      String? ImageUrl,
      String? AudioUrl,
      int? AutoAddToKennel,
      int? Rank,
      String? AddedBy_KennelId,
      String? AddedBy_UserId,
      String? Lyrics,
      String? Tags,
      DateTime? createdAt,
      int isInKennel});
}

/// @nodoc
class _$SongModelCopyWithImpl<$Res> implements $SongModelCopyWith<$Res> {
  _$SongModelCopyWithImpl(this._self, this._then);

  final SongModel _self;
  final $Res Function(SongModel) _then;

  /// Create a copy of SongModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? SongName = null,
    Object? TuneOf = freezed,
    Object? BawdyRating = freezed,
    Object? Notes = freezed,
    Object? Actions = freezed,
    Object? Variants = freezed,
    Object? ImageUrl = freezed,
    Object? AudioUrl = freezed,
    Object? AutoAddToKennel = freezed,
    Object? Rank = freezed,
    Object? AddedBy_KennelId = freezed,
    Object? AddedBy_UserId = freezed,
    Object? Lyrics = freezed,
    Object? Tags = freezed,
    Object? createdAt = freezed,
    Object? isInKennel = null,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      SongName: null == SongName
          ? _self.SongName
          : SongName // ignore: cast_nullable_to_non_nullable
              as String,
      TuneOf: freezed == TuneOf
          ? _self.TuneOf
          : TuneOf // ignore: cast_nullable_to_non_nullable
              as String?,
      BawdyRating: freezed == BawdyRating
          ? _self.BawdyRating
          : BawdyRating // ignore: cast_nullable_to_non_nullable
              as int?,
      Notes: freezed == Notes
          ? _self.Notes
          : Notes // ignore: cast_nullable_to_non_nullable
              as String?,
      Actions: freezed == Actions
          ? _self.Actions
          : Actions // ignore: cast_nullable_to_non_nullable
              as String?,
      Variants: freezed == Variants
          ? _self.Variants
          : Variants // ignore: cast_nullable_to_non_nullable
              as String?,
      ImageUrl: freezed == ImageUrl
          ? _self.ImageUrl
          : ImageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      AudioUrl: freezed == AudioUrl
          ? _self.AudioUrl
          : AudioUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      AutoAddToKennel: freezed == AutoAddToKennel
          ? _self.AutoAddToKennel
          : AutoAddToKennel // ignore: cast_nullable_to_non_nullable
              as int?,
      Rank: freezed == Rank
          ? _self.Rank
          : Rank // ignore: cast_nullable_to_non_nullable
              as int?,
      AddedBy_KennelId: freezed == AddedBy_KennelId
          ? _self.AddedBy_KennelId
          : AddedBy_KennelId // ignore: cast_nullable_to_non_nullable
              as String?,
      AddedBy_UserId: freezed == AddedBy_UserId
          ? _self.AddedBy_UserId
          : AddedBy_UserId // ignore: cast_nullable_to_non_nullable
              as String?,
      Lyrics: freezed == Lyrics
          ? _self.Lyrics
          : Lyrics // ignore: cast_nullable_to_non_nullable
              as String?,
      Tags: freezed == Tags
          ? _self.Tags
          : Tags // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isInKennel: null == isInKennel
          ? _self.isInKennel
          : isInKennel // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// Adds pattern-matching-related methods to [SongModel].
extension SongModelPatterns on SongModel {
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

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_SongModel value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SongModel() when $default != null:
        return $default(_that);
      case _:
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

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_SongModel value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SongModel():
        return $default(_that);
      case _:
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

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_SongModel value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SongModel() when $default != null:
        return $default(_that);
      case _:
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

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            String id,
            String SongName,
            String? TuneOf,
            int? BawdyRating,
            String? Notes,
            String? Actions,
            String? Variants,
            String? ImageUrl,
            String? AudioUrl,
            int? AutoAddToKennel,
            int? Rank,
            String? AddedBy_KennelId,
            String? AddedBy_UserId,
            String? Lyrics,
            String? Tags,
            DateTime? createdAt,
            int isInKennel)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SongModel() when $default != null:
        return $default(
            _that.id,
            _that.SongName,
            _that.TuneOf,
            _that.BawdyRating,
            _that.Notes,
            _that.Actions,
            _that.Variants,
            _that.ImageUrl,
            _that.AudioUrl,
            _that.AutoAddToKennel,
            _that.Rank,
            _that.AddedBy_KennelId,
            _that.AddedBy_UserId,
            _that.Lyrics,
            _that.Tags,
            _that.createdAt,
            _that.isInKennel);
      case _:
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

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            String id,
            String SongName,
            String? TuneOf,
            int? BawdyRating,
            String? Notes,
            String? Actions,
            String? Variants,
            String? ImageUrl,
            String? AudioUrl,
            int? AutoAddToKennel,
            int? Rank,
            String? AddedBy_KennelId,
            String? AddedBy_UserId,
            String? Lyrics,
            String? Tags,
            DateTime? createdAt,
            int isInKennel)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SongModel():
        return $default(
            _that.id,
            _that.SongName,
            _that.TuneOf,
            _that.BawdyRating,
            _that.Notes,
            _that.Actions,
            _that.Variants,
            _that.ImageUrl,
            _that.AudioUrl,
            _that.AutoAddToKennel,
            _that.Rank,
            _that.AddedBy_KennelId,
            _that.AddedBy_UserId,
            _that.Lyrics,
            _that.Tags,
            _that.createdAt,
            _that.isInKennel);
      case _:
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

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            String id,
            String SongName,
            String? TuneOf,
            int? BawdyRating,
            String? Notes,
            String? Actions,
            String? Variants,
            String? ImageUrl,
            String? AudioUrl,
            int? AutoAddToKennel,
            int? Rank,
            String? AddedBy_KennelId,
            String? AddedBy_UserId,
            String? Lyrics,
            String? Tags,
            DateTime? createdAt,
            int isInKennel)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SongModel() when $default != null:
        return $default(
            _that.id,
            _that.SongName,
            _that.TuneOf,
            _that.BawdyRating,
            _that.Notes,
            _that.Actions,
            _that.Variants,
            _that.ImageUrl,
            _that.AudioUrl,
            _that.AutoAddToKennel,
            _that.Rank,
            _that.AddedBy_KennelId,
            _that.AddedBy_UserId,
            _that.Lyrics,
            _that.Tags,
            _that.createdAt,
            _that.isInKennel);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _SongModel with DiagnosticableTreeMixin implements SongModel {
  _SongModel(
      {required this.id,
      required this.SongName,
      this.TuneOf,
      this.BawdyRating,
      this.Notes,
      this.Actions,
      this.Variants,
      this.ImageUrl,
      this.AudioUrl,
      this.AutoAddToKennel,
      this.Rank,
      this.AddedBy_KennelId,
      this.AddedBy_UserId,
      this.Lyrics,
      this.Tags,
      this.createdAt,
      this.isInKennel = 0});
  factory _SongModel.fromJson(Map<String, dynamic> json) =>
      _$SongModelFromJson(json);

  @override
  final String id;
  @override
  final String SongName;
  @override
  final String? TuneOf;
  @override
  final int? BawdyRating;
  @override
  final String? Notes;
  @override
  final String? Actions;
  @override
  final String? Variants;
  @override
  final String? ImageUrl;
  @override
  final String? AudioUrl;
  @override
  final int? AutoAddToKennel;
  @override
  final int? Rank;
  @override
  final String? AddedBy_KennelId;
  @override
  final String? AddedBy_UserId;
  @override
  final String? Lyrics;
  @override
  final String? Tags;
  @override
  final DateTime? createdAt;
  @override
  @JsonKey()
  final int isInKennel;

  /// Create a copy of SongModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$SongModelCopyWith<_SongModel> get copyWith =>
      __$SongModelCopyWithImpl<_SongModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$SongModelToJson(
      this,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'SongModel'))
      ..add(DiagnosticsProperty('id', id))
      ..add(DiagnosticsProperty('SongName', SongName))
      ..add(DiagnosticsProperty('TuneOf', TuneOf))
      ..add(DiagnosticsProperty('BawdyRating', BawdyRating))
      ..add(DiagnosticsProperty('Notes', Notes))
      ..add(DiagnosticsProperty('Actions', Actions))
      ..add(DiagnosticsProperty('Variants', Variants))
      ..add(DiagnosticsProperty('ImageUrl', ImageUrl))
      ..add(DiagnosticsProperty('AudioUrl', AudioUrl))
      ..add(DiagnosticsProperty('AutoAddToKennel', AutoAddToKennel))
      ..add(DiagnosticsProperty('Rank', Rank))
      ..add(DiagnosticsProperty('AddedBy_KennelId', AddedBy_KennelId))
      ..add(DiagnosticsProperty('AddedBy_UserId', AddedBy_UserId))
      ..add(DiagnosticsProperty('Lyrics', Lyrics))
      ..add(DiagnosticsProperty('Tags', Tags))
      ..add(DiagnosticsProperty('createdAt', createdAt))
      ..add(DiagnosticsProperty('isInKennel', isInKennel));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _SongModel &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.SongName, SongName) ||
                other.SongName == SongName) &&
            (identical(other.TuneOf, TuneOf) || other.TuneOf == TuneOf) &&
            (identical(other.BawdyRating, BawdyRating) ||
                other.BawdyRating == BawdyRating) &&
            (identical(other.Notes, Notes) || other.Notes == Notes) &&
            (identical(other.Actions, Actions) || other.Actions == Actions) &&
            (identical(other.Variants, Variants) ||
                other.Variants == Variants) &&
            (identical(other.ImageUrl, ImageUrl) ||
                other.ImageUrl == ImageUrl) &&
            (identical(other.AudioUrl, AudioUrl) ||
                other.AudioUrl == AudioUrl) &&
            (identical(other.AutoAddToKennel, AutoAddToKennel) ||
                other.AutoAddToKennel == AutoAddToKennel) &&
            (identical(other.Rank, Rank) || other.Rank == Rank) &&
            (identical(other.AddedBy_KennelId, AddedBy_KennelId) ||
                other.AddedBy_KennelId == AddedBy_KennelId) &&
            (identical(other.AddedBy_UserId, AddedBy_UserId) ||
                other.AddedBy_UserId == AddedBy_UserId) &&
            (identical(other.Lyrics, Lyrics) || other.Lyrics == Lyrics) &&
            (identical(other.Tags, Tags) || other.Tags == Tags) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.isInKennel, isInKennel) ||
                other.isInKennel == isInKennel));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      SongName,
      TuneOf,
      BawdyRating,
      Notes,
      Actions,
      Variants,
      ImageUrl,
      AudioUrl,
      AutoAddToKennel,
      Rank,
      AddedBy_KennelId,
      AddedBy_UserId,
      Lyrics,
      Tags,
      createdAt,
      isInKennel);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'SongModel(id: $id, SongName: $SongName, TuneOf: $TuneOf, BawdyRating: $BawdyRating, Notes: $Notes, Actions: $Actions, Variants: $Variants, ImageUrl: $ImageUrl, AudioUrl: $AudioUrl, AutoAddToKennel: $AutoAddToKennel, Rank: $Rank, AddedBy_KennelId: $AddedBy_KennelId, AddedBy_UserId: $AddedBy_UserId, Lyrics: $Lyrics, Tags: $Tags, createdAt: $createdAt, isInKennel: $isInKennel)';
  }
}

/// @nodoc
abstract mixin class _$SongModelCopyWith<$Res>
    implements $SongModelCopyWith<$Res> {
  factory _$SongModelCopyWith(
          _SongModel value, $Res Function(_SongModel) _then) =
      __$SongModelCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String SongName,
      String? TuneOf,
      int? BawdyRating,
      String? Notes,
      String? Actions,
      String? Variants,
      String? ImageUrl,
      String? AudioUrl,
      int? AutoAddToKennel,
      int? Rank,
      String? AddedBy_KennelId,
      String? AddedBy_UserId,
      String? Lyrics,
      String? Tags,
      DateTime? createdAt,
      int isInKennel});
}

/// @nodoc
class __$SongModelCopyWithImpl<$Res> implements _$SongModelCopyWith<$Res> {
  __$SongModelCopyWithImpl(this._self, this._then);

  final _SongModel _self;
  final $Res Function(_SongModel) _then;

  /// Create a copy of SongModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? SongName = null,
    Object? TuneOf = freezed,
    Object? BawdyRating = freezed,
    Object? Notes = freezed,
    Object? Actions = freezed,
    Object? Variants = freezed,
    Object? ImageUrl = freezed,
    Object? AudioUrl = freezed,
    Object? AutoAddToKennel = freezed,
    Object? Rank = freezed,
    Object? AddedBy_KennelId = freezed,
    Object? AddedBy_UserId = freezed,
    Object? Lyrics = freezed,
    Object? Tags = freezed,
    Object? createdAt = freezed,
    Object? isInKennel = null,
  }) {
    return _then(_SongModel(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      SongName: null == SongName
          ? _self.SongName
          : SongName // ignore: cast_nullable_to_non_nullable
              as String,
      TuneOf: freezed == TuneOf
          ? _self.TuneOf
          : TuneOf // ignore: cast_nullable_to_non_nullable
              as String?,
      BawdyRating: freezed == BawdyRating
          ? _self.BawdyRating
          : BawdyRating // ignore: cast_nullable_to_non_nullable
              as int?,
      Notes: freezed == Notes
          ? _self.Notes
          : Notes // ignore: cast_nullable_to_non_nullable
              as String?,
      Actions: freezed == Actions
          ? _self.Actions
          : Actions // ignore: cast_nullable_to_non_nullable
              as String?,
      Variants: freezed == Variants
          ? _self.Variants
          : Variants // ignore: cast_nullable_to_non_nullable
              as String?,
      ImageUrl: freezed == ImageUrl
          ? _self.ImageUrl
          : ImageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      AudioUrl: freezed == AudioUrl
          ? _self.AudioUrl
          : AudioUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      AutoAddToKennel: freezed == AutoAddToKennel
          ? _self.AutoAddToKennel
          : AutoAddToKennel // ignore: cast_nullable_to_non_nullable
              as int?,
      Rank: freezed == Rank
          ? _self.Rank
          : Rank // ignore: cast_nullable_to_non_nullable
              as int?,
      AddedBy_KennelId: freezed == AddedBy_KennelId
          ? _self.AddedBy_KennelId
          : AddedBy_KennelId // ignore: cast_nullable_to_non_nullable
              as String?,
      AddedBy_UserId: freezed == AddedBy_UserId
          ? _self.AddedBy_UserId
          : AddedBy_UserId // ignore: cast_nullable_to_non_nullable
              as String?,
      Lyrics: freezed == Lyrics
          ? _self.Lyrics
          : Lyrics // ignore: cast_nullable_to_non_nullable
              as String?,
      Tags: freezed == Tags
          ? _self.Tags
          : Tags // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isInKennel: null == isInKennel
          ? _self.isInKennel
          : isInKennel // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

// dart format on
