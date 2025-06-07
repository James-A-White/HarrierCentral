import 'package:get/get.dart';
import 'package:harrier_central/imports.dart';
import '../check_in_pack_page/check_in_pack_page_controller.dart';

// This is the complete StatelessWidget version of CheckInPackPage using the GetX controller

class CheckInPackPage extends StatelessWidget {
  const CheckInPackPage({super.key, required this.eventAggregate});

  final RunAdminAggregate eventAggregate;

  // ignore: constant_identifier_names
  static const double LIST_ITEM_HEIGHT = 84.0;

  // ignore: constant_identifier_names
  static const double LIST_ITEM_LEFT_MARGIN = 88.0;

  @override
  Widget build(BuildContext context) {
    final CheckInPackController controller = Get.put(
      CheckInPackController(eventAggregate),
      tag: eventAggregate.event.eventId,
      permanent: false,
      // will auto-dispose on page pop
    );

    return Obx(
      () => Scaffold(
        key: controller.scaffoldKey,
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: themeAppBarBackground,
          iconTheme: const IconThemeData(color: Colors.white, size: 28.0),
          title: TextScaleFactorClamper(
            textScaleFactor: G0<DeviceInfo>().textClamp15,
            child: Text(
              controller.isLoading.value ||
                      eventAggregate.event.eventName.isEmpty
                  ? '... Loading'
                  : '${eventAggregate.event.eventName} Check In',
              style: ts_appBarTitle,
            ),
          ),
        ),
        body:
            controller.isLoading.value
                ? const HcCircularProgressIndicator(key: Key('430320291'))
                : Stack(
                  fit: StackFit.loose,
                  alignment: AlignmentDirectional.topStart,
                  children: <Widget>[
                    SizedBox(
                      height: MediaQuery.of(context).size.height,
                      width: 10,
                    ),
                    PositionedTransition(
                      rect: controller.hasherListAnimation,
                      child: Obx(
                        () => RefreshIndicator(
                          displacement: 120,
                          onRefresh:
                              () async => await controller
                                  .refreshSqlTablesFromBackend(true),
                          child: ListView.separated(
                            separatorBuilder:
                                (context, index) => const Divider(
                                  height: 1.0,
                                  color: Colors.black45,
                                ),
                            physics: const AlwaysScrollableScrollPhysics(),
                            controller: controller.scrollController,
                            itemCount: controller.filteredList.length,
                            itemBuilder: (context, index) {
                              final hasher = controller.filteredList[index];
                              return GestureDetector(
                                onTap:
                                    () => controller.onHasherTapped(
                                      context,
                                      index,
                                    ),
                                child: Container(
                                  color:
                                      controller.shouldHighlightHasher(hasher)
                                          ? Colors.amber.shade100
                                          : Colors.white,
                                  width: MediaQuery.of(context).size.width,

                                  child: Stack(
                                    children: [
                                      // Avatar photo
                                      Container(
                                        width: LIST_ITEM_HEIGHT,
                                        height: LIST_ITEM_HEIGHT,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade200,
                                          image: DecorationImage(
                                            fit: BoxFit.cover,
                                            image:
                                                hasher.photo.startsWith(
                                                      'https://',
                                                    )
                                                    ? NetworkImage(hasher.photo)
                                                    : AssetImage(
                                                          'images/avatars/${hasher.photo.replaceAll('bundle://', '')}.jpg',
                                                        )
                                                        as ImageProvider,
                                          ),
                                        ),
                                      ),
                                      // Name
                                      Positioned(
                                        left: LIST_ITEM_LEFT_MARGIN + 2.0,
                                        top: 10,
                                        child: Text(
                                          hasher.nameForDisplay,
                                          style: TextStyle(
                                            fontFamily:
                                                hasher.isMember != 0
                                                    ? 'AvenirNextCondensedDemiBold'
                                                    : 'AvenirNextCondensedMedium',
                                            fontSize: 25.0,
                                            height: 1.0,
                                          ),
                                        ),
                                      ),
                                      // RSVP Icon
                                      Positioned(
                                        left: LIST_ITEM_LEFT_MARGIN,
                                        bottom: 5,
                                        child: controller.buildRsvpIcon(
                                          index,
                                          hasher.rsvpState,
                                          hasher.isHare,
                                          hasher,
                                        ),
                                      ),
                                      // Attendance Icon
                                      Positioned(
                                        left: LIST_ITEM_LEFT_MARGIN + 35.0,
                                        bottom: 5,
                                        child: controller.buildAttendanceIcon(
                                          index,
                                          hasher.rsvpState,
                                          hasher.attendenceState,
                                          hasher,
                                        ),
                                      ),
                                      // Payment Icon
                                      Positioned(
                                        left: LIST_ITEM_LEFT_MARGIN + 70.0,
                                        bottom: 5,
                                        child: controller.buildPaymentIcon(
                                          index,
                                          hasher.attendenceState,
                                          hasher.isPaid,
                                          hasher.paymentType,

                                          hasher,
                                        ),
                                      ),
                                      // Special Run Icon
                                      if (controller.shouldShowDrinkIcon(
                                        hasher,
                                      ))
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          width: 35,
                                          height: 35,
                                          child: Image.asset(
                                            'images/icons/beer_mug.png',
                                          ),
                                        ),
                                      // Haring count label
                                      if (hasher.totalHaringThisKennel > 0)
                                        Positioned(
                                          right: 4,
                                          bottom: 17,
                                          child: Text(
                                            'Hared = ${hasher.totalHaringThisKennel + hasher.historicalHaringCount}',
                                            style: controller
                                                .getHaringLabelStyle(hasher),
                                          ),
                                        ),
                                      // Run count label
                                      if (hasher.totalRunsThisKennel > 0)
                                        Positioned(
                                          right: 4,
                                          bottom: 1,
                                          child: Text(
                                            'Total Runs = ${hasher.totalRunsThisKennel + hasher.historicalTotalRunCount}',
                                            style: controller.getRunLabelStyle(
                                              hasher,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    SlideTransition(
                      position: controller.filterPanelAnimation,
                      child: Container(
                        height: 120,
                        color: Colors.white,
                        alignment: Alignment.center,
                        child: _filterBar(context, controller),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      child: Container(
                        decoration: const BoxDecoration(
                          // border: new Border.all(width: 1.0, color: Colors.black),
                          //shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: Color.fromARGB(70, 0, 0, 0),
                              offset: Offset(0.0, 6.0),
                              blurRadius: 10.0,
                            ),
                          ],
                        ),
                        height: 85,
                        padding: const EdgeInsets.only(top: 10),
                        width: MediaQuery.of(context).size.width,
                        //color: Colors.white,
                        child: Row(
                          children: [
                            RotationTransition(
                              turns: controller.buttonAnimation,
                              child: IconButton(
                                padding: const EdgeInsets.all(0),
                                onPressed: controller.toggleFilterPanel,
                                icon: Icon(
                                  FontAwesome5Solid.arrow_alt_circle_right,
                                  size: 35,
                                  color:
                                      controller.showFilter.value
                                          ? Colors.green
                                          : Colors.grey,
                                ),
                              ),
                            ),
                            Container(
                              height: 60,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              decoration: const BoxDecoration(
                                border: Border(
                                  left: BorderSide(
                                    color: Colors.black,
                                    width: 1.0,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          autocorrect: false,
                                          onChanged: controller.onSearchChanged,
                                          focusNode: controller.searchFocusNode,
                                          controller:
                                              controller.searchController,
                                          keyboardType: TextInputType.text,
                                          style: ts_titleMediumBlack,
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                            icon: const Icon(
                                              FontAwesome.search,
                                              color: Colors.black,
                                            ),
                                            hintText:
                                                'Enter Hash or mortal name',
                                            hintStyle: ts_hint,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    controller.searchTypeText.value,
                                    style:
                                        controller.highlightSearchType.value
                                            ? ts_footnoteSmallRed
                                            : ts_footnoteSmall,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 40,
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  shape: button_shape,
                                  backgroundColor: Colors.white,
                                ),
                                onPressed: controller.clearSearch,
                                child: Text(
                                  'X',
                                  style: ts_headingBlack.copyWith(
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _filterBar(BuildContext context, CheckInPackController controller) {
    return TextScaleFactorClamper(
      textScaleFactor: G0<DeviceInfo>().textClamp25,
      child: Container(
        decoration: const BoxDecoration(
          // border: new Border.all(width: 1.0, color: Colors.black),
          //shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Color.fromARGB(70, 0, 0, 0),
              offset: Offset(0.0, 6.0),
              blurRadius: 10.0,
            ),
          ],
        ),
        padding: const EdgeInsets.only(top: 10),
        width: MediaQuery.of(context).size.width,
        height: 120,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            CheckinFiltersCell(
              counter: controller.memberCount.value,
              label: 'Member',
              index: 5,
              onTap: () {
                controller.refreshPackListFromTables(true);
              },
              filterValues: controller.filterValues,
            ),

            CheckinFiltersCell(
              counter: controller.countComing.value,
              label: 'Coming',
              index: 1,
              useTriState: false,
              onTap: () {
                controller.refreshPackListFromTables(true);
              },
              filterValues: controller.filterValues,
            ),

            CheckinFiltersCell(
              counter: controller.countAtHash.value,
              index: 2,
              label: 'At Hash',
              onTap: () {
                controller.refreshPackListFromTables(true);
              },
              filterValues: controller.filterValues,
            ),
            CheckinFiltersCell(
              counter: controller.countPaid.value,
              index: 3,
              label: 'Paid',
              onTap: () {
                controller.refreshPackListFromTables(true);
              },
              filterValues: controller.filterValues,
            ),
            CheckinFiltersCell(
              counter: controller.countOnIn.value,
              index: 4,
              label: 'On In',
              onTap: () {
                controller.refreshPackListFromTables(true);
              },
              filterValues: controller.filterValues,
            ),
            CheckinFiltersCell(
              counter: controller.drinkCount.value,
              index: 6,
              useTriState: false,
              label: 'Drink!',
              onTap: () {
                controller.refreshPackListFromTables(true);
              },
              filterValues: controller.filterValues,
            ),
          ],
        ),
      ),
    );
  }
}

// Controller defined earlier above remains unchanged.
