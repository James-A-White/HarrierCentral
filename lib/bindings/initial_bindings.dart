// lib/bindings/initial_bindings.dart

import 'package:harrier_central/imports.dart';

class InitialBindings extends Bindings {
  @override
  void dependencies() {
    // Make it live for the app lifetime
    Get.putAsync<NetworkService>(
      () async => (await NetworkService().init()),
      permanent: true,
    );
  }
}
