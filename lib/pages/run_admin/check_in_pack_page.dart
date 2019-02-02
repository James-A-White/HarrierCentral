import 'dart:core';
import 'dart:math';

import 'package:barcode_scan/barcode_scan.dart';

import 'package:cached_network_image/cached_network_image.dart';

import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:harrier_central/util/enums.dart';
import 'package:harrier_central/data_models/future_run_model.dart';
import 'package:harrier_central/data_models/pack_model.dart';
import 'package:harrier_central/remote_api_data/pack_scoped_model.dart';
import 'package:harrier_central/remote_api_data/pay_scoped_model.dart';
import 'package:harrier_central/remote_api_data/pay_for_event_service.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/utilities.dart';
import 'package:harrier_central/pages/run_admin/other_payment_popup.dart';
import 'package:harrier_central/data_models/process_qr_scan_for_checkin_model.dart';
import 'package:harrier_central/remote_api_data/process_qr_scan_for_checkin_service.dart';
import 'package:harrier_central/pages/run_admin/payment_popup.dart';
import 'package:harrier_central/data_models/pay_for_event_model.dart';
import 'package:harrier_central/pages/kennel_admin/add_member_page.dart';
import 'package:harrier_central/data_models/add_user_model.dart';
import 'package:harrier_central/pages/init/choose_profile_image.dart';

import 'package:scoped_model/scoped_model.dart';

class CheckInPackPage extends StatefulWidget {
  CheckInPackPage({
    @required this.futureRun,
  });

  FutureRun futureRun;

  @override
  State<CheckInPackPage> createState() {
    return CheckInPackPageState();
  }
}

class CheckInPackPageState extends State<CheckInPackPage> {
  PackScopedModel _packScopedModel = PackScopedModel();
  PayScopedModel _payScopedModel = PayScopedModel();

  PayForEventService _payForEventService = PayForEventService();

  String _currentUserId = Preferences.getStringPref(StringPrefsEnum.userId);

  bool _loadingPack = false;

  GlobalKey packListBox = GlobalKey();

  String memberPrice;
  String nonMemberPrice;

  List<PackModel> packList;

  num snackBarButtonSize = 35.0;

  Future<Null> _getPackWithRefresh() async {
    _packScopedModel
        .getPack(
            widget.futureRun.eventId, '00000000-0000-0000-0000-000000000000')
        .then((List<PackModel> _thePack) {
      packList = _thePack;
      setState(() {});
    });

    setState(() {});

    return null;
  }

  void getPack(bool forceRefresh) {
    if ((packList == null) || forceRefresh) {
      _packScopedModel
          .getPack(
              widget.futureRun.eventId, '00000000-0000-0000-0000-000000000000')
          .then((List<PackModel> _thePack) {
        packList = _thePack;
        setState(() {});
      });
    }
  }

  void populatePriceStrings() {
    memberPrice = Utilities.getFormattedMoney(
        widget.futureRun.eventPriceForMembers,
        widget.futureRun.digitsAfterDecimal,
        widget.futureRun.currencySymbol);
    nonMemberPrice = Utilities.getFormattedMoney(
        widget.futureRun.eventPriceForNonMembers,
        widget.futureRun.digitsAfterDecimal,
        widget.futureRun.currencySymbol);
  }

