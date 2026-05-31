import 'package:harrier_central/imports.dart';

// ---------------------------------------------------------------------------
// Persistent queue for photos taken while offline.
//
// Each entry holds the compressed JPEG at a stable path in the app's
// documents directory plus everything needed to complete the upload later:
// SAS token request params, DB record params, and the GPS position at
// capture time.
//
// GPS track markers (PHO::photoId) are NOT re-enqueued when processing
// the queue. The photo is recorded in the DB and appears in Hash Flash;
// it simply won't appear as a map pin on the live run track, which is
// an acceptable trade-off for the offline case.
// ---------------------------------------------------------------------------

class PendingPhotoUpload {
  const PendingPhotoUpload({
    required this.photoId,
    required this.eventId,
    required this.kennelId,
    required this.kennelSlug,
    required this.eventNumber,
    required this.sharingOverride,
    required this.filePath,
    required this.lat,
    required this.lng,
    required this.savedAtMs,
    this.caption,
    this.assetId,
  });

  final String photoId;
  final String eventId;
  final String kennelId;
  final String kennelSlug;
  final int eventNumber;
  final int sharingOverride;   // 0 = private, 1 = share
  final String filePath;       // stable path in app documents dir
  final double lat;
  final double lng;
  final int savedAtMs;
  final String? caption;
  final String? assetId;       // camera roll asset ID if saved there

  Map<String, dynamic> toJson() => {
    'photoId': photoId,
    'eventId': eventId,
    'kennelId': kennelId,
    'kennelSlug': kennelSlug,
    'eventNumber': eventNumber,
    'sharingOverride': sharingOverride,
    'filePath': filePath,
    'lat': lat,
    'lng': lng,
    'savedAtMs': savedAtMs,
    if (caption != null) 'caption': caption,
    if (assetId != null) 'assetId': assetId,
  };

  factory PendingPhotoUpload.fromJson(Map<String, dynamic> j) =>
      PendingPhotoUpload(
        photoId: j['photoId'] as String,
        eventId: j['eventId'] as String,
        kennelId: j['kennelId'] as String,
        kennelSlug: j['kennelSlug'] as String,
        eventNumber: (j['eventNumber'] as num).toInt(),
        sharingOverride: (j['sharingOverride'] as num).toInt(),
        filePath: j['filePath'] as String,
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
        savedAtMs: (j['savedAtMs'] as num).toInt(),
        caption: j['caption'] as String?,
        assetId: j['assetId'] as String?,
      );
}

class KennelPhotoUploadQueue {
  static const String _storageKey = 'hc_pendingPhotoUploads';

  static List<PendingPhotoUpload> load() {
    final raw = GetStorage().read<String>(_storageKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(PendingPhotoUpload.fromJson)
          .toList();
    } catch (e) {
      debugPrint('[KennelPhotoUploadQueue] load failed: $e');
      return [];
    }
  }

  static Future<void> enqueue(PendingPhotoUpload entry) async {
    final entries = load()..add(entry);
    await _save(entries);
    debugPrint('[KennelPhotoUploadQueue] enqueued ${entry.photoId} (${entries.length} total)');
  }

  static Future<void> remove(String photoId) async {
    final entries = load().where((e) => e.photoId != photoId).toList();
    await _save(entries);
    debugPrint('[KennelPhotoUploadQueue] removed $photoId (${entries.length} remaining)');
  }

  static int get count => load().length;

  static Future<void> _save(List<PendingPhotoUpload> entries) async {
    await GetStorage().write(
      _storageKey,
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
  }
}
