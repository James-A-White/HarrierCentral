import 'package:hcportal/imports.dart';
import 'package:intl/intl.dart';

/// "Email members" on a run, portal edition (E9.F6.S6–S9): the API drafts
/// the subject and prose, the sender steers it with the kennel's saved
/// instruction (or their own), edits, and sends to the members who have
/// run emails on. The facts — date, venue, hares, price, the app link and
/// the I'm-in / can't-make-it links — are added by the server and are never
/// editable here.
///
/// Opened with `Get.dialog<int>(RunEmailDialog(...))`; pops with the
/// recipient count on send.
class RunEmailDialogController extends GetxController {
  RunEmailDialogController({
    required this.publicEventId,
    required this.kennelShortName,
  });

  final String publicEventId;
  final String kennelShortName;

  final TextEditingController subject = TextEditingController();
  final TextEditingController body = TextEditingController();
  final TextEditingController instruction = TextEditingController();

  final Rx<RunEmailContext?> context = Rx<RunEmailContext?>(null);
  final RxBool isLoading = true.obs;
  final RxBool isDrafting = false.obs;
  final RxBool isSending = false.obs;
  final RxBool isPreviewing = false.obs;
  final RxBool saveInstruction = false.obs;
  final RxString error = ''.obs;
  final RxString notice = ''.obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(_load());
  }

  @override
  void onClose() {
    subject.dispose();
    body.dispose();
    instruction.dispose();
    super.onClose();
  }

  Future<void> _load() async {
    try {
      final RunEmailContext c =
          await const RunEmailService().context(publicEventId);
      if (isClosed) return;
      context.value = c;
      instruction.text = c.instruction;
      isLoading.value = false;
      await draft();
    } on RunEmailException catch (e) {
      if (isClosed) return;
      error.value = e.message;
      isLoading.value = false;
    }
  }

  /// First draft, and every Rewrite; the instruction box is read each time.
  Future<void> draft() async {
    isDrafting.value = true;
    error.value = '';
    try {
      final RunEmailDraft d = await const RunEmailService()
          .draft(publicEventId, instruction: instruction.text.trim());
      if (isClosed) return;
      subject.text = d.subject;
      body.text = d.body;
    } on RunEmailException catch (e) {
      if (isClosed) return;
      error.value = e.message;
      if (subject.text.trim().isEmpty) {
        subject.text = context.value?.title ?? '';
      }
    } finally {
      if (!isClosed) isDrafting.value = false;
    }
  }

  /// The line under the title: how many have gone out and when the last did.
  String get history {
    final RunEmailContext? c = context.value;
    if (c == null || !c.alreadySent) return 'No email has been sent for this run yet.';
    final String when = c.emailLastSentAt == null
        ? ''
        : ' on ${DateFormat('d MMM, HH:mm').format(c.emailLastSentAt!)}';
    return '⚠ Already emailed ${c.emailSendCount} '
        '${c.emailSendCount == 1 ? 'time' : 'times'} — last to '
        '${c.emailLastSentCount ?? '?'} ${c.emailLastSentCount == 1 ? 'member' : 'members'}$when.';
  }

  /// The finished email — facts block, buttons, footer — to the sender's own
  /// inbox only. Nothing is recorded (James, 2026-10-09).
  Future<void> preview() async {
    final String subj = subject.text.trim();
    final String text = body.text.trim();
    if (subj.isEmpty || text.isEmpty) {
      error.value = 'The email needs a subject and some text.';
      return;
    }
    isPreviewing.value = true;
    error.value = '';
    notice.value = '';
    try {
      await const RunEmailService().send(
        publicEventId,
        subject: subj,
        body: text,
        previewToSelf: true,
      );
      if (isClosed) return;
      notice.value = 'Preview sent to your inbox.';
    } on RunEmailException catch (e) {
      if (isClosed) return;
      error.value = e.message;
    } finally {
      if (!isClosed) isPreviewing.value = false;
    }
  }

  /// "Who gets it": the two pills, in a dialog over this one.
  Future<void> openAudience() async {
    await Get.dialog<void>(
      RunEmailAudienceDialog(
        publicEventId: publicEventId,
        kennelShortName: kennelShortName,
      ),
    );
    await deleteAfterExit<RunEmailAudienceController>(
      Get.find<RunEmailAudienceController>(
        tag: RunEmailAudienceDialog.tagFor(publicEventId),
      ),
      tag: RunEmailAudienceDialog.tagFor(publicEventId),
    );
  }

  Future<void> send() async {
    final String subj = subject.text.trim();
    final String text = body.text.trim();
    final int n = context.value?.recipientCount ?? 0;
    if (subj.isEmpty || text.isEmpty) {
      error.value = 'The email needs a subject and some text.';
      return;
    }
    final bool? go = await Get.dialog<bool>(
      AlertDialog(
        title: Text('Send to $n ${n == 1 ? 'member' : 'members'}?'),
        content: Text(
          'The email goes to everyone in $kennelShortName who has run emails '
          'switched on. The run\'s date, venue, hares, price and the I\'m-in / '
          'can\'t-make-it buttons are added under your text.\n\n$history',
        ),
        actions: [
          HcButton.secondary(
            label: 'Cancel',
            onPressed: () => Get.back<bool>(result: false),
          ),
          HcButton.primary(
            label: 'Send',
            onPressed: () => Get.back<bool>(result: true),
          ),
        ],
      ),
    );
    if (go != true || isClosed) return;

    isSending.value = true;
    error.value = '';
    try {
      final int sent = await const RunEmailService().send(
        publicEventId,
        subject: subj,
        body: text,
        instruction: instruction.text.trim(),
        saveInstruction: saveInstruction.value,
      );
      if (isClosed) return;
      Get.back<int>(result: sent);
    } on RunEmailException catch (e) {
      if (isClosed) return;
      error.value = e.message;
    } finally {
      if (!isClosed) isSending.value = false;
    }
  }
}

