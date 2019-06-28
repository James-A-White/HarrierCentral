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
import 'package:harrier_central/widgets/circular_progress_indicator.dart';
import 'package:harrier_central/util/preferences.dart';

class RunAdminMainPage extends StatefulWidget {
  //final FutureRunScopedModel futureRunsModel;

  const RunAdminMainPage({Key key, this.eventId}) : super(key: key);

  final String eventId;

  @override
  RunAdminMainPageState createState() => RunAdminMainPageState();
}

class RunAdminMainPageState extends State<RunAdminMainPage> {
  bool _isLoading = true;

  Map<String, dynamic> event;

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
          hkm.mismanagementRoleFlags,
          k.kennelShortName,
          coalesce(c.digitsAfterDecimal,2) as digitsAfterDecimal, 
          coalesce(c.currencySymbol,"$dollarSign") as currencySymbol,
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
              event = results[0];
            }
          });
        });
      } catch (e) {
        print(e);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                      builder: (BuildContext context) => CheckInPackPage(eventId: widget.eventId, kennelId: event['kennelId']),
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
                      builder: (BuildContext context) => CheckInScannerPage(
                            kennelShortName: event['kennelShortName'],
                            eventId: event['eventId'],
                            eventName: event['eventName'],
                            eventNumber: event['eventNumber'],
                            currencySymbol: event['currencySymbol'],
                            digitsAfterDecimal: event['digitsAfterDecimal'],
                            memberPrice: event['memberPrice'],
                            nonMemberPrice: event['nonMemberPrice'],
                          ),
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
                          event: event,
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
                          eventName: event['eventName'],
                          eventId: event['eventId'],
                          digitsAfterDecimal: event['digitsAfterDecimal'],
                          currencySymbol: event['currencySymbol'],
                        ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    ));


    kiddies.add(Padding(
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
              padding: const EdgeInsets.only(left: 10, right: 10,top:10),
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
                    builder: (BuildContext context) =>
                        EventQrCodePage(kennelShortName: event['kennelShortName'], qrContent: event['eventId'], title: event['eventName'], runStartPrefix: QR_PREFIX_SPECIFIC_RUN_START, runEndPrefix: QR_PREFIX_SPECIFIC_RUN_END, eventStartDatetime: DateTime.parse(event['eventStartDatetime']))));
          },
        ),
      ),
    ));

    return kiddies;
  }
}
