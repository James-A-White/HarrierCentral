import 'package:harrier_central/imports.dart';
import 'package:harrier_central/services/photos/camera_roll_scan_service.dart';
import 'package:harrier_central/services/photos/run_photo_sweep_service.dart';
import 'package:photo_manager/photo_manager.dart' hide LatLng;

/// Finds this run's photos in the camera roll and lets the hasher pick which
/// to send (E6.F2.S5). Nothing goes up on its own: the sweep proposes, the
/// hasher ticks, and the notice says plainly where the photos may end up.
class RunPhotoSweepController extends GetxController {
  RunPhotoSweepController({required this.eventId, required this.eventName});

  final String eventId;
  final String eventName;

  final RunPhotoSweepService _service = const RunPhotoSweepService();

  final RxBool busy = false.obs;
  final RxString status = ''.obs;
  final RxnString blocked = RxnString();
  final Rxn<RunScanResult> result = Rxn<RunScanResult>();
  final RxSet<String> chosen = <String>{}.obs;
  final RxInt uploadDone = 0.obs;
  final RxInt uploadTotal = 0.obs;

  @override
  void onReady() {
    super.onReady();
    unawaited(scan());
  }

  /// The photos still to send — the ones already up are shown but never
  /// offered again.
  List<PhotoCandidate> get offerable =>
      result.value?.candidates
          .where((PhotoCandidate c) => !c.alreadyUploaded)
          .toList(growable: false) ??
      const <PhotoCandidate>[];

  Future<void> scan() async {
    busy.value = true;
    blocked.value = null;
    status.value = 'Looking through your photos…';
    try {
      final PermissionState p = await _service.requestAccess();
      if (!p.hasAccess) {
        blocked.value =
            'Harrier Central needs access to your photos to find the ones '
            'from this run. You can grant it in Settings.';
        return;
      }
      final List<RunScanResult> found = await _service.sweep(eventId: eventId);
      result.value = found.isEmpty ? null : found.first;
      chosen
        ..clear()
        ..addAll(offerable.map((PhotoCandidate c) => c.asset.id));
      status.value = '';
    } catch (e, s) {
      BootLogger.logError('[RunPhotoSweepController.scan]', e, s);
      status.value = 'Those photos could not be checked. Please try again.';
    } finally {
      busy.value = false;
    }
  }

  void toggle(String assetId) {
    if (chosen.contains(assetId)) {
      chosen.remove(assetId);
    } else {
      chosen.add(assetId);
    }
  }

  Future<void> send() async {
    final RunScanResult? r = result.value;
    if (r == null || chosen.isEmpty || busy.value) return;
    final List<PhotoCandidate> picked = offerable
        .where((PhotoCandidate c) => chosen.contains(c.asset.id))
        .toList(growable: false);
    if (picked.isEmpty) return;

    final bool? ok = await Utilities.showAlert(
      'Send ${picked.length} ${picked.length == 1 ? 'photo' : 'photos'}?',
      'They go to your Hash Flash for review. Approved photos appear on the '
          'run and on the kennel\'s public website, so anyone with the link '
          'can see them.',
      'Send',
      showCancelButton: true,
    );
    if (ok != true) return;

    busy.value = true;
    uploadDone.value = 0;
    uploadTotal.value = picked.length;
    status.value = 'Sending…';
    try {
      final ({int sent, int failed}) res = await _service.upload(
        run: r.run,
        chosen: picked,
        onProgress: (int d, int t) => uploadDone.value = d,
      );
      status.value = res.failed == 0
          ? '${res.sent} sent for review.'
          : '${res.sent} sent, ${res.failed} could not be sent.';
      await scan(); // refresh what is already up
    } catch (e, s) {
      BootLogger.logError('[RunPhotoSweepController.send]', e, s);
      status.value = 'Those photos could not be sent. Please try again.';
    } finally {
      busy.value = false;
      uploadTotal.value = 0;
    }
  }
}

class RunPhotoSweepPage extends StatelessWidget {
  const RunPhotoSweepPage({
    super.key,
    required this.eventId,
    required this.eventName,
  });

