// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'usage_data_new_events.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UdNewEventsModel implements DiagnosticableTreeMixin {
  String get kennelName;
  String get kennelShortName;
  String get kennelLogo;
  String get eventName;
  int get minutesAgoUpdated;
  int get minutesAgoCreated;
  int get minutesUntilRun;
  int get activityLastDay;
  String get publicEventId;

  /// Create a copy of UdNewEventsModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $UdNewEventsModelCopyWith<UdNewEventsModel> get copyWith =>
      _$UdNewEventsModelCopyWithImpl<UdNewEventsModel>(
          this as UdNewEventsModel, _$identity);

  /// Serializes this UdNewEventsModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'UdNewEventsModel'))
      ..add(DiagnosticsProperty('kennelName', kennelName))
      ..add(DiagnosticsProperty('kennelShortName', kennelShortName))
      ..add(DiagnosticsProperty('kennelLogo', kennelLogo))
      ..add(DiagnosticsProperty('eventName', eventName))
      ..add(DiagnosticsProperty('minutesAgoUpdated', minutesAgoUpdated))
      ..add(DiagnosticsProperty('minutesAgoCreated', minutesAgoCreated))
      ..add(DiagnosticsProperty('minutesUntilRun', minutesUntilRun))
      ..add(DiagnosticsProperty('activityLastDay', activityLastDay))
      ..add(DiagnosticsProperty('publicEventId', publicEventId));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is UdNewEventsModel &&
            (identical(other.kennelName, kennelName) ||
                other.kennelName == kennelName) &&
            (identical(other.kennelShortName, kennelShortName) ||
                other.kennelShortName == kennelShortName) &&
            (identical(other.kennelLogo, kennelLogo) ||
                other.kennelLogo == kennelLogo) &&
            (identical(other.eventName, eventName) ||
                other.eventName == eventName) &&
            (identical(other.minutesAgoUpdated, minutesAgoUpdated) ||
                other.minutesAgoUpdated == minutesAgoUpdated) &&
            (identical(other.minutesAgoCreated, minutesAgoCreated) ||
                other.minutesAgoCreated == minutesAgoCreated) &&
            (identical(other.minutesUntilRun, minutesUntilRun) ||
                other.minutesUntilRun == minutesUntilRun) &&
            (identical(other.activityLastDay, activityLastDay) ||
                other.activityLastDay == activityLastDay) &&
            (identical(other.publicEventId, publicEventId) ||
                other.publicEventId == publicEventId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      kennelName,
      kennelShortName,
      kennelLogo,
      eventName,
      minutesAgoUpdated,
      minutesAgoCreated,
      minutesUntilRun,
      activityLastDay,
      publicEventId);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'UdNewEventsModel(kennelName: $kennelName, kennelShortName: $kennelShortName, kennelLogo: $kennelLogo, eventName: $eventName, minutesAgoUpdated: $minutesAgoUpdated, minutesAgoCreated: $minutesAgoCreated, minutesUntilRun: $minutesUntilRun, activityLastDay: $activityLastDay, publicEventId: $publicEventId)';
  }
}

/// @nodoc
abstract mixin class $UdNewEventsModelCopyWith<$Res> {
  factory $UdNewEventsModelCopyWith(
          UdNewEventsModel value, $Res Function(UdNewEventsModel) _then) =
      _$UdNewEventsModelCopyWithImpl;
  @useResult
  $Res call(
      {String kennelName,
      String kennelShortName,
      String kennelLogo,
      String eventName,
      int minutesAgoUpdated,
      int minutesAgoCreated,
      int minutesUntilRun,
      int activityLastDay,
      String publicEventId});
}

