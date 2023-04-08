import 'package:harrier_central/imports.dart';
// import 'package:intl/intl.dart';

class Leaderboard extends StatefulWidget {
  const Leaderboard({
    Key? key,
    this.kennelId,
  }) : super(key: key);

  final String? kennelId;

  @override
  LeaderboardState createState() => LeaderboardState();
}

// NULLSAFETODO1

class LeaderboardState extends State<Leaderboard> {
  // @override
  // void initState() {}

  @override
  Widget build(BuildContext context) {
    return Container(color: Colors.red);
  }
}

// class LeaderboardState extends State<Leaderboard> with TickerProviderStateMixin {
//   @override
//   void initState() {
//     _timespanTabController = TabController(vsync: this, length: 3);
//     if (widget.kennelId != null) {
//       _showKennels = true;
//     }

//     QueryKennels.queryKennelDetails().then((List<Map<String, dynamic>> kennels) {
//       _kennels = {};

//       for (Map<String, dynamic> kennel in kennels) {
//         _kennels[kennel["kennelId"]] = kennel;
//       }

//       if (_filteredLeaderboardList == null) {
//         _getLeaderboard().then(
//           (value) {
//             setState(() {
//               _leaderboardSortColumnIndex = 0;
//               _sortOrderAsc = false;
//               _sortLeaderboard(_leaderboardSortColumnIndex, false);
//             });
//           },
//         );
//       }
//     });

//     super.initState();
//   }

//   @override
//   void dispose() {
//     _leaderScrollController.dispose();
//     super.dispose();
//   }

//   Future<void> _getLeaderboard() async {
//     String responseBody;

//     bool updateLocalLeaderboardCache = false;

//     DateTime? lastLeaderboardUpdate = getDatePref(DatePrefsEnum.lastLeaderboardUpdate);

//     if ((widget.kennelId != null) || (lastLeaderboardUpdate == null) || (DateFormat('yyyyMMMdd').format(lastLeaderboardUpdate) != DateFormat('yyyyMMMdd').format(DateTime.now()))) {
//       final String userId = getStringPref(StringPrefsEnum.userId)!;
//       final String accessToken = IveCoreUtilities.generateToken(userId.toUpperCase(), 'getLeaderboard');

//       final String body = jsonEncode(<String, Object?>{
//         'userId': userId,
//         'accessToken': accessToken,
//         'kennelId': widget.kennelId,
//       });

//       responseBody = await ServiceCommon.sendHttpPost('hc3_get_leaderboard', body);
//       updateLocalLeaderboardCache = true;
//     } else {
//       responseBody = getStringPref(StringPrefsEnum.leaderboardJson) ?? '';
//       updateLocalLeaderboardCache = false;
//     }

//     if (!responseBody.startsWith(ERROR_PREFIX)) {
//       _filteredLeaderboardList = <LeaderboardModel>[];
//       _filteredLeaderboardAggregateList = <LeaderboardModel>[];

//       _leaderboardList = <LeaderboardModel>[];
//       _leaderboardAggregateList = <LeaderboardModel>[];

//       if ((widget.kennelId == null) && updateLocalLeaderboardCache) {
//         await setDatePref(DatePrefsEnum.lastLeaderboardUpdate, DateTime.now());
//         await setStringPref(StringPrefsEnum.leaderboardJson, responseBody);
//       }

//       List<dynamic> jsonResults = json.decode(responseBody);

//       Map<String, LeaderboardModel> leaderAggregateMap = {};

//       jsonResults[0].forEach((dynamic element) {
//         LeaderboardModel lm = LeaderboardModel.fromJson(element);
//         lm.searchText = ' ${lm.displayName}, ${_kennels[lm.kennelId]['searchText']}, ';
//         if ((lm.homeKennelId != null) && (lm.homeKennelId.isNotEmpty)) {
//           lm.searchText += _kennels[lm.kennelId]['searchText'];
//         }
//         _leaderboardList.add(lm);

