import 'package:harrier_central/imports.dart';
import 'package:intl/intl.dart';

class ChooseProfileImage extends StatefulWidget {
  const ChooseProfileImage({
    super.key,
    required this.isForThisDevice,
    required this.fileNamePrefix,
    this.currentProfileImage,
    this.popToCaller = true,
  });

  final bool isForThisDevice;
  final String fileNamePrefix;
  final String? currentProfileImage;
  final bool popToCaller;

  @override
  ChooseProfileImageState createState() => ChooseProfileImageState();
}

enum SelectedImageTypeEnum {
  none,
  avatar,
  fromCamera,
  fromGallery,
  fromNetwork,
}

class ChooseProfileImageState extends State<ChooseProfileImage> {
  SelectedImageTypeEnum _imageTypeSelection = SelectedImageTypeEnum.none;
  SelectedImageTypeEnum _previousImageTypeSelection =
      SelectedImageTypeEnum.none;

  final double _thumbnailSize = 50.0;
  final double _uploadingImageSize = 180.0;

  int _selectedAvatarIcon = 1;

  int _selectedRadioValue = 0;
  int _previouslySelectedRadioValue = 0;

  bool _showCircularProgressIndicator = true;

  Future<File>? _imageFromCamera;
  Future<File>? _imageFromGallery;

  bool _isIos = false;

  @override
  void initState() {
    super.initState();

    if (widget.currentProfileImage == null) {
      _imageTypeSelection = SelectedImageTypeEnum.none;
    } else if (widget.currentProfileImage!.toLowerCase().startsWith(
      'bundle://',
    )) {
      _imageTypeSelection = SelectedImageTypeEnum.avatar;
    } else if (widget.currentProfileImage!.toLowerCase().startsWith('http')) {
      _imageTypeSelection = SelectedImageTypeEnum.fromNetwork;
    }

    unawaited(
      SystemChrome.setPreferredOrientations(<DeviceOrientation>[
        DeviceOrientation.portraitUp,
      ]),
    );

    setStateIfMounted(() {
      _showCircularProgressIndicator = false;
    });
  }

