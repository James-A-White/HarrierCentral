// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'run_history_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RunHistoryModelImpl _$$RunHistoryModelImplFromJson(
        Map<String, dynamic> json) =>
    _$RunHistoryModelImpl(
      totalRunsThisKennel: json['totalRunsThisKennel'] as int? ?? 0,
      totalHaringThisKennel: json['totalHaringThisKennel'] as int? ?? 0,
      hcRunsThisKennel: json['hcRunsThisKennel'] as int? ?? 0,
      hcHaringThisKennel: json['hcHaringThisKennel'] as int? ?? 0,
      kennelName: json['kennelName'] as String,
      kennelShortName: json['kennelShortName'] as String,
      kennelId: json['kennelId'] as String,
      kennelLogo: json['kennelLogo'] as String,
      currencySymbol: json['currencySymbol'] as String? ?? r'$^',
      kennelCredit: (json['kennelCredit'] as num?)?.toDouble() ?? 0.0,
      historicalHaringCount: json['historicalHaringCount'] as int? ?? 0,
      historicalTotalRunCount: json['historicalTotalRunCount'] as int? ?? 0,
      historicalCountIsEstimate: json['historicalCountIsEstimate'] as int? ?? 0,
      following: json['following'] as int? ?? 0,
      digitsAfterDecimal: json['digitsAfterDecimal'] as int? ?? 2,
    );

Map<String, dynamic> _$$RunHistoryModelImplToJson(
        _$RunHistoryModelImpl instance) =>
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
