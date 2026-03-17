// package imports
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'usage_category_detail.freezed.dart';
part 'usage_category_detail.g.dart';

@freezed
abstract class UdCategoryDetailModel with _$UdCategoryDetailModel {
  factory UdCategoryDetailModel({
    required DateTime? dateOfActivity,
    required String? message,
  }) = _UdCategoryDetailModel;

  factory UdCategoryDetailModel.fromJson(Map<String, dynamic> json) =>
      _$UdCategoryDetailModelFromJson(json);
}
