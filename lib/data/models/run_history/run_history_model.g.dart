// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'run_history_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$_RunHistoryModel _$$_RunHistoryModelFromJson(Map<String, dynamic> json) =>
    _$_RunHistoryModel(
      totalRunsThisKennel: json['totalRunsThisKennel'] as int,
      totalHaringThisKennel: json['totalHaringThisKennel'] as int,
      hcRunsThisKennel: json['hcRunsThisKennel'] as int,
      hcHaringThisKennel: json['hcHaringThisKennel'] as int,
      kennelName: json['kennelName'] as String,
      kennelShortName: json['kennelShortName'] as String,
      kennelId: json['kennelId'] as String,
      kennelLogo: json['kennelLogo'] as String,
      currencySymbol: json['currencySymbol'] as String,
      kennelCredit: (json['kennelCredit'] as num).toDouble(),
      historicalHaringCount: json['historicalHaringCount'] as int,
      historicalTotalRunCount: json['historicalTotalRunCount'] as int,
      historicalCountIsEstimate: json['historicalCountIsEstimate'] as int,
      following: json['following'] as int,
      digitsAfterDecimal: json['digitsAfterDecimal'] as int,
    );

Map<String, dynamic> _$$_RunHistoryModelToJson(_$_RunHistoryModel instance) =>
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
