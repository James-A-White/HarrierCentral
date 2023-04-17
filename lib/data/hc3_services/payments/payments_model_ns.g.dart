// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payments_model_ns.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$_PaymentsModel _$$_PaymentsModelFromJson(Map<String, dynamic> json) =>
    _$_PaymentsModel(
      paymentId: json['paymentId'] as String,
      kennelId: json['kennelId'] as String,
      paidBy: json['paidBy'] as String,
      hemId: json['hemId'] as String,
      eventId: json['eventId'] as String,
      paidTo: json['paidTo'] as String,
      creditAmount: (json['creditAmount'] as num).toDouble(),
      debitAmount: (json['debitAmount'] as num).toDouble(),
      creditAvailable: (json['creditAvailable'] as num).toDouble(),
      paidDate: DateTime.parse(json['paidDate'] as String),
      paymentType: json['paymentType'] as int,
      productType: json['productType'] as int,
      cancelledDate: json['cancelledDate'] == null
          ? null
          : DateTime.parse(json['cancelledDate'] as String),
      cancelledBy: json['cancelledBy'] as String?,
      confirmedDate: json['confirmedDate'] == null
          ? null
          : DateTime.parse(json['confirmedDate'] as String),
      confirmedBy: json['confirmedBy'] as String?,
      paymentReference: json['paymentReference'] as String?,
      notes: json['notes'] as String?,
      doPayForExtras: json['doPayForExtras'] as int,
      surcharge: (json['surcharge'] as num).toDouble(),
      paymentProvider: json['paymentProvider'] as String?,
      discountAmount: (json['discountAmount'] as num).toDouble(),
      discountPercent: json['discountPercent'] as int,
      discountDescription: json['discountDescription'] as String,
      specialRunPriceReason: json['specialRunPriceReason'] as String,
      removed: json['removed'] as int?,
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$_PaymentsModelToJson(_$_PaymentsModel instance) =>
    <String, dynamic>{
      'paymentId': instance.paymentId,
      'kennelId': instance.kennelId,
      'paidBy': instance.paidBy,
      'hemId': instance.hemId,
      'eventId': instance.eventId,
      'paidTo': instance.paidTo,
      'creditAmount': instance.creditAmount,
      'debitAmount': instance.debitAmount,
      'creditAvailable': instance.creditAvailable,
      'paidDate': instance.paidDate.toIso8601String(),
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
      'discountAmount': instance.discountAmount,
      'discountPercent': instance.discountPercent,
      'discountDescription': instance.discountDescription,
      'specialRunPriceReason': instance.specialRunPriceReason,
      'removed': instance.removed,
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
