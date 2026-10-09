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

  /// Per-send overrides (James, 2026-10-09): members moved in or out of this
  /// send only. Never written to anybody's preferences; gone with the
  /// dialog. The server re-checks every id.
  final RxSet<String> includeIds = <String>{}.obs;
  final RxSet<String> excludeIds = <String>{}.obs;

  int get effectiveCount =>
      (context.value?.recipientCount ?? 0) - excludeIds.length + includeIds.length;

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
      await CoreUtilities.showAlert(
        'Preview sent',
        'The finished email has been sent to your inbox. Check the spam folder '
            'if it is not there in a minute. Nothing was recorded against the run.',
        'OK',
      );
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
        composer: this,
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
    final int n = effectiveCount;
    if (subj.isEmpty || text.isEmpty) {
      error.value = 'The email needs a subject and some text.';
      return;
    }
    final String overrides = includeIds.isEmpty && excludeIds.isEmpty
        ? ''
        : '\n\nOverrides for this send only: ${includeIds.length} moved in, '
            '${excludeIds.length} moved out.';
    final bool? go = await Get.dialog<bool>(
      AlertDialog(
        title: Text('Send to $n ${n == 1 ? 'member' : 'members'}?'),
        content: Text(
          'The email goes to everyone in $kennelShortName who has run emails '
          'switched on. The run\'s date, venue, hares, price and the I\'m-in / '
          'can\'t-make-it buttons are added under your text.\n\n$history$overrides',
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
        includeHasherIds: includeIds,
        excludeHasherIds: excludeIds,
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
            // Read the override sets here so a move repaints the button.
            final int n = (c.context.value?.recipientCount ?? 0) - c.excludeIds.length + c.includeIds.length;
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
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text('Checking who gets run emails…', style: ts_alertDialogBodyMedium),
          ],
        ),
      );
    }
    final RunEmailContext? ctx = c.context.value;
    final bool busy = c.isDrafting.value || c.isSending.value || c.isPreviewing.value;
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Everything below is disabled while the model writes, so say so
          // where the eye is (James, 2026-10-09): a bar at the top and, over
          // the message area, a spinner with words.
          if (busy)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                children: [
                  const LinearProgressIndicator(minHeight: 4),
                  const SizedBox(height: 6),
                  Text(
                    c.isDrafting.value
                        ? 'Writing the email for you — a few seconds…'
                        : c.isPreviewing.value
                            ? 'Sending the preview to your inbox…'
                            : 'Sending…',
                    style: ts_alertDialogBodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
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
          Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                ],
              ),
              if (c.isDrafting.value)
                Positioned.fill(
                  child: Container(
                    color: Colors.white.withValues(alpha: 0.75),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 12),
                        Text('Writing the email…', style: ts_alertDialogBodyMedium),
                      ],
                    ),
                  ),
                ),
            ],
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

/// "Who gets the email" (James, 2026-10-09), portal edition: the attendance
/// roster's shape — search box, a row per member with photo, hash name,
/// mortal name and WHY they are in this list — plus one labelled button that
/// moves them to the other list for this send only. Overrides live in the
/// composer's two sets; the server re-checks every id. Blocked, bouncing and
/// address-less members have no button.
class RunEmailAudienceController extends GetxController {
  RunEmailAudienceController({required this.publicEventId, required this.composer});
  final String publicEventId;
  final RunEmailDialogController composer;

