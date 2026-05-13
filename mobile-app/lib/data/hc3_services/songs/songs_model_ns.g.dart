// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'songs_model_ns.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SongsModel _$SongsModelFromJson(Map<String, dynamic> json) => _SongsModel(
  songId: json['songId'] as String,
  songName: json['songName'] as String,
  tuneOf: json['tuneOf'] as String?,
  bawdyRating: (json['bawdyRating'] as num).toInt(),
  notes: json['notes'] as String?,
  actions: json['actions'] as String?,
  variants: json['variants'] as String?,
  imageUrl: json['imageUrl'] as String?,
  audioUrl: json['audioUrl'] as String?,
  autoAddToKennel: (json['autoAddToKennel'] as num).toInt(),
  rank: (json['rank'] as num).toInt(),
  addedByKennelId: json['addedByKennelId'] as String?,
  addedByUserId: json['addedByUserId'] as String?,
  lyrics: json['lyrics'] as String,
  tags: json['tags'] as String?,
  removed: (json['removed'] as num?)?.toInt(),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$SongsModelToJson(_SongsModel instance) =>
    <String, dynamic>{
      'songId': instance.songId,
      'songName': instance.songName,
      'tuneOf': instance.tuneOf,
      'bawdyRating': instance.bawdyRating,
      'notes': instance.notes,
      'actions': instance.actions,
      'variants': instance.variants,
      'imageUrl': instance.imageUrl,
      'audioUrl': instance.audioUrl,
      'autoAddToKennel': instance.autoAddToKennel,
      'rank': instance.rank,
      'addedByKennelId': instance.addedByKennelId,
      'addedByUserId': instance.addedByUserId,
      'lyrics': instance.lyrics,
      'tags': instance.tags,
      'removed': instance.removed,
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
