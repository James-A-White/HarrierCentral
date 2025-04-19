// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'kennel_member_results_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$KennelMemberResultsModel implements DiagnosticableTreeMixin {
  String get hasherId;
  String get dispName;
  String get nameForSort;
  String? get photo;
  int get following;
  String get kennelId;
  DateTime? get dateOfLastRun;
  int get hcTotalRunCount;
  int get hcHaringCount;
  int get historicalTotalRunCount;
  int get historicalHaringCount;
  int get kennelEmailAlertPreference;
  DateTime? get membershipExpirationDate;
  DateTime? get memberSince;
  int get membershipDurationInMonths;
  int get appAccessFlags;
  int get mismanagementRoles;
  String? get kennelShortName;
  double get kennelCredit;
  int get memberFollowingStatus;
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get memberInfoBeingUpdated;

  /// Create a copy of KennelMemberResultsModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $KennelMemberResultsModelCopyWith<KennelMemberResultsModel> get copyWith =>
      _$KennelMemberResultsModelCopyWithImpl<KennelMemberResultsModel>(
          this as KennelMemberResultsModel, _$identity);

  /// Serializes this KennelMemberResultsModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'KennelMemberResultsModel'))
      ..add(DiagnosticsProperty('hasherId', hasherId))
      ..add(DiagnosticsProperty('dispName', dispName))
      ..add(DiagnosticsProperty('nameForSort', nameForSort))
      ..add(DiagnosticsProperty('photo', photo))
      ..add(DiagnosticsProperty('following', following))
      ..add(DiagnosticsProperty('kennelId', kennelId))
      ..add(DiagnosticsProperty('dateOfLastRun', dateOfLastRun))
      ..add(DiagnosticsProperty('hcTotalRunCount', hcTotalRunCount))
      ..add(DiagnosticsProperty('hcHaringCount', hcHaringCount))
      ..add(DiagnosticsProperty(
          'historicalTotalRunCount', historicalTotalRunCount))
      ..add(DiagnosticsProperty('historicalHaringCount', historicalHaringCount))
      ..add(DiagnosticsProperty(
          'kennelEmailAlertPreference', kennelEmailAlertPreference))
      ..add(DiagnosticsProperty(
          'membershipExpirationDate', membershipExpirationDate))
      ..add(DiagnosticsProperty('memberSince', memberSince))
      ..add(DiagnosticsProperty(
          'membershipDurationInMonths', membershipDurationInMonths))
      ..add(DiagnosticsProperty('appAccessFlags', appAccessFlags))
      ..add(DiagnosticsProperty('mismanagementRoles', mismanagementRoles))
      ..add(DiagnosticsProperty('kennelShortName', kennelShortName))
      ..add(DiagnosticsProperty('kennelCredit', kennelCredit))
      ..add(DiagnosticsProperty('memberFollowingStatus', memberFollowingStatus))
      ..add(DiagnosticsProperty(
          'memberInfoBeingUpdated', memberInfoBeingUpdated));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is KennelMemberResultsModel &&
            (identical(other.hasherId, hasherId) ||
                other.hasherId == hasherId) &&
            (identical(other.dispName, dispName) ||
                other.dispName == dispName) &&
            (identical(other.nameForSort, nameForSort) ||
                other.nameForSort == nameForSort) &&
            (identical(other.photo, photo) || other.photo == photo) &&
            (identical(other.following, following) ||
                other.following == following) &&
            (identical(other.kennelId, kennelId) ||
                other.kennelId == kennelId) &&
            (identical(other.dateOfLastRun, dateOfLastRun) ||
                other.dateOfLastRun == dateOfLastRun) &&
            (identical(other.hcTotalRunCount, hcTotalRunCount) ||
                other.hcTotalRunCount == hcTotalRunCount) &&
            (identical(other.hcHaringCount, hcHaringCount) ||
                other.hcHaringCount == hcHaringCount) &&
            (identical(other.historicalTotalRunCount, historicalTotalRunCount) ||
                other.historicalTotalRunCount == historicalTotalRunCount) &&
            (identical(other.historicalHaringCount, historicalHaringCount) ||
                other.historicalHaringCount == historicalHaringCount) &&
            (identical(other.kennelEmailAlertPreference,
                    kennelEmailAlertPreference) ||
                other.kennelEmailAlertPreference ==
                    kennelEmailAlertPreference) &&
            (identical(other.membershipExpirationDate, membershipExpirationDate) ||
                other.membershipExpirationDate == membershipExpirationDate) &&
            (identical(other.memberSince, memberSince) ||
                other.memberSince == memberSince) &&
            (identical(other.membershipDurationInMonths,
                    membershipDurationInMonths) ||
                other.membershipDurationInMonths ==
                    membershipDurationInMonths) &&
            (identical(other.appAccessFlags, appAccessFlags) ||
                other.appAccessFlags == appAccessFlags) &&
            (identical(other.mismanagementRoles, mismanagementRoles) ||
                other.mismanagementRoles == mismanagementRoles) &&
            (identical(other.kennelShortName, kennelShortName) ||
                other.kennelShortName == kennelShortName) &&
            (identical(other.kennelCredit, kennelCredit) ||
                other.kennelCredit == kennelCredit) &&
            (identical(other.memberFollowingStatus, memberFollowingStatus) ||
                other.memberFollowingStatus == memberFollowingStatus) &&
            (identical(other.memberInfoBeingUpdated, memberInfoBeingUpdated) ||
                other.memberInfoBeingUpdated == memberInfoBeingUpdated));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        hasherId,
        dispName,
        nameForSort,
        photo,
        following,
        kennelId,
        dateOfLastRun,
        hcTotalRunCount,
        hcHaringCount,
        historicalTotalRunCount,
        historicalHaringCount,
        kennelEmailAlertPreference,
        membershipExpirationDate,
        memberSince,
        membershipDurationInMonths,
        appAccessFlags,
        mismanagementRoles,
        kennelShortName,
        kennelCredit,
        memberFollowingStatus,
        memberInfoBeingUpdated
      ]);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'KennelMemberResultsModel(hasherId: $hasherId, dispName: $dispName, nameForSort: $nameForSort, photo: $photo, following: $following, kennelId: $kennelId, dateOfLastRun: $dateOfLastRun, hcTotalRunCount: $hcTotalRunCount, hcHaringCount: $hcHaringCount, historicalTotalRunCount: $historicalTotalRunCount, historicalHaringCount: $historicalHaringCount, kennelEmailAlertPreference: $kennelEmailAlertPreference, membershipExpirationDate: $membershipExpirationDate, memberSince: $memberSince, membershipDurationInMonths: $membershipDurationInMonths, appAccessFlags: $appAccessFlags, mismanagementRoles: $mismanagementRoles, kennelShortName: $kennelShortName, kennelCredit: $kennelCredit, memberFollowingStatus: $memberFollowingStatus, memberInfoBeingUpdated: $memberInfoBeingUpdated)';
  }
}

