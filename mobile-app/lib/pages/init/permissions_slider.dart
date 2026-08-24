import 'package:harrier_central/imports.dart';

// NOTE: The PODFILE needs to include the following lines for
// Permissions_handler to work properly

// post_install do |installer|
//   installer.pods_project.targets.each do |target|
//     flutter_additional_ios_build_settings(target)
//     target.build_configurations.each do |config|
//       config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '10.0'

//       # You can remove unused permissions here
//       # for more infomation: https://github.com/BaseflowIT/flutter-permission-handler/blob/master/permission_handler/ios/Classes/PermissionHandlerEnums.h
//       # e.g. when you don't need camera permission, just add 'PERMISSION_CAMERA=0'
//       config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
//         '$(inherited)',
//         ## dart: PermissionGroup.calendar
//         'PERMISSION_EVENTS=0',
//         ## dart: PermissionGroup.reminders
//         'PERMISSION_REMINDERS=0',
//         ## dart: PermissionGroup.contacts
//         'PERMISSION_CONTACTS=0',
//         ## dart: PermissionGroup.camera
//         'PERMISSION_CAMERA=1',
//         ## dart: PermissionGroup.microphone
//         'PERMISSION_MICROPHONE=0',
//         ## dart: PermissionGroup.speech
//         'PERMISSION_SPEECH_RECOGNIZER=1',
//         ## dart: PermissionGroup.photos
//         'PERMISSION_PHOTOS=1',
//         ## dart: [PermissionGroup.location, PermissionGroup.locationAlways, PermissionGroup.locationWhenInUse]
//         'PERMISSION_LOCATION=1',
//         ## dart: PermissionGroup.notification
//         'PERMISSION_NOTIFICATIONS=1',
//         ## dart: PermissionGroup.mediaLibrary
//         'PERMISSION_MEDIA_LIBRARY=1',
//         ## dart: PermissionGroup.sensors
//         'PERMISSION_SENSORS=1',
//         ## dart: PermissionGroup.bluetooth
//         'PERMISSION_BLUETOOTH=0',
//         ## dart: PermissionGroup.appTrackingTransparency
//         'PERMISSION_APP_TRACKING_TRANSPARENCY=0',
//         ## dart: PermissionGroup.criticalAlerts
//         'PERMISSION_CRITICAL_ALERTS=0',
//       ]
//      end
//   end
// end

class PermissionSliderPage extends StatefulWidget {
  const PermissionSliderPage({super.key});

  @override
  PermissionSliderPageState createState() => PermissionSliderPageState();
}

class PermissionSliderPageState extends State<PermissionSliderPage> {
  List<ContentConfig> slides = <ContentConfig>[];

  late TextStyle titleStyle;

  late TextStyle descriptionStyle;

  late TextStyle navStyle;

  late Function _goToTab;

  @override
  void initState() {
    super.initState();

    descriptionStyle = TextStyle(
      color: Colors.black,
      fontSize: 24.0 * deviceInfo.deviceWidthScaleFactor,
      fontFamily: 'AvenirNextRegular',
    );
    titleStyle = TextStyle(
      color: Colors.black,
      fontSize: 32.0 * deviceInfo.deviceWidthScaleFactor,
      fontFamily: 'AvenirNextRegular',
    );
    navStyle = TextStyle(
      color: themeAppBarBackground,
      fontSize: 18.0 * deviceInfo.deviceWidthScaleFactor,
      fontFamily: 'AvenirNextDemiBold',
    );

    slides.add(
      ContentConfig(
        title: 'Let us know where you are!',
        maxLineTitle: 2,
        styleTitle: titleStyle,
        description: 'This lets us find the Hash events closest to you',
        styleDescription: descriptionStyle,
        pathImage: 'images/init/intro/intro_phone_location.png',
        heightImage: 140 * deviceInfo.deviceMaxScaleFactor,
        colorBegin: const Color.fromARGB(255, 230, 203, 203),
        colorEnd: const Color.fromARGB(255, 230, 203, 203),
        directionColorBegin: Alignment.topRight,
        directionColorEnd: Alignment.bottomLeft,
      ),
    );

    slides.add(
      ContentConfig(
        title: 'Smile for the camera!',
        maxLineTitle: 2,
        styleTitle: titleStyle,
        description:
            'Can we access your camera for your profile photo and to scan QR codes?',
        styleDescription: descriptionStyle,
        pathImage: 'images/init/intro/intro_old_camera.png',
        heightImage: 120 * deviceInfo.deviceMaxScaleFactor,
        colorBegin: const Color.fromARGB(255, 222, 215, 252),
        colorEnd: const Color.fromARGB(255, 222, 215, 252),
        directionColorBegin: Alignment.topRight,
        directionColorEnd: Alignment.bottomLeft,
      ),
    );

    slides.add(
      ContentConfig(
        title: 'Keep up to date',
        maxLineTitle: 2,
        styleTitle: titleStyle,
        description:
            'Let us notify you about changes to runs you are following',
        styleDescription: descriptionStyle,
        pathImage: 'images/init/intro/intro_notification.png',
        heightImage: 150 * deviceInfo.deviceMaxScaleFactor,
        colorBegin: const Color.fromARGB(255, 252, 212, 212),
        colorEnd: const Color.fromARGB(255, 252, 212, 212),
        directionColorBegin: Alignment.topRight,
        directionColorEnd: Alignment.bottomLeft,
      ),
    );

    slides.add(
      ContentConfig(
        title: 'Some Last\r\nDetails',
        maxLineTitle: 2,
        styleTitle: titleStyle,
        description:
            'Please Provide Just a Tiny Bit of Personal Information...',
        styleDescription: descriptionStyle,
        pathImage: 'images/init/intro/intro_pen.png',
        heightImage: 150 * deviceInfo.deviceMaxScaleFactor,
        colorBegin: const Color.fromARGB(255, 227, 227, 227),
        colorEnd: const Color.fromARGB(255, 227, 227, 227),
        directionColorBegin: Alignment.topRight,
        directionColorEnd: Alignment.bottomLeft,
      ),
    );
  }

