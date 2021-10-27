// @dart=2.11
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
  //                 'You can //print out these codes and place them somewhere convenient for Hashers to scan at the beginning and end of the runs. This is especially good for large Hash groups.',
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
          title: widget.isRunStart ? const Text('Run Start QR Code') : const Text('Run End QR Code'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  widget.isRunStart
                      ? 'This QR code can be scanned by Hashers to check in when they arrive at the start of a run.\r\n\r\nThis will automatically mark them as at the run, but will not mark them as paid. This is especially useful for Hashes with large packs.'
                      : 'This QR code can be scanned by Hashers to check in when they finish running the Hash trail.\r\n\r\nThis will automatically mark them as having finished the run.\r\n\r\nThis is especially useful for Hashes where it is important to account that everyone has arrived safely at the end of the run and ensure no one remains on trail.',
                  textAlign: TextAlign.justify,
                  style: const TextStyle(fontFamily: 'AvenirNextRegular', fontStyle: FontStyle.normal, fontSize: 16.0, height: 1.0),
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
                    data: BASE_HCWEB_MOBILE_URL + widget.qrPrefix + widget.qrContent.toUpperCase(),
                    // data: (widget.isRunStart ? 'EVTSTART:' : 'EVTEND:') + widget.qrContent.toUpperCase(),
                    //data: 'testing123',
                    version: 6,
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
