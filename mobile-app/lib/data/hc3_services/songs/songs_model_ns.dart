import 'package:harrier_central/imports.dart';

part 'songs_model_ns.freezed.dart';
part 'songs_model_ns.g.dart';

@freezed
abstract class SongsModel with _$SongsModel implements BaseModel {
  factory SongsModel({
    required String songId,
    required String songName,
    String? tuneOf,
    required int bawdyRating,
    String? notes,
    String? actions,
    String? variants,
    String? imageUrl,
    String? audioUrl,
    required int autoAddToKennel,
    required int rank,
    String? addedByKennelId,
    String? addedByUserId,
    required String lyrics,
    String? tags,
    int? removed,
    DateTime? updatedAt,
  }) = _SongsModel;

  factory SongsModel.fromJson(Map<String, dynamic> json) =>
      _$SongsModelFromJson(json);
}
