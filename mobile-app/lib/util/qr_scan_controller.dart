import 'package:harrier_central/imports.dart';

/// The QR scanner state machine shared by the check-in scanner and the
/// invite-code page: one MobileScannerController, a scanning flag, and the
/// one-code-per-five-seconds debounce. Subclasses say what a code means.
///
/// Until 2026-09-23 each of those two pages carried its own copy of this in
/// a State; the duplication was the smell.
abstract class QrScanController extends GetxController {
  final MobileScannerController scanner = MobileScannerController(
    facing: CameraFacing.back,
    torchEnabled: false,
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: [BarcodeFormat.qrCode],
  );

  final RxBool isScanning = false.obs;
  DateTime? _lastScan;

  @override
  void onClose() {
    unawaited(
      Future.microtask(() async {
        await scanner.stop();
        unawaited(scanner.dispose());
      }),
    );
    super.onClose();
  }

  /// Pause if scanning, start if not; [doScanning] forces one direction.
  Future<void> toggleScanning({bool? doScanning}) async {
    if (isScanning.value && ((doScanning == null) || !doScanning)) {
      await scanner.pause();
      if (isClosed) return;
      isScanning.value = false;
      onScanningPaused();
    } else if ((doScanning == null) || doScanning) {
      await scanner.start();
      if (isClosed) return;
      isScanning.value = true;
      onScanningStarted();
    }
  }

  void onScanningPaused() {}
  void onScanningStarted() {}

  /// MobileScanner's onDetect: "debounce" the listener to discard multiple
  /// scans that happen within a 5 second window, pause, then handle.
  Future<void> onDetect(BarcodeCapture capture) async {
    if (capture.barcodes.isEmpty) return;
    final String? code = capture.barcodes.first.rawValue;
    final DateTime now = DateTime.now();
    if (_lastScan != null && _lastScan!.difference(now).inSeconds.abs() <= 5) {
      return;
    }
    _lastScan = now;
    await toggleScanning();
    if (isClosed || code == null) return;
    await onCodeRead(code);
  }

  /// What a scanned code means on this page.
  Future<void> onCodeRead(String code);
}