  final Rx<RunEmailAudience?> audience = Rx<RunEmailAudience?>(null);
  final RxBool isLoading = true.obs;
  final RxString error = ''.obs;
  final RxInt pill = 0.obs;
  final RxString query = ''.obs;
  final TextEditingController search = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    search.addListener(() => query.value = search.text.trim().toLowerCase());
    unawaited(load());
  }

  @override
  void onClose() {
    search.dispose();
    super.onClose();
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

  bool isMovedIn(RunEmailAudienceEntry e) => composer.includeIds.contains(e.hasherId);
  bool isMovedOut(RunEmailAudienceEntry e) => composer.excludeIds.contains(e.hasherId);

  List<RunEmailAudienceEntry> get willGet {
    final RunEmailAudience? a = audience.value;
    if (a == null) return const [];
    return [
      ...a.recipients.where((e) => !isMovedOut(e)),
      ...a.nonRecipients.where(isMovedIn),
    ]..sort(_byName);
  }

  List<RunEmailAudienceEntry> get willNot {
    final RunEmailAudience? a = audience.value;
    if (a == null) return const [];
    return [
      ...a.nonRecipients.where((e) => !isMovedIn(e)),
      ...a.recipients.where(isMovedOut),
    ]..sort(_byName);
  }

  static int _byName(RunEmailAudienceEntry a, RunEmailAudienceEntry b) =>
      a.name.toLowerCase().compareTo(b.name.toLowerCase());

  void toggle(RunEmailAudienceEntry e) {
    if (!e.canMove) return;
    final RunEmailAudience? a = audience.value;
    if (a == null) return;
    final bool naturallyIn = a.recipients.any((r) => r.hasherId == e.hasherId);
    if (naturallyIn) {
      if (!composer.excludeIds.remove(e.hasherId)) composer.excludeIds.add(e.hasherId);
    } else if (!composer.includeIds.remove(e.hasherId)) {
      if (composer.includeIds.length >= 20) {
        error.value = 'At most 20 members can be moved in for one send.';
      } else {
        composer.includeIds.add(e.hasherId);
      }
    }
  }
}

class RunEmailAudienceDialog extends StatelessWidget {
  const RunEmailAudienceDialog({
    super.key,
    required this.publicEventId,
    required this.kennelShortName,
    required this.composer,
  });

  final String publicEventId;
  final String kennelShortName;
  final RunEmailDialogController composer;

  static String tagFor(String publicEventId) => 'runemail-audience-$publicEventId';

  @override
  Widget build(BuildContext context) {
    return GetBuilder<RunEmailAudienceController>(
      init: RunEmailAudienceController(publicEventId: publicEventId, composer: composer),
      tag: tagFor(publicEventId),
      builder: (RunEmailAudienceController c) => AlertDialog(
        title: const Text('Who gets the email'),
        content: SizedBox(
          width: 640,
          height: 600,
          child: Obx(() => _body(c)),
        ),
        actions: [
          HcButton.primary(label: 'Done', onPressed: () => Get.back<void>()),
        ],
      ),
    );
  }

