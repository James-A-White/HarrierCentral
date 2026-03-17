// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'song_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SongModel _$SongModelFromJson(Map<String, dynamic> json) => _SongModel(
      id: json['id'] as String,
      SongName: json['SongName'] as String,
      TuneOf: json['TuneOf'] as String?,
      BawdyRating: (json['BawdyRating'] as num?)?.toInt(),
      Notes: json['Notes'] as String?,
      Actions: json['Actions'] as String?,
      Variants: json['Variants'] as String?,
      ImageUrl: json['ImageUrl'] as String?,
      AudioUrl: json['AudioUrl'] as String?,
      AutoAddToKennel: (json['AutoAddToKennel'] as num?)?.toInt(),
      Rank: (json['Rank'] as num?)?.toInt(),
      AddedBy_KennelId: json['AddedBy_KennelId'] as String?,
      AddedBy_UserId: json['AddedBy_UserId'] as String?,
      Lyrics: json['Lyrics'] as String?,
      Tags: json['Tags'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      isInKennel: (json['isInKennel'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$SongModelToJson(_SongModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'SongName': instance.SongName,
      'TuneOf': instance.TuneOf,
      'BawdyRating': instance.BawdyRating,
      'Notes': instance.Notes,
      'Actions': instance.Actions,
      'Variants': instance.Variants,
      'ImageUrl': instance.ImageUrl,
      'AudioUrl': instance.AudioUrl,
      'AutoAddToKennel': instance.AutoAddToKennel,
      'Rank': instance.Rank,
      'AddedBy_KennelId': instance.AddedBy_KennelId,
      'AddedBy_UserId': instance.AddedBy_UserId,
      'Lyrics': instance.Lyrics,
      'Tags': instance.Tags,
      'createdAt': instance.createdAt?.toIso8601String(),
      'isInKennel': instance.isInKennel,
    };
