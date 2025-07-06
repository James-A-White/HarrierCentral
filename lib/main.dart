import 'package:harrier_central/imports.dart';
import 'package:get/get.dart';

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
    G0<AppModel>().geoLocationStream?.cancel();
    G0<AppModel>().geoLocationStream = null;
    // print('GeoLocation Stream cancelled ($source)');
  }
}

void setupFirebaseListeners() {
  // FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  //   print('Got a message while in the foreground!');
  //   print('Message data: ${message.data}');
  // });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    _handleNotificationClick(message);
  });
}

void _handleNotificationClick(RemoteMessage message) async {
  //await Get.offAll(() => MainNavigationPage());

  Get.until((route) => route.settings.name == '/main');

  final controller = Get.find<FutureRunListPageController>();
  controller.processNotificationClickOnResume(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //debugPaintSizeEnabled=true;

  await initPrefs();

  Get.put(AppLifecycleController()); // register lifecycle-aware controller

  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);

  await Firebase.initializeApp();
  setupFirebaseListeners();

  runApp(
    GetMaterialApp(
      builder: (BuildContext context, Widget? child) {
        final MediaQueryData mediaQueryData = MediaQuery.of(context);
        final TextScaler scale = mediaQueryData.textScaler.clamp(
          minScaleFactor: .8,
          maxScaleFactor: 1.75,
        );
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: scale),
          child: child ?? Container(),
        );
      },
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      // localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
      //   AppLocalizationsDelegate(),
      //   GlobalMaterialLocalizations.delegate,
      //   GlobalWidgetsLocalizations.delegate,
      // ],
      supportedLocales: const <Locale>[
        Locale('en', 'US'), // English
        Locale('es', 'ES'), // Spanish
        Locale('pt', 'PT'), // Portugese
        Locale('de', 'DE'), // German
        // ... other locales the app supports
      ],
      home: AppEntryPage(),

      getPages: [
        GetPage(name: '/main', page: () => MainNavigationPage()),
        // Other routes...
      ],
      routes: routes,
      theme: ThemeData(
        appBarTheme: AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle(
            // Status bar color
            statusBarColor: hc_red,

            // Status bar brightness (optional)
            statusBarIconBrightness:
                Brightness.dark, // For Android (dark icons)
            statusBarBrightness: Brightness.dark, // For iOS (dark icons)
          ),
        ),
        primaryColor: Colors.grey.shade700,
        primaryColorDark: Colors.grey.shade900,
        primaryColorLight: Colors.grey.shade400,
        bottomAppBarTheme: BottomAppBarTheme(color: Colors.grey.shade700),
        highlightColor: Colors.yellow,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: hc_red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            textStyle: const TextStyle(color: Colors.white),
            shadowColor: Colors.transparent,
            elevation: 0,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          //     style: TextButton.styleFrom(
          //   backgroundColor: hc_red,
          //   primary
          //   textStyle: const TextStyle(color: Colors.white),
          // )
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all<Color>(hc_red),
            foregroundColor: WidgetStateProperty.all<Color>(Colors.white),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white, size: 30.0),
        scaffoldBackgroundColor: Colors.brown.shade50,
      ),
    ),
  );
}

// class LoginColors {
//   const LoginColors();

//   static Color loginGradientStart = Colors.grey[400];
//   static Color loginGradientEnd = Colors.blueGrey[900];

//   static final LinearGradient primaryGradient = LinearGradient(
//     colors: <Color>[loginGradientStart, loginGradientEnd],
//     stops: const <double>[0.0, 1.0],
//     begin: Alignment.topCenter,
//     end: Alignment.bottomCenter,
//   );
// }
