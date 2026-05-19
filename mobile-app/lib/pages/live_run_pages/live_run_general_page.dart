import 'package:geolocator/geolocator.dart';
import 'package:harrier_central/imports.dart';

class LiveRunGeneralController extends GetxController {
  LiveRunGeneralController({required this.run}) {
    LiveRunService.ensure();
    qrItems = _buildQrItems();
  }

  final RunDetailsAggregate run;
  final LocationService _locationService = Get.find<LocationService>();

  // Carousel state for QR codes lives in the controller to keep the page stateless.
  final PageController qrPageController = PageController(viewportFraction: 0.9);
  final RxInt currentQrIndex = 0.obs;
  late final List<QrShareItem> qrItems;

  final RxBool isTracking = false.obs;
  final RxDouble distanceKm = 0.0.obs;
  final Rx<Duration> elapsed = const Duration().obs;
  final Rx<Position?> lastPosition = Rx<Position?>(null);

  DateTime? _trackingStartedAt;
  Timer? _elapsedTicker;

  String get runWebsiteUrl {
    if (run.event.isCountedRun != 0) {
      return '$BASE_HASHRUNS_DOT_ORG_URL${run.kennel.kennelUniqueShortName}/${run.event.eventNumber}';
    }
    return '$BASE_HASHRUNS_DOT_ORG_URL#/RID?publicEventId=${run.event.publicEventId}';
  }

  /// Prefer a kennel landing page; fall back to kennel website; lastly use run page.
  String get kennelWebsiteUrl {
    final slug = run.kennel.kennelUniqueShortName;
    if (slug.isNotEmpty) {
      return '$BASE_HASHRUNS_DOT_ORG_URL$slug';
    }
    if (run.kennel.kennelWebsiteUrl?.isNotEmpty == true) {
      return run.kennel.kennelWebsiteUrl!;
    }
    return runWebsiteUrl;
  }

  @override
  void onInit() {
    super.onInit();
    isTracking.value = _locationService.joinRunTracking.value;
    lastPosition.value = _locationService.lastKnownPosition.value;

    ever<bool>(_locationService.joinRunTracking, _handleTrackingToggle);
    ever<Position?>(_locationService.lastKnownPosition, _handlePosition);

    if (isTracking.value) {
      _trackingStartedAt ??= DateTime.now();
      _startElapsedTicker();
    }
  }

  @override
  void onClose() {
    _stopElapsedTicker();
    qrPageController.dispose();
    super.onClose();
  }

  void toggleTracking() {
    final newValue = !_locationService.joinRunTracking.value;
    _locationService.eventId = run.event.eventId;
    _locationService.userId = getStringPref(StringPrefsEnum.userId);

    if (newValue) {
      _trackingStartedAt = DateTime.now();
      distanceKm.value = 0.0;
      elapsed.value = Duration.zero;
    }

    _locationService.joinRunTracking.value = newValue;

    if (!newValue) {
      _stopElapsedTicker();
    }
  }

  void stopTracking() {
    if (_locationService.joinRunTracking.value) {
      _locationService.joinRunTracking.value = false;
      _stopElapsedTicker();
    }
  }

  Future<void> markPoint(HashRunPointTypes type, {String? label}) async {
    await _locationService.markPoint(type, label: label);
  }

  void _handleTrackingToggle(bool value) {
    isTracking.value = value;
    if (value) {
      _trackingStartedAt ??= DateTime.now();
      _startElapsedTicker();
    } else {
      _stopElapsedTicker();
    }
  }

  void _handlePosition(Position? position) {
    lastPosition.value = position;
    if (!isTracking.value || position == null) return;
    distanceKm.value =
        _locationService.filteredSessionDistanceMeters.value / 1000.0;
    _trackingStartedAt ??= DateTime.now();
    _updateElapsed();
  }

  void _startElapsedTicker() {
    _elapsedTicker ??= Timer.periodic(const Duration(seconds: 1), (_) {
      _updateElapsed();
    });
    _updateElapsed();
  }

