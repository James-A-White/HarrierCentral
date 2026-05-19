import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ProfilePhoto extends StatelessWidget {
  const ProfilePhoto({
    super.key,
    this.profilePhotoUrl,
    this.photoHeight = 75.0,
    this.leftPadding = 0,
  });

  final String? profilePhotoUrl;
  final double photoHeight;
  final double leftPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: photoHeight,
      height: photoHeight,
      margin: EdgeInsets.only(left: leftPadding),
      alignment: Alignment.centerRight,
      child: profilePhotoUrl == null || profilePhotoUrl!.isEmpty
          ? Image.asset('images/icons/create_profile_photo.png')
          : profilePhotoUrl!.contains('bundle://')
          ? Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Image.asset(
                  ('images/avatars/${profilePhotoUrl!.replaceAll('bundle://', '')}.jpg')
                      .toLowerCase(),
                ),
              ],
            )
          : CachedNetworkImage(
              imageUrl: profilePhotoUrl!,
              //errorWidget: (BuildContext context,String url,Exception error) => const  Icon(Icons.error),
              //errorWidget:  const  Icon(Icons.error),
              fadeInDuration: const Duration(milliseconds: 0),
              fit: BoxFit.fitHeight,
              height: photoHeight,
            ),
    );
  }
}
