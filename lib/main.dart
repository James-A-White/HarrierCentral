import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:harrier_central/pages/init/app_entry_page.dart';
import 'package:harrier_central/util/routes.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:harrier_central/localization.dart';
//import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/rendering.dart';



void main() {
  //debugPaintSizeEnabled=true;
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight
    ]);

  runApp(
    MaterialApp(
        localizationsDelegates: const <LocalizationsDelegate<dynamic>> [
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
        routes: Routes.routes,
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


