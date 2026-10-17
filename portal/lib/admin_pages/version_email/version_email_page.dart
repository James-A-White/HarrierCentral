import 'package:hcportal/imports.dart';
import 'package:intl/intl.dart';

// ---------------------------------------------------------------------------
// HC Admin Tools › Version email (E19.F3.S3, James 2026-10-17).
//
// Pick an app build (or "All 2.x"), see who is still on it — signed in
// within the chosen number of days and not on a newer phone — edit the
// draft, send yourself a test, then send. Each person gets the store button
// for the phone(s) they use, in the normal HC email. Picking a build fills
// in the five most important features added since it (AI, editable).
// Who is NOT sent it, and why, is listed too: generated, blocked or bouncing
// addresses, and anyone sent a version email in the last 30 days.
// Platform admins with Newsflash see the tile.
// ---------------------------------------------------------------------------

const String _kFeaturesHeading = "What's new since your version:";

const String _kDraftSubject = 'Please update Harrier Central — your version is retiring';

const String _kDraftBody = '''Hi {firstName},

You're using an older version of the Harrier Central app. We're retiring it to keep everyone's accounts and run payments safe, and after 1 December 2026 it will stop working.

The new version is free: update the app from the App Store or Google Play with the button below. Your runs, kennels and history are all still there.

$_kFeaturesHeading
• (finding the five biggest…)

If anything doesn't work after updating, just reply to this email and we'll sort it out.

On-On,
James, Harrier Central''';

class VersionEmailController extends GetxController {
  final TextEditingController subject = TextEditingController(text: _kDraftSubject);
  final TextEditingController body = TextEditingController(text: _kDraftBody);

  static const List<int> dayChoices = [30, 60, 90, 180, 365];
  int days = 90;

  List<AppVersionUsage> versions = [];
  String? selectedKey; // 'all:2' or a build number
  List<VersionEmailRecipient> people = [];
  bool loadingVersions = true;
  bool loadingPeople = false;
  bool suggesting = false;
  bool testing = false;
  bool sending = false;
  String? message;

  /// Minted once per send intent and kept until that send is confirmed done,
  /// so a retry after a lost reply is the SAME send (CLAUDE.md, idempotent writes).
  String? pendingSendId;
  VersionEmailProgress progress = const VersionEmailProgress();
  Timer? _poll;

  int get eligibleCount => people.where((p) => p.eligible).length;
  bool get hasGeneratedEmail => people.any((p) => isGeneratedEmail(p.email));

  @override
  void onInit() {
    super.onInit();
    unawaited(loadVersions());
  }

  @override
  void onClose() {
    _poll?.cancel();
    subject.dispose();
    body.dispose();
    super.onClose();
  }

  /// The dropdown: one "All N.x" per major version, then every build.
  List<({String key, String label})> get choices {
    final List<({String key, String label})> out = [];
    final majors = <String>{for (final v in versions) v.major}.toList()..sort();
    for (final m in majors) {
      final inMajor = versions.where((v) => v.major == m).toList();
      final n = inMajor.fold<int>(0, (a, v) => a + v.users);
      out.add((key: 'all:$m', label: 'All $m.x — $n ${n == 1 ? 'person' : 'people'}'));
    }
    for (final v in versions) {
      out.add((
        key: v.build,
        label: '${v.version} (${v.build}) — ${v.users} · iPhone ${v.ios} · Android ${v.android}',
      ));
    }
    return out;
  }

  List<String> get selectedBuilds {
    final key = selectedKey;
    if (key == null) return const [];
    if (key.startsWith('all:')) {
      final m = key.substring(4);
      return versions.where((v) => v.major == m).map((v) => v.build).toList();
    }
    return [key];
  }

  Future<void> loadVersions() async {
    loadingVersions = true;
    update();
    final rows = await getAppVersionUsage(days);
    if (isClosed) return;
    versions = rows ?? [];
    loadingVersions = false;
    if (selectedKey != null && !choices.any((c) => c.key == selectedKey)) {
      selectedKey = null;
      people = [];
    }
    update();
    if (selectedKey != null) await loadPeople();
  }

  Future<void> setDays(int d) async {
    if (d == days) return;
    days = d;
    await loadVersions();
  }

  Future<void> select(String? key) async {
    if (key == null || key == selectedKey) return;
    selectedKey = key;
    message = null;
    update();
    await Future.wait([loadPeople(), suggestFeatures()]);
  }

  Future<void> loadPeople() async {
    final builds = selectedBuilds;
    if (builds.isEmpty) return;
    loadingPeople = true;
    update();
    final r = await getVersionEmailRecipients(builds, days, sendId: pendingSendId);
    if (isClosed) return;
    loadingPeople = false;
    if (r != null) {
      people = r.people;
      progress = r.progress;
    }
    update();
  }

