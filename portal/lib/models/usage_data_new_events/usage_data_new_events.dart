// package imports
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'usage_data_new_events.freezed.dart';
part 'usage_data_new_events.g.dart';

@freezed
abstract class UdNewEventsModel with _$UdNewEventsModel {
  factory UdNewEventsModel({
    required String kennelName,
    required String kennelShortName,
    required String kennelLogo,
    required String eventName,
    required int minutesAgoUpdated,
    required int minutesAgoCreated,
    required int minutesUntilRun,
    required int activityLastDay,
    required String publicEventId,
    // Added 2026-10-09 for the /<slug>/<number> run link; defaults keep an
    // older SP reply parsing.
    @Default('') String kennelUniqueShortName,
    @Default(0) int eventNumber,
    @Default(0) int isCountedRun,
  }) = _UdNewEventsModel;

  factory UdNewEventsModel.fromJson(Map<String, dynamic> json) =>
      _$UdNewEventsModelFromJson(json);
}
