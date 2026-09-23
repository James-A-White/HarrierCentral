import 'package:harrier_central/imports.dart';

/// The swipeable run list shared by the kennel and country history pages.
/// Reads [UserRunHistoryController.runs] in its own Obx.
class UserRunHistoryList extends StatelessWidget {
  const UserRunHistoryList({
    super.key,
    required this.c,
    required this.historicalHaringCount,
    required this.historicalTotalRunCount,
    required this.showCountry,
    required this.showKennel,
  });

  final UserRunHistoryController c;
  final int historicalHaringCount;
  final int historicalTotalRunCount;
  final bool showCountry;
  final bool showKennel;

  Future<void> _openRun(UserRunHistoryModel item) async {
    final List<dynamic> run = await QueryRuns.getRunDetailsAggregates(
      true,
      eventId: item.eventId,
      queryType: EnumRunQueryType.singleRun,
      runsTimeScope: RunsTimeScope.future,
      runsToDisplay: RunsToDisplay.allRuns,
    );
    if (run.isEmpty || c.isClosed) return;
    // The root navigator, not a context: nothing here is captured across the
    // await above.
    await navigatorKey.currentState?.push<dynamic>(
      MaterialPageRoute<dynamic>(
        builder: (BuildContext context) => RunDetailsPage(futureRun: run[0]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Snapshot inside the Obx so itemCount and itemBuilder agree.
      final List<UserRunHistoryModel> runs = c.runs;
      if (runs.isEmpty) {
        return Center(child: Text('No runs logged yet.', style: ts_regular));
      }
      return ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: runs.length,
        padding: const EdgeInsets.only(top: 5),
        separatorBuilder: (BuildContext context, int index) =>
            const Divider(height: 1.0, color: Colors.black45),
        itemBuilder: (BuildContext context, int index) {
          final UserRunHistoryModel item = runs[index];
          return Dismissible(
            key: Key(item.eventId),
            confirmDismiss: (DismissDirection direction) async {
              await c.onSwipe(item, direction);
              return false;
            },
            background: item.canEditRunAttendence == 0
                ? _swipePane(
                    color: Colors.grey,
                    icon: const Icon(
                      FontAwesome.lock,
                      color: Colors.white,
                      size: 35.0,
                    ),
                    label: 'Run locked',
                  )
                : _swipePane(
                    color: hc_red,
                    icon: const Icon(
                      FontAwesome.times_circle,
                      color: Colors.white,
                      size: 35.0,
                    ),
                    label: 'I was not\r\nat the Hash',
                  ),
            secondaryBackground: item.canEditRunAttendence == 0
                ? _swipePane(
                    color: Colors.grey,
                    icon: const Icon(
                      FontAwesome.lock,
                      color: Colors.white,
                      size: 35.0,
                    ),
                    label: 'Run locked',
                    trailing: true,
                  )
                : (item.attendenceState < attendenceAtHash.value) ||
                      ((item.attendenceState >= attendenceAtHash.value) &&
                          (item.isHare == isHareYes.value))
                ? _swipePane(
                    color: Colors.green,
                    icon: const Icon(
                      FontAwesome.check_circle,
                      color: Colors.white,
                      size: 35.0,
                    ),
                    label: 'I was at\r\nthe Hash',
                    trailing: true,
                  )
                : _swipePane(
                    color: Colors.purple,
                    icon: const Padding(
                      padding: EdgeInsets.only(left: 2.5, right: 2.5),
                      child: ImageIcon(
                        AssetImage('images/icons/hare_icon.png'),
                        color: Colors.white,
                        size: 30.0,
                      ),
                    ),
                    label: 'I was a Hare',
                    trailing: true,
                  ),
            onDismissed: (DismissDirection direction) {
              // confirmDismiss always answers false, so never reached.
            },
            child: GestureDetector(
              onTapUp: (TapUpDetails details) => unawaited(_openRun(item)),
              child: UserEventListItem(
                item: item,
                historicalHaringCount: historicalHaringCount,
                historicalTotalRunCount: historicalTotalRunCount,
                showCountry: showCountry,
                showKennel: showKennel,
                setAttendenceStateCallback:
                    (
                      EnumAttendenceState attendenceState,
                      EnumIsHare isHare,
                    ) => c.onSetAttendence(item, attendenceState, isHare),
              ),
            ),
          );
        },
      );
    });
  }

  /// The coloured pane a row reveals as it is swiped.
  Widget _swipePane({
    required Color color,
    required Widget icon,
    required String label,
    bool trailing = false,
  }) {
    final TextStyle style = ts_titleMedium;
    return Container(
      color: color,
      child: Row(
        mainAxisAlignment: trailing
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: trailing
            ? <Widget>[
                Padding(padding: const EdgeInsets.only(right: 15.0), child: icon),
                Padding(
                  padding: const EdgeInsets.only(right: 15.0),
                  child: Text(
                    label,
                    maxLines: 2,
                    textAlign: TextAlign.right,
                    style: style,
                  ),
                ),
              ]
            : <Widget>[
                Padding(padding: const EdgeInsets.only(left: 10.0), child: icon),
                Padding(
                  padding: const EdgeInsets.only(left: 15.0),
                  child: Text(label, maxLines: 2, style: style),
                ),
              ],
      ),
    );
  }
}
