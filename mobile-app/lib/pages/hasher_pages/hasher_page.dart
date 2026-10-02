import 'package:harrier_central/imports.dart';
import 'package:intl/intl.dart';

/// The hasher page (E10.F1.S5, shared with E9.F1.S26's search): who they
/// are, the runs the two of you shared, and a way to message them. Opened
/// from Run Counts › By Hasher and from a search result, so it is built
/// once. The header shows what the caller already had while the runs load.
class HasherPageController extends GetxController {
  HasherPageController(this.seed);

  final HasherSummary seed;

  final Rxn<HasherTogether> together = Rxn<HasherTogether>();
  final RxBool loading = true.obs;
  final RxBool failed = false.obs;
  final RxBool messaging = false.obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(load());
  }

  Future<void> load() async {
    loading.value = true;
    failed.value = false;
    final HasherTogether? t = await HasherDirectoryService.fetchRunsTogether(
      seed.publicHasherId,
    );
    if (isClosed) return;
    together.value = t;
    failed.value = t == null;
    loading.value = false;
  }

  Future<void> message() async {
    if (messaging.value) return;
    messaging.value = true;
    try {
      await messageHasher(
        seed.publicHasherId,
        together.value?.hasher.displayName ?? seed.displayName,
      );
    } finally {
      if (!isClosed) messaging.value = false;
    }
  }

  /// Opens the run when this phone holds it; every run the caller attended
  /// normally is, but very old ones may have aged out of the cache.
  Future<void> openRun(SharedRun run) async {
    final List<dynamic> found = await QueryRuns.getRunDetailsAggregates(
      true,
      eventId: run.eventId,
      queryType: EnumRunQueryType.singleRun,
      runsTimeScope: RunsTimeScope.future,
      runsToDisplay: RunsToDisplay.allRuns,
    );
    if (isClosed) return;
    if (found.isEmpty) {
      hcSnack("That run's details aren't on this phone.");
      return;
    }
    await navigatorKey.currentState?.push<dynamic>(
      MaterialPageRoute<dynamic>(
        builder: (BuildContext context) => RunDetailsPage(futureRun: found[0]),
      ),
    );
  }
}

class HasherPage extends StatelessWidget {
  const HasherPage({super.key, required this.hasher});

  final HasherSummary hasher;

  static Future<void> open(HasherSummary hasher) =>
      Get.to<void>(
        () => HasherPage(hasher: hasher),
        preventDuplicates: false,
      ) ??
      Future<void>.value();

