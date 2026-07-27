import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:hcportal/imports.dart';

/// Super-admin permission matrix editor: pick a grantor (role/flag), toggle
/// which functions it grants globally, save. Saving recompiles the matrix
/// server-side and delivers it to clients (Permissions V2).
class PermissionsController extends GetxController {
  final RxBool isLoading = true.obs;
  final RxBool isSaving = false.obs;
  final Rxn<PermissionMatrixData> matrix = Rxn<PermissionMatrixData>();

  /// Currently selected grantor (matrix row).
  final RxnInt selectedGrantorId = RxnInt();

  /// Working checkbox state for the selected grantor: functionId → granted.
  final RxMap<int, bool> checks = <int, bool>{}.obs;

  /// True when [checks] differs from what was loaded (enables Save).
  final RxBool dirty = false.obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(loadMatrix());
  }

  Future<void> loadMatrix() async {
    isLoading.value = true;
    final data = await queryPermissionMatrix();
    matrix.value = data;
    if (data != null && data.grantors.isNotEmpty) {
      selectGrantor(selectedGrantorId.value ?? data.grantors.first.id);
    }
    isLoading.value = false;
    if (data == null) {
      _showError('Could not load the permission matrix.');
    }
  }

  /// Load the checkbox state for [grantorId] from the loaded grants.
  void selectGrantor(int grantorId) {
    final data = matrix.value;
    if (data == null) return;
    selectedGrantorId.value = grantorId;
    checks
      ..clear()
      ..addEntries(data.functions
          .map((f) => MapEntry(f.id, data.isGranted(grantorId, f.id))));
    dirty.value = false;
  }

  void toggle(int functionId, bool value) {
    checks[functionId] = value;
    dirty.value = true;
  }

  Future<void> save() async {
    final data = matrix.value;
    final grantorId = selectedGrantorId.value;
    if (data == null || grantorId == null) return;
    final grantor =
        data.grantors.firstWhereOrNull((g) => g.id == grantorId);
    if (grantor == null) return;

    isSaving.value = true;
    final functionKeys = data.functions
        .where((f) => checks[f.id] == true)
        .map((f) => f.functionKey)
        .toList();

    final ok = await savePermissionMatrix(
      grantorKey: grantor.grantorKey,
      functionKeys: functionKeys,
    );
    isSaving.value = false;

    if (ok) {
      // Reload so the grant set reflects what was persisted, keeping selection.
      await loadMatrix();
      Get.snackbar(
        'Saved',
        '${grantor.displayName} permissions updated.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF16A34A),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } else {
      _showError('Failed to save. Please try again.');
    }
  }

  void _showError(String message) {
    if (kDebugMode) debugPrint('PermissionsController error: $message');
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFFDC2626),
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
    );
  }
}
