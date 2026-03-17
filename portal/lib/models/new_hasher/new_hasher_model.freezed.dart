// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'new_hasher_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NewHasherModel implements DiagnosticableTreeMixin {
  String? get publicHasherId;
  String? get publicKennelId;
  String? get hashName;
  String? get firstName;
  String? get lastName;
  String? get eMail;
  String? get addHasherStatus;
  int get historicTotalRuns;
  int get historicHaring;

  /// Create a copy of NewHasherModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $NewHasherModelCopyWith<NewHasherModel> get copyWith =>
      _$NewHasherModelCopyWithImpl<NewHasherModel>(
          this as NewHasherModel, _$identity);

  /// Serializes this NewHasherModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'NewHasherModel'))
      ..add(DiagnosticsProperty('publicHasherId', publicHasherId))
      ..add(DiagnosticsProperty('publicKennelId', publicKennelId))
      ..add(DiagnosticsProperty('hashName', hashName))
      ..add(DiagnosticsProperty('firstName', firstName))
      ..add(DiagnosticsProperty('lastName', lastName))
      ..add(DiagnosticsProperty('eMail', eMail))
      ..add(DiagnosticsProperty('addHasherStatus', addHasherStatus))
      ..add(DiagnosticsProperty('historicTotalRuns', historicTotalRuns))
      ..add(DiagnosticsProperty('historicHaring', historicHaring));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is NewHasherModel &&
            (identical(other.publicHasherId, publicHasherId) ||
                other.publicHasherId == publicHasherId) &&
            (identical(other.publicKennelId, publicKennelId) ||
                other.publicKennelId == publicKennelId) &&
            (identical(other.hashName, hashName) ||
                other.hashName == hashName) &&
            (identical(other.firstName, firstName) ||
                other.firstName == firstName) &&
            (identical(other.lastName, lastName) ||
                other.lastName == lastName) &&
            (identical(other.eMail, eMail) || other.eMail == eMail) &&
            (identical(other.addHasherStatus, addHasherStatus) ||
                other.addHasherStatus == addHasherStatus) &&
            (identical(other.historicTotalRuns, historicTotalRuns) ||
                other.historicTotalRuns == historicTotalRuns) &&
            (identical(other.historicHaring, historicHaring) ||
                other.historicHaring == historicHaring));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      publicHasherId,
      publicKennelId,
      hashName,
      firstName,
      lastName,
      eMail,
      addHasherStatus,
      historicTotalRuns,
      historicHaring);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'NewHasherModel(publicHasherId: $publicHasherId, publicKennelId: $publicKennelId, hashName: $hashName, firstName: $firstName, lastName: $lastName, eMail: $eMail, addHasherStatus: $addHasherStatus, historicTotalRuns: $historicTotalRuns, historicHaring: $historicHaring)';
  }
}

/// @nodoc
abstract mixin class $NewHasherModelCopyWith<$Res> {
  factory $NewHasherModelCopyWith(
          NewHasherModel value, $Res Function(NewHasherModel) _then) =
      _$NewHasherModelCopyWithImpl;
  @useResult
  $Res call(
      {String? publicHasherId,
      String? publicKennelId,
      String? hashName,
      String? firstName,
      String? lastName,
      String? eMail,
      String? addHasherStatus,
      int historicTotalRuns,
      int historicHaring});
}

