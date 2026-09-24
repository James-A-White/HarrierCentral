import 'package:harrier_central/imports.dart';

/// Pops the current page, whatever toast is showing.
///
/// GetX 4.7.3's `Get.back()` carries a compatibility shim: if a GetX
/// snackbar is open it closes the snackbar and RETURNS — no pop. A page that
/// shows "Saved!" with `hcSnack` and then calls `Get.back()` therefore stays
/// on screen, and whatever `isSaving` flag guarded the button never clears.
/// That hung Add Down Down on builds 1397 and 1399 (2026-09-24): the charge
/// was saved, the spinner never stopped.
///
/// Pop through the navigator itself, then show the toast — it draws on the
/// app overlay and survives the pop.
void hcPop<T extends Object?>({T? result}) {
  final NavigatorState? nav = Get.key.currentState;
  if (nav != null && nav.canPop()) nav.pop<T>(result);
}
