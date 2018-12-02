import 'package:flutter/material.dart';

import 'package:harrier_central/data_models/kennel_member_model.dart';
import 'package:cached_network_image/cached_network_image.dart';


class KennelMemberListItem extends StatelessWidget {
  final GetKennelMembersModel kennelMember;

  const KennelMemberListItem({
    @required this.kennelMember,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      stepWidth: MediaQuery.of(context).size.width,
      child: Stack(
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(left: 10.0, bottom: 2.0),
                child: Text(
                  '${kennelMember.displayName}',
                  style: const TextStyle(
                      fontFamily: 'AvenirNextCondensedDemiBold',
                      fontStyle: FontStyle.normal,
                      fontSize: 22.0,
                      height: 1.0),
                  textAlign: TextAlign.center,
                ),
              ),
              InkWell(
                  // onTap: () {
                  //   Navigator.of(context).push<dynamic>(
                  //     MaterialPageRoute<dynamic>(
                  //       builder: (context) {
                  //         return KennelDetailPage(kennel: kennel);
                  //       },
                  //     ),
                  //   );
                  // },
                  child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: kennelMember.photo.startsWith('http')
                                  ? CachedNetworkImage(
                                      imageUrl: kennelMember.photo,
                                      placeholder:
                                          const CircularProgressIndicator(),
                                      errorWidget: const Icon(Icons.error),
                                      //fadeOutDuration:  Duration(seconds: 1),
                                      fadeInDuration: Duration(milliseconds: 0),
                                      width: 80.0,
                                      height: 80.0,
                                      fit: BoxFit.fill)
                                  : kennelMember.photo.startsWith('bundle')
                                      ? Image(
                                          width: 80.0,
                                          height: 80.0,
                                          fit: BoxFit.fill,
                                          image: AssetImage('images/avatars/' +
                                              kennelMember
                                                  .photo
                                                  .toLowerCase()
                                                  .replaceFirst(
                                                      'bundle://', '') +
                                              '.png'),
                                        )
                                      : Image(
                                          width: 80.0,
                                          height: 80.0,
                                          fit: BoxFit.fill,
                                          image: AssetImage(
                                              'images/avatars/avatar-2.png'),
                                        ),
                  ),
                  // Column(
                  //     mainAxisSize: MainAxisSize.max,
                  //     children: <Widget>[
                  //       // Text(
                  //       //   '${kennel.kennelName}',
                  //       //   style:
                  //       //       TextStyle(fontSize: 22.0, fontWeight: FontWeight.w400),
                  //       //   textAlign: TextAlign.left,
                  //       // ),
                  //       Container(width: 10.0, height: 10.0),
                  //       Text(
                  //         '${kennelMember.locationName}',
                  //         style: const TextStyle(
                  //             fontFamily: 'AvenirNextRegular',
                  //             fontStyle: FontStyle.normal,
                  //             fontSize: 16.0,
                  //             height: 1.0),
                  //       ),
                  //       Text(
                  //         '${Utilities.getDistance(kennelMember.distance, context)}',
                  //         style: const TextStyle(
                  //             fontFamily: 'AvenirNextRegular',
                  //             fontStyle: FontStyle.normal,
                  //             fontSize: 16.0,
                  //             height: 1.0),
                  //       ),
                  //       // const Text(
                  //       //   'xxxx Active Members',
                  //       //                             style: TextStyle(
                  //       //             fontFamily: 'AvenirNextRegular',
                  //       //             fontStyle: FontStyle.normal,
                  //       //             fontSize: 16.0,
                  //       //             height: 1.0),
                  //       // ),
                  //       Text(
                  //         DateFormat("E, MMM d 'at' h:mm a")
                  //             .format(kennelMember.dateNextRun),
                  //         style: TextStyle(
                  //             fontFamily: 'AvenirNextRegular',
                  //             fontStyle: FontStyle.normal,
                  //             fontSize: 16.0,
                  //             height: 1.0),
                  //       ),
                  //     ],
                  //     crossAxisAlignment: CrossAxisAlignment.start)
                
                ],
              )),
              
              const Divider(
                color: Colors.black,
                height: 18.0,
              ),
            ],
          ),
          // Align(
          //   alignment: Alignment.centerRight,
          //   child: IconButton(
          //     icon: const Icon(Icons.settings),
          //     iconSize: Theme.of(context).iconTheme.size,
          //     color: Colors.black54,
          //     splashColor: Theme.of(context).highlightColor,
          //     onPressed: () {
          //       Navigator.push<dynamic>(
          //         context,
          //         MaterialPageRoute<dynamic>(
          //           builder: (context) => KennelAdminMainPage(kennel: kennelMember),
          //         ),
          //       );
          //     },
          //   ),
          // ),
       
        ],
      ),
    );
  }
}
