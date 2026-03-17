// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'usage_data_app_activity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UdAppActivityModel implements DiagnosticableTreeMixin {
  String get dataType;
  int get lastHour;
  int get lastHourComp;
  int get lastDay;
  int get lastDayComp;
  int get lastWeek;
  int get lastWeekComp;
  int get lastMonth;
  int get lastMonthComp;

  /// Create a copy of UdAppActivityModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $UdAppActivityModelCopyWith<UdAppActivityModel> get copyWith =>
      _$UdAppActivityModelCopyWithImpl<UdAppActivityModel>(
          this as UdAppActivityModel, _$identity);

  /// Serializes this UdAppActivityModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'UdAppActivityModel'))
      ..add(DiagnosticsProperty('dataType', dataType))
      ..add(DiagnosticsProperty('lastHour', lastHour))
      ..add(DiagnosticsProperty('lastHourComp', lastHourComp))
      ..add(DiagnosticsProperty('lastDay', lastDay))
      ..add(DiagnosticsProperty('lastDayComp', lastDayComp))
      ..add(DiagnosticsProperty('lastWeek', lastWeek))
      ..add(DiagnosticsProperty('lastWeekComp', lastWeekComp))
      ..add(DiagnosticsProperty('lastMonth', lastMonth))
      ..add(DiagnosticsProperty('lastMonthComp', lastMonthComp));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is UdAppActivityModel &&
            (identical(other.dataType, dataType) ||
                other.dataType == dataType) &&
            (identical(other.lastHour, lastHour) ||
                other.lastHour == lastHour) &&
            (identical(other.lastHourComp, lastHourComp) ||
                other.lastHourComp == lastHourComp) &&
            (identical(other.lastDay, lastDay) || other.lastDay == lastDay) &&
            (identical(other.lastDayComp, lastDayComp) ||
                other.lastDayComp == lastDayComp) &&
            (identical(other.lastWeek, lastWeek) ||
                other.lastWeek == lastWeek) &&
            (identical(other.lastWeekComp, lastWeekComp) ||
                other.lastWeekComp == lastWeekComp) &&
            (identical(other.lastMonth, lastMonth) ||
                other.lastMonth == lastMonth) &&
            (identical(other.lastMonthComp, lastMonthComp) ||
                other.lastMonthComp == lastMonthComp));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, dataType, lastHour, lastHourComp,
      lastDay, lastDayComp, lastWeek, lastWeekComp, lastMonth, lastMonthComp);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'UdAppActivityModel(dataType: $dataType, lastHour: $lastHour, lastHourComp: $lastHourComp, lastDay: $lastDay, lastDayComp: $lastDayComp, lastWeek: $lastWeek, lastWeekComp: $lastWeekComp, lastMonth: $lastMonth, lastMonthComp: $lastMonthComp)';
  }
}

/// @nodoc
abstract mixin class $UdAppActivityModelCopyWith<$Res> {
  factory $UdAppActivityModelCopyWith(
          UdAppActivityModel value, $Res Function(UdAppActivityModel) _then) =
      _$UdAppActivityModelCopyWithImpl;
  @useResult
  $Res call(
      {String dataType,
      int lastHour,
      int lastHourComp,
      int lastDay,
      int lastDayComp,
      int lastWeek,
      int lastWeekComp,
      int lastMonth,
      int lastMonthComp});
}

