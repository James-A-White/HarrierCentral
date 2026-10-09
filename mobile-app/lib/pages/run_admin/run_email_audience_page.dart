import 'package:harrier_central/imports.dart';

/// "Who gets the email" (James, 2026-10-09): the run attendance roster's
/// layout — light hash-foot background, search box, a row per member with
/// the square photo, the hash name, the mortal name and, where the roster
/// shows the home kennel, WHY the member is in this list — plus one labelled
/// button that moves them to the other list for this send only.
///
/// Overrides live in the composer's two sets and die with the page; the
/// server re-checks every id. Blocked, bouncing and address-less members
/// have no button: the block is the member's unsubscribe.
class RunEmailAudienceController extends GetxController {
  RunEmailAudienceController({
    required this.eventAggregate,
    required this.composer,
  });

  final RunAdminAggregate eventAggregate;
  final RunEmailComposerController composer;

  static String tagFor(String eventId) => 'runemail-audience-$eventId';

  final Rx<RunEmailAudience?> audience = Rx<RunEmailAudience?>(null);
  final RxBool isLoading = true.obs;
  final RxString error = ''.obs;

  /// 0 = will get it, 1 = will not.
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

  bool isMovedIn(RunEmailAudienceEntry e) =>
      composer.includeIds.contains(e.hasherId);
  bool isMovedOut(RunEmailAudienceEntry e) =>
      composer.excludeIds.contains(e.hasherId);

  /// The "will get it" list with overrides applied, then the "will not".
  List<RunEmailAudienceEntry> get willGet {
    final RunEmailAudience? a = audience.value;
    if (a == null) return const <RunEmailAudienceEntry>[];
    return <RunEmailAudienceEntry>[
      ...a.recipients.where((RunEmailAudienceEntry e) => !isMovedOut(e)),
      ...a.nonRecipients.where(isMovedIn),
    ]..sort(_byName);
  }

  List<RunEmailAudienceEntry> get willNot {
    final RunEmailAudience? a = audience.value;
    if (a == null) return const <RunEmailAudienceEntry>[];
    return <RunEmailAudienceEntry>[
      ...a.nonRecipients.where((RunEmailAudienceEntry e) => !isMovedIn(e)),
      ...a.recipients.where(isMovedOut),
    ]..sort(_byName);
  }

  static int _byName(RunEmailAudienceEntry a, RunEmailAudienceEntry b) =>
      a.name.toLowerCase().compareTo(b.name.toLowerCase());

  int get movedInCount => composer.includeIds.length;
  int get movedOutCount => composer.excludeIds.length;

  /// Moves a member to the other list for this send, or undoes that move.
  void toggle(RunEmailAudienceEntry e) {
    if (!e.canMove) return;
    final RunEmailAudience? a = audience.value;
    if (a == null) return;
    final bool naturallyIn = a.recipients.any(
      (RunEmailAudienceEntry r) => r.hasherId == e.hasherId,
    );
    if (naturallyIn) {
      if (composer.excludeIds.contains(e.hasherId)) {
        composer.excludeIds.remove(e.hasherId);
      } else {
        composer.excludeIds.add(e.hasherId);
      }
    } else {
      if (composer.includeIds.contains(e.hasherId)) {
        composer.includeIds.remove(e.hasherId);
      } else if (composer.includeIds.length >= 20) {
        hcSnack(
          'At most 20 members can be moved in for one send.',
          error: true,
        );
      } else {
        composer.includeIds.add(e.hasherId);
      }
    }
  }
}

class RunEmailAudiencePage extends StatelessWidget {
  const RunEmailAudiencePage({
    super.key,
    required this.eventAggregate,
    required this.composer,
  });

  final RunAdminAggregate eventAggregate;
  final RunEmailComposerController composer;

