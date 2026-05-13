// lib/bindings/initial_bindings.dart

import 'package:harrier_central/imports.dart';

// InitialBindings is used in hasher_profile_page.dart as a Bindings argument.
// dependencies() is intentionally empty — services are registered via services_init.dart
// at app startup. If additional lazy-put registrations are needed, add them here.
class InitialBindings extends Bindings {
  @override
  void dependencies() {}
}
