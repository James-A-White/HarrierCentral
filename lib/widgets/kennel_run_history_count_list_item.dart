import 'package:flutter/material.dart';

import 'package:harrier_central/data_models/kennel_run_history_totals_model.dart';
import 'package:harrier_central/widgets/kennel_logo.dart';

import 'package:auto_size_text/auto_size_text.dart';

class KennelRunHistoryCountListItem extends StatelessWidget {
  const KennelRunHistoryCountListItem({@required this.kennelRunHistoryCount});

  final KennelRunHistoryTotals kennelRunHistoryCount;

  @override
  Widget build(BuildContext context) {
    return

        // IntrinsicWidth(
        //   stepWidth: MediaQuery.of(context).size.width,
        //   child:

        Stack(
      children: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: MediaQuery.of(context).size.width,
              height: 36.0,
              padding: const EdgeInsets.only(left: 10.0, bottom: 2.0),
              child: AutoSizeText(
                '${kennelRunHistoryCount.kennelName}',
                //'Super fucking long text thats sure to overflow and more',
                //'Super fucking',
                minFontSize: 18,
                maxFontSize: 22,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
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
                // Container(
                //   padding: const EdgeInsets.only(top: 12.0),
                //   child: ScopedModelDescendant<FutureRunScopedModel>(
                //     builder: (BuildContext runContext, Widget runChild,
                //             FutureRunScopedModel runModel) =>
                //         ScopedModelDescendant<KennelScopedModel>(
                //           builder:
                //               (BuildContext context, Widget child,
                //                       KennelScopedModel model) =>
                //                   IconButton(
                //                     icon: Icon(
                //                         (kennelRunHistoryCount.followingRequested != null) ?
                //                             FontAwesome.cloud_upload
                //                                     : (kennelRunHistoryCount.followingBool == 1)
                //                             ? const Icon(FontAwesome.check_circle)
                //                                 .icon
                //                             : (kennelRunHistoryCount.followingRequested ??
                //                                         kennelRunHistoryCount
                //                                             .followingBool) ==
                //                                     2
                //                                 ? const Icon(FontAwesome
                //                                         .times_circle)
                //                                     .icon
                //                                 : const Icon(FontAwesome.circle_thin)
                //                                     .icon,
                //                         color: kennelRunHistoryCount.followingRequested !=
                //                                 null
                //                             ? Colors.blue
                //                             : kennelRunHistoryCount.followingBool == 1
                //                                 ? Colors.green
                //                                 : kennelRunHistoryCount.followingBool == 2
                //                                     ? Colors.red
                //                                     : Colors.grey.shade700),
                //                     tooltip: 'Select to follow a Kennel',
                //                     iconSize: 35.0,
                //                     alignment: Alignment.topCenter,
                //                     splashColor: Colors.greenAccent,
                //                     onPressed: () {
                //                       model.toggleFollowing(kennelRunHistoryCount);
                //                       runModel.clearFutureRunsList();

                //                       // setState(() {
                //                       // kennel.followingBool = kennel.followingBool == 0 ? 1 : 0;
                //                       // });
                //                     },
                //                   ),
                //         ),
                //   ),
                //   // child: IconButton(
                //   //   icon:const  Icon(
                //   //       kennel.followingBool == 0
                //   //           ? Icons.radio_button_unchecked
                //   //           : Icons.radio_button_checked,
                //   //       color: Colors.blueGrey),
                //   //   tooltip: 'Select to follow a Kennel',
                //   //   iconSize: 35.0,
                //   //   alignment: Alignment.topCenter,
                //   //   splashColor: Colors.greenAccent,
                //   //   onPressed: () {
                //   //     // setState(() {
                //   //     // kennel.followingBool = kennel.followingBool == 0 ? 1 : 0;
                //   //     // });
                //   //   },
                //   // ),
                //   alignment: Alignment.topCenter,
                //   //height: 40.0,
                // ),
                Padding(
                  padding: const EdgeInsets.only(left: 10.0, right: 8.0),
                  child: KennelLogo(
                    kennelLogoUrl: kennelRunHistoryCount.kennelLogo,
                    kennelShortName: kennelRunHistoryCount.kennelShortName,
                    logoHeight: 80.0,
                    leftPadding: 0.0,
                  ),
                ),
                Column(
                  children: <Widget>[
                    const Text(
                      'Pack\r\nRuns',
                      //'Super fucking long text thats sure to overflow and more',
                      //'Super fucking',
                      style: TextStyle(
                          fontFamily: 'AvenirNextCondensedDemiBold',
                          fontStyle: FontStyle.normal,
                          fontSize: 20.0,
                          height: 0.7),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      '${kennelRunHistoryCount.totalPackRunsThisKennel.toString()}',
                      //'Super fucking long text thats sure to overflow and more',
                      //'Super fucking',
                      style: const TextStyle(
                          fontFamily: 'AvenirNextCondensedDemiBold',
                          fontStyle: FontStyle.normal,
                          fontSize: 20.0,
                          height: 0.7),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                                Column(
                  children: <Widget>[
                    const Text(
                      'Hare\r\nRuns',
                      //'Super fucking long text thats sure to overflow and more',
                      //'Super fucking',
                      style: TextStyle(
                          fontFamily: 'AvenirNextCondensedDemiBold',
                          fontStyle: FontStyle.normal,
                          fontSize: 20.0,
                          height: 0.7),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      '${kennelRunHistoryCount.totalHaringThisKennel.toString()}',
                      //'Super fucking long text thats sure to overflow and more',
                      //'Super fucking',
                      style: const TextStyle(
                          fontFamily: 'AvenirNextCondensedDemiBold',
                          fontStyle: FontStyle.normal,
                          fontSize: 20.0,
                          height: 0.7),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                                                Column(
                  children: <Widget>[
                    const Text(
                      'Total\r\nRuns',
                      //'Super fucking long text thats sure to overflow and more',
                      //'Super fucking',
                      style: TextStyle(
                          fontFamily: 'AvenirNextCondensedDemiBold',
                          fontStyle: FontStyle.normal,
                          fontSize: 20.0,
                          height: 0.7),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      '${kennelRunHistoryCount.totalRunsThisKennel.toString()}',
                      //'Super fucking long text thats sure to overflow and more',
                      //'Super fucking',
                      style: const TextStyle(
                          fontFamily: 'AvenirNextCondensedDemiBold',
                          fontStyle: FontStyle.normal,
                          fontSize: 20.0,
                          height: 0.7),
                      textAlign: TextAlign.center,
                    ),
                  ],
                )

                // Column(
                //     mainAxisSize: MainAxisSize.max,
                //     children: <Widget>[
                //       // Text(
                //       //   '${kennel.kennelName}',
                //       //   style:
                //       //       TextStyle(fontSize: 22.0, fontWeight: FontWeight.w400),
                //       //   textAlign: TextAlign.left,
                //       // ),
                //       Container(width: 10.0, height: 10.0),
                //       Text(
                //         '${kennelRunHistoryCount.locationName}',
                //         style: const TextStyle(
                //             fontFamily: 'AvenirNextRegular',
                //             fontStyle: FontStyle.normal,
                //             fontSize: 16.0,
                //             height: 1.0),
                //       ),
                //       Text(
                //         '${Utilities.getDistance(kennelRunHistoryCount.distance, context)}',
                //         style: const TextStyle(
                //             fontFamily: 'AvenirNextRegular',
                //             fontStyle: FontStyle.normal,
                //             fontSize: 16.0,
                //             height: 1.0),
                //       ),
                //       // const Text(
                //       //   'xxxx Active Members',
                //       //                             style: const TextStyle(
                //       //             fontFamily: 'AvenirNextRegular',
                //       //             fontStyle: FontStyle.normal,
                //       //             fontSize: 16.0,
                //       //             height: 1.0),
                //       // ),
                //       Text(
                //         DateFormat("E, MMM d 'at' h:mm a")
                //             .format(kennelRunHistoryCount.dateNextRun),
                //         style: const TextStyle(
                //             fontFamily: 'AvenirNextRegular',
                //             fontStyle: FontStyle.normal,
                //             fontSize: 16.0,
                //             height: 1.0),
                //       ),
                //     ],
                //     crossAxisAlignment: CrossAxisAlignment.start)
              ],
            )),
            Container(
              width: MediaQuery.of(context).size.width,
              child: const Divider(
                color: Colors.black,
                height: 20.0,
              ),
            ),
          ],
        ),
        // Align(
        //   alignment: Alignment.centerRight,
        //   child: IconButton(
        //     icon: const Icon(Icons.settings),
        //     iconSize: Theme.of(context).iconTheme.size,
        //     color: Colors.black54,
        //     splashColor: Theme.of(context).highlightColor,
        //     // onPressed: () {
        //     //   Navigator.push<dynamic>(
        //     //     context,
        //     //     MaterialPageRoute<dynamic>(
        //     //       builder: (BuildContext context) => KennelAdminMainPage(kennel: kennelRunHistoryCount),
        //     //     ),
        //     //   );
        //     // },
        //   ),
        // ),
      ],
    );
  }
}
