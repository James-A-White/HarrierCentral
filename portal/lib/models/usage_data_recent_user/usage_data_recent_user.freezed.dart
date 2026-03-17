// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'usage_data_recent_user.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UdRecentUserModel implements DiagnosticableTreeMixin {
  String get userId;
  String get userName;
  String get realName;
  String get photo;
  DateTime get lastLoginDate;
  int get minutesSinceLastLogin;
  int get loginCount;
  int get isIphone;
  String get systemVersion;
  String get kennelName;
  String get kennelShortName;
  String get hcVersion;
  int get highlightPhoneVersion;
  int get highlightHcVersion;

  /// Create a copy of UdRecentUserModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $UdRecentUserModelCopyWith<UdRecentUserModel> get copyWith =>
      _$UdRecentUserModelCopyWithImpl<UdRecentUserModel>(
          this as UdRecentUserModel, _$identity);

  /// Serializes this UdRecentUserModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'UdRecentUserModel'))
      ..add(DiagnosticsProperty('userId', userId))
      ..add(DiagnosticsProperty('userName', userName))
      ..add(DiagnosticsProperty('realName', realName))
      ..add(DiagnosticsProperty('photo', photo))
      ..add(DiagnosticsProperty('lastLoginDate', lastLoginDate))
      ..add(DiagnosticsProperty('minutesSinceLastLogin', minutesSinceLastLogin))
      ..add(DiagnosticsProperty('loginCount', loginCount))
      ..add(DiagnosticsProperty('isIphone', isIphone))
      ..add(DiagnosticsProperty('systemVersion', systemVersion))
      ..add(DiagnosticsProperty('kennelName', kennelName))
      ..add(DiagnosticsProperty('kennelShortName', kennelShortName))
      ..add(DiagnosticsProperty('hcVersion', hcVersion))
      ..add(DiagnosticsProperty('highlightPhoneVersion', highlightPhoneVersion))
      ..add(DiagnosticsProperty('highlightHcVersion', highlightHcVersion));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is UdRecentUserModel &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.userName, userName) ||
                other.userName == userName) &&
            (identical(other.realName, realName) ||
                other.realName == realName) &&
            (identical(other.photo, photo) || other.photo == photo) &&
            (identical(other.lastLoginDate, lastLoginDate) ||
                other.lastLoginDate == lastLoginDate) &&
            (identical(other.minutesSinceLastLogin, minutesSinceLastLogin) ||
                other.minutesSinceLastLogin == minutesSinceLastLogin) &&
            (identical(other.loginCount, loginCount) ||
                other.loginCount == loginCount) &&
            (identical(other.isIphone, isIphone) ||
                other.isIphone == isIphone) &&
            (identical(other.systemVersion, systemVersion) ||
                other.systemVersion == systemVersion) &&
            (identical(other.kennelName, kennelName) ||
                other.kennelName == kennelName) &&
            (identical(other.kennelShortName, kennelShortName) ||
                other.kennelShortName == kennelShortName) &&
            (identical(other.hcVersion, hcVersion) ||
                other.hcVersion == hcVersion) &&
            (identical(other.highlightPhoneVersion, highlightPhoneVersion) ||
                other.highlightPhoneVersion == highlightPhoneVersion) &&
            (identical(other.highlightHcVersion, highlightHcVersion) ||
                other.highlightHcVersion == highlightHcVersion));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      userId,
      userName,
      realName,
      photo,
      lastLoginDate,
      minutesSinceLastLogin,
      loginCount,
      isIphone,
      systemVersion,
      kennelName,
      kennelShortName,
      hcVersion,
      highlightPhoneVersion,
      highlightHcVersion);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'UdRecentUserModel(userId: $userId, userName: $userName, realName: $realName, photo: $photo, lastLoginDate: $lastLoginDate, minutesSinceLastLogin: $minutesSinceLastLogin, loginCount: $loginCount, isIphone: $isIphone, systemVersion: $systemVersion, kennelName: $kennelName, kennelShortName: $kennelShortName, hcVersion: $hcVersion, highlightPhoneVersion: $highlightPhoneVersion, highlightHcVersion: $highlightHcVersion)';
  }
}

/// @nodoc
abstract mixin class $UdRecentUserModelCopyWith<$Res> {
  factory $UdRecentUserModelCopyWith(
          UdRecentUserModel value, $Res Function(UdRecentUserModel) _then) =
      _$UdRecentUserModelCopyWithImpl;
  @useResult
  $Res call(
      {String userId,
      String userName,
      String realName,
      String photo,
      DateTime lastLoginDate,
      int minutesSinceLastLogin,
      int loginCount,
      int isIphone,
      String systemVersion,
      String kennelName,
      String kennelShortName,
      String hcVersion,
      int highlightPhoneVersion,
      int highlightHcVersion});
}

