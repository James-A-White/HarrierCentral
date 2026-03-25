// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'participant_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ParticipantModel _$ParticipantModelFromJson(Map<String, dynamic> json) =>
    _ParticipantModel(
      displayName: json['displayName'] as String,
      rsvpState: (json['rsvpState'] as num).toInt(),
      attendanceState: (json['attendanceState'] as num).toInt(),
      isHare: (json['isHare'] as num).toInt(),
      totalRunsThisKennel: (json['totalRunsThisKennel'] as num).toInt(),
      totalHaringThisKennel: (json['totalHaringThisKennel'] as num).toInt(),
      amountPaidStr: json['amountPaidStr'] as String,
      amountOwedStr: json['amountOwedStr'] as String,
      creditAvailableStr: json['creditAvailableStr'] as String,
      virginVisitorType: (json['virginVisitorType'] as num).toInt(),
    );

Map<String, dynamic> _$ParticipantModelToJson(_ParticipantModel instance) =>
    <String, dynamic>{
      'displayName': instance.displayName,
      'rsvpState': instance.rsvpState,
      'attendanceState': instance.attendanceState,
      'isHare': instance.isHare,
      'totalRunsThisKennel': instance.totalRunsThisKennel,
      'totalHaringThisKennel': instance.totalHaringThisKennel,
      'amountPaidStr': instance.amountPaidStr,
      'amountOwedStr': instance.amountOwedStr,
      'creditAvailableStr': instance.creditAvailableStr,
      'virginVisitorType': instance.virginVisitorType,
    };
