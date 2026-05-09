// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'run_history_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RunHistoryModel _$RunHistoryModelFromJson(
  Map<String, dynamic> json,
) => _RunHistoryModel(
  totalRunsThisKennel: (json['totalRunsThisKennel'] as num?)?.toInt() ?? 0,
  totalHaringThisKennel: (json['totalHaringThisKennel'] as num?)?.toInt() ?? 0,
  hcRunsThisKennel: (json['hcRunsThisKennel'] as num?)?.toInt() ?? 0,
  hcHaringThisKennel: (json['hcHaringThisKennel'] as num?)?.toInt() ?? 0,
  kennelName: json['kennelName'] as String,
  kennelShortName: json['kennelShortName'] as String,
  kennelId: json['kennelId'] as String,
  kennelLogo: json['kennelLogo'] as String,
  currencySymbol: json['currencySymbol'] as String? ?? r'$^',
  kennelCredit: (json['kennelCredit'] as num?)?.toDouble() ?? 0.0,
  historicalHaringCount: (json['historicalHaringCount'] as num?)?.toInt() ?? 0,
  historicalTotalRunCount:
      (json['historicalTotalRunCount'] as num?)?.toInt() ?? 0,
  historicalCountIsEstimate:
      (json['historicalCountIsEstimate'] as num?)?.toInt() ?? 0,
  following: (json['following'] as num?)?.toInt() ?? 0,
  digitsAfterDecimal: (json['digitsAfterDecimal'] as num?)?.toInt() ?? 2,
);

Map<String, dynamic> _$RunHistoryModelToJson(_RunHistoryModel instance) =>
    <String, dynamic>{
      'totalRunsThisKennel': instance.totalRunsThisKennel,
      'totalHaringThisKennel': instance.totalHaringThisKennel,
      'hcRunsThisKennel': instance.hcRunsThisKennel,
      'hcHaringThisKennel': instance.hcHaringThisKennel,
      'kennelName': instance.kennelName,
      'kennelShortName': instance.kennelShortName,
      'kennelId': instance.kennelId,
      'kennelLogo': instance.kennelLogo,
      'currencySymbol': instance.currencySymbol,
      'kennelCredit': instance.kennelCredit,
      'historicalHaringCount': instance.historicalHaringCount,
      'historicalTotalRunCount': instance.historicalTotalRunCount,
      'historicalCountIsEstimate': instance.historicalCountIsEstimate,
      'following': instance.following,
      'digitsAfterDecimal': instance.digitsAfterDecimal,
    };
