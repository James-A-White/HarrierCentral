import 'package:harrier_central/imports.dart';

// this prevents exceptions being thrown on iOS when
// the app is in the background and location services
// is not set to Always Allow.
class AppLifecycleController extends SuperController<void> {
  @override
  void onPaused() {
    _cancelGeoStream('onPaused');
  }

  @override
  void onDetached() {
    _cancelGeoStream('onDetached');
  }

  @override
  void onInactive() {
    _cancelGeoStream('onInactive');
  }

  @override
  void onResumed() {
    Utilities.subscribeToGeoLocationStream(); // re-subscribe
    if (Get.isRegistered<ChatPageController>()) {
      final chatPageController = Get.find<ChatPageController>();
      chatPageController.onAppResumed(); // Call your method safely
    }
  }

  @override
  void onHidden() {
    _cancelGeoStream('onHidden');
  }

  void _cancelGeoStream(String source) {
    appModel.geoLocationStream?.cancel();
    appModel.geoLocationStream = null;
    // print('GeoLocation Stream cancelled ($source)');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // One-time platform/bootstrap
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);

  // ✅ Keep top status bar visible
  // 🚫 Hide the bottom navigation bar (Android only)
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
  );

  // ✅ Apply the style after a short delay to ensure window attachment
  WidgetsBinding.instance.addPostFrameCallback((_) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        systemNavigationBarColor: themeAppBarBackground,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false, // avoids auto-darkening
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  });

  // App-level init — safe to re-run on an in-app “restart”
  await initPrefs(); // if services read prefs during init()
  await initServices(); // GetX DI registration (see services_init.dart)

  runApp(const RootApp());
}

class RootApp extends StatelessWidget {
  const RootApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      builder: (BuildContext context, Widget? child) {
        final mediaQueryData = MediaQuery.of(context);
        final scale = mediaQueryData.textScaler.clamp(
          minScaleFactor: .8,
          maxScaleFactor: 1.75,
        );
        return MediaQuery(
          data: mediaQueryData.copyWith(textScaler: scale),
          child: child ?? const SizedBox.shrink(),
        );
      },
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey, // or Get.key if you prefer
      supportedLocales: const <Locale>[
        Locale('en', 'US'),
        Locale('es', 'ES'),
        Locale('pt', 'PT'),
        Locale('de', 'DE'),
      ],
      home: AppEntryPage(),
      getPages: [
        GetPage(name: '/main', page: () => MainNavigationPage()),
        // ...other routes
      ],
      initialBinding: InitialBindings(), // controllers, etc.
      routes: routes,
      theme: ThemeData(
        appBarTheme: AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
        ),
        primaryColor: Colors.grey,
        primaryColorDark: Colors.black87,
        primaryColorLight: Colors.black45,
        bottomAppBarTheme: const BottomAppBarThemeData(color: Colors.grey),
        highlightColor: Colors.yellow,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: hc_red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: const TextStyle(color: Colors.white),
            shadowColor: Colors.transparent,
            elevation: 0,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStatePropertyAll(hc_red),
            foregroundColor: const WidgetStatePropertyAll(Colors.white),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white, size: 30),
        scaffoldBackgroundColor: Colors.brown.shade50,
      ),
    );
  }
}
