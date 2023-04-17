//import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:harrier_central/imports.dart';

part 'countries_model_ns.freezed.dart';
part 'countries_model_ns.g.dart';

@freezed
class CountriesModel with _$CountriesModel implements BaseModel {
  factory CountriesModel({
    required String countryId,
    required String countryCode,
    required double latitude,
    required double longitude,
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
    int? removed,
    DateTime? updatedAt,
  }) = _CountriesModel;

  factory CountriesModel.fromJson(Map<String, dynamic> json) => _$CountriesModelFromJson(json);
}
