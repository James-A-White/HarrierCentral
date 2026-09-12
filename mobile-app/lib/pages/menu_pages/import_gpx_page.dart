import 'package:file_picker/file_picker.dart';
import 'package:harrier_central/imports.dart';

/// Import a track file as PackTrack trails (E5.F5.S6 / S7).
///
/// One button, any file: a GPX, TCX or FIT activity, or a whole Strava /
/// Garmin archive (zip). The file goes straight to blob storage, then the
/// server is asked to process it in slices while this page shows each
/// activity's outcome as it lands — a single file resolves in seconds, an
/// archive streams. The server applies the rules: a run that already has a
/// track is never overwritten by an archive; a run with no recorded start
/// is skipped; several runs on one day are held for the hasher to choose.
/// A single file is held instead of skipped in those two cases, so the
/// person can confirm or replace right here.
class ImportGpxController extends GetxController {
  ImportGpxController({this.initialFilePath});

  /// A file the OS handed to the app (see IncomingFileService) — uploaded
  /// on open instead of waiting for the user to pick one.
  final String? initialFilePath;

  final TrackImportService _service = const TrackImportService();

  final RxBool busy = false.obs;
  final RxnString fileName = RxnString();
  final RxString status = ''.obs;
  final RxDouble uploadProgress = 0.0.obs;
  final Rxn<TrackImportJob> job = Rxn<TrackImportJob>();

  /// Live position while the server works: activities checked so far, of
  /// how many, and imported so far. Polled every few seconds between the
  /// slice responses, which only arrive every ~40 s.
  final RxInt checked = 0.obs;
  final RxnInt total = RxnInt();
  final RxInt importedSoFar = 0.obs;
  Timer? _progressTimer;

  /// Earlier uploads, newest first. Their files are kept, so any of them
  /// can be run again — the way to pick up runs whose start point was
  /// fixed after the first pass, without transferring the archive again.
  final RxList<TrackImportJob> previous = <TrackImportJob>[].obs;

  bool _cancelled = false;

  @override
  void onReady() {
    super.onReady();
    unawaited(_loadPrevious());
    // The page opens on its own explanation and the Choose a file button;
    // it no longer throws a file browser at the user (James, 2026-09-12).
    // A file the OS handed us is still loaded straight away.
    final String? path = initialFilePath;
    if (path != null && path.isNotEmpty) {
      unawaited(loadPath(path));
    }
  }

  Future<void> _loadPrevious() async {
    try {
      final List<TrackImportJob> jobs = await _service.fetchRecent();
      if (_cancelled) return;
      previous.assignAll(jobs.where((TrackImportJob j) => j.isFinished));
    } catch (e, s) {
      BootLogger.logError('[ImportGpxController._loadPrevious]', e, s);
    }
  }

  @override
  void onClose() {
    _cancelled = true;
    _progressTimer?.cancel();
    super.onClose();
  }

