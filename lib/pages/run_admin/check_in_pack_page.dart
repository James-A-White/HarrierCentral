import 'dart:core';
import 'dart:math';

//import 'package:barcode_scan/barcode_scan.dart';

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
import 'package:harrier_central/data_models/process_qr_scan_for_checkin_model.dart';
import 'package:harrier_central/remote_api_data/process_qr_scan_for_checkin_service.dart';
import 'package:harrier_central/pages/run_admin/payment_popup.dart';
import 'package:harrier_central/data_models/pay_for_event_model.dart';
import 'package:harrier_central/pages/kennel_admin/add_member_page.dart';
import 'package:harrier_central/data_models/add_user_model.dart';
import 'package:harrier_central/pages/init/choose_profile_image.dart';
import 'package:harrier_central/widgets/payment_snackbar.dart';

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

  @override
  Widget build(BuildContext topContext) {
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
                                return PackListView(
                                    packList: packList,
                                    packScopedModel: _packScopedModel,
                                    payScopedModel: _payScopedModel,
                                    futureRun: widget.futureRun);
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
                                        builder: (context) =>
                                            ChooseProfileImage(
                                              false,
                                              // kennelId: widget.futureRun.kennelId,
                                              // eventId: widget.futureRun.eventId,
                                              // attendenceState: attendenceAtHash,
                                            ),
                                      ),
                                    ).then<dynamic>((String profileImageUrl) {
                                      if (profileImageUrl.isEmpty) {
                                      } else {
                                        Navigator.push<AddUserModel>(
                                          context,
                                          MaterialPageRoute<AddUserModel>(
                                            builder: (context) => AddMemberPage(
                                                kennelId:
                                                    widget.futureRun.kennelId,
                                                eventId:
                                                    widget.futureRun.eventId,
                                                attendenceState:
                                                    attendenceAtHash,
                                                profileImageUrl:
                                                    profileImageUrl),
                                          ),
                                        ).then<dynamic>((AddUserModel test) {
                                          _getPackWithRefresh();
                                        });
                                      }
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

    // final Future<String> scanAction = BarcodeScanner.scan();
    // scanAction.then((String scanText) {
    //   ProcessQrScanForCheckinService srv = ProcessQrScanForCheckinService();
    //   final Future<ProcessQrScanForCheckinModel> apiCall =
    //       srv.processQrScan(widget.futureRun.eventId, scanText, checkinType, 0);
    //   apiCall.then((ProcessQrScanForCheckinModel result) {
    //     if (result.isPaid == 0) {
    //       PaymentPopup pp = new PaymentPopup(
    //         amount: result.runPriceThisUser,
    //         creditAllowed: result.isCreditAllowed,
    //         creditRemaining: result.remainingCredit,
    //         currencySymbol: result.currencySymbol,
    //         hemId: result.hasherEventMapId,
    //         decimalDigits: result.currencyDigitsAfterDecimal,
    //       );

    //       Future<bool> dlg = showDialog<bool>(
    //           context: context,
    //           barrierDismissible: false, // user must tap button!
    //           builder: (BuildContext context) {
    //             return pp;
    //           });

    //       dlg.then((bool x) {
    //         int minimumAttendenceValue =
    //             checkinType == checkinTypeRunStart.value
    //                 ? attendenceAtHash.value
    //                 : attendenceOnIn.value;

    //         PayForEventService paySrv = PayForEventService();
    //         Future<List<PayForEventModel>> retVal = paySrv.payForEvent(
    //             result.targetUserId,
    //             widget.futureRun.eventId,
    //             result.hasherEventMapId,
    //             pp.selectedValue,
    //             pp.amount,
    //             minimumAttendenceValue);
    //         retVal.then((List<PayForEventModel> paymentResult) {
    //           if (paymentResult.isNotEmpty) {
    //             showScanResults(
    //                 snackBar,
    //                 scanContext,
    //                 result,
    //                 checkinType,
    //                 paymentResult[0].isPaid,
    //                 paymentResult[0].result,
    //                 pp.selectedValue);
    //             //_packScopedModel.forceRefresh();
    //           } else {
    //             //setState(() => barcode = 'Error processing payment');
    //           }
    //         });
    //       });
    //     } else {
    //       showScanResults(snackBar, scanContext, result, checkinType, 1,
    //           result.paymentInstructions, result.paymentType);
    //       //_packScopedModel.forceRefresh();
    //     }
    //   });

    //   Scaffold.of(scanContext)
    //       .removeCurrentSnackBar(reason: SnackBarClosedReason.hide);
    //   Scaffold.of(scanContext).showSnackBar(snackBar);
    // });
 
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
          digitsAfterDecimal: widget?.futureRun?.digitsAfterDecimal ?? 2,
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
    final snackbar = PaymentSnackBar(
      context: context,
      index: index,
      futureRun: widget.futureRun,
      packScopedModel: _packScopedModel,
      payScopedModel: _payScopedModel,
      packList: packList,
    );

    return snackbar;
  }
}

