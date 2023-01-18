// @dart=2.11

import 'package:harrier_central/imports.dart';
import 'package:intl/intl.dart';

class ChooseProfileImage extends StatefulWidget {
  const ChooseProfileImage({Key key, @required this.isForThisDevice, @required this.fileNamePrefix, @required this.currentProfileImage, this.popToCaller = true}) : super(key: key);

  final bool isForThisDevice;
  final String fileNamePrefix;
  final String currentProfileImage;
  final bool popToCaller;

  @override
  ChooseProfileImageState createState() => ChooseProfileImageState();
}

enum SelectedImageTypeEnum { none, avatar, fromCamera, fromGallery, fromFacebook, fromNetwork }

class ChooseProfileImageState extends State<ChooseProfileImage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  SelectedImageTypeEnum _imageTypeSelection = SelectedImageTypeEnum.none;
  SelectedImageTypeEnum _previousImageTypeSelection = SelectedImageTypeEnum.none;

  final num _thumbnailSize = 50.0;
  final num _uploadingImageSize = 180.0;

  final String _facebookProfileUrl = getStringPref(StringPrefsEnum.facebookProfilePhoto);

  int _selectedAvatarIcon;

  int _selectedRadioValue;
  int _previouslySelectedRadioValue;

  bool _showCircularProgressIndicator = true;

  Future<File> _imageFromCamera;
  Future<File> _imageFromGallery;
  Future<File> _imageFromFacebook;

  CachedNetworkImage _facebookProfileImage;

  bool _isIos = false;

  @override
  void initState() {
    if ((_facebookProfileImage == null) && widget.isForThisDevice && ((_facebookProfileUrl ?? '').isNotEmpty)) {
      _facebookProfileImage = CachedNetworkImage(
          imageUrl: _facebookProfileUrl,
          //placeholder: HcCircularProgressIndicator(key: Key('yyyyyyy')),
          //errorWidget: const  Icon(Icons.error),
          // placeholder: (BuildContext context, String url) =>
          //     HcCircularProgressIndicator(key: Key('yyyyyyy')),
          // errorWidget: (BuildContext context, String url, Exception error) =>
          //     const  Icon(Icons.error),
          //fadeOutDuration:  Duration(seconds: 1),
          fadeInDuration: const Duration(milliseconds: 0),
          width: _thumbnailSize,
          height: _thumbnailSize,
          fit: BoxFit.fill);

      _imageTypeSelection = SelectedImageTypeEnum.fromFacebook;
    }

    if (widget.currentProfileImage == null) {
      _imageTypeSelection = SelectedImageTypeEnum.none;
    } else if (widget.currentProfileImage.toLowerCase().startsWith('bundle://')) {
      _imageTypeSelection = SelectedImageTypeEnum.avatar;
    } else if (widget.currentProfileImage.toLowerCase().startsWith('http')) {
      _imageTypeSelection = SelectedImageTypeEnum.fromNetwork;
    }

    SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.portraitUp,
    ]);

    super.initState();

    setState(() {
      _showCircularProgressIndicator = false;
    });
  }

  Widget getImageSourceButton({String label, SelectedImageTypeEnum selectedImageType, String iosIcon, String androidIcon, bool disabled = false}) {
    return Container(
      padding: const EdgeInsets.only(right: 10.0, top: 10.0, bottom: 5.0),
      width: 120,
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        color: disabled == true ? Colors.grey[500] : Colors.yellow[100],
        border: Border.all(
          color: Colors.red.shade900,
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
                    activeColor: Colors.red.shade900,
                    value: selectedImageType.index,
                    groupValue: _selectedRadioValue,
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
                    SizedBox(width: G0<DeviceInfo>().deviceWidth, height: G0<DeviceInfo>().deviceHeight),
                    Positioned(
                      top: 25.0,
                      child: Text(
                        'Choose an image source',
                        textAlign: TextAlign.center,
                        style: smallHeadingStyle.copyWith(fontSize: 24.0),
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
                              child: getImageSourceButton(
                                  label: 'Camera', iosIcon: 'images/icons/ios_camera.png', androidIcon: 'images/icons/android_camera.png', selectedImageType: SelectedImageTypeEnum.fromCamera),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: getImageSourceButton(
                                  label: 'Gallery', iosIcon: 'images/icons/ios_gallery.png', androidIcon: 'images/icons/android_gallery.png', selectedImageType: SelectedImageTypeEnum.fromGallery),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              child: getImageSourceButton(label: 'Avatar', iosIcon: 'images/icons/avatar.png', androidIcon: 'images/icons/avatar.png', selectedImageType: SelectedImageTypeEnum.avatar),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: getImageSourceButton(
                                  label: 'Facebook',
                                  iosIcon: 'images/icons/facebook.png',
                                  androidIcon: 'images/icons/facebook.png',
                                  selectedImageType: SelectedImageTypeEnum.fromFacebook,
                                  disabled: _facebookProfileImage == null),
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
                        //clipBehavior: Clip.hardEdge,
                        alignment: AlignmentDirectional.center,
                        children: <Widget>[
                          Container(
                            margin: const EdgeInsets.all(0.0),
                            child: Image.asset('images/other/white_square.jpg', width: 400, height: 400, fit: BoxFit.fitHeight),
                          ),
                          (_imageTypeSelection == SelectedImageTypeEnum.none)
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
                                  // height: 400,
                                  // width: 400,
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
                      child: TextButton(
                        style: TextButton.styleFrom(backgroundColor: _imageTypeSelection == SelectedImageTypeEnum.none ? Colors.grey : Colors.red.shade900),
                        //color: imageTypeSelection == _SelectedImageTypeEnum.none ? Colors.grey : Theme.of(context).accentColor,
                        child: Text('Next', style: textStyleButton),
                        onPressed: () {
                          if (_imageTypeSelection != SelectedImageTypeEnum.none) {
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
          child: FancyDivider(key: Key('13301239'), innerColor: Colors.white),
        ),
        Container(
          color: Colors.white,
          height: _uploadingImageSize + 6,
          width: _uploadingImageSize + 6,
          padding: const EdgeInsets.all(6.0),
          child: _getPreviewImage(),
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
                  color: index.isEven ? Colors.white : Colors.red.shade900,
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
      fileName = '${widget.fileNamePrefix.replaceAll('USC:', '')}_${datetime}_thumb.jpg';
    } else {
      fileName = 'profilePhoto_${Random().nextInt(899999) + 100000}_${datetime}_thumb.jpg';
    }

    switch (_imageTypeSelection) {
      case SelectedImageTypeEnum.none:
        break;
      case SelectedImageTypeEnum.avatar:
        profileImageUrl = 'bundle://avatar-$_selectedAvatarIcon'.toLowerCase();
        break;
      case SelectedImageTypeEnum.fromCamera:
      case SelectedImageTypeEnum.fromGallery:
      case SelectedImageTypeEnum.fromFacebook:
        profileImageUrl = BASE_PROFILE_PHOTOS_URL + fileName;
        break;
      case SelectedImageTypeEnum.fromNetwork:
        profileImageUrl = widget.currentProfileImage;
        break;
    }

    if (_imageTypeSelection == SelectedImageTypeEnum.fromCamera) {
      final File file = await _imageFromCamera;
      _upload(file, fileName);
    } else if (_imageTypeSelection == SelectedImageTypeEnum.fromGallery) {
      final File file = await _imageFromGallery;
      _upload(file, fileName);
    } else if (_imageTypeSelection == SelectedImageTypeEnum.fromFacebook) {
      final File file = await _imageFromFacebook;
      _upload(file, fileName);
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

      final String responseBody = await srv.changeProfilePicture(targetUserId: userId, photo: profileImageUrl);

      if (!responseBody.startsWith(ERROR_PREFIX)) {
        await setStringPref(StringPrefsEnum.profilePhotoUrl, profileImageUrl);
      } else {
        await IveCoreUtilities.showAlert(context, 'Profile photo not updated.',
            'There was a problem updating your profile picture. Please ensure you have a good network connection and try again.\r\n\r\nSorry for the inconvenience!', 'OK');
      }

      await Navigator.pushReplacement<dynamic, dynamic>(
          context,
          MaterialPageRoute<dynamic>(
            builder: (BuildContext context) => const MainNavigationPage(
              promos: <PromoModel>[],
              firstPromoImage: null,
            ),
          ));
    }
  }

  String _upload(File imageFile, String fileName) {
    final Uri uri = Uri.parse(
        'http://harriercentral.blob.core.windows.net/profile-photos/$fileName?st=2018-11-22T07%3A36%3A49Z&se=2028-11-23T07%3A36%3A00Z&sp=rwl&sv=2018-03-28&sr=c&sig=GdHEgSU7Qbp6nEMbOeuxnTjKVVIXw1AImXUff8GPq2U%3D');

    final Request request = Request('PUT', uri);

    final Map<String, String> headers = <String, String>{'content-type': 'image/jpeg', 'x-ms-blob-type': 'BlockBlob'};

    request.headers.addAll(headers);

    request.bodyBytes = imageFile.readAsBytesSync();
    request.send().then((StreamedResponse response) {
      //print('Avatar thumbnail upload response = ${response.statusCode}');
    });

    return uri.toString();
  }

  Widget _getPreviewImage() {
    Widget returnWidget = Image.asset(
      'images/icons/create_profile_photo.png',
    );

    switch (_imageTypeSelection) {
      case SelectedImageTypeEnum.avatar:
        if (_selectedAvatarIcon != null) {
          returnWidget = Image.asset('images/avatars/avatar-$_selectedAvatarIcon.jpg', fit: BoxFit.fill);
        } else if ((widget.currentProfileImage != null) && (widget.currentProfileImage.startsWith('bundle://'))) {
          final String avatarPath = 'images/avatars/${widget.currentProfileImage.replaceAll('bundle://', '')}.jpg';
          returnWidget = Image.asset(avatarPath, fit: BoxFit.fill);
        }
        break;
      case SelectedImageTypeEnum.fromCamera:
        returnWidget = _previewImage();
        break;
      case SelectedImageTypeEnum.fromGallery:
        returnWidget = _previewImage();
        break;
      case SelectedImageTypeEnum.fromFacebook:
        // returnWidget = Container(
        //   constraints: const BoxConstraints(),
        //   child: FittedBox(child: _facebookProfileImage, fit: BoxFit.contain),
        // );
        returnWidget = _previewImage();
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
                Image.asset(('images/avatars/${url.replaceAll('bundle://', '')}.jpg').toLowerCase()),
              ])
            : CachedNetworkImage(
                imageUrl: url,
                //errorWidget: (BuildContext context,String url,Exception error) => const  Icon(Icons.error),
                //errorWidget:  const  Icon(Icons.error),
                fadeInDuration: const Duration(milliseconds: 0),
              );
  }

  void _handleRadioValueChange(SelectedImageTypeEnum value, {bool forceOpen = false}) {
    setState(() {
      _previouslySelectedRadioValue = _selectedRadioValue;
      _selectedRadioValue = value.index;
      _previousImageTypeSelection = _imageTypeSelection;
      _imageTypeSelection = value;
    });

    switch (_imageTypeSelection) {
      case SelectedImageTypeEnum.avatar:
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
                _selectedRadioValue = _previouslySelectedRadioValue;
                _imageTypeSelection = _previousImageTypeSelection;
              });
            }
          });
        }
        break;
      case SelectedImageTypeEnum.fromCamera:
        if (forceOpen || (_imageFromCamera == null)) {
          _getImageFromCameraOrGallery(ImageSource.camera);
        }
        break;
      case SelectedImageTypeEnum.fromGallery:
        if (forceOpen || (_imageFromGallery == null)) {
          _getImageFromCameraOrGallery(ImageSource.gallery);
        }
        break;
      case SelectedImageTypeEnum.fromFacebook:
        if (forceOpen || (_imageFromFacebook == null)) {
          _getImageFromFacebook();
        }
        break;
      default:
        _getImageFromCameraOrGallery(ImageSource.gallery);
        break;
    }
    setState(() {});
  }

  Future<void> _getImageFromFacebook() async {
    if ((_facebookProfileUrl != null) && (_facebookProfileUrl.isNotEmpty)) {
      final Response response = await get(Uri.parse(_facebookProfileUrl));
      final Directory documentDirectory = await getApplicationDocumentsDirectory();
      final File profilePhotoFile = File('${documentDirectory.path}/temp.jpg');
      profilePhotoFile.writeAsBytesSync(response.bodyBytes);

      final ImageCropper ic = ImageCropper();
      final CroppedFile croppedFile = await ic.cropImage(
          sourcePath: profilePhotoFile.path,
          aspectRatio: const CropAspectRatio(ratioX: 1.0, ratioY: 1.0),
          aspectRatioPresets: <CropAspectRatioPreset>[CropAspectRatioPreset.square],
          maxWidth: 300,
          maxHeight: 300,
          compressFormat: ImageCompressFormat.jpg,
          compressQuality: 50);

      final File file = File.fromRawPath(await croppedFile.readAsBytes());
      _imageFromGallery = Future<File>.value(file);

      await _imageFromFacebook;
      setState(() {});
    }
  }

  Future<void> _getImageFromCameraOrGallery(ImageSource source) async {
    final XFile image = await ImagePicker().pickImage(source: source);

    if (image == null) {
      setState(() {
        _selectedRadioValue = _previouslySelectedRadioValue;
        _imageTypeSelection = _previousImageTypeSelection;
      });
    } else {
      final ImageCropper ic = ImageCropper();
      final CroppedFile croppedFile = await ic.cropImage(
          sourcePath: image.path,
          aspectRatio: const CropAspectRatio(ratioX: 1.0, ratioY: 1.0),
          aspectRatioPresets: <CropAspectRatioPreset>[CropAspectRatioPreset.square],
          maxWidth: 300,
          maxHeight: 300,
          compressFormat: ImageCompressFormat.jpg,
          compressQuality: 50);

      // final Uint8List bytes = await croppedFile.readAsBytes();
      // final File file = File.fromRawPath(bytes);

      setState(() {
        if (_imageTypeSelection == SelectedImageTypeEnum.fromCamera) {
          _imageFromCamera = Future<File>.value(File(croppedFile.path));
        } else {
          _imageFromGallery = Future<File>.value(File(croppedFile.path));
        }
      });
    }
  }

  // void _getImageFromCameraOrGallery(ImageSource source) {
  //   setState(() {
  //     ImagePicker().pickImage(source: source).then((XFile image) {
  //       setState(() {
  //         if (image == null) {
  //           setState(() {
  //             _selectedRadioValue = _previouslySelectedRadioValue;
  //             _imageTypeSelection = _previousImageTypeSelection;
  //           });
  //         } else {
  //           final ImageCropper ic = ImageCropper();
  //           final Future<File> img = ic.cropImage(
  //               sourcePath: image.path,
  //               aspectRatio: const CropAspectRatio(ratioX: 1.0, ratioY: 1.0),
  //               aspectRatioPresets: <CropAspectRatioPreset>[CropAspectRatioPreset.square],
  //               maxWidth: 300,
  //               maxHeight: 300,
  //               compressFormat: ImageCompressFormat.jpg,
  //               compressQuality: 50);

  //           if (_imageTypeSelection == SelectedImageTypeEnum.fromCamera) {
  //             _imageFromCamera = img;
  //           } else {
  //             _imageFromGallery = img;
  //           }
  //         }
  //       });
  //     });
  //   });
  // }

  Widget _previewImage() {
    return FutureBuilder<File>(
        future: (_imageTypeSelection == SelectedImageTypeEnum.fromCamera)
            ? _imageFromCamera
            : (_imageTypeSelection == SelectedImageTypeEnum.fromFacebook)
                ? _imageFromFacebook
                : _imageFromGallery,
        builder: (BuildContext context, AsyncSnapshot<File> snapshot) {
          if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
            return Image.file(snapshot.data, fit: BoxFit.fitHeight);
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
