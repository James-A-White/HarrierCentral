import 'package:harrier_central/imports.dart';

class KennelsListPage extends StatelessWidget {
  const KennelsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final KennelsListPageController controller = Get.put(KennelsListPageController());

    return AppScaffold(
      extendBody: true,
      floatingActionButton: _buildFab(controller),
      body: Obx(() {
        final bool showSpinner =
            controller.filteredList.isEmpty && tableModel.globalKennelMainPageList == null;

        if (showSpinner) {
          return const Center(
            child: HcAppCircularProgressIndicator(key: Key('3320159590')),
          );
        }

        final bool isEmpty = controller.filteredList.isEmpty &&
            tableModel.globalKennelMainPageList != null &&
            tableModel.globalKennelMainPageList!.isEmpty;

        return Container(
          decoration: Backgrounds.defaultHcBackground(),
          child: isEmpty
              ? Center(child: Text('Loading Kennels.', style: ts_headingLarge))
              : NestedScrollView(
                  controller: controller.scrollController,
                  headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
                    return <Widget>[
                      SliverList(
                        delegate: SliverChildListDelegate(<Widget>[
                          _buildSearchBar(context, controller),
                        ]),
                      ),
                    ];
                  },
                  body: RefreshIndicator(
                    onRefresh: controller.handleRefresh,
                    child: ListView.builder(
                      itemCount: controller.filteredList.length + 1,
                      itemBuilder: (BuildContext context, int index) {
                        if (index == controller.filteredList.length) {
                          return Container(height: 100.0);
                        }
                        return Padding(
                          padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                          child: KennelListItem(
                            kennelItem: controller.filteredList[index],
                            kennelSelected: () => controller.navigateToKennelAdmin(context, index),
                            onFollowSelected: (int followValue, int isHomeKennel) =>
                                controller.updateFollowStatus(index, followValue, isHomeKennel),
                            onNotificationSelected: (NotificationState state) =>
                                controller.updateNotificationStatus(index, state),
                            onEmailSelected: (dynamic retVal) =>
                                controller.updateEmailStatus(index, retVal),
                          ),
                        );
                      },
                    ),
                  ),
                ),
        );
      }),
    );
  }

  Widget _buildFab(KennelsListPageController controller) {
    final int randomTag = Random().nextInt(1000000) + 1000000;
    return SpeedDial(
      animatedIcon: AnimatedIcons.menu_close,
      animatedIconTheme: const IconThemeData(size: 22.0),
      visible: true,
      curve: Curves.bounceIn,
      overlayColor: Colors.black,
      overlayOpacity: 0.5,
      tooltip: 'Speed Dial',
      heroTag: 'speed-dial-hero-tag-$randomTag',
      backgroundColor: hc_red,
      foregroundColor: Colors.white,
      elevation: 8.0,
      shape: const CircleBorder(),
      children: <SpeedDialChild>[
        SpeedDialChild(
          child: const Icon(Entypo.heart, color: Colors.white),
          backgroundColor: hc_red,
          label: 'Sort by following status',
          labelStyle: const TextStyle(fontSize: 18.0),
          onTap: () async {
            controller.sortByType.value = EnumSortKennelListBy.following;
            await controller.refreshFromTable(true);
          },
        ),
        if (appModel.hasLocationPermissions)
          SpeedDialChild(
            child: const Icon(FontAwesome.sort_amount_asc),
            backgroundColor: Colors.lightBlue.shade500,
            label: 'Sort by distance',
            labelStyle: const TextStyle(fontSize: 18.0),
            onTap: () async {
              controller.sortByType.value = EnumSortKennelListBy.distance;
              await controller.refreshFromTable(true);
            },
          ),
        SpeedDialChild(
          child: const Icon(FontAwesome.sort_alpha_asc),
          backgroundColor: Colors.pink.shade200,
          label: 'Sort by Kennel name',
          labelStyle: const TextStyle(fontSize: 18.0),
          onTap: () async {
            controller.sortByType.value = EnumSortKennelListBy.kennelName;
            await controller.refreshFromTable(true);
          },
        ),
        SpeedDialChild(
          child: const Icon(MaterialCommunityIcons.city_variant_outline),
          backgroundColor: Colors.lightGreen.shade500,
          label: 'Sort by city name',
          labelStyle: const TextStyle(fontSize: 18.0),
          onTap: () async {
            controller.sortByType.value = EnumSortKennelListBy.cityName;
            await controller.refreshFromTable(true);
          },
        ),
        SpeedDialChild(
          child: const Icon(Entypo.globe),
          backgroundColor: Colors.lightGreen.shade500,
          label: 'Sort by country/region name',
          labelStyle: const TextStyle(fontSize: 18.0),
          onTap: () async {
            controller.sortByType.value = EnumSortKennelListBy.countryRegionName;
            await controller.refreshFromTable(true);
          },
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context, KennelsListPageController controller) {
    return Container(
      padding: const EdgeInsets.only(left: 10),
      color: Colors.white,
      width: MediaQuery.sizeOf(context).width,
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              autocorrect: false,
              onChanged: (String text) {
                controller.searchText.value = text;
              },
              focusNode: controller.searchFocusNode,
              controller: controller.searchController,
              keyboardType: TextInputType.text,
              style: ts_titleMediumBlack,
              decoration: InputDecoration(
                border: InputBorder.none,
                icon: const Icon(FontAwesome.search, color: Colors.black),
                hintText: 'Search...',
                hintStyle: ts_searchLabel,
              ),
            ),
          ),
          SizedBox(
            width: 40,
            child: TextButton(
              style: TextButton.styleFrom(
                shape: button_shape,
                textStyle: TextStyle(color: Colors.grey.shade700),
                backgroundColor: Colors.white,
              ),
              child: Text(
                'X',
                style: ts_headingBlack.copyWith(color: Colors.grey.shade700),
              ),
              onPressed: () {
                controller.searchController.text = '';
                controller.searchText.value = '';
              },
            ),
          ),
        ],
      ),
    );
  }
}