  final String eventId;
  final String eventName;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<RunPhotoSweepController>(
      init: RunPhotoSweepController(eventId: eventId, eventName: eventName),
      global: false,
      builder: (RunPhotoSweepController c) {
        return AppScaffold(
          appBar: AppBar(
            backgroundColor: themeAppBarBackground,
            title: Text('Photos of this run', style: ts_appBarTitle),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Obx(() {
            final String? blocked = c.blocked.value;
            if (blocked != null) {
              return _message(blocked);
            }
            if (c.busy.value && c.result.value == null) {
              return _message(
                c.status.value.isEmpty
                    ? 'Looking through your photos…'
                    : c.status.value,
                spinner: true,
              );
            }
            final RunScanResult? r = c.result.value;
            if (r == null || r.eligible == 0) {
              return _message(
                'No photos from your camera roll match this run.\n\n'
                'A photo has to carry a location as well as a time — one '
                'without a location cannot be placed on the trail, so it is '
                'left alone.',
              );
            }
            return Column(
              children: <Widget>[
                _header(c, r),
                Expanded(child: _grid(c, r)),
                _footer(context, c),
              ],
            );
          }),
        );
      },
    );
  }

  Widget _message(String text, {bool spinner = false}) => Padding(
    padding: const EdgeInsets.all(28.0),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (spinner) ...<Widget>[
          const CircularProgressIndicator(),
          const SizedBox(height: 18),
        ],
        Text(text, style: ts_alertDialogBody, textAlign: TextAlign.center),
      ],
    ),
  );

  Widget _header(RunPhotoSweepController c, RunScanResult r) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '${r.eligible} eligible  ·  ${r.added} already added',
          style: ts_alertDialogTitle.copyWith(fontSize: 17),
        ),
        const SizedBox(height: 6),
        Text(
          'Anything you send goes to your Hash Flash for review. Approved '
          'photos appear on the run and on the kennel\'s public website, so '
          'they may become publicly viewable.',
          style: ts_footnoteBlack.copyWith(color: Colors.black54),
        ),
      ],
    ),
  );

  Widget _grid(RunPhotoSweepController c, RunScanResult r) => GridView.builder(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 130,
      crossAxisSpacing: 6,
      mainAxisSpacing: 6,
    ),
    itemCount: r.candidates.length,
    itemBuilder: (BuildContext _, int i) {
      final PhotoCandidate p = r.candidates[i];
      final bool done = p.alreadyUploaded;
      final bool ticked = c.chosen.contains(p.asset.id);
      return GestureDetector(
        onTap: done ? null : () => c.toggle(p.asset.id),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: _Thumb(asset: p.asset),
            ),
            if (done)
              const ColoredBox(
                color: Color(0x99000000),
                child: Center(
                  child: Icon(Icons.check_circle, color: Colors.white, size: 30),
                ),
              )
            else
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(
                    ticked
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: ticked ? hc_blue : Colors.white,
                    size: 24,
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );

  Widget _footer(BuildContext context, RunPhotoSweepController c) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (c.status.value.isNotEmpty) ...<Widget>[
            Text(c.status.value, style: ts_alertDialogBody),
            const SizedBox(height: 8),
          ],
          if (c.uploadTotal.value > 0) ...<Widget>[
            LinearProgressIndicator(
              value: c.uploadDone.value / c.uploadTotal.value,
            ),
            const SizedBox(height: 8),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (c.busy.value || c.chosen.isEmpty) ? null : c.send,
              child: Text(
                c.chosen.isEmpty
                    ? 'Choose photos to send'
                    : 'Send ${c.chosen.length} for review',
                style: ts_button,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// A camera-roll thumbnail. photo_manager hands back bytes rather than a
/// widget (AssetEntityImage lives in a separate package the app does not
/// carry), and the future is held in a field so a rebuild does not re-read
/// the asset on every scroll frame.
class _Thumb extends StatefulWidget {
  const _Thumb({required this.asset});

  final AssetEntity asset;

  @override
  State<_Thumb> createState() => _ThumbState();
}

class _ThumbState extends State<_Thumb> {
  late Future<Uint8List?> _bytes;

  @override
  void initState() {
    super.initState();
    _bytes = widget.asset.thumbnailDataWithSize(
      const ThumbnailSize.square(260),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _bytes,
      builder: (BuildContext _, AsyncSnapshot<Uint8List?> snap) {
        final Uint8List? data = snap.data;
        if (data == null) {
          return const ColoredBox(color: Colors.black12);
        }
        return Image.memory(data, fit: BoxFit.cover, gaplessPlayback: true);
      },
    );
  }
}
