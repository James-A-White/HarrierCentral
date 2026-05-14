import 'package:harrier_central/imports.dart';

class AppEntryPage extends StatefulWidget {
  const AppEntryPage({super.key});

  @override
  AppEntryPageState createState() => AppEntryPageState();
}

class AppEntryPageState extends State<AppEntryPage>
    with SingleTickerProviderStateMixin {
  // late AnimationController _iconAnimationController;
  // late CurvedAnimation _iconAnimation;

  var _launchCount = 0;

  /// Show the splash screen on every Nth launch, then hand off to AppBootService.
  Future<void> _runBoot() async {
    if (_launchCount % DISPLAY_SPLASH_ON_LAUNCH == 0) {
      await Future<void>.delayed(
        const Duration(seconds: SPLASH_SCREEN_DISPLAY_TIME),
      );
    }
    await AppBootService().boot();
  }

  @override
  void dispose() {
    // _iconAnimationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _launchCount = getIntPref(IntPrefsEnum.launchCount) ?? 0;
    unawaited(setIntPref(IntPrefsEnum.launchCount, _launchCount + 1));

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await precacheImage(
        const AssetAvifImage('images/backgrounds/hash_foot_background.avif'),
        navigatorKey.currentState!.context,
      );
      await _runBoot();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_launchCount % DISPLAY_SPLASH_ON_LAUNCH == 0) {
      return Image.asset('images/init/splash_screen.jpg');
    }
    return Image.asset('images/init/launcher_background.png');
  }
}
