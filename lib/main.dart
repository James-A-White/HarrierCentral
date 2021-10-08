// @dart=2.11
import 'package:harrier_central/imports.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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
      child: MaterialApp(
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
              primaryColor: Colors.grey.shade700,
              primaryColorDark: Colors.grey.shade900,
              primaryColorLight: Colors.grey.shade400,
              bottomAppBarColor: Colors.grey.shade700,
              highlightColor: Colors.yellow,
              selectedRowColor: Colors.red.shade50,
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                    primary: Colors.red.shade900,
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
                  backgroundColor: MaterialStateProperty.all<Color>(Colors.red.shade900),
                  foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
                ),
              ),
              iconTheme: const IconThemeData(color: Colors.white, size: 30.0),
              scaffoldBackgroundColor: Colors.brown.shade50)),
    ),
  );
}

class LoginColors {
  const LoginColors();

  static Color loginGradientStart = Colors.grey[400];
  static Color loginGradientEnd = Colors.blueGrey[900];

  static final LinearGradient primaryGradient = LinearGradient(
    colors: <Color>[loginGradientStart, loginGradientEnd],
    stops: const <double>[0.0, 1.0],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
