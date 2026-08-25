import 'package:harrier_central/imports.dart';

/// Where the onboarding flow hands off to when it completes (or when there
/// is nothing to show).
enum OnboardingDestination {
  /// Guest "Create your free account or Log In" → account search.
  findMyAccount,

  /// Post-authorization first run and auth-recovery paths → the
  /// "Do you already have an account?" branch point.
  accountQuestion,
}

/// One slide in the onboarding PageView. Permission pages carry a
/// [permissionRequest] plus the skip-warning copy; plain intro slides don't.
class OnboardingSlide {
  OnboardingSlide({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.imageHeight,
    required this.backgroundColor,
    this.permissionRequest,
    this.skipWarningTitle,
    this.skipWarningText,
  });

  final String title;
  final String description;
  final String imagePath;
  final double imageHeight;
  final Color backgroundColor;

  /// Requests the page's permission(s). Null for plain intro slides.
  final Future<void> Function()? permissionRequest;
  final String? skipWarningTitle;
  final String? skipWarningText;

  bool get isPermissionPage => permissionRequest != null;
}

/// Replaces the retired `intro_slider` package (edge-to-edge inset bugs,
/// stale maintenance) with a plain PageView the app fully controls.
///
/// The flow is assembled per launch:
///  - intro slides only if this device has never completed them
///    ([BoolPrefsEnum.introSliderSeen]);
///  - each permission page only if that permission is not already granted;
///  - if nothing needs showing, we navigate straight to the destination.
class OnboardingFlowController extends GetxController {
  OnboardingFlowController({
    required this.slides,
    required this.destination,
  });

  final List<OnboardingSlide> slides;
  final OnboardingDestination destination;

  final PageController pageController = PageController();
  final RxInt currentPage = 0.obs;

  bool _requestInProgress = false;

  OnboardingSlide get activeSlide => slides[currentPage.value];
  bool get isLastPage => currentPage.value == slides.length - 1;