  Widget _body(RunEmailAudienceController c) {
    if (c.isLoading.value) return const Center(child: CircularProgressIndicator());
    if (c.audience.value == null) {
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
    final int movedIn = c.composer.includeIds.length;
    final int movedOut = c.composer.excludeIds.length;
    final bool showingGet = c.pill.value == 0;
    final List<RunEmailAudienceEntry> getList = c.willGet;
    final List<RunEmailAudienceEntry> notList = c.willNot;
    final List<RunEmailAudienceEntry> all = showingGet ? getList : notList;
    final String q = c.query.value;
    final List<RunEmailAudienceEntry> rows =
        q.isEmpty ? all : all.where((e) => e.searchText.contains(q)).toList();
    String count(int base, int moved) => moved == 0 ? '$base' : '$base + $moved';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: SegmentedButton<int>(
            segments: [
              ButtonSegment<int>(
                value: 0,
                icon: const Icon(Icons.mark_email_read_outlined),
                label: Text('Will get it (${count(getList.length - movedIn, movedIn)})'),
              ),
              ButtonSegment<int>(
                value: 1,
                icon: const Icon(Icons.unsubscribe_outlined),
                label: Text('Will not (${count(notList.length - movedOut, movedOut)})'),
              ),
            ],
            selected: {c.pill.value},
            onSelectionChanged: (Set<int> s) => c.pill.value = s.first,
            // The same style as "Send to N members" (HcButton.primary): the
            // chosen pill red with white text, the other white; the button's
            // corner radius, padding, height and type face, no shadow.
            showSelectedIcon: false,
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith(
                (Set<WidgetState> states) => states.contains(WidgetState.selected)
                    ? HcButtonTokens.primary
                    : Colors.white,
              ),
              foregroundColor: WidgetStateProperty.resolveWith(
                (Set<WidgetState> states) => states.contains(WidgetState.selected)
                    ? HcButtonTokens.onFilled
                    : HcButtonTokens.primary,
              ),
              iconColor: WidgetStateProperty.resolveWith(
                (Set<WidgetState> states) => states.contains(WidgetState.selected)
                    ? HcButtonTokens.onFilled
                    : HcButtonTokens.primary,
              ),
              side: const WidgetStatePropertyAll<BorderSide>(
                BorderSide(color: HcButtonTokens.primary),
              ),
              shape: WidgetStatePropertyAll<OutlinedBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(HcButtonTokens.radius),
                ),
              ),
              padding: const WidgetStatePropertyAll<EdgeInsets>(HcButtonTokens.padding),
              minimumSize: const WidgetStatePropertyAll<Size>(
                Size(HcButtonTokens.minWidth, HcButtonTokens.minHeight),
              ),
              textStyle: const WidgetStatePropertyAll<TextStyle>(HcButtonTokens.textStyle),
              elevation: const WidgetStatePropertyAll<double>(0),
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: c.search,
          decoration: const InputDecoration(
            isDense: true,
            prefixIcon: Icon(Icons.search),
            hintText: 'Enter Hash or mortal name',
            border: OutlineInputBorder(),
          ),
        ),
        if (movedIn + movedOut > 0)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'For this send only: $movedIn moved in, $movedOut moved out. Nobody\'s settings change.',
              style: const TextStyle(color: Colors.black54, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        if (c.error.value.isNotEmpty)
          Text(c.error.value, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Expanded(
          child: rows.isEmpty
              ? Center(
                  child: Text(
                    q.isNotEmpty ? 'Nobody matches.' : showingGet ? 'Nobody yet.' : 'Everyone gets it.',
                    style: ts_alertDialogBody,
                  ),
                )
              : ListView.separated(
                  itemCount: rows.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (BuildContext context, int i) => _row(c, rows[i], showingGet),
                ),
        ),
      ],
    );
  }

  Widget _row(RunEmailAudienceController c, RunEmailAudienceEntry e, bool inGetList) {
    final bool overridden = c.isMovedIn(e) || c.isMovedOut(e);
    return ListTile(
      dense: true,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(4),
          image: e.photo.isEmpty
              ? null
              : DecorationImage(fit: BoxFit.cover, image: NetworkImage(e.photo)),
        ),
      ),
      title: Text.rich(
        TextSpan(
          text: e.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
          children: [
            if (e.mortalName.isNotEmpty)
              TextSpan(
                text: '  (${e.mortalName})',
                style: const TextStyle(fontWeight: FontWeight.w400, color: Colors.black87),
              ),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Wrap(
        spacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(e.reason, style: TextStyle(color: e.isBouncing ? Colors.red.shade800 : Colors.black87)),
          if (overridden) _badge('Override', Colors.blue.shade700),
          if (e.isBlocked) _badge('Blocked', Colors.black87),
          if (e.isBouncing && !e.isBlocked) _badge('Bouncing', Colors.red.shade800),
          if (e.isSuspect && !e.isBouncing) _badge('Check address', Colors.orange.shade800),
        ],
      ),
      trailing: e.canMove
          ? (overridden
              ? HcButton.secondary(label: 'Undo', onPressed: () => c.toggle(e))
              : HcButton.secondary(
                  label: inGetList ? 'Don\'t send' : 'Send anyway',
                  onPressed: () => c.toggle(e),
                ))
          : null,
    );
  }

  Widget _badge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
      );
}
