// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'approve_login_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ApproveLoginModel _$ApproveLoginModelFromJson(Map<String, dynamic> json) {
  return _ApproveLoginModel.fromJson(json);
}

/// @nodoc
mixin _$ApproveLoginModel {
  String? get apiVersion => throw _privateConstructorUsedError;
  int? get approvalCode => throw _privateConstructorUsedError;
  String? get loginMessage => throw _privateConstructorUsedError;
  String? get loginMessageTitle => throw _privateConstructorUsedError;
  int? get serverStatusCode => throw _privateConstructorUsedError;
  DateTime? get messageEndDate => throw _privateConstructorUsedError;
  int? get messageDisplayType => throw _privateConstructorUsedError;
  String? get iosDownloadLink => throw _privateConstructorUsedError;
  String? get androidDownloadLink => throw _privateConstructorUsedError;
  String? get imageRootUrl => throw _privateConstructorUsedError;
  int? get isBetaTester => throw _privateConstructorUsedError;
  String? get email => throw _privateConstructorUsedError;
  String? get homeKennelId => throw _privateConstructorUsedError;
  DateTime? get thirdPartyForceTokenRefresh =>
      throw _privateConstructorUsedError;

  /// Serializes this ApproveLoginModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ApproveLoginModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ApproveLoginModelCopyWith<ApproveLoginModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ApproveLoginModelCopyWith<$Res> {
  factory $ApproveLoginModelCopyWith(
          ApproveLoginModel value, $Res Function(ApproveLoginModel) then) =
      _$ApproveLoginModelCopyWithImpl<$Res, ApproveLoginModel>;
  @useResult
  $Res call(
      {String? apiVersion,
      int? approvalCode,
      String? loginMessage,
      String? loginMessageTitle,
      int? serverStatusCode,
      DateTime? messageEndDate,
      int? messageDisplayType,
      String? iosDownloadLink,
      String? androidDownloadLink,
      String? imageRootUrl,
      int? isBetaTester,
      String? email,
      String? homeKennelId,
      DateTime? thirdPartyForceTokenRefresh});
}

