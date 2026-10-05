// package imports
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'usage_data_integration_monitor.freezed.dart';
part 'usage_data_integration_monitor.g.dart';

@freezed
abstract class UdIntegrationMonitorModel with _$UdIntegrationMonitorModel {
  factory UdIntegrationMonitorModel({
    required int integrationId,
    required int recordsRead,
    required int recordsWritten,
    // required String recordSuccessInfo,
    required String recordsFailedInfo,
    required int errorCount,
    required String errorInfo,
    required int kennelsSucceeded,
    required String kennelsSucceededInfo,
    required int kennelsFailed,
    required String kennelsFailedInfo,
    required String integrationAbbreviation,
    required int integrationEnabled,
    required int interval,
    // required DateTime strtedAt,
    required DateTime endedAt,
    required int minutesAgo,
    required int futureRunCount,
    // Runs page (AI) tile only, integration 6 (2026-10-05): runs it added
    // and runs it refreshed over 14 days, and kennels set to it. Null on
    // the other tiles.
    int? newRuns14d,
    int? updatedRuns14d,
    int? kennelsUsing,
  }) = _UdIntegrationMonitorModel;

  factory UdIntegrationMonitorModel.fromJson(Map<String, dynamic> json) =>
      _$UdIntegrationMonitorModelFromJson(json);
}
