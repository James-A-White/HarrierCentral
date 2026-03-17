// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'participant_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ParticipantModel {
  String get displayName;
  int get rsvpState;
  int get attendanceState;
  int get totalRunsThisKennel;
  int get totalHaringThisKennel;
  String get amountPaidStr;
  String get amountOwedStr;
  String get creditAvailableStr;
  int get virginVisitorType;

  /// Create a copy of ParticipantModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ParticipantModelCopyWith<ParticipantModel> get copyWith =>
      _$ParticipantModelCopyWithImpl<ParticipantModel>(
          this as ParticipantModel, _$identity);

  /// Serializes this ParticipantModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ParticipantModel &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.rsvpState, rsvpState) ||
                other.rsvpState == rsvpState) &&
            (identical(other.attendanceState, attendanceState) ||
                other.attendanceState == attendanceState) &&
            (identical(other.totalRunsThisKennel, totalRunsThisKennel) ||
                other.totalRunsThisKennel == totalRunsThisKennel) &&
            (identical(other.totalHaringThisKennel, totalHaringThisKennel) ||
                other.totalHaringThisKennel == totalHaringThisKennel) &&
            (identical(other.amountPaidStr, amountPaidStr) ||
                other.amountPaidStr == amountPaidStr) &&
            (identical(other.amountOwedStr, amountOwedStr) ||
                other.amountOwedStr == amountOwedStr) &&
            (identical(other.creditAvailableStr, creditAvailableStr) ||
                other.creditAvailableStr == creditAvailableStr) &&
            (identical(other.virginVisitorType, virginVisitorType) ||
                other.virginVisitorType == virginVisitorType));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      displayName,
      rsvpState,
      attendanceState,
      totalRunsThisKennel,
      totalHaringThisKennel,
      amountPaidStr,
      amountOwedStr,
      creditAvailableStr,
      virginVisitorType);

  @override
  String toString() {
    return 'ParticipantModel(displayName: $displayName, rsvpState: $rsvpState, attendanceState: $attendanceState, totalRunsThisKennel: $totalRunsThisKennel, totalHaringThisKennel: $totalHaringThisKennel, amountPaidStr: $amountPaidStr, amountOwedStr: $amountOwedStr, creditAvailableStr: $creditAvailableStr, virginVisitorType: $virginVisitorType)';
  }
}

/// @nodoc
abstract mixin class $ParticipantModelCopyWith<$Res> {
  factory $ParticipantModelCopyWith(
          ParticipantModel value, $Res Function(ParticipantModel) _then) =
      _$ParticipantModelCopyWithImpl;
  @useResult
  $Res call(
      {String displayName,
      int rsvpState,
      int attendanceState,
      int totalRunsThisKennel,
      int totalHaringThisKennel,
      String amountPaidStr,
      String amountOwedStr,
      String creditAvailableStr,
      int virginVisitorType});
}

