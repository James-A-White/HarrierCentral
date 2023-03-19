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
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

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

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
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
abstract class _$$_DbErrorModelCopyWith<$Res>
    implements $DbErrorModelCopyWith<$Res> {
  factory _$$_DbErrorModelCopyWith(
          _$_DbErrorModel value, $Res Function(_$_DbErrorModel) then) =
      __$$_DbErrorModelCopyWithImpl<$Res>;
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
class __$$_DbErrorModelCopyWithImpl<$Res>
    extends _$DbErrorModelCopyWithImpl<$Res, _$_DbErrorModel>
    implements _$$_DbErrorModelCopyWith<$Res> {
  __$$_DbErrorModelCopyWithImpl(
      _$_DbErrorModel _value, $Res Function(_$_DbErrorModel) _then)
      : super(_value, _then);

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
    return _then(_$_DbErrorModel(
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
class _$_DbErrorModel implements _DbErrorModel {
  _$_DbErrorModel(
      {this.errorId,
      this.errorType,
      this.errorTitle,
      this.errorUserMessage,
      this.debugMessage,
      this.errorProc});

  factory _$_DbErrorModel.fromJson(Map<String, dynamic> json) =>
      _$$_DbErrorModelFromJson(json);

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
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_DbErrorModel &&
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

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, errorId, errorType, errorTitle,
      errorUserMessage, debugMessage, errorProc);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_DbErrorModelCopyWith<_$_DbErrorModel> get copyWith =>
      __$$_DbErrorModelCopyWithImpl<_$_DbErrorModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_DbErrorModelToJson(
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
      final String? errorProc}) = _$_DbErrorModel;

  factory _DbErrorModel.fromJson(Map<String, dynamic> json) =
      _$_DbErrorModel.fromJson;

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
  @override
  @JsonKey(ignore: true)
  _$$_DbErrorModelCopyWith<_$_DbErrorModel> get copyWith =>
      throw _privateConstructorUsedError;
}
