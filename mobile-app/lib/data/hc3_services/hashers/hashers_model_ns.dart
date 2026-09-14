import 'package:harrier_central/imports.dart';

part 'hashers_model_ns.freezed.dart';
part 'hashers_model_ns.g.dart';

@freezed
abstract class HashersModel with _$HashersModel implements BaseModel {
  factory HashersModel({
    required String hasherId,
    String? firstName,
    String? lastName,
    required String dispName,
    String? hashName,
    String? photo,
    required int dispPref,
    required int includeInGlobalHashDirectory,
    /// Chat rooms this hasher has turned OFF (E9.F1.S8). Mirrors of the two
    /// grant bitfields on HasherKennelMap — same bit, same meaning — but held
    /// here because a room is global while those fields are per-kennel.
    ///
    /// They store DEVIATIONS, not pins: every room defaults to pinned, so 0
    /// means "all of them pinned" and a set bit means "I turned that one off".
    /// The sync masks these to the calling hasher, so they are 0 on every
    /// other hasher's row.
    int? unpinnedMismanagementRooms,
    int? unpinnedAppAccessRooms,
    int? removed,
    DateTime? updatedAt,
    String? homeKennelId,
  }) = _HashersModel;

  factory HashersModel.fromJson(Map<String, dynamic> json) =>
      _$HashersModelFromJson(json);

  factory HashersModel.empty() => _$HashersModelFromJson(
    json.decode('''{
        "hasherId": "$GUID_EMPTY",
        "dispName": "<new hasher>",
        "dispPref": 0,
        "includeInGlobalHashDirectory" : 0,
        "removed": 0,
        "updatedAt": "2000-01-01"}
        '''),
  );
}