/// @nodoc
class _$UdAppActivityModelCopyWithImpl<$Res>
    implements $UdAppActivityModelCopyWith<$Res> {
  _$UdAppActivityModelCopyWithImpl(this._self, this._then);

  final UdAppActivityModel _self;
  final $Res Function(UdAppActivityModel) _then;

  /// Create a copy of UdAppActivityModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? dataType = null,
    Object? lastHour = null,
    Object? lastHourComp = null,
    Object? lastDay = null,
    Object? lastDayComp = null,
    Object? lastWeek = null,
    Object? lastWeekComp = null,
    Object? lastMonth = null,
    Object? lastMonthComp = null,
  }) {
    return _then(_self.copyWith(
      dataType: null == dataType
          ? _self.dataType
          : dataType // ignore: cast_nullable_to_non_nullable
              as String,
      lastHour: null == lastHour
          ? _self.lastHour
          : lastHour // ignore: cast_nullable_to_non_nullable
              as int,
      lastHourComp: null == lastHourComp
          ? _self.lastHourComp
          : lastHourComp // ignore: cast_nullable_to_non_nullable
              as int,
      lastDay: null == lastDay
          ? _self.lastDay
          : lastDay // ignore: cast_nullable_to_non_nullable
              as int,
      lastDayComp: null == lastDayComp
          ? _self.lastDayComp
          : lastDayComp // ignore: cast_nullable_to_non_nullable
              as int,
      lastWeek: null == lastWeek
          ? _self.lastWeek
          : lastWeek // ignore: cast_nullable_to_non_nullable
              as int,
      lastWeekComp: null == lastWeekComp
          ? _self.lastWeekComp
          : lastWeekComp // ignore: cast_nullable_to_non_nullable
              as int,
      lastMonth: null == lastMonth
          ? _self.lastMonth
          : lastMonth // ignore: cast_nullable_to_non_nullable
              as int,
      lastMonthComp: null == lastMonthComp
          ? _self.lastMonthComp
          : lastMonthComp // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// Adds pattern-matching-related methods to [UdAppActivityModel].
extension UdAppActivityModelPatterns on UdAppActivityModel {
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
    TResult Function(_UdAppActivityModel value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _UdAppActivityModel() when $default != null:
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
    TResult Function(_UdAppActivityModel value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UdAppActivityModel():
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
    TResult? Function(_UdAppActivityModel value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UdAppActivityModel() when $default != null:
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
            String dataType,
            int lastHour,
            int lastHourComp,
            int lastDay,
            int lastDayComp,
            int lastWeek,
            int lastWeekComp,
            int lastMonth,
            int lastMonthComp)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _UdAppActivityModel() when $default != null:
        return $default(
            _that.dataType,
            _that.lastHour,
            _that.lastHourComp,
            _that.lastDay,
            _that.lastDayComp,
            _that.lastWeek,
            _that.lastWeekComp,
            _that.lastMonth,
            _that.lastMonthComp);
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
            String dataType,
            int lastHour,
            int lastHourComp,
            int lastDay,
            int lastDayComp,
            int lastWeek,
            int lastWeekComp,
            int lastMonth,
            int lastMonthComp)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UdAppActivityModel():
        return $default(
            _that.dataType,
            _that.lastHour,
            _that.lastHourComp,
            _that.lastDay,
            _that.lastDayComp,
            _that.lastWeek,
            _that.lastWeekComp,
            _that.lastMonth,
            _that.lastMonthComp);
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
            String dataType,
            int lastHour,
            int lastHourComp,
            int lastDay,
            int lastDayComp,
            int lastWeek,
            int lastWeekComp,
            int lastMonth,
            int lastMonthComp)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UdAppActivityModel() when $default != null:
        return $default(
            _that.dataType,
            _that.lastHour,
            _that.lastHourComp,
            _that.lastDay,
            _that.lastDayComp,
            _that.lastWeek,
            _that.lastWeekComp,
            _that.lastMonth,
            _that.lastMonthComp);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _UdAppActivityModel
    with DiagnosticableTreeMixin
    implements UdAppActivityModel {
  _UdAppActivityModel(
      {required this.dataType,
      required this.lastHour,
      required this.lastHourComp,
      required this.lastDay,
      required this.lastDayComp,
      required this.lastWeek,
      required this.lastWeekComp,
      required this.lastMonth,
      required this.lastMonthComp});
  factory _UdAppActivityModel.fromJson(Map<String, dynamic> json) =>
      _$UdAppActivityModelFromJson(json);

  @override
  final String dataType;
  @override
  final int lastHour;
  @override
  final int lastHourComp;
  @override
  final int lastDay;
  @override
  final int lastDayComp;
  @override
  final int lastWeek;
  @override
  final int lastWeekComp;
  @override
  final int lastMonth;
  @override
  final int lastMonthComp;

  /// Create a copy of UdAppActivityModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$UdAppActivityModelCopyWith<_UdAppActivityModel> get copyWith =>
      __$UdAppActivityModelCopyWithImpl<_UdAppActivityModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$UdAppActivityModelToJson(
      this,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'UdAppActivityModel'))
      ..add(DiagnosticsProperty('dataType', dataType))
      ..add(DiagnosticsProperty('lastHour', lastHour))
      ..add(DiagnosticsProperty('lastHourComp', lastHourComp))
      ..add(DiagnosticsProperty('lastDay', lastDay))
      ..add(DiagnosticsProperty('lastDayComp', lastDayComp))
      ..add(DiagnosticsProperty('lastWeek', lastWeek))
      ..add(DiagnosticsProperty('lastWeekComp', lastWeekComp))
      ..add(DiagnosticsProperty('lastMonth', lastMonth))
      ..add(DiagnosticsProperty('lastMonthComp', lastMonthComp));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _UdAppActivityModel &&
            (identical(other.dataType, dataType) ||
                other.dataType == dataType) &&
            (identical(other.lastHour, lastHour) ||
                other.lastHour == lastHour) &&
            (identical(other.lastHourComp, lastHourComp) ||
                other.lastHourComp == lastHourComp) &&
            (identical(other.lastDay, lastDay) || other.lastDay == lastDay) &&
            (identical(other.lastDayComp, lastDayComp) ||
                other.lastDayComp == lastDayComp) &&
            (identical(other.lastWeek, lastWeek) ||
                other.lastWeek == lastWeek) &&
            (identical(other.lastWeekComp, lastWeekComp) ||
                other.lastWeekComp == lastWeekComp) &&
            (identical(other.lastMonth, lastMonth) ||
                other.lastMonth == lastMonth) &&
            (identical(other.lastMonthComp, lastMonthComp) ||
                other.lastMonthComp == lastMonthComp));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, dataType, lastHour, lastHourComp,
      lastDay, lastDayComp, lastWeek, lastWeekComp, lastMonth, lastMonthComp);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'UdAppActivityModel(dataType: $dataType, lastHour: $lastHour, lastHourComp: $lastHourComp, lastDay: $lastDay, lastDayComp: $lastDayComp, lastWeek: $lastWeek, lastWeekComp: $lastWeekComp, lastMonth: $lastMonth, lastMonthComp: $lastMonthComp)';
  }
}