  /// Fills the "What's new" paragraph with the five biggest features since the
  /// oldest chosen build. The rest of the text is left as the admin has it.
  Future<void> suggestFeatures() async {
    final builds = selectedBuilds;
    if (builds.isEmpty || suggesting) return;
    suggesting = true;
    update();
    try {
      final features = await suggestVersionFeatures(builds);
      if (isClosed) return;
      if (features.isNotEmpty) _putFeatures(features);
    } on VersionEmailException catch (e) {
      if (isClosed) return;
      message = e.message;
    } finally {
      if (!isClosed) {
        suggesting = false;
        update();
      }
    }
  }

  void _putFeatures(List<String> features) {
    final String bullets = features.map((f) => '• ${f.replaceFirst(RegExp(r'^[•\-\*]\s*'), '')}').join('\n');
    final String text = body.text;
    final int at = text.indexOf(_kFeaturesHeading);
    if (at < 0) {
      body.text = '${text.trimRight()}\n\n$_kFeaturesHeading\n$bullets';
      return;
    }
    final int start = at + _kFeaturesHeading.length;
    final int gap = text.indexOf('\n\n', start);
    body.text = '${text.substring(0, start)}\n$bullets${gap < 0 ? '' : text.substring(gap)}';
  }

  Future<void> sendTest() async {
    if (testing) return;
    testing = true;
    message = null;
    update();
    try {
      final to = await sendVersionEmailTest(subject.text.trim(), body.text);
      if (isClosed) return;
      message = 'Test sent to $to (with both store buttons).';
    } on VersionEmailException catch (e) {
      if (isClosed) return;
      message = e.message;
    } finally {
      if (!isClosed) {
        testing = false;
        update();
      }
    }
  }

  Future<void> send() async {
    if (sending || eligibleCount == 0) return;
    final bool? go = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Send the version email?'),
        content: Text(
          'Send "${subject.text.trim()}" to $eligibleCount '
          '${eligibleCount == 1 ? 'person' : 'people'}? This cannot be undone.',
        ),
        actions: [
          TextButton(
            style: hcDialogButtonStyle(hcDialogCancelColor),
            onPressed: () => Get.back<bool>(result: false),
            child: const Text('Cancel', textAlign: TextAlign.center),
          ),
          TextButton(
            style: hcDialogButtonStyle(hcDialogPrimaryColor),
            onPressed: () => Get.back<bool>(result: true),
            child: Text('Send to $eligibleCount', textAlign: TextAlign.center),
          ),
        ],
      ),
    );
    if (go != true || isClosed) return;
    sending = true;
    message = null;
    update();
    pendingSendId ??= const Uuid().v4();
    try {
      final queued = await sendVersionEmail(pendingSendId!, selectedBuilds, days, subject.text.trim(), body.text);
      if (isClosed) return;
      message = 'Sending to $queued…';
      _startPolling();
    } on VersionEmailException catch (e) {
      if (isClosed) return;
      // The send id is kept: pressing Send again is the same send.
      message = e.message;
      sending = false;
    } finally {
      if (!isClosed) update();
    }
  }

  void _startPolling() {
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 3), (_) async {
      await loadPeople();
      if (isClosed) return;
      if (progress.done) {
        _poll?.cancel();
        message = 'Done: ${progress.sent} sent'
            '${progress.failed > 0 ? ', ${progress.failed} failed (see the error log)' : ''}.';
        sending = false;
        pendingSendId = null; // the next send is a new intent
        await loadPeople();
        update();
      }
    });
  }
}

class VersionEmailPage extends StatelessWidget {
  const VersionEmailPage({super.key});

