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

/// One kennel member on "Who gets it", as the check-in roster shows them,
/// with why they are in that list and whether an admin may move them for
/// one send. reasonCode: 1 on for this run, 2 on for the kennel, 3 run
/// emails off, 4 kennel emails off, 5 never switched on, 6 no email
/// address, 7 blocked all emails, 8 email bouncing. emailStatus: 0 Unknown,
/// 1 OK, 2 Suspect, 3 Bounced.
class RunEmailAudienceEntry {
  const RunEmailAudienceEntry({
    required this.hasherId,
    required this.name,
    this.mortalName = '',
    this.photo = '',
    this.reason = '',
    this.reasonCode = 0,
    this.emailStatus = 0,
    this.canMove = false,
  });

  final HcId hasherId;
  final String name;
  final String mortalName;
  final String photo;
  final String reason;
  final int reasonCode;
  final int emailStatus;
  final bool canMove;

  bool get isBlocked => reasonCode == 7;
  bool get isBouncing => reasonCode == 8 || emailStatus == 3;
  bool get isSuspect => emailStatus == 2;

  /// The roster's lower-cased haystack: hash name and mortal name.
  String get searchText => '$name $mortalName'.toLowerCase();

  factory RunEmailAudienceEntry.fromJson(Map<String, dynamic> e) =>
      RunEmailAudienceEntry(
        hasherId: HcId((e['hasherId'] ?? '') as String),
        name: (e['name'] ?? '') as String,
        mortalName: (e['mortalName'] ?? '') as String,
        photo: (e['photo'] ?? '') as String,
        reason: (e['reason'] ?? '') as String,
        reasonCode: (e['reasonCode'] as num?)?.toInt() ?? 0,
        emailStatus: (e['emailStatus'] as num?)?.toInt() ?? 0,
        canMove: e['canMove'] == true,
      );
}

/// The signed-in hasher's own email delivery status (hcapp_getMyEmailStatus).
class MyEmailStatus {
  const MyEmailStatus({required this.email, required this.status, required this.blocked});
  final String email;
  final int status;
  final bool blocked;
  bool get isBounced => status == 3;
}

class RunEmailAudience {
  const RunEmailAudience({required this.recipients, required this.nonRecipients});
  final List<RunEmailAudienceEntry> recipients;
  final List<RunEmailAudienceEntry> nonRecipients;
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

  /// Who will get the email and which kennel members will not, with why.
  Future<RunEmailAudience> audience(HcId eventId) async {
    final Map<String, dynamic> j = await _call(eventId, 'audience');
    List<RunEmailAudienceEntry> parse(dynamic list) =>
        ((list as List<dynamic>?) ?? const <dynamic>[])
            .map(
              (dynamic e) =>
                  RunEmailAudienceEntry.fromJson(e as Map<String, dynamic>),
            )
            .toList();
    return RunEmailAudience(
      recipients: parse(j['recipients']),
      nonRecipients: parse(j['nonRecipients']),
    );
  }

  /// Returns how many recipients the email was sent to. With [previewToSelf]
  /// the finished email goes to the sender only and nothing is recorded.
  Future<int> send(
    HcId eventId, {
    required String subject,
    required String body,
    String instruction = '',
    bool saveInstruction = false,
    bool previewToSelf = false,
    Iterable<HcId> includeHasherIds = const <HcId>[],
    Iterable<HcId> excludeHasherIds = const <HcId>[],
  }) async {
    final Map<String, dynamic> j = await _call(eventId, 'send', <String, Object>{
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

  /// The signed-in hasher's own address status, for the "update your email"
  /// prompt. Null when it could not be fetched — never a reason to nag.
  static Future<MyEmailStatus?> myEmailStatus() async {
    final String? deviceId = getStringPref(StringPrefsEnum.deviceId);
    final String? deviceSecret = getStringPref(StringPrefsEnum.deviceSecret);
    final String? userId = getStringPref(StringPrefsEnum.userId);
    if ((userId ?? '').isEmpty || (deviceId ?? '').isEmpty || (deviceSecret ?? '').isEmpty) {
      return null;
    }
    try {
      final http.Response r = await http
          .post(
            Uri.parse(BASE_AF_API_URL),
            headers: <String, String>{'content-type': 'application/json'},
            body: jsonEncode(<String, String>{
              'queryType': 'getMyEmailStatus',
              'deviceId': deviceId!,
              'accessToken': Utilities.generateToken(
                userId!,
                'hcapp_getMyEmailStatus',
                paramString: deviceSecret!,
              ),
            }),
          )
          .timeout(const Duration(seconds: 20));
      if (r.statusCode != 200) return null;
      final dynamic j = jsonDecode(r.body);
      final Map<String, dynamic>? row =
          (j is List && j.isNotEmpty && j[0] is List && (j[0] as List).isNotEmpty)
          ? (j[0] as List)[0] as Map<String, dynamic>
          : null;
      if (row == null) return null;
      return MyEmailStatus(
        email: (row['email'] ?? '') as String,
        status: (row['emailStatus'] as num?)?.toInt() ?? 0,
        blocked: (row['emailBlocked'] as num?)?.toInt() == 1,
      );
    } catch (_) {
      return null;
    }
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
