// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payments_service.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentsModel _$PaymentsModelFromJson(Map<String, dynamic> json) {
  return PaymentsModel(
    paymentId: json['paymentId'] as String,
    kennelId: json['kennelId'] as String,
    paidBy: json['paidBy'] as String,
    hemId: json['hemId'] as String,
    eventId: json['eventId'] as String,
    paidTo: json['paidTo'] as String,
    creditAmount: json['creditAmount'] as num,
    debitAmount: json['debitAmount'] as num,
    paidDate: json['paidDate'] == null
        ? null
        : DateTime.parse(json['paidDate'] as String),
    paymentType: json['paymentType'] as int,
    productType: json['productType'] as int,
    cancelledDate: json['cancelledDate'] == null
        ? null
        : DateTime.parse(json['cancelledDate'] as String),
    cancelledBy: json['cancelledBy'] as String,
    confirmedDate: json['confirmedDate'] == null
        ? null
        : DateTime.parse(json['confirmedDate'] as String),
    confirmedBy: json['confirmedBy'] as String,
    paymentReference: json['paymentReference'] as String,
    notes: json['notes'] as String,
    doPayForExtras: json['doPayForExtras'] as int,
    surcharge: json['surcharge'] as num,
    paymentProvider: json['paymentProvider'] as String,
    removed: json['removed'] as int,
    updatedAt: json['updatedAt'] == null
        ? null
        : DateTime.parse(json['updatedAt'] as String),
  );
}

Map<String, dynamic> _$PaymentsModelToJson(PaymentsModel instance) =>
    <String, dynamic>{
      'paymentId': instance.paymentId,
      'kennelId': instance.kennelId,
      'paidBy': instance.paidBy,
      'hemId': instance.hemId,
      'eventId': instance.eventId,
      'paidTo': instance.paidTo,
      'creditAmount': instance.creditAmount,
      'debitAmount': instance.debitAmount,
      'paidDate': instance.paidDate?.toIso8601String(),
      'paymentType': instance.paymentType,
      'productType': instance.productType,
      'cancelledDate': instance.cancelledDate?.toIso8601String(),
      'cancelledBy': instance.cancelledBy,
      'confirmedDate': instance.confirmedDate?.toIso8601String(),
      'confirmedBy': instance.confirmedBy,
      'paymentReference': instance.paymentReference,
      'notes': instance.notes,
      'doPayForExtras': instance.doPayForExtras,
      'surcharge': instance.surcharge,
      'paymentProvider': instance.paymentProvider,
      'removed': instance.removed,
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
