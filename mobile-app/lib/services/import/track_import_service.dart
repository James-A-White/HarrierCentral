import 'package:harrier_central/imports.dart';

import 'package:http/http.dart' as http;

/// Why an import could not proceed. The message is written for the user.
class TrackImportException implements Exception {
  const TrackImportException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// One activity found in an upload and what happened to it (the server's
/// ResultJson item, E5.F5.S7).
class ImportActivity {
  const ImportActivity({
    required this.index,
    required this.name,
    required this.outcome,
    this.format,
    this.sport,
    this.startUtc,
    this.endUtc,
    this.points = 0,
    this.distanceM = 0,
    this.eventId,
    this.eventName,
    this.kennelName,
    this.candidates = const <ImportCandidate>[],
    this.error,
  });

  factory ImportActivity.fromJson(Map<String, dynamic> j) => ImportActivity(
    index: (j['i'] as num?)?.toInt() ?? 0,
    name: (j['name'] as String?) ?? '',
    outcome: (j['outcome'] as String?) ?? 'pending',
    format: j['format'] as String?,
    sport: j['sport'] as String?,
    startUtc: DateTime.tryParse((j['startUtc'] as String?) ?? '')?.toUtc(),
    endUtc: DateTime.tryParse((j['endUtc'] as String?) ?? '')?.toUtc(),
    points: (j['points'] as num?)?.toInt() ?? 0,
    distanceM: (j['distanceM'] as num?)?.toInt() ?? 0,
    eventId: j['eventId'] as String?,
    eventName: j['eventName'] as String?,
    kennelName: j['kennelName'] as String?,
    candidates: ((j['candidates'] as List<dynamic>?) ?? const <dynamic>[])
        .map((dynamic c) => ImportCandidate.fromJson(c as Map<String, dynamic>))
        .toList(growable: false),
    error: j['error'] as String?,
  );

  final int index;
  final String name;

  /// imported | replaced | skippedExisting | noRun | noLocation | tooFar |
  /// held | unparseable | noTime | failed | pending
  final String outcome;
  final String? format;
  final String? sport;
  final DateTime? startUtc;
  final DateTime? endUtc;
  final int points;
  final int distanceM;
  final String? eventId;
  final String? eventName;
  final String? kennelName;
  final List<ImportCandidate> candidates;
  final String? error;

  bool get isHeld => outcome == 'held';
  bool get isImported => outcome == 'imported' || outcome == 'replaced';

  String get shortName {
    final String base = name.split('/').last;
    return base.isEmpty ? name : base;
  }

  /// A one-line, human reading of the outcome.
  String get outcomeText {
    switch (outcome) {
      case 'imported':
        return 'Imported to ${eventName ?? 'the run'}';
      case 'replaced':
        return 'Replaced your track on ${eventName ?? 'the run'}';
      case 'skippedExisting':
        return 'Skipped — you already have a track on ${eventName ?? 'that run'}';
      case 'noRun':
        return 'No hash run around that time';
      case 'noLocation':
        return 'A run matched on time but has no recorded start — skipped';
      case 'tooFar':
        return 'A run started around then, but more than a mile away';
      case 'held':
        return candidates.length > 1
            ? 'Which run? ${candidates.length} match'
            : 'Needs your confirmation';
      case 'unparseable':
        return 'Not a readable track file';
      case 'noTime':
        return 'No timestamps in the track';
      case 'failed':
        return 'Failed: ${error ?? 'unknown error'}';
      default:
        return 'Waiting…';
    }
  }
}

class ImportCandidate {
  const ImportCandidate({
    required this.eventId,
    required this.eventName,
    required this.kennelName,
    required this.hasLocation,
    this.startLocal,
    this.distanceMeters,
    this.existingTrackPoints = 0,
  });

  factory ImportCandidate.fromJson(Map<String, dynamic> j) => ImportCandidate(
    eventId: normalizeUuid(j['eventId'] as String),
    eventName: (j['eventName'] as String?) ?? 'Run',
    kennelName: (j['kennelName'] as String?) ?? '',
    hasLocation: j['hasLocation'] == true,
    startLocal: DateTime.tryParse((j['startLocal'] as String?) ?? ''),
    distanceMeters: (j['distanceMeters'] as num?)?.toInt(),
    existingTrackPoints: (j['existingTrackPoints'] as num?)?.toInt() ?? 0,
  );

  final String eventId;
  final String eventName;
  final String kennelName;
  final bool hasLocation;
  final DateTime? startLocal;
  final int? distanceMeters;
  final int existingTrackPoints;
}

/// A track-import job as the server reports it (hcapp_getTrackImports).
class TrackImportJob {
  const TrackImportJob({
    required this.jobId,
    required this.status,
    required this.kind,
    required this.nextIndex,
    required this.activities,
    this.fileName,
    this.activityCount,
    this.importedCount = 0,
    this.skippedCount = 0,
    this.heldCount = 0,
    this.errorMessage,
  });

