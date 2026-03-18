// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'hasher_kennels_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HasherKennelsModel implements DiagnosticableTreeMixin {
  String get publicKennelId;
  String get kennelName;
  String get kennelShortName;
  String get kennelUniqueShortName;
  String get kennelLogo;
  String get kennelCountryCodes;
  String get countryId;
  String get countryName;
  int get isFollowing;
  int get isMember;
  int get isHomeKennel;
  int get appAccessFlags;
  int get defaultTags1;
  int get defaultTags2;
  int get defaultTags3;
  int get defaultDigitsAfterDecimal;
  String get defaultCurrencySymbol;
  DateTime get defaultRunStartTime;
  double get cityLat;
  double get cityLon;
  double get defaultEventPriceForMembers;
  double get defaultEventPriceForNonMembers;
  String? get cityName;
  String? get regionName;
  String? get continentName;
  DateTime? get membershipExpirationDate;
  double? get kennelLat;
  double? get kennelLon;

  /// Create a copy of HasherKennelsModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $HasherKennelsModelCopyWith<HasherKennelsModel> get copyWith =>
      _$HasherKennelsModelCopyWithImpl<HasherKennelsModel>(
          this as HasherKennelsModel, _$identity);

  /// Serializes this HasherKennelsModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'HasherKennelsModel'))
      ..add(DiagnosticsProperty('publicKennelId', publicKennelId))
      ..add(DiagnosticsProperty('kennelName', kennelName))
      ..add(DiagnosticsProperty('kennelShortName', kennelShortName))
      ..add(DiagnosticsProperty('kennelUniqueShortName', kennelUniqueShortName))
      ..add(DiagnosticsProperty('kennelLogo', kennelLogo))
      ..add(DiagnosticsProperty('kennelCountryCodes', kennelCountryCodes))
      ..add(DiagnosticsProperty('countryId', countryId))
      ..add(DiagnosticsProperty('countryName', countryName))
      ..add(DiagnosticsProperty('isFollowing', isFollowing))
      ..add(DiagnosticsProperty('isMember', isMember))
      ..add(DiagnosticsProperty('isHomeKennel', isHomeKennel))
      ..add(DiagnosticsProperty('appAccessFlags', appAccessFlags))
      ..add(DiagnosticsProperty('defaultTags1', defaultTags1))
      ..add(DiagnosticsProperty('defaultTags2', defaultTags2))
      ..add(DiagnosticsProperty('defaultTags3', defaultTags3))
      ..add(DiagnosticsProperty(
          'defaultDigitsAfterDecimal', defaultDigitsAfterDecimal))
      ..add(DiagnosticsProperty('defaultCurrencySymbol', defaultCurrencySymbol))
      ..add(DiagnosticsProperty('defaultRunStartTime', defaultRunStartTime))
      ..add(DiagnosticsProperty('cityLat', cityLat))
      ..add(DiagnosticsProperty('cityLon', cityLon))
      ..add(DiagnosticsProperty(
          'defaultEventPriceForMembers', defaultEventPriceForMembers))
      ..add(DiagnosticsProperty(
          'defaultEventPriceForNonMembers', defaultEventPriceForNonMembers))
      ..add(DiagnosticsProperty('cityName', cityName))
      ..add(DiagnosticsProperty('regionName', regionName))
      ..add(DiagnosticsProperty('continentName', continentName))
      ..add(DiagnosticsProperty(
          'membershipExpirationDate', membershipExpirationDate))
      ..add(DiagnosticsProperty('kennelLat', kennelLat))
      ..add(DiagnosticsProperty('kennelLon', kennelLon));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is HasherKennelsModel &&
            (identical(other.publicKennelId, publicKennelId) ||
                other.publicKennelId == publicKennelId) &&
            (identical(other.kennelName, kennelName) ||
                other.kennelName == kennelName) &&
            (identical(other.kennelShortName, kennelShortName) ||
                other.kennelShortName == kennelShortName) &&
            (identical(other.kennelUniqueShortName, kennelUniqueShortName) ||
                other.kennelUniqueShortName == kennelUniqueShortName) &&
            (identical(other.kennelLogo, kennelLogo) ||
                other.kennelLogo == kennelLogo) &&
            (identical(other.kennelCountryCodes, kennelCountryCodes) ||
                other.kennelCountryCodes == kennelCountryCodes) &&
            (identical(other.countryId, countryId) ||
                other.countryId == countryId) &&
            (identical(other.countryName, countryName) ||
                other.countryName == countryName) &&
            (identical(other.isFollowing, isFollowing) ||
                other.isFollowing == isFollowing) &&
            (identical(other.isMember, isMember) ||
                other.isMember == isMember) &&
            (identical(other.isHomeKennel, isHomeKennel) ||
                other.isHomeKennel == isHomeKennel) &&
            (identical(other.appAccessFlags, appAccessFlags) ||
                other.appAccessFlags == appAccessFlags) &&
            (identical(other.defaultTags1, defaultTags1) ||
                other.defaultTags1 == defaultTags1) &&
            (identical(other.defaultTags2, defaultTags2) ||
                other.defaultTags2 == defaultTags2) &&
            (identical(other.defaultTags3, defaultTags3) ||
                other.defaultTags3 == defaultTags3) &&
            (identical(other.defaultDigitsAfterDecimal, defaultDigitsAfterDecimal) ||
                other.defaultDigitsAfterDecimal == defaultDigitsAfterDecimal) &&
            (identical(other.defaultCurrencySymbol, defaultCurrencySymbol) ||
                other.defaultCurrencySymbol == defaultCurrencySymbol) &&
            (identical(other.defaultRunStartTime, defaultRunStartTime) ||
                other.defaultRunStartTime == defaultRunStartTime) &&
            (identical(other.cityLat, cityLat) || other.cityLat == cityLat) &&
            (identical(other.cityLon, cityLon) || other.cityLon == cityLon) &&
            (identical(other.defaultEventPriceForMembers,
                    defaultEventPriceForMembers) ||
                other.defaultEventPriceForMembers ==
                    defaultEventPriceForMembers) &&
            (identical(other.defaultEventPriceForNonMembers,
                    defaultEventPriceForNonMembers) ||
                other.defaultEventPriceForNonMembers ==
                    defaultEventPriceForNonMembers) &&
            (identical(other.cityName, cityName) ||
                other.cityName == cityName) &&
            (identical(other.regionName, regionName) ||
                other.regionName == regionName) &&
            (identical(other.continentName, continentName) ||
                other.continentName == continentName) &&
            (identical(
                    other.membershipExpirationDate, membershipExpirationDate) ||
                other.membershipExpirationDate == membershipExpirationDate) &&
            (identical(other.kennelLat, kennelLat) ||
                other.kennelLat == kennelLat) &&
            (identical(other.kennelLon, kennelLon) ||
                other.kennelLon == kennelLon));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        publicKennelId,
        kennelName,
        kennelShortName,
        kennelUniqueShortName,
        kennelLogo,
        kennelCountryCodes,
        countryId,
        countryName,
        isFollowing,
        isMember,
        isHomeKennel,
        appAccessFlags,
        defaultTags1,
        defaultTags2,
        defaultTags3,
        defaultDigitsAfterDecimal,
        defaultCurrencySymbol,
        defaultRunStartTime,
        cityLat,
        cityLon,
        defaultEventPriceForMembers,
        defaultEventPriceForNonMembers,
        cityName,
        regionName,
        continentName,
        membershipExpirationDate,
        kennelLat,
        kennelLon
      ]);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'HasherKennelsModel(publicKennelId: $publicKennelId, kennelName: $kennelName, kennelShortName: $kennelShortName, kennelUniqueShortName: $kennelUniqueShortName, kennelLogo: $kennelLogo, kennelCountryCodes: $kennelCountryCodes, countryId: $countryId, countryName: $countryName, isFollowing: $isFollowing, isMember: $isMember, isHomeKennel: $isHomeKennel, appAccessFlags: $appAccessFlags, defaultTags1: $defaultTags1, defaultTags2: $defaultTags2, defaultTags3: $defaultTags3, defaultDigitsAfterDecimal: $defaultDigitsAfterDecimal, defaultCurrencySymbol: $defaultCurrencySymbol, defaultRunStartTime: $defaultRunStartTime, cityLat: $cityLat, cityLon: $cityLon, defaultEventPriceForMembers: $defaultEventPriceForMembers, defaultEventPriceForNonMembers: $defaultEventPriceForNonMembers, cityName: $cityName, regionName: $regionName, continentName: $continentName, membershipExpirationDate: $membershipExpirationDate, kennelLat: $kennelLat, kennelLon: $kennelLon)';
  }
}

