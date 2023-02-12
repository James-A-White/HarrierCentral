// @dart=2.11
import 'package:harrier_central/imports.dart';
//import 'package:geolocator/geolocator.dart';

class RunAdminAggregate {
  RunAdminAggregate({
    this.event,
    this.extensions,
    this.kennel,
  });

  final RunDetailQueryExtensions extensions;
  EventModel event;
  final KennelsModel kennel;
}

class RunDetailQueryExtensions {
  RunDetailQueryExtensions({
    this.appAccessFlags,
    this.mismanagementRoles,
    this.digAfterDec,
    this.curSym,
    this.curCode,
    this.memberPrice,
    this.nonMemberPrice,
    this.latitude,
    this.longitude,
    this.isMapAndDistanceValid,
    this.paymentAmountStr,
  });

  final int appAccessFlags;
  final int mismanagementRoles;
  final int digAfterDec;
  final String curSym;
  final String curCode;
  final num memberPrice;
  final num nonMemberPrice;
  String paymentUrl;
  num distToEvent;
  int distancePreference;
  num latitude;
  num longitude;
  bool isMapAndDistanceValid;
  String paymentAmountStr;

  bool isLoading = false;

  static RunDetailQueryExtensions fromMap(Map<String, dynamic> map) {
    final RunDetailQueryExtensions item = RunDetailQueryExtensions(
      appAccessFlags: map['appAccessFlags'],
      mismanagementRoles: map['mismanagementRoles'],
      digAfterDec: map['digAfterDec'],
      curSym: map['curSym'],
      curCode: map['curCode'],
      memberPrice: map['memberPrice'],
      nonMemberPrice: map['nonMemberPrice'],
      latitude: map['latitude'] == null ? null : map['latitude'] + 0.0,
      longitude: map['longitude'] == null ? null : map['longitude'] + 0.0,
      isMapAndDistanceValid: map['isMapAndDistanceValid'] == 1,
      paymentAmountStr: '',
    );
    return item;
  }

  Mismanagement get mismanagement {
    return Mismanagement(mismanagementRoles);
  }

  AppAccess get appAccess {
    return AppAccess(appAccessFlags);
  }
}

class RunAdminPage extends StatefulWidget {
  const RunAdminPage({Key key, this.eventId}) : super(key: key);

  final String eventId;

  @override
  RunAdminPageState createState() => RunAdminPageState();
}

class RunAdminPageState extends State<RunAdminPage> {
  bool _isLoading = true;
  int _isBetaTester = 0;

  RunAdminAggregate _eventAggregate;

  @override
  void initState() {
    _getRunDetails(widget.eventId);

    _isBetaTester = getIntPref(IntPrefsEnum.isBetaTester);

    super.initState();
  }

  void _getRunDetails(String eventId) {
    G0<TableModel>().syncEventAdminService.updateFromBackend(SyncEventAdminService.flagsAllData, false, eventId).then((bool result) {
      CommonQueries.getEventAdminInfoFromLocalCache(widget.eventId, _userId).then((RunAdminAggregate rd) {
        _eventAggregate = rd;
        setState(() {
          _isLoading = false;
          //final String resultStr = result ? 'successfully' : 'unsuccessfully';
          //print('Event admin data synchronized $resultStr');
        });
      });
    });
  }