/// @nodoc
class _$ApproveLoginModelCopyWithImpl<$Res, $Val extends ApproveLoginModel>
    implements $ApproveLoginModelCopyWith<$Res> {
  _$ApproveLoginModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ApproveLoginModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? apiVersion = freezed,
    Object? approvalCode = freezed,
    Object? loginMessage = freezed,
    Object? loginMessageTitle = freezed,
    Object? serverStatusCode = freezed,
    Object? messageEndDate = freezed,
    Object? messageDisplayType = freezed,
    Object? iosDownloadLink = freezed,
    Object? androidDownloadLink = freezed,
    Object? imageRootUrl = freezed,
    Object? isBetaTester = freezed,
    Object? email = freezed,
    Object? homeKennelId = freezed,
    Object? thirdPartyForceTokenRefresh = freezed,
  }) {
    return _then(_value.copyWith(
      apiVersion: freezed == apiVersion
          ? _value.apiVersion
          : apiVersion // ignore: cast_nullable_to_non_nullable
              as String?,
      approvalCode: freezed == approvalCode
          ? _value.approvalCode
          : approvalCode // ignore: cast_nullable_to_non_nullable
              as int?,
      loginMessage: freezed == loginMessage
          ? _value.loginMessage
          : loginMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      loginMessageTitle: freezed == loginMessageTitle
          ? _value.loginMessageTitle
          : loginMessageTitle // ignore: cast_nullable_to_non_nullable
              as String?,
      serverStatusCode: freezed == serverStatusCode
          ? _value.serverStatusCode
          : serverStatusCode // ignore: cast_nullable_to_non_nullable
              as int?,
      messageEndDate: freezed == messageEndDate
          ? _value.messageEndDate
          : messageEndDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      messageDisplayType: freezed == messageDisplayType
          ? _value.messageDisplayType
          : messageDisplayType // ignore: cast_nullable_to_non_nullable
              as int?,
      iosDownloadLink: freezed == iosDownloadLink
          ? _value.iosDownloadLink
          : iosDownloadLink // ignore: cast_nullable_to_non_nullable
              as String?,
      androidDownloadLink: freezed == androidDownloadLink
          ? _value.androidDownloadLink
          : androidDownloadLink // ignore: cast_nullable_to_non_nullable
              as String?,
      imageRootUrl: freezed == imageRootUrl
          ? _value.imageRootUrl
          : imageRootUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      isBetaTester: freezed == isBetaTester
          ? _value.isBetaTester
          : isBetaTester // ignore: cast_nullable_to_non_nullable
              as int?,
      email: freezed == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String?,
      homeKennelId: freezed == homeKennelId
          ? _value.homeKennelId
          : homeKennelId // ignore: cast_nullable_to_non_nullable
              as String?,
      thirdPartyForceTokenRefresh: freezed == thirdPartyForceTokenRefresh
          ? _value.thirdPartyForceTokenRefresh
          : thirdPartyForceTokenRefresh // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ApproveLoginModelImplCopyWith<$Res>
    implements $ApproveLoginModelCopyWith<$Res> {
  factory _$$ApproveLoginModelImplCopyWith(_$ApproveLoginModelImpl value,
          $Res Function(_$ApproveLoginModelImpl) then) =
      __$$ApproveLoginModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String? apiVersion,
      int? approvalCode,
      String? loginMessage,
      String? loginMessageTitle,
      int? serverStatusCode,
      DateTime? messageEndDate,
      int? messageDisplayType,
      String? iosDownloadLink,
      String? androidDownloadLink,
      String? imageRootUrl,
      int? isBetaTester,
      String? email,
      String? homeKennelId,
      DateTime? thirdPartyForceTokenRefresh});
}

/// @nodoc
class __$$ApproveLoginModelImplCopyWithImpl<$Res>
    extends _$ApproveLoginModelCopyWithImpl<$Res, _$ApproveLoginModelImpl>
    implements _$$ApproveLoginModelImplCopyWith<$Res> {
  __$$ApproveLoginModelImplCopyWithImpl(_$ApproveLoginModelImpl _value,
      $Res Function(_$ApproveLoginModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of ApproveLoginModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? apiVersion = freezed,
    Object? approvalCode = freezed,
    Object? loginMessage = freezed,
    Object? loginMessageTitle = freezed,
    Object? serverStatusCode = freezed,
    Object? messageEndDate = freezed,
    Object? messageDisplayType = freezed,
    Object? iosDownloadLink = freezed,
    Object? androidDownloadLink = freezed,
    Object? imageRootUrl = freezed,
    Object? isBetaTester = freezed,
    Object? email = freezed,
    Object? homeKennelId = freezed,
    Object? thirdPartyForceTokenRefresh = freezed,
  }) {
    return _then(_$ApproveLoginModelImpl(
      apiVersion: freezed == apiVersion
          ? _value.apiVersion
          : apiVersion // ignore: cast_nullable_to_non_nullable
              as String?,
      approvalCode: freezed == approvalCode
          ? _value.approvalCode
          : approvalCode // ignore: cast_nullable_to_non_nullable
              as int?,
      loginMessage: freezed == loginMessage
          ? _value.loginMessage
          : loginMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      loginMessageTitle: freezed == loginMessageTitle
          ? _value.loginMessageTitle
          : loginMessageTitle // ignore: cast_nullable_to_non_nullable
              as String?,
      serverStatusCode: freezed == serverStatusCode
          ? _value.serverStatusCode
          : serverStatusCode // ignore: cast_nullable_to_non_nullable
              as int?,
      messageEndDate: freezed == messageEndDate
          ? _value.messageEndDate
          : messageEndDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      messageDisplayType: freezed == messageDisplayType
          ? _value.messageDisplayType
          : messageDisplayType // ignore: cast_nullable_to_non_nullable
              as int?,
      iosDownloadLink: freezed == iosDownloadLink
          ? _value.iosDownloadLink
          : iosDownloadLink // ignore: cast_nullable_to_non_nullable
              as String?,
      androidDownloadLink: freezed == androidDownloadLink
          ? _value.androidDownloadLink
          : androidDownloadLink // ignore: cast_nullable_to_non_nullable
              as String?,
      imageRootUrl: freezed == imageRootUrl
          ? _value.imageRootUrl
          : imageRootUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      isBetaTester: freezed == isBetaTester
          ? _value.isBetaTester
          : isBetaTester // ignore: cast_nullable_to_non_nullable
              as int?,
      email: freezed == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String?,
      homeKennelId: freezed == homeKennelId
          ? _value.homeKennelId
          : homeKennelId // ignore: cast_nullable_to_non_nullable
              as String?,
      thirdPartyForceTokenRefresh: freezed == thirdPartyForceTokenRefresh
          ? _value.thirdPartyForceTokenRefresh
          : thirdPartyForceTokenRefresh // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ApproveLoginModelImpl implements _ApproveLoginModel {
  _$ApproveLoginModelImpl(
      {this.apiVersion,
      this.approvalCode,
      this.loginMessage,
      this.loginMessageTitle,
      this.serverStatusCode,
      this.messageEndDate,
      this.messageDisplayType,
      this.iosDownloadLink,
      this.androidDownloadLink,
      this.imageRootUrl,
      this.isBetaTester,
      this.email,
      this.homeKennelId,
      this.thirdPartyForceTokenRefresh});

  factory _$ApproveLoginModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ApproveLoginModelImplFromJson(json);

  @override
  final String? apiVersion;
  @override
  final int? approvalCode;
  @override
  final String? loginMessage;
  @override
  final String? loginMessageTitle;
  @override
  final int? serverStatusCode;
  @override
  final DateTime? messageEndDate;
  @override
  final int? messageDisplayType;
  @override
  final String? iosDownloadLink;
  @override
  final String? androidDownloadLink;
  @override
  final String? imageRootUrl;
  @override
  final int? isBetaTester;
  @override
  final String? email;
  @override
  final String? homeKennelId;
  @override
  final DateTime? thirdPartyForceTokenRefresh;

  @override
  String toString() {
    return 'ApproveLoginModel(apiVersion: $apiVersion, approvalCode: $approvalCode, loginMessage: $loginMessage, loginMessageTitle: $loginMessageTitle, serverStatusCode: $serverStatusCode, messageEndDate: $messageEndDate, messageDisplayType: $messageDisplayType, iosDownloadLink: $iosDownloadLink, androidDownloadLink: $androidDownloadLink, imageRootUrl: $imageRootUrl, isBetaTester: $isBetaTester, email: $email, homeKennelId: $homeKennelId, thirdPartyForceTokenRefresh: $thirdPartyForceTokenRefresh)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ApproveLoginModelImpl &&
            (identical(other.apiVersion, apiVersion) ||
                other.apiVersion == apiVersion) &&
            (identical(other.approvalCode, approvalCode) ||
                other.approvalCode == approvalCode) &&
            (identical(other.loginMessage, loginMessage) ||
                other.loginMessage == loginMessage) &&
            (identical(other.loginMessageTitle, loginMessageTitle) ||
                other.loginMessageTitle == loginMessageTitle) &&
            (identical(other.serverStatusCode, serverStatusCode) ||
                other.serverStatusCode == serverStatusCode) &&
            (identical(other.messageEndDate, messageEndDate) ||
                other.messageEndDate == messageEndDate) &&
            (identical(other.messageDisplayType, messageDisplayType) ||
                other.messageDisplayType == messageDisplayType) &&
            (identical(other.iosDownloadLink, iosDownloadLink) ||
                other.iosDownloadLink == iosDownloadLink) &&
            (identical(other.androidDownloadLink, androidDownloadLink) ||
                other.androidDownloadLink == androidDownloadLink) &&
            (identical(other.imageRootUrl, imageRootUrl) ||
                other.imageRootUrl == imageRootUrl) &&
            (identical(other.isBetaTester, isBetaTester) ||
                other.isBetaTester == isBetaTester) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.homeKennelId, homeKennelId) ||
                other.homeKennelId == homeKennelId) &&
            (identical(other.thirdPartyForceTokenRefresh,
                    thirdPartyForceTokenRefresh) ||
                other.thirdPartyForceTokenRefresh ==
                    thirdPartyForceTokenRefresh));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      apiVersion,
      approvalCode,
      loginMessage,
      loginMessageTitle,
      serverStatusCode,
      messageEndDate,
      messageDisplayType,
      iosDownloadLink,
      androidDownloadLink,
      imageRootUrl,
      isBetaTester,
      email,
      homeKennelId,
      thirdPartyForceTokenRefresh);

  /// Create a copy of ApproveLoginModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ApproveLoginModelImplCopyWith<_$ApproveLoginModelImpl> get copyWith =>
      __$$ApproveLoginModelImplCopyWithImpl<_$ApproveLoginModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ApproveLoginModelImplToJson(
      this,
    );
  }
}

