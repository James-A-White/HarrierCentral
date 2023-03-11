import 'package:harrier_central/imports_null_safe.dart';

part 'countries_model_ns.freezed.dart';
part 'countries_model_ns.g.dart';

@freezed
class CountriesModel with _$CountriesModel implements BaseModel {
  factory CountriesModel({
    required String countryId,
    required String countryCode,
    required num latitude,
    required num longitude,
    required String countryName,
    String? countrySearchTags,
    required String continentCode,
    String? flagFile,
    required String currencyCode,
    required String primaryCultureCode,
    required int showRegion,
    String? currencySymbol,
    int? digitsAfterDecimal,
    int? distancePreference,
    required int removed,
    required DateTime updatedAt,
  }) = _CountriesModel;

  factory CountriesModel.fromJson(Map<String, dynamic> json) => _$CountriesModelFromJson(json);
}
