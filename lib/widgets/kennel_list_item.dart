import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:harrier_central/data_models/kennel_model.dart';
import 'package:harrier_central/pages/kennel_admin/kennel_admin_main.dart';
import 'package:harrier_central/services/kennel_scoped_model.dart';
import 'package:harrier_central/util/utilities.dart';
import 'package:harrier_central/widgets/kennel_logo.dart';
import 'package:harrier_central/services/future_run_scoped_model.dart';

import 'package:intl/intl.dart';
import 'package:scoped_model/scoped_model.dart';

class KennelsListItem extends StatelessWidget {
  const KennelsListItem({
    @required this.kennel,
  });

  final Kennel kennel;

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      stepWidth: MediaQuery.of(context).size.width,
      child: Stack(
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(left: 10.0, bottom: 2.0),
                child: Text(
                  '${kennel.kennelName}',
                  style: const TextStyle(
                      fontFamily: 'AvenirNextCondensedDemiBold',
                      fontStyle: FontStyle.normal,
                      fontSize: 22.0,
                      height: 1.0),
                  textAlign: TextAlign.center,
                ),
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
                  child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: ScopedModelDescendant<FutureRunScopedModel>(
                      builder: (BuildContext runContext, Widget runChild,
                              FutureRunScopedModel runModel) =>
                          ScopedModelDescendant<KennelScopedModel>(
                            builder:
                                (BuildContext context, Widget child,
                                        KennelScopedModel model) =>
                                    IconButton(
                                      icon: Icon(
                                          (kennel.followingRequested ??
                                                      kennel.followingBool) ==
                                                  1
                                              ? const Icon(FontAwesomeIcons.solidCheckCircle)
                                                  .icon
                                              : (kennel.followingRequested ??
                                                          kennel
                                                              .followingBool) ==
                                                      2
                                                  ? const Icon(FontAwesomeIcons
                                                          .solidTimesCircle)
                                                      .icon
                                                  : const Icon(FontAwesomeIcons.circle)
                                                      .icon,
                                          color: kennel.followingRequested !=
                                                  null
                                              ? Colors.blue
                                              : kennel.followingBool == 1
                                                  ? Colors.green
                                                  : kennel.followingBool == 2
                                                      ? Colors.red
                                                      : Colors.grey.shade700),
                                      tooltip: 'Select to follow a Kennel',
                                      iconSize: 35.0,
                                      alignment: Alignment.topCenter,
                                      splashColor: Colors.greenAccent,
                                      onPressed: () {
                                        model.toggleFollowing(kennel);
                                        runModel.clearFutureRunsList();

                                        // setState(() {
                                        // kennel.followingBool = kennel.followingBool == 0 ? 1 : 0;
                                        // });
                                      },
                                    ),
                          ),
                    ),
                    // child: IconButton(
                    //   icon:const  Icon(
                    //       kennel.followingBool == 0
                    //           ? Icons.radio_button_unchecked
                    //           : Icons.radio_button_checked,
                    //       color: Colors.blueGrey),
                    //   tooltip: 'Select to follow a Kennel',
                    //   iconSize: 35.0,
                    //   alignment: Alignment.topCenter,
                    //   splashColor: Colors.greenAccent,
                    //   onPressed: () {
                    //     // setState(() {
                    //     // kennel.followingBool = kennel.followingBool == 0 ? 1 : 0;
                    //     // });
                    //   },
                    // ),
                    alignment: Alignment.topCenter,
                    //height: 40.0,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: KennelLogo(
                      kennelLogoUrl: kennel.kennelLogo,
                      kennelShortName: kennel.kennelShortName,
                      logoHeight: 80.0,
                      leftPadding: 0.0,
                    ),
                  ),
                  Column(
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        // Text(
                        //   '${kennel.kennelName}',
                        //   style:
                        //       TextStyle(fontSize: 22.0, fontWeight: FontWeight.w400),
                        //   textAlign: TextAlign.left,
                        // ),
                        Container(width: 10.0, height: 10.0),
                        Text(
                          '${kennel.locationName}',
                          style: const TextStyle(
                              fontFamily: 'AvenirNextRegular',
                              fontStyle: FontStyle.normal,
                              fontSize: 16.0,
                              height: 1.0),
                        ),
                        Text(
                          '${Utilities.getDistance(kennel.distance, context)}',
                          style: const TextStyle(
                              fontFamily: 'AvenirNextRegular',
                              fontStyle: FontStyle.normal,
                              fontSize: 16.0,
                              height: 1.0),
                        ),
                        // const Text(
                        //   'xxxx Active Members',
                        //                             style: const TextStyle(
                        //             fontFamily: 'AvenirNextRegular',
                        //             fontStyle: FontStyle.normal,
                        //             fontSize: 16.0,
                        //             height: 1.0),
                        // ),
                        Text(
                          DateFormat("E, MMM d 'at' h:mm a")
                              .format(kennel.dateNextRun),
                          style: const TextStyle(
                              fontFamily: 'AvenirNextRegular',
                              fontStyle: FontStyle.normal,
                              fontSize: 16.0,
                              height: 1.0),
                        ),
                      ],
                      crossAxisAlignment: CrossAxisAlignment.start)
                ],
              )),
              const Divider(
                color: Colors.black,
                height: 18.0,
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: const Icon(Icons.settings),
              iconSize: Theme.of(context).iconTheme.size,
              color: Colors.black54,
              splashColor: Theme.of(context).highlightColor,
              onPressed: () {
                Navigator.push<dynamic>(
                  context,
                  MaterialPageRoute<dynamic>(
                    builder: (BuildContext context) => KennelAdminMainPage(kennel: kennel),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