/// @nodoc
abstract mixin class $HasherKennelsModelCopyWith<$Res> {
  factory $HasherKennelsModelCopyWith(
          HasherKennelsModel value, $Res Function(HasherKennelsModel) _then) =
      _$HasherKennelsModelCopyWithImpl;
  @useResult
  $Res call(
      {String publicKennelId,
      String kennelName,
      String kennelShortName,
      String kennelUniqueShortName,
      String kennelLogo,
      String kennelCountryCodes,
      String countryId,
      String countryName,
      int isFollowing,
      int isMember,
      int isHomeKennel,
      int appAccessFlags,
      int defaultTags1,
      int defaultTags2,
      int defaultTags3,
      int defaultDigitsAfterDecimal,
      String defaultCurrencySymbol,
      DateTime defaultRunStartTime,
      double cityLat,
      double cityLon,
      double defaultEventPriceForMembers,
      double defaultEventPriceForNonMembers,
      String? cityName,
      String? regionName,
      String? continentName,
      DateTime? membershipExpirationDate,
      double? kennelLat,
      double? kennelLon});
}

/// @nodoc
class _$HasherKennelsModelCopyWithImpl<$Res>
    implements $HasherKennelsModelCopyWith<$Res> {
  _$HasherKennelsModelCopyWithImpl(this._self, this._then);

  final HasherKennelsModel _self;
  final $Res Function(HasherKennelsModel) _then;

  /// Create a copy of HasherKennelsModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? publicKennelId = null,
    Object? kennelName = null,
    Object? kennelShortName = null,
    Object? kennelUniqueShortName = null,
    Object? kennelLogo = null,
    Object? kennelCountryCodes = null,
    Object? countryId = null,
    Object? countryName = null,
    Object? isFollowing = null,
    Object? isMember = null,
    Object? isHomeKennel = null,
    Object? appAccessFlags = null,
    Object? defaultTags1 = null,
    Object? defaultTags2 = null,
    Object? defaultTags3 = null,
    Object? defaultDigitsAfterDecimal = null,
    Object? defaultCurrencySymbol = null,
    Object? defaultRunStartTime = null,
    Object? cityLat = null,
    Object? cityLon = null,
    Object? defaultEventPriceForMembers = null,
    Object? defaultEventPriceForNonMembers = null,
    Object? cityName = freezed,
    Object? regionName = freezed,
    Object? continentName = freezed,
    Object? membershipExpirationDate = freezed,
    Object? kennelLat = freezed,
    Object? kennelLon = freezed,
  }) {
    return _then(_self.copyWith(
      publicKennelId: null == publicKennelId
          ? _self.publicKennelId
          : publicKennelId // ignore: cast_nullable_to_non_nullable
              as String,
      kennelName: null == kennelName
          ? _self.kennelName
          : kennelName // ignore: cast_nullable_to_non_nullable
              as String,
      kennelShortName: null == kennelShortName
          ? _self.kennelShortName
          : kennelShortName // ignore: cast_nullable_to_non_nullable
              as String,
      kennelUniqueShortName: null == kennelUniqueShortName
          ? _self.kennelUniqueShortName
          : kennelUniqueShortName // ignore: cast_nullable_to_non_nullable
              as String,
      kennelLogo: null == kennelLogo
          ? _self.kennelLogo
          : kennelLogo // ignore: cast_nullable_to_non_nullable
              as String,
      kennelCountryCodes: null == kennelCountryCodes
          ? _self.kennelCountryCodes
          : kennelCountryCodes // ignore: cast_nullable_to_non_nullable
              as String,
      countryId: null == countryId
          ? _self.countryId
          : countryId // ignore: cast_nullable_to_non_nullable
              as String,
      countryName: null == countryName
          ? _self.countryName
          : countryName // ignore: cast_nullable_to_non_nullable
              as String,
      isFollowing: null == isFollowing
          ? _self.isFollowing
          : isFollowing // ignore: cast_nullable_to_non_nullable
              as int,
      isMember: null == isMember
          ? _self.isMember
          : isMember // ignore: cast_nullable_to_non_nullable
              as int,
      isHomeKennel: null == isHomeKennel
          ? _self.isHomeKennel
          : isHomeKennel // ignore: cast_nullable_to_non_nullable
              as int,
      appAccessFlags: null == appAccessFlags
          ? _self.appAccessFlags
          : appAccessFlags // ignore: cast_nullable_to_non_nullable
              as int,
      defaultTags1: null == defaultTags1
          ? _self.defaultTags1
          : defaultTags1 // ignore: cast_nullable_to_non_nullable
              as int,
      defaultTags2: null == defaultTags2
          ? _self.defaultTags2
          : defaultTags2 // ignore: cast_nullable_to_non_nullable
              as int,
      defaultTags3: null == defaultTags3
          ? _self.defaultTags3
          : defaultTags3 // ignore: cast_nullable_to_non_nullable
              as int,
      defaultDigitsAfterDecimal: null == defaultDigitsAfterDecimal
          ? _self.defaultDigitsAfterDecimal
          : defaultDigitsAfterDecimal // ignore: cast_nullable_to_non_nullable
              as int,
      defaultCurrencySymbol: null == defaultCurrencySymbol
          ? _self.defaultCurrencySymbol
          : defaultCurrencySymbol // ignore: cast_nullable_to_non_nullable
              as String,
      defaultRunStartTime: null == defaultRunStartTime
          ? _self.defaultRunStartTime
          : defaultRunStartTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      cityLat: null == cityLat
          ? _self.cityLat
          : cityLat // ignore: cast_nullable_to_non_nullable
              as double,
      cityLon: null == cityLon
          ? _self.cityLon
          : cityLon // ignore: cast_nullable_to_non_nullable
              as double,
      defaultEventPriceForMembers: null == defaultEventPriceForMembers
          ? _self.defaultEventPriceForMembers
          : defaultEventPriceForMembers // ignore: cast_nullable_to_non_nullable
              as double,
      defaultEventPriceForNonMembers: null == defaultEventPriceForNonMembers
          ? _self.defaultEventPriceForNonMembers
          : defaultEventPriceForNonMembers // ignore: cast_nullable_to_non_nullable
              as double,
      cityName: freezed == cityName
          ? _self.cityName
          : cityName // ignore: cast_nullable_to_non_nullable
              as String?,
      regionName: freezed == regionName
          ? _self.regionName
          : regionName // ignore: cast_nullable_to_non_nullable
              as String?,
      continentName: freezed == continentName
          ? _self.continentName
          : continentName // ignore: cast_nullable_to_non_nullable
              as String?,
      membershipExpirationDate: freezed == membershipExpirationDate
          ? _self.membershipExpirationDate
          : membershipExpirationDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      kennelLat: freezed == kennelLat
          ? _self.kennelLat
          : kennelLat // ignore: cast_nullable_to_non_nullable
              as double?,
      kennelLon: freezed == kennelLon
          ? _self.kennelLon
          : kennelLon // ignore: cast_nullable_to_non_nullable
              as double?,
    ));
  }
}

