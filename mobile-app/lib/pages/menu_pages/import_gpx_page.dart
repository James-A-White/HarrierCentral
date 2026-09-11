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
  ImportGpxController({this.initialFilePath, this.autoPick = false});

  /// A file the OS handed to the app (see IncomingFileService) — uploaded
  /// on open instead of waiting for the user to pick one.
  final String? initialFilePath;

  /// Open the file picker as soon as the page is up (the Hash Runs app-bar
  /// button has already explained what will happen).
  final bool autoPick;

  final TrackImportService _service = const TrackImportService();

  final RxBool busy = false.obs;
  final RxnString fileName = RxnString();
  final RxString status = ''.obs;
  final RxDouble uploadProgress = 0.0.obs;
  final Rxn<TrackImportJob> job = Rxn<TrackImportJob>();

  bool _cancelled = false;

  @override
  void onReady() {
    super.onReady();
    final String? path = initialFilePath;
    if (path != null && path.isNotEmpty) {
      unawaited(loadPath(path));
    } else if (autoPick) {
      unawaited(pickFile());
    }
  }

  @override
  void onClose() {
    _cancelled = true;
    super.onClose();
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
      status.value = 'Finding your runs…';
      TrackImportJob j = await _service.process(jobId);
      job.value = j;
      while (!j.isFinished && !_cancelled) {
        status.value = _progressText(j);
        j = await _service.process(jobId);
        job.value = j;
      }
      status.value = _summaryText(j);
    } on TrackImportException catch (e) {
      status.value = e.message;
    } catch (e, s) {
      BootLogger.logError('[ImportGpxController._run]', e, s);
      status.value = 'The import failed. Please try again.';
    } finally {
      busy.value = false;
    }
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
    final String dist = a.distanceM > 0
        ? '${(a.distanceM * METERS_TO_MILES).toStringAsFixed(1)} mi'
        : '';
    return <String>[
      when,
      dist,
      if (a.sport != null) a.sport!,
    ].where((String x) => x.isNotEmpty).join('  ·  ');
  }
}

class ImportGpxPage extends StatelessWidget {
  const ImportGpxPage({super.key, this.initialFilePath, this.autoPick = false});

  /// Set when the OS handed the app a file; the page uploads it on open.
  final String? initialFilePath;

  /// Open the file picker straight away.
  final bool autoPick;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ImportGpxController>(
      init: ImportGpxController(
        initialFilePath: initialFilePath,
        autoPick: autoPick,
      ),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: ts_titleCondensed,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (detail.isNotEmpty) Text(detail, style: ts_alertDialogBody),
            Text(a.outcomeText, style: ts_alertDialogBody),
            if (a.isHeld)
              for (final ImportCandidate cand in a.candidates) ...<Widget>[
                const SizedBox(height: 6),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        '${cand.eventName} — ${cand.kennelName}\n'
                        '${ImportGpxController.describeStart(cand.startLocal)}'
                        '${cand.hasLocation ? '  ·  ${cand.distanceMeters} m from the track start' : '  ·  no recorded start'}'
                        '${cand.existingTrackPoints > 0 ? '  ·  you have a track here' : ''}',
                        style: ts_alertDialogBody,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: busy ? null : () => onResolve(cand),
                      child: Text(
                        cand.existingTrackPoints > 0 ? 'Replace' : 'Import',
                        style: ts_button,
                      ),
                    ),
                  ],
                ),
              ],
          ],
        ),
      ),
    );
  }
}
