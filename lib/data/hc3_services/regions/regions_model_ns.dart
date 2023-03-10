import 'package:harrier_central/imports_null_safe.dart';

part 'regions_model_ns.freezed.dart';
part 'regions_model_ns.g.dart';

@freezed
class RegionsModel with _$RegionsModel implements BaseModel {
  factory RegionsModel({
    required String? regionId,
    required String? regionName,
    required String? regionSearchTags,
    required String? regionAbbreviation,
    required String? countryId,
    required String? flagFile,
    required int? removed,
    required DateTime? updatedAt,
  }) = _RegionsModel;

  factory RegionsModel.fromJson(Map<String, dynamic> json) => _$RegionsModelFromJson(json);
}