//         if ((widget.kennelId == null) || (widget.kennelId!.isEmpty)) {
//           if (leaderAggregateMap.containsKey(lm.hasherId)) {
//             leaderAggregateMap[lm.hasherId].rollingYearHaringCount += lm.rollingYearHaringCount;
//             leaderAggregateMap[lm.hasherId].rollingYearTotalRunCount += lm.rollingYearTotalRunCount;
//             leaderAggregateMap[lm.hasherId].totalHaringCount += lm.totalHaringCount;
//             leaderAggregateMap[lm.hasherId].totalRunCount += lm.totalRunCount;
//             leaderAggregateMap[lm.hasherId].ytdHaringCount += lm.ytdHaringCount;
//             leaderAggregateMap[lm.hasherId].ytdTotalRunCount += lm.ytdTotalRunCount;
//             leaderAggregateMap[lm.hasherId].searchText += ' ${_kennels[lm.kennelId]['searchText']}, ';

//             if (lm.totalRunCount > 0) {
//               leaderAggregateMap[lm.hasherId].kennelCountTotal++;
//             }

//             if (lm.rollingYearTotalRunCount > 0) {
//               leaderAggregateMap[lm.hasherId].kennelCountRollingYear++;
//             }

//             if (lm.ytdTotalRunCount > 0) {
//               leaderAggregateMap[lm.hasherId].kennelCountYtd++;
//             }
//           } else {
//             LeaderboardModel newLm = LeaderboardModel.clone(lm);
//             newLm.searchText = ' ${newLm.displayName}, ${_kennels[newLm.kennelId]['searchText']}, ';
//             if ((newLm.homeKennelId != null) && (newLm.homeKennelId.isNotEmpty)) {
//               newLm.searchText += _kennels[newLm.kennelId]['searchText'];
//             }

//             if (lm.totalRunCount > 0) {
//               newLm.kennelCountTotal++;
//             }

//             if (lm.rollingYearTotalRunCount > 0) {
//               newLm.kennelCountRollingYear++;
//             }

//             if (lm.ytdTotalRunCount > 0) {
//               newLm.kennelCountYtd++;
//             }

//             leaderAggregateMap.addAll({lm.hasherId: newLm});
//           }
//         }
//       });

//       _leaderboardAggregateList = leaderAggregateMap.values.toList();

//       _filteredLeaderboardAggregateList = _leaderboardAggregateList.toList();
//       _filteredLeaderboardList = _leaderboardList.toList();
//     }

//     return;
//   }

//   TabController _timespanTabController;
//   //TabController _scopeTabController;

//   Map<String, Map<String, dynamic>> _kennels = {};

//   final FocusNode _searchFocusNode = FocusNode();
//   final TextEditingController _searchController = TextEditingController();

//   List<LeaderboardModel>? _leaderboardList;
//   List<LeaderboardModel>? _leaderboardAggregateList;

//   List<LeaderboardModel>? _filteredLeaderboardList;
//   List<LeaderboardModel>? _filteredLeaderboardAggregateList;

//   bool _showKennels = false;
//   bool _showHomeKennel = false;

//   final ScrollController _leaderScrollController = ScrollController(keepScrollOffset: false, initialScrollOffset: 50.0);

