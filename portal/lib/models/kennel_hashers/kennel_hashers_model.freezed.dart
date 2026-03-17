// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'kennel_hashers_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$KennelHashersModel implements DiagnosticableTreeMixin {
  String get publicHasherId;
  String get publicKennelId;
  String get eMail;
  String get photo;
  String get inviteCode;
  String get isHomeKennel;
  String get isFollowing;
  String get isMember;
  String get status;
  String get notifications;
  String get emailAlerts;
  int get historicHaring;
  int get historicTotalRuns;
  int get hcHaringCount;
  int get hcTotalRunCount;
  String get historicCountsAreEstimates;
  num get kennelCredit;
  num get discountAmount;
  int get discountPercent;
  num get hashCredit;
  String? get hashName;
  String? get firstName;
  String? get lastName;
  String? get displayName;
  DateTime? get lastLoginDateTime;
  DateTime? get dateOfLastRun;
  DateTime? get membershipExpirationDate;
  String? get discountDescription;
  String? get atLastEvent;
  String? get atSecondToLastEvent;
  DateTime? get lastEventDate;
  DateTime? get nextEventDate;
  DateTime? get secondToLastEventDate;
  String? get nextEventNumber;

  /// Create a copy of KennelHashersModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $KennelHashersModelCopyWith<KennelHashersModel> get copyWith =>
      _$KennelHashersModelCopyWithImpl<KennelHashersModel>(
          this as KennelHashersModel, _$identity);

  /// Serializes this KennelHashersModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'KennelHashersModel'))
      ..add(DiagnosticsProperty('publicHasherId', publicHasherId))
      ..add(DiagnosticsProperty('publicKennelId', publicKennelId))
      ..add(DiagnosticsProperty('eMail', eMail))
      ..add(DiagnosticsProperty('photo', photo))
      ..add(DiagnosticsProperty('inviteCode', inviteCode))
      ..add(DiagnosticsProperty('isHomeKennel', isHomeKennel))
      ..add(DiagnosticsProperty('isFollowing', isFollowing))
      ..add(DiagnosticsProperty('isMember', isMember))
      ..add(DiagnosticsProperty('status', status))
      ..add(DiagnosticsProperty('notifications', notifications))
      ..add(DiagnosticsProperty('emailAlerts', emailAlerts))
      ..add(DiagnosticsProperty('historicHaring', historicHaring))
      ..add(DiagnosticsProperty('historicTotalRuns', historicTotalRuns))
      ..add(DiagnosticsProperty('hcHaringCount', hcHaringCount))
      ..add(DiagnosticsProperty('hcTotalRunCount', hcTotalRunCount))
      ..add(DiagnosticsProperty(
          'historicCountsAreEstimates', historicCountsAreEstimates))
      ..add(DiagnosticsProperty('kennelCredit', kennelCredit))
      ..add(DiagnosticsProperty('discountAmount', discountAmount))
      ..add(DiagnosticsProperty('discountPercent', discountPercent))
      ..add(DiagnosticsProperty('hashCredit', hashCredit))
      ..add(DiagnosticsProperty('hashName', hashName))
      ..add(DiagnosticsProperty('firstName', firstName))
      ..add(DiagnosticsProperty('lastName', lastName))
      ..add(DiagnosticsProperty('displayName', displayName))
      ..add(DiagnosticsProperty('lastLoginDateTime', lastLoginDateTime))
      ..add(DiagnosticsProperty('dateOfLastRun', dateOfLastRun))
      ..add(DiagnosticsProperty(
          'membershipExpirationDate', membershipExpirationDate))
      ..add(DiagnosticsProperty('discountDescription', discountDescription))
      ..add(DiagnosticsProperty('atLastEvent', atLastEvent))
      ..add(DiagnosticsProperty('atSecondToLastEvent', atSecondToLastEvent))
      ..add(DiagnosticsProperty('lastEventDate', lastEventDate))
      ..add(DiagnosticsProperty('nextEventDate', nextEventDate))
      ..add(DiagnosticsProperty('secondToLastEventDate', secondToLastEventDate))
      ..add(DiagnosticsProperty('nextEventNumber', nextEventNumber));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is KennelHashersModel &&
            (identical(other.publicHasherId, publicHasherId) ||
                other.publicHasherId == publicHasherId) &&
            (identical(other.publicKennelId, publicKennelId) ||
                other.publicKennelId == publicKennelId) &&
            (identical(other.eMail, eMail) || other.eMail == eMail) &&
            (identical(other.photo, photo) || other.photo == photo) &&
            (identical(other.inviteCode, inviteCode) ||
                other.inviteCode == inviteCode) &&
            (identical(other.isHomeKennel, isHomeKennel) ||
                other.isHomeKennel == isHomeKennel) &&
            (identical(other.isFollowing, isFollowing) ||
                other.isFollowing == isFollowing) &&
            (identical(other.isMember, isMember) ||
                other.isMember == isMember) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.notifications, notifications) ||
                other.notifications == notifications) &&
            (identical(other.emailAlerts, emailAlerts) ||
                other.emailAlerts == emailAlerts) &&
            (identical(other.historicHaring, historicHaring) ||
                other.historicHaring == historicHaring) &&
            (identical(other.historicTotalRuns, historicTotalRuns) ||
                other.historicTotalRuns == historicTotalRuns) &&
            (identical(other.hcHaringCount, hcHaringCount) ||
                other.hcHaringCount == hcHaringCount) &&
            (identical(other.hcTotalRunCount, hcTotalRunCount) ||
                other.hcTotalRunCount == hcTotalRunCount) &&
            (identical(other.historicCountsAreEstimates,
                    historicCountsAreEstimates) ||
                other.historicCountsAreEstimates ==
                    historicCountsAreEstimates) &&
            (identical(other.kennelCredit, kennelCredit) ||
                other.kennelCredit == kennelCredit) &&
            (identical(other.discountAmount, discountAmount) ||
                other.discountAmount == discountAmount) &&
            (identical(other.discountPercent, discountPercent) ||
                other.discountPercent == discountPercent) &&
            (identical(other.hashCredit, hashCredit) ||
                other.hashCredit == hashCredit) &&
            (identical(other.hashName, hashName) ||
                other.hashName == hashName) &&
            (identical(other.firstName, firstName) ||
                other.firstName == firstName) &&
            (identical(other.lastName, lastName) ||
                other.lastName == lastName) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.lastLoginDateTime, lastLoginDateTime) ||
                other.lastLoginDateTime == lastLoginDateTime) &&
            (identical(other.dateOfLastRun, dateOfLastRun) ||
                other.dateOfLastRun == dateOfLastRun) &&
            (identical(
                    other.membershipExpirationDate, membershipExpirationDate) ||
                other.membershipExpirationDate == membershipExpirationDate) &&
            (identical(other.discountDescription, discountDescription) ||
                other.discountDescription == discountDescription) &&
            (identical(other.atLastEvent, atLastEvent) ||
                other.atLastEvent == atLastEvent) &&
            (identical(other.atSecondToLastEvent, atSecondToLastEvent) ||
                other.atSecondToLastEvent == atSecondToLastEvent) &&
            (identical(other.lastEventDate, lastEventDate) ||
                other.lastEventDate == lastEventDate) &&
            (identical(other.nextEventDate, nextEventDate) ||
                other.nextEventDate == nextEventDate) &&
            (identical(other.secondToLastEventDate, secondToLastEventDate) ||
                other.secondToLastEventDate == secondToLastEventDate) &&
            (identical(other.nextEventNumber, nextEventNumber) ||
                other.nextEventNumber == nextEventNumber));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        publicHasherId,
        publicKennelId,
        eMail,
        photo,
        inviteCode,
        isHomeKennel,
        isFollowing,
        isMember,
        status,
        notifications,
        emailAlerts,
        historicHaring,
        historicTotalRuns,
        hcHaringCount,
        hcTotalRunCount,
        historicCountsAreEstimates,
        kennelCredit,
        discountAmount,
        discountPercent,
        hashCredit,
        hashName,
        firstName,
        lastName,
        displayName,
        lastLoginDateTime,
        dateOfLastRun,
        membershipExpirationDate,
        discountDescription,
        atLastEvent,
        atSecondToLastEvent,
        lastEventDate,
        nextEventDate,
        secondToLastEventDate,
        nextEventNumber
      ]);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'KennelHashersModel(publicHasherId: $publicHasherId, publicKennelId: $publicKennelId, eMail: $eMail, photo: $photo, inviteCode: $inviteCode, isHomeKennel: $isHomeKennel, isFollowing: $isFollowing, isMember: $isMember, status: $status, notifications: $notifications, emailAlerts: $emailAlerts, historicHaring: $historicHaring, historicTotalRuns: $historicTotalRuns, hcHaringCount: $hcHaringCount, hcTotalRunCount: $hcTotalRunCount, historicCountsAreEstimates: $historicCountsAreEstimates, kennelCredit: $kennelCredit, discountAmount: $discountAmount, discountPercent: $discountPercent, hashCredit: $hashCredit, hashName: $hashName, firstName: $firstName, lastName: $lastName, displayName: $displayName, lastLoginDateTime: $lastLoginDateTime, dateOfLastRun: $dateOfLastRun, membershipExpirationDate: $membershipExpirationDate, discountDescription: $discountDescription, atLastEvent: $atLastEvent, atSecondToLastEvent: $atSecondToLastEvent, lastEventDate: $lastEventDate, nextEventDate: $nextEventDate, secondToLastEventDate: $secondToLastEventDate, nextEventNumber: $nextEventNumber)';
  }
}

