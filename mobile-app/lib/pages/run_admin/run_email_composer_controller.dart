import 'package:harrier_central/imports.dart';
import 'package:intl/intl.dart';

/// The run email composer (E9.F6.S7): the API drafts a subject and prose,
/// the sender steers it with an optional instruction and a Rewrite, edits
/// what came back, and sends. The facts — date, venue, hares, price, the app
/// link and the I'm-in / can't-make-it links — are added by the server and
/// never editable here, so a "make it funny" cannot move the start time.
///
/// Stateless page over this controller; every await is followed by an
/// isClosed check.
class RunEmailComposerController extends GetxController {
  RunEmailComposerController({
    required this.eventAggregate,
    required this.context,
  });

  final RunAdminAggregate eventAggregate;
  final RunEmailContext context;

  static String tagFor(String eventId) => 'runemail-$eventId';

  HcId get _eventId => HcId(eventAggregate.event.eventId);

  final TextEditingController subject = TextEditingController();
  final TextEditingController body = TextEditingController();
  final TextEditingController instruction = TextEditingController();

  final RxBool isDrafting = false.obs;
  final RxBool isSending = false.obs;
  final RxBool isPreviewing = false.obs;

  /// Subject AND message both have text. Preview, Who gets it and Send are
  /// disabled until they do (James, 2026-10-09): an empty email is never
  /// worth a preview, an audience or a send. Kept in step by listeners on
  /// the two fields, so typing, "Use run description" and "Write with AI"
  /// all repaint the buttons.
  final RxBool hasContent = false.obs;

  void _refreshHasContent() {
    hasContent.value =
        subject.text.trim().isNotEmpty && body.text.trim().isNotEmpty;
  }

  /// "Save as the kennel's default": the instruction is stored on the kennel
  /// at send time and pre-filled for whoever sends next (James, 2026-10-09).
  final RxBool saveInstruction = false.obs;

  /// What the kennel had saved when the page opened; the box starts with it.
  String get savedInstruction => context.instruction;

  /// Per-send overrides (James, 2026-10-09): members moved in or out of this
  /// send only. Never written to anybody's preferences; gone when the page
  /// closes. The server re-checks them (a blocked member is refused).
  final RxSet<HcId> includeIds = <HcId>{}.obs;
  final RxSet<HcId> excludeIds = <HcId>{}.obs;

  /// Who the email will reach with the overrides applied.
  int get effectiveCount =>
      context.recipientCount - excludeIds.length + includeIds.length;

  /// Set when a draft failed, so the sender can write it by hand instead.
  final RxString draftError = ''.obs;

  /// Opens with the fields empty and the kennel's prompt pre-filled; the
  /// sender then picks "Use run description" or "Write with AI" (James,
  /// 2026-10-09) — nothing is drafted, and no AI is spent, until they do.
  @override
  void onInit() {
    super.onInit();
    instruction.text = context.instruction;
    subject.addListener(_refreshHasContent);
    body.addListener(_refreshHasContent);
  }

  /// The run's own description as the email, no AI: subject = the run's
  /// title, body = the description as written in the run.
  void useRunDescription() {
    final String desc = (eventAggregate.event.eventDescription ?? '').trim();
    if (desc.isEmpty) {
      hcSnack('This run has no description yet.', error: true);
      return;
    }
    subject.text = context.title;
    body.text = desc;
    draftError.value = '';
  }

  @override
  void onClose() {
    subject.dispose();
    body.dispose();
    instruction.dispose();
    super.onClose();
  }

  /// First draft on open, and every Rewrite. The instruction box is read
  /// each time, so "now in French" on top of a finished draft just works.
  Future<void> draft() async {
    isDrafting.value = true;
    draftError.value = '';
    try {
      final RunEmailDraft d = await const RunEmailService().draft(
        _eventId,
        instruction: instruction.text.trim(),
      );
      if (isClosed) return;
      subject.text = d.subject;
      body.text = d.body;
    } on RunEmailException catch (e) {
      if (isClosed) return;
      draftError.value = e.message;
      if (subject.text.trim().isEmpty) subject.text = context.title;
    } catch (e, s) {
      BootLogger.logError('[RunEmailComposer.draft]', e, s);
      if (isClosed) return;
      draftError.value = 'The draft could not be written. You can write it yourself.';
    } finally {
      if (!isClosed) isDrafting.value = false;
    }
  }