//   // ignore: constant_identifier_names
//   static const int TABINDEX_365_DAYS = 0;
//   // ignore: constant_identifier_names
//   static const int TABINDEX_CURRENT_YEAR = 1;
//   // ignore: constant_identifier_names
//   static const int TABINDEX_TOTAL = 2;

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//         child: Column(
//       children: <Widget>[
//         Expanded(
//           child: _filteredLeaderboardList == null
//               ? const SizedBox(
//                   //color: Colors.grey[300],
//                   width: 70.0,
//                   height: 70.0,
//                   child: Padding(padding: EdgeInsets.all(5.0), child: Center(child: HcCircularProgressIndicator(key: Key('22030392')))),
//                 )
//               : Column(
//                   children: <Widget>[
//                     Expanded(
//                       child: SizedBox(
//                         //key: packListBox,
//                         //color: const Color.fromARGB(60, 255, 255, 255),
//                         //margin: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 15.0),
//                         //padding: const EdgeInsets.symmetric(horizontal: 8.0),
//                         width: MediaQuery.of(context).size.width,
//                         child: CustomScrollView(
//                           controller: _leaderScrollController,
//                           slivers: <Widget>[
//                             // SliverAppBar(
//                             //   expandedHeight: 100.0,
//                             //   floating: true,
//                             //   backgroundColor: Colors.transparent,
//                             //   automaticallyImplyLeading: false,
//                             //   flexibleSpace: Column(
//                             //     children: <Widget>[
//                             //       Container(color: Colors.pink, height: 40.0),
//                             //     ],
//                             //   ),
//                             // ),
//                             SliverAppBar(
//                               // expandedHeight: 120.0,
//                               // stretchTriggerOffset: 220.0,
//                               toolbarHeight: widget.kennelId == null ? 155.0 : 106.0,
//                               floating: true,
//                               //stretch: true,
//                               backgroundColor: Colors.grey.shade400,
//                               // foregroundColor: Colors.transparent,
//                               shadowColor: Colors.transparent,
//                               automaticallyImplyLeading: false,
//                               flexibleSpace: Column(
//                                 children: <Widget>[
//                                   //Container(color: Colors.pink, height: 40.0),
//                                   _searchBar(),
//                                   Container(
//                                     padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 7.0),
//                                     color: Colors.grey.shade400,
//                                     child: TabBar(
//                                       onTap: (void _) {
//                                         _sortLeaderboard(_leaderboardSortColumnIndex, false);
//                                         setState(() {});
//                                       },
//                                       labelStyle: const TextStyle(fontFamily: 'AvenirNextCondensedBold', fontStyle: FontStyle.normal, fontSize: 18.0, height: 1.0),
//                                       unselectedLabelStyle: const TextStyle(fontFamily: 'AvenirNextCondensedMedium', fontStyle: FontStyle.normal, fontSize: 18.0, height: 1.0),
//                                       isScrollable: false,
//                                       unselectedLabelColor: Colors.black,
//                                       labelColor: Colors.white,
//                                       //labelPadding: const EdgeInsets.only(top: 3, left: 20, right: 20),
//                                       indicatorSize: TabBarIndicatorSize.tab,
//                                       indicator: BubbleTabIndicator(
//                                           indicatorHeight: 25.0,
//                                           indicatorColor: Colors.red.shade900,
//                                           tabBarIndicatorSize: TabBarIndicatorSize.label,
//                                           indicatorRadius: 20.0,
//                                           bubblePadding: const EdgeInsets.only(top: 5.0)
//                                           //insets: const EdgeInsets.only(bottom: 5),
//                                           ),
//                                       tabs: <Tab>[
//                                         const Tab(text: '365 days'),
//                                         Tab(text: 'In ${DateTime.now().year}'),
//                                         const Tab(text: 'Total'),
//                                       ],
//                                       controller: _timespanTabController,
//                                     ),
//                                   ),
//                                   const Divider(
//                                     color: Colors.black45,
//                                     thickness: 1.0,
//                                     height: 1.0,
//                                   ),
//                                   if (widget.kennelId == null) ...<Widget>[
//                                     //const SizedBox(height: 10.0),
//                                     Row(
//                                       mainAxisAlignment: MainAxisAlignment.center,
//                                       children: [
//                                         //SizedBox(width: 10),
//                                         Checkbox(
//                                           value: _showKennels,
//                                           checkColor: Colors.white,
//                                           activeColor: Colors.red.shade900,
//                                           onChanged: (value) {
//                                             setState(() {
//                                               _showKennels = !_showKennels;
//                                             });
//                                           },
//                                         ),
//                                         Padding(
//                                           padding: const EdgeInsets.only(top: 3.0),
//                                           child: Text(
//                                             'Show Kennels',
//                                             style: _showKennels
//                                                 ? const TextStyle(fontFamily: 'AvenirNextCondensedBold', fontStyle: FontStyle.normal, fontSize: 18.0, height: 1.0)
//                                                 : const TextStyle(fontFamily: 'AvenirNextCondensedMedium', fontStyle: FontStyle.normal, fontSize: 18.0, height: 1.0),
//                                           ),
//                                         ),
//                                         const SizedBox(width: 10),
//                                         Checkbox(
//                                           value: _showHomeKennel,
//                                           checkColor: Colors.white,
//                                           activeColor: Colors.red.shade900,
//                                           onChanged: (value) {
//                                             setState(() {
//                                               _showHomeKennel = !_showHomeKennel;
//                                             });
//                                           },
//                                         ),
//                                         Padding(
//                                           padding: const EdgeInsets.only(top: 3.0),
//                                           child: Text(
//                                             'Home Kennel',
//                                             style: _showHomeKennel
//                                                 ? const TextStyle(fontFamily: 'AvenirNextCondensedBold', fontStyle: FontStyle.normal, fontSize: 20.0, height: 1.0)
//                                                 : const TextStyle(fontFamily: 'AvenirNextCondensedMedium', fontStyle: FontStyle.normal, fontSize: 20.0, height: 1.0),
//                                           ),
//                                         ),
//                                         const SizedBox(width: 15),
//                                       ],
//                                     ),

