import 'package:harrier_central/imports.dart';

class CountryRunHistoryCountListItem extends StatelessWidget {
  const CountryRunHistoryCountListItem({
    super.key,
    required this.countryId,
    required this.countryName,
    required this.flagFile,
    required this.runCount,
    required this.hareCount,
  });

  final String countryId;
  final String countryName;
  final String flagFile;
  final int runCount;
  final int hareCount;
  //final Function refreshCounters;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        InkWell(
          onTap: () {
            Navigator.of(context).push<dynamic>(
              MaterialPageRoute<dynamic>(
                builder: (BuildContext context) {
                  return UserCountryHistoryListPage(
                    appDomain: AppDomainType.user,
                    countryId: countryId,
                    countryName: countryName,
                  );

                  // refreshKennelInfo: () {
                  //  // return refreshCounters(kennelInfo.kennelId);
                  // });
                },
              ),
            ).then((void _) {
              // refreshCounters(kennelInfo.kennelId);
            });
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Padding(
                  padding: const EdgeInsets.only(left: 20.0),
                  child: Image.asset(
                    'images/flags/$flagFile',
                    height: 80,
                    width: 80,
                  )),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // const SizedBox(
                    //   height: 28,
                    //   width: 20,
                    // ),
                    Padding(
                      padding: const EdgeInsets.only(left: 48),
                      child: Text(
                        countryName,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: ts_titleCondensedBlack,
                        textAlign: TextAlign.left,
                      ),
                    ),
                    Text(
                      '  =  $runCount',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: ts_titleCondensedVeryLargeBlack,
                      textAlign: TextAlign.left,
                    ),
                    hareCount <= 0
                        ? const SizedBox(height: 20)
                        : Container(
                            height: 20.0,
                            padding: const EdgeInsets.only(left: 48.0),
                            child: Text(
                              '($hareCount times hared)',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: ts_titleMediumCondensedBlack.copyWith(
                                  fontSize: 18.0),
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
