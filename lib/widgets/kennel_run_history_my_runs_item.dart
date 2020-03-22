import 'package:flutter/material.dart';

class KennelRunHistoryMyRunsItem extends StatelessWidget {
  const KennelRunHistoryMyRunsItem({@required this.refreshCounters});

  final Function refreshCounters;

  @override
  Widget build(BuildContext context) {
    const TextStyle numberStyle = TextStyle(
      fontFamily: 'AvenirNextCondensedDemiBold',
      fontStyle: FontStyle.normal,
      fontSize: 32.0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        InkWell(
          onTap: () {
            // Navigator.of(context).push<dynamic>(
            //   MaterialPageRoute<dynamic>(
            //     builder: (BuildContext context) {
            //       return UserRunHistoryListPage(
            //         kennelInfo: kennelInfo,
            //       );
            //     },
            //   ),
            // ).then((void dummy) {
            //   refreshCounters();
            // });
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(left: 20.0),
                child: Container(
                  padding: const EdgeInsets.only(left: 0.0),
                  height: 80.0,
                  child: Image.asset('images/icons/my_runs_badge.png'),
                ),

                // (kennelInfo.kennelLogo == null || kennelInfo.kennelLogo.length < 5)
                //     ? Container(height: 80, width: 80)
                //     : KennelLogo(
                //         kennelLogoUrl: kennelInfo.kennelLogo,
                //         kennelShortName: kennelInfo.kennelShortName,
                //         logoHeight: 80.0,
                //         leftPadding: 0.0,
                //       ),
              ),
              Expanded(
                child: Container(
                  width: 250,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const SizedBox(
                        height: 28,
                        width: 20,
                      ),
                      Text(
                        //'  =  ' + (kennelInfo.historicalCountIsEstimate != 0 ? '~' : '') + '${kennelInfo.totalRunsThisKennel.toString()}',
                        '  =  99',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: numberStyle.copyWith(height: 0.6),
                        textAlign: TextAlign.left,
                      ),
                      const SizedBox(height: 20)
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
