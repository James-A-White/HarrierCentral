import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

part 'kennel_website_model.freezed.dart';
part 'kennel_website_model.g.dart';

class _UuidConverter extends JsonConverter<UuidValue, String> {
  const _UuidConverter();

  @override
  UuidValue fromJson(String json) => UuidValue.fromString(json);

  @override
  String toJson(UuidValue object) => object.toString();
}

// SQL Server BIT columns arrive as JSON booleans from the .NET shim.
// This converter accepts both `true`/`false` and `1`/`0`.
class _BoolConverter extends JsonConverter<bool, dynamic> {
  const _BoolConverter();

  @override
  bool fromJson(dynamic json) => json == true || json == 1;

  @override
  dynamic toJson(bool object) => object;
}

@freezed
abstract class KennelWebsiteModel with _$KennelWebsiteModel {
  factory KennelWebsiteModel({
    // Identity & routing
    @_UuidConverter() required UuidValue kennelId,
    @_BoolConverter() required bool enabled,
    String? customDomain,
    String? urlShortcode,

    // HC6 theming
    required String themeMode,
    String? primaryColor,
    String? accentColor,
    required int scrollBlur,

    // Branding & imagery
    String? bannerImage,
    String? ogImageUrl,
    String? backgroundImage,

    // HC6 style tokens
    String? titleTextColor,
    String? bodyTextColor,
    String? textMutedColor,
    String? cardBackgroundColor,
    String? buttonPrimaryColor,
    String? buttonCancelColor,
    String? buttonSecondaryColor,
    String? runCardColor,

    // HC5 nav colours (legacy — superseded by primaryColor + accentColor + themeMode)
    String? backgroundColor,
    String? menuBackgroundColor,
    String? menuTextColor,

    // HC5 fonts (legacy)
    String? titleFont,
    String? bodyFont,

    // Content
    String? titleText,
    String? tagline,
    String? welcomeText,

    // SEO
    String? seoTitle,
    String? seoDescription,
    String? seoStructuredDataJson,

    // Structured content (JSON)
    String? mismanagementDescription,
    String? mismanagementJson,
    String? extraMenusJson,
    String? contactDetailsJson,

    // System
    int? controlFlags,

    // Page features (JSON)
    String? pageFeaturesJson,
  }) = _KennelWebsiteModel;

  factory KennelWebsiteModel.empty() => KennelWebsiteModel(
        kennelId: UuidValue.fromString(const Uuid().v4()),
        enabled: false,
        themeMode: 'dark',
        scrollBlur: 0,
      );

  factory KennelWebsiteModel.fromJson(Map<String, dynamic> json) =>
      _$KennelWebsiteModelFromJson(json);
}
