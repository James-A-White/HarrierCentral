import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:harrier_central/imports.dart';

/// Where a hashruns.org link points, once parsed.
///
/// Pure — no I/O — so it is unit-testable, and so the OS-facing side of the
/// service stays a thin wrapper around it.
class DeepLinkTarget {
  const DeepLinkTarget._({
    this.kennelSlug,
    this.runNumber,
    this.publicEventId,
    this.tab = RunTab.rsvp,
  });

  /// `/<slug>/<number>[/…]` — the run page and its sub-pages.
  const DeepLinkTarget.run(String slug, int number, {RunTab tab = RunTab.rsvp})
    : this._(kennelSlug: slug, runNumber: number, tab: tab);

  /// The legacy `#/RID?publicEventId=…` form the QR codes still carry.
  const DeepLinkTarget.legacy(String publicEventId)
    : this._(publicEventId: publicEventId);

  final String? kennelSlug;
  final int? runNumber;
  final String? publicEventId;

  /// Check-in by default (James, 2026-09-15: "opens the app to the check-in
  /// page to that specific run"). The map and photo sub-pages open on their
  /// own tab instead, because that is what the link was for.
  final RunTab tab;

  bool get isLegacy => publicEventId != null;

  @override
  String toString() => isLegacy
      ? 'DeepLinkTarget(legacy $publicEventId)'
      : 'DeepLinkTarget($kennelSlug/$runNumber → ${tab.name})';
}

/// Opens hashruns.org links inside the app (E9.F3, James 2026-09-15).
///
/// Universal links on iOS and App Links on Android hand the URL to the app
/// instead of Safari or Chrome — but only for the paths the web declares in
/// `.well-known/apple-app-site-association` and `assetlinks.json`, and only
/// once the app declares the domain in its entitlements and manifest. The
/// three must agree, or the link opens the browser as before with no error
/// anywhere.
///
/// The app CLAIMS every `/<slug>/<something>` path, because the declarations
/// cannot express "only when the second segment is a number". So this
/// service has to be graceful about paths it does not understand: those go
/// to an in-app browser tab, which does not re-trigger the link and so
/// cannot loop.
class DeepLinkService {
  DeepLinkService._();
  static final DeepLinkService instance = DeepLinkService._();

  static const Set<String> _hosts = <String>{'www.hashruns.org', 'hashruns.org'};

  /// The kennel-level pages of the public site. These share the two-segment
  /// shape of a run URL, so they would otherwise parse as "run number
  /// 'songs'". They are the website's, not ours to open.
  static const Set<String> _kennelPages = <String>{
    'songs', 'about', 'runs', 'next-run', 'events', 'legacy', 'photos',
  };

  final AppLinks _links = AppLinks();
  StreamSubscription<Uri>? _sub;
  bool _started = false;

  /// A link that arrived before the app could act on it — cold start, or
  /// mid-login. Replaced, not queued: the newest link is the one the person
  /// meant.
  Uri? _pending;
  bool _handling = false;

  /// Call once, right after runApp. Safe to call before any widget exists:
  /// nothing here needs a context until a link actually arrives, and even
  /// then it waits for the app to be ready.
  Future<void> start() async {
    if (_started) return;
    _started = true;
    try {
      final Uri? initial = await _links.getInitialLink();
      if (initial != null) _receive(initial, 'cold start');
    } catch (e) {
      debugPrint('[DEEPLINK] getInitialLink failed: $e');
    }
    _sub = _links.uriLinkStream.listen(
      (Uri uri) => _receive(uri, 'while running'),
      onError: (Object e) => debugPrint('[DEEPLINK] stream error: $e'),
    );
  }

  /// A link tapped INSIDE the app — in a chat bubble, say. iOS never routes
  /// a universal link back to the app that owns the domain (it opens Safari),
  /// so anything in-app that wants a hashruns.org run to open as a run has to
  /// come through here rather than through url_launcher.
  Future<void> open(Uri uri) => _handle(uri);

  void _receive(Uri uri, String how) {
    debugPrint('[DEEPLINK] received $how: $uri');
    _pending = uri;
    unawaited(_drain());
  }

  // ---------------------------------------------------------------------
  // Parsing — pure, tested.
  // ---------------------------------------------------------------------

