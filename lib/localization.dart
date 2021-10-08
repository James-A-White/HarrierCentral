// @dart=2.11

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:harrier_central/l10n/messages_all.dart';
import 'package:intl/intl.dart';

class AppLocalizations {
  static Future<AppLocalizations> load(Locale locale) {
    final String name = locale.countryCode.isEmpty ? locale.languageCode : locale.toString();
    final String localeName = Intl.canonicalizedLocale(name);

    return initializeMessages(localeName).then((bool _) {
      Intl.defaultLocale = localeName;
      return AppLocalizations();
    });
  }

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  String get title {
    return Intl.message('Hello world App', name: 'title', desc: 'The application title');
  }

  String get hello {
    return Intl.message('Hello', name: 'hello');
  }

  String get kilometers {
    return Intl.message('Kilometers', name: 'kilometers');
  }

  String get meters {
    return Intl.message('Meters', name: 'meters');
  }

  String get miles {
    return Intl.message('Miles', name: 'miles');
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return <String>['en', 'es', 'pt', 'de'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return AppLocalizations.load(locale);
  }

  @override
  bool shouldReload(LocalizationsDelegate<AppLocalizations> old) {
    return false;
  }
}