class RunEmailDialog extends StatelessWidget {
  const RunEmailDialog({
    super.key,
    required this.publicEventId,
    required this.kennelShortName,
  });

  final String publicEventId;
  final String kennelShortName;

  static String tagFor(String publicEventId) => 'runemail-$publicEventId';

  @override
  Widget build(BuildContext context) {
    return GetBuilder<RunEmailDialogController>(
      init: RunEmailDialogController(
        publicEventId: publicEventId,
        kennelShortName: kennelShortName,
      ),
      tag: tagFor(publicEventId),
      builder: (RunEmailDialogController c) => AlertDialog(
        title: const Text('Email the run to members'),
        content: SizedBox(
          width: 600,
          child: Obx(() => _body(c)),
        ),
        actions: [
          HcButton.secondary(
            label: 'Cancel',
            onPressed: () => Get.back<int>(),
          ),
          Obx(() {
            final int n = c.context.value?.recipientCount ?? 0;
            final bool busy = c.isLoading.value || c.isDrafting.value || c.isSending.value;
            return HcButton.primary(
              icon: Icons.send_rounded,
              label: c.isSending.value
                  ? 'Sending…'
                  : n == 0
                      ? 'Nobody has run emails on'
                      : 'Send to $n ${n == 1 ? 'member' : 'members'}',
              onPressed: busy || n == 0 ? null : c.send,
            );
          }),
        ],
      ),
    );
  }

