import 'package:harrier_central/imports.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

// class CheckInBindings extends Bindings {
//   @override
//   void dependencies() {
//     final eventAggregate = Get.arguments as RunAdminAggregate;

//     Get.put(
//       CheckInPackController(eventAggregate),
//       tag: eventAggregate.event.eventId,
//       permanent: false,
//     );
//   }
// }

class CheckInPackPage extends StatelessWidget {
  final String controllerTag;

  const CheckInPackPage({super.key, required this.controllerTag});

  // ignore: constant_identifier_names
  static const double LIST_ITEM_HEIGHT = 84.0;

  // ignore: constant_identifier_names
  static const double LIST_ITEM_LEFT_MARGIN = 88.0;

  @override
  Widget build(BuildContext context) {
    // Assuming you know the tag (e.g. passed in as a property or globally available)
    final eventAggregate = Get.find<CheckInPackController>(
      tag: controllerTag,
    ).eventAggregate;

    return GetBuilder<CheckInPackController>(
      id: 'AppScaffold',
      tag: controllerTag,
      builder: (AppScaffoldController) {
        return AppScaffold(
          //key: AppScaffoldController.ScaffoldKey,
          floatingActionButton: SpeedDial(
            // both default to 16
            // marginEnd: 18,
            // marginBottom: 30,
            animatedIcon: AnimatedIcons.menu_close,
            animatedIconTheme: const IconThemeData(size: 22.0),
            // this is ignored if animatedIcon is non null
            // child:const  Icon(Icons.add),
            visible: true,
            curve: Curves.bounceIn,
            overlayColor: Colors.black,
            overlayOpacity: 0.5,
            onOpen: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              AppScaffoldController.searchFocusNode.unfocus();
            },
            //onClose: () => //print('DIAL CLOSED'),
            tooltip: 'Speed Dial',
            heroTag: 'speed-dial-hero-tag-62345',
            backgroundColor: hc_red,
            foregroundColor: Colors.white,
            elevation: 8.0,
            shape: const CircleBorder(),
            children: <SpeedDialChild>[
              SpeedDialChild(
                child: const Icon(Icons.filter_list),
                backgroundColor: Colors.green,
                label: 'Preset Filters',
                labelStyle: TextStyle(
                  fontSize: 18.0 * (1.0 / deviceInfo.deviceTextScaleFactor),
                ),
                onTap: () async {
                  await AppScaffoldController.filterOptionsPopup(context);
                },
              ),
              // SpeedDialChild(
              //     child: const Icon(Icons.person_add),
              //     backgroundColor: hc_blue,
              //     label: 'Add Hasher to Harrier Central',
              //     labelStyle: const TextStyle(fontSize: 18.0),
              //     onTap: () {
              //       Navigator.push<HashersModel>(
              //         context,
              //         MaterialPageRoute<HashersModel>(
              //           builder: (BuildContext context) => HasherProfilePage(
              //             dataContext: EnumDataContext.event,
              //             pageType: EnumMyProfilePageType.newHasherProfile,
              //             eventId: widget.eventAggregate.event.eventId,
              //             kennelId: widget.eventAggregate.event.kennelId,
              //             uiElementsToDisplay: HasherProfilePage.flagUiElement_followKennel,
              //           ),
              //         ),
              //       ).then((HashersModel result) {
              //         _refreshPackListFromTables(true);
              //       });
              //     }),
              SpeedDialChild(
                child: const Icon(FontAwesome.heart, color: Colors.white),
                backgroundColor: hc_blue,
                label: 'Add Virgin / Visitor',
                labelStyle: TextStyle(
                  fontSize: 18.0 * (1.0 / deviceInfo.deviceTextScaleFactor),
                ),
                onTap: () =>
                    AppScaffoldController.showVirginVisitorPopup(context),
                //onTap: () => {},
              ),
              SpeedDialChild(
                child: const Icon(
                  MaterialCommunityIcons.account_search,
                  color: Colors.white,
                ),
                backgroundColor: hc_blue,
                label: 'Find Hasher and add',
                labelStyle: TextStyle(
                  fontSize: 18.0 * (1.0 / deviceInfo.deviceTextScaleFactor),
                ),
                //onTap: () async => {},
                onTap: () async =>
                    await AppScaffoldController.findHasher(context),
              ),
              SpeedDialChild(
                child: const Icon(
                  MaterialCommunityIcons.transfer_right,
                  color: Colors.white,
                ),
                backgroundColor: hc_blue,
                label: 'Copy RSVPs from Previous run',
                labelStyle: TextStyle(
                  fontSize: 18.0 * (1.0 / deviceInfo.deviceTextScaleFactor),
                ),
                onTap: () =>
                    AppScaffoldController.copyRsvpsFromLastRun(context),
                //onTap: () => {},
              ),
              SpeedDialChild(
                child: const Icon(
                  MaterialCommunityIcons.gesture_tap_button,
                  color: Colors.white,
                ),
                backgroundColor: Colors.deepOrange,
                label: 'Toggle multi-selection',
                labelStyle: TextStyle(
                  fontSize: 18.0 * (1.0 / deviceInfo.deviceTextScaleFactor),
                ),
                onTap: () => AppScaffoldController.showMultiSelect.value =
                    !AppScaffoldController.showMultiSelect.value,
                //onTap: () => {},
              ),
              // SpeedDialChild(
              //     child: const Icon(MaterialCommunityIcons.message_video),
              //     backgroundColor: Colors.deepOrange,
              //     label: 'View video tutorial',
              //     labelStyle: TextStyle(
              //       fontSize: 18.0 * (1.0 / deviceInfo.deviceTextScaleFactor),
              //     ),
              //     onTap: () => Navigator.push<dynamic>(
              //           context,
              //           MaterialPageRoute<dynamic>(
              //               builder: (BuildContext context) => const VideoTutorialPage(
              //                     title: 'How to use Check In Page',
              //                     videoUrl: 'https://harriercentral.blob.core.windows.net/help-videos/rabbit.mp4',
              //                   )),
              //         )),
              // if ((widget.eventAggregate.kennel.bankScheme != null) &&
              //     (widget.eventAggregate.kennel.bankScheme !=
              //         '')) ...<SpeedDialChild>[
              //   SpeedDialChild(
              //     child: const Icon(MaterialCommunityIcons.bank),
              //     backgroundColor: Colors.purple,
              //     label: 'Bank Transfer\r\n(Member)',
              //     labelStyle: TextStyle(
              //       fontSize: 18.0 * (1.0 / deviceInfo.deviceTextScaleFactor),
              //     ),
              //     onTap:
              //         () => BankTransferQr.showBankTransferQrCode(
              //           context,
              //           widget.eventAggregate,
              //           true,
              //         ),
              //   ),
              //   SpeedDialChild(
              //     child: const Icon(MaterialCommunityIcons.bank),
              //     backgroundColor: Colors.purple,
              //     label: 'Bank Transfer\r\n(Non-Member)',
              //     labelStyle: TextStyle(
              //       fontSize: 18.0 * (1.0 / deviceInfo.deviceTextScaleFactor),
              //     ),
              //     onTap:
              //         () => BankTransferQr.showBankTransferQrCode(
              //           context,
              //           widget.eventAggregate,
              //           false,
              //         ),
              //   ),
              // ],
            ],
          ),
          appBar: AppBar(
            centerTitle: true,
            backgroundColor: themeAppBarBackground,
            iconTheme: const IconThemeData(color: Colors.white, size: 28.0),
            title: TextScaleFactorClamper(
              textScaleFactor: deviceInfo.textClamp15,
              child: Text(
                AppScaffoldController.isLoading ||
                        eventAggregate.event.eventName.isEmpty
                    ? '... Loading'
                    : '${eventAggregate.event.eventName} Check In',
                style: ts_appBarTitle,
              ),
            ),
          ),

          body: AppScaffoldController.isLoading
              ? const HcAppCircularProgressIndicator(key: Key('430320291'))
              : Stack(
                  fit: StackFit.loose,
                  alignment: AlignmentDirectional.topStart,
                  children: <Widget>[
                    SizedBox(
                      height: MediaQuery.sizeOf(context).height,
                      width: 10,
                    ),
                    PositionedTransition(
                      rect: AppScaffoldController.hasherListAnimation,
                      child: RefreshIndicator(
                        displacement: 120,
                        onRefresh: () async =>
                            await AppScaffoldController.refreshSqlTablesFromBackend(
                              true,
                            ),
                        child: GetBuilder<CheckInPackController>(
                          id: 'hasherList',
                          tag: controllerTag,
                          builder: (AppScaffoldController) {
                            return ListView.separated(
                              separatorBuilder:
                                  (BuildContext context, int index) =>
                                      const Divider(
                                        height: 1.0,
                                        color: Colors.black45,
                                      ),
                              physics: const AlwaysScrollableScrollPhysics(),
                              scrollDirection: Axis.vertical,
                              controller:
                                  AppScaffoldController.scrollController,
                              itemCount:
                                  (AppScaffoldController.filteredList.length) +
                                  2,
                              itemBuilder: (BuildContext context, int index) {
                                if (index ==
                                    (AppScaffoldController
                                        .filteredList
                                        .length)) {
                                  return Obx(() {
                                    if (AppScaffoldController
                                        .forceShowAllHashers
                                        .value) {
                                      return _getAddHasherBlock(
                                        AppScaffoldController,
                                        context,
                                      );
                                    } else {
                                      return _getSearchAllHashersBlock(
                                        AppScaffoldController,
                                        context,
                                      );
                                    }
                                  });
                                } else if (index ==
                                    (AppScaffoldController
                                            .filteredList
                                            .length) +
                                        1) {
                                  return const SizedBox(height: 120);
                                } else {
                                  double amountOwed =
                                      AppScaffoldController
                                              .filteredList[index]
                                              .isMember !=
                                          1
                                      ? eventAggregate.extensions.nonMemberPrice
                                      : eventAggregate.extensions.memberPrice;

                                  amountOwed =
                                      AppScaffoldController
                                              .filteredList[index]
                                              .isMember !=
                                          1
                                      ? eventAggregate.extensions.nonMemberPrice
                                      : eventAggregate.extensions.memberPrice;
                                  amountOwed -= AppScaffoldController
                                      .filteredList[index]
                                      .discountAmount;
                                  amountOwed -=
                                      amountOwed *
                                      (AppScaffoldController
                                              .filteredList[index]
                                              .discountPercent /
                                          100.0);

                                  final String amountOwedStr =
                                      IveCoreUtilities.getFormattedMoney(
                                        amountOwed,
                                        eventAggregate.extensions.digAfterDec,
                                        eventAggregate.extensions.curSym,
                                      );

                                  CheckInPackModel packMember =
                                      AppScaffoldController.filteredList[index];

                                  return Slidable(
                                    key: Key(index.toString()),
                                    // controller: slidableController,

                                    // The start action pane is the one at the left or the top side.
                                    startActionPane: ActionPane(
                                      motion: const BehindMotion(),
                                      // A pane can dismiss the Slidable.
                                      dismissible: DismissiblePane(
                                        closeOnCancel: true,
                                        dismissThreshold: 0.65,
                                        dismissalDuration: const Duration(
                                          milliseconds: 800,
                                        ),
                                        resizeDuration: const Duration(
                                          milliseconds: 800,
                                        ),
                                        confirmDismiss: () async {
                                          if (packMember.isPaid != 1) {
                                            unawaited(
                                              AppScaffoldController.payForEvent(
                                                context,

                                                paymentBankTransfer.value,
                                                index,
                                                -1,
                                              ),
                                            );
                                          }
                                          return false;
                                        },
                                        onDismissed: () {},
                                      ),
                                      dragDismissible: true,
                                      children: [
                                        CustomSlidableAction(
                                          // An action can be bigger than the others.
                                          flex: 2,
                                          onPressed: _emptyFunction,
                                          backgroundColor:
                                              (packMember.isPaid == 1
                                              ? Colors.grey
                                              : hc_blue),

                                          foregroundColor: Colors.white,
                                          child: packMember.isPaid == 1
                                              ? Container(
                                                  color: Colors.grey,
                                                  width: deviceInfo.deviceWidth,
                                                  child: Column(
                                                    children: <Widget>[
                                                      const Padding(
                                                        padding:
                                                            EdgeInsets.only(
                                                              top: 5.0,
                                                            ),
                                                        child: Icon(
                                                          FontAwesome
                                                              .check_circle,
                                                          size: 30.0,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets.only(
                                                              top: 5.0,
                                                            ),
                                                        child: Text(
                                                          'Already\r\npaid',
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: ts_snackbar,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                )
                                              : Container(
                                                  color: hc_blue,
                                                  width: deviceInfo.deviceWidth,
                                                  child: Column(
                                                    children: <Widget>[
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets.only(
                                                              top: 8.0,
                                                            ),
                                                        child: Image.asset(
                                                          'images/icons/payment_type_4.png',
                                                          height: 27.0,
                                                          width: 27.0,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets.only(
                                                              top: 10.0,
                                                            ),
                                                        child: Text(
                                                          '${(eventAggregate.event.eventPriceForExtras) != 0 ? '' : '$amountOwedStr\r\n'}Bank Transfer',
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: ts_titleMedium,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                        ),
                                      ],
                                    ),

                                    // The end action pane is the one at the right or the bottom side.
                                    endActionPane: ActionPane(
                                      motion: const BehindMotion(),
                                      // A pane can dismiss the Slidable.
                                      dismissible: DismissiblePane(
                                        closeOnCancel: true,
                                        dismissThreshold: 0.65,
                                        dismissalDuration: const Duration(
                                          milliseconds: 800,
                                        ),
                                        resizeDuration: const Duration(
                                          milliseconds: 800,
                                        ),
                                        confirmDismiss: () async {
                                          if (packMember.isPaid != 1) {
                                            unawaited(
                                              AppScaffoldController.payForEvent(
                                                context,

                                                paymentCash.value,
                                                index,
                                                -1,
                                              ),
                                            );
                                          } else {
                                            unawaited(
                                              AppScaffoldController.updateAttendenceState(
                                                packMember,
                                                -1,
                                                attendenceOnIn.value,
                                                -1,
                                              ),
                                            );
                                          }
                                          return false;
                                        },
                                        onDismissed: () {},
                                      ),
                                      dragDismissible: true,
                                      children: [
                                        CustomSlidableAction(
                                          // An action can be bigger than the others.
                                          flex: 2,
                                          onPressed: _emptyFunction,
                                          backgroundColor:
                                              (packMember.isPaid == 1
                                                  ? packMember.attendenceState >=
                                                            attendenceOnIn.value
                                                        ? Colors.grey
                                                        : Colors.amber[800]
                                                  : Colors.green) ??
                                              Colors.white,

                                          foregroundColor: Colors.white,
                                          child: packMember.isPaid == 1
                                              ? packMember.attendenceState >=
                                                        attendenceOnIn.value
                                                    ? Container(
                                                        width: deviceInfo
                                                            .deviceWidth,
                                                        color: Colors.grey,
                                                        child: Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .end,
                                                          children: <Widget>[
                                                            const Padding(
                                                              padding:
                                                                  EdgeInsets.only(
                                                                    top: 5.0,
                                                                  ),
                                                              child: Icon(
                                                                FontAwesome
                                                                    .check_circle,
                                                                size: 30.0,
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                            ),
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets.only(
                                                                    top: 5.0,
                                                                  ),
                                                              child: Text(
                                                                'Already\r\nOn-In',
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                                style:
                                                                    ts_snackbar,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      )
                                                    : Container(
                                                        color:
                                                            Colors.amber[800],
                                                        width: deviceInfo
                                                            .deviceWidth,
                                                        child: Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .end,
                                                          children: <Widget>[
                                                            const Padding(
                                                              padding:
                                                                  EdgeInsets.only(
                                                                    top: 2.0,
                                                                  ),
                                                              child: Icon(
                                                                Ionicons
                                                                    .ios_beer,
                                                                size: 30.0,
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                            ),
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets.only(
                                                                    top: 5.0,
                                                                  ),
                                                              child: Text(
                                                                'Record as\r\nOn-In',
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                                style:
                                                                    ts_snackbar,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      )
                                              : Container(
                                                  width: deviceInfo.deviceWidth,
                                                  color: Colors.green,
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    mainAxisSize:
                                                        MainAxisSize.max,
                                                    children: <Widget>[
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets.only(
                                                              bottom: 5.0,
                                                              top: 8.0,
                                                            ),
                                                        child: Image.asset(
                                                          'images/icons/payment_type_3.png',
                                                          height: 25.0,
                                                          width: 25.0,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets.only(
                                                              bottom: 5.0,
                                                            ),
                                                        child: Text(
                                                          '${(eventAggregate.event.eventPriceForExtras ?? 0) != 0 ? '' : '$amountOwedStr\r\n'}Cash',
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: ts_snackbar,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                        ),
                                      ],
                                    ),

                                    child: Container(
                                      color: Colors.white,
                                      child: Obx(
                                        () => _listItem(
                                          context,
                                          index,
                                          AppScaffoldController,
                                        ),
                                      ),
                                    ),
                                  );
                                }
                              },
                            );
                          },
                        ),
                      ),
                    ),
                    SlideTransition(
                      position: AppScaffoldController.filterPanelAnimation,
                      child: Container(
                        height: 120,
                        color: Colors.white,
                        alignment: Alignment.center,
                        child: _filterBar(context, AppScaffoldController),
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
                        width: MediaQuery.sizeOf(context).width,
                        //color: Colors.white,
                        child: Row(
                          children: [
                            RotationTransition(
                              turns: AppScaffoldController.buttonAnimation,
                              child: IconButton(
                                padding: const EdgeInsets.all(0),
                                onPressed:
                                    AppScaffoldController.toggleFilterPanel,
                                icon: Icon(
                                  FontAwesome5Solid.arrow_alt_circle_right,
                                  size: 35,
                                  color: AppScaffoldController.showFilter.value
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
                                          onChanged: AppScaffoldController
                                              .onSearchChanged,
                                          focusNode: AppScaffoldController
                                              .searchFocusNode,
                                          controller: AppScaffoldController
                                              .searchController,
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
                                  Obx(
                                    () => Text(
                                      AppScaffoldController
                                          .searchTypeText
                                          .value,
                                      style:
                                          AppScaffoldController
                                              .highlightSearchType
                                              .value
                                          ? ts_footnoteSmallRed
                                          : ts_footnoteSmall,
                                    ),
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
                                onPressed: AppScaffoldController.clearSearch,
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
        );
      },
    );
  }

  void _emptyFunction(BuildContext context) {}

  Widget _listItem(
    BuildContext context,
    int index,
    CheckInPackController controller,
  ) {
    final hasher = controller.filteredList[index];

    double multselectMargin = controller.showMultiSelect.value ? 40.0 : 0.0;

    return Row(
      children: [
        SizedBox(
          width: multselectMargin,
          child:
              ((hasher.hasherId) == null ||
                  (controller.showMultiSelect.value == false))
              ? null
              : Obx(
                  () => Checkbox(
                    value:
                        controller.multiSelectValues[hasher.hasherId!]?.value ??
                        (controller.multiSelectValues[hasher.hasherId!] =
                                false.obs)
                            .value,

                    onChanged: (bool? value) {
                      if (value != null) {
                        if (hasher.hasherId != null) {
                          if (controller.multiSelectValues.containsKey(
                            hasher.hasherId,
                          )) {
                            controller
                                    .multiSelectValues[hasher.hasherId]!
                                    .value =
                                value;
                          } else {
                            controller.multiSelectValues[hasher.hasherId!] =
                                RxBool(value);
                          }
                        }
                      }
                    },
                  ),
                ),
        ),
        GestureDetector(
          onTap: () => controller.onHasherTapped(context, index),
          child: Container(
            color: controller.shouldHighlightHasher(hasher)
                ? Colors.amber.shade100
                : Colors.white,
            width: MediaQuery.sizeOf(context).width - multselectMargin,

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
                      image: hasher.photo.startsWith('https://')
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
                  top: 3,
                  child: Row(
                    children: [
                      if (hasher.isMember == 1)
                        Padding(
                          padding: const EdgeInsets.only(right: 2.0),
                          child: Icon(
                            MaterialCommunityIcons.star_circle,
                            color: Colors.green.shade800,
                            size: 23,
                          ),
                        ),
                      Text(
                        hasher.nameForDisplay,
                        style: TextStyle(
                          color: hasher.isMember == 1
                              ? Colors.green.shade800
                              : Colors.black,
                          fontFamily: hasher.isMember != 0
                              ? 'AvenirNextCondensedDemiBold'
                              : 'AvenirNextCondensedMedium',
                          fontSize: 25.0,
                          height: 1.0,
                        ),
                      ),
                      if (hasher.virginVisitorType == 0)
                        Text(
                          '  (${hasher.firstName.trim()} ${hasher.lastName.trim()})',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(
                            fontFamily: 'AvenirNextCondensedMedium',
                            fontSize: 18.0,
                            height: 1.0,
                            color: hasher.isMember == 1
                                ? Colors.green.shade900
                                : Colors.black,
                          ),
                        ),
                    ],
                  ),
                ),

                if (hasher.homeKennelName != null)
                  Positioned.fill(
                    left: LIST_ITEM_LEFT_MARGIN + 3.0,
                    top: 27,
                    child: Text(
                      hasher.homeKennelName!,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                        fontFamily: 'AvenirNextCondensedMedium',
                        fontSize: 18.0,
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
                if (controller.shouldShowDrinkIcon(hasher))
                  Positioned(
                    top: 8,
                    right: 8,
                    width: 35,
                    height: 35,
                    child: Image.asset('images/icons/beer_mug.png'),
                  ),
                // Haring count label
                if (hasher.totalHaringThisKennel > 0)
                  Positioned(
                    right: 4,
                    bottom: 17,
                    child: Text(
                      'Hared = ${hasher.totalHaringThisKennel + hasher.historicalHaringCount}',
                      style: controller.getHaringLabelStyle(hasher),
                    ),
                  ),
                // Run count label
                if (hasher.totalRunsThisKennel > 0)
                  Positioned(
                    right: 4,
                    bottom: 1,
                    child: Text(
                      'Total Runs = ${hasher.totalRunsThisKennel + hasher.historicalTotalRunCount}',
                      style: controller.getRunLabelStyle(hasher),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _filterBar(BuildContext context, CheckInPackController controller) {
    return TextScaleFactorClamper(
      textScaleFactor: deviceInfo.textClamp25,
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
        width: MediaQuery.sizeOf(context).width,
        height: 120,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            CheckinFiltersCell(
              counter: controller.memberCount.value,
              label: 'Member',
              index: 5,
              onTap: () async {
                await controller.refreshPackListFromTables(true);
              },
              filterValues: controller.filterValues,
            ),

            CheckinFiltersCell(
              counter: controller.countComing.value,
              label: 'Coming',
              index: 1,
              useTriState: false,
              onTap: () async {
                await controller.refreshPackListFromTables(true);
              },
              filterValues: controller.filterValues,
            ),

            CheckinFiltersCell(
              counter: controller.countAtHash.value,
              index: 2,
              label: 'At Hash',
              onTap: () async {
                await controller.refreshPackListFromTables(true);
              },
              filterValues: controller.filterValues,
            ),
            CheckinFiltersCell(
              counter: controller.countPaid.value,
              index: 3,
              label: 'Paid',
              onTap: () async {
                await controller.refreshPackListFromTables(true);
              },
              filterValues: controller.filterValues,
            ),
            CheckinFiltersCell(
              counter: controller.countOnIn.value,
              index: 4,
              label: 'On In',
              onTap: () async {
                await controller.refreshPackListFromTables(true);
              },
              filterValues: controller.filterValues,
            ),
            CheckinFiltersCell(
              counter: controller.drinkCount.value,
              index: 6,
              useTriState: false,
              label: 'Drink!',
              onTap: () async {
                await controller.refreshPackListFromTables(true);
              },
              filterValues: controller.filterValues,
            ),
          ],
        ),
      ),
    );
  }

  Widget _getAddHasherBlock(
    CheckInPackController controller,
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: () async {
        HashersModel? result = await Navigator.push<HashersModel>(
          context,
          MaterialPageRoute<HashersModel>(
            builder: (BuildContext context) => HasherProfilePage(
              dataContext: EnumDataContext.event,
              pageType: EnumMyProfilePageType.newHasherProfile,
              eventId: controller.eventAggregate.event.eventId,
              kennelId: controller.eventAggregate.event.kennelId,
              uiElementsToDisplay: HasherProfilePage.flagUiElement_followKennel,
              hashNameFromSearch: _capitalizeFirstLetter(
                controller.searchController.text,
              ),
            ),
          ),
        );

        controller.forceShowAllHashers.value = false;
        if (result != null) {
          await controller.refreshPackListFromTables(true);
          // NULLSAFETEST
          // if (result.dispName == '') {
          //   result = result.copyWith(dispName: null);
          // }
          // if (result.hashName == '') {
          //   result = result.copyWith(hashName: null);
          // }

          //controller.searchText = result.dispName;
          controller.searchController.text = result.dispName;
          await controller.filterPackListResults();
        }
      },
      child: Container(
        height: 80,
        margin: const EdgeInsets.only(left: 10),
        child: Row(
          children: <Widget>[
            Icon(SimpleLineIcons.magnifier_add, size: 35.0, color: hc_red),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 14.0, right: 10.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Can\'t find a Hasher?', style: ts_contentStyle),
                    AutoSizeText(
                      controller.searchController.text.isNotEmpty
                          ? 'Click here to add \'${_capitalizeFirstLetter(controller.searchController.text)}\''
                          : 'Click here to add a new Hasher',
                      style: ts_contentStyle,
                      maxLines: 1,
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

  Widget _getSearchAllHashersBlock(
    CheckInPackController controller,
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: () async {
        controller.forceShowAllHashers.value =
            !controller.forceShowAllHashers.value;
        await controller.filterPackListResults();
      },
      child: Container(
        height: 80,
        margin: const EdgeInsets.only(left: 10),
        child: Row(
          children: <Widget>[
            Icon(SimpleLineIcons.magnifier, size: 35.0, color: hc_blue),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 14.0, right: 10.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Can\'t find a Hasher?', style: ts_contentStyle),
                    AutoSizeText(
                      'Click here to search all Hashers',
                      style: ts_contentStyle,
                      maxLines: 1,
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

  String _capitalizeFirstLetter(String s) =>
      s.isNotEmpty ? '${s[0].toUpperCase()}${s.substring(1)}' : s;
}

// Controller defined earlier above remains unchanged.
