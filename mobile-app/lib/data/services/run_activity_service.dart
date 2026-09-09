import 'package:harrier_central/imports.dart';

/// What a run has to show: a PackTrack track, photos, chat, down-downs.
class RunActivity {
  const RunActivity({
    required this.hasTrack,
    this.runners = 0,
    required this.photos,
    required this.messages,
    required this.downDowns,
  });

  final bool hasTrack;

  /// Hashers who recorded a track on the run (`HC.EventTrackRunner`). Zero
  /// for a run tracked before that table existed whose backfill found no
  /// runner rows — the icon then shows without a number.
  final int runners;
  final int photos;
  final int messages;
  final int downDowns;

  bool get any => hasTrack || photos > 0 || messages > 0 || downDowns > 0;

  static const RunActivity none =
      RunActivity(hasTrack: false, photos: 0, messages: 0, downDowns: 0);
}

/// Per-run activity for the icons on a run card, fetched from
/// `hcapp_getRunActivity` in batches and cached for the session.
///
/// A card calls [want] from its build; the ids of every card that asked in
/// the last 300 ms go to the server in one call, so scrolling a list of two
/// thousand past runs costs one request per screenful, not one per card.
/// None of this is in the local database on purpose — chat, photos and
/// down-downs are not synced tables, and whether a run has a track lives in
/// `HC.EventTrack`, written by the position store. The cache is reactive:
/// a card's Obx repaints when its answer lands.
class RunActivityService {
  RunActivityService._();

  static final RxMap<String, RunActivity> byEvent =
      <String, RunActivity>{}.obs;
  static final Set<String> _inFlight = <String>{};
  static final List<String> _queue = <String>[];
  static Timer? _debounce;
  static const Duration _debounceFor = Duration(milliseconds: 300);
  static const int _batchSize = 80;

  /// Ask for [eventId]'s activity. Cheap and idempotent; safe from build().
  static void want(String eventId) {
    final String id = normalizeUuid(eventId);
    if (id.isEmpty ||
        byEvent.containsKey(id) ||
        _inFlight.contains(id) ||
        _queue.contains(id)) {
      return;
    }
    _queue.add(id);
    _debounce ??= Timer(_debounceFor, () => unawaited(_flush()));
  }

  /// Forget one run so its next [want] refetches — after the viewer uploads
  /// a photo, posts a message or adds a charge.
  static void invalidate(String eventId) =>
      byEvent.remove(normalizeUuid(eventId));

  static Future<void> _flush() async {
    _debounce = null;
    if (_queue.isEmpty) return;
    final List<String> batch = _queue.take(_batchSize).toList();
    _queue.removeRange(0, batch.length);
    _inFlight.addAll(batch);
    try {
      final String raw = await _fetch(batch);
      if (!raw.startsWith(ERROR_PREFIX)) {
        final dynamic outer = jsonDecode(raw);
        final List<dynamic> rows = outer is List && outer.isNotEmpty
            ? (outer[0] as List<dynamic>)
            : const <dynamic>[];
        final Map<String, RunActivity> got = <String, RunActivity>{};
        for (final dynamic r in rows) {
          if (r is! Map<String, dynamic>) continue;
          final String? id = r['eventId'] as String?;
          if (id == null) continue;
          got[normalizeUuid(id)] = RunActivity(
            hasTrack: (r['hasTrack'] as num?)?.toInt() == 1,
            runners: (r['runnerCount'] as num?)?.toInt() ?? 0,
            photos: (r['photoCount'] as num?)?.toInt() ?? 0,
            messages: (r['messageCount'] as num?)?.toInt() ?? 0,
            downDowns: (r['downDownCount'] as num?)?.toInt() ?? 0,
          );
        }
        // An id the server did not answer for (unknown run) gets 'none', so
        // it is not asked for again this session.
        for (final String id in batch) {
          got.putIfAbsent(id, () => RunActivity.none);
        }
        byEvent.addAll(got);
      }
    } catch (e, s) {
      BootLogger.logError('[RunActivityService._flush] n=${batch.length}', e, s);
    } finally {
      _inFlight.removeAll(batch);
      if (_queue.isNotEmpty) {
        _debounce ??= Timer(_debounceFor, () => unawaited(_flush()));
      }
    }
  }

  static Future<String> _fetch(List<String> ids) {
    final String userId = getStringPref(StringPrefsEnum.userId) ?? '';
    final String deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    final String deviceSecret =
        getStringPref(StringPrefsEnum.deviceSecret) ?? '';
    final Map<String, dynamic> body = <String, dynamic>{
      'queryType': 'getRunActivity',
      'deviceId': deviceId,
      'eventIds': ids.join('|'),
    };
    return ServiceCommon.sendHttpPost(
      () {
        body['accessToken'] = Utilities.generateToken(
          userId,
          'hcapp_getRunActivity',
          paramString: deviceSecret,
        );
        return jsonEncode(body);
      },
      // Decoration, not data: a failure must never raise the SP error dialog.
      errorCallback: () {},
    );
  }
}
