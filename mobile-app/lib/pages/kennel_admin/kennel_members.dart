// ignore_for_file: constant_identifier_names

import 'package:harrier_central/imports.dart';

/// The kennel admin's members list. Stateless over [KennelMembersController];
/// navigation to the profile, access and role pages stays here, every read
/// and write lives there.
class KennelMembersList extends StatelessWidget {
  const KennelMembersList({super.key, required this.kennelListAggregate});

  final KennelListAggregate kennelListAggregate;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<KennelMembersController>(
      init: KennelMembersController(kennelListAggregate: kennelListAggregate),
      tag: KennelMembersController.tagFor(kennelListAggregate.kennel.kennelId),
      builder: (KennelMembersController c) => AppScaffold(
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: themeAppBarBackground,
          iconTheme: const IconThemeData(color: Colors.white, size: 28.0),
          title: Text(
            '${kennelListAggregate.kennel.kennelShortName} Members',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        floatingActionButton: SpeedDial(
          animatedIcon: AnimatedIcons.menu_close,
          animatedIconTheme: const IconThemeData(size: 22.0),
          visible: true,
          curve: Curves.bounceIn,
          overlayColor: Colors.black,
          overlayOpacity: 0.5,
          onOpen: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
          tooltip: 'Speed Dial',
          heroTag: 'speed-dial-hero-tag-422345',
          backgroundColor: hc_red,
          foregroundColor: Colors.white,
          elevation: 8.0,
          shape: const CircleBorder(),
          children: <SpeedDialChild>[
            SpeedDialChild(
              child: Icon(c.nextSort.icon),
              backgroundColor: Colors.deepOrange,
              label: c.nextSort.label,
              labelStyle: const TextStyle(fontSize: 18.0),
              onTap: () => unawaited(c.cycleSort()),
            ),
            SpeedDialChild(
              child: const Icon(MaterialCommunityIcons.account_search),
              backgroundColor: hc_blue,
              label: 'Find Hasher and add',
              labelStyle: const TextStyle(fontSize: 18.0),
              onTap: () async {
                final Map<String, dynamic>? result =
                    await Navigator.push<Map<String, dynamic>>(
                      context,
                      MaterialPageRoute<Map<String, dynamic>>(
                        settings: const RouteSettings(),
                        builder: (BuildContext context) => FindHasherPage(
                          FindHasherPageType.addMember,
                          kennelId: kennelListAggregate.kennel.kennelId,
                        ),
                      ),
                    );
                if (result == null) return;
                final hasher = result['hasher'];
                final String? hasherId = hasher?.hasherId as String?;
                if (hasherId == null) return;
                await c.addMember(hasherId);
              },
            ),
            SpeedDialChild(
              child: const Icon(Icons.person_add),
              backgroundColor: Colors.green,
              label: 'Add new Hasher\r\nto Harrier Central',
              labelStyle: const TextStyle(fontSize: 18.0),
              onTap: () async {
                final result = await Navigator.push<HashersModel>(
                  context,
                  MaterialPageRoute<HashersModel>(
                    builder: (BuildContext context) => HasherProfilePage(
                      dataContext: EnumDataContext.kennel,
                      pageType: EnumMyProfilePageType.newHasherProfile,
                      kennelId: kennelListAggregate.kennel.kennelId,
                      uiElementsToDisplay:
                          HasherProfilePage.flagUiElement_followKennel,
                      kennelShortName:
                          kennelListAggregate.kennel.kennelShortName,
                    ),
                  ),
                );
                if (result == null) return;
                await c.refreshAll();
              },
            ),
          ],
        ),
        body: Stack(
          fit: StackFit.loose,
          alignment: AlignmentDirectional.topStart,
          children: <Widget>[
            SizedBox(height: MediaQuery.sizeOf(context).height, width: 10),
            PositionedTransition(
              rect: c.hasherListAnimation,
              child: SizedBox(
                key: c.packListBoxKey,
                height: 300,
                child: Obx(
                  () => c.isLoading.value
                      ? const HcAppCircularProgressIndicator(
                          key: Key('75223930'),
                        )
                      : _memberList(context, c),
                ),
              ),
            ),
            SlideTransition(
              position: c.filterPanelAnimation,
              child: _filterBar(context, c),
            ),
            Positioned(top: 0, child: _searchBar(context, c)),
          ],
        ),
      ),
    );
  }

