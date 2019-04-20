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

import 'package:harrier_central/data/models/single_result_model.dart';
import 'package:harrier_central/pages/init/avatar_icons_page.dart';
import 'package:harrier_central/data/services/update_avatar_service.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/routes.dart';
import 'package:harrier_central/util/utilities.dart';
import 'package:harrier_central/util/enums.dart';
import 'package:harrier_central/util/styles.dart';
import 'package:harrier_central/data/models/user_model.dart';
import 'package:harrier_central/data/services/add_user_service.dart';
import 'package:harrier_central/widgets/fancy_divider.dart';

class ChooseProfileImage extends StatefulWidget {
  const ChooseProfileImage(
      {Key key,
      this.doAddUser,
      this.isForThisDevice,
      this.firstName,
      this.lastName,
      this.email,
      this.hashName,
      this.eventId,
      this.kennelId,
      this.attendenceState})
      : super(key: key);

  final bool doAddUser;
  final bool isForThisDevice;
  final String firstName;
  final String lastName;
  final String email;
  final String hashName;
  final String eventId;
  final String kennelId;
  final EnumAttendenceState<int> attendenceState;

  @override
  _ChooseProfileImageState createState() => _ChooseProfileImageState();
}

enum _SelectedImageTypeEnum {
  none,
  avatar,
  fromCamera,
  fromGallery,
  facebookProfilePic
}

