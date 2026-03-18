// package imports
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'run_list_model.freezed.dart';
part 'run_list_model.g.dart';

@freezed
abstract class RunListModel with _$RunListModel {
  factory RunListModel({
    required String publicEventId,
    required DateTime eventStartDatetime,
    required String publicKennelId,
    required int isVisible,
    required int isCountedRun,
    required int eventGeographicScope,
    required int eventNumber,
    required String eventName,
    required String kennelShortName,
    required String kennelLogo,
    required int daysUntilEvent,
    required String searchText,
    required String kennelName,
    required String eventCityAndCountry,
    required String resolvableLocation,
    required int eventChatMessageCount,
    required String? locationOneLineDesc,
    String? hares,
    double? syncLat,
    double? syncLong,
    String? eventImage,
    String? extEventImage,
    int? useFbImage,
  }) = _RunListModel;

  factory RunListModel.fromJson(Map<String, dynamic> json) =>
      _$RunListModelFromJson(json);
}
