// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_run_history_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserRunHistoryModelImpl _$$UserRunHistoryModelImplFromJson(
        Map<String, dynamic> json) =>
    _$UserRunHistoryModelImpl(
      eventId: json['eventId'] as String,
      eventName: json['eventName'] as String,
      eventNumber: (json['eventNumber'] as num).toInt(),
      eventStartDatetime: DateTime.parse(json['eventStartDatetime'] as String),
      canEditRunAttendence:
          (json['canEditRunAttendence'] as num?)?.toInt() ?? 0,
      hemId: json['hemId'] as String?,
      attendenceState: (json['attendenceState'] as num?)?.toInt() ?? 0,
      isHare: (json['isHare'] as num?)?.toInt() ?? 0,
      creditAmount: (json['creditAmount'] as num?)?.toDouble(),
      debitAmount: (json['debitAmount'] as num?)?.toDouble(),
      creditAvailable: (json['creditAvailable'] as num?)?.toDouble(),
      paymentType: (json['paymentType'] as num?)?.toInt(),
      extrasDescription: json['extrasDescription'] as String?,
      extrasPrice: (json['extrasPrice'] as num?)?.toDouble(),
      doPayForExtras: (json['doPayForExtras'] as num?)?.toInt(),
      totalRunsThisKennel: (json['totalRunsThisKennel'] as num?)?.toInt(),
      totalHaringThisKennel: (json['totalHaringThisKennel'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$UserRunHistoryModelImplToJson(
        _$UserRunHistoryModelImpl instance) =>
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
