import 'dart:async';

import 'package:flutter/material.dart';
import 'package:harrier_central/pages/run_admin/run_admin_main.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import 'package:harrier_central/pages/run_admin/receipt_detail_page.dart';
import 'package:harrier_central/util/styles.dart';
import 'package:harrier_central/util/utilities.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/util/globals.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/database/database.dart';
import 'package:harrier_central/data/hc3_services/sync_event_admin_service.dart';
import 'package:harrier_central/data/hc3_services/receipts_service.dart';

class ReceiptsList extends StatefulWidget {
  const ReceiptsList({Key key, @required this.eventAggregate}) : super(key: key);

  final RunDetailAggregate eventAggregate;

  @override
  ReceiptsListState createState() => ReceiptsListState();
}

class ReceiptsListState extends State<ReceiptsList> {
  ReceiptsListState();

  int pageIndex = 1;

  List<Map<String, dynamic>> receiptsList = <Map<String, dynamic>>[];

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    refreshFromTable();
    // DBProvider.db.database.then((Database db) {
    //   db.rawQuery('SELECT * FROM receipts ORDER BY id').then((List<Map<String, dynamic>> result) {
    //     print(result);
    //   });
    // });

    super.initState();
  }

  void refreshFromTable() {
    DBProvider.db.database.then((Database db) {
      try {
        db.query(receiptsTableHelper.tableName).then((List<Map<String, dynamic>> results) {
          setState(() {
            receiptsList = results;
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
        key: _scaffoldKey,
        appBar: AppBar(
          centerTitle: true,
        
          backgroundColor: themeAppBarBackground,
          title: Text(
            '${widget.eventAggregate.event.eventName} receipts',
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
        ),
        floatingActionButton: SpeedDial(
          // both default to 16
          marginRight: 18,
          marginBottom: 30,
          animatedIcon: AnimatedIcons.menu_close,
          animatedIconTheme: const IconThemeData(size: 22.0),
          // this is ignored if animatedIcon is non null
          // child:const  Icon(Icons.add),
          visible: true,
          curve: Curves.bounceIn,
          overlayColor: Colors.black,
          overlayOpacity: 0.5,
          onOpen: () {
            _scaffoldKey.currentState.hideCurrentSnackBar();
          },
          onClose: () => print('DIAL CLOSED'),
          tooltip: 'Speed Dial',
          heroTag: 'speed-dial-hero-tag',
          backgroundColor: Theme.of(context).accentColor,
          foregroundColor: Colors.white,
          elevation: 8.0,
          shape: const CircleBorder(),
          children: <SpeedDialChild>[
            SpeedDialChild(
                child: const Icon(MaterialCommunityIcons.playlist_plus),
                backgroundColor: Colors.blue,
                label: 'Add Receipt',
                labelStyle: const TextStyle(fontSize: 18.0),
                onTap: () => Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                          builder: (BuildContext context) => ReceiptDetailPage(
                                eventId: widget.eventAggregate.event.eventId,
                              )),
                    ).then<dynamic>((void receipt) {
                      refreshFromTable();
                    })),
          ],
        ),
        body:
            //  model.isLoading
            //     ? _buildCircularProgressIndicator()
            //     :
            _buildListView());
  }

  Future<void> _handleRefresh() async {
    final Database db = await DBProvider.db.database;

    final SyncEventAdminService cSrv = SyncEventAdminService();
    final bool result = await cSrv.updateFromBackend(db, SyncEventAdminService.flagReceiptsTable, true, widget.eventAggregate.event.eventId);
    final String resultStr = result ? 'successfully' : 'unsuccessfully';
    print('Receipts data synchronized $resultStr');
    refreshFromTable();
  }

  Future<void> setReceiptReimbursementStatus(String receiptId, bool cancelReimbursement) async {
    final String userId = getStringPref(StringPrefsEnum.userId);

    final Database db = await DBProvider.db.database;

    await db.transaction<dynamic>((Transaction txn) async {
      final String guidFlag = cancelReimbursement ? GUID_9 : GUID_8;
      final String sql = 'UPDATE receipts SET reimbursedBy = "$guidFlag" where receiptId = "$receiptId"';
      final int result = await txn.rawUpdate(sql);
      print(result.toString() + ' update to receipts table @ ${DateTime.now().millisecondsSinceEpoch.toString()}');
      refreshFromTable();
    });

    final ReceiptsModel item =
        ReceiptsModel(receiptId: receiptId, eventId: widget.eventAggregate.event.eventId, receiptShortDescription: '', receiptAmount: -1, notes: '', reimbursedBy: cancelReimbursement ? GUID_MAX : userId, reimbursedAmount: 0, reimbursedOn: '1999/1/1', reimbursedNotes: '', imageUrl: '', removed: -1);

    setState(() {
      final ReceiptsService srv = ReceiptsService();
      srv.uploadReceipt(context, item).then((String result) {
        DBProvider.db.database.then((Database db) {
          baseService.bulkUpdateDatabase(receiptsTableHelper,result, db, null).then((int notUsed) {
            refreshFromTable();
          });
        });
      });
    });
  }

  Future<void> setReceiptRemovedStatus(String receiptId, bool removed) async {
    final Database db = await DBProvider.db.database;

    await db.transaction<dynamic>((Transaction txn) async {
      final String guidFlag = removed ? GUID_9 : GUID_8;
      final String sql = 'UPDATE receipts SET reimbursedBy = "$guidFlag" where receiptId = "$receiptId"';
      final int result = await txn.rawUpdate(sql);
      print(result.toString() + ' update to receipts table @ ${DateTime.now().millisecondsSinceEpoch.toString()}');
      refreshFromTable();
    });

    final ReceiptsModel item =
        ReceiptsModel(receiptId: receiptId, eventId: widget.eventAggregate.event.eventId, receiptShortDescription: '', receiptAmount: -1, notes: '', reimbursedBy: GUID_EMPTY, reimbursedAmount: -1, reimbursedOn: '1999/1/1', reimbursedNotes: '', imageUrl: '', removed: removed ? 0 : 1);

    setState(() {
      final ReceiptsService srv = ReceiptsService();
      srv.uploadReceipt(context, item).then((String result) {
        DBProvider.db.database.then((Database db) {
          baseService.bulkUpdateDatabase(receiptsTableHelper,result, db, null).then((int notUsed) {
            refreshFromTable();
          });
        });
      });
    });
  }

  Widget _buildListView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: receiptsList.isEmpty
                ? const Center(child: Text('No receipts available.'))
                : RefreshIndicator(
                    onRefresh: () => _handleRefresh(),
                    displacement: 40.0,
                    child: ListView.separated(
                      separatorBuilder: (BuildContext context, int index) => const Divider(
                        height: 1.0,
                        color: Colors.black45,
                      ),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: receiptsList.length,
                      itemBuilder: (BuildContext context, int index) {
                        final Map<String, dynamic> receipt = receiptsList[index];
                        return 
                        
                        
                        
                        
                        
                        
                        
                        
                        Dismissible(
                          key: Key(receipt['receiptId']),
                          confirmDismiss: (DismissDirection direction) {
                            if (direction == DismissDirection.endToStart) {
                              setReceiptReimbursementStatus(receipt['receiptId'], (receipt['reimbursedBy'] != null) && (receipt['reimbursedBy'] != GUID_EMPTY));
                            } else if (direction == DismissDirection.startToEnd) {
                              setReceiptRemovedStatus(receipt['receiptId'], receipt['removed'] == 1);
                            }
                            return Future<bool>.value(false);
                          },
                          background: receipt['removed'] == 0
                              ? Container(
                                  color: Colors.red,
                                  child: Row(children: const <Widget>[
                                    Padding(
                                      padding: EdgeInsets.only(left: 10.0),
                                      child: Icon(FontAwesome.times_circle, color: Colors.white, size: 35.0),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(left: 15.0),
                                      child: Text(
                                          // '${Utilities.getFormattedMoney(filteredList[index].debitAmount, widget.digitsAfterDecimal, widget.currencySymbol)} Bank Transfer',
                                          'Ignore receipt',
                                          style: TextStyle(fontFamily: 'AvenirNextDemiBold', fontStyle: FontStyle.normal, color: Colors.white, fontSize: 17.0, height: 1.0)),
                                    )
                                  ]))
                              : Container(
                                  color: Colors.green,
                                  child: Row(children: const <Widget>[
                                    Padding(
                                      padding: EdgeInsets.only(left: 10.0),
                                      child: Icon(FontAwesome.check_circle, color: Colors.white, size: 35.0),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(left: 15.0),
                                      child: Text(
                                          // '${Utilities.getFormattedMoney(filteredList[index].debitAmount, widget.digitsAfterDecimal, widget.currencySymbol)} Bank Transfer',
                                          'Restore receipt',
                                          style: TextStyle(fontFamily: 'AvenirNextDemiBold', fontStyle: FontStyle.normal, color: Colors.white, fontSize: 17.0, height: 1.0)),
                                    )
                                  ])),
                          secondaryBackground: (receipt['reimbursedBy'] != null) && (receipt['reimbursedBy'] != GUID_EMPTY) && (receipt['reimbursedBy'] != GUID_8)
                              ? Container(
                                  color: Colors.yellow,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: const <Widget>[
                                      Padding(
                                        padding: EdgeInsets.only(right: 15.0),
                                        child: Icon(FontAwesome.times_circle, color: Colors.black, size: 35.0),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.only(right: 15.0),
                                        child: Text(
                                            //'${Utilities.getFormattedMoney(filteredList[index].debitAmount, widget.digitsAfterDecimal, widget.currencySymbol)} Cash',
                                            'Cancel Reimbursement',
                                            style: TextStyle(fontFamily: 'AvenirNextDemiBold', fontStyle: FontStyle.normal, color: Colors.black, fontSize: 17.0, height: 1.0)),
                                      )
                                    ],
                                  ),
                                )
                              : Container(
                                  color: Colors.green,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: const <Widget>[
                                      Padding(
                                        padding: EdgeInsets.only(right: 15.0),
                                        child: Icon(FontAwesome.check_circle, color: Colors.white, size: 35.0),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.only(right: 15.0),
                                        child: Text(
                                            //'${Utilities.getFormattedMoney(filteredList[index].debitAmount, widget.digitsAfterDecimal, widget.currencySymbol)} Cash',
                                            'Receipt reimbursed',
                                            style: TextStyle(fontFamily: 'AvenirNextDemiBold', fontStyle: FontStyle.normal, color: Colors.white, fontSize: 17.0, height: 1.0)),
                                      )
                                    ],
                                  ),
                                ),
                          onDismissed: (DismissDirection direction) {
                            print(direction.toString() + ' NOTE: We should never reach this point');
                          },
                          child: Container(
                            height: 50.0,
                            padding: const EdgeInsets.all(0.0),
                            child: ListView(scrollDirection: Axis.horizontal, children: <Widget>[
                              ReceiptListItem(
                                  currencySymbol: widget.eventAggregate.extensions.curSym,
                                  digitsAfterDecimal: widget.eventAggregate.extensions.digAfterDec,
                                  receipt: receiptsList[index],
                                  itemPressed: () {
                                    Navigator.push<void>(
                                      context,
                                      MaterialPageRoute<void>(
                                          builder: (BuildContext context) => ReceiptDetailPage(
                                                eventId: widget.eventAggregate.event.eventId,
                                                receiptItem: receiptsList[index],
                                              )),
                                    ).then<dynamic>((void receipt) {
                                      refreshFromTable();
                                    });
                                  }),
                            ]),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ),

        // Container(
        //   width: 150.0,
        //   child: RaisedButton(
        //     child: const Text(
        //       'Add Member',
        //       style: TextStyle(color: Colors.white),
        //     ),
        //     onPressed: () {
        //       Navigator.push<dynamic>(
        //         context,
        //         MaterialPageRoute<dynamic>(
        //           builder: (BuildContext context) => AddMemberPage(
        //                 kennelId: widget.kennel['kennelId'],
        //               ),
        //         ),
        //       );
        //     },
        //   ),
        // ),
      ],
    );
  }
}

class ReceiptListItem extends StatelessWidget {
  const ReceiptListItem({@required this.receipt, @required this.itemPressed, @required this.currencySymbol, @required this.digitsAfterDecimal});

  final Map<String, dynamic> receipt;
  final Function itemPressed;
  final int digitsAfterDecimal;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        itemPressed();
      },
      child: Container(
        width: MediaQuery.of(context).size.width,
        child: Row(
          // crossAxisAlignment: CrossAxisAlignment.center,
          // mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.only(left: 10.0),
                child: ((receipt['reimbursedBy'] == null) || (receipt['reimbursedBy'] == GUID_EMPTY))
                    ? const Icon(FontAwesome.circle_thin, size: 35.0, color: Colors.grey)
                    : receipt['reimbursedBy'] == GUID_8 || receipt['reimbursedBy'] == GUID_9 ? Icon(delayIcon, size: 35.0, color: Colors.blue) : Icon(FontAwesome.check_circle, size: 35.0, color: receipt['removed'] == 0 ? Colors.green : Colors.grey),
              ),
            ),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.only(left: 10.0),
                child: Text(
                  '${Utilities.getFormattedMoney(receipt['receiptAmount'], digitsAfterDecimal, currencySymbol)}',
                  style: TextStyle(fontFamily: 'AvenirNextCondensedDemiBold', fontStyle: FontStyle.normal, fontSize: 22.0, height: 1.0, color: receipt['removed'] == 0 ? Colors.blue[700] : Colors.grey),
                  textAlign: TextAlign.right,
                ),
              ),
            ),
            const SizedBox(
              height: 10,
              width: 10,
            ),
            Expanded(
              flex: 6,
              child: Text(
                '${receipt['receiptShortDesc']}',
                style: TextStyle(fontFamily: 'AvenirNextCondensedDemiBold', fontStyle: FontStyle.normal, fontSize: 22.0, height: 1.0, color: receipt['removed'] == 0 ? Colors.black : Colors.grey),
                textAlign: TextAlign.left,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