  /// How many emails have gone out for this run and when the last did — on
  /// the page and again in the confirmation, so a second send is a choice
  /// (James, 2026-10-09).
  String get history {
    final RunEmailContext c = context;
    if (!c.alreadySent) return 'No email has been sent for this run yet.';
    final String when = c.emailLastSentAt == null
        ? ''
        : ' on ${DateFormat('d MMM, HH:mm').format(c.emailLastSentAt!)}';
    return '⚠ Already emailed ${c.emailSendCount} '
        '${c.emailSendCount == 1 ? 'time' : 'times'} — last to '
        '${c.emailLastSentCount ?? '?'} '
        '${c.emailLastSentCount == 1 ? 'member' : 'members'}$when.';
  }

  /// The finished email — facts block, buttons, footer — to the sender's own
  /// inbox and nobody else's. Nothing is recorded (James, 2026-10-09).
  Future<void> preview() async {
    final String subj = subject.text.trim();
    final String text = body.text.trim();
    if (subj.isEmpty || text.isEmpty) {
      hcSnack('The email needs a subject and some text.', error: true);
      return;
    }
    isPreviewing.value = true;
    try {
      await const RunEmailService().send(
        _eventId,
        subject: subj,
        body: text,
        previewToSelf: true,
      );
      if (isClosed) return;
      final String me = getStringPref(StringPrefsEnum.email) ?? 'your email';
      // A dialog, not a toast: the sender should not have to wonder whether
      // the tap took (James, 2026-10-09).
      await Utilities.showAlert(
        'Preview sent',
        'The finished email has been sent to $me. Check your inbox — and '
            'the spam folder if it is not there in a minute. Nothing was '
            'recorded against the run.',
        'OK',
      );
    } on RunEmailException catch (e) {
      if (isClosed) return;
      hcSnack(e.message, error: true, seconds: 6);
    } catch (e, s) {
      BootLogger.logError('[RunEmailComposer.preview]', e, s);
      if (isClosed) return;
      hcSnack('The preview could not be sent. Try again.', error: true);
    } finally {
      if (!isClosed) isPreviewing.value = false;
    }
  }

  /// Opens "Who gets it"; it reads and edits this page's override sets.
  Future<void> openAudience() async {
    await Get.to<void>(
      () => RunEmailAudiencePage(eventAggregate: eventAggregate, composer: this),
    );
  }

  /// Sends after one confirmation. Pops the page with the count on success
  /// (the toast is shown by the caller, after the pop — a GetX toast open
  /// during Get.back() swallows the pop).
  Future<void> send() async {
    final String subj = subject.text.trim();
    final String text = body.text.trim();
    if (subj.isEmpty || text.isEmpty) {
      hcSnack('The email needs a subject and some text.', error: true);
      return;
    }
    final int n = effectiveCount;
    final String overrides = includeIds.isEmpty && excludeIds.isEmpty
        ? ''
        : '\n\nOverrides for this send only: ${includeIds.length} moved in, '
              '${excludeIds.length} moved out.';
    final bool? go = await Utilities.showAlert(
      'Send to $n ${n == 1 ? 'member' : 'members'}?',
      'The email goes to everyone in ${eventAggregate.kennel.kennelShortName} '
          'who has run emails switched on. The run\'s date, venue, hares, '
          'price and the I\'m-in / can\'t-make-it buttons are added under '
          'your text.\n\n$history$overrides',
      'Send',
      showCancelButton: true,
    );
    if (go != true || isClosed) return;

    isSending.value = true;
    try {
      final int sent = await const RunEmailService().send(
        _eventId,
        subject: subj,
        body: text,
        instruction: instruction.text.trim(),
        saveInstruction: saveInstruction.value,
        includeHasherIds: includeIds,
        excludeHasherIds: excludeIds,
      );
      if (isClosed) return;
      hcPop<int>(result: sent);
    } on RunEmailException catch (e) {
      if (isClosed) return;
      hcSnack(e.message, error: true, seconds: 6);
    } catch (e, s) {
      BootLogger.logError('[RunEmailComposer.send]', e, s);
      if (isClosed) return;
      hcSnack('The email could not be sent. Try again.', error: true);
    } finally {
      if (!isClosed) isSending.value = false;
    }
  }
}
