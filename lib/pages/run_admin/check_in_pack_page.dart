import 'dart:core';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:scoped_model/scoped_model.dart';

import 'package:harrier_central/data_models/planned_run_model.dart';
import 'package:harrier_central/data_models/pay_for_event_model.dart';
import 'package:harrier_central/data_models/process_qr_scan_for_checkin_model.dart';
import 'package:harrier_central/data_models/user_model.dart';
import 'package:harrier_central/services/pack_scoped_model.dart';
import 'package:harrier_central/services/pay_scoped_model.dart';
import 'package:harrier_central/util/enums.dart';
import 'package:harrier_central/util/styles.dart';
import 'package:harrier_central/util/utilities.dart';
import 'package:harrier_central/widgets/new_user.dart';
import 'package:harrier_central/widgets/payment_snackbar.dart';
import 'package:harrier_central/pages/run_admin/find_hasher_page.dart';
import 'package:harrier_central/data_models/all_hasher_model.dart';

class CheckInPackPage extends StatefulWidget {
  const CheckInPackPage({
    @required this.futureRun,
  });

  final PlannedRun futureRun;

  @override
  State<CheckInPackPage> createState() {
    return CheckInPackPageState();
  }
}

class CheckInPackPageState extends State<CheckInPackPage> {
  final PackScopedModel _packScopedModel = PackScopedModel();
  final PayScopedModel _payScopedModel = PayScopedModel();

  GlobalKey packListBox = GlobalKey();

  List<UserModel> packList;

  num snackBarButtonSize = 35.0;

  Future<void> _reloadPack(bool showReloadingIndicator) async {
    _packScopedModel
        .getpackFromBackend(
            widget.futureRun.eventId, showReloadingIndicator, true)
        .then((List<UserModel> _thePack) {
      packList = _thePack;

      setState(() {
        print('_reloadPack() -  = ${DateTime.now().millisecondsSinceEpoch}');
      });
    });

    if (showReloadingIndicator) {
      setState(() {});
    }
  }

  void getPack(bool forceRefresh) {
    if ((packList == null) || forceRefresh) {
      _packScopedModel
          .getpackFromBackend(widget.futureRun.eventId, true, false)
          .then((List<UserModel> _thePack) {
        packList = _thePack;
        setState(() {
          print('getPack() = ${DateTime.now().millisecondsSinceEpoch}');
        });
      });
    }
  }

  void findHasher(PackScopedModel packScopedModel) {
    Navigator.push<AllHasherListModel>(
      context,
      MaterialPageRoute<AllHasherListModel>(
        settings: const RouteSettings(),
        builder: (BuildContext context) {
          return const FindHasherPage();
        },
      ),
    ).then((AllHasherListModel hasher) {
      if ((hasher != null) && (hasher.userId != null))
      {
      packScopedModel.joinEvent(widget.futureRun.eventId, rsvpYes.value,
          isHareNo.value, attendenceAtHash.value, hasher.userId);
      }
    });
  }

