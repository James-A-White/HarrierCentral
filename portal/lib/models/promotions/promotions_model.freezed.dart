// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'promotions_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PromotionsModel implements DiagnosticableTreeMixin {
  String get promotionId;
  String get promoName;
  DateTime get promoStartDate;
  int get promoDisplayButtons;
  String get promoImage;
  String get promoImageExtension;
  String get promoOverlayTiming;
  int get promoPriority;
  int get promoGeographicScope;
  int get promoImageIsDark;
  int get promoDisplayTimeInMs;
  int get promoDisplayTimingDotsToDisplay;
  String get promoDisplayTimingDotsShape;
  int get promoDisplayTimingDotsSize;
  String get promoType;
  int get promoIsDraft;
  String? get promoGroupId;
  String? get kennelId;
  String? get cityId;
  String? get eventId;
  String? get userId;
  DateTime? get promoEndDate;
  String? get promoImageWide;
  String? get promoImageTall;
  String? get promoExternalUrl;
  String? get promoExternalUrlButtonText;
  double? get promoLat;
  double? get promoLon;
  int? get promoRadius;

  /// Create a copy of PromotionsModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PromotionsModelCopyWith<PromotionsModel> get copyWith =>
      _$PromotionsModelCopyWithImpl<PromotionsModel>(
          this as PromotionsModel, _$identity);

  /// Serializes this PromotionsModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'PromotionsModel'))
      ..add(DiagnosticsProperty('promotionId', promotionId))
      ..add(DiagnosticsProperty('promoName', promoName))
      ..add(DiagnosticsProperty('promoStartDate', promoStartDate))
      ..add(DiagnosticsProperty('promoDisplayButtons', promoDisplayButtons))
      ..add(DiagnosticsProperty('promoImage', promoImage))
      ..add(DiagnosticsProperty('promoImageExtension', promoImageExtension))
      ..add(DiagnosticsProperty('promoOverlayTiming', promoOverlayTiming))
      ..add(DiagnosticsProperty('promoPriority', promoPriority))
      ..add(DiagnosticsProperty('promoGeographicScope', promoGeographicScope))
      ..add(DiagnosticsProperty('promoImageIsDark', promoImageIsDark))
      ..add(DiagnosticsProperty('promoDisplayTimeInMs', promoDisplayTimeInMs))
      ..add(DiagnosticsProperty(
          'promoDisplayTimingDotsToDisplay', promoDisplayTimingDotsToDisplay))
      ..add(DiagnosticsProperty(
          'promoDisplayTimingDotsShape', promoDisplayTimingDotsShape))
      ..add(DiagnosticsProperty(
          'promoDisplayTimingDotsSize', promoDisplayTimingDotsSize))
      ..add(DiagnosticsProperty('promoType', promoType))
      ..add(DiagnosticsProperty('promoIsDraft', promoIsDraft))
      ..add(DiagnosticsProperty('promoGroupId', promoGroupId))
      ..add(DiagnosticsProperty('kennelId', kennelId))
      ..add(DiagnosticsProperty('cityId', cityId))
      ..add(DiagnosticsProperty('eventId', eventId))
      ..add(DiagnosticsProperty('userId', userId))
      ..add(DiagnosticsProperty('promoEndDate', promoEndDate))
      ..add(DiagnosticsProperty('promoImageWide', promoImageWide))
      ..add(DiagnosticsProperty('promoImageTall', promoImageTall))
      ..add(DiagnosticsProperty('promoExternalUrl', promoExternalUrl))
      ..add(DiagnosticsProperty(
          'promoExternalUrlButtonText', promoExternalUrlButtonText))
      ..add(DiagnosticsProperty('promoLat', promoLat))
      ..add(DiagnosticsProperty('promoLon', promoLon))
      ..add(DiagnosticsProperty('promoRadius', promoRadius));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PromotionsModel &&
            (identical(other.promotionId, promotionId) ||
                other.promotionId == promotionId) &&
            (identical(other.promoName, promoName) ||
                other.promoName == promoName) &&
            (identical(other.promoStartDate, promoStartDate) ||
                other.promoStartDate == promoStartDate) &&
            (identical(other.promoDisplayButtons, promoDisplayButtons) ||
                other.promoDisplayButtons == promoDisplayButtons) &&
            (identical(other.promoImage, promoImage) ||
                other.promoImage == promoImage) &&
            (identical(other.promoImageExtension, promoImageExtension) ||
                other.promoImageExtension == promoImageExtension) &&
            (identical(other.promoOverlayTiming, promoOverlayTiming) ||
                other.promoOverlayTiming == promoOverlayTiming) &&
            (identical(other.promoPriority, promoPriority) ||
                other.promoPriority == promoPriority) &&
            (identical(other.promoGeographicScope, promoGeographicScope) ||
                other.promoGeographicScope == promoGeographicScope) &&
            (identical(other.promoImageIsDark, promoImageIsDark) ||
                other.promoImageIsDark == promoImageIsDark) &&
            (identical(other.promoDisplayTimeInMs, promoDisplayTimeInMs) ||
                other.promoDisplayTimeInMs == promoDisplayTimeInMs) &&
            (identical(other.promoDisplayTimingDotsToDisplay,
                    promoDisplayTimingDotsToDisplay) ||
                other.promoDisplayTimingDotsToDisplay ==
                    promoDisplayTimingDotsToDisplay) &&
            (identical(other.promoDisplayTimingDotsShape,
                    promoDisplayTimingDotsShape) ||
                other.promoDisplayTimingDotsShape ==
                    promoDisplayTimingDotsShape) &&
            (identical(other.promoDisplayTimingDotsSize, promoDisplayTimingDotsSize) ||
                other.promoDisplayTimingDotsSize ==
                    promoDisplayTimingDotsSize) &&
            (identical(other.promoType, promoType) ||
                other.promoType == promoType) &&
            (identical(other.promoIsDraft, promoIsDraft) ||
                other.promoIsDraft == promoIsDraft) &&
            (identical(other.promoGroupId, promoGroupId) ||
                other.promoGroupId == promoGroupId) &&
            (identical(other.kennelId, kennelId) ||
                other.kennelId == kennelId) &&
            (identical(other.cityId, cityId) || other.cityId == cityId) &&
            (identical(other.eventId, eventId) || other.eventId == eventId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.promoEndDate, promoEndDate) ||
                other.promoEndDate == promoEndDate) &&
            (identical(other.promoImageWide, promoImageWide) ||
                other.promoImageWide == promoImageWide) &&
            (identical(other.promoImageTall, promoImageTall) ||
                other.promoImageTall == promoImageTall) &&
            (identical(other.promoExternalUrl, promoExternalUrl) ||
                other.promoExternalUrl == promoExternalUrl) &&
            (identical(other.promoExternalUrlButtonText, promoExternalUrlButtonText) ||
                other.promoExternalUrlButtonText ==
                    promoExternalUrlButtonText) &&
            (identical(other.promoLat, promoLat) || other.promoLat == promoLat) &&
            (identical(other.promoLon, promoLon) || other.promoLon == promoLon) &&
            (identical(other.promoRadius, promoRadius) || other.promoRadius == promoRadius));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        promotionId,
        promoName,
        promoStartDate,
        promoDisplayButtons,
        promoImage,
        promoImageExtension,
        promoOverlayTiming,
        promoPriority,
        promoGeographicScope,
        promoImageIsDark,
        promoDisplayTimeInMs,
        promoDisplayTimingDotsToDisplay,
        promoDisplayTimingDotsShape,
        promoDisplayTimingDotsSize,
        promoType,
        promoIsDraft,
        promoGroupId,
        kennelId,
        cityId,
        eventId,
        userId,
        promoEndDate,
        promoImageWide,
        promoImageTall,
        promoExternalUrl,
        promoExternalUrlButtonText,
        promoLat,
        promoLon,
        promoRadius
      ]);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'PromotionsModel(promotionId: $promotionId, promoName: $promoName, promoStartDate: $promoStartDate, promoDisplayButtons: $promoDisplayButtons, promoImage: $promoImage, promoImageExtension: $promoImageExtension, promoOverlayTiming: $promoOverlayTiming, promoPriority: $promoPriority, promoGeographicScope: $promoGeographicScope, promoImageIsDark: $promoImageIsDark, promoDisplayTimeInMs: $promoDisplayTimeInMs, promoDisplayTimingDotsToDisplay: $promoDisplayTimingDotsToDisplay, promoDisplayTimingDotsShape: $promoDisplayTimingDotsShape, promoDisplayTimingDotsSize: $promoDisplayTimingDotsSize, promoType: $promoType, promoIsDraft: $promoIsDraft, promoGroupId: $promoGroupId, kennelId: $kennelId, cityId: $cityId, eventId: $eventId, userId: $userId, promoEndDate: $promoEndDate, promoImageWide: $promoImageWide, promoImageTall: $promoImageTall, promoExternalUrl: $promoExternalUrl, promoExternalUrlButtonText: $promoExternalUrlButtonText, promoLat: $promoLat, promoLon: $promoLon, promoRadius: $promoRadius)';
  }
}

