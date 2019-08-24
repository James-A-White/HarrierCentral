import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:sqflite/sqflite.dart';

import 'package:harrier_central/database/database.dart';
import 'package:harrier_central/pages/run_admin/event_qr_code_page.dart';
import 'package:harrier_central/pages/run_admin/check_in_scanner_page.dart';
import 'package:harrier_central/pages/run_admin/payment_report.dart';
import 'package:harrier_central/pages/run_admin/receipts_page.dart';
import 'package:harrier_central/data/hc3_services/sync_event_admin_service.dart';
import 'package:harrier_central/data/hc3_services/narrow_event_service.dart';
import 'package:harrier_central/data/hc3_services/hasher_kennel_map_service.dart';
import 'package:harrier_central/data/hc3_services/kennels_service.dart';
import 'package:harrier_central/data/hc3_services/countries_service.dart';
import 'package:harrier_central/pages/run_admin/check_in_pack_page.dart';
import 'package:harrier_central/util/styles.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/util/utilities.dart';
import 'package:harrier_central/widgets/circular_progress_indicator.dart';
import 'package:harrier_central/util/preferences.dart';

class RunAdminAggregate {
  RunAdminAggregate({
    this.event,
    this.extensions,
    this.kennel,
  });

  final RunAdminQueryExtensions extensions;
  final NarrowEventsModel event;
  final KennelsModel kennel;
}

class RunAdminQueryExtensions {
  RunAdminQueryExtensions({this.mismanagementRoleFlags, this.digAfterDec, this.curSym, this.curCode, this.memberPrice, this.nonMemberPrice});

  final int mismanagementRoleFlags;
  final int digAfterDec;
  final String curSym;
  final String curCode;
  final num memberPrice;
  final num nonMemberPrice;

  bool isLoading = false;

  static RunAdminQueryExtensions fromMap(Map<String, dynamic> map) {
    final RunAdminQueryExtensions item = RunAdminQueryExtensions(mismanagementRoleFlags: map['mismanagementRoleFlags'], digAfterDec: map['digAfterDec'], curSym: map['curSym'], curCode: map['curCode'], memberPrice: map['memberPrice'], nonMemberPrice: map['nonMemberPrice']);
    return item;
  }
}

class RunAdminMainPage extends StatefulWidget {
  //final FutureRunScopedModel futureRunsModel;

  const RunAdminMainPage({Key key, this.eventId}) : super(key: key);

  final String eventId;

  @override
  RunAdminMainPageState createState() => RunAdminMainPageState();
}

class RunAdminMainPageState extends State<RunAdminMainPage> {
  bool _isLoading = true;

  RunAdminAggregate eventAggregate;

  @override
  void initState() {
    DBProvider.db.database.then((Database db) async {
      final SyncEventAdminService cSrv = SyncEventAdminService();
      cSrv.updateFromBackend(db, SyncEventAdminService.flagsAllData, false, widget.eventId).then((bool result) {
        refreshFromTables();
        setState(() {
          final String resultStr = result ? 'successfully' : 'unsuccessfully';
          print('Event admin data synchronized $resultStr');
          _isLoading = false;
        });
      });
    });

    super.initState();
  }

  String userId = getStringPref(StringPrefsEnum.userId);

