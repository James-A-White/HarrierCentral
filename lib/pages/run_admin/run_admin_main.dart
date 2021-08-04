import 'package:harrier_central/imports.dart';
import 'package:geolocator/geolocator.dart';

class RunDetailAggregate {
  RunDetailAggregate({
    this.event,
    this.extensions,
    this.kennel,
  });

  final RunDetailQueryExtensions extensions;
  final EventModel event;
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

  bool isLoading = false;

  static RunDetailQueryExtensions fromMap(Map<String, dynamic> map) {
    final RunDetailQueryExtensions item = RunDetailQueryExtensions(
        appAccessFlags: map['appAccessFlags'],
        mismanagementRoles: map['mismanagementRoles'],
        digAfterDec: map['digAfterDec'],
        curSym: map['curSym'],
        curCode: map['curCode'],
        memberPrice: map['memberPrice'],
        nonMemberPrice: map['nonMemberPrice']);
    return item;
  }

  Mismanagement get mismanagement {
    return Mismanagement(mismanagementRoles);
  }

  AppAccess get appAccess {
    return AppAccess(appAccessFlags);
  }
}

class RunDetailPage extends StatefulWidget {
  //final FutureRunScopedModel futureRunsModel;

  const RunDetailPage({Key key, this.eventId}) : super(key: key);

  final String eventId;

  @override
  RunDetailPageState createState() => RunDetailPageState();
}

class RunDetailPageState extends State<RunDetailPage> {
  bool _isLoading = true;
  int _isBetaTester = 0;

  RunDetailAggregate _eventAggregate;

  @override
  void initState() {
    G0<TableModel>().syncEventAdminService.updateFromBackend(SyncEventAdminService.flagsAllData, false, widget.eventId).then((bool result) {
      refreshFromTables().then((void dummy) {
        setState(() {
          final String resultStr = result ? 'successfully' : 'unsuccessfully';
          print('Event admin data synchronized $resultStr');
        });
      });
    });

    _isBetaTester = getIntPref(IntPrefsEnum.isBetaTester);

    super.initState();
  }

  String userId = getStringPref(StringPrefsEnum.userId);

