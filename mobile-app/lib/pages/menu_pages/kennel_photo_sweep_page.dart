import 'package:harrier_central/imports.dart';
import 'package:harrier_central/services/photos/camera_roll_scan_service.dart';
import 'package:harrier_central/services/photos/run_photo_sweep_service.dart';
import 'package:photo_manager/photo_manager.dart' hide LatLng;

/// Every run of a kennel that has photos of it still sitting in the camera
/// roll (E6.F2.S5): "Run #1696 — 14 eligible, 6 added". Tapping one opens the
/// per-run selector.
class KennelPhotoSweepController extends GetxController {
  KennelPhotoSweepController({
    required this.kennelId,
    required this.kennelName,
  });

  final String kennelId;
  final String kennelName;

  final RunPhotoSweepService _service = const RunPhotoSweepService();

  final RxBool busy = false.obs;
  final RxString status = ''.obs;
  final RxnString blocked = RxnString();
  final RxList<RunScanResult> results = <RunScanResult>[].obs;
  final RxInt done = 0.obs;
  final RxInt total = 0.obs;

  @override
  void onReady() {
    super.onReady();
    unawaited(scan());
  }

  int get totalEligible =>
      results.fold<int>(0, (int s, RunScanResult r) => s + r.eligible);
  int get totalPending =>
      results.fold<int>(0, (int s, RunScanResult r) => s + r.pending);

  Future<void> scan() async {
    busy.value = true;
    blocked.value = null;
    status.value = 'Looking through your photos…';
    done.value = 0;
    total.value = 0;
    try {
      final PermissionState p = await _service.requestAccess();
      if (!p.hasAccess) {
        blocked.value =
            'Harrier Central needs access to your photos to find the ones '
            'from your runs. You can grant it in Settings.';
        return;
      }
      final List<RunScanResult> found = await _service.sweep(
        kennelId: kennelId,
        onProgress: (int d, int t) {
          done.value = d;
          total.value = t;
        },
      );
      results.assignAll(found);
      status.value = '';
    } catch (e, s) {
      BootLogger.logError('[KennelPhotoSweepController.scan]', e, s);
      status.value = 'Your photos could not be checked. Please try again.';
    } finally {
      busy.value = false;
      total.value = 0;
    }
  }
}

class KennelPhotoSweepPage extends StatelessWidget {
  const KennelPhotoSweepPage({
    super.key,
    required this.kennelId,
    required this.kennelName,
  });

  final String kennelId;
  final String kennelName;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<KennelPhotoSweepController>(
      init: KennelPhotoSweepController(
        kennelId: kennelId,
        kennelName: kennelName,
      ),
      global: false,
      builder: (KennelPhotoSweepController c) {
        return AppScaffold(
          appBar: AppBar(
            backgroundColor: themeAppBarBackground,
            title: Text('Photos on your phone', style: ts_appBarTitle),
            iconTheme: const IconThemeData(color: Colors.white),
            actions: <Widget>[
              Obx(
                () => IconButton(
                  tooltip: 'Check again',
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: c.busy.value ? null : c.scan,
                ),
              ),
            ],
          ),
          body: Obx(() {
            final String? blocked = c.blocked.value;
            if (blocked != null) {
              return SweepMessage(text: blocked);
            }
            if (c.busy.value && c.results.isEmpty) {
              return SweepMessage(
                text: c.total.value > 0
                    ? 'Checking your runs… ${c.done.value} of ${c.total.value}'
                    : 'Looking through your photos…',
                spinner: true,
              );
            }
            if (c.results.isEmpty) {
              return SweepMessage(
                text:
                    'No photos on this phone match your runs with $kennelName.\n\n'
                    'A photo has to carry a location as well as a time — one '
                    'without a location cannot be placed on a trail, so it is '
                    'left alone.',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
              itemCount: c.results.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (BuildContext _, int i) {
                if (i == 0) return _summary(c);
                return _runRow(context, c, c.results[i - 1]);
              },
            );
          }),
        );
      },
    );
  }

  Widget _summary(KennelPhotoSweepController c) => Padding(
    padding: const EdgeInsets.only(bottom: 4.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '${c.results.length} ${c.results.length == 1 ? 'run' : 'runs'}  ·  '
          '${c.totalEligible} eligible  ·  ${c.totalPending} still to add',
          style: ts_alertDialogTitle.copyWith(fontSize: 17),
        ),
        const SizedBox(height: 6),
        Text(
          'These are photos on this phone taken around a run you were at, '
          'close to where you ran. Open a run to choose which to send; '
          'nothing is sent until you do.',
          style: ts_footnoteBlack.copyWith(color: Colors.black54),
        ),
      ],
    ),
  );

  Widget _runRow(
    BuildContext context,
    KennelPhotoSweepController c,
    RunScanResult r,
  ) {
    final String number = r.run.eventNumber > 0
        ? 'Run #${r.run.eventNumber}'
        : r.run.eventName;
    return InkWell(
      onTap: () async {
        await Navigator.push<dynamic>(
          context,
          MaterialPageRoute<dynamic>(
            builder: (_) => RunPhotoSweepPage(
              eventId: r.run.eventId,
              eventName: r.run.eventName,
            ),
          ),
        );
        // Counts change when photos are sent, so re-read on the way back.
        await c.scan();
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    number,
                    style: ts_alertDialogTitle.copyWith(fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (r.run.eventNumber > 0 && r.run.eventName.isNotEmpty)
                    Text(
                      r.run.eventName,
                      style: ts_alertDialogBody,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 2),
                  Text(
                    '${r.eligible} eligible  ·  ${r.added} added',
                    style: ts_footnoteBlack.copyWith(
                      color: r.pending > 0 ? hc_blue : Colors.black45,
                      fontWeight: r.pending > 0
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black38),
          ],
        ),
      ),
    );
  }
}
