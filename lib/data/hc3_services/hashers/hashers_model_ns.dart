import 'package:harrier_central/imports.dart';

part 'hashers_model_ns.freezed.dart';
part 'hashers_model_ns.g.dart';

@freezed
class HashersModel with _$HashersModel implements BaseModel {
  factory HashersModel({
    required String hasherId,
    String? firstName,
    String? lastName,
    required String dispName,
    String? hashName,
    String? photo,
    required int dispPref,
    required int includeInGlobalHashDirectory,
    int? removed,
    DateTime? updatedAt,
  }) = _HashersModel;

  factory HashersModel.fromJson(Map<String, dynamic> json) => _$HashersModelFromJson(json);

  factory HashersModel.empty() => _$HashersModelFromJson(json.decode('''{
        "hasherId": "$GUID_EMPTY",
        "dispName": "<new hasher>",
        "dispPref": 0,
        "includeInGlobalHashDirectory" : 0,
        "removed": 0,
        "updatedAt": "2000-01-01"}
        '''));
}
