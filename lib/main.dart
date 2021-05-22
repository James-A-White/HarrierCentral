import 'package:harrier_central/imports.dart';

//import 'package:flutter/scheduler.dart' show timeDilation;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  //debugPaintSizeEnabled=true;

  //timeDilation = 4.0;

  SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    //DeviceOrientation.landscapeLeft,
    //DeviceOrientation.landscapeRight
  ]);

  initializeGlobals();

  runApp(
    MaterialApp(
        debugShowCheckedModeBanner: false,
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
            primaryColor: Colors.grey[700],
            primaryColorDark: Colors.grey[900],
            primaryColorLight: Colors.grey[400],
            accentColor: Colors.red[900],
            bottomAppBarColor: Colors.grey[700],
            highlightColor: Colors.yellow,
            selectedRowColor: Colors.red[50],
            buttonColor: Colors.red[900],
            iconTheme: const IconThemeData(color: Colors.white, size: 30.0),
            scaffoldBackgroundColor: Colors.brown[50])),
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