  static const double _rowHeight = 84.0;
  static const double _leftMargin = 88.0;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<RunEmailAudienceController>(
      init: RunEmailAudienceController(
        eventAggregate: eventAggregate,
        composer: composer,
      ),
      tag: RunEmailAudienceController.tagFor(eventAggregate.event.eventId),
      builder: (RunEmailAudienceController c) => AppScaffold(
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: themeAppBarBackground,
          iconTheme: const IconThemeData(color: Colors.white, size: 28.0),
          title: Text('Who gets the email', style: ts_appBarTitle),
        ),
        body: DecoratedBox(
          decoration: Backgrounds.defaultHcBackgroundLight(),
          child: Obx(() => _body(context, c)),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, RunEmailAudienceController c) {
    if (c.isLoading.value) {
      return const Center(
        child: HcAppCircularProgressIndicator(key: Key('runemail-audience')),
      );
    }
    if (c.audience.value == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(
                c.error.value,
                style: ts_titleMediumBlack,
                textAlign: TextAlign.center,
              ),
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
    // Read the override sets here so a move repaints the counts and rows.
    final int movedIn = c.movedInCount;
    final int movedOut = c.movedOutCount;
    final bool showingGet = c.pill.value == 0;
    final List<RunEmailAudienceEntry> all = showingGet ? c.willGet : c.willNot;
    final String q = c.query.value;
    final List<RunEmailAudienceEntry> rows = q.isEmpty
        ? all
        : all
              .where((RunEmailAudienceEntry e) => e.searchText.contains(q))
              .toList();
    final int baseGet = all.length - (showingGet ? movedIn : movedOut);

    String count(int base, int moved) =>
        moved == 0 ? '$base' : '$base + $moved';
    final int getBase = showingGet ? baseGet : c.willGet.length - movedIn;
    final int notBase = showingGet ? c.willNot.length - movedOut : baseGet;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Center(
            child: SegmentedButton<int>(
              segments: <ButtonSegment<int>>[
                ButtonSegment<int>(
                  value: 0,
                  icon: const Icon(Icons.mark_email_read_outlined),
                  label: Text('Will get it (${count(getBase, movedIn)})'),
                ),
                ButtonSegment<int>(
                  value: 1,
                  icon: const Icon(Icons.unsubscribe_outlined),
                  label: Text('Will not (${count(notBase, movedOut)})'),
                ),
              ],
              selected: <int>{c.pill.value},
              onSelectionChanged: (Set<int> s) => c.pill.value = s.first,
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith(
                  (Set<WidgetState> states) =>
                      states.contains(WidgetState.selected)
                      ? hc_red
                      : Colors.white,
                ),
                foregroundColor: WidgetStateProperty.resolveWith(
                  (Set<WidgetState> states) =>
                      states.contains(WidgetState.selected)
                      ? Colors.white
                      : Colors.black87,
                ),
              ),
            ),
          ),
        ),
        // The roster's search box, filtering the current tab.
        Container(
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 6),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black26),
          ),
          child: TextField(
            controller: c.search,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            style: ts_titleMediumBlack,
            decoration: InputDecoration(
              border: InputBorder.none,
              icon: const Icon(Icons.search, color: Colors.black),
              hintText: 'Enter Hash or mortal name',
              hintStyle: ts_hint,
            ),
          ),
        ),
        if (movedIn + movedOut > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
            child: Text(
              'For this send only: $movedIn moved in, $movedOut moved out. '
              'Nobody\'s settings change.',
              style: const TextStyle(color: Colors.black54, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        Expanded(
          child: rows.isEmpty
              ? Center(
                  child: Text(
                    q.isNotEmpty
                        ? 'Nobody matches.'
                        : showingGet
                        ? 'Nobody yet.'
                        : 'Everyone gets it.',
                    style: ts_titleMediumBlack,
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(8, 2, 8, 24),
                  itemCount: rows.length,
                  itemBuilder: (BuildContext context, int i) =>
                      _row(context, c, rows[i], inGetList: showingGet),
                ),
        ),
      ],
    );
  }

  /// One member, in the roster's shape: photo left, hash name with the mortal
  /// name after it, the reason line where the roster shows the home kennel,
  /// badges, and the one button on the right.
  Widget _row(
    BuildContext context,
    RunEmailAudienceController c,
    RunEmailAudienceEntry e, {
    required bool inGetList,
  }) {
    final bool overridden = c.isMovedIn(e) || c.isMovedOut(e);
    final double h = _rowHeight * bodyTextScale(context);
    return Container(
      height: h,
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: overridden ? hc_blue : Colors.black12,
          width: overridden ? 2 : 1,
        ),
      ),
      child: Stack(
        children: <Widget>[
          // Square photo, shown whole (profile photos are square).
          Container(
            width: _rowHeight,
            height: h,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(5),
              ),
              image: DecorationImage(
                fit: BoxFit.cover,
                image: avatarImageProvider(e.photo.isEmpty ? null : e.photo),
              ),
            ),
          ),
          Positioned(
            left: _leftMargin + 2,
            right: 120,
            top: 4,
            child: Text.rich(
              TextSpan(
                text: e.name,
                style: const TextStyle(
                  fontFamily: 'AvenirNextCondensedDemiBold',
                  fontSize: 23,
                  height: 1.0,
                  color: Colors.black,
                ),
                children: <InlineSpan>[
                  if (e.mortalName.isNotEmpty)
                    TextSpan(
                      text: '  (${e.mortalName})',
                      style: const TextStyle(
                        fontFamily: 'AvenirNextCondensedMedium',
                        fontSize: 17,
                        height: 1.0,
                        color: Colors.black87,
                      ),
                    ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Positioned(
            left: _leftMargin + 3,
            right: 120,
            top: 30,
            child: Text(
              e.reason,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'AvenirNextCondensedMedium',
                fontSize: 17,
                height: 1.0,
                color: e.isBouncing ? Colors.red.shade800 : Colors.black87,
              ),
            ),
          ),
          Positioned(
            left: _leftMargin + 3,
            bottom: 6,
            child: Wrap(
              spacing: 6,
              children: <Widget>[
                if (overridden) _badge('Override', hc_blue),
                if (e.isBlocked) _badge('Blocked', Colors.black87),
                if (e.isBouncing && !e.isBlocked)
                  _badge('Bouncing', Colors.red.shade800),
                if (e.isSuspect && !e.isBouncing)
                  _badge('Check address', Colors.orange.shade800),
              ],
            ),
          ),
          Positioned(
            right: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: e.canMove
                  ? SizedBox(
                      width: 104,
                      child: ElevatedButton(
                        onPressed: () => c.toggle(e),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: overridden ? hc_blue : hc_red,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 8,
                          ),
                        ),
                        child: Text(
                          overridden
                              ? 'Undo'
                              : inGetList
                              ? 'Don\'t send'
                              : 'Send anyway',
                          style: ts_button,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : const SizedBox(width: 104),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
