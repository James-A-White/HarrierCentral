// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_query_extensions_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PaymentQueryExtensionsModelImpl _$$PaymentQueryExtensionsModelImplFromJson(
        Map<String, dynamic> json) =>
    _$PaymentQueryExtensionsModelImpl(
      pkHemId: json['pkHemId'] as String,
      paidByName: json['paidByName'] as String,
      paidToName: json['paidToName'] as String,
      isMember: json['isMember'] as int? ?? 0,
      creditAvailable: (json['creditAvailable'] as num?)?.toDouble() ?? 0.0,
      eventPriceForMembers:
          (json['eventPriceForMembers'] as num?)?.toDouble() ?? 0.0,
      eventPriceForNonMembers:
          (json['eventPriceForNonMembers'] as num?)?.toDouble() ?? 0.0,
      confByName: json['confByName'] as String?,
      extrasPrice: (json['extrasPrice'] as num?)?.toDouble() ?? 0.0,
      extrasDescription: json['extrasDescription'] as String?,
      discountAmountAvailable:
          (json['discountAmountAvailable'] as num?)?.toDouble() ?? 0.0,
      discountPercentAvailable: json['discountPercentAvailable'] as int? ?? 0,
      isFollowing: json['isFollowing'] as int? ?? 0,
      discountAvailableDescription:
          json['discountAvailableDescription'] as String?,
      isHashCredit: json['isHashCredit'] as bool? ?? false,
    );

Map<String, dynamic> _$$PaymentQueryExtensionsModelImplToJson(
        _$PaymentQueryExtensionsModelImpl instance) =>
    <String, dynamic>{
      'pkHemId': instance.pkHemId,
      'paidByName': instance.paidByName,
      'paidToName': instance.paidToName,
      'isMember': instance.isMember,
      'creditAvailable': instance.creditAvailable,
      'eventPriceForMembers': instance.eventPriceForMembers,
      'eventPriceForNonMembers': instance.eventPriceForNonMembers,
      'confByName': instance.confByName,
      'extrasPrice': instance.extrasPrice,
      'extrasDescription': instance.extrasDescription,
      'discountAmountAvailable': instance.discountAmountAvailable,
      'discountPercentAvailable': instance.discountPercentAvailable,
      'isFollowing': instance.isFollowing,
      'discountAvailableDescription': instance.discountAvailableDescription,
      'isHashCredit': instance.isHashCredit,
    };
