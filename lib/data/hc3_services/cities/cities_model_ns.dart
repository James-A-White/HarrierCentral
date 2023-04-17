import 'package:harrier_central/imports.dart';

part 'cities_model_ns.freezed.dart';
part 'cities_model_ns.g.dart';

@freezed
class CitiesModel with _$CitiesModel implements BaseModel {
  const factory CitiesModel({
    required String cityId,
    required String cityName,
    String? citySearchTags,
    required String regionId,
    required double latitude,
    required double longitude,
    required String cityAscii,
    String? flagFile,
    int? removed,
    DateTime? updatedAt,
  }) = _CitiesModel;

  factory CitiesModel.fromJson(Map<String, dynamic> json) => _$CitiesModelFromJson(json);

  @override
  factory CitiesModel.fromMap(Map<String, dynamic> map) {
    return CitiesModel.fromJson(map);
  }
}
