// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'usage_category_detail.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UdCategoryDetailModel _$UdCategoryDetailModelFromJson(
        Map<String, dynamic> json) =>
    _UdCategoryDetailModel(
      dateOfActivity: json['dateOfActivity'] == null
          ? null
          : DateTime.parse(json['dateOfActivity'] as String),
      message: json['message'] as String?,
    );

Map<String, dynamic> _$UdCategoryDetailModelToJson(
        _UdCategoryDetailModel instance) =>
    <String, dynamic>{
      'dateOfActivity': instance.dateOfActivity?.toIso8601String(),
      'message': instance.message,
    };