  static const Color _muted = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<VersionEmailController>(
      init: VersionEmailController(),
      global: false,
      builder: (c) => Scaffold(
        appBar: AppBar(
          title: const Text('Version email'),
          leading: GestureDetector(
            onTap: () => Get.back<void>(),
            child: const Icon(MaterialCommunityIcons.arrow_left, color: Colors.black),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Email everyone still using an app version. Each person gets the App Store or '
                      'Google Play button for the phone they use, in the normal Harrier Central email. '
                      'Someone on a newer phone as well is not counted; anyone sent a version email in '
                      'the last 30 days is skipped.',
                      style: TextStyle(color: _muted),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),
                    _Pickers(c: c),
                    const SizedBox(height: 18),
                    _Editor(c: c),
                    const SizedBox(height: 14),
                    _Actions(c: c),
                    if (c.message != null) ...[
                      const SizedBox(height: 10),
                      Text(c.message!, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                    const SizedBox(height: 22),
                    _People(c: c),
                    GeneratedEmailNote(show: c.hasGeneratedEmail),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pickers extends StatelessWidget {
  const _Pickers({required this.c});
  final VersionEmailController c;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 12,
      children: [
        SizedBox(
          width: 520,
          child: DropdownButtonFormField<String>(
            initialValue: c.selectedKey,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: c.loadingVersions ? 'Loading versions…' : 'App version',
              border: const OutlineInputBorder(),
            ),
            items: [
              for (final ch in c.choices)
                DropdownMenuItem<String>(value: ch.key, child: Text(ch.label, overflow: TextOverflow.ellipsis)),
            ],
            onChanged: c.loadingVersions || c.sending ? null : (v) => unawaited(c.select(v)),
          ),
        ),
        SizedBox(
          width: 220,
          child: DropdownButtonFormField<int>(
            initialValue: c.days,
            decoration: const InputDecoration(labelText: 'Signed in within', border: OutlineInputBorder()),
            items: [
              for (final d in VersionEmailController.dayChoices)
                DropdownMenuItem<int>(value: d, child: Text('$d days')),
            ],
            onChanged: c.sending ? null : (v) => unawaited(c.setDays(v ?? 90)),
          ),
        ),
      ],
    );
  }
}

class _Editor extends StatelessWidget {
  const _Editor({required this.c});
  final VersionEmailController c;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: c.subject,
          maxLength: 250,
          decoration: const InputDecoration(labelText: 'Subject', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: c.body,
          minLines: 14,
          maxLines: 30,
          decoration: const InputDecoration(
            labelText: 'Email',
            helperText: 'Plain text. A blank line starts a paragraph; links become clickable; '
                '{firstName} is each person\'s first name. The store buttons are added under the text.',
            helperMaxLines: 2,
            alignLabelWithHint: true,
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.c});
  final VersionEmailController c;

  @override
  Widget build(BuildContext context) {
    final bool picked = c.selectedKey != null;
    final p = c.progress;
    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 10,
          children: [
            HcButton.secondary(
              label: 'Suggest top 5 features',
              icon: MaterialCommunityIcons.creation,
              loading: c.suggesting,
              onPressed: picked && !c.sending ? () => unawaited(c.suggestFeatures()) : null,
            ),
            HcButton.secondary(
              label: 'Send test to me',
              icon: MaterialCommunityIcons.email_check_outline,
              loading: c.testing,
              onPressed: c.sending ? null : () => unawaited(c.sendTest()),
            ),
            HcButton.primary(
              label: c.sending ? 'Sending…' : 'Send to ${c.eligibleCount}',
              icon: MaterialCommunityIcons.send,
              loading: c.sending,
              onPressed: picked && c.eligibleCount > 0 && !c.sending ? () => unawaited(c.send()) : null,
            ),
          ],
        ),
        if (c.sending && p.total > 0) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: 420,
            child: LinearProgressIndicator(value: (p.sent + p.failed) / p.total),
          ),
          const SizedBox(height: 6),
          Text('Sent ${p.sent} of ${p.total}${p.failed > 0 ? ' · ${p.failed} failed' : ''}',
              textAlign: TextAlign.center),
        ],
      ],
    );
  }
}

class _People extends StatelessWidget {
  const _People({required this.c});
  final VersionEmailController c;

  static final DateFormat _date = DateFormat('d MMM yyyy');

  @override
  Widget build(BuildContext context) {
    if (c.selectedKey == null) {
      return const Text('Pick a version to see who is still using it.', textAlign: TextAlign.center);
    }
    if (c.loadingPeople && c.people.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    final int notSent = c.people.length - c.eligibleCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${c.eligibleCount} will be sent the email'
          '${notSent > 0 ? ' · $notSent listed but not sent' : ''}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 22,
            columns: const [
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Email')),
              DataColumn(label: Text('Phone')),
              DataColumn(label: Text('Version')),
              DataColumn(label: Text('Last sign-in')),
              DataColumn(label: Text('')),
            ],
            rows: [
              for (final p in c.people)
                DataRow(
                  color: WidgetStatePropertyAll(p.eligible ? null : const Color(0xFFF3F4F6)),
                  cells: [
                    DataCell(Text(p.name)),
                    DataCell(Text(p.email, style: emailTextStyle(p.email))),
                    DataCell(Text([if (p.ios) 'iPhone', if (p.android) 'Android'].join(' + '))),
                    DataCell(Text(p.version)),
                    DataCell(Text(p.lastLogin == null ? '' : _date.format(p.lastLogin!))),
                    DataCell(
                      p.eligible
                          ? const Icon(Icons.check, color: Color(0xFF15803D), size: 18)
                          : Text(p.reason, style: const TextStyle(color: Color(0xFF6B7280))),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}