  /// null means "not a link this app opens" — the caller bounces it to the
  /// browser rather than guessing.
  static DeepLinkTarget? parse(Uri uri) {
    if (!_hosts.contains(uri.host.toLowerCase())) return null;

    // Legacy hash-route form: https://www.hashruns.org/#/RID?publicEventId=…
    // The interesting part is in the FRAGMENT, which Uri does not parse as a
    // query, so it is parsed by hand.
    final String frag = uri.fragment;
    if (frag.startsWith('/RID')) {
      final int q = frag.indexOf('?');
      if (q >= 0) {
        final String? id = Uri.splitQueryString(frag.substring(q + 1))['publicEventId'];
        if (id != null && id.isNotEmpty) return DeepLinkTarget.legacy(id.toLowerCase());
      }
      return null;
    }

    final List<String> seg =
        uri.pathSegments.where((String s) => s.isNotEmpty).toList();
    if (seg.length < 2) return null; // "/" and "/<slug>" are the website's.

    final String slug = seg[0].toLowerCase();
    final String second = seg[1].toLowerCase();
    if (_kennelPages.contains(second)) return null;
    final int? number = int.tryParse(second);
    if (number == null || number <= 0) return null;

    RunTab tab = RunTab.rsvp;
    if (seg.length >= 3) {
      switch (seg[2].toLowerCase()) {
        case 'packtrack':
          tab = RunTab.map;
        case 'photos':
          tab = RunTab.photos;
        default:
          // trail-tv and anything newer: the run page is the right landing.
          tab = RunTab.details;
      }
    }
    return DeepLinkTarget.run(slug, number, tab: tab);
  }

  // ---------------------------------------------------------------------
  // Acting on it.
  // ---------------------------------------------------------------------

  Future<void> _drain() async {
    if (_handling) return;
    _handling = true;
    try {
      while (_pending != null) {
        final Uri uri = _pending!;
        _pending = null;
        await _handle(uri);
      }
    } finally {
      _handling = false;
    }
  }

  Future<void> _handle(Uri uri) async {
    final DeepLinkTarget? target = parse(uri);
    if (target == null) {
      debugPrint('[DEEPLINK] not a run link, bouncing to the site: $uri');
      await _openInBrowser(uri);
      return;
    }

    // A cold-start link arrives before the database is open or the run list
    // exists. Wait for the app to be usable rather than acting on a half-
    // built one; a link that is still unactionable after 45 s is dropped,
    // because by then the person has moved on and a surprise navigation
    // would be worse than nothing.
    final bool ready = await _waitUntilReady(const Duration(seconds: 45));
    if (!ready) {
      debugPrint('[DEEPLINK] app never became ready; dropping $uri');
      return;
    }

    final String? eventId = await _resolveEventId(target);
    if (eventId == null) {
      // Nothing local and no way to get it — hand back to the website, which
      // can always show the run.
      await _openInBrowser(uri);
      return;
    }
    await _openRun(eventId, target.tab, uri);
  }

  Future<bool> _waitUntilReady(Duration limit) async {
    final DateTime deadline = DateTime.now().add(limit);
    while (DateTime.now().isBefore(deadline)) {
      if (_isReady) return true;
      await Future<void>.delayed(const Duration(milliseconds: 400));
    }
    return _isReady;
  }

  bool get _isReady =>
      currentUserId.isNotEmpty &&
      Get.isRegistered<FutureRunListPageController>() &&
      navigatorKey.currentContext != null;

  /// Local first. A run in a followed kennel is already on the phone; one in
  /// a kennel the hasher does not follow is not (the user sync carries only
  /// ten days of other kennels' runs), so that case offers to follow — which
  /// is what opening a run link from a kennel means — and pulls that
  /// kennel's runs down through the SAME force-replicate path the kennel
  /// admin screen already uses.
  Future<String?> _resolveEventId(DeepLinkTarget t) async {
    if (t.isLegacy) return _eventIdByPublicId(t.publicEventId!);

    final Map<String, dynamic>? kennel = await _kennelBySlug(t.kennelSlug!);
    if (kennel == null) {
      debugPrint('[DEEPLINK] unknown kennel slug ${t.kennelSlug}');
      return null;
    }
    final kh = tableModel.kennelsTableHelper;
    final String kennelId = normalizeUuid(kennel[kh.colKennelId] as String);
    final String kennelName =
        (kennel[kh.colKennelShortName] as String?) ?? t.kennelSlug!;

    String? eventId = await _eventIdByNumber(kennelId, t.runNumber!);
    if (eventId != null) return eventId;

    final bool follow = await _offerToFollow(kennelName);
    if (!follow) return null;
    await _followAndReplicate(kennelId);
    eventId = await _eventIdByNumber(kennelId, t.runNumber!);
    if (eventId == null) {
      debugPrint('[DEEPLINK] followed $kennelName but run ${t.runNumber} still absent');
    }
    return eventId;
  }

