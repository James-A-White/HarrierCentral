import 'dart:ui';
import 'dart:async';
import 'dart:io';

import 'package:image_picker/image_picker.dart';

import 'package:flutter/cupertino.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:harrier_central/main.dart';

import 'package:harrier_central/pages/init/avatar_icons_page.dart';
import 'package:image_cropper/image_cropper.dart';

//import 'package:the_gorgeous_login/style/theme.dart' as Theme;

class ChooseAvatarPage extends StatefulWidget {
  const ChooseAvatarPage({Key key}) : super(key: key);

  @override
  _ChooseAvatarState createState() => _ChooseAvatarState();
}

class _ChooseAvatarState extends State<ChooseAvatarPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _selectedValue = 0;
  num _thumbnailSize = 85.0;
  num _previewAvatarSize = 120.0;

  int _selectedAvatarIcon = 1;

  Future<File> _imageFile;

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
                                  groupValue: _selectedValue,
                                  onChanged: _handleRadioValueChange1,
                                ),
                                Image.asset(
                                  'images/icons/avatar_icon.png',
                                  width: _thumbnailSize,
                                  height: _thumbnailSize,
                                ),
                              ],
                            ),
                            Row(
                              children: <Widget>[
                                Radio<int>(
                                  value: 1,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.padded,
                                  groupValue: _selectedValue,
                                  onChanged: _handleRadioValueChange1,
                                ),
                                Image.asset(
                                  'images/icons/avatar_ios_camera.png',
                                  width: _thumbnailSize,
                                  height: _thumbnailSize,
                                ),
                              ],
                            ),
                            Row(
                              children: <Widget>[
                                Radio<int>(
                                  value: 2,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.padded,
                                  groupValue: _selectedValue,
                                  onChanged: _handleRadioValueChange1,
                                ),
                                Image.asset(
                                  'images/icons/avatar_ios_camera_roll.png',
                                  width: _thumbnailSize,
                                  height: _thumbnailSize,
                                ),
                              ],
                            ),
                            Row(
                              children: <Widget>[
                                Radio<int>(
                                  value: 3,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.padded,
                                  groupValue: _selectedValue,
                                  onChanged: _handleRadioValueChange1,
                                ),
                                Image.asset(
                                  'images/icons/avatar_facebook_profile_pic.png',
                                  width: _thumbnailSize,
                                  height: _thumbnailSize,
                                ),
                              ],
                            ),
                          ],
                        ),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Text(
                                'Selected\r\nAvatar',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20.0,
                                    fontFamily: 'WorkSansSemiBold'),
                              ),
                              const Padding(
                                padding: EdgeInsets.only(top: 10.0),
                              ),
                              Container(
                                child: _getPreviewAvatar(),
                                color: Colors.white,
                                height: _previewAvatarSize + 6,
                                width: _previewAvatarSize + 6,
                                padding: EdgeInsets.all(6.0),
                              ),
                              const Padding(
                                padding: EdgeInsets.only(top: 60.0),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 20.0),
                    child: RaisedButton(
                        child: const Text(
                          'Next',
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: () {
                          int i = 0;
                        }),
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

    switch (_selectedValue) {
      case 0:
        returnWidget = Image.asset(
          'images/avatars/avatar-$_selectedAvatarIcon.png',
          width: _previewAvatarSize,
          height: _previewAvatarSize,
        );
        break;
      case 1:
        returnWidget = _previewImage();
        break;     
      case 2:
        returnWidget = _previewImage();
        break;
      default:
        returnWidget = Container(
            color: Colors.green,
            height: _previewAvatarSize,
            width: _previewAvatarSize);
    }
    return returnWidget;
  }

  void _handleRadioValueChange1(int value) {
    setState(() {
      _selectedValue = value;
      switch (_selectedValue) {
        case 0:
          // Navigator.of(context)
          //     .pushNamed<dynamic>(RouteNames.AVATAR_ICON_PAGE.toString())
          //     .then((dynamic onValue) {
          //   avatarIconName = 'avatar-$onValue.png';
          // });
          Navigator.push<dynamic>(
            context,
            MaterialPageRoute<dynamic>(
              builder: (context) =>
                  AvatarIconsPage(selectedAvatarIcon: _selectedAvatarIcon),
            ),
          ).then((dynamic onValue) {
            _selectedAvatarIcon = onValue;
          });
          break;
        case 1:
          _onImageButtonPressed(ImageSource.camera);
          break;
        case 2:
          //                 Navigator.push<dynamic>(
          //   context,
          //   MaterialPageRoute<dynamic>(
          //     builder: (context) =>
          //         ImageFromGallery(),
          //   ),
          // ).then((dynamic onValue) {
          //   _selectedAvatarIcon = onValue;
          // });
          _onImageButtonPressed(ImageSource.gallery);
          break;
      }
    });
  }

  void _onImageButtonPressed(ImageSource source) {
    setState(() {
      ImagePicker.pickImage(source: source).then((File image) {
       setState(() {
        _imageFile = ImageCropper.cropImage(
          sourcePath: image.path,
          ratioX: 1.0,
          ratioY: 1.0,
          maxWidth: 512,
          maxHeight: 512,
        );});
      });
    });
  }

  Widget _previewImage() {
    return FutureBuilder<File>(
        future: _imageFile,
        builder: (BuildContext context, AsyncSnapshot<File> snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.data != null) {
            return Image.file(snapshot.data);
          } else if (snapshot.error != null) {
            return const Text(
              'Error picking image.',
              textAlign: TextAlign.center,
            );
          } else {
            return const Text(
              'You have not yet picked an image.',
              textAlign: TextAlign.center,
            );
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
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitDown,
    ]);
  }
}
