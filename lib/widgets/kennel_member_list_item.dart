import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import 'package:harrier_central/pages/kennel_admin/kennel_members.dart';
import 'package:harrier_central/widgets/multiple_choice_popup.dart';

enum EnumMemberPopupActions { addOneMonth, addSixMonths, subtractOneMonth, subtractSixMonths, cancelMembership }

class KennelMemberListItem extends StatelessWidget {
  const KennelMemberListItem({
    @required this.kennelMember,
    @required this.modifyMembershipCallback
  });

  final KennelMembersResults kennelMember;
  final Function modifyMembershipCallback;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // Navigator.push<dynamic>(
        //   context,
        //   MaterialPageRoute<dynamic>(
        //     builder: (BuildContext context) =>
        //         UserSecretQrPage(kennelMemberModel: kennelMember),
        //   ),
        // );
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
                        errorWidget: (BuildContext context, String url, Object error) => Image.asset('images/avatars/avatar-2.png', height: 80, width: 80, fit: BoxFit.fill),
                        //fadeOutDuration:  Duration(seconds: 1),
                        fadeInDuration: const Duration(milliseconds: 0),
                        width: 80.0,
                        height: 80.0,
                        fit: BoxFit.fill)
                    : kennelMember.photo.startsWith('bundle')
                        ? Image(
                            width: 80.0,
                            height: 80.0,
                            fit: BoxFit.fill,
                            image: AssetImage(('images/avatars/' + kennelMember.photo.toLowerCase().replaceFirst('bundle://', '') + '.png').toLowerCase()),
                          )
                        : Image(
                            width: 80.0,
                            height: 80.0,
                            fit: BoxFit.fill,
                            image: const AssetImage('images/avatars/avatar-2.png'),
                          ),
              ),
              Container(
                  padding: const EdgeInsets.only(left: 10.0, bottom: 2.0),
                  width: MediaQuery.of(context).size.width - 135,
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '${kennelMember.dispName}',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontFamily: kennelMember.isMember == 1 ? 'AvenirNextCondensedDemiBold' : 'AvenirNextCondensed', fontStyle: FontStyle.normal, fontSize: 22.0, height: 1.0),
                        textAlign: TextAlign.left,
                      ),
                      kennelMember.dateOfLastRun == null
                          ? Container()
                          : Text(
                              'Last run: ${DateFormat('MMM dd, yyyy').format(kennelMember.dateOfLastRun)}',
                              style: const TextStyle(fontFamily: 'AvenirNextDemiBold', fontStyle: FontStyle.normal, fontSize: 15.0, height: 1.0),
                              textAlign: TextAlign.center,
                            ),
                      kennelMember.membershipDateBeingUpdated ?? false
                          ? const Text(
                              '<Update in progress>',
                              style: TextStyle(fontFamily: 'AvenirNextDemiBold', fontStyle: FontStyle.normal, fontSize: 15.0, height: 1.0, color: Colors.blue),
                              textAlign: TextAlign.center,
                            )
                          : kennelMember.membershipExpirationDate == null
                              ? kennelMember.following != 1
                                  ? Container()
                                  : const Text(
                                      '(following this Kennel)',
                                      style: TextStyle(fontFamily: 'AvenirNextMedium', fontStyle: FontStyle.normal, fontSize: 15.0, height: 1.0),
                                      textAlign: TextAlign.center,
                                    )
                              : Text(
                                  'Valid until: ${DateFormat('MMM dd, yyyy').format(kennelMember.membershipExpirationDate)}',
                                  style: const TextStyle(fontFamily: 'AvenirNextDemiBold', fontStyle: FontStyle.normal, fontSize: 15.0, height: 1.0),
                                  textAlign: TextAlign.center,
                                ),
                    ],
                  )),
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
                    ];

                    final MultipleChoicePopup popup = MultipleChoicePopup(
                        title: 'Membership options',
                        buttons: buttons,
                        cancelButtonTitle: 'Cancel',
                        buttonPress: (dynamic retVal) {
                          modifyMembershipCallback(retVal);
                        });

                    showDialog<void>(
                        context: context,
                        barrierDismissible: false, // user must tap button!
                        builder: (BuildContext context) {
                          return popup;
                        });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
