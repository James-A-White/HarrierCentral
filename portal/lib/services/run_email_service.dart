import 'package:hcportal/imports.dart';
import 'package:http/http.dart' as http;

/// What the API knows about a run's email before anything is written: the
/// kennel's saved instruction, how many members would receive it, and
/// whether one has already gone out.
class RunEmailContext {
  const RunEmailContext({
    required this.title,
    required this.when,
    required this.where,
    required this.recipientCount,
    required this.emailSendCount,
    this.emailLastSentAt,
    this.emailLastSentCount,
    this.instruction = '',
  });

  final String title;
  final String when;
  final String where;
  final int recipientCount;
  final int emailSendCount;
  final DateTime? emailLastSentAt;
  final int? emailLastSentCount;
  final String instruction;

  bool get alreadySent => emailSendCount > 0;

  factory RunEmailContext.fromJson(Map<String, dynamic> j) => RunEmailContext(
        title: (j['title'] ?? '') as String,
        when: (j['when'] ?? '') as String,
        where: (j['where'] ?? '') as String,
        recipientCount: (j['recipientCount'] as num?)?.toInt() ?? 0,
        emailSendCount: (j['emailSendCount'] as num?)?.toInt() ?? 0,
        emailLastSentAt: j['emailLastSentAt'] == null
            ? null
            : DateTime.tryParse(j['emailLastSentAt'] as String)?.toLocal(),
        emailLastSentCount: (j['emailLastSentCount'] as num?)?.toInt(),
        instruction: (j['instruction'] ?? '') as String,
      );
}

/// One kennel member on "Who gets it", with why they are in that list and
/// whether an admin may move them for one send. reasonCode — gets it: 1 on for
/// this run, 2 on for the kennel, 9 member, 10 follower, 11 RSVP'd; not:
/// 3 run emails off, 4 kennel emails off, 5 not a member, follower or RSVP,
/// 6 no email address, 7 blocked all emails, 8 email bouncing.
/// emailStatus: 0 Unknown, 1 OK, 2 Suspect, 3 Bounced.
class RunEmailAudienceEntry {
  const RunEmailAudienceEntry({
    required this.hasherId,
    required this.name,
    this.mortalName = '',
    this.email = '',
    this.photo = '',
    this.reason = '',
    this.reasonCode = 0,
    this.emailStatus = 0,
    this.canMove = false,
  });

  final String hasherId;
  final String name;
  final String mortalName;

  /// The address, only when the caller is a kennel admin / hare raiser;
  /// empty for a hare who may edit just this run (the API leaves it out).
  final String email;
  final String photo;
  final String reason;
  final int reasonCode;
  final int emailStatus;
  final bool canMove;

  bool get isBlocked => reasonCode == 7;
  bool get isBouncing => reasonCode == 8 || emailStatus == 3;
  bool get isSuspect => emailStatus == 2;
  String get searchText => '$name $mortalName $email'.toLowerCase();

  factory RunEmailAudienceEntry.fromJson(Map<String, dynamic> e) =>
      RunEmailAudienceEntry(
        hasherId: normalizeUuid((e['hasherId'] ?? '') as String),
        name: (e['name'] ?? '') as String,
        mortalName: (e['mortalName'] ?? '') as String,
        email: (e['email'] ?? '') as String,
        photo: (e['photo'] ?? '') as String,
        reason: (e['reason'] ?? '') as String,
        reasonCode: (e['reasonCode'] as num?)?.toInt() ?? 0,
        emailStatus: (e['emailStatus'] as num?)?.toInt() ?? 0,
        canMove: e['canMove'] == true,
      );
}

class RunEmailAudience {
  const RunEmailAudience({required this.recipients, required this.nonRecipients});
  final List<RunEmailAudienceEntry> recipients;
  final List<RunEmailAudienceEntry> nonRecipients;
}

class RunEmailDraft {
  const RunEmailDraft({required this.subject, required this.body});
  final String subject;
  final String body;
}

class RunEmailException implements Exception {
  const RunEmailException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// The portal's calls behind "Email members" on a run (E9.F6.S6–S9): the
/// same RunEmail API endpoint the app uses, told `client = 'portal'` so the
/// token is checked by hcportal_getRunEmailContext (which gates on "may
/// edit runs for this kennel"). The send list is built in ONE stored
/// procedure shared with the app.
class RunEmailService {
  const RunEmailService();

  Future<RunEmailContext> context(String publicEventId) async =>
      RunEmailContext.fromJson(await _call(publicEventId, 'context'));

  Future<RunEmailDraft> draft(String publicEventId,
      {String instruction = ''}) async {
    final Map<String, dynamic> j =
        await _call(publicEventId, 'draft', {'instruction': instruction});
    return RunEmailDraft(
      subject: (j['subject'] ?? '') as String,
      body: (j['body'] ?? '') as String,
    );
  }

