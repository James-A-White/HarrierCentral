import 'package:harrier_central/imports.dart';

class ReceiptsList extends StatefulWidget {
  const ReceiptsList({super.key, required this.eventAggregate});

  final RunAdminAggregate eventAggregate;

  @override
  ReceiptsListState createState() => ReceiptsListState();
}

class ReceiptsListState extends State<ReceiptsList> {
  ReceiptsListState();

  int pageIndex = 1;

  List<Map<String, dynamic>> receiptsList = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    unawaited(initStateAsync());
    // DBProvider.db.database.then((Database db) {
    //   db.rawQuery('SELECT * FROM receipts ORDER BY id').then((List<Map<String, dynamic>> result) {
    //     //print(result);
    //   });
    // });
  }

  Future<void> initStateAsync() async {
    await refreshFromTable();
  }

  Future<void> refreshFromTable() async {
    try {
      receiptsList = await database.query(
        EnumDataTables.receipts.eventTableName,
      );
    } catch (e) {
      print(e);
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: themeAppBarBackground,
        iconTheme: const IconThemeData(color: Colors.white, size: 28.0),
        title: Text(
          '${widget.eventAggregate.event.eventName} receipts',
          style: ts_appBarTitle,
        ),
      ),
      floatingActionButton: SpeedDial(
        // both default to 16
        // marginEnd: 18,
        // marginBottom: 30,
        animatedIcon: AnimatedIcons.menu_close,
        animatedIconTheme: const IconThemeData(size: 22.0),
        // this is ignored if animatedIcon is non null
        // child:const  Icon(Icons.add),
        visible: true,
        curve: Curves.bounceIn,
        overlayColor: Colors.black,
        overlayOpacity: 0.5,
        onOpen: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
        //onClose: () => //print('DIAL CLOSED'),
        tooltip: 'Speed Dial',
        heroTag: 'speed-dial-hero-tag-6234277',
        backgroundColor: hc_red,
        foregroundColor: Colors.white,
        elevation: 8.0,
        shape: const CircleBorder(),
        children: <SpeedDialChild>[
          SpeedDialChild(
            child: const Icon(MaterialCommunityIcons.playlist_plus),
            backgroundColor: hc_blue,
            label: 'Add Receipt',
            labelStyle: const TextStyle(fontSize: 18.0),
            onTap: () async {
              await Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (BuildContext context) => ReceiptDetailPage(
                    eventId: widget.eventAggregate.event.eventId,
                  ),
                ),
              );

              await refreshFromTable();
            },
          ),
        ],
      ),
      // body: Container(
      //   decoration: Backgrounds.defaultHcBackground(),
      //   height: MediaQuery.of(context).size.height,
      //   child: Container(
      //     margin: const EdgeInsets.all(30.0),
      //     color: themeLightBackground,
      //     child: _buildListView(),
      //   ),
      // ),
      body: Container(color: themeLightBackground, child: _buildListView()),
    );
  }

  Future<void> _handleRefresh() async {
    await tableModel.syncEventAdminService.updateFromBackend(
      EnumDataTables.receipts.flag,
      true,
      widget.eventAggregate.event.eventId,
    );
    //final String resultStr = result ? 'successfully' : 'unsuccessfully';
    //print('Receipts data synchronized $resultStr');
    await refreshFromTable();
  }

  Future<void> setReceiptReimbursementStatus(
    String receiptId,
    bool cancelReimbursement,
  ) async {
    final String userId = getStringPref(StringPrefsEnum.userId)!;

    await database.transaction<dynamic>((Transaction txn) async {
      final String guidFlag = cancelReimbursement ? GUID_9 : GUID_8;
      final String sql =
          'UPDATE ${EnumDataTables.receipts.eventTableName} SET reimbursedBy = "$guidFlag" where receiptId = "$receiptId"';
      await txn.rawUpdate(sql);
      //print(result.toString() + ' update to receipts table @ ${DateTime.now().millisecondsSinceEpoch.toString()}');
    });

    await refreshFromTable();

    final ReceiptsModel item = ReceiptsModel(
      userId: userId,
      receiptId: receiptId,
      eventId: widget.eventAggregate.event.eventId,
      receiptShortDesc: '',
      receiptAmount: -1,
      notes: '',
      reimbursedBy: cancelReimbursement ? GUID_MAX : userId,
      reimbursedAmount: 0,
      reimbursedOn: '1999/1/1',
      reimbursedNotes: '',
      imageUrl: '',
      removed: -1,
    );

    final ReceiptsService srv = ReceiptsService();
    final String responseBody = await srv.uploadReceipt(item);
    if (!responseBody.startsWith(ERROR_PREFIX)) {
      await tableModel.baseService.bulkUpdateDatabase(
        tableModel.receiptsTableHelper,
        EnumDataTables.receipts.eventTableName,
        responseBody,
        database,
      );

      await refreshFromTable();
    } else {
      await Utilities.showAlert(
        'Error uploading receipt',
        'There was an error uploading the receipt. Check your Internet connection and try again.\r\n\r\nSorry for the inconvenience!',
        'OK',
      );
    }
    setState(() {});
  }

  Future<void> setReceiptRemovedStatus(String receiptId, bool removed) async {
    await database.transaction<dynamic>((Transaction txn) async {
      final String guidFlag = removed ? GUID_9 : GUID_8;
      final String sql =
          'UPDATE ${EnumDataTables.receipts.eventTableName} SET reimbursedBy = "$guidFlag" where receiptId = "$receiptId"';
      await txn.rawUpdate(sql);
      //print(result.toString() + ' update to receipts table @ ${DateTime.now().millisecondsSinceEpoch.toString()}');
    });

    await refreshFromTable();

    final String userId = getStringPref(StringPrefsEnum.userId)!;

    final ReceiptsModel item = ReceiptsModel(
      userId: userId,
      receiptId: receiptId,
      eventId: widget.eventAggregate.event.eventId,
      receiptShortDesc: '',
      receiptAmount: -1,
      notes: '',
      reimbursedBy: GUID_EMPTY,
      reimbursedAmount: -1,
      reimbursedOn: '1999/1/1',
      reimbursedNotes: '',
      imageUrl: '',
      removed: removed ? 0 : 1,
    );

    final ReceiptsService srv = ReceiptsService();
    final String responseBody = await srv.uploadReceipt(item);
    if (!responseBody.startsWith(ERROR_PREFIX)) {
      await tableModel.baseService.bulkUpdateDatabase(
        tableModel.receiptsTableHelper,
        EnumDataTables.receipts.eventTableName,
        responseBody,
        database,
      );
      await refreshFromTable();
    } else {
      await Utilities.showAlert(
        'Error uploading receipt',
        'There was an error uploading the receipt. Check your Internet connection and try again.\r\n\r\nSorry for the inconvenience!',
        'OK',
      );
    }
  }

  Widget _buildListView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: receiptsList.isEmpty
                ? Center(
                    child: Text('No receipts available.', style: ts_titleBlack),
                  )
                : RefreshIndicator(
                    onRefresh: _handleRefresh,
                    displacement: 40.0,
                    child: ListView.separated(
                      separatorBuilder: (BuildContext context, int index) =>
                          const Divider(height: 1.0, color: Colors.black45),
                      // physics: const AlwaysScrollableScrollPhysics(),
                      shrinkWrap: true,
                      physics: ClampingScrollPhysics(),
                      itemCount: receiptsList.length,
                      itemBuilder: (BuildContext context, int index) {
                        final Map<String, dynamic> receipt =
                            receiptsList[index];

                        return Dismissible(
                          key: Key(receipt['receiptId']),
                          confirmDismiss: (DismissDirection direction) async {
                            if (direction == DismissDirection.endToStart) {
                              unawaited(
                                setReceiptReimbursementStatus(
                                  receipt['receiptId'],
                                  (receipt['reimbursedBy'] != null) &&
                                      (receipt['reimbursedBy'] != GUID_EMPTY),
                                ),
                              );
                            } else if (direction ==
                                DismissDirection.startToEnd) {
                              unawaited(
                                setReceiptRemovedStatus(
                                  receipt['receiptId'],
                                  receipt['removed'] == 1,
                                ),
                              );
                            }
                            return Future<bool>.value(false);
                          },
                          background: receipt['removed'] == 0
                              ? Container(
                                  color: hc_red,
                                  child: Row(
                                    children: <Widget>[
                                      const Padding(
                                        padding: EdgeInsets.only(left: 10.0),
                                        child: Icon(
                                          FontAwesome.times_circle,
                                          color: Colors.white,
                                          size: 35.0,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 15.0,
                                        ),
                                        child: Text(
                                          // '${IveCoreUtilities.getFormattedMoney(filteredList[index].debitAmount, widget.digitsAfterDecimal, widget.currencySymbol)} Bank Transfer',
                                          'Ignore receipt',
                                          style: ts_titleMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Container(
                                  color: Colors.green,
                                  child: Row(
                                    children: <Widget>[
                                      const Padding(
                                        padding: EdgeInsets.only(left: 10.0),
                                        child: Icon(
                                          FontAwesome.check_circle,
                                          color: Colors.white,
                                          size: 35.0,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 15.0,
                                        ),
                                        child: Text(
                                          // '${IveCoreUtilities.getFormattedMoney(filteredList[index].debitAmount, widget.digitsAfterDecimal, widget.currencySymbol)} Bank Transfer',
                                          'Restore receipt',
                                          style: ts_titleMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                          secondaryBackground:
                              (receipt['reimbursedBy'] != null) &&
                                  (receipt['reimbursedBy'] != GUID_EMPTY) &&
                                  (receipt['reimbursedBy'] != GUID_8)
                              ? Container(
                                  color: Colors.yellow,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: <Widget>[
                                      const Padding(
                                        padding: EdgeInsets.only(right: 15.0),
                                        child: Icon(
                                          FontAwesome.times_circle,
                                          color: Colors.black,
                                          size: 35.0,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          right: 15.0,
                                        ),
                                        child: Text(
                                          //'${IveCoreUtilities.getFormattedMoney(filteredList[index].debitAmount, widget.digitsAfterDecimal, widget.currencySymbol)} Cash',
                                          'Cancel Reimbursement',
                                          style: ts_titleMediumBlack,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Container(
                                  color: Colors.green,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: <Widget>[
                                      const Padding(
                                        padding: EdgeInsets.only(right: 15.0),
                                        child: Icon(
                                          FontAwesome.check_circle,
                                          color: Colors.white,
                                          size: 35.0,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          right: 15.0,
                                        ),
                                        child: Text(
                                          //'${IveCoreUtilities.getFormattedMoney(filteredList[index].debitAmount, widget.digitsAfterDecimal, widget.currencySymbol)} Cash',
                                          'Receipt reimbursed',
                                          style: ts_titleMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                          onDismissed: (DismissDirection direction) {
                            //print(direction.toString() + ' NOTE: We should never reach this point');
                          },
                          child: Container(
                            height: 50.0,
                            padding: const EdgeInsets.all(0.0),
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: <Widget>[
                                ReceiptListItem(
                                  currencySymbol:
                                      widget.eventAggregate.extensions.curSym,
                                  digitsAfterDecimal: widget
                                      .eventAggregate
                                      .extensions
                                      .digAfterDec,
                                  receipt: receiptsList[index],
                                  itemPressed: () async {
                                    await Navigator.push<void>(
                                      context,
                                      MaterialPageRoute<void>(
                                        builder: (BuildContext context) =>
                                            ReceiptDetailPage(
                                              eventId: widget
                                                  .eventAggregate
                                                  .event
                                                  .eventId,
                                              receiptItem: receiptsList[index],
                                            ),
                                      ),
                                    );
                                    await refreshFromTable();
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ),
        Container(
          padding: EdgeInsets.only(left: 10, right: 70, bottom: 20),
          child: Text(
            'Swipe the receipt items in the list above to the left to set their reimbursement status',
            maxLines: 3,
            style: ts_titleBlack,
          ),
        ),
      ],
    );
  }
}

class ReceiptListItem extends StatelessWidget {
  const ReceiptListItem({
    super.key,
    required this.receipt,
    required this.itemPressed,
    required this.currencySymbol,
    required this.digitsAfterDecimal,
  });

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
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Row(
          // crossAxisAlignment: CrossAxisAlignment.center,
          // mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.only(left: 10.0),
                child:
                    ((receipt['reimbursedBy'] == null) ||
                        (receipt['reimbursedBy'] == GUID_EMPTY))
                    ? const Icon(
                        FontAwesome.circle_thin,
                        size: 35.0,
                        color: Colors.grey,
                      )
                    : receipt['reimbursedBy'] == GUID_8 ||
                          receipt['reimbursedBy'] == GUID_9
                    ? Icon(delayIcon, size: 35.0, color: hc_blue)
                    : Icon(
                        FontAwesome.check_circle,
                        size: 35.0,
                        color: receipt['removed'] == 0
                            ? Colors.green
                            : Colors.grey,
                      ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.only(left: 10.0),
                child: Text(
                  IveCoreUtilities.getFormattedMoney(
                    receipt['receiptAmount'],
                    digitsAfterDecimal,
                    currencySymbol,
                  ),
                  style: TextStyle(
                    fontFamily: 'AvenirNextCondensedDemiBold',
                    fontStyle: FontStyle.normal,
                    fontSize: 22.0,
                    height: 1.0,
                    color: receipt['removed'] == 0 ? hc_blue : Colors.grey,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ),
            const SizedBox(height: 10, width: 10),
            Expanded(
              flex: 7,
              child: Text(
                '${receipt['receiptShortDesc']}',
                style: TextStyle(
                  fontFamily: 'AvenirNextCondensedDemiBold',
                  fontStyle: FontStyle.normal,
                  fontSize: 22.0,
                  height: 1.0,
                  color: receipt['removed'] == 0 ? Colors.black : Colors.grey,
                ),
                textAlign: TextAlign.left,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