abstract class _ApproveLoginModel implements ApproveLoginModel {
  factory _ApproveLoginModel(
      {final String? apiVersion,
      final int? approvalCode,
      final String? loginMessage,
      final String? loginMessageTitle,
      final int? serverStatusCode,
      final DateTime? messageEndDate,
      final int? messageDisplayType,
      final String? iosDownloadLink,
      final String? androidDownloadLink,
      final String? imageRootUrl,
      final int? isBetaTester,
      final String? email,
      final String? homeKennelId,
      final DateTime? thirdPartyForceTokenRefresh}) = _$ApproveLoginModelImpl;

  factory _ApproveLoginModel.fromJson(Map<String, dynamic> json) =
      _$ApproveLoginModelImpl.fromJson;

  @override
  String? get apiVersion;
  @override
  int? get approvalCode;
  @override
  String? get loginMessage;
  @override
  String? get loginMessageTitle;
  @override
  int? get serverStatusCode;
  @override
  DateTime? get messageEndDate;
  @override
  int? get messageDisplayType;
  @override
  String? get iosDownloadLink;
  @override
  String? get androidDownloadLink;
  @override
  String? get imageRootUrl;
  @override
  int? get isBetaTester;
  @override
  String? get email;
  @override
  String? get homeKennelId;
  @override
  DateTime? get thirdPartyForceTokenRefresh;

  /// Create a copy of ApproveLoginModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ApproveLoginModelImplCopyWith<_$ApproveLoginModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
