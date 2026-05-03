// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'kennel_website_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$KennelWebsiteModel {
// Identity & routing
  @_UuidConverter()
  UuidValue get kennelId;
  @_BoolConverter()
  bool get enabled;
  String? get customDomain;
  String? get urlShortcode; // HC6 theming
  String get themeMode;
  String? get primaryColor;
  String? get accentColor;
  int get scrollBlur; // Branding & imagery
  String? get bannerImage;
  String? get ogImageUrl;
  String? get backgroundImage; // HC6 style tokens
  String? get titleTextColor;
  String? get bodyTextColor;
  String? get textMutedColor;
  String?
      get cardBackgroundColor; // HC5 nav colours (legacy — superseded by primaryColor + accentColor + themeMode)
  String? get backgroundColor;
  String? get menuBackgroundColor;
  String? get menuTextColor; // HC5 fonts (legacy)
  String? get titleFont;
  String? get bodyFont; // Content
  String? get titleText;
  String? get tagline;
  String? get welcomeText; // SEO
  String? get seoTitle;
  String? get seoDescription;
  String? get seoStructuredDataJson; // Structured content (JSON)
  String? get mismanagementDescription;
  String? get mismanagementJson;
  String? get extraMenusJson;
  String? get contactDetailsJson; // System
  int? get controlFlags;

  /// Create a copy of KennelWebsiteModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $KennelWebsiteModelCopyWith<KennelWebsiteModel> get copyWith =>
      _$KennelWebsiteModelCopyWithImpl<KennelWebsiteModel>(
          this as KennelWebsiteModel, _$identity);

  /// Serializes this KennelWebsiteModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is KennelWebsiteModel &&
            (identical(other.kennelId, kennelId) ||
                other.kennelId == kennelId) &&
            (identical(other.enabled, enabled) || other.enabled == enabled) &&
            (identical(other.customDomain, customDomain) ||
                other.customDomain == customDomain) &&
            (identical(other.urlShortcode, urlShortcode) ||
                other.urlShortcode == urlShortcode) &&
            (identical(other.themeMode, themeMode) ||
                other.themeMode == themeMode) &&
            (identical(other.primaryColor, primaryColor) ||
                other.primaryColor == primaryColor) &&
            (identical(other.accentColor, accentColor) ||
                other.accentColor == accentColor) &&
            (identical(other.scrollBlur, scrollBlur) ||
                other.scrollBlur == scrollBlur) &&
            (identical(other.bannerImage, bannerImage) ||
                other.bannerImage == bannerImage) &&
            (identical(other.ogImageUrl, ogImageUrl) ||
                other.ogImageUrl == ogImageUrl) &&
            (identical(other.backgroundImage, backgroundImage) ||
                other.backgroundImage == backgroundImage) &&
            (identical(other.titleTextColor, titleTextColor) ||
                other.titleTextColor == titleTextColor) &&
            (identical(other.bodyTextColor, bodyTextColor) ||
                other.bodyTextColor == bodyTextColor) &&
            (identical(other.textMutedColor, textMutedColor) ||
                other.textMutedColor == textMutedColor) &&
            (identical(other.cardBackgroundColor, cardBackgroundColor) ||
                other.cardBackgroundColor == cardBackgroundColor) &&
            (identical(other.backgroundColor, backgroundColor) ||
                other.backgroundColor == backgroundColor) &&
            (identical(other.menuBackgroundColor, menuBackgroundColor) ||
                other.menuBackgroundColor == menuBackgroundColor) &&
            (identical(other.menuTextColor, menuTextColor) ||
                other.menuTextColor == menuTextColor) &&
            (identical(other.titleFont, titleFont) ||
                other.titleFont == titleFont) &&
            (identical(other.bodyFont, bodyFont) ||
                other.bodyFont == bodyFont) &&
            (identical(other.titleText, titleText) ||
                other.titleText == titleText) &&
            (identical(other.tagline, tagline) || other.tagline == tagline) &&
            (identical(other.welcomeText, welcomeText) ||
                other.welcomeText == welcomeText) &&
            (identical(other.seoTitle, seoTitle) ||
                other.seoTitle == seoTitle) &&
            (identical(other.seoDescription, seoDescription) ||
                other.seoDescription == seoDescription) &&
            (identical(other.seoStructuredDataJson, seoStructuredDataJson) ||
                other.seoStructuredDataJson == seoStructuredDataJson) &&
            (identical(
                    other.mismanagementDescription, mismanagementDescription) ||
                other.mismanagementDescription == mismanagementDescription) &&
            (identical(other.mismanagementJson, mismanagementJson) ||
                other.mismanagementJson == mismanagementJson) &&
            (identical(other.extraMenusJson, extraMenusJson) ||
                other.extraMenusJson == extraMenusJson) &&
            (identical(other.contactDetailsJson, contactDetailsJson) ||
                other.contactDetailsJson == contactDetailsJson) &&
            (identical(other.controlFlags, controlFlags) ||
                other.controlFlags == controlFlags));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        kennelId,
        enabled,
        customDomain,
        urlShortcode,
        themeMode,
        primaryColor,
        accentColor,
        scrollBlur,
        bannerImage,
        ogImageUrl,
        backgroundImage,
        titleTextColor,
        bodyTextColor,
        textMutedColor,
        cardBackgroundColor,
        backgroundColor,
        menuBackgroundColor,
        menuTextColor,
        titleFont,
        bodyFont,
        titleText,
        tagline,
        welcomeText,
        seoTitle,
        seoDescription,
        seoStructuredDataJson,
        mismanagementDescription,
        mismanagementJson,
        extraMenusJson,
        contactDetailsJson,
        controlFlags
      ]);

  @override
  String toString() {
    return 'KennelWebsiteModel(kennelId: $kennelId, enabled: $enabled, customDomain: $customDomain, urlShortcode: $urlShortcode, themeMode: $themeMode, primaryColor: $primaryColor, accentColor: $accentColor, scrollBlur: $scrollBlur, bannerImage: $bannerImage, ogImageUrl: $ogImageUrl, backgroundImage: $backgroundImage, titleTextColor: $titleTextColor, bodyTextColor: $bodyTextColor, textMutedColor: $textMutedColor, cardBackgroundColor: $cardBackgroundColor, backgroundColor: $backgroundColor, menuBackgroundColor: $menuBackgroundColor, menuTextColor: $menuTextColor, titleFont: $titleFont, bodyFont: $bodyFont, titleText: $titleText, tagline: $tagline, welcomeText: $welcomeText, seoTitle: $seoTitle, seoDescription: $seoDescription, seoStructuredDataJson: $seoStructuredDataJson, mismanagementDescription: $mismanagementDescription, mismanagementJson: $mismanagementJson, extraMenusJson: $extraMenusJson, contactDetailsJson: $contactDetailsJson, controlFlags: $controlFlags)';
  }
}

