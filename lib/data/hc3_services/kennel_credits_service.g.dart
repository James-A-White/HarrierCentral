// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kennel_credits_service.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KennelCreditsModel _$KennelCreditsModelFromJson(Map<String, dynamic> json) {
  return KennelCreditsModel(
    kennelCreditId: json['kennelCreditId'] as String,
    userId: json['userId'] as String,
    kennelId: json['kennelId'] as String,
    currentBalance: json['currentBalance'] as num,
    balanceAsOfEventId: json['balanceAsOfEventId'] as String,
    updatedAt: json['updatedAt'] == null
        ? null
        : DateTime.parse(json['updatedAt'] as String),
    removed: json['removed'] as int,
  );
}

Map<String, dynamic> _$KennelCreditsModelToJson(KennelCreditsModel instance) =>
    <String, dynamic>{
      'kennelCreditId': instance.kennelCreditId,
      'userId': instance.userId,
      'kennelId': instance.kennelId,
      'currentBalance': instance.currentBalance,
      'balanceAsOfEventId': instance.balanceAsOfEventId,
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'removed': instance.removed,
    };