  final String _userId = getStringPref(StringPrefsEnum.userId);

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: themeAppBarBackground,
        title: const Text(
          'Run Admin',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: Container(
        decoration: Backgrounds.defaultHcBackground(),
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.only(left: 20, right: 20),
        child: _isLoading
            ? const HcCircularProgressIndicator(key: Key('16093026'))
            : SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(top: 20, bottom: 20),
                      child: AutoSizeText(_eventAggregate.event.eventName, style: titleStyle, textAlign: TextAlign.center, maxLines: 2),
                    ),
                    const FancyDivider(
                      key: Key('66103920'),
                      innerColor: Colors.white,
                      topMargin: 20.0,
                      bottomMargin: 5.0,
                    ),
                    Column(mainAxisAlignment: MainAxisAlignment.start, mainAxisSize: MainAxisSize.max, children: _kiddies()),
                    const FancyDivider(
                      key: Key('669190022'),
                      innerColor: Colors.white,
                      topMargin: 35.0,
                      bottomMargin: 5.0,
                    ),
                    RunDetails(
                      _eventAggregate.event,
                      _eventAggregate.kennel,
                      _eventAggregate.extensions.digAfterDec,
                      _eventAggregate.extensions.curSym,
                      _eventAggregate.extensions.distancePreference,
                      _eventAggregate.extensions.distToEvent,
                      _eventAggregate.extensions.paymentUrl,
                      false,
                      _eventAggregate.extensions.isMapAndDistanceValid,
                      eventUrlWithKennelBackup: _eventAggregate.event.eventUrl ?? _eventAggregate.kennel.kennelEventsUrl,
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  final num buttonWidth = 315.0;

  List<Widget> _kiddies() {
    final List<Widget> kiddies = <Widget>[];

    kiddies.add(
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 15, bottom: 15),
            child: SizedBox(
              width: 110,
              height: 110,
              child: ElevatedButton(
                // shape: RoundedRectangleBorder(
                //     borderRadius: BorderRadius.circular(10.0)),
                // padding:
                //     const EdgeInsets.only(top: 2.0, left: 0.0, bottom: 0.0),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.only(top: 2.0, left: 0.0, bottom: 0.0),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(left: 3, top: 5),
                    child: Image.asset('images/icons/check_in_pack_icon.png', height: 55.0, width: 55.0),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8, right: 10, top: 10),
                    child: Text(
                      'Manual check in',
                      style: buttonLabelStyleSmallCompressedLines,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ]),

                onPressed: () {
                  Navigator.push<dynamic>(
                    context,
                    MaterialPageRoute<dynamic>(
                      builder: (BuildContext context) => CheckInPackPage(eventAggregate: _eventAggregate),
                    ),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 15, bottom: 15),
            child: SizedBox(
              width: 110,
              height: 110,
              child: ElevatedButton(
                // shape: RoundedRectangleBorder(
                //     borderRadius: BorderRadius.circular(10.0)),
                // padding:
                //     const EdgeInsets.only(top: 2.0, left: 0.0, bottom: 0.0),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.only(top: 2.0, left: 0.0, bottom: 0.0),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(left: 0, top: 5),
                    child: Image.asset('images/icons/qr_scanner_phone_icon.png', height: 55.0, width: 55.0),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8, right: 10, top: 10),
                    child: Text(
                      'Scan to check in',
                      style: buttonLabelStyleSmallCompressedLines,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ]),
                onPressed: () {
                  Navigator.push<dynamic>(
                    context,
                    MaterialPageRoute<dynamic>(
                      builder: (BuildContext context) => CheckInScannerPage(eventAggregate: _eventAggregate),
                    ),
                  );
                },
              ),
            ),
          )
        ],
      ),
    );

    if (_eventAggregate.extensions.appAccess.canManageHashCash) {
      kiddies.add(Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 15, bottom: 15),
            child: Container(
              width: 110,
              height: 110,
              foregroundDecoration: _isBetaTester == 1
                  ? null
                  : BoxDecoration(
                      color: Colors.grey.shade100,
                      backgroundBlendMode: BlendMode.saturation,
                    ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.only(top: 2.0, left: 0.0, bottom: 0.0),
                  backgroundColor: _isBetaTester == 1 ? null : Colors.grey,
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(left: 3, top: 5),
                    child: Image.asset('images/icons/hash_cash_icon.png', height: 55.0, width: 55.0),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 10, right: 10, top: 10),
                    child: Text(
                      'Hash\r\ncash',
                      style: buttonLabelStyleSmallCompressedLines,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ]),
                onPressed: () {
                  if (_isBetaTester == 1) {
                    Navigator.push<dynamic>(
                      context,
                      MaterialPageRoute<dynamic>(
                        builder: (BuildContext context) => PaymentReportPage(
                          eventAggregate: _eventAggregate,
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 15, bottom: 15),
            child: Container(
              width: 110,
              height: 110,
              foregroundDecoration: _isBetaTester == 1
                  ? null
                  : const BoxDecoration(
                      color: Colors.grey,
                      backgroundBlendMode: BlendMode.saturation,
                    ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.only(top: 2.0, left: 0.0, bottom: 0.0),
                  backgroundColor: _isBetaTester == 1 ? null : Colors.grey,
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(left: 0, top: 5),
                    child: Image.asset('images/icons/receipt_icon.png', height: 55.0, width: 55.0),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 10, right: 10, top: 10),
                    child: Text(
                      'Manage receipts',
                      style: buttonLabelStyleSmallCompressedLines,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ]),
                onPressed: () {
                  if (_isBetaTester == 1) {
                    Navigator.push<dynamic>(
                      context,
                      MaterialPageRoute<dynamic>(
                        builder: (BuildContext context) => ReceiptsList(
                          eventAggregate: _eventAggregate,
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ));
    }

    if (_eventAggregate.extensions.appAccess.canManageRuns) {
      kiddies.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 15, bottom: 15),
              child: SizedBox(
                width: 110,
                height: 110,
                // foregroundDecoration: BoxDecoration(
                //   color: Colors.grey,
                //   backgroundBlendMode: BlendMode.saturation,
                // ),
                child: ElevatedButton(
                  // shape: RoundedRectangleBorder(
                  //     borderRadius: BorderRadius.circular(10.0)),
                  // padding: const EdgeInsets.only(top: 2.0, left: 0.0, bottom: 0.0),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.only(top: 2.0, left: 0.0, bottom: 0.0),
                    //primary: Colors.grey,
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(left: 3, top: 5),
                      child: Image.asset('images/icons/print_qr_icon.png', height: 55.0, width: 55.0),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 10, right: 10, top: 10),
                      child: Text(
                        'Print QR codes',
                        style: buttonLabelStyleSmallCompressedLines,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ]),
                  onPressed: () {
                    Navigator.push<dynamic>(
                        context,
                        MaterialPageRoute<dynamic>(
                            builder: (BuildContext context) => EventQrCodePage(
                                kennelShortName: _eventAggregate.kennel.kennelShortName,
                                qrContent: _eventAggregate.event.publicEventId,
                                title: _eventAggregate.event.eventName,
                                runStartPrefix: QR_PREFIX_SPECIFIC_RUN_START,
                                runEndPrefix: QR_PREFIX_SPECIFIC_RUN_END,
                                runLink: QR_PREFIX_HASHRUNS_DOT_ORG_RUN_LINK,
                                showRunLink: true,
                                eventStartDatetime: _eventAggregate.event.eventStartDatetime)));
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 15, bottom: 15),
              child: SizedBox(
                width: 110,
                height: 110,
                child: ElevatedButton(
                  // shape: RoundedRectangleBorder(
                  //     borderRadius: BorderRadius.circular(10.0)),
                  // padding: const EdgeInsets.only(top: 2.0, left: 0.0, bottom: 0.0),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.only(top: 2.0, left: 0.0, bottom: 0.0),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(left: 3, top: 5),
                      child: Image.asset('images/icons/email_icon.png', height: 55.0, width: 55.0),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 10, right: 10, top: 10),
                      child: Text(
                        'Email Run Details',
                        style: buttonLabelStyleSmallCompressedLines,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ]),
                  onPressed: () {
                    Navigator.push<dynamic>(
                      context,
                      MaterialPageRoute<dynamic>(
                        builder: (BuildContext context) => EmailEditorPage(
                          eventId: widget.eventId,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      );

      kiddies.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 15, bottom: 15),
              child: SizedBox(
                width: 110,
                height: 110,
                // foregroundDecoration: BoxDecoration(
                //   color: Colors.grey,
                //   backgroundBlendMode: BlendMode.saturation,
                // ),
                child: ElevatedButton(
                  // shape: RoundedRectangleBorder(
                  //     borderRadius: BorderRadius.circular(10.0)),
                  // padding: const EdgeInsets.only(top: 2.0, left: 0.0, bottom: 0.0),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.only(top: 2.0, left: 0.0, bottom: 0.0),
                    //primary: Colors.grey,
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(left: 3, top: 5),
                      child: Image.asset('images/icons/edit_run_icon.png', height: 55.0, width: 55.0),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 10, right: 10, top: 10),
                      child: Text(
                        'Edit run details',
                        style: buttonLabelStyleSmallCompressedLines,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ]),
                  onPressed: () async {
                    await Navigator.push<dynamic>(
                        context,
                        MaterialPageRoute<dynamic>(
                            builder: (BuildContext context) => EditRunDetailsPage(false, _eventAggregate, (String eventId) async {
                                  _eventAggregate = await CommonQueries.getEventAdminInfoFromLocalCache(eventId, _userId);
                                  _isLoading = false;
                                  return _eventAggregate;
                                })));
                    _getRunDetails(widget.eventId);
                  },
                ),
              ),
            ),
            if (_eventAggregate.extensions.appAccess.canManageAwards)
              Container(
                margin: const EdgeInsets.only(top: 20, bottom: 15),
                width: 110,
                height: 110,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 0.0),
                  ),
                  child: Column(children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(left: 3, top: 1),
                      child: Image.asset('images/icons/run_awards.png', height: 55.0, width: 55.0),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 10, right: 10, top: 8),
                      child: Text(
                        'Award\r\nlist',
                        textAlign: TextAlign.center,
                        style: buttonLabelStyleSmall,
                      ),
                    ),
                  ]),
                  onPressed: () {
                    Navigator.push<dynamic>(
                      context,
                      MaterialPageRoute<dynamic>(builder: (BuildContext context) => DrinksList(eventAggregate: _eventAggregate)),
                    );
                  },
                ),
              ),
          ],
        ),
      );
    }

    return kiddies;
  }
}
