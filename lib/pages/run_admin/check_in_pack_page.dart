import 'dart:core';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:scoped_model/scoped_model.dart';

import 'package:harrier_central/data_models/future_run_model.dart';
import 'package:harrier_central/data_models/process_qr_scan_for_checkin_model.dart';
import 'package:harrier_central/data_models/user_model.dart';
import 'package:harrier_central/pages/init/choose_profile_image.dart';
import 'package:harrier_central/pages/kennel_admin/add_member_page.dart';
import 'package:harrier_central/services/pack_scoped_model.dart';
import 'package:harrier_central/services/pay_for_event_service.dart';
import 'package:harrier_central/services/pay_scoped_model.dart';
import 'package:harrier_central/util/enums.dart';
import 'package:harrier_central/util/styles.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/widgets/payment_snackbar.dart';

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

  List<UserModel> packList;

  num snackBarButtonSize = 35.0;

  Future<void> _reloadPack(bool showReloadingIndicator) async {
    _packScopedModel
        .getpackFromBackend(
            widget.futureRun.eventId, showReloadingIndicator, true)
        .then((List<UserModel> _thePack) {
      packList = _thePack;
      setState(() {});
    });

    if (showReloadingIndicator) setState(() {});
  }

  void getPack(bool forceRefresh) {
    if ((packList == null) || forceRefresh) {
      _packScopedModel
          .getpackFromBackend(widget.futureRun.eventId, true, false)
          .then((List<UserModel> _thePack) {
        packList = _thePack;
        setState(() {});
      });
    }
  }

  void showVirginVisitorPopup() {
    // _packScopedModel
    //     .joinEventAsVisitor(
    //         'Amy', EnumVirginVisitor.virgin, widget.futureRun.eventId)
    //     .then((JoinEventModel result) {
    //   _reloadPack(false);
    // });

    AddVisitorVirginPopup addVirginVisitorPopup = AddVisitorVirginPopup();

    Future<Map<String, String>> dlg = showDialog<Map<String, String>>(
        context: context,
        barrierDismissible: false, // user must tap button!
        builder: (BuildContext context) {
          return addVirginVisitorPopup;
        });

    dlg.then((Map<String, String> x) {
      String name = x['name'];
      String type = x['type'];
      String email = x['email'] ?? '';
      String phoneNumber = x['phone'] ?? '';

      EnumVirginVisitor evv = EnumVirginVisitor.virgin;
      if (type == EnumVirginVisitor.visitor.toString()) {
        evv = EnumVirginVisitor.visitor;
      }

      if (type != 'cancel') {
        _packScopedModel
            .joinEventAsVisitor(
                name, email, phoneNumber, evv, widget.futureRun.eventId)
            .then((UserModel result) {
          _packScopedModel.addEditUser(result);
          _packScopedModel.sortPackList();
          packList = _packScopedModel.packList;

          _packScopedModel.forceRefresh();
          //_reloadPack(false);
        });
      }
    });

    // dlg.whenComplete(action)
  }

  @override
  Widget build(BuildContext topContext) {
    getPack(false);
    return ScopedModel<PackScopedModel>(
      model: _packScopedModel,
      child: ScopedModel<PayScopedModel>(
        model: _payScopedModel,
        child: Scaffold(
          floatingActionButton: SpeedDial(
            // both default to 16
            marginRight: 18,
            marginBottom: 70,
            animatedIcon: AnimatedIcons.menu_close,
            animatedIconTheme: IconThemeData(size: 22.0),
            // this is ignored if animatedIcon is non null
            // child: Icon(Icons.add),
            visible: true,
            curve: Curves.bounceIn,
            overlayColor: Colors.black,
            overlayOpacity: 0.5,
            onOpen: () => print('OPENING DIAL'),
            onClose: () => print('DIAL CLOSED'),
            tooltip: 'Speed Dial',
            heroTag: 'speed-dial-hero-tag',
            backgroundColor: Theme.of(context).accentColor,
            foregroundColor: Colors.white,
            elevation: 8.0,
            shape: CircleBorder(),
            children: [
              SpeedDialChild(
                child: Icon(Icons.filter_list),
                backgroundColor: Colors.green,
                label: 'Filter List',
                labelStyle: TextStyle(fontSize: 18.0),
                onTap: () => print('THIRD CHILD'),
              ),
              SpeedDialChild(
                child: Icon(FontAwesomeIcons.beer),
                backgroundColor: Colors.green,
                label: 'Scan: On In',
                labelStyle: TextStyle(fontSize: 18.0),
                onTap: () => print('FIRST CHILD'),
              ),
              SpeedDialChild(
                child: Icon(Icons.directions_run),
                backgroundColor: Colors.red,
                label: 'Scan: At Hash',
                labelStyle: TextStyle(fontSize: 18.0),
                onTap: () => print('SECOND CHILD'),
              ),
              SpeedDialChild(
                child: Icon(Icons.person_add),
                backgroundColor: Colors.blue,
                label: 'Add Member',
                labelStyle: TextStyle(fontSize: 18.0),
                onTap: () => Navigator.push<String>(
                      context,
                      MaterialPageRoute<String>(
                        builder: (context) => ChooseProfileImage(
                              false,
                              // kennelId: widget.futureRun.kennelId,
                              // eventId: widget.futureRun.eventId,
                              // attendenceState: attendenceAtHash,
                            ),
                      ),
                    ).then<dynamic>((String profileImageUrl) {
                      if (profileImageUrl.isEmpty) {
                      } else {
                        Navigator.push<UserModel>(
                          context,
                          MaterialPageRoute<UserModel>(
                            builder: (context) => AddMemberPage(
                                kennelId: widget.futureRun.kennelId,
                                eventId: widget.futureRun.eventId,
                                attendenceState: attendenceAtHash,
                                profileImageUrl: profileImageUrl),
                          ),
                        ).then<dynamic>((UserModel user) {
                          _packScopedModel.addEditUser(user);
                          _packScopedModel.sortPackList();
                          _packScopedModel.forceRefresh();
                        });
                      }
                    }),
              ),
              SpeedDialChild(
                child: Icon(FontAwesomeIcons.solidHeart),
                backgroundColor: Colors.blue,
                label: 'Add Virgin / Visitor',
                labelStyle: TextStyle(fontSize: 18.0),
                onTap: () => showVirginVisitorPopup(),
              )
            ],
          ),
          appBar: AppBar(
            centerTitle: true,
            backgroundColor: ThemeColors.appBarBackground,
            title: Text(
              '${widget.futureRun.eventName} Check In',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
          body: Builder(
            builder: (scaffoldContext) => Stack(children: <Widget>[
                  (packList == null || packList.isEmpty)
                      ? Center(
                          child: Container(
                              height: 50,
                              width: 50,
                              child: CircularProgressIndicator()))
                      : Positioned(
                          top: 0.0,
                          right: 0.0,
                          left: 0.0,
                          child: Container(
                            key: packListBox,
                            height: MediaQuery.of(context).size.height,
                            child: RefreshIndicator(
                              onRefresh: () => _reloadPack(true),
                              child: ScopedModelDescendant<PackScopedModel>(
                                builder: (BuildContext context, Widget child,
                                    PackScopedModel model) {
                                  print(DateTime.now()
                                          .millisecondsSinceEpoch
                                          .toString() +
                                      ' pack list update, #items = ' +
                                      packList.length.toString());
                                  return PackListView(
                                      packList: packList,
                                      packScopedModel: _packScopedModel,
                                      payScopedModel: _payScopedModel,
                                      futureRun: widget.futureRun);
                                },
                              ),
                            ),
                          ),
                        ),
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
        (UserModel packMember) =>
            packMember.hasherId.toUpperCase() ==
            result.targetUserId.toUpperCase(),
        orElse: () => null);

    if (packItem == null) {
      packItem = UserModel(
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

class PackListView extends StatelessWidget {
  const PackListView({
    Key key,
    @required this.packList,
    @required this.packScopedModel,
    @required this.payScopedModel,
    @required this.futureRun,
  }) : super(key: key);

  final List<UserModel> packList;
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

  bool checkSpecialRun(int runCount) {
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
    print(DateTime.now().millisecondsSinceEpoch.toString());
    return ListView.separated(
        separatorBuilder: (context, index) => Divider(
              height: 1.0,
              color: Colors.black45,
            ),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: packList?.length ?? 0,
        itemBuilder: (BuildContext context, int index) {
          return ((packList == null) || (packList.isEmpty))
              ? Container(
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
                              placeholder: (context, url) => Container(
                                  child: Center(
                                      child: Container(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 3.0,
                                          ))),
                                  height: 70.0,
                                  width: 70.0),
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.error),
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
                        child: packList[index].userRunCount < 1
                            ? Text('')
                            : Text(
                                packList[index].userRunCount.toString() +
                                    (packList[index].userRunCount == 1
                                        ? ' Run'
                                        : ' Runs'),
                                style: TextStyle(
                                  fontFamily: checkSpecialRun(
                                              packList[index].userRunCount) ==
                                          true
                                      ? 'AvenirNextDemiBold'
                                      : 'AvenirNext',
                                  fontStyle: FontStyle.normal,
                                  fontSize: 25.0,
                                  height: 1.0,
                                  color: checkSpecialRun(
                                              packList[index].userRunCount) ==
                                          true
                                      ? Colors.red[700]
                                      : Colors.black,
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
                        return packList.length == 0
                            ? Positioned(
                                top: 0,
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Text('No pack members loaded'))
                            : Positioned(
                                left: 115.0,
                                bottom: 3.0,
                                child: packList[index].attendenceState <
                                        attendenceAtHash.value
                                    ? Container()
                                    : packList[index].rsvpState != rsvpYes.value
                                        ? Container()
                                        : CircleAvatar(
                                            backgroundColor: packList[index]
                                                        .attendenceState ==
                                                    0
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
                          return packList.length == 0
                              ? Positioned(
                                  top: 0,
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Text('No pack members loaded'))
                              : Positioned(
                                  left: 117.0,
                                  bottom: packList[index].attendenceState < -1
                                      ? 4.5
                                      : 5.5,
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
                                                  ? Image.asset('images/icons/dollar_sign_icon.png',
                                                      height: 24.0,
                                                      width: 24.0,
                                                      color: Colors.red)
                                                  : packList[index].isPaid == isPaidYes.value
                                                      ? Image.asset('images/icons/payment_type_${packList[index].paymentType}.png',
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

//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//

class AddVisitorVirginPopup extends StatefulWidget {
  AddVisitorVirginPopup();

  _AddVisitorVirginPopupState createState() => _AddVisitorVirginPopupState();
}

class _AddVisitorVirginPopupState extends State<AddVisitorVirginPopup> {
  final FocusNode myFocusNodeFirstName = FocusNode();

  TextEditingController nameTextController = TextEditingController();
  TextEditingController emailTextController = TextEditingController();
  TextEditingController phoneTextController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Visitor or Virgin'),
      content: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
        TextField(
          autofocus: true,
          focusNode: myFocusNodeFirstName,
          controller: nameTextController,
          keyboardType: TextInputType.text,
          style: const TextStyle(
              fontFamily: 'WorkSansSemiBold',
              fontSize: 16.0,
              color: Colors.black),
          decoration: const InputDecoration(
            //border: InputBorder.none,
            icon: Icon(
              FontAwesomeIcons.moneyBillWave,
              color: Colors.white,
            ),
            hintText: 'Just Julie',
            hintStyle:
                TextStyle(fontFamily: 'WorkSansSemiBold', fontSize: 16.0),
          ),
        ),
        TextField(
          autofocus: true,
          //focusNode: myFocusNodeFirstName,
          controller: emailTextController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(
              fontFamily: 'WorkSansSemiBold',
              fontSize: 16.0,
              color: Colors.black),
          decoration: const InputDecoration(
            //border: InputBorder.none,
            icon: Icon(
              FontAwesomeIcons.moneyBillWave,
              color: Colors.white,
            ),
            hintText: '(email - optional)',
            hintStyle:
                TextStyle(fontFamily: 'WorkSansSemiBold', fontSize: 16.0),
          ),
        ),
        TextField(
          autofocus: true,
          //focusNode: myFocusNodeFirstName,
          controller: phoneTextController,
          keyboardType: TextInputType.phone,
          style: const TextStyle(
              fontFamily: 'WorkSansSemiBold',
              fontSize: 16.0,
              color: Colors.black),
          decoration: const InputDecoration(
            //border: InputBorder.none,
            icon: Icon(
              FontAwesomeIcons.moneyBillWave,
              color: Colors.white,
            ),
            hintText: '(phone # - optional)',
            hintStyle:
                TextStyle(fontFamily: 'WorkSansSemiBold', fontSize: 16.0),
          ),
        ),
      ]),
      actions: <Widget>[
        FlatButton(
          color: Colors.red,
          child: Text("Cancel"),
          textColor: Colors.white,
          onPressed: () {
            Navigator.of(context)
                .pop(<String, String>{'type': 'cancel', 'amount': ''});
          },
        ),

        FlatButton(
            color: Colors.blue,
            child: Text("Add Visitor"),
            textColor: Colors.white,
            onPressed: () {
              Navigator.of(context).pop(<String, String>{
                'type': EnumVirginVisitor.visitor.toString(),
                'name': nameTextController.text,
                'email': emailTextController.text,
                'phone': phoneTextController.text,
              });
            }),

        FlatButton(
            color: Colors.blue,
            child: Text("Add Virgin"),
            textColor: Colors.white,
            onPressed: () {
              Navigator.of(context).pop(<String, String>{
                'type': EnumVirginVisitor.virgin.toString(),
                'name': nameTextController.text,
                'email': emailTextController.text,
                'phone': phoneTextController.text,
              });
            }),
        // ),
      ],
    );
  }
}

// KEEP THIS CODE
// KEEP THIS CODE
// KEEP THIS CODE
// KEEP THIS CODE

// class PackGridView extends StatelessWidget {
//   const PackGridView({
//     Key key,
//     @required this.packList,
//     @required this.packScopedModel,
//     @required this.payScopedModel,
//     @required this.futureRun,
//   }) : super(key: key);

//   final List<PackModel> packList;
//   final PackScopedModel packScopedModel;
//   final PayScopedModel payScopedModel;
//   final FutureRun futureRun;

//   Widget buildRsvpAndPaymentSnackbar(
//       BuildContext context, int index, PackScopedModel _packScopedModel) {
//     final snackbar = PaymentSnackBar(
//       context: context,
//       index: index,
//       futureRun: futureRun,
//       packScopedModel: packScopedModel,
//       payScopedModel: payScopedModel,
//       packList: packList,
//     );

//     return snackbar;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return StaggeredGridView.countBuilder(
//       crossAxisCount: 3,
//       itemCount: packList?.length ?? 0,
//       addRepaintBoundaries: false,
//       itemBuilder: (BuildContext context, int index) {
//         return packList.isEmpty
//             ? new Container(
//                 color: Colors.grey[300],
//                 width: 70.0,
//                 height: 70.0,
//                 child: new Padding(
//                     padding: const EdgeInsets.all(5.0),
//                     child: new Center(child: new CircularProgressIndicator())),
//               )
//             : GestureDetector(
//                 onTap: () {
//                   final snackBar = buildRsvpAndPaymentSnackbar(
//                       context, index, packScopedModel);

//                   Scaffold.of(context)
//                       .removeCurrentSnackBar(reason: SnackBarClosedReason.hide);
//                   Scaffold.of(context).showSnackBar(snackBar);
//                 },
//                 child: Stack(
//                   children: <Widget>[
//                     packList[index].photo.startsWith('http')
//                         ? CachedNetworkImage(
//                             imageUrl: packList[index].photo,
//                             //placeholder: CircularProgressIndicator(),
//                             //errorWidget: Icon(Icons.error),
//                             placeholder: (context, url) => const CircularProgressIndicator(),
//                             errorWidget: (context, url, error) => const Icon(Icons.error),
//                             //fadeOutDuration:  Duration(seconds: 1),
//                             fadeInDuration: Duration(milliseconds: 0),
//                             width: 300.0,
//                             height: 300.0,
//                             fit: BoxFit.fill)
//                         : packList[index].photo.startsWith('bundle')
//                             ? Image(
//                                 width: 300.0,
//                                 height: 300.0,
//                                 fit: BoxFit.fill,
//                                 image: AssetImage('images/avatars/' +
//                                     packList[index]
//                                         .photo
//                                         .toLowerCase()
//                                         .replaceFirst('bundle://', '') +
//                                     '.png'),
//                               )
//                             : Image(
//                                 width: 300.0,
//                                 height: 300.0,
//                                 fit: BoxFit.fill,
//                                 image:
//                                     AssetImage('images/avatars/avatar-2.png'),
//                               ),
//                     Positioned(
//                       left: 3.0,
//                       bottom: 1.0,
//                       child: CircleAvatar(
//                         backgroundColor: packList[index].rsvpState == 0
//                             ? Colors.transparent
//                             : packList[index].rsvpState == -1
//                                 ? Colors.blue
//                                 : Colors.white,
//                         radius: 14.0,
//                       ),
//                     ),
//                     Positioned(
//                       left: 5.0,
//                       bottom: packList[index].rsvpState <= 0
//                           ? 2.5
//                           : packList[index].isHare == 1 ? 3.0 : 3.5,
//                       child: packList[index].rsvpState <= 0
//                           ? CircleAvatar(
//                               backgroundColor: Colors.transparent,
//                               radius: 12.0,
//                             )
//                           : packList[index].rsvpState == rsvpNo.value
//                               ? Icon(FontAwesomeIcons.solidTimesCircle,
//                                   color: Colors.red, size: 24.0)
//                               : packList[index].rsvpState == rsvpMaybe.value
//                                   ? Icon(FontAwesomeIcons.solidQuestionCircle,
//                                       color: Colors.orange, size: 24.0)
//                                   : packList[index].isHare == 0
//                                       ? Icon(FontAwesomeIcons.solidCheckCircle,
//                                           color: Colors.green, size: 24.0)
//                                       : Image.asset(
//                                           'images/icons/hare_icon.png',
//                                           color: Colors.deepPurple,
//                                           height: 24.0,
//                                           width: 24.0),

//                       // AssetImage(
//                       //     'images/icons/hare_icon.png'),
//                     ),
//                     Positioned(
//                       right: 3.0,
//                       bottom: 1.0,
//                       child: packList[index].rsvpState != rsvpYes.value
//                           ? Container()
//                           : CircleAvatar(
//                               backgroundColor:
//                                   packList[index].attendenceState == 0
//                                       ? Colors.transparent
//                                       : packList[index].attendenceState == -1
//                                           ? Colors.blue
//                                           : Colors.white,
//                               radius: 14.0,
//                             ),
//                     ),
//                     Positioned(
//                       right: 5.0,
//                       bottom: packList[index].attendenceState <= 0 ? 2.5 : 3.5,
//                       child: packList[index].rsvpState != rsvpYes.value
//                           ? Container()
//                           : packList[index].attendenceState ==
//                                   attendenceNo.value
//                               ? Image.asset('images/icons/not_at_hash_icon.png',
//                                   height: 24.0,
//                                   width: 24.0,
//                                   color: Colors.red[700])
//                               : packList[index].attendenceState ==
//                                       attendenceAtHash.value
//                                   ? Image.asset('images/icons/runner_icon.png',
//                                       height: 24.0,
//                                       width: 24.0,
//                                       color: Colors.red)
//                                   : packList[index].attendenceState >=
//                                           attendenceOnIn.value
//                                       ? Image.asset(
//                                           'images/icons/beer_icon.png',
//                                           height: 24.0,
//                                           width: 24.0,
//                                           color: Colors.green)
//                                       : Image.asset(
//                                           'images/icons/beer_icon.png',
//                                           height: 24.0,
//                                           width: 24.0,
//                                           color: Colors.transparent),
//                     ),

//                     // Payment icons

//                     ScopedModelDescendant<PayScopedModel>(builder:
//                         (BuildContext context, Widget child,
//                             PayScopedModel model) {
//                       return Positioned(
//                         right: 0.0,
//                         left: 0.0,
//                         bottom: 1.0,
//                         child: packList[index].attendenceState <
//                                 attendenceAtHash.value
//                             ? Container()
//                             : packList[index].rsvpState != rsvpYes.value
//                                 ? Container()
//                                 : CircleAvatar(
//                                     backgroundColor:
//                                         packList[index].attendenceState == 0
//                                             ? Colors.transparent
//                                             : packList[index].isPaid == -1
//                                                 ? Colors.blue
//                                                 : Colors.white,
//                                     radius: 14.0,
//                                   ),
//                       );
//                     }),

//                     ScopedModelDescendant<PayScopedModel>(
//                       builder: (BuildContext context, Widget child,
//                           PayScopedModel model) {
//                         return Positioned(
//                             right: 0.0,
//                             left: 0.0,
//                             bottom: packList[index].attendenceState < -1
//                                 ? 2.5
//                                 : 3.5,
//                             child: packList[index].attendenceState < attendenceAtHash.value
//                                 ? Container()
//                                 : packList[index].rsvpState != rsvpYes.value
//                                     ? Container()
//                                     : ((packList[index].attendenceState <=
//                                                 attendenceNo.value) &&
//                                             (packList[index].requestedAttendenceState <=
//                                                 attendenceNo.value))
//                                         ? Image.asset('images/icons/dollar_sign_icon.png',
//                                             height: 24.0,
//                                             width: 24.0,
//                                             color: Colors.transparent)
//                                         : packList[index].isPaid == isPaidNo.value
//                                             ? Image.asset(
//                                                 'images/icons/dollar_sign_icon.png',
//                                                 height: 24.0,
//                                                 width: 24.0,
//                                                 color: Colors.red)
//                                             : packList[index].isPaid == isPaidYes.value
//                                                 ? Image.asset(
//                                                     'images/icons/payment_type_${packList[index].paymentType}.png',
//                                                     height: 24.0,
//                                                     width: 24.0,
//                                                     color: Colors.green)
//                                                 : Container()

//                             // AssetImage(
//                             //     'images/icons/hare_icon.png'),
//                             );
//                       },
//                     ),
//                   ],
//                 )); //TODO: Replace this with another avatar for missing image
//       },
//       staggeredTileBuilder: (int index) {
//         return packList[index].isHare == 0
//             ? new StaggeredTile.count(1, 1)
//             : new StaggeredTile.count(2, 2);
//       },
//       mainAxisSpacing: 8.0,
//       crossAxisSpacing: 8.0,
//     );
//   }
// }
