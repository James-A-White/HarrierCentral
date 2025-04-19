// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'db_error_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DbErrorModel implements DiagnosticableTreeMixin {
  String? get errorId;
  num? get errorType;
  String? get errorTitle;
  String? get errorUserMessage;
  String? get debugMessage;
  String? get errorProc;

  /// Create a copy of DbErrorModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $DbErrorModelCopyWith<DbErrorModel> get copyWith =>
      _$DbErrorModelCopyWithImpl<DbErrorModel>(
          this as DbErrorModel, _$identity);

  /// Serializes this DbErrorModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'DbErrorModel'))
      ..add(DiagnosticsProperty('errorId', errorId))
      ..add(DiagnosticsProperty('errorType', errorType))
      ..add(DiagnosticsProperty('errorTitle', errorTitle))
      ..add(DiagnosticsProperty('errorUserMessage', errorUserMessage))
      ..add(DiagnosticsProperty('debugMessage', debugMessage))
      ..add(DiagnosticsProperty('errorProc', errorProc));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is DbErrorModel &&
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

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'DbErrorModel(errorId: $errorId, errorType: $errorType, errorTitle: $errorTitle, errorUserMessage: $errorUserMessage, debugMessage: $debugMessage, errorProc: $errorProc)';
  }
}

/// @nodoc
abstract mixin class $DbErrorModelCopyWith<$Res> {
  factory $DbErrorModelCopyWith(
          DbErrorModel value, $Res Function(DbErrorModel) _then) =
      _$DbErrorModelCopyWithImpl;
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
class _$DbErrorModelCopyWithImpl<$Res> implements $DbErrorModelCopyWith<$Res> {
  _$DbErrorModelCopyWithImpl(this._self, this._then);

  final DbErrorModel _self;
  final $Res Function(DbErrorModel) _then;

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
    return _then(_self.copyWith(
      errorId: freezed == errorId
          ? _self.errorId
          : errorId // ignore: cast_nullable_to_non_nullable
              as String?,
      errorType: freezed == errorType
          ? _self.errorType
          : errorType // ignore: cast_nullable_to_non_nullable
              as num?,
      errorTitle: freezed == errorTitle
          ? _self.errorTitle
          : errorTitle // ignore: cast_nullable_to_non_nullable
              as String?,
      errorUserMessage: freezed == errorUserMessage
          ? _self.errorUserMessage
          : errorUserMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      debugMessage: freezed == debugMessage
          ? _self.debugMessage
          : debugMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      errorProc: freezed == errorProc
          ? _self.errorProc
          : errorProc // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _DbErrorModel with DiagnosticableTreeMixin implements DbErrorModel {
  _DbErrorModel(
      {this.errorId,
      this.errorType,
      this.errorTitle,
      this.errorUserMessage,
      this.debugMessage,
      this.errorProc});
  factory _DbErrorModel.fromJson(Map<String, dynamic> json) =>
      _$DbErrorModelFromJson(json);

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

  /// Create a copy of DbErrorModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$DbErrorModelCopyWith<_DbErrorModel> get copyWith =>
      __$DbErrorModelCopyWithImpl<_DbErrorModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$DbErrorModelToJson(
      this,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'DbErrorModel'))
      ..add(DiagnosticsProperty('errorId', errorId))
      ..add(DiagnosticsProperty('errorType', errorType))
      ..add(DiagnosticsProperty('errorTitle', errorTitle))
      ..add(DiagnosticsProperty('errorUserMessage', errorUserMessage))
      ..add(DiagnosticsProperty('debugMessage', debugMessage))
      ..add(DiagnosticsProperty('errorProc', errorProc));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _DbErrorModel &&
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

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'DbErrorModel(errorId: $errorId, errorType: $errorType, errorTitle: $errorTitle, errorUserMessage: $errorUserMessage, debugMessage: $debugMessage, errorProc: $errorProc)';
  }
}

/// @nodoc
abstract mixin class _$DbErrorModelCopyWith<$Res>
    implements $DbErrorModelCopyWith<$Res> {
  factory _$DbErrorModelCopyWith(
          _DbErrorModel value, $Res Function(_DbErrorModel) _then) =
      __$DbErrorModelCopyWithImpl;
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
class __$DbErrorModelCopyWithImpl<$Res>
    implements _$DbErrorModelCopyWith<$Res> {
  __$DbErrorModelCopyWithImpl(this._self, this._then);

  final _DbErrorModel _self;
  final $Res Function(_DbErrorModel) _then;

  /// Create a copy of DbErrorModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? errorId = freezed,
    Object? errorType = freezed,
    Object? errorTitle = freezed,
    Object? errorUserMessage = freezed,
    Object? debugMessage = freezed,
    Object? errorProc = freezed,
  }) {
    return _then(_DbErrorModel(
      errorId: freezed == errorId
          ? _self.errorId
          : errorId // ignore: cast_nullable_to_non_nullable
              as String?,
      errorType: freezed == errorType
          ? _self.errorType
          : errorType // ignore: cast_nullable_to_non_nullable
              as num?,
      errorTitle: freezed == errorTitle
          ? _self.errorTitle
          : errorTitle // ignore: cast_nullable_to_non_nullable
              as String?,
      errorUserMessage: freezed == errorUserMessage
          ? _self.errorUserMessage
          : errorUserMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      debugMessage: freezed == debugMessage
          ? _self.debugMessage
          : debugMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      errorProc: freezed == errorProc
          ? _self.errorProc
          : errorProc // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on