  void _stopElapsedTicker() {
    _elapsedTicker?.cancel();
    _elapsedTicker = null;
  }

  void _updateElapsed() {
    final started = _trackingStartedAt;
    if (started == null) return;
    elapsed.value = DateTime.now().difference(started);
  }

  String formattedElapsed() {
    final totalSeconds = elapsed.value.inSeconds;
    final hours = (totalSeconds ~/ 3600).toString().padLeft(1, '0');
    final minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  List<QrShareItem> _buildQrItems() {
    final items = <QrShareItem>[
      QrShareItem(
        title: 'Run #${run.event.eventNumber}',
        description: 'this run',
        url: runWebsiteUrl,
      ),
      QrShareItem(
        title: 'Next ${run.kennel.kennelShortName} Run',
        description: 'next ${run.kennel.kennelShortName} run',
        url:
            '$BASE_HASHRUNS_DOT_ORG_URL${run.kennel.kennelUniqueShortName}/nextrun',
      ),
    ];

    final kennelRunsUrl = run.event.isCountedRun != 0
        ? '$BASE_HASHRUNS_DOT_ORG_URL${run.kennel.kennelUniqueShortName}'
        : '';
    if (kennelRunsUrl.isNotEmpty) {
      items.add(
        QrShareItem(
          title: '${run.kennel.kennelShortName} upcoming Runs',
          description: '${run.kennel.kennelName} upcoming runs',
          url: kennelRunsUrl,
        ),
      );
    }

    final kennelWebsite = kennelWebsiteUrl;
    if (kennelWebsite.isNotEmpty) {
      items.add(
        QrShareItem(
          title: '${run.kennel.kennelShortName} Website',
          description: '${run.kennel.kennelName} website',
          url: kennelWebsite,
        ),
      );
    }

    return items;
  }
}

class LiveRunGeneralPage extends StatelessWidget {
  LiveRunGeneralPage({super.key, required this.run})
    : controller = Get.put(
        LiveRunGeneralController(run: run),
        tag: 'live-run-general-${run.event.eventId}',
        // TODO: consider fenix:true if re-entry causes issues (L4)
      );

