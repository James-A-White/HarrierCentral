import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:sqflite/sqflite.dart';

import 'package:harrier_central/pages/run_admin/run_start_end_qr_codes_page.dart';
import 'package:harrier_central/pages/run_admin/check_in_scanner_page.dart';
import 'package:harrier_central/pages/run_admin/payment_report.dart';
import 'package:harrier_central/pages/run_admin/receipts_page.dart';
import 'package:harrier_central/database/database.dart';
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

          SELECT e.*,hkm.mismanagementRoleFlags,k.kennelShortName,coalesce(c.digitsAfterDecimal,2) as digitsAfterDecimal, coalesce(c.currencySymbol,"$dollarSign") as currencySymbol from ${NarrowEventsTableHelper.tableName} e
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
      body: Container(decoration: Backgrounds.defaultHcBackground(), height: MediaQuery.of(context).size.height, child: _isLoading ? const HcCircularProgressIndicator() : Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: kiddies())),
    );
  }

  List<Widget> kiddies() {
    final List<Widget> kiddies = <Widget>[];

    if (event != null) {
      if ((((event['mismanagementRoleFlags'] ?? 0) & mmAuthAllowCheckInAndOutFlag) != 0) || (((event['mismanagementRoleFlags'] ?? 0) & mmAuthAllowHashCashFlag) != 0)) {
        kiddies.add(rsvpRow());
      }

      if (((event['mismanagementRoleFlags'] ?? 0) & mmAuthAllowCheckInAndOutFlag) != 0) {
        kiddies.add(startAndEndScannerRow());
      }

      kiddies.add(startAndEndQrRow());

      kiddies.add(receiptsRow());
    }

    return kiddies;
  }

  Row rsvpRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        !(((event['mismanagementRoleFlags'] ?? 0) & mmAuthAllowEditRsvpFlag) != 0)
            ? Container()
            : Container(
                margin: const EdgeInsets.only(left: 10, right: 10),
                width: 150.0,
                height: 100.0,
                child: RaisedButton(
                  child: const Text(
                    'Check in Pack',
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () {
                    Navigator.push<dynamic>(
                      context,
                      MaterialPageRoute<dynamic>(
                        builder: (BuildContext context) => CheckInPackPage(eventId: event['eventId']),
                      ),
                    );
                  },
                ),
              ),
        !(((event['mismanagementRoleFlags'] ?? 0) & mmAuthAllowHashCashFlag) != 0)
            ? Container()
            : Container(
                margin: const EdgeInsets.only(left: 10, right: 10),
                width: 150.0,
                height: 100.0,
                child: RaisedButton(
                  child: const Text(
                    'Hash Cash',
                    style: TextStyle(color: Colors.white),
                  ),
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
      ],
    );
  }

  Row startAndEndScannerRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
          margin: const EdgeInsets.only(left: 10, right: 10),
          width: 150.0,
          height: 100.0,
          child: RaisedButton(
            child: const Text(
              'Scan at Run Start',
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () {
              Navigator.push<dynamic>(
                context,
                MaterialPageRoute<dynamic>(
                  builder: (BuildContext context) => CheckInScannerPage(
                        kennelShortName: event['kennelShortName'],
                        eventId: event['eventId'],
                        eventName: event['eventName'],
                        eventNumber: event['eventNumber'],
                        isRunStart: 1,
                      ),
                ),
              );
            },
          ),
        ),
        Container(
          margin: const EdgeInsets.only(left: 10, right: 10),
          width: 150.0,
          height: 100.0,
          child: RaisedButton(
            child: const Text(
              'Scan at Run End',
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () {
              Navigator.push<dynamic>(
                context,
                MaterialPageRoute<dynamic>(
                  builder: (BuildContext context) => CheckInScannerPage(
                        kennelShortName: event['kennelShortName'],
                        eventId: event['eventId'],
                        eventName: event['eventName'],
                        eventNumber: event['eventNumber'],
                        isRunStart: 0,
                      ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Row startAndEndQrRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
          margin: const EdgeInsets.only(left: 10, right: 10),
          width: 150.0,
          height: 100.0,
          child: RaisedButton(
              child: const Text(
                'Run Start QR',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                Navigator.push<dynamic>(
                    context,
                    MaterialPageRoute<dynamic>(
                        builder: (BuildContext context) => RunStartEndQrCodes(
                              kennelShortName: event['kennelShortName'],
                              eventId: event['eventId'],
                              eventName: event['eventName'],
                              eventNumber: event['eventNumber'],
                              eventStartDatetime: DateTime.parse(event['eventStartDatetime']),
                              isStart: true,
                            )));
              }),
        ),
        Container(
          margin: const EdgeInsets.only(left: 10, right: 10),
          width: 150.0,
          height: 100.0,
          child: RaisedButton(
              child: const Text(
                'Run End QR',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                Navigator.push<dynamic>(
                    context,
                    MaterialPageRoute<dynamic>(
                        builder: (BuildContext context) => RunStartEndQrCodes(
                              kennelShortName: event['kennelShortName'],
                              eventId: event['eventId'],
                              eventName: event['eventName'],
                              eventNumber: event['eventNumber'],
                              eventStartDatetime: DateTime.parse(event['eventStartDatetime']),
                              isStart: false,
                            )));
              }),
        ),
      ],
    );
  }

  Row receiptsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
          margin: const EdgeInsets.only(left: 10, right: 10),
          width: 150.0,
          height: 100.0,
          child: RaisedButton(
              child: const Text(
                'Manage receipts',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                Navigator.push<dynamic>(context, MaterialPageRoute<dynamic>(builder: (BuildContext context) => ReceiptsList(eventName: event['eventName'], eventId: event['eventId'], digitsAfterDecimal: event['digitsAfterDecimal'], currencySymbol: event['currencySymbol'])));
              }),
        ),
      ],
    );
  }
}
