import 'package:harrier_central/imports.dart';
import 'package:harrier_central/firebase_options.dart';

// this prevents exceptions being thrown on iOS when
// the app is in the background and location services
// is not set to Always Allow.
class AppLifecycleController extends SuperController<void> {
  /// Breadcrumb the app-level lifecycle transition, but ONLY while a live run is
  /// being tracked. A kill that happens here (backgrounded during tracking) is
  /// the prime suspect for a PackTrack native crash — iOS background-location
  /// watchdog or OOM — which leaves no Dart stack. Staying silent when not
  /// tracking keeps ordinary backgrounding out of the capped harvest log.
  void _trackingLifecycleBreadcrumb(String phase) {
    if (Get.isRegistered<LocationService>() &&
        Get.find<LocationService>().joinRunTracking.value) {
      BootLogger.logBreadcrumb(
        'App lifecycle -> $phase (run tracking ACTIVE) ${BootLogger.memInfo()}',
      );
    }
  }

  @override
  void onPaused() {
    _trackingLifecycleBreadcrumb('paused');
  }

  @override
  void onDetached() {
    _trackingLifecycleBreadcrumb('detached');
  }

  @override
  void onInactive() {
    _trackingLifecycleBreadcrumb('inactive');
  }

  @override
  void onResumed() {
    _trackingLifecycleBreadcrumb('resumed');
    // Re-register LocationService if it was deleted while the app was paused.
    if (!Get.isRegistered<LocationService>()) {
      Get.put(LocationService());
    }
    if (Get.isRegistered<ChatPageController>()) {
      final chatPageController = Get.find<ChatPageController>();
      unawaited(chatPageController.onAppResumed()); // Call your method safely
    }
  }

  @override
  void onHidden() {
    _trackingLifecycleBreadcrumb('hidden');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Capture Flutter framework errors (widget build failures, assertion errors, etc.)
  final FlutterExceptionHandler? originalFlutterError = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    BootLogger.logError('[ERROR][FLUTTER]', details.exception, details.stack);
    originalFlutterError?.call(details);
  };

  // Capture uncaught async/platform errors that escape the Flutter framework
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    BootLogger.logError('[ERROR][ASYNC]', error, stack);
    return false; // let the platform continue its default handling
  };

  // One-time platform/bootstrap. Phones are portrait-only; tablets (iPad,
  // unfolded foldables) rotate freely — see FormFactor.
  await SystemChrome.setPreferredOrientations(FormFactor.preferredOrientations);

  // ✅ Keep top status bar visible
  // 🚫 Hide the bottom navigation bar (Android only)
  // iOS: Debug/Release-Info.plist now ship UIStatusBarHidden=false so the bar
  // is visible from the first frame and this call is a no-op there. It used to
  // be hidden for the splash and re-shown here — on iOS 26 that re-show does
  // NOT update the safe-area inset (flutter/flutter#175520), so on iPad the
  // status bar was drawn over the app bar until the first rotation.
  await SystemChrome.setEnabledSystemUIMode(
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

  // Firebase must be initialised before initServices() so that the
  // Firebase.apps.isNotEmpty guards in services_init and the navigation
  // controllers actually pass. NotificationService.init() also calls
  // Firebase.initializeApp() but it is never reached without this bootstrap.
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // App-level init — safe to re-run on an in-app “restart”
  await initPrefs(); // if services read prefs during init()
  await initServices(); // GetX DI registration (see services_init.dart)

  runApp(RestartWidget(key: restartKey, child: RootApp()));
}

class RootApp extends StatelessWidget {
  const RootApp({super.key});

  @override
  Widget build(BuildContext context) {
    //print('Building RootApp...');
    return GetMaterialApp(
      themeMode: ThemeMode.light, // ✅ force light mode
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
      supportedLocales: const <Locale>[Locale('en', 'US')],
      home: AppEntryPage(),
      getPages: [
        GetPage(name: '/main', page: () => MainNavigationPage()),
        // ...other routes
      ],
      //initialBinding: InitialBindings(), // controllers, etc.
      routes: routes,
      theme: ThemeData(
        useMaterial3: false, // ✅ disable M3 dynamic surfaces
        appBarTheme: AppBarTheme(
          surfaceTintColor:
              Colors.transparent, // ✅ fix grey overlay on Android 12+
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
