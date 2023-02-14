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

  LeaderboardModel({this.displayName, this.totalRunCount, this.totalHaringCount, this.ytdTotalRunCount, this.ytdHaringCount, this.rollingYearTotalRunCount, this.rollingYearHaringCount});

  LeaderboardModel.fromJson(Map<String, dynamic> json) {
    displayName = json['displayName'];
    totalRunCount = json['totalRunCount'];
    totalHaringCount = json['totalHaringCount'];
    ytdTotalRunCount = json['ytdTotalRunCount'];
    ytdHaringCount = json['ytdHaringCount'];
    rollingYearTotalRunCount = json['rollingYearTotalRunCount'];
    rollingYearHaringCount = json['rollingYearHaringCount'];
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
    _leaderboardTabController = TabController(vsync: this, length: 3);

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

    jsonResults[0].forEach((element) {
      _leaderboardList.add(LeaderboardModel.fromJson(element));
    });

    return;
  }

  TabController _leaderboardTabController;

  List<LeaderboardModel> _leaderboardList;

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
                            controller: _leaderboardTabController,
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
                                          itemCount: _leaderboardList.length,
                                          itemBuilder: (BuildContext context, int index) {
                                            final LeaderboardModel e = _leaderboardList[index];

                                            return Row(
                                              children: <Widget>[
                                                SizedBox(
                                                    width: 50.0,
                                                    child: Text(
                                                        (_leaderboardTabController.index == TABINDEX_TOTAL
                                                                ? e.totalRunCount
                                                                : _leaderboardTabController.index == TABINDEX_365_DAYS
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
                                                        (_leaderboardTabController.index == TABINDEX_TOTAL
                                                                ? e.totalHaringCount
                                                                : _leaderboardTabController.index == TABINDEX_365_DAYS
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
                                                    child: Text(e.displayName ?? '<unknown>',
                                                        overflow: TextOverflow.ellipsis,
                                                        style: const TextStyle(
                                                          fontFamily: 'AvenirNextCondensedMedium',
                                                          fontStyle: FontStyle.normal,
                                                          fontSize: LEADER_FONT_SIZE,
                                                          height: 1.0,
                                                          color: Colors.white,
                                                        ))),
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

  Widget _buildLeaderboardView() {
    //print('buildRsvpView() -  = ${DateTime.now().millisecondsSinceEpoch}');
  }

  bool _sortOrderAsc = false;

  void _sortLeaderboard(int columnIndex, bool alternateSortOrder) {
    if (alternateSortOrder && (columnIndex == _leaderboardSortColumnIndex)) {
      _sortOrderAsc = !_sortOrderAsc;
    }

    _leaderboardSortColumnIndex = columnIndex;

    switch (_leaderboardSortColumnIndex) {
      // sort runs
      case 0:
        switch (_leaderboardTabController.index) {
          case TABINDEX_TOTAL:
            _leaderboardList.sort((a, b) {
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
            break;

          case TABINDEX_CURRENT_YEAR:
            _leaderboardList.sort((a, b) {
              int cmp = a.ytdTotalRunCount.compareTo(b.ytdTotalRunCount);
              if (cmp != 0) return _sortOrderAsc ? cmp : -cmp;
              return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
            });
            break;
        }
        break;
      // sort haring
      case 1:
        switch (_leaderboardTabController.index) {
          case TABINDEX_TOTAL:
            _leaderboardList.sort((a, b) {
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
            break;
          case TABINDEX_CURRENT_YEAR:
            _leaderboardList.sort((a, b) {
              int cmp = a.ytdHaringCount.compareTo(b.ytdHaringCount);
              if (cmp != 0) return _sortOrderAsc ? cmp : -cmp;
              return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
            });
            break;
        }
        break;
      // sort by name
      case 2:
        _sortOrderAsc
            ? _leaderboardList.sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()))
            : _leaderboardList.sort((b, a) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
        break;
    }
  }
}