/// @nodoc
class _$NewHasherModelCopyWithImpl<$Res>
    implements $NewHasherModelCopyWith<$Res> {
  _$NewHasherModelCopyWithImpl(this._self, this._then);

  final NewHasherModel _self;
  final $Res Function(NewHasherModel) _then;

  /// Create a copy of NewHasherModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? publicHasherId = freezed,
    Object? publicKennelId = freezed,
    Object? hashName = freezed,
    Object? firstName = freezed,
    Object? lastName = freezed,
    Object? eMail = freezed,
    Object? addHasherStatus = freezed,
    Object? historicTotalRuns = null,
    Object? historicHaring = null,
  }) {
    return _then(_self.copyWith(
      publicHasherId: freezed == publicHasherId
          ? _self.publicHasherId
          : publicHasherId // ignore: cast_nullable_to_non_nullable
              as String?,
      publicKennelId: freezed == publicKennelId
          ? _self.publicKennelId
          : publicKennelId // ignore: cast_nullable_to_non_nullable
              as String?,
      hashName: freezed == hashName
          ? _self.hashName
          : hashName // ignore: cast_nullable_to_non_nullable
              as String?,
      firstName: freezed == firstName
          ? _self.firstName
          : firstName // ignore: cast_nullable_to_non_nullable
              as String?,
      lastName: freezed == lastName
          ? _self.lastName
          : lastName // ignore: cast_nullable_to_non_nullable
              as String?,
      eMail: freezed == eMail
          ? _self.eMail
          : eMail // ignore: cast_nullable_to_non_nullable
              as String?,
      addHasherStatus: freezed == addHasherStatus
          ? _self.addHasherStatus
          : addHasherStatus // ignore: cast_nullable_to_non_nullable
              as String?,
      historicTotalRuns: null == historicTotalRuns
          ? _self.historicTotalRuns
          : historicTotalRuns // ignore: cast_nullable_to_non_nullable
              as int,
      historicHaring: null == historicHaring
          ? _self.historicHaring
          : historicHaring // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// Adds pattern-matching-related methods to [NewHasherModel].
extension NewHasherModelPatterns on NewHasherModel {
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
    TResult Function(_NewHasherModel value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _NewHasherModel() when $default != null:
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
    TResult Function(_NewHasherModel value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _NewHasherModel():
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
    TResult? Function(_NewHasherModel value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _NewHasherModel() when $default != null:
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
            String? publicHasherId,
            String? publicKennelId,
            String? hashName,
            String? firstName,
            String? lastName,
            String? eMail,
            String? addHasherStatus,
            int historicTotalRuns,
            int historicHaring)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _NewHasherModel() when $default != null:
        return $default(
            _that.publicHasherId,
            _that.publicKennelId,
            _that.hashName,
            _that.firstName,
            _that.lastName,
            _that.eMail,
            _that.addHasherStatus,
            _that.historicTotalRuns,
            _that.historicHaring);
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
            String? publicHasherId,
            String? publicKennelId,
            String? hashName,
            String? firstName,
            String? lastName,
            String? eMail,
            String? addHasherStatus,
            int historicTotalRuns,
            int historicHaring)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _NewHasherModel():
        return $default(
            _that.publicHasherId,
            _that.publicKennelId,
            _that.hashName,
            _that.firstName,
            _that.lastName,
            _that.eMail,
            _that.addHasherStatus,
            _that.historicTotalRuns,
            _that.historicHaring);
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
            String? publicHasherId,
            String? publicKennelId,
            String? hashName,
            String? firstName,
            String? lastName,
            String? eMail,
            String? addHasherStatus,
            int historicTotalRuns,
            int historicHaring)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _NewHasherModel() when $default != null:
        return $default(
            _that.publicHasherId,
            _that.publicKennelId,
            _that.hashName,
            _that.firstName,
            _that.lastName,
            _that.eMail,
            _that.addHasherStatus,
            _that.historicTotalRuns,
            _that.historicHaring);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _NewHasherModel with DiagnosticableTreeMixin implements NewHasherModel {
  _NewHasherModel(
      {this.publicHasherId,
      this.publicKennelId,
      this.hashName,
      this.firstName,
      this.lastName,
      this.eMail,
      this.addHasherStatus,
      this.historicTotalRuns = 0,
      this.historicHaring = 0});
  factory _NewHasherModel.fromJson(Map<String, dynamic> json) =>
      _$NewHasherModelFromJson(json);

  @override
  final String? publicHasherId;
  @override
  final String? publicKennelId;
  @override
  final String? hashName;
  @override
  final String? firstName;
  @override
  final String? lastName;
  @override
  final String? eMail;
  @override
  final String? addHasherStatus;
  @override
  @JsonKey()
  final int historicTotalRuns;
  @override
  @JsonKey()
  final int historicHaring;

  /// Create a copy of NewHasherModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$NewHasherModelCopyWith<_NewHasherModel> get copyWith =>
      __$NewHasherModelCopyWithImpl<_NewHasherModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$NewHasherModelToJson(
      this,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'NewHasherModel'))
      ..add(DiagnosticsProperty('publicHasherId', publicHasherId))
      ..add(DiagnosticsProperty('publicKennelId', publicKennelId))
      ..add(DiagnosticsProperty('hashName', hashName))
      ..add(DiagnosticsProperty('firstName', firstName))
      ..add(DiagnosticsProperty('lastName', lastName))
      ..add(DiagnosticsProperty('eMail', eMail))
      ..add(DiagnosticsProperty('addHasherStatus', addHasherStatus))
      ..add(DiagnosticsProperty('historicTotalRuns', historicTotalRuns))
      ..add(DiagnosticsProperty('historicHaring', historicHaring));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _NewHasherModel &&
            (identical(other.publicHasherId, publicHasherId) ||
                other.publicHasherId == publicHasherId) &&
            (identical(other.publicKennelId, publicKennelId) ||
                other.publicKennelId == publicKennelId) &&
            (identical(other.hashName, hashName) ||
                other.hashName == hashName) &&
            (identical(other.firstName, firstName) ||
                other.firstName == firstName) &&
            (identical(other.lastName, lastName) ||
                other.lastName == lastName) &&
            (identical(other.eMail, eMail) || other.eMail == eMail) &&
            (identical(other.addHasherStatus, addHasherStatus) ||
                other.addHasherStatus == addHasherStatus) &&
            (identical(other.historicTotalRuns, historicTotalRuns) ||
                other.historicTotalRuns == historicTotalRuns) &&
            (identical(other.historicHaring, historicHaring) ||
                other.historicHaring == historicHaring));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      publicHasherId,
      publicKennelId,
      hashName,
      firstName,
      lastName,
      eMail,
      addHasherStatus,
      historicTotalRuns,
      historicHaring);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'NewHasherModel(publicHasherId: $publicHasherId, publicKennelId: $publicKennelId, hashName: $hashName, firstName: $firstName, lastName: $lastName, eMail: $eMail, addHasherStatus: $addHasherStatus, historicTotalRuns: $historicTotalRuns, historicHaring: $historicHaring)';
  }
}

