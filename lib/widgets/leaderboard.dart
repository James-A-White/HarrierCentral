// ignore_for_file: constant_identifier_names

import 'package:harrier_central/imports.dart';
import 'package:intl/intl.dart';

class LeaderboardModel {
  String displayName;
  int totalRunCount;
  int totalHaringCount;
  int ytdTotalRunCount;
  int ytdHaringCount;
  int rollingYearTotalRunCount;
  int rollingYearHaringCount;
  String kennelId;
  String? homeKennelId;
  String hasherId;
  int kennelCountTotal;
  int kennelCountYtd;
  int kennelCountRollingYear;
  String searchText;

  LeaderboardModel({
    required this.displayName,
    required this.totalRunCount,
    required this.totalHaringCount,
    required this.ytdTotalRunCount,
    required this.ytdHaringCount,
    required this.rollingYearTotalRunCount,
    required this.rollingYearHaringCount,
    required this.kennelId,
    this.homeKennelId,
    required this.hasherId,
    required this.kennelCountTotal,
    required this.kennelCountYtd,
    required this.kennelCountRollingYear,
    required this.searchText,
  });

  LeaderboardModel.fromJson(Map<String, dynamic> json)
    : displayName = json['a'],
      totalRunCount = json['b'],
      totalHaringCount = json['c'],
      ytdTotalRunCount = json['d'],
      ytdHaringCount = json['e'],
      rollingYearTotalRunCount = json['f'],
      rollingYearHaringCount = json['g'],
      kennelId = json['h'],
      homeKennelId = json['i'],
      hasherId = json['j'],
      kennelCountTotal = 0,
      kennelCountYtd = 0,
      kennelCountRollingYear = 0,
      searchText = '';

  LeaderboardModel.clone(LeaderboardModel lm)
    : displayName = lm.displayName,
      totalRunCount = lm.totalRunCount,
      totalHaringCount = lm.totalHaringCount,
      ytdTotalRunCount = lm.ytdTotalRunCount,
      ytdHaringCount = lm.ytdHaringCount,
      rollingYearTotalRunCount = lm.rollingYearTotalRunCount,
      rollingYearHaringCount = lm.rollingYearHaringCount,
      kennelId = lm.kennelId,
      homeKennelId = lm.homeKennelId,
      hasherId = lm.hasherId,
      kennelCountTotal = lm.kennelCountTotal,
      kennelCountYtd = lm.kennelCountYtd,
      kennelCountRollingYear = lm.kennelCountRollingYear,
      searchText = lm.searchText;
}

// Map<String, dynamic> toJson() {
//   final Map<String, dynamic> data = <String, dynamic>{};
//   data['displayName'] = displayName;
//   data['totalRunCount'] = totalRunCount;
//   data['totalHaringCount'] = totalHaringCount;
//   data['ytdTotalRunCount'] = ytdTotalRunCount;
//   data['ytdHaringCount'] = ytdHaringCount;
//   data['rollingYearTotalRunCount'] = rollingYearTotalRunCount;
//   data['rollingYearHaringCount'] = rollingYearHaringCount;
//   data['kennelId'] = kennelId;
//   data['homeKennelId'] = homeKennelId;
//   data['hasherId'] = hasherId;
//   data['kennelCountTotal'] = kennelCountTotal;
//   data['kennelCountYtd'] = kennelCountYtd;
//   data['kennelCountRollingYear'] = kennelCountRollingYear;
//   data['searchText'] = searchText;
//   return data;

class Leaderboard extends StatefulWidget {
  const Leaderboard({super.key, this.kennelId});

  final String? kennelId;

  @override
  LeaderboardState createState() => LeaderboardState();
}