/// @nodoc
class _$ParticipantModelCopyWithImpl<$Res>
    implements $ParticipantModelCopyWith<$Res> {
  _$ParticipantModelCopyWithImpl(this._self, this._then);

  final ParticipantModel _self;
  final $Res Function(ParticipantModel) _then;

  /// Create a copy of ParticipantModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? displayName = null,
    Object? rsvpState = null,
    Object? attendanceState = null,
    Object? totalRunsThisKennel = null,
    Object? totalHaringThisKennel = null,
    Object? amountPaidStr = null,
    Object? amountOwedStr = null,
    Object? creditAvailableStr = null,
    Object? virginVisitorType = null,
  }) {
    return _then(_self.copyWith(
      displayName: null == displayName
          ? _self.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      rsvpState: null == rsvpState
          ? _self.rsvpState
          : rsvpState // ignore: cast_nullable_to_non_nullable
              as int,
      attendanceState: null == attendanceState
          ? _self.attendanceState
          : attendanceState // ignore: cast_nullable_to_non_nullable
              as int,
      totalRunsThisKennel: null == totalRunsThisKennel
          ? _self.totalRunsThisKennel
          : totalRunsThisKennel // ignore: cast_nullable_to_non_nullable
              as int,
      totalHaringThisKennel: null == totalHaringThisKennel
          ? _self.totalHaringThisKennel
          : totalHaringThisKennel // ignore: cast_nullable_to_non_nullable
              as int,
      amountPaidStr: null == amountPaidStr
          ? _self.amountPaidStr
          : amountPaidStr // ignore: cast_nullable_to_non_nullable
              as String,
      amountOwedStr: null == amountOwedStr
          ? _self.amountOwedStr
          : amountOwedStr // ignore: cast_nullable_to_non_nullable
              as String,
      creditAvailableStr: null == creditAvailableStr
          ? _self.creditAvailableStr
          : creditAvailableStr // ignore: cast_nullable_to_non_nullable
              as String,
      virginVisitorType: null == virginVisitorType
          ? _self.virginVisitorType
          : virginVisitorType // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// Adds pattern-matching-related methods to [ParticipantModel].
extension ParticipantModelPatterns on ParticipantModel {
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
    TResult Function(_ParticipantModel value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ParticipantModel() when $default != null:
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
    TResult Function(_ParticipantModel value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ParticipantModel():
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
    TResult? Function(_ParticipantModel value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ParticipantModel() when $default != null:
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
            String displayName,
            int rsvpState,
            int attendanceState,
            int totalRunsThisKennel,
            int totalHaringThisKennel,
            String amountPaidStr,
            String amountOwedStr,
            String creditAvailableStr,
            int virginVisitorType)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ParticipantModel() when $default != null:
        return $default(
            _that.displayName,
            _that.rsvpState,
            _that.attendanceState,
            _that.totalRunsThisKennel,
            _that.totalHaringThisKennel,
            _that.amountPaidStr,
            _that.amountOwedStr,
            _that.creditAvailableStr,
            _that.virginVisitorType);
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
            String displayName,
            int rsvpState,
            int attendanceState,
            int totalRunsThisKennel,
            int totalHaringThisKennel,
            String amountPaidStr,
            String amountOwedStr,
            String creditAvailableStr,
            int virginVisitorType)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ParticipantModel():
        return $default(
            _that.displayName,
            _that.rsvpState,
            _that.attendanceState,
            _that.totalRunsThisKennel,
            _that.totalHaringThisKennel,
            _that.amountPaidStr,
            _that.amountOwedStr,
            _that.creditAvailableStr,
            _that.virginVisitorType);
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
            String displayName,
            int rsvpState,
            int attendanceState,
            int totalRunsThisKennel,
            int totalHaringThisKennel,
            String amountPaidStr,
            String amountOwedStr,
            String creditAvailableStr,
            int virginVisitorType)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ParticipantModel() when $default != null:
        return $default(
            _that.displayName,
            _that.rsvpState,
            _that.attendanceState,
            _that.totalRunsThisKennel,
            _that.totalHaringThisKennel,
            _that.amountPaidStr,
            _that.amountOwedStr,
            _that.creditAvailableStr,
            _that.virginVisitorType);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _ParticipantModel implements ParticipantModel {
  const _ParticipantModel(
      {required this.displayName,
      required this.rsvpState,
      required this.attendanceState,
      required this.totalRunsThisKennel,
      required this.totalHaringThisKennel,
      required this.amountPaidStr,
      required this.amountOwedStr,
      required this.creditAvailableStr,
      required this.virginVisitorType});
  factory _ParticipantModel.fromJson(Map<String, dynamic> json) =>
      _$ParticipantModelFromJson(json);

  @override
  final String displayName;
  @override
  final int rsvpState;
  @override
  final int attendanceState;
  @override
  final int totalRunsThisKennel;
  @override
  final int totalHaringThisKennel;
  @override
  final String amountPaidStr;
  @override
  final String amountOwedStr;
  @override
  final String creditAvailableStr;
  @override
  final int virginVisitorType;

  /// Create a copy of ParticipantModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ParticipantModelCopyWith<_ParticipantModel> get copyWith =>
      __$ParticipantModelCopyWithImpl<_ParticipantModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ParticipantModelToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ParticipantModel &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.rsvpState, rsvpState) ||
                other.rsvpState == rsvpState) &&
            (identical(other.attendanceState, attendanceState) ||
                other.attendanceState == attendanceState) &&
            (identical(other.totalRunsThisKennel, totalRunsThisKennel) ||
                other.totalRunsThisKennel == totalRunsThisKennel) &&
            (identical(other.totalHaringThisKennel, totalHaringThisKennel) ||
                other.totalHaringThisKennel == totalHaringThisKennel) &&
            (identical(other.amountPaidStr, amountPaidStr) ||
                other.amountPaidStr == amountPaidStr) &&
            (identical(other.amountOwedStr, amountOwedStr) ||
                other.amountOwedStr == amountOwedStr) &&
            (identical(other.creditAvailableStr, creditAvailableStr) ||
                other.creditAvailableStr == creditAvailableStr) &&
            (identical(other.virginVisitorType, virginVisitorType) ||
                other.virginVisitorType == virginVisitorType));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      displayName,
      rsvpState,
      attendanceState,
      totalRunsThisKennel,
      totalHaringThisKennel,
      amountPaidStr,
      amountOwedStr,
      creditAvailableStr,
      virginVisitorType);

  @override
  String toString() {
    return 'ParticipantModel(displayName: $displayName, rsvpState: $rsvpState, attendanceState: $attendanceState, totalRunsThisKennel: $totalRunsThisKennel, totalHaringThisKennel: $totalHaringThisKennel, amountPaidStr: $amountPaidStr, amountOwedStr: $amountOwedStr, creditAvailableStr: $creditAvailableStr, virginVisitorType: $virginVisitorType)';
  }
}