//                                     const Divider(
//                                       color: Colors.black45,
//                                       thickness: 1.0,
//                                       height: 1.0,
//                                     ),
//                                     //const SizedBox(height: 3.0),
//                                   ],
//                                 ],
//                               ),
//                             ),
//                             SliverAppBar(
//                               pinned: true,
//                               toolbarHeight: 60.0,
//                               backgroundColor: const Color.fromARGB(255, 26, 0, 65),
//                               automaticallyImplyLeading: false,
//                               flexibleSpace: Column(children: [
//                                 const SizedBox(height: 10.0),
//                                 Row(
//                                   children: <Widget>[
//                                     const SizedBox(width: 4.0),
//                                     GestureDetector(
//                                       onTap: () {
//                                         setState(
//                                           () {
//                                             _sortLeaderboard(0, true);
//                                           },
//                                         );
//                                       },
//                                       child: SizedBox(
//                                         width: 50.0,
//                                         child: Text(
//                                           'Runs',
//                                           textAlign: TextAlign.center,
//                                           style: TextStyle(
//                                             fontFamily: _leaderboardSortColumnIndex == 0 ? 'AvenirNextCondensedBold' : 'AvenirNextCondensedMedium',
//                                             fontStyle: FontStyle.normal,
//                                             fontSize: LEADER_FONT_SIZE,
//                                             height: 1.0,
//                                             color: Colors.yellow,
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//                                     GestureDetector(
//                                       onTap: () {
//                                         setState(
//                                           () {
//                                             _sortLeaderboard(1, true);
//                                           },
//                                         );
//                                       },
//                                       child: SizedBox(
//                                         width: 70.0,
//                                         child: Text(
//                                           'Hared',
//                                           textAlign: TextAlign.center,
//                                           style: TextStyle(
//                                             fontFamily: _leaderboardSortColumnIndex == 1 ? 'AvenirNextCondensedBold' : 'AvenirNextCondensedMedium',
//                                             fontStyle: FontStyle.normal,
//                                             fontSize: LEADER_FONT_SIZE,
//                                             height: 1.0,
//                                             color: Colors.yellow,
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//                                     Expanded(
//                                       child: GestureDetector(
//                                         onTap: () {
//                                           setState(() {
//                                             _sortLeaderboard(2, true);
//                                           });
//                                         },
//                                         child: Text(
//                                           'Hasher',
//                                           textAlign: TextAlign.center,
//                                           style: TextStyle(
//                                             fontFamily: _leaderboardSortColumnIndex == 2 ? 'AvenirNextCondensedBold' : 'AvenirNextCondensedMedium',
//                                             fontStyle: FontStyle.normal,
//                                             fontSize: LEADER_FONT_SIZE,
//                                             height: 1.0,
//                                             color: Colors.yellow,
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//                                     const SizedBox(width: 50.0),
//                                   ],
//                                 ),
//                                 Row(
//                                   children: <Widget>[
//                                     GestureDetector(
//                                       onTap: () {
//                                         setState(() {
//                                           _sortLeaderboard(0, true);
//                                         });
//                                       },
//                                       child: SizedBox(
//                                         width: 50.0,
//                                         child: _leaderboardSortColumnIndex != 0
//                                             ? null
//                                             : Icon(
//                                                 _sortOrderAsc ? AntDesign.caretup : AntDesign.caretdown,
//                                                 size: 20.0,
//                                                 color: Colors.yellow,
//                                               ),
//                                       ),
//                                     ),
//                                     GestureDetector(
//                                       onTap: () {
//                                         setState(
//                                           () {
//                                             _sortLeaderboard(1, true);
//                                           },
//                                         );
//                                       },
//                                       child: SizedBox(
//                                         width: 70.0,
//                                         child: _leaderboardSortColumnIndex != 1
//                                             ? null
//                                             : Icon(
//                                                 _sortOrderAsc ? AntDesign.caretup : AntDesign.caretdown,
//                                                 size: 20.0,
//                                                 color: Colors.yellow,
//                                               ),
//                                       ),
//                                     ),
//                                     Expanded(
//                                       child: GestureDetector(
//                                         onTap: () {
//                                           setState(() {
//                                             _sortLeaderboard(2, true);
//                                           });
//                                         },
//                                         child: SizedBox(
//                                           child: _leaderboardSortColumnIndex != 2
//                                               ? null
//                                               : Icon(
//                                                   _sortOrderAsc ? AntDesign.caretup : AntDesign.caretdown,
//                                                   size: 20.0,
//                                                   color: Colors.yellow,
//                                                 ),
//                                         ),
//                                       ),
//                                     ),
//                                     const SizedBox(width: 50.0),
//                                   ],
//                                 ),
//                               ]),
//                             ),
//                             // Next, create a SliverList
//                             SliverToBoxAdapter(
//                                 child: SizedBox(
//                                     child: _filteredLeaderboardList.isEmpty
//                                         ? Container(
//                                             height: 400.0,
//                                             padding: const EdgeInsets.symmetric(horizontal: 20.0),
//                                             child: Center(
//                                               child: Text(
//                                                 'No leaderboard records found',
//                                                 style: largeTitleStyle,
//                                                 textAlign: TextAlign.center,
//                                               ),
//                                             ),
//                                           )
//                                         : const SizedBox(
//                                             height: 15,
//                                           ))),
//                             SliverList(
//                               // Use a delegate to build items as they're scrolled on screen.
//                               delegate: SliverChildBuilderDelegate(
//                                 // The builder function returns a ListTile with a title that
//                                 // displays the index of the current item.
//                                 (context, index) {
//                                   if (index == (_showKennels ? _filteredLeaderboardList.length : _filteredLeaderboardAggregateList.length)) {
//                                     return const SizedBox(height: 50);
//                                   }

