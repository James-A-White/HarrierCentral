// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'are_we_at_run_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AreWeAtRunModel _$AreWeAtRunModelFromJson(Map<String, dynamic> json) =>
    _AreWeAtRunModel(
      eventId: json['eventId'] as String,
      eventName: json['eventName'] as String,
      eventImage: json['eventImage'] as String?,
      kennelId: json['kennelId'] as String,
      kennelLogo: json['kennelLogo'] as String,
      kennelShortName: json['kennelShortName'] as String,
      eventNumber: (json['eventNumber'] as num).toInt(),
      distanceInMeters: (json['distanceInMeters'] as num).toDouble(),
      deltaHours: (json['deltaHours'] as num).toDouble(),
      kennelCredit: (json['kennelCredit'] as num?)?.toDouble() ?? 0.0,
      memberPrice: (json['memberPrice'] as num).toDouble(),
      nonMemberPrice: (json['nonMemberPrice'] as num).toDouble(),
      extrasCost: (json['extrasCost'] as num).toDouble(),
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
      discountPercent: (json['discountPercent'] as num?)?.toDouble() ?? 0.0,
      attendenceState: (json['attendenceState'] as num?)?.toInt() ?? 0,
      digitsAfterDecimal: (json['digitsAfterDecimal'] as num?)?.toInt() ?? 2,
      allowSelfPayment: (json['allowSelfPayment'] as num?)?.toInt() ?? 0,
      currencySymbol: json['currencySymbol'] as String? ?? r'$^',
      membershipExpirationDate: DateTime.parse(
        json['membershipExpirationDate'] as String,
      ),
      extrasDescription: json['extrasDescription'] as String?,
    );

Map<String, dynamic> _$AreWeAtRunModelToJson(_AreWeAtRunModel instance) =>
    <String, dynamic>{
      'eventId': instance.eventId,
      'eventName': instance.eventName,
      'eventImage': instance.eventImage,
      'kennelId': instance.kennelId,
      'kennelLogo': instance.kennelLogo,
      'kennelShortName': instance.kennelShortName,
      'eventNumber': instance.eventNumber,
      'distanceInMeters': instance.distanceInMeters,
      'deltaHours': instance.deltaHours,
      'kennelCredit': instance.kennelCredit,
      'memberPrice': instance.memberPrice,
      'nonMemberPrice': instance.nonMemberPrice,
      'extrasCost': instance.extrasCost,
      'discountAmount': instance.discountAmount,
      'discountPercent': instance.discountPercent,
      'attendenceState': instance.attendenceState,
      'digitsAfterDecimal': instance.digitsAfterDecimal,
      'allowSelfPayment': instance.allowSelfPayment,
      'currencySymbol': instance.currencySymbol,
      'membershipExpirationDate': instance.membershipExpirationDate
          .toIso8601String(),
      'extrasDescription': instance.extrasDescription,
    };
