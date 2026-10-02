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

  /// Everyone I've run with, most runs together first (E10.F1.S5). The
  /// search box filters the list on the phone; a hasher's real name is only
  /// matched where it is the name they show.
  Widget _buildHasherList(HistoryListController c) {
    final String q = c.coRunnerQuery.value;
    final List<HasherSummary> all = c.coRunners.toList();
    final bool loading = c.coRunnersLoading.value;
    final bool failed = c.coRunnersFailed.value;
    final List<HasherSummary> shown = <HasherSummary>[
      for (final HasherSummary h in all)
        if (h.matches(q)) h,
    ];
    return Expanded(
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              child: TextField(
                controller: c.coRunnerSearch,
                onChanged: (String v) => c.coRunnerQuery.value = v,
                decoration: InputDecoration(
                  hintText: "Search hashers you've run with",
                  border: InputBorder.none,
                  prefixIcon: const Icon(Icons.search, color: Colors.black),
                  suffixIcon: q.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close, color: Colors.black54),
                          onPressed: () {
                            c.coRunnerSearch.clear();
                            c.coRunnerQuery.value = '';
                          },
                        ),
                ),
              ),
            ),
          ),
          if (failed && all.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Showing the last list saved on this phone.',
                style: ts_bodySmall.copyWith(color: Colors.black54),
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(
            child: all.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: <Widget>[
                      const SizedBox(height: 40),
                      if (loading)
                        const Center(child: HcAppCircularProgressIndicator())
                      else
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: <Widget>[
                              Text(
                                failed
                                    ? "The list couldn't be loaded. It needs a connection."
                                    : "You haven't run with anyone yet.",
                                style: ts_title.copyWith(color: Colors.black87),
                                textAlign: TextAlign.center,
                              ),
                              if (failed) ...<Widget>[
                                const SizedBox(height: 10),
                                ElevatedButton(
                                  onPressed: () =>
                                      unawaited(c.loadCoRunners(force: true)),
                                  child: const Text(
                                    'Try again',
                                    style: TextStyle(color: Colors.white),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                    ],
                  )
                // The same rhythm as By Kennel: fixed 100-high rows.
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(top: 10, bottom: 24),
                    itemExtent: 100.0,
                    itemCount: shown.length,
                    itemBuilder: (BuildContext context, int i) {
                      if (i >= shown.length) return const SizedBox.shrink();
                      return HasherRunCountListItem(hasher: shown[i]);
                    },
                  ),
          ),
        ],
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
                  // By Hasher refreshes its own list, not the run counts.
                  onRefresh: () => tabIndex == HistoryListController.byHasherTab
                      ? c.loadCoRunners(force: true)
                      : c.pullToRefresh(),
                  displacement: 40.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.max,
                    children: <Widget>[
                      // Three choices, so the bar spans the width and each
                      // label shrinks rather than overflowing at a large
                      // text size (By Hasher, E10.F1.S5).
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                        child: SizedBox(
                          height: 60,
                          child: TabBar(
                            labelStyle: ts_tabSelected,
                            unselectedLabelStyle: ts_tabUnselected,
                            isScrollable: false,
                            dividerColor: Colors.transparent,
                            unselectedLabelColor: Colors.white,
                            labelColor: Colors.white,
                            labelPadding: const EdgeInsets.symmetric(
                              horizontal: 2,
                            ),
                            indicatorSize: TabBarIndicatorSize.tab,
                            indicatorPadding: const EdgeInsets.symmetric(
                              horizontal: 2.0,
                              vertical: 10.0,
                            ),
                            indicator: BoxDecoration(
                              color: hc_red,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            tabs: <Tab>[
                              for (final (int i, String label)
                                  in const <(int, String)>[
                                    (0, 'By Kennel'),
                                    (1, 'By Country'),
                                    (2, 'By Hasher'),
                                  ])
                                Tab(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      label,
                                      style: ts_numberStyle.copyWith(
                                        color: tabIndex == i
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                            controller: c.tabController,
                          ),
                        ),
                      ),
                      switch (tabIndex) {
                        0 => _buildKennelStatsList(c),
                        1 => _buildCountryStatsList(c),
                        _ => _buildHasherList(c),
                      },
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
                    // Shrinks only when the counts are wider (or taller)
                    // than the 120 dp header: 1.5x text on a small phone
                    // overflowed it (2026-09-25).
                    : Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Column(
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
                        ),
                      ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
