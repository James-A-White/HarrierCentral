import 'package:harrier_central/imports.dart';

part 'regions_model_ns.freezed.dart';
part 'regions_model_ns.g.dart';

@freezed
abstract class RegionsModel with _$RegionsModel implements BaseModel {
  factory RegionsModel({
    required String regionId,
    required String regionName,
    String? regionSearchTags,
    String? regionAbbreviation,
    required String countryId,
    String? flagFile,
    int? removed,
    DateTime? updatedAt,
  }) = _RegionsModel;

  factory RegionsModel.fromJson(Map<String, dynamic> json) =>
      _$RegionsModelFromJson(json);
}
