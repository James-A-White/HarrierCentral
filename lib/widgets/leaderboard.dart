// @dart=2.11
import 'package:harrier_central/imports.dart';

class LeaderboardModel {
  String displayName;
  int totalRunCount;
  int totalHaringCount;
  int ytdTotalRunCount;
  int ytdHaringCount;
  int rollingYearTotalRunCount;
  int rollingYearHaringCount;
  String kennelName;
  String kennelShortName;
  String hasherId;
  int kennelCountTotal;
  int kennelCountYtd;
  int kennelCountRollingYear;

  LeaderboardModel({
    this.displayName,
    this.totalRunCount,
    this.totalHaringCount,
    this.ytdTotalRunCount,
    this.ytdHaringCount,
    this.rollingYearTotalRunCount,
    this.rollingYearHaringCount,
    this.kennelName,
    this.kennelShortName,
    this.hasherId,
    this.kennelCountTotal,
    this.kennelCountYtd,
    this.kennelCountRollingYear,
  });

  LeaderboardModel.fromJson(Map<String, dynamic> json) {
    displayName = json['displayName'];
    totalRunCount = json['totalRunCount'];
    totalHaringCount = json['totalHaringCount'];
    ytdTotalRunCount = json['ytdTotalRunCount'];
    ytdHaringCount = json['ytdHaringCount'];
    rollingYearTotalRunCount = json['rollingYearTotalRunCount'];
    rollingYearHaringCount = json['rollingYearHaringCount'];
    kennelName = json['kennelName'];
    kennelShortName = json['kennelShortName'];
    hasherId = json['hasherId'];
    kennelCountTotal = 0;
    kennelCountYtd = 0;
    kennelCountRollingYear = 0;
  }

  LeaderboardModel.clone(LeaderboardModel lm) {
    displayName = lm.displayName;
    totalRunCount = lm.totalRunCount;
    totalHaringCount = lm.totalHaringCount;
    ytdTotalRunCount = lm.ytdTotalRunCount;
    ytdHaringCount = lm.ytdHaringCount;
    rollingYearTotalRunCount = lm.rollingYearTotalRunCount;
    rollingYearHaringCount = lm.rollingYearHaringCount;
    kennelName = lm.kennelName;
    kennelShortName = lm.kennelShortName;
    hasherId = lm.hasherId;
    kennelCountTotal = lm.kennelCountTotal;
    kennelCountYtd = lm.kennelCountYtd;
    kennelCountRollingYear = lm.kennelCountRollingYear;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['displayName'] = displayName;
    data['totalRunCount'] = totalRunCount;
    data['totalHaringCount'] = totalHaringCount;
    data['ytdTotalRunCount'] = ytdTotalRunCount;
    data['ytdHaringCount'] = ytdHaringCount;
    data['rollingYearTotalRunCount'] = rollingYearTotalRunCount;
    data['rollingYearHaringCount'] = rollingYearHaringCount;
    data['kennelName'] = kennelName;
    data['kennelShortName'] = kennelShortName;
    data['hasherId'] = hasherId;
    data['kennelCountTotal'] = kennelCountTotal;
    data['kennelCountYtd'] = kennelCountYtd;
    data['kennelCountRollingYear'] = kennelCountRollingYear;
    return data;
  }
}

class Leaderboard extends StatefulWidget {
  const Leaderboard({Key key, this.kennelId}) : super(key: key);

  final String kennelId;

  @override
  LeaderboardState createState() => LeaderboardState();
}

class LeaderboardState extends State<Leaderboard> with TickerProviderStateMixin {
  @override
  void initState() {
    _timespanTabController = TabController(vsync: this, length: 3);
    if (widget.kennelId == null) {
      _scopeTabController = TabController(vsync: this, length: 2);
    }

    if (_leaderboardList == null) {
      _getLeaderboard().then(
        (value) {
          setState(() {
            _leaderboardSortColumnIndex = 0;
            _sortOrderAsc = false;
            _sortLeaderboard(_leaderboardSortColumnIndex, false);
          });
        },
      );
    }

    super.initState();
  }

  @override
  void dispose() {
    _leaderScrollController.dispose();
    super.dispose();
  }

