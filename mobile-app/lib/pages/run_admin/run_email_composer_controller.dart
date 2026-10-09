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

  final RxBool isDrafting = true.obs;
  final RxBool isSending = false.obs;
  final RxBool isPreviewing = false.obs;

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

  @override
  void onInit() {
    super.onInit();
    instruction.text = context.instruction;
    unawaited(draft());
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
      hcSnack('Preview sent to $me — check your inbox.', seconds: 5);
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