  void showVirginVisitorPopup() {
    // _packScopedModel
    //     .joinEventAsVisitor(
    //         'Amy', EnumVirginVisitor.virgin, widget.futureRun.eventId)
    //     .then((JoinEventModel result) {
    //   _reloadPack(false);
    // });

    const AddVisitorVirginPopup addVirginVisitorPopup = AddVisitorVirginPopup();

    final Future<Map<String, String>> dlg = showDialog<Map<String, String>>(
        context: context,
        barrierDismissible: false, // user must tap button!
        builder: (BuildContext context) {
          return addVirginVisitorPopup;
        });

    dlg.then((Map<String, String> x) {
      final String name = x['name'];
      final String type = x['type'];
      final String email = x['email'] ?? '';
      final String phoneNumber = x['phone'] ?? '';

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
          packList = _packScopedModel.filteredPackList;

          _packScopedModel.forceRefresh();
          //_reloadPack(false);
        });
      }
    });

    // dlg.whenComplete(action)
  }

  GlobalKey<ScaffoldState> scaffoldKey;

  final FocusNode searchFocusNode = FocusNode();
  TextEditingController searchController = TextEditingController();

  AppBar getAppBar(String title) {
    return AppBar(
      centerTitle: true,
      backgroundColor: themeAppBarBackground,
      title: Text(
        '$title Check In',
        style: const TextStyle(
          color: Colors.white,
        ),
      ),
    );
  }

  // void _onSearchTextChanged() {
  //   setState(() {
  //     print('onSearchTextChanged = ${DateTime.now().millisecondsSinceEpoch}');
  //   });
  // }

  Container searchBar(PackScopedModel model, num width) {
    return Container(
      // color: Colors.red,
      padding: const EdgeInsets.only(left: 10, top: 10),
      width: width,
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: TextField(
              onChanged: (String text) {
                //setState(() {
                model.filterPackList(text);
                model.forceRefresh();
                packList = model.filteredPackList;
                // });
              },
              focusNode: searchFocusNode,
              controller: searchController,
              keyboardType: TextInputType.text,
              style: const TextStyle(
                  fontFamily: 'WorkSansSemiBold',
                  fontSize: 16.0,
                  color: Colors.black),
              decoration: const InputDecoration(
                border: InputBorder.none,
                icon: Icon(
                  FontAwesome.search,
                  color: Colors.black,
                ),
                hintText: 'Hash or mortal name',
                hintStyle:
                    TextStyle(fontFamily: 'WorkSansSemiBold', fontSize: 16.0),
              ),
            ),
          ),
          Container(
            width: 40,
            child: FlatButton(
              //color: Colors.red,
              child: const Text('X'),
              textColor: Colors.grey[700],
              onPressed: () {
                searchController.text = '';
                model.filterPackList('');
                model.forceRefresh();
                packList = model.filteredPackList;
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    getPack(false);
    return ScopedModel<PackScopedModel>(
      model: _packScopedModel,
      child: ScopedModel<PayScopedModel>(
        model: _payScopedModel,
        child: Scaffold(
          key: scaffoldKey,
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
            onOpen: () => print('OPENING DIAL'),
            onClose: () => print('DIAL CLOSED'),
            tooltip: 'Speed Dial',
            heroTag: 'speed-dial-hero-tag',
            backgroundColor: Theme.of(context).accentColor,
            foregroundColor: Colors.white,
            elevation: 8.0,
            shape: CircleBorder(),
            children: <SpeedDialChild>[
              SpeedDialChild(
                child: const Icon(Icons.filter_list),
                backgroundColor: Colors.green,
                label: 'Filter List',
                labelStyle: const TextStyle(fontSize: 18.0),
                onTap: () => print('THIRD CHILD'),
              ),
              SpeedDialChild(
                child: const Icon(Ionicons.ios_beer),
                backgroundColor: Colors.green,
                label: 'Scan: On In',
                labelStyle: const TextStyle(fontSize: 18.0),
                onTap: () => print('FIRST CHILD'),
              ),
              SpeedDialChild(
                child: const Icon(Icons.directions_run),
                backgroundColor: Colors.red,
                label: 'Scan: At Hash',
                labelStyle: const TextStyle(fontSize: 18.0),
                onTap: () => print('SECOND CHILD'),
              ),
              SpeedDialChild(
                child: const Icon(Icons.person_add),
                backgroundColor: Colors.blue,
                label: 'Add Member',
                labelStyle: const TextStyle(fontSize: 18.0),
                onTap: () => Navigator.push<UserModel>(
                      context,
                      MaterialPageRoute<UserModel>(
                          builder: (BuildContext context) => NewUserWidget(
                                scaffoldKey: scaffoldKey,
                                isForThisDevice: false,
                                eventId: widget.futureRun.eventId,
                                kennelId: widget.futureRun.kennelId,
                                attendenceState: attendenceAtHash,
                              )),
                    ).then<dynamic>((UserModel user) {
                      if (user != null) {
                        _packScopedModel.addEditUser(user);
                        searchController.text =
                            user.firstName + ' ' + user.lastName;
                        _packScopedModel.filterPackList(
                            user.firstName + ' ' + user.lastName);
                        packList = _packScopedModel.filteredPackList;
                        _packScopedModel.forceRefresh();
                      }
                    }),

                //     ChooseProfileImage(
                //           false,
                //           // kennelId: widget.futureRun.kennelId,
                //           // eventId: widget.futureRun.eventId,
                //           // attendenceState: attendenceAtHash,
                //         ),
                //   ),
                // ).then<dynamic>((String profileImageUrl) {
                //   if (profileImageUrl.isEmpty) {
                //   } else {
                //     Navigator.push<UserModel>(
                //       context,
                //       MaterialPageRoute<UserModel>(
                //         builder: (BuildContext context) => AddMemberPage(
                //             kennelId: widget.futureRun.kennelId,
                //             eventId: widget.futureRun.eventId,
                //             attendenceState: attendenceAtHash,
                //             profileImageUrl: profileImageUrl),
                //       ),
                //     ).then<dynamic>((UserModel user) {
                //       _packScopedModel.addEditUser(user);
                //       _packScopedModel.sortPackList();
                //       _packScopedModel.forceRefresh();
                //     });
                //   }
                // }),
              ),
              SpeedDialChild(
                child: const Icon(FontAwesome.heart),
                backgroundColor: Colors.blue,
                label: 'Add Virgin / Visitor',
                labelStyle: const TextStyle(fontSize: 18.0),
                onTap: () => showVirginVisitorPopup(),
              ),
              SpeedDialChild(
                child: const Icon(MaterialCommunityIcons.account_search),
                backgroundColor: Colors.blue,
                label: 'Find Hasher',
                labelStyle: const TextStyle(fontSize: 18.0),
                onTap: () => findHasher(_packScopedModel),
              )
            ],
          ),
          appBar: getAppBar(widget.futureRun.eventName),
          body: LayoutBuilder(
            builder: (BuildContext scaffoldContext,
                    BoxConstraints constraints) =>
                Stack(children: <Widget>[
                  Positioned(
                      top: 0,
                      child: searchBar(_packScopedModel, constraints.maxWidth)),
                  Positioned(
                    top: searchBar(_packScopedModel, constraints.maxWidth)
                        .constraints
                        .maxHeight,
                    right: 0.0,
                    left: 0.0,
                    child: (packList == null || packList.isEmpty)
                        ? Center(
                            child: Container(
                                height: 50,
                                width: 50,
                                child: const CircularProgressIndicator()))
                        : Container(
                            key: packListBox,
                            height: constraints.maxHeight -
                                searchBar(
                                        _packScopedModel, constraints.maxWidth)
                                    .constraints
                                    .maxHeight,
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
    // final Widget snackBar = buildScanResultSnackbar(
    //     scanContext, _packScopedModel, 'Processing QR Scan');

    // final Future<String> scanAction = BarcodeScanner.scan();
    // scanAction.then((String scanText) {
    //   ProcessQrScanForCheckinService srv = ProcessQrScanForCheckinService();
    //   final Future<ProcessQrScanForCheckinModel> apiCall =
    //       srv.processQrScan(widget.futureRun.eventId, scanText, checkinType, 0);
    //   apiCall.then((ProcessQrScanForCheckinModel result) {
    //     if (result.isPaid == 0) {
    //       PaymentPopup pp = PaymentPopup(
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

    UserModel packItem = packList.firstWhere(
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

    if (isPaid >= 0) {
      packItem.isPaid = isPaid;
    }

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
    final SnackBar snackbar = SnackBar(
      duration: const Duration(seconds: 4),
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

  // Widget buildRsvpAndPaymentSnackbar(
  //     BuildContext context, int index, PackScopedModel _packScopedModel) {
  //   final SnackBar snackbar = PaymentSnackBar(
  //     context: context,
  //     index: index,
  //     futureRun: widget.futureRun,
  //     packScopedModel: _packScopedModel,
  //     payScopedModel: _payScopedModel,
  //     packList: packList,
  //   );

  //   return snackbar;
  // }
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
  final PlannedRun futureRun;

  SnackBar buildRsvpAndPaymentSnackbar(
      BuildContext context, int index, PackScopedModel _packScopedModel) {
    final SnackBar snackbar = PaymentSnackBar(
        context: context,
        index: index,
        futureRun: futureRun,
        packScopedModel: packScopedModel,
        payScopedModel: payScopedModel,
        packList: packList);

    return snackbar;
  }

  Widget listItem(BuildContext context, int index) {
    return GestureDetector(
      onTap: () {
        if (futureRun.mmAuthShowCheckInSnackbar) {
          final SnackBar snackBar =
              buildRsvpAndPaymentSnackbar(context, index, packScopedModel);

          Scaffold.of(context)
              .removeCurrentSnackBar(reason: SnackBarClosedReason.hide);
          Scaffold.of(context).showSnackBar(snackBar);
        }
      },
      child: Container(
        width: MediaQuery.of(context).size.width,
        child: Stack(
          children: <Widget>[
            packList[index].photo.startsWith('http')
                ? CachedNetworkImage(
                    imageUrl: packList[index].photo,
                    // placeholder: (context, url) => Container(
                    //     child: Center(
                    //       child: Container(
                    //         height: 20,
                    //         width: 20,
                    //         child: CircularProgressIndicator(
                    //           strokeWidth: 3.0,
                    //         ),
                    //       ),
                    //     ),
                    //     height: 70.0,
                    //    width: 70.0),
                    errorWidget:
                        (BuildContext context, String url, Object error) =>
                            const Icon(Icons.error),
                    //fadeOutDuration:  Duration(seconds: 1),
                    fadeInDuration: const Duration(milliseconds: 0),
                    width: 70.0,
                    height: 70.0,
                    fit: BoxFit.fill)
                : packList[index].photo.startsWith('bundle')
                    ? Image(
                        width: 70.0,
                        height: 70.0,
                        fit: BoxFit.fill,
                        image: AssetImage(('images/avatars/' +
                                packList[index]
                                    .photo
                                    .toLowerCase()
                                    .replaceFirst('bundle://', '') +
                                '.png')
                            .toLowerCase()),
                      )
                    : Image(
                        width: 70.0,
                        height: 70.0,
                        fit: BoxFit.fill,
                        image: const AssetImage('images/avatars/avatar-2.png'),
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
            // this widget is here to grow the contents of the cell to a size that fills nearly the whole cell
            // in order to give plenty of room for the tap gesture.
            Positioned(
              left: 75,
              top: 0,
              child: Container(
                  width: MediaQuery.of(context).size.width - 80,
                  height: 65,
                  color: Colors.transparent),
            ),
            Positioned(
              right: 3.0,
              bottom: 0.0,
              child: packList[index].userRunCount < 1
                  ? const Text('')
                  : Text(
                      packList[index].userRunCount.toString() +
                          (packList[index].userRunCount == 1
                              ? ' Run'
                              : ' Runs'),
                      style: TextStyle(
                        fontFamily:
                            checkSpecialRun(packList[index].userRunCount) ==
                                    true
                                ? 'AvenirNextDemiBold'
                                : 'AvenirNext',
                        fontStyle: FontStyle.normal,
                        fontSize: 25.0,
                        height: 1.0,
                        color: checkSpecialRun(packList[index].userRunCount) ==
                                true
                            ? Colors.red[700]
                            : Colors.black,
                      )),
            ),

            Positioned(
              left: 75.0,
              bottom: 3.0,
              child: packList[index].rsvpState == -1
                  ? CircleAvatar(
                      backgroundColor: Colors.grey[350],
                      radius: 14.0,
                    )
                  : CircleAvatar(
                      backgroundColor: packList[index].rsvpState == 0
                          ? Colors.grey[350]
                          : Colors.white,
                      radius: 14.0,
                    ),
            ),
            Positioned(
              left: 76.0,
              bottom: packList[index].rsvpState <= 0
                  ? 2.0
                  : packList[index].isHare == 1 ? 5.0 : 3.5,
              child: (packList[index].rsvpState < 0) ||
                      (packList[index].isHare < 0)
                  ? Icon(delayIcon, color: Colors.blue[800])
                  : packList[index].rsvpState == 0
                      ? Container()
                      : packList[index].rsvpState == rsvpNo.value
                          ? const Icon(FontAwesome.times_circle,
                              color: Colors.red, size: 27.0)
                          : packList[index].rsvpState == rsvpMaybe.value
                              ? const Icon(FontAwesome.question_circle,
                                  color: Colors.orange, size: 27.0)
                              : packList[index].isHare == 0
                                  ? const Icon(FontAwesome.check_circle,
                                      color: Colors.green, size: 27.0)
                                  : Image.asset('images/icons/hare_icon.png',
                                      color: Colors.deepPurple,
                                      height: 24.0,
                                      width: 24.0),
            ),

            ScopedModelDescendant<PayScopedModel>(builder:
                (BuildContext context, Widget child, PayScopedModel model) {
              return packList.isEmpty
                  ? const Positioned(
                      top: 0,
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Text('No pack members loaded'))
                  : Positioned(
                      left: 155.0,
                      bottom: 3.0,
                      child: (packList[index].attendenceState <
                                  attendenceAtHash.value) &&
                              (packList[index].requestedAttendenceState <
                                  attendenceAtHash.value)
                          ? CircleAvatar(
                              backgroundColor: Colors.grey[350],
                              radius: 14.0,
                            )
                          : (packList[index].rsvpState != rsvpYes.value) &&
                                  (packList[index].requestedRsvpState !=
                                      rsvpYes.value)
                              ? Container()
                              : packList[index].isPaid == -1
                                  ? Icon(delayIcon, color: Colors.blue[800])
                                  : CircleAvatar(
                                      backgroundColor:
                                          packList[index].attendenceState == 0
                                              ? Colors.transparent
                                              : Colors.white,
                                      radius: 14.0,
                                    ),
                    );
            }),
            ScopedModelDescendant<PayScopedModel>(
              builder:
                  (BuildContext context, Widget child, PayScopedModel model) {
                return packList.isEmpty
                    ? const Positioned(
                        top: 0,
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Text('No pack members loaded'))
                    : Positioned(
                        left: 157.0,
                        bottom:
                            packList[index].attendenceState < -1 ? 4.5 : 5.5,
                        child: (packList[index].attendenceState < attendenceAtHash.value) &&
                                (packList[index].requestedAttendenceState <
                                    attendenceAtHash.value)
                            ? Container()
                            : (packList[index].rsvpState != rsvpYes.value) && (packList[index].requestedRsvpState != rsvpYes.value)
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
                                            ? Image.asset('images/icons/payment_type_${packList[index].paymentType}.png', height: 24.0, width: 24.0, color: Colors.green)
                                            : Container());
              },
            ),

            Positioned(
              left: 115.0,
              bottom: 3.0,
              child: (packList[index].rsvpState != rsvpYes.value) &&
                      (packList[index].requestedRsvpState != rsvpYes.value)
                  ? CircleAvatar(
                      backgroundColor: Colors.grey[350],
                      radius: 14.0,
                    )
                  : packList[index].attendenceState < 0
                      ? Icon(delayIcon, color: Colors.blue[800])
                      : CircleAvatar(
                          backgroundColor: packList[index].attendenceState == 0
                              ? Colors.transparent
                              : Colors.white,
                          radius: 14.0,
                        ),
            ),
            Positioned(
              left: 117.0,
              bottom: packList[index].attendenceState <= 0 ? 4.5 : 5.5,
              child: (packList[index].rsvpState != rsvpYes.value) &&
                      (packList[index].requestedRsvpState != rsvpYes.value)
                  ? Container()
                  : packList[index].attendenceState == attendenceNo.value
                      ? Image.asset('images/icons/not_at_hash_icon.png',
                          height: 24.0, width: 24.0, color: Colors.red[700])
                      : packList[index].attendenceState ==
                              attendenceAtHash.value
                          ? Image.asset('images/icons/runner_icon.png',
                              height: 24.0, width: 24.0, color: Colors.red)
                          : packList[index].attendenceState >=
                                  attendenceOnIn.value
                              ? Image.asset('images/icons/beer_icon.png',
                                  height: 24.0,
                                  width: 24.0,
                                  color: Colors.green)
                              : Container(),
            ),

            // Payment icons
          ],
        ),
      ),
    );
  }

  bool checkSpecialRun(int runCount) {
    bool result = false;
    if (runCount == 1) {
      result = true;
    }
    if (runCount == 5) {
      result = true;
    }
    if (runCount == 10) {
      result = true;
    }
    if ((runCount % 25 == 0) && (runCount > 0)) {
      result = true;
    }
    if (runCount % 100 == 69) {
      result = true;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    print(DateTime.now().millisecondsSinceEpoch.toString());
    return ListView.separated(
        separatorBuilder: (BuildContext context, int index) => const Divider(
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
                  child: const Padding(
                      padding: EdgeInsets.all(5.0),
                      child: Center(child: CircularProgressIndicator())),
                )
              : Dismissible(
                  key: Key(index.toString()),
                  confirmDismiss: (DismissDirection direction) {
                    if (packList[index].isPaid != 1) {
                      packScopedModel.forceRefresh();
                      print(direction.toString() + ' ' + index.toString());
                      processPayment(
                          index,
                          packScopedModel,
                          payScopedModel,
                          context,
                          direction == DismissDirection.endToStart ? 3 : 4,
                          packList[index].eventPrice);
                    } else {
                      if (direction == DismissDirection.endToStart) {
                        packScopedModel.setRsvpState(rsvpYes.value, -1,
                            attendenceOnIn.value, packList[index]);
                      }
                    }
                    return Future<bool>.value(false);
                  },
                  background: packList[index].isPaid == 1
                      ? Container(
                          color: Colors.grey,
                          child: Row(
                            children: const <Widget>[
                              Padding(
                                padding: EdgeInsets.only(left: 15.0),
                                child: Icon(FontAwesome.check_circle,
                                    size: 35.0, color: Colors.white),
                              ),
                              Padding(
                                padding: EdgeInsets.only(left: 15.0),
                                child: Text(
                                  'Already paid',
                                  style: TextStyle(
                                      fontFamily: 'AvenirNextDemiBold',
                                      fontStyle: FontStyle.normal,
                                      color: Colors.white,
                                      fontSize: 20.0,
                                      height: 1.0),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          color: Colors.blue,
                          child: Row(
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.only(left: 15.0),
                                child: Image.asset(
                                    'images/icons/payment_type_4.png',
                                    height: 30.0,
                                    width: 30.0,
                                    color: Colors.white),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 15.0),
                                child: Text(
                                    '${Utilities.getFormattedMoney(packList[index].eventPrice, packList[index].digitsAfterDecimal, packList[index].currencySymbol)} Bank Transfer',
                                    style: const TextStyle(
                                        fontFamily: 'AvenirNextDemiBold',
                                        fontStyle: FontStyle.normal,
                                        color: Colors.white,
                                        fontSize: 20.0,
                                        height: 1.0)),
                              ),
                            ],
                          ),
                        ),
                  secondaryBackground: packList[index].isPaid == 1
                      ? packList[index].attendenceState >= attendenceOnIn.value
                          ? Container(
                              color: Colors.grey,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: const <Widget>[
                                  Padding(
                                    padding: EdgeInsets.only(right: 15.0),
                                    child: Icon(FontAwesome.check_circle,
                                        size: 35.0, color: Colors.white),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(right: 15.0),
                                    child: Text(
                                      'Already marked On-In',
                                      style: TextStyle(
                                          fontFamily: 'AvenirNextDemiBold',
                                          fontStyle: FontStyle.normal,
                                          color: Colors.white,
                                          fontSize: 20.0,
                                          height: 1.0),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Container(
                              color: Colors.amber[800],
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: const <Widget>[
                                  Padding(
                                    padding: EdgeInsets.only(right: 15.0),
                                    child: Icon(Ionicons.ios_beer,
                                        size: 35.0, color: Colors.white),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(right: 15.0),
                                    child: Text(
                                      'Record as On-In',
                                      style: TextStyle(
                                          fontFamily: 'AvenirNextDemiBold',
                                          fontStyle: FontStyle.normal,
                                          color: Colors.white,
                                          fontSize: 20.0,
                                          height: 1.0),
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
                              Padding(
                                padding: const EdgeInsets.only(right: 15.0),
                                child: Image.asset(
                                    'images/icons/payment_type_3.png',
                                    height: 30.0,
                                    width: 30.0,
                                    color: Colors.white),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 15.0),
                                child: Text(
                                    '${Utilities.getFormattedMoney(packList[index].eventPrice, packList[index].digitsAfterDecimal, packList[index].currencySymbol)} Cash',
                                    style: const TextStyle(
                                        fontFamily: 'AvenirNextDemiBold',
                                        fontStyle: FontStyle.normal,
                                        color: Colors.white,
                                        fontSize: 20.0,
                                        height: 1.0)),
                              ),
                            ],
                          ),
                        ),
                  onDismissed: (DismissDirection direction) {
                    print(direction.toString() +
                        ' NOTE: We should never reach this point');
                  },
                  child: listItem(context, index),
                );
        });
  }

  void processPayment(
      int index,
      PackScopedModel _packScopedModel,
      PayScopedModel _payScopedModel,
      BuildContext context,
      int paymentType,
      num paymentAmount) {
    final UserModel hasher = packList[index];

    if (hasher.rsvpState < rsvpYes.value) {
      hasher.rsvpState = -1;
      hasher.requestedRsvpState = rsvpYes.value;
    }

    _packScopedModel.forceRefresh();

    _payScopedModel
        .payForEvent(
            packList, index, paymentType, paymentAmount, attendenceAtHash.value)
        .then((List<PayForEventModel> result) {
      if (paymentType == paymentNotPaid.value) {
        hasher.isPaid = 0;
      } else {
        hasher.isPaid = 1;
      }

      if (hasher.hasherEventMapId != result[0].hasherEventMapId) {
        hasher.hasherEventMapId = result[0].hasherEventMapId;
      }

      if (hasher.userRunCount != result[0].totalRunsThisKennel) {
        hasher.userRunCount = result[0].totalRunsThisKennel;
      }

      hasher.rsvpState = rsvpYes.value;
      hasher.requestedRsvpState = -1;

      if (hasher.attendenceState < attendenceAtHash.value) {
        hasher.attendenceState = attendenceAtHash.value;
      }

      _packScopedModel.forceRefresh();

      packList[index].paymentType = paymentType;
      if ((paymentType == paymentCashOtherAmount.value) ||
          (paymentType == paymentBankTransferOtherAmount.value)) {
        final num fundsDifference = paymentAmount -
            (hasher.isMember == 1
                ? futureRun.eventPriceForMembers
                : futureRun.eventPriceForNonMembers);

        final String credit = Utilities.getFormattedMoney(fundsDifference,
            futureRun?.digitsAfterDecimal ?? 2, futureRun.currencySymbol);

        final double hashCashAmount = hasher.isMember == 1
            ? futureRun.eventPriceForMembers
            : futureRun.eventPriceForNonMembers;

        final String hashCash = Utilities.getFormattedMoney(hashCashAmount,
            futureRun?.digitsAfterDecimal ?? 2, futureRun.currencySymbol);

        final String amountPaid = Utilities.getFormattedMoney(paymentAmount,
            futureRun?.digitsAfterDecimal ?? 2, futureRun.currencySymbol);

        final String paymentMethod = paymentType == paymentCashOtherAmount.value
            ? 'in cash'
            : 'by bank transfer';

        if (fundsDifference > 0.0) {
          showDialog<void>(
              context: context,
              builder: (BuildContext context) {
                // return object of type Dialog
                return AlertDialog(
                  title: const Text('Credit applied to account'),
                  content: Text(
                      '$amountPaid was paid $paymentMethod. $hashCash was used to pay for the run and $credit has been credited to your Hash account for ${futureRun.kennelShortName}'),
                  actions: <Widget>[
                    // usually buttons at the bottom of the dialog
                    FlatButton(
                      color: Colors.blue,
                      textColor: Colors.white,
                      child: const Text('Close'),
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

    Scaffold.of(context).hideCurrentSnackBar(reason: SnackBarClosedReason.hide);
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
  const AddVisitorVirginPopup();

  @override
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
      title: const Text('Add Visitor or Virgin'),
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
              FontAwesome.money,
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
              FontAwesome.money,
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
              FontAwesome.money,
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
          child: const Text('Cancel'),
          textColor: Colors.white,
          onPressed: () {
            Navigator.of(context)
                .pop(<String, String>{'type': 'cancel', 'amount': ''});
          },
        ),

        FlatButton(
            color: Colors.blue,
            child: const Text('Add Visitor'),
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
            child: const Text('Add Virgin'),
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
