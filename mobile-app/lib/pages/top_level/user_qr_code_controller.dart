import 'package:harrier_central/imports.dart';
import 'package:intl/intl.dart';

enum EQrScannerState {
  waitingForScan,
  scanning,
  isProcessing,
  qrNotRecognized,
  dataRecorded,
}

/// State for the "Run check in page": the Scan / Be Scanned tab, and the
/// check-in scanner (run start/end codes, kennel generic codes, and the web
/// portal sign-in code) with its on-screen message and picture.
///
/// Owned by the page, not the tab, so swiping to Be Scanned and back keeps
/// the scanner where it was — the tab used to keep itself alive for that.
class UserQrCodeController extends QrScanController
    with GetSingleTickerProviderStateMixin {
  static const String tag = 'qr-checkin';

  late final TabController tabController;
  final RxString onScreenMessage = 'Scanning paused'.obs;
  final Rx<EQrScannerState> state = EQrScannerState.waitingForScan.obs;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(vsync: this, length: 2);
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }

  @override
  void onScanningPaused() {
    onScreenMessage.value = 'Scanning paused';
    state.value = EQrScannerState.waitingForScan;
  }

  @override
  void onScanningStarted() {
    onScreenMessage.value = 'Looking for QR Code';
    state.value = EQrScannerState.scanning;
  }

  /// The Start / Stop Scanning button.
  Future<void> tapStartStop() async {
    if (Utilities.isConnected(showDialog: true)) await toggleScanning();
  }

  @override
  Future<void> onCodeRead(String scanResult) async {
    final player = AudioPlayer();
    await player.setAsset('assets/sounds/camera.mp3');
    await player.play();
    await player.dispose();
    if (isClosed) return;

    onScreenMessage.value = 'Processing QR Scan';
    state.value = EQrScannerState.isProcessing;

    final Map<String, String> result = Utilities.validateScan(
      scanResult,
      Utilities.qrScanTypeFlag_runStart |
          Utilities.qrScanTypeFlag_runEnd |
          Utilities.qrScanTypeFlag_kennelRunEnd |
          Utilities.qrScanTypeFlag_kennelRunStart |
          Utilities.qrScanTypeFlag_authenticateWebPortal,
    );

    if (result['validScan'] == 'false') {
      state.value = EQrScannerState.qrNotRecognized;
      onScreenMessage.value = result['validHcQr'] == 'true'
          ? 'This QR code is not valid here'
          : 'QR code not recignized';
      return;
    }

    final String prefix = result['prefix'] ?? '';
    final String scanData = result['content'] ?? '';

    if ((prefix == QR_PREFIX_SPECIFIC_RUN_START) ||
        (prefix == QR_PREFIX_SPECIFIC_RUN_END)) {
      final int attendenceState = (prefix == QR_PREFIX_SPECIFIC_RUN_START)
          ? attendenceAtHash.value
          : attendenceOnIn.value;
      final List<dynamic> adHocData = await tableModel.hasherEventMapService
          .setEventAttendence(
            scanData,
            currentUserId,
            AppDomainType.user,
            attendenceState,
            isHare: isHareNo.value,
          );
      if (isClosed) return;
      state.value = EQrScannerState.dataRecorded;
      onScreenMessage.value =
          firstRow(adHocData)?['userMessage'] ?? 'Processing Complete';
    } else if ((prefix == QR_PREFIX_KENNEL_GENERIC_RUN_END) ||
        (prefix == QR_PREFIX_KENNEL_GENERIC_RUN_START)) {
      final int attendenceState = prefix == QR_PREFIX_KENNEL_GENERIC_RUN_START
          ? attendenceAtHash.value
          : attendenceOnIn.value;

      // The result is either the number of hours to the closest event or an
      // actual eventId for one event.
      final String queryResult = await CommonQueries.getClosestEventInTime(
        scanData,
      );
      if (isClosed) return;
      if (double.tryParse(queryResult) != null) {
        final double? hoursUntilNextEvent = double.tryParse(
          queryResult.replaceAll(',', '.'),
        );
        if (hoursUntilNextEvent != null) {
          onScreenMessage.value = notYetOpenMessage(hoursUntilNextEvent);
        }
      } else if (queryResult == EMPTY_RESULT) {
        onScreenMessage.value =
            'There is no event for this Kennel at this time';
      } else {
        final List<dynamic> adHocData = await tableModel.hasherEventMapService
            .setEventAttendence(
              scanData,
              currentUserId,
              AppDomainType.user,
              attendenceState,
              isHare: isHareNo.value,
            );
        if (isClosed) return;
        onScreenMessage.value =
            firstRow(adHocData)?['userMessage'] ?? 'Processing Complete';
      }
    } else if (prefix == QR_PREFIX_AUTHENTICATE_WEB_PORTAL_LOGIN) {
      final AuthenticateWebPortalService svc = AuthenticateWebPortalService();
      final SingleResultModel? returnValue = await svc.authenticateWebPortal(
        scanData,
      );
      if (isClosed) return;
      onScreenMessage.value =
          (returnValue != null &&
              returnValue.result != null &&
              returnValue.result!.isNotEmpty)
          ? returnValue.result!
          : 'Processing Complete';
    }
  }

  /// "Not open yet" wording for a kennel's generic code: days, hours or
  /// minutes to the next run. Pure, unit-tested.
  static String notYetOpenMessage(double hoursUntilNextEvent) {
    const String lead = 'The next event does not open for check-in for another';
    if (hoursUntilNextEvent > 24) {
      return '$lead ${NumberFormat('###').format(hoursUntilNextEvent / 24)} days';
    }
    if (hoursUntilNextEvent >= 2) {
      return '$lead ${NumberFormat('##').format(hoursUntilNextEvent)} hours';
    }
    final String minutes = NumberFormat('###').format(hoursUntilNextEvent * 60);
    return '$lead $minutes minute${minutes != '1' ? 's' : ''}';
  }
}
