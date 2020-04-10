import 'dart:async';
import 'dart:io' as platform;
import 'dart:math';
import 'dart:ui';

import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:http/http.dart' as http;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';


import 'package:harrier_central/pages/top_level/main_navigation_page.dart';
import 'package:harrier_central/pages/init/avatar_icons_page.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:ive_flutter_core/util/core_utilities.dart';

import 'package:harrier_central/util/styles.dart';
import 'package:harrier_central/util/globals.dart';
import 'package:ive_flutter_core/widgets/fancy_divider.dart';
import 'package:harrier_central/data/hc3_services/hashers_service.dart';
import 'package:harrier_central/util/enums.dart';

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
  _SelectedImageTypeEnum previousImageTypeSelection = _SelectedImageTypeEnum.none;

  final num _thumbnailSize = 50.0;
  final num _uploadingImageSize = 180.0;

  String facebookProfileUrl = getStringPref(StringPrefsEnum.facebookProfilePhoto);

  int _selectedAvatarIcon;

  int selectedRadioValue;
  int previouslySelectedRadioValue;

  bool _showCircularProgressIndicator = true;

  Future<platform.File> _imageFromCamera;
  Future<platform.File> _imageFromGallery;

  CachedNetworkImage facebookProfileImage;

  bool _isIos = false;

  @override
  void initState() {
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

    if (widget.currentProfileImage == null) {
      imageTypeSelection = _SelectedImageTypeEnum.none;
    } else if (widget.currentProfileImage.toLowerCase().startsWith('bundle://')) {
      imageTypeSelection = _SelectedImageTypeEnum.avatar;
    } else if (widget.currentProfileImage.toLowerCase().startsWith('http')) {
      imageTypeSelection = _SelectedImageTypeEnum.fromNetwork;
    }

    SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.portraitUp,
    ]);

    super.initState();

    setState(() {
      _showCircularProgressIndicator = false;
    });
  }

  Widget getImageSourceButton({String label, _SelectedImageTypeEnum selectedImageType, String iosIcon, String androidIcon, bool disabled = false}) {
    return Container(
      padding: const EdgeInsets.only(right: 10.0, top: 10.0, bottom: 5.0),
      width: 120,
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        color: disabled == true ? Colors.grey[500] : Colors.yellow[100],
        border: Border.all(
          color: Theme.of(context).accentColor,
          width: 2, //                   <--- border width here
        ),
      ),
      child: GestureDetector(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Radio<int>(
                    activeColor: Theme.of(context).accentColor,
                    value: selectedImageType.index,
                    groupValue: selectedRadioValue,
                    onChanged: (int dummy) {
                      if (!disabled) {
                        _handleRadioValueChange(selectedImageType, forceOpen: false);
                      }
                    }),
                Expanded(
                  child: Opacity(
                    opacity: disabled ? 0.5 : 1.0,
                    child: Image.asset(
                      _isIos ? iosIcon : androidIcon,
                      width: _thumbnailSize,
                      height: _thumbnailSize,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5.0),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 10.0),
                child: Text(
                  label,
                  style: mediumTextRed.copyWith(fontSize: 20),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
        onTap: () {
          if (!disabled) {
            _handleRadioValueChange(selectedImageType, forceOpen: true);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _isIos = Theme.of(context).platform == TargetPlatform.iOS;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: themeAppBarBackground,
        title: const Text(
          'Choose Profile Image',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: Container(
        //height: MediaQuery.of(context).size.height-200,
        width: MediaQuery.of(context).size.width,
        decoration: Backgrounds.defaultHcBackground(),
        child: Container(
          child: _showCircularProgressIndicator
              ? _buildProgressIndicator()
              : Stack(
                  fit: StackFit.expand,
                  //overflow: Overflow.visible,
                  alignment: AlignmentDirectional.center,
                  children: <Widget>[
                    Container(width: deviceWidth, height: deviceHeight),
                    Positioned(
                      top: 25.0,
                      child: Container(
                        //padding: const EdgeInsets.only(top: 25.0, bottom: 25.0),
                        child: Text(
                          'Choose an image source',
                          textAlign: TextAlign.center,
                          style: smallHeadingStyle.copyWith(fontSize: 24.0),
                        ),
                      ),
                    ),

                    Positioned(
                      top: 60.0,
                      child: Container(
                        padding: const EdgeInsets.only(top: 10, bottom: 30),
                        height: 260,
                        width: 260,
                        child: Stack(
                          alignment: AlignmentDirectional.center,
                          children: <Widget>[
                            Positioned(
                              top: 0,
                              left: 0,
                              child: getImageSourceButton(label: 'Camera', iosIcon: 'images/icons/ios_camera.png', androidIcon: 'images/icons/android_camera.png', selectedImageType: _SelectedImageTypeEnum.fromCamera),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: getImageSourceButton(label: 'Gallery', iosIcon: 'images/icons/ios_gallery.png', androidIcon: 'images/icons/android_gallery.png', selectedImageType: _SelectedImageTypeEnum.fromGallery),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              child: getImageSourceButton(label: 'Avatar', iosIcon: 'images/icons/avatar.png', androidIcon: 'images/icons/avatar.png', selectedImageType: _SelectedImageTypeEnum.avatar),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: getImageSourceButton(label: 'Facebook', iosIcon: 'images/icons/facebook.png', androidIcon: 'images/icons/facebook.png', selectedImageType: _SelectedImageTypeEnum.facebookProfilePic, disabled: facebookProfileImage == null),
                            ),
                          ],
                        ),
                      ),
                    ),

                    Positioned(
                      top: 315,
                      bottom: 90,
                      left: 30,
                      right: 30,
                      child: Stack(
                        fit: StackFit.loose,
                        //overflow: Overflow.clip,
                        alignment: AlignmentDirectional.center,
                        children: <Widget>[
                          Container(
                            margin: const EdgeInsets.all(0.0),
                            child: Image.asset('images/other/white_square.jpg', width: 400, height: 400, fit: BoxFit.fitHeight),
                          ),
                          (imageTypeSelection == _SelectedImageTypeEnum.none)
                              ? Container(
                                  margin: const EdgeInsets.all(6.0),
                                  // Positioned(
                                  // left: 30,
                                  // right: 30,
                                  // child:
                                  child: Image.asset(
                                    'images/icons/create_profile_photo.png',
                                  ),
                                )
                              //,
                              // )
                              : Container(
                                  margin: const EdgeInsets.all(6.0),
                                  // Positioned(
                                  // left: 30,
                                  // right: 30,
                                  // child:
                                  child: _getPreviewImage(),
                                ),
                        ],
                      ),
                    ),

                    Positioned(
                      bottom: 20.0,
                      child: FlatButton(
                        color: imageTypeSelection == _SelectedImageTypeEnum.none ? Colors.grey : Theme.of(context).accentColor,
                        child: const Text('Next'),
                        textColor: Colors.white,
                        onPressed: () {
                          if (imageTypeSelection != _SelectedImageTypeEnum.none) {
                            _processAndContinue();
                          }
                        },
                      ),
                    ),

                    //),
                  ],
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
        const SizedBox(
          height: 20,
          width: 20,
        ),
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
      _showCircularProgressIndicator = true;
    });

    final num startTime = DateTime.now().millisecondsSinceEpoch;
    _prepareAndUploadImageThenContinue(startTime);
  }

  Future<void> _prepareAndUploadImageThenContinue(int startTime) async {
    String profileImageUrl = '';

    String fileName;

    final String datetime = DateFormat('yyyyMMddkkmmss').format(DateTime.now());

    if ((widget.fileNamePrefix != null) && (widget.fileNamePrefix.isNotEmpty)) {
      fileName = widget.fileNamePrefix.replaceAll('USC:', '') + '_${datetime}_thumb.jpg';
    } else {
      fileName = 'profilePhoto_${Random().nextInt(899999) + 100000}_${datetime}_thumb.jpg';
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

      // final Future<dynamic> apiCall =
      //     srv.addEditUser(targetUserId: userId, firstName: '', lastName: '', email: '', hashName: '', photo: profileImageUrl, eventId: GUID_EMPTY, kennelId: GUID_EMPTY, historicalPackRunCount: '', historicalHaringCount: '', historicalCountIsEstimate: false, followKennelOnAddNewUser: 0);

      final Future<dynamic> apiCall = srv.changeProfilePicture(targetUserId: userId, photo: profileImageUrl);

      apiCall.then((void dummy) async {
        setStringPref(StringPrefsEnum.profilePhotoUrl, profileImageUrl);

        Navigator.pushReplacement<dynamic, dynamic>(
            context,
            MaterialPageRoute<dynamic>(
              builder: (BuildContext context) => const MainNavigationPage(),
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
    Widget returnWidget = Image.asset(
      'images/icons/create_profile_photo.png',
    );

    switch (imageTypeSelection) {
      case _SelectedImageTypeEnum.avatar:
        if (_selectedAvatarIcon != null) {
          returnWidget = Image.asset('images/avatars/avatar-$_selectedAvatarIcon.jpg', fit: BoxFit.fill);
        } else if ((widget.currentProfileImage != null) && (widget.currentProfileImage.startsWith('bundle://'))) {
          final String avatarPath = 'images/avatars/${widget.currentProfileImage.replaceAll('bundle://', '')}.jpg';
          returnWidget = Image.asset(avatarPath, fit: BoxFit.fill);
        }
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
        );
        break;

      default:
        if (widget.currentProfileImage.isNotEmpty) {
          returnWidget = getProfilePhoto(widget.currentProfileImage);
        }
    }
    return returnWidget;
  }

  Widget getProfilePhoto(String url) {
    return ((url == null) || (url.isEmpty))
        ? Image.asset(
            'images/icons/create_profile_photo.png',
          )
        : url.contains('bundle://')
            ? Stack(alignment: Alignment.center, children: <Widget>[
                Image.asset(('images/avatars/' + url.replaceAll('bundle://', '') + '.jpg').toLowerCase()),
              ])
            : CachedNetworkImage(
                imageUrl: url,
                //errorWidget: (BuildContext context,String url,Exception error) => const  Icon(Icons.error),
                //errorWidget:  const  Icon(Icons.error),
                fadeInDuration: const Duration(milliseconds: 0),
              );
  }

  void _handleRadioValueChange(_SelectedImageTypeEnum value, {bool forceOpen = false}) {
    setState(() {
      previouslySelectedRadioValue = selectedRadioValue;
      selectedRadioValue = value.index;
      previousImageTypeSelection = imageTypeSelection;
      imageTypeSelection = value;
    });

    switch (imageTypeSelection) {
      case _SelectedImageTypeEnum.avatar:
        if (forceOpen || (_selectedAvatarIcon == null)) {
          Navigator.push<dynamic>(
            context,
            MaterialPageRoute<dynamic>(
              builder: (BuildContext context) => AvatarIconsPage(selectedAvatarIcon: _selectedAvatarIcon),
            ),
          ).then((dynamic onValue) {
            if (onValue != null) {
              setState(() {
                _selectedAvatarIcon = onValue;
              });
            } else {
              setState(() {
                selectedRadioValue = previouslySelectedRadioValue;
                imageTypeSelection = previousImageTypeSelection;
              });
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
    setState(() {});
  }

  void _onImageButtonPressed(ImageSource source) {
    setState(() {
      ImagePicker.pickImage(source: source).then((platform.File image) {
        setState(() {
          if (image == null) {
            setState(() {
              selectedRadioValue = previouslySelectedRadioValue;
              imageTypeSelection = previousImageTypeSelection;
            });
          } else {
            final Future<platform.File> img = ImageCropper.cropImage(
              sourcePath: image.path,
              aspectRatio: const CropAspectRatio(ratioX: 1.0, ratioY: 1.0),
              aspectRatioPresets: <CropAspectRatioPreset>[CropAspectRatioPreset.square],
              maxWidth: 512,
              maxHeight: 512,
            );

            if (imageTypeSelection == _SelectedImageTypeEnum.fromCamera) {
              _imageFromCamera = img;
            } else {
              _imageFromGallery = img;
            }
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
}
