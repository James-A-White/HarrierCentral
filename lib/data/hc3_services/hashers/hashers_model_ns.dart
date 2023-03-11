import 'package:harrier_central/imports_null_safe.dart';

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
    required int removed,
    required DateTime updatedAt,
  }) = _HashersModel;

  factory HashersModel.fromJson(Map<String, dynamic> json) => _$HashersModelFromJson(json);
}