/// @nodoc
abstract mixin class $PromotionsModelCopyWith<$Res> {
  factory $PromotionsModelCopyWith(
          PromotionsModel value, $Res Function(PromotionsModel) _then) =
      _$PromotionsModelCopyWithImpl;
  @useResult
  $Res call(
      {String promotionId,
      String promoName,
      DateTime promoStartDate,
      int promoDisplayButtons,
      String promoImage,
      String promoImageExtension,
      String promoOverlayTiming,
      int promoPriority,
      int promoGeographicScope,
      int promoImageIsDark,
      int promoDisplayTimeInMs,
      int promoDisplayTimingDotsToDisplay,
      String promoDisplayTimingDotsShape,
      int promoDisplayTimingDotsSize,
      String promoType,
      int promoIsDraft,
      String? promoGroupId,
      String? kennelId,
      String? cityId,
      String? eventId,
      String? userId,
      DateTime? promoEndDate,
      String? promoImageWide,
      String? promoImageTall,
      String? promoExternalUrl,
      String? promoExternalUrlButtonText,
      double? promoLat,
      double? promoLon,
      int? promoRadius});
}

/// @nodoc
class _$PromotionsModelCopyWithImpl<$Res>
    implements $PromotionsModelCopyWith<$Res> {
  _$PromotionsModelCopyWithImpl(this._self, this._then);

  final PromotionsModel _self;
  final $Res Function(PromotionsModel) _then;

  /// Create a copy of PromotionsModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? promotionId = null,
    Object? promoName = null,
    Object? promoStartDate = null,
    Object? promoDisplayButtons = null,
    Object? promoImage = null,
    Object? promoImageExtension = null,
    Object? promoOverlayTiming = null,
    Object? promoPriority = null,
    Object? promoGeographicScope = null,
    Object? promoImageIsDark = null,
    Object? promoDisplayTimeInMs = null,
    Object? promoDisplayTimingDotsToDisplay = null,
    Object? promoDisplayTimingDotsShape = null,
    Object? promoDisplayTimingDotsSize = null,
    Object? promoType = null,
    Object? promoIsDraft = null,
    Object? promoGroupId = freezed,
    Object? kennelId = freezed,
    Object? cityId = freezed,
    Object? eventId = freezed,
    Object? userId = freezed,
    Object? promoEndDate = freezed,
    Object? promoImageWide = freezed,
    Object? promoImageTall = freezed,
    Object? promoExternalUrl = freezed,
    Object? promoExternalUrlButtonText = freezed,
    Object? promoLat = freezed,
    Object? promoLon = freezed,
    Object? promoRadius = freezed,
  }) {
    return _then(_self.copyWith(
      promotionId: null == promotionId
          ? _self.promotionId
          : promotionId // ignore: cast_nullable_to_non_nullable
              as String,
      promoName: null == promoName
          ? _self.promoName
          : promoName // ignore: cast_nullable_to_non_nullable
              as String,
      promoStartDate: null == promoStartDate
          ? _self.promoStartDate
          : promoStartDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      promoDisplayButtons: null == promoDisplayButtons
          ? _self.promoDisplayButtons
          : promoDisplayButtons // ignore: cast_nullable_to_non_nullable
              as int,
      promoImage: null == promoImage
          ? _self.promoImage
          : promoImage // ignore: cast_nullable_to_non_nullable
              as String,
      promoImageExtension: null == promoImageExtension
          ? _self.promoImageExtension
          : promoImageExtension // ignore: cast_nullable_to_non_nullable
              as String,
      promoOverlayTiming: null == promoOverlayTiming
          ? _self.promoOverlayTiming
          : promoOverlayTiming // ignore: cast_nullable_to_non_nullable
              as String,
      promoPriority: null == promoPriority
          ? _self.promoPriority
          : promoPriority // ignore: cast_nullable_to_non_nullable
              as int,
      promoGeographicScope: null == promoGeographicScope
          ? _self.promoGeographicScope
          : promoGeographicScope // ignore: cast_nullable_to_non_nullable
              as int,
      promoImageIsDark: null == promoImageIsDark
          ? _self.promoImageIsDark
          : promoImageIsDark // ignore: cast_nullable_to_non_nullable
              as int,
      promoDisplayTimeInMs: null == promoDisplayTimeInMs
          ? _self.promoDisplayTimeInMs
          : promoDisplayTimeInMs // ignore: cast_nullable_to_non_nullable
              as int,
      promoDisplayTimingDotsToDisplay: null == promoDisplayTimingDotsToDisplay
          ? _self.promoDisplayTimingDotsToDisplay
          : promoDisplayTimingDotsToDisplay // ignore: cast_nullable_to_non_nullable
              as int,
      promoDisplayTimingDotsShape: null == promoDisplayTimingDotsShape
          ? _self.promoDisplayTimingDotsShape
          : promoDisplayTimingDotsShape // ignore: cast_nullable_to_non_nullable
              as String,
      promoDisplayTimingDotsSize: null == promoDisplayTimingDotsSize
          ? _self.promoDisplayTimingDotsSize
          : promoDisplayTimingDotsSize // ignore: cast_nullable_to_non_nullable
              as int,
      promoType: null == promoType
          ? _self.promoType
          : promoType // ignore: cast_nullable_to_non_nullable
              as String,
      promoIsDraft: null == promoIsDraft
          ? _self.promoIsDraft
          : promoIsDraft // ignore: cast_nullable_to_non_nullable
              as int,
      promoGroupId: freezed == promoGroupId
          ? _self.promoGroupId
          : promoGroupId // ignore: cast_nullable_to_non_nullable
              as String?,
      kennelId: freezed == kennelId
          ? _self.kennelId
          : kennelId // ignore: cast_nullable_to_non_nullable
              as String?,
      cityId: freezed == cityId
          ? _self.cityId
          : cityId // ignore: cast_nullable_to_non_nullable
              as String?,
      eventId: freezed == eventId
          ? _self.eventId
          : eventId // ignore: cast_nullable_to_non_nullable
              as String?,
      userId: freezed == userId
          ? _self.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String?,
      promoEndDate: freezed == promoEndDate
          ? _self.promoEndDate
          : promoEndDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      promoImageWide: freezed == promoImageWide
          ? _self.promoImageWide
          : promoImageWide // ignore: cast_nullable_to_non_nullable
              as String?,
      promoImageTall: freezed == promoImageTall
          ? _self.promoImageTall
          : promoImageTall // ignore: cast_nullable_to_non_nullable
              as String?,
      promoExternalUrl: freezed == promoExternalUrl
          ? _self.promoExternalUrl
          : promoExternalUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      promoExternalUrlButtonText: freezed == promoExternalUrlButtonText
          ? _self.promoExternalUrlButtonText
          : promoExternalUrlButtonText // ignore: cast_nullable_to_non_nullable
              as String?,
      promoLat: freezed == promoLat
          ? _self.promoLat
          : promoLat // ignore: cast_nullable_to_non_nullable
              as double?,
      promoLon: freezed == promoLon
          ? _self.promoLon
          : promoLon // ignore: cast_nullable_to_non_nullable
              as double?,
      promoRadius: freezed == promoRadius
          ? _self.promoRadius
          : promoRadius // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// Adds pattern-matching-related methods to [PromotionsModel].
extension PromotionsModelPatterns on PromotionsModel {
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
    TResult Function(_PromotionsModel value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PromotionsModel() when $default != null:
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
    TResult Function(_PromotionsModel value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PromotionsModel():
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
    TResult? Function(_PromotionsModel value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PromotionsModel() when $default != null:
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
            String promotionId,
            String promoName,
            DateTime promoStartDate,
            int promoDisplayButtons,
            String promoImage,
            String promoImageExtension,
            String promoOverlayTiming,
            int promoPriority,
            int promoGeographicScope,
            int promoImageIsDark,
            int promoDisplayTimeInMs,
            int promoDisplayTimingDotsToDisplay,
            String promoDisplayTimingDotsShape,
            int promoDisplayTimingDotsSize,
            String promoType,
            int promoIsDraft,
            String? promoGroupId,
            String? kennelId,
            String? cityId,
            String? eventId,
            String? userId,
            DateTime? promoEndDate,
            String? promoImageWide,
            String? promoImageTall,
            String? promoExternalUrl,
            String? promoExternalUrlButtonText,
            double? promoLat,
            double? promoLon,
            int? promoRadius)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PromotionsModel() when $default != null:
        return $default(
            _that.promotionId,
            _that.promoName,
            _that.promoStartDate,
            _that.promoDisplayButtons,
            _that.promoImage,
            _that.promoImageExtension,
            _that.promoOverlayTiming,
            _that.promoPriority,
            _that.promoGeographicScope,
            _that.promoImageIsDark,
            _that.promoDisplayTimeInMs,
            _that.promoDisplayTimingDotsToDisplay,
            _that.promoDisplayTimingDotsShape,
            _that.promoDisplayTimingDotsSize,
            _that.promoType,
            _that.promoIsDraft,
            _that.promoGroupId,
            _that.kennelId,
            _that.cityId,
            _that.eventId,
            _that.userId,
            _that.promoEndDate,
            _that.promoImageWide,
            _that.promoImageTall,
            _that.promoExternalUrl,
            _that.promoExternalUrlButtonText,
            _that.promoLat,
            _that.promoLon,
            _that.promoRadius);
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
            String promotionId,
            String promoName,
            DateTime promoStartDate,
            int promoDisplayButtons,
            String promoImage,
            String promoImageExtension,
            String promoOverlayTiming,
            int promoPriority,
            int promoGeographicScope,
            int promoImageIsDark,
            int promoDisplayTimeInMs,
            int promoDisplayTimingDotsToDisplay,
            String promoDisplayTimingDotsShape,
            int promoDisplayTimingDotsSize,
            String promoType,
            int promoIsDraft,
            String? promoGroupId,
            String? kennelId,
            String? cityId,
            String? eventId,
            String? userId,
            DateTime? promoEndDate,
            String? promoImageWide,
            String? promoImageTall,
            String? promoExternalUrl,
            String? promoExternalUrlButtonText,
            double? promoLat,
            double? promoLon,
            int? promoRadius)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PromotionsModel():
        return $default(
            _that.promotionId,
            _that.promoName,
            _that.promoStartDate,
            _that.promoDisplayButtons,
            _that.promoImage,
            _that.promoImageExtension,
            _that.promoOverlayTiming,
            _that.promoPriority,
            _that.promoGeographicScope,
            _that.promoImageIsDark,
            _that.promoDisplayTimeInMs,
            _that.promoDisplayTimingDotsToDisplay,
            _that.promoDisplayTimingDotsShape,
            _that.promoDisplayTimingDotsSize,
            _that.promoType,
            _that.promoIsDraft,
            _that.promoGroupId,
            _that.kennelId,
            _that.cityId,
            _that.eventId,
            _that.userId,
            _that.promoEndDate,
            _that.promoImageWide,
            _that.promoImageTall,
            _that.promoExternalUrl,
            _that.promoExternalUrlButtonText,
            _that.promoLat,
            _that.promoLon,
            _that.promoRadius);
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
            String promotionId,
            String promoName,
            DateTime promoStartDate,
            int promoDisplayButtons,
            String promoImage,
            String promoImageExtension,
            String promoOverlayTiming,
            int promoPriority,
            int promoGeographicScope,
            int promoImageIsDark,
            int promoDisplayTimeInMs,
            int promoDisplayTimingDotsToDisplay,
            String promoDisplayTimingDotsShape,
            int promoDisplayTimingDotsSize,
            String promoType,
            int promoIsDraft,
            String? promoGroupId,
            String? kennelId,
            String? cityId,
            String? eventId,
            String? userId,
            DateTime? promoEndDate,
            String? promoImageWide,
            String? promoImageTall,
            String? promoExternalUrl,
            String? promoExternalUrlButtonText,
            double? promoLat,
            double? promoLon,
            int? promoRadius)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PromotionsModel() when $default != null:
        return $default(
            _that.promotionId,
            _that.promoName,
            _that.promoStartDate,
            _that.promoDisplayButtons,
            _that.promoImage,
            _that.promoImageExtension,
            _that.promoOverlayTiming,
            _that.promoPriority,
            _that.promoGeographicScope,
            _that.promoImageIsDark,
            _that.promoDisplayTimeInMs,
            _that.promoDisplayTimingDotsToDisplay,
            _that.promoDisplayTimingDotsShape,
            _that.promoDisplayTimingDotsSize,
            _that.promoType,
            _that.promoIsDraft,
            _that.promoGroupId,
            _that.kennelId,
            _that.cityId,
            _that.eventId,
            _that.userId,
            _that.promoEndDate,
            _that.promoImageWide,
            _that.promoImageTall,
            _that.promoExternalUrl,
            _that.promoExternalUrlButtonText,
            _that.promoLat,
            _that.promoLon,
            _that.promoRadius);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _PromotionsModel with DiagnosticableTreeMixin implements PromotionsModel {
  _PromotionsModel(
      {required this.promotionId,
      required this.promoName,
      required this.promoStartDate,
      required this.promoDisplayButtons,
      required this.promoImage,
      required this.promoImageExtension,
      required this.promoOverlayTiming,
      required this.promoPriority,
      required this.promoGeographicScope,
      required this.promoImageIsDark,
      required this.promoDisplayTimeInMs,
      required this.promoDisplayTimingDotsToDisplay,
      required this.promoDisplayTimingDotsShape,
      required this.promoDisplayTimingDotsSize,
      required this.promoType,
      required this.promoIsDraft,
      this.promoGroupId,
      this.kennelId,
      this.cityId,
      this.eventId,
      this.userId,
      this.promoEndDate,
      this.promoImageWide,
      this.promoImageTall,
      this.promoExternalUrl,
      this.promoExternalUrlButtonText,
      this.promoLat,
      this.promoLon,
      this.promoRadius});
  factory _PromotionsModel.fromJson(Map<String, dynamic> json) =>
      _$PromotionsModelFromJson(json);

  @override
  final String promotionId;
  @override
  final String promoName;
  @override
  final DateTime promoStartDate;
  @override
  final int promoDisplayButtons;
  @override
  final String promoImage;
  @override
  final String promoImageExtension;
  @override
  final String promoOverlayTiming;
  @override
  final int promoPriority;
  @override
  final int promoGeographicScope;
  @override
  final int promoImageIsDark;
  @override
  final int promoDisplayTimeInMs;
  @override
  final int promoDisplayTimingDotsToDisplay;
  @override
  final String promoDisplayTimingDotsShape;
  @override
  final int promoDisplayTimingDotsSize;
  @override
  final String promoType;
  @override
  final int promoIsDraft;
  @override
  final String? promoGroupId;
  @override
  final String? kennelId;
  @override
  final String? cityId;
  @override
  final String? eventId;
  @override
  final String? userId;
  @override
  final DateTime? promoEndDate;
  @override
  final String? promoImageWide;
  @override
  final String? promoImageTall;
  @override
  final String? promoExternalUrl;
  @override
  final String? promoExternalUrlButtonText;
  @override
  final double? promoLat;
  @override
  final double? promoLon;
  @override
  final int? promoRadius;

  /// Create a copy of PromotionsModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PromotionsModelCopyWith<_PromotionsModel> get copyWith =>
      __$PromotionsModelCopyWithImpl<_PromotionsModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$PromotionsModelToJson(
      this,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'PromotionsModel'))
      ..add(DiagnosticsProperty('promotionId', promotionId))
      ..add(DiagnosticsProperty('promoName', promoName))
      ..add(DiagnosticsProperty('promoStartDate', promoStartDate))
      ..add(DiagnosticsProperty('promoDisplayButtons', promoDisplayButtons))
      ..add(DiagnosticsProperty('promoImage', promoImage))
      ..add(DiagnosticsProperty('promoImageExtension', promoImageExtension))
      ..add(DiagnosticsProperty('promoOverlayTiming', promoOverlayTiming))
      ..add(DiagnosticsProperty('promoPriority', promoPriority))
      ..add(DiagnosticsProperty('promoGeographicScope', promoGeographicScope))
      ..add(DiagnosticsProperty('promoImageIsDark', promoImageIsDark))
      ..add(DiagnosticsProperty('promoDisplayTimeInMs', promoDisplayTimeInMs))
      ..add(DiagnosticsProperty(
          'promoDisplayTimingDotsToDisplay', promoDisplayTimingDotsToDisplay))
      ..add(DiagnosticsProperty(
          'promoDisplayTimingDotsShape', promoDisplayTimingDotsShape))
      ..add(DiagnosticsProperty(
          'promoDisplayTimingDotsSize', promoDisplayTimingDotsSize))
      ..add(DiagnosticsProperty('promoType', promoType))
      ..add(DiagnosticsProperty('promoIsDraft', promoIsDraft))
      ..add(DiagnosticsProperty('promoGroupId', promoGroupId))
      ..add(DiagnosticsProperty('kennelId', kennelId))
      ..add(DiagnosticsProperty('cityId', cityId))
      ..add(DiagnosticsProperty('eventId', eventId))
      ..add(DiagnosticsProperty('userId', userId))
      ..add(DiagnosticsProperty('promoEndDate', promoEndDate))
      ..add(DiagnosticsProperty('promoImageWide', promoImageWide))
      ..add(DiagnosticsProperty('promoImageTall', promoImageTall))
      ..add(DiagnosticsProperty('promoExternalUrl', promoExternalUrl))
      ..add(DiagnosticsProperty(
          'promoExternalUrlButtonText', promoExternalUrlButtonText))
      ..add(DiagnosticsProperty('promoLat', promoLat))
      ..add(DiagnosticsProperty('promoLon', promoLon))
      ..add(DiagnosticsProperty('promoRadius', promoRadius));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PromotionsModel &&
            (identical(other.promotionId, promotionId) ||
                other.promotionId == promotionId) &&
            (identical(other.promoName, promoName) ||
                other.promoName == promoName) &&
            (identical(other.promoStartDate, promoStartDate) ||
                other.promoStartDate == promoStartDate) &&
            (identical(other.promoDisplayButtons, promoDisplayButtons) ||
                other.promoDisplayButtons == promoDisplayButtons) &&
            (identical(other.promoImage, promoImage) ||
                other.promoImage == promoImage) &&
            (identical(other.promoImageExtension, promoImageExtension) ||
                other.promoImageExtension == promoImageExtension) &&
            (identical(other.promoOverlayTiming, promoOverlayTiming) ||
                other.promoOverlayTiming == promoOverlayTiming) &&
            (identical(other.promoPriority, promoPriority) ||
                other.promoPriority == promoPriority) &&
            (identical(other.promoGeographicScope, promoGeographicScope) ||
                other.promoGeographicScope == promoGeographicScope) &&
            (identical(other.promoImageIsDark, promoImageIsDark) ||
                other.promoImageIsDark == promoImageIsDark) &&
            (identical(other.promoDisplayTimeInMs, promoDisplayTimeInMs) ||
                other.promoDisplayTimeInMs == promoDisplayTimeInMs) &&
            (identical(other.promoDisplayTimingDotsToDisplay,
                    promoDisplayTimingDotsToDisplay) ||
                other.promoDisplayTimingDotsToDisplay ==
                    promoDisplayTimingDotsToDisplay) &&
            (identical(other.promoDisplayTimingDotsShape,
                    promoDisplayTimingDotsShape) ||
                other.promoDisplayTimingDotsShape ==
                    promoDisplayTimingDotsShape) &&
            (identical(other.promoDisplayTimingDotsSize, promoDisplayTimingDotsSize) ||
                other.promoDisplayTimingDotsSize ==
                    promoDisplayTimingDotsSize) &&
            (identical(other.promoType, promoType) ||
                other.promoType == promoType) &&
            (identical(other.promoIsDraft, promoIsDraft) ||
                other.promoIsDraft == promoIsDraft) &&
            (identical(other.promoGroupId, promoGroupId) ||
                other.promoGroupId == promoGroupId) &&
            (identical(other.kennelId, kennelId) ||
                other.kennelId == kennelId) &&
            (identical(other.cityId, cityId) || other.cityId == cityId) &&
            (identical(other.eventId, eventId) || other.eventId == eventId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.promoEndDate, promoEndDate) ||
                other.promoEndDate == promoEndDate) &&
            (identical(other.promoImageWide, promoImageWide) ||
                other.promoImageWide == promoImageWide) &&
            (identical(other.promoImageTall, promoImageTall) ||
                other.promoImageTall == promoImageTall) &&
            (identical(other.promoExternalUrl, promoExternalUrl) ||
                other.promoExternalUrl == promoExternalUrl) &&
            (identical(other.promoExternalUrlButtonText, promoExternalUrlButtonText) ||
                other.promoExternalUrlButtonText ==
                    promoExternalUrlButtonText) &&
            (identical(other.promoLat, promoLat) || other.promoLat == promoLat) &&
            (identical(other.promoLon, promoLon) || other.promoLon == promoLon) &&
            (identical(other.promoRadius, promoRadius) || other.promoRadius == promoRadius));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        promotionId,
        promoName,
        promoStartDate,
        promoDisplayButtons,
        promoImage,
        promoImageExtension,
        promoOverlayTiming,
        promoPriority,
        promoGeographicScope,
        promoImageIsDark,
        promoDisplayTimeInMs,
        promoDisplayTimingDotsToDisplay,
        promoDisplayTimingDotsShape,
        promoDisplayTimingDotsSize,
        promoType,
        promoIsDraft,
        promoGroupId,
        kennelId,
        cityId,
        eventId,
        userId,
        promoEndDate,
        promoImageWide,
        promoImageTall,
        promoExternalUrl,
        promoExternalUrlButtonText,
        promoLat,
        promoLon,
        promoRadius
      ]);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'PromotionsModel(promotionId: $promotionId, promoName: $promoName, promoStartDate: $promoStartDate, promoDisplayButtons: $promoDisplayButtons, promoImage: $promoImage, promoImageExtension: $promoImageExtension, promoOverlayTiming: $promoOverlayTiming, promoPriority: $promoPriority, promoGeographicScope: $promoGeographicScope, promoImageIsDark: $promoImageIsDark, promoDisplayTimeInMs: $promoDisplayTimeInMs, promoDisplayTimingDotsToDisplay: $promoDisplayTimingDotsToDisplay, promoDisplayTimingDotsShape: $promoDisplayTimingDotsShape, promoDisplayTimingDotsSize: $promoDisplayTimingDotsSize, promoType: $promoType, promoIsDraft: $promoIsDraft, promoGroupId: $promoGroupId, kennelId: $kennelId, cityId: $cityId, eventId: $eventId, userId: $userId, promoEndDate: $promoEndDate, promoImageWide: $promoImageWide, promoImageTall: $promoImageTall, promoExternalUrl: $promoExternalUrl, promoExternalUrlButtonText: $promoExternalUrlButtonText, promoLat: $promoLat, promoLon: $promoLon, promoRadius: $promoRadius)';
  }
}