/// @nodoc
class _$UdRecentUserModelCopyWithImpl<$Res>
    implements $UdRecentUserModelCopyWith<$Res> {
  _$UdRecentUserModelCopyWithImpl(this._self, this._then);

  final UdRecentUserModel _self;
  final $Res Function(UdRecentUserModel) _then;

  /// Create a copy of UdRecentUserModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? userName = null,
    Object? realName = null,
    Object? photo = null,
    Object? lastLoginDate = null,
    Object? minutesSinceLastLogin = null,
    Object? loginCount = null,
    Object? isIphone = null,
    Object? systemVersion = null,
    Object? kennelName = null,
    Object? kennelShortName = null,
    Object? hcVersion = null,
    Object? highlightPhoneVersion = null,
    Object? highlightHcVersion = null,
  }) {
    return _then(_self.copyWith(
      userId: null == userId
          ? _self.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      userName: null == userName
          ? _self.userName
          : userName // ignore: cast_nullable_to_non_nullable
              as String,
      realName: null == realName
          ? _self.realName
          : realName // ignore: cast_nullable_to_non_nullable
              as String,
      photo: null == photo
          ? _self.photo
          : photo // ignore: cast_nullable_to_non_nullable
              as String,
      lastLoginDate: null == lastLoginDate
          ? _self.lastLoginDate
          : lastLoginDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      minutesSinceLastLogin: null == minutesSinceLastLogin
          ? _self.minutesSinceLastLogin
          : minutesSinceLastLogin // ignore: cast_nullable_to_non_nullable
              as int,
      loginCount: null == loginCount
          ? _self.loginCount
          : loginCount // ignore: cast_nullable_to_non_nullable
              as int,
      isIphone: null == isIphone
          ? _self.isIphone
          : isIphone // ignore: cast_nullable_to_non_nullable
              as int,
      systemVersion: null == systemVersion
          ? _self.systemVersion
          : systemVersion // ignore: cast_nullable_to_non_nullable
              as String,
      kennelName: null == kennelName
          ? _self.kennelName
          : kennelName // ignore: cast_nullable_to_non_nullable
              as String,
      kennelShortName: null == kennelShortName
          ? _self.kennelShortName
          : kennelShortName // ignore: cast_nullable_to_non_nullable
              as String,
      hcVersion: null == hcVersion
          ? _self.hcVersion
          : hcVersion // ignore: cast_nullable_to_non_nullable
              as String,
      highlightPhoneVersion: null == highlightPhoneVersion
          ? _self.highlightPhoneVersion
          : highlightPhoneVersion // ignore: cast_nullable_to_non_nullable
              as int,
      highlightHcVersion: null == highlightHcVersion
          ? _self.highlightHcVersion
          : highlightHcVersion // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// Adds pattern-matching-related methods to [UdRecentUserModel].
extension UdRecentUserModelPatterns on UdRecentUserModel {
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
    TResult Function(_UdRecentUserModel value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _UdRecentUserModel() when $default != null:
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
    TResult Function(_UdRecentUserModel value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UdRecentUserModel():
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
    TResult? Function(_UdRecentUserModel value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UdRecentUserModel() when $default != null:
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
            String userId,
            String userName,
            String realName,
            String photo,
            DateTime lastLoginDate,
            int minutesSinceLastLogin,
            int loginCount,
            int isIphone,
            String systemVersion,
            String kennelName,
            String kennelShortName,
            String hcVersion,
            int highlightPhoneVersion,
            int highlightHcVersion)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _UdRecentUserModel() when $default != null:
        return $default(
            _that.userId,
            _that.userName,
            _that.realName,
            _that.photo,
            _that.lastLoginDate,
            _that.minutesSinceLastLogin,
            _that.loginCount,
            _that.isIphone,
            _that.systemVersion,
            _that.kennelName,
            _that.kennelShortName,
            _that.hcVersion,
            _that.highlightPhoneVersion,
            _that.highlightHcVersion);
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
            String userId,
            String userName,
            String realName,
            String photo,
            DateTime lastLoginDate,
            int minutesSinceLastLogin,
            int loginCount,
            int isIphone,
            String systemVersion,
            String kennelName,
            String kennelShortName,
            String hcVersion,
            int highlightPhoneVersion,
            int highlightHcVersion)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UdRecentUserModel():
        return $default(
            _that.userId,
            _that.userName,
            _that.realName,
            _that.photo,
            _that.lastLoginDate,
            _that.minutesSinceLastLogin,
            _that.loginCount,
            _that.isIphone,
            _that.systemVersion,
            _that.kennelName,
            _that.kennelShortName,
            _that.hcVersion,
            _that.highlightPhoneVersion,
            _that.highlightHcVersion);
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
            String userId,
            String userName,
            String realName,
            String photo,
            DateTime lastLoginDate,
            int minutesSinceLastLogin,
            int loginCount,
            int isIphone,
            String systemVersion,
            String kennelName,
            String kennelShortName,
            String hcVersion,
            int highlightPhoneVersion,
            int highlightHcVersion)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UdRecentUserModel() when $default != null:
        return $default(
            _that.userId,
            _that.userName,
            _that.realName,
            _that.photo,
            _that.lastLoginDate,
            _that.minutesSinceLastLogin,
            _that.loginCount,
            _that.isIphone,
            _that.systemVersion,
            _that.kennelName,
            _that.kennelShortName,
            _that.hcVersion,
            _that.highlightPhoneVersion,
            _that.highlightHcVersion);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _UdRecentUserModel
    with DiagnosticableTreeMixin
    implements UdRecentUserModel {
  _UdRecentUserModel(
      {this.userId = '',
      required this.userName,
      this.realName = '',
      required this.photo,
      required this.lastLoginDate,
      required this.minutesSinceLastLogin,
      required this.loginCount,
      required this.isIphone,
      required this.systemVersion,
      required this.kennelName,
      required this.kennelShortName,
      required this.hcVersion,
      required this.highlightPhoneVersion,
      required this.highlightHcVersion});
  factory _UdRecentUserModel.fromJson(Map<String, dynamic> json) =>
      _$UdRecentUserModelFromJson(json);

  @override
  @JsonKey()
  final String userId;
  @override
  final String userName;
  @override
  @JsonKey()
  final String realName;
  @override
  final String photo;
  @override
  final DateTime lastLoginDate;
  @override
  final int minutesSinceLastLogin;
  @override
  final int loginCount;
  @override
  final int isIphone;
  @override
  final String systemVersion;
  @override
  final String kennelName;
  @override
  final String kennelShortName;
  @override
  final String hcVersion;
  @override
  final int highlightPhoneVersion;
  @override
  final int highlightHcVersion;

  /// Create a copy of UdRecentUserModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$UdRecentUserModelCopyWith<_UdRecentUserModel> get copyWith =>
      __$UdRecentUserModelCopyWithImpl<_UdRecentUserModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$UdRecentUserModelToJson(
      this,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'UdRecentUserModel'))
      ..add(DiagnosticsProperty('userId', userId))
      ..add(DiagnosticsProperty('userName', userName))
      ..add(DiagnosticsProperty('realName', realName))
      ..add(DiagnosticsProperty('photo', photo))
      ..add(DiagnosticsProperty('lastLoginDate', lastLoginDate))
      ..add(DiagnosticsProperty('minutesSinceLastLogin', minutesSinceLastLogin))
      ..add(DiagnosticsProperty('loginCount', loginCount))
      ..add(DiagnosticsProperty('isIphone', isIphone))
      ..add(DiagnosticsProperty('systemVersion', systemVersion))
      ..add(DiagnosticsProperty('kennelName', kennelName))
      ..add(DiagnosticsProperty('kennelShortName', kennelShortName))
      ..add(DiagnosticsProperty('hcVersion', hcVersion))
      ..add(DiagnosticsProperty('highlightPhoneVersion', highlightPhoneVersion))
      ..add(DiagnosticsProperty('highlightHcVersion', highlightHcVersion));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _UdRecentUserModel &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.userName, userName) ||
                other.userName == userName) &&
            (identical(other.realName, realName) ||
                other.realName == realName) &&
            (identical(other.photo, photo) || other.photo == photo) &&
            (identical(other.lastLoginDate, lastLoginDate) ||
                other.lastLoginDate == lastLoginDate) &&
            (identical(other.minutesSinceLastLogin, minutesSinceLastLogin) ||
                other.minutesSinceLastLogin == minutesSinceLastLogin) &&
            (identical(other.loginCount, loginCount) ||
                other.loginCount == loginCount) &&
            (identical(other.isIphone, isIphone) ||
                other.isIphone == isIphone) &&
            (identical(other.systemVersion, systemVersion) ||
                other.systemVersion == systemVersion) &&
            (identical(other.kennelName, kennelName) ||
                other.kennelName == kennelName) &&
            (identical(other.kennelShortName, kennelShortName) ||
                other.kennelShortName == kennelShortName) &&
            (identical(other.hcVersion, hcVersion) ||
                other.hcVersion == hcVersion) &&
            (identical(other.highlightPhoneVersion, highlightPhoneVersion) ||
                other.highlightPhoneVersion == highlightPhoneVersion) &&
            (identical(other.highlightHcVersion, highlightHcVersion) ||
                other.highlightHcVersion == highlightHcVersion));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      userId,
      userName,
      realName,
      photo,
      lastLoginDate,
      minutesSinceLastLogin,
      loginCount,
      isIphone,
      systemVersion,
      kennelName,
      kennelShortName,
      hcVersion,
      highlightPhoneVersion,
      highlightHcVersion);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'UdRecentUserModel(userId: $userId, userName: $userName, realName: $realName, photo: $photo, lastLoginDate: $lastLoginDate, minutesSinceLastLogin: $minutesSinceLastLogin, loginCount: $loginCount, isIphone: $isIphone, systemVersion: $systemVersion, kennelName: $kennelName, kennelShortName: $kennelShortName, hcVersion: $hcVersion, highlightPhoneVersion: $highlightPhoneVersion, highlightHcVersion: $highlightHcVersion)';
  }
}