  Widget _body(RunEmailDialogController c) {
    if (c.isLoading.value) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final RunEmailContext? ctx = c.context.value;
    final bool busy = c.isDrafting.value || c.isSending.value || c.isPreviewing.value;
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (ctx != null) ...[
            Text(ctx.title, style: ts_alertDialogBodyMedium),
            Text('${ctx.when}\n${ctx.where}', style: ts_alertDialogBody),
            const SizedBox(height: 6),
            Text(
              c.history,
              style: ts_alertDialogBody.copyWith(
                color: ctx.alreadySent ? Colors.deepOrange.shade700 : Colors.black54,
              ),
            ),
            const SizedBox(height: 14),
          ],
          TextField(
            controller: c.instruction,
            enabled: !busy,
            maxLength: 300,
            minLines: 2,
            maxLines: 6,
            decoration: InputDecoration(
              labelText: (ctx?.instruction ?? '').isEmpty
                  ? 'Anything to add? (optional)'
                  : '$kennelShortName\'s usual instruction',
              hintText: 'e.g. make it a funny Halloween story · write it in French',
              border: const OutlineInputBorder(),
            ),
          ),
          CheckboxListTile(
            value: c.saveInstruction.value,
            onChanged: busy ? null : (bool? v) => c.saveInstruction.value = v ?? false,
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            title: Text('Save as $kennelShortName\'s default'),
            subtitle: const Text(
              'Pre-filled for whoever emails the next run. Tick with the box empty to clear it.',
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: HcButton.secondary(
              icon: Icons.auto_awesome,
              label: c.isDrafting.value ? 'Writing…' : 'Rewrite',
              onPressed: busy ? null : c.draft,
            ),
          ),
          const SizedBox(height: 14),
          if (c.error.value.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(c.error.value, style: const TextStyle(color: Colors.red)),
            ),
          TextField(
            controller: c.subject,
            enabled: !busy,
            maxLength: 150,
            minLines: 1,
            maxLines: 3,
            keyboardType: TextInputType.text,
            decoration: const InputDecoration(
              labelText: 'Subject',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: c.body,
            enabled: !busy,
            minLines: 8,
            maxLines: 30,
            maxLength: 6000,
            keyboardType: TextInputType.multiline,
            decoration: const InputDecoration(
              labelText: 'Your message',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const Text(
            'The run\'s date, venue, hares, price and the ✓ I\'m in / ✗ Can\'t make it '
            'buttons are added under your message automatically, so they are always right.',
            style: TextStyle(color: Colors.black54, fontSize: 12),
          ),
          const SizedBox(height: 12),
          // Try it on yourself, and see who it reaches — before it goes.
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              HcButton.secondary(
                icon: Icons.mark_email_read_outlined,
                label: c.isPreviewing.value ? 'Sending preview…' : 'Preview to me',
                onPressed: busy ? null : c.preview,
              ),
              HcButton.secondary(
                icon: Icons.people_outline,
                label: 'Who gets it',
                onPressed: c.isSending.value ? null : c.openAudience,
              ),
            ],
          ),
          if (c.notice.value.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                c.notice.value,
                style: TextStyle(color: Colors.green.shade800),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

/// "Who gets it" (James, 2026-10-09): two pills — the members the run email
/// will reach, and the kennel members it will not, each with the reason.
/// Names are the ones the check-in list shows; both lists come from the
/// same procedure that builds the send list.
class RunEmailAudienceController extends GetxController {
  RunEmailAudienceController({required this.publicEventId});
  final String publicEventId;

  final Rx<RunEmailAudience?> audience = Rx<RunEmailAudience?>(null);
  final RxBool isLoading = true.obs;
  final RxString error = ''.obs;
  final RxInt pill = 0.obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(load());
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = '';
    try {
      final RunEmailAudience a =
          await const RunEmailService().audience(publicEventId);
      if (isClosed) return;
      audience.value = a;
    } on RunEmailException catch (e) {
      if (isClosed) return;
      error.value = e.message;
    } finally {
      if (!isClosed) isLoading.value = false;
    }
  }
}

class RunEmailAudienceDialog extends StatelessWidget {
  const RunEmailAudienceDialog({
    super.key,
    required this.publicEventId,
    required this.kennelShortName,
  });

  final String publicEventId;
  final String kennelShortName;

  static String tagFor(String publicEventId) => 'runemail-audience-$publicEventId';

  @override
  Widget build(BuildContext context) {
    return GetBuilder<RunEmailAudienceController>(
      init: RunEmailAudienceController(publicEventId: publicEventId),
      tag: tagFor(publicEventId),
      builder: (RunEmailAudienceController c) => AlertDialog(
        title: const Text('Who gets the email'),
        content: SizedBox(
          width: 520,
          height: 520,
          child: Obx(() => _body(c)),
        ),
        actions: [
          HcButton.primary(
            label: 'Close',
            onPressed: () => Get.back<void>(),
          ),
        ],
      ),
    );
  }

  Widget _body(RunEmailAudienceController c) {
    if (c.isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }
    final RunEmailAudience? a = c.audience.value;
    if (a == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(c.error.value, style: ts_alertDialogBody, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            HcButton.secondary(label: 'Try again', onPressed: c.load),
          ],
        ),
      );
    }
    final bool showingRecipients = c.pill.value == 0;
    final List<RunEmailAudienceEntry> rows =
        showingRecipients ? a.recipients : a.nonRecipients;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: SegmentedButton<int>(
            segments: [
              ButtonSegment<int>(
                value: 0,
                icon: const Icon(Icons.mark_email_read_outlined),
                label: Text('Will get it (${a.recipients.length})'),
              ),
              ButtonSegment<int>(
                value: 1,
                icon: const Icon(Icons.unsubscribe_outlined),
                label: Text('Will not (${a.nonRecipients.length})'),
              ),
            ],
            selected: {c.pill.value},
            onSelectionChanged: (Set<int> s) => c.pill.value = s.first,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          showingRecipients
              ? 'Members with run emails on — for this run, or for $kennelShortName as a whole.'
              : 'Members of $kennelShortName who will not get this email, and why. They can switch run emails on from the envelope on the kennel or the run in the app.',
          style: const TextStyle(color: Colors.black54, fontSize: 12),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: rows.isEmpty
              ? Center(
                  child: Text(
                    showingRecipients ? 'Nobody yet.' : 'Everyone gets it.',
                    style: ts_alertDialogBody,
                  ),
                )
              : ListView.separated(
                  itemCount: rows.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (BuildContext context, int i) {
                    final RunEmailAudienceEntry e = rows[i];
                    return ListTile(
                      dense: true,
                      title: Text(e.name),
                      subtitle: e.reason.isEmpty ? null : Text(e.reason),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
