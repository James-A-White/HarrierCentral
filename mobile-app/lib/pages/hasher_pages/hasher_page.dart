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
        body: DecoratedBox(
          decoration: Backgrounds.defaultHcBackground(),
          child: Obx(() {
            final HasherTogether? t = c.together.value;
            final bool loading = c.loading.value;
            final bool failed = c.failed.value;
            final bool messaging = c.messaging.value;
            final HasherSummary h = t?.hasher ?? hasher;
            final List<SharedRun> runs = t?.runs ?? const <SharedRun>[];
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
                            style: ts_body,
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
                        style: ts_body,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  SliverList.builder(
                    itemCount: runs.length,
                    itemBuilder: (BuildContext context, int i) =>
                        _runRow(runs[i], h.displayName, c),
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
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          // A hasher's photo is a portrait, drawn as a circle.
          ClipOval(
            child: SizedBox(
              width: 96,
              height: 96,
              child: (h.photo ?? '').isEmpty
                  ? Image.asset('images/icons/create_profile_photo.png')
                  : Image(
                      image: avatarImageProvider(h.photo),
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            h.displayName,
            style: ts_headingLarge,
            textAlign: TextAlign.center,
          ),
          if ((h.homeKennelShortName ?? h.homeKennelName) != null) ...<Widget>[
            const SizedBox(height: 6),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: <Widget>[
                if ((h.homeKennelLogo ?? '').isNotEmpty)
                  // A kennel logo is shown whole, never masked.
                  KennelLogo(
                    kennelLogoUrl: h.homeKennelLogo,
                    kennelShortName: h.homeKennelShortName,
                    logoHeight: 28,
                    zoomGesture: KennelLogoZoomGesture.none,
                  ),
                Text(
                  'Home kennel: ${h.homeKennelName ?? h.homeKennelShortName}',
                  style: ts_body.copyWith(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ],
          if (facts.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              facts.join(' · '),
              style: ts_body,
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 14),
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

  Widget _runRow(SharedRun r, String theirName, HasherPageController c) {
    final String? hareNote = r.meHare && r.themHare
        ? 'You both hared'
        : r.meHare
        ? 'You hared'
        : r.themHare
        ? '$theirName hared'
        : null;
    final String title = <String>[
      if ((r.kennelShortName ?? '').isNotEmpty) r.kennelShortName!,
      if (r.eventNumber > 0) '#${r.eventNumber}',
    ].join(' ');
    return InkWell(
      onTap: () => unawaited(c.openRun(r)),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 48,
              child: KennelLogo(
                kennelLogoUrl: r.kennelLogo,
                kennelShortName: r.kennelShortName,
                logoHeight: 44,
                zoomGesture: KennelLogoZoomGesture.none,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title.isEmpty ? r.eventName : title,
                    style: ts_titleMediumBold,
                  ),
                  if (title.isNotEmpty && r.eventName.isNotEmpty)
                    Text(
                      r.eventName,
                      style: ts_body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  Text(
                    <String>[
                      if (r.startLocal != null) _day.format(r.startLocal!),
                      ?hareNote,
                    ].join(' · '),
                    style: ts_bodySmall.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white60),
          ],
        ),
      ),
    );
  }
}