  static final DateFormat _day = DateFormat('d MMM yyyy');

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HasherPageController>(
      init: HasherPageController(hasher),
      global: false,
      // A page-local controller is not deleted by GetX on its own.
      dispose: (GetBuilderState<HasherPageController> s) =>
          s.controller?.onDelete(),
      builder: (HasherPageController c) => AppScaffold(
        appBar: AppBar(
          backgroundColor: themeAppBarBackground,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => hcPop<void>(),
            tooltip: 'Back',
          ),
          title: Text(
            hasher.displayName,
            style: ts_appBarTitle,
            overflow: TextOverflow.ellipsis,
          ),
          centerTitle: true,
        ),
        // Styled as a kennel's run history (James, 2026-10-02): the light
        // background, a white header panel, and run rows like that list's.
        body: DecoratedBox(
          decoration: Backgrounds.defaultHcBackgroundLight(),
          child: Obx(() {
            final HasherTogether? t = c.together.value;
            final bool loading = c.loading.value;
            final bool failed = c.failed.value;
            final bool messaging = c.messaging.value;
            final HasherSummary h = t?.hasher ?? hasher;
            final List<SharedRun> runs = t?.runs ?? const <SharedRun>[];
            final TextStyle note = ts_titleMediumCondensedBlack.copyWith(
              color: Colors.black87,
            );
            return CustomScrollView(
              slivers: <Widget>[
                SliverToBoxAdapter(child: _header(h, t, messaging, c)),
                if (loading)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: HcAppCircularProgressIndicator()),
                    ),
                  )
                else if (failed)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: <Widget>[
                          Text(
                            "Your runs together couldn't be loaded.",
                            style: note,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () => unawaited(c.load()),
                            child: const Text(
                              'Try again',
                              style: TextStyle(color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (runs.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        "You haven't run together yet.",
                        style: note,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  SliverList.separated(
                    itemCount: runs.length,
                    separatorBuilder: (BuildContext context, int i) =>
                        const Divider(height: 1.0, color: Colors.black45),
                    itemBuilder: (BuildContext context, int i) =>
                        SharedRunListItem(
                          run: runs[i],
                          theirName: h.displayName,
                          onTap: () => unawaited(c.openRun(runs[i])),
                        ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _header(
    HasherSummary h,
    HasherTogether? t,
    bool messaging,
    HasherPageController c,
  ) {
    final List<String> facts = <String>[
      if (t != null) ...<String>[
        '${t.runsTogether} ${t.runsTogether == 1 ? 'run' : 'runs'} together',
        if (t.firstTogether != null) 'first ${_day.format(t.firstTogether!)}',
        if (t.lastTogether != null) 'last ${_day.format(t.lastTogether!)}',
        if (t.haredTogether > 0) 'hared together ${t.haredTogether}',
      ],
    ];
    final TextStyle line = ts_titleMediumCondensedBlack.copyWith(
      color: Colors.black87,
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Color.fromARGB(70, 0, 0, 0),
            offset: Offset(0.0, 6.0),
            blurRadius: 10.0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              // Square and whole, never trimmed into a circle. A tap opens it
              // full screen, zoomable (James, 2026-10-02) — the same viewer a
              // kennel member's photo opens in.
              GestureDetector(
                onTap: () => _openPhoto(h),
                child: HasherPhoto(url: h.photo, size: 90),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(h.displayName, style: ts_boldTitleStyle),
                    if ((h.homeKennelShortName ?? h.homeKennelName) != null)
                      Row(
                        children: <Widget>[
                          if ((h.homeKennelLogo ?? '').isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              // A kennel logo is shown whole, never masked.
                              child: KennelLogo(
                                kennelLogoUrl: h.homeKennelLogo,
                                kennelShortName: h.homeKennelShortName,
                                logoHeight: 24,
                                zoomGesture: KennelLogoZoomGesture.none,
                              ),
                            ),
                          Flexible(
                            child: Text(
                              h.homeKennelName ?? h.homeKennelShortName!,
                              style: line,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    if (facts.isNotEmpty) Text(facts.join(' · '), style: line),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: messaging ? null : () => unawaited(c.message()),
            icon: messaging
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.chat_bubble_outline, color: Colors.white),
            label: Text(
              'Message ${h.displayName}',
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  /// The photo enlarged and zoomable. Nothing to open without a photo (the
  /// placeholder is not theirs).
  void _openPhoto(HasherSummary h) {
    final String? url = blobUrlForPhoto(h.photo);
    if (url == null) return;
    unawaited(
      navigatorKey.currentState?.push<void>(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => ZoomableImagePage2(
            pageTitle: h.displayName,
            imageUrl: url,
            appBarBackgroundColor: themeAppBarBackground,
            background: Backgrounds.defaultHcBackground(),
            margin: 20.0,
          ),
        ),
      ),
    );
  }
}

/// One shared run, drawn as a kennel's run history draws a run
/// (UserEventListItem): my status icon — the green tick, or the purple hare
/// when I hared — the kennel logo, a divider, then the run's name, "Run #N
/// on `date` at `time`", and "My FILTH run #115 and #63 time haring". When
/// the other hasher hared, a purple line says so. No payments and no
/// attendance menu: this is their page, not the run's.
class SharedRunListItem extends StatelessWidget {
  const SharedRunListItem({
    super.key,
    required this.run,
    required this.theirName,
    required this.onTap,
  });

  final SharedRun run;
  final String theirName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final SharedRun r = run;
    final TextStyle black = ts_titleMediumCondensedBlack.copyWith(
      color: Colors.black87,
    );
    final DateTime? at = r.startLocal;
    final String when = at == null
        ? ''
        : ' on ${DateFormat(at.year != DateTime.now().year ? "E, MMM d, yyyy 'at' h:mm a" : "E, MMM d 'at' h:mm a").format(at)}';
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 5, top: 5, bottom: 5),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              r.meHare
                  ? const Padding(
                      padding: EdgeInsets.only(left: 2.5, right: 2.5),
                      child: ImageIcon(
                        AssetImage('images/icons/hare_icon.png'),
                        color: Colors.purple,
                        size: 30.0,
                      ),
                    )
                  : const Icon(
                      FontAwesome.check_circle,
                      color: Colors.green,
                      size: 35.0,
                    ),
              Padding(
                padding: const EdgeInsets.only(left: 5.0),
                child: KennelLogo(
                  kennelLogoUrl: r.kennelLogo,
                  kennelShortName: r.kennelShortName,
                  logoHeight: 60,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 7.0, right: 3.0),
                child: VerticalDivider(thickness: 2.0, width: 2.0),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        r.eventName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: black,
                      ),
                      Text(
                        'Run #${r.eventNumber}$when',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: black,
                      ),
                      if (r.myRunNumber > 0)
                        Row(
                          children: <Widget>[
                            Flexible(
                              child: Text(
                                'My ${r.kennelShortName ?? ''} run #${r.myRunNumber}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: ts_titleMediumCondensedBlack.copyWith(
                                  color: Colors.green.shade800,
                                ),
                              ),
                            ),
                            if (r.meHare && r.myHareNumber > 0)
                              Flexible(
                                child: Text(
                                  ' and #${r.myHareNumber} time haring',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: ts_titleMediumCondensedBlack.copyWith(
                                    color: Colors.purple.shade800,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      if (r.themHare)
                        Text(
                          '$theirName hared',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ts_titleMediumCondensedBlack.copyWith(
                            color: Colors.purple.shade800,
                          ),
                        ),
                      RunActivityIcons(
                        runners: r.trackRunnerCount,
                        photos: r.photoCount,
                        messages: r.messageCount,
                        downDowns: r.downDownCount,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
