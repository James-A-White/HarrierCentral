import 'package:harrier_central/imports.dart';

class AppEntryPage extends StatefulWidget {
  const AppEntryPage({super.key});

  @override
  AppEntryPageState createState() => AppEntryPageState();
}

class AppEntryPageState extends State<AppEntryPage>
    with SingleTickerProviderStateMixin {
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
  void initState() {
    super.initState();

    _launchCount = getIntPref(IntPrefsEnum.launchCount) ?? 0;
    unawaited(setIntPref(IntPrefsEnum.launchCount, _launchCount + 1));

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await precacheImage(
          const AssetAvifImage('images/backgrounds/hash_foot_background.avif'),
          navigatorKey.currentState!.context,
        );
      } catch (_) {}
      await _runBoot();
    });
  }

  @override
  Widget build(BuildContext context) {
    final String imagePath = (_launchCount % DISPLAY_SPLASH_ON_LAUNCH == 0)
        ? 'images/init/splash_screen.jpg'
        : 'images/init/launcher_background.png';

    // Phone-shaped screens: fill edge-to-edge as always. Wide screens
    // (unfolded Fold, tablets): BoxFit.cover would crop the top/bottom of
    // the art, so contain it on black letterbox bars instead.
    final Size screen = MediaQuery.sizeOf(context);
    final bool isWideScreen = screen.width / screen.height > 0.65;

    return Container(
      color: Colors.black,
      child: Center(
        child: Image.asset(
          imagePath,
          fit: isWideScreen ? BoxFit.contain : BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }
}