//                                   LeaderboardModel e = !_showKennels ? _filteredLeaderboardAggregateList[index] : _filteredLeaderboardList[index];
//                                   return Column(
//                                     children: [
//                                       const SizedBox(height: 3.0),
//                                       Row(
//                                         children: <Widget>[
//                                           SizedBox(
//                                               width: 50.0,
//                                               child: Text(
//                                                   (_timespanTabController.index == TABINDEX_TOTAL
//                                                           ? e.totalRunCount
//                                                           : _timespanTabController.index == TABINDEX_365_DAYS
//                                                               ? e.rollingYearTotalRunCount
//                                                               : e.ytdTotalRunCount)
//                                                       .toString(),
//                                                   textAlign: TextAlign.center,
//                                                   style: const TextStyle(
//                                                     fontFamily: 'AvenirNextCondensedMedium',
//                                                     fontStyle: FontStyle.normal,
//                                                     fontSize: LEADER_FONT_SIZE,
//                                                     height: 1.0,
//                                                     color: Colors.white,
//                                                   ))),
//                                           SizedBox(
//                                               width: 70.0,
//                                               child: Text(
//                                                   (_timespanTabController.index == TABINDEX_TOTAL
//                                                           ? e.totalHaringCount
//                                                           : _timespanTabController.index == TABINDEX_365_DAYS
//                                                               ? e.rollingYearHaringCount
//                                                               : e.ytdHaringCount)
//                                                       .toString(),
//                                                   textAlign: TextAlign.center,
//                                                   style: const TextStyle(
//                                                     fontFamily: 'AvenirNextCondensedMedium',
//                                                     fontStyle: FontStyle.normal,
//                                                     fontSize: LEADER_FONT_SIZE,
//                                                     height: 1.0,
//                                                     color: Colors.white,
//                                                   ))),
//                                           Expanded(
//                                             child: SingleChildScrollView(
//                                               scrollDirection: Axis.horizontal,
//                                               child: Row(
//                                                 children: [
//                                                   Text(
//                                                     e.displayName ?? '<unknown>',
//                                                     //overflow: TextOverflow.ellipsis,
//                                                     style: const TextStyle(
//                                                       fontFamily: 'AvenirNextCondensedMedium',
//                                                       fontStyle: FontStyle.normal,
//                                                       fontSize: LEADER_FONT_SIZE,
//                                                       height: 1.0,
//                                                       color: Colors.white,
//                                                     ),
//                                                   ),
//                                                   if ((widget.kennelId == null) && _showHomeKennel && (e.homeKennelId != null)) ...<Widget>[
//                                                     Text(
//                                                       '  -  ${_kennels[e.homeKennelId]["kennelShortName"]}',
//                                                       //overflow: TextOverflow.ellipsis,
//                                                       style: TextStyle(
//                                                         fontFamily: 'AvenirNextCondensedMedium',
//                                                         fontStyle: FontStyle.italic,
//                                                         fontSize: LEADER_FONT_SIZE,
//                                                         height: 1.0,
//                                                         color: Colors.blue.shade100,
//                                                       ),
//                                                     ),
//                                                   ],
//                                                   if ((widget.kennelId == null) && _showKennels) ...<Widget>[
//                                                     Text(
//                                                       '  -  ${_kennels[e.kennelId]["kennelName"]}',
//                                                       //overflow: TextOverflow.ellipsis,
//                                                       style: TextStyle(
//                                                         fontFamily: 'AvenirNextCondensedMedium',
//                                                         fontStyle: FontStyle.italic,
//                                                         fontSize: LEADER_FONT_SIZE,
//                                                         height: 1.0,
//                                                         color: Colors.pink.shade100,
//                                                       ),
//                                                     ),
//                                                   ],
//                                                   if ((widget.kennelId == null) && !_showKennels) ...<Widget>[
//                                                     Text(
//                                                       '  -  ${_timespanTabController.index == TABINDEX_TOTAL ? e.kennelCountTotal : _timespanTabController.index == TABINDEX_365_DAYS ? e.kennelCountRollingYear : e.kennelCountYtd} Kennels',
//                                                       //overflow: TextOverflow.ellipsis,
//                                                       style: TextStyle(
//                                                         fontFamily: 'AvenirNextCondensedMedium',
//                                                         fontStyle: FontStyle.italic,
//                                                         fontSize: LEADER_FONT_SIZE,
//                                                         height: 1.0,
//                                                         color: Colors.pink.shade100,
//                                                       ),
//                                                     ),
//                                                   ]
//                                                 ],
//                                               ),
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                     ],
//                                   );
//                                 },

