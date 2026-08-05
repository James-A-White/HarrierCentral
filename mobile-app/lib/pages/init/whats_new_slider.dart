// ignore_for_file: constant_identifier_names

import 'package:harrier_central/imports.dart';

/// Which announcement generation this slider presents. Bump it (and the
/// slides) for the next big release; every device whose
/// [StringPrefsEnum.whatsNewSeenVersion] differs sees the slider once on its
/// next normal boot.
const String WHATS_NEW_VERSION = '3.0';

/// One-time "What's New in 3.0" announcement, shown to EXISTING users on
/// their first boot after updating (see the gate in
/// AppBootService._handleExistingUser). Fresh installs never see it — the
/// new-user intro already sells these features, so IntroSliderPage stamps
/// the seen-version on completion.
///
/// Visuals are composed from shipped assets and Material icons — no
/// screenshots, which the removed help system taught us rot as the UI
/// evolves (todos/app.md).
class WhatsNew30SliderPage extends StatelessWidget {
  const WhatsNew30SliderPage({super.key});

  static final TextStyle _titleStyle = TextStyle(
    color: Colors.black,
    fontSize: 32.0 * deviceInfo.deviceWidthScaleFactor,
    fontFamily: 'AvenirNextRegular',
  );
  static final TextStyle _descriptionStyle = TextStyle(
    color: Colors.black,
    fontSize: 24.0 * deviceInfo.deviceWidthScaleFactor,
    fontFamily: 'AvenirNextRegular',
  );
  static final TextStyle _navStyle = TextStyle(
    color: themeAppBarBackground,
    fontSize: 18.0 * deviceInfo.deviceWidthScaleFactor,
    fontFamily: 'AvenirNextDemiBold',
  );

  /// A feature "dial": big icon in a ringed circle, echoing the compass and
  /// radar dials the slides are describing.
  Widget _dial(IconData icon, Color color) {
    final double size = 150 * deviceInfo.deviceMaxScaleFactor;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: color, width: 6),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Icon(icon, size: size * 0.58, color: color),
    );
  }

  /// The app icon with a "3.0" badge for the welcome slide.
  Widget _appIconWithBadge() {
    final double size = 140 * deviceInfo.deviceMaxScaleFactor;
    return SizedBox(
      width: size * 1.25,
      height: size * 1.15,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(size * 0.22),
            child: Image.asset(
              'images/other/hc_app_icon.png',
              width: size,
              height: size,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: themeAppBarBackground,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: Text(
                '3.0',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24.0 * deviceInfo.deviceWidthScaleFactor,
                  fontFamily: 'AvenirNextDemiBold',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  ContentConfig _slide({
    required String title,
    required String description,
    required Widget centre,
    required Color background,
  }) {
    return ContentConfig(
      title: title,
      maxLineTitle: 2,
      styleTitle: _titleStyle,
      description: description,
      styleDescription: _descriptionStyle,
      centerWidget: centre,
      colorBegin: background,
      colorEnd: background,
      directionColorBegin: Alignment.topRight,
      directionColorEnd: Alignment.bottomLeft,
    );
  }

  List<ContentConfig> _slides() => <ContentConfig>[
    _slide(
      title: 'Welcome to\r\nHarrier Central 3.0',
      description:
          'The biggest update ever — live trail tracking, run photos, '
          'Down Downs and more.\r\n\r\nSwipe to see what\'s new. On-On!',
      centre: _appIconWithBadge(),
      background: const Color.fromARGB(255, 227, 227, 227),
    ),
    _slide(
      title: 'Watch the\r\nPack Live',
      description:
          'PackTrack puts the whole run on a live map — hares lay marks in '
          'the app, the pack lights up as they run, and every trail can be '
          'replayed afterwards.',
      centre: _dial(Icons.route, Colors.green.shade700),
      background: const Color.fromARGB(255, 172, 255, 161),
    ),
    _slide(
      title: 'Lost?\r\nNot Anymore.',
      description:
          'The Lost Compass points you back to the trail and steers you '
          'onto it — and if you need help, one tap tells the pack exactly '
          'where you are.',
      centre: _dial(Icons.navigation, hc_blue),
      background: const Color.fromARGB(255, 143, 234, 255),
    ),
    _slide(
      title: 'Introducing the\r\nHash Flash',
      description:
          'Snap photos on trail and at circle. The Hash Flash reviews and '
          'shares the best — relive the run in the gallery and right on the '
          'trail map.',
      centre: _dial(Icons.photo_camera, Colors.purple.shade600),
      background: const Color.fromARGB(255, 234, 195, 255),
    ),
    _slide(
      title: 'Down Downs,\r\nDigitised',
      description:
          'Charges, songs, and who drank what — make charges at circle, '
          'pick the song, and the record lives on in the run\'s history.',
      centre: _dial(Icons.sports_bar, Colors.orange.shade800),
      background: const Color.fromARGB(255, 255, 244, 210),
    ),
    _slide(
      title: 'Your Run Day,\r\nSorted',
      description:
          'Arrive at the start and the app offers to check you in. RSVP in '
          'a tap, chat with the pack, and get the news that matters.',
      centre: _dial(Icons.where_to_vote, Colors.red.shade700),
      background: const Color.fromARGB(255, 255, 190, 180),
    ),
  ];

  Future<void> _finish() async {
    await setStringPref(
      StringPrefsEnum.whatsNewSeenVersion,
      WHATS_NEW_VERSION,
    );
    await Get.off(() => MainNavigationPage(), routeName: '/main');
  }

  @override
  Widget build(BuildContext context) {
    return IntroSlider(
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
      listContentConfig: _slides(),
      renderSkipBtn: Text('Skip', style: _navStyle),
      onSkipPress: _finish,
      renderNextBtn: Text('Next', style: _navStyle),
      renderDoneBtn: Text('On-On!', style: _navStyle),
      onDonePress: _finish,
    );
  }
}