  void _startProgressPolling(String jobId) {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      try {
        final p = await _service.fetchProgress(jobId);
        if (p == null || _cancelled) return;
        checked.value = p.nextIndex;
        total.value = p.activityCount;
        importedSoFar.value = p.imported;
      } catch (_) {
        // A missed poll is nothing; the next one or the slice response updates.
      }
    });
  }

  void _stopProgressPolling() {
    _progressTimer?.cancel();
    _progressTimer = null;
  }

  Future<void> pickFile() async {
    if (busy.value) return;
    // FileType.any: the picker's own extension filter needs a registered UTI
    // on iOS; the server decides the type from the bytes anyway.
    final FilePickerResult? picked = await FilePicker.pickFiles(
      type: FileType.any,
    );
    final PlatformFile? file = picked?.files.singleOrNull;
    if (file == null || file.path == null) return;
    await _run(File(file.path!), file.name);
  }

  /// A file already on disk — handed to the app by the OS.
  Future<void> loadPath(String path) async {
    if (busy.value) return;
    await _run(File(path), path.split('/').last);
  }

  Future<void> _run(File file, String name) async {
    busy.value = true;
    job.value = null;
    uploadProgress.value = 0;
    fileName.value = name;
    try {
      status.value = 'Uploading $name…';
      final String jobId = await _service.upload(
        file: file,
        fileName: name,
        onProgress: (double f) => uploadProgress.value = f,
      );
      if (_cancelled) return;
      await _follow(jobId);
    } on TrackImportException catch (e) {
      status.value = e.message;
    } catch (e, s) {
      BootLogger.logError('[ImportGpxController._run]', e, s);
      status.value = 'The import failed. Please try again.';
    } finally {
      busy.value = false;
    }
  }

  /// Calls the server for slices until the job is done. A slice that times
  /// out or fails on the wire is NOT a failed import — the server carries on
  /// with it — so the loop waits, reads the job as stored, and continues from
  /// wherever the server got to. It gives up only when nothing has moved
  /// after several attempts, and the nightly backstop finishes the job then.
  /// Run a kept upload again from its first activity (see [previous]).
  Future<void> reimport(TrackImportJob prev) async {
    if (busy.value) return;
    final String name = prev.fileName ?? 'that file';
    final bool? ok = await Utilities.showAlert(
      'Re-import $name?',
      'Every activity in the file is checked against your runs again, '
          'using the file already uploaded. Runs that already have your '
          'track are left alone; runs whose start point has been fixed '
          'since, and runs added since, are found now.',
      'Re-import',
      showCancelButton: true,
    );
    if (ok != true) return;
    busy.value = true;
    job.value = null;
    uploadProgress.value = 0;
    fileName.value = prev.fileName;
    try {
      await _follow(prev.jobId, reimport: true);
    } on TrackImportException catch (e) {
      status.value = e.message;
    } catch (e, s) {
      BootLogger.logError('[ImportGpxController.reimport]', e, s);
      status.value = 'That re-import failed. Please try again.';
    } finally {
      busy.value = false;
      unawaited(_loadPrevious());
    }
  }

  /// Clear an earlier upload off the list. The file and everything already
  /// imported from it stay put — this only tidies the list.
  Future<void> deleteUpload(TrackImportJob prev) async {
    if (busy.value) return;
    final String name = prev.fileName ?? 'that file';
    final bool? ok = await Utilities.showAlert(
      'Remove $name from the list?',
      'The runs this upload already imported keep their tracks. Only the '
          'entry in this list goes, so you can no longer re-import from it.',
      'Remove',
      showCancelButton: true,
    );
    if (ok != true) return;
    busy.value = true;
    try {
      await _service.delete(prev.jobId);
      previous.removeWhere((TrackImportJob j) => j.jobId == prev.jobId);
    } on TrackImportException catch (e) {
      status.value = e.message;
    } catch (e, s) {
      BootLogger.logError('[ImportGpxController.deleteUpload]', e, s);
      status.value = 'That upload could not be removed. Please try again.';
    } finally {
      busy.value = false;
      unawaited(_loadPrevious());
    }
  }

  /// Drive a registered job to completion, showing progress as it goes.
  Future<void> _follow(String jobId, {bool reimport = false}) async {
    status.value = 'Finding your runs…';
    checked.value = 0;
    total.value = null;
    importedSoFar.value = 0;
    _startProgressPolling(jobId);
    TrackImportJob j;
    try {
      j = await _driveToCompletion(jobId, reimportFirst: reimport);
    } finally {
      _stopProgressPolling();
    }
    checked.value = j.activityCount ?? j.activities.length;
    total.value = j.activityCount ?? j.activities.length;
    importedSoFar.value = j.importedCount;
    status.value = _summaryText(j);
    unawaited(_loadPrevious());
  }

  Future<TrackImportJob> _driveToCompletion(
    String jobId, {
    bool reimportFirst = false,
  }) async {
    int stalls = 0;
    int lastIndex = -1;
    bool first = true;
    TrackImportJob? j;
    while (!_cancelled) {
      try {
        // The restart flag rides on the first call only; a retry after a
        // timeout must continue the job, not restart it again.
        final bool restart = reimportFirst && first;
        first = false;
        j = await _service.process(jobId, reimport: restart);
        stalls = 0;
      } catch (e) {
        BootLogger.logBreadcrumb('TrackImport: slice failed ($e) — polling');
        await Future<void>.delayed(const Duration(seconds: 5));
        final TrackImportJob? stored = await _service.fetch(jobId);
        if (stored != null) j = stored;
        if (j == null || j.nextIndex == lastIndex) {
          if (++stalls >= 4) {
            throw const TrackImportException(
              'The import stopped responding. What was done so far is kept, '
              'and the rest will be finished overnight — check back tomorrow.',
            );
          }
        } else {
          stalls = 0;
        }
      }
      job.value = j;
      if (j == null) continue;
      checked.value = j.nextIndex;
      total.value = j.activityCount;
      importedSoFar.value = j.importedCount;
      if (j.isFinished) return j;
      lastIndex = j.nextIndex;
      status.value = _progressText(j);
    }
    return j ?? (throw const TrackImportException('Cancelled.'));
  }

  /// A held activity: the user picked a run (or confirmed the only one).
  Future<void> resolve(ImportActivity a, ImportCandidate c) async {
    final TrackImportJob? j = job.value;
    if (busy.value || j == null) return;
    bool replace = false;
    if (c.existingTrackPoints > 0) {
      final bool? ok = await Utilities.showAlert(
        'You already have a track on this run',
        'Your PackTrack trail for ${c.eventName} has ${c.existingTrackPoints} '
            'points. Importing this activity will REPLACE it — the existing '
            'trail is deleted first.',
        'Replace',
        showCancelButton: true,
      );
      if (ok != true) return;
      replace = true;
    } else if (!c.hasLocation) {
      final bool? ok = await Utilities.showAlert(
        'No recorded start',
        '${c.eventName} (${c.kennelName}) has no recorded start location, so '
            'it was matched on time alone. Import the track to this run?',
        'Import',
        showCancelButton: true,
      );
      if (ok != true) return;
    }
    busy.value = true;
    try {
      status.value = 'Importing to ${c.eventName}…';
      final TrackImportJob updated = await _service.resolve(
        jobId: j.jobId,
        index: a.index,
        eventId: c.eventId,
        replace: replace,
      );
      job.value = updated;
      status.value = _summaryText(updated);
    } on TrackImportException catch (e) {
      status.value = e.message;
    } catch (e, s) {
      BootLogger.logError('[ImportGpxController.resolve]', e, s);
      status.value = 'That import failed. Please try again.';
    } finally {
      busy.value = false;
    }
  }

  static String _progressText(TrackImportJob j) {
    final int? total = j.activityCount;
    if (total == null || total <= 1) return 'Finding your runs…';
    return 'Checked ${j.nextIndex} of $total activities — '
        '${j.importedCount} imported so far…';
  }

  static String _summaryText(TrackImportJob j) {
    if (j.status == 3) return j.errorMessage ?? 'The import failed.';
    final int total = j.activityCount ?? j.activities.length;
    if (total == 1) {
      final ImportActivity? a = j.activities.singleOrNull;
      return a?.outcomeText ?? 'Done.';
    }
    final StringBuffer b = StringBuffer(
      'Done — $total activities: ${j.importedCount} imported',
    );
    if (j.heldCount > 0) b.write(', ${j.heldCount} need a look');
    if (j.skippedCount > 0) b.write(', ${j.skippedCount} skipped');
    b.write(
      '. Imported tracks show on their runs now and are archived tonight.',
    );
    return b.toString();
  }

  static String _two(int v) => v.toString().padLeft(2, '0');

  static String describeStart(DateTime? l) {
    if (l == null) return '';
    return '${l.year}-${_two(l.month)}-${_two(l.day)} '
        '${_two(l.hour)}:${_two(l.minute)}';
  }

  static String describeActivity(ImportActivity a) {
    final DateTime? s = a.startUtc?.toLocal();
    final String when = s == null ? '' : describeStart(s);
    // The units the hasher chose in Settings, not miles for everyone
    // (James, 2026-09-12). An imported activity has no run yet, so Auto
    // falls back to the device locale inside prefersImperial.
    final bool imperial = Utilities.prefersImperial();
    final String dist = a.distanceM > 0
        ? imperial
              ? '${(a.distanceM * METERS_TO_MILES).toStringAsFixed(1)} mi'
              : '${(a.distanceM / 1000).toStringAsFixed(1)} km'
        : '';
    return <String>[
      when,
      dist,
      if (a.sport != null) a.sport!,
    ].where((String x) => x.isNotEmpty).join('  ·  ');
  }
}

