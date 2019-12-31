import 'dart:async';
import 'dart:io' as platform;
import 'dart:ui';

import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:http/http.dart' as http;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:tinycolor/tinycolor.dart';

import 'package:harrier_central/pages/top_level/main_navigation_page.dart';
import 'package:harrier_central/pages/init/avatar_icons_page.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/styles.dart';
import 'package:harrier_central/util/globals.dart';
import 'package:harrier_central/widgets/fancy_divider.dart';
import 'package:harrier_central/widgets/profile_photo.dart';
import 'package:harrier_central/data/hc3_services/hashers_service.dart';

class ChooseProfileImage extends StatefulWidget {
  const ChooseProfileImage({Key key, @required this.isForThisDevice, @required this.fileNamePrefix, @required this.currentProfileImage, this.popToCaller = true}) : super(key: key);

  final bool isForThisDevice;
  final String fileNamePrefix;
  final String currentProfileImage;
  final bool popToCaller;

  @override
  _ChooseProfileImageState createState() => _ChooseProfileImageState();
}

enum _SelectedImageTypeEnum { none, avatar, fromCamera, fromGallery, facebookProfilePic, fromNetwork }

class _ChooseProfileImageState extends State<ChooseProfileImage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  _SelectedImageTypeEnum imageTypeSelection = _SelectedImageTypeEnum.none;

  final num _thumbnailSize = 50.0;
  final num _previewImageSize = 145.0;
  final num _uploadingImageSize = 180.0;

  String facebookProfileUrl = getStringPref(StringPrefsEnum.facebookProfilePhoto);

  int _selectedAvatarIcon = 1;

  bool _processingSelection = false;

  Future<platform.File> _imageFromCamera;
  Future<platform.File> _imageFromGallery;

  CachedNetworkImage facebookProfileImage;

  bool _isIos = false;

  @override
  void initState() {
    super.initState();

    if (widget.currentProfileImage.toLowerCase().startsWith('bundle://')) {
      imageTypeSelection = _SelectedImageTypeEnum.avatar;
    } else if (widget.currentProfileImage.toLowerCase().startsWith('http')) {
      imageTypeSelection = _SelectedImageTypeEnum.fromNetwork;
    }

    SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.portraitUp,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    _isIos = Theme.of(context).platform == TargetPlatform.iOS;
    if ((facebookProfileImage == null) && widget.isForThisDevice && ((facebookProfileUrl ?? '').isNotEmpty)) {
      facebookProfileImage = CachedNetworkImage(
          imageUrl: facebookProfileUrl,
          //placeholder: const HcCircularProgressIndicator(),
          //errorWidget: const  Icon(Icons.error),
          // placeholder: (BuildContext context, String url) =>
          //     const HcCircularProgressIndicator(),
          // errorWidget: (BuildContext context, String url, Exception error) =>
          //     const  Icon(Icons.error),
          //fadeOutDuration:  Duration(seconds: 1),
          fadeInDuration: const Duration(milliseconds: 0),
          width: _thumbnailSize,
          height: _thumbnailSize,
          fit: BoxFit.fill);

      imageTypeSelection = _SelectedImageTypeEnum.facebookProfilePic;
    }

    final AppBar appBar = AppBar(
      centerTitle: true,
      backgroundColor: themeAppBarBackground,
      title: const Text(
        'Choose Profile Image',
        style: TextStyle(
          color: Colors.white,
        ),
      ),
    );

    return Scaffold(
      key: _scaffoldKey,
      appBar: appBar,
      body: NotificationListener<OverscrollIndicatorNotification>(
        onNotification: (OverscrollIndicatorNotification overscroll) {
          overscroll.disallowGlow();
          return true; // TODO(James): What shoudl the return type really be?
        },
        child: Container(
          height: MediaQuery.of(context).size.height,
          decoration: Backgrounds.defaultHcBackground(),
          child: SingleChildScrollView(
            child: Container(
              width: MediaQuery.of(context).size.width,
              //height: MediaQuery.of(context).size.height >= 500.0 ? MediaQuery.of(context).size.height - appBar.preferredSize.height : 500.0,
              child: _processingSelection
                  ? _buildProgressIndicator()
                  : Column(
                      //alignment: AlignmentDirectional.topCenter,
                      children: <Widget>[
                        // Container(
                        //     width: MediaQuery.of(context).size.width,
                        //     height:500
                        //     ),

                        // Positioned(
                        //   top: 0,
                        //   child:

                        Container(
                          margin: const EdgeInsets.only(top: 20, bottom: 5),
                          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
                            Container(
                              padding: const EdgeInsets.only(right: 5),
                              child: RaisedButton(
                                color: imageTypeSelection == _SelectedImageTypeEnum.fromCamera ? TinyColor(Theme.of(context).accentColor).lighten(15).color : Theme.of(context).accentColor,
                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(30.0))),
                                child: Container(
                                  padding: const EdgeInsets.only(top: 10, bottom: 10),
                                  width: 100 * deviceWidthScaleFactor,
                                  height: 100,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      Image.asset(
                                        _isIos ? 'images/icons/ios_camera.png' : 'images/icons/android_camera.png',
                                        width: _thumbnailSize,
                                        height: _thumbnailSize,
                                      ),
                                      Container(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        height: 30,
                                        child: Text(
                                          'Camera',
                                          style: textStyleButton,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _handleRadioValueChange(_SelectedImageTypeEnum.fromCamera, forceOpen: true);
                                  });
                                },
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.only(left: 5),
                              child: RaisedButton(
                                color: imageTypeSelection == _SelectedImageTypeEnum.fromGallery ? TinyColor(Theme.of(context).accentColor).lighten(15).color : Theme.of(context).accentColor,
                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topRight: Radius.circular(30.0))),
                                child: Container(
                                  padding: const EdgeInsets.only(top: 10, bottom: 10),
                                  width: 100 * deviceWidthScaleFactor,
                                  height: 100,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      Image.asset(
                                        _isIos ? 'images/icons/ios_gallery.png' : 'images/icons/android_gallery.png',
                                        width: _thumbnailSize,
                                        height: _thumbnailSize,
                                      ),
                                      Container(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        height: 30,
                                        child: Text(
                                          'Gallery',
                                          style: textStyleButton,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _handleRadioValueChange(_SelectedImageTypeEnum.fromGallery, forceOpen: true);
                                  });
                                },
                              ),
                            ),
                          ]),
                        ),
                        //),

                        // Positioned(
                        //   top: 125,
                        //   child:

                        Container(
                          margin: const EdgeInsets.only(top: 5, bottom: 20),
                          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
                            Container(
                              padding: const EdgeInsets.only(right: 5),
                              child: RaisedButton(
                                color: imageTypeSelection == _SelectedImageTypeEnum.avatar ? TinyColor(Theme.of(context).accentColor).lighten(15).color : Theme.of(context).accentColor,
                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30.0))),
                                child: Container(
                                  padding: const EdgeInsets.only(top: 10, bottom: 10),
                                  width: 100 * deviceWidthScaleFactor,
                                  height: 100,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      Image.asset(
                                        'images/icons/avatar.png',
                                        width: _thumbnailSize,
                                        height: _thumbnailSize,
                                      ),
                                      Container(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        height: 30,
                                        child: Text(
                                          'Avatar',
                                          style: textStyleButton,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _handleRadioValueChange(_SelectedImageTypeEnum.avatar, forceOpen: true);
                                  });
                                },
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.only(left: 5),
                              child: RaisedButton(
                                color: facebookProfileImage == null ? Colors.grey : imageTypeSelection == _SelectedImageTypeEnum.facebookProfilePic ? TinyColor(Theme.of(context).accentColor).lighten(15).color : Theme.of(context).accentColor,
                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(bottomRight: Radius.circular(30.0))),
                                child: Container(
                                  padding: const EdgeInsets.only(top: 10, bottom: 10),
                                  width: 100 * deviceWidthScaleFactor,
                                  height: 100,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      Opacity(
                                        opacity: facebookProfileImage == null ? 0.5 : 1.0,
                                        child: Image.asset(
                                          'images/icons/facebook.png',
                                          width: _thumbnailSize,
                                          height: _thumbnailSize,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        height: 30,
                                        child: Text(
                                          'FB Photo',
                                          style: facebookProfileImage == null ? textStyleDisabledButton : textStyleButton,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                onPressed: () {
                                  if (facebookProfileImage != null) {
                                    setState(() {
                                      _handleRadioValueChange(_SelectedImageTypeEnum.facebookProfilePic, forceOpen: true);
                                    });
                                  }
                                },
                              ),
                            ),
                          ]),
                        ),
                        //),

                        // Positioned(
                        //   top: 250,
                        //   child:

                        Container(
                            width: MediaQuery.of(context).size.width,
                            padding: const EdgeInsets.only(top: 20),
                            child: const FancyDivider(
                              innerColor: Colors.white,
                            )),
                        //),

                        // Positioned(
                        //   top: 280,
                        //   child:
                        SizedBox(
                          height: 10,
                          width: 10,
                        ),
                        Text(
                          imageTypeSelection == _SelectedImageTypeEnum.avatar ? 'Selected Avatar' : 'Selected Image',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 20.0, fontFamily: 'WorkSansSemiBold'),
                        ),
                        const SizedBox(
                          height: 20,
                          width: 20,
                        ),

                        ((imageTypeSelection == _SelectedImageTypeEnum.none) && (widget.currentProfileImage.isEmpty))
                            ? Container(
                                child: Image.asset(
                                  'images/icons/create_profile_photo.png',
                                  height: 100,
                                  width: 100,
                                ),
                                color: Colors.white,
                                height: 200 * deviceWidthScaleFactor,
                                width: 200 * deviceWidthScaleFactor,
                                padding: const EdgeInsets.all(6.0),
                              )
                            : Container(
                                child: _getPreviewImage(),
                                color: Colors.white,
                                height: 200 * deviceWidthScaleFactor,
                                width: 200 * deviceWidthScaleFactor,
                                padding: const EdgeInsets.all(6.0),
                              ),
                        const SizedBox(
                          height: 20,
                          width: 20,
                        ),

                        FlatButton(
                            color: imageTypeSelection == _SelectedImageTypeEnum.none ? Colors.grey : Theme.of(context).accentColor,
                            child: const Text('Next'),
                            textColor: Colors.white,
                            onPressed: () {
                              if (imageTypeSelection != _SelectedImageTypeEnum.none) {
                                _processAndContinue();
                              }
                            }),

                        const SizedBox(
                          height: 20,
                          width: 20,
                        )

                        //),
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

            const Padding(
              padding: EdgeInsets.only(top: 20.0),
              child: Text(
                'Uploading\r\nProfile Image',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 32.0, fontFamily: 'WorkSansSemiBold'),
              ),
            ),
        const Padding(
                    padding: EdgeInsets.only(top: 32.0, bottom: 20.0),
                    child: FancyDivider(innerColor: Colors.white),
                  ),
        Container(
          child: _getPreviewImage(),
          color: Colors.white,
          height: _uploadingImageSize + 6,
          width: _uploadingImageSize + 6,
          padding: const EdgeInsets.all(6.0),
          
        ),
        const SizedBox(height: 20, width: 20,),
        Center(
          child: SpinKitCircle(
            size: 75.0,
            itemBuilder: (_, int index) {
              return DecoratedBox(
                decoration: BoxDecoration(
                  color: index.isEven ? Colors.white : Theme.of(context).accentColor,
                ),
              );
            },
          ),
        )
      ],
    );
  }

  void _processAndContinue() {
    // in order to keep our UI fluid, pay close attention to
    // how the async stuff is handled here...
    setState(() {
      _processingSelection = true;
    });

    final num startTime = DateTime.now().millisecondsSinceEpoch;
    _prepareAndUploadImageThenContinue(startTime);
  }

  Future<void> _prepareAndUploadImageThenContinue(int startTime) async {
    String profileImageUrl = '';

    String fileName;

    final String datetime = DateFormat('yyyyMMddkkmmss').format(DateTime.now());

    fileName = widget.fileNamePrefix.replaceAll('UQR:', '') + '_${datetime}_thumb.jpg';

    switch (imageTypeSelection) {
      case _SelectedImageTypeEnum.none:
        break;
      case _SelectedImageTypeEnum.avatar:
        profileImageUrl = 'bundle://avatar-$_selectedAvatarIcon'.toLowerCase();
        break;
      case _SelectedImageTypeEnum.fromCamera:
      case _SelectedImageTypeEnum.fromGallery:
        profileImageUrl = BASE_PROFILE_PHOTOS_URL + fileName;
        break;
      case _SelectedImageTypeEnum.facebookProfilePic:
        profileImageUrl = facebookProfileUrl;
        break;
      case _SelectedImageTypeEnum.fromNetwork:
        profileImageUrl = widget.currentProfileImage;
        break;
    }

    if (imageTypeSelection == _SelectedImageTypeEnum.fromCamera) {
      _imageFromCamera.then((platform.File file) {
        _upload(file, fileName);
      });
    } else if (imageTypeSelection == _SelectedImageTypeEnum.fromGallery) {
      _imageFromGallery.then((platform.File file) {
        _upload(file, fileName);
      });
    }

    final num deltaTime = DateTime.now().millisecondsSinceEpoch - startTime;
    if (deltaTime < 1250) {
      await Future<dynamic>.delayed(Duration(milliseconds: 1500 - deltaTime));
    }

    if (widget.popToCaller) {
      Navigator.of(context).pop(profileImageUrl);
    } else {
      final String userId = getStringPref(StringPrefsEnum.userId);

      final HashersService srv = HashersService();

      final Future<dynamic> apiCall =
          srv.addEditUser(targetUserId: userId, firstName: '', lastName: '', email: '', hashName: '', photo: profileImageUrl, eventId: GUID_EMPTY, kennelId: GUID_EMPTY, historicalPackRunCount: '', historicalHaringCount: '', historicalCountIsEstimate: false, followKennelOnAddNewUser: 0);

      apiCall.then((void dummy) async {
        setStringPref(StringPrefsEnum.profilePhotoUrl, profileImageUrl);

        Navigator.pushReplacement<dynamic, dynamic>(
            context,
            MaterialPageRoute<dynamic>(
              builder: (BuildContext context) => MainNavigationPage(),
            ));
      });
    }
  }

  String _upload(platform.File imageFile, String fileName) {
    final Uri uri = Uri.parse('http://harriercentral.blob.core.windows.net/profile-photos/$fileName?st=2018-11-22T07%3A36%3A49Z&se=2028-11-23T07%3A36%3A00Z&sp=rwl&sv=2018-03-28&sr=c&sig=GdHEgSU7Qbp6nEMbOeuxnTjKVVIXw1AImXUff8GPq2U%3D');

    final http.Request request = http.Request('PUT', uri);

    final Map<String, String> headers = <String, String>{'content-type': 'image/jpeg', 'x-ms-blob-type': 'BlockBlob'};

    request.headers.addAll(headers);

    request.bodyBytes = imageFile.readAsBytesSync();
    request.send().then((http.StreamedResponse response) {
      print('Avatar thumbnail upload response = ${response.statusCode}');
    });

    return uri.toString();
  }

  Widget _getPreviewImage() {
    Widget returnWidget;
    // if (_selectedAvatarIcon == null)
    // {
    //   _selectedAvatarIcon = 1;
    // }

    switch (imageTypeSelection) {
      case _SelectedImageTypeEnum.avatar:
        returnWidget = Image.asset(
          'images/avatars/avatar-$_selectedAvatarIcon.jpg',
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
        returnWidget = Container(
          constraints: const BoxConstraints(),
          child: FittedBox(child: facebookProfileImage, fit: BoxFit.contain),
          width: _previewImageSize,
          height: _previewImageSize,
        );
        break;

      default:
        if (widget.currentProfileImage.isNotEmpty) {
          returnWidget = ProfilePhoto(profilePhotoUrl: widget.currentProfileImage);
        } else {
          returnWidget = Image.asset(
            'images/icons/create_profile_photo.png',
            // height: 100,
            // width: 100,
          );
        }
    }
    return returnWidget;
  }

  void _handleRadioValueChange(_SelectedImageTypeEnum value, {bool forceOpen = false}) {
    setState(() {
      imageTypeSelection = value;
      switch (imageTypeSelection) {
        case _SelectedImageTypeEnum.avatar:
          if (forceOpen) {
            Navigator.push<dynamic>(
              context,
              MaterialPageRoute<dynamic>(
                builder: (BuildContext context) => AvatarIconsPage(selectedAvatarIcon: _selectedAvatarIcon),
              ),
            ).then((dynamic onValue) {
              if (onValue != null) {
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
          break;
        default:
          _onImageButtonPressed(ImageSource.gallery);
          break;
      }
    });
  }

  void _onImageButtonPressed(ImageSource source) {
    setState(() {
      ImagePicker.pickImage(source: source).then((platform.File image) {
        setState(() {
          final Future<platform.File> img = ImageCropper.cropImage(
            sourcePath: image.path,
            aspectRatio: const CropAspectRatio(ratioX: 1.0, ratioY: 1.0),
            aspectRatioPresets: [CropAspectRatioPreset.square],
            maxWidth: 512,
            maxHeight: 512,
          );

          if (imageTypeSelection == _SelectedImageTypeEnum.fromCamera) {
            _imageFromCamera = img;
          } else {
            _imageFromGallery = img;
          }
        });
      });
    });
  }

  Widget _previewImage() {
    return FutureBuilder<platform.File>(
        future: (imageTypeSelection == _SelectedImageTypeEnum.fromCamera) ? _imageFromCamera : _imageFromGallery,
        builder: (BuildContext context, AsyncSnapshot<platform.File> snapshot) {
          if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
            return Image.file(snapshot.data);
          } else if (snapshot.error != null) {
            return const Text(
              'Error picking image.',
              textAlign: TextAlign.center,
            );
          } else {
            return Image.asset(
              'images/icons/create_profile_photo.png',
              // height: 100,
              // width: 100,
            );
          }
        });
  }

  // @override
  // void dispose() {
  //   super.dispose();
  // }

}
