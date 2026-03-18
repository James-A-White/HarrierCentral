// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hasher_kennels_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HasherKennelsModel _$HasherKennelsModelFromJson(Map<String, dynamic> json) =>
    _HasherKennelsModel(
      publicKennelId: json['publicKennelId'] as String,
      kennelName: json['kennelName'] as String,
      kennelShortName: json['kennelShortName'] as String,
      kennelUniqueShortName: json['kennelUniqueShortName'] as String,
      kennelLogo: json['kennelLogo'] as String,
      kennelCountryCodes: json['kennelCountryCodes'] as String,
      countryId: json['countryId'] as String,
      countryName: json['countryName'] as String,
      isFollowing: (json['isFollowing'] as num).toInt(),
      isMember: (json['isMember'] as num).toInt(),
      isHomeKennel: (json['isHomeKennel'] as num).toInt(),
      appAccessFlags: (json['appAccessFlags'] as num).toInt(),
      defaultTags1: (json['defaultTags1'] as num).toInt(),
      defaultTags2: (json['defaultTags2'] as num).toInt(),
      defaultTags3: (json['defaultTags3'] as num).toInt(),
      defaultDigitsAfterDecimal:
          (json['defaultDigitsAfterDecimal'] as num).toInt(),
      defaultCurrencySymbol: json['defaultCurrencySymbol'] as String,
      defaultRunStartTime:
          DateTime.parse(json['defaultRunStartTime'] as String),
      cityLat: (json['cityLat'] as num).toDouble(),
      cityLon: (json['cityLon'] as num).toDouble(),
      defaultEventPriceForMembers:
          (json['defaultEventPriceForMembers'] as num).toDouble(),
      defaultEventPriceForNonMembers:
          (json['defaultEventPriceForNonMembers'] as num).toDouble(),
      cityName: json['cityName'] as String?,
      regionName: json['regionName'] as String?,
      continentName: json['continentName'] as String?,
      membershipExpirationDate: json['membershipExpirationDate'] == null
          ? null
          : DateTime.parse(json['membershipExpirationDate'] as String),
      kennelLat: (json['kennelLat'] as num?)?.toDouble(),
      kennelLon: (json['kennelLon'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$HasherKennelsModelToJson(_HasherKennelsModel instance) =>
    <String, dynamic>{
      'publicKennelId': instance.publicKennelId,
      'kennelName': instance.kennelName,
      'kennelShortName': instance.kennelShortName,
      'kennelUniqueShortName': instance.kennelUniqueShortName,
      'kennelLogo': instance.kennelLogo,
      'kennelCountryCodes': instance.kennelCountryCodes,
      'countryId': instance.countryId,
      'countryName': instance.countryName,
      'isFollowing': instance.isFollowing,
      'isMember': instance.isMember,
      'isHomeKennel': instance.isHomeKennel,
      'appAccessFlags': instance.appAccessFlags,
      'defaultTags1': instance.defaultTags1,
      'defaultTags2': instance.defaultTags2,
      'defaultTags3': instance.defaultTags3,
      'defaultDigitsAfterDecimal': instance.defaultDigitsAfterDecimal,
      'defaultCurrencySymbol': instance.defaultCurrencySymbol,
      'defaultRunStartTime': instance.defaultRunStartTime.toIso8601String(),
      'cityLat': instance.cityLat,
      'cityLon': instance.cityLon,
      'defaultEventPriceForMembers': instance.defaultEventPriceForMembers,
      'defaultEventPriceForNonMembers': instance.defaultEventPriceForNonMembers,
      'cityName': instance.cityName,
      'regionName': instance.regionName,
      'continentName': instance.continentName,
      'membershipExpirationDate':
          instance.membershipExpirationDate?.toIso8601String(),
      'kennelLat': instance.kennelLat,
      'kennelLon': instance.kennelLon,
    };
