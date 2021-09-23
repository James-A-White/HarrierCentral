// @dart=2.11
import 'package:harrier_central/imports.dart';

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

    return Column(
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
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: numberStyle.copyWith(height: 0.6),
                        textAlign: TextAlign.left,
                      ),
                      kennelInfo.totalHaringThisKennel <= 0
                          ? const SizedBox(height: 20)
                          : Container(
                              padding: const EdgeInsets.only(left: 45.0),
                              child: Text(
                                '(${kennelInfo.totalHaringThisKennel.toString()} times hared)',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: numberStyle.copyWith(fontSize: 18.0),
                                textAlign: TextAlign.left,
                              ),
                            ),
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
