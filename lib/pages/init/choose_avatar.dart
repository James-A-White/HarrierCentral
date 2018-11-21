import 'dart:math';
import 'dart:ui';

import 'package:flutter/cupertino.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:harrier_central/main.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:harrier_central/remote_api_data/add_user_service.dart';
import 'package:harrier_central/data_models/add_user_model.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/routes.dart';

//import 'package:the_gorgeous_login/style/theme.dart' as Theme;

class ChooseAvatarPage extends StatefulWidget {
  const ChooseAvatarPage({Key key}) : super(key: key);

  @override
  _ChooseAvatarState createState() => _ChooseAvatarState();
}

class _ChooseAvatarState extends State<ChooseAvatarPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int selectedValue = 0;
  num thumbnailSize = 85.0;
  num previewAvatarSize = 120.0;

  String avatarIconName = 'Avatar-1.png';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: NotificationListener<OverscrollIndicatorNotification>(
        onNotification: (OverscrollIndicatorNotification overscroll) {
          overscroll.disallowGlow();
        },
        child: SingleChildScrollView(
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height >= 500.0
                ? MediaQuery.of(context).size.height
                : 500.0,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: <Color>[
                    LoginColors.loginGradientStart,
                    LoginColors.loginGradientEnd
                  ],
                  begin: const FractionalOffset(0.0, 0.0),
                  end: const FractionalOffset(1.0, 1.0),
                  stops: const <double>[0.0, 1.0],
                  tileMode: TileMode.clamp),
            ),
            child: Padding(
              padding: EdgeInsets.only(top: 40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(top: 0.0),
                    child: Text(
                      'Choose Avatar',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32.0,
                          fontFamily: 'WorkSansSemiBold'),
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: <Widget>[
                        Column(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Radio<int>(
                                  value: 0,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.padded,
                                  groupValue: selectedValue,
                                  onChanged: _handleRadioValueChange1,
                                ),
                                Image.asset(
                                  'images/icons/avatar_icon.png',
                                  width: thumbnailSize,
                                  height: thumbnailSize,
                                ),
                              ],
                            ),
                            Row(
                              children: <Widget>[
                                Radio<int>(
                                  value: 1,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.padded,
                                  groupValue: selectedValue,
                                  onChanged: _handleRadioValueChange1,
                                ),
                                Image.asset(
                                  'images/icons/avatar_ios_camera.png',
                                  width: thumbnailSize,
                                  height: thumbnailSize,
                                ),
                              ],
                            ),
                            Row(
                              children: <Widget>[
                                Radio<int>(
                                  value: 2,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.padded,
                                  groupValue: selectedValue,
                                  onChanged: _handleRadioValueChange1,
                                ),
                                Image.asset(
                                  'images/icons/avatar_ios_camera_roll.png',
                                  width: thumbnailSize,
                                  height: thumbnailSize,
                                ),
                              ],
                            ),
                            Row(
                              children: <Widget>[
                                Radio<int>(
                                  value: 3,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.padded,
                                  groupValue: selectedValue,
                                  onChanged: _handleRadioValueChange1,
                                ),
                                Image.asset(
                                  'images/icons/avatar_facebook_profile_pic.png',
                                  width: thumbnailSize,
                                  height: thumbnailSize,
                                ),
                              ],
                            ),
                          ],
                        ),
                        Expanded(
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[_getPreviewAvatar()]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _getPreviewAvatar() {
    Widget returnWidget;

    switch (selectedValue) {
      case 0:
        returnWidget = Image.asset(
                                  'images/avatars/$avatarIconName',width: previewAvatarSize, height: previewAvatarSize,);
        break;
      default:
        returnWidget =
            Container(color: Colors.green, height: previewAvatarSize, width: previewAvatarSize);
    }
    return returnWidget;
  }

  void _handleRadioValueChange1(int value) {
    setState(() {
      selectedValue = value;
      switch (selectedValue) {
        case 0:
          Navigator.of(context)
              .pushNamed<dynamic>(RouteNames.AVATAR_ICON_PAGE.toString())
              .then((dynamic onValue) {
            avatarIconName = 'avatar-$onValue.png';
          });
          break;
        case 1:
          break;
        case 2:
          break;
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }
}
