import 'package:harrier_central/imports.dart';

/// "Who gets it" (James, 2026-10-09): two pills — the members the run email
/// will reach, and the kennel members it will not, each with the reason.
/// Names are the ones the check-in list shows (the kennel hash name, else
/// the display name), fetched from the same procedure that builds the send
/// list, so this page and the send can never disagree.
class RunEmailAudienceController extends GetxController {
  RunEmailAudienceController({required this.eventAggregate});

  final RunAdminAggregate eventAggregate;

  static String tagFor(String eventId) => 'runemail-audience-$eventId';

  final Rx<RunEmailAudience?> audience = Rx<RunEmailAudience?>(null);
  final RxBool isLoading = true.obs;
  final RxString error = ''.obs;

  /// 0 = will receive, 1 = will not.
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
      final RunEmailAudience a = await const RunEmailService().audience(
        HcId(eventAggregate.event.eventId),
      );
      if (isClosed) return;
      audience.value = a;
    } on RunEmailException catch (e) {
      if (isClosed) return;
      error.value = e.message;
    } catch (e, s) {
      BootLogger.logError('[RunEmailAudience.load]', e, s);
      if (isClosed) return;
      error.value = 'The list could not be loaded. Try again.';
    } finally {
      if (!isClosed) isLoading.value = false;
    }
  }
}

class RunEmailAudiencePage extends StatelessWidget {
  const RunEmailAudiencePage({
    super.key,
    required this.eventAggregate,
    required this.recipientCount,
  });

  final RunAdminAggregate eventAggregate;
  final int recipientCount;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<RunEmailAudienceController>(
      init: RunEmailAudienceController(eventAggregate: eventAggregate),
      tag: RunEmailAudienceController.tagFor(eventAggregate.event.eventId),
      builder: (RunEmailAudienceController c) => AppScaffold(
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: themeAppBarBackground,
          iconTheme: const IconThemeData(color: Colors.white, size: 28.0),
          title: Text('Who gets the email', style: ts_appBarTitle),
        ),
        body: DecoratedBox(
          decoration: Backgrounds.defaultHcBackground(),
          child: Obx(() => _body(c)),
        ),
      ),
    );
  }

  Widget _body(RunEmailAudienceController c) {
    if (c.isLoading.value) {
      return const Center(
        child: HcAppCircularProgressIndicator(key: Key('runemail-audience')),
      );
    }
    final RunEmailAudience? a = c.audience.value;
    if (a == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(c.error.value, style: ts_body, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: c.load,
                child: Text(
                  'Try again',
                  style: ts_button,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      );
    }
    final bool showingRecipients = c.pill.value == 0;
    final List<RunEmailAudienceEntry> rows = showingRecipients
        ? a.recipients
        : a.nonRecipients;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Center(
            child: SegmentedButton<int>(
              segments: <ButtonSegment<int>>[
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
              selected: <int>{c.pill.value},
              onSelectionChanged: (Set<int> s) => c.pill.value = s.first,
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith(
                  (Set<WidgetState> states) =>
                      states.contains(WidgetState.selected)
                      ? hc_red
                      : Colors.black.withValues(alpha: 0.35),
                ),
                foregroundColor: const WidgetStatePropertyAll<Color>(
                  Colors.white,
                ),
                side: const WidgetStatePropertyAll<BorderSide>(
                  BorderSide(color: Colors.white54),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            showingRecipients
                ? 'Members with run emails on — for this run, or for ${eventAggregate.kennel.kennelShortName} as a whole.'
                : 'Members of ${eventAggregate.kennel.kennelShortName} who will not get this email, and why. They can switch run emails on from the envelope on the kennel or the run.',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: rows.isEmpty
              ? Center(
                  child: Text(
                    showingRecipients ? 'Nobody yet.' : 'Everyone gets it.',
                    style: ts_body,
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: rows.length,
                  separatorBuilder: (_, _) =>
                      const Divider(color: Colors.white24, height: 1),
                  itemBuilder: (BuildContext context, int i) {
                    final RunEmailAudienceEntry e = rows[i];
                    return ListTile(
                      dense: true,
                      title: Text(e.name, style: ts_body),
                      subtitle: e.reason.isEmpty
                          ? null
                          : Text(
                              e.reason,
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                            ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