  factory TrackImportJob.fromJson(Map<String, dynamic> j) {
    List<ImportActivity> acts = const <ImportActivity>[];
    final String? rj = j['resultJson'] as String?;
    if (rj != null && rj.isNotEmpty) {
      try {
        final dynamic decoded = jsonDecode(rj);
        acts = ((decoded as Map<String, dynamic>)['activities'] as List<dynamic>? ?? const <dynamic>[])
            .map((dynamic a) => ImportActivity.fromJson(a as Map<String, dynamic>))
            .toList(growable: false);
      } catch (_) {
        acts = const <ImportActivity>[];
      }
    }
    return TrackImportJob(
      jobId: normalizeUuid(j['jobId'] as String),
      fileName: j['fileName'] as String?,
      status: (j['status'] as num?)?.toInt() ?? 0,
      kind: (j['kind'] as num?)?.toInt() ?? 0,
      nextIndex: (j['nextIndex'] as num?)?.toInt() ?? 0,
      activityCount: (j['activityCount'] as num?)?.toInt(),
      importedCount: (j['importedCount'] as num?)?.toInt() ?? 0,
      skippedCount: (j['skippedCount'] as num?)?.toInt() ?? 0,
      heldCount: (j['heldCount'] as num?)?.toInt() ?? 0,
      errorMessage: j['errorMessage'] as String?,
      activities: acts,
    );
  }

  final String jobId;
  final String? fileName;

  /// 0 uploaded · 1 processing · 2 done · 3 failed
  final int status;

  /// 0 unknown · 1 gpx · 2 tcx · 3 fit · 4 zip
  final int kind;
  final int nextIndex;
  final int? activityCount;
  final int importedCount;
  final int skippedCount;
  final int heldCount;
  final String? errorMessage;
  final List<ImportActivity> activities;

  bool get isFinished => status == 2 || status == 3;
  bool get isArchive => kind == 4;
}

/// Uploads a track file and drives its import (E5.F5.S7).
///
/// The bytes go straight to blob storage with a SAS from
/// GetTrackImportUploadToken, in 4 MB blocks with progress — a Strava
/// archive can be hundreds of megabytes, so nothing is read into memory
/// whole and nothing passes through a function. Then the job is
/// registered (hcapp_submitTrackImport) and ProcessTrackImport is called
/// repeatedly; each call does a slice and returns the results so far, so a
/// single file resolves in one call and an archive streams its outcomes.
/// A held activity is resolved with the same function.
class TrackImportService {
  const TrackImportService();

  static const int blockSize = 4 * 1024 * 1024;
  static const Duration _blockTimeout = Duration(seconds: 120);
  static const Duration _processTimeout = Duration(seconds: 70);

  // ── Upload ────────────────────────────────────────────────────────────────

