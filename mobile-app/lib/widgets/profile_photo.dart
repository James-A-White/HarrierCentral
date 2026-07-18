import 'package:flutter/material.dart';
import 'package:harrier_central/util/avatar.dart';

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
          : Image(
              image: avatarImageProvider(profilePhotoUrl),
              fit: BoxFit.fitHeight,
              height: photoHeight,
            ),
    );
  }
}
