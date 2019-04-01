import 'dart:async';
import 'dart:io';
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

import 'package:harrier_central/data_models/single_result_model.dart';
import 'package:harrier_central/main.dart';
import 'package:harrier_central/pages/init/avatar_icons_page.dart';
import 'package:harrier_central/services/update_avatar_service.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/routes.dart';
import 'package:harrier_central/util/enums.dart';
import 'package:harrier_central/util/styles.dart';
import 'package:harrier_central/data_models/user_model.dart';
import 'package:harrier_central/services/add_user_service.dart';

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
  avatar,
  fromCamera,
  fromGallery,
  facebookProfilePic
}

class _ChooseProfileImageState extends State<ChooseProfileImage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  _SelectedImageTypeEnum _radioImageTypeSelection =
      _SelectedImageTypeEnum.avatar;

  final num _thumbnailSize = 85.0;
  final num _previewImageSize = 120.0;
  final num _uploadingImageSize = 180.0;

  String facebookProfileUrl =
      getStringPref(StringPrefsEnum.facebookProfilePhoto);

  int _selectedAvatarIcon = 1;
  //int _currentAvatarIcon = 1;

  bool _processingSelection = false;

  Future<File> _imageFromCamera;
  Future<File> _imageFromGallery;

  CachedNetworkImage facebookProfileImage;

  @override
  Widget build(BuildContext context) {
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

      _radioImageTypeSelection = _SelectedImageTypeEnum.facebookProfilePic;
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
                  : Padding(
                      padding: const EdgeInsets.only(top: 0.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        mainAxisSize: MainAxisSize.max,
                        children: <Widget>[
                          // Padding(
                          //   padding: const EdgeInsets.only(top: 0.0),
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
                          //         child: const  Icon(FontAwesomeIcons.circle,
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
                                    (facebookProfileImage == null)
                                        ? Container()
                                        : Row(
                                            children: <Widget>[
                                              Container(
                                                margin: const EdgeInsets.only(
                                                    left: 20, right: 10),
                                                height: 30,
                                                width: 30,
                                                decoration: BoxDecoration(
                                                  color: _radioImageTypeSelection ==
                                                          _SelectedImageTypeEnum
                                                              .facebookProfilePic
                                                      ? Colors.green
                                                      : Colors.grey[350],
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Radio<
                                                    _SelectedImageTypeEnum>(
                                                  activeColor: Colors.white,
                                                  value: _SelectedImageTypeEnum
                                                      .facebookProfilePic,
                                                  materialTapTargetSize:
                                                      MaterialTapTargetSize
                                                          .padded,
                                                  groupValue:
                                                      _radioImageTypeSelection,
                                                  onChanged:
                                                      _handleRadioValueChange,
                                                ),
                                              ),
                                              FlatButton(
                                                onPressed: () {
                                                  setState(() {
                                                    _handleRadioValueChange(
                                                        _SelectedImageTypeEnum
                                                            .facebookProfilePic,
                                                        forceOpen: true);
                                                  });
                                                },
                                                child: ClipRRect(
                                                  child: facebookProfileImage,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12.0),
                                                ),
                                              ),
                                            ],
                                          ),
                                    Row(
                                      children: <Widget>[
                                        Container(
                                          margin: const EdgeInsets.only(
                                              left: 20, right: 10),
                                          height: 30,
                                          width: 30,
                                          decoration: BoxDecoration(
                                            color: _radioImageTypeSelection ==
                                                    _SelectedImageTypeEnum
                                                        .avatar
                                                ? Colors.green
                                                : Colors.grey[350],
                                            shape: BoxShape.circle,
                                          ),
                                          child: Radio<_SelectedImageTypeEnum>(
                                            activeColor: Colors.white,
                                            value:
                                                _SelectedImageTypeEnum.avatar,
                                            materialTapTargetSize:
                                                MaterialTapTargetSize.padded,
                                            groupValue:
                                                _radioImageTypeSelection,
                                            onChanged: _handleRadioValueChange,
                                          ),
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
                                        Container(
                                          margin: const EdgeInsets.only(
                                              left: 20, right: 10),
                                          height: 30,
                                          width: 30,
                                          decoration: BoxDecoration(
                                            color: _radioImageTypeSelection ==
                                                    _SelectedImageTypeEnum
                                                        .fromCamera
                                                ? Colors.green
                                                : Colors.grey[350],
                                            shape: BoxShape.circle,
                                          ),
                                          child: Radio<_SelectedImageTypeEnum>(
                                            activeColor: Colors.white,
                                            value: _SelectedImageTypeEnum
                                                .fromCamera,
                                            materialTapTargetSize:
                                                MaterialTapTargetSize.padded,
                                            groupValue:
                                                _radioImageTypeSelection,
                                            onChanged: _handleRadioValueChange,
                                          ),
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
                                        Container(
                                          margin: const EdgeInsets.only(
                                              left: 20, right: 10),
                                          height: 30,
                                          width: 30,
                                          decoration: BoxDecoration(
                                            color: _radioImageTypeSelection ==
                                                    _SelectedImageTypeEnum
                                                        .fromGallery
                                                ? Colors.green
                                                : Colors.grey[350],
                                            shape: BoxShape.circle,
                                          ),
                                          child: Radio<_SelectedImageTypeEnum>(
                                            activeColor: Colors.white,
                                            value: _SelectedImageTypeEnum
                                                .fromGallery,
                                            materialTapTargetSize:
                                                MaterialTapTargetSize.padded,
                                            groupValue:
                                                _radioImageTypeSelection,
                                            onChanged: _handleRadioValueChange,
                                          ),
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
                                  ],
                                ),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: <Widget>[
                                      Text(
                                        _radioImageTypeSelection ==
                                                _SelectedImageTypeEnum.avatar
                                            ? 'Selected\r\nAvatar'
                                            : 'Selected\r\nImage',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20.0,
                                            fontFamily: 'WorkSansSemiBold'),
                                      ),
                                      const Padding(
                                        padding:
                                           EdgeInsets.only(top: 10.0),
                                      ),
                                      Container(
                                        child: _getPreviewImage(),
                                        color: Colors.white,
                                        height: _previewImageSize + 6,
                                        width: _previewImageSize + 6,
                                        padding: const EdgeInsets.all(6.0),
                                      ),

                                      // const Padding(
                                      //   padding: const EdgeInsets.only(top: 60.0),
                                      // ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.only(bottom: 20.0),
                            child: Container(
                              margin: const EdgeInsets.only(
                                  top: 10.0, bottom: 30.0),
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.all(
                                    Radius.circular(5.0)),
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
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(
                                        vertical: 10.0, horizontal: 20.0),
                                    child: Text(
                                      'Next >',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 25.0,
                                          fontFamily: 'WorkSansBold'),
                                    ),
                                  ),
                                  onPressed: () => _processAndContinue()),
                            ),
                          ),
                        ],
                      ),
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
            setStringPref(
                StringPrefsEnum.displayName, user.displayName);
            setStringPref(StringPrefsEnum.qrCode, user.qrCode);
            setStringPref(StringPrefsEnum.supportCode, user.supportCode);
            setStringPref(
                StringPrefsEnum.qrSecretCode, user.qrSecretCode);
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

    if (widget.doAddUser) {
      // this is for either of the two cases where
      // a user has been added, either for this device
      // or the owner of this device adding other users. In both
      // cases, we should have a valid UserModel variable set
      fileName = user.qrCode.replaceAll('UQR:', '') + '_thumb.jpg';
      // in case we are creating users not for this device
      // make sure we have the correct hash userId
      userId = user.hasherId;
    } else {
      // in the case where we are simply updating the existing
      // profile image of the account associated with this device,
      // use the existing QR code stored in preferences as the base name for the photo
      fileName = getStringPref(StringPrefsEnum.qrCode)
              .replaceAll('UQR:', '') +
          '_thumb.jpg';
    }

    switch (_radioImageTypeSelection) {
      case _SelectedImageTypeEnum.avatar:
        profileImageUrl = 'bundle://Avatar-$_selectedAvatarIcon';
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
      // this is the case where we are adding a user for this device
      // when this code is finished, we want to redirect the user to the
      // main screen
      setStringPref(
          StringPrefsEnum.profilePhotoUrl, profileImageUrl);

      final UpdateProfilePhotoService svc = UpdateProfilePhotoService();
      svc
          .updateProfilePhoto(profileImageUrl, userId)
          .then((SingleResultModel result) {
        if (_radioImageTypeSelection == _SelectedImageTypeEnum.fromCamera) {
          _imageFromCamera.then((File file) {
            _upload(file, fileName);
          });
        } else if (_radioImageTypeSelection ==
            _SelectedImageTypeEnum.fromGallery) {
          _imageFromGallery.then((File file) {
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
      // when this code is done executing, we want to pop back
      // to the caller.
      final UpdateProfilePhotoService svc = UpdateProfilePhotoService();
      svc
          .updateProfilePhoto(profileImageUrl, userId)
          .then((SingleResultModel result) {
        if (_radioImageTypeSelection == _SelectedImageTypeEnum.fromCamera) {
          _imageFromCamera.then((File file) {
            _upload(file, fileName);
          });
        } else if (_radioImageTypeSelection ==
            _SelectedImageTypeEnum.fromGallery) {
          _imageFromGallery.then((File file) {
            _upload(file, fileName);
          });
        }

        Future<dynamic>.delayed(const Duration(milliseconds: 3500))
            .then((void dummy) {
          Navigator.of(context).pop(user);
        });
      });
    } else {
      // this last case will be for updating the profile photo
      // of the user of this device, but without creating a
      // user
      final UpdateProfilePhotoService svc = UpdateProfilePhotoService();
      svc
          .updateProfilePhoto(profileImageUrl, userId)
          .then((SingleResultModel result) {
        if (_radioImageTypeSelection == _SelectedImageTypeEnum.fromCamera) {
          _imageFromCamera.then((File file) {
            _upload(file, fileName);
          });
        } else if (_radioImageTypeSelection ==
            _SelectedImageTypeEnum.fromGallery) {
          _imageFromGallery.then((File file) {
            _upload(file, fileName);
          });
        }
      });
    }
  }

  void _upload(File imageFile, String fileName) {
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
  }

  Widget _getPreviewImage() {
    Widget returnWidget;
    // if (_selectedAvatarIcon == null)
    // {
    //   _selectedAvatarIcon = 1;
    // }

    switch (_radioImageTypeSelection) {
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
      _radioImageTypeSelection = value;
      switch (_radioImageTypeSelection) {
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
      ImagePicker.pickImage(source: source).then((File image) {
        setState(() {
          final Future<File> img = ImageCropper.cropImage(
            sourcePath: image.path,
            ratioX: 1.0,
            ratioY: 1.0,
            maxWidth: 512,
            maxHeight: 512,
          );

          if (_radioImageTypeSelection == _SelectedImageTypeEnum.fromCamera) {
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
        future: (_radioImageTypeSelection == _SelectedImageTypeEnum.fromCamera)
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
