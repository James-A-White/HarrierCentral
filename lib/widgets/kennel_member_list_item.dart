import 'package:harrier_central/imports.dart';
import 'package:intl/intl.dart';

enum EnumMemberPopupActions { addOneMonth, addSixMonths, subtractOneMonth, subtractSixMonths, cancelMembership, toggleHomeKennel, setHomeKennel, clearHomeKennel }

class KennelMemberListItem extends StatelessWidget {
  const KennelMemberListItem({@required this.kennelId, @required this.kennelMember, @required this.modifyMembershipCallback, @required this.toggleEmailPreferenceCallback});

  final String kennelId;
  final KennelMembersResults kennelMember;
  final Function modifyMembershipCallback;
  final Function toggleEmailPreferenceCallback;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context)
            .push<HashersModel>(
          MaterialPageRoute<HashersModel>(
            //maintainState: false,
            builder: (BuildContext context) => HasherProfilePage(
              dataContext: EnumDataContext.kennel,
              pageType: EnumMyProfilePageType.anyHasherProfile,
              hasherId: kennelMember.hasherId,
              uiElementsToDisplay: HasherProfilePage.flagUiElement_inviteCode,
              kennelShortName: kennelMember.kennelShortName,
              kennelId: kennelMember.kennelId,
            ),
          ),
        )
            .then((HashersModel result) {
          if (result != null) {
            kennelMember.dispName = result.dispName;
            kennelMember.photo = result.photo;
          }
        });
      },
      child: Container(
        child: IntrinsicWidth(
          stepWidth: MediaQuery.of(context).size.width,
          child: Row(
            //crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(left: 0.0, right: 5.0),
                child: kennelMember.photo.startsWith('http')
                    ? CachedNetworkImage(
                        imageUrl: kennelMember.photo,
                        //placeholder: const HcCircularProgressIndicator(),
                        //errorWidget: const  Icon(Icons.error),
                        // placeholder: (BuildContext context,String url) => const HcCircularProgressIndicator(),

                        // TODO(James): Replace avatar icon with missing image icon
                        errorWidget: (BuildContext context, String url, Object error) => Image.asset('images/avatars/avatar-2.jpg', height: 80, width: 80, fit: BoxFit.fill),
                        //fadeOutDuration:  Duration(seconds: 1),
                        fadeInDuration: const Duration(milliseconds: 0),
                        width: PROFILE_PIC_SIZE,
                        height: PROFILE_PIC_SIZE,
                        fit: BoxFit.fill)
                    : kennelMember.photo.startsWith('bundle')
                        ? Image(
                            width: PROFILE_PIC_SIZE,
                            height: PROFILE_PIC_SIZE,
                            fit: BoxFit.fill,
                            image: AssetImage(('images/avatars/' + kennelMember.photo.toLowerCase().replaceFirst('bundle://', '') + '.jpg').toLowerCase()),
                          )
                        : const Image(
                            width: PROFILE_PIC_SIZE,
                            height: PROFILE_PIC_SIZE,
                            fit: BoxFit.fill,
                            image: AssetImage('images/avatars/avatar-2.jpg'),
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
                            child: Text(
                              '${kennelMember.dispName}',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontFamily: (kennelMember?.membershipExpirationDate ?? DateTime.parse('19900101')).isAfter(DateTime.now())
                                      ? 'AvenirNextCondensedDemiBold'
                                      : 'AvenirNextCondensed',
                                  fontStyle: FontStyle.normal,
                                  fontSize: 22.0,
                                  height: 1.0),
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ],
                      ),
                      kennelMember.homeKennelBeingUpdated ?? false
                          ? const Text(
                              '<Updating home kennel>',
                              style: TextStyle(fontFamily: 'AvenirNextMedium', fontStyle: FontStyle.normal, fontSize: 15.0, height: 1.0, color: Colors.blue),
                              textAlign: TextAlign.center,
                            )
                          : Text(
                              '${kennelMember.homeKennelName ?? '<no home hash>'}',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontFamily: 'AvenirNextMedium', fontStyle: FontStyle.normal, fontSize: 13.0 * G0<DeviceInfo>().deviceWidthScaleFactor, height: 1.0),
                              textAlign: TextAlign.left,
                            ),
                      kennelMember.dateOfLastRun == null
                          ? Container()
                          : Text(
                              'Last run: ${DateFormat('MMM dd, yyyy').format(kennelMember.dateOfLastRun)}',
                              style: TextStyle(fontFamily: 'AvenirNextMedium', fontStyle: FontStyle.normal, fontSize: 13.0 * G0<DeviceInfo>().deviceWidthScaleFactor, height: 1.0),
                              textAlign: TextAlign.center,
                            ),
                      kennelMember.membershipDateBeingUpdated ?? false
                          ? Text(
                              '<Updating membership>',
                              style: TextStyle(
                                  fontFamily: 'AvenirNextMedium',
                                  fontStyle: FontStyle.normal,
                                  fontSize: 13.0 * G0<DeviceInfo>().deviceWidthScaleFactor,
                                  height: 1.0,
                                  color: Colors.blue),
                              textAlign: TextAlign.center,
                            )
                          : kennelMember.membershipExpirationDate == null
                              ? kennelMember.following != 1
                                  ? Container()
                                  : Text(
                                      '(following this Kennel)',
                                      style: TextStyle(
                                          fontFamily: 'AvenirNextMedium', fontStyle: FontStyle.normal, fontSize: 13.0 * G0<DeviceInfo>().deviceWidthScaleFactor, height: 1.0),
                                      textAlign: TextAlign.center,
                                    )
                              : Text(
                                  'Valid until: ${DateFormat('MMM dd, yyyy').format(kennelMember.membershipExpirationDate)}',
                                  style:
                                      TextStyle(fontFamily: 'AvenirNextMedium', fontStyle: FontStyle.normal, fontSize: 13.0 * G0<DeviceInfo>().deviceWidthScaleFactor, height: 1.0),
                                  textAlign: TextAlign.center,
                                ),
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
                            Container(
                              height: 30,
                              width: 30,
                              child: const Icon(MaterialCommunityIcons.numeric_1_circle, color: Colors.yellow),
                            ),
                          ],
                          'returnValue': EnumMemberPopupActions.addOneMonth,
                        },
                        <String, dynamic>{
                          'title': 'Add six months',
                          'icon': <Widget>[
                            Container(
                              height: 30,
                              width: 30,
                              child: const Icon(MaterialCommunityIcons.numeric_6_circle, color: Colors.yellow),
                            ),
                          ],
                          'returnValue': EnumMemberPopupActions.addSixMonths,
                        },
                        <String, dynamic>{
                          'title': 'Subtract one month',
                          'icon': <Widget>[
                            Container(
                              height: 30,
                              width: 30,
                              child: const Icon(MaterialCommunityIcons.numeric_1_circle_outline, color: Colors.yellow),
                            ),
                          ],
                          'returnValue': EnumMemberPopupActions.subtractOneMonth,
                        },
                        <String, dynamic>{
                          'title': 'Subtract six months',
                          'icon': <Widget>[
                            Container(
                              height: 30,
                              width: 30,
                              child: const Icon(MaterialCommunityIcons.numeric_6_circle_outline, color: Colors.yellow),
                            ),
                          ],
                          'returnValue': EnumMemberPopupActions.subtractSixMonths,
                        },
                        <String, dynamic>{
                          'title': 'Cancel membership',
                          'icon': <Widget>[
                            Container(
                              height: 30,
                              width: 30,
                              child: Icon(FontAwesome.times_circle, color: Colors.red[200]),
                            ),
                          ],
                          'returnValue': EnumMemberPopupActions.cancelMembership,
                        },
                        kennelMember.homeKennelName == null
                            ? <String, dynamic>{
                                'title': 'Set home kennel',
                                'icon': <Widget>[
                                  Container(height: 30, width: 30, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                                  const Icon(FontAwesome.home, color: Colors.white, size: 23)
                                ],
                                'returnValue': EnumMemberPopupActions.setHomeKennel,
                              }
                            : kennelId == kennelMember.homeKennelId
                                ? <String, dynamic>{
                                    'title': 'Clear home kennel',
                                    'icon': <Widget>[
                                      Container(height: 30, width: 30, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                                      const Icon(FontAwesome.home, color: Colors.white, size: 23)
                                    ],
                                    'returnValue': EnumMemberPopupActions.clearHomeKennel,
                                  }
                                : <String, dynamic>{
                                    'title': '', // NOTE: Because the title is empty, this button will not be displayed
                                    'icon': <Widget>[
                                      Container(
                                        height: 30,
                                        width: 30,
                                        child: Icon(FontAwesome.times_circle, color: Colors.red[200]),
                                      ),
                                    ],
                                    'returnValue': EnumMemberPopupActions.cancelMembership,
                                  },
                      ];

                      final MultipleChoicePopup popup = MultipleChoicePopup(
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
      ),
    );
  }
}
