import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';

import 'package:harrier_central/data/models/kennel_member_model.dart';
import 'package:harrier_central/pages/kennel_admin/user_secret_qr_page.dart';

class KennelMemberListItem extends StatelessWidget {
  const KennelMemberListItem({
    @required this.kennelMember,
  });

  final KennelMemberModel kennelMember;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push<dynamic>(
          context,
          MaterialPageRoute<dynamic>(
            builder: (BuildContext context) =>
                UserSecretQrPage(kennelMemberModel: kennelMember),
          ),
        );
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 8.0),
            child: kennelMember.photo.startsWith('http')
                ? CachedNetworkImage(
                    imageUrl: kennelMember.photo,
                    //placeholder: const HcCircularProgressIndicator(),
                    //errorWidget: const  Icon(Icons.error),
                    // placeholder: (BuildContext context,String url) => const HcCircularProgressIndicator(),

                    // TODO(James): Replace avatar icon with missing image icon
                    errorWidget: (BuildContext context,String url,Object error) => Image.asset('images/avatars/avatar-2.png', height:80, width:80, fit: BoxFit.fill),
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
                        image: AssetImage(('images/avatars/' +
                            kennelMember.photo
                                .toLowerCase()
                                .replaceFirst('bundle://', '') +
                            '.png').toLowerCase()),
                      )
                    : Image(
                        width: 80.0,
                        height: 80.0,
                        fit: BoxFit.fill,
                        image: const AssetImage('images/avatars/avatar-2.png'),
                      ),
          ),
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
        ],
      ),
    );
  }
}