  Widget _memberList(BuildContext context, KennelMembersController c) {
    // Snapshot inside the caller's Obx so itemCount and itemBuilder agree.
    final List<dynamic> members = c.filteredMembers;
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 0.0),
            child: members.isEmpty
                ? Center(child: Text('No members found.', style: ts_regular))
                : RefreshIndicator(
                    onRefresh: c.pullToRefresh,
                    displacement: 40.0,
                    child: ListView.separated(
                      separatorBuilder: (BuildContext context, int index) =>
                          const Divider(height: 1.0, color: Colors.black45),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: members.length + 1,
                      itemBuilder: (BuildContext context, int index) {
                        if (index == members.length) {
                          return const SizedBox(height: 100.0);
                        } else {
                          if (members[index] is int) {
                            String memberType = '';
                            if (members[index] == 1) {
                              memberType = 'Kennel Members';
                            } else if (members[index] == 2) {
                              memberType = 'Recent runs with this Kennel';
                            } else if (members[index] == 3) {
                              memberType = 'Has runs with this Kennel';
                            } else if (members[index] == 4) {
                              memberType = 'Follows this Kennel';
                            } else {
                              memberType = 'Others';
                            }

                            return Container(
                              padding: const EdgeInsets.only(top: 7.0),
                              height: 40.0,
                              color: themeBackgroundColor,
                              child: Text(
                                memberType,
                                style: ts_titleLarge,
                                textAlign: TextAlign.center,
                              ),
                            );
                          } else {
                            final KennelMemberResultsModel item =
                                members[index];
                            return Dismissible(
                              key: Key(item.hasherId),
                              confirmDismiss: (DismissDirection direction) async {
                                // swipe from right to left to indicate that
                                // the hasher either attended the run as a pack
                                // member or as a hare
                                final int monthsToAdd =
                                    direction == DismissDirection.endToStart
                                    ? item.membershipDurationInMonths
                                    : -9999;

                                await c.modifyMembership(index, monthsToAdd);

                                return false;
                              },
                              background: Container(
                                color: hc_red,
                                child: Row(
                                  children: <Widget>[
                                    const Padding(
                                      padding: EdgeInsets.only(left: 10.0),
                                      child: Icon(
                                        FontAwesome.times_circle,
                                        color: Colors.white,
                                        size: 35.0,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: 15.0,
                                      ),
                                      child: Text(
                                        // '${IveCoreUtilities.getFormattedMoney(filteredList[index].debitAmount, widget.digitsAfterDecimal, widget.currencySymbol)} Bank Transfer',
                                        'Cancel\r\nmembership',
                                        maxLines: 2,
                                        style: ts_titleMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              secondaryBackground: Container(
                                color: Colors.green,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: <Widget>[
                                    const Padding(
                                      padding: EdgeInsets.only(right: 15.0),
                                      child: Icon(
                                        FontAwesome.plus_circle,
                                        color: Colors.white,
                                        size: 35.0,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        right: 15.0,
                                      ),
                                      child: Text(
                                        //'${IveCoreUtilities.getFormattedMoney(filteredList[index].debitAmount, widget.digitsAfterDecimal, widget.currencySymbol)} Cash',
                                        'Add ${item.membershipDurationInMonths} months\r\nto membership',
                                        style: ts_titleMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              onDismissed: (DismissDirection direction) {
                                //print(direction.toString() + ' NOTE: We should never reach this point');
                              },
                              child: KennelMemberListItem(
                                kennelListAggregate: kennelListAggregate,
                                kennelMember: members[index],
                                refreshRunCountsCallback:
                                    (
                                      bool refreshThisUserData,
                                      String dispName,
                                      String photo,
                                    ) => c.afterProfileEdit(
                                      index,
                                      refreshThisUserData: refreshThisUserData,
                                      dispName: dispName,
                                      photo: photo,
                                    ),
                                modifyMembershipCallback:
                                    (EnumMemberPopupActions? retVal) async {
                                      if (retVal == null) return;

                                      switch (retVal) {
                                        case EnumMemberPopupActions
                                            .cancelDialog:
                                          break;
                                        case EnumMemberPopupActions
                                            .chargeMembership:
                                          final KennelMemberResultsModel m =
                                              members[index];
                                          await showMembershipChargeSheet(
                                            context: context,
                                            kennelId: kennelListAggregate
                                                .kennel
                                                .kennelId,
                                            userId: m.hasherId,
                                            displayName: m.dispName,
                                            appDomainType: AppDomainType.kennel,
                                            onCharged: c.afterMembershipCharged,
                                          );
                                          break;
                                        case EnumMemberPopupActions.addOneMonth:
                                          await c.modifyMembership(index, 1);
                                          break;
                                        case EnumMemberPopupActions
                                            .addSixMonths:
                                          await c.modifyMembership(index, 6);
                                          break;
                                        case EnumMemberPopupActions.addOneYear:
                                          await c.modifyMembership(index, 12);
                                          break;
                                        case EnumMemberPopupActions
                                            .permanentMembership:
                                          await c.modifyMembership(index, 9999);
                                          break;
                                        case EnumMemberPopupActions
                                            .cancelMembership:
                                          await c.modifyMembership(
                                            index,
                                            -9999,
                                          );
                                          break;
                                        case EnumMemberPopupActions
                                            .hideSharedNotes:
                                          await c.setUserProperties(
                                            index,
                                            kennelStandingSet:
                                                KENNEL_STANDING_NOTES_SUPPRESSED,
                                          );
                                          break;
                                        case EnumMemberPopupActions
                                            .allowSharedNotes:
                                          await c.setUserProperties(
                                            index,
                                            kennelStandingClear:
                                                KENNEL_STANDING_NOTES_SUPPRESSED,
                                          );
                                          break;
                                        case EnumMemberPopupActions.grantAlumni:
                                          // ALUMNI bit 0x0002 (manual grant)
                                          await c.setUserProperties(
                                            index,
                                            kennelStandingSet: 0x0002,
                                          );
                                          break;
                                        case EnumMemberPopupActions
                                            .revokeAlumni:
                                          await c.setUserProperties(
                                            index,
                                            kennelStandingClear: 0x0002,
                                          );
                                          break;
                                        case EnumMemberPopupActions
                                            .editKennelAdmin:
                                          final int? appAccessResult =
                                              await Navigator.push<int>(
                                                context,
                                                MaterialPageRoute<int>(
                                                  builder:
                                                      (
                                                        BuildContext context,
                                                      ) => AppAccessPage(
                                                        appAccess:
                                                            members[index]
                                                                .appAccessFlags,
                                                      ),
                                                ),
                                              );

                                          if (appAccessResult != null) {
                                            await c.setUserProperties(
                                              index,
                                              appAccessFlags: appAccessResult,
                                            );
                                          }
                                          break;
                                        case EnumMemberPopupActions
                                            .editMismanagementRole:
                                          final int? mismanagementResult =
                                              await Navigator.push<int>(
                                                context,
                                                MaterialPageRoute<int>(
                                                  builder:
                                                      (
                                                        BuildContext context,
                                                      ) => MismanagementRolesPage(
                                                        mismanagementRoles:
                                                            members[index]
                                                                .mismanagementRoles,
                                                      ),
                                                ),
                                              );

                                          if (mismanagementResult != null) {
                                            await c.setUserProperties(
                                              index,
                                              mismanagementRoles:
                                                  mismanagementResult,
                                            );
                                          }
                                          break;
                                      }
                                    },
                                toggleEmailPreferenceCallback: () =>
                                    c.toggleEmailPreference(index),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _searchBar(BuildContext context, KennelMembersController c) {
    return Container(
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
      height: 85,
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              RotationTransition(
                turns: c.buttonAnimation,
                child: IconButton(
                  padding: const EdgeInsets.all(0),
                  onPressed: () => unawaited(c.toggleFilterPanel()),
                  icon: Obx(
                    () => Icon(
                      FontAwesome5Solid.arrow_alt_circle_right,
                      size: 35,
                      color: c.showFilter.value ? Colors.green : Colors.grey,
                    ),
                  ),
                ),
              ),
              Container(
                height: 60,
                margin: const EdgeInsets.only(left: 3, right: 10),
                decoration: const BoxDecoration(
                  border: Border(
                    left: BorderSide(color: Colors.black, width: 1.0),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  children: <Widget>[
                    TextField(
                      autocorrect: false,
                      onChanged: c.setSearchText,
                      focusNode: c.searchFocusNode,
                      controller: c.searchController,
                      keyboardType: TextInputType.text,
                      style: ts_titleMediumBlack,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        icon: const Icon(
                          FontAwesome.search,
                          color: Colors.black,
                        ),
                        hintText: 'Enter Hash or mortal name',
                        hintStyle: ts_hint,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 40,
                child: TextButton(
                  style: text_button_style.copyWith(
                    textStyle: WidgetStatePropertyAll(
                      TextStyle(color: Colors.grey.shade700),
                    ),
                    backgroundColor: const WidgetStatePropertyAll(Colors.white),
                  ),
                  onPressed: c.clearSearch,
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
        ],
      ),
    );
  }

  Widget _filterBar(BuildContext context, KennelMembersController c) {
    return Obx(
      () => Container(
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
            KennelFilterCell(
              counter: c.countIsMember.value,
              label: 'Member',
              index: 0,
              onTap: c.refreshAll,
              filterValues: c.filterValues,
            ),
            KennelFilterCell(
              counter: c.countIsFollowing.value,
              label: 'Follow',
              index: 1,
              onTap: c.refreshAll,
              filterValues: c.filterValues,
            ),
            // KennelFilterCell(
            //   counter: countIsHomeKennel,
            //   label: 'Home',
            //   index: 2,
            //   useTriState: true,
            //   },
            //   filterValues: filterValues,
            // ),
            KennelFilterCell(
              counter: c.countHasRecentRuns.value,
              label: 'Have runs',
              index: 3,
              useTriState: true,
              onTap: c.refreshAll,
              filterValues: c.filterValues,
            ),
            // KennelFilterCell(
            //   counter: countAtHash,
            //   index: 2,
            //   label: 'At Hash',
            //   },
            //   filterValues: filterValues,
            //   counter: countPaid,
            //   index: 3,
            //   label: 'Paid',
            //   },
            //   counter: countOnIn,
            //   index: 4,
            //   label: 'On In',
            //   },
            //   filterValues: filterValues,
            // ),
          ],
        ),
      ),
    );
  }
}
