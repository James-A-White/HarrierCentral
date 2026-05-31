import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:hcportal/imports.dart';

class EventDetailsResult {
  EventDetailsResult({
    required this.runDetails,
    required this.participants,
  });

  factory EventDetailsResult.empty() {
    return EventDetailsResult(
      runDetails: RunDetailsModel.empty(),
      participants: [ParticipantModel.empty()],
    );
  }

  final RunDetailsModel runDetails;
  final List<ParticipantModel> participants;
}

Future<EventDetailsResult> querySingleEvent(String publicEventId) async {
  publicEventId = normalizeUuid(publicEventId);
  if (publicEventId.length != 36) {
    return EventDetailsResult.empty();
  }

  final deviceId = box.get(HIVE_DEVICE_ID) as String;
  final deviceSecret = (box.get(HIVE_DEVICE_SECRET) as String?) ?? '';
  final accessToken = Utilities.generateToken(
    deviceId,
    'hcportal_getEvent',
    paramString: '$deviceSecret:$publicEventId',
  );
  final body = <String, dynamic>{
    'queryType': 'getEvent',
    'deviceId': deviceId,
    'accessToken': accessToken,
    'publicEventId': publicEventId,
  };

  final result = await ServiceCommon.sendHttpPostToHC6Api(body);
  if (kDebugMode) debugPrint(result is ApiError
      ? 'SP 8a (a-b) [getEvent] called — FAILED'
      : 'SP 8a (a-b) [getEvent] called — success');
  if (result case ApiSuccess(:final body)) {
    final jsonItems = json.decode(body) as List<dynamic>;

    final rdm = RunDetailsModel.fromJson(
        (jsonItems[0] as List<dynamic>)[0] as Map<String, dynamic>);

    final participants = <ParticipantModel>[];
    for (final record in jsonItems[1] as List<dynamic>) {
      participants.add(ParticipantModel.fromJson(record as Map<String, dynamic>));
    }

    return EventDetailsResult(participants: participants, runDetails: rdm);
  }

  return EventDetailsResult.empty();
}