  Future<void> _getLeaderboard() async {
    final String userId = getStringPref(StringPrefsEnum.userId);
    final String accessToken = IveCoreUtilities.generateToken(userId.toUpperCase(), 'getLeaderboard');

    final String body = jsonEncode(<String, Object>{
      'userId': userId,
      'accessToken': accessToken,
      'kennelId': widget.kennelId,
    });

    final String responseBody = await ServiceCommon.sendHttpPost('hc3_get_leaderboard', body);

    List<dynamic> jsonResults = json.decode(responseBody);

    _leaderboardList = <LeaderboardModel>[];
    _leaderboardAggregateList = <LeaderboardModel>[];

    Map<String, LeaderboardModel> leaderAggregateMap = {};

    jsonResults[0].forEach((element) {
      LeaderboardModel lm = LeaderboardModel.fromJson(element);
      _leaderboardList.add(lm);

      if ((widget.kennelId == null) || (widget.kennelId.isEmpty)) {
        if (leaderAggregateMap.containsKey(lm.hasherId)) {
          leaderAggregateMap[lm.hasherId].rollingYearHaringCount += lm.rollingYearHaringCount;
          leaderAggregateMap[lm.hasherId].rollingYearTotalRunCount += lm.rollingYearTotalRunCount;
          leaderAggregateMap[lm.hasherId].totalHaringCount += lm.totalHaringCount;
          leaderAggregateMap[lm.hasherId].totalRunCount += lm.totalRunCount;
          leaderAggregateMap[lm.hasherId].ytdHaringCount += lm.ytdHaringCount;
          leaderAggregateMap[lm.hasherId].ytdTotalRunCount += lm.ytdTotalRunCount;
          if (lm.totalRunCount > 0) {
            leaderAggregateMap[lm.hasherId].kennelCountTotal++;
          }

          if (lm.rollingYearTotalRunCount > 0) {
            leaderAggregateMap[lm.hasherId].kennelCountRollingYear++;
          }

          if (lm.ytdTotalRunCount > 0) {
            leaderAggregateMap[lm.hasherId].kennelCountYtd++;
          }
        } else {
          LeaderboardModel newLm = LeaderboardModel.clone(lm);

          if (lm.totalRunCount > 0) {
            newLm.kennelCountTotal++;
          }

          if (lm.rollingYearTotalRunCount > 0) {
            newLm.kennelCountRollingYear++;
          }

          if (lm.ytdTotalRunCount > 0) {
            newLm.kennelCountYtd++;
          }

          leaderAggregateMap.addAll({lm.hasherId: newLm});
        }
      }
    });

    _leaderboardAggregateList = leaderAggregateMap.values.toList();

    return;
  }

  TabController _timespanTabController;
  TabController _scopeTabController;

  List<LeaderboardModel> _leaderboardList;
  List<LeaderboardModel> _leaderboardAggregateList;

  final ScrollController _leaderScrollController = ScrollController();

