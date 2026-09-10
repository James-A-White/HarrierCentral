import 'package:file_picker/file_picker.dart';
import 'package:harrier_central/imports.dart';

/// Import a GPX file as the user's own PackTrack trail (E5.F5.S6).
///
/// Flow: pick a file → parse it → ask the server which run it belongs to
/// (first point's time and position) → confirm → upload. A run with a
/// recorded start must be within a mile of the track's first point; a run
/// with none is accepted on time alone once the user confirms it. An
/// existing track on the chosen run is never silently overwritten: the user
/// is told and can replace it.
class ImportGpxController extends GetxController {
  ImportGpxController({this.initialFilePath, this.autoPick = false});

  /// A file the OS handed to the app (see IncomingFileService) — loaded on
  /// open instead of waiting for the user to pick one.
  final String? initialFilePath;

  /// Open the file picker as soon as the page is up (the Hash Runs app-bar
  /// button has already explained what will happen).
  final bool autoPick;

  final GpxImportService _service = const GpxImportService();

  final RxBool busy = false.obs;
  final RxnString fileName = RxnString();
  final RxString status = ''.obs;
  final RxList<RunCandidate> candidates = <RunCandidate>[].obs;
  final RxnString importedEventName = RxnString();

  List<UserEventLocation>? _points;

  int get pointCount => _points?.length ?? 0;

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

  Future<void> pickFile() async {
    if (busy.value) return;
    // FileType.any: the picker's own extension filter needs a registered UTI
    // on iOS; the extension is checked in [_load] instead.
    final FilePickerResult? picked = await FilePicker.pickFiles(
      type: FileType.any,
      withData: true,
    );
    final PlatformFile? file = picked?.files.singleOrNull;
    if (file == null) return;
    await _load(name: file.name, bytes: file.bytes);
  }

  /// A file already on disk — handed to the app by the OS.
  Future<void> loadPath(String path) async {
    if (busy.value) return;
    Uint8List? bytes;
    try {
      bytes = await File(path).readAsBytes();
    } catch (_) {
      bytes = null;
    }
    await _load(name: path.split('/').last, bytes: bytes);
  }

  Future<void> _load({required String name, required Uint8List? bytes}) async {
    busy.value = true;
    candidates.clear();
    importedEventName.value = null;
    _points = null;
    try {
      fileName.value = name;
      if (!name.toLowerCase().endsWith('.gpx')) {
        status.value = 'Please choose a .gpx file.';
        return;
      }
      if (bytes == null) {
        status.value = 'Could not read that file.';
        return;
      }
      status.value = 'Reading $name…';
      final ParsedGpx parsed = _service.parse(utf8.decode(bytes));
      final List<UserEventLocation> points = _service.buildPoints(parsed);
      _points = points;

      status.value = 'Finding the run…';
      final List<RunCandidate> found = await _service.findRuns(parsed);
      final List<RunCandidate> passing = found
          .where((c) => c.passesDistance)
          .toList(growable: false);
      if (passing.isEmpty) {
        status.value = found.isEmpty
            ? 'No run started around ${_fmtWhen(parsed.firstTimestampMs)}.'
            : 'A run started around then, but its recorded start is '
                  '${_fmtDistance(found.first.distanceMeters)} from where '
                  'this track begins — more than a mile, so it was not '
                  'matched.';
        return;
      }
      candidates.assignAll(passing);
      status.value = passing.length == 1
          ? 'Track of ${parsed.points.length} points, '
                '${points.length} after thinning. Import it to this run?'
          : 'Track of ${parsed.points.length} points, '
                '${points.length} after thinning. Which run is it?';
    } on GpxImportException catch (e) {
      status.value = e.message;
    } catch (e, s) {
      BootLogger.logError('[ImportGpxController.pickFile]', e, s);
      status.value = 'Something went wrong reading that file.';
    } finally {
      busy.value = false;
    }
  }