//                                 childCount: _showKennels ? _filteredLeaderboardList.length + 1 : _filteredLeaderboardAggregateList.length + 1,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//         ),
//       ],
//     ));
//   }

//   Widget _searchBar() {
//     return Container(
//       height: 50,
//       color: Colors.white,
//       child: Column(
//         mainAxisSize: MainAxisSize.max,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: <Widget>[
//           const Divider(
//             height: 2.0,
//             thickness: 2.0,
//           ),
//           Expanded(
//             child: Padding(
//               padding: const EdgeInsets.only(left: 14.0),
//               child: Row(
//                 children: <Widget>[
//                   Expanded(
//                     child: TextField(
//                       autocorrect: false,
//                       onChanged: (String text) {
//                         setState(() {
//                           _filterResults(_searchController.text);
//                           _sortLeaderboard(_leaderboardSortColumnIndex, false);
//                         });
//                       },
//                       focusNode: _searchFocusNode,
//                       controller: _searchController,
//                       keyboardType: TextInputType.text,
//                       style: const TextStyle(fontFamily: 'WorkSansSemiBold', fontSize: 16.0, color: Colors.black),
//                       decoration: const InputDecoration(
//                         border: InputBorder.none,
//                         icon: Icon(
//                           FontAwesome.search,
//                           color: Colors.black,
//                         ),
//                         hintText: 'Search...',
//                         hintStyle: TextStyle(fontFamily: 'WorkSansSemiBold', fontSize: 16.0),
//                       ),
//                     ),
//                   ),
//                   SizedBox(
//                     width: 40,
//                     child: TextButton(
//                       style: TextButton.styleFrom(textStyle: TextStyle(color: Colors.grey.shade700), backgroundColor: Colors.white),
//                       child: Text('X', style: headingStyle20Black.copyWith(color: Colors.grey.shade700)),
//                       onPressed: () {
//                         _searchController.text = '';
//                         //_searchRunsText = '';
//                         setState(() {
//                           _filterResults(_searchController.text);
//                           _sortLeaderboard(_leaderboardSortColumnIndex, false);
//                         });
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ignore: constant_identifier_names
//   static const double LEADER_FONT_SIZE = 22.0;

