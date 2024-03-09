// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'check_in_pack_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CheckInPackModelImpl _$$CheckInPackModelImplFromJson(
        Map<String, dynamic> json) =>
    _$CheckInPackModelImpl(
      hasherId: json['hasherId'] as String,
      hemId: json['hemId'] as String,
      isMember: json['isMember'] as int? ?? 0,
      isHare: json['isHare'] as int? ?? 0,
      isPaid: json['isPaid'] as int? ?? 0,
      nameForDisplay: json['nameForDisplay'] as String? ?? '',
      nameForSort: json['nameForSort'] as String? ?? '',
      paymentType: json['paymentType'] as int? ?? 0,
      creditAmount: (json['creditAmount'] as num?)?.toDouble() ?? 0.0,
      photo: json['photo'] as String? ?? '',
      virginVisitorType: json['virginVisitorType'] as int? ?? 0,
      rsvpState: json['rsvpState'] as int? ?? 0,
      attendenceState: json['attendenceState'] as int? ?? 0,
      discountPercent: json['discountPercent'] as int? ?? 0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
      hcTotalRunCount: json['hcTotalRunCount'] as int? ?? 0,
      hcHaringCount: json['hcHaringCount'] as int? ?? 0,
      historicalTotalRunCount: json['historicalTotalRunCount'] as int? ?? 0,
      historicalHaringCount: json['historicalHaringCount'] as int? ?? 0,
      historicalCountIsEstimate: json['historicalCountIsEstimate'] as int? ?? 0,
      totalRunsThisKennel: json['totalRunsThisKennel'] as int? ?? 0,
      totalHaringThisKennel: json['totalHaringThisKennel'] as int? ?? 0,
      hemUpdatedAt: json['hemUpdatedAt'] as String,
      payUpdatedAt: json['payUpdatedAt'] as String,
      credit: (json['credit'] as num?)?.toDouble() ?? 0.0,
      isFollowing: json['isFollowing'] as int? ?? 0,
    );

Map<String, dynamic> _$$CheckInPackModelImplToJson(
        _$CheckInPackModelImpl instance) =>
    <String, dynamic>{
      'hasherId': instance.hasherId,
      'hemId': instance.hemId,
      'isMember': instance.isMember,
      'isHare': instance.isHare,
      'isPaid': instance.isPaid,
      'nameForDisplay': instance.nameForDisplay,
      'nameForSort': instance.nameForSort,
      'paymentType': instance.paymentType,
      'creditAmount': instance.creditAmount,
      'photo': instance.photo,
      'virginVisitorType': instance.virginVisitorType,
      'rsvpState': instance.rsvpState,
      'attendenceState': instance.attendenceState,
      'discountPercent': instance.discountPercent,
      'discountAmount': instance.discountAmount,
      'hcTotalRunCount': instance.hcTotalRunCount,
      'hcHaringCount': instance.hcHaringCount,
      'historicalTotalRunCount': instance.historicalTotalRunCount,
      'historicalHaringCount': instance.historicalHaringCount,
      'historicalCountIsEstimate': instance.historicalCountIsEstimate,
      'totalRunsThisKennel': instance.totalRunsThisKennel,
      'totalHaringThisKennel': instance.totalHaringThisKennel,
      'hemUpdatedAt': instance.hemUpdatedAt,
      'payUpdatedAt': instance.payUpdatedAt,
      'credit': instance.credit,
      'isFollowing': instance.isFollowing,
    };