  /// Who will get the email and which kennel members will not, with why.
  Future<RunEmailAudience> audience(String publicEventId) async {
    final Map<String, dynamic> j = await _call(publicEventId, 'audience');
    List<RunEmailAudienceEntry> parse(dynamic list) =>
        ((list as List<dynamic>?) ?? const <dynamic>[])
            .map((dynamic e) =>
                RunEmailAudienceEntry.fromJson(e as Map<String, dynamic>))
            .toList();
    return RunEmailAudience(
      recipients: parse(j['recipients']),
      nonRecipients: parse(j['nonRecipients']),
    );
  }

  /// Returns how many recipients the email was sent to. With [previewToSelf]
  /// the finished email goes to the sender only and nothing is recorded.
  Future<int> send(
    String publicEventId, {
    required String subject,
    required String body,
    String instruction = '',
    bool saveInstruction = false,
    bool previewToSelf = false,
    Iterable<String> includeHasherIds = const <String>[],
    Iterable<String> excludeHasherIds = const <String>[],
  }) async {
    final Map<String, dynamic> j = await _call(publicEventId, 'send', {
      'subject': subject,
      'body': body,
      'instruction': instruction,
      'saveInstruction': saveInstruction,
      'previewToSelf': previewToSelf,
      'includeHasherIds': includeHasherIds.toList(),
      'excludeHasherIds': excludeHasherIds.toList(),
    });
    return (j['sent'] as num?)?.toInt() ?? 0;
  }

  /// Clears a hasher's bounced email status for this run's audience
  /// (E19.F4.S5, hcportal_clearEmailBounce — parity with the app).
  Future<void> clearBounce(String publicEventId, String hasherId) async {
    final box = Hive.box(HIVE_NAME);
    final String deviceId = (box.get(HIVE_DEVICE_ID) as String?) ?? '';
    final String deviceSecret = (box.get(HIVE_DEVICE_SECRET) as String?) ?? '';
    if (deviceId.isEmpty || deviceSecret.isEmpty) {
      throw const RunEmailException('You are not signed in.');
    }
    http.Response response;
    try {
      response = await http
          .post(
            Uri.parse(BASE_HC6_API_URL),
            headers: {'content-type': 'application/json'},
            body: jsonEncode({
              'queryType': 'clearEmailBounce',
              'deviceId': deviceId,
              'accessToken': Utilities.generateToken(
                deviceId,
                'hcportal_clearEmailBounce',
                paramString: deviceSecret,
              ),
              'publicEventId': publicEventId,
              'hasherId': hasherId,
            }),
          )
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw const RunEmailException(
        'No connection to Harrier Central. Check your connection and try again.',
      );
    }
    Map<String, dynamic>? row;
    try {
      final dynamic j = jsonDecode(response.body);
      if (j is List && j.isNotEmpty && j[0] is List && (j[0] as List).isNotEmpty) {
        row = (j[0] as List)[0] as Map<String, dynamic>;
      }
    } catch (_) {}
    if (response.statusCode != 200 || row == null || row['Success'] != 1) {
      throw RunEmailException((row?['ErrorMessage'] as String?) ??
          'The bounce could not be cleared just now (${response.statusCode}).');
    }
  }

  Future<Map<String, dynamic>> _call(
    String publicEventId,
    String action, [
    Map<String, Object> extra = const {},
  ]) async {
    final box = Hive.box(HIVE_NAME);
    final String deviceId = (box.get(HIVE_DEVICE_ID) as String?) ?? '';
    final String deviceSecret = (box.get(HIVE_DEVICE_SECRET) as String?) ?? '';
    if (deviceId.isEmpty || deviceSecret.isEmpty) {
      throw const RunEmailException('You are not signed in.');
    }
    final String accessToken = Utilities.generateToken(
      deviceId,
      'hcportal_getRunEmailContext',
      paramString: deviceSecret,
    );

    http.Response response;
    try {
      response = await http
          .post(
            Uri.parse(BASE_RUN_EMAIL_URL),
            headers: {'content-type': 'application/json'},
            body: jsonEncode({
              'client': 'portal',
              'deviceId': deviceId,
              'accessToken': accessToken,
              'publicEventId': publicEventId,
              'action': action,
              ...extra,
            }),
          )
          // A draft waits on the model; 60 s is generous but not forever.
          .timeout(const Duration(seconds: 60));
    } catch (_) {
      throw const RunEmailException(
        'No connection to Harrier Central. Check your connection and try again.',
      );
    }

    Map<String, dynamic> j;
    try {
      j = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      j = {};
    }
    if (response.statusCode != 200) {
      throw RunEmailException((j['errorUserMessage'] as String?) ??
          'Harrier Central could not do that just now (${response.statusCode}).');
    }
    return j;
  }
}