  Widget getImageSourceButton({
    required String label,
    required SelectedImageTypeEnum selectedImageType,
    required String iosIcon,
    required String androidIcon,
    bool disabled = false,
  }) {
    return Container(
      padding: const EdgeInsets.only(right: 10.0, top: 10.0, bottom: 5.0),
      width: 120,
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        color: disabled == true ? Colors.grey[500] : Colors.yellow[100],
        border: Border.all(color: hc_red, width: 2),
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
                Radio<int>(activeColor: hc_red, value: selectedImageType.index),
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
                  style: ts_regularRed,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
        onTap: () async {
          if (!disabled) {
            await _handleRadioValueChange(selectedImageType, forceOpen: true);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _isIos = Theme.of(context).platform == TargetPlatform.iOS;

    return AppScaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: themeAppBarBackground,
        iconTheme: const IconThemeData(color: Colors.white, size: 28.0),
        title: Text('Choose Profile Image', style: ts_appBarTitle),
      ),
      body: Container(
        width: MediaQuery.sizeOf(context).width,
        decoration: Backgrounds.defaultHcBackground(),
        child: Container(
          child: _showCircularProgressIndicator
              ? _buildProgressIndicator()
              : Stack(
                  fit: StackFit.expand,
                  alignment: AlignmentDirectional.center,
                  children: <Widget>[
                    SizedBox(
                      width: deviceInfo.deviceWidth,
                      height: deviceInfo.deviceHeight,
                    ),
                    Positioned(
                      top: 25.0,
                      child: Text(
                        'Choose an image source',
                        textAlign: TextAlign.center,
                        style: ts_headingLarge,
                      ),
                    ),

                    Positioned(
                      top: 60.0,
                      child: Container(
                        padding: const EdgeInsets.only(top: 10, bottom: 30),
                        height: 260,
                        width: 260,
                        child: RadioGroup(
                          groupValue: _selectedRadioValue,
                          onChanged: (int? value) async {
                            if (value != null) {
                              await _handleRadioValueChange(
                                SelectedImageTypeEnum.values[value],
                                forceOpen: false,
                              );
                            }
                          },

                          child: Stack(
                            alignment: AlignmentDirectional.center,
                            children: <Widget>[
                              Positioned(
                                top: 0,
                                left: 0,
                                child: getImageSourceButton(
                                  label: 'Camera',
                                  iosIcon: 'images/icons/ios_camera.png',
                                  androidIcon:
                                      'images/icons/android_camera.png',
                                  selectedImageType:
                                      SelectedImageTypeEnum.fromCamera,
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: getImageSourceButton(
                                  label: 'Gallery',
                                  iosIcon: 'images/icons/ios_gallery.png',
                                  androidIcon:
                                      'images/icons/android_gallery.png',
                                  selectedImageType:
                                      SelectedImageTypeEnum.fromGallery,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                child: getImageSourceButton(
                                  label: 'Avatar',
                                  iosIcon: 'images/icons/avatar.png',
                                  androidIcon: 'images/icons/avatar.png',
                                  selectedImageType:
                                      SelectedImageTypeEnum.avatar,
                                ),
                              ),
                            ],
                          ),
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
                        alignment: AlignmentDirectional.center,
                        children: <Widget>[
                          Container(
                            margin: const EdgeInsets.all(0.0),
                            child: Image.asset(
                              'images/other/white_square.jpg',
                              width: 400,
                              height: 400,
                              fit: BoxFit.fitHeight,
                            ),
                          ),
                          (_imageTypeSelection == SelectedImageTypeEnum.none)
                              ? Container(
                                  margin: const EdgeInsets.all(6.0),
                                  child: Image.asset(
                                    'images/icons/create_profile_photo.png',
                                  ),
                                )
                              : Container(
                                  margin: const EdgeInsets.all(6.0),
                                  child: _getPreviewImage(),
                                ),
                        ],
                      ),
                    ),

                    Positioned(
                      bottom: 20.0,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          shape: button_shape,
                          backgroundColor:
                              _imageTypeSelection == SelectedImageTypeEnum.none
                              ? Colors.grey
                              : hc_red,
                        ),
                        child: Text('Next', style: ts_button),
                        onPressed: () async {
                          if (_imageTypeSelection !=
                              SelectedImageTypeEnum.none) {
                            await _processAndContinue();
                          }
                        },
                      ),
                    ),
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
        Padding(
          padding: const EdgeInsets.only(top: 20.0),
          child: Text(
            'Uploading\r\nProfile Image',
            textAlign: TextAlign.center,
            style: ts_titleVeryLarge,
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
        const SizedBox(height: 20, width: 20),
        const Center(
          child: HcAppCircularProgressIndicator(key: Key('1387562')),
        ),
      ],
    );
  }

  Future<void> _processAndContinue() async {
    setStateIfMounted(() {
      _showCircularProgressIndicator = true;
    });

    final int startTime = DateTime.now().millisecondsSinceEpoch;
    await _prepareAndUploadImageThenContinue(startTime);
  }

  Future<void> _prepareAndUploadImageThenContinue(int startTime) async {
    String profileImageUrl = '';

    String fileName;

    final String datetime = DateFormat('yyyyMMddkkmmss').format(DateTime.now());

    if (widget.fileNamePrefix.isNotEmpty) {
      fileName =
          '${widget.fileNamePrefix.replaceAll('USC:', '')}_${datetime}_thumb.jpg';
    } else {
      fileName =
          'profilePhoto_${Random().nextInt(899999) + 100000}_${datetime}_thumb.jpg';
    }

    switch (_imageTypeSelection) {
      case SelectedImageTypeEnum.none:
        break;
      case SelectedImageTypeEnum.avatar:
        profileImageUrl = bundledAvatarUrl(_selectedAvatarIcon);
        break;
      case SelectedImageTypeEnum.fromCamera:
      case SelectedImageTypeEnum.fromGallery:
        profileImageUrl = BASE_PROFILE_PHOTOS_URL + fileName;
        break;
      case SelectedImageTypeEnum.fromNetwork:
        if (widget.currentProfileImage != null) {
          profileImageUrl = widget.currentProfileImage!;
        }
        break;
    }

    if (_imageTypeSelection != SelectedImageTypeEnum.fromNetwork) {
      if (_imageTypeSelection == SelectedImageTypeEnum.fromCamera) {
        final File? file = await _imageFromCamera;
        await _upload(file, fileName);
      } else if (_imageTypeSelection == SelectedImageTypeEnum.fromGallery) {
        final File? file = await _imageFromGallery;
        await _upload(file, fileName);
      }

      final int deltaTime = DateTime.now().millisecondsSinceEpoch - startTime;
      if (deltaTime < 1250) {
        await Future<dynamic>.delayed(Duration(milliseconds: 1500 - deltaTime));
      }
    }

    if (widget.popToCaller) {
      if (!mounted) return;
      Navigator.of(context).pop(profileImageUrl);
    } else {
      final String userId = currentUserId;

      final HashersService srv = HashersService();

      final bool updateWasSuccessful = await srv.changeProfilePicture(
        targetUserId: userId,
        photo: profileImageUrl,
      );

      if (updateWasSuccessful) {
        await setStringPref(StringPrefsEnum.profilePhotoUrl, profileImageUrl);
      } else {
        await Utilities.showAlert(
          'Profile photo not updated.',
          'There was a problem updating your profile picture. Please ensure you have a good network connection and try again.\r\n\r\nSorry for the inconvenience!',
          'OK',
        );
      }

      await Get.off(() => MainNavigationPage(), routeName: '/main');
    }
  }

  Future<String> _upload(File? imageFile, String fileName) async {
    if (imageFile != null) {
      final Uri uri = Uri.parse(
        'http://harriercentral.blob.core.windows.net/profile-photos/$fileName?st=2018-11-22T07%3A36%3A49Z&se=2028-11-23T07%3A36%3A00Z&sp=rwl&sv=2018-03-28&sr=c&sig=GdHEgSU7Qbp6nEMbOeuxnTjKVVIXw1AImXUff8GPq2U%3D',
      );

      final Request request = Request('PUT', uri);

      final Map<String, String> headers = <String, String>{
        'content-type': 'image/jpeg',
        'x-ms-blob-type': 'BlockBlob',
      };

      request.headers.addAll(headers);

      request.bodyBytes = imageFile.readAsBytesSync();
      await request.send().then((StreamedResponse response) {});

      return uri.toString();
    }

    return '';
  }

  Widget _getPreviewImage() {
    Widget returnWidget = Image.asset('images/icons/create_profile_photo.png');

    switch (_imageTypeSelection) {
      case SelectedImageTypeEnum.avatar:
        returnWidget = Image.asset(
          'images/avatars/avatar-$_selectedAvatarIcon.jpg',
          fit: BoxFit.fill,
        );
        break;
      case SelectedImageTypeEnum.fromCamera:
      case SelectedImageTypeEnum.fromGallery:
        returnWidget = _previewImage();
        break;

      default:
        if ((widget.currentProfileImage ?? '').isNotEmpty) {
          returnWidget = getProfilePhoto(widget.currentProfileImage!);
        }
    }
    return returnWidget;
  }

  Widget getProfilePhoto(String url) {
    return (url.isEmpty)
        ? Image.asset('images/icons/create_profile_photo.png')
        : url.contains('bundle://')
        ? Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Image.asset(
                ('images/avatars/${url.replaceAll('bundle://', '')}.jpg')
                    .toLowerCase(),
              ),
            ],
          )
        : CachedNetworkImage(
            imageUrl: url,
            fadeInDuration: const Duration(milliseconds: 0),
          );
  }

  Future<void> _handleRadioValueChange(
    SelectedImageTypeEnum value, {
    bool forceOpen = false,
  }) async {
    setStateIfMounted(() {
      _previouslySelectedRadioValue = _selectedRadioValue;
      _selectedRadioValue = value.index;
      _previousImageTypeSelection = _imageTypeSelection;
      _imageTypeSelection = value;
    });

    switch (_imageTypeSelection) {
      case SelectedImageTypeEnum.avatar:
        if (forceOpen) {
          await Navigator.push<dynamic>(
            context,
            MaterialPageRoute<dynamic>(
              builder: (BuildContext context) =>
                  AvatarIconsPage(selectedAvatarIcon: _selectedAvatarIcon),
            ),
          ).then((dynamic onValue) {
            if (onValue != null) {
              setStateIfMounted(() {
                _selectedAvatarIcon = onValue;
              });
            } else {
              setStateIfMounted(() {
                _selectedRadioValue = _previouslySelectedRadioValue;
                _imageTypeSelection = _previousImageTypeSelection;
              });
            }
          });
        }
        break;
      case SelectedImageTypeEnum.fromCamera:
        if (forceOpen || (_imageFromCamera == null)) {
          await _getImageFromCameraOrGallery(ImageSource.camera);
        }
        break;
      case SelectedImageTypeEnum.fromGallery:
        if (forceOpen || (_imageFromGallery == null)) {
          await _getImageFromCameraOrGallery(ImageSource.gallery);
        }
        break;
      default:
        break;
    }
    setStateIfMounted(() {});
  }

  Future<void> _getImageFromCameraOrGallery(ImageSource source) async {
    final XFile? image = await ImagePicker().pickImage(source: source);

    if (image == null) {
      setStateIfMounted(() {
        _selectedRadioValue = _previouslySelectedRadioValue;
        _imageTypeSelection = _previousImageTypeSelection;
      });
    } else {
      final ImageCropper ic = ImageCropper();
      final CroppedFile? croppedFile = await ic.cropImage(
        sourcePath: image.path,
        aspectRatio: const CropAspectRatio(ratioX: 1.0, ratioY: 1.0),
        maxWidth: 300,
        maxHeight: 300,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 50,
      );

      if (croppedFile != null) {
        setStateIfMounted(() {
          if (_imageTypeSelection == SelectedImageTypeEnum.fromCamera) {
            _imageFromCamera = Future<File>.value(File(croppedFile.path));
          } else {
            _imageFromGallery = Future<File>.value(File(croppedFile.path));
          }
        });
      }
    }
  }

  Widget _previewImage() {
    return FutureBuilder<File>(
      future: _imageTypeSelection == SelectedImageTypeEnum.fromCamera
          ? _imageFromCamera
          : _imageFromGallery,
      builder: (BuildContext context, AsyncSnapshot<File> snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.data != null) {
          return Image.file(snapshot.data!, fit: BoxFit.fitHeight);
        } else if (snapshot.error != null) {
          return const Text(
            'Error picking image.',
            textAlign: TextAlign.center,
          );
        } else {
          return Image.asset('images/icons/create_profile_photo.png');
        }
      },
    );
  }
}
