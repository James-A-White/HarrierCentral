// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'usage_category_detail.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UdCategoryDetailModel implements DiagnosticableTreeMixin {
  DateTime? get dateOfActivity;
  String? get message;

  /// Create a copy of UdCategoryDetailModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $UdCategoryDetailModelCopyWith<UdCategoryDetailModel> get copyWith =>
      _$UdCategoryDetailModelCopyWithImpl<UdCategoryDetailModel>(
          this as UdCategoryDetailModel, _$identity);

  /// Serializes this UdCategoryDetailModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'UdCategoryDetailModel'))
      ..add(DiagnosticsProperty('dateOfActivity', dateOfActivity))
      ..add(DiagnosticsProperty('message', message));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is UdCategoryDetailModel &&
            (identical(other.dateOfActivity, dateOfActivity) ||
                other.dateOfActivity == dateOfActivity) &&
            (identical(other.message, message) || other.message == message));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, dateOfActivity, message);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'UdCategoryDetailModel(dateOfActivity: $dateOfActivity, message: $message)';
  }
}

/// @nodoc
abstract mixin class $UdCategoryDetailModelCopyWith<$Res> {
  factory $UdCategoryDetailModelCopyWith(UdCategoryDetailModel value,
          $Res Function(UdCategoryDetailModel) _then) =
      _$UdCategoryDetailModelCopyWithImpl;
  @useResult
  $Res call({DateTime? dateOfActivity, String? message});
}

/// @nodoc
class _$UdCategoryDetailModelCopyWithImpl<$Res>
    implements $UdCategoryDetailModelCopyWith<$Res> {
  _$UdCategoryDetailModelCopyWithImpl(this._self, this._then);

  final UdCategoryDetailModel _self;
  final $Res Function(UdCategoryDetailModel) _then;

  /// Create a copy of UdCategoryDetailModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? dateOfActivity = freezed,
    Object? message = freezed,
  }) {
    return _then(_self.copyWith(
      dateOfActivity: freezed == dateOfActivity
          ? _self.dateOfActivity
          : dateOfActivity // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      message: freezed == message
          ? _self.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [UdCategoryDetailModel].
extension UdCategoryDetailModelPatterns on UdCategoryDetailModel {
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
    TResult Function(_UdCategoryDetailModel value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _UdCategoryDetailModel() when $default != null:
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
    TResult Function(_UdCategoryDetailModel value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UdCategoryDetailModel():
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
    TResult? Function(_UdCategoryDetailModel value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UdCategoryDetailModel() when $default != null:
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
    TResult Function(DateTime? dateOfActivity, String? message)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _UdCategoryDetailModel() when $default != null:
        return $default(_that.dateOfActivity, _that.message);
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
    TResult Function(DateTime? dateOfActivity, String? message) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UdCategoryDetailModel():
        return $default(_that.dateOfActivity, _that.message);
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
    TResult? Function(DateTime? dateOfActivity, String? message)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UdCategoryDetailModel() when $default != null:
        return $default(_that.dateOfActivity, _that.message);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _UdCategoryDetailModel
    with DiagnosticableTreeMixin
    implements UdCategoryDetailModel {
  _UdCategoryDetailModel({required this.dateOfActivity, required this.message});
  factory _UdCategoryDetailModel.fromJson(Map<String, dynamic> json) =>
      _$UdCategoryDetailModelFromJson(json);

  @override
  final DateTime? dateOfActivity;
  @override
  final String? message;

  /// Create a copy of UdCategoryDetailModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$UdCategoryDetailModelCopyWith<_UdCategoryDetailModel> get copyWith =>
      __$UdCategoryDetailModelCopyWithImpl<_UdCategoryDetailModel>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$UdCategoryDetailModelToJson(
      this,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'UdCategoryDetailModel'))
      ..add(DiagnosticsProperty('dateOfActivity', dateOfActivity))
      ..add(DiagnosticsProperty('message', message));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _UdCategoryDetailModel &&
            (identical(other.dateOfActivity, dateOfActivity) ||
                other.dateOfActivity == dateOfActivity) &&
            (identical(other.message, message) || other.message == message));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, dateOfActivity, message);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'UdCategoryDetailModel(dateOfActivity: $dateOfActivity, message: $message)';
  }
}

/// @nodoc
abstract mixin class _$UdCategoryDetailModelCopyWith<$Res>
    implements $UdCategoryDetailModelCopyWith<$Res> {
  factory _$UdCategoryDetailModelCopyWith(_UdCategoryDetailModel value,
          $Res Function(_UdCategoryDetailModel) _then) =
      __$UdCategoryDetailModelCopyWithImpl;
  @override
  @useResult
  $Res call({DateTime? dateOfActivity, String? message});
}

/// @nodoc
class __$UdCategoryDetailModelCopyWithImpl<$Res>
    implements _$UdCategoryDetailModelCopyWith<$Res> {
  __$UdCategoryDetailModelCopyWithImpl(this._self, this._then);

  final _UdCategoryDetailModel _self;
  final $Res Function(_UdCategoryDetailModel) _then;

  /// Create a copy of UdCategoryDetailModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? dateOfActivity = freezed,
    Object? message = freezed,
  }) {
    return _then(_UdCategoryDetailModel(
      dateOfActivity: freezed == dateOfActivity
          ? _self.dateOfActivity
          : dateOfActivity // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      message: freezed == message
          ? _self.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on
