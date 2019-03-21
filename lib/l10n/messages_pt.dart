// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a pt locale. All the
// messages from the main program should be duplicated here with the same
// function name.

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

// ignore: unnecessary_new
final MessageLookup messages = MessageLookup();

// ignore: unused_element
final String _keepAnalysisHappy = Intl.defaultLocale;

// ignore: non_constant_identifier_names
typedef MessageIfAbsent(String message_str, List<String>  args);

class MessageLookup extends MessageLookupByLibrary {
  @override
  get localeName => 'pt';

  @override
  Map<String,dynamic> get messages => _notInlinedMessages(_notInlinedMessages);
  static dynamic _notInlinedMessages(dynamic _) => <String, Function>{
        'hello': MessageLookupByLibrary.simpleMessage('Hello'),
        'kilometers': MessageLookupByLibrary.simpleMessage('quilometros'),
        'title': MessageLookupByLibrary.simpleMessage('Hello world App')
      };
}
