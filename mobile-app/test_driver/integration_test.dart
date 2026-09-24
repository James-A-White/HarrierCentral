// Driver for `flutter drive --driver=test_driver/integration_test.dart
// --target=integration_test/<file>.dart`. Its only job is to save the
// screenshots the test takes to integration_test/screenshots/<name>.png.
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final Directory dir = Directory('integration_test/screenshots');
  if (!dir.existsSync()) dir.createSync(recursive: true);
  await integrationDriver(
    onScreenshot: (String name, List<int> bytes, [Map<String, Object?>? args]) async {
      final File file = File('${dir.path}/$name.png');
      file.writeAsBytesSync(bytes);
      return true;
    },
  );
}