  Future<void> importTo(RunCandidate run) async {
    final List<UserEventLocation>? points = _points;
    if (busy.value || points == null) return;

    if (!run.hasLocation) {
      final bool? go = await Utilities.showAlert(
        'No recorded start',
        '${run.eventName} (${run.kennelName}) has no recorded start '
            'location, so it was matched on time alone. Import the track to '
            'this run?',
        'Import',
        showCancelButton: true,
      );
      if (go != true) return;
    }

    if (run.hasExistingTrack) {
      final bool? replace = await Utilities.showAlert(
        'You already have a track on this run',
        'Your PackTrack trail for ${run.eventName} has '
            '${run.existingTrackPoints} points. Importing this file will '
            'REPLACE it — the existing trail is deleted first.',
        'Replace',
        showCancelButton: true,
      );
      if (replace != true) return;
    }

    busy.value = true;
    try {
      if (run.hasExistingTrack) {
        status.value = 'Removing the existing track…';
        await _service.deleteExistingTrack(run.eventId);
      }
      status.value = 'Uploading ${points.length} points…';
      final int sent = await _service.importTrack(
        eventId: run.eventId,
        points: points,
      );
      candidates.clear();
      importedEventName.value = run.eventName;
      status.value =
          'Done — $sent points imported as your track for ${run.eventName}. '
          'It will show on the run\'s map now and be archived tonight.';
    } on GpxImportException catch (e) {
      status.value = e.message;
    } catch (e, s) {
      BootLogger.logError('[ImportGpxController.importTo]', e, s);
      status.value = 'The import failed. Please try again.';
    } finally {
      busy.value = false;
    }
  }

  static String _fmtWhen(int ms) {
    final DateTime local = DateTime.fromMillisecondsSinceEpoch(ms).toLocal();
    return '${local.year}-${_two(local.month)}-${_two(local.day)} '
        '${_two(local.hour)}:${_two(local.minute)}';
  }

  static String _two(int v) => v.toString().padLeft(2, '0');

  static String _fmtDistance(int? metres) {
    if (metres == null) return 'an unknown distance';
    final double miles = metres * METERS_TO_MILES;
    return miles >= 10
        ? '${miles.round()} miles'
        : '${miles.toStringAsFixed(1)} miles';
  }

  static String describeStart(RunCandidate c) {
    final DateTime? l = c.startLocal;
    if (l == null) return '';
    return '${l.year}-${_two(l.month)}-${_two(l.day)} '
        '${_two(l.hour)}:${_two(l.minute)}';
  }
}

class ImportGpxPage extends StatelessWidget {
  const ImportGpxPage({super.key, this.initialFilePath, this.autoPick = false});

  /// Set when the OS handed the app a file; the page loads it on open.
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
            title: Text('Import GPX Track', style: ts_appBarTitle),
          ),
          body: Obx(() {
            final bool busy = c.busy.value;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                Text(
                  'Choose a GPX file from your watch or running app. The run '
                  'is found from the track\'s first point: its time, and its '
                  'position within a mile of the run\'s recorded start. The '
                  'track then becomes your PackTrack trail for that run.',
                  style: ts_alertDialogBody,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: busy ? null : c.pickFile,
                  icon: const Icon(Icons.upload_file, color: Colors.white),
                  label: Text(
                    c.fileName.value == null
                        ? 'Choose GPX file'
                        : 'Choose a different file',
                    style: ts_button,
                  ),
                ),
                if (c.fileName.value != null) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(c.fileName.value!, style: ts_alertDialogBody),
                ],
                if (busy) ...<Widget>[
                  const SizedBox(height: 16),
                  const Center(child: CircularProgressIndicator()),
                ],
                if (c.status.value.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 16),
                  Text(c.status.value, style: ts_alertDialogBody),
                ],
                for (final RunCandidate run in c.candidates) ...<Widget>[
                  const SizedBox(height: 12),
                  Card(
                    child: ListTile(
                      title: Text(run.eventName, style: ts_titleCondensed),
                      subtitle: Text(
                        '${run.kennelName}\n'
                        '${ImportGpxController.describeStart(run)}'
                        '${run.hasLocation ? '  ·  start ${run.distanceMeters} m from the track\'s first point' : '  ·  no recorded start location'}'
                        '${run.hasExistingTrack ? '\nYou already have a track here (${run.existingTrackPoints} points)' : ''}',
                        style: ts_alertDialogBody,
                      ),
                      isThreeLine: true,
                      trailing: ElevatedButton(
                        onPressed: busy ? null : () => c.importTo(run),
                        child: Text('Import', style: ts_button),
                      ),
                    ),
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
