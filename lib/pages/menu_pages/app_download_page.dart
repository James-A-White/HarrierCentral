// @dart=2.11
import 'package:harrier_central/imports.dart';

class AppDownloadPage extends StatefulWidget {
  const AppDownloadPage({Key key}) : super(key: key);

  @override
  _AppDownloadPageState createState() => _AppDownloadPageState();
}

class _AppDownloadPageState extends State<AppDownloadPage> with SingleTickerProviderStateMixin {
  List<Tab> tabs = <Tab>[];

  String barcode = '';
  bool isAdmin = true;

  PageController _pageController;
  TabController _tabController;

  final String userId = getStringPref(StringPrefsEnum.userId);

  GlobalKey tabKey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: themeAppBarBackground,
        title: const Text(
          'App Download Links',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: Container(
        decoration: Backgrounds.defaultHcBackground(),
        child: Stack(
          alignment: AlignmentDirectional.center,
          children: <Widget>[
            // Positioned(
            //     top: 30,
            //     left: 0,
            //     right: 0,
            //     child: Text(
            //       'QR Code Scanner',
            //       textAlign: TextAlign.center,
            //       style: const TextStyle(
            //           fontFamily: 'AvenirNextRegular',
            //           fontStyle: FontStyle.normal,
            //           color: Colors.white,
            //           fontSize: 24.0,
            //           height: 1.0),
            //     )),
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Container(
                width: 340.0,
                height: 45.0,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColorLight,
                  borderRadius: const BorderRadius.all(Radius.circular(35.0)),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 1.0, right: 1.0),
                  child: TabBar(
                    labelStyle: const TextStyle(fontFamily: 'AvenirNextCondensedMedium', fontStyle: FontStyle.normal, fontSize: 18.0, height: 1.0),
                    unselectedLabelStyle: const TextStyle(fontFamily: 'AvenirNextCondensedMedium', fontStyle: FontStyle.normal, fontSize: 18.0, height: 1.0),
                    isScrollable: false,
                    unselectedLabelColor: Colors.black,
                    labelColor: Colors.white,
                    labelPadding: const EdgeInsets.only(top: 5, left: 20, right: 20),
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BubbleTabIndicator(
                      indicatorHeight: 35.0,
                      indicatorColor: Colors.red.shade900,
                      tabBarIndicatorSize: TabBarIndicatorSize.tab,
                      indicatorRadius: 20.0,
                    ),
                    tabs: tabs,
                    controller: _tabController,
                  ),
                ),
              ),
            ),
            Positioned(
                top: 80,
                bottom: 0,
                child: SizedBox(
                  key: tabKey,
                  //color: Colors.teal,
                  width: MediaQuery.of(context).size.width,
                  child: TabBarView(
                    controller: _tabController,
                    children: const <Widget>[IosDownloadTab(), AndroidDownloadTab()],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController?.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initTabs();

    _pageController = PageController(initialPage: 0, keepPage: true);
    _tabController = TabController(vsync: this, length: tabs.length);
  }

  Color left = Colors.white;
  Color right = Colors.white;

  // Widget _buildMenuBar(BuildContext context) {
  //   return Container(
  //     width: 300.0,
  //     height: 50.0,
  //     decoration: const BoxDecoration(
  //       color: Color(0x552B2B2B),
  //       borderRadius: BorderRadius.all(Radius.circular(25.0)),
  //     ),
  //     child: CustomPaint(
  //       painter: TabIndicationPainter(
  //           context: context, pageController: _pageController),
  //       child: Row(
  //         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //         children: <Widget>[
  //           Expanded(
  //             child: TextButton(
  //               splashColor: Colors.transparent,
  //               highlightColor: Colors.transparent,
  //               onPressed: _onSwitchToQrScanner,
  //               child: Text(
  //                 'Scan',
  //                 style: const TextStyle(
  //                     color: left,
  //                     fontSize: 14.0,
  //                     fontFamily: 'WorkSansSemiBold'),
  //               ),
  //             ),
  //           ),
  //           Expanded(
  //             child: TextButton(
  //               splashColor: Colors.transparent,
  //               highlightColor: Colors.transparent,
  //               onPressed: _onSwitchToQrCode,
  //               child: Text(
  //                 'My Scanner',
  //                 style: const TextStyle(
  //                     color: right,
  //                     fontSize: 14.0,
  //                     fontFamily: 'WorkSansSemiBold'),
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // Future<bool> _displayInstructions(BuildContext context) async {
  //   return showDialog<bool>(
  //     context: context,
  //     barrierDismissible: false, // user must tap button!
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: const Text('About your QR Scanner'),
  //         content: SingleChildScrollView(
  //           child: ListBody(
  //             children: const <Widget>[
  //               Text(
  //                 'You can use your QR scanner to add friends to your Harrier Central friend list simply by scanning their personal QR code. You can also use your scanner to check in when you arrive at runs and to check in when you are done with trail so the hares know who is still out.',
  //                 textAlign: TextAlign.justify,
  //                 style: TextStyle(fontFamily: 'AvenirNextRegular', fontStyle: FontStyle.normal, fontSize: 16.0, height: 1.0),
  //               )
  //             ],
  //           ),
  //         ),
  //         actions: <Widget>[
  //           TextButton(
  //             child: const Text('OK, Got it!'),
  //             onPressed: () {
  //               Navigator.of(context).pop(true);
  //             },
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  void _initTabs() {
    if (tabs.isEmpty) {
      tabs.add(const Tab(text: 'iOS'));
      tabs.add(const Tab(text: 'Android'));
    }
  }

  // void _onSwitchToQrCode() {
  //   _pageController.animateToPage(0,
  //       duration: const Duration(milliseconds: 500), curve: Curves.decelerate);
  // }

  // void _onSwitchToQrScanner() {
  //   _pageController?.animateToPage(1,
  //       duration: const Duration(milliseconds: 500), curve: Curves.decelerate);
  // }
}

class IosDownloadTab extends StatefulWidget {
  const IosDownloadTab({Key key}) : super(key: key);

  @override
  _IosDownloadTabState createState() => _IosDownloadTabState();
}

class _IosDownloadTabState extends State<IosDownloadTab> with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  Future<bool> _displayInstructions(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('App QR Codes'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Text(
                  'Get your friends to download Harrier Central!\r\n\r\nIt'
                  's easy. They can either scan these QR codes or use the link to access the app download pages.',
                  textAlign: TextAlign.justify,
                  style: TextStyle(fontFamily: 'AvenirNextRegular', fontStyle: FontStyle.normal, fontSize: 16.0, height: 1.0),
                )
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK, Got it!'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  Key tabKey;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
      //print('Height = ${constraints.maxHeight}');
      //print('Width = ${constraints.maxWidth}');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(
              width: 10,
              height: (G0<DeviceInfo>().deviceWidthScaleFactor - 1) * 90,
            ),
            Container(
              padding: const EdgeInsets.only(top: 10, bottom: 20, right: 25, left: 25),
              child: Text(
                'Have friends scan this QR code or use the link below to download Harrier Central for iOS.',
                textAlign: TextAlign.justify,
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'AvenirNextDemiBold',
                  fontStyle: FontStyle.normal,
                  fontSize: 16.0 * G0<DeviceInfo>().deviceWidthScaleFactor,
                  height: 1.2,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 0, bottom: 10, left: 30, right: 30),
                child: Stack(alignment: AlignmentDirectional.center,
                    //height: math.min(constraints.maxHeight, constraints.maxWidth) * 0.65,
                    children: <Widget>[
                      QrImage(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.all(10.0),
                          data: getStringPref(StringPrefsEnum.iosDownloadLink),
                          //data: 'testing abc',
                          version: 3,
                          errorCorrectionLevel: 3),
                    ]),
              ),
            ),
            Container(
              padding: const EdgeInsets.only(top: 10, bottom: 0, right: 25, left: 25),
              child: Text(
                getStringPref(StringPrefsEnum.iosDownloadLink),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'AvenirNextDemiBold',
                  fontStyle: FontStyle.normal,
                  fontSize: 16.0 * G0<DeviceInfo>().deviceWidthScaleFactor,
                  height: 1.2,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 0.0, right: 0.0),
              child: TextButton(
                child: const Text('Learn more about this feature'),
                onPressed: () {
                  _displayInstructions(context);
                },
              ),
            ),
          ],
        ),
      );
    });
  }
}