class PackGridView extends StatelessWidget {
  const PackGridView({
    Key key,
    @required this.packList,
    @required this.packScopedModel,
    @required this.payScopedModel,
    @required this.futureRun,
  }) : super(key: key);

  final List<PackModel> packList;
  final PackScopedModel packScopedModel;
  final PayScopedModel payScopedModel;
  final FutureRun futureRun;

  Widget buildRsvpAndPaymentSnackbar(
      BuildContext context, int index, PackScopedModel _packScopedModel) {
    final snackbar = PaymentSnackBar(
      context: context,
      index: index,
      futureRun: futureRun,
      packScopedModel: packScopedModel,
      payScopedModel: payScopedModel,
      packList: packList,
    );

    return snackbar;
  }

  @override
  Widget build(BuildContext context) {
    return StaggeredGridView.countBuilder(
      crossAxisCount: 3,
      itemCount: packList?.length ?? 0,
      addRepaintBoundaries: false,
      itemBuilder: (BuildContext context, int index) {
        return packList.isEmpty
            ? new Container(
                color: Colors.grey[300],
                width: 70.0,
                height: 70.0,
                child: new Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: new Center(child: new CircularProgressIndicator())),
              )
            : GestureDetector(
                onTap: () {
                  final snackBar = buildRsvpAndPaymentSnackbar(
                      context, index, packScopedModel);

                  Scaffold.of(context)
                      .removeCurrentSnackBar(reason: SnackBarClosedReason.hide);
                  Scaffold.of(context).showSnackBar(snackBar);
                },
                child: Stack(
                  children: <Widget>[
                    packList[index].photo.startsWith('http')
                        ? CachedNetworkImage(
                            imageUrl: packList[index].photo,
                            //placeholder: CircularProgressIndicator(),
                            //errorWidget: Icon(Icons.error),
                            placeholder: (context, url) => const CircularProgressIndicator(),
                            errorWidget: (context, url, error) => const Icon(Icons.error),
                            //fadeOutDuration:  Duration(seconds: 1),
                            fadeInDuration: Duration(milliseconds: 0),
                            width: 300.0,
                            height: 300.0,
                            fit: BoxFit.fill)
                        : packList[index].photo.startsWith('bundle')
                            ? Image(
                                width: 300.0,
                                height: 300.0,
                                fit: BoxFit.fill,
                                image: AssetImage('images/avatars/' +
                                    packList[index]
                                        .photo
                                        .toLowerCase()
                                        .replaceFirst('bundle://', '') +
                                    '.png'),
                              )
                            : Image(
                                width: 300.0,
                                height: 300.0,
                                fit: BoxFit.fill,
                                image:
                                    AssetImage('images/avatars/avatar-2.png'),
                              ),
                    Positioned(
                      left: 3.0,
                      bottom: 1.0,
                      child: CircleAvatar(
                        backgroundColor: packList[index].rsvpState == 0
                            ? Colors.transparent
                            : packList[index].rsvpState == -1
                                ? Colors.blue
                                : Colors.white,
                        radius: 14.0,
                      ),
                    ),
                    Positioned(
                      left: 5.0,
                      bottom: packList[index].rsvpState <= 0
                          ? 2.5
                          : packList[index].isHare == 1 ? 3.0 : 3.5,
                      child: packList[index].rsvpState <= 0
                          ? CircleAvatar(
                              backgroundColor: Colors.transparent,
                              radius: 12.0,
                            )
                          : packList[index].rsvpState == rsvpNo.value
                              ? Icon(FontAwesomeIcons.solidTimesCircle,
                                  color: Colors.red, size: 24.0)
                              : packList[index].rsvpState == rsvpMaybe.value
                                  ? Icon(FontAwesomeIcons.solidQuestionCircle,
                                      color: Colors.orange, size: 24.0)
                                  : packList[index].isHare == 0
                                      ? Icon(FontAwesomeIcons.solidCheckCircle,
                                          color: Colors.green, size: 24.0)
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
                      child: packList[index].rsvpState != rsvpYes.value
                          ? Container()
                          : CircleAvatar(
                              backgroundColor:
                                  packList[index].attendenceState == 0
                                      ? Colors.transparent
                                      : packList[index].attendenceState == -1
                                          ? Colors.blue
                                          : Colors.white,
                              radius: 14.0,
                            ),
                    ),
                    Positioned(
                      right: 5.0,
                      bottom: packList[index].attendenceState <= 0 ? 2.5 : 3.5,
                      child: packList[index].rsvpState != rsvpYes.value
                          ? Container()
                          : packList[index].attendenceState ==
                                  attendenceNo.value
                              ? Image.asset('images/icons/not_at_hash_icon.png',
                                  height: 24.0,
                                  width: 24.0,
                                  color: Colors.red[700])
                              : packList[index].attendenceState ==
                                      attendenceAtHash.value
                                  ? Image.asset('images/icons/runner_icon.png',
                                      height: 24.0,
                                      width: 24.0,
                                      color: Colors.red)
                                  : packList[index].attendenceState >=
                                          attendenceOnIn.value
                                      ? Image.asset(
                                          'images/icons/beer_icon.png',
                                          height: 24.0,
                                          width: 24.0,
                                          color: Colors.green)
                                      : Image.asset(
                                          'images/icons/beer_icon.png',
                                          height: 24.0,
                                          width: 24.0,
                                          color: Colors.transparent),
                    ),

                    // Payment icons

                    ScopedModelDescendant<PayScopedModel>(builder:
                        (BuildContext context, Widget child,
                            PayScopedModel model) {
                      return Positioned(
                        right: 0.0,
                        left: 0.0,
                        bottom: 1.0,
                        child: packList[index].attendenceState <
                                attendenceAtHash.value
                            ? Container()
                            : packList[index].rsvpState != rsvpYes.value
                                ? Container()
                                : CircleAvatar(
                                    backgroundColor:
                                        packList[index].attendenceState == 0
                                            ? Colors.transparent
                                            : packList[index].isPaid == -1
                                                ? Colors.blue
                                                : Colors.white,
                                    radius: 14.0,
                                  ),
                      );
                    }),

                    ScopedModelDescendant<PayScopedModel>(
                      builder: (BuildContext context, Widget child,
                          PayScopedModel model) {
                        return Positioned(
                            right: 0.0,
                            left: 0.0,
                            bottom: packList[index].attendenceState < -1
                                ? 2.5
                                : 3.5,
                            child: packList[index].attendenceState < attendenceAtHash.value
                                ? Container()
                                : packList[index].rsvpState != rsvpYes.value
                                    ? Container()
                                    : ((packList[index].attendenceState <=
                                                attendenceNo.value) &&
                                            (packList[index].requestedAttendenceState <=
                                                attendenceNo.value))
                                        ? Image.asset('images/icons/dollar_sign_icon.png',
                                            height: 24.0,
                                            width: 24.0,
                                            color: Colors.transparent)
                                        : packList[index].isPaid == isPaidNo.value
                                            ? Image.asset(
                                                'images/icons/dollar_sign_icon.png',
                                                height: 24.0,
                                                width: 24.0,
                                                color: Colors.red)
                                            : packList[index].isPaid == isPaidYes.value
                                                ? Image.asset(
                                                    'images/icons/payment_type_${packList[index].paymentType}.png',
                                                    height: 24.0,
                                                    width: 24.0,
                                                    color: Colors.green)
                                                : Container()

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
  }
}

class PackListView extends StatelessWidget {
  const PackListView({
    Key key,
    @required this.packList,
    @required this.packScopedModel,
    @required this.payScopedModel,
    @required this.futureRun,
  }) : super(key: key);

  final List<PackModel> packList;
  final PackScopedModel packScopedModel;
  final PayScopedModel payScopedModel;
  final FutureRun futureRun;

  Widget buildRsvpAndPaymentSnackbar(
      BuildContext context, int index, PackScopedModel _packScopedModel) {
    final snackbar = PaymentSnackBar(
      context: context,
      index: index,
      futureRun: futureRun,
      packScopedModel: packScopedModel,
      payScopedModel: payScopedModel,
      packList: packList,
    );

    return snackbar;
  }

  bool checkSpecialRun(int runCount)
  {
    bool result = false;
    if (runCount == 1) result = true;
    if (runCount == 5) result = true;
    if (runCount == 10) result = true;
    if ((runCount % 25 == 0) && (runCount > 0)) result = true;
    if (runCount % 100 == 69) result = true;
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
        separatorBuilder: (context, index) => Divider(
              height: 1.0,
              color: Colors.black45,
            ),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: packList?.length ?? 0,
        itemBuilder: (BuildContext context, int index) {
          return packList.isEmpty
              ? new Container(
                  color: Colors.grey[300],
                  width: 70.0,
                  height: 70.0,
                  child: new Padding(
                      padding: const EdgeInsets.all(5.0),
                      child:
                          new Center(child: new CircularProgressIndicator())),
                )
              : GestureDetector(
                  onTap: () {
                    final snackBar = buildRsvpAndPaymentSnackbar(
                        context, index, packScopedModel);

                    Scaffold.of(context).removeCurrentSnackBar(
                        reason: SnackBarClosedReason.hide);
                    Scaffold.of(context).showSnackBar(snackBar);
                  },
                  child: Stack(
                    children: <Widget>[
                      packList[index].photo.startsWith('http')
                          ? CachedNetworkImage(
                              imageUrl: packList[index].photo,
                              //placeholder: const CircularProgressIndicator(),
                              //errorWidget: const Icon(Icons.error),
                              placeholder: (context, url) => const CircularProgressIndicator(),
                              errorWidget: (context, url, error) => const Icon(Icons.error),
                              //fadeOutDuration:  Duration(seconds: 1),
                              fadeInDuration: Duration(milliseconds: 0),
                              width: 70.0,
                              height: 70.0,
                              fit: BoxFit.fill)
                          : packList[index].photo.startsWith('bundle')
                              ? Image(
                                  width: 70.0,
                                  height: 70.0,
                                  fit: BoxFit.fill,
                                  image: AssetImage('images/avatars/' +
                                      packList[index]
                                          .photo
                                          .toLowerCase()
                                          .replaceFirst('bundle://', '') +
                                      '.png'),
                                )
                              : Image(
                                  width: 70.0,
                                  height: 70.0,
                                  fit: BoxFit.fill,
                                  image:
                                      AssetImage('images/avatars/avatar-2.png'),
                                ),

                      Positioned(
                        left: 77.0,
                        top: 3.0,
                        child: Text(packList[index].displayName,
                            style: const TextStyle(
                                fontFamily: 'AvenirNextCondensedMedium',
                                fontStyle: FontStyle.normal,
                                fontSize: 25.0,
                                height: 1.0)),
                      ),
                        Positioned(
                        right: 3.0,
                        bottom: 0.0,
                        child: packList[index].userRunCount < 1 ? Text('') :
                        
                        Text(packList[index].userRunCount.toString() + (packList[index].userRunCount == 1 ? ' Run' : ' Runs'),
                            style: TextStyle(
                                fontFamily: checkSpecialRun(packList[index].userRunCount) == true ? 'AvenirNextDemiBold' : 'AvenirNext',
                                fontStyle: FontStyle.normal,
                                fontSize: 25.0,
                                height: 1.0,
                                color: checkSpecialRun(packList[index].userRunCount) == true ? Colors.red[700]: Colors.black,
                                )),
                      ),
                     
                      Positioned(
                        left: 75.0,
                        bottom: 3.0,
                        child: CircleAvatar(
                          backgroundColor: packList[index].rsvpState == 0
                              ? Colors.transparent
                              : packList[index].rsvpState == -1
                                  ? Colors.blue
                                  : Colors.white,
                          radius: 14.0,
                        ),
                      ),
                      Positioned(
                        left: 77.0,
                        bottom: packList[index].rsvpState <= 0
                            ? 4.5
                            : packList[index].isHare == 1 ? 5.0 : 5.5,
                        child: packList[index].rsvpState <= 0
                            ? CircleAvatar(
                                backgroundColor: Colors.transparent,
                                radius: 12.0,
                              )
                            : packList[index].rsvpState == rsvpNo.value
                                ? Icon(FontAwesomeIcons.solidTimesCircle,
                                    color: Colors.red, size: 24.0)
                                : packList[index].rsvpState == rsvpMaybe.value
                                    ? Icon(FontAwesomeIcons.solidQuestionCircle,
                                        color: Colors.orange, size: 24.0)
                                    : packList[index].isHare == 0
                                        ? Icon(
                                            FontAwesomeIcons.solidCheckCircle,
                                            color: Colors.green,
                                            size: 24.0)
                                        : Image.asset(
                                            'images/icons/hare_icon.png',
                                            color: Colors.deepPurple,
                                            height: 24.0,
                                            width: 24.0),

                        // AssetImage(
                        //     'images/icons/hare_icon.png'),
                      ),

                      ScopedModelDescendant<PayScopedModel>(builder:
                          (BuildContext context, Widget child,
                              PayScopedModel model) {
                        return Positioned(
                          left: 115.0,
                          bottom: 3.0,
                          child: packList[index].attendenceState <
                                  attendenceAtHash.value
                              ? Container()
                              : packList[index].rsvpState != rsvpYes.value
                                  ? Container()
                                  : CircleAvatar(
                                      backgroundColor:
                                          packList[index].attendenceState == 0
                                              ? Colors.transparent
                                              : packList[index].isPaid == -1
                                                  ? Colors.blue
                                                  : Colors.white,
                                      radius: 14.0,
                                    ),
                        );
                      }),
                      ScopedModelDescendant<PayScopedModel>(
                        builder: (BuildContext context, Widget child,
                            PayScopedModel model) {
                          return Positioned(
                              left: 117.0,
                              bottom: packList[index].attendenceState < -1
                                  ? 4.5
                                  : 5.5,
                              child: packList[index].attendenceState < attendenceAtHash.value
                                  ? Container()
                                  : packList[index].rsvpState != rsvpYes.value
                                      ? Container()
                                      : ((packList[index].attendenceState <= attendenceNo.value) &&
                                              (packList[index].requestedAttendenceState <=
                                                  attendenceNo.value))
                                          ? Image.asset(
                                              'images/icons/dollar_sign_icon.png',
                                              height: 24.0,
                                              width: 24.0,
                                              color: Colors.transparent)
                                          : packList[index].isPaid == isPaidNo.value
                                              ? Image.asset(
                                                  'images/icons/dollar_sign_icon.png',
                                                  height: 24.0,
                                                  width: 24.0,
                                                  color: Colors.red)
                                              : packList[index].isPaid == isPaidYes.value
                                                  ? Image.asset(
                                                      'images/icons/payment_type_${packList[index].paymentType}.png',
                                                      height: 24.0,
                                                      width: 24.0,
                                                      color: Colors.green)
                                                  : Container()

                              // AssetImage(
                              //     'images/icons/hare_icon.png'),
                              );
                        },
                      ),

                      Positioned(
                        left: 155.0,
                        bottom: 3.0,
                        child: packList[index].rsvpState != rsvpYes.value
                            ? Container()
                            : CircleAvatar(
                                backgroundColor:
                                    packList[index].attendenceState == 0
                                        ? Colors.transparent
                                        : packList[index].attendenceState == -1
                                            ? Colors.blue
                                            : Colors.white,
                                radius: 14.0,
                              ),
                      ),
                      Positioned(
                        left: 157.0,
                        bottom:
                            packList[index].attendenceState <= 0 ? 4.5 : 5.5,
                        child: packList[index].rsvpState != rsvpYes.value
                            ? Container()
                            : packList[index].attendenceState ==
                                    attendenceNo.value
                                ? Image.asset(
                                    'images/icons/not_at_hash_icon.png',
                                    height: 24.0,
                                    width: 24.0,
                                    color: Colors.red[700])
                                : packList[index].attendenceState ==
                                        attendenceAtHash.value
                                    ? Image.asset(
                                        'images/icons/runner_icon.png',
                                        height: 24.0,
                                        width: 24.0,
                                        color: Colors.red)
                                    : packList[index].attendenceState >=
                                            attendenceOnIn.value
                                        ? Image.asset(
                                            'images/icons/beer_icon.png',
                                            height: 24.0,
                                            width: 24.0,
                                            color: Colors.green)
                                        : Image.asset(
                                            'images/icons/beer_icon.png',
                                            height: 24.0,
                                            width: 24.0,
                                            color: Colors.transparent),
                      ),

                      // Payment icons
                    ],
                  ),
                );
        });
  }
}