class LeaderboardState extends State<Leaderboard>
    with TickerProviderStateMixin {
  late TabController _timespanTabController;
  Map<String, Map<String, dynamic>>? _kennels;

  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();

  List<LeaderboardModel>? _leaderboardList;
  List<LeaderboardModel>? _leaderboardAggregateList;

  List<LeaderboardModel> _filteredLeaderboardList = [];
  List<LeaderboardModel> _filteredLeaderboardAggregateList = [];

  bool _showKennels = false;
  bool _showHomeKennel = false;

  final ScrollController _leaderScrollController = ScrollController(
    keepScrollOffset: false,
    initialScrollOffset: 50.0,
  );

  static const int TABINDEX_365_DAYS = 0;
  static const int TABINDEX_CURRENT_YEAR = 1;
  static const int TABINDEX_TOTAL = 2;

  static const double LEADER_FONT_SIZE = 22.0;

  int _leaderboardSortColumnIndex = 0;
  bool _sortOrderAsc = false;

  @override
  void initState() {
    super.initState();
    _timespanTabController = TabController(vsync: this, length: 3);
    if (widget.kennelId != null) {
      _showKennels = true;
    }

    QueryKennels.queryKennelDetails().then((
      List<Map<String, dynamic>> kennels,
    ) {
      _kennels = {};

      for (Map<String, dynamic> kennel in kennels) {
        _kennels![kennel["kennelId"]] = kennel;
      }

      if (_filteredLeaderboardList.isEmpty) {
        _getLeaderboard().then((value) {
          setState(() {
            _leaderboardSortColumnIndex = 0;
            _sortOrderAsc = false;
            _sortLeaderboard(_leaderboardSortColumnIndex, false);
          });
        });
      }
    });
  }

  @override
  void dispose() {
    _leaderScrollController.dispose();
    super.dispose();
  }

  Future<void> _getLeaderboard() async {
    String responseBody;
    bool updateLocalLeaderboardCache = false;

    DateTime? lastLeaderboardUpdate = getDatePref(
      DatePrefsEnum.lastLeaderboardUpdate,
    );

    if ((widget.kennelId != null) ||
        (lastLeaderboardUpdate == null) ||
        (DateFormat('yyyyMMMdd').format(lastLeaderboardUpdate) !=
            DateFormat('yyyyMMMdd').format(DateTime.now()))) {
      final String userId = getStringPref(StringPrefsEnum.userId) ?? '';
      final String deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
      final String deviceSecret =
          getStringPref(StringPrefsEnum.deviceSecret) ?? '';

      final String accessToken = Utilities.generateToken(
        userId,
        'hcapp_getLeaderboard',
        paramString: deviceSecret,
      );

      final String body = jsonEncode(<String, Object?>{
        'queryType': 'getLeaderboard',
        'deviceId': deviceId,
        'accessToken': accessToken,
        'kennelId': widget.kennelId,
      });

      responseBody = await ServiceCommon.sendHttpPostV2(body);
      updateLocalLeaderboardCache = true;
    } else {
      responseBody = getStringPref(StringPrefsEnum.leaderboardJson) ?? '';
      updateLocalLeaderboardCache = false;
    }

    if (!responseBody.startsWith(ERROR_PREFIX)) {
      _filteredLeaderboardList = <LeaderboardModel>[];
      _filteredLeaderboardAggregateList = <LeaderboardModel>[];

      _leaderboardList = <LeaderboardModel>[];
      _leaderboardAggregateList = <LeaderboardModel>[];

      // temporarily cache the leaderboard
      if ((widget.kennelId == null) && updateLocalLeaderboardCache) {
        await setDatePref(DatePrefsEnum.lastLeaderboardUpdate, DateTime.now());
        await setStringPref(StringPrefsEnum.leaderboardJson, responseBody);
      }

      List<dynamic> jsonResults = json.decode(responseBody);

      Map<String, LeaderboardModel> leaderAggregateMap = {};

      jsonResults[0].forEach((element) {
        LeaderboardModel lm = LeaderboardModel.fromJson(element);
        lm.searchText =
            ' ${lm.displayName}, ${_kennels![lm.kennelId]!['searchText']}, ';
        if ((lm.homeKennelId != null) && (lm.homeKennelId!.isNotEmpty)) {
          lm.searchText += _kennels![lm.kennelId]!['searchText'];
        }
        _leaderboardList!.add(lm);

        // if we are doing this for all kennels
        if ((widget.kennelId == null) || (widget.kennelId!.isEmpty)) {
          if (leaderAggregateMap.containsKey(lm.hasherId)) {
            leaderAggregateMap[lm.hasherId]!.rollingYearHaringCount =
                (leaderAggregateMap[lm.hasherId]!.rollingYearHaringCount +
                    lm.rollingYearHaringCount);
            leaderAggregateMap[lm.hasherId]!.rollingYearTotalRunCount =
                (leaderAggregateMap[lm.hasherId]!.rollingYearTotalRunCount +
                    lm.rollingYearTotalRunCount);
            leaderAggregateMap[lm.hasherId]!.totalHaringCount =
                (leaderAggregateMap[lm.hasherId]!.totalHaringCount +
                    lm.totalHaringCount);
            leaderAggregateMap[lm.hasherId]!.totalRunCount =
                (leaderAggregateMap[lm.hasherId]!.totalRunCount +
                    lm.totalRunCount);
            leaderAggregateMap[lm.hasherId]!.ytdHaringCount =
                (leaderAggregateMap[lm.hasherId]!.ytdHaringCount +
                    lm.ytdHaringCount);
            leaderAggregateMap[lm.hasherId]!.ytdTotalRunCount =
                (leaderAggregateMap[lm.hasherId]!.ytdTotalRunCount +
                    lm.ytdTotalRunCount);
            leaderAggregateMap[lm.hasherId]!.searchText +=
                ' ${_kennels![lm.kennelId]!['searchText']}, ';

            if (lm.totalRunCount > 0) {
              leaderAggregateMap[lm.hasherId]!.kennelCountTotal =
                  (leaderAggregateMap[lm.hasherId]!.kennelCountTotal + 1);
            }

            if (lm.rollingYearTotalRunCount > 0) {
              leaderAggregateMap[lm.hasherId]!.kennelCountRollingYear =
                  (leaderAggregateMap[lm.hasherId]!.kennelCountRollingYear + 1);
            }

            if (lm.ytdTotalRunCount > 0) {
              leaderAggregateMap[lm.hasherId]!.kennelCountYtd =
                  (leaderAggregateMap[lm.hasherId]!.kennelCountYtd + 1);
            }
          } else {
            LeaderboardModel newLm = LeaderboardModel.clone(lm);
            newLm.searchText =
                ' ${newLm.displayName}, ${_kennels![newLm.kennelId]!['searchText']}, ';
            if ((newLm.homeKennelId != null) &&
                (newLm.homeKennelId!.isNotEmpty)) {
              newLm.searchText += _kennels![newLm.kennelId]!['searchText'];
            }

            if (lm.totalRunCount > 0) {
              newLm.kennelCountTotal = 1;
            }

            if (lm.rollingYearTotalRunCount > 0) {
              newLm.kennelCountRollingYear = 1;
            }

            if (lm.ytdTotalRunCount > 0) {
              newLm.kennelCountYtd = 1;
            }

            leaderAggregateMap[lm.hasherId] = newLm;
          }
        }
      });

      _leaderboardAggregateList = leaderAggregateMap.values.toList();

      _filteredLeaderboardAggregateList = _leaderboardAggregateList!.toList();
      if (_leaderboardList != null) {
        _filteredLeaderboardList =
            _leaderboardList!
                .map((item) => LeaderboardModel.clone(item))
                .toList();
      }
    }

    return;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: <Widget>[
          Expanded(
            child:
                _filteredLeaderboardList.isEmpty
                    ? const SizedBox(
                      width: 70.0,
                      height: 70.0,
                      child: Padding(
                        padding: EdgeInsets.all(5.0),
                        child: Center(
                          child: HcCircularProgressIndicator(
                            key: Key('22030392'),
                          ),
                        ),
                      ),
                    )
                    : Column(
                      children: <Widget>[
                        Expanded(
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width,
                            child: CustomScrollView(
                              controller: _leaderScrollController,
                              slivers: <Widget>[
                                SliverAppBar(
                                  toolbarHeight:
                                      widget.kennelId == null ? 155.0 : 106.0,
                                  floating: true,
                                  backgroundColor: Colors.grey.shade400,
                                  shadowColor: Colors.transparent,
                                  automaticallyImplyLeading: false,
                                  flexibleSpace: Column(
                                    children: <Widget>[
                                      _searchBar(),
                                      Container(
                                        padding: const EdgeInsets.only(
                                          left: 20.0,
                                          right: 20.0,
                                          top: 7.0,
                                        ),
                                        color: Colors.grey.shade400,
                                        child: TabBar(
                                          onTap: (void _) {
                                            _sortLeaderboard(
                                              _leaderboardSortColumnIndex,
                                              false,
                                            );
                                            setState(() {});
                                          },
                                          labelStyle: const TextStyle(
                                            fontFamily:
                                                'AvenirNextCondensedBold',
                                            fontStyle: FontStyle.normal,
                                            fontSize: 18.0,
                                            height: 1.0,
                                          ),
                                          unselectedLabelStyle: const TextStyle(
                                            fontFamily:
                                                'AvenirNextCondensedMedium',
                                            fontStyle: FontStyle.normal,
                                            fontSize: 18.0,
                                            height: 1.0,
                                          ),
                                          isScrollable: false,
                                          unselectedLabelColor: Colors.black,
                                          labelColor: Colors.white,
                                          indicatorSize:
                                              TabBarIndicatorSize.tab,
                                          indicator: BubbleTabIndicator(
                                            indicatorHeight: 25.0,
                                            indicatorColor: hc_red,
                                            tabBarIndicatorSize:
                                                TabBarIndicatorSize.label,
                                            indicatorRadius: 10.0,
                                            padding: const EdgeInsets.only(
                                              top: 5.0,
                                            ),
                                          ),
                                          tabs: <Tab>[
                                            const Tab(text: '365 days'),
                                            Tab(
                                              text: 'In ${DateTime.now().year}',
                                            ),
                                            const Tab(text: 'Total'),
                                          ],
                                          controller: _timespanTabController,
                                        ),
                                      ),
                                      const Divider(
                                        color: Colors.black45,
                                        thickness: 1.0,
                                        height: 1.0,
                                      ),
                                      if (widget.kennelId == null) ...<Widget>[
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Checkbox(
                                              value: _showKennels,
                                              checkColor: Colors.white,
                                              activeColor: hc_red,
                                              onChanged: (value) {
                                                setState(() {
                                                  _showKennels = !_showKennels;
                                                });
                                              },
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 3.0,
                                              ),
                                              child: Text(
                                                'Show Kennels',
                                                style:
                                                    _showKennels
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
                                              value: _showHomeKennel,
                                              checkColor: Colors.white,
                                              activeColor: hc_red,
                                              onChanged: (value) {
                                                setState(() {
                                                  _showHomeKennel =
                                                      !_showHomeKennel;
                                                });
                                              },
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 3.0,
                                              ),
                                              child: Text(
                                                'Home Kennel',
                                                style:
                                                    _showHomeKennel
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
                                            onTap: () {
                                              setState(() {
                                                _sortLeaderboard(0, true);
                                              });
                                            },
                                            child: SizedBox(
                                              width: 50.0,
                                              child: Text(
                                                'Runs',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontFamily:
                                                      _leaderboardSortColumnIndex ==
                                                              0
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
                                            onTap: () {
                                              setState(() {
                                                _sortLeaderboard(1, true);
                                              });
                                            },
                                            child: SizedBox(
                                              width: 70.0,
                                              child: Text(
                                                'Hared',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontFamily:
                                                      _leaderboardSortColumnIndex ==
                                                              1
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
                                              onTap: () {
                                                setState(() {
                                                  _sortLeaderboard(2, true);
                                                });
                                              },
                                              child: Text(
                                                'Hasher',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontFamily:
                                                      _leaderboardSortColumnIndex ==
                                                              2
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
                                            onTap: () {
                                              setState(() {
                                                _sortLeaderboard(0, true);
                                              });
                                            },
                                            child: SizedBox(
                                              width: 50.0,
                                              child:
                                                  _leaderboardSortColumnIndex !=
                                                          0
                                                      ? null
                                                      : Icon(
                                                        _sortOrderAsc
                                                            ? AntDesign.caretup
                                                            : AntDesign
                                                                .caretdown,
                                                        size: 20.0,
                                                        color: Colors.yellow,
                                                      ),
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _sortLeaderboard(1, true);
                                              });
                                            },
                                            child: SizedBox(
                                              width: 70.0,
                                              child:
                                                  _leaderboardSortColumnIndex !=
                                                          1
                                                      ? null
                                                      : Icon(
                                                        _sortOrderAsc
                                                            ? AntDesign.caretup
                                                            : AntDesign
                                                                .caretdown,
                                                        size: 20.0,
                                                        color: Colors.yellow,
                                                      ),
                                            ),
                                          ),
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _sortLeaderboard(2, true);
                                                });
                                              },
                                              child: SizedBox(
                                                child:
                                                    _leaderboardSortColumnIndex !=
                                                            2
                                                        ? null
                                                        : Icon(
                                                          _sortOrderAsc
                                                              ? AntDesign
                                                                  .caretup
                                                              : AntDesign
                                                                  .caretdown,
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
                                    child:
                                        _filteredLeaderboardList.isEmpty
                                            ? Container(
                                              height: 400.0,
                                              padding:
                                                  const EdgeInsets.symmetric(
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
                                          (_showKennels
                                              ? _filteredLeaderboardList.length
                                              : _filteredLeaderboardAggregateList
                                                  .length)) {
                                        return const SizedBox(height: 50);
                                      }

                                      LeaderboardModel e =
                                          !_showKennels
                                              ? _filteredLeaderboardAggregateList[index]
                                              : _filteredLeaderboardList[index];
                                      return Column(
                                        children: [
                                          const SizedBox(height: 3.0),
                                          Row(
                                            children: <Widget>[
                                              SizedBox(
                                                width: 50.0,
                                                child: Text(
                                                  (_timespanTabController
                                                                  .index ==
                                                              TABINDEX_TOTAL
                                                          ? e.totalRunCount
                                                          : _timespanTabController
                                                                  .index ==
                                                              TABINDEX_365_DAYS
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
                                                  (_timespanTabController
                                                                  .index ==
                                                              TABINDEX_TOTAL
                                                          ? e.totalHaringCount
                                                          : _timespanTabController
                                                                  .index ==
                                                              TABINDEX_365_DAYS
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
                                                child: SingleChildScrollView(
                                                  scrollDirection:
                                                      Axis.horizontal,
                                                  child: Row(
                                                    children: [
                                                      Text(
                                                        e.displayName,
                                                        style: const TextStyle(
                                                          fontFamily:
                                                              'AvenirNextCondensedMedium',
                                                          fontStyle:
                                                              FontStyle.normal,
                                                          fontSize:
                                                              LEADER_FONT_SIZE,
                                                          height: 1.0,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                      if ((widget.kennelId ==
                                                              null) &&
                                                          _showHomeKennel &&
                                                          (e.homeKennelId !=
                                                              null))
                                                        Text(
                                                          '  -  ${_kennels![e.homeKennelId]!["kennelShortName"]}',
                                                          style: TextStyle(
                                                            fontFamily:
                                                                'AvenirNextCondensedMedium',
                                                            fontStyle:
                                                                FontStyle
                                                                    .italic,
                                                            fontSize:
                                                                LEADER_FONT_SIZE,
                                                            height: 1.0,
                                                            color:
                                                                Colors
                                                                    .blue
                                                                    .shade100,
                                                          ),
                                                        ),
                                                      if ((widget.kennelId ==
                                                              null) &&
                                                          _showKennels)
                                                        Text(
                                                          '  -  ${_kennels![e.kennelId]!["kennelName"]}',
                                                          style: TextStyle(
                                                            fontFamily:
                                                                'AvenirNextCondensedMedium',
                                                            fontStyle:
                                                                FontStyle
                                                                    .italic,
                                                            fontSize:
                                                                LEADER_FONT_SIZE,
                                                            height: 1.0,
                                                            color:
                                                                Colors
                                                                    .pink
                                                                    .shade100,
                                                          ),
                                                        ),
                                                      if ((widget.kennelId ==
                                                              null) &&
                                                          !_showKennels)
                                                        Text(
                                                          '  -  ${_timespanTabController.index == TABINDEX_TOTAL
                                                              ? e.kennelCountTotal
                                                              : _timespanTabController.index == TABINDEX_365_DAYS
                                                              ? e.kennelCountRollingYear
                                                              : e.kennelCountYtd} Kennels',
                                                          style: TextStyle(
                                                            fontFamily:
                                                                'AvenirNextCondensedMedium',
                                                            fontStyle:
                                                                FontStyle
                                                                    .italic,
                                                            fontSize:
                                                                LEADER_FONT_SIZE,
                                                            height: 1.0,
                                                            color:
                                                                Colors
                                                                    .pink
                                                                    .shade100,
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      );
                                    },
                                    childCount:
                                        _showKennels
                                            ? _filteredLeaderboardList.length +
                                                1
                                            : _filteredLeaderboardAggregateList
                                                    .length +
                                                1,
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

  Widget _searchBar() {
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
                        setState(() {
                          _filterResults(_searchController.text);
                          _sortLeaderboard(_leaderboardSortColumnIndex, false);
                        });
                      },
                      focusNode: _searchFocusNode,
                      controller: _searchController,
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
                        _searchController.text = '';
                        setState(() {
                          _filterResults(_searchController.text);
                          _sortLeaderboard(_leaderboardSortColumnIndex, false);
                        });
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

  void _sortLeaderboard(int columnIndex, bool alternateSortOrder) {
    if ((_filteredLeaderboardList.isNotEmpty) ||
        (_filteredLeaderboardAggregateList.isNotEmpty)) {
      if (alternateSortOrder && (columnIndex == _leaderboardSortColumnIndex)) {
        _sortOrderAsc = !_sortOrderAsc;
      }

      _leaderboardSortColumnIndex = columnIndex;

      switch (_leaderboardSortColumnIndex) {
        // sort runs
        case 0:
          switch (_timespanTabController.index) {
            case TABINDEX_TOTAL:
              _filteredLeaderboardList.sort((a, b) {
                int cmp = a.totalRunCount.compareTo(b.totalRunCount);
                if (cmp != 0) return _sortOrderAsc ? cmp : -cmp;
                return a.displayName.toLowerCase().compareTo(
                  b.displayName.toLowerCase(),
                );
              });
              _filteredLeaderboardAggregateList.sort((a, b) {
                int cmp = a.totalRunCount.compareTo(b.totalRunCount);
                if (cmp != 0) return _sortOrderAsc ? cmp : -cmp;
                return a.displayName.toLowerCase().compareTo(
                  b.displayName.toLowerCase(),
                );
              });
              break;
            case TABINDEX_365_DAYS:
              _filteredLeaderboardList.sort((a, b) {
                int cmp = a.rollingYearTotalRunCount.compareTo(
                  b.rollingYearTotalRunCount,
                );
                if (cmp != 0) return _sortOrderAsc ? cmp : -cmp;
                return a.displayName.toLowerCase().compareTo(
                  b.displayName.toLowerCase(),
                );
              });
              _filteredLeaderboardAggregateList.sort((a, b) {
                int cmp = a.rollingYearTotalRunCount.compareTo(
                  b.rollingYearTotalRunCount,
                );
                if (cmp != 0) return _sortOrderAsc ? cmp : -cmp;
                return a.displayName.toLowerCase().compareTo(
                  b.displayName.toLowerCase(),
                );
              });
              break;

            case TABINDEX_CURRENT_YEAR:
              _filteredLeaderboardList.sort((a, b) {
                int cmp = a.ytdTotalRunCount.compareTo(b.ytdTotalRunCount);
                if (cmp != 0) return _sortOrderAsc ? cmp : -cmp;
                return a.displayName.toLowerCase().compareTo(
                  b.displayName.toLowerCase(),
                );
              });
              _filteredLeaderboardAggregateList.sort((a, b) {
                int cmp = a.ytdTotalRunCount.compareTo(b.ytdTotalRunCount);
                if (cmp != 0) return _sortOrderAsc ? cmp : -cmp;
                return a.displayName.toLowerCase().compareTo(
                  b.displayName.toLowerCase(),
                );
              });
              break;
          }
          break;
        // sort haring
        case 1:
          switch (_timespanTabController.index) {
            case TABINDEX_TOTAL:
              _filteredLeaderboardList.sort((a, b) {
                int cmp = a.totalHaringCount.compareTo(b.totalHaringCount);
                if (cmp != 0) return _sortOrderAsc ? cmp : -cmp;
                return a.displayName.toLowerCase().compareTo(
                  b.displayName.toLowerCase(),
                );
              });
              _filteredLeaderboardAggregateList.sort((a, b) {
                int cmp = a.totalHaringCount.compareTo(b.totalHaringCount);
                if (cmp != 0) return _sortOrderAsc ? cmp : -cmp;
                return a.displayName.toLowerCase().compareTo(
                  b.displayName.toLowerCase(),
                );
              });
              break;
            case TABINDEX_365_DAYS:
              _filteredLeaderboardList.sort((a, b) {
                int cmp = a.rollingYearHaringCount.compareTo(
                  b.rollingYearHaringCount,
                );
                if (cmp != 0) return _sortOrderAsc ? cmp : -cmp;
                return a.displayName.toLowerCase().compareTo(
                  b.displayName.toLowerCase(),
                );
              });
              _filteredLeaderboardAggregateList.sort((a, b) {
                int cmp = a.rollingYearHaringCount.compareTo(
                  b.rollingYearHaringCount,
                );
                if (cmp != 0) return _sortOrderAsc ? cmp : -cmp;
                return a.displayName.toLowerCase().compareTo(
                  b.displayName.toLowerCase(),
                );
              });
              break;
            case TABINDEX_CURRENT_YEAR:
              _filteredLeaderboardList.sort((a, b) {
                int cmp = a.ytdHaringCount.compareTo(b.ytdHaringCount);
                if (cmp != 0) return _sortOrderAsc ? cmp : -cmp;
                return a.displayName.toLowerCase().compareTo(
                  b.displayName.toLowerCase(),
                );
              });
              _filteredLeaderboardAggregateList.sort((a, b) {
                int cmp = a.ytdHaringCount.compareTo(b.ytdHaringCount);
                if (cmp != 0) return _sortOrderAsc ? cmp : -cmp;
                return a.displayName.toLowerCase().compareTo(
                  b.displayName.toLowerCase(),
                );
              });
              break;
          }
          break;
        // sort by name
        case 2:
          _filteredLeaderboardList.sort((a, b) {
            int cmp = a.displayName.toLowerCase().compareTo(
              b.displayName.toLowerCase(),
            );
            if (cmp != 0) return _sortOrderAsc ? cmp : -cmp;
            return a.kennelId.toLowerCase().compareTo(b.kennelId.toLowerCase());
          });

          _filteredLeaderboardAggregateList.sort((a, b) {
            int cmp = a.displayName.toLowerCase().compareTo(
              b.displayName.toLowerCase(),
            );
            if (cmp != 0) return _sortOrderAsc ? cmp : -cmp;
            return a.kennelId.toLowerCase().compareTo(b.kennelId.toLowerCase());
          });

          break;
      }
    }
  }

  void _filterResults(String filter) {
    List<String> addParams = <String>[];
    List<String> subParams = <String>[];

    filter = filter.replaceAll('+ ', '+').replaceAll('- ', '-');

    int firstPositive = filter.indexOf('+');
    if (firstPositive >= 0) {
      addParams = Utilities.parseSearchTokens(filter, r"\+");
    }

    int firstNegative = filter.indexOf('-');
    if (firstNegative >= 0) {
      subParams = Utilities.parseSearchTokens(filter, r"-");
    }

    String firstTokenString = '';
    if ((firstPositive > 0) && (firstNegative > 0)) {
      int firstToken = min(firstPositive, firstNegative);
      firstTokenString = filter.substring(0, firstToken).trim().toLowerCase();
    } else if (firstPositive > 0) {
      firstTokenString =
          filter.substring(0, firstPositive).trim().toLowerCase();
    } else if (firstNegative > 0) {
      firstTokenString =
          filter.substring(0, firstNegative).trim().toLowerCase();
    } else {
      firstTokenString = filter.trim().toLowerCase();
    }

    if (firstTokenString.isNotEmpty) {
      addParams.add(firstTokenString);
    }

    _filteredLeaderboardList.clear();
    _filteredLeaderboardAggregateList.clear();

    if (filter.isNotEmpty) {
      _filteredLeaderboardList =
          _leaderboardList!.where((LeaderboardModel a) {
            for (String param in subParams) {
              if (a.searchText.toLowerCase().contains(param)) {
                return false;
              }
            }

            for (String param in addParams) {
              if (a.searchText.toLowerCase().contains(param)) {
                return true;
              }
            }

            return false;
          }).toList();

      _filteredLeaderboardAggregateList =
          _leaderboardAggregateList!.where((LeaderboardModel a) {
            for (String param in subParams) {
              if (a.searchText.toLowerCase().contains(param)) {
                return false;
              }
            }

            for (String param in addParams) {
              if (a.searchText.toLowerCase().contains(param)) {
                return true;
              }
            }

            return false;
          }).toList();
    } else {
      _filteredLeaderboardList.addAll(_leaderboardList!);
      _filteredLeaderboardAggregateList.addAll(_leaderboardAggregateList!);
    }
  }
}