  @override
  Widget build(BuildContext topContext) {
    populatePriceStrings();
    getPack(false);
    return ScopedModel<PackScopedModel>(
      model: _packScopedModel,
      child: ScopedModel<PayScopedModel>(
        model: _payScopedModel,
        child: Scaffold(
          appBar: AppBar(
            centerTitle: true,
            backgroundColor: Theme.of(topContext).primaryColor,
            title: Text(
              '${widget.futureRun.eventName} Check In',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
          body: Builder(
            builder: (scaffoldContext) => Stack(
                    //mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Positioned(
                        top: 0.0,
                        right: 0.0,
                        left: 0.0,
                        child: Container(
                          key: packListBox,
                          height: MediaQuery.of(context).size.height - 195,
                          // margin: const EdgeInsets.only(
                          //     top: 10.0, left: 16.0, right: 16.0, bottom: 100.0),
                          //padding: const EdgeInsets.all(8.0),
                          // decoration: new BoxDecoration(
                          //     border: new Border.all(color: Theme.of(context).accentColor)),
                          child:

                              // Scrollbar(
                              //   child:

                              RefreshIndicator(
                            onRefresh: _getPackWithRefresh,
                            child: ScopedModelDescendant<PackScopedModel>(
                              builder: (BuildContext context, Widget child,
                                  PackScopedModel model) {
                                return StaggeredGridView.countBuilder(
                                  crossAxisCount: 3,
                                  itemCount: packList?.length ?? 0,
                                  addRepaintBoundaries: false,
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                    return packList.isEmpty
                                        ? new Container(
                                            color: Colors.grey[300],
                                            width: 70.0,
                                            height: 70.0,
                                            child: new Padding(
                                                padding:
                                                    const EdgeInsets.all(5.0),
                                                child: new Center(
                                                    child:
                                                        new CircularProgressIndicator())),
                                          )
                                        : GestureDetector(
                                            onTap: () {
                                              final snackBar =
                                                  buildRsvpAndPaymentSnackbar(
                                                      context,
                                                      index,
                                                      _packScopedModel);

                                              Scaffold.of(context)
                                                  .removeCurrentSnackBar(
                                                      reason:
                                                          SnackBarClosedReason
                                                              .hide);
                                              Scaffold.of(context)
                                                  .showSnackBar(snackBar);
                                            },
                                            child: Stack(
                                              children: <Widget>[
                                                packList[index]
                                                        .photo
                                                        .startsWith('http')
                                                    ? CachedNetworkImage(
                                                        imageUrl:
                                                            packList[index]
                                                                .photo,
                                                        placeholder:
                                                            const CircularProgressIndicator(),
                                                        errorWidget: const Icon(
                                                            Icons.error),
                                                        //fadeOutDuration:  Duration(seconds: 1),
                                                        fadeInDuration:
                                                            Duration(
                                                                milliseconds:
                                                                    0),
                                                        width: 300.0,
                                                        height: 300.0,
                                                        fit: BoxFit.fill)
                                                    : packList[index]
                                                            .photo
                                                            .startsWith(
                                                                'bundle')
                                                        ? Image(
                                                            width: 300.0,
                                                            height: 300.0,
                                                            fit: BoxFit.fill,
                                                            image: AssetImage('images/avatars/' +
                                                                packList[index]
                                                                    .photo
                                                                    .toLowerCase()
                                                                    .replaceFirst(
                                                                        'bundle://',
                                                                        '') +
                                                                '.png'),
                                                          )
                                                        : Image(
                                                            width: 300.0,
                                                            height: 300.0,
                                                            fit: BoxFit.fill,
                                                            image: AssetImage(
                                                                'images/avatars/avatar-2.png'),
                                                          ),
                                                Positioned(
                                                  left: 3.0,
                                                  bottom: 1.0,
                                                  child: CircleAvatar(
                                                    backgroundColor: packList[
                                                                    index]
                                                                .rsvpState ==
                                                            0
                                                        ? Colors.transparent
                                                        : packList[index]
                                                                    .rsvpState ==
                                                                -1
                                                            ? Colors.blue
                                                            : Colors.white,
                                                    radius: 14.0,
                                                  ),
                                                ),
                                                Positioned(
                                                  left: 5.0,
                                                  bottom: packList[index]
                                                              .rsvpState <=
                                                          0
                                                      ? 2.5
                                                      : packList[index]
                                                                  .isHare ==
                                                              1
                                                          ? 3.0
                                                          : 3.5,
                                                  child: packList[index].rsvpState <=
                                                          0
                                                      ? CircleAvatar(
                                                          backgroundColor:
                                                              Colors
                                                                  .transparent,
                                                          radius: 12.0,
                                                        )
                                                      : packList[index]
                                                                  .rsvpState ==
                                                              rsvpNo.value
                                                          ? Icon(FontAwesomeIcons.solidTimesCircle,
                                                              color: Colors.red,
                                                              size: 24.0)
                                                          : packList[index]
                                                                      .rsvpState ==
                                                                  rsvpMaybe
                                                                      .value
                                                              ? Icon(FontAwesomeIcons.solidQuestionCircle,
                                                                  color: Colors
                                                                      .orange,
                                                                  size: 24.0)
                                                              : packList[index].isHare == 0
                                                                  ? Icon(FontAwesomeIcons.solidCheckCircle,
                                                                      color: Colors
                                                                          .green,
                                                                      size:
                                                                          24.0)
                                                                  : Image.asset(
                                                                      'images/icons/hare_icon.png',
                                                                      color: Colors.deepPurple,
                                                                      height: 24.0,
                                                                      width: 24.0),

                                                  // AssetImage(
                                                  //     'images/icons/hare_icon.png'),
                                                ),
                                                Positioned(
                                                  right: 3.0,
                                                  bottom: 1.0,
                                                  child: packList[index]
                                                              .rsvpState !=
                                                          rsvpYes.value
                                                      ? Container()
                                                      : CircleAvatar(
                                                          backgroundColor: packList[
                                                                          index]
                                                                      .attendenceState ==
                                                                  0
                                                              ? Colors
                                                                  .transparent
                                                              : packList[index]
                                                                          .attendenceState ==
                                                                      -1
                                                                  ? Colors.blue
                                                                  : Colors
                                                                      .white,
                                                          radius: 14.0,
                                                        ),
                                                ),
                                                Positioned(
                                                  right: 5.0,
                                                  bottom: packList[index]
                                                              .attendenceState <=
                                                          0
                                                      ? 2.5
                                                      : 3.5,
                                                  child: packList[index].rsvpState != rsvpYes.value
                                                      ? Container()
                                                      : packList[index].attendenceState ==
                                                              attendenceNo.value
                                                          ? Image.asset(
                                                              'images/icons/not_at_hash_icon.png',
                                                              height: 24.0,
                                                              width: 24.0,
                                                              color: Colors
                                                                  .red[700])
                                                          : packList[index].attendenceState ==
                                                                  attendenceAtHash
                                                                      .value
                                                              ? Image.asset(
                                                                  'images/icons/runner_icon.png',
                                                                  height: 24.0,
                                                                  width: 24.0,
                                                                  color: Colors
                                                                      .red)
                                                              : packList[index].attendenceState >= attendenceOnIn.value
                                                                  ? Image.asset(
                                                                      'images/icons/beer_icon.png',
                                                                      height: 24.0,
                                                                      width: 24.0,
                                                                      color: Colors.green)
                                                                  : Image.asset('images/icons/beer_icon.png', height: 24.0, width: 24.0, color: Colors.transparent),
                                                ),

                                                // Payment icons

                                                ScopedModelDescendant<
                                                        PayScopedModel>(
                                                    builder: (BuildContext
                                                            context,
                                                        Widget child,
                                                        PayScopedModel model) {
                                                  return Positioned(
                                                    right: 0.0,
                                                    left: 0.0,
                                                    bottom: 1.0,
                                                    child: packList[index]
                                                                .attendenceState <
                                                            attendenceAtHash
                                                                .value
                                                        ? Container()
                                                        : packList[index]
                                                                    .rsvpState !=
                                                                rsvpYes.value
                                                            ? Container()
                                                            : CircleAvatar(
                                                                backgroundColor: packList[
                                                                                index]
                                                                            .attendenceState ==
                                                                        0
                                                                    ? Colors
                                                                        .transparent
                                                                    : packList[index].isPaid ==
                                                                            -1
                                                                        ? Colors
                                                                            .blue
                                                                        : Colors
                                                                            .white,
                                                                radius: 14.0,
                                                              ),
                                                  );
                                                }),

                                                ScopedModelDescendant<
                                                    PayScopedModel>(
                                                  builder: (BuildContext
                                                          context,
                                                      Widget child,
                                                      PayScopedModel model) {
                                                    return Positioned(
                                                        right: 0.0,
                                                        left: 0.0,
                                                        bottom: packList[index].attendenceState < -1
                                                            ? 2.5
                                                            : 3.5,
                                                        child: packList[index].attendenceState <
                                                                attendenceAtHash
                                                                    .value
                                                            ? Container()
                                                            : packList[index]
                                                                        .rsvpState !=
                                                                    rsvpYes
                                                                        .value
                                                                ? Container()
                                                                : ((packList[index].attendenceState <= attendenceNo.value) && (packList[index].requestedAttendenceState <= attendenceNo.value))
                                                                    ? Image.asset(
                                                                        'images/icons/dollar_sign_icon.png',
                                                                        height:
                                                                            24.0,
                                                                        width:
                                                                            24.0,
                                                                        color: Colors
                                                                            .transparent)
                                                                    : packList[index].isPaid == isPaidNo.value
                                                                        ? Image.asset('images/icons/dollar_sign_icon.png',
                                                                            height: 24.0,
                                                                            width: 24.0,
                                                                            color: Colors.red)
                                                                        : packList[index].isPaid == isPaidYes.value ? Image.asset('images/icons/payment_type_${packList[index].paymentType}.png', height: 24.0, width: 24.0, color: Colors.green) : Container()

                                                        // AssetImage(
                                                        //     'images/icons/hare_icon.png'),
                                                        );
                                                  },
                                                ),
                                              ],
                                            )); //TODO: Replace this with another avatar for missing image
                                  },
                                  staggeredTileBuilder: (int index) {
                                    return packList[index].isHare == 0
                                        ? new StaggeredTile.count(1, 1)
                                        : new StaggeredTile.count(2, 2);
                                  },
                                  mainAxisSpacing: 8.0,
                                  crossAxisSpacing: 8.0,
                                );
                              },
                            ),
                          ),
                          //),
                          // ),
                        ),
                      ),
                      Positioned(
                        bottom: 0.0,
                        right: 0.0,
                        left: 0.0,
                        child: Container(
                          height: 60.0,
                          color: Colors.grey[400],
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: <Widget>[
                                MaterialButton(
                                    //highlightColor: Colors.transparent,
                                    color: Theme.of(topContext).accentColor,
                                    splashColor: Colors.yellow,
                                    minWidth:
                                        MediaQuery.of(topContext).size.width /
                                            3.2,
                                    //shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(5.0))),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(
                                          vertical: 0.0, horizontal: 0.0),
                                      child: Text(
                                        'Scan at Hash',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14.0,
                                            fontFamily: 'WorkSansBold'),
                                      ),
                                    ),
                                    onPressed: () {
                                      scanUserBarcode(checkinTypeRunStart.value,
                                          scaffoldContext);
                                    }),
                                MaterialButton(
                                    //highlightColor: Colors.transparent,
                                    color: Theme.of(topContext).accentColor,
                                    splashColor: Colors.yellow,
                                    minWidth:
                                        MediaQuery.of(topContext).size.width /
                                            3.2,
                                    //shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(5.0))),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(
                                          vertical: 0.0, horizontal: 0.0),
                                      child: Text(
                                        'Scan On-In',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14.0,
                                            fontFamily: 'WorkSansBold'),
                                      ),
                                    ),
                                    onPressed: () {
                                      scanUserBarcode(checkinTypeRunEnd.value,
                                          scaffoldContext);
                                    }),
                                MaterialButton(
                                    //highlightColor: Colors.transparent,
                                    color: Theme.of(topContext).accentColor,
                                    splashColor: Colors.yellow,
                                    minWidth:
                                        MediaQuery.of(topContext).size.width /
                                            3.2,
                                    //shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(5.0))),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(
                                          vertical: 0.0, horizontal: 0.0),
                                      child: Text(
                                        'Filter view',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14.0,
                                            fontFamily: 'WorkSansBold'),
                                      ),
                                    ),
                                    onPressed: () {}),
                              ]),
                        ),
                      ),
                      Positioned(
                        bottom: 50.0,
                        right: 0.0,
                        left: 0.0,
                        child: Container(
                          height: 60.0,
                          color: Colors.grey[400],
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: <Widget>[
                                // MaterialButton(
                                //     //highlightColor: Colors.transparent,
                                //     color: Theme.of(topContext).accentColor,
                                //     splashColor: Colors.yellow,
                                //     minWidth:
                                //         MediaQuery.of(topContext).size.width /
                                //             3.2,
                                //     //shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(5.0))),
                                //     child: const Padding(
                                //       padding: EdgeInsets.symmetric(
                                //           vertical: 0.0, horizontal: 0.0),
                                //       child: Text(
                                //         'Add Virgin',
                                //         style: TextStyle(
                                //             color: Colors.white,
                                //             fontSize: 14.0,
                                //             fontFamily: 'WorkSansBold'),
                                //       ),
                                //     ),
                                //     onPressed: () {}),
                                // MaterialButton(
                                //     //highlightColor: Colors.transparent,
                                //     color: Theme.of(topContext).accentColor,
                                //     splashColor: Colors.yellow,
                                //     minWidth:
                                //         MediaQuery.of(topContext).size.width /
                                //             3.2,
                                //     //shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(5.0))),
                                //     child: const Padding(
                                //       padding: EdgeInsets.symmetric(
                                //           vertical: 0.0, horizontal: 0.0),
                                //       child: Text(
                                //         'Add Visitor',
                                //         style: TextStyle(
                                //             color: Colors.white,
                                //             fontSize: 14.0,
                                //             fontFamily: 'WorkSansBold'),
                                //       ),
                                //     ),
                                //     onPressed: () {}),
                                
                                MaterialButton(
                                    //highlightColor: Colors.transparent,
                                    color: Theme.of(topContext).accentColor,
                                    splashColor: Colors.yellow,
                                    minWidth:
                                        MediaQuery.of(topContext).size.width /
                                            3.2,
                                    //shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(5.0))),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(
                                          vertical: 0.0, horizontal: 0.0),
                                      child: Text(
                                        'Add member',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14.0,
                                            fontFamily: 'WorkSansBold'),
                                      ),
                                    ),
                onPressed: () {
                   Navigator.push<String>(
                    context,
                    MaterialPageRoute<String>(
                      builder: (context) => ChooseProfileImage(false,
                            // kennelId: widget.futureRun.kennelId,
                            // eventId: widget.futureRun.eventId,
                            // attendenceState: attendenceAtHash,
                          ),
                    ),
                  ).then<dynamic>((String profileImageUrl){
                    Navigator.push<AddUserModel>(
                    context,
                    MaterialPageRoute<AddUserModel>(
                      builder: (context) => AddMemberPage(
                            kennelId: widget.futureRun.kennelId,
                            eventId: widget.futureRun.eventId,
                            attendenceState: attendenceAtHash,
                            profileImageUrl: profileImageUrl
                          ),
                    ),
                  ).then<dynamic>((AddUserModel test){
                    num i = 0;
                  });


                  });

                },
             ),
                              ]),
                        ),
                      )
                    ]),
          ),
        ),
      ),
    );
  }