  Future<void> _onDonePress() async {
    await Navigator.of(
      context,
    ).pushReplacementNamed(RouteNames.ACCOUNT_QUESTION.toString());
  }

  bool permission1requested = false;
  bool permission2requested = false;
  bool permission3requested = false;

  int activeTab = 0;

  void _onTabChangeCompleted(num index) {
    // NOTE: Checking the tab versus the index is done
    // to catch cases where the GestureDetector on the
    // 'Allow' button does not fire properly. This is
    // a bit of a hack, but should guarantee that
    // permissions are always requested. The real way to
    // fix this would be to find out why the GestureDetctor
    // on the 'Allow' button is not consistently firing.
    // if (activeTab != index) {
    //   _requestPermissions();
    //   //activeTab = index;
    // }
  }

  Widget _renderNextBtn() {
    return GestureDetector(
      child: Text('Allow', style: navStyle),
      onTap: () async {
        await _requestPermissions();
      },
    );
  }

  bool _permissionRequestInProgress = false;

  Future<void> _requestPermissions() async {
    if (!_permissionRequestInProgress) {
      _permissionRequestInProgress = true;
      if (activeTab == 0) {
        final PermissionStatus ps = await Permission.location.request();

        if (ps.isGranted) {
          if (await Permission.location.serviceStatus.isEnabled) {
            appModel.hasLocationPermissions = true;
            if (!Get.isRegistered<LocationService>()) Get.put(LocationService());
            //await Utilities.subscribeToGeoLocationStream();
          }
        } else {
          appModel.hasLocationPermissions = false;
        }

        activeTab = 1;
        _goToTab(1);
      } else if (activeTab == 1) {
        await Permission.camera.request().isGranted;
        await Future<void>.delayed(const Duration(milliseconds: 1000));
        await Permission.photos.request().isGranted;

        activeTab = 2;
        _goToTab(2);
      } else if (activeTab == 2) {
        // final NotificationSupport notifications = NotificationSupport();
        // // ignore: unawaited_futures
        // await notifications.configureNotifications(false);

        await _requestNotificationPermission();

        activeTab = 3;
        _goToTab(3);
      }
      _permissionRequestInProgress = false;
    }
  }

  Future<void> _requestNotificationPermission() async {
    // FirebaseMessaging messaging = FirebaseMessaging.instance;

    // await messaging.requestPermission(
    //   alert: true,
    //   badge: true,
    //   sound: true,
    // );

    if (Firebase.apps.isNotEmpty && !Get.isRegistered<NotificationService>()) {
      await Get.putAsync<NotificationService>(() => NotificationService().init());
    }

    // NotificationSettings settings = await messaging.requestPermission(
    //   alert: true,
    //   badge: true,
    //   sound: true,
    // );

    // if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    //   print('User granted permission');
    // } else {
    //   print('User declined or has not accepted permission');
    // }
  }