/// @nodoc
abstract mixin class $KennelHashersModelCopyWith<$Res> {
  factory $KennelHashersModelCopyWith(
          KennelHashersModel value, $Res Function(KennelHashersModel) _then) =
      _$KennelHashersModelCopyWithImpl;
  @useResult
  $Res call(
      {String publicHasherId,
      String publicKennelId,
      String eMail,
      String photo,
      String inviteCode,
      String isHomeKennel,
      String isFollowing,
      String isMember,
      String status,
      String notifications,
      String emailAlerts,
      int historicHaring,
      int historicTotalRuns,
      int hcHaringCount,
      int hcTotalRunCount,
      String historicCountsAreEstimates,
      num kennelCredit,
      num discountAmount,
      int discountPercent,
      num hashCredit,
      String? hashName,
      String? firstName,
      String? lastName,
      String? displayName,
      DateTime? lastLoginDateTime,
      DateTime? dateOfLastRun,
      DateTime? membershipExpirationDate,
      String? discountDescription,
      String? atLastEvent,
      String? atSecondToLastEvent,
      DateTime? lastEventDate,
      DateTime? nextEventDate,
      DateTime? secondToLastEventDate,
      String? nextEventNumber});
}

/// @nodoc
class _$KennelHashersModelCopyWithImpl<$Res>
    implements $KennelHashersModelCopyWith<$Res> {
  _$KennelHashersModelCopyWithImpl(this._self, this._then);

  final KennelHashersModel _self;
  final $Res Function(KennelHashersModel) _then;

  /// Create a copy of KennelHashersModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? publicHasherId = null,
    Object? publicKennelId = null,
    Object? eMail = null,
    Object? photo = null,
    Object? inviteCode = null,
    Object? isHomeKennel = null,
    Object? isFollowing = null,
    Object? isMember = null,
    Object? status = null,
    Object? notifications = null,
    Object? emailAlerts = null,
    Object? historicHaring = null,
    Object? historicTotalRuns = null,
    Object? hcHaringCount = null,
    Object? hcTotalRunCount = null,
    Object? historicCountsAreEstimates = null,
    Object? kennelCredit = null,
    Object? discountAmount = null,
    Object? discountPercent = null,
    Object? hashCredit = null,
    Object? hashName = freezed,
    Object? firstName = freezed,
    Object? lastName = freezed,
    Object? displayName = freezed,
    Object? lastLoginDateTime = freezed,
    Object? dateOfLastRun = freezed,
    Object? membershipExpirationDate = freezed,
    Object? discountDescription = freezed,
    Object? atLastEvent = freezed,
    Object? atSecondToLastEvent = freezed,
    Object? lastEventDate = freezed,
    Object? nextEventDate = freezed,
    Object? secondToLastEventDate = freezed,
    Object? nextEventNumber = freezed,
  }) {
    return _then(_self.copyWith(
      publicHasherId: null == publicHasherId
          ? _self.publicHasherId
          : publicHasherId // ignore: cast_nullable_to_non_nullable
              as String,
      publicKennelId: null == publicKennelId
          ? _self.publicKennelId
          : publicKennelId // ignore: cast_nullable_to_non_nullable
              as String,
      eMail: null == eMail
          ? _self.eMail
          : eMail // ignore: cast_nullable_to_non_nullable
              as String,
      photo: null == photo
          ? _self.photo
          : photo // ignore: cast_nullable_to_non_nullable
              as String,
      inviteCode: null == inviteCode
          ? _self.inviteCode
          : inviteCode // ignore: cast_nullable_to_non_nullable
              as String,
      isHomeKennel: null == isHomeKennel
          ? _self.isHomeKennel
          : isHomeKennel // ignore: cast_nullable_to_non_nullable
              as String,
      isFollowing: null == isFollowing
          ? _self.isFollowing
          : isFollowing // ignore: cast_nullable_to_non_nullable
              as String,
      isMember: null == isMember
          ? _self.isMember
          : isMember // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      notifications: null == notifications
          ? _self.notifications
          : notifications // ignore: cast_nullable_to_non_nullable
              as String,
      emailAlerts: null == emailAlerts
          ? _self.emailAlerts
          : emailAlerts // ignore: cast_nullable_to_non_nullable
              as String,
      historicHaring: null == historicHaring
          ? _self.historicHaring
          : historicHaring // ignore: cast_nullable_to_non_nullable
              as int,
      historicTotalRuns: null == historicTotalRuns
          ? _self.historicTotalRuns
          : historicTotalRuns // ignore: cast_nullable_to_non_nullable
              as int,
      hcHaringCount: null == hcHaringCount
          ? _self.hcHaringCount
          : hcHaringCount // ignore: cast_nullable_to_non_nullable
              as int,
      hcTotalRunCount: null == hcTotalRunCount
          ? _self.hcTotalRunCount
          : hcTotalRunCount // ignore: cast_nullable_to_non_nullable
              as int,
      historicCountsAreEstimates: null == historicCountsAreEstimates
          ? _self.historicCountsAreEstimates
          : historicCountsAreEstimates // ignore: cast_nullable_to_non_nullable
              as String,
      kennelCredit: null == kennelCredit
          ? _self.kennelCredit
          : kennelCredit // ignore: cast_nullable_to_non_nullable
              as num,
      discountAmount: null == discountAmount
          ? _self.discountAmount
          : discountAmount // ignore: cast_nullable_to_non_nullable
              as num,
      discountPercent: null == discountPercent
          ? _self.discountPercent
          : discountPercent // ignore: cast_nullable_to_non_nullable
              as int,
      hashCredit: null == hashCredit
          ? _self.hashCredit
          : hashCredit // ignore: cast_nullable_to_non_nullable
              as num,
      hashName: freezed == hashName
          ? _self.hashName
          : hashName // ignore: cast_nullable_to_non_nullable
              as String?,
      firstName: freezed == firstName
          ? _self.firstName
          : firstName // ignore: cast_nullable_to_non_nullable
              as String?,
      lastName: freezed == lastName
          ? _self.lastName
          : lastName // ignore: cast_nullable_to_non_nullable
              as String?,
      displayName: freezed == displayName
          ? _self.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String?,
      lastLoginDateTime: freezed == lastLoginDateTime
          ? _self.lastLoginDateTime
          : lastLoginDateTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      dateOfLastRun: freezed == dateOfLastRun
          ? _self.dateOfLastRun
          : dateOfLastRun // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      membershipExpirationDate: freezed == membershipExpirationDate
          ? _self.membershipExpirationDate
          : membershipExpirationDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      discountDescription: freezed == discountDescription
          ? _self.discountDescription
          : discountDescription // ignore: cast_nullable_to_non_nullable
              as String?,
      atLastEvent: freezed == atLastEvent
          ? _self.atLastEvent
          : atLastEvent // ignore: cast_nullable_to_non_nullable
              as String?,
      atSecondToLastEvent: freezed == atSecondToLastEvent
          ? _self.atSecondToLastEvent
          : atSecondToLastEvent // ignore: cast_nullable_to_non_nullable
              as String?,
      lastEventDate: freezed == lastEventDate
          ? _self.lastEventDate
          : lastEventDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      nextEventDate: freezed == nextEventDate
          ? _self.nextEventDate
          : nextEventDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      secondToLastEventDate: freezed == secondToLastEventDate
          ? _self.secondToLastEventDate
          : secondToLastEventDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      nextEventNumber: freezed == nextEventNumber
          ? _self.nextEventNumber
          : nextEventNumber // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [KennelHashersModel].
extension KennelHashersModelPatterns on KennelHashersModel {
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
    TResult Function(_KennelHashersModel value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _KennelHashersModel() when $default != null:
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
    TResult Function(_KennelHashersModel value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _KennelHashersModel():
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
    TResult? Function(_KennelHashersModel value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _KennelHashersModel() when $default != null:
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
            String publicHasherId,
            String publicKennelId,
            String eMail,
            String photo,
            String inviteCode,
            String isHomeKennel,
            String isFollowing,
            String isMember,
            String status,
            String notifications,
            String emailAlerts,
            int historicHaring,
            int historicTotalRuns,
            int hcHaringCount,
            int hcTotalRunCount,
            String historicCountsAreEstimates,
            num kennelCredit,
            num discountAmount,
            int discountPercent,
            num hashCredit,
            String? hashName,
            String? firstName,
            String? lastName,
            String? displayName,
            DateTime? lastLoginDateTime,
            DateTime? dateOfLastRun,
            DateTime? membershipExpirationDate,
            String? discountDescription,
            String? atLastEvent,
            String? atSecondToLastEvent,
            DateTime? lastEventDate,
            DateTime? nextEventDate,
            DateTime? secondToLastEventDate,
            String? nextEventNumber)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _KennelHashersModel() when $default != null:
        return $default(
            _that.publicHasherId,
            _that.publicKennelId,
            _that.eMail,
            _that.photo,
            _that.inviteCode,
            _that.isHomeKennel,
            _that.isFollowing,
            _that.isMember,
            _that.status,
            _that.notifications,
            _that.emailAlerts,
            _that.historicHaring,
            _that.historicTotalRuns,
            _that.hcHaringCount,
            _that.hcTotalRunCount,
            _that.historicCountsAreEstimates,
            _that.kennelCredit,
            _that.discountAmount,
            _that.discountPercent,
            _that.hashCredit,
            _that.hashName,
            _that.firstName,
            _that.lastName,
            _that.displayName,
            _that.lastLoginDateTime,
            _that.dateOfLastRun,
            _that.membershipExpirationDate,
            _that.discountDescription,
            _that.atLastEvent,
            _that.atSecondToLastEvent,
            _that.lastEventDate,
            _that.nextEventDate,
            _that.secondToLastEventDate,
            _that.nextEventNumber);
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
            String publicHasherId,
            String publicKennelId,
            String eMail,
            String photo,
            String inviteCode,
            String isHomeKennel,
            String isFollowing,
            String isMember,
            String status,
            String notifications,
            String emailAlerts,
            int historicHaring,
            int historicTotalRuns,
            int hcHaringCount,
            int hcTotalRunCount,
            String historicCountsAreEstimates,
            num kennelCredit,
            num discountAmount,
            int discountPercent,
            num hashCredit,
            String? hashName,
            String? firstName,
            String? lastName,
            String? displayName,
            DateTime? lastLoginDateTime,
            DateTime? dateOfLastRun,
            DateTime? membershipExpirationDate,
            String? discountDescription,
            String? atLastEvent,
            String? atSecondToLastEvent,
            DateTime? lastEventDate,
            DateTime? nextEventDate,
            DateTime? secondToLastEventDate,
            String? nextEventNumber)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _KennelHashersModel():
        return $default(
            _that.publicHasherId,
            _that.publicKennelId,
            _that.eMail,
            _that.photo,
            _that.inviteCode,
            _that.isHomeKennel,
            _that.isFollowing,
            _that.isMember,
            _that.status,
            _that.notifications,
            _that.emailAlerts,
            _that.historicHaring,
            _that.historicTotalRuns,
            _that.hcHaringCount,
            _that.hcTotalRunCount,
            _that.historicCountsAreEstimates,
            _that.kennelCredit,
            _that.discountAmount,
            _that.discountPercent,
            _that.hashCredit,
            _that.hashName,
            _that.firstName,
            _that.lastName,
            _that.displayName,
            _that.lastLoginDateTime,
            _that.dateOfLastRun,
            _that.membershipExpirationDate,
            _that.discountDescription,
            _that.atLastEvent,
            _that.atSecondToLastEvent,
            _that.lastEventDate,
            _that.nextEventDate,
            _that.secondToLastEventDate,
            _that.nextEventNumber);
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
            String publicHasherId,
            String publicKennelId,
            String eMail,
            String photo,
            String inviteCode,
            String isHomeKennel,
            String isFollowing,
            String isMember,
            String status,
            String notifications,
            String emailAlerts,
            int historicHaring,
            int historicTotalRuns,
            int hcHaringCount,
            int hcTotalRunCount,
            String historicCountsAreEstimates,
            num kennelCredit,
            num discountAmount,
            int discountPercent,
            num hashCredit,
            String? hashName,
            String? firstName,
            String? lastName,
            String? displayName,
            DateTime? lastLoginDateTime,
            DateTime? dateOfLastRun,
            DateTime? membershipExpirationDate,
            String? discountDescription,
            String? atLastEvent,
            String? atSecondToLastEvent,
            DateTime? lastEventDate,
            DateTime? nextEventDate,
            DateTime? secondToLastEventDate,
            String? nextEventNumber)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _KennelHashersModel() when $default != null:
        return $default(
            _that.publicHasherId,
            _that.publicKennelId,
            _that.eMail,
            _that.photo,
            _that.inviteCode,
            _that.isHomeKennel,
            _that.isFollowing,
            _that.isMember,
            _that.status,
            _that.notifications,
            _that.emailAlerts,
            _that.historicHaring,
            _that.historicTotalRuns,
            _that.hcHaringCount,
            _that.hcTotalRunCount,
            _that.historicCountsAreEstimates,
            _that.kennelCredit,
            _that.discountAmount,
            _that.discountPercent,
            _that.hashCredit,
            _that.hashName,
            _that.firstName,
            _that.lastName,
            _that.displayName,
            _that.lastLoginDateTime,
            _that.dateOfLastRun,
            _that.membershipExpirationDate,
            _that.discountDescription,
            _that.atLastEvent,
            _that.atSecondToLastEvent,
            _that.lastEventDate,
            _that.nextEventDate,
            _that.secondToLastEventDate,
            _that.nextEventNumber);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _KennelHashersModel
    with DiagnosticableTreeMixin
    implements KennelHashersModel {
  _KennelHashersModel(
      {required this.publicHasherId,
      required this.publicKennelId,
      required this.eMail,
      required this.photo,
      required this.inviteCode,
      required this.isHomeKennel,
      required this.isFollowing,
      required this.isMember,
      required this.status,
      required this.notifications,
      required this.emailAlerts,
      required this.historicHaring,
      required this.historicTotalRuns,
      required this.hcHaringCount,
      required this.hcTotalRunCount,
      required this.historicCountsAreEstimates,
      required this.kennelCredit,
      required this.discountAmount,
      required this.discountPercent,
      required this.hashCredit,
      this.hashName,
      this.firstName,
      this.lastName,
      this.displayName,
      this.lastLoginDateTime,
      this.dateOfLastRun,
      this.membershipExpirationDate,
      this.discountDescription,
      this.atLastEvent,
      this.atSecondToLastEvent,
      this.lastEventDate,
      this.nextEventDate,
      this.secondToLastEventDate,
      this.nextEventNumber});
  factory _KennelHashersModel.fromJson(Map<String, dynamic> json) =>
      _$KennelHashersModelFromJson(json);

  @override
  final String publicHasherId;
  @override
  final String publicKennelId;
  @override
  final String eMail;
  @override
  final String photo;
  @override
  final String inviteCode;
  @override
  final String isHomeKennel;
  @override
  final String isFollowing;
  @override
  final String isMember;
  @override
  final String status;
  @override
  final String notifications;
  @override
  final String emailAlerts;
  @override
  final int historicHaring;
  @override
  final int historicTotalRuns;
  @override
  final int hcHaringCount;
  @override
  final int hcTotalRunCount;
  @override
  final String historicCountsAreEstimates;
  @override
  final num kennelCredit;
  @override
  final num discountAmount;
  @override
  final int discountPercent;
  @override
  final num hashCredit;
  @override
  final String? hashName;
  @override
  final String? firstName;
  @override
  final String? lastName;
  @override
  final String? displayName;
  @override
  final DateTime? lastLoginDateTime;
  @override
  final DateTime? dateOfLastRun;
  @override
  final DateTime? membershipExpirationDate;
  @override
  final String? discountDescription;
  @override
  final String? atLastEvent;
  @override
  final String? atSecondToLastEvent;
  @override
  final DateTime? lastEventDate;
  @override
  final DateTime? nextEventDate;
  @override
  final DateTime? secondToLastEventDate;
  @override
  final String? nextEventNumber;

  /// Create a copy of KennelHashersModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$KennelHashersModelCopyWith<_KennelHashersModel> get copyWith =>
      __$KennelHashersModelCopyWithImpl<_KennelHashersModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$KennelHashersModelToJson(
      this,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'KennelHashersModel'))
      ..add(DiagnosticsProperty('publicHasherId', publicHasherId))
      ..add(DiagnosticsProperty('publicKennelId', publicKennelId))
      ..add(DiagnosticsProperty('eMail', eMail))
      ..add(DiagnosticsProperty('photo', photo))
      ..add(DiagnosticsProperty('inviteCode', inviteCode))
      ..add(DiagnosticsProperty('isHomeKennel', isHomeKennel))
      ..add(DiagnosticsProperty('isFollowing', isFollowing))
      ..add(DiagnosticsProperty('isMember', isMember))
      ..add(DiagnosticsProperty('status', status))
      ..add(DiagnosticsProperty('notifications', notifications))
      ..add(DiagnosticsProperty('emailAlerts', emailAlerts))
      ..add(DiagnosticsProperty('historicHaring', historicHaring))
      ..add(DiagnosticsProperty('historicTotalRuns', historicTotalRuns))
      ..add(DiagnosticsProperty('hcHaringCount', hcHaringCount))
      ..add(DiagnosticsProperty('hcTotalRunCount', hcTotalRunCount))
      ..add(DiagnosticsProperty(
          'historicCountsAreEstimates', historicCountsAreEstimates))
      ..add(DiagnosticsProperty('kennelCredit', kennelCredit))
      ..add(DiagnosticsProperty('discountAmount', discountAmount))
      ..add(DiagnosticsProperty('discountPercent', discountPercent))
      ..add(DiagnosticsProperty('hashCredit', hashCredit))
      ..add(DiagnosticsProperty('hashName', hashName))
      ..add(DiagnosticsProperty('firstName', firstName))
      ..add(DiagnosticsProperty('lastName', lastName))
      ..add(DiagnosticsProperty('displayName', displayName))
      ..add(DiagnosticsProperty('lastLoginDateTime', lastLoginDateTime))
      ..add(DiagnosticsProperty('dateOfLastRun', dateOfLastRun))
      ..add(DiagnosticsProperty(
          'membershipExpirationDate', membershipExpirationDate))
      ..add(DiagnosticsProperty('discountDescription', discountDescription))
      ..add(DiagnosticsProperty('atLastEvent', atLastEvent))
      ..add(DiagnosticsProperty('atSecondToLastEvent', atSecondToLastEvent))
      ..add(DiagnosticsProperty('lastEventDate', lastEventDate))
      ..add(DiagnosticsProperty('nextEventDate', nextEventDate))
      ..add(DiagnosticsProperty('secondToLastEventDate', secondToLastEventDate))
      ..add(DiagnosticsProperty('nextEventNumber', nextEventNumber));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _KennelHashersModel &&
            (identical(other.publicHasherId, publicHasherId) ||
                other.publicHasherId == publicHasherId) &&
            (identical(other.publicKennelId, publicKennelId) ||
                other.publicKennelId == publicKennelId) &&
            (identical(other.eMail, eMail) || other.eMail == eMail) &&
            (identical(other.photo, photo) || other.photo == photo) &&
            (identical(other.inviteCode, inviteCode) ||
                other.inviteCode == inviteCode) &&
            (identical(other.isHomeKennel, isHomeKennel) ||
                other.isHomeKennel == isHomeKennel) &&
            (identical(other.isFollowing, isFollowing) ||
                other.isFollowing == isFollowing) &&
            (identical(other.isMember, isMember) ||
                other.isMember == isMember) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.notifications, notifications) ||
                other.notifications == notifications) &&
            (identical(other.emailAlerts, emailAlerts) ||
                other.emailAlerts == emailAlerts) &&
            (identical(other.historicHaring, historicHaring) ||
                other.historicHaring == historicHaring) &&
            (identical(other.historicTotalRuns, historicTotalRuns) ||
                other.historicTotalRuns == historicTotalRuns) &&
            (identical(other.hcHaringCount, hcHaringCount) ||
                other.hcHaringCount == hcHaringCount) &&
            (identical(other.hcTotalRunCount, hcTotalRunCount) ||
                other.hcTotalRunCount == hcTotalRunCount) &&
            (identical(other.historicCountsAreEstimates,
                    historicCountsAreEstimates) ||
                other.historicCountsAreEstimates ==
                    historicCountsAreEstimates) &&
            (identical(other.kennelCredit, kennelCredit) ||
                other.kennelCredit == kennelCredit) &&
            (identical(other.discountAmount, discountAmount) ||
                other.discountAmount == discountAmount) &&
            (identical(other.discountPercent, discountPercent) ||
                other.discountPercent == discountPercent) &&
            (identical(other.hashCredit, hashCredit) ||
                other.hashCredit == hashCredit) &&
            (identical(other.hashName, hashName) ||
                other.hashName == hashName) &&
            (identical(other.firstName, firstName) ||
                other.firstName == firstName) &&
            (identical(other.lastName, lastName) ||
                other.lastName == lastName) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.lastLoginDateTime, lastLoginDateTime) ||
                other.lastLoginDateTime == lastLoginDateTime) &&
            (identical(other.dateOfLastRun, dateOfLastRun) ||
                other.dateOfLastRun == dateOfLastRun) &&
            (identical(
                    other.membershipExpirationDate, membershipExpirationDate) ||
                other.membershipExpirationDate == membershipExpirationDate) &&
            (identical(other.discountDescription, discountDescription) ||
                other.discountDescription == discountDescription) &&
            (identical(other.atLastEvent, atLastEvent) ||
                other.atLastEvent == atLastEvent) &&
            (identical(other.atSecondToLastEvent, atSecondToLastEvent) ||
                other.atSecondToLastEvent == atSecondToLastEvent) &&
            (identical(other.lastEventDate, lastEventDate) ||
                other.lastEventDate == lastEventDate) &&
            (identical(other.nextEventDate, nextEventDate) ||
                other.nextEventDate == nextEventDate) &&
            (identical(other.secondToLastEventDate, secondToLastEventDate) ||
                other.secondToLastEventDate == secondToLastEventDate) &&
            (identical(other.nextEventNumber, nextEventNumber) ||
                other.nextEventNumber == nextEventNumber));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        publicHasherId,
        publicKennelId,
        eMail,
        photo,
        inviteCode,
        isHomeKennel,
        isFollowing,
        isMember,
        status,
        notifications,
        emailAlerts,
        historicHaring,
        historicTotalRuns,
        hcHaringCount,
        hcTotalRunCount,
        historicCountsAreEstimates,
        kennelCredit,
        discountAmount,
        discountPercent,
        hashCredit,
        hashName,
        firstName,
        lastName,
        displayName,
        lastLoginDateTime,
        dateOfLastRun,
        membershipExpirationDate,
        discountDescription,
        atLastEvent,
        atSecondToLastEvent,
        lastEventDate,
        nextEventDate,
        secondToLastEventDate,
        nextEventNumber
      ]);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'KennelHashersModel(publicHasherId: $publicHasherId, publicKennelId: $publicKennelId, eMail: $eMail, photo: $photo, inviteCode: $inviteCode, isHomeKennel: $isHomeKennel, isFollowing: $isFollowing, isMember: $isMember, status: $status, notifications: $notifications, emailAlerts: $emailAlerts, historicHaring: $historicHaring, historicTotalRuns: $historicTotalRuns, hcHaringCount: $hcHaringCount, hcTotalRunCount: $hcTotalRunCount, historicCountsAreEstimates: $historicCountsAreEstimates, kennelCredit: $kennelCredit, discountAmount: $discountAmount, discountPercent: $discountPercent, hashCredit: $hashCredit, hashName: $hashName, firstName: $firstName, lastName: $lastName, displayName: $displayName, lastLoginDateTime: $lastLoginDateTime, dateOfLastRun: $dateOfLastRun, membershipExpirationDate: $membershipExpirationDate, discountDescription: $discountDescription, atLastEvent: $atLastEvent, atSecondToLastEvent: $atSecondToLastEvent, lastEventDate: $lastEventDate, nextEventDate: $nextEventDate, secondToLastEventDate: $secondToLastEventDate, nextEventNumber: $nextEventNumber)';
  }
}