  Future<void> refreshFromTables() async {
    try {
      const String dollarSign = r'$^';

      final String sql = '''

          SELECT e.*,
          k.*,
          hkm.${G0<TableModel>().hasherKennelMapTableHelper.colAppAccessFlags},
          hkm.${G0<TableModel>().hasherKennelMapTableHelper.colMismanagementRoles},
          coalesce(k.${G0<TableModel>().kennelsTableHelper.colCurrencyCode},c.${G0<TableModel>().countriesTableHelper.colCurrencyCode},"USD") as curCode,
          coalesce(k.${G0<TableModel>().kennelsTableHelper.colDigitsAfterDecimal},c.${G0<TableModel>().countriesTableHelper.colDigitsAfterDecimal},2) as digAfterDec, 
          coalesce(k.${G0<TableModel>().kennelsTableHelper.colCurrencySymbol},c.${G0<TableModel>().countriesTableHelper.colCurrencySymbol},"$dollarSign") as curSym,
          coalesce(e.${G0<TableModel>().eventsTableHelper.colEventPriceForMembers},k.${G0<TableModel>().kennelsTableHelper.colDefaultPriceForMembers},0) as memberPrice,
          coalesce(e.${G0<TableModel>().eventsTableHelper.colEventPriceForNonMembers},k.${G0<TableModel>().kennelsTableHelper.colDefaultPriceForNonMembers},0) as nonMemberPrice
          FROM ${G0<TableModel>().eventsTableHelper.getTableName(AppDomainType.user)} e
          INNER JOIN ${G0<TableModel>().kennelsTableHelper.getTableName(AppDomainType.user)} k on k.kennelId = e.kennelId
          LEFT OUTER JOIN ${G0<TableModel>().countriesTableHelper.getTableName(AppDomainType.user)} c on c.countryId = k.countryId
          LEFT OUTER JOIN ${G0<TableModel>().hasherKennelMapTableHelper.getTableName(AppDomainType.user)} hkm on e.kennelId = hkm.kennelId,
          hashers h  
          WHERE e.eventId = "${widget.eventId}"
          AND hkm.userId = "$userId"
          AND h.hasherId = "$userId"
          
          ''';

      final List<Map<String, dynamic>> results = await G0<Database>().rawQuery(sql);

      final Geolocator locator = Geolocator();

      final num dist = await locator.distanceBetween(
        IveCoreUtilities.unInt(G0<DeviceInfo>().deviceLat),
        IveCoreUtilities.unInt(G0<DeviceInfo>().deviceLon),
        IveCoreUtilities.unInt(results[0]['narrowEventLatitude']),
        IveCoreUtilities.unInt(
          results[0]['narrowEventLongitude'],
        ),
      );

      if (results.isNotEmpty) {
        final EventModel eventItem = G0<TableModel>().eventsTableHelper.fromMap(results[0]);
        final RunDetailQueryExtensions extensions = RunDetailQueryExtensions.fromMap(results[0]);
        final KennelsModel kennel = G0<TableModel>().kennelsTableHelper.fromMap(results[0]);
        String paymentLinkUrl = '';

        if (((eventItem.eventPaymentUrl ?? '') != '') && ((eventItem.eventPaymentUrlExpires == null) || (eventItem.eventPaymentUrlExpires.isAfter(DateTime.now())))) {
          paymentLinkUrl = eventItem.eventPaymentUrl;
        } else if (((kennel.kennelPaymentUrl ?? '') != '') && ((kennel.kennelPaymentUrlExpires == null) || (kennel.kennelPaymentUrlExpires.isAfter(DateTime.now())))) {
          paymentLinkUrl = kennel.kennelPaymentUrl;
        }

        extensions.paymentUrl = paymentLinkUrl;
        extensions.distToEvent = dist;
        //extensions.distancePreference = results[0]['distancePreference'];

        _eventAggregate = RunDetailAggregate(event: eventItem, extensions: extensions, kennel: kennel);
      }
      _isLoading = false;
    } catch (e) {
      print(e);
    }
  }

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
            ? HcCircularProgressIndicator(key: UniqueKey())
            : SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(top: 20, bottom: 20),
                      child: AutoSizeText(_eventAggregate.event.eventName, style: titleStyle, textAlign: TextAlign.center, maxLines: 2),
                    ),
                    FancyDivider(
                      key: UniqueKey(),
                      innerColor: Colors.white,
                      topMargin: 20.0,
                      bottomMargin: 5.0,
                    ),
                    Column(mainAxisAlignment: MainAxisAlignment.start, mainAxisSize: MainAxisSize.max, children: <Widget>[]..addAll(kiddies())),
                    FancyDivider(
                      key: UniqueKey(),
                      innerColor: Colors.white,
                      topMargin: 35.0,
                      bottomMargin: 5.0,
                    ),
                    RunDetails(_eventAggregate.event, _eventAggregate.kennel, _eventAggregate.extensions.digAfterDec, _eventAggregate.extensions.curSym,
                        _eventAggregate.extensions.distancePreference, _eventAggregate.extensions.distToEvent, _eventAggregate.extensions.paymentUrl, false),
                  ],
                ),
              ),
      ),
    );
  }

  final num buttonWidth = 315.0;

  List<Widget> kiddies() {
    final List<Widget> kiddies = <Widget>[];

    kiddies.add(
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 15, bottom: 15),
            child: Container(
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
            child: Container(
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
                primary: _isBetaTester == 1 ? null : Colors.grey,
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
                primary: _isBetaTester == 1 ? null : Colors.grey,
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

    kiddies.add(
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 15, bottom: 15),
            child: Container(
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
                              qrContent: _eventAggregate.event.eventId,
                              title: _eventAggregate.event.eventName,
                              runStartPrefix: QR_PREFIX_SPECIFIC_RUN_START,
                              runEndPrefix: QR_PREFIX_SPECIFIC_RUN_END,
                              eventStartDatetime: _eventAggregate.event.eventStartDatetime)));
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 15, bottom: 15),
            child: Container(
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
            child: Container(
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
                onPressed: () {
                  Navigator.push<dynamic>(
                      context,
                      MaterialPageRoute<dynamic>(
                          builder: (BuildContext context) => EditRunDetailsPage(_eventAggregate, () async {
                                await refreshFromTables();
                                return _eventAggregate;
                              })));
                },
              ),
            ),
          ),
        ],
      ),
    );

    return kiddies;
  }
}
