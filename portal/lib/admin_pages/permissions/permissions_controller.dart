import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:hcportal/imports.dart';

/// Super-admin permission matrix editor. Scope = Global default OR a specific
/// kennel override. Pick a grantor (role/flag), toggle its functions, save.
/// Saving recompiles the matrix server-side and delivers it to clients.
class PermissionsController extends GetxController {
  final RxBool isLoading = true.obs;
  final RxBool isSaving = false.obs;
  final Rxn<PermissionMatrixData> matrix = Rxn<PermissionMatrixData>();

  /// Scope: null = Global default; otherwise the kennel's publicKennelId.
  final RxnString selectedKennelPublicId = RxnString();

  /// Currently selected grantor (matrix row).
  final RxnInt selectedGrantorId = RxnInt();

  /// Working state for the selected grantor: functionId → value.
  ///   Global scope:  1 = granted, null = not granted.
  ///   Kennel scope:  1 = grant, -1 = revoke, null = inherit global.
  final RxMap<int, int?> checks = <int, int?>{}.obs;

  final RxBool dirty = false.obs;

  bool get isKennelScope => selectedKennelPublicId.value != null;

  @override
  void onInit() {
    super.onInit();
    unawaited(loadMatrix());
  }

  Future<void> loadMatrix() async {
    isLoading.value = true;
    final data = await queryPermissionMatrix(
      publicKennelId: selectedKennelPublicId.value,
    );
    matrix.value = data;
    if (data != null && data.grantors.isNotEmpty) {
      selectGrantor(selectedGrantorId.value ?? data.grantors.first.id);
    }
    isLoading.value = false;
    if (data == null) _showError('Could not load the permission matrix.');
  }

  /// Change scope (Global = null) and reload for that scope.
  Future<void> selectScope(String? publicKennelId) async {
    selectedKennelPublicId.value = publicKennelId;
    await loadMatrix();
  }

  /// Rebuild the working state for [grantorId] from the loaded data + scope.
  void selectGrantor(int grantorId) {
    final data = matrix.value;
    if (data == null) return;
    selectedGrantorId.value = grantorId;
    checks.clear();
    for (final f in data.functions) {
      checks[f.id] = isKennelScope
          ? data.overrideFor(grantorId, f.id) // 1 / -1 / null
          : (data.isGranted(grantorId, f.id) ? 1 : null);
    }
    checks.refresh();
    dirty.value = false;
  }

  void setValue(int functionId, int? value) {
    checks[functionId] = value;
    dirty.value = true;
  }

  /// The global default for a cell (for showing the inherited state).
  bool globalGranted(int functionId) {
    final data = matrix.value;
    final gid = selectedGrantorId.value;
    if (data == null || gid == null) return false;
    return data.isGranted(gid, functionId);
  }

  Future<void> save() async {
    final data = matrix.value;
    final grantorId = selectedGrantorId.value;
    if (data == null || grantorId == null) return;
    final grantor = data.grantors.firstWhereOrNull((g) => g.id == grantorId);
    if (grantor == null) return;

    isSaving.value = true;
    bool ok;
    if (isKennelScope) {
      final granted = data.functions
          .where((f) => checks[f.id] == 1)
          .map((f) => f.functionKey)
          .toList();
      final revoked = data.functions
          .where((f) => checks[f.id] == -1)
          .map((f) => f.functionKey)
          .toList();
      ok = await savePermissionMatrix(
        grantorKey: grantor.grantorKey,
        publicKennelId: selectedKennelPublicId.value,
        grantedKeys: granted,
        revokedKeys: revoked,
      );
    } else {
      final functionKeys = data.functions
          .where((f) => checks[f.id] == 1)
          .map((f) => f.functionKey)
          .toList();
      ok = await savePermissionMatrix(
        grantorKey: grantor.grantorKey,
        functionKeys: functionKeys,
      );
    }
    isSaving.value = false;

    if (ok) {
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
