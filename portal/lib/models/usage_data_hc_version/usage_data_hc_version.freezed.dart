// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'usage_data_hc_version.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UdHcVersion implements DiagnosticableTreeMixin {
  String get versionNum;
  String get buildNum;
  int get isiPhone;
  int get isNotiPhone;

  /// Create a copy of UdHcVersion
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $UdHcVersionCopyWith<UdHcVersion> get copyWith =>
      _$UdHcVersionCopyWithImpl<UdHcVersion>(this as UdHcVersion, _$identity);

  /// Serializes this UdHcVersion to a JSON map.
  Map<String, dynamic> toJson();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'UdHcVersion'))
      ..add(DiagnosticsProperty('versionNum', versionNum))
      ..add(DiagnosticsProperty('buildNum', buildNum))
      ..add(DiagnosticsProperty('isiPhone', isiPhone))
      ..add(DiagnosticsProperty('isNotiPhone', isNotiPhone));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is UdHcVersion &&
            (identical(other.versionNum, versionNum) ||
                other.versionNum == versionNum) &&
            (identical(other.buildNum, buildNum) ||
                other.buildNum == buildNum) &&
            (identical(other.isiPhone, isiPhone) ||
                other.isiPhone == isiPhone) &&
            (identical(other.isNotiPhone, isNotiPhone) ||
                other.isNotiPhone == isNotiPhone));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, versionNum, buildNum, isiPhone, isNotiPhone);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'UdHcVersion(versionNum: $versionNum, buildNum: $buildNum, isiPhone: $isiPhone, isNotiPhone: $isNotiPhone)';
  }
}

/// @nodoc
abstract mixin class $UdHcVersionCopyWith<$Res> {
  factory $UdHcVersionCopyWith(
          UdHcVersion value, $Res Function(UdHcVersion) _then) =
      _$UdHcVersionCopyWithImpl;
  @useResult
  $Res call(
      {String versionNum, String buildNum, int isiPhone, int isNotiPhone});
}

/// @nodoc
class _$UdHcVersionCopyWithImpl<$Res> implements $UdHcVersionCopyWith<$Res> {
  _$UdHcVersionCopyWithImpl(this._self, this._then);

  final UdHcVersion _self;
  final $Res Function(UdHcVersion) _then;

  /// Create a copy of UdHcVersion
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? versionNum = null,
    Object? buildNum = null,
    Object? isiPhone = null,
    Object? isNotiPhone = null,
  }) {
    return _then(_self.copyWith(
      versionNum: null == versionNum
          ? _self.versionNum
          : versionNum // ignore: cast_nullable_to_non_nullable
              as String,
      buildNum: null == buildNum
          ? _self.buildNum
          : buildNum // ignore: cast_nullable_to_non_nullable
              as String,
      isiPhone: null == isiPhone
          ? _self.isiPhone
          : isiPhone // ignore: cast_nullable_to_non_nullable
              as int,
      isNotiPhone: null == isNotiPhone
          ? _self.isNotiPhone
          : isNotiPhone // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// Adds pattern-matching-related methods to [UdHcVersion].
extension UdHcVersionPatterns on UdHcVersion {
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
    TResult Function(_UdHcVersion value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _UdHcVersion() when $default != null:
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
    TResult Function(_UdHcVersion value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UdHcVersion():
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
    TResult? Function(_UdHcVersion value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UdHcVersion() when $default != null:
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
            String versionNum, String buildNum, int isiPhone, int isNotiPhone)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _UdHcVersion() when $default != null:
        return $default(_that.versionNum, _that.buildNum, _that.isiPhone,
            _that.isNotiPhone);
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
            String versionNum, String buildNum, int isiPhone, int isNotiPhone)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UdHcVersion():
        return $default(_that.versionNum, _that.buildNum, _that.isiPhone,
            _that.isNotiPhone);
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
            String versionNum, String buildNum, int isiPhone, int isNotiPhone)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UdHcVersion() when $default != null:
        return $default(_that.versionNum, _that.buildNum, _that.isiPhone,
            _that.isNotiPhone);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _UdHcVersion with DiagnosticableTreeMixin implements UdHcVersion {
  _UdHcVersion(
      {required this.versionNum,
      required this.buildNum,
      required this.isiPhone,
      required this.isNotiPhone});
  factory _UdHcVersion.fromJson(Map<String, dynamic> json) =>
      _$UdHcVersionFromJson(json);

  @override
  final String versionNum;
  @override
  final String buildNum;
  @override
  final int isiPhone;
  @override
  final int isNotiPhone;

  /// Create a copy of UdHcVersion
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$UdHcVersionCopyWith<_UdHcVersion> get copyWith =>
      __$UdHcVersionCopyWithImpl<_UdHcVersion>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$UdHcVersionToJson(
      this,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'UdHcVersion'))
      ..add(DiagnosticsProperty('versionNum', versionNum))
      ..add(DiagnosticsProperty('buildNum', buildNum))
      ..add(DiagnosticsProperty('isiPhone', isiPhone))
      ..add(DiagnosticsProperty('isNotiPhone', isNotiPhone));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _UdHcVersion &&
            (identical(other.versionNum, versionNum) ||
                other.versionNum == versionNum) &&
            (identical(other.buildNum, buildNum) ||
                other.buildNum == buildNum) &&
            (identical(other.isiPhone, isiPhone) ||
                other.isiPhone == isiPhone) &&
            (identical(other.isNotiPhone, isNotiPhone) ||
                other.isNotiPhone == isNotiPhone));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, versionNum, buildNum, isiPhone, isNotiPhone);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'UdHcVersion(versionNum: $versionNum, buildNum: $buildNum, isiPhone: $isiPhone, isNotiPhone: $isNotiPhone)';
  }
}

/// @nodoc
abstract mixin class _$UdHcVersionCopyWith<$Res>
    implements $UdHcVersionCopyWith<$Res> {
  factory _$UdHcVersionCopyWith(
          _UdHcVersion value, $Res Function(_UdHcVersion) _then) =
      __$UdHcVersionCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String versionNum, String buildNum, int isiPhone, int isNotiPhone});
}

/// @nodoc
class __$UdHcVersionCopyWithImpl<$Res> implements _$UdHcVersionCopyWith<$Res> {
  __$UdHcVersionCopyWithImpl(this._self, this._then);

  final _UdHcVersion _self;
  final $Res Function(_UdHcVersion) _then;

  /// Create a copy of UdHcVersion
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? versionNum = null,
    Object? buildNum = null,
    Object? isiPhone = null,
    Object? isNotiPhone = null,
  }) {
    return _then(_UdHcVersion(
      versionNum: null == versionNum
          ? _self.versionNum
          : versionNum // ignore: cast_nullable_to_non_nullable
              as String,
      buildNum: null == buildNum
          ? _self.buildNum
          : buildNum // ignore: cast_nullable_to_non_nullable
              as String,
      isiPhone: null == isiPhone
          ? _self.isiPhone
          : isiPhone // ignore: cast_nullable_to_non_nullable
              as int,
      isNotiPhone: null == isNotiPhone
          ? _self.isNotiPhone
          : isNotiPhone // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

// dart format on
