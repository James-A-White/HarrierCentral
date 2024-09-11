import 'package:harrier_central/imports.dart';
import 'package:get/get.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  //debugPaintSizeEnabled=true;

  //timeDilation = 4.0;

  SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    //DeviceOrientation.landscapeLeft,
    //DeviceOrientation.landscapeRight
  ]);

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
        home: const AppEntryPage(),
        routes: routes,
        theme: ThemeData(
            appBarTheme: const AppBarTheme(
              systemOverlayStyle: SystemUiOverlayStyle(
                // Status bar color
                statusBarColor: Colors.red,

                // Status bar brightness (optional)
                statusBarIconBrightness: Brightness.dark, // For Android (dark icons)
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
                  backgroundColor: Colors.red.shade900,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                  textStyle: const TextStyle(color: Colors.white),
                  shadowColor: Colors.transparent,
                  elevation: 0),
            ),
            textButtonTheme: TextButtonThemeData(
              //     style: TextButton.styleFrom(
              //   backgroundColor: Colors.red.shade900,
              //   primary
              //   textStyle: const TextStyle(color: Colors.white),
              // )
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all<Color>(Colors.red.shade900),
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