/// @nodoc
abstract mixin class _$KennelHashersModelCopyWith<$Res>
    implements $KennelHashersModelCopyWith<$Res> {
  factory _$KennelHashersModelCopyWith(
          _KennelHashersModel value, $Res Function(_KennelHashersModel) _then) =
      __$KennelHashersModelCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String publicHasherId,
      String publicKennelId,
      String eMail,
      String photo,
      String inviteCode,
      String isHomeKennel,
      String isFollowing,
      String isMember,
      String status,
      String notifications,
      String emailAlerts,
      int historicHaring,
      int historicTotalRuns,
      int hcHaringCount,
      int hcTotalRunCount,
      String historicCountsAreEstimates,
      num kennelCredit,
      num discountAmount,
      int discountPercent,
      num hashCredit,
      String? hashName,
      String? firstName,
      String? lastName,
      String? displayName,
      DateTime? lastLoginDateTime,
      DateTime? dateOfLastRun,
      DateTime? membershipExpirationDate,
      String? discountDescription,
      String? atLastEvent,
      String? atSecondToLastEvent,
      DateTime? lastEventDate,
      DateTime? nextEventDate,
      DateTime? secondToLastEventDate,
      String? nextEventNumber});
}

/// @nodoc
class __$KennelHashersModelCopyWithImpl<$Res>
    implements _$KennelHashersModelCopyWith<$Res> {
  __$KennelHashersModelCopyWithImpl(this._self, this._then);

  final _KennelHashersModel _self;
  final $Res Function(_KennelHashersModel) _then;

  /// Create a copy of KennelHashersModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? publicHasherId = null,
    Object? publicKennelId = null,
    Object? eMail = null,
    Object? photo = null,
    Object? inviteCode = null,
    Object? isHomeKennel = null,
    Object? isFollowing = null,
    Object? isMember = null,
    Object? status = null,
    Object? notifications = null,
    Object? emailAlerts = null,
    Object? historicHaring = null,
    Object? historicTotalRuns = null,
    Object? hcHaringCount = null,
    Object? hcTotalRunCount = null,
    Object? historicCountsAreEstimates = null,
    Object? kennelCredit = null,
    Object? discountAmount = null,
    Object? discountPercent = null,
    Object? hashCredit = null,
    Object? hashName = freezed,
    Object? firstName = freezed,
    Object? lastName = freezed,
    Object? displayName = freezed,
    Object? lastLoginDateTime = freezed,
    Object? dateOfLastRun = freezed,
    Object? membershipExpirationDate = freezed,
    Object? discountDescription = freezed,
    Object? atLastEvent = freezed,
    Object? atSecondToLastEvent = freezed,
    Object? lastEventDate = freezed,
    Object? nextEventDate = freezed,
    Object? secondToLastEventDate = freezed,
    Object? nextEventNumber = freezed,
  }) {
    return _then(_KennelHashersModel(
      publicHasherId: null == publicHasherId
          ? _self.publicHasherId
          : publicHasherId // ignore: cast_nullable_to_non_nullable
              as String,
      publicKennelId: null == publicKennelId
          ? _self.publicKennelId
          : publicKennelId // ignore: cast_nullable_to_non_nullable
              as String,
      eMail: null == eMail
          ? _self.eMail
          : eMail // ignore: cast_nullable_to_non_nullable
              as String,
      photo: null == photo
          ? _self.photo
          : photo // ignore: cast_nullable_to_non_nullable
              as String,
      inviteCode: null == inviteCode
          ? _self.inviteCode
          : inviteCode // ignore: cast_nullable_to_non_nullable
              as String,
      isHomeKennel: null == isHomeKennel
          ? _self.isHomeKennel
          : isHomeKennel // ignore: cast_nullable_to_non_nullable
              as String,
      isFollowing: null == isFollowing
          ? _self.isFollowing
          : isFollowing // ignore: cast_nullable_to_non_nullable
              as String,
      isMember: null == isMember
          ? _self.isMember
          : isMember // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      notifications: null == notifications
          ? _self.notifications
          : notifications // ignore: cast_nullable_to_non_nullable
              as String,
      emailAlerts: null == emailAlerts
          ? _self.emailAlerts
          : emailAlerts // ignore: cast_nullable_to_non_nullable
              as String,
      historicHaring: null == historicHaring
          ? _self.historicHaring
          : historicHaring // ignore: cast_nullable_to_non_nullable
              as int,
      historicTotalRuns: null == historicTotalRuns
          ? _self.historicTotalRuns
          : historicTotalRuns // ignore: cast_nullable_to_non_nullable
              as int,
      hcHaringCount: null == hcHaringCount
          ? _self.hcHaringCount
          : hcHaringCount // ignore: cast_nullable_to_non_nullable
              as int,
      hcTotalRunCount: null == hcTotalRunCount
          ? _self.hcTotalRunCount
          : hcTotalRunCount // ignore: cast_nullable_to_non_nullable
              as int,
      historicCountsAreEstimates: null == historicCountsAreEstimates
          ? _self.historicCountsAreEstimates
          : historicCountsAreEstimates // ignore: cast_nullable_to_non_nullable
              as String,
      kennelCredit: null == kennelCredit
          ? _self.kennelCredit
          : kennelCredit // ignore: cast_nullable_to_non_nullable
              as num,
      discountAmount: null == discountAmount
          ? _self.discountAmount
          : discountAmount // ignore: cast_nullable_to_non_nullable
              as num,
      discountPercent: null == discountPercent
          ? _self.discountPercent
          : discountPercent // ignore: cast_nullable_to_non_nullable
              as int,
      hashCredit: null == hashCredit
          ? _self.hashCredit
          : hashCredit // ignore: cast_nullable_to_non_nullable
              as num,
      hashName: freezed == hashName
          ? _self.hashName
          : hashName // ignore: cast_nullable_to_non_nullable
              as String?,
      firstName: freezed == firstName
          ? _self.firstName
          : firstName // ignore: cast_nullable_to_non_nullable
              as String?,
      lastName: freezed == lastName
          ? _self.lastName
          : lastName // ignore: cast_nullable_to_non_nullable
              as String?,
      displayName: freezed == displayName
          ? _self.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String?,
      lastLoginDateTime: freezed == lastLoginDateTime
          ? _self.lastLoginDateTime
          : lastLoginDateTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      dateOfLastRun: freezed == dateOfLastRun
          ? _self.dateOfLastRun
          : dateOfLastRun // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      membershipExpirationDate: freezed == membershipExpirationDate
          ? _self.membershipExpirationDate
          : membershipExpirationDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      discountDescription: freezed == discountDescription
          ? _self.discountDescription
          : discountDescription // ignore: cast_nullable_to_non_nullable
              as String?,
      atLastEvent: freezed == atLastEvent
          ? _self.atLastEvent
          : atLastEvent // ignore: cast_nullable_to_non_nullable
              as String?,
      atSecondToLastEvent: freezed == atSecondToLastEvent
          ? _self.atSecondToLastEvent
          : atSecondToLastEvent // ignore: cast_nullable_to_non_nullable
              as String?,
      lastEventDate: freezed == lastEventDate
          ? _self.lastEventDate
          : lastEventDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      nextEventDate: freezed == nextEventDate
          ? _self.nextEventDate
          : nextEventDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      secondToLastEventDate: freezed == secondToLastEventDate
          ? _self.secondToLastEventDate
          : secondToLastEventDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      nextEventNumber: freezed == nextEventNumber
          ? _self.nextEventNumber
          : nextEventNumber // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on
