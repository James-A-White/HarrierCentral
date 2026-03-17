// package imports
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'new_hasher_model.freezed.dart';
part 'new_hasher_model.g.dart';

@freezed
abstract class NewHasherModel with _$NewHasherModel {
  factory NewHasherModel({
    String? publicHasherId,
    String? publicKennelId,
    String? hashName,
    String? firstName,
    String? lastName,
    String? eMail,
    String? addHasherStatus,
    @Default(0) int historicTotalRuns,
    @Default(0) int historicHaring,
  }) = _NewHasherModel;

  factory NewHasherModel.fromJson(Map<String, dynamic> json) =>
      _$NewHasherModelFromJson(json);
}