/// Adds pattern-matching-related methods to [HasherKennelsModel].
extension HasherKennelsModelPatterns on HasherKennelsModel {
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
    TResult Function(_HasherKennelsModel value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _HasherKennelsModel() when $default != null:
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
    TResult Function(_HasherKennelsModel value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HasherKennelsModel():
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
    TResult? Function(_HasherKennelsModel value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HasherKennelsModel() when $default != null:
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
            String publicKennelId,
            String kennelName,
            String kennelShortName,
            String kennelUniqueShortName,
            String kennelLogo,
            String kennelCountryCodes,
            String countryId,
            String countryName,
            int isFollowing,
            int isMember,
            int isHomeKennel,
            int appAccessFlags,
            int defaultTags1,
            int defaultTags2,
            int defaultTags3,
            int defaultDigitsAfterDecimal,
            String defaultCurrencySymbol,
            DateTime defaultRunStartTime,
            double cityLat,
            double cityLon,
            double defaultEventPriceForMembers,
            double defaultEventPriceForNonMembers,
            String? cityName,
            String? regionName,
            String? continentName,
            DateTime? membershipExpirationDate,
            double? kennelLat,
            double? kennelLon)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _HasherKennelsModel() when $default != null:
        return $default(
            _that.publicKennelId,
            _that.kennelName,
            _that.kennelShortName,
            _that.kennelUniqueShortName,
            _that.kennelLogo,
            _that.kennelCountryCodes,
            _that.countryId,
            _that.countryName,
            _that.isFollowing,
            _that.isMember,
            _that.isHomeKennel,
            _that.appAccessFlags,
            _that.defaultTags1,
            _that.defaultTags2,
            _that.defaultTags3,
            _that.defaultDigitsAfterDecimal,
            _that.defaultCurrencySymbol,
            _that.defaultRunStartTime,
            _that.cityLat,
            _that.cityLon,
            _that.defaultEventPriceForMembers,
            _that.defaultEventPriceForNonMembers,
            _that.cityName,
            _that.regionName,
            _that.continentName,
            _that.membershipExpirationDate,
            _that.kennelLat,
            _that.kennelLon);
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
            String publicKennelId,
            String kennelName,
            String kennelShortName,
            String kennelUniqueShortName,
            String kennelLogo,
            String kennelCountryCodes,
            String countryId,
            String countryName,
            int isFollowing,
            int isMember,
            int isHomeKennel,
            int appAccessFlags,
            int defaultTags1,
            int defaultTags2,
            int defaultTags3,
            int defaultDigitsAfterDecimal,
            String defaultCurrencySymbol,
            DateTime defaultRunStartTime,
            double cityLat,
            double cityLon,
            double defaultEventPriceForMembers,
            double defaultEventPriceForNonMembers,
            String? cityName,
            String? regionName,
            String? continentName,
            DateTime? membershipExpirationDate,
            double? kennelLat,
            double? kennelLon)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HasherKennelsModel():
        return $default(
            _that.publicKennelId,
            _that.kennelName,
            _that.kennelShortName,
            _that.kennelUniqueShortName,
            _that.kennelLogo,
            _that.kennelCountryCodes,
            _that.countryId,
            _that.countryName,
            _that.isFollowing,
            _that.isMember,
            _that.isHomeKennel,
            _that.appAccessFlags,
            _that.defaultTags1,
            _that.defaultTags2,
            _that.defaultTags3,
            _that.defaultDigitsAfterDecimal,
            _that.defaultCurrencySymbol,
            _that.defaultRunStartTime,
            _that.cityLat,
            _that.cityLon,
            _that.defaultEventPriceForMembers,
            _that.defaultEventPriceForNonMembers,
            _that.cityName,
            _that.regionName,
            _that.continentName,
            _that.membershipExpirationDate,
            _that.kennelLat,
            _that.kennelLon);
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
            String publicKennelId,
            String kennelName,
            String kennelShortName,
            String kennelUniqueShortName,
            String kennelLogo,
            String kennelCountryCodes,
            String countryId,
            String countryName,
            int isFollowing,
            int isMember,
            int isHomeKennel,
            int appAccessFlags,
            int defaultTags1,
            int defaultTags2,
            int defaultTags3,
            int defaultDigitsAfterDecimal,
            String defaultCurrencySymbol,
            DateTime defaultRunStartTime,
            double cityLat,
            double cityLon,
            double defaultEventPriceForMembers,
            double defaultEventPriceForNonMembers,
            String? cityName,
            String? regionName,
            String? continentName,
            DateTime? membershipExpirationDate,
            double? kennelLat,
            double? kennelLon)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HasherKennelsModel() when $default != null:
        return $default(
            _that.publicKennelId,
            _that.kennelName,
            _that.kennelShortName,
            _that.kennelUniqueShortName,
            _that.kennelLogo,
            _that.kennelCountryCodes,
            _that.countryId,
            _that.countryName,
            _that.isFollowing,
            _that.isMember,
            _that.isHomeKennel,
            _that.appAccessFlags,
            _that.defaultTags1,
            _that.defaultTags2,
            _that.defaultTags3,
            _that.defaultDigitsAfterDecimal,
            _that.defaultCurrencySymbol,
            _that.defaultRunStartTime,
            _that.cityLat,
            _that.cityLon,
            _that.defaultEventPriceForMembers,
            _that.defaultEventPriceForNonMembers,
            _that.cityName,
            _that.regionName,
            _that.continentName,
            _that.membershipExpirationDate,
            _that.kennelLat,
            _that.kennelLon);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _HasherKennelsModel extends HasherKennelsModel
    with DiagnosticableTreeMixin {
  _HasherKennelsModel(
      {required this.publicKennelId,
      required this.kennelName,
      required this.kennelShortName,
      required this.kennelUniqueShortName,
      required this.kennelLogo,
      required this.kennelCountryCodes,
      required this.countryId,
      required this.countryName,
      required this.isFollowing,
      required this.isMember,
      required this.isHomeKennel,
      required this.appAccessFlags,
      required this.defaultTags1,
      required this.defaultTags2,
      required this.defaultTags3,
      required this.defaultDigitsAfterDecimal,
      required this.defaultCurrencySymbol,
      required this.defaultRunStartTime,
      required this.cityLat,
      required this.cityLon,
      required this.defaultEventPriceForMembers,
      required this.defaultEventPriceForNonMembers,
      this.cityName,
      this.regionName,
      this.continentName,
      this.membershipExpirationDate,
      this.kennelLat,
      this.kennelLon})
      : super._();
  factory _HasherKennelsModel.fromJson(Map<String, dynamic> json) =>
      _$HasherKennelsModelFromJson(json);

  @override
  final String publicKennelId;
  @override
  final String kennelName;
  @override
  final String kennelShortName;
  @override
  final String kennelUniqueShortName;
  @override
  final String kennelLogo;
  @override
  final String kennelCountryCodes;
  @override
  final String countryId;
  @override
  final String countryName;
  @override
  final int isFollowing;
  @override
  final int isMember;
  @override
  final int isHomeKennel;
  @override
  final int appAccessFlags;
  @override
  final int defaultTags1;
  @override
  final int defaultTags2;
  @override
  final int defaultTags3;
  @override
  final int defaultDigitsAfterDecimal;
  @override
  final String defaultCurrencySymbol;
  @override
  final DateTime defaultRunStartTime;
  @override
  final double cityLat;
  @override
  final double cityLon;
  @override
  final double defaultEventPriceForMembers;
  @override
  final double defaultEventPriceForNonMembers;
  @override
  final String? cityName;
  @override
  final String? regionName;
  @override
  final String? continentName;
  @override
  final DateTime? membershipExpirationDate;
  @override
  final double? kennelLat;
  @override
  final double? kennelLon;

  /// Create a copy of HasherKennelsModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$HasherKennelsModelCopyWith<_HasherKennelsModel> get copyWith =>
      __$HasherKennelsModelCopyWithImpl<_HasherKennelsModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$HasherKennelsModelToJson(
      this,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'HasherKennelsModel'))
      ..add(DiagnosticsProperty('publicKennelId', publicKennelId))
      ..add(DiagnosticsProperty('kennelName', kennelName))
      ..add(DiagnosticsProperty('kennelShortName', kennelShortName))
      ..add(DiagnosticsProperty('kennelUniqueShortName', kennelUniqueShortName))
      ..add(DiagnosticsProperty('kennelLogo', kennelLogo))
      ..add(DiagnosticsProperty('kennelCountryCodes', kennelCountryCodes))
      ..add(DiagnosticsProperty('countryId', countryId))
      ..add(DiagnosticsProperty('countryName', countryName))
      ..add(DiagnosticsProperty('isFollowing', isFollowing))
      ..add(DiagnosticsProperty('isMember', isMember))
      ..add(DiagnosticsProperty('isHomeKennel', isHomeKennel))
      ..add(DiagnosticsProperty('appAccessFlags', appAccessFlags))
      ..add(DiagnosticsProperty('defaultTags1', defaultTags1))
      ..add(DiagnosticsProperty('defaultTags2', defaultTags2))
      ..add(DiagnosticsProperty('defaultTags3', defaultTags3))
      ..add(DiagnosticsProperty(
          'defaultDigitsAfterDecimal', defaultDigitsAfterDecimal))
      ..add(DiagnosticsProperty('defaultCurrencySymbol', defaultCurrencySymbol))
      ..add(DiagnosticsProperty('defaultRunStartTime', defaultRunStartTime))
      ..add(DiagnosticsProperty('cityLat', cityLat))
      ..add(DiagnosticsProperty('cityLon', cityLon))
      ..add(DiagnosticsProperty(
          'defaultEventPriceForMembers', defaultEventPriceForMembers))
      ..add(DiagnosticsProperty(
          'defaultEventPriceForNonMembers', defaultEventPriceForNonMembers))
      ..add(DiagnosticsProperty('cityName', cityName))
      ..add(DiagnosticsProperty('regionName', regionName))
      ..add(DiagnosticsProperty('continentName', continentName))
      ..add(DiagnosticsProperty(
          'membershipExpirationDate', membershipExpirationDate))
      ..add(DiagnosticsProperty('kennelLat', kennelLat))
      ..add(DiagnosticsProperty('kennelLon', kennelLon));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _HasherKennelsModel &&
            (identical(other.publicKennelId, publicKennelId) ||
                other.publicKennelId == publicKennelId) &&
            (identical(other.kennelName, kennelName) ||
                other.kennelName == kennelName) &&
            (identical(other.kennelShortName, kennelShortName) ||
                other.kennelShortName == kennelShortName) &&
            (identical(other.kennelUniqueShortName, kennelUniqueShortName) ||
                other.kennelUniqueShortName == kennelUniqueShortName) &&
            (identical(other.kennelLogo, kennelLogo) ||
                other.kennelLogo == kennelLogo) &&
            (identical(other.kennelCountryCodes, kennelCountryCodes) ||
                other.kennelCountryCodes == kennelCountryCodes) &&
            (identical(other.countryId, countryId) ||
                other.countryId == countryId) &&
            (identical(other.countryName, countryName) ||
                other.countryName == countryName) &&
            (identical(other.isFollowing, isFollowing) ||
                other.isFollowing == isFollowing) &&
            (identical(other.isMember, isMember) ||
                other.isMember == isMember) &&
            (identical(other.isHomeKennel, isHomeKennel) ||
                other.isHomeKennel == isHomeKennel) &&
            (identical(other.appAccessFlags, appAccessFlags) ||
                other.appAccessFlags == appAccessFlags) &&
            (identical(other.defaultTags1, defaultTags1) ||
                other.defaultTags1 == defaultTags1) &&
            (identical(other.defaultTags2, defaultTags2) ||
                other.defaultTags2 == defaultTags2) &&
            (identical(other.defaultTags3, defaultTags3) ||
                other.defaultTags3 == defaultTags3) &&
            (identical(other.defaultDigitsAfterDecimal, defaultDigitsAfterDecimal) ||
                other.defaultDigitsAfterDecimal == defaultDigitsAfterDecimal) &&
            (identical(other.defaultCurrencySymbol, defaultCurrencySymbol) ||
                other.defaultCurrencySymbol == defaultCurrencySymbol) &&
            (identical(other.defaultRunStartTime, defaultRunStartTime) ||
                other.defaultRunStartTime == defaultRunStartTime) &&
            (identical(other.cityLat, cityLat) || other.cityLat == cityLat) &&
            (identical(other.cityLon, cityLon) || other.cityLon == cityLon) &&
            (identical(other.defaultEventPriceForMembers,
                    defaultEventPriceForMembers) ||
                other.defaultEventPriceForMembers ==
                    defaultEventPriceForMembers) &&
            (identical(other.defaultEventPriceForNonMembers,
                    defaultEventPriceForNonMembers) ||
                other.defaultEventPriceForNonMembers ==
                    defaultEventPriceForNonMembers) &&
            (identical(other.cityName, cityName) ||
                other.cityName == cityName) &&
            (identical(other.regionName, regionName) ||
                other.regionName == regionName) &&
            (identical(other.continentName, continentName) ||
                other.continentName == continentName) &&
            (identical(
                    other.membershipExpirationDate, membershipExpirationDate) ||
                other.membershipExpirationDate == membershipExpirationDate) &&
            (identical(other.kennelLat, kennelLat) ||
                other.kennelLat == kennelLat) &&
            (identical(other.kennelLon, kennelLon) ||
                other.kennelLon == kennelLon));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        publicKennelId,
        kennelName,
        kennelShortName,
        kennelUniqueShortName,
        kennelLogo,
        kennelCountryCodes,
        countryId,
        countryName,
        isFollowing,
        isMember,
        isHomeKennel,
        appAccessFlags,
        defaultTags1,
        defaultTags2,
        defaultTags3,
        defaultDigitsAfterDecimal,
        defaultCurrencySymbol,
        defaultRunStartTime,
        cityLat,
        cityLon,
        defaultEventPriceForMembers,
        defaultEventPriceForNonMembers,
        cityName,
        regionName,
        continentName,
        membershipExpirationDate,
        kennelLat,
        kennelLon
      ]);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'HasherKennelsModel(publicKennelId: $publicKennelId, kennelName: $kennelName, kennelShortName: $kennelShortName, kennelUniqueShortName: $kennelUniqueShortName, kennelLogo: $kennelLogo, kennelCountryCodes: $kennelCountryCodes, countryId: $countryId, countryName: $countryName, isFollowing: $isFollowing, isMember: $isMember, isHomeKennel: $isHomeKennel, appAccessFlags: $appAccessFlags, defaultTags1: $defaultTags1, defaultTags2: $defaultTags2, defaultTags3: $defaultTags3, defaultDigitsAfterDecimal: $defaultDigitsAfterDecimal, defaultCurrencySymbol: $defaultCurrencySymbol, defaultRunStartTime: $defaultRunStartTime, cityLat: $cityLat, cityLon: $cityLon, defaultEventPriceForMembers: $defaultEventPriceForMembers, defaultEventPriceForNonMembers: $defaultEventPriceForNonMembers, cityName: $cityName, regionName: $regionName, continentName: $continentName, membershipExpirationDate: $membershipExpirationDate, kennelLat: $kennelLat, kennelLon: $kennelLon)';
  }
}

