import 'package:harrier_central/imports.dart';

class CheckInScannerPage extends StatefulWidget {
  const CheckInScannerPage({super.key, required this.eventAggregate});

  final RunAdminAggregate eventAggregate;

  @override
  CheckInScannerPageState createState() => CheckInScannerPageState();
}

class CheckInScannerPageState extends State<CheckInScannerPage> {
  late final CheckInScannerController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(CheckInScannerController(widget.eventAggregate));
  }

  @override
  void dispose() {
    Get.delete<CheckInScannerController>();
    super.dispose();
  }

  @override
  void reassemble() {
    super.reassemble();
    final c = controller.scannerController;
    if (c == null) return;

    // Hot-reload camera handling (debug builds only).
    assert(() {
      if (Platform.isAndroid) {
        unawaited(
          c
              .pause()
              .then((_) {
                if (!mounted) return;
                controller.isScanning.value = false;
                controller.onScreenMessage.value = 'Scanning paused';
                controller.scannerState.value = EQrScannerState.waitingForScan;
              })
              .catchError((Object e, StackTrace st) {}),
        );
      } else if (Platform.isIOS) {
        unawaited(
          c
              .start()
              .then((_) {
                if (!mounted) return;
                controller.isScanning.value = true;
                controller.onScreenMessage.value = 'Looking for QR Code';
                controller.scannerState.value = EQrScannerState.scanning;
              })
              .catchError((Object e, StackTrace st) {}),
        );
      }
      return true;
    }());
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: themeAppBarBackground,
        iconTheme: const IconThemeData(color: Colors.white, size: 28.0),
        title: Text('Scan at start & end of Hash', style: ts_appBarTitle),
      ),
      body: Container(
        decoration: Backgrounds.defaultHcBackground(),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Expanded(
                child: Obx(
                  () => Column(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.only(
                          top: 30.0,
                          left: 30.0,
                          right: 30.0,
                          bottom: 20.0,
                        ),
                        child: AutoSizeText(
                          'Use this scanner to scan Hasher barcodes at the start of the run so you know who is at the Hash and at the end of the run so you can ensure that no one is lost on trail.',
                          textAlign: TextAlign.justify,
                          maxLines: 4,
                          style: ts_titleMedium.copyWith(height: 0.8),
                        ),
                      ),
                      // "Scan at start of run" button — visible when not in
                      // mid-scan-end-of-run mode.
                      if ((controller.scannerState.value !=
                              EQrScannerState.scanning) ||
                          controller.isScanningAtRunStart.value) ...<Widget>[
                        Container(
                          padding: const EdgeInsets.only(bottom: 20.0),
                          child: ElevatedButton(
                            style: ButtonStyle(
                              backgroundColor:
                                  WidgetStateProperty.resolveWith<Color?>((
                                    Set<WidgetState> states,
                                  ) {
                                    if (states.contains(WidgetState.disabled)) {
                                      return Colors.grey.shade700;
                                    }
                                    return null;
                                  }),
                              textStyle:
                                  WidgetStateProperty.resolveWith<TextStyle?>((
                                    Set<WidgetState> states,
                                  ) {
                                    if (states.contains(WidgetState.disabled)) {
                                      return TextStyle(
                                        color: Colors.grey.shade200,
                                      );
                                    }
                                    return null;
                                  }),
                            ),
                            onPressed: () async {
                              controller.isScanningAtRunStart.value = true;
                              await controller.toggleScanning();
                            },
                            child: Text(
                              ((controller.scannerState.value ==
                                          EQrScannerState.scanning) &&
                                      controller.isScanningAtRunStart.value)
                                  ? 'Stop Scanning'
                                  : 'Scan at start of run',
                              style: ts_title,
                            ),
                          ),
                        ),
                      ],
                      Expanded(
                        child: Stack(
                          alignment: AlignmentDirectional.center,
                          children: <Widget>[
                            Image.asset('images/other/qr_scanner.png'),
                            Container(
                              padding: const EdgeInsets.all(11.0),
                              child: AspectRatio(
                                aspectRatio: 1.0,
                                child: MobileScanner(
                                  controller: controller.scannerController,
                                  onDetect: (BarcodeCapture result) {
                                    final String? rawValue =
                                        result.barcodes.first.rawValue;
                                    unawaited(
                                      controller.onCodeDetected(rawValue),
                                    );
                                  },
                                ),
                              ),
                            ),
                            if ((!controller.isScanning.value) &&
                                (controller.scannerState.value ==
                                    EQrScannerState.waitingForScan)) ...<
                              Widget
                            >[Image.asset('images/other/qr_scanner.png')],
                            if ((!controller.isScanning.value) &&
                                (controller.scannerState.value ==
                                    EQrScannerState.isProcessing)) ...<Widget>[
                              Image.asset(
                                'images/other/uploading_to_cloud.png',
                              ),
                            ],
                            if ((!controller.isScanning.value) &&
                                (controller.scannerState.value ==
                                    EQrScannerState.dataRecorded)) ...<Widget>[
                              Image.asset('images/other/run_info_recorded.png'),
                            ],
                            if ((!controller.isScanning.value) &&
                                (controller.scannerState.value ==
                                    EQrScannerState
                                        .qrNotRecognized)) ...<Widget>[
                              Image.asset('images/other/qr_not_recognized.png'),
                            ],
                          ],
                        ),
                      ),
                      // "Scan at end of run" button — visible when not in
                      // mid-scan-start-of-run mode.
                      if ((controller.scannerState.value !=
                              EQrScannerState.scanning) ||
                          !controller.isScanningAtRunStart.value) ...<Widget>[
                        Container(
                          padding: const EdgeInsets.only(top: 20.0),
                          child: ElevatedButton(
                            style: ButtonStyle(
                              backgroundColor:
                                  WidgetStateProperty.resolveWith<Color?>((
                                    Set<WidgetState> states,
                                  ) {
                                    if (states.contains(WidgetState.disabled)) {
                                      return Colors.grey.shade700;
                                    }
                                    return null;
                                  }),
                              textStyle:
                                  WidgetStateProperty.resolveWith<TextStyle?>((
                                    Set<WidgetState> states,
                                  ) {
                                    if (states.contains(WidgetState.disabled)) {
                                      return TextStyle(
                                        color: Colors.grey.shade200,
                                      );
                                    }
                                    return null;
                                  }),
                            ),
                            onPressed: () async {
                              controller.isScanningAtRunStart.value = false;
                              await controller.toggleScanning();
                            },
                            child: Text(
                              ((controller.scannerState.value ==
                                          EQrScannerState.scanning) &&
                                      !controller.isScanningAtRunStart.value)
                                  ? 'Stop Scanning'
                                  : 'Scan at end of run',
                              style: ts_title,
                            ),
                          ),
                        ),
                      ],
                      SizedBox(
                        height: 100,
                        child: Center(
                          child: AutoSizeText(
                            controller.onScreenMessage.value,
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            style: ts_headingLarge.copyWith(height: 0.9),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
