// ...existing code...
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_positions.freezed.dart';
part 'user_positions.g.dart';

@freezed
abstract class UserPositionsPayload with _$UserPositionsPayload {
  const factory UserPositionsPayload({
    required String eventId,
    String? latestServerTimestampMs,
    required List<UserTrack> users,
  }) = _UserPositionsPayload;

  factory UserPositionsPayload.fromJson(Map<String, dynamic> json) =>
      _$UserPositionsPayloadFromJson(json);
}

@freezed
abstract class UserTrack with _$UserTrack {
  const factory UserTrack({
    required String id,
    required List<TrackPoint> positions,
  }) = _UserTrack;

  factory UserTrack.fromJson(Map<String, dynamic> json) =>
      _$UserTrackFromJson(json);
}

@freezed
abstract class TrackPoint with _$TrackPoint {
  const factory TrackPoint({
    required double lat,
    required double lng,
    required double acc,
    double? alt,
    @JsonKey(name: 'timestampMs') required int timestampMs,
    String? type,
  }) = _TrackPoint;

  factory TrackPoint.fromJson(Map<String, dynamic> json) =>
      _$TrackPointFromJson(json);
}
