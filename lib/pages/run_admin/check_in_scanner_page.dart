import 'package:harrier_central/imports.dart';

class CheckInScannerPage extends StatefulWidget {
  const CheckInScannerPage({
    Key? key,
    required this.eventAggregate,
  }) : super(key: key);

  final RunAdminAggregate eventAggregate;

  @override
  CheckInScannerPageState createState() => CheckInScannerPageState();
}

final GlobalKey _qrKey = GlobalKey(debugLabel: 'QR');
bool _isScanningAtRunStart = true;

final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

class CheckInScannerPageState extends State<CheckInScannerPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: themeAppBarBackground,
        title: const Text(
          'Scan at start & end of Hash',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: Container(
        decoration: Backgrounds.defaultHcBackground(),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Expanded(
                child: Column(
                  //alignment: AlignmentDirectional.center,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.only(top: 30.0, left: 30.0, right: 30.0, bottom: 20.0),
                      child: const AutoSizeText(
                        'Use this scanner to scan Hasher barcodes at the start of the run so you know who is at the Hash and at the end of the run so you can ensure that no one is lost on trail.',
                        textAlign: TextAlign.justify,
                        maxLines: 4,
                        style: TextStyle(color: Colors.white, fontFamily: 'AvenirNextDemiBold', fontStyle: FontStyle.normal, fontSize: 16.0, height: 0.8),
                      ),
                    ),
                    if ((_state != EQrScannerState.scanning) || _isScanningAtRunStart) ...<Widget>[
                      Container(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: ElevatedButton(
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.resolveWith<Color?>(
                                (Set<MaterialState> states) {
                                  if (states.contains(MaterialState.disabled)) {
                                    return Colors.grey.shade700;
                                  }
                                  return null; // Use the component's default.
                                },
                              ),
                              textStyle: MaterialStateProperty.resolveWith<TextStyle?>(
                                (Set<MaterialState> states) {
                                  if (states.contains(MaterialState.disabled)) {
                                    return TextStyle(color: Colors.grey.shade200);
                                  }
                                  return null; // Use the component's default.
                                },
                              ),
                            ),
                            child: Text(
                              ((_state == EQrScannerState.scanning) && _isScanningAtRunStart) ? 'Stop Scanning' : 'Scan at start of run',
                              style: const TextStyle(
                                  fontFamily: 'AvenirNextDemiBold',
                                  //color: Colors.white,
                                  fontStyle: FontStyle.normal,
                                  fontSize: 22.0,
                                  height: 1.0),
                            ),
                            //disabledTextColor: Colors.grey[200],

                            onPressed: () async {
                              _isScanningAtRunStart = true;
                              await _toggleScanning();
                            }),
                      ),
                    ],
                    Expanded(
                      //padding: EdgeInsets.all(10 * (G0<DeviceInfo>().deviceMaxScaleFactor * 1.5)),
                      child: Stack(
                        alignment: AlignmentDirectional.center,
                        children: <Widget>[
                          Image.asset(
                            'images/other/qr_scanner.png',
                          ),
                          Container(
                            padding: const EdgeInsets.all(11.0),
                            child: AspectRatio(
                              aspectRatio: 1.0,
                              child: QRView(
                                key: _qrKey,
                                onQRViewCreated: _onQRViewCreated,
                              ),
                            ),
                          ),
                          if ((!_isScanning) && (_state == EQrScannerState.waitingForScan)) ...<Widget>[
                            Image.asset(
                              'images/other/qr_scanner.png',
                            ),
                          ],
                          if ((!_isScanning) && (_state == EQrScannerState.isProcessing)) ...<Widget>[
                            Image.asset(
                              'images/other/uploading_to_cloud.png',
                            ),
                          ],
                          if ((!_isScanning) && (_state == EQrScannerState.dataRecorded)) ...<Widget>[
                            Image.asset(
                              'images/other/run_info_recorded.png',
                            ),
                          ],
                          if ((!_isScanning) && (_state == EQrScannerState.qrNotRecognized)) ...<Widget>[
                            Image.asset(
                              'images/other/qr_not_recognized.png',
                            ),
                          ],
                        ],
                      ),
                    ),
                    if ((_state != EQrScannerState.scanning) || !_isScanningAtRunStart) ...<Widget>[
                      Container(
                        padding: const EdgeInsets.only(top: 20.0),
                        child: ElevatedButton(
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.resolveWith<Color?>(
                                (Set<MaterialState> states) {
                                  if (states.contains(MaterialState.disabled)) {
                                    return Colors.grey.shade700;
                                  }
                                  return null; // Use the component's default.
                                },
                              ),
                              textStyle: MaterialStateProperty.resolveWith<TextStyle?>(
                                (Set<MaterialState> states) {
                                  if (states.contains(MaterialState.disabled)) {
                                    return TextStyle(color: Colors.grey.shade200);
                                  }
                                  return null; // Use the component's default.
                                },
                              ),
                            ),
                            onPressed: () async {
                              _isScanningAtRunStart = false;
                              await _toggleScanning();
                            },
                            child: Text(
                              //'Scan at end of run',
                              ((_state == EQrScannerState.scanning) && !_isScanningAtRunStart) ? 'Stop Scanning' : 'Scan at end of run',
                              style: const TextStyle(
                                  fontFamily: 'AvenirNextDemiBold',
                                  //color: Colors.white,
                                  fontStyle: FontStyle.normal,
                                  fontSize: 22.0,
                                  height: 1.0),
                            )),
                      ),
                    ],
                    SizedBox(
                      //color:Colors.yellow,
                      height: 100,
                      child: Center(
                        child: AutoSizeText(
                          _onScreenMessage,
                          //'This is a test of how ',
                          //'This is a test of how this works with 2 lines ',
                          //'this is a test of how 3 lines will fit Ill need a lot more text than that to make it work',
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          style: const TextStyle(fontFamily: 'AvenirNextDemiBold', fontStyle: FontStyle.normal, color: Colors.yellow, fontSize: 26.0, height: 0.9),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _onScreenMessage = 'Waiting to scan';
  String? _result;
  bool _isScanning = false;

  QRViewController? _controller;
  EQrScannerState _state = EQrScannerState.waitingForScan;

  void _onQRViewCreated(QRViewController controller) {
    _controller = controller;
    setState(() {
      // _isScanning = true;
      // _onScreenMessage = 'Looking for QR Code';
      // _state = EQrScannerState.scanning;
      //_toggleScanning();
    });

    if (_controller != null) {
      _controller!.scannedDataStream.listen((Barcode scanData) async {
        _result = scanData.code;
        // "debounce" the listener to discard multiple scans
        // that happen within a 5 second window.
        if ((_lastScan == null) || (_lastScan!.difference(DateTime.now()).inSeconds.abs() > 5)) {
          _lastScan = DateTime.now();
          await _toggleScanning();
          await _onCodeRead(_result);
        }
      });
    }
  }

  DateTime? _lastScan;

  @override
  void reassemble() {
    super.reassemble();
    if (_controller != null) {
      if (Platform.isAndroid) {
        _controller!.pauseCamera();
        _isScanning = false;
        _onScreenMessage = 'Scanning paused';
        _state = EQrScannerState.waitingForScan;
      } else if (Platform.isIOS) {
        _controller!.resumeCamera();
        _isScanning = true;
        _onScreenMessage = 'Looking for QR Code';
        _state = EQrScannerState.scanning;
      }
    }
  }

  Future<void> _toggleScanning({bool? doScanning}) async {
    if (_controller != null) {
      if (_isScanning && ((doScanning == null) || !doScanning)) {
        await _controller!.pauseCamera();
        _isScanning = false;
        setState(() {
          _onScreenMessage = 'Scanning paused';
        });
        _state = EQrScannerState.waitingForScan;
      } else {
        if ((doScanning == null) || doScanning) {
          await _controller!.resumeCamera();
          _isScanning = true;
          setState(() {
            _onScreenMessage = 'Looking for QR Code';
          });
          _state = EQrScannerState.scanning;
        }
      }
    }
  }

  Future<void> _onCodeRead(dynamic scanResult) async {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    final AudioCache audioPlayer = AudioCache(prefix: 'assets/sounds/');
    // ignore: unawaited_futures
    await audioPlayer.play('camera.mp3');

    final Map<String, String> result = Utilities.validateScan(scanResult, Utilities.qrScanTypeFlag_user);

    if (result['validScan'] == 'false') {
      setState(() {
        _onScreenMessage = result['validHcQr'] == 'true' ? 'This QR code is not valid here' : 'QR code not recignized';
      });
    } else {
      if ((result['prefix'] != null) && (result['content'] != null)) {
        final String prefix = result['prefix']!;
        final String content = result['content']!;

        if (prefix != QR_PREFIX_USER_CODE) {
          // NOTE: We should never get to this point in, but set
          //print('ERROR! The app should never reach this point.');
        } else {
          setState(() {
            _onScreenMessage = 'Processing QR Scan';
          });
          final int attendenceState = _isScanningAtRunStart ? attendenceAtHash.value : attendenceOnIn.value;

          final List<dynamic> adHocData = await G0<TableModel>().hasherEventMapService.setEventAttendence(
                widget.eventAggregate.event.eventId,
                null, // result['hasher'].hasherId,
                AppDomainType.event,
                attendenceState,
                qrScanText: prefix + content,
              );

          if (adHocData.isNotEmpty) {
            double amountOwed = adHocData[0]['isMember'] == 1 ? widget.eventAggregate.extensions.memberPrice : widget.eventAggregate.extensions.nonMemberPrice;

            final num discountAmount = adHocData[0]['discountAmount'];
            final int discountPercent = adHocData[0]['discountPercent'];
            //final String discountDescription = adHocData[0]['discountDescription'];

            amountOwed -= discountAmount;
            amountOwed -= amountOwed * (discountPercent / 100.0);

            if (!mounted) return;
            IveCoreUtilities.showInSnackBar(context, _scaffoldKey, adHocData[0]['userMessage'], durationInSeconds: 5);
            //
            if ((adHocData[0]['isPaid'] != 0) || (amountOwed <= 0)) {
              //scanUserBarcode();
              // Future<void>.delayed(const Duration(seconds: 4)).then((void _) {
              //   scanUserBarcode();
              // });
            } else {
              final PaymentPopup pp = PaymentPopup(
                amount: amountOwed,
                creditAllowed: 1, // TODO(James): fix this in the DB so that Kennnels can disable credit
                creditRemaining: 0,
                currencySymbol: widget.eventAggregate.extensions.curSym,
                hemId: adHocData[0]['hasherEventMapId'],
                decimalDigits: widget.eventAggregate.extensions.digAfterDec,
                allowDefaultPricing: adHocData[0]['isMember'] == 1,
                // valueChanged: (num value) {
                //   finalValue = value;
                // },
              );

              final PaymentPopupResult? popupResult = await showDialog<PaymentPopupResult>(
                  context: context,
                  barrierDismissible: false, // user must tap button!
                  builder: (BuildContext context) {
                    return pp;
                  });

              if ((popupResult != null) && (popupResult.transactionType != -1)) {
                setState(() {
                  _onScreenMessage = 'Please wait, processing payment';
                });

                await _payForEvent(adHocData[0]['hasherEventMapId'], popupResult.transactionType, popupResult.transactionValue);
              }
            }
          }
          setState(() {
            _onScreenMessage = 'Processing Complete';
          });
          await Future<void>.delayed(const Duration(seconds: 2));
          await _toggleScanning(doScanning: true);
        }
      }
    }
  }

  Future<void> _payForEvent(String hemId, int paymentType, double amount) async {
    final PaymentsService paySrv = PaymentsService();
    final List<dynamic> paymentResult =
        await paySrv.payForEvent(widget.eventAggregate.event.eventId, GUID_EMPTY, hemId, paymentType, amount, attendenceAtHash.value, payForRunOnly, AppDomainType.event);

    if ((paymentResult != null) && (paymentResult.isNotEmpty)) {
      final int paymentType = paymentResult[0]['paymentType'];
      final String amountPaid = IveCoreUtilities.getFormattedMoney(paymentResult[0]['creditAmount'] ?? 0, widget.eventAggregate.extensions.digAfterDec, widget.eventAggregate.extensions.curSym);

      _onScreenMessage = paymentResult[0]['hasherWhoPaid'];

      if (paymentResult[0]['attendenceState'] == attendenceAtHash.value) {
        _onScreenMessage += ' is checked in and';
      } else if (paymentResult[0]['attendenceState'] == attendenceOnIn.value) {
        _onScreenMessage += ' is On Inn and';
      }

      switch (paymentType) {
        case 1:
          _onScreenMessage += ' has not paid and needs to pay for the Hash';
          break;
        case 2:
          _onScreenMessage += ' enjoyed a FREE Hash today';
          break;
        case 3:
          _onScreenMessage += ' has paid $amountPaid in cash';
          break;
        case 4:
          _onScreenMessage += ' has paid $amountPaid by bank transfer';
          break;
        case 5:
          _onScreenMessage += ' has paid $amountPaid in cash';
          break;
        case 6:
          _onScreenMessage += ' has paid $amountPaid using Hash credit';
          break;
        case 7:
          _onScreenMessage += ' has paid $amountPaid by bank transfer';
          break;
        default:
          break;
      }
      setState(() {});

      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      await Future<void>.delayed(const Duration(milliseconds: 4500));

      await _toggleScanning(doScanning: true);
    }
  }
}