/// @nodoc
abstract mixin class $KennelMemberResultsModelCopyWith<$Res> {
  factory $KennelMemberResultsModelCopyWith(KennelMemberResultsModel value,
          $Res Function(KennelMemberResultsModel) _then) =
      _$KennelMemberResultsModelCopyWithImpl;
  @useResult
  $Res call(
      {String hasherId,
      String dispName,
      String nameForSort,
      String? photo,
      int following,
      String kennelId,
      DateTime? dateOfLastRun,
      int hcTotalRunCount,
      int hcHaringCount,
      int historicalTotalRunCount,
      int historicalHaringCount,
      int kennelEmailAlertPreference,
      DateTime? membershipExpirationDate,
      DateTime? memberSince,
      int membershipDurationInMonths,
      int appAccessFlags,
      int mismanagementRoles,
      String? kennelShortName,
      double kennelCredit,
      int memberFollowingStatus,
      @JsonKey(includeFromJson: false, includeToJson: false)
      bool memberInfoBeingUpdated});
}

/// @nodoc
class _$KennelMemberResultsModelCopyWithImpl<$Res>
    implements $KennelMemberResultsModelCopyWith<$Res> {
  _$KennelMemberResultsModelCopyWithImpl(this._self, this._then);

  final KennelMemberResultsModel _self;
  final $Res Function(KennelMemberResultsModel) _then;

  /// Create a copy of KennelMemberResultsModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? hasherId = null,
    Object? dispName = null,
    Object? nameForSort = null,
    Object? photo = freezed,
    Object? following = null,
    Object? kennelId = null,
    Object? dateOfLastRun = freezed,
    Object? hcTotalRunCount = null,
    Object? hcHaringCount = null,
    Object? historicalTotalRunCount = null,
    Object? historicalHaringCount = null,
    Object? kennelEmailAlertPreference = null,
    Object? membershipExpirationDate = freezed,
    Object? memberSince = freezed,
    Object? membershipDurationInMonths = null,
    Object? appAccessFlags = null,
    Object? mismanagementRoles = null,
    Object? kennelShortName = freezed,
    Object? kennelCredit = null,
    Object? memberFollowingStatus = null,
    Object? memberInfoBeingUpdated = null,
  }) {
    return _then(_self.copyWith(
      hasherId: null == hasherId
          ? _self.hasherId
          : hasherId // ignore: cast_nullable_to_non_nullable
              as String,
      dispName: null == dispName
          ? _self.dispName
          : dispName // ignore: cast_nullable_to_non_nullable
              as String,
      nameForSort: null == nameForSort
          ? _self.nameForSort
          : nameForSort // ignore: cast_nullable_to_non_nullable
              as String,
      photo: freezed == photo
          ? _self.photo
          : photo // ignore: cast_nullable_to_non_nullable
              as String?,
      following: null == following
          ? _self.following
          : following // ignore: cast_nullable_to_non_nullable
              as int,
      kennelId: null == kennelId
          ? _self.kennelId
          : kennelId // ignore: cast_nullable_to_non_nullable
              as String,
      dateOfLastRun: freezed == dateOfLastRun
          ? _self.dateOfLastRun
          : dateOfLastRun // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      hcTotalRunCount: null == hcTotalRunCount
          ? _self.hcTotalRunCount
          : hcTotalRunCount // ignore: cast_nullable_to_non_nullable
              as int,
      hcHaringCount: null == hcHaringCount
          ? _self.hcHaringCount
          : hcHaringCount // ignore: cast_nullable_to_non_nullable
              as int,
      historicalTotalRunCount: null == historicalTotalRunCount
          ? _self.historicalTotalRunCount
          : historicalTotalRunCount // ignore: cast_nullable_to_non_nullable
              as int,
      historicalHaringCount: null == historicalHaringCount
          ? _self.historicalHaringCount
          : historicalHaringCount // ignore: cast_nullable_to_non_nullable
              as int,
      kennelEmailAlertPreference: null == kennelEmailAlertPreference
          ? _self.kennelEmailAlertPreference
          : kennelEmailAlertPreference // ignore: cast_nullable_to_non_nullable
              as int,
      membershipExpirationDate: freezed == membershipExpirationDate
          ? _self.membershipExpirationDate
          : membershipExpirationDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      memberSince: freezed == memberSince
          ? _self.memberSince
          : memberSince // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      membershipDurationInMonths: null == membershipDurationInMonths
          ? _self.membershipDurationInMonths
          : membershipDurationInMonths // ignore: cast_nullable_to_non_nullable
              as int,
      appAccessFlags: null == appAccessFlags
          ? _self.appAccessFlags
          : appAccessFlags // ignore: cast_nullable_to_non_nullable
              as int,
      mismanagementRoles: null == mismanagementRoles
          ? _self.mismanagementRoles
          : mismanagementRoles // ignore: cast_nullable_to_non_nullable
              as int,
      kennelShortName: freezed == kennelShortName
          ? _self.kennelShortName
          : kennelShortName // ignore: cast_nullable_to_non_nullable
              as String?,
      kennelCredit: null == kennelCredit
          ? _self.kennelCredit
          : kennelCredit // ignore: cast_nullable_to_non_nullable
              as double,
      memberFollowingStatus: null == memberFollowingStatus
          ? _self.memberFollowingStatus
          : memberFollowingStatus // ignore: cast_nullable_to_non_nullable
              as int,
      memberInfoBeingUpdated: null == memberInfoBeingUpdated
          ? _self.memberInfoBeingUpdated
          : memberInfoBeingUpdated // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _KennelMemberResultsModel
    with DiagnosticableTreeMixin
    implements KennelMemberResultsModel {
  _KennelMemberResultsModel(
      {required this.hasherId,
      required this.dispName,
      required this.nameForSort,
      this.photo,
      this.following = 0,
      required this.kennelId,
      this.dateOfLastRun,
      this.hcTotalRunCount = 0,
      this.hcHaringCount = 0,
      this.historicalTotalRunCount = 0,
      this.historicalHaringCount = 0,
      this.kennelEmailAlertPreference = 0,
      this.membershipExpirationDate,
      this.memberSince,
      this.membershipDurationInMonths = 6,
      this.appAccessFlags = 0,
      this.mismanagementRoles = 0,
      this.kennelShortName,
      this.kennelCredit = 0.0,
      this.memberFollowingStatus = 0,
      @JsonKey(includeFromJson: false, includeToJson: false)
      this.memberInfoBeingUpdated = false});
  factory _KennelMemberResultsModel.fromJson(Map<String, dynamic> json) =>
      _$KennelMemberResultsModelFromJson(json);

  @override
  final String hasherId;
  @override
  final String dispName;
  @override
  final String nameForSort;
  @override
  final String? photo;
  @override
  @JsonKey()
  final int following;
  @override
  final String kennelId;
  @override
  final DateTime? dateOfLastRun;
  @override
  @JsonKey()
  final int hcTotalRunCount;
  @override
  @JsonKey()
  final int hcHaringCount;
  @override
  @JsonKey()
  final int historicalTotalRunCount;
  @override
  @JsonKey()
  final int historicalHaringCount;
  @override
  @JsonKey()
  final int kennelEmailAlertPreference;
  @override
  final DateTime? membershipExpirationDate;
  @override
  final DateTime? memberSince;
  @override
  @JsonKey()
  final int membershipDurationInMonths;
  @override
  @JsonKey()
  final int appAccessFlags;
  @override
  @JsonKey()
  final int mismanagementRoles;
  @override
  final String? kennelShortName;
  @override
  @JsonKey()
  final double kennelCredit;
  @override
  @JsonKey()
  final int memberFollowingStatus;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  final bool memberInfoBeingUpdated;

  /// Create a copy of KennelMemberResultsModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$KennelMemberResultsModelCopyWith<_KennelMemberResultsModel> get copyWith =>
      __$KennelMemberResultsModelCopyWithImpl<_KennelMemberResultsModel>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$KennelMemberResultsModelToJson(
      this,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'KennelMemberResultsModel'))
      ..add(DiagnosticsProperty('hasherId', hasherId))
      ..add(DiagnosticsProperty('dispName', dispName))
      ..add(DiagnosticsProperty('nameForSort', nameForSort))
      ..add(DiagnosticsProperty('photo', photo))
      ..add(DiagnosticsProperty('following', following))
      ..add(DiagnosticsProperty('kennelId', kennelId))
      ..add(DiagnosticsProperty('dateOfLastRun', dateOfLastRun))
      ..add(DiagnosticsProperty('hcTotalRunCount', hcTotalRunCount))
      ..add(DiagnosticsProperty('hcHaringCount', hcHaringCount))
      ..add(DiagnosticsProperty(
          'historicalTotalRunCount', historicalTotalRunCount))
      ..add(DiagnosticsProperty('historicalHaringCount', historicalHaringCount))
      ..add(DiagnosticsProperty(
          'kennelEmailAlertPreference', kennelEmailAlertPreference))
      ..add(DiagnosticsProperty(
          'membershipExpirationDate', membershipExpirationDate))
      ..add(DiagnosticsProperty('memberSince', memberSince))
      ..add(DiagnosticsProperty(
          'membershipDurationInMonths', membershipDurationInMonths))
      ..add(DiagnosticsProperty('appAccessFlags', appAccessFlags))
      ..add(DiagnosticsProperty('mismanagementRoles', mismanagementRoles))
      ..add(DiagnosticsProperty('kennelShortName', kennelShortName))
      ..add(DiagnosticsProperty('kennelCredit', kennelCredit))
      ..add(DiagnosticsProperty('memberFollowingStatus', memberFollowingStatus))
      ..add(DiagnosticsProperty(
          'memberInfoBeingUpdated', memberInfoBeingUpdated));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _KennelMemberResultsModel &&
            (identical(other.hasherId, hasherId) ||
                other.hasherId == hasherId) &&
            (identical(other.dispName, dispName) ||
                other.dispName == dispName) &&
            (identical(other.nameForSort, nameForSort) ||
                other.nameForSort == nameForSort) &&
            (identical(other.photo, photo) || other.photo == photo) &&
            (identical(other.following, following) ||
                other.following == following) &&
            (identical(other.kennelId, kennelId) ||
                other.kennelId == kennelId) &&
            (identical(other.dateOfLastRun, dateOfLastRun) ||
                other.dateOfLastRun == dateOfLastRun) &&
            (identical(other.hcTotalRunCount, hcTotalRunCount) ||
                other.hcTotalRunCount == hcTotalRunCount) &&
            (identical(other.hcHaringCount, hcHaringCount) ||
                other.hcHaringCount == hcHaringCount) &&
            (identical(other.historicalTotalRunCount, historicalTotalRunCount) ||
                other.historicalTotalRunCount == historicalTotalRunCount) &&
            (identical(other.historicalHaringCount, historicalHaringCount) ||
                other.historicalHaringCount == historicalHaringCount) &&
            (identical(other.kennelEmailAlertPreference,
                    kennelEmailAlertPreference) ||
                other.kennelEmailAlertPreference ==
                    kennelEmailAlertPreference) &&
            (identical(other.membershipExpirationDate, membershipExpirationDate) ||
                other.membershipExpirationDate == membershipExpirationDate) &&
            (identical(other.memberSince, memberSince) ||
                other.memberSince == memberSince) &&
            (identical(other.membershipDurationInMonths,
                    membershipDurationInMonths) ||
                other.membershipDurationInMonths ==
                    membershipDurationInMonths) &&
            (identical(other.appAccessFlags, appAccessFlags) ||
                other.appAccessFlags == appAccessFlags) &&
            (identical(other.mismanagementRoles, mismanagementRoles) ||
                other.mismanagementRoles == mismanagementRoles) &&
            (identical(other.kennelShortName, kennelShortName) ||
                other.kennelShortName == kennelShortName) &&
            (identical(other.kennelCredit, kennelCredit) ||
                other.kennelCredit == kennelCredit) &&
            (identical(other.memberFollowingStatus, memberFollowingStatus) ||
                other.memberFollowingStatus == memberFollowingStatus) &&
            (identical(other.memberInfoBeingUpdated, memberInfoBeingUpdated) ||
                other.memberInfoBeingUpdated == memberInfoBeingUpdated));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        hasherId,
        dispName,
        nameForSort,
        photo,
        following,
        kennelId,
        dateOfLastRun,
        hcTotalRunCount,
        hcHaringCount,
        historicalTotalRunCount,
        historicalHaringCount,
        kennelEmailAlertPreference,
        membershipExpirationDate,
        memberSince,
        membershipDurationInMonths,
        appAccessFlags,
        mismanagementRoles,
        kennelShortName,
        kennelCredit,
        memberFollowingStatus,
        memberInfoBeingUpdated
      ]);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'KennelMemberResultsModel(hasherId: $hasherId, dispName: $dispName, nameForSort: $nameForSort, photo: $photo, following: $following, kennelId: $kennelId, dateOfLastRun: $dateOfLastRun, hcTotalRunCount: $hcTotalRunCount, hcHaringCount: $hcHaringCount, historicalTotalRunCount: $historicalTotalRunCount, historicalHaringCount: $historicalHaringCount, kennelEmailAlertPreference: $kennelEmailAlertPreference, membershipExpirationDate: $membershipExpirationDate, memberSince: $memberSince, membershipDurationInMonths: $membershipDurationInMonths, appAccessFlags: $appAccessFlags, mismanagementRoles: $mismanagementRoles, kennelShortName: $kennelShortName, kennelCredit: $kennelCredit, memberFollowingStatus: $memberFollowingStatus, memberInfoBeingUpdated: $memberInfoBeingUpdated)';
  }
}

