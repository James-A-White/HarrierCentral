import 'package:flutter/material.dart';

import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:scoped_model/scoped_model.dart';

import 'package:harrier_central/data/hc3_services/hasher_kennel_map_service.dart';
import 'package:harrier_central/util/utilities.dart';
import 'package:harrier_central/util/styles.dart';
import 'package:harrier_central/util/enums.dart';
import 'package:harrier_central/widgets/kennel_logo.dart';
import 'package:harrier_central/widgets/follow_kennel_popup.dart';
import 'package:harrier_central/data/services/future_run_scoped_model.dart';

class KennelsListItem extends StatefulWidget {
  const KennelsListItem({Key key, @required this.kennel}) : super(key: key);

  final Map<String, dynamic> kennel;

  @override
  KennelListItemState createState() => KennelListItemState();
}

class KennelListItemState extends State<KennelsListItem> {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      margin: const EdgeInsets.only(top: 10.0, left: 0.0, right: 0.0),
      color: Colors.white,
      child: IntrinsicWidth(
        stepWidth: MediaQuery.of(context).size.width,
        child: Stack(
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      child: ScopedModelDescendant<FutureRunScopedModel>(
                        builder: (BuildContext runContext, Widget runChild, FutureRunScopedModel runModel) => IconButton(
                              icon: Icon(widget.kennel['followingRequested'] != -1 ? delayIcon : widget.kennel['following'] == 1 ? const Icon(FontAwesome.check_circle).icon : widget.kennel['following'] == 2 ? const Icon(FontAwesome.times_circle).icon : const Icon(FontAwesome.star).icon,
                                  color: widget.kennel['followingRequested'] != -1 ? Colors.blue : widget.kennel['following'] == 1 ? Colors.green : widget.kennel['following'] == 2 ? Colors.red : Colors.yellow[800]),
                              tooltip: 'Select to follow a Kennel',
                              iconSize: 35.0,
                              alignment: Alignment.topCenter,
                              splashColor: Colors.greenAccent,
                              onPressed: () {
                                final HasherKennelMapService srv = HasherKennelMapService();
                                int followingRequested = widget.kennel['following'] + 1;
                                if (followingRequested > 2) {
                                  followingRequested = 0;
                                }
                                widget.kennel['followingRequested'] = followingRequested;
                                setState(() {});
                                srv.toggleFollowing(widget.kennel).then((void dummy) {
                                  setState(() {});
                                });
                              },
                            ),
                      ),
                      alignment: Alignment.topCenter,
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width - 70,
                      padding: const EdgeInsets.only(left: 0.0, bottom: 2.0),
                      child: Text(
                        '${widget.kennel['kennelName']}',
                        style: const TextStyle(fontFamily: 'AvenirNextCondensedDemiBold', fontStyle: FontStyle.normal, fontSize: 22.0, height: 1.0),
                        textAlign: TextAlign.left,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                InkWell(
                    // onTap: () {
                    //   Navigator.of(context).push<dynamic>(
                    //     MaterialPageRoute<dynamic>(
                    //       builder: (BuildContext context) {
                    //         return KennelDetailPage(kennel: kennel);
                    //       },
                    //     ),
                    //   );
                    // },
                    child: Stack(
                  children: <Widget>[
                    Container(
                      width: MediaQuery.of(context).size.width,
                      height: 85,
                    ),
                    Positioned(
                      left: 5,
                      top: 0,
                      child: KennelLogo(
                        kennelLogoUrl: widget.kennel['kennelLogo'],
                        kennelShortName: widget.kennel['kennelShortName'],
                        logoHeight: 80.0,
                        leftPadding: 0.0,
                      ),
                    ),
                    Positioned(
                      left: 100,
                      child: Column(
                          mainAxisSize: MainAxisSize.max,
                          children: <Widget>[
                            Container(width: 10.0, height: 10.0),
                            Text(
                              '${widget.kennel['location']}',
                              style: const TextStyle(fontFamily: 'AvenirNextRegular', fontStyle: FontStyle.normal, fontSize: 16.0, height: 1.0),
                            ),
                            Text(
                              '${Utilities.getDistance(widget.kennel['distance'], context)}',
                              style: const TextStyle(fontFamily: 'AvenirNextRegular', fontStyle: FontStyle.normal, fontSize: 16.0, height: 1.0),
                            ),
                            // const Text(
                            //   'xxxx Active Members',
                            //                             style: const TextStyle(
                            //             fontFamily: 'AvenirNextRegular',
                            //             fontStyle: FontStyle.normal,
                            //             fontSize: 16.0,
                            //             height: 1.0),
                            // ),
                            // Text(
                            //   DateFormat("E, MMM d 'at' h:mm a")
                            //       .format(kennel.dateNextRun),
                            //   style: const TextStyle(
                            //       fontFamily: 'AvenirNextRegular',
                            //       fontStyle: FontStyle.normal,
                            //       fontSize: 16.0,
                            //       height: 1.0),
                            // ),
                          ],
                          crossAxisAlignment: CrossAxisAlignment.start),
                    ),
                  ],
                )),
                // const Divider(
                //   color: Colors.black,
                //   height: 18.0,
                // ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(MaterialCommunityIcons.dots_vertical),
                iconSize: Theme.of(context).iconTheme.size,
                color: Colors.black54,
                splashColor: Theme.of(context).highlightColor,
                onPressed: () {
                  final FollowKennelPopup otherPaymentPopup = FollowKennelPopup(kennelName: widget.kennel['kennelName']);

                  final Future<EnumFollowType<int>> dlg = showDialog<EnumFollowType<int>>(
                      context: context,
                      barrierDismissible: false, // user must tap button!
                      builder: (BuildContext context) {
                        return otherPaymentPopup;
                      });

                  dlg.then((EnumFollowType<int> x) {
                    if (x.value != -1) {
                      final HasherKennelMapService srv = HasherKennelMapService();
                      widget.kennel['followingRequested'] = x.value;
                      setState(() {});
                      srv.toggleFollowing(widget.kennel).then((void dummy) {
                        setState(() {});
                      });
                    }
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
