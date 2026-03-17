// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'usage_data_login_history.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UdLoginHistoryModel implements DiagnosticableTreeMixin {
  DateTime get loginDate;
  String get hcVersion;
  String get systemVersion;
  int get isIphone;
  double get latitude;
  double get longitude;
  String get locationName;

  /// Create a copy of UdLoginHistoryModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $UdLoginHistoryModelCopyWith<UdLoginHistoryModel> get copyWith =>
      _$UdLoginHistoryModelCopyWithImpl<UdLoginHistoryModel>(
          this as UdLoginHistoryModel, _$identity);

  /// Serializes this UdLoginHistoryModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'UdLoginHistoryModel'))
      ..add(DiagnosticsProperty('loginDate', loginDate))
      ..add(DiagnosticsProperty('hcVersion', hcVersion))
      ..add(DiagnosticsProperty('systemVersion', systemVersion))
      ..add(DiagnosticsProperty('isIphone', isIphone))
      ..add(DiagnosticsProperty('latitude', latitude))
      ..add(DiagnosticsProperty('longitude', longitude))
      ..add(DiagnosticsProperty('locationName', locationName));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is UdLoginHistoryModel &&
            (identical(other.loginDate, loginDate) ||
                other.loginDate == loginDate) &&
            (identical(other.hcVersion, hcVersion) ||
                other.hcVersion == hcVersion) &&
            (identical(other.systemVersion, systemVersion) ||
                other.systemVersion == systemVersion) &&
            (identical(other.isIphone, isIphone) ||
                other.isIphone == isIphone) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.locationName, locationName) ||
                other.locationName == locationName));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, loginDate, hcVersion,
      systemVersion, isIphone, latitude, longitude, locationName);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'UdLoginHistoryModel(loginDate: $loginDate, hcVersion: $hcVersion, systemVersion: $systemVersion, isIphone: $isIphone, latitude: $latitude, longitude: $longitude, locationName: $locationName)';
  }
}

/// @nodoc
abstract mixin class $UdLoginHistoryModelCopyWith<$Res> {
  factory $UdLoginHistoryModelCopyWith(
          UdLoginHistoryModel value, $Res Function(UdLoginHistoryModel) _then) =
      _$UdLoginHistoryModelCopyWithImpl;
  @useResult
  $Res call(
      {DateTime loginDate,
      String hcVersion,
      String systemVersion,
      int isIphone,
      double latitude,
      double longitude,
      String locationName});
}

