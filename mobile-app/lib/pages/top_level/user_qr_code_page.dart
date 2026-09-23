import 'package:harrier_central/imports.dart';

/// The "Run check in page": Scan / Be Scanned. Stateless over
/// [UserQrCodeController], which owns the tab and the scanner for as long as
/// the page is open.
class UserQrCodePage extends StatelessWidget {
  const UserQrCodePage({super.key});

  static const List<Tab> _tabs = <Tab>[
    Tab(text: 'Scan'),
    Tab(text: 'Be Scanned'),
  ];

  @override
  Widget build(BuildContext context) {
    return GetBuilder<UserQrCodeController>(
      init: UserQrCodeController(),
      tag: UserQrCodeController.tag,
      builder: (UserQrCodeController c) => Stack(
        children: <Widget>[
          SizedBox(
            height: MediaQuery.sizeOf(context).height,
            width: MediaQuery.sizeOf(context).width,
          ),
          Positioned(
            top: 0,
            left: 0,
            width: MediaQuery.sizeOf(context).width,
            height: MediaQuery.sizeOf(context).height,
            child: AppScaffold(
              appBar: AppBar(
                centerTitle: true,
                backgroundColor: themeAppBarBackground,
                iconTheme: const IconThemeData(color: Colors.white, size: 28.0),
                actions: <IconButton>[
                  IconButton(
                    icon: const Icon(Icons.info_outline),
                    onPressed: () => _displayInstructions(context, c),
                  ),
                ],
                title: Text('Run check in page', style: ts_appBarTitle),
              ),
              body: Container(
                decoration: Backgrounds.defaultHcBackground(),
                child: Stack(
                  alignment: AlignmentDirectional.center,
                  children: <Widget>[
                    Positioned(
                      top: 20,
                      left: 20,
                      right: 20,
                      child: Container(
                        width: 340.0,
                        height: 45.0,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColorLight,
                          borderRadius: const BorderRadius.all(
                            Radius.circular(35.0),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 1.0, right: 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(999),
                            ),
                            padding: const EdgeInsets.all(5.0),
                            // Reviewed for 2.0+
                            child: TabBar(
                              labelStyle: ts_tabSelected,
                              unselectedLabelStyle: ts_tabUnselected,
                              isScrollable: false,
                              unselectedLabelColor: Colors.black,
                              labelColor: Colors.white,
                              labelPadding: const EdgeInsets.only(
                                top: 5,
                                left: 20,
                                right: 20,
                              ),
                              indicatorSize: TabBarIndicatorSize.tab,
                              indicator: BoxDecoration(
                                color: hc_red,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              indicatorColor: Colors.transparent,
                              tabs: _tabs,
                              controller: c.tabController,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // left/right pin the tab view to the body's actual width
                    // (a MediaQuery width here would be the whole window on a
                    // tablet, overflowing the centred content column).
                    Positioned(
                      top: 80,
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: TabBarView(
                        controller: c.tabController,
                        children: const <Widget>[QrScannerTab(), QrCodeTab()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _displayInstructions(
    BuildContext context,
    UserQrCodeController c,
  ) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Your QR Code', style: ts_alertDialogTitle),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  c.tabController.index == 0
                      ? 'Mis-management can scan this code to keep your run counts accurate and ensure that no one is left behind on trail at the end of a run.\r\n\r\nThis is your unique code. If you don\'t normally carry a phone, you can //print this code as a way to be quickly checked in at Hash runs.'
                      : 'You can use your QR scanner to check in when you arrive at runs and to check in when you are done with trail so the hares know who is still out on trail.',
                  textAlign: TextAlign.justify,
                  style: ts_alertDialogBody,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: text_button_style,
              child: Text('OK, Got it!', style: ts_button),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }
}

class QrCodeTab extends StatefulWidget {
  const QrCodeTab({super.key});

  @override
  QrCodeTabState createState() => QrCodeTabState();
}

class QrCodeTabState extends State<QrCodeTab>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final String userName = getStringPref(StringPrefsEnum.displayName) ?? '';
    final String userQrCode = getStringPref(StringPrefsEnum.qrCode) ?? '';

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SizedBox(
                width: 10,
                height: (deviceInfo.deviceWidthScaleFactor - 1) * 90,
              ),
              Container(
                padding: const EdgeInsets.only(
                  top: 0,
                  bottom: 30,
                  right: 25,
                  left: 25,
                ),
                child: Text(
                  'This code can be scanned by mismanagement to check you in at the beginning and end of runs.',
                  textAlign: TextAlign.justify,
                  style: ts_titleMedium.copyWith(
                    fontSize: 16.0 * deviceInfo.deviceWidthScaleFactor,
                  ),
                ),
              ),

              AutoSizeText(
                'QR for: $userName',
                //'QR Code for xxx',
                textAlign: TextAlign.center,
                maxLines: 1,
                style: ts_titleMedium.copyWith(
                  fontSize: 24.0 * deviceInfo.deviceWidthScaleFactor,
                ),
              ),

              // Positioned(
              //   top: 127,

              //   child: Container(
              //                       color: Colors.white,
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 20,
                    bottom: 10,
                    left: 30,
                    right: 30,
                  ),
                  child: Stack(
                    alignment: AlignmentDirectional.center,
                    //height: min(constraints.maxHeight, constraints.maxWidth) * 0.65,
                    children: <Widget>[
                      // A QR code fills whatever it is given; on a tablet
                      // that would be ~1000pt, so cap it (see FormFactor).
                      ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: FormFactor.maxQrSize,
                          maxHeight: FormFactor.maxQrSize,
                        ),
                        child: QrImageView(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.all(10.0),
                          data: BASE_HCWEB_MOBILE_URL + userQrCode,
                          //data: 'testing123',
                          version: 5,
                          //size: 200.0,
                          errorCorrectionLevel: QrErrorCorrectLevel.M,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The Scan tab. Stateless; its state is the page's [UserQrCodeController],
/// so swiping away and back does not restart the scanner.
class QrScannerTab extends StatelessWidget {
  const QrScannerTab({super.key});

  @override
  Widget build(BuildContext context) {
    final UserQrCodeController c = Get.find<UserQrCodeController>(
      tag: UserQrCodeController.tag,
    );
    return Column(
      children: <Widget>[
        SizedBox(
          width: 10,
          height: (deviceInfo.deviceWidthScaleFactor - 1) * 90,
        ),
        Container(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: AutoSizeText(
            'Use this scanner to scan QR codes at the beginning and end of runs to check in.',
            textAlign: TextAlign.justify,
            maxLines: 4,
            style: ts_titleMedium.copyWith(
              fontSize: 16.0 * deviceInfo.deviceWidthScaleFactor,
            ),
          ),
        ),
        Expanded(
          child: Container(
            padding: EdgeInsets.all(
              10 * (deviceInfo.deviceMaxScaleFactor * 1.5),
            ),
            child: Obx(() {
              final bool scanning = c.isScanning.value;
              final EQrScannerState state = c.state.value;
              return Stack(
                alignment: AlignmentDirectional.center,
                children: <Widget>[
                  Image.asset('images/other/qr_scanner.png'),
                  Container(
                    padding: const EdgeInsets.all(11.0),
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: MobileScanner(
                        controller: c.scanner,
                        onDetect: c.onDetect,
                      ),
                    ),
                  ),
                  if (!scanning && state == EQrScannerState.waitingForScan)
                    Image.asset('images/other/qr_scanner.png'),
                  if (!scanning && state == EQrScannerState.isProcessing)
                    Image.asset('images/other/uploading_to_cloud.png'),
                  if (!scanning && state == EQrScannerState.dataRecorded)
                    Image.asset('images/other/run_info_recorded.png'),
                  if (!scanning && state == EQrScannerState.qrNotRecognized)
                    Image.asset('images/other/qr_not_recognized.png'),
                ],
              );
            }),
          ),
        ),
        Obx(() {
          if (c.state.value == EQrScannerState.dataRecorded) {
            return const SizedBox.shrink();
          }
          return Container(
            margin: const EdgeInsets.all(10.0),
            height: 40.0,
            child: StyleForConnected(
              child: ElevatedButton(
                child: Text(
                  c.isScanning.value ? 'Stop Scanning' : 'Start Scanning',
                  style: ts_title,
                ),
                onPressed: () => unawaited(c.tapStartStop()),
              ),
            ),
          );
        }),
        Container(
          padding: const EdgeInsets.only(
            top: 20,
            bottom: 30,
            left: 20,
            right: 20,
          ),
          child: Center(
            child: Obx(
              () => AutoSizeText(
                c.onScreenMessage.value,
                textAlign: TextAlign.center,
                maxLines: 3,
                style: ts_headingLarge,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