/// @nodoc
abstract mixin class $KennelWebsiteModelCopyWith<$Res> {
  factory $KennelWebsiteModelCopyWith(
          KennelWebsiteModel value, $Res Function(KennelWebsiteModel) _then) =
      _$KennelWebsiteModelCopyWithImpl;
  @useResult
  $Res call(
      {@_UuidConverter() UuidValue kennelId,
      @_BoolConverter() bool enabled,
      String? customDomain,
      String? urlShortcode,
      String themeMode,
      String? primaryColor,
      String? accentColor,
      int scrollBlur,
      String? bannerImage,
      String? ogImageUrl,
      String? backgroundImage,
      String? titleTextColor,
      String? bodyTextColor,
      String? textMutedColor,
      String? cardBackgroundColor,
      String? backgroundColor,
      String? menuBackgroundColor,
      String? menuTextColor,
      String? titleFont,
      String? bodyFont,
      String? titleText,
      String? tagline,
      String? welcomeText,
      String? seoTitle,
      String? seoDescription,
      String? seoStructuredDataJson,
      String? mismanagementDescription,
      String? mismanagementJson,
      String? extraMenusJson,
      String? contactDetailsJson,
      int? controlFlags});
}

/// @nodoc
class _$KennelWebsiteModelCopyWithImpl<$Res>
    implements $KennelWebsiteModelCopyWith<$Res> {
  _$KennelWebsiteModelCopyWithImpl(this._self, this._then);

  final KennelWebsiteModel _self;
  final $Res Function(KennelWebsiteModel) _then;

  /// Create a copy of KennelWebsiteModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? kennelId = null,
    Object? enabled = null,
    Object? customDomain = freezed,
    Object? urlShortcode = freezed,
    Object? themeMode = null,
    Object? primaryColor = freezed,
    Object? accentColor = freezed,
    Object? scrollBlur = null,
    Object? bannerImage = freezed,
    Object? ogImageUrl = freezed,
    Object? backgroundImage = freezed,
    Object? titleTextColor = freezed,
    Object? bodyTextColor = freezed,
    Object? textMutedColor = freezed,
    Object? cardBackgroundColor = freezed,
    Object? backgroundColor = freezed,
    Object? menuBackgroundColor = freezed,
    Object? menuTextColor = freezed,
    Object? titleFont = freezed,
    Object? bodyFont = freezed,
    Object? titleText = freezed,
    Object? tagline = freezed,
    Object? welcomeText = freezed,
    Object? seoTitle = freezed,
    Object? seoDescription = freezed,
    Object? seoStructuredDataJson = freezed,
    Object? mismanagementDescription = freezed,
    Object? mismanagementJson = freezed,
    Object? extraMenusJson = freezed,
    Object? contactDetailsJson = freezed,
    Object? controlFlags = freezed,
  }) {
    return _then(_self.copyWith(
      kennelId: null == kennelId
          ? _self.kennelId
          : kennelId // ignore: cast_nullable_to_non_nullable
              as UuidValue,
      enabled: null == enabled
          ? _self.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool,
      customDomain: freezed == customDomain
          ? _self.customDomain
          : customDomain // ignore: cast_nullable_to_non_nullable
              as String?,
      urlShortcode: freezed == urlShortcode
          ? _self.urlShortcode
          : urlShortcode // ignore: cast_nullable_to_non_nullable
              as String?,
      themeMode: null == themeMode
          ? _self.themeMode
          : themeMode // ignore: cast_nullable_to_non_nullable
              as String,
      primaryColor: freezed == primaryColor
          ? _self.primaryColor
          : primaryColor // ignore: cast_nullable_to_non_nullable
              as String?,
      accentColor: freezed == accentColor
          ? _self.accentColor
          : accentColor // ignore: cast_nullable_to_non_nullable
              as String?,
      scrollBlur: null == scrollBlur
          ? _self.scrollBlur
          : scrollBlur // ignore: cast_nullable_to_non_nullable
              as int,
      bannerImage: freezed == bannerImage
          ? _self.bannerImage
          : bannerImage // ignore: cast_nullable_to_non_nullable
              as String?,
      ogImageUrl: freezed == ogImageUrl
          ? _self.ogImageUrl
          : ogImageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      backgroundImage: freezed == backgroundImage
          ? _self.backgroundImage
          : backgroundImage // ignore: cast_nullable_to_non_nullable
              as String?,
      titleTextColor: freezed == titleTextColor
          ? _self.titleTextColor
          : titleTextColor // ignore: cast_nullable_to_non_nullable
              as String?,
      bodyTextColor: freezed == bodyTextColor
          ? _self.bodyTextColor
          : bodyTextColor // ignore: cast_nullable_to_non_nullable
              as String?,
      textMutedColor: freezed == textMutedColor
          ? _self.textMutedColor
          : textMutedColor // ignore: cast_nullable_to_non_nullable
              as String?,
      cardBackgroundColor: freezed == cardBackgroundColor
          ? _self.cardBackgroundColor
          : cardBackgroundColor // ignore: cast_nullable_to_non_nullable
              as String?,
      backgroundColor: freezed == backgroundColor
          ? _self.backgroundColor
          : backgroundColor // ignore: cast_nullable_to_non_nullable
              as String?,
      menuBackgroundColor: freezed == menuBackgroundColor
          ? _self.menuBackgroundColor
          : menuBackgroundColor // ignore: cast_nullable_to_non_nullable
              as String?,
      menuTextColor: freezed == menuTextColor
          ? _self.menuTextColor
          : menuTextColor // ignore: cast_nullable_to_non_nullable
              as String?,
      titleFont: freezed == titleFont
          ? _self.titleFont
          : titleFont // ignore: cast_nullable_to_non_nullable
              as String?,
      bodyFont: freezed == bodyFont
          ? _self.bodyFont
          : bodyFont // ignore: cast_nullable_to_non_nullable
              as String?,
      titleText: freezed == titleText
          ? _self.titleText
          : titleText // ignore: cast_nullable_to_non_nullable
              as String?,
      tagline: freezed == tagline
          ? _self.tagline
          : tagline // ignore: cast_nullable_to_non_nullable
              as String?,
      welcomeText: freezed == welcomeText
          ? _self.welcomeText
          : welcomeText // ignore: cast_nullable_to_non_nullable
              as String?,
      seoTitle: freezed == seoTitle
          ? _self.seoTitle
          : seoTitle // ignore: cast_nullable_to_non_nullable
              as String?,
      seoDescription: freezed == seoDescription
          ? _self.seoDescription
          : seoDescription // ignore: cast_nullable_to_non_nullable
              as String?,
      seoStructuredDataJson: freezed == seoStructuredDataJson
          ? _self.seoStructuredDataJson
          : seoStructuredDataJson // ignore: cast_nullable_to_non_nullable
              as String?,
      mismanagementDescription: freezed == mismanagementDescription
          ? _self.mismanagementDescription
          : mismanagementDescription // ignore: cast_nullable_to_non_nullable
              as String?,
      mismanagementJson: freezed == mismanagementJson
          ? _self.mismanagementJson
          : mismanagementJson // ignore: cast_nullable_to_non_nullable
              as String?,
      extraMenusJson: freezed == extraMenusJson
          ? _self.extraMenusJson
          : extraMenusJson // ignore: cast_nullable_to_non_nullable
              as String?,
      contactDetailsJson: freezed == contactDetailsJson
          ? _self.contactDetailsJson
          : contactDetailsJson // ignore: cast_nullable_to_non_nullable
              as String?,
      controlFlags: freezed == controlFlags
          ? _self.controlFlags
          : controlFlags // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// Adds pattern-matching-related methods to [KennelWebsiteModel].
extension KennelWebsiteModelPatterns on KennelWebsiteModel {
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
    TResult Function(_KennelWebsiteModel value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _KennelWebsiteModel() when $default != null:
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
    TResult Function(_KennelWebsiteModel value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _KennelWebsiteModel():
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
    TResult? Function(_KennelWebsiteModel value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _KennelWebsiteModel() when $default != null:
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
            @_UuidConverter() UuidValue kennelId,
            @_BoolConverter() bool enabled,
            String? customDomain,
            String? urlShortcode,
            String themeMode,
            String? primaryColor,
            String? accentColor,
            int scrollBlur,
            String? bannerImage,
            String? ogImageUrl,
            String? backgroundImage,
            String? titleTextColor,
            String? bodyTextColor,
            String? textMutedColor,
            String? cardBackgroundColor,
            String? backgroundColor,
            String? menuBackgroundColor,
            String? menuTextColor,
            String? titleFont,
            String? bodyFont,
            String? titleText,
            String? tagline,
            String? welcomeText,
            String? seoTitle,
            String? seoDescription,
            String? seoStructuredDataJson,
            String? mismanagementDescription,
            String? mismanagementJson,
            String? extraMenusJson,
            String? contactDetailsJson,
            int? controlFlags)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _KennelWebsiteModel() when $default != null:
        return $default(
            _that.kennelId,
            _that.enabled,
            _that.customDomain,
            _that.urlShortcode,
            _that.themeMode,
            _that.primaryColor,
            _that.accentColor,
            _that.scrollBlur,
            _that.bannerImage,
            _that.ogImageUrl,
            _that.backgroundImage,
            _that.titleTextColor,
            _that.bodyTextColor,
            _that.textMutedColor,
            _that.cardBackgroundColor,
            _that.backgroundColor,
            _that.menuBackgroundColor,
            _that.menuTextColor,
            _that.titleFont,
            _that.bodyFont,
            _that.titleText,
            _that.tagline,
            _that.welcomeText,
            _that.seoTitle,
            _that.seoDescription,
            _that.seoStructuredDataJson,
            _that.mismanagementDescription,
            _that.mismanagementJson,
            _that.extraMenusJson,
            _that.contactDetailsJson,
            _that.controlFlags);
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
            @_UuidConverter() UuidValue kennelId,
            @_BoolConverter() bool enabled,
            String? customDomain,
            String? urlShortcode,
            String themeMode,
            String? primaryColor,
            String? accentColor,
            int scrollBlur,
            String? bannerImage,
            String? ogImageUrl,
            String? backgroundImage,
            String? titleTextColor,
            String? bodyTextColor,
            String? textMutedColor,
            String? cardBackgroundColor,
            String? backgroundColor,
            String? menuBackgroundColor,
            String? menuTextColor,
            String? titleFont,
            String? bodyFont,
            String? titleText,
            String? tagline,
            String? welcomeText,
            String? seoTitle,
            String? seoDescription,
            String? seoStructuredDataJson,
            String? mismanagementDescription,
            String? mismanagementJson,
            String? extraMenusJson,
            String? contactDetailsJson,
            int? controlFlags)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _KennelWebsiteModel():
        return $default(
            _that.kennelId,
            _that.enabled,
            _that.customDomain,
            _that.urlShortcode,
            _that.themeMode,
            _that.primaryColor,
            _that.accentColor,
            _that.scrollBlur,
            _that.bannerImage,
            _that.ogImageUrl,
            _that.backgroundImage,
            _that.titleTextColor,
            _that.bodyTextColor,
            _that.textMutedColor,
            _that.cardBackgroundColor,
            _that.backgroundColor,
            _that.menuBackgroundColor,
            _that.menuTextColor,
            _that.titleFont,
            _that.bodyFont,
            _that.titleText,
            _that.tagline,
            _that.welcomeText,
            _that.seoTitle,
            _that.seoDescription,
            _that.seoStructuredDataJson,
            _that.mismanagementDescription,
            _that.mismanagementJson,
            _that.extraMenusJson,
            _that.contactDetailsJson,
            _that.controlFlags);
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
            @_UuidConverter() UuidValue kennelId,
            @_BoolConverter() bool enabled,
            String? customDomain,
            String? urlShortcode,
            String themeMode,
            String? primaryColor,
            String? accentColor,
            int scrollBlur,
            String? bannerImage,
            String? ogImageUrl,
            String? backgroundImage,
            String? titleTextColor,
            String? bodyTextColor,
            String? textMutedColor,
            String? cardBackgroundColor,
            String? backgroundColor,
            String? menuBackgroundColor,
            String? menuTextColor,
            String? titleFont,
            String? bodyFont,
            String? titleText,
            String? tagline,
            String? welcomeText,
            String? seoTitle,
            String? seoDescription,
            String? seoStructuredDataJson,
            String? mismanagementDescription,
            String? mismanagementJson,
            String? extraMenusJson,
            String? contactDetailsJson,
            int? controlFlags)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _KennelWebsiteModel() when $default != null:
        return $default(
            _that.kennelId,
            _that.enabled,
            _that.customDomain,
            _that.urlShortcode,
            _that.themeMode,
            _that.primaryColor,
            _that.accentColor,
            _that.scrollBlur,
            _that.bannerImage,
            _that.ogImageUrl,
            _that.backgroundImage,
            _that.titleTextColor,
            _that.bodyTextColor,
            _that.textMutedColor,
            _that.cardBackgroundColor,
            _that.backgroundColor,
            _that.menuBackgroundColor,
            _that.menuTextColor,
            _that.titleFont,
            _that.bodyFont,
            _that.titleText,
            _that.tagline,
            _that.welcomeText,
            _that.seoTitle,
            _that.seoDescription,
            _that.seoStructuredDataJson,
            _that.mismanagementDescription,
            _that.mismanagementJson,
            _that.extraMenusJson,
            _that.contactDetailsJson,
            _that.controlFlags);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _KennelWebsiteModel implements KennelWebsiteModel {
  _KennelWebsiteModel(
      {@_UuidConverter() required this.kennelId,
      @_BoolConverter() required this.enabled,
      this.customDomain,
      this.urlShortcode,
      required this.themeMode,
      this.primaryColor,
      this.accentColor,
      required this.scrollBlur,
      this.bannerImage,
      this.ogImageUrl,
      this.backgroundImage,
      this.titleTextColor,
      this.bodyTextColor,
      this.textMutedColor,
      this.cardBackgroundColor,
      this.backgroundColor,
      this.menuBackgroundColor,
      this.menuTextColor,
      this.titleFont,
      this.bodyFont,
      this.titleText,
      this.tagline,
      this.welcomeText,
      this.seoTitle,
      this.seoDescription,
      this.seoStructuredDataJson,
      this.mismanagementDescription,
      this.mismanagementJson,
      this.extraMenusJson,
      this.contactDetailsJson,
      this.controlFlags});
  factory _KennelWebsiteModel.fromJson(Map<String, dynamic> json) =>
      _$KennelWebsiteModelFromJson(json);

// Identity & routing
  @override
  @_UuidConverter()
  final UuidValue kennelId;
  @override
  @_BoolConverter()
  final bool enabled;
  @override
  final String? customDomain;
  @override
  final String? urlShortcode;
// HC6 theming
  @override
  final String themeMode;
  @override
  final String? primaryColor;
  @override
  final String? accentColor;
  @override
  final int scrollBlur;
// Branding & imagery
  @override
  final String? bannerImage;
  @override
  final String? ogImageUrl;
  @override
  final String? backgroundImage;
// HC6 style tokens
  @override
  final String? titleTextColor;
  @override
  final String? bodyTextColor;
  @override
  final String? textMutedColor;
  @override
  final String? cardBackgroundColor;
// HC5 nav colours (legacy — superseded by primaryColor + accentColor + themeMode)
  @override
  final String? backgroundColor;
  @override
  final String? menuBackgroundColor;
  @override
  final String? menuTextColor;
// HC5 fonts (legacy)
  @override
  final String? titleFont;
  @override
  final String? bodyFont;
// Content
  @override
  final String? titleText;
  @override
  final String? tagline;
  @override
  final String? welcomeText;
// SEO
  @override
  final String? seoTitle;
  @override
  final String? seoDescription;
  @override
  final String? seoStructuredDataJson;
// Structured content (JSON)
  @override
  final String? mismanagementDescription;
  @override
  final String? mismanagementJson;
  @override
  final String? extraMenusJson;
  @override
  final String? contactDetailsJson;
// System
  @override
  final int? controlFlags;

  /// Create a copy of KennelWebsiteModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$KennelWebsiteModelCopyWith<_KennelWebsiteModel> get copyWith =>
      __$KennelWebsiteModelCopyWithImpl<_KennelWebsiteModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$KennelWebsiteModelToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _KennelWebsiteModel &&
            (identical(other.kennelId, kennelId) ||
                other.kennelId == kennelId) &&
            (identical(other.enabled, enabled) || other.enabled == enabled) &&
            (identical(other.customDomain, customDomain) ||
                other.customDomain == customDomain) &&
            (identical(other.urlShortcode, urlShortcode) ||
                other.urlShortcode == urlShortcode) &&
            (identical(other.themeMode, themeMode) ||
                other.themeMode == themeMode) &&
            (identical(other.primaryColor, primaryColor) ||
                other.primaryColor == primaryColor) &&
            (identical(other.accentColor, accentColor) ||
                other.accentColor == accentColor) &&
            (identical(other.scrollBlur, scrollBlur) ||
                other.scrollBlur == scrollBlur) &&
            (identical(other.bannerImage, bannerImage) ||
                other.bannerImage == bannerImage) &&
            (identical(other.ogImageUrl, ogImageUrl) ||
                other.ogImageUrl == ogImageUrl) &&
            (identical(other.backgroundImage, backgroundImage) ||
                other.backgroundImage == backgroundImage) &&
            (identical(other.titleTextColor, titleTextColor) ||
                other.titleTextColor == titleTextColor) &&
            (identical(other.bodyTextColor, bodyTextColor) ||
                other.bodyTextColor == bodyTextColor) &&
            (identical(other.textMutedColor, textMutedColor) ||
                other.textMutedColor == textMutedColor) &&
            (identical(other.cardBackgroundColor, cardBackgroundColor) ||
                other.cardBackgroundColor == cardBackgroundColor) &&
            (identical(other.backgroundColor, backgroundColor) ||
                other.backgroundColor == backgroundColor) &&
            (identical(other.menuBackgroundColor, menuBackgroundColor) ||
                other.menuBackgroundColor == menuBackgroundColor) &&
            (identical(other.menuTextColor, menuTextColor) ||
                other.menuTextColor == menuTextColor) &&
            (identical(other.titleFont, titleFont) ||
                other.titleFont == titleFont) &&
            (identical(other.bodyFont, bodyFont) ||
                other.bodyFont == bodyFont) &&
            (identical(other.titleText, titleText) ||
                other.titleText == titleText) &&
            (identical(other.tagline, tagline) || other.tagline == tagline) &&
            (identical(other.welcomeText, welcomeText) ||
                other.welcomeText == welcomeText) &&
            (identical(other.seoTitle, seoTitle) ||
                other.seoTitle == seoTitle) &&
            (identical(other.seoDescription, seoDescription) ||
                other.seoDescription == seoDescription) &&
            (identical(other.seoStructuredDataJson, seoStructuredDataJson) ||
                other.seoStructuredDataJson == seoStructuredDataJson) &&
            (identical(
                    other.mismanagementDescription, mismanagementDescription) ||
                other.mismanagementDescription == mismanagementDescription) &&
            (identical(other.mismanagementJson, mismanagementJson) ||
                other.mismanagementJson == mismanagementJson) &&
            (identical(other.extraMenusJson, extraMenusJson) ||
                other.extraMenusJson == extraMenusJson) &&
            (identical(other.contactDetailsJson, contactDetailsJson) ||
                other.contactDetailsJson == contactDetailsJson) &&
            (identical(other.controlFlags, controlFlags) ||
                other.controlFlags == controlFlags));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        kennelId,
        enabled,
        customDomain,
        urlShortcode,
        themeMode,
        primaryColor,
        accentColor,
        scrollBlur,
        bannerImage,
        ogImageUrl,
        backgroundImage,
        titleTextColor,
        bodyTextColor,
        textMutedColor,
        cardBackgroundColor,
        backgroundColor,
        menuBackgroundColor,
        menuTextColor,
        titleFont,
        bodyFont,
        titleText,
        tagline,
        welcomeText,
        seoTitle,
        seoDescription,
        seoStructuredDataJson,
        mismanagementDescription,
        mismanagementJson,
        extraMenusJson,
        contactDetailsJson,
        controlFlags
      ]);

  @override
  String toString() {
    return 'KennelWebsiteModel(kennelId: $kennelId, enabled: $enabled, customDomain: $customDomain, urlShortcode: $urlShortcode, themeMode: $themeMode, primaryColor: $primaryColor, accentColor: $accentColor, scrollBlur: $scrollBlur, bannerImage: $bannerImage, ogImageUrl: $ogImageUrl, backgroundImage: $backgroundImage, titleTextColor: $titleTextColor, bodyTextColor: $bodyTextColor, textMutedColor: $textMutedColor, cardBackgroundColor: $cardBackgroundColor, backgroundColor: $backgroundColor, menuBackgroundColor: $menuBackgroundColor, menuTextColor: $menuTextColor, titleFont: $titleFont, bodyFont: $bodyFont, titleText: $titleText, tagline: $tagline, welcomeText: $welcomeText, seoTitle: $seoTitle, seoDescription: $seoDescription, seoStructuredDataJson: $seoStructuredDataJson, mismanagementDescription: $mismanagementDescription, mismanagementJson: $mismanagementJson, extraMenusJson: $extraMenusJson, contactDetailsJson: $contactDetailsJson, controlFlags: $controlFlags)';
  }
}

/// @nodoc
abstract mixin class _$KennelWebsiteModelCopyWith<$Res>
    implements $KennelWebsiteModelCopyWith<$Res> {
  factory _$KennelWebsiteModelCopyWith(
          _KennelWebsiteModel value, $Res Function(_KennelWebsiteModel) _then) =
      __$KennelWebsiteModelCopyWithImpl;
  @override
  @useResult
  $Res call(
      {@_UuidConverter() UuidValue kennelId,
      @_BoolConverter() bool enabled,
      String? customDomain,
      String? urlShortcode,
      String themeMode,
      String? primaryColor,
      String? accentColor,
      int scrollBlur,
      String? bannerImage,
      String? ogImageUrl,
      String? backgroundImage,
      String? titleTextColor,
      String? bodyTextColor,
      String? textMutedColor,
      String? cardBackgroundColor,
      String? backgroundColor,
      String? menuBackgroundColor,
      String? menuTextColor,
      String? titleFont,
      String? bodyFont,
      String? titleText,
      String? tagline,
      String? welcomeText,
      String? seoTitle,
      String? seoDescription,
      String? seoStructuredDataJson,
      String? mismanagementDescription,
      String? mismanagementJson,
      String? extraMenusJson,
      String? contactDetailsJson,
      int? controlFlags});
}

/// @nodoc
class __$KennelWebsiteModelCopyWithImpl<$Res>
    implements _$KennelWebsiteModelCopyWith<$Res> {
  __$KennelWebsiteModelCopyWithImpl(this._self, this._then);

  final _KennelWebsiteModel _self;
  final $Res Function(_KennelWebsiteModel) _then;

  /// Create a copy of KennelWebsiteModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? kennelId = null,
    Object? enabled = null,
    Object? customDomain = freezed,
    Object? urlShortcode = freezed,
    Object? themeMode = null,
    Object? primaryColor = freezed,
    Object? accentColor = freezed,
    Object? scrollBlur = null,
    Object? bannerImage = freezed,
    Object? ogImageUrl = freezed,
    Object? backgroundImage = freezed,
    Object? titleTextColor = freezed,
    Object? bodyTextColor = freezed,
    Object? textMutedColor = freezed,
    Object? cardBackgroundColor = freezed,
    Object? backgroundColor = freezed,
    Object? menuBackgroundColor = freezed,
    Object? menuTextColor = freezed,
    Object? titleFont = freezed,
    Object? bodyFont = freezed,
    Object? titleText = freezed,
    Object? tagline = freezed,
    Object? welcomeText = freezed,
    Object? seoTitle = freezed,
    Object? seoDescription = freezed,
    Object? seoStructuredDataJson = freezed,
    Object? mismanagementDescription = freezed,
    Object? mismanagementJson = freezed,
    Object? extraMenusJson = freezed,
    Object? contactDetailsJson = freezed,
    Object? controlFlags = freezed,
  }) {
    return _then(_KennelWebsiteModel(
      kennelId: null == kennelId
          ? _self.kennelId
          : kennelId // ignore: cast_nullable_to_non_nullable
              as UuidValue,
      enabled: null == enabled
          ? _self.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool,
      customDomain: freezed == customDomain
          ? _self.customDomain
          : customDomain // ignore: cast_nullable_to_non_nullable
              as String?,
      urlShortcode: freezed == urlShortcode
          ? _self.urlShortcode
          : urlShortcode // ignore: cast_nullable_to_non_nullable
              as String?,
      themeMode: null == themeMode
          ? _self.themeMode
          : themeMode // ignore: cast_nullable_to_non_nullable
              as String,
      primaryColor: freezed == primaryColor
          ? _self.primaryColor
          : primaryColor // ignore: cast_nullable_to_non_nullable
              as String?,
      accentColor: freezed == accentColor
          ? _self.accentColor
          : accentColor // ignore: cast_nullable_to_non_nullable
              as String?,
      scrollBlur: null == scrollBlur
          ? _self.scrollBlur
          : scrollBlur // ignore: cast_nullable_to_non_nullable
              as int,
      bannerImage: freezed == bannerImage
          ? _self.bannerImage
          : bannerImage // ignore: cast_nullable_to_non_nullable
              as String?,
      ogImageUrl: freezed == ogImageUrl
          ? _self.ogImageUrl
          : ogImageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      backgroundImage: freezed == backgroundImage
          ? _self.backgroundImage
          : backgroundImage // ignore: cast_nullable_to_non_nullable
              as String?,
      titleTextColor: freezed == titleTextColor
          ? _self.titleTextColor
          : titleTextColor // ignore: cast_nullable_to_non_nullable
              as String?,
      bodyTextColor: freezed == bodyTextColor
          ? _self.bodyTextColor
          : bodyTextColor // ignore: cast_nullable_to_non_nullable
              as String?,
      textMutedColor: freezed == textMutedColor
          ? _self.textMutedColor
          : textMutedColor // ignore: cast_nullable_to_non_nullable
              as String?,
      cardBackgroundColor: freezed == cardBackgroundColor
          ? _self.cardBackgroundColor
          : cardBackgroundColor // ignore: cast_nullable_to_non_nullable
              as String?,
      backgroundColor: freezed == backgroundColor
          ? _self.backgroundColor
          : backgroundColor // ignore: cast_nullable_to_non_nullable
              as String?,
      menuBackgroundColor: freezed == menuBackgroundColor
          ? _self.menuBackgroundColor
          : menuBackgroundColor // ignore: cast_nullable_to_non_nullable
              as String?,
      menuTextColor: freezed == menuTextColor
          ? _self.menuTextColor
          : menuTextColor // ignore: cast_nullable_to_non_nullable
              as String?,
      titleFont: freezed == titleFont
          ? _self.titleFont
          : titleFont // ignore: cast_nullable_to_non_nullable
              as String?,
      bodyFont: freezed == bodyFont
          ? _self.bodyFont
          : bodyFont // ignore: cast_nullable_to_non_nullable
              as String?,
      titleText: freezed == titleText
          ? _self.titleText
          : titleText // ignore: cast_nullable_to_non_nullable
              as String?,
      tagline: freezed == tagline
          ? _self.tagline
          : tagline // ignore: cast_nullable_to_non_nullable
              as String?,
      welcomeText: freezed == welcomeText
          ? _self.welcomeText
          : welcomeText // ignore: cast_nullable_to_non_nullable
              as String?,
      seoTitle: freezed == seoTitle
          ? _self.seoTitle
          : seoTitle // ignore: cast_nullable_to_non_nullable
              as String?,
      seoDescription: freezed == seoDescription
          ? _self.seoDescription
          : seoDescription // ignore: cast_nullable_to_non_nullable
              as String?,
      seoStructuredDataJson: freezed == seoStructuredDataJson
          ? _self.seoStructuredDataJson
          : seoStructuredDataJson // ignore: cast_nullable_to_non_nullable
              as String?,
      mismanagementDescription: freezed == mismanagementDescription
          ? _self.mismanagementDescription
          : mismanagementDescription // ignore: cast_nullable_to_non_nullable
              as String?,
      mismanagementJson: freezed == mismanagementJson
          ? _self.mismanagementJson
          : mismanagementJson // ignore: cast_nullable_to_non_nullable
              as String?,
      extraMenusJson: freezed == extraMenusJson
          ? _self.extraMenusJson
          : extraMenusJson // ignore: cast_nullable_to_non_nullable
              as String?,
      contactDetailsJson: freezed == contactDetailsJson
          ? _self.contactDetailsJson
          : contactDetailsJson // ignore: cast_nullable_to_non_nullable
              as String?,
      controlFlags: freezed == controlFlags
          ? _self.controlFlags
          : controlFlags // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

// dart format on
