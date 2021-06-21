import 'package:harrier_central/imports.dart';

//import 'dart:math' as math;

class EventQrCodePage extends StatefulWidget {
  const EventQrCodePage(
      {Key key,
      @required this.kennelShortName,
      @required this.qrContent,
      @required this.title,
      @required this.runStartPrefix,
      @required this.runEndPrefix,
      this.eventStartDatetime})
      : super(key: key);

  final String kennelShortName;
  final String qrContent;
  final String title;
  final String runStartPrefix;
  final String runEndPrefix;
  final DateTime eventStartDatetime;

  @override
  _EventQrCodePageState createState() => _EventQrCodePageState();
}

class _EventQrCodePageState extends State<EventQrCodePage> with SingleTickerProviderStateMixin {
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
          'QRs for start & end of Hash',
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
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelPadding: const EdgeInsets.only(top: 5, left: 20, right: 20),
                    indicator: BubbleTabIndicator(
                      indicatorHeight: 35.0,
                      indicatorColor: Theme.of(context).buttonColor,
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
                child: Container(
                  key: tabKey,
                  width: MediaQuery.of(context).size.width,
                  child: TabBarView(
                    controller: _tabController,
                    children: <Widget>[
                      QrTab(
                        isRunStart: true,
                        qrPrefix: widget.runStartPrefix,
                        qrContent: widget.qrContent,
                        title: widget.title,
                        eventStartDatetime: widget.eventStartDatetime,
                      ),
                      QrTab(
                        isRunStart: false,
                        qrPrefix: widget.runEndPrefix,
                        qrContent: widget.qrContent,
                        title: widget.title,
                        eventStartDatetime: widget.eventStartDatetime,
                      )
                    ],
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
  //                 'You can print out these codes and place them somewhere convenient for Hashers to scan at the beginning and end of the runs. This is especially good for large Hash groups.',
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
      tabs.add(const Tab(text: 'Run Start'));
      tabs.add(const Tab(text: 'Run End'));
    }
  }
}

class TabIndicationPainter extends CustomPainter {
  TabIndicationPainter({this.context, this.dxTarget = 125.0, this.dxEntry = 25.0, this.radius = 21.0, this.dy = 25.0, this.pageController}) : super(repaint: pageController) {
    painter = Paint()
      ..color = Theme.of(context).accentColor
      ..style = PaintingStyle.fill;
  }

  Paint painter;
  final num dxTarget;
  final num dxEntry;
  final num radius;
  final num dy;
  BuildContext context;

  final PageController pageController;

  @override
  void paint(Canvas canvas, Size size) {
    final ScrollPosition pos = pageController.position;
    final num fullExtent = pos.maxScrollExtent - pos.minScrollExtent + pos.viewportDimension;

    final num pageOffset = pos.extentBefore / fullExtent;

    final bool left2right = dxEntry < dxTarget;
    final Offset entry = Offset(left2right ? dxEntry : dxTarget, dy);
    final Offset target = Offset(left2right ? dxTarget : dxEntry, dy);

    final Path path = Path();
    path.addArc(Rect.fromCircle(center: entry, radius: radius), 0.5 * pi, 1 * pi);
    path.addRect(Rect.fromLTRB(entry.dx, dy - radius, target.dx, dy + radius));
    path.addArc(Rect.fromCircle(center: target, radius: radius), 1.5 * pi, 1 * pi);

    canvas.translate(size.width * pageOffset, 0.0);
    canvas.drawShadow(path, const Color(0xFFfbab66), 3.0, true);
    canvas.drawPath(path, painter);
  }

  @override
  bool shouldRepaint(TabIndicationPainter oldDelegate) => true;
}

class QrTab extends StatefulWidget {
  const QrTab({Key key, @required this.isRunStart, @required this.qrContent, @required this.title, @required this.qrPrefix, this.eventStartDatetime}) : super(key: key);

  final bool isRunStart;
  final String qrPrefix;
  final String qrContent;
  final String title;
  final DateTime eventStartDatetime;

  @override
  _QrTabState createState() => _QrTabState();
}

class _QrTabState extends State<QrTab> with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  Future<bool> _displayInstructions(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Your QR Code'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Text(
                  'This QR code allows other Hashers to quickly scan you using their Harrier Central apps.\r\n\r\nAny Hasher can scan this code to easily add you as their friend.\r\n\r\nHares and mis-management can use this code to scan you in at the beginning and end of runs in order to keep your run counts accurate and ensure that no one is left behind on trail at the end of a run.',
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

  num spacer = 12.0 + (G0<DeviceInfo>().deviceMaxScaleFactor * 30);

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20),
      child: Column(
        //alignment: AlignmentDirectional.center,
        children: <Widget>[
          SizedBox(
            width: spacer / 3,
            height: spacer / 3,
          ),
          Text(
            'Print this code and make it available for Hashers to scan at the beginning and end of runs',
            textAlign: TextAlign.justify,
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'AvenirNextDemiBold',
              fontStyle: FontStyle.normal,
              fontSize: 14.0 * G0<DeviceInfo>().deviceWidthScaleFactor,
              height: 1.0,
            ),
          ),
          SizedBox(
            width: spacer,
            height: spacer,
          ),
          AutoSizeText(
            //widget.eventName,
            widget.isRunStart ? 'QR code for run start at:' : 'QR code for run end at:',
            maxLines: 1,
            minFontSize: 22.0,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontFamily: 'AvenirNextDemiBold', fontStyle: FontStyle.normal, fontSize: 24.0, height: 0.8),
          ),
          SizedBox(
            width: spacer / 3,
            height: spacer / 3,
          ),
          AutoSizeText(
            widget.title,
            // 'This is a fake hash run name that needs to be very long so we can see how it fits on the page when it overflows three lines',
            maxLines: 3,
            minFontSize: 22.0,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontFamily: 'AvenirNextMedium', fontStyle: FontStyle.normal, fontSize: 24.0, height: 1.0),
          ),

          //               Text(
//                 eventName,
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(
//                   color: Colors.white,
//                     fontFamily: 'AvenirNextRegular',
//                     fontStyle: FontStyle.normal,
//                     fontSize: 28.0,
//                     height: 1.0),
//               ),
//               Text(
//                 DateFormat('E, MMM d \'at\' h:mm a').format(eventStartDatetime),
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(
//                   color: Colors.white,
//                     fontFamily: 'AvenirNextRegular',
//                     fontStyle: FontStyle.normal,
//                     fontSize: 20.0,
//                     height: 1.0),
//               ),
          // Positioned(
          //   top: 127,

          //   child: Container(
          //                       color: Colors.white,
          //     height: MediaQuery.of(context).size.width * 0.8,
          //     width: MediaQuery.of(context).size.width * 0.8,
          //   ),
          // ),
          SizedBox(
            width: spacer / 3,
            height: spacer / 3,
          ),
          Expanded(
            child: Stack(
              children: <Widget>[
                QrImage(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.all(15.0),
                    data: widget.qrPrefix + widget.qrContent.toUpperCase(),
                    // data: (widget.isRunStart ? 'EVTSTART:' : 'EVTEND:') + widget.qrContent.toUpperCase(),
                    //data: 'testing123',
                    version: 4,
                    //size: 200.0,
                    errorCorrectionLevel: 3),
              ],
            ),
          ),
          SizedBox(
            width: spacer / 3,
            height: spacer / 3,
          ),
          TextButton(
            child: const Text('Learn more about this feature'),
            onPressed: () {
              _displayInstructions(context);
            },
          ),
        ],
      ),
    );
  }
}