  final RunDetailsAggregate run;
  final LiveRunGeneralController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: Backgrounds.defaultHcBackground(),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopButtons(context),
                    const SizedBox(height: 12),
                    _buildStatsRow(),
                    const SizedBox(height: 12),
                    // _buildActionsRow(context),
                    // const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMarkerGrid(context),
                        //const SizedBox(width: 12),
                        Expanded(child: _buildQrSmall()),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(child: _buildChatSection()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopButtons(BuildContext context) {
    return Obx(() {
      final tracking = controller.isTracking.value;

      final buttonShape = RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      );
      const buttonPadding = EdgeInsets.symmetric(vertical: 3);

      if (!tracking) {
        return SizedBox(
          height: 45,
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.play_arrow, size: 20, color: Colors.white),
            label: Text(
              'Start Run Tracking',
              style: ts_button.copyWith(fontSize: 18),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
              padding: buttonPadding,
              shape: buttonShape,
            ),
            onPressed: controller.toggleTracking,
          ),
        );
      }

      // Tracking active — Pause and End Run side by side.
      return SizedBox(
        height: 45,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.pause, size: 20, color: Colors.white),
                label: Text(
                  'Pause',
                  style: ts_button.copyWith(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  foregroundColor: Colors.white,
                  padding: buttonPadding,
                  shape: buttonShape,
                ),
                onPressed: controller.toggleTracking,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: hc_red,
                  foregroundColor: Colors.white,
                  padding: buttonPadding,
                  shape: buttonShape,
                ),
                // TODO: wire up full End Run flow (mark On Inn + flush + confirm)
                onPressed: controller.stopTracking,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'images/live_run_trail_markers/oninn.png',
                      height: 26,
                      width: 26,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'End Run',
                      style: ts_button.copyWith(fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildQrSmall() {
    final items = controller.qrItems;
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 3),
        // Text('Share', style: ts_button.copyWith(color: Colors.yellow)),
        // const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: controller.qrPageController,
            onPageChanged: (index) => controller.currentQrIndex.value = index,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    //padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: QrImageView(data: item.url, size: 110),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: AutoSizeText(
                      item.title,
                      textAlign: TextAlign.center,
                      style: ts_titleMediumBold,
                      maxLines: 3,
                      minFontSize: 12,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            label: 'Dist (in km)',
            valueBuilder: () {
              final dist = controller.distanceKm.value;
              if (dist <= 0) return '--';
              return dist.toStringAsFixed(2);
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            label: 'Time',
            valueBuilder: controller.formattedElapsed,
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required String label,
    required String Function() valueBuilder,
  }) {
    return Obx(() {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.lightBlueAccent.shade100,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AutoSizeText(
              label,
              style: ts_titleDarkRedLarge,
              maxLines: 1,
              minFontSize: 12,
            ),
            const SizedBox(height: 6),
            AutoSizeText(
              valueBuilder(),
              style: ts_titleCondensedVeryLargeBlack.copyWith(fontSize: 42),
              maxLines: 1,
              maxFontSize: 42,
              minFontSize: 20,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildMarkerGrid(BuildContext context) {
    final markers = [
      HashRunPointTypes.check,
      HashRunPointTypes.falseTrail,
      HashRunPointTypes.shortCut,
      HashRunPointTypes.checkback,

      HashRunPointTypes.whichyWay,
      HashRunPointTypes.fishhook,
      HashRunPointTypes.regroup,
      HashRunPointTypes.hashView,

      HashRunPointTypes.customLabel,
      HashRunPointTypes.drinkStop,
      HashRunPointTypes.onInn,
      HashRunPointTypes.caution,
    ];

    const int perRow = 4;
    final rows = <Widget>[];
    for (var i = 0; i < markers.length; i += perRow) {
      final slice = markers.skip(i).take(perRow).toList(growable: false);
      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              for (var j = 0; j < slice.length; j++) ...[
                _buildMarkerButton(context, slice[j]),
                if (j != slice.length - 1) const SizedBox(width: 10),
              ],
            ],
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Mark your trail map',
          style: ts_button.copyWith(color: Colors.yellow),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        ...rows,
      ],
    );
  }

  Widget _buildMarkerButton(BuildContext context, HashRunPointTypes type) {
    return InkWell(
      onTap: () async {
        String? label;

        if (type == HashRunPointTypes.customLabel ||
            type == HashRunPointTypes.caution) {
          final popup = GetPointLabelPopup(
            title: type == HashRunPointTypes.customLabel
                ? 'Add Point Label'
                : 'Add Caution Note',
            hintText: type == HashRunPointTypes.customLabel
                ? 'Point Label'
                : 'Caution / warning text',
            confirmButtonText: type == HashRunPointTypes.customLabel
                ? 'Save Label'
                : 'Save Warning',
            iconData: type.iconData,
          );

          final dialogResult = await showDialog<Map<String, String>>(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) => popup,
          );

          final trimmed = dialogResult?['label']?.trim() ?? '';
          if (trimmed.isEmpty) {
            return;
          }
          label = trimmed;
        }

        await controller.markPoint(type, label: label);

        if (type == HashRunPointTypes.onInn) {
          controller.stopTracking();
        }

        final suffix = (label != null && label.isNotEmpty) ? ' — $label' : '';
        Get.snackbar(
          'Marker recorded',
          '${type.label}$suffix',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: hc_blue,
        );
      },
      borderRadius: BorderRadius.circular(40),
      child: Image.asset(
        'images/live_run_trail_markers/${type.pngIcon}',
        height: 50,
        width: 50,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) =>
            Icon(type.iconData, color: type.color, size: 32),
      ),
    );
  }

  Widget _buildChatSection() {
    return Card(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ChatPage(
          eventId: run.event.eventId,
          publicEventId: run.event.publicEventId,
        ),
      ),
    );
  }
}

class QrShareItem {
  const QrShareItem({
    required this.title,
    required this.description,
    required this.url,
  });

  final String title;
  final String description;
  final String url;
}