/// @nodoc
abstract mixin class _$UdAppActivityModelCopyWith<$Res>
    implements $UdAppActivityModelCopyWith<$Res> {
  factory _$UdAppActivityModelCopyWith(
          _UdAppActivityModel value, $Res Function(_UdAppActivityModel) _then) =
      __$UdAppActivityModelCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String dataType,
      int lastHour,
      int lastHourComp,
      int lastDay,
      int lastDayComp,
      int lastWeek,
      int lastWeekComp,
      int lastMonth,
      int lastMonthComp});
}

/// @nodoc
class __$UdAppActivityModelCopyWithImpl<$Res>
    implements _$UdAppActivityModelCopyWith<$Res> {
  __$UdAppActivityModelCopyWithImpl(this._self, this._then);

  final _UdAppActivityModel _self;
  final $Res Function(_UdAppActivityModel) _then;

  /// Create a copy of UdAppActivityModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? dataType = null,
    Object? lastHour = null,
    Object? lastHourComp = null,
    Object? lastDay = null,
    Object? lastDayComp = null,
    Object? lastWeek = null,
    Object? lastWeekComp = null,
    Object? lastMonth = null,
    Object? lastMonthComp = null,
  }) {
    return _then(_UdAppActivityModel(
      dataType: null == dataType
          ? _self.dataType
          : dataType // ignore: cast_nullable_to_non_nullable
              as String,
      lastHour: null == lastHour
          ? _self.lastHour
          : lastHour // ignore: cast_nullable_to_non_nullable
              as int,
      lastHourComp: null == lastHourComp
          ? _self.lastHourComp
          : lastHourComp // ignore: cast_nullable_to_non_nullable
              as int,
      lastDay: null == lastDay
          ? _self.lastDay
          : lastDay // ignore: cast_nullable_to_non_nullable
              as int,
      lastDayComp: null == lastDayComp
          ? _self.lastDayComp
          : lastDayComp // ignore: cast_nullable_to_non_nullable
              as int,
      lastWeek: null == lastWeek
          ? _self.lastWeek
          : lastWeek // ignore: cast_nullable_to_non_nullable
              as int,
      lastWeekComp: null == lastWeekComp
          ? _self.lastWeekComp
          : lastWeekComp // ignore: cast_nullable_to_non_nullable
              as int,
      lastMonth: null == lastMonth
          ? _self.lastMonth
          : lastMonth // ignore: cast_nullable_to_non_nullable
              as int,
      lastMonthComp: null == lastMonthComp
          ? _self.lastMonthComp
          : lastMonthComp // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

// dart format on
