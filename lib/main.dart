import 'package:harrier_central/imports.dart';
import 'package:get/get.dart';

// Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   print("Handling background message: ${message.messageId}");
// }

void setupFirebaseListeners() {
  // FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  //   print('Got a message while in the foreground!');
  //   print('Message data: ${message.data}');
  // });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    _handleNotificationClick(message);
  });
}

void _handleNotificationClick(RemoteMessage message) {
  // final data = message.data;
  // print(data);
  // final screen = data['screen'];

  // if (screen == 'chat' && data['chatId'] != null) {
  //   Get.to(() => ChatPage(chatId: data['chatId']));
  // } else if (screen == 'profile') {
  //   Get.to(() => ProfilePage(userId: data['userId']));
  // } else {
  //   // Default fallback
  //   Get.to(() => HomePage());
  // }
}

// Future<String?> getToken() async {
//   String? token = await FirebaseMessaging.instance.getToken();
//   print('FCM Token: $token');
//   return token;
// }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //debugPaintSizeEnabled=true;

  //timeDilation = 4.0;

  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    //DeviceOrientation.landscapeLeft,
    //DeviceOrientation.landscapeRight
  ]);

  await Firebase.initializeApp();

  //FirebaseMessaging messaging = FirebaseMessaging.instance;

  // // Ensure APNs token is set
  // String? apnsToken = await messaging.getAPNSToken();
  // //print("APNs Token: $apnsToken");

  // if (apnsToken != null) {
  //   // Retrieve the FCM token after APNs token is set
  //   String? fcmToken = await messaging.getToken();
  //   print("FCM Token: $fcmToken");
  // } else {
  //   print("Error: APNs token is null");
  // }

  //FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  setupFirebaseListeners();
  //await getToken();

  runApp(
    Phoenix(
      child: GetMaterialApp(
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
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          AppLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const <Locale>[
          Locale('en', 'US'), // English
          Locale('es', 'ES'), // Spanish
          Locale('pt', 'PT'), // Portugese
          Locale('de', 'DE'), // German
          // ... other locales the app supports
        ],
        home: AppEntryPage(),
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
                      borderRadius: BorderRadius.circular(10.0)),
                  textStyle: const TextStyle(color: Colors.white),
                  shadowColor: Colors.transparent,
                  elevation: 0),
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
            scaffoldBackgroundColor: Colors.brown.shade50),
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
