// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_run_history_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$_UserRunHistoryModel _$$_UserRunHistoryModelFromJson(
        Map<String, dynamic> json) =>
    _$_UserRunHistoryModel(
      eventId: json['eventId'] as String,
      eventName: json['eventName'] as String,
      eventNumber: json['eventNumber'] as int,
      eventStartDatetime: DateTime.parse(json['eventStartDatetime'] as String),
      canEditRunAttendence: json['canEditRunAttendence'] as int? ?? 0,
      hemId: json['hemId'] as String,
      attendenceState: json['attendenceState'] as int? ?? 0,
      isHare: json['isHare'] as int? ?? 0,
      creditAmount: (json['creditAmount'] as num?)?.toDouble(),
      debitAmount: (json['debitAmount'] as num?)?.toDouble(),
      creditAvailable: (json['creditAvailable'] as num?)?.toDouble(),
      paymentType: json['paymentType'] as int?,
      extrasDescription: json['extrasDescription'] as String?,
      extrasPrice: (json['extrasPrice'] as num?)?.toDouble(),
      doPayForExtras: json['doPayForExtras'] as int?,
      totalRunsThisKennel: json['totalRunsThisKennel'] as int?,
      totalHaringThisKennel: json['totalHaringThisKennel'] as int?,
    );

Map<String, dynamic> _$$_UserRunHistoryModelToJson(
        _$_UserRunHistoryModel instance) =>
    <String, dynamic>{
      'eventId': instance.eventId,
      'eventName': instance.eventName,
      'eventNumber': instance.eventNumber,
      'eventStartDatetime': instance.eventStartDatetime.toIso8601String(),
      'canEditRunAttendence': instance.canEditRunAttendence,
      'hemId': instance.hemId,
      'attendenceState': instance.attendenceState,
      'isHare': instance.isHare,
      'creditAmount': instance.creditAmount,
      'debitAmount': instance.debitAmount,
      'creditAvailable': instance.creditAvailable,
      'paymentType': instance.paymentType,
      'extrasDescription': instance.extrasDescription,
      'extrasPrice': instance.extrasPrice,
      'doPayForExtras': instance.doPayForExtras,
      'totalRunsThisKennel': instance.totalRunsThisKennel,
      'totalHaringThisKennel': instance.totalHaringThisKennel,
    };