  void refreshFromTables() {
    DBProvider.db.database.then((Database db) {
      try {
        const String dollarSign = r'$^';

        final String sql = '''

          SELECT e.*,
          k.*,
          hkm.mismanagementRoleFlags,
          coalesce(k.${KennelsTableHelper.colCurrencyCode},c.${CountriesTableHelper.colCurrencyCode},"USD") as curCode,
          coalesce(k.digitsAfterDecimal,c.digitsAfterDecimal,2) as digAfterDec, 
          coalesce(k.currencySymbol,c.currencySymbol,"$dollarSign") as curSym,
          coalesce(e.eventPriceForMembers,k.defaultPriceForMembers,0) as memberPrice,
          coalesce(e.eventPriceForNonMembers,k.defaultPriceForNonMembers,0) as nonMemberPrice
          FROM ${NarrowEventsTableHelper.tableName} e
          INNER JOIN ${KennelsTableHelper.tableName} k on k.kennelId = e.kennelId
          LEFT OUTER JOIN ${CountriesTableHelper.tableName} c on c.countryId = k.countryId
          LEFT OUTER JOIN ${HasherKennelMapTableHelper.getTableName(HasherKennelMapTableType.user)} hkm on e.kennelId = hkm.kennelId
          WHERE e.eventId = "${widget.eventId}"
          AND hkm.userId = "$userId"
          
          ''';

        db.rawQuery(sql).then((List<Map<String, dynamic>> results) {
          setState(() {
            if (results.isNotEmpty) {
              final NarrowEventsModel eventItem = NarrowEventsTableHelper.fromMap(results[0]);
              final RunAdminQueryExtensions extensions = RunAdminQueryExtensions.fromMap(results[0]);
              final KennelsModel kennel = KennelsTableHelper.fromMap(results[0]);
              eventAggregate = RunAdminAggregate(event: eventItem, extensions: extensions, kennel: kennel);
            }
          });
        });
      } catch (e) {
        print(e);
      }
    });
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
          child: _isLoading ? const HcCircularProgressIndicator() : Column(mainAxisAlignment: MainAxisAlignment.start, mainAxisSize: MainAxisSize.max, children: <Widget>[]..addAll(kiddies()))),
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
              child: RaisedButton(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                padding: const EdgeInsets.only(top: 2.0, left: 0.0, bottom: 0.0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(left: 3, top: 5),
                    child: Image.asset('images/icons/check_in_pack_icon.png', height: 55.0, width: 55.0),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8, right: 10, top: 10),
                    child: Text(
                      'Manual check in',
                      style: buttonLabelStyleSmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ]),
                textColor: Colors.white,
                onPressed: () {
                  Navigator.push<dynamic>(
                    context,
                    MaterialPageRoute<dynamic>(
                      builder: (BuildContext context) => CheckInPackPage(eventAggregate: eventAggregate),
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
              child: RaisedButton(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                padding: const EdgeInsets.only(top: 2.0, left: 0.0, bottom: 0.0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(left: 0, top: 5),
                    child: Image.asset('images/icons/qr_scanner_phone_icon.png', height: 55.0, width: 55.0),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8, right: 10, top: 10),
                    child: Text(
                      'Scan to check in',
                      style: buttonLabelStyleSmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ]),
                textColor: Colors.white,
                onPressed: () {
                  Navigator.push<dynamic>(
                    context,
                    MaterialPageRoute<dynamic>(
                      builder: (BuildContext context) => CheckInScannerPage(eventAggregate: eventAggregate),
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
            child: RaisedButton(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
              padding: const EdgeInsets.only(top: 2.0, left: 0.0, bottom: 0.0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(left: 3, top: 5),
                  child: Image.asset('images/icons/hash_cash_icon.png', height: 55.0, width: 55.0),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 10, right: 10, top: 10),
                  child: Text(
                    'Hash\r\ncash',
                    style: buttonLabelStyleSmall,
                    textAlign: TextAlign.center,
                  ),
                ),
              ]),
              textColor: Colors.white,
              onPressed: () {
                Navigator.push<dynamic>(
                  context,
                  MaterialPageRoute<dynamic>(
                    builder: (BuildContext context) => PaymentReportPage(
                      eventAggregate: eventAggregate,
                    ),
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
            child: RaisedButton(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
              padding: const EdgeInsets.only(top: 2.0, left: 0.0, bottom: 0.0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(left: 0, top: 5),
                  child: Image.asset('images/icons/receipt_icon.png', height: 55.0, width: 55.0),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 10, right: 10, top: 10),
                  child: Text(
                    'Manage receipts',
                    style: buttonLabelStyleSmall,
                    textAlign: TextAlign.center,
                  ),
                ),
              ]),
              textColor: Colors.white,
              onPressed: () {
                Navigator.push<dynamic>(
                  context,
                  MaterialPageRoute<dynamic>(
                    builder: (BuildContext context) => ReceiptsList(
                      eventAggregate: eventAggregate,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    ));

    kiddies.add(Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 15, bottom: 15),
          child: Container(
            width: 110,
            height: 110,
            child: RaisedButton(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
              padding: const EdgeInsets.only(top: 2.0, left: 0.0, bottom: 0.0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(left: 3, top: 5),
                  child: Image.asset('images/icons/print_qr_icon.png', height: 55.0, width: 55.0),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 10, right: 10, top: 10),
                  child: Text(
                    'Print QR codes',
                    style: buttonLabelStyleSmall,
                    textAlign: TextAlign.center,
                  ),
                ),
              ]),
              textColor: Colors.white,
              onPressed: () {
                Navigator.push<dynamic>(
                    context,
                    MaterialPageRoute<dynamic>(
                        builder: (BuildContext context) => EventQrCodePage(
                            kennelShortName: eventAggregate.kennel.kennelShortName,
                            qrContent: eventAggregate.event.eventId,
                            title: eventAggregate.event.eventName,
                            runStartPrefix: QR_PREFIX_SPECIFIC_RUN_START,
                            runEndPrefix: QR_PREFIX_SPECIFIC_RUN_END,
                            eventStartDatetime: eventAggregate.event.eventStartDatetime)));
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 15, bottom: 15),
          child: Container(
            width: 110,
            height: 110,
            child: RaisedButton(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
              padding: const EdgeInsets.only(top: 2.0, left: 0.0, bottom: 0.0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(left: 3, top: 5),
                  child: Image.asset('images/icons/email_icon.png', height: 55.0, width: 55.0),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 10, right: 10, top: 10),
                  child: Text(
                    'Email Run Details',
                    style: buttonLabelStyleSmall,
                    textAlign: TextAlign.center,
                  ),
                ),
              ]),
              textColor: Colors.white,
              onPressed: () {
                Utilities.showAlert(context, 'Email run details', 'Would you like to e-mail the run details to hashers who have signed up for e-mail notifications?', 'OK', showCancelButton: true).then((bool result) {
                  if (result) {
                    NarrowEventsService.sendRunDetailsByEmail(eventId: widget.eventId).then((Map<String, String> result) {
                      _scaffoldKey.currentState?.hideCurrentSnackBar();
                      if (result['result'].toLowerCase().startsWith('success')) {
                        Utilities.showAlert(context, 'E-mails successfully sent', 'Emails have been successfully sent to ${result['emailCount']} hashers', 'OK');
                      } else {
                        Utilities.showAlert(context, 'Error sending emails', 'There was a problem sending run detail e-mails to hashers.\r\n\r\nPlease try again later or contact us at connect@harriercentral.com', 'OK');
                      }
                    });
                    Utilities.showInSnackBar(context, _scaffoldKey, 'Run detail emails being sent ..', durationInSeconds: 10);
                  }
                });
              },
            ),
          ),
        ),
      ],
    ));

    return kiddies;
  }
}