/// @nodoc
abstract mixin class _$ParticipantModelCopyWith<$Res>
    implements $ParticipantModelCopyWith<$Res> {
  factory _$ParticipantModelCopyWith(
          _ParticipantModel value, $Res Function(_ParticipantModel) _then) =
      __$ParticipantModelCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String displayName,
      int rsvpState,
      int attendanceState,
      int totalRunsThisKennel,
      int totalHaringThisKennel,
      String amountPaidStr,
      String amountOwedStr,
      String creditAvailableStr,
      int virginVisitorType});
}

/// @nodoc
class __$ParticipantModelCopyWithImpl<$Res>
    implements _$ParticipantModelCopyWith<$Res> {
  __$ParticipantModelCopyWithImpl(this._self, this._then);

  final _ParticipantModel _self;
  final $Res Function(_ParticipantModel) _then;

  /// Create a copy of ParticipantModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? displayName = null,
    Object? rsvpState = null,
    Object? attendanceState = null,
    Object? totalRunsThisKennel = null,
    Object? totalHaringThisKennel = null,
    Object? amountPaidStr = null,
    Object? amountOwedStr = null,
    Object? creditAvailableStr = null,
    Object? virginVisitorType = null,
  }) {
    return _then(_ParticipantModel(
      displayName: null == displayName
          ? _self.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      rsvpState: null == rsvpState
          ? _self.rsvpState
          : rsvpState // ignore: cast_nullable_to_non_nullable
              as int,
      attendanceState: null == attendanceState
          ? _self.attendanceState
          : attendanceState // ignore: cast_nullable_to_non_nullable
              as int,
      totalRunsThisKennel: null == totalRunsThisKennel
          ? _self.totalRunsThisKennel
          : totalRunsThisKennel // ignore: cast_nullable_to_non_nullable
              as int,
      totalHaringThisKennel: null == totalHaringThisKennel
          ? _self.totalHaringThisKennel
          : totalHaringThisKennel // ignore: cast_nullable_to_non_nullable
              as int,
      amountPaidStr: null == amountPaidStr
          ? _self.amountPaidStr
          : amountPaidStr // ignore: cast_nullable_to_non_nullable
              as String,
      amountOwedStr: null == amountOwedStr
          ? _self.amountOwedStr
          : amountOwedStr // ignore: cast_nullable_to_non_nullable
              as String,
      creditAvailableStr: null == creditAvailableStr
          ? _self.creditAvailableStr
          : creditAvailableStr // ignore: cast_nullable_to_non_nullable
              as String,
      virginVisitorType: null == virginVisitorType
          ? _self.virginVisitorType
          : virginVisitorType // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

// dart format on