class AndroidDownloadTab extends StatefulWidget {
  const AndroidDownloadTab({Key key}) : super(key: key);

  @override
  _AndroidDownloadTabState createState() => _AndroidDownloadTabState();
}

class _AndroidDownloadTabState extends State<AndroidDownloadTab> with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  Future<bool> _displayInstructions(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('App QR Codes'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Text(
                  'Get your friends to download Harrier Central!\r\n\r\nIt'
                  's easy. They can either scan these QR codes or use the link to access the app download pages.',
                  textAlign: TextAlign.justify,
                  style: TextStyle(fontFamily: 'AvenirNextRegular', fontStyle: FontStyle.normal, fontSize: 16.0, height: 1.0),
                )
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK, Got it!'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  Key tabKey;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
      //print('Height = ${constraints.maxHeight}');
      //print('Width = ${constraints.maxWidth}');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(
              width: 10,
              height: (G0<DeviceInfo>().deviceWidthScaleFactor - 1) * 90,
            ),
            Container(
              padding: const EdgeInsets.only(top: 10, bottom: 20, right: 25, left: 25),
              child: Text(
                'Have friends scan this QR code or use the link below to download Harrier Central for Android.',
                textAlign: TextAlign.justify,
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'AvenirNextDemiBold',
                  fontStyle: FontStyle.normal,
                  fontSize: 16.0 * G0<DeviceInfo>().deviceWidthScaleFactor,
                  height: 1.2,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 0, bottom: 10, left: 30, right: 30),
                child: Stack(alignment: AlignmentDirectional.center,
                    //height: math.min(constraints.maxHeight, constraints.maxWidth) * 0.65,
                    children: <Widget>[
                      QrImage(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.all(10.0),
                          data: getStringPref(StringPrefsEnum.androidDownloadLink),
                          //data: 'testing 123',
                          version: 3,
                          errorCorrectionLevel: 3),
                    ]),
              ),
            ),
            Container(
              padding: const EdgeInsets.only(top: 10, bottom: 0, right: 25, left: 25),
              child: Text(
                getStringPref(StringPrefsEnum.androidDownloadLink),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'AvenirNextDemiBold',
                  fontStyle: FontStyle.normal,
                  fontSize: 16.0 * G0<DeviceInfo>().deviceWidthScaleFactor,
                  height: 1.2,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 0.0, right: 0.0),
              child: TextButton(
                child: const Text('Learn more about this feature'),
                onPressed: () {
                  _displayInstructions(context);
                },
              ),
            ),
          ],
        ),
      );
    });
  }
}
