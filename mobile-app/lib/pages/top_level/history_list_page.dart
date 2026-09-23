import 'package:harrier_central/imports.dart';

/// The History tab: my run counts by kennel and by country. Stateless over
/// [HistoryListController], which lives for the session like this tab does.
class HistoryListPage extends StatelessWidget {
  const HistoryListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HistoryListController>(
      init: HistoryListController(),
      tag: HistoryListController.tag,
      builder: (HistoryListController c) => AppScaffold(
        body: Obx(
          () => c.isLoading.value
              ? const Center(
                  child: HcAppCircularProgressIndicator(key: Key('600193968')),
                )
              : _buildListView(context, c),
        ),
      ),
    );
  }

  Widget _buildCountryStatsList(HistoryListController c) {
    final List<CountryStats> countries = c.countries;
    return Expanded(
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: countries.length,
        padding: const EdgeInsets.only(top: 20),
        itemExtent: 100.0,
        itemBuilder: (BuildContext context, int index) {
          if (index >= countries.length) return const SizedBox.shrink();
          final CountryStats stats = countries[index];
          if (stats.runCount == 0) return Container();
          return CountryRunHistoryCountListItem(
            countryId: stats.countryId,
            countryName: stats.countryName,
            flagFile: stats.flagFile,
            runCount: stats.runCount,
            hareCount: stats.hareCount,
          );
        },
      ),
    );
  }

  Widget _buildKennelStatsList(HistoryListController c) {
    // Snapshot the list for this build so itemCount and itemBuilder can never
    // disagree, however the field is mutated while the frame is in flight.
    final List<RunHistoryModel> kennels = c.kennels;
    return Expanded(
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: kennels.length,
        padding: const EdgeInsets.only(top: 20),
        itemExtent: 100.0,
        itemBuilder: (BuildContext context, int index) {
          if (index >= kennels.length) return const SizedBox.shrink();
          return KennelRunHistoryCountListItem(
            kennelInfo: kennels[index],
            // Re-reads the stats and hands back the fresh row: this runs after
            // the refresh has swapped a new list in, and the caller wants it.
            refreshCounters: (String kennelId) => c.refreshKennelRow(kennelId),
          );
        },
      ),
    );
  }

  Widget _buildListView(BuildContext context, HistoryListController c) {
    final String? photo = getStringPref(StringPrefsEnum.profilePhotoUrl);
    final int tabIndex = c.tabIndex.value;
    final int kennelCount = c.kennels.length;
    final int countryCount = c.countries.length;
    return Stack(
      children: <Widget>[
        Container(
          margin: const EdgeInsets.only(top: 105),
          decoration: Backgrounds.defaultHcBackgroundLight(),
          padding: const EdgeInsets.only(top: 0.0),
          child: kennelCount == 0
              ? Center(child: Text('No runs logged yet.', style: ts_title))
              : RefreshIndicator(
                  onRefresh: c.pullToRefresh,
                  displacement: 40.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.max,
                    children: <Widget>[
                      Container(
                        width: 200,
                        padding: const EdgeInsets.only(
                          left: 30,
                          right: 30,
                          top: 10.0,
                        ),
                        child: DefaultTabController(
                          length: 2,
                          child: Container(
                            padding: const EdgeInsets.all(8.0),
                            width: 140.0,
                            height: 75.0,
                            // reviewed for 2.0+
                            child: TabBar(
                              labelStyle: ts_tabSelected,
                              unselectedLabelStyle: ts_tabUnselected,
                              isScrollable: false,
                              unselectedLabelColor: Colors.white,
                              labelColor: Colors.white,
                              labelPadding: const EdgeInsets.only(
                                top: 5,
                                left: 0,
                                right: 0,
                              ),
                              indicatorSize: TabBarIndicatorSize.label,
                              indicatorPadding: EdgeInsets.symmetric(
                                horizontal: -5.0,
                                vertical: 13.0,
                              ),
                              indicator: BoxDecoration(
                                color: hc_red,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              tabs: <Tab>[
                                Tab(
                                  child: Container(
                                    alignment: Alignment.center,
                                    width: 140,
                                    child: Text(
                                      'By Kennel',
                                      style: ts_numberStyle.copyWith(
                                        color: tabIndex == 0
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                                Tab(
                                  child: Container(
                                    alignment: Alignment.center,
                                    width: 140,
                                    child: Text(
                                      'By Country',
                                      style: ts_numberStyle.copyWith(
                                        color: tabIndex == 1
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              controller: c.tabController,
                            ),
                          ),
                        ),
                      ),
                      tabIndex == 0
                          ? _buildKennelStatsList(c)
                          : _buildCountryStatsList(c),
                    ],
                  ),
                ),
        ),
        Positioned(
          top: 0,
          left: 0,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Color.fromARGB(70, 0, 0, 0),
                  offset: Offset(0.0, 6.0),
                  blurRadius: 10.0,
                ),
              ],
            ),
            height: 120,
            width: MediaQuery.sizeOf(context).width,
            child: Row(
              children: <Widget>[
                ProfilePhoto(
                  leftPadding: 20.0,
                  photoHeight: 80.0,
                  profilePhotoUrl: photo,
                ),
                const SizedBox(width: 20),
                kennelCount == 0
                    ? Container()
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'My total run counts',
                            style: ts_titleMediumBold.copyWith(
                              height: 1.2,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            'Total runs: ${c.totalRuns.value}',
                            style: ts_titleMedium.copyWith(
                              height: 1.2,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.left,
                          ),
                          Text(
                            'Total times hared: ${c.totalHaring.value}',
                            style: ts_titleMedium.copyWith(
                              height: 1.2,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.left,
                          ),
                          // How far the hashing has spread, not just how much
                          // of it there has been (James, 2026-09-17). Both
                          // lists are filled by setupInitialValues() before
                          // this builds, whichever tab is showing.
                          Text(
                            '$kennelCount '
                            '${kennelCount == 1 ? 'kennel' : 'kennels'} '
                            'in $countryCount '
                            '${countryCount == 1 ? 'country' : 'countries'}',
                            style: ts_titleMedium.copyWith(
                              height: 1.2,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
