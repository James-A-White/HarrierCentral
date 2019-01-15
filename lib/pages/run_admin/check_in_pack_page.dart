import 'dart:core';

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
  Widget build(BuildContext context) {
    getPack(false);
    return ScopedModel<PackScopedModel>(
      model: _packScopedModel,
      child: ScopedModel<PayScopedModel>(
        model: _payScopedModel,
        child: Scaffold(
          appBar: AppBar(
            centerTitle: true,
            backgroundColor: Theme.of(context).primaryColor,
            title: Text(
              '${widget.futureRun.eventName} Check In',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
          body: Container(
            key: packListBox,
            margin:
                const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 15.0),
            padding: const EdgeInsets.all(8.0),
            decoration: new BoxDecoration(
                border: new Border.all(color: Theme.of(context).accentColor)),
            child: Scrollbar(
              child: RefreshIndicator(
                onRefresh: _getPackWithRefresh,
                child: ClipRect(
                  clipBehavior: Clip.antiAlias,
                  clipper: packListBox.currentContext == null
                      ? null
                      : RectClipper(
                          width: packListBox.currentContext
                              .findRenderObject()
                              .paintBounds
                              .width,
                          height: packListBox.currentContext
                              .findRenderObject()
                              .paintBounds
                              .height),
                  child: StaggeredGridView.countBuilder(
                    crossAxisCount: 3,
                    itemCount: packList?.length ?? 0,
                    itemBuilder: (BuildContext context, int index) {
                      return packList.isEmpty
                          ? new Container(
                              color: Colors.grey[300],
                              width: 70.0,
                              height: 70.0,
                              child: new Padding(
                                  padding: const EdgeInsets.all(5.0),
                                  child: new Center(
                                      child: new CircularProgressIndicator())),
                            )
                          : GestureDetector(onTap: () {
                              final snackBar = buildSnackbar(
                                  context, index, _packScopedModel);

                              Scaffold.of(context).removeCurrentSnackBar(
                                  reason: SnackBarClosedReason.hide);
                              Scaffold.of(context).showSnackBar(snackBar);
                            }, child: ScopedModelDescendant<PackScopedModel>(
                              builder: (BuildContext context, Widget child,
                                  PackScopedModel model) {
                                return Stack(
                                  children: <Widget>[
                                    packList[index].photo.startsWith('http')
                                        ? CachedNetworkImage(
                                            imageUrl: packList[index].photo,
                                            placeholder:
                                                const CircularProgressIndicator(),
                                            errorWidget:
                                                const Icon(Icons.error),
                                            //fadeOutDuration:  Duration(seconds: 1),
                                            fadeInDuration:
                                                Duration(milliseconds: 0),
                                            width: 300.0,
                                            height: 300.0,
                                            fit: BoxFit.fill)
                                        : packList[index]
                                                .photo
                                                .startsWith('bundle')
                                            ? Image(
                                                width: 300.0,
                                                height: 300.0,
                                                fit: BoxFit.fill,
                                                image: AssetImage(
                                                    'images/avatars/' +
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
                                        backgroundColor:
                                            packList[index].rsvpState == 0
                                                ? Colors.transparent
                                                : packList[index].rsvpState ==
                                                        -1
                                                    ? Colors.blue
                                                    : Colors.white,
                                        radius: 14.0,
                                      ),
                                    ),
                                    Positioned(
                                      left: 5.0,
                                      bottom: packList[index].rsvpState <= 0
                                          ? 2.5
                                          : packList[index].isHare == 1
                                              ? 3.0
                                              : 3.5,
                                      child: packList[index].rsvpState <= 0
                                          ? CircleAvatar(
                                              backgroundColor:
                                                  Colors.transparent,
                                              radius: 12.0,
                                            )
                                          : packList[index].rsvpState ==
                                                  rsvpNo.value
                                              ? Icon(
                                                  FontAwesomeIcons
                                                      .solidTimesCircle,
                                                  color: Colors.red,
                                                  size: 24.0)
                                              : packList[index].rsvpState ==
                                                      rsvpMaybe.value
                                                  ? Icon(
                                                      FontAwesomeIcons
                                                          .solidQuestionCircle,
                                                      color: Colors.orange,
                                                      size: 24.0)
                                                  : packList[index].isHare == 0
                                                      ? Icon(
                                                          FontAwesomeIcons
                                                              .solidCheckCircle,
                                                          color: Colors.green,
                                                          size: 24.0)
                                                      : Image.asset(
                                                          'images/icons/hare_icon.png',
                                                          color:
                                                              Colors.deepPurple,
                                                          height: 24.0,
                                                          width: 24.0),

                                      // AssetImage(
                                      //     'images/icons/hare_icon.png'),
                                    ),
                                    Positioned(
                                      right: 3.0,
                                      bottom: 1.0,
                                      child: packList[index].rsvpState !=
                                              rsvpYes.value
                                          ? Container()
                                          : CircleAvatar(
                                              backgroundColor: packList[index]
                                                          .attendenceState ==
                                                      0
                                                  ? Colors.transparent
                                                  : packList[index]
                                                              .attendenceState ==
                                                          -1
                                                      ? Colors.blue
                                                      : Colors.white,
                                              radius: 14.0,
                                            ),
                                    ),
                                    Positioned(
                                      right: 5.0,
                                      bottom:
                                          packList[index].attendenceState <= 0
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

                                    ScopedModelDescendant<PayScopedModel>(
                                        builder: (BuildContext context,
                                            Widget child,
                                            PayScopedModel model) {
                                      return Positioned(
                                        right: 0.0,
                                        left: 0.0,
                                        bottom: 1.0,
                                        child: packList[index].attendenceState <
                                                attendenceAtHash.value
                                            ? Container()
                                            : packList[index].rsvpState !=
                                                    rsvpYes.value
                                                ? Container()
                                                : CircleAvatar(
                                                    backgroundColor: packList[
                                                                    index]
                                                                .attendenceState ==
                                                            0
                                                        ? Colors.transparent
                                                        : packList[index]
                                                                    .isPaid ==
                                                                -1
                                                            ? Colors.blue
                                                            : Colors.white,
                                                    radius: 14.0,
                                                  ),
                                      );
                                    }),

                                    ScopedModelDescendant<PayScopedModel>(
                                      builder: (BuildContext context,
                                          Widget child, PayScopedModel model) {
                                        return Positioned(
                                            right: 0.0,
                                            left: 0.0,
                                            bottom: packList[index].attendenceState < -1
                                                ? 2.5
                                                : 3.5,
                                            child: packList[index].attendenceState <
                                                    attendenceAtHash.value
                                                ? Container()
                                                : packList[index].rsvpState != rsvpYes.value
                                                    ? Container()
                                                    : packList[index].attendenceState <= attendenceNo.value
                                                        ? Image.asset('images/icons/dollar_sign_icon.png',
                                                            height: 24.0,
                                                            width: 24.0,
                                                            color: Colors
                                                                .transparent)
                                                        : packList[index].isPaid == isPaidNo.value
                                                            ? Image.asset('images/icons/dollar_sign_icon.png',
                                                                height: 24.0,
                                                                width: 24.0,
                                                                color:
                                                                    Colors.red)
                                                            : packList[index].isPaid == isPaidYes.value
                                                                ? Image.asset('images/icons/dollar_sign_icon.png',
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
                                );
                              },
                            )); //TODO: Replace this with another avatar for missing image
                    },
                    staggeredTileBuilder: (int index) {
                      return packList[index].isHare == 0
                          ? new StaggeredTile.count(1, 1)
                          : new StaggeredTile.count(2, 2);
                    },
                    mainAxisSpacing: 8.0,
                    crossAxisSpacing: 8.0,
                  ),
                ),
              ),
            ),
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
//

  Widget buildSnackbar(
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
                              builder: (BuildContext context, Widget child,
                                  PayScopedModel model) {
                                return 


          Column(children: <Widget>[
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
                        icon: Image.asset('images/icons/x_icon.png',
                            height: 30.0, width: 30.0),
                        color: widget.futureRun.requestedRsvpState == 1
                            ? Colors.blue
                            : widget.futureRun.rsvpState == 2
                                ? Colors.green
                                : Colors.grey,
                        //tooltip: 'Select to follow a Kennel',
                        iconSize: 30.0,
                        alignment: Alignment.topCenter,
                        splashColor: Colors.greenAccent,
                        onPressed: () {
                          payForEvent(index, _packScopedModel, _payScopedModel, context,
                              paymentNotPaid.value, 0.0);
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
                        icon: Image.asset('images/icons/free_run_icon.png',
                            height: 30.0, width: 30.0),
                        color: widget.futureRun.requestedRsvpState == 1
                            ? Colors.blue
                            : widget.futureRun.rsvpState == 2
                                ? Colors.green
                                : Colors.grey,
                        //tooltip: 'Select to follow a Kennel',
                        iconSize: 30.0,
                        alignment: Alignment.topCenter,
                        splashColor: Colors.greenAccent,
                        onPressed: () {
                          payForEvent(index, _packScopedModel, _payScopedModel, context,
                              paymentFreeRun.value, 0.0);
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
                        icon: Image.asset('images/icons/paid_other_icon.png',
                            height: 30.0, width: 30.0),
                        color: widget.futureRun.requestedRsvpState == 1
                            ? Colors.blue
                            : widget.futureRun.rsvpState == 2
                                ? Colors.green
                                : Colors.grey,
                        //tooltip: 'Select to follow a Kennel',
                        iconSize: 30.0,
                        alignment: Alignment.topCenter,
                        splashColor: Colors.greenAccent,
                        onPressed: () {
                          payForEvent(index, _packScopedModel, _payScopedModel, context,
                              paymentCashOtherAmount.value, 0.0);
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
                        icon: Image.asset('images/icons/dollar_sign_icon.png',
                            height: 30.0, width: 30.0),
                        color: widget.futureRun.requestedRsvpState == 1
                            ? Colors.blue
                            : widget.futureRun.rsvpState == 2
                                ? Colors.green
                                : Colors.grey,
                        //tooltip: 'Select to follow a Kennel',
                        iconSize: 30.0,
                        alignment: Alignment.topCenter,
                        splashColor: Colors.greenAccent,
                        onPressed: () {
                          payForEvent(index, _packScopedModel, _payScopedModel, context,
                              paymentCash.value, 5.00);
                        },
                      ),
                      Text(
                        "Paid €5.00\r\ncash",
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
                        icon: Image.asset('images/icons/bank_icon.png',
                            height: 30.0, width: 30.0),
                        color: widget.futureRun.requestedRsvpState == 1
                            ? Colors.blue
                            : widget.futureRun.rsvpState == 2
                                ? Colors.green
                                : Colors.grey,
                        //tooltip: 'Select to follow a Kennel',
                        iconSize: 30.0,
                        alignment: Alignment.topCenter,
                        splashColor: Colors.greenAccent,
                        onPressed: () {
                          payForEvent(index, _packScopedModel, _payScopedModel, context,
                              paymentBankTransfer.value, 5.0);
                        },
                      ),
                      Text(
                        "Paid €5.00\r\nbank transfer",
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
                        icon: Image.asset('images/icons/borrow_money_icon.png',
                            height: 30.0, width: 30.0),
                        color: widget.futureRun.requestedRsvpState == 1
                            ? Colors.blue
                            : widget.futureRun.rsvpState == 2
                                ? Colors.green
                                : Colors.grey,
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
                        'Owes €5.00',
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
          ]);},),
       
       
       
       
       
       
        ],
      ),
      backgroundColor: Theme.of(context).accentColor,
    );

    return snackbar;
  }

  void payForEvent(int index, PackScopedModel _packScopedModel, PayScopedModel _payScopedModel,
      BuildContext context, int paymentType, num paymentAmount) {

    _payScopedModel.payForEvent(packList, index, paymentType, paymentAmount);

    packList[index].isPaid = -1;

    int attendenceState = -1;
    if (packList[index].attendenceState < attendenceAtHash.value) {
      attendenceState = attendenceAtHash.value;
    }
    _packScopedModel.setRsvpState(
        rsvpYes.value, -1, attendenceState, packList[index]);

    Scaffold.of(context).hideCurrentSnackBar(reason: SnackBarClosedReason.hide);
  }
}

class RectClipper extends CustomClipper<Rect> {
  RectClipper({@required this.width, @required this.height});

  double width;
  double height;

  @override
  Rect getClip(Size size) {
    Rect r = const Offset(0.0, 0.0) & Size(width, height - 33);

    // This is where we decide what part of our image is going to be
    // visible. If you try to run the app now, nothing will be shown.
    return r;
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) => false;
}
