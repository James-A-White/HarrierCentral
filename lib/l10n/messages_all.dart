// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that looks up messages for specific locales by
// delegating to the appropriate library.

import 'dart:async';

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';
// ignore: implementation_imports
import 'package:intl/src/intl_helpers.dart';

import 'messages_de.dart' as messages_de;
import 'messages_en.dart' as messages_en;
import 'messages_es.dart' as messages_es;
import 'messages_messages.dart' as messages_messages;
import 'messages_pt.dart' as messages_pt;

typedef LibraryLoader = Future<dynamic> Function();

Map<String, LibraryLoader> _deferredLibraries = <String, LibraryLoader>{
// ignore: unnecessary_new
  'de': () => Future<dynamic>.value(null),
// ignore: unnecessary_new
  'en': () => Future<dynamic>.value(null),
// ignore: unnecessary_new
  'es': () => Future<dynamic>.value(null),
// ignore: unnecessary_new
  'messages': () => Future<dynamic>.value(null),
// ignore: unnecessary_new
  'pt': () => Future<dynamic>.value(null),
};

MessageLookupByLibrary _findExact(String localeName) {
  switch (localeName) {
    case 'de':
      return messages_de.messages;
    case 'en':
      return messages_en.messages;
    case 'es':
      return messages_es.messages;
    case 'messages':
      return messages_messages.messages;
    case 'pt':
      return messages_pt.messages;
    default:
      return null;
  }
}

/// User programs should call this before using [localeName] for messages.
Future<bool> initializeMessages(String localeName) async {
  final String availableLocale = Intl.verifiedLocale(
      localeName, (String locale) => _deferredLibraries[locale] != null,
      onFailure: (dynamic _) => null);
  if (availableLocale == null) {
    // ignore: unnecessary_new
    return Future<bool>.value(false);
  }
  final LibraryLoader lib = _deferredLibraries[availableLocale];
  // ignore: unnecessary_new
  await (lib == null ? Future<bool>.value(false) : lib());
  // ignore: unnecessary_new
  initializeInternalMessageLookup(() => CompositeMessageLookup());
  messageLookup.addLocale(availableLocale, _findGeneratedMessagesFor);
  // ignore: unnecessary_new
  return Future<bool>.value(true);
}

bool _messagesExistFor(String locale) {
  try {
    return _findExact(locale) != null;
  } catch (e) {
    return false;
  }
}

MessageLookupByLibrary _findGeneratedMessagesFor(String locale) {
  final String actualLocale = Intl.verifiedLocale(locale, _messagesExistFor,
      onFailure: (dynamic _) => null);
  if (actualLocale == null) {
    return null;
  }
  return _findExact(actualLocale);
}