//   int _leaderboardSortColumnIndex = 0;

//   // Widget _buildLeaderboardView() {
//   //   //print('buildRsvpView() -  = ${DateTime.now().millisecondsSinceEpoch}');
//   // }

//   bool _sortOrderAsc = false;

//   void _sortLeaderboard(int columnIndex, bool alternateSortOrder) {
//     if ((_filteredLeaderboardList != null) &&
//         ((widget.kennelId != null) || (_filteredLeaderboardAggregateList != null)) &&
//         (_filteredLeaderboardList.isNotEmpty) &&
//         ((widget.kennelId != null) || (_filteredLeaderboardAggregateList.isNotEmpty))) {
//       if (alternateSortOrder && (columnIndex == _leaderboardSortColumnIndex)) {
//         _sortOrderAsc = !_sortOrderAsc;
//       }

//       _leaderboardSortColumnIndex = columnIndex;

//       switch (_leaderboardSortColumnIndex) {
//         // sort runs
//         case 0:
//           switch (_timespanTabController.index) {
//             case TABINDEX_TOTAL:
//               _filteredLeaderboardList.sort((a, b) {
//                 int cmp = a.totalRunCount.compareTo(b.totalRunCount);
//                 if (cmp != 0) return _sortOrderAsc ? cmp : -cmp;
//                 return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
//               });
//               _filteredLeaderboardAggregateList.sort((a, b) {
//                 int cmp = a.totalRunCount.compareTo(b.totalRunCount);
//                 if (cmp != 0) return _sortOrderAsc ? cmp : -cmp;
//                 return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
//               });
//               break;
//             case TABINDEX_365_DAYS:
//               _filteredLeaderboardList.sort((a, b) {
//                 int cmp = a.rollingYearTotalRunCount.compareTo(b.rollingYearTotalRunCount);
//                 if (cmp != 0) return _sortOrderAsc ? cmp : -cmp;
//                 return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
//               });
//               _filteredLeaderboardAggregateList.sort((a, b) {
//                 int cmp = a.rollingYearTotalRunCount.compareTo(b.rollingYearTotalRunCount);
//                 if (cmp != 0) return _sortOrderAsc ? cmp : -cmp;
//                 return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
//               });
//               break;

//             case TABINDEX_CURRENT_YEAR:
//               _filteredLeaderboardList.sort((a, b) {
//                 int cmp = a.ytdTotalRunCount.compareTo(b.ytdTotalRunCount);
//                 if (cmp != 0) return _sortOrderAsc ? cmp : -cmp;
//                 return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
//               });
//               _filteredLeaderboardAggregateList.sort((a, b) {
//                 int cmp = a.ytdTotalRunCount.compareTo(b.ytdTotalRunCount);
//                 if (cmp != 0) return _sortOrderAsc ? cmp : -cmp;
//                 return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
//               });
//               break;
//           }
//           break;
//         // sort haring
//         case 1:
//           switch (_timespanTabController.index) {
//             case TABINDEX_TOTAL:
//               _filteredLeaderboardList.sort((a, b) {
//                 int cmp = a.totalHaringCount.compareTo(b.totalHaringCount);
//                 if (cmp != 0) return _sortOrderAsc ? cmp : -cmp;
//                 return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
//               });
//               _filteredLeaderboardAggregateList.sort((a, b) {
//                 int cmp = a.totalHaringCount.compareTo(b.totalHaringCount);
//                 if (cmp != 0) return _sortOrderAsc ? cmp : -cmp;
//                 return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
//               });
//               break;
//             case TABINDEX_365_DAYS:
//               _filteredLeaderboardList.sort((a, b) {
//                 int cmp = a.rollingYearHaringCount.compareTo(b.rollingYearHaringCount);
//                 if (cmp != 0) return _sortOrderAsc ? cmp : -cmp;
//                 return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
//               });
//               _filteredLeaderboardAggregateList.sort((a, b) {
//                 int cmp = a.rollingYearHaringCount.compareTo(b.rollingYearHaringCount);
//                 if (cmp != 0) return _sortOrderAsc ? cmp : -cmp;
//                 return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
//               });
//               break;
//             case TABINDEX_CURRENT_YEAR:
//               _filteredLeaderboardList.sort((a, b) {
//                 int cmp = a.ytdHaringCount.compareTo(b.ytdHaringCount);
//                 if (cmp != 0) return _sortOrderAsc ? cmp : -cmp;
//                 return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
//               });
//               _filteredLeaderboardAggregateList.sort((a, b) {
//                 int cmp = a.ytdHaringCount.compareTo(b.ytdHaringCount);
//                 if (cmp != 0) return _sortOrderAsc ? cmp : -cmp;
//                 return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
//               });
//               break;
//           }
//           break;
//         // sort by name
//         case 2:
//           _filteredLeaderboardList.sort((a, b) {
//             int cmp = a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
//             if (cmp != 0) return _sortOrderAsc ? cmp : -cmp;
//             return a.kennelId.toLowerCase().compareTo(b.kennelId.toLowerCase());
//           });

