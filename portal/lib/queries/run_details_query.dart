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
  if (publicEventId.length != 36) {
    return EventDetailsResult.empty();
  }

  final publicHasherId = await box.get(HIVE_HASHER_ID) as String;
  final accessToken = Utilities.generateToken(
    publicHasherId,
    'hcportal_getEvent',
    paramString: publicEventId,
  );
  final body = <String, String>{
    'queryType': 'getEvent',
    'publicHasherId': publicHasherId,
    'accessToken': accessToken,
    'publicEventId': publicEventId,
  };

  final jsonResult = await ServiceCommon.sendHttpPostToAzureFunctionApi(body);
  if (jsonResult.length > 10) {
    final jsonItems = json.decode(jsonResult) as List<dynamic>;

    // Parse the run details from the first result set
    final rdm = RunDetailsModel.fromJson(
        (jsonItems[0] as List<dynamic>)[0] as Map<String, dynamic>);

    // Parse the participants from the second result set
    final participants = <ParticipantModel>[];
    final participantRecords = (jsonItems[1] as List<dynamic>);

    for (final record in participantRecords) {
      participants.add(
        ParticipantModel.fromJson(
          record as Map<String, dynamic>,
        ),
      );
    }

    return EventDetailsResult(participants: participants, runDetails: rdm);
  }

  return EventDetailsResult.empty();
}
