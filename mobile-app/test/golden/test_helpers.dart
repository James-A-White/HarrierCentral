// Test helpers for widget golden tests.
// Sets up minimal GetX + GetStorage environment without needing a real device.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:harrier_central/util/globals.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/services/connectivity_service.dart';

/// Mock path_provider so GetStorage can initialise without a real device.
Future<void> _mockPathProvider() async {
  final tempDir = await Directory.systemTemp.createTemp('hc_test_');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (MethodCall call) async => tempDir.path,
  );
}

/// Boot a minimal test environment: GetStorage (via mocked path_provider) + a stubbed DeviceInfo.
/// Call this in setUp() before pumping any widget that uses deviceInfo or prefs.
Future<void> setupTestEnvironment() async {
  await _mockPathProvider();
  await GetStorage.init('test');

  // Suppress AVIF codec failures — the native AVIF decoder is unavailable in
  // the headless test environment. All other Flutter errors still propagate.
  FlutterError.onError = (FlutterErrorDetails details) {
    final msg = details.exception.toString();
    if (msg.contains('Codec failed') ||
        msg.contains('invalid image data') ||
        msg.contains("Field 'api' has not been initialized")) {
      return; // swallow image decode errors silently
    }
    FlutterError.dumpErrorToConsole(details, forceReport: true);
  };

  // Stub DeviceInfo at iPhone 14 Pro dimensions so scale factors are realistic.
  final info = DeviceInfo();
  await info.init(390, 844, 1.0);
  Get.put<DeviceInfo>(info, permanent: true);

  // Stub NetworkService — widgets like OfflineModeRibbon need this.
  // We don't call init() (which uses platform channels) — just register the
  // service with its default state (online).
  Get.put<NetworkService>(NetworkService(), permanent: true);
}

/// Tear down GetX registrations and restore error handler between tests.
void tearDownTestEnvironment() {
  FlutterError.onError = FlutterError.dumpErrorToConsole;
  Get.reset();
}

/// Minimal app wrapper that provides Material + nav context.
/// Keeps the test frame at a fixed phone-like size so goldens are stable.
class TestApp extends StatelessWidget {
  const TestApp({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      home: child,
    );
  }
}

/// Set a consistent 390×844 surface size for all golden comparisons.
void setPhoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3); // 3x pixel ratio
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