/// @nodoc
abstract mixin class _$HasherKennelsModelCopyWith<$Res>
    implements $HasherKennelsModelCopyWith<$Res> {
  factory _$HasherKennelsModelCopyWith(
          _HasherKennelsModel value, $Res Function(_HasherKennelsModel) _then) =
      __$HasherKennelsModelCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String publicKennelId,
      String kennelName,
      String kennelShortName,
      String kennelUniqueShortName,
      String kennelLogo,
      String kennelCountryCodes,
      String countryId,
      String countryName,
      int isFollowing,
      int isMember,
      int isHomeKennel,
      int appAccessFlags,
      int defaultTags1,
      int defaultTags2,
      int defaultTags3,
      int defaultDigitsAfterDecimal,
      String defaultCurrencySymbol,
      DateTime defaultRunStartTime,
      double cityLat,
      double cityLon,
      double defaultEventPriceForMembers,
      double defaultEventPriceForNonMembers,
      String? cityName,
      String? regionName,
      String? continentName,
      DateTime? membershipExpirationDate,
      double? kennelLat,
      double? kennelLon});
}

/// @nodoc
class __$HasherKennelsModelCopyWithImpl<$Res>
    implements _$HasherKennelsModelCopyWith<$Res> {
  __$HasherKennelsModelCopyWithImpl(this._self, this._then);

  final _HasherKennelsModel _self;
  final $Res Function(_HasherKennelsModel) _then;

  /// Create a copy of HasherKennelsModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? publicKennelId = null,
    Object? kennelName = null,
    Object? kennelShortName = null,
    Object? kennelUniqueShortName = null,
    Object? kennelLogo = null,
    Object? kennelCountryCodes = null,
    Object? countryId = null,
    Object? countryName = null,
    Object? isFollowing = null,
    Object? isMember = null,
    Object? isHomeKennel = null,
    Object? appAccessFlags = null,
    Object? defaultTags1 = null,
    Object? defaultTags2 = null,
    Object? defaultTags3 = null,
    Object? defaultDigitsAfterDecimal = null,
    Object? defaultCurrencySymbol = null,
    Object? defaultRunStartTime = null,
    Object? cityLat = null,
    Object? cityLon = null,
    Object? defaultEventPriceForMembers = null,
    Object? defaultEventPriceForNonMembers = null,
    Object? cityName = freezed,
    Object? regionName = freezed,
    Object? continentName = freezed,
    Object? membershipExpirationDate = freezed,
    Object? kennelLat = freezed,
    Object? kennelLon = freezed,
  }) {
    return _then(_HasherKennelsModel(
      publicKennelId: null == publicKennelId
          ? _self.publicKennelId
          : publicKennelId // ignore: cast_nullable_to_non_nullable
              as String,
      kennelName: null == kennelName
          ? _self.kennelName
          : kennelName // ignore: cast_nullable_to_non_nullable
              as String,
      kennelShortName: null == kennelShortName
          ? _self.kennelShortName
          : kennelShortName // ignore: cast_nullable_to_non_nullable
              as String,
      kennelUniqueShortName: null == kennelUniqueShortName
          ? _self.kennelUniqueShortName
          : kennelUniqueShortName // ignore: cast_nullable_to_non_nullable
              as String,
      kennelLogo: null == kennelLogo
          ? _self.kennelLogo
          : kennelLogo // ignore: cast_nullable_to_non_nullable
              as String,
      kennelCountryCodes: null == kennelCountryCodes
          ? _self.kennelCountryCodes
          : kennelCountryCodes // ignore: cast_nullable_to_non_nullable
              as String,
      countryId: null == countryId
          ? _self.countryId
          : countryId // ignore: cast_nullable_to_non_nullable
              as String,
      countryName: null == countryName
          ? _self.countryName
          : countryName // ignore: cast_nullable_to_non_nullable
              as String,
      isFollowing: null == isFollowing
          ? _self.isFollowing
          : isFollowing // ignore: cast_nullable_to_non_nullable
              as int,
      isMember: null == isMember
          ? _self.isMember
          : isMember // ignore: cast_nullable_to_non_nullable
              as int,
      isHomeKennel: null == isHomeKennel
          ? _self.isHomeKennel
          : isHomeKennel // ignore: cast_nullable_to_non_nullable
              as int,
      appAccessFlags: null == appAccessFlags
          ? _self.appAccessFlags
          : appAccessFlags // ignore: cast_nullable_to_non_nullable
              as int,
      defaultTags1: null == defaultTags1
          ? _self.defaultTags1
          : defaultTags1 // ignore: cast_nullable_to_non_nullable
              as int,
      defaultTags2: null == defaultTags2
          ? _self.defaultTags2
          : defaultTags2 // ignore: cast_nullable_to_non_nullable
              as int,
      defaultTags3: null == defaultTags3
          ? _self.defaultTags3
          : defaultTags3 // ignore: cast_nullable_to_non_nullable
              as int,
      defaultDigitsAfterDecimal: null == defaultDigitsAfterDecimal
          ? _self.defaultDigitsAfterDecimal
          : defaultDigitsAfterDecimal // ignore: cast_nullable_to_non_nullable
              as int,
      defaultCurrencySymbol: null == defaultCurrencySymbol
          ? _self.defaultCurrencySymbol
          : defaultCurrencySymbol // ignore: cast_nullable_to_non_nullable
              as String,
      defaultRunStartTime: null == defaultRunStartTime
          ? _self.defaultRunStartTime
          : defaultRunStartTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      cityLat: null == cityLat
          ? _self.cityLat
          : cityLat // ignore: cast_nullable_to_non_nullable
              as double,
      cityLon: null == cityLon
          ? _self.cityLon
          : cityLon // ignore: cast_nullable_to_non_nullable
              as double,
      defaultEventPriceForMembers: null == defaultEventPriceForMembers
          ? _self.defaultEventPriceForMembers
          : defaultEventPriceForMembers // ignore: cast_nullable_to_non_nullable
              as double,
      defaultEventPriceForNonMembers: null == defaultEventPriceForNonMembers
          ? _self.defaultEventPriceForNonMembers
          : defaultEventPriceForNonMembers // ignore: cast_nullable_to_non_nullable
              as double,
      cityName: freezed == cityName
          ? _self.cityName
          : cityName // ignore: cast_nullable_to_non_nullable
              as String?,
      regionName: freezed == regionName
          ? _self.regionName
          : regionName // ignore: cast_nullable_to_non_nullable
              as String?,
      continentName: freezed == continentName
          ? _self.continentName
          : continentName // ignore: cast_nullable_to_non_nullable
              as String?,
      membershipExpirationDate: freezed == membershipExpirationDate
          ? _self.membershipExpirationDate
          : membershipExpirationDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      kennelLat: freezed == kennelLat
          ? _self.kennelLat
          : kennelLat // ignore: cast_nullable_to_non_nullable
              as double?,
      kennelLon: freezed == kennelLon
          ? _self.kennelLon
          : kennelLon // ignore: cast_nullable_to_non_nullable
              as double?,
    ));
  }
}

// dart format on