  /// Intro slides swipe freely; permission pages advance only via the
  /// Allow / Skip buttons so a request can never be swiped past.
  ScrollPhysics get physics => activeSlide.isPermissionPage
      ? const NeverScrollableScrollPhysics()
      : const ClampingScrollPhysics();

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }

  /// Entry point. Builds the needed page list and either shows the flow or
  /// jumps straight to [destination] when there is nothing left to show.
  static Future<void> start(OnboardingDestination destination) async {
    final List<OnboardingSlide> slides = <OnboardingSlide>[];

    if (!(getBoolPref(BoolPrefsEnum.introSliderSeen) ?? false)) {
      slides.addAll(_introSlides());
    }
    slides.addAll(await _neededPermissionSlides());

    if (slides.isEmpty) {
      await _navigateToDestination(destination, replaceRoute: false);
      return;
    }

    Get.delete<OnboardingFlowController>(force: true);
    final OnboardingFlowController controller = Get.put(
      OnboardingFlowController(slides: slides, destination: destination),
    );
    await Get.to<void>(
      () => const OnboardingFlowPage(),
      routeName: '/onboarding',
    );
    // Reached via back-navigation without completing — drop the controller.
    if (Get.isRegistered<OnboardingFlowController>() &&
        Get.find<OnboardingFlowController>() == controller) {
      Get.delete<OnboardingFlowController>(force: true);
    }
  }

  Future<void> onPageChanged(int index) async {
    currentPage.value = index;
    await _markIntroSeenIfComplete(index);
  }

  /// Right-hand button: "Next" on intro slides, "Allow" on permission pages,
  /// "OK" on the final page.
  Future<void> onPrimaryPressed() async {
    if (_requestInProgress) return;
    _requestInProgress = true;
    try {
      final OnboardingSlide slide = activeSlide;
      if (slide.isPermissionPage) {
        await slide.permissionRequest!();
      }
      await _advance();
    } finally {
      _requestInProgress = false;
    }
  }

  /// Left-hand button: on intro slides, Skip jumps to the LAST intro slide
  /// (classic intro-slider behavior) rather than advancing one page.
  /// Permission pages first warn (matching the retired slider's behavior),
  /// then advance regardless — onboarding is never gated on a permission.
  Future<void> onSkipPressed() async {
    final OnboardingSlide slide = activeSlide;
    if (!slide.isPermissionPage) {
      final int lastIntroIndex =
          slides.lastIndexWhere((OnboardingSlide s) => !s.isPermissionPage);
      if (lastIntroIndex > currentPage.value) {
        await pageController.animateToPage(
          lastIntroIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        await _advance();
      }
      return;
    }
    final bool? allow = await Utilities.showAlert(
      slide.skipWarningTitle ?? 'Are you sure?',
      slide.skipWarningText ?? '',
      'Allow',
      showCancelButton: true,
      cancelButtonText: 'Disallow',
    );
    if (allow ?? false) {
      await slide.permissionRequest!();
    }
    await _advance();
  }

  Future<void> _advance() async {
    if (isLastPage) {
      await _complete();
      return;
    }
    await pageController.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _complete() async {
    await setBoolPref(BoolPrefsEnum.introSliderSeen, true);
    await _navigateToDestination(destination, replaceRoute: true);
  }

  /// The intro is "seen" once the user reaches its final slide (or any
  /// permission page beyond it).
  Future<void> _markIntroSeenIfComplete(int index) async {
    if (getBoolPref(BoolPrefsEnum.introSliderSeen) ?? false) return;
    final int lastIntroIndex =
        slides.lastIndexWhere((OnboardingSlide s) => !s.isPermissionPage);
    if (lastIntroIndex >= 0 && index >= lastIntroIndex) {
      await setBoolPref(BoolPrefsEnum.introSliderSeen, true);
    }
  }

  static Future<void> _navigateToDestination(
    OnboardingDestination destination, {
    required bool replaceRoute,
  }) async {
    final Widget page = switch (destination) {
      OnboardingDestination.findMyAccount => const FindMyAccountPage(),
      OnboardingDestination.accountQuestion => const AccountQuestionPage(),
    };
    if (replaceRoute) {
      await Get.off<void>(() => page);
    } else {
      await Get.to<void>(() => page);
    }
  }

  // ── Slide definitions ────────────────────────────────────────────────

  static List<OnboardingSlide> _introSlides() {
    return <OnboardingSlide>[
      OnboardingSlide(
        title: 'Welcome to Harrier Central',
        description: 'The World\'s Best Way to Manage Your Hash Life',
        imagePath: 'images/other/hc_app_icon.png',
        imageHeight: 120,
        backgroundColor: const Color.fromARGB(255, 227, 227, 227),
      ),
      OnboardingSlide(
        title: 'Discover Hash Runs',
        description:
            'Instantly Find Hash Runs Around the Corner or Across the Globe!',
        imagePath: 'images/init/intro/intro_map.png',
        imageHeight: 120,
        backgroundColor: const Color.fromARGB(255, 172, 255, 161),
      ),
      OnboardingSlide(
        title: 'Your Run History',
        description: 'Track Your Run Counts Across all Hash Kennels',
        imagePath: 'images/init/intro/intro_run_counts.png',
        imageHeight: 170,
        backgroundColor: const Color.fromARGB(255, 234, 195, 255),
      ),
      OnboardingSlide(
        title: 'Easy\nHash Cash',
        description:
            'With new ways to pay for the Hash, you\'ll never fumble for cash again',
        imagePath: 'images/init/intro/intro_cash.png',
        imageHeight: 140,
        backgroundColor: const Color.fromARGB(255, 255, 244, 210),
      ),
      OnboardingSlide(
        title: 'Built for\nMis-Management',
        description:
            'Powerful Tools Designed to Make It Easier to Manage Your Kennel',
        imagePath: 'images/init/intro/intro_admin_tools.png',
        imageHeight: 100,
        backgroundColor: const Color.fromARGB(255, 200, 200, 255),
      ),
      OnboardingSlide(
        title: 'Secure Data',
        description:
            'We don\'t Share Your Data with *Anyone* Outside of Harrier Central',
        imagePath: 'images/init/intro/intro_data_security.png',
        imageHeight: 140,
        backgroundColor: const Color.fromARGB(255, 255, 190, 180),
      ),
      OnboardingSlide(
        title: 'More to Come!',
        description:
            'There are dozens more features designed just for the Hash coming soon!',
        imagePath: 'images/init/intro/intro_rocket.png',
        imageHeight: 150,
        backgroundColor: const Color.fromARGB(255, 143, 234, 255),
      ),
    ];
  }

  static Future<List<OnboardingSlide>> _neededPermissionSlides() async {
    final List<OnboardingSlide> slides = <OnboardingSlide>[];

    if (!await Permission.location.status.isGranted) {
      slides.add(
        OnboardingSlide(
          title: 'Let us know where you are!',
          description: 'This lets us find the Hash events closest to you',
          imagePath: 'images/init/intro/intro_phone_location.png',
          imageHeight: 140,
          backgroundColor: const Color.fromARGB(255, 230, 203, 203),
          permissionRequest: _requestLocation,
          skipWarningTitle: 'Location Preference',
          skipWarningText:
              'if you do not allow Harrier Central to detect your location '
              'the app will not be able to find the closest Hash runs along '
              'with other important features.',
        ),
      );
    }

    final bool cameraGranted = await Permission.camera.status.isGranted;
    final bool photosGranted = await Permission.photos.status.isGranted;
    if (!cameraGranted || !photosGranted) {
      slides.add(
        OnboardingSlide(
          title: 'Smile for the camera!',
          description:
              'Can we access your camera for your profile photo and to scan QR codes?',
          imagePath: 'images/init/intro/intro_old_camera.png',
          imageHeight: 120,
          backgroundColor: const Color.fromARGB(255, 222, 215, 252),
          permissionRequest: _requestCameraAndPhotos,
          skipWarningTitle: 'Camera Preference',
          skipWarningText:
              'if you do not allow Harrier Central to access your camera you '
              'will not be able to scan QR codes to check in to runs or take '
              'a profile photo.',
        ),
      );
    }

    if (!await Permission.notification.status.isGranted) {
      slides.add(
        OnboardingSlide(
          title: 'Keep up to date',
          description:
              'Let us notify you about changes to runs you are following',
          imagePath: 'images/init/intro/intro_notification.png',
          imageHeight: 150,
          backgroundColor: const Color.fromARGB(255, 252, 212, 212),
          permissionRequest: _requestNotifications,
          skipWarningTitle: 'Notification Preference',
          skipWarningText:
              'if you do not allow Harrier Central to send notifications you '
              'will not be alerted when details of upcoming runs change',
        ),
      );
    }

    return slides;
  }

  static Future<void> _requestLocation() async {
    final PermissionStatus ps = await Permission.location.request();
    if (ps.isGranted) {
      if (await Permission.location.serviceStatus.isEnabled) {
        appModel.hasLocationPermissions = true;
        if (!Get.isRegistered<LocationService>()) Get.put(LocationService());
      }
    } else {
      appModel.hasLocationPermissions = false;
    }
  }

  static Future<void> _requestCameraAndPhotos() async {
    await Permission.camera.request();
    await Future<void>.delayed(const Duration(milliseconds: 1000));
    await Permission.photos.request();
  }

  static Future<void> _requestNotifications() async {
    await Permission.notification.request();
    if (Firebase.apps.isNotEmpty && !Get.isRegistered<NotificationService>()) {
      await Get.putAsync<NotificationService>(
        () => NotificationService().init(),
      );
    }
  }
}