  Widget _renderDoneBtn() {
    return Text('OK', style: navStyle);
  }

  Widget _renderSkipBtn() {
    return Text('Skip', style: navStyle);
  }

  Future<void> _onSkipPress() async {
    if (activeTab == 0) {
      await Utilities.showAlert(
        'Location Preference',
        'if you do not allow Harrier Central to detect your location the app will not be able to find the closest Hash runs along with other important features.',
        'Allow',
        showCancelButton: true,
        cancelButtonText: 'Disallow',
      ).then((bool? allow) async {
        if (allow ?? false) {
          if (await Permission.locationWhenInUse.request().isGranted) {
            if (!Get.isRegistered<LocationService>()) Get.put(LocationService());
            //await Utilities.subscribeToGeoLocationStream();
            _goToTab(1);
          }
        } else {
          _goToTab(1);
        }
      });
    }

    if (activeTab == 1) {
      await Utilities.showAlert(
        'Camera Preference',
        'if you do not allow Harrier Central to access your camera you will not be able to scan QR codes to check in to runs or take a profile photo.',
        'Allow',
        showCancelButton: true,
        cancelButtonText: 'Disallow',
      ).then((bool? allow) async {
        if (allow ?? false) {
          if (await Permission.camera.request().isGranted) {
            if (await Permission.photos.request().isGranted) {
              _goToTab(2);
            }
          }
        } else {
          _goToTab(2);
        }
      });
    }

    if (activeTab == 2) {
      await Utilities.showAlert(
        'Notification Preference',
        'if you do not allow Harrier Central to send notification you will not be alerted when details of upcomign runs change',
        'Allow',
        showCancelButton: true,
        cancelButtonText: 'Disallow',
      ).then((bool? allow) async {
        if (allow ?? false) {
          // final NotificationSupport notifications = NotificationSupport();
          // await notifications.configureNotifications(false);
        }
        _goToTab(3);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return IntroSlider(
      // Android 15/16 edge-to-edge: lift the nav row above the system
      // navigation area, keeping the slide background full-bleed.
      navigationBarConfig: NavigationBarConfig(
        padding: EdgeInsets.only(
          top: 10,
          bottom: 10 + MediaQuery.of(context).viewPadding.bottom,
        ),
      ),
      // List slides
      listContentConfig: slides,

      // Skip button
      renderSkipBtn: _renderSkipBtn(),

      skipButtonStyle: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith<Color>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.pressed)) {
            return const Color(0xff000000);
          }
          return const Color(0xffffffff);
        }),
        backgroundColor: WidgetStateProperty.resolveWith<Color>((
          Set<WidgetState> states,
        ) {
          return const Color(0x00000000);
        }),
      ),

      onSkipPress: _onSkipPress,

      //showSkipBtn: true,
      onTabChangeCompleted: _onTabChangeCompleted,

      // // Dot indicator
      // showDotIndicator: true,
      // colorDot: themeAppBarBackground40,
      // colorActiveDot: themeAppBarBackground,
      // sizeDot: 6.0,

      // // Show or hide status bar
      // hideStatusBar: true,

      // Indicator
      indicatorConfig: IndicatorConfig(
        sizeIndicator: 10,
        indicatorWidget: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: themeAppBarBackground40,
          ),
        ),
        activeIndicatorWidget: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: themeAppBarBackground,
          ),
        ),
        spaceBetweenIndicator: 10,
        typeIndicatorAnimation: TypeIndicatorAnimation.sliding,
      ),

      // Next button
      renderNextBtn: _renderNextBtn(),
      nextButtonStyle: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith<Color>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.pressed)) {
            return const Color(0xff000000);
          }
          return const Color(0xffffffff);
        }),
        backgroundColor: WidgetStateProperty.resolveWith<Color>((
          Set<WidgetState> states,
        ) {
          return const Color(0x00000000);
        }),
      ),

      // Done button
      renderDoneBtn: _renderDoneBtn(),
      onDonePress: _onDonePress,
      doneButtonStyle: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith<Color>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.pressed)) {
            return const Color(0xff000000);
          }
          return const Color(0xffffffff);
        }),
        backgroundColor: WidgetStateProperty.resolveWith<Color>((
          Set<WidgetState> states,
        ) {
          return const Color(0x00000000);
        }),
      ),

      refFuncGoToTab: (dynamic refFunc) {
        _goToTab = refFunc;
      },
    );
  }
}
