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

  /// Returns how many recipients the email was sent to.
  Future<int> send(
    String publicEventId, {
    required String subject,
    required String body,
    String instruction = '',
    bool saveInstruction = false,
  }) async {
    final Map<String, dynamic> j = await _call(publicEventId, 'send', {
      'subject': subject,
      'body': body,
      'instruction': instruction,
      'saveInstruction': saveInstruction,
    });
    return (j['sent'] as num?)?.toInt() ?? 0;
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