/// @nodoc
abstract mixin class _$PromotionsModelCopyWith<$Res>
    implements $PromotionsModelCopyWith<$Res> {
  factory _$PromotionsModelCopyWith(
          _PromotionsModel value, $Res Function(_PromotionsModel) _then) =
      __$PromotionsModelCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String promotionId,
      String promoName,
      DateTime promoStartDate,
      int promoDisplayButtons,
      String promoImage,
      String promoImageExtension,
      String promoOverlayTiming,
      int promoPriority,
      int promoGeographicScope,
      int promoImageIsDark,
      int promoDisplayTimeInMs,
      int promoDisplayTimingDotsToDisplay,
      String promoDisplayTimingDotsShape,
      int promoDisplayTimingDotsSize,
      String promoType,
      int promoIsDraft,
      String? promoGroupId,
      String? kennelId,
      String? cityId,
      String? eventId,
      String? userId,
      DateTime? promoEndDate,
      String? promoImageWide,
      String? promoImageTall,
      String? promoExternalUrl,
      String? promoExternalUrlButtonText,
      double? promoLat,
      double? promoLon,
      int? promoRadius});
}

/// @nodoc
class __$PromotionsModelCopyWithImpl<$Res>
    implements _$PromotionsModelCopyWith<$Res> {
  __$PromotionsModelCopyWithImpl(this._self, this._then);

  final _PromotionsModel _self;
  final $Res Function(_PromotionsModel) _then;

  /// Create a copy of PromotionsModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? promotionId = null,
    Object? promoName = null,
    Object? promoStartDate = null,
    Object? promoDisplayButtons = null,
    Object? promoImage = null,
    Object? promoImageExtension = null,
    Object? promoOverlayTiming = null,
    Object? promoPriority = null,
    Object? promoGeographicScope = null,
    Object? promoImageIsDark = null,
    Object? promoDisplayTimeInMs = null,
    Object? promoDisplayTimingDotsToDisplay = null,
    Object? promoDisplayTimingDotsShape = null,
    Object? promoDisplayTimingDotsSize = null,
    Object? promoType = null,
    Object? promoIsDraft = null,
    Object? promoGroupId = freezed,
    Object? kennelId = freezed,
    Object? cityId = freezed,
    Object? eventId = freezed,
    Object? userId = freezed,
    Object? promoEndDate = freezed,
    Object? promoImageWide = freezed,
    Object? promoImageTall = freezed,
    Object? promoExternalUrl = freezed,
    Object? promoExternalUrlButtonText = freezed,
    Object? promoLat = freezed,
    Object? promoLon = freezed,
    Object? promoRadius = freezed,
  }) {
    return _then(_PromotionsModel(
      promotionId: null == promotionId
          ? _self.promotionId
          : promotionId // ignore: cast_nullable_to_non_nullable
              as String,
      promoName: null == promoName
          ? _self.promoName
          : promoName // ignore: cast_nullable_to_non_nullable
              as String,
      promoStartDate: null == promoStartDate
          ? _self.promoStartDate
          : promoStartDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      promoDisplayButtons: null == promoDisplayButtons
          ? _self.promoDisplayButtons
          : promoDisplayButtons // ignore: cast_nullable_to_non_nullable
              as int,
      promoImage: null == promoImage
          ? _self.promoImage
          : promoImage // ignore: cast_nullable_to_non_nullable
              as String,
      promoImageExtension: null == promoImageExtension
          ? _self.promoImageExtension
          : promoImageExtension // ignore: cast_nullable_to_non_nullable
              as String,
      promoOverlayTiming: null == promoOverlayTiming
          ? _self.promoOverlayTiming
          : promoOverlayTiming // ignore: cast_nullable_to_non_nullable
              as String,
      promoPriority: null == promoPriority
          ? _self.promoPriority
          : promoPriority // ignore: cast_nullable_to_non_nullable
              as int,
      promoGeographicScope: null == promoGeographicScope
          ? _self.promoGeographicScope
          : promoGeographicScope // ignore: cast_nullable_to_non_nullable
              as int,
      promoImageIsDark: null == promoImageIsDark
          ? _self.promoImageIsDark
          : promoImageIsDark // ignore: cast_nullable_to_non_nullable
              as int,
      promoDisplayTimeInMs: null == promoDisplayTimeInMs
          ? _self.promoDisplayTimeInMs
          : promoDisplayTimeInMs // ignore: cast_nullable_to_non_nullable
              as int,
      promoDisplayTimingDotsToDisplay: null == promoDisplayTimingDotsToDisplay
          ? _self.promoDisplayTimingDotsToDisplay
          : promoDisplayTimingDotsToDisplay // ignore: cast_nullable_to_non_nullable
              as int,
      promoDisplayTimingDotsShape: null == promoDisplayTimingDotsShape
          ? _self.promoDisplayTimingDotsShape
          : promoDisplayTimingDotsShape // ignore: cast_nullable_to_non_nullable
              as String,
      promoDisplayTimingDotsSize: null == promoDisplayTimingDotsSize
          ? _self.promoDisplayTimingDotsSize
          : promoDisplayTimingDotsSize // ignore: cast_nullable_to_non_nullable
              as int,
      promoType: null == promoType
          ? _self.promoType
          : promoType // ignore: cast_nullable_to_non_nullable
              as String,
      promoIsDraft: null == promoIsDraft
          ? _self.promoIsDraft
          : promoIsDraft // ignore: cast_nullable_to_non_nullable
              as int,
      promoGroupId: freezed == promoGroupId
          ? _self.promoGroupId
          : promoGroupId // ignore: cast_nullable_to_non_nullable
              as String?,
      kennelId: freezed == kennelId
          ? _self.kennelId
          : kennelId // ignore: cast_nullable_to_non_nullable
              as String?,
      cityId: freezed == cityId
          ? _self.cityId
          : cityId // ignore: cast_nullable_to_non_nullable
              as String?,
      eventId: freezed == eventId
          ? _self.eventId
          : eventId // ignore: cast_nullable_to_non_nullable
              as String?,
      userId: freezed == userId
          ? _self.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String?,
      promoEndDate: freezed == promoEndDate
          ? _self.promoEndDate
          : promoEndDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      promoImageWide: freezed == promoImageWide
          ? _self.promoImageWide
          : promoImageWide // ignore: cast_nullable_to_non_nullable
              as String?,
      promoImageTall: freezed == promoImageTall
          ? _self.promoImageTall
          : promoImageTall // ignore: cast_nullable_to_non_nullable
              as String?,
      promoExternalUrl: freezed == promoExternalUrl
          ? _self.promoExternalUrl
          : promoExternalUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      promoExternalUrlButtonText: freezed == promoExternalUrlButtonText
          ? _self.promoExternalUrlButtonText
          : promoExternalUrlButtonText // ignore: cast_nullable_to_non_nullable
              as String?,
      promoLat: freezed == promoLat
          ? _self.promoLat
          : promoLat // ignore: cast_nullable_to_non_nullable
              as double?,
      promoLon: freezed == promoLon
          ? _self.promoLon
          : promoLon // ignore: cast_nullable_to_non_nullable
              as double?,
      promoRadius: freezed == promoRadius
          ? _self.promoRadius
          : promoRadius // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

// dart format on