//
//
//
//
//
//

  void scanUserBarcode(num checkinType, BuildContext scanContext) {
    Widget snackBar = buildScanResultSnackbar(
        scanContext, _packScopedModel, "Processing QR Scan");

    final Future<String> scanAction = BarcodeScanner.scan();
    scanAction.then((String scanText) {
      ProcessQrScanForCheckinService srv = ProcessQrScanForCheckinService();
      final Future<ProcessQrScanForCheckinModel> apiCall =
          srv.processQrScan(widget.futureRun.eventId, scanText, checkinType, 0);
      apiCall.then((ProcessQrScanForCheckinModel result) {
        if (result.isPaid == 0) {
          PaymentPopup pp = new PaymentPopup(
            amount: result.runPriceThisUser,
            creditAllowed: result.isCreditAllowed,
            creditRemaining: result.remainingCredit,
            currencySymbol: result.currencySymbol,
            hemId: result.hasherEventMapId,
            decimalDigits: result.currencyDigitsAfterDecimal,
          );

          Future<bool> dlg = showDialog<bool>(
              context: context,
              barrierDismissible: false, // user must tap button!
              builder: (BuildContext context) {
                return pp;
              });

          dlg.then((bool x) {
            int minimumAttendenceValue = checkinType == checkinTypeRunStart.value ? attendenceAtHash.value : attendenceOnIn.value;


            PayForEventService paySrv = PayForEventService();
            Future<List<PayForEventModel>> retVal = paySrv.payForEvent(
                result.targetUserId,
                widget.futureRun.eventId,
                result.hasherEventMapId,
                pp.selectedValue,
                pp.amount,
                minimumAttendenceValue);
            retVal.then((List<PayForEventModel> paymentResult) {
              if (paymentResult.isNotEmpty) {
                showScanResults(
                    snackBar,
                    scanContext,
                    result,
                    checkinType,
                    paymentResult[0].isPaid,
                    paymentResult[0].result,
                    pp.selectedValue);
                //_packScopedModel.forceRefresh();
              } else {
                //setState(() => barcode = 'Error processing payment');
              }
            });
          });
        } else {
          showScanResults(snackBar, scanContext, result, checkinType, 1,
              result.paymentInstructions, result.paymentType);
          //_packScopedModel.forceRefresh();
        }
      });

      Scaffold.of(scanContext)
          .removeCurrentSnackBar(reason: SnackBarClosedReason.hide);
      Scaffold.of(scanContext).showSnackBar(snackBar);
    });
  }

  Widget showScanResults(
      Widget snackBar,
      BuildContext scanContext,
      ProcessQrScanForCheckinModel result,
      num checkinType,
      num isPaid,
      String userMessage,
      int paymentType) {
    snackBar =
        buildScanResultSnackbar(scanContext, _packScopedModel, userMessage);

    Scaffold.of(scanContext)
        .removeCurrentSnackBar(reason: SnackBarClosedReason.remove);
    Scaffold.of(scanContext).showSnackBar(snackBar);

    var packItem = packList.firstWhere(
        (PackModel packMember) =>
            packMember.hasherId.toUpperCase() ==
            result.targetUserId.toUpperCase(),
        orElse: () => null);

    if (packItem == null) {
      packItem = PackModel(
          hasherId: result.targetUserId,
          photo: result.photo,
          rsvpState: result.rsvpState,
          attendenceState: result.attendenceState,
          displayName: result.scannedUserName,
          eventId: widget.futureRun.eventId,
          isMember: result.isMember,
          isHare: result.isHare,
          hasherEventMapId: result.hasherEventMapId,
          isFollowing: result.isFollowing,
          currencySymbol: widget.futureRun.currencySymbol,
          eventPrice: result.runPriceThisUser,
          digitsAfterDecimal: widget.futureRun.digitsAfterDecimal,
          virginVisitorType: result.virginVisitorType,
          userStartEvent: result.userStartEvent,
          userEndEvent: result.userEndEvent,
          userRunCount: result.userRunCountThisKennel,
          credit: result.remainingCredit,
          allowNegativeCredit: result.allowNegativeCredit,
          isPaid: result.isPaid,
          paymentType: paymentType);

      packList.add(packItem);
    }

    packItem.paymentType = paymentType;
    packItem.rsvpState = rsvpYes.value;

    if (isPaid >= 0) packItem.isPaid = isPaid;

    if (checkinType == 0) {
      packItem.attendenceState = attendenceAtHash.value;
    } else {
      packItem.attendenceState = attendenceOnIn.value;
    }
    _packScopedModel.forceRefresh();

    return snackBar;
  }