/// @nodoc
class _$UdNewEventsModelCopyWithImpl<$Res>
    implements $UdNewEventsModelCopyWith<$Res> {
  _$UdNewEventsModelCopyWithImpl(this._self, this._then);

  final UdNewEventsModel _self;
  final $Res Function(UdNewEventsModel) _then;

  /// Create a copy of UdNewEventsModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? kennelName = null,
    Object? kennelShortName = null,
    Object? kennelLogo = null,
    Object? eventName = null,
    Object? minutesAgoUpdated = null,
    Object? minutesAgoCreated = null,
    Object? minutesUntilRun = null,
    Object? activityLastDay = null,
    Object? publicEventId = null,
  }) {
    return _then(_self.copyWith(
      kennelName: null == kennelName
          ? _self.kennelName
          : kennelName // ignore: cast_nullable_to_non_nullable
              as String,
      kennelShortName: null == kennelShortName
          ? _self.kennelShortName
          : kennelShortName // ignore: cast_nullable_to_non_nullable
              as String,
      kennelLogo: null == kennelLogo
          ? _self.kennelLogo
          : kennelLogo // ignore: cast_nullable_to_non_nullable
              as String,
      eventName: null == eventName
          ? _self.eventName
          : eventName // ignore: cast_nullable_to_non_nullable
              as String,
      minutesAgoUpdated: null == minutesAgoUpdated
          ? _self.minutesAgoUpdated
          : minutesAgoUpdated // ignore: cast_nullable_to_non_nullable
              as int,
      minutesAgoCreated: null == minutesAgoCreated
          ? _self.minutesAgoCreated
          : minutesAgoCreated // ignore: cast_nullable_to_non_nullable
              as int,
      minutesUntilRun: null == minutesUntilRun
          ? _self.minutesUntilRun
          : minutesUntilRun // ignore: cast_nullable_to_non_nullable
              as int,
      activityLastDay: null == activityLastDay
          ? _self.activityLastDay
          : activityLastDay // ignore: cast_nullable_to_non_nullable
              as int,
      publicEventId: null == publicEventId
          ? _self.publicEventId
          : publicEventId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// Adds pattern-matching-related methods to [UdNewEventsModel].
extension UdNewEventsModelPatterns on UdNewEventsModel {
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
    TResult Function(_UdNewEventsModel value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _UdNewEventsModel() when $default != null:
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
    TResult Function(_UdNewEventsModel value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UdNewEventsModel():
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
    TResult? Function(_UdNewEventsModel value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UdNewEventsModel() when $default != null:
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
            String kennelName,
            String kennelShortName,
            String kennelLogo,
            String eventName,
            int minutesAgoUpdated,
            int minutesAgoCreated,
            int minutesUntilRun,
            int activityLastDay,
            String publicEventId)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _UdNewEventsModel() when $default != null:
        return $default(
            _that.kennelName,
            _that.kennelShortName,
            _that.kennelLogo,
            _that.eventName,
            _that.minutesAgoUpdated,
            _that.minutesAgoCreated,
            _that.minutesUntilRun,
            _that.activityLastDay,
            _that.publicEventId);
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
            String kennelName,
            String kennelShortName,
            String kennelLogo,
            String eventName,
            int minutesAgoUpdated,
            int minutesAgoCreated,
            int minutesUntilRun,
            int activityLastDay,
            String publicEventId)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UdNewEventsModel():
        return $default(
            _that.kennelName,
            _that.kennelShortName,
            _that.kennelLogo,
            _that.eventName,
            _that.minutesAgoUpdated,
            _that.minutesAgoCreated,
            _that.minutesUntilRun,
            _that.activityLastDay,
            _that.publicEventId);
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
            String kennelName,
            String kennelShortName,
            String kennelLogo,
            String eventName,
            int minutesAgoUpdated,
            int minutesAgoCreated,
            int minutesUntilRun,
            int activityLastDay,
            String publicEventId)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UdNewEventsModel() when $default != null:
        return $default(
            _that.kennelName,
            _that.kennelShortName,
            _that.kennelLogo,
            _that.eventName,
            _that.minutesAgoUpdated,
            _that.minutesAgoCreated,
            _that.minutesUntilRun,
            _that.activityLastDay,
            _that.publicEventId);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _UdNewEventsModel
    with DiagnosticableTreeMixin
    implements UdNewEventsModel {
  _UdNewEventsModel(
      {required this.kennelName,
      required this.kennelShortName,
      required this.kennelLogo,
      required this.eventName,
      required this.minutesAgoUpdated,
      required this.minutesAgoCreated,
      required this.minutesUntilRun,
      required this.activityLastDay,
      required this.publicEventId});
  factory _UdNewEventsModel.fromJson(Map<String, dynamic> json) =>
      _$UdNewEventsModelFromJson(json);

  @override
  final String kennelName;
  @override
  final String kennelShortName;
  @override
  final String kennelLogo;
  @override
  final String eventName;
  @override
  final int minutesAgoUpdated;
  @override
  final int minutesAgoCreated;
  @override
  final int minutesUntilRun;
  @override
  final int activityLastDay;
  @override
  final String publicEventId;

  /// Create a copy of UdNewEventsModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$UdNewEventsModelCopyWith<_UdNewEventsModel> get copyWith =>
      __$UdNewEventsModelCopyWithImpl<_UdNewEventsModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$UdNewEventsModelToJson(
      this,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'UdNewEventsModel'))
      ..add(DiagnosticsProperty('kennelName', kennelName))
      ..add(DiagnosticsProperty('kennelShortName', kennelShortName))
      ..add(DiagnosticsProperty('kennelLogo', kennelLogo))
      ..add(DiagnosticsProperty('eventName', eventName))
      ..add(DiagnosticsProperty('minutesAgoUpdated', minutesAgoUpdated))
      ..add(DiagnosticsProperty('minutesAgoCreated', minutesAgoCreated))
      ..add(DiagnosticsProperty('minutesUntilRun', minutesUntilRun))
      ..add(DiagnosticsProperty('activityLastDay', activityLastDay))
      ..add(DiagnosticsProperty('publicEventId', publicEventId));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _UdNewEventsModel &&
            (identical(other.kennelName, kennelName) ||
                other.kennelName == kennelName) &&
            (identical(other.kennelShortName, kennelShortName) ||
                other.kennelShortName == kennelShortName) &&
            (identical(other.kennelLogo, kennelLogo) ||
                other.kennelLogo == kennelLogo) &&
            (identical(other.eventName, eventName) ||
                other.eventName == eventName) &&
            (identical(other.minutesAgoUpdated, minutesAgoUpdated) ||
                other.minutesAgoUpdated == minutesAgoUpdated) &&
            (identical(other.minutesAgoCreated, minutesAgoCreated) ||
                other.minutesAgoCreated == minutesAgoCreated) &&
            (identical(other.minutesUntilRun, minutesUntilRun) ||
                other.minutesUntilRun == minutesUntilRun) &&
            (identical(other.activityLastDay, activityLastDay) ||
                other.activityLastDay == activityLastDay) &&
            (identical(other.publicEventId, publicEventId) ||
                other.publicEventId == publicEventId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      kennelName,
      kennelShortName,
      kennelLogo,
      eventName,
      minutesAgoUpdated,
      minutesAgoCreated,
      minutesUntilRun,
      activityLastDay,
      publicEventId);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'UdNewEventsModel(kennelName: $kennelName, kennelShortName: $kennelShortName, kennelLogo: $kennelLogo, eventName: $eventName, minutesAgoUpdated: $minutesAgoUpdated, minutesAgoCreated: $minutesAgoCreated, minutesUntilRun: $minutesUntilRun, activityLastDay: $activityLastDay, publicEventId: $publicEventId)';
  }
}

/// @nodoc
abstract mixin class _$UdNewEventsModelCopyWith<$Res>
    implements $UdNewEventsModelCopyWith<$Res> {
  factory _$UdNewEventsModelCopyWith(
          _UdNewEventsModel value, $Res Function(_UdNewEventsModel) _then) =
      __$UdNewEventsModelCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String kennelName,
      String kennelShortName,
      String kennelLogo,
      String eventName,
      int minutesAgoUpdated,
      int minutesAgoCreated,
      int minutesUntilRun,
      int activityLastDay,
      String publicEventId});
}

