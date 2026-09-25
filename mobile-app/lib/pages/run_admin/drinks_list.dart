// ignore_for_file: constant_identifier_names

import 'package:harrier_central/imports.dart';

/// "Drink chug-a-lug" — the milestone awards for a run. StatelessWidget over
/// [DrinksListController]; see the controller for why it is no longer a State.
class DrinksList extends StatelessWidget {
  const DrinksList({super.key, required this.eventAggregate});

  final RunAdminAggregate eventAggregate;

  static const double LIST_ITEM_HEIGHT = 84.0;
  static const double LIST_ITEM_ELEMENT_HEIGHT = 84.0;

  @override
  Widget build(BuildContext context) {
    // GetBuilder's `init` puts the controller and deletes it when this widget
    // is disposed — the page is pushed with a MaterialPageRoute, so GetX would
    // not otherwise know when to. Every visit therefore starts a fresh load.
    return GetBuilder<DrinksListController>(
      init: DrinksListController(eventAggregate: eventAggregate),
      tag: DrinksListController.tagFor(eventAggregate.event.eventId),
      builder: (DrinksListController controller) => AppScaffold(
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: themeAppBarBackground,
          iconTheme: const IconThemeData(color: Colors.white, size: 28.0),
          title: Text('Drink chug-a-lug', style: ts_appBarTitle),
          actions: <Widget>[
            IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () => unawaited(controller.manualRefresh()),
            ),
          ],
        ),
        body: SafeArea(
          child: Container(
            decoration: Backgrounds.defaultHcBackgroundLight(),
            child: Obx(() {
              if (controller.isLoading.value) {
                return const HcAppCircularProgressIndicator(
                  key: Key('52039320'),
                );
              }
              // Every Rx the page depends on is read here, in this builder:
              // the children below get plain values.
              final List<DrinksResults> shown = controller.visible;
              final bool all = controller.showAll.value;
              final bool anyExpected = controller.expected.isNotEmpty;
              final bool failed = controller.loadFailed.value;
              final bool predict = controller.canPredict;
              return Column(
                children: <Widget>[
                  if (predict)
                    _AllAtRunHeader(
                      all: all,
                      onSelect: (bool v) => controller.showAll.value = v,
                    ),
                  Expanded(
                    child: shown.isEmpty
                        ? _EmptyState(
                            controller: controller,
                            failed: failed,
                            predict: predict,
                            all: all,
                            anyExpected: anyExpected,
                          )
                        : _AwardsList(awards: shown),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.controller,
    required this.failed,
    required this.predict,
    required this.all,
    required this.anyExpected,
  });

  final DrinksListController controller;
  final bool failed;
  final bool predict;
  final bool all;
  final bool anyExpected;

  @override
  Widget build(BuildContext context) {
    // Two different facts, which used to share one message. "No awards" is a
    // statement about the run; "couldn't load" is a statement about the phone.
    final String title;
    String? detail;
    if (failed) {
      title = 'Could not load the awards';
      detail =
          'A connection is required to get the current run counts. This '
          'run may well have awards — they just could not be fetched.';
    } else if (predict && !all && anyExpected) {
      title = 'Nobody here has an award yet';
      detail = 'Switch to All to see who is due one if they come.';
    } else if (predict) {
      title = 'No awards due for this Trail';
      detail =
          'Nobody checked in, recently active or on the RSVP list has a '
          'milestone coming up.';
    } else {
      title = 'No awards for this Trail';
    }
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Icon(
              failed ? Icons.cloud_off : Icons.emoji_events_outlined,
              size: 52,
              color: themeBackgroundColor,
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: ts_headingVeryLarge.copyWith(color: themeBackgroundColor),
            ),
            if (detail != null) ...<Widget>[
              const SizedBox(height: 10),
              Text(
                detail,
                textAlign: TextAlign.center,
                style: ts_body.copyWith(color: themeBackgroundColor),
              ),
            ],
            if (failed) ...<Widget>[
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: () => unawaited(controller.manualRefresh()),
                icon: const Icon(Icons.refresh),
                label: const Text('Try again', textAlign: TextAlign.center),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The All | At Run switch and what grey means. Only for today's and upcoming
/// runs ([DrinksListController.canPredict]).
class _AllAtRunHeader extends StatelessWidget {
  const _AllAtRunHeader({required this.all, required this.onSelect});

  final bool all;
  final void Function(bool all) onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Center(
            child: Material(
              color: themeAppBarBackground,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _segment('All', selected: all, onTap: () => onSelect(true)),
                    _segment(
                      'At Run',
                      selected: !all,
                      onTap: () => onSelect(false),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (all) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              'Greyed out: not checked in — the award they get if they come. '
              'Counts as of today.',
              textAlign: TextAlign.center,
              style: ts_body.copyWith(
                color: themeBackgroundColor,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _segment(
    String label, {
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: selected ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(17),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: selected ? themeAppBarBackground : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _AwardsList extends StatelessWidget {
  const _AwardsList({required this.awards});

  /// A snapshot taken in the page's Obx, so itemCount and itemBuilder agree.
  final List<DrinksResults> awards;

  /// Luminance-weighted greyscale, for a hasher who is not checked in.
  static const List<double> _greyscale = <double>[
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 1, 0,
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: awards.length,
      separatorBuilder: (BuildContext context, int index) =>
          const Divider(height: 1.0, color: Colors.black45),
      itemBuilder: (BuildContext context, int index) {
        final DrinksResults a = awards[index];
        final Widget row = Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            const SizedBox(height: DrinksList.LIST_ITEM_HEIGHT, width: 10.0),
            Utilities.getProfilePic(
              a.photo,
              DrinksList.LIST_ITEM_ELEMENT_HEIGHT,
              DrinksList.LIST_ITEM_ELEMENT_HEIGHT,
              context,
              a.dispName,
            ),
            Expanded(
              child: Column(
                children: <Widget>[
                  FittedBox(
                    child: Text(a.dispName, style: ts_titleLargeCondensedBlack),
                  ),
                  if (a.specialRunCount == 1)
                    FittedBox(
                      child: Text('1 run', style: ts_titleLargeCondensedBlack),
                    ),
                  if (a.specialRunCount > 1)
                    FittedBox(
                      child: Text(
                        '${a.totalRunsThisKennel} runs',
                        style: ts_titleLargeCondensedBlack,
                      ),
                    ),
                  if (a.specialHaringCount == 1)
                    FittedBox(
                      child: Text(
                        'First time haring',
                        style: ts_titleLargeCondensedBlack,
                      ),
                    ),
                  if (a.specialHaringCount > 1)
                    FittedBox(
                      child: Text(
                        '${a.totalHaringThisKennel} hared runs',
                        style: ts_titleLargeCondensedBlack,
                      ),
                    ),
                ],
              ),
            ),
            if (a.specialRunCount > 0)
              Image.asset(
                'images/run_count_icons/run_${a.specialRunCount}.png',
                height: DrinksList.LIST_ITEM_ELEMENT_HEIGHT,
                width: DrinksList.LIST_ITEM_ELEMENT_HEIGHT,
              ),
            if (a.specialHaringCount > 0)
              Image.asset(
                'images/run_count_icons/rabbit_with_beer.png',
                height: DrinksList.LIST_ITEM_ELEMENT_HEIGHT,
                width: DrinksList.LIST_ITEM_ELEMENT_HEIGHT,
              ),
            const Divider(),
          ],
        );
        if (a.atRun) return row;
        // Not checked in: the photo, text and badge fade together, so the row
        // reads as "not here yet" rather than as a style glitch.
        return Semantics(
          label: '${a.dispName}, not checked in',
          child: Opacity(
            opacity: 0.45,
            child: ColorFiltered(
              colorFilter: const ColorFilter.matrix(_greyscale),
              child: row,
            ),
          ),
        );
      },
    );
  }
}