/// @nodoc
abstract mixin class _$UdRecentUserModelCopyWith<$Res>
    implements $UdRecentUserModelCopyWith<$Res> {
  factory _$UdRecentUserModelCopyWith(
          _UdRecentUserModel value, $Res Function(_UdRecentUserModel) _then) =
      __$UdRecentUserModelCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String userId,
      String userName,
      String realName,
      String photo,
      DateTime lastLoginDate,
      int minutesSinceLastLogin,
      int loginCount,
      int isIphone,
      String systemVersion,
      String kennelName,
      String kennelShortName,
      String hcVersion,
      int highlightPhoneVersion,
      int highlightHcVersion});
}

/// @nodoc
class __$UdRecentUserModelCopyWithImpl<$Res>
    implements _$UdRecentUserModelCopyWith<$Res> {
  __$UdRecentUserModelCopyWithImpl(this._self, this._then);

  final _UdRecentUserModel _self;
  final $Res Function(_UdRecentUserModel) _then;

  /// Create a copy of UdRecentUserModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? userId = null,
    Object? userName = null,
    Object? realName = null,
    Object? photo = null,
    Object? lastLoginDate = null,
    Object? minutesSinceLastLogin = null,
    Object? loginCount = null,
    Object? isIphone = null,
    Object? systemVersion = null,
    Object? kennelName = null,
    Object? kennelShortName = null,
    Object? hcVersion = null,
    Object? highlightPhoneVersion = null,
    Object? highlightHcVersion = null,
  }) {
    return _then(_UdRecentUserModel(
      userId: null == userId
          ? _self.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      userName: null == userName
          ? _self.userName
          : userName // ignore: cast_nullable_to_non_nullable
              as String,
      realName: null == realName
          ? _self.realName
          : realName // ignore: cast_nullable_to_non_nullable
              as String,
      photo: null == photo
          ? _self.photo
          : photo // ignore: cast_nullable_to_non_nullable
              as String,
      lastLoginDate: null == lastLoginDate
          ? _self.lastLoginDate
          : lastLoginDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      minutesSinceLastLogin: null == minutesSinceLastLogin
          ? _self.minutesSinceLastLogin
          : minutesSinceLastLogin // ignore: cast_nullable_to_non_nullable
              as int,
      loginCount: null == loginCount
          ? _self.loginCount
          : loginCount // ignore: cast_nullable_to_non_nullable
              as int,
      isIphone: null == isIphone
          ? _self.isIphone
          : isIphone // ignore: cast_nullable_to_non_nullable
              as int,
      systemVersion: null == systemVersion
          ? _self.systemVersion
          : systemVersion // ignore: cast_nullable_to_non_nullable
              as String,
      kennelName: null == kennelName
          ? _self.kennelName
          : kennelName // ignore: cast_nullable_to_non_nullable
              as String,
      kennelShortName: null == kennelShortName
          ? _self.kennelShortName
          : kennelShortName // ignore: cast_nullable_to_non_nullable
              as String,
      hcVersion: null == hcVersion
          ? _self.hcVersion
          : hcVersion // ignore: cast_nullable_to_non_nullable
              as String,
      highlightPhoneVersion: null == highlightPhoneVersion
          ? _self.highlightPhoneVersion
          : highlightPhoneVersion // ignore: cast_nullable_to_non_nullable
              as int,
      highlightHcVersion: null == highlightHcVersion
          ? _self.highlightHcVersion
          : highlightHcVersion // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

// dart format on
