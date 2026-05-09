import 'package:harrier_central/imports.dart';

part 'user_event_location.freezed.dart';
part 'user_event_location.g.dart';

@freezed
abstract class UserEventLocation with _$UserEventLocation {
  factory UserEventLocation({
    required String ts,
    required double lat,
    required double lng,
    required double acc,
    required double alt,
  }) = _UserEventLocation;

  factory UserEventLocation.fromJson(Map<String, dynamic> json) =>
      _$UserEventLocationFromJson(json);

  @override
  factory UserEventLocation.fromMap(Map<String, dynamic> map) {
    return UserEventLocation.fromJson(map);
  }
}
