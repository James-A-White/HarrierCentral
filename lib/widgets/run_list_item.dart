
import 'dart:core';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:harrier_central/data_models/future_run_model.dart';
import 'package:harrier_central/pages/detail_pages/run_details_page.dart';
import 'package:harrier_central/remote_api_data/future_run_scoped_model.dart';
import 'package:harrier_central/util/utilities.dart';
import 'package:harrier_central/widgets/kennel_logo.dart';

import 'package:intl/intl.dart';
import 'package:scoped_model/scoped_model.dart';

class RunListItem extends StatefulWidget {
  RunListItem({Key key, @required FutureRun this.futureRun}) : super(key: key);

  FutureRun futureRun;

  @override
  _RunListItemState createState() => _RunListItemState();
}

class _RunListItemState extends State<RunListItem> with WidgetsBindingObserver {
  _RunListItemState();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('App lifecycle state => ' + state.toString());
    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    // return IntrinsicWidth(
    //     child:
    return Card(
        elevation: 4.0,
        margin: const EdgeInsets.only(top: 20.0, left: 15.0, right: 15.0),
        color: (widget.futureRun.isExpanded ?? false)
            ? Theme.of(context).selectedRowColor
            : Colors.white,
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: <
            Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 5.0, left: 8.0, right: 8.0),
            child: Text(
              widget.futureRun.eventName,
              style: TextStyle(
                  fontFamily: 'AvenirNextCondensedDemiBold',
                  fontStyle: FontStyle.normal,
                  fontSize: 17.0,
                  color: (widget.futureRun.isExpanded ?? false)
                      ? Theme.of(context).accentColor
                      : Colors.black,
                  height: 1.0),
              textAlign: TextAlign.left,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            //padding: EdgeInsets.only(top: 15.0, bottom: 10.0),
            margin: EdgeInsets.only(top: 7.0, bottom: 0.0),
            padding: EdgeInsets.only(top: 7.0, bottom: 0.0),
            height: widget.futureRun.isExpanded ? 0.0 : 1.0,
            color: Colors.grey[300],
          ),
          ScopedModelDescendant<FutureRunScopedModel>(
            builder: (BuildContext context, Widget child,
                FutureRunScopedModel futureScopedModel) {
              return FlatButton(
                splashColor: Theme.of(context).accentColor,
                highlightColor: Theme.of(context).accentColor,
                onPressed: () {
                  Navigator.push<dynamic>(
                    this.context,
                    MaterialPageRoute<dynamic>(
                      builder: (context) =>
                          RunDetailsPage(futureRun: widget.futureRun),
                    ),
                  );
                  //   },
                  // );
                },
                padding: EdgeInsets.only(
                    top: 10.0, left: 10.0, right: 10.0, bottom: 10.0),
                child: Stack(
                  children: <Widget>[
                    widget.futureRun.haresCount == 0
                        ? Align(
                            alignment: Alignment.topRight,
                            child: Image(
                                width: 75.0,
                                height: 75.0,
                                fit: BoxFit.fill,
                                image: AssetImage(
                                    'images/other/hare_needed_stamp.png')))
                        : Container(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Stack(alignment: Alignment.center, children: <Widget>[
                          KennelLogo(
                            kennelLogoUrl: widget.futureRun.kennelLogo,
                            kennelShortName: widget.futureRun.kennelShortName,
                            logoHeight: 70.0,
                            leftPadding: 10.0,
                          ),
                        ]),
                        Padding(
                          padding: const EdgeInsets.only(top: 3.0, left: 10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Run #${widget.futureRun.eventNumber}, in ' +
                                    (widget.futureRun.daysUntilNextRun <= 14
                                        ? widget.futureRun.daysUntilNextRun == 0
                                            ? 'TODAY'
                                            : widget.futureRun
                                                        .daysUntilNextRun ==
                                                    1
                                                ? 'Tomorrow'
                                                : '${widget.futureRun.daysUntilNextRun.toString()} days'
                                        : widget.futureRun.daysUntilNextRun <=
                                                30
                                            ? (widget.futureRun
                                                            .daysUntilNextRun ~/
                                                        7.0)
                                                    .toString() +
                                                ((widget.futureRun
                                                                .daysUntilNextRun ~/
                                                            7.0) ==
                                                        1
                                                    ? ' week'
                                                    : ' weeks')
                                            : widget.futureRun
                                                        .daysUntilNextRun <=
                                                    365
                                                ? (widget.futureRun
                                                                .daysUntilNextRun ~/
                                                            30.0)
                                                        .toString() +
                                                    ((widget.futureRun
                                                                    .daysUntilNextRun ~/
                                                                30.0) ==
                                                            1
                                                        ? ' month'
                                                        : ' months')
                                                : (widget.futureRun
                                                                .daysUntilNextRun ~/
                                                            365.0)
                                                        .toString() +
                                                        ((widget.futureRun
                                                                .daysUntilNextRun ~/
                                                            365.0) == 1 ? ' year' :
                                                    ' years')),
                                style: const TextStyle(
                                    color: Colors.black87,
                                    fontFamily: 'AvenirNextDemiBold',
                                    fontStyle: FontStyle.normal,
                                    fontSize: 15.0,
                                    height: 0.85),
                                textAlign: TextAlign.left,
                              ),
                              Text(
                                DateFormat("E, MMM d 'at' h:mm a").format(
                                    widget.futureRun.eventStartDatetime),
                                style: const TextStyle(
                                    color: Colors.black87,
                                    fontFamily: 'AvenirNextRegular',
                                    fontStyle: FontStyle.normal,
                                    fontSize: 15.0,
                                    height: 0.85),
                                textAlign: TextAlign.left,
                              ),
                              Text(
                                widget.futureRun.hareList.length <= 0
                                    ? 'RSVP to sign up to Hare!'
                                    : 'Hares: ' + widget.futureRun.hareList,
                                style: const TextStyle(
                                    color: Colors.black87,
                                    fontFamily: 'AvenirNextRegular',
                                    fontStyle: FontStyle.normal,
                                    fontSize: 15.0,
                                    height: 0.85),
                                textAlign: TextAlign.left,
                              ),
                              widget.futureRun.distanceToEvent >= 0
                                  ? Text(
                                      Utilities.getDistance(
                                              widget.futureRun.distanceToEvent,
                                              context) +
                                          ' from here',
                                      style: const TextStyle(
                                          color: Colors.black87,
                                          fontFamily: 'AvenirNextRegular',
                                          fontStyle: FontStyle.normal,
                                          fontSize: 15.0,
                                          height: 0.85),
                                      textAlign: TextAlign.left,
                                    )
                                  : const Text(''),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          )
        ]));
  }
}
