import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'song_model.freezed.dart';
part 'song_model.g.dart';

@freezed
abstract class SongModel with _$SongModel {
  factory SongModel({
    required String id,
    required String SongName,
    String? TuneOf,
    int? BawdyRating,
    String? Notes,
    String? Actions,
    String? Variants,
    String? ImageUrl,
    String? AudioUrl,
    int? AutoAddToKennel,
    int? Rank,
    String? AddedBy_KennelId,
    String? AddedBy_UserId,
    String? Lyrics,
    String? Tags,
    DateTime? createdAt,
    @Default(0) int isInKennel,
  }) = _SongModel;

  factory SongModel.empty() => SongModel(
        id: '',
        SongName: '',
      );

  factory SongModel.fromJson(Map<String, dynamic> json) =>
      _$SongModelFromJson(json);
}