//
//
//
//

  Widget buildScanResultSnackbar(BuildContext context,
      PackScopedModel _packScopedModel, String resultStr) {
    final snackbar = SnackBar(
      duration: Duration(seconds: 4),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            resultStr,
            style: const TextStyle(
                fontFamily: 'AvenirNextCondensedDemiBold',
                fontStyle: FontStyle.normal,
                fontSize: 20.0,
                height: 1.0),
          ),
        ],
      ),
      backgroundColor: Theme.of(context).accentColor,
    );

    return snackbar;
  }

//
//
//

  Widget buildRsvpAndPaymentSnackbar(
      BuildContext context, int index, PackScopedModel _packScopedModel) {
    final snackbar = SnackBar(
      duration: Duration(seconds: 5),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            packList[index].displayName,
            style: const TextStyle(
                fontFamily: 'AvenirNextCondensedDemiBold',
                fontStyle: FontStyle.normal,
                fontSize: 35.0,
                height: 1.0),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    IconButton(
                      icon: Image.asset(
                        'images/icons/x_icon.png',
                        height: 30.0,
                        width: 30.0,
                        color: packList[index].requestedRsvpState != -1
                            ? Colors.blue
                            : packList[index].rsvpState == rsvpNo.value
                                ? Colors.yellow
                                : Colors.white,
                      ),

                      //tooltip: 'Select to follow a Kennel',
                      iconSize: 30.0,
                      alignment: Alignment.topCenter,
                      splashColor: Colors.greenAccent,
                      onPressed: () {
                        _packScopedModel.setRsvpState(
                            rsvpNo.value,
                            isHareNo.value,
                            attendenceNo.value,
                            packList[index]);
                        Scaffold.of(context).hideCurrentSnackBar(
                            reason: SnackBarClosedReason.hide);
                      },
                    ),
                    Text(
                      "Not coming",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'AvenirNextCondensedDemiBold',
                        fontStyle: FontStyle.normal,
                        fontSize: 15.0,
                        height: 0.7,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    IconButton(
                      icon: Image.asset(
                        'images/icons/question_icon.png',
                        height: 30.0,
                        width: 30.0,
                        color: packList[index].requestedRsvpState != -1
                            ? Colors.blue
                            : packList[index].rsvpState == rsvpMaybe.value
                                ? Colors.yellow
                                : Colors.white,
                      ),

                      //tooltip: 'Select to follow a Kennel',
                      iconSize: 30.0,
                      alignment: Alignment.topCenter,
                      splashColor: Colors.greenAccent,
                      onPressed: () {
                        _packScopedModel.setRsvpState(
                            rsvpMaybe.value,
                            isHareNo.value,
                            attendenceNo.value,
                            packList[index]);
                        Scaffold.of(context).hideCurrentSnackBar(
                            reason: SnackBarClosedReason.hide);
                      },
                    ),
                    Text(
                      "Maybe",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'AvenirNextCondensedDemiBold',
                        fontStyle: FontStyle.normal,
                        fontSize: 15.0,
                        height: 0.7,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    IconButton(
                      icon: Image.asset(
                        'images/icons/check_icon.png',
                        height: 30.0,
                        width: 30.0,
                        color: packList[index].requestedRsvpState != -1
                            ? Colors.blue
                            : ((packList[index].rsvpState == rsvpYes.value) &&
                                    (packList[index].isHare == isHareNo.value))
                                ? Colors.yellow
                                : Colors.white,
                      ),

                      //tooltip: 'Select to follow a Kennel',
                      iconSize: 30.0,
                      alignment: Alignment.topCenter,
                      splashColor: Colors.greenAccent,
                      onPressed: () {
                        _packScopedModel.setRsvpState(
                            rsvpYes.value, isHareNo.value, -1, packList[index]);
                        Scaffold.of(context).hideCurrentSnackBar(
                            reason: SnackBarClosedReason.hide);
                      },
                    ),
                    Text(
                      "Coming",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'AvenirNextCondensedDemiBold',
                        fontStyle: FontStyle.normal,
                        fontSize: 15.0,
                        height: 0.7,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    IconButton(
                      icon: Image.asset(
                        'images/icons/hare_icon.png',
                        height: 30.0,
                        width: 30.0,
                        color: packList[index].requestedRsvpState != -1
                            ? Colors.blue
                            : ((packList[index].rsvpState == rsvpYes.value) &&
                                    (packList[index].isHare == isHareYes.value))
                                ? Colors.yellow
                                : Colors.white,
                      ),

                      //tooltip: 'Select to follow a Kennel',
                      iconSize: 30.0,
                      alignment: Alignment.topCenter,
                      splashColor: Colors.greenAccent,
                      onPressed: () {
                        _packScopedModel.setRsvpState(rsvpYes.value,
                            isHareYes.value, -1, packList[index]);
                        Scaffold.of(context).hideCurrentSnackBar(
                            reason: SnackBarClosedReason.hide);
                      },
                    ),
                    Text(
                      "Will hare",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'AvenirNextCondensedDemiBold',
                        fontStyle: FontStyle.normal,
                        fontSize: 15.0,
                        height: 0.7,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(top: 15.0, bottom: 15.0),
            child: Container(color: Colors.white, height: 3.0),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    IconButton(
                      icon: Image.asset(
                        'images/icons/not_at_hash_icon.png',
                        height: 30.0,
                        width: 30.0,
                        color: packList[index].requestedAttendenceState != -1
                            ? Colors.blue
                            : ((packList[index].attendenceState ==
                                        attendenceNo.value) &&
                                    (packList[index].rsvpState ==
                                        rsvpYes.value))
                                ? Colors.yellow
                                : Colors.white,
                      ),

                      //tooltip: 'Select to follow a Kennel',
                      iconSize: 30.0,
                      alignment: Alignment.topCenter,
                      splashColor: Colors.greenAccent,
                      onPressed: () {
                        _packScopedModel.setRsvpState(
                            -1, -1, attendenceNo.value, packList[index]);
                        Scaffold.of(context).hideCurrentSnackBar(
                            reason: SnackBarClosedReason.hide);
                      },
                    ),
                    Text(
                      "Not at Hash",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'AvenirNextCondensedDemiBold',
                        fontStyle: FontStyle.normal,
                        fontSize: 15.0,
                        height: 0.7,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    IconButton(
                      icon: Image.asset(
                        'images/icons/runner_icon.png',
                        height: 30.0,
                        width: 30.0,
                        color: packList[index].requestedAttendenceState != -1
                            ? Colors.blue
                            : ((packList[index].attendenceState ==
                                        attendenceAtHash.value) &&
                                    (packList[index].rsvpState ==
                                        rsvpYes.value))
                                ? Colors.yellow
                                : Colors.white,
                      ),

                      //tooltip: 'Select to follow a Kennel',
                      iconSize: 30.0,
                      alignment: Alignment.topCenter,
                      splashColor: Colors.greenAccent,
                      onPressed: () {
                        _packScopedModel.setRsvpState(rsvpYes.value, -1,
                            attendenceAtHash.value, packList[index]);
                        Scaffold.of(context).hideCurrentSnackBar(
                            reason: SnackBarClosedReason.hide);
                      },
                    ),
                    Text(
                      "At Hash",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'AvenirNextCondensedDemiBold',
                        fontStyle: FontStyle.normal,
                        fontSize: 15.0,
                        height: 0.7,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    IconButton(
                      icon: Image.asset(
                        'images/icons/beer_icon.png',
                        height: 30.0,
                        width: 30.0,
                        color: packList[index].requestedAttendenceState != -1
                            ? Colors.blue
                            : ((packList[index].attendenceState ==
                                        attendenceOnIn.value) &&
                                    (packList[index].rsvpState ==
                                        rsvpYes.value))
                                ? Colors.yellow
                                : Colors.white,
                      ),

                      //tooltip: 'Select to follow a Kennel',
                      iconSize: 30.0,
                      alignment: Alignment.topCenter,
                      splashColor: Colors.greenAccent,
                      onPressed: () {
                        _packScopedModel.setRsvpState(rsvpYes.value, -1,
                            attendenceOnIn.value, packList[index]);
                        Scaffold.of(context).hideCurrentSnackBar(
                            reason: SnackBarClosedReason.hide);
                      },
                    ),
                    Text(
                      "On In",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'AvenirNextCondensedDemiBold',
                        fontStyle: FontStyle.normal,
                        fontSize: 15.0,
                        height: 0.7,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(top: 15.0, bottom: 15.0),
            child: Container(color: Colors.white, height: 3.0),
          ),
          ScopedModelDescendant<PayScopedModel>(
            builder:
                (BuildContext context, Widget child, PayScopedModel model) {
              return Column(children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Expanded(
                      flex: 1,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          IconButton(
                            icon: Image.asset('images/icons/payment_type_1.png',
                                height: 30.0,
                                width: 30.0,
                                color: ((packList[index].isPaid == 0) ||
                                        (packList[index].paymentType ==
                                            paymentNotPaid.value))
                                    ? Colors.yellow
                                    : Colors.white),

                            //tooltip: 'Select to follow a Kennel',
                            iconSize: 30.0,
                            alignment: Alignment.topCenter,
                            splashColor: Colors.greenAccent,
                            onPressed: () {
                              processPayment(
                                  index,
                                  _packScopedModel,
                                  _payScopedModel,
                                  context,
                                  paymentNotPaid.value,
                                  0.0);
                            },
                          ),
                          Text(
                            "Not paid",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'AvenirNextCondensedDemiBold',
                              fontStyle: FontStyle.normal,
                              fontSize: 15.0,
                              height: 0.7,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          IconButton(
                            icon: Image.asset('images/icons/payment_type_2.png',
                                height: 30.0,
                                width: 30.0,
                                color: packList[index].paymentType ==
                                        paymentFreeRun.value
                                    ? Colors.yellow
                                    : Colors.white),
                            //tooltip: 'Select to follow a Kennel',
                            iconSize: 30.0,
                            alignment: Alignment.topCenter,
                            splashColor: Colors.greenAccent,
                            onPressed: () {
                              processPayment(
                                  index,
                                  _packScopedModel,
                                  _payScopedModel,
                                  context,
                                  paymentFreeRun.value,
                                  0.0);
                            },
                          ),
                          Text(
                            "Free run",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'AvenirNextCondensedDemiBold',
                              fontStyle: FontStyle.normal,
                              fontSize: 15.0,
                              height: 0.7,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          IconButton(
                            icon: Image.asset(
                                'images/icons/payment_type_5.png',
                                height: 30.0,
                                width: 30.0,
                                color: ((packList[index].paymentType ==
                                        paymentCashOtherAmount.value) || (packList[index].paymentType ==
                                        paymentBankTransferOtherAmount.value))
                                    ? Colors.yellow
                                    : Colors.white),
                            //tooltip: 'Select to follow a Kennel',
                            iconSize: 30.0,
                            alignment: Alignment.topCenter,
                            splashColor: Colors.greenAccent,
                            onPressed: () {
                              payOther(index, _packScopedModel, context);
                            },
                          ),
                          Text(
                            "Paid other",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'AvenirNextCondensedDemiBold',
                              fontStyle: FontStyle.normal,
                              fontSize: 15.0,
                              height: 0.7,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Container(width: 100, height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      flex: 1,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          IconButton(
                            icon: Image.asset(
                                'images/icons/payment_type_3.png',
                                height: 30.0,
                                width: 30.0,
                                color: packList[index].paymentType ==
                                        paymentCash.value
                                    ? Colors.yellow
                                    : Colors.white),
                            //tooltip: 'Select to follow a Kennel',
                            iconSize: 30.0,
                            alignment: Alignment.topCenter,
                            splashColor: Colors.greenAccent,
                            onPressed: () {
                              processPayment(
                                  index,
                                  _packScopedModel,
                                  _payScopedModel,
                                  context,
                                  paymentCash.value,
                                  packList[index].isMember != 1
                                      ? widget.futureRun.eventPriceForNonMembers
                                      : widget
                                          .futureRun.eventPriceForNonMembers);
                            },
                          ),
                          Text(
                            'Paid ${packList[index].isMember != 1 ? nonMemberPrice : memberPrice}\r\ncash',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'AvenirNextCondensedDemiBold',
                              fontStyle: FontStyle.normal,
                              fontSize: 15.0,
                              height: 0.7,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          IconButton(
                            icon: Image.asset('images/icons/payment_type_4.png',
                                height: 30.0,
                                width: 30.0,
                                color: packList[index].paymentType ==
                                        paymentBankTransfer.value
                                    ? Colors.yellow
                                    : Colors.white),
                            //tooltip: 'Select to follow a Kennel',
                            iconSize: 30.0,
                            alignment: Alignment.topCenter,
                            splashColor: Colors.greenAccent,
                            onPressed: () {
                              processPayment(
                                  index,
                                  _packScopedModel,
                                  _payScopedModel,
                                  context,
                                  paymentBankTransfer.value,
                                  packList[index].isMember != 1
                                      ? widget.futureRun.eventPriceForNonMembers
                                      : widget
                                          .futureRun.eventPriceForNonMembers);
                            },
                          ),
                          Text(
                            'Paid ${packList[index].isMember != 1 ? nonMemberPrice : memberPrice}\r\nbank transfer',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'AvenirNextCondensedDemiBold',
                              fontStyle: FontStyle.normal,
                              fontSize: 15.0,
                              height: 0.7,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          IconButton(
                            icon: Image.asset(
                                'images/icons/payment_type_6.png',
                                height: 30.0,
                                width: 30.0,
                                color: packList[index].paymentType ==
                                        paymentHashCredit.value
                                    ? Colors.yellow
                                    : Colors.white),
                            //tooltip: 'Select to follow a Kennel',
                            iconSize: 30.0,
                            alignment: Alignment.topCenter,
                            splashColor: Colors.greenAccent,
                            onPressed: () {
                              processPayment(
                                  index,
                                  _packScopedModel,
                                  _payScopedModel,
                                  context,
                                  paymentHashCredit.value,
                                  packList[index].isMember != 1
                                      ? widget.futureRun.eventPriceForNonMembers
                                      : widget
                                          .futureRun.eventPriceForNonMembers);
                            },
                          ),
                          Text(
                            'Credit ${packList[index].isMember != 1 ? nonMemberPrice : memberPrice}\r\n(${packList[index].credit < 0 ? 'Owes' : 'Credit'} ${Utilities.getFormattedMoney(packList[index].credit.abs(), widget.futureRun.digitsAfterDecimal, widget.futureRun.currencySymbol)})',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'AvenirNextCondensedDemiBold',
                              fontStyle: FontStyle.normal,
                              fontSize: 15.0,
                              height: 0.7,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ]);
            },
          ),
        ],
      ),
      backgroundColor: Theme.of(context).accentColor,
    );

    return snackbar;
  }

  void payOther(
      int index, PackScopedModel _packScopedModel, BuildContext context) {
    OtherPaymentPopup otherPaymentPopup =
        new OtherPaymentPopup(currencySymbol: widget.futureRun.currencySymbol);

    Future<Map<String,String>> dlg = showDialog<Map<String,String>>(
        context: context,
        barrierDismissible: false, // user must tap button!
        builder: (BuildContext context) {
          return otherPaymentPopup;
        });

    dlg.then((Map<String,String> x) {
      String amount = x['amount'];
      String type = x['type'];

      if (type != 'cancel') {
        num v = num.tryParse(amount);
        int t = int.tryParse(type);

        if ((v != null) && (t != null)) {
          processPayment(index, _packScopedModel, _payScopedModel, context,
              t, v);
        }
      }
    });
  }

  void processPayment(
      int index,
      PackScopedModel _packScopedModel,
      PayScopedModel _payScopedModel,
      BuildContext context,
      int paymentType,
      num paymentAmount) {
    PackModel hasher = packList[index];

    if (hasher.rsvpState < rsvpYes.value)
    {
      hasher.rsvpState = -1;
      hasher.requestedRsvpState = rsvpYes.value;
    }

    // if (hasher.attendenceState < attendenceAtHash.value)
    // {
    //   hasher.attendenceState = -1;
    //   hasher.requestedAttendenceState = attendenceAtHash.value;
    // }

    _packScopedModel.forceRefresh();

    _payScopedModel
        .payForEvent(packList, index, paymentType, paymentAmount,attendenceAtHash.value)
        .then((List<PayForEventModel> result) {

      if (paymentType == paymentNotPaid.value) {
        hasher.isPaid = 0;
      } else {
        hasher.isPaid = 1;
      } 

      if (hasher.hasherEventMapId != result[0].hasherEventMapId)
      {
        hasher.hasherEventMapId = result[0].hasherEventMapId;
      }

      hasher.rsvpState = rsvpYes.value;
      hasher.requestedRsvpState = -1;

      if (hasher.attendenceState < attendenceAtHash.value)
      {
        hasher.attendenceState = attendenceAtHash.value;
      }

       _packScopedModel.forceRefresh();
      
      packList[index].paymentType = paymentType;
      if ((paymentType == paymentCashOtherAmount.value) ||(paymentType == paymentBankTransferOtherAmount.value)) {
        final num fundsDifference = paymentAmount -
            (hasher.isMember == 1
                ? widget.futureRun.eventPriceForMembers
                : widget.futureRun.eventPriceForNonMembers);

        String credit = Utilities.getFormattedMoney(
            fundsDifference,
            widget.futureRun.digitsAfterDecimal,
            widget.futureRun.currencySymbol);

        double hashCashAmount = (hasher.isMember == 1
            ? widget.futureRun.eventPriceForMembers
            : widget.futureRun.eventPriceForNonMembers);

        String hashCash = Utilities.getFormattedMoney(
            hashCashAmount,
            widget.futureRun.digitsAfterDecimal,
            widget.futureRun.currencySymbol);

        String amountPaid = Utilities.getFormattedMoney(
            paymentAmount,
            widget.futureRun.digitsAfterDecimal,
            widget.futureRun.currencySymbol);

       

        String paymentMethod = paymentType == paymentCashOtherAmount.value ? 'in cash' : 'by bank transfer';

        if (fundsDifference > 0.0) {
          showDialog<void>(
              context: context,
              builder: (BuildContext context) {
                // return object of type Dialog
                return AlertDialog(
                  title: new Text("Credit applied to account"),
                  content: new Text(
                      '$amountPaid was paid $paymentMethod. $hashCash was used to pay for the run and $credit has been credited to your Hash account for ${widget.futureRun.kennelShortName}'),
                  actions: <Widget>[
                    // usually buttons at the bottom of the dialog
                    new FlatButton(
                      color:Colors.blue,
                      textColor: Colors.white,
                      child: new Text("Close"),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                );
              });
        }
      }
    });

    packList[index].isPaid = -1;

    // int attendenceState = -1;
    // if (packList[index].attendenceState < attendenceAtHash.value) {
    //   attendenceState = attendenceAtHash.value;
    // }
    // _packScopedModel.setRsvpState(
    //     rsvpYes.value, -1, attendenceState, packList[index]);

    Scaffold.of(context).hideCurrentSnackBar(reason: SnackBarClosedReason.hide);
  }
}

// class RectClipper extends CustomClipper<Rect> {
//   RectClipper({@required this.width, @required this.height});

//   double width;
//   double height;

//   @override
//   Rect getClip(Size size) {
//     Rect r = const Offset(0.0, 0.0) & Size(width, height - 33);

//     // This is where we decide what part of our image is going to be
//     // visible. If you try to run the app now, nothing will be shown.
//     return r;
//   }

//   @override
//   bool shouldReclip(CustomClipper<Rect> oldClipper) => false;
// }
