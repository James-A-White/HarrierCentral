import 'package:harrier_central/imports.dart';

class CheckInScannerController extends GetxController {
  CheckInScannerController(this.eventAggregate);

  final RunAdminAggregate eventAggregate;

  // ── Reactive state ─────────────────────────────────────────────────────────

  final RxString onScreenMessage = 'Waiting to scan'.obs;
  final RxBool isScanning = false.obs;
  final RxBool isScanningAtRunStart = true.obs;
  final Rx<EQrScannerState> scannerState = EQrScannerState.waitingForScan.obs;

  // ── Internal (non-reactive) fields ─────────────────────────────────────────

  MobileScannerController? scannerController;
  String? _result;
  DateTime? _lastScan;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    scannerController = MobileScannerController(
      facing: CameraFacing.back,
      torchEnabled: false,
      detectionSpeed: DetectionSpeed.noDuplicates,
      formats: [BarcodeFormat.qrCode],
    );
  }

  @override
  void onClose() {
    final c = scannerController;
    if (c != null) {
      unawaited(
        Future.microtask(() async {
          await c.stop();
          unawaited(c.dispose());
        }),
      );
    }
    super.onClose();
  }

  // ── Public methods ─────────────────────────────────────────────────────────

  Future<void> toggleScanning({bool? doScanning}) async {
    final c = scannerController;
    if (c == null) return;

    if (isScanning.value && ((doScanning == null) || !doScanning)) {
      await c.pause();
      isScanning.value = false;
      onScreenMessage.value = 'Scanning paused';
      scannerState.value = EQrScannerState.waitingForScan;
    } else {
      if ((doScanning == null) || doScanning) {
        await c.start();
        isScanning.value = true;
        onScreenMessage.value = 'Looking for QR Code';
        scannerState.value = EQrScannerState.scanning;
      }
    }
  }

  /// Called from MobileScanner.onDetect. Applies a 5-second debounce, then
  /// pauses the camera and processes the result.
  Future<void> onCodeDetected(String? rawValue) async {
    _result = rawValue;
    if ((_lastScan == null) ||
        (_lastScan!.difference(DateTime.now()).inSeconds.abs() > 5)) {
      _lastScan = DateTime.now();
      await toggleScanning();
      final r = _result;
      if (r != null) {
        await _onCodeRead(r);
      }
    }
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  Future<void> _onCodeRead(String scanResult) async {
    // Dismiss any visible snack bar.
    final ctx = navigatorKey.currentContext;
    if (ctx != null) {
      ScaffoldMessenger.of(ctx).hideCurrentSnackBar();
    }

    final player = AudioPlayer();
    await player.setAsset('assets/sounds/camera.mp3');
    await player.play();
    await player.dispose();

    final Map<String, String> result = Utilities.validateScan(
      scanResult,
      Utilities.qrScanTypeFlag_user,
    );

    if (result['validScan'] == 'false') {
      onScreenMessage.value = result['validHcQr'] == 'true'
          ? 'This QR code is not valid here'
          : 'QR code not recognized';
      return;
    }

    if ((result['prefix'] == null) || (result['content'] == null)) return;

    final String prefix = result['prefix']!;
    final String content = result['content']!;

    if (prefix != QR_PREFIX_USER_CODE) return;

    onScreenMessage.value = 'Processing QR Scan';

    final int attendanceState = isScanningAtRunStart.value
        ? attendenceAtHash.value
        : attendenceOnIn.value;

    final List<dynamic> adHocData = await tableModel.hasherEventMapService
        .setEventAttendence(
          eventAggregate.event.eventId,
          null,
          AppDomainType.event,
          attendanceState,
          qrScanText: prefix + content,
        );

    if (adHocData.isNotEmpty) {
      double amountOwed = adHocData[0]['isMember'] == 1
          ? eventAggregate.extensions.memberPrice
          : eventAggregate.extensions.nonMemberPrice;

      final num discountAmount = adHocData[0]['discountAmount'];
      final int discountPercent = adHocData[0]['discountPercent'];

      amountOwed -= discountAmount;
      amountOwed -= amountOwed * (discountPercent / 100.0);

      // Show userMessage in a snackbar via global navigator key context.
      // ignore: use_build_context_synchronously
      if (navigatorKey.currentContext != null) {
        // ignore: use_build_context_synchronously
        IveCoreUtilities.showInSnackBar(
          // ignore: use_build_context_synchronously
          navigatorKey.currentContext!,
          adHocData[0]['userMessage'] as String,
          durationInSeconds: 5,
        );
      }

      if ((adHocData[0]['isPaid'] != 0) || (amountOwed <= 0)) {
        // Already paid or zero balance — no payment dialog needed.
      } else {
        final PaymentPopup pp = PaymentPopup(
          amount: amountOwed,
          creditAllowed: 1,
          creditRemaining: 0,
          currencySymbol: eventAggregate.extensions.curSym,
          hemId: adHocData[0]['hasherEventMapId'] as String,
          decimalDigits: eventAggregate.extensions.digAfterDec,
          allowDefaultPricing: adHocData[0]['isMember'] == 1,
        );

        final PaymentPopupResult? popupResult =
            await Get.dialog<PaymentPopupResult>(pp, barrierDismissible: false);

        if ((popupResult != null) && (popupResult.transactionType != -1)) {
          onScreenMessage.value = 'Please wait, processing payment';
          await _payForEvent(
            adHocData[0]['hasherEventMapId'] as String,
            popupResult.transactionType,
            popupResult.transactionValue,
          );
        }
      }
    }

    onScreenMessage.value = 'Processing Complete';
    await Future<void>.delayed(const Duration(seconds: 2));
    await toggleScanning(doScanning: true);
  }

  Future<void> _payForEvent(
    String hemId,
    int paymentType,
    double amount,
  ) async {
    final PaymentsService paySrv = PaymentsService();
    final List<dynamic> paymentResult = await paySrv.payForEvent(
      eventAggregate.event.eventId,
      GUID_EMPTY,
      hemId,
      paymentType,
      amount,
      attendenceAtHash.value,
      payForRunOnly,
      AppDomainType.event,
    );

    if (paymentResult.isNotEmpty) {
      final int paidType = paymentResult[0]['paymentType'] as int;
      final String amountPaid = IveCoreUtilities.getFormattedMoney(
        paymentResult[0]['creditAmount'] ?? 0,
        eventAggregate.extensions.digAfterDec,
        eventAggregate.extensions.curSym,
      );

      String message = paymentResult[0]['hasherWhoPaid'] as String;

      if (paymentResult[0]['attendenceState'] == attendenceAtHash.value) {
        message += ' is checked in and';
      } else if (paymentResult[0]['attendenceState'] == attendenceOnIn.value) {
        message += ' is On Inn and';
      }

      switch (paidType) {
        case 1:
          message += ' has not paid and needs to pay for the Hash';
        case 2:
          message += ' enjoyed a FREE Hash today';
        case 3:
          message += ' has paid $amountPaid in cash';
        case 4:
          message += ' has paid $amountPaid by bank transfer';
        case 5:
          message += ' has paid $amountPaid in cash';
        case 6:
          message += ' has paid $amountPaid using Hash credit';
        case 7:
          message += ' has paid $amountPaid by bank transfer';
        default:
          break;
      }

      onScreenMessage.value = message;

      final ctx = navigatorKey.currentContext;
      if (ctx != null) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(ctx).hideCurrentSnackBar();
      }

      await Future<void>.delayed(const Duration(milliseconds: 4500));
      await toggleScanning(doScanning: true);
    }
  }
}
