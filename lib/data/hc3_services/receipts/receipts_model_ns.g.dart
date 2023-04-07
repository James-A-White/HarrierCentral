// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipts_model_ns.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$_ReceiptsModel _$$_ReceiptsModelFromJson(Map<String, dynamic> json) =>
    _$_ReceiptsModel(
      receiptId: json['receiptId'] as String,
      eventId: json['eventId'] as String,
      userId: json['userId'] as String,
      receiptAmount: (json['receiptAmount'] as num?)?.toDouble() ?? 0.0,
      costCategory: json['costCategory'] as int? ?? 0,
      dateUploaded: json['dateUploaded'] == null
          ? null
          : DateTime.parse(json['dateUploaded'] as String),
      imageUrl: json['imageUrl'] as String?,
      receiptShortDescription: json['receiptShortDescription'] as String?,
      notes: json['notes'] as String?,
      reimbursedBy: json['reimbursedBy'] as String?,
      reimbursedOn: json['reimbursedOn'] as String?,
      reimbursedAmount: (json['reimbursedAmount'] as num?)?.toDouble(),
      reimbursedNotes: json['reimbursedNotes'] as String?,
      removed: json['removed'] as int?,
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$_ReceiptsModelToJson(_$_ReceiptsModel instance) =>
    <String, dynamic>{
      'receiptId': instance.receiptId,
      'eventId': instance.eventId,
      'userId': instance.userId,
      'receiptAmount': instance.receiptAmount,
      'costCategory': instance.costCategory,
      'dateUploaded': instance.dateUploaded?.toIso8601String(),
      'imageUrl': instance.imageUrl,
      'receiptShortDescription': instance.receiptShortDescription,
      'notes': instance.notes,
      'reimbursedBy': instance.reimbursedBy,
      'reimbursedOn': instance.reimbursedOn,
      'reimbursedAmount': instance.reimbursedAmount,
      'reimbursedNotes': instance.reimbursedNotes,
      'removed': instance.removed,
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
