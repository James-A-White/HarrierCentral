import 'package:http/http.dart' as http;
import 'package:harrier_central/imports.dart';

/// What the API knows about a run's email before anything is written: how
/// many members would receive it, and whether one has already gone out.
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

  /// The kennel's saved drafting instruction ("write it in French"),
  /// pre-filled for every sender; '' when none.
  final String instruction;

  final String title;
  final String when;
  final String where;
  final int recipientCount;
  final int emailSendCount;
  final DateTime? emailLastSentAt;
  final int? emailLastSentCount;

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

/// A drafted email: the model's subject and prose. The facts block (date,
/// venue, hares, price, the app and RSVP links) is added by the server at
/// send time and is never part of what the sender edits.
class RunEmailDraft {
  const RunEmailDraft({required this.subject, required this.body});
  final String subject;
  final String body;
}

/// Thrown when the API refused or could not be reached; [message] is for
/// the sender to read.
class RunEmailException implements Exception {
  const RunEmailException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// The three calls behind Save and send → Email (E9.F6.S6–S9), all to the
/// RunEmail API endpoint with the app's own device token. The endpoint runs
/// hcapp_getRunEmailContext, which gates on "may edit runs for this kennel"
/// and builds the send list by the email-alert rule.
class RunEmailService {
  const RunEmailService();

  Future<RunEmailContext> context(HcId eventId) async {
    final Map<String, dynamic> j = await _call(eventId, 'context');
    return RunEmailContext.fromJson(j);
  }

  Future<RunEmailDraft> draft(HcId eventId, {String instruction = ''}) async {
    final Map<String, dynamic> j = await _call(eventId, 'draft', <String, String>{
      'instruction': instruction,
    });
    return RunEmailDraft(
      subject: (j['subject'] ?? '') as String,
      body: (j['body'] ?? '') as String,
    );
  }

  /// Returns how many recipients the email was sent to.
  Future<int> send(
    HcId eventId, {
    required String subject,
    required String body,
    String instruction = '',
    bool saveInstruction = false,
  }) async {
    final Map<String, dynamic> j = await _call(eventId, 'send', <String, Object>{
      'subject': subject,
      'body': body,
      'instruction': instruction,
      'saveInstruction': saveInstruction,
    });
    return (j['sent'] as num?)?.toInt() ?? 0;
  }

  Future<Map<String, dynamic>> _call(
    HcId eventId,
    String action, [
    Map<String, Object> extra = const <String, Object>{},
  ]) async {
    final String? deviceId = getStringPref(StringPrefsEnum.deviceId);
    final String? deviceSecret = getStringPref(StringPrefsEnum.deviceSecret);
    final String? userId = getStringPref(StringPrefsEnum.userId);
    if ((userId ?? '').isEmpty ||
        (deviceId ?? '').isEmpty ||
        (deviceSecret ?? '').isEmpty) {
      throw const RunEmailException('You are not signed in.');
    }
    final String accessToken = Utilities.generateToken(
      userId!,
      'hcapp_getRunEmailContext',
      paramString: deviceSecret!,
    );
    final String payload = jsonEncode(<String, Object>{
      'deviceId': deviceId!,
      'accessToken': accessToken,
      'eventId': eventId,
      'action': action,
      ...extra,
    });

    http.Response response;
    try {
      response = await http
          .post(
            Uri.parse(RUN_EMAIL_API_URL),
            headers: <String, String>{'content-type': 'application/json'},
            body: payload,
          )
          // A draft waits on the model; 60 s is generous but not forever.
          .timeout(const Duration(seconds: 60));
    } catch (e) {
      BootLogger.logBreadcrumb('[RunEmail.$action] transport: $e');
      throw const RunEmailException(
        'No connection to Harrier Central. Check your signal and try again.',
      );
    }

    Map<String, dynamic> j;
    try {
      j = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      j = <String, dynamic>{};
    }
    if (response.statusCode != 200) {
      final String msg =
          (j['errorUserMessage'] as String?) ??
          'Harrier Central could not do that just now (${response.statusCode}).';
      BootLogger.logBreadcrumb(
        '[RunEmail.$action] ${response.statusCode}: $msg',
      );
      throw RunEmailException(msg);
    }
    return j;
  }
}
