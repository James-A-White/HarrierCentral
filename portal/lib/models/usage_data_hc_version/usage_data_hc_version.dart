// package imports
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'usage_data_hc_version.freezed.dart';
part 'usage_data_hc_version.g.dart';

@freezed
abstract class UdHcVersion with _$UdHcVersion {
  factory UdHcVersion({
    required String versionNum,
    required String buildNum,
    required int isiPhone,
    required int isNotiPhone,
  }) = _UdHcVersion;

  factory UdHcVersion.fromJson(Map<String, dynamic> json) =>
      _$UdHcVersionFromJson(json);
}