  // ignore: constant_identifier_names
  static const int TABINDEX_365_DAYS = 0;
  // ignore: constant_identifier_names
  static const int TABINDEX_CURRENT_YEAR = 1;
  // ignore: constant_identifier_names
  static const int TABINDEX_TOTAL = 2;

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Column(
      children: <Widget>[
        Expanded(
          child: _leaderboardList == null
              ? const SizedBox(
                  //color: Colors.grey[300],
                  width: 70.0,
                  height: 70.0,
                  child: Padding(padding: EdgeInsets.all(5.0), child: Center(child: HcCircularProgressIndicator(key: Key('22030392')))),
                )
              : _leaderboardList.isEmpty
                  ? Column(
                      children: <Widget>[
                        const Expanded(flex: 40, child: SizedBox()),
                        Text(
                          'No run counts\r\nregistered for\r\nthis Kennel.',
                          style: largeTitleStyle,
                          textAlign: TextAlign.center,
                        ),
                        const Expanded(flex: 100, child: SizedBox()),
                      ],
                    )
                  : Column(
                      children: <Widget>[
                        if (widget.kennelId == null) ...<Widget>[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0),
                            //width: 140.0,
                            child: TabBar(
                              onTap: (void _) {
                                //_sortLeaderboard(_leaderboardSortColumnIndex, false);
                                setState(() {});
                              },
                              labelStyle: const TextStyle(fontFamily: 'AvenirNextCondensedBold', fontStyle: FontStyle.normal, fontSize: 18.0, height: 1.0),
                              unselectedLabelStyle: const TextStyle(fontFamily: 'AvenirNextCondensedMedium', fontStyle: FontStyle.normal, fontSize: 18.0, height: 1.0),
                              isScrollable: false,
                              unselectedLabelColor: Colors.white,
                              labelColor: Colors.white,
                              //labelPadding: const EdgeInsets.only(top: 3, left: 20, right: 20),
                              indicatorSize: TabBarIndicatorSize.tab,
                              indicator: BubbleTabIndicator(
                                  indicatorHeight: 25.0,
                                  indicatorColor: Colors.red.shade900,
                                  tabBarIndicatorSize: TabBarIndicatorSize.label,
                                  indicatorRadius: 20.0,
                                  bubblePadding: const EdgeInsets.only(top: 5.0)
                                  //insets: const EdgeInsets.only(bottom: 5),
                                  ),
                              tabs: const <Tab>[
                                Tab(text: 'Combined'),
                                Tab(text: 'By Kennel'),
                              ],
                              controller: _scopeTabController,
                            ),
                          ),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          //width: 140.0,
                          child: TabBar(
                            onTap: (void _) {
                              _sortLeaderboard(_leaderboardSortColumnIndex, false);
                              setState(() {});
                            },
                            labelStyle: const TextStyle(fontFamily: 'AvenirNextCondensedBold', fontStyle: FontStyle.normal, fontSize: 18.0, height: 1.0),
                            unselectedLabelStyle: const TextStyle(fontFamily: 'AvenirNextCondensedMedium', fontStyle: FontStyle.normal, fontSize: 18.0, height: 1.0),
                            isScrollable: false,
                            unselectedLabelColor: Colors.white,
                            labelColor: Colors.white,
                            //labelPadding: const EdgeInsets.only(top: 3, left: 20, right: 20),
                            indicatorSize: TabBarIndicatorSize.tab,
                            indicator: BubbleTabIndicator(
                                indicatorHeight: 25.0,
                                indicatorColor: Colors.red.shade900,
                                tabBarIndicatorSize: TabBarIndicatorSize.label,
                                indicatorRadius: 20.0,
                                bubblePadding: const EdgeInsets.only(top: 5.0)
                                //insets: const EdgeInsets.only(bottom: 5),
                                ),
                            tabs: <Tab>[
                              const Tab(text: '365 days'),
                              Tab(text: 'In ${DateTime.now().year}'),
                              const Tab(text: 'Total'),
                            ],
                            controller: _timespanTabController,
                          ),
                        ),
                        const SizedBox(
                          height: 10.0,
                        ),
                        Expanded(
                          child: Container(
                            //key: packListBox,
                            color: const Color.fromARGB(60, 255, 255, 255),
                            margin: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 15.0),
                            padding: const EdgeInsets.all(8.0),
                            width: MediaQuery.of(context).size.width,
                            child: Scrollbar(
                                controller: _leaderScrollController,
                                child: Column(
                                  children: <Widget>[
                                    Row(
                                      children: <Widget>[
                                        GestureDetector(
                                          onTap: () {
                                            setState(
                                              () {
                                                _sortLeaderboard(0, true);
                                              },
                                            );
                                          },
                                          child: SizedBox(
                                            width: 50.0,
                                            child: Text(
                                              'Runs',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontFamily: _leaderboardSortColumnIndex == 0 ? 'AvenirNextCondensedBold' : 'AvenirNextCondensedMedium',
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
                                            setState(
                                              () {
                                                _sortLeaderboard(1, true);
                                              },
                                            );
                                          },
                                          child: SizedBox(
                                            width: 70.0,
                                            child: Text(
                                              'Hared',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontFamily: _leaderboardSortColumnIndex == 1 ? 'AvenirNextCondensedBold' : 'AvenirNextCondensedMedium',
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
                                                fontFamily: _leaderboardSortColumnIndex == 2 ? 'AvenirNextCondensedBold' : 'AvenirNextCondensedMedium',
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
                                            child: _leaderboardSortColumnIndex != 0
                                                ? null
                                                : Icon(
                                                    _sortOrderAsc ? AntDesign.caretup : AntDesign.caretdown,
                                                    size: 20.0,
                                                    color: Colors.yellow,
                                                  ),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            setState(
                                              () {
                                                _sortLeaderboard(1, true);
                                              },
                                            );
                                          },
                                          child: SizedBox(
                                            width: 70.0,
                                            child: _leaderboardSortColumnIndex != 1
                                                ? null
                                                : Icon(
                                                    _sortOrderAsc ? AntDesign.caretup : AntDesign.caretdown,
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
                                              child: _leaderboardSortColumnIndex != 2
                                                  ? null
                                                  : Icon(
                                                      _sortOrderAsc ? AntDesign.caretup : AntDesign.caretdown,
                                                      size: 20.0,
                                                      color: Colors.yellow,
                                                    ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 50.0),
                                      ],
                                    ),
                                    const SizedBox(height: 7.0),
                                    Expanded(
                                      child: ListView.separated(
                                          separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 3.0),
                                          physics: const AlwaysScrollableScrollPhysics(),
                                          controller: _leaderScrollController,
                                          itemCount: (_scopeTabController?.index ?? 1) == 0 ? _leaderboardAggregateList.length : _leaderboardList.length,
                                          itemBuilder: (BuildContext context, int index) {
                                            final LeaderboardModel e = (_scopeTabController?.index ?? 1) == 0 ? _leaderboardAggregateList[index] : _leaderboardList[index];
                                            return Row(
                                              children: <Widget>[
                                                SizedBox(
                                                    width: 50.0,
                                                    child: Text(
                                                        (_timespanTabController.index == TABINDEX_TOTAL
                                                                ? e.totalRunCount
                                                                : _timespanTabController.index == TABINDEX_365_DAYS
                                                                    ? e.rollingYearTotalRunCount
                                                                    : e.ytdTotalRunCount)
                                                            .toString(),
                                                        textAlign: TextAlign.center,
                                                        style: const TextStyle(
                                                          fontFamily: 'AvenirNextCondensedMedium',
                                                          fontStyle: FontStyle.normal,
                                                          fontSize: LEADER_FONT_SIZE,
                                                          height: 1.0,
                                                          color: Colors.white,
                                                        ))),
                                                SizedBox(
                                                    width: 70.0,
                                                    child: Text(
                                                        (_timespanTabController.index == TABINDEX_TOTAL
                                                                ? e.totalHaringCount
                                                                : _timespanTabController.index == TABINDEX_365_DAYS
                                                                    ? e.rollingYearHaringCount
                                                                    : e.ytdHaringCount)
                                                            .toString(),
                                                        textAlign: TextAlign.center,
                                                        style: const TextStyle(
                                                          fontFamily: 'AvenirNextCondensedMedium',
                                                          fontStyle: FontStyle.normal,
                                                          fontSize: LEADER_FONT_SIZE,
                                                          height: 1.0,
                                                          color: Colors.white,
                                                        ))),
                                                Expanded(
                                                    child: SingleChildScrollView(
                                                  scrollDirection: Axis.horizontal,
                                                  child: Row(
                                                    children: [
                                                      Text(
                                                        e.displayName ?? '<unknown>',
                                                        //overflow: TextOverflow.ellipsis,
                                                        style: const TextStyle(
                                                          fontFamily: 'AvenirNextCondensedMedium',
                                                          fontStyle: FontStyle.normal,
                                                          fontSize: LEADER_FONT_SIZE,
                                                          height: 1.0,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                      if ((widget.kennelId == null) && ((_scopeTabController?.index ?? 1) == 1)) ...<Widget>[
                                                        Text(
                                                          '  -  ${e.kennelName}',
                                                          //overflow: TextOverflow.ellipsis,
                                                          style: TextStyle(
                                                            fontFamily: 'AvenirNextCondensedMedium',
                                                            fontStyle: FontStyle.italic,
                                                            fontSize: LEADER_FONT_SIZE,
                                                            height: 1.0,
                                                            color: Colors.pink.shade100,
                                                          ),
                                                        ),
                                                      ],
                                                      if ((widget.kennelId == null) && ((_scopeTabController?.index ?? 1) == 0)) ...<Widget>[
                                                        Text(
                                                          '  -  ${_timespanTabController.index == TABINDEX_TOTAL ? e.kennelCountTotal : _timespanTabController.index == TABINDEX_365_DAYS ? e.kennelCountRollingYear : e.kennelCountYtd} Kennels',
                                                          //overflow: TextOverflow.ellipsis,
                                                          style: TextStyle(
                                                            fontFamily: 'AvenirNextCondensedMedium',
                                                            fontStyle: FontStyle.italic,
                                                            fontSize: LEADER_FONT_SIZE,
                                                            height: 1.0,
                                                            color: Colors.pink.shade100,
                                                          ),
                                                        ),
                                                      ]
                                                    ],
                                                  ),
                                                )),
                                              ],
                                            );
                                          }),
                                    ),
                                  ],
                                )),
                          ),
                        ),
                      ],
                    ),
        ),
      ],
    ));
  }

  // ignore: constant_identifier_names
  static const double LEADER_FONT_SIZE = 22.0;

  int _leaderboardSortColumnIndex = 0;

  // Widget _buildLeaderboardView() {
  //   //print('buildRsvpView() -  = ${DateTime.now().millisecondsSinceEpoch}');
  // }

  bool _sortOrderAsc = false;

  void _sortLeaderboard(int columnIndex, bool alternateSortOrder) {
    if (alternateSortOrder && (columnIndex == _leaderboardSortColumnIndex)) {
      _sortOrderAsc = !_sortOrderAsc;
    }

    _leaderboardSortColumnIndex = columnIndex;

    switch (_leaderboardSortColumnIndex) {
      // sort runs
      case 0:
        switch (_timespanTabController.index) {
          case TABINDEX_TOTAL:
            _leaderboardList.sort((a, b) {
              int cmp = a.totalRunCount.compareTo(b.totalRunCount);
              if (cmp != 0) return _sortOrderAsc ? cmp : -cmp;
              return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
            });
            _leaderboardAggregateList.sort((a, b) {
              int cmp = a.totalRunCount.compareTo(b.totalRunCount);
              if (cmp != 0) return _sortOrderAsc ? cmp : -cmp;
              return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
            });
            break;
          case TABINDEX_365_DAYS:
            _leaderboardList.sort((a, b) {
              int cmp = a.rollingYearTotalRunCount.compareTo(b.rollingYearTotalRunCount);
              if (cmp != 0) return _sortOrderAsc ? cmp : -cmp;
              return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
            });
            _leaderboardAggregateList.sort((a, b) {
              int cmp = a.rollingYearTotalRunCount.compareTo(b.rollingYearTotalRunCount);
              if (cmp != 0) return _sortOrderAsc ? cmp : -cmp;
              return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
            });
            break;

          case TABINDEX_CURRENT_YEAR:
            _leaderboardList.sort((a, b) {
              int cmp = a.ytdTotalRunCount.compareTo(b.ytdTotalRunCount);
              if (cmp != 0) return _sortOrderAsc ? cmp : -cmp;
              return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
            });
            _leaderboardAggregateList.sort((a, b) {
              int cmp = a.ytdTotalRunCount.compareTo(b.ytdTotalRunCount);
              if (cmp != 0) return _sortOrderAsc ? cmp : -cmp;
              return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
            });
            break;
        }
        break;
      // sort haring
      case 1:
        switch (_timespanTabController.index) {
          case TABINDEX_TOTAL:
            _leaderboardList.sort((a, b) {
              int cmp = a.totalHaringCount.compareTo(b.totalHaringCount);
              if (cmp != 0) return _sortOrderAsc ? cmp : -cmp;
              return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
            });
            _leaderboardAggregateList.sort((a, b) {
              int cmp = a.totalHaringCount.compareTo(b.totalHaringCount);
              if (cmp != 0) return _sortOrderAsc ? cmp : -cmp;
              return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
            });
            break;
          case TABINDEX_365_DAYS:
            _leaderboardList.sort((a, b) {
              int cmp = a.rollingYearHaringCount.compareTo(b.rollingYearHaringCount);
              if (cmp != 0) return _sortOrderAsc ? cmp : -cmp;
              return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
            });
            _leaderboardAggregateList.sort((a, b) {
              int cmp = a.rollingYearHaringCount.compareTo(b.rollingYearHaringCount);
              if (cmp != 0) return _sortOrderAsc ? cmp : -cmp;
              return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
            });
            break;
          case TABINDEX_CURRENT_YEAR:
            _leaderboardList.sort((a, b) {
              int cmp = a.ytdHaringCount.compareTo(b.ytdHaringCount);
              if (cmp != 0) return _sortOrderAsc ? cmp : -cmp;
              return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
            });
            _leaderboardAggregateList.sort((a, b) {
              int cmp = a.ytdHaringCount.compareTo(b.ytdHaringCount);
              if (cmp != 0) return _sortOrderAsc ? cmp : -cmp;
              return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
            });
            break;
        }
        break;
      // sort by name
      case 2:
        // _sortOrderAsc
        //     ? _leaderboardList.sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()))
        //     : _leaderboardList.sort((b, a) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));

        _leaderboardList.sort((a, b) {
          int cmp = a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
          if (cmp != 0) return _sortOrderAsc ? cmp : -cmp;
          return a.kennelName.toLowerCase().compareTo(b.kennelName.toLowerCase());
        });

        _leaderboardAggregateList.sort((a, b) {
          int cmp = a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
          if (cmp != 0) return _sortOrderAsc ? cmp : -cmp;
          return a.kennelName.toLowerCase().compareTo(b.kennelName.toLowerCase());
        });

        // _sortOrderAsc
        //     ? _leaderboardAggregateList.sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()))
        //     : _leaderboardAggregateList.sort((b, a) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
        break;
    }
  }
}
