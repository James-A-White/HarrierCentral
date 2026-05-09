import 'package:harrier_central/imports.dart';

class KennelRunHistoryCountListItem extends StatelessWidget {
  const KennelRunHistoryCountListItem({
    super.key,
    required this.kennelInfo,
    required this.refreshCounters,
  });

  final RunHistoryModel kennelInfo;
  final Function refreshCounters;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        InkWell(
          onTap: () {
            Navigator.of(context)
                .push<dynamic>(
                  MaterialPageRoute<dynamic>(
                    builder: (BuildContext context) {
                      return UserRunHistoryListPage(
                        appDomain: AppDomainType.user,
                        kennelInfo: kennelInfo,
                        refreshKennelInfo: () {
                          return refreshCounters(kennelInfo.kennelId);
                        },
                      );
                    },
                  ),
                )
                .then((void _) {
                  refreshCounters(kennelInfo.kennelId);
                });
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(left: 20.0),
                child:
                    kennelInfo.kennelLogo.length < 5
                        ? const SizedBox(height: 80, width: 80)
                        : KennelLogo(
                          kennelId: kennelInfo.kennelId,
                          kennelLogoUrl: kennelInfo.kennelLogo,
                          kennelShortName: kennelInfo.kennelShortName,
                          logoHeight: 80.0,
                          leftPadding: 0.0,
                        ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 2.0),
                child: Text(
                  ' = ',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: ts_titleCondensedVeryLargeBlack,
                  textAlign: TextAlign.left,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      kennelInfo.kennelName,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: ts_titleCondensedBlack,
                      textAlign: TextAlign.left,
                    ),

                    Text(
                      '${kennelInfo.historicalCountIsEstimate != 0 ? '~' : ''}${kennelInfo.totalRunsThisKennel}',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: ts_titleCondensedVeryLargeBlack,
                      textAlign: TextAlign.left,
                    ),
                    kennelInfo.totalHaringThisKennel <= 0
                        ? const SizedBox(height: 20)
                        : SizedBox(
                          height: 20.0,
                          //padding: const EdgeInsets.only(left: 45.0),
                          child: Text(
                            '(${kennelInfo.totalHaringThisKennel.toString()} times hared)',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: ts_titleMediumCondensedBlack.copyWith(
                              fontSize: 18.0,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
