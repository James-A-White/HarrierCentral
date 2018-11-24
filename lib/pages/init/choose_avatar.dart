import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:harrier_central/main.dart';
import 'package:harrier_central/pages/init/avatar_icons_page.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/remote_api_data/update_avatar_service.dart';
import 'package:harrier_central/data_models/single_result_model.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/util/routes.dart';

import 'package:http/http.dart' as http;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

class ChooseAvatarPage extends StatefulWidget {
  const ChooseAvatarPage({Key key}) : super(key: key);

  @override
  _ChooseAvatarState createState() => _ChooseAvatarState();
}

enum _SelectedAvatarTypeEnum {
  avatar,
  fromCamera,
  fromGallery,
  facebookProfilePic
}

class _ChooseAvatarState extends State<ChooseAvatarPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  _SelectedAvatarTypeEnum _selectedAvatarType = _SelectedAvatarTypeEnum.avatar;
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
                                Radio<_SelectedAvatarTypeEnum>(
                                  value: _SelectedAvatarTypeEnum.avatar,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.padded,
                                  groupValue: _selectedAvatarType,
                                  onChanged: _handleRadioValueChange,
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
                                Radio<_SelectedAvatarTypeEnum>(
                                  value: _SelectedAvatarTypeEnum.fromCamera,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.padded,
                                  groupValue: _selectedAvatarType,
                                  onChanged: _handleRadioValueChange,
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
                                Radio<_SelectedAvatarTypeEnum>(
                                  value: _SelectedAvatarTypeEnum.fromGallery,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.padded,
                                  groupValue: _selectedAvatarType,
                                  onChanged: _handleRadioValueChange,
                                ),
                                Image.asset(
                                  'images/icons/avatar_ios_camera_roll.png',
                                  width: _thumbnailSize,
                                  height: _thumbnailSize,
                                ),
                              ],
                            ),
                            // Row(
                            //   children: <Widget>[
                            //     Radio<_SelectedAvatarTypeEnum>(
                            //       value: _SelectedAvatarTypeEnum
                            //           .facebookProfilePic,
                            //       materialTapTargetSize:
                            //           MaterialTapTargetSize.padded,
                            //       groupValue: _selectedAvatarType,
                            //       onChanged: _handleRadioValueChange,
                            //     ),
                            //     Image.asset(
                            //       'images/icons/avatar_facebook_profile_pic.png',
                            //       width: _thumbnailSize,
                            //       height: _thumbnailSize,
                            //     ),
                            //   ],
                            // ),
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
                        onPressed: () async {
                          _updateAvatar();
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

  void _updateAvatar() {
    String avatarUrl = '';

    String fileName = Preferences.getStringPref(StringPrefsEnum.qrCode)
            .replaceAll('UQR:', '') +
        '_thumb.jpg';

    switch (_selectedAvatarType) {
      case _SelectedAvatarTypeEnum.avatar:
        avatarUrl = 'bundle://Avatar-$_selectedAvatarIcon';
        break;
      case _SelectedAvatarTypeEnum.fromCamera:
      case _SelectedAvatarTypeEnum.fromGallery:
        avatarUrl = BASE_PROFILE_PHOTOS_URL + fileName;
        break;
      case _SelectedAvatarTypeEnum.facebookProfilePic:
        break;
    }

    Preferences.setStringPref(StringPrefsEnum.avatarUrl, avatarUrl);

    String userId = Preferences.getStringPref(StringPrefsEnum.userId);
    UpdateAvatarService svc = UpdateAvatarService();
    svc.updateAvatar(avatarUrl, userId).then((SingleResultModel result) {
      if ((_selectedAvatarType == _SelectedAvatarTypeEnum.fromCamera) ||
          (_selectedAvatarType == _SelectedAvatarTypeEnum.fromGallery)) {
        _imageFile.then((File file) {
          _upload(file, fileName);
        });
      }
      Navigator.of(context).pushReplacementNamed(RouteNames.MAIN_LANDING_PAGE.toString());
    });
  }

  void _upload(File imageFile, String fileName) async {
    final uri = Uri.parse(
        'http://harriercentral.blob.core.windows.net/profile-photos/$fileName?st=2018-11-22T07%3A36%3A49Z&se=2028-11-23T07%3A36%3A00Z&sp=rwl&sv=2018-03-28&sr=c&sig=GdHEgSU7Qbp6nEMbOeuxnTjKVVIXw1AImXUff8GPq2U%3D');

    var request = http.Request('PUT', uri);

    Map<String, String> headers = {
      'content-type': 'image/jpeg',
      'x-ms-blob-type': 'BlockBlob'
    };

    request.headers.addAll(headers);

    request.bodyBytes = imageFile.readAsBytesSync();
    request.send().then((http.StreamedResponse response) {
      print('Avatar thumbnail upload response = ${response.statusCode}');
    });
  }

  Widget _getPreviewAvatar() {
    Widget returnWidget;

    switch (_selectedAvatarType) {
      case _SelectedAvatarTypeEnum.avatar:
        returnWidget = Image.asset(
          'images/avatars/avatar-$_selectedAvatarIcon.png',
          width: _previewAvatarSize,
          height: _previewAvatarSize,
        );
        break;
      case _SelectedAvatarTypeEnum.fromCamera:
        returnWidget = _previewImage();
        break;
      case _SelectedAvatarTypeEnum.fromGallery:
        returnWidget = _previewImage();
        break;
      case _SelectedAvatarTypeEnum.facebookProfilePic:
      default:
        returnWidget = Container(
            color: Colors.green,
            height: _previewAvatarSize,
            width: _previewAvatarSize);
    }
    return returnWidget;
  }

  void _handleRadioValueChange(_SelectedAvatarTypeEnum value) {
    setState(() {
      _selectedAvatarType = value;
      switch (_selectedAvatarType) {
        case _SelectedAvatarTypeEnum.avatar:
          Navigator.push<dynamic>(
            this.context,
            MaterialPageRoute<dynamic>(
              builder: (context) =>
                  AvatarIconsPage(selectedAvatarIcon: _selectedAvatarIcon),
            ),
          ).then((dynamic onValue) {
            _selectedAvatarIcon = onValue;
          });
          break;
        case _SelectedAvatarTypeEnum.fromCamera:
          _onImageButtonPressed(ImageSource.camera);
          break;
        case _SelectedAvatarTypeEnum.fromGallery:
          _onImageButtonPressed(ImageSource.gallery);
          break;
        case _SelectedAvatarTypeEnum.facebookProfilePic:
        default:
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
          );
        });
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

// print(file.path);
// http.MultipartFile.fromPath('image', file.path,
//         contentType: MediaType('image', 'jpeg'))
//     .then((http.MultipartFile mpFile) {
//   var request = http.MultipartRequest(
//       'PUT',
//       Uri.parse(
//           'http://harriercentral.blob.core.windows.net/profile-photos/test5.jpg?st=2018-11-22T07%3A36%3A49Z&se=2028-11-23T07%3A36%3A00Z&sp=rwl&sv=2018-03-28&sr=c&sig=GdHEgSU7Qbp6nEMbOeuxnTjKVVIXw1AImXUff8GPq2U%3D'));

//   try {
//     //request.contentLength = mpFile.length;
//     request.files.add(mpFile);

//     // Map<String, String> headers = {
//     //   'Content-Length':
//     //       request.contentLength.toString(),
//     //   'Content-Type': 'image/jpeg',
//     //   'x-ms-blob-type': 'BlockBlob'
//     // };

//     request.fields.addAll({
//       'Content-Length':
//           request.contentLength.toString()
//     });

//     request.headers
//         .addAll({'x-ms-blob-type': 'BlockBlob'});
//     request.headers
//         .addAll({'Content-Type': 'image/jpeg'});
//     request.headers.addAll({
//       'Content-Length':
//           request.contentLength.toString()
//     });

//     request.send().then((response) {
//       print(response.statusCode);
//     });
//   } catch (Exception) {
//     print(Exception);
//   }
// });
