import 'package:geolocator/geolocator.dart';
import 'package:harrier_central/imports.dart';
import 'package:intl/intl.dart';

class LiveRunGeneralController extends GetxController {
  LiveRunGeneralController({required this.run}) {
    LiveRunService.ensure();
  }

  final RunDetailsAggregate run;
  final LocationService _locationService = Get.find<LocationService>();

  final RxBool isTracking = false.obs;
  final RxDouble distanceKm = 0.0.obs;
  final Rx<Duration> elapsed = const Duration().obs;
  final Rx<Position?> lastPosition = Rx<Position?>(null);

  // Exposes LocationService.isPaused directly so the UI Obx can observe it.
  RxBool get isPaused => _locationService.isPaused;

  // True once the event is within 5 minutes of starting (or already started).
  late final RxBool canStartTracking;

  DateTime? _trackingStartedAt;
  Timer? _elapsedTicker;
  Timer? _preRunTimer;
  Worker? _trackingWorker;
  Worker? _positionWorker;

  @override
  void onInit() {
    super.onInit();
    isTracking.value = _locationService.joinRunTracking.value;
    lastPosition.value = _locationService.lastKnownPosition.value;

    canStartTracking = _checkCanStart().obs;
    if (!canStartTracking.value) {
      _preRunTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        if (_checkCanStart()) {
          canStartTracking.value = true;
          _preRunTimer?.cancel();
          _preRunTimer = null;
        }
      });
    }

    _trackingWorker = ever<bool>(_locationService.joinRunTracking, _handleTrackingToggle);
    _positionWorker = ever<Position?>(_locationService.lastKnownPosition, _handlePosition);

    if (isTracking.value) {
      _trackingStartedAt ??= DateTime.now();
      _startElapsedTicker();
    }
  }

  @override
  void onClose() {
    _preRunTimer?.cancel();
    _trackingWorker?.dispose();
    _positionWorker?.dispose();
    _stopElapsedTicker();
    super.onClose();
  }

  bool _checkCanStart() {
    return DateTime.now().toUtc().isAfter(
      run.event.eventStartDatetimeGmt.toUtc().subtract(const Duration(minutes: 5)),
    );
  }

  // Local-time label shown on the disabled start button.
  String get trackingOpensAt {
    final opensAt = run.event.eventStartDatetimeGmt
        .toLocal()
        .subtract(const Duration(minutes: 5));
    return DateFormat('h:mm a').format(opensAt);
  }

  void toggleTracking() {
    final newValue = !_locationService.joinRunTracking.value;
    _locationService.eventId = run.event.eventId;
    _locationService.userId = getStringPref(StringPrefsEnum.userId);

    if (newValue) {
      _preRunTimer?.cancel();
      _preRunTimer = null;
      _trackingStartedAt = DateTime.now();
      distanceKm.value = 0.0;
      elapsed.value = Duration.zero;
    }

    _locationService.joinRunTracking.value = newValue;

    if (!newValue) {
      _stopElapsedTicker();
    }
  }

  Future<void> pauseTracking() async {
    await _locationService.pauseTracking();
    _stopElapsedTicker();
  }

  void resumeTracking() {
    _locationService.resumeTracking();
    // _handleTrackingToggle fires when joinRunTracking becomes true,
    // restarting the elapsed ticker.
  }

  void stopTracking() {
    unawaited(_locationService.stopTracking());
    _stopElapsedTicker();
  }

  Future<void> markPoint(HashRunPointTypes type, {String? label}) async {
    await _locationService.markPoint(type, label: label);
  }

  Future<void> takePhoto() async {
    final blobUrl = await KennelPhotoService().captureAndUpload(
      eventId: run.event.eventId,
      kennelId: run.kennel.kennelId,
      kennelSlug: run.kennel.kennelUniqueShortName,
      eventNumber: run.event.eventNumber,
    );
    if (blobUrl != null) {
      Get.snackbar(
        'Photo saved',
        'Your photo has been added to the run.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: hc_blue,
      );
    }
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
}