/// @nodoc
abstract mixin class _$KennelMemberResultsModelCopyWith<$Res>
    implements $KennelMemberResultsModelCopyWith<$Res> {
  factory _$KennelMemberResultsModelCopyWith(_KennelMemberResultsModel value,
          $Res Function(_KennelMemberResultsModel) _then) =
      __$KennelMemberResultsModelCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String hasherId,
      String dispName,
      String nameForSort,
      String? photo,
      int following,
      String kennelId,
      DateTime? dateOfLastRun,
      int hcTotalRunCount,
      int hcHaringCount,
      int historicalTotalRunCount,
      int historicalHaringCount,
      int kennelEmailAlertPreference,
      DateTime? membershipExpirationDate,
      DateTime? memberSince,
      int membershipDurationInMonths,
      int appAccessFlags,
      int mismanagementRoles,
      String? kennelShortName,
      double kennelCredit,
      int memberFollowingStatus,
      @JsonKey(includeFromJson: false, includeToJson: false)
      bool memberInfoBeingUpdated});
}

/// @nodoc
class __$KennelMemberResultsModelCopyWithImpl<$Res>
    implements _$KennelMemberResultsModelCopyWith<$Res> {
  __$KennelMemberResultsModelCopyWithImpl(this._self, this._then);

  final _KennelMemberResultsModel _self;
  final $Res Function(_KennelMemberResultsModel) _then;

  /// Create a copy of KennelMemberResultsModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? hasherId = null,
    Object? dispName = null,
    Object? nameForSort = null,
    Object? photo = freezed,
    Object? following = null,
    Object? kennelId = null,
    Object? dateOfLastRun = freezed,
    Object? hcTotalRunCount = null,
    Object? hcHaringCount = null,
    Object? historicalTotalRunCount = null,
    Object? historicalHaringCount = null,
    Object? kennelEmailAlertPreference = null,
    Object? membershipExpirationDate = freezed,
    Object? memberSince = freezed,
    Object? membershipDurationInMonths = null,
    Object? appAccessFlags = null,
    Object? mismanagementRoles = null,
    Object? kennelShortName = freezed,
    Object? kennelCredit = null,
    Object? memberFollowingStatus = null,
    Object? memberInfoBeingUpdated = null,
  }) {
    return _then(_KennelMemberResultsModel(
      hasherId: null == hasherId
          ? _self.hasherId
          : hasherId // ignore: cast_nullable_to_non_nullable
              as String,
      dispName: null == dispName
          ? _self.dispName
          : dispName // ignore: cast_nullable_to_non_nullable
              as String,
      nameForSort: null == nameForSort
          ? _self.nameForSort
          : nameForSort // ignore: cast_nullable_to_non_nullable
              as String,
      photo: freezed == photo
          ? _self.photo
          : photo // ignore: cast_nullable_to_non_nullable
              as String?,
      following: null == following
          ? _self.following
          : following // ignore: cast_nullable_to_non_nullable
              as int,
      kennelId: null == kennelId
          ? _self.kennelId
          : kennelId // ignore: cast_nullable_to_non_nullable
              as String,
      dateOfLastRun: freezed == dateOfLastRun
          ? _self.dateOfLastRun
          : dateOfLastRun // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      hcTotalRunCount: null == hcTotalRunCount
          ? _self.hcTotalRunCount
          : hcTotalRunCount // ignore: cast_nullable_to_non_nullable
              as int,
      hcHaringCount: null == hcHaringCount
          ? _self.hcHaringCount
          : hcHaringCount // ignore: cast_nullable_to_non_nullable
              as int,
      historicalTotalRunCount: null == historicalTotalRunCount
          ? _self.historicalTotalRunCount
          : historicalTotalRunCount // ignore: cast_nullable_to_non_nullable
              as int,
      historicalHaringCount: null == historicalHaringCount
          ? _self.historicalHaringCount
          : historicalHaringCount // ignore: cast_nullable_to_non_nullable
              as int,
      kennelEmailAlertPreference: null == kennelEmailAlertPreference
          ? _self.kennelEmailAlertPreference
          : kennelEmailAlertPreference // ignore: cast_nullable_to_non_nullable
              as int,
      membershipExpirationDate: freezed == membershipExpirationDate
          ? _self.membershipExpirationDate
          : membershipExpirationDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      memberSince: freezed == memberSince
          ? _self.memberSince
          : memberSince // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      membershipDurationInMonths: null == membershipDurationInMonths
          ? _self.membershipDurationInMonths
          : membershipDurationInMonths // ignore: cast_nullable_to_non_nullable
              as int,
      appAccessFlags: null == appAccessFlags
          ? _self.appAccessFlags
          : appAccessFlags // ignore: cast_nullable_to_non_nullable
              as int,
      mismanagementRoles: null == mismanagementRoles
          ? _self.mismanagementRoles
          : mismanagementRoles // ignore: cast_nullable_to_non_nullable
              as int,
      kennelShortName: freezed == kennelShortName
          ? _self.kennelShortName
          : kennelShortName // ignore: cast_nullable_to_non_nullable
              as String?,
      kennelCredit: null == kennelCredit
          ? _self.kennelCredit
          : kennelCredit // ignore: cast_nullable_to_non_nullable
              as double,
      memberFollowingStatus: null == memberFollowingStatus
          ? _self.memberFollowingStatus
          : memberFollowingStatus // ignore: cast_nullable_to_non_nullable
              as int,
      memberInfoBeingUpdated: null == memberInfoBeingUpdated
          ? _self.memberInfoBeingUpdated
          : memberInfoBeingUpdated // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

// dart format on
