import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:sqflite/sqflite.dart';

import 'package:harrier_central/data/models/planned_run_model.dart';
import 'package:harrier_central/pages/run_admin/run_start_end_qr_codes_page.dart';
import 'package:harrier_central/pages/run_admin/check_in_scanner_page.dart';
import 'package:harrier_central/pages/run_admin/payment_report.dart';
import 'package:harrier_central/pages/run_admin/receipts_page.dart';
import 'package:harrier_central/database/database.dart';
import 'package:harrier_central/data/hc3_services/sync_event_admin_service.dart';
import 'package:harrier_central/pages/run_admin/check_in_pack_page.dart';
import 'package:harrier_central/util/styles.dart';
import 'package:harrier_central/widgets/circular_progress_indicator.dart';

class RunAdminMainPage extends StatefulWidget {
  //final FutureRunScopedModel futureRunsModel;

  const RunAdminMainPage({Key key, this.futureRun}) : super(key: key);

  final PlannedRun futureRun;

  @override
  RunAdminMainPageState createState() => RunAdminMainPageState();
}

class RunAdminMainPageState extends State<RunAdminMainPage> {
  bool _isLoading = true;

  @override
  void initState() {
    DBProvider.db.database.then((Database db) async {
      final SyncEventAdminService cSrv = SyncEventAdminService();
      cSrv.updateFromBackend(db, SyncEventAdminService.flagsAllData, false, widget.futureRun.eventId).then((bool result) {
        setState(() {
          final String resultStr = result ? 'successfully' : 'unsuccessfully';
          print('Event admin data synchronized $resultStr');
          _isLoading = false;
        });
      });
    });

    super.initState();
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

    if (widget.futureRun.mmAuthAllowCheckInAndOut || widget.futureRun.mmAuthAllowEditRsvp) {
      kiddies.add(rsvpRow());
    }

    if (widget.futureRun.mmAuthAllowCheckInAndOut) {
      kiddies.add(attendenceRow());
    }

    kiddies.add(paymentRow());

    kiddies.add(receiptsRow());

    return kiddies;
  }

  Row rsvpRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        !widget.futureRun.mmAuthAllowEditRsvp
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
                        builder: (BuildContext context) => CheckInPackPage(futureRun: widget.futureRun),
                      ),
                    );
                  },
                ),
              ),
        !widget.futureRun.mmAuthAllowHashCash
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
                              eventId: widget.futureRun.eventId,
                              currencySymbol: widget.futureRun.currencySymbol,
                              digitsAfterDecimal: widget.futureRun.digitsAfterDecimal,
                              eventName: widget.futureRun.eventName,
                            ),
                      ),
                    );
                  },
                ),
              ),

        // Container(
        //   width: 150.0,
        //   child: RaisedButton(
        //       child: const Text(
        //         'Edit Run',
        //         style:
        //             TextStyle(color: Colors.white),
        //       ),
        //       onPressed: () {
        //         //int i = 0;
        //       }),
        // ),
      ],
    );
  }

  Row attendenceRow() {
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
                        kennelShortName: widget.futureRun.kennelShortName,
                        eventId: widget.futureRun.eventId,
                        eventName: widget.futureRun.eventName,
                        eventNumber: widget.futureRun.eventNumber,
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
                        kennelShortName: widget.futureRun.kennelShortName,
                        eventId: widget.futureRun.eventId,
                        eventName: widget.futureRun.eventName,
                        eventNumber: widget.futureRun.eventNumber,
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

  Row paymentRow() {
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
                              kennelShortName: widget.futureRun.kennelShortName,
                              eventId: widget.futureRun.eventId,
                              eventName: widget.futureRun.eventName,
                              eventNumber: widget.futureRun.eventNumber,
                              eventStartDatetime: widget.futureRun.eventStartDatetime,
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
                              kennelShortName: widget.futureRun.kennelShortName,
                              eventId: widget.futureRun.eventId,
                              eventName: widget.futureRun.eventName,
                              eventNumber: widget.futureRun.eventNumber,
                              eventStartDatetime: widget.futureRun.eventStartDatetime,
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
                Navigator.push<dynamic>(
                    context, MaterialPageRoute<dynamic>(builder: (BuildContext context) => ReceiptsList(eventName: widget.futureRun.eventName, eventId: widget.futureRun.eventId, digitsAfterDecimal: widget.futureRun.digitsAfterDecimal, currencySymbol: widget.futureRun.currencySymbol)));
              }),
        ),

        // Container(
        //   margin: const EdgeInsets.only(left: 10, right: 10),
        //   width: 150.0,
        //   height: 100.0,
        //   child: RaisedButton(
        //       child: const Text(
        //         'Run End QR',
        //         style: TextStyle(color: Colors.white),
        //       ),
        //       onPressed: () {
        //         Navigator.push<dynamic>(
        //             context,
        //             MaterialPageRoute<dynamic>(
        //                 builder: (BuildContext context) => RunStartEndQrCodes(
        //                       kennelShortName: widget.futureRun.kennelShortName,
        //                       eventId: widget.futureRun.eventId,
        //                       eventName: widget.futureRun.eventName,
        //                       eventNumber: widget.futureRun.eventNumber,
        //                       eventStartDatetime:
        //                           widget.futureRun.eventStartDatetime,
        //                       isStart: false,
        //                     )));
        //       }),
        // ),
      ],
    );
  }
}
