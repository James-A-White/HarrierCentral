import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import 'package:harrier_central/data_models/single_result_model.dart';
import 'package:harrier_central/main.dart';
import 'package:harrier_central/pages/init/avatar_icons_page.dart';
import 'package:harrier_central/services/update_avatar_service.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/routes.dart';


class ChooseProfileImage extends StatefulWidget {
  bool isInitFlow;

  ChooseProfileImage(this.isInitFlow, {Key key}) : super(key: key);

  @override
  _ChooseProfileImageState createState() => _ChooseProfileImageState();
}

enum _SelectedImageTypeEnum {
  avatar,
  fromCamera,
  fromGallery,
  facebookProfilePic
}

class _ChooseProfileImageState extends State<ChooseProfileImage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  _SelectedImageTypeEnum _selectedImageType = _SelectedImageTypeEnum.avatar;
  num _thumbnailSize = 85.0;
  num _previewImageSize = 120.0;
  num _uploadingImageSize = 180.0;

  int _selectedAvatarIcon = 1;
  //int _currentAvatarIcon = 1;

  bool _processingSelection = false;

  Future<File> _imageFromCamera;
  Future<File> _imageFromGallery;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
          centerTitle: true,
          backgroundColor: Theme.of(context).primaryColor,
          title: Text(
            'Choose Profile Image',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ),
      body: NotificationListener<OverscrollIndicatorNotification>(
        onNotification: (OverscrollIndicatorNotification overscroll) {
          overscroll.disallowGlow();
        },
        child: SingleChildScrollView(
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height >= 300.0
                ? MediaQuery.of(context).size.height - 100
                : 300.0,
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
            child: _processingSelection
                ? _buildProgressIndicator()
                : Padding(
                    padding: EdgeInsets.only(top: 0.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        // Padding(
                        //   padding: EdgeInsets.only(top: 0.0),
                        //   child: Text(
                        //     'Choose Profile Image',
                        //     textAlign: TextAlign.center,
                        //     style: const TextStyle(
                        //         color: Colors.white,
                        //         fontSize: 32.0,
                        //         fontFamily: 'WorkSansSemiBold'),
                        //   ),
                        // ),
                        // Padding(
                        //   padding: const EdgeInsets.only(top: 10.0),
                        //   child: Row(
                        //     mainAxisAlignment: MainAxisAlignment.center,
                        //     children: <Widget>[
                        //       Container(
                        //         decoration: const BoxDecoration(
                        //           gradient: LinearGradient(
                        //               colors: <Color>[
                        //                 Colors.white10,
                        //                 Colors.white,
                        //               ],
                        //               begin: FractionalOffset(0.0, 0.0),
                        //               end: FractionalOffset(1.0, 1.0),
                        //               stops: <double>[0.0, 1.0],
                        //               tileMode: TileMode.clamp),
                        //         ),
                        //         width: 100.0,
                        //         height: 1.0,
                        //       ),
                        //       const Padding(
                        //         padding:
                        //             EdgeInsets.only(left: 15.0, right: 15.0),
                        //         child: const Icon(FontAwesomeIcons.circle,
                        //             color: Color(0xFFFFFFFF), size: 10.0),
                        //       ),
                        //       Container(
                        //         decoration: const BoxDecoration(
                        //           gradient: LinearGradient(
                        //               colors: <Color>[
                        //                 Colors.white,
                        //                 Colors.white10,
                        //               ],
                        //               begin: FractionalOffset(0.0, 0.0),
                        //               end: FractionalOffset(1.0, 1.0),
                        //               stops: <double>[0.0, 1.0],
                        //               tileMode: TileMode.clamp),
                        //         ),
                        //         width: 100.0,
                        //         height: 1.0,
                        //       ),
                        //     ],
                        //   ),
                        // ),
                        
                        
                        Expanded(
                          child: Row(
                            children: <Widget>[
                              Column(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      Radio<_SelectedImageTypeEnum>(
                                        value: _SelectedImageTypeEnum.avatar,
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.padded,
                                        groupValue: _selectedImageType,
                                        onChanged: _handleRadioValueChange,
                                      ),
                                      FlatButton(
                                        onPressed: () {
                                          setState(() {
                                            _handleRadioValueChange(
                                                _SelectedImageTypeEnum.avatar,
                                                forceOpen: true);
                                          });
                                        },
                                        child: Image.asset(
                                          'images/icons/avatar_icon.png',
                                          width: _thumbnailSize,
                                          height: _thumbnailSize,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: <Widget>[
                                      Radio<_SelectedImageTypeEnum>(
                                        value:
                                            _SelectedImageTypeEnum.fromCamera,
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.padded,
                                        groupValue: _selectedImageType,
                                        onChanged: _handleRadioValueChange,
                                      ),
                                      FlatButton(
                                        onPressed: () {
                                          setState(() {
                                            _handleRadioValueChange(
                                                _SelectedImageTypeEnum
                                                    .fromCamera,
                                                forceOpen: true);
                                          });
                                        },
                                        child: Image.asset(
                                          'images/icons/avatar_ios_camera.png',
                                          width: _thumbnailSize,
                                          height: _thumbnailSize,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: <Widget>[
                                      Radio<_SelectedImageTypeEnum>(
                                        value:
                                            _SelectedImageTypeEnum.fromGallery,
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.padded,
                                        groupValue: _selectedImageType,
                                        onChanged: _handleRadioValueChange,
                                      ),
                                      FlatButton(
                                        onPressed: () {
                                          setState(() {
                                            _handleRadioValueChange(
                                                _SelectedImageTypeEnum
                                                    .fromGallery,
                                                forceOpen: true);
                                          });
                                        },
                                        child: Image.asset(
                                          'images/icons/avatar_ios_camera_roll.png',
                                          width: _thumbnailSize,
                                          height: _thumbnailSize,
                                        ),
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
                                      ((_selectedImageType ==
                                              _SelectedImageTypeEnum.avatar)
                                          ? 'Selected\r\nAvatar'
                                          : 'Selected\r\nImage'),
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
                                      child: _getPreviewImage(),
                                      color: Colors.white,
                                      height: _previewImageSize + 6,
                                      width: _previewImageSize + 6,
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
                          child: Container(
                            margin:
                                const EdgeInsets.only(top: 10.0, bottom: 30.0),
                            decoration: BoxDecoration(
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(5.0)),
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: LoginColors.loginGradientStart,
                                  offset: const Offset(1.0, 6.0),
                                  blurRadius: 20.0,
                                ),
                                BoxShadow(
                                  color: LoginColors.loginGradientEnd,
                                  offset: const Offset(1.0, 6.0),
                                  blurRadius: 20.0,
                                ),
                              ],
                              gradient: LinearGradient(
                                  colors: <Color>[
                                    LoginColors.loginGradientEnd,
                                    LoginColors.loginGradientStart
                                  ],
                                  begin: const FractionalOffset(0.2, 0.2),
                                  end: const FractionalOffset(1.0, 1.0),
                                  stops: const <double>[0.0, 1.0],
                                  tileMode: TileMode.clamp),
                            ),
                            child: MaterialButton(
                                highlightColor: Colors.transparent,
                                splashColor: LoginColors.loginGradientEnd,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 10.0, horizontal: 20.0),
                                  child: Text(
                                    ((_selectedImageType ==
                                            _SelectedImageTypeEnum.avatar)
                                        ? 'NEXT'
                                        : 'NEXT'),
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 25.0,
                                        fontFamily: 'WorkSansBold'),
                                  ),
                                ),
                                onPressed: () => _updateAvatar()),
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

  Widget _buildProgressIndicator() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Column(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(top: 0.0),
              child: Text(
                'Uploading\r\nProfile Image',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32.0,
                    fontFamily: 'WorkSansSemiBold'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                          colors: <Color>[
                            Colors.white10,
                            Colors.white,
                          ],
                          begin: FractionalOffset(0.0, 0.0),
                          end: FractionalOffset(1.0, 1.0),
                          stops: <double>[0.0, 1.0],
                          tileMode: TileMode.clamp),
                    ),
                    width: 100.0,
                    height: 1.0,
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 15.0, right: 15.0),
                    child: const Icon(FontAwesomeIcons.circle,
                        color: Color(0xFFFFFFFF), size: 10.0),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                          colors: <Color>[
                            Colors.white,
                            Colors.white10,
                          ],
                          begin: FractionalOffset(0.0, 0.0),
                          end: FractionalOffset(1.0, 1.0),
                          stops: <double>[0.0, 1.0],
                          tileMode: TileMode.clamp),
                    ),
                    width: 100.0,
                    height: 1.0,
                  ),
                ],
              ),
            ),
          ],
        ),
        Container(
          child: _getPreviewImage(),
          color: Colors.white,
          height: _uploadingImageSize + 6,
          width: _uploadingImageSize + 6,
          padding: EdgeInsets.all(6.0),
        ),
        Center(
          child: SpinKitCircle(
            size: 75.0,
            itemBuilder: (_, int index) {
              return DecoratedBox(
                decoration: BoxDecoration(
                  color: index.isEven
                      ? Colors.white
                      : Theme.of(context).accentColor,
                ),
              );
            },
          ),
        )
      ],
    );
  }

  void _updateAvatar() {
    setState(() {
      _processingSelection = true;
    });

    String avatarUrl = '';

    String fileName = Preferences.getStringPref(StringPrefsEnum.qrCode)
            .replaceAll('UQR:', '') +
        '_thumb.jpg';

     if (widget.isInitFlow == false)
     {
        var uuid = Uuid();
        fileName = uuid.v1().toString() + '_thumb.jpg';
     }

    switch (_selectedImageType) {
      case _SelectedImageTypeEnum.avatar:
        avatarUrl = 'bundle://Avatar-$_selectedAvatarIcon';
        break;
      case _SelectedImageTypeEnum.fromCamera:
      case _SelectedImageTypeEnum.fromGallery:
        avatarUrl = BASE_PROFILE_PHOTOS_URL + fileName;
        break;
      case _SelectedImageTypeEnum.facebookProfilePic:
        break;
    }

    Preferences.setStringPref(StringPrefsEnum.profilePhotoUrl, avatarUrl);

    if (widget.isInitFlow == true) {
      String userId = Preferences.getStringPref(StringPrefsEnum.userId);
      UpdateAvatarService svc = UpdateAvatarService();
      svc.updateAvatar(avatarUrl, userId).then((SingleResultModel result) {
        if (_selectedImageType == _SelectedImageTypeEnum.fromCamera) {
          _imageFromCamera.then((File file) {
            _upload(file, fileName);
          });
        } else if (_selectedImageType == _SelectedImageTypeEnum.fromGallery) {
          _imageFromGallery.then((File file) {
            _upload(file, fileName);
          });
        }

        Future<dynamic>.delayed(const Duration(milliseconds: 3500))
            .then((void dummy) {
          Navigator.of(context)
              .pushReplacementNamed(RouteNames.MAIN_LANDING_PAGE.toString());
        });
      });
    } else {
      if (_selectedImageType == _SelectedImageTypeEnum.fromCamera) {
          _imageFromCamera.then((File file) {
            _upload(file, fileName);
          });
        } else if (_selectedImageType == _SelectedImageTypeEnum.fromGallery) {
          _imageFromGallery.then((File file) {
            _upload(file, fileName);
          });
        }
        Navigator.of(context)
              .pop(avatarUrl);

    }
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

  Widget _getPreviewImage() {
    Widget returnWidget;
    // if (_selectedAvatarIcon == null)
    // {
    //   _selectedAvatarIcon = 1;
    // }

    switch (_selectedImageType) {
      case _SelectedImageTypeEnum.avatar:
        returnWidget = Image.asset(
          'images/avatars/avatar-$_selectedAvatarIcon.png',
          width: _previewImageSize,
          height: _previewImageSize,
        );
        break;
      case _SelectedImageTypeEnum.fromCamera:
        returnWidget = _previewImage();
        break;
      case _SelectedImageTypeEnum.fromGallery:
        returnWidget = _previewImage();
        break;
      case _SelectedImageTypeEnum.facebookProfilePic:
      default:
        returnWidget = Container(
            color: Colors.green,
            height: _previewImageSize,
            width: _previewImageSize);
    }
    return returnWidget;
  }

  void _handleRadioValueChange(_SelectedImageTypeEnum value,
      {bool forceOpen = false}) {
    setState(() {
      _selectedImageType = value;
      switch (_selectedImageType) {
        case _SelectedImageTypeEnum.avatar:
          if (forceOpen) {
            Navigator.push<dynamic>(
              this.context,
              MaterialPageRoute<dynamic>(
                builder: (context) =>
                    AvatarIconsPage(selectedAvatarIcon: _selectedAvatarIcon),
              ),
            ).then((dynamic onValue) {
              if (onValue != null)
              {
                _selectedAvatarIcon = onValue;
              }
            });
          }
          break;
        case _SelectedImageTypeEnum.fromCamera:
          if (forceOpen || (_imageFromCamera == null)) {
            _onImageButtonPressed(ImageSource.camera);
          }
          break;
        case _SelectedImageTypeEnum.fromGallery:
          if (forceOpen || (_imageFromGallery == null)) {
            _onImageButtonPressed(ImageSource.gallery);
          }
          break;
        case _SelectedImageTypeEnum.facebookProfilePic:
        default:
          _onImageButtonPressed(ImageSource.gallery);
          break;
      }
    });
  }

  void _onImageButtonPressed(ImageSource source) {
    setState(() async {
      ImagePicker.pickImage(source: source).then((File image) {
        setState(() {
          var img = ImageCropper.cropImage(
            sourcePath: image.path,
            ratioX: 1.0,
            ratioY: 1.0,
            maxWidth: 512,
            maxHeight: 512,
          );

          if (_selectedImageType == _SelectedImageTypeEnum.fromCamera) {
            _imageFromCamera = img;
          } else {
            _imageFromGallery = img;
          }
        });
      });
    });
  }

  Widget _previewImage() {
    return FutureBuilder<File>(
        future: (_selectedImageType == _SelectedImageTypeEnum.fromCamera)
            ? _imageFromCamera
            : _imageFromGallery,
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
              'You have not yet chosen an image.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 22.0,
                  fontFamily: 'WorkSansBold'),
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
