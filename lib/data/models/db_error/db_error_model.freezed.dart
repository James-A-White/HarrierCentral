// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'db_error_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

DbErrorModel _$DbErrorModelFromJson(Map<String, dynamic> json) {
  return _DbErrorModel.fromJson(json);
}

/// @nodoc
mixin _$DbErrorModel {
  String? get errorId => throw _privateConstructorUsedError;
  num? get errorType => throw _privateConstructorUsedError;
  String? get errorTitle => throw _privateConstructorUsedError;
  String? get errorUserMessage => throw _privateConstructorUsedError;
  String? get debugMessage => throw _privateConstructorUsedError;
  String? get errorProc => throw _privateConstructorUsedError;

  /// Serializes this DbErrorModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DbErrorModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DbErrorModelCopyWith<DbErrorModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DbErrorModelCopyWith<$Res> {
  factory $DbErrorModelCopyWith(
          DbErrorModel value, $Res Function(DbErrorModel) then) =
      _$DbErrorModelCopyWithImpl<$Res, DbErrorModel>;
  @useResult
  $Res call(
      {String? errorId,
      num? errorType,
      String? errorTitle,
      String? errorUserMessage,
      String? debugMessage,
      String? errorProc});
}

/// @nodoc
class _$DbErrorModelCopyWithImpl<$Res, $Val extends DbErrorModel>
    implements $DbErrorModelCopyWith<$Res> {
  _$DbErrorModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DbErrorModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? errorId = freezed,
    Object? errorType = freezed,
    Object? errorTitle = freezed,
    Object? errorUserMessage = freezed,
    Object? debugMessage = freezed,
    Object? errorProc = freezed,
  }) {
    return _then(_value.copyWith(
      errorId: freezed == errorId
          ? _value.errorId
          : errorId // ignore: cast_nullable_to_non_nullable
              as String?,
      errorType: freezed == errorType
          ? _value.errorType
          : errorType // ignore: cast_nullable_to_non_nullable
              as num?,
      errorTitle: freezed == errorTitle
          ? _value.errorTitle
          : errorTitle // ignore: cast_nullable_to_non_nullable
              as String?,
      errorUserMessage: freezed == errorUserMessage
          ? _value.errorUserMessage
          : errorUserMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      debugMessage: freezed == debugMessage
          ? _value.debugMessage
          : debugMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      errorProc: freezed == errorProc
          ? _value.errorProc
          : errorProc // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DbErrorModelImplCopyWith<$Res>
    implements $DbErrorModelCopyWith<$Res> {
  factory _$$DbErrorModelImplCopyWith(
          _$DbErrorModelImpl value, $Res Function(_$DbErrorModelImpl) then) =
      __$$DbErrorModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String? errorId,
      num? errorType,
      String? errorTitle,
      String? errorUserMessage,
      String? debugMessage,
      String? errorProc});
}

/// @nodoc
class __$$DbErrorModelImplCopyWithImpl<$Res>
    extends _$DbErrorModelCopyWithImpl<$Res, _$DbErrorModelImpl>
    implements _$$DbErrorModelImplCopyWith<$Res> {
  __$$DbErrorModelImplCopyWithImpl(
      _$DbErrorModelImpl _value, $Res Function(_$DbErrorModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of DbErrorModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? errorId = freezed,
    Object? errorType = freezed,
    Object? errorTitle = freezed,
    Object? errorUserMessage = freezed,
    Object? debugMessage = freezed,
    Object? errorProc = freezed,
  }) {
    return _then(_$DbErrorModelImpl(
      errorId: freezed == errorId
          ? _value.errorId
          : errorId // ignore: cast_nullable_to_non_nullable
              as String?,
      errorType: freezed == errorType
          ? _value.errorType
          : errorType // ignore: cast_nullable_to_non_nullable
              as num?,
      errorTitle: freezed == errorTitle
          ? _value.errorTitle
          : errorTitle // ignore: cast_nullable_to_non_nullable
              as String?,
      errorUserMessage: freezed == errorUserMessage
          ? _value.errorUserMessage
          : errorUserMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      debugMessage: freezed == debugMessage
          ? _value.debugMessage
          : debugMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      errorProc: freezed == errorProc
          ? _value.errorProc
          : errorProc // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DbErrorModelImpl implements _DbErrorModel {
  _$DbErrorModelImpl(
      {this.errorId,
      this.errorType,
      this.errorTitle,
      this.errorUserMessage,
      this.debugMessage,
      this.errorProc});

  factory _$DbErrorModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$DbErrorModelImplFromJson(json);

  @override
  final String? errorId;
  @override
  final num? errorType;
  @override
  final String? errorTitle;
  @override
  final String? errorUserMessage;
  @override
  final String? debugMessage;
  @override
  final String? errorProc;

  @override
  String toString() {
    return 'DbErrorModel(errorId: $errorId, errorType: $errorType, errorTitle: $errorTitle, errorUserMessage: $errorUserMessage, debugMessage: $debugMessage, errorProc: $errorProc)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DbErrorModelImpl &&
            (identical(other.errorId, errorId) || other.errorId == errorId) &&
            (identical(other.errorType, errorType) ||
                other.errorType == errorType) &&
            (identical(other.errorTitle, errorTitle) ||
                other.errorTitle == errorTitle) &&
            (identical(other.errorUserMessage, errorUserMessage) ||
                other.errorUserMessage == errorUserMessage) &&
            (identical(other.debugMessage, debugMessage) ||
                other.debugMessage == debugMessage) &&
            (identical(other.errorProc, errorProc) ||
                other.errorProc == errorProc));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, errorId, errorType, errorTitle,
      errorUserMessage, debugMessage, errorProc);

  /// Create a copy of DbErrorModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DbErrorModelImplCopyWith<_$DbErrorModelImpl> get copyWith =>
      __$$DbErrorModelImplCopyWithImpl<_$DbErrorModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DbErrorModelImplToJson(
      this,
    );
  }
}

abstract class _DbErrorModel implements DbErrorModel {
  factory _DbErrorModel(
      {final String? errorId,
      final num? errorType,
      final String? errorTitle,
      final String? errorUserMessage,
      final String? debugMessage,
      final String? errorProc}) = _$DbErrorModelImpl;

  factory _DbErrorModel.fromJson(Map<String, dynamic> json) =
      _$DbErrorModelImpl.fromJson;

  @override
  String? get errorId;
  @override
  num? get errorType;
  @override
  String? get errorTitle;
  @override
  String? get errorUserMessage;
  @override
  String? get debugMessage;
  @override
  String? get errorProc;

  /// Create a copy of DbErrorModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DbErrorModelImplCopyWith<_$DbErrorModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
