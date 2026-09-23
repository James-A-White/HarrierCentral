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
              if (controller.awards.isEmpty) {
                return _EmptyState(controller: controller);
              }
              return _AwardsList(controller: controller);
            }),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.controller});

  final DrinksListController controller;

  @override
  Widget build(BuildContext context) {
    // Its own Obx: a child widget's build runs after the parent Obx's builder
    // has returned, so reads here are not tracked by the parent.
    return Obx(() => _body(controller.loadFailed.value));
  }

  Widget _body(bool failed) {
    return Center(
      child: Padding(
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
              // Two different facts, which used to share one message. "No
              // awards" is a statement about the run; "couldn't load" is a
              // statement about the phone.
              failed ? 'Could not load the awards' : 'No awards yet for this Trail',
              textAlign: TextAlign.center,
              style: ts_headingVeryLarge.copyWith(color: themeBackgroundColor),
            ),
            if (failed) ...<Widget>[
              const SizedBox(height: 10),
              Text(
                'A connection is required to get the current run counts. This '
                'run may well have awards — they just could not be fetched.',
                textAlign: TextAlign.center,
                style: ts_body.copyWith(color: themeBackgroundColor),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: () => unawaited(controller.manualRefresh()),
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AwardsList extends StatelessWidget {
  const _AwardsList({required this.controller});

  final DrinksListController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() => _list(context, controller.awards));
  }

  Widget _list(BuildContext context, List<DrinksResults> awards) {
    // Snapshot inside the Obx so itemCount and itemBuilder agree.
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: awards.length,
      separatorBuilder: (BuildContext context, int index) =>
          const Divider(height: 1.0, color: Colors.black45),
      itemBuilder: (BuildContext context, int index) {
        final DrinksResults a = awards[index];
        return Row(
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
      },
    );
  }
}