/// @nodoc
class __$UdNewEventsModelCopyWithImpl<$Res>
    implements _$UdNewEventsModelCopyWith<$Res> {
  __$UdNewEventsModelCopyWithImpl(this._self, this._then);

  final _UdNewEventsModel _self;
  final $Res Function(_UdNewEventsModel) _then;

  /// Create a copy of UdNewEventsModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? kennelName = null,
    Object? kennelShortName = null,
    Object? kennelLogo = null,
    Object? eventName = null,
    Object? minutesAgoUpdated = null,
    Object? minutesAgoCreated = null,
    Object? minutesUntilRun = null,
    Object? activityLastDay = null,
    Object? publicEventId = null,
  }) {
    return _then(_UdNewEventsModel(
      kennelName: null == kennelName
          ? _self.kennelName
          : kennelName // ignore: cast_nullable_to_non_nullable
              as String,
      kennelShortName: null == kennelShortName
          ? _self.kennelShortName
          : kennelShortName // ignore: cast_nullable_to_non_nullable
              as String,
      kennelLogo: null == kennelLogo
          ? _self.kennelLogo
          : kennelLogo // ignore: cast_nullable_to_non_nullable
              as String,
      eventName: null == eventName
          ? _self.eventName
          : eventName // ignore: cast_nullable_to_non_nullable
              as String,
      minutesAgoUpdated: null == minutesAgoUpdated
          ? _self.minutesAgoUpdated
          : minutesAgoUpdated // ignore: cast_nullable_to_non_nullable
              as int,
      minutesAgoCreated: null == minutesAgoCreated
          ? _self.minutesAgoCreated
          : minutesAgoCreated // ignore: cast_nullable_to_non_nullable
              as int,
      minutesUntilRun: null == minutesUntilRun
          ? _self.minutesUntilRun
          : minutesUntilRun // ignore: cast_nullable_to_non_nullable
              as int,
      activityLastDay: null == activityLastDay
          ? _self.activityLastDay
          : activityLastDay // ignore: cast_nullable_to_non_nullable
              as int,
      publicEventId: null == publicEventId
          ? _self.publicEventId
          : publicEventId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on