class _ChooseProfileImageState extends State<ChooseProfileImage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  _SelectedImageTypeEnum imageTypeSelection = _SelectedImageTypeEnum.none;

  final num _thumbnailSize = 50.0;
  final num _previewImageSize = 145.0;
  final num _uploadingImageSize = 180.0;

  String facebookProfileUrl =
      getStringPref(StringPrefsEnum.facebookProfilePhoto);

  int _selectedAvatarIcon = 1;

  bool _processingSelection = false;

  Future<platform.File> _imageFromCamera;
  Future<platform.File> _imageFromGallery;

  CachedNetworkImage facebookProfileImage;

  bool _isIos = false;

  @override
  Widget build(BuildContext context) {
    _isIos = Theme.of(context).platform == TargetPlatform.iOS;
    if ((facebookProfileImage == null) &&
        widget.isForThisDevice &&
        ((facebookProfileUrl ?? '').isNotEmpty)) {
      facebookProfileImage = CachedNetworkImage(
          imageUrl: facebookProfileUrl,
          //placeholder: const CircularProgressIndicator(),
          //errorWidget: const  Icon(Icons.error),
          // placeholder: (BuildContext context, String url) =>
          //     const CircularProgressIndicator(),
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
        },
        child: Container(
          height: MediaQuery.of(context).size.height,
          decoration: Backgrounds.defaultHcBackground(),
          child: SingleChildScrollView(
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height >= 500.0
                  ? MediaQuery.of(context).size.height -
                      appBar.preferredSize.height
                  : 500.0,
              child: _processingSelection
                  ? _buildProgressIndicator()
                  : Stack(
                      alignment: AlignmentDirectional.topCenter,
                      children: <Widget>[
                        // Container(
                        //     //width: MediaQuery.of(context).size.width
                        //     ),
                        Positioned(
                          top: 0,
                          child: Container(
                            margin: const EdgeInsets.only(top: 20, bottom: 5),
                            child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Container(
                                    padding: const EdgeInsets.only(right: 5),
                                    child: RaisedButton(
                                      color: imageTypeSelection ==
                                              _SelectedImageTypeEnum.fromCamera
                                          ? TinyColor(
                                                  Theme.of(context).accentColor)
                                              .lighten(15)
                                              .color
                                          : Theme.of(context).accentColor,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: const BorderRadius.only(
                                              topLeft: Radius.circular(30.0))),
                                      child: Container(
                                        padding: const EdgeInsets.only(
                                            top: 10, bottom: 10),
                                        width: 120,
                                        height: 100,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: <Widget>[
                                            Image.asset(
                                              _isIos
                                                  ? 'images/icons/ios_camera.png'
                                                  : 'images/icons/android_camera.png',
                                              width: _thumbnailSize,
                                              height: _thumbnailSize,
                                            ),
                                            Container(
                                              padding: const EdgeInsets.only(
                                                  top: 8.0),
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
                                          _handleRadioValueChange(
                                              _SelectedImageTypeEnum.fromCamera,
                                              forceOpen: true);
                                        });
                                      },
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.only(left: 5),
                                    child: RaisedButton(
                                      color: imageTypeSelection ==
                                              _SelectedImageTypeEnum.fromGallery
                                          ? TinyColor(
                                                  Theme.of(context).accentColor)
                                              .lighten(15)
                                              .color
                                          : Theme.of(context).accentColor,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: const BorderRadius.only(
                                              topRight: Radius.circular(30.0))),
                                      child: Container(
                                        padding: const EdgeInsets.only(
                                            top: 10, bottom: 10),
                                        width: 120,
                                        height: 100,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: <Widget>[
                                            Image.asset(
                                              _isIos
                                                  ? 'images/icons/ios_gallery.png'
                                                  : 'images/icons/android_gallery.png',
                                              width: _thumbnailSize,
                                              height: _thumbnailSize,
                                            ),
                                            Container(
                                              padding: const EdgeInsets.only(
                                                  top: 8.0),
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
                                          _handleRadioValueChange(
                                              _SelectedImageTypeEnum
                                                  .fromGallery,
                                              forceOpen: true);
                                        });
                                      },
                                    ),
                                  ),
                                ]),
                          ),
                        ),
                        Positioned(
                          top: 125,
                          child: Container(
                            margin: const EdgeInsets.only(top: 5, bottom: 20),
                            child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Container(
                                    padding: const EdgeInsets.only(right: 5),
                                    child: RaisedButton(
                                      color: imageTypeSelection ==
                                              _SelectedImageTypeEnum.avatar
                                          ? TinyColor(
                                                  Theme.of(context).accentColor)
                                              .lighten(15)
                                              .color
                                          : Theme.of(context).accentColor,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: const BorderRadius.only(
                                              bottomLeft:
                                                  Radius.circular(30.0))),
                                      child: Container(
                                        padding: const EdgeInsets.only(
                                            top: 10, bottom: 10),
                                        width: 120,
                                        height: 100,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: <Widget>[
                                            Image.asset(
                                              'images/icons/avatar.png',
                                              width: _thumbnailSize,
                                              height: _thumbnailSize,
                                            ),
                                            Container(
                                              padding: const EdgeInsets.only(
                                                  top: 8.0),
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
                                          _handleRadioValueChange(
                                              _SelectedImageTypeEnum.avatar,
                                              forceOpen: true);
                                        });
                                      },
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.only(left: 5),
                                    child: RaisedButton(
                                      color: facebookProfileImage == null
                                          ? Colors.grey
                                          : imageTypeSelection ==
                                                  _SelectedImageTypeEnum
                                                      .facebookProfilePic
                                              ? TinyColor(Theme.of(context)
                                                      .accentColor)
                                                  .lighten(15)
                                                  .color
                                              : Theme.of(context).accentColor,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: const BorderRadius.only(
                                              bottomRight:
                                                  Radius.circular(30.0))),
                                      child: Container(
                                        padding: const EdgeInsets.only(
                                            top: 10, bottom: 10),
                                        width: 120,
                                        height: 100,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: <Widget>[
                                            Opacity(
                                              opacity:
                                                  facebookProfileImage == null
                                                      ? 0.5
                                                      : 1.0,
                                              child: Image.asset(
                                                'images/icons/facebook.png',
                                                width: _thumbnailSize,
                                                height: _thumbnailSize,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.only(
                                                  top: 8.0),
                                              height: 30,
                                              child: Text(
                                                'FB Photo',
                                                style: facebookProfileImage ==
                                                        null
                                                    ? textStyleDisabledButton
                                                    : textStyleButton,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      onPressed: () {
                                        if (facebookProfileImage != null) {
                                          setState(() {
                                            _handleRadioValueChange(
                                                _SelectedImageTypeEnum
                                                    .facebookProfilePic,
                                                forceOpen: true);
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ]),
                          ),
                        ),
                        Positioned(
                          top: 250,
                          child: Container(
                              width: MediaQuery.of(context).size.width,
                              padding: const EdgeInsets.only(top: 20),
                              child:
                                  const FancyDivider(innerColor: Colors.white,)),
                        ),

                        Positioned(
                          top: 280,
                          child: Text(
                            imageTypeSelection == _SelectedImageTypeEnum.avatar
                                ? 'Selected Avatar'
                                : 'Selected Image',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20.0,
                                fontFamily: 'WorkSansSemiBold'),
                          ),
                        ),

                        Positioned(
                          top: 320,
                          bottom: 100,
                          child: LayoutBuilder(builder: (BuildContext context,
                              BoxConstraints viewportConstraints) {
                            return imageTypeSelection ==
                                    _SelectedImageTypeEnum.none
                                ? Container(
                                    child: Image.asset(
                                      'images/icons/create_profile_photo.png',
                                      height: 100,
                                      width: 100,
                                    ),
                                    color: Colors.white,
                                    height: viewportConstraints.maxHeight,
                                    width: viewportConstraints.maxHeight,
                                    padding: const EdgeInsets.all(6.0),
                                  )
                                : Container(
                                    child: _getPreviewImage(),
                                    color: Colors.white,
                                    height: viewportConstraints.maxHeight,
                                    width: viewportConstraints.maxHeight,
                                    padding: const EdgeInsets.all(6.0),
                                  );
                          }),
                        ),
                        Positioned(
                          bottom: 30,
                          child: RaisedButton(
                            color: imageTypeSelection ==
                                    _SelectedImageTypeEnum.none
                                ? Colors.grey
                                : Theme.of(context).accentColor,
                            child: Container(
                              width: 150,
                              height: 50,
                              child: Container(
                                child: Center(
                                  child: Text(
                                    'Next >',
                                    style: textStyleButton,
                                  ),
                                ),
                              ),
                            ),
                            onPressed: () {
                              if (imageTypeSelection !=
                                  _SelectedImageTypeEnum.none) {
                                _processAndContinue();
                              }
                            },
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
              padding: const EdgeInsets.only(top: 0.0),
              child: Text(
                widget.doAddUser
                    ? 'Creating account\r\nand uploading\r\nprofile image'
                    : 'Uploading\r\nProfile Image',
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
                    child: Icon(FontAwesome.circle,
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
          padding: const EdgeInsets.all(6.0),
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

  void _processAndContinue() {
    // in order to keep our UI fluid, pay close attention to
    // how the async stuff is handled here...
    setState(() {
      _processingSelection = true;
    });

    final num startTime = DateTime.now().millisecondsSinceEpoch;

    if (widget.doAddUser) {
      if (widget.isForThisDevice) {
        AddUserService()
            .addUser(
                _scaffoldKey.currentContext,
                getStringPref(StringPrefsEnum.firstName),
                getStringPref(StringPrefsEnum.lastName),
                getStringPref(StringPrefsEnum.email),
                getStringPref(StringPrefsEnum.hashName),
                getStringPref(StringPrefsEnum.facebookId),
                getStringPref(StringPrefsEnum.gender),
                '',
                GUID_EMPTY,
                '',
                hasherTypeMember)
            .then((UserModel user) {
          // if the call fails, user will be null
          if (user != null) {
            setStringPref(StringPrefsEnum.userId, user.hasherId);
            setStringPref(StringPrefsEnum.displayName, user.displayName);
            setStringPref(StringPrefsEnum.qrCode, user.qrCode);
            setStringPref(StringPrefsEnum.supportCode, user.supportCode);
            setStringPref(StringPrefsEnum.qrSecretCode, user.qrSecretCode);
            // after this executes, we will push and replace this to the main screen
            // the logic for this is in the underlying method
            _prepareAndUploadImageThenContinue(startTime, user);
          } else {
            setState(() {
              _processingSelection = false;
              Navigator.of(context).pop(null);
            });
          }
        });
      } else {
        // adding an "external" user who is not associated with this device
        // typically these people are added while at a Hash so we have to
        // push in an event ID
        AddUserService()
            .addUser(
                _scaffoldKey.currentContext,
                widget.firstName,
                widget.lastName,
                widget.email,
                widget.hashName,
                '', // facebook ID
                '', // gender
                '', // photo
                widget.kennelId, // member kennel ID
                widget.eventId, // event ID
                hasherTypeMember,
                attendenceState: widget.attendenceState)
            .then((UserModel user) {
          // if the call fails, user will be null
          if (user != null) {
            // after this executes, we will push and replace this to the main screen
            // the logic for this is in the underlying method
            _prepareAndUploadImageThenContinue(startTime, user);
          } else {
            setState(() {
              _processingSelection = false;
              // pop the user back to the page where they enter the details
              Navigator.of(context).pop(null);
            });
          }
        });
      }
    } else {
      // after this executes, we will pop back to the originating screen that invoked this screen
      _prepareAndUploadImageThenContinue(startTime, null);
    }
  }

  void _prepareAndUploadImageThenContinue(int startTime, UserModel user) {
    String profileImageUrl = '';

    String fileName;

    String userId = getStringPref(StringPrefsEnum.userId);
    final String datetime = DateFormat('yyyyMMddkkmmss').format(DateTime.now());

    if (widget.doAddUser) {
      // this is for either of the two cases where
      // a user has been added, either for this device
      // or the owner of this device adding other users. In both
      // cases, we should have a valid UserModel variable set
      fileName = user.qrCode.replaceAll('UQR:', '') + '_${datetime}_thumb.jpg';
      // in case we are creating users not for this device
      // make sure we have the correct hash userId
      userId = user.hasherId;
    } else {
      // in the case where we are simply updating the existing
      // profile image of the account associated with this device,
      // use the existing QR code stored in preferences as the base name for the photo
      fileName = getStringPref(StringPrefsEnum.qrCode).replaceAll('UQR:', '') +
          '_${datetime}_thumb.jpg';
    }

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
    }

    if ((widget.doAddUser) && (widget.isForThisDevice)) {
      // this is the case where we are adding a new user for the user of
      // this device. This typically happens when a user installs the app.
      // When this code is finished, we want to redirect the user to the
      // main screen
      setStringPref(StringPrefsEnum.profilePhotoUrl, profileImageUrl);

      final UpdateProfilePhotoService svc = UpdateProfilePhotoService();
      svc
          .updateProfilePhoto(profileImageUrl, userId)
          .then((SingleResultModel result) {
        if (imageTypeSelection == _SelectedImageTypeEnum.fromCamera) {
          _imageFromCamera.then((platform.File file) {
            _upload(file, fileName);
          });
        } else if (imageTypeSelection == _SelectedImageTypeEnum.fromGallery) {
          _imageFromGallery.then((platform.File file) {
            _upload(file, fileName);
          });
        }

        // how long has the
        final num deltaTime = DateTime.now().millisecondsSinceEpoch - startTime;

        if (deltaTime > 1000) {
          print('Delay to show uploading screen = $deltaTime milliseconds');
          Future<dynamic>.delayed(Duration(milliseconds: deltaTime))
              .then((void dummy) {
            Navigator.of(context)
                .pushReplacementNamed(RouteNames.MAIN_LANDING_PAGE.toString());
          });
        } else {
          Navigator.of(context)
              .pushReplacementNamed(RouteNames.MAIN_LANDING_PAGE.toString());
        }
      });
    } else if ((widget.doAddUser) && (!widget.isForThisDevice)) {
      // this is for a user being added from the device,
      // but not a user that represents the owner of this device.
      // This is usually called when an admin adds a new user from his / her device.
      // When this code is done executing, we want to pop back
      // to the caller.
      final UpdateProfilePhotoService svc = UpdateProfilePhotoService();
      svc
          .updateProfilePhoto(profileImageUrl, userId)
          .then((SingleResultModel result) {
        if (imageTypeSelection == _SelectedImageTypeEnum.fromCamera) {
          _imageFromCamera.then((platform.File file) {
            _upload(file, fileName);
          });
        } else if (imageTypeSelection == _SelectedImageTypeEnum.fromGallery) {
          _imageFromGallery.then((platform.File file) {
            _upload(file, fileName);
          });
        }

        user.photo = profileImageUrl;

        Future<dynamic>.delayed(const Duration(milliseconds: 3500))
            .then((void dummy) {
          Navigator.of(context).pop(user);
        });
      });
    } else {
      // this last case will be for updating the profile photo
      // of the user of this device, but without creating a
      // user
      print('Uploading profile image');

      final UpdateProfilePhotoService svc = UpdateProfilePhotoService();
      svc
          .updateProfilePhoto(profileImageUrl, userId)
          .then((SingleResultModel result) {
        if (result.result.toLowerCase() == 'success') {
          setStringPref(StringPrefsEnum.profilePhotoUrl, profileImageUrl);

          if (imageTypeSelection == _SelectedImageTypeEnum.fromCamera) {
            _imageFromCamera.then((platform.File file) {
              _upload(file, fileName);
            });
          } else if (imageTypeSelection == _SelectedImageTypeEnum.fromGallery) {
            _imageFromGallery.then((platform.File file) {
              _upload(file, fileName);
            });
          }
        } else {
          Utilities.showAlert(
              context,
              'Error Uploading Image',
              'There was an error uploading your new profile image. Please try again later. If you continue to have a problem please contact us at connect@harriercentral.com',
              'OK');
        }

        Future<dynamic>.delayed(const Duration(milliseconds: 3500))
            .then((void dummy) {
          Navigator.of(context).pop(user);
        });
      });
    }
  }

  String _upload(platform.File imageFile, String fileName) {
    final Uri uri = Uri.parse(
        'http://harriercentral.blob.core.windows.net/profile-photos/$fileName?st=2018-11-22T07%3A36%3A49Z&se=2028-11-23T07%3A36%3A00Z&sp=rwl&sv=2018-03-28&sr=c&sig=GdHEgSU7Qbp6nEMbOeuxnTjKVVIXw1AImXUff8GPq2U%3D');

    final http.Request request = http.Request('PUT', uri);

    final Map<String, String> headers = <String, String>{
      'content-type': 'image/jpeg',
      'x-ms-blob-type': 'BlockBlob'
    };

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
        returnWidget = Container(
          constraints: const BoxConstraints(),
          child: FittedBox(child: facebookProfileImage, fit: BoxFit.contain),
          width: _previewImageSize,
          height: _previewImageSize,
        );
        break;
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
      imageTypeSelection = value;
      switch (imageTypeSelection) {
        case _SelectedImageTypeEnum.avatar:
          if (forceOpen) {
            Navigator.push<dynamic>(
              context,
              MaterialPageRoute<dynamic>(
                builder: (BuildContext context) =>
                    AvatarIconsPage(selectedAvatarIcon: _selectedAvatarIcon),
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
    setState(() async {
      ImagePicker.pickImage(source: source).then((platform.File image) {
        setState(() {
          final Future<platform.File> img = ImageCropper.cropImage(
            sourcePath: image.path,
            ratioX: 1.0,
            ratioY: 1.0,
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
        future: (imageTypeSelection == _SelectedImageTypeEnum.fromCamera)
            ? _imageFromCamera
            : _imageFromGallery,
        builder: (BuildContext context, AsyncSnapshot<platform.File> snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.data != null) {
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