class ImportGpxPage extends StatelessWidget {
  const ImportGpxPage({super.key, this.initialFilePath});

  /// Set when the OS handed the app a file; the page uploads it on open.
  final String? initialFilePath;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ImportGpxController>(
      init: ImportGpxController(initialFilePath: initialFilePath),
      builder: (ImportGpxController c) {
        return AppScaffold(
          appBar: AppBar(
            backgroundColor: themeAppBarBackground,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text('Import Tracks', style: ts_appBarTitle),
          ),
          body: Obx(() {
            final bool busy = c.busy.value;
            final TrackImportJob? j = c.job.value;
            final double up = c.uploadProgress.value;
            final bool uploading = busy && j == null && up > 0 && up < 1;
            final List<ImportActivity> ordered = j == null
                ? const <ImportActivity>[]
                : <ImportActivity>[
                    ...j.activities.where((ImportActivity a) => a.isHeld),
                    ...j.activities.where((ImportActivity a) => !a.isHeld),
                  ];
            return ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                Text(
                  'Choose a GPX, TCX or FIT file from your watch or running '
                  'app — or a whole Strava or Garmin archive (zip). Harrier '
                  'Central finds the hash run each track belongs to, from the '
                  'time and place of its first point, and uploads it as your '
                  'PackTrack trail for that run. Runs you already have a track '
                  'on are left alone.',
                  style: ts_alertDialogBody,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: busy ? null : c.pickFile,
                  icon: const Icon(Icons.upload_file, color: Colors.white),
                  label: Text(
                    c.fileName.value == null
                        ? 'Choose a file'
                        : 'Choose a different file',
                    style: ts_button,
                  ),
                ),
                if (c.fileName.value != null) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(c.fileName.value!, style: ts_alertDialogBody),
                ],
                if (uploading) ...<Widget>[
                  const SizedBox(height: 12),
                  LinearProgressIndicator(value: up),
                  const SizedBox(height: 4),
                  Text(
                    'Uploading… ${(up * 100).round()}%',
                    style: ts_alertDialogBody,
                  ),
                ] else if (busy &&
                    c.total.value != null &&
                    c.total.value! > 1) ...<Widget>[
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: (c.checked.value / c.total.value!).clamp(0.0, 1.0),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${c.checked.value} of ${c.total.value} activities checked'
                    '  ·  ${c.importedSoFar.value} imported',
                    style: ts_alertDialogBody,
                  ),
                ] else if (busy) ...<Widget>[
                  const SizedBox(height: 16),
                  const Center(child: CircularProgressIndicator()),
                ],
                if (c.status.value.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 16),
                  Text(c.status.value, style: ts_alertDialogBody),
                ],
                for (final ImportActivity a in ordered) ...<Widget>[
                  const SizedBox(height: 10),
                  _ActivityCard(
                    activity: a,
                    title: (j != null && j.isArchive)
                        ? a.shortName
                        : (c.fileName.value ?? a.shortName),
                    busy: busy,
                    onResolve: (ImportCandidate cand) => c.resolve(a, cand),
                  ),
                ],
                if (c.previous.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 24),
                  Text('Previous uploads', style: ts_alertDialogTitle),
                  const SizedBox(height: 4),
                  Text(
                    'Your files are kept. Re-import one to check its '
                    'activities against your runs again — for runs whose '
                    'start point was fixed after the first pass.',
                    style: ts_alertDialogBody,
                  ),
                  for (final TrackImportJob p in c.previous) ...<Widget>[
                    const SizedBox(height: 10),
                    _PreviousUploadCard(
                      job: p,
                      busy: busy,
                      onReimport: () => c.reimport(p),
                      onDelete: () => c.deleteUpload(p),
                    ),
                  ],
                ],
              ],
            );
          }),
        );
      },
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.activity,
    required this.title,
    required this.busy,
    required this.onResolve,
  });

  final ImportActivity activity;
  final String title;
  final bool busy;
  final void Function(ImportCandidate) onResolve;

  @override
  Widget build(BuildContext context) {
    final ImportActivity a = activity;
    final IconData icon = a.isImported
        ? Icons.check_circle
        : a.isHeld
        ? Icons.help_outline
        : Icons.remove_circle_outline;
    final Color color = a.isImported
        ? Colors.green.shade700
        : a.isHeld
        ? Colors.orange.shade800
        : Colors.grey;
    final String detail = ImportGpxController.describeActivity(a);
    // On the white card: dark text throughout.
    final TextStyle heading = ts_alertDialogTitle.copyWith(fontSize: 18);
    final TextStyle body = ts_alertDialogBody.copyWith(fontSize: 15);
    final TextStyle small = ts_alertDialogBody.copyWith(
      fontSize: 13,
      color: Colors.black54,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(detail.isNotEmpty ? detail : title, style: heading),
                      if (detail.isNotEmpty)
                        Text(
                          title,
                          style: small,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 2),
                      Text(
                        a.outcomeText,
                        style: body.copyWith(
                          color: a.isHeld
                              ? Colors.orange.shade900
                              : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (a.isHeld) ...<Widget>[
              const SizedBox(height: 6),
              for (final ImportCandidate cand in a.candidates)
                _CandidateRow(
                  candidate: cand,
                  busy: busy,
                  onResolve: () => onResolve(cand),
                ),
            ] else
              const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}

/// One run the hasher can choose for a held activity: name, kennel, when
/// and how far, a flag if they already have a track there, and its button.
class _CandidateRow extends StatelessWidget {
  const _CandidateRow({
    required this.candidate,
    required this.busy,
    required this.onResolve,
  });

  final ImportCandidate candidate;
  final bool busy;
  final VoidCallback onResolve;

  @override
  Widget build(BuildContext context) {
    final ImportCandidate c = candidate;
    final TextStyle name = ts_alertDialogTitle.copyWith(fontSize: 17);
    final TextStyle line = ts_alertDialogBody.copyWith(fontSize: 14);
    final TextStyle small = ts_alertDialogBody.copyWith(
      fontSize: 13,
      color: Colors.black54,
    );
    final String when = ImportGpxController.describeStart(c.startLocal);
    final int? away = c.distanceMeters;
    final String gap = away == null
        ? ''
        : Utilities.prefersImperial()
        ? '${(away * METERS_TO_YARDS).round()} yd'
        : '$away m';
    final String where = c.hasLocation
        ? '$gap from where the track starts'
        : 'no recorded start location';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(c.eventName, style: name),
                    Text(c.kennelName, style: small),
                    const SizedBox(height: 4),
                    Text('$when  ·  $where', style: line),
                    if (c.existingTrackPoints > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'You already have a track on this run',
                          style: line.copyWith(color: Colors.orange.shade900),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: busy ? null : onResolve,
                style: ElevatedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                child: Text(
                  c.existingTrackPoints > 0 ? 'Replace' : 'Import',
                  style: ts_button,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One earlier upload: name, when, what it found, and a Re-import button.
class _PreviousUploadCard extends StatelessWidget {
  const _PreviousUploadCard({
    required this.job,
    required this.busy,
    required this.onReimport,
    required this.onDelete,
  });

  final TrackImportJob job;
  final bool busy;
  final VoidCallback onReimport;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final DateTime? when = job.uploadedAt?.toLocal();
    final int? total = job.activityCount;
    final String found = job.status == 3
        ? (job.errorMessage ?? 'Failed')
        : total == null
        ? ''
        : '$total ${total == 1 ? 'activity' : 'activities'}'
              '  ·  ${job.importedCount} imported'
              '${job.heldCount > 0 ? '  ·  ${job.heldCount} held' : ''}';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  job.fileName ?? 'Upload',
                  style: ts_alertDialogBody,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (when != null)
                  Text(
                    ImportGpxController.describeStart(when),
                    style: ts_alertDialogBody,
                  ),
                if (found.isNotEmpty) Text(found, style: ts_alertDialogBody),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              ElevatedButton(
                onPressed: busy ? null : onReimport,
                child: Text('Re-import', style: ts_button),
              ),
              const SizedBox(height: 6),
              ElevatedButton(
                onPressed: busy ? null : onDelete,
                child: Text('Remove', style: ts_button),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