  Future<Map<String, dynamic>?> _kennelBySlug(String slug) async {
    final kh = tableModel.kennelsTableHelper;
    final rows = await database.rawQuery(
      'SELECT ${kh.colKennelId}, ${kh.colKennelShortName} '
      'FROM ${EnumDataTables.kennels.commonTableName} '
      'WHERE lower(${kh.colKennelUniqueShortName}) = ? LIMIT 1',
      <Object?>[slug.toLowerCase()],
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<String?> _eventIdByNumber(String kennelId, int number) async {
    final eh = tableModel.eventsTableHelper;
    final rows = await database.rawQuery(
      'SELECT ${eh.colEventId} FROM ${EnumDataTables.events.commonTableName} '
      'WHERE lower(${eh.colKennelId}) = ? AND ${eh.colEventNumber} = ? '
      'AND ${eh.colRemoved} = 0 LIMIT 1',
      <Object?>[kennelId, number],
    );
    return rows.isEmpty ? null : normalizeUuid(rows.first[eh.colEventId] as String);
  }

  Future<String?> _eventIdByPublicId(String publicEventId) async {
    final eh = tableModel.eventsTableHelper;
    final rows = await database.rawQuery(
      'SELECT ${eh.colEventId} FROM ${EnumDataTables.events.commonTableName} '
      'WHERE lower(${eh.colPublicEventId}) = ? AND ${eh.colRemoved} = 0 LIMIT 1',
      <Object?>[publicEventId.toLowerCase()],
    );
    return rows.isEmpty ? null : normalizeUuid(rows.first[eh.colEventId] as String);
  }

  Future<bool> _offerToFollow(String kennelName) async {
    final BuildContext? ctx = navigatorKey.currentContext;
    if (ctx == null) return false;
    final bool? yes = await showDialog<bool>(
      context: ctx,
      builder: (BuildContext c) => AlertDialog(
        title: Text('Follow $kennelName?'),
        content: Text(
          "This run belongs to $kennelName, which you don't follow yet. "
          'Follow them to open it — their runs will then show in your list.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('Not now'),
          ),
          TextButton(
            onPressed: () => Navigator.of(c).pop(true),
            child: const Text('Follow'),
          ),
        ],
      ),
    );
    return yes == true;
  }

  /// Verbatim the kennel-admin auto-follow: mark followed, clear the stale
  /// ten-day slice of this kennel's events, then force-replicate its full
  /// history so the run is actually there.
  Future<void> _followAndReplicate(String kennelId) async {
    await HasherKennelMapService().updateHasherKennelStatus(
      kennelId,
      AppDomainType.user,
      followingState: followTypeFollow.value,
    );
    await database.rawDelete(
      'DELETE FROM ${EnumDataTables.events.commonTableName} '
      'WHERE lower(${tableModel.eventsTableHelper.colKennelId}) = "${normalizeUuid(kennelId)}"',
    );
    await tableModel.syncUserDataService.updateFromBackend(
      EnumDataTables.events.flag,
      true,
      forceReplicateAllRunsForKennel: kennelId,
      debugText: 'deep_link_service: follow + force-replicate to open a linked run',
    );
  }

  Future<void> _openRun(String eventId, RunTab tab, Uri uri) async {
    final List<RunDetailsAggregate> runs = await QueryRuns.getRunDetailsAggregates(
      true,
      eventId: eventId,
      queryType: EnumRunQueryType.singleRun,
      runsTimeScope: RunsTimeScope.future,
      runsToDisplay: RunsToDisplay.allRuns,
    );
    if (runs.isEmpty) {
      debugPrint('[DEEPLINK] event $eventId has no aggregate; bouncing');
      await _openInBrowser(uri);
      return;
    }
    debugPrint('[DEEPLINK] opening run $eventId on ${tab.name}');
    await Get.to<void>(
      () => RunDetailsPage(futureRun: runs.first, openToTab: tab),
    );
  }

  /// In-app browser tab, deliberately: an external launch of a hashruns.org
  /// URL would come straight back to this app on Android and loop.
  Future<void> _openInBrowser(Uri uri) async {
    try {
      await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    } catch (e) {
      debugPrint('[DEEPLINK] could not open $uri in a browser: $e');
    }
  }

  void dispose() {
    unawaited(_sub?.cancel());
    _sub = null;
    _started = false;
  }
}
