import 'package:harrier_central/imports_null_safe.dart';

part 'leaderboard_model.freezed.dart';
part 'leaderboard_model.g.dart';

@freezed
class LeaderboardModel with _$LeaderboardModel implements BaseModel {
  factory LeaderboardModel({
    required String displayName,
    required int totalRunCount,
    required int totalHaringCount,
    required int ytdTotalRunCount,
    required int ytdHaringCount,
    required int rollingYearTotalRunCount,
    required int rollingYearHaringCount,
    required String kennelId,
    String? homeKennelId,
    required String hasherId,
    required int kennelCountTotal,
    required int kennelCountYtd,
    required int kennelCountRollingYear,
    String? searchText,
  }) = _LeaderboardModel;

  factory LeaderboardModel.fromJson(Map<String, dynamic> json) => _$LeaderboardModelFromJson(json);

  @override
  factory LeaderboardModel.fromMap(Map<String, dynamic> map) {
    return LeaderboardModel.fromJson(map);
  }
}