//           _filteredLeaderboardAggregateList.sort((a, b) {
//             int cmp = a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
//             if (cmp != 0) return _sortOrderAsc ? cmp : -cmp;
//             return a.kennelId.toLowerCase().compareTo(b.kennelId.toLowerCase());
//           });

//           break;
//       }
//     }
//   }

//   void _filterResults(String filter) {
//     while (filter.contains('+ ')) {
//       filter = filter.replaceAll('+ ', '+');
//     }

//     while (filter.contains('- ')) {
//       filter = filter.replaceAll('- ', '-');
//     }

//     List<String> addParams = <String>[];
//     List<String> subParams = <String>[];

//     int firstPositive = filter.indexOf('+');
//     if (firstPositive >= 0) {
//       addParams = Utilities.parseSearchTokens(filter, r"\+");
//     }

//     int firstNegative = filter.indexOf('-');
//     if (firstNegative >= 0) {
//       subParams = Utilities.parseSearchTokens(filter, r"-");
//     }

//     if ((firstPositive > 0) && (firstNegative > 0)) {
//       int firstToken = min(firstPositive, firstNegative);
//       addParams.add(filter.substring(0, firstToken).trim().toLowerCase());
//     } else if (firstPositive > 0) {
//       addParams.add(filter.substring(0, firstPositive).trim().toLowerCase());
//     } else if (firstNegative > 0) {
//       addParams.add(filter.substring(0, firstNegative).trim().toLowerCase());
//     } else {
//       addParams.add(filter.trim().toLowerCase());
//     }

//     _filteredLeaderboardList ??= <LeaderboardModel>[];
//     _filteredLeaderboardList.clear();

//     _filteredLeaderboardAggregateList ??= <LeaderboardModel>[];
//     _filteredLeaderboardAggregateList.clear();

//     if ((filter != null) && (filter.isNotEmpty)) {
//       if (_leaderboardList != null) {
//         _filteredLeaderboardList = _leaderboardList.where((LeaderboardModel a) {
//           for (String param in subParams) {
//             if (a.searchText.toLowerCase().contains(param)) {
//               return false;
//             }
//           }

//           for (String param in addParams) {
//             if (a.searchText.toLowerCase().contains(param)) {
//               return true;
//             }
//           }

//           return false;
//         }).toList();
//       }

//       if (_leaderboardAggregateList != null) {
//         _filteredLeaderboardAggregateList = _leaderboardAggregateList.where((LeaderboardModel a) {
//           for (String param in subParams) {
//             if (a.searchText.toLowerCase().contains(param)) {
//               return false;
//             }
//           }

//           for (String param in addParams) {
//             if (a.searchText.toLowerCase().contains(param)) {
//               return true;
//             }
//           }
//           return false;
//         }).toList();
//       }
//     } else {
//       _filteredLeaderboardList.addAll(_leaderboardList);
//       _filteredLeaderboardAggregateList.addAll(_leaderboardAggregateList);
//     }
//   }
// }