class LiveRunGeneralPage extends StatelessWidget {
  LiveRunGeneralPage({super.key, required this.run})
    : controller = Get.put(
        LiveRunGeneralController(run: run),
        tag: 'live-run-general-${run.event.eventId}',
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
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildMarkerGrid(context),
                          _buildPhotoButton(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildChatSection(),
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
        borderRadius: BorderRadius.circular(12),
      );
      const buttonPadding = EdgeInsets.symmetric(vertical: 3);

      final paused = controller.isPaused.value;

      if (!tracking && !paused) {
        // Not running — full-width start button. Disabled until 5 min before start.
        final canStart = controller.canStartTracking.value;
        return SizedBox(
          height: 45,
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.play_arrow, size: 20),
            label: Text(
              canStart
                  ? 'Start Run Tracking'
                  : 'Tracking opens at ${controller.trackingOpensAt}',
              style: ts_button.copyWith(fontSize: canStart ? 18 : 15),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              disabledBackgroundColor: Colors.grey.shade700,
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white60,
              padding: buttonPadding,
              shape: buttonShape,
            ),
            onPressed: canStart ? controller.toggleTracking : null,
          ),
        );
      }

      // Tracking or paused — left button toggles Auto Pause / Resume,
      // right button ends the run.
      final leftButton = paused
          ? ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow, size: 20, color: Colors.white),
              label: Text('Resume', style: ts_button.copyWith(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                padding: buttonPadding,
                shape: buttonShape,
              ),
              onPressed: controller.resumeTracking,
            )
          : ElevatedButton.icon(
              icon: const Icon(Icons.pause, size: 20, color: Colors.white),
              label: Text(
                'Auto Pause',
                style: ts_button.copyWith(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                foregroundColor: Colors.white,
                padding: buttonPadding,
                shape: buttonShape,
              ),
              onPressed: () => unawaited(controller.pauseTracking()),
            );

      return SizedBox(
        height: 45,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: leftButton),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: hc_red,
                  foregroundColor: Colors.white,
                  padding: buttonPadding,
                  shape: buttonShape,
                ),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => AlertDialog(
                      title: Text('End Run?', style: ts_alertDialogTitle),
                      content: Text(
                        'Are you sure you want to end your run? '
                        'Once stopped, tracking cannot be restarted. '
                        'Your data will be saved.',
                        style: ts_alertDialogBody,
                      ),
                      actions: [
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade600,
                            foregroundColor: Colors.white,
                          ),
                          child: Text('Keep Tracking', style: ts_button),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: hc_red,
                            foregroundColor: Colors.white,
                          ),
                          child: Text('End Run', style: ts_button),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) controller.stopTracking();
                },
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
                    Text('End Run', style: ts_button.copyWith(fontSize: 18)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildPhotoButton() {
    // Expanded must be a direct Row child — Obx wraps only the reactive button.
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(left: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Obx(() {
                final active =
                    controller.isTracking.value || controller.isPaused.value;
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: active ? hc_blue : Colors.grey.shade700,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade700,
                    disabledForegroundColor: Colors.white54,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed:
                      active ? () => unawaited(controller.takePhoto()) : null,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.camera_alt, size: 44),
                      const SizedBox(height: 8),
                      Text(
                        'Take\nPhoto',
                        textAlign: TextAlign.center,
                        style: ts_button.copyWith(fontSize: 15),
                      ),
                    ],
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 58,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: hc_red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Get.find<LiveRunShellController>().setTab(3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.qr_code_2, size: 28),
                    const SizedBox(width: 10),
                    Text(
                      'Share\nRuns',
                      textAlign: TextAlign.center,
                      style: ts_button.copyWith(fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
    return ChatStripWidget(
      eventId: run.event.eventId,
      publicEventId: run.event.publicEventId,
    );
  }
}