/// @nodoc
class _$UdLoginHistoryModelCopyWithImpl<$Res>
    implements $UdLoginHistoryModelCopyWith<$Res> {
  _$UdLoginHistoryModelCopyWithImpl(this._self, this._then);

  final UdLoginHistoryModel _self;
  final $Res Function(UdLoginHistoryModel) _then;

  /// Create a copy of UdLoginHistoryModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? loginDate = null,
    Object? hcVersion = null,
    Object? systemVersion = null,
    Object? isIphone = null,
    Object? latitude = null,
    Object? longitude = null,
    Object? locationName = null,
  }) {
    return _then(_self.copyWith(
      loginDate: null == loginDate
          ? _self.loginDate
          : loginDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      hcVersion: null == hcVersion
          ? _self.hcVersion
          : hcVersion // ignore: cast_nullable_to_non_nullable
              as String,
      systemVersion: null == systemVersion
          ? _self.systemVersion
          : systemVersion // ignore: cast_nullable_to_non_nullable
              as String,
      isIphone: null == isIphone
          ? _self.isIphone
          : isIphone // ignore: cast_nullable_to_non_nullable
              as int,
      latitude: null == latitude
          ? _self.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double,
      longitude: null == longitude
          ? _self.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double,
      locationName: null == locationName
          ? _self.locationName
          : locationName // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// Adds pattern-matching-related methods to [UdLoginHistoryModel].
extension UdLoginHistoryModelPatterns on UdLoginHistoryModel {
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
    TResult Function(_UdLoginHistoryModel value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _UdLoginHistoryModel() when $default != null:
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
    TResult Function(_UdLoginHistoryModel value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UdLoginHistoryModel():
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
    TResult? Function(_UdLoginHistoryModel value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UdLoginHistoryModel() when $default != null:
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
            DateTime loginDate,
            String hcVersion,
            String systemVersion,
            int isIphone,
            double latitude,
            double longitude,
            String locationName)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _UdLoginHistoryModel() when $default != null:
        return $default(
            _that.loginDate,
            _that.hcVersion,
            _that.systemVersion,
            _that.isIphone,
            _that.latitude,
            _that.longitude,
            _that.locationName);
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
            DateTime loginDate,
            String hcVersion,
            String systemVersion,
            int isIphone,
            double latitude,
            double longitude,
            String locationName)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UdLoginHistoryModel():
        return $default(
            _that.loginDate,
            _that.hcVersion,
            _that.systemVersion,
            _that.isIphone,
            _that.latitude,
            _that.longitude,
            _that.locationName);
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
            DateTime loginDate,
            String hcVersion,
            String systemVersion,
            int isIphone,
            double latitude,
            double longitude,
            String locationName)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UdLoginHistoryModel() when $default != null:
        return $default(
            _that.loginDate,
            _that.hcVersion,
            _that.systemVersion,
            _that.isIphone,
            _that.latitude,
            _that.longitude,
            _that.locationName);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _UdLoginHistoryModel
    with DiagnosticableTreeMixin
    implements UdLoginHistoryModel {
  _UdLoginHistoryModel(
      {required this.loginDate,
      required this.hcVersion,
      required this.systemVersion,
      required this.isIphone,
      this.latitude = 0.0,
      this.longitude = 0.0,
      this.locationName = ''});
  factory _UdLoginHistoryModel.fromJson(Map<String, dynamic> json) =>
      _$UdLoginHistoryModelFromJson(json);

  @override
  final DateTime loginDate;
  @override
  final String hcVersion;
  @override
  final String systemVersion;
  @override
  final int isIphone;
  @override
  @JsonKey()
  final double latitude;
  @override
  @JsonKey()
  final double longitude;
  @override
  @JsonKey()
  final String locationName;

  /// Create a copy of UdLoginHistoryModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$UdLoginHistoryModelCopyWith<_UdLoginHistoryModel> get copyWith =>
      __$UdLoginHistoryModelCopyWithImpl<_UdLoginHistoryModel>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$UdLoginHistoryModelToJson(
      this,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'UdLoginHistoryModel'))
      ..add(DiagnosticsProperty('loginDate', loginDate))
      ..add(DiagnosticsProperty('hcVersion', hcVersion))
      ..add(DiagnosticsProperty('systemVersion', systemVersion))
      ..add(DiagnosticsProperty('isIphone', isIphone))
      ..add(DiagnosticsProperty('latitude', latitude))
      ..add(DiagnosticsProperty('longitude', longitude))
      ..add(DiagnosticsProperty('locationName', locationName));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _UdLoginHistoryModel &&
            (identical(other.loginDate, loginDate) ||
                other.loginDate == loginDate) &&
            (identical(other.hcVersion, hcVersion) ||
                other.hcVersion == hcVersion) &&
            (identical(other.systemVersion, systemVersion) ||
                other.systemVersion == systemVersion) &&
            (identical(other.isIphone, isIphone) ||
                other.isIphone == isIphone) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.locationName, locationName) ||
                other.locationName == locationName));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, loginDate, hcVersion,
      systemVersion, isIphone, latitude, longitude, locationName);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'UdLoginHistoryModel(loginDate: $loginDate, hcVersion: $hcVersion, systemVersion: $systemVersion, isIphone: $isIphone, latitude: $latitude, longitude: $longitude, locationName: $locationName)';
  }
}

/// @nodoc
abstract mixin class _$UdLoginHistoryModelCopyWith<$Res>
    implements $UdLoginHistoryModelCopyWith<$Res> {
  factory _$UdLoginHistoryModelCopyWith(_UdLoginHistoryModel value,
          $Res Function(_UdLoginHistoryModel) _then) =
      __$UdLoginHistoryModelCopyWithImpl;
  @override
  @useResult
  $Res call(
      {DateTime loginDate,
      String hcVersion,
      String systemVersion,
      int isIphone,
      double latitude,
      double longitude,
      String locationName});
}

/// @nodoc
class __$UdLoginHistoryModelCopyWithImpl<$Res>
    implements _$UdLoginHistoryModelCopyWith<$Res> {
  __$UdLoginHistoryModelCopyWithImpl(this._self, this._then);

  final _UdLoginHistoryModel _self;
  final $Res Function(_UdLoginHistoryModel) _then;

  /// Create a copy of UdLoginHistoryModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? loginDate = null,
    Object? hcVersion = null,
    Object? systemVersion = null,
    Object? isIphone = null,
    Object? latitude = null,
    Object? longitude = null,
    Object? locationName = null,
  }) {
    return _then(_UdLoginHistoryModel(
      loginDate: null == loginDate
          ? _self.loginDate
          : loginDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      hcVersion: null == hcVersion
          ? _self.hcVersion
          : hcVersion // ignore: cast_nullable_to_non_nullable
              as String,
      systemVersion: null == systemVersion
          ? _self.systemVersion
          : systemVersion // ignore: cast_nullable_to_non_nullable
              as String,
      isIphone: null == isIphone
          ? _self.isIphone
          : isIphone // ignore: cast_nullable_to_non_nullable
              as int,
      latitude: null == latitude
          ? _self.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double,
      longitude: null == longitude
          ? _self.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double,
      locationName: null == locationName
          ? _self.locationName
          : locationName // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on
