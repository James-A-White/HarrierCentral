import 'package:flutter/material.dart';

import 'package:harrier_central/pages/top_level/history_list_page.dart';
import 'package:harrier_central/pages/history_sub_pages/user_run_history_list_page.dart';
import 'package:harrier_central/widgets/kennel_logo.dart';

import 'package:auto_size_text/auto_size_text.dart';

class KennelRunHistoryCountListItem extends StatelessWidget {
  const KennelRunHistoryCountListItem({@required this.kennelInfo, @required this.refreshCounters});

  final HistoryListResults kennelInfo;
  final Function refreshCounters;

  @override
  Widget build(BuildContext context) {
    const TextStyle numberStyle = TextStyle(
      fontFamily: 'AvenirNextCondensedDemiBold',
      fontStyle: FontStyle.normal,
      fontSize: 32.0,
    );

    return

        // IntrinsicWidth(
        //   stepWidth: MediaQuery.of(context).size.width,
        //   child:

        //   Stack(
        // children: <Widget>[
        Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        InkWell(
          onTap: () {
            Navigator.of(context).push<dynamic>(
              MaterialPageRoute<dynamic>(
                builder: (BuildContext context) {
                  return UserRunHistoryListPage(
                    kennelInfo: kennelInfo,
                  );
                },
              ),
            ).then((void dummy) {
              refreshCounters();
            });
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(left: 20.0),
                child: (kennelInfo.kennelLogo == null || kennelInfo.kennelLogo.length < 5)
                    ? Container(height: 80, width: 80)
                    : KennelLogo(
                        kennelLogoUrl: kennelInfo.kennelLogo,
                        kennelShortName: kennelInfo.kennelShortName,
                        logoHeight: 80.0,
                        leftPadding: 0.0,
                      ),
              ),
              Expanded(
                child: Container(
                  //width: 250,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const SizedBox(
                        height: 28,
                        width: 20,
                      ),

                      Text(
                        '  =  ' + (kennelInfo.historicalCountIsEstimate != 0 ? '~' : '') + '${kennelInfo.totalRunsThisKennel.toString()}',
                        //'   =   9999',
                        //'Super fucking long text thats sure to overflow and more',
                        //'999',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,

                        style: numberStyle.copyWith(height: 0.6),
                        textAlign: TextAlign.left,
                      ),
                      //color: Colors.green,

                      kennelInfo.totalHaringThisKennel <= 0
                          ? Container(width: 120)
                          : Container(
                              padding: const EdgeInsets.only(left: 45.0),

                              child: Text(
                                '(${kennelInfo.totalHaringThisKennel.toString()} times hared)',

                                //=='   =   22',
                                //'Super fucking long text thats sure to overflow and more',
                                //'999',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: numberStyle.copyWith(fontSize: 18.0),
                                textAlign: TextAlign.left,
                              ),
                              //color: Colors.green,
                            ),
                    ],
                  ),
                ),
              ),
              // Container(
              //   //padding: EdgeInsets.only(left:50.0),
              //   //width: textWidth,
              //   width:80,
              //   child: AutoSizeText(
              //     '${kennelRunHistoryCount.totalHaringThisKennel.toString()}',
              //     //'Super fucking long text thats sure to overflow and more',
              //     //'999',
              //     overflow: TextOverflow.ellipsis,
              //     minFontSize: 22.0,
              //     maxLines: 1,
              //     style: numberStyle,
              //     textAlign: TextAlign.center,
              //   ),
              //   //color: Colors.blue,
              // ),

              // Container(
              //   width: textWidth,
              //   child: AutoSizeText(
              //     //'${kennelRunHistoryCount.totalPackRunsThisKennel.toString()}',
              //     //'Super fucking long text thats sure to overflow and more',
              //     '${((kennelRunHistoryCount.totalPackRunsThisKennel * 3) + (kennelRunHistoryCount.totalHaringThisKennel * 10)).toString()}',
              //     overflow: TextOverflow.ellipsis,
              //     minFontSize: 18.0,
              //     maxLines: 1,
              //     style: numberStyle,
              //     textAlign: TextAlign.center,
              //   ),
              //   //color: Colors.purple,
              // ),
              //Container(width: 1, height: 1)

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
          ),
        ),
        // Container(
        //   width: MediaQuery.of(context).size.width,
        //   child:

        // const Divider(
        //   color: Colors.black,
        //   height: 10.0,
        // ),
        // ),
      ],
      //   ),
      //   // Align(
      //   //   alignment: Alignment.centerRight,
      //   //   child: IconButton(
      //   //     icon: const Icon(Icons.settings),
      //   //     iconSize: Theme.of(context).iconTheme.size,
      //   //     color: Colors.black54,
      //   //     splashColor: Theme.of(context).highlightColor,
      //   //     // onPressed: () {
      //   //     //   Navigator.push<dynamic>(
      //   //     //     context,
      //   //     //     MaterialPageRoute<dynamic>(
      //   //     //       builder: (BuildContext context) => KennelAdminMainPage(kennel: kennelRunHistoryCount),
      //   //     //     ),
      //   //     //   );
      //   //     // },
      //   //   ),
      //   // ),
      // ],
    );
  }
}