/// @nodoc
abstract mixin class _$NewHasherModelCopyWith<$Res>
    implements $NewHasherModelCopyWith<$Res> {
  factory _$NewHasherModelCopyWith(
          _NewHasherModel value, $Res Function(_NewHasherModel) _then) =
      __$NewHasherModelCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String? publicHasherId,
      String? publicKennelId,
      String? hashName,
      String? firstName,
      String? lastName,
      String? eMail,
      String? addHasherStatus,
      int historicTotalRuns,
      int historicHaring});
}

/// @nodoc
class __$NewHasherModelCopyWithImpl<$Res>
    implements _$NewHasherModelCopyWith<$Res> {
  __$NewHasherModelCopyWithImpl(this._self, this._then);

  final _NewHasherModel _self;
  final $Res Function(_NewHasherModel) _then;

  /// Create a copy of NewHasherModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? publicHasherId = freezed,
    Object? publicKennelId = freezed,
    Object? hashName = freezed,
    Object? firstName = freezed,
    Object? lastName = freezed,
    Object? eMail = freezed,
    Object? addHasherStatus = freezed,
    Object? historicTotalRuns = null,
    Object? historicHaring = null,
  }) {
    return _then(_NewHasherModel(
      publicHasherId: freezed == publicHasherId
          ? _self.publicHasherId
          : publicHasherId // ignore: cast_nullable_to_non_nullable
              as String?,
      publicKennelId: freezed == publicKennelId
          ? _self.publicKennelId
          : publicKennelId // ignore: cast_nullable_to_non_nullable
              as String?,
      hashName: freezed == hashName
          ? _self.hashName
          : hashName // ignore: cast_nullable_to_non_nullable
              as String?,
      firstName: freezed == firstName
          ? _self.firstName
          : firstName // ignore: cast_nullable_to_non_nullable
              as String?,
      lastName: freezed == lastName
          ? _self.lastName
          : lastName // ignore: cast_nullable_to_non_nullable
              as String?,
      eMail: freezed == eMail
          ? _self.eMail
          : eMail // ignore: cast_nullable_to_non_nullable
              as String?,
      addHasherStatus: freezed == addHasherStatus
          ? _self.addHasherStatus
          : addHasherStatus // ignore: cast_nullable_to_non_nullable
              as String?,
      historicTotalRuns: null == historicTotalRuns
          ? _self.historicTotalRuns
          : historicTotalRuns // ignore: cast_nullable_to_non_nullable
              as int,
      historicHaring: null == historicHaring
          ? _self.historicHaring
          : historicHaring // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

// dart format on