  /// Uploads [file] and registers the job. Calls [onProgress] with 0..1.
  Future<String> upload({
    required File file,
    required String fileName,
    void Function(double fraction)? onProgress,
  }) async {
    final String userId = currentUserId;
    final String deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    final String deviceSecret = getStringPref(StringPrefsEnum.deviceSecret) ?? '';

    // 1. The SAS and the job id.
    final http.Response tokenResp = await http
        .post(
          Uri.parse(TRACK_IMPORT_UPLOAD_TOKEN_URL),
          headers: const <String, String>{'content-type': 'application/json'},
          body: jsonEncode(<String, dynamic>{
            'deviceId': deviceId,
            'accessToken': Utilities.generateToken(
              userId,
              'hcapp_getTrackImportUploadToken',
              paramString: deviceSecret,
            ),
            'fileName': fileName,
          }),
        )
        .timeout(const Duration(seconds: 20));
    if (tokenResp.statusCode != 200) {
      throw TrackImportException(
        'Could not start the upload (${tokenResp.statusCode}). Please try again.',
      );
    }
    final Map<String, dynamic> token = jsonDecode(tokenResp.body) as Map<String, dynamic>;
    final String jobId = normalizeUuid(token['jobId'] as String);
    final String sasUrl = token['sasUrl'] as String;
    final String blobUrl = token['blobUrl'] as String;

    // 2. Block upload with progress.
    final int total = await file.length();
    if (total == 0) throw const TrackImportException('That file is empty.');
    final List<String> blockIds = <String>[];
    int sent = 0;
    int n = 0;
    final RandomAccessFile raf = await file.open();
    try {
      while (sent < total) {
        final int len = (total - sent).clamp(0, blockSize);
        final Uint8List chunk = await raf.read(len);
        final String blockId = base64.encode(
          utf8.encode(n.toString().padLeft(6, '0')),
        );
        final Uri put = Uri.parse(
          '$sasUrl&comp=block&blockid=${Uri.encodeQueryComponent(blockId)}',
        );
        final http.Response r = await http
            .put(put, headers: const <String, String>{'x-ms-blob-type': 'BlockBlob'}, body: chunk)
            .timeout(_blockTimeout);
        if (r.statusCode != 201) {
          throw TrackImportException(
            'The upload stopped at ${(100 * sent / total).round()}% '
            '(${r.statusCode}). Please try again.',
          );
        }
        blockIds.add(blockId);
        sent += len;
        n++;
        onProgress?.call(sent / total);
      }
    } finally {
      await raf.close();
    }
    final String blockList =
        '<?xml version="1.0" encoding="utf-8"?><BlockList>'
        '${blockIds.map((String b) => '<Latest>$b</Latest>').join()}'
        '</BlockList>';
    final http.Response commit = await http
        .put(
          Uri.parse('$sasUrl&comp=blocklist'),
          headers: const <String, String>{'content-type': 'application/xml'},
          body: blockList,
        )
        .timeout(_blockTimeout);
    if (commit.statusCode != 201) {
      throw TrackImportException(
        'The upload could not be completed (${commit.statusCode}). Please try again.',
      );
    }

    // 3. Register the job.
    final String raw = await ServiceCommon.sendHttpPost(() {
      return jsonEncode(<String, dynamic>{
        'queryType': 'submitTrackImport',
        'deviceId': deviceId,
        'jobId': jobId,
        'blobUrl': blobUrl,
        'fileName': fileName,
        'byteSize': total,
        'accessToken': Utilities.generateToken(
          userId,
          'hcapp_submitTrackImport',
          paramString: deviceSecret,
        ),
      });
    });
    if (raw.startsWith(ERROR_PREFIX)) {
      throw const TrackImportException(
        'The file uploaded but could not be registered. Please try again.',
      );
    }
    BootLogger.logBreadcrumb(
      'TrackImport: uploaded $fileName ($total B) as job $jobId',
    );
    return jobId;
  }

  // ── Process ───────────────────────────────────────────────────────────────

  /// One slice of processing; returns the job as it stands afterwards.
  Future<TrackImportJob> process(String jobId) => _processCall(jobId, null);

  /// Import held activity [index] to [eventId]; [replace] deletes an
  /// existing track first (the single-file Replace button).
  Future<TrackImportJob> resolve({
    required String jobId,
    required int index,
    required String eventId,
    bool replace = false,
  }) => _processCall(jobId, <String, dynamic>{
    'index': index,
    'eventId': normalizeUuid(eventId),
    'replace': replace,
  });

  Future<TrackImportJob> _processCall(String jobId, Map<String, dynamic>? resolve) async {
    final String userId = currentUserId;
    final String deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    final String deviceSecret = getStringPref(StringPrefsEnum.deviceSecret) ?? '';
    final http.Response r = await http
        .post(
          Uri.parse(PROCESS_TRACK_IMPORT_URL),
          headers: const <String, String>{'content-type': 'application/json'},
          body: jsonEncode(<String, dynamic>{
            'deviceId': deviceId,
            'accessToken': Utilities.generateToken(
              userId,
              'hcapp_getTrackImports',
              paramString: deviceSecret,
            ),
            'jobId': jobId,
            'resolve': ?resolve,
          }),
        )
        .timeout(_processTimeout);
    if (r.statusCode != 200) {
      String msg = 'The import could not be processed (${r.statusCode}).';
      try {
        final dynamic d = jsonDecode(r.body);
        if (d is Map && d['errorUserMessage'] is String) msg = d['errorUserMessage'] as String;
        if (d is Map && d['error'] is String) msg = d['error'] as String;
      } catch (_) {}
      throw TrackImportException(msg);
    }
    return TrackImportJob.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  /// The job as stored (no processing) — for reopening a past import.
  Future<TrackImportJob?> fetch(String jobId) async {
    final String userId = currentUserId;
    final String deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    final String deviceSecret = getStringPref(StringPrefsEnum.deviceSecret) ?? '';
    final String raw = await ServiceCommon.sendHttpPost(() {
      return jsonEncode(<String, dynamic>{
        'queryType': 'getTrackImports',
        'deviceId': deviceId,
        'jobId': jobId,
        'accessToken': Utilities.generateToken(
          userId,
          'hcapp_getTrackImports',
          paramString: deviceSecret,
        ),
      });
    });
    if (raw.startsWith(ERROR_PREFIX)) return null;
    final List<dynamic> rowsets = jsonDecode(raw) as List<dynamic>;
    if (rowsets.isEmpty || (rowsets[0] as List<dynamic>).isEmpty) return null;
    return TrackImportJob.fromJson((rowsets[0] as List<dynamic>)[0] as Map<String, dynamic>);
  }
}
