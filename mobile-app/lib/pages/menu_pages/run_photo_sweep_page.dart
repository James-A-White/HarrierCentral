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
      // Nothing ticked to start with (James, 2026-09-12). These photos can end
      // up on a public website, so sending them is a decision the hasher makes
      // rather than one they have to undo.
      chosen.clear();
      status.value = '';
    } catch (e, s) {
      BootLogger.logError('[RunPhotoSweepController.scan]', e, s);
      status.value = 'Those photos could not be checked. Please try again.';
    } finally {
      busy.value = false;
    }
  }

  /// True once every offerable photo is ticked, so the control can flip.
  bool get allChosen =>
      offerable.isNotEmpty && chosen.length >= offerable.length;

  void selectAll() =>
      chosen.addAll(offerable.map((PhotoCandidate c) => c.asset.id));

  void selectNone() => chosen.clear();

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
              return SweepMessage(text: blocked);
            }
            if (c.busy.value && c.result.value == null) {
              return SweepMessage(
                text: c.status.value.isEmpty
                    ? 'Looking through your photos…'
                    : c.status.value,
                spinner: true,
              );
            }
            final RunScanResult? r = c.result.value;
            if (r == null || r.eligible == 0) {
              return SweepMessage(
                text:
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

  Widget _header(RunPhotoSweepController c, RunScanResult r) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                '${r.eligible} eligible  ·  ${r.added} already added',
                style: ts_alertDialogTitle.copyWith(fontSize: 17),
              ),
            ),
            if (c.offerable.isNotEmpty)
              TextButton(
                onPressed: c.busy.value
                    ? null
                    : (c.allChosen ? c.selectNone : c.selectAll),
                child: Text(
                  c.allChosen ? 'Select none' : 'Select all',
                  // White: the button themes paint red (see CLAUDE.md).
                  style: ts_button.copyWith(color: Colors.white),
                ),
              ),
          ],
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
        // The picture opens; the ring in the corner is what selects. Choosing
        // between four near-identical circle shots needs them full screen
        // (James, 2026-09-12).
        onTap: () => _openCarousel(c, r, i),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: _Thumb(asset: p.asset),
            ),
            if (done) const ColoredBox(color: Color(0x66000000)),
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: _SelectionRing(selected: done || ticked),
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

/// The selection marker (James, 2026-09-12): a black outer circle and a white
/// ring, which never change, around an inner area that is transparent when
/// unselected and green with a solid white tick when selected. The two rings
/// are the point — a plain tick vanishes on a bright photo and a plain circle
/// vanishes on a dark one, and a pub interior gives you both in one grid.
class _SelectionRing extends StatelessWidget {
  const _SelectionRing({required this.selected});

  final bool selected;

  static const double _size = 32;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _size,
      height: _size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black54,
      ),
      padding: const EdgeInsets.all(2.5),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          // Transparent until chosen, so the photo shows through the middle.
          color: selected ? const Color(0xFF2E9E4F) : Colors.transparent,
        ),
        child: selected
            ? const Icon(Icons.check, color: Colors.white, size: 17)
            : null,
      ),
    );
  }
}

/// Full screen, swipeable and pinch-zoomable, opening on the photo tapped.
/// Selection stays reachable from here because this is where the choice
/// between four near-identical shots is actually made.
Future<void> _openCarousel(
  RunPhotoSweepController c,
  RunScanResult r,
  int index,
) async {
  final BuildContext? ctx = navigatorKey.currentContext;
  if (ctx == null) return;
  await Navigator.push<void>(
    ctx,
    MaterialPageRoute<void>(
      builder: (_) => _SweepCarousel(controller: c, result: r, initial: index),
    ),
  );
}

class _SweepCarousel extends StatefulWidget {
  const _SweepCarousel({
    required this.controller,
    required this.result,
    required this.initial,
  });

  final RunPhotoSweepController controller;
  final RunScanResult result;
  final int initial;

  @override
  State<_SweepCarousel> createState() => _SweepCarouselState();
}

class _SweepCarouselState extends State<_SweepCarousel> {
  late final PageController _pages = PageController(
    initialPage: widget.initial,
  );
  late int _index = widget.initial;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<PhotoCandidate> photos = widget.result.candidates;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_index + 1} of ${photos.length}',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
      body: Stack(
        children: <Widget>[
          PhotoViewGallery(
            pageController: _pages,
            onPageChanged: (int i) => setState(() => _index = i),
            backgroundDecoration: const BoxDecoration(color: Colors.black),
            pageOptions: photos
                .map(
                  (PhotoCandidate p) => PhotoViewGalleryPageOptions.customChild(
                    child: _FullPhoto(asset: p.asset),
                  ),
                )
                .toList(growable: false),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Obx(() {
                  final PhotoCandidate p = photos[_index];
                  if (p.alreadyUploaded) {
                    return const _CarouselLabel(text: 'Already added');
                  }
                  final bool ticked = widget.controller.chosen.contains(
                    p.asset.id,
                  );
                  return GestureDetector(
                    onTap: () => widget.controller.toggle(p.asset.id),
                    child: _CarouselLabel(
                      text: ticked ? 'Selected' : 'Not selected',
                      selected: ticked,
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CarouselLabel extends StatelessWidget {
  const _CarouselLabel({required this.text, this.selected = false});

  final String text;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _SelectionRing(selected: selected),
            const SizedBox(width: 10),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A full-resolution-enough copy for pinching into. The grid's 260 px
/// thumbnail is useless zoomed; the original can be tens of megabytes, so
/// this asks for a large thumbnail instead.
class _FullPhoto extends StatefulWidget {
  const _FullPhoto({required this.asset});

  final AssetEntity asset;

  @override
  State<_FullPhoto> createState() => _FullPhotoState();
}

class _FullPhotoState extends State<_FullPhoto> {
  late Future<Uint8List?> _bytes;

  @override
  void initState() {
    super.initState();
    _bytes = widget.asset.thumbnailDataWithSize(
      const ThumbnailSize(1600, 1600),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _bytes,
      builder: (BuildContext _, AsyncSnapshot<Uint8List?> snap) {
        final Uint8List? data = snap.data;
        if (data == null) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }
        return Image.memory(data, fit: BoxFit.contain, gaplessPlayback: true);
      },
    );
  }
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
