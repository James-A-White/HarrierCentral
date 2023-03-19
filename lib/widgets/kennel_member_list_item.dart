import 'package:harrier_central/imports_null_safe.dart';
import 'package:intl/intl.dart';

enum EnumMemberPopupActions {
  addOneMonth,
  addSixMonths,
  addOneYear,
  cancelMembership,
  permanentMembership,
  editKennelAdmin,
  editMismanagementRole,
}

class KennelMemberListItem extends StatelessWidget {
  const KennelMemberListItem({
    Key? key,
    required this.kennelListAggregate,
    required this.kennelMember,
    required this.modifyMembershipCallback,
    required this.toggleEmailPreferenceCallback,
    required this.refreshRunCountsCallback,
  }) : super(key: key);

  final KennelListAggregate kennelListAggregate;
  final KennelMemberResultsModel kennelMember;
  final Function modifyMembershipCallback;
  final Function toggleEmailPreferenceCallback;
  final Function refreshRunCountsCallback;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // NULLSAFETODO
        Navigator.of(context)
            .push<HashersModel>(
              MaterialPageRoute<HashersModel>(
                //maintainState: false,
                builder: (BuildContext context) => HasherProfilePage(
                  dataContext: EnumDataContext.kennel,
                  pageType: EnumMyProfilePageType.anyHasherProfile,
                  hasherId: kennelMember.hasherId,
                  uiElementsToDisplay: HasherProfilePage.flagUiElement_previousRunCount | HasherProfilePage.flagUiElement_getInviteCodeButton,
                  kennelShortName: kennelMember.kennelShortName ?? '',
                  kennelId: kennelMember.kennelId,
                ),
              ),
            )
            .then<dynamic>((HashersModel result) async {
              bool refreshThisUserData = false;

              kennelMember.dispName = result.dispName;
              kennelMember.photo = result.photo;

              kennelMember = kennelMember.copyWith();

              if (result.hasherId == getStringPref(StringPrefsEnum.userId)) {
                refreshThisUserData = true;
              }

              await refreshRunCountsCallback(refreshThisUserData);
            } as FutureOr Function(HashersModel? value));
      },
      child: IntrinsicWidth(
        stepWidth: MediaQuery.of(context).size.width,
        child: Row(
          //crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(left: 0.0, right: 5.0),
              child: kennelMember.photo == null
                  ? const Image(
                      width: PROFILE_PIC_SIZE,
                      height: PROFILE_PIC_SIZE,
                      fit: BoxFit.fill,
                      image: AssetImage('images/avatars/avatar-2.jpg'),
                    )
                  : GestureDetector(
                      onTap: () {
                        Navigator.push<void>(
                          context,
                          MaterialPageRoute<void>(
                            builder: (BuildContext context) => ZoomableImagePage2(
                                key: const Key('36601939'),
                                pageTitle: kennelMember.dispName,
                                imageUrl: (kennelMember.photo!.startsWith('http')) ? kennelMember.photo : null,
                                assetImage: kennelMember.photo!.contains('bundle://') ? 'images/avatars/${kennelMember.photo!.replaceAll('bundle://', '')}.jpg' : null,
                                appBarBackgroundColor: themeAppBarBackground,
                                background: Backgrounds.defaultHcBackground(),
                                margin: 20.0),
                          ),
                        );
                      },
                      child: kennelMember.photo!.startsWith('http')
                          ? CachedNetworkImage(
                              imageUrl: kennelMember.photo!,
                              //placeholder: HcCircularProgressIndicator(key: Key('yyyyyyy')),
                              //errorWidget: const  Icon(Icons.error),
                              // placeholder: (BuildContext context,String url) => HcCircularProgressIndicator(key: Key('yyyyyyy')),

                              // TODO(James): Replace avatar icon with missing image icon
                              errorWidget: (BuildContext context, String url, dynamic error) => Image.asset('images/avatars/avatar-2.jpg', height: 80, width: 80, fit: BoxFit.fill),
                              fadeInDuration: const Duration(milliseconds: 0),
                              width: PROFILE_PIC_SIZE,
                              height: PROFILE_PIC_SIZE,
                              fit: BoxFit.fill)
                          : kennelMember.photo!.startsWith('bundle')
                              ? Image(
                                  width: PROFILE_PIC_SIZE,
                                  height: PROFILE_PIC_SIZE,
                                  fit: BoxFit.fill,
                                  image: AssetImage(('images/avatars/${kennelMember.photo!.toLowerCase().replaceFirst('bundle://', '')}.jpg').toLowerCase()),
                                )
                              : const Image(
                                  width: PROFILE_PIC_SIZE,
                                  height: PROFILE_PIC_SIZE,
                                  fit: BoxFit.fill,
                                  image: AssetImage('images/avatars/avatar-2.jpg'),
                                ),
                    ),
            ),
            Container(
                padding: const EdgeInsets.only(left: 10.0, bottom: 2.0),
                width: MediaQuery.of(context).size.width - 145,
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Row(children: <Widget>[
                            Expanded(
                              child: AutoSizeText(
                                kennelMember.dispName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontFamily: (kennelMember.membershipExpirationDate ?? DateTime.parse('19900101')).isAfter(DateTime.now()) ? 'AvenirNextCondensedDemiBold' : 'AvenirNextCondensed',
                                    fontStyle: FontStyle.normal,
                                    fontSize: 22.0,
                                    height: 1.0),
                                textAlign: TextAlign.left,
                              ),
                            ),
                            const SizedBox(width: 10.0),
                            if (kennelMember.appAccess.isAdmin) ...<Widget>[
                              Padding(padding: const EdgeInsets.only(bottom: 5.0, left: 3.0), child: Icon(FontAwesome.gear, color: Colors.blue[800], size: 24.0))
                            ],
                            //if (kennelMember.appAccess.isAdmin && kennelMember.mismanagement.isOnMismanagement) ...<Widget>[const SizedBox(width: 10.0)],
                            if (kennelMember.mismanagement.isOnMismanagement) ...<Widget>[
                              Padding(padding: const EdgeInsets.only(bottom: 5.0, left: 3.0), child: Icon(MaterialCommunityIcons.account_tie, color: Colors.blue[800], size: 24.0))
                            ],
                          ]),
                        ),
                      ],
                    ),
                    // kennelMember.homeKennelBeingUpdated ?? false
                    //     ? const Text(
                    //         '<Updating home kennel>',
                    //         style: TextStyle(fontFamily: 'AvenirNextMedium', fontStyle: FontStyle.normal, fontSize: 15.0, height: 1.0, color: Colors.blue),
                    //         textAlign: TextAlign.center,
                    //       )
                    //     : Text(
                    //         '${kennelMember.homeKennelName ?? '<no home hash>'}',
                    //         overflow: TextOverflow.ellipsis,
                    //         style: TextStyle(fontFamily: 'AvenirNextMedium', fontStyle: FontStyle.normal, fontSize: 13.0 * G0<DeviceInfo>().deviceWidthScaleFactor, height: 1.0),
                    //         textAlign: TextAlign.left,
                    //       ),
                    if (kennelMember.dateOfLastRun != null) ...<Widget>[
                      Text(
                        'Last run: ${DateFormat('MMM dd, yyyy').format(kennelMember.dateOfLastRun!)}',
                        style: TextStyle(fontFamily: 'AvenirNextMedium', fontStyle: FontStyle.normal, fontSize: 13.0 * G0<DeviceInfo>().deviceWidthScaleFactor, height: 1.0),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    (((kennelMember.hcHaringCount ?? 0) == 0) &&
                            ((kennelMember.hcTotalRunCount ?? 0) == 0) &&
                            ((kennelMember.historicalHaringCount ?? 0) == 0) &&
                            ((kennelMember.historicalTotalRunCount ?? 0) == 0))
                        ? Container()
                        : Text(
                            'Runs: ${(kennelMember.hcTotalRunCount ?? 0) + (kennelMember.historicalTotalRunCount ?? 0)}, Haring: ${(kennelMember.hcHaringCount ?? 0) + (kennelMember.historicalHaringCount ?? 0)}',
                            style: TextStyle(fontFamily: 'AvenirNextMedium', fontStyle: FontStyle.normal, fontSize: 13.0 * G0<DeviceInfo>().deviceWidthScaleFactor, height: 1.0),
                            textAlign: TextAlign.center,
                          ),
                    kennelMember.memberInfoBeingUpdated ?? false
                        ? Text(
                            '<Updating membership>',
                            style: TextStyle(fontFamily: 'AvenirNextMedium', fontStyle: FontStyle.normal, fontSize: 13.0 * G0<DeviceInfo>().deviceWidthScaleFactor, height: 1.0, color: Colors.blue),
                            textAlign: TextAlign.center,
                          )
                        : kennelMember.membershipExpirationDate == null
                            ? kennelMember.following != 1
                                ? Container()
                                : Text(
                                    '(following this Kennel)',
                                    style: TextStyle(fontFamily: 'AvenirNextMedium', fontStyle: FontStyle.normal, fontSize: 13.0 * G0<DeviceInfo>().deviceWidthScaleFactor, height: 1.0),
                                    textAlign: TextAlign.center,
                                  )
                            : Text(
                                kennelMember.membershipExpirationDate!.year >= 2100 ? 'Permanent Member' : 'Valid until: ${DateFormat('MMM dd, yyyy').format(kennelMember.membershipExpirationDate!)}',
                                style: TextStyle(fontFamily: 'AvenirNextMedium', fontStyle: FontStyle.normal, fontSize: 13.0 * G0<DeviceInfo>().deviceWidthScaleFactor, height: 1.0),
                                textAlign: TextAlign.center,
                              ),
                    if ((kennelMember.kennelCredit ?? 0) != 0) ...<Widget>[
                      Text(
                        (kennelMember.kennelCredit! >= 0 ? 'Credit available: ' : 'Funds owed: ') +
                            IveCoreUtilities.getFormattedMoney(
                                kennelMember.kennelCredit!.abs(), kennelListAggregate.kennel.digitsAfterDecimal ?? 2, kennelListAggregate.kennel.currencySymbol ?? r'$^'),
                        style: TextStyle(
                            fontFamily: 'AvenirNextDemiBold',
                            fontStyle: FontStyle.normal,
                            fontSize: 16.0,
                            height: 1.0,
                            color: kennelMember.kennelCredit! >= 0 ? Colors.green.shade900 : Colors.red.shade900),
                      ),
                    ]
                  ],
                )),
            Column(children: <Widget>[
              Container(
                padding: const EdgeInsets.only(right: 0),
                child: GestureDetector(
                  onTap: () {
                    toggleEmailPreferenceCallback();
                  },
                  child: kennelMember.kennelEmailAlertPreference == -1
                      ? Icon(delayIcon, color: Colors.blue[800], size: 24.0)
                      : Image(
                          width: 24.0,
                          height: 24.0,
                          fit: BoxFit.fill,
                          image: kennelMember.kennelEmailAlertPreference == 1
                              ? const AssetImage('images/icons/envelope_gold_50px.png')
                              : kennelMember.kennelEmailAlertPreference == 2
                                  ? const AssetImage('images/icons/envelope_silver_strike_out_50px.png')
                                  : const AssetImage('images/icons/envelope_silver_strike_out_50px.png'),
                        ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(MaterialCommunityIcons.dots_vertical),
                  iconSize: Theme.of(context).iconTheme.size,
                  color: Colors.black54,
                  splashColor: Theme.of(context).highlightColor,
                  onPressed: () {
                    //

                    final List<Map<String, dynamic>> buttons = <Map<String, dynamic>>[
                      <String, dynamic>{
                        'title': 'Add one month',
                        'icon': <Widget>[
                          const SizedBox(
                            height: 30,
                            width: 30,
                            child: Icon(MaterialCommunityIcons.numeric_1_circle, color: Colors.yellow),
                          ),
                        ],
                        'returnValue': EnumMemberPopupActions.addOneMonth,
                      },
                      <String, dynamic>{
                        'title': 'Add six months',
                        'icon': <Widget>[
                          const SizedBox(
                            height: 30,
                            width: 30,
                            child: Icon(MaterialCommunityIcons.numeric_6_circle, color: Colors.yellow),
                          ),
                        ],
                        'returnValue': EnumMemberPopupActions.addSixMonths,
                      },
                      <String, dynamic>{
                        'title': 'Add one year',
                        'icon': <Widget>[
                          const SizedBox(
                            height: 30,
                            width: 30,
                            child: Icon(MaterialCommunityIcons.numeric_1_box, color: Colors.yellow),
                          ),
                        ],
                        'returnValue': EnumMemberPopupActions.addOneYear,
                      },
                      <String, dynamic>{
                        'title': 'Permanent membership',
                        'icon': <Widget>[
                          SizedBox(
                            height: 30,
                            width: 30,
                            child: Icon(FontAwesome.check_square, color: Colors.green.shade300),
                          ),
                        ],
                        'returnValue': EnumMemberPopupActions.permanentMembership,
                      },
                      <String, dynamic>{
                        'title': 'Cancel membership',
                        'icon': <Widget>[
                          SizedBox(
                            height: 30,
                            width: 30,
                            child: Icon(FontAwesome.times_circle, color: Colors.red.shade200),
                          ),
                        ],
                        'returnValue': EnumMemberPopupActions.cancelMembership,
                      },
                    ];

                    // if the current user of this device is a superAdmin
                    // give them the ability to set and clear admin flags for other
                    // users
                    if (kennelListAggregate.hkm.appAccess.isSuperAdmin) {
                      buttons.add(
                        <String, dynamic>{
                          'title': 'Edit HC admin roles',
                          'icon': <Widget>[
                            const SizedBox(
                              height: 30,
                              width: 30,
                              child: Icon(FontAwesome.gear, color: Colors.white),
                            ),
                          ],
                          'returnValue': EnumMemberPopupActions.editKennelAdmin,
                        },
                      );

                      buttons.add(
                        <String, dynamic>{
                          'title': 'Edit mismanagement roles',
                          'icon': <Widget>[
                            SizedBox(
                              height: 30,
                              width: 30,
                              child: Icon(MaterialCommunityIcons.account_tie, color: Colors.blue.shade200),
                            ),
                          ],
                          'returnValue': EnumMemberPopupActions.editMismanagementRole,
                        },
                      );
                    }

                    final MultipleChoicePopup popup = MultipleChoicePopup(
                      key: const Key('69691039'),
                      title: 'Membership options',
                      buttons: buttons,
                      cancelButtonTitle: 'Cancel',
                      cancelButtonReturnValue: followTypeCancel,
                    );

                    showDialog<dynamic>(
                        context: context,
                        barrierDismissible: false, // user must tap button!
                        builder: (BuildContext context) {
                          return popup;
                        }).then((dynamic retVal) {
                      modifyMembershipCallback(retVal);
                    });
                  },
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
