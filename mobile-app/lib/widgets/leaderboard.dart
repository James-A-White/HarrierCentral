// ignore_for_file: constant_identifier_names

import 'package:harrier_central/imports.dart';

/// The leaderboard, for one kennel (kennel admin) or all of them (drawer).
/// Stateless over [LeaderboardController].
class Leaderboard extends StatelessWidget {
  const Leaderboard({super.key, this.kennelId});

  final String? kennelId;

  static const double LEADER_FONT_SIZE = 22.0;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LeaderboardController>(
      init: LeaderboardController(kennelId: kennelId),
      tag: LeaderboardController.tagFor(kennelId),
      builder: (LeaderboardController c) => Obx(() => _body(context, c)),
    );
  }

  Widget _body(BuildContext context, LeaderboardController c) {
    // Snapshots inside the Obx so childCount and the builder agree.
    final List<LeaderboardModel> rows = c.filteredRows;
    final List<LeaderboardModel> agg = c.filteredAggregate;
    final bool showKennels = c.showKennels.value;
    final bool showHomeKennel = c.showHomeKennel.value;
    final int tab = c.tabIndex.value;
    final int sortCol = c.sortColumn.value;
    final bool sortAsc = c.sortAsc.value;
    return Center(
      child: Column(
        children: <Widget>[
          Expanded(
            child: c.isLoading.value
                ? const SizedBox(
                    width: 70.0,
                    height: 70.0,
                    child: Padding(
                      padding: EdgeInsets.all(5.0),
                      child: Center(
                        child: HcAppCircularProgressIndicator(
                          key: Key('22030392'),
                        ),
                      ),
                    ),
                  )
                : rows.isEmpty
                ? const Center(
                    child: Text(
                      'No history',
                      style: TextStyle(
                        fontFamily: 'AvenirNextCondensedMedium',
                        fontSize: 22.0,
                        color: Colors.white70,
                      ),
                    ),
                  )
                : Column(
                    children: <Widget>[
                      Expanded(
                        child: SizedBox(
                          width: MediaQuery.sizeOf(context).width,
                          child: CustomScrollView(
                            controller: c.leaderScrollController,
                            slivers: <Widget>[
                              SliverAppBar(
                                toolbarHeight: kennelId == null ? 150.0 : 101.0,
                                floating: true,
                                backgroundColor: Colors.grey.shade400,
                                shadowColor: Colors.transparent,
                                automaticallyImplyLeading: false,
                                flexibleSpace: Column(
                                  children: <Widget>[
                                    _searchBar(c),
                                    Container(
                                      // decoration: BoxDecoration(
                                      //   color: Colors.grey[300],
                                      //   borderRadius: BorderRadius.circular(
                                      //     999,
                                      height: 50.0,
                                      padding: const EdgeInsets.all(5.0),
                                      // reviewed for 2.0+
                                      child: TabBar(
                                        onTap: (int _) => c.onTabTap(),
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        labelStyle: ts_tabSelected,
                                        unselectedLabelStyle: ts_tabUnselected,
                                        isScrollable: false,
                                        unselectedLabelColor: Colors.black,
                                        labelColor: Colors.white,
                                        labelPadding: const EdgeInsets.only(
                                          top: 5,
                                          left: 0,
                                          right: 0,
                                        ),
                                        indicatorPadding:
                                            EdgeInsetsGeometry.only(
                                              top: 3,
                                              bottom: 3,
                                            ),
                                        indicatorSize: TabBarIndicatorSize.tab,
                                        indicator: BoxDecoration(
                                          color: hc_red,
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        tabs: <Tab>[
                                          const Tab(text: '365 days'),
                                          Tab(
                                            text: 'In ${DateTime.now().year}',
                                          ),
                                          const Tab(text: 'Total'),
                                        ],
                                        controller: c.timespanTabController,
                                      ),
                                    ),
                                    const Divider(
                                      color: Colors.black45,
                                      thickness: 1.0,
                                      height: 1.0,
                                    ),
                                    if (kennelId == null) ...<Widget>[
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Checkbox(
                                            value: showKennels,
                                            checkColor: Colors.white,
                                            activeColor: hc_red,
                                            onChanged: (value) =>
                                                c.toggleShowKennels(),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 3.0,
                                            ),
                                            child: Text(
                                              'Show Kennels',
                                              style: showKennels
                                                  ? const TextStyle(
                                                      fontFamily:
                                                          'AvenirNextCondensedBold',
                                                      fontStyle:
                                                          FontStyle.normal,
                                                      fontSize: 18.0,
                                                      height: 1.0,
                                                    )
                                                  : const TextStyle(
                                                      fontFamily:
                                                          'AvenirNextCondensedMedium',
                                                      fontStyle:
                                                          FontStyle.normal,
                                                      fontSize: 18.0,
                                                      height: 1.0,
                                                    ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Checkbox(
                                            value: showHomeKennel,
                                            checkColor: Colors.white,
                                            activeColor: hc_red,
                                            onChanged: (value) =>
                                                c.toggleShowHomeKennel(),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 3.0,
                                            ),
                                            child: Text(
                                              'Home Kennel',
                                              style: showHomeKennel
                                                  ? const TextStyle(
                                                      fontFamily:
                                                          'AvenirNextCondensedBold',
                                                      fontStyle:
                                                          FontStyle.normal,
                                                      fontSize: 20.0,
                                                      height: 1.0,
                                                    )
                                                  : const TextStyle(
                                                      fontFamily:
                                                          'AvenirNextCondensedMedium',
                                                      fontStyle:
                                                          FontStyle.normal,
                                                      fontSize: 20.0,
                                                      height: 1.0,
                                                    ),
                                            ),
                                          ),
                                          const SizedBox(width: 15),
                                        ],
                                      ),
                                      const Divider(
                                        color: Colors.black45,
                                        thickness: 1.0,
                                        height: 1.0,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              SliverAppBar(
                                pinned: true,
                                toolbarHeight: 60.0,
                                backgroundColor: const Color.fromARGB(
                                  255,
                                  26,
                                  0,
                                  65,
                                ),
                                automaticallyImplyLeading: false,
                                flexibleSpace: Column(
                                  children: [
                                    const SizedBox(height: 10.0),
                                    Row(
                                      children: <Widget>[
                                        const SizedBox(width: 4.0),
                                        GestureDetector(
                                          onTap: () =>
                                              c.sortLeaderboard(0, true),
                                          child: SizedBox(
                                            width: 50.0,
                                            child: Text(
                                              'Runs',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontFamily: sortCol == 0
                                                    ? 'AvenirNextCondensedBold'
                                                    : 'AvenirNextCondensedMedium',
                                                fontStyle: FontStyle.normal,
                                                fontSize: LEADER_FONT_SIZE,
                                                height: 1.0,
                                                color: Colors.yellow,
                                              ),
                                            ),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () =>
                                              c.sortLeaderboard(1, true),
                                          child: SizedBox(
                                            width: 70.0,
                                            child: Text(
                                              'Hared',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontFamily: sortCol == 1
                                                    ? 'AvenirNextCondensedBold'
                                                    : 'AvenirNextCondensedMedium',
                                                fontStyle: FontStyle.normal,
                                                fontSize: LEADER_FONT_SIZE,
                                                height: 1.0,
                                                color: Colors.yellow,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () =>
                                                c.sortLeaderboard(2, true),
                                            child: Text(
                                              'Hasher',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontFamily: sortCol == 2
                                                    ? 'AvenirNextCondensedBold'
                                                    : 'AvenirNextCondensedMedium',
                                                fontStyle: FontStyle.normal,
                                                fontSize: LEADER_FONT_SIZE,
                                                height: 1.0,
                                                color: Colors.yellow,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 50.0),
                                      ],
                                    ),
                                    Row(
                                      children: <Widget>[
                                        GestureDetector(
                                          onTap: () =>
                                              c.sortLeaderboard(0, true),
                                          child: SizedBox(
                                            width: 50.0,
                                            child: sortCol != 0
                                                ? null
                                                : Icon(
                                                    sortAsc
                                                        ? AntDesign.caretup
                                                        : AntDesign.caretdown,
                                                    size: 20.0,
                                                    color: Colors.yellow,
                                                  ),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () =>
                                              c.sortLeaderboard(1, true),
                                          child: SizedBox(
                                            width: 70.0,
                                            child: sortCol != 1
                                                ? null
                                                : Icon(
                                                    sortAsc
                                                        ? AntDesign.caretup
                                                        : AntDesign.caretdown,
                                                    size: 20.0,
                                                    color: Colors.yellow,
                                                  ),
                                          ),
                                        ),
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () =>
                                                c.sortLeaderboard(2, true),
                                            child: SizedBox(
                                              child: sortCol != 2
                                                  ? null
                                                  : Icon(
                                                      sortAsc
                                                          ? AntDesign.caretup
                                                          : AntDesign.caretdown,
                                                      size: 20.0,
                                                      color: Colors.yellow,
                                                    ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 50.0),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              SliverToBoxAdapter(
                                child: SizedBox(
                                  child: rows.isEmpty
                                      ? Container(
                                          height: 400.0,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20.0,
                                          ),
                                          child: Center(
                                            child: Text(
                                              'No leaderboard records found',
                                              style: ts_titleLarge,
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        )
                                      : const SizedBox(height: 15),
                                ),
                              ),
                              SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    if (index ==
                                        (showKennels
                                            ? rows.length
                                            : agg.length)) {
                                      return const SizedBox(height: 50);
                                    }

                                    LeaderboardModel e = !showKennels
                                        ? agg[index]
                                        : rows[index];
                                    return Column(
                                      children: [
                                        const SizedBox(height: 3.0),
                                        Row(
                                          // Counts sit level with the name's
                                          // first line when it wraps.
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            SizedBox(
                                              width: 50.0,
                                              child: Text(
                                                (tab ==
                                                            LeaderboardController
                                                                .TABINDEX_TOTAL
                                                        ? e.totalRunCount
                                                        : tab ==
                                                              LeaderboardController
                                                                  .TABINDEX_365_DAYS
                                                        ? e.rollingYearTotalRunCount
                                                        : e.ytdTotalRunCount)
                                                    .toString(),
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  fontFamily:
                                                      'AvenirNextCondensedMedium',
                                                  fontStyle: FontStyle.normal,
                                                  fontSize: LEADER_FONT_SIZE,
                                                  height: 1.0,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              width: 70.0,
                                              child: Text(
                                                (tab ==
                                                            LeaderboardController
                                                                .TABINDEX_TOTAL
                                                        ? e.totalHaringCount
                                                        : tab ==
                                                              LeaderboardController
                                                                  .TABINDEX_365_DAYS
                                                        ? e.rollingYearHaringCount
                                                        : e.ytdHaringCount)
                                                    .toString(),
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  fontFamily:
                                                      'AvenirNextCondensedMedium',
                                                  fontStyle: FontStyle.normal,
                                                  fontSize: LEADER_FONT_SIZE,
                                                  height: 1.0,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              // One wrapping line of text, not a sideways
                                              // scroller: a long kennel name ran off the
                                              // edge with nothing to say there was more.
                                              child: Text.rich(
                                                TextSpan(
                                                  style: const TextStyle(
                                                    fontFamily:
                                                        'AvenirNextCondensedMedium',
                                                    fontStyle: FontStyle.normal,
                                                    fontSize: LEADER_FONT_SIZE,
                                                    height: 1.0,
                                                    color: Colors.white,
                                                  ),
                                                  children: <InlineSpan>[
                                                    TextSpan(
                                                      text: e.displayName,
                                                    ),
                                                    if ((kennelId == null) &&
                                                        showHomeKennel &&
                                                        (e.homeKennelId !=
                                                            null) &&
                                                        (c.kennels[e
                                                                .homeKennelId]?["kennelShortName"] !=
                                                            null))
                                                      TextSpan(
                                                        text:
                                                            '  -  ${c.kennels[e.homeKennelId]!["kennelShortName"]}',
                                                        style: TextStyle(
                                                          fontStyle:
                                                              FontStyle.italic,
                                                          color: Colors
                                                              .blue
                                                              .shade100,
                                                        ),
                                                      ),
                                                    if ((kennelId == null) &&
                                                        showKennels &&
                                                        (c.kennels[e
                                                                .kennelId]?["kennelName"] !=
                                                            null))
                                                      TextSpan(
                                                        text:
                                                            '  -  ${c.kennels[e.kennelId]!["kennelName"]}',
                                                        style: TextStyle(
                                                          fontStyle:
                                                              FontStyle.italic,
                                                          color: Colors
                                                              .pink
                                                              .shade100,
                                                        ),
                                                      ),
                                                    if ((kennelId == null) &&
                                                        !showKennels)
                                                      TextSpan(
                                                        text:
                                                            '  -  ${tab == LeaderboardController.TABINDEX_TOTAL
                                                                ? e.kennelCountTotal
                                                                : tab == LeaderboardController.TABINDEX_365_DAYS
                                                                ? e.kennelCountRollingYear
                                                                : e.kennelCountYtd} Kennels',
                                                        style: TextStyle(
                                                          fontStyle:
                                                              FontStyle.italic,
                                                          color: Colors
                                                              .pink
                                                              .shade100,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    );
                                  },
                                  childCount: showKennels
                                      ? rows.length + 1
                                      : agg.length + 1,
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
      ),
    );
  }

  Widget _searchBar(LeaderboardController c) {
    return Container(
      height: 50,
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Divider(height: 2.0, thickness: 2.0),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 14.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      autocorrect: false,
                      onChanged: (String text) {
                        c.onSearchChanged(c.searchController.text);
                      },
                      focusNode: c.searchFocusNode,
                      controller: c.searchController,
                      keyboardType: TextInputType.text,
                      style: const TextStyle(
                        fontFamily: 'WorkSansSemiBold',
                        fontSize: 16.0,
                        color: Colors.black,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        icon: Icon(Icons.search, color: Colors.black),
                        hintText: 'Search...',
                        hintStyle: TextStyle(
                          fontFamily: 'WorkSansSemiBold',
                          fontSize: 16.0,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        shape: button_shape,
                        backgroundColor: Colors.white,
                      ),
                      child: const Text(
                        'X',
                        style: TextStyle(color: Colors.grey),
                      ),
                      onPressed: () {
                        c.searchController.text = '';
                        c.onSearchChanged(c.searchController.text);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
