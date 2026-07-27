import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:hcportal/imports.dart';

/// Controller for a single kennel's permission overrides (tagged by
/// publicKennelId so each kennel editor gets its own instance).
class KennelPermissionsController extends GetxController {
  KennelPermissionsController(this.publicKennelId);

  final String publicKennelId;

  final RxBool isLoading = true.obs;
  final RxBool isSaving = false.obs;
  final RxBool dirty = false.obs;
  final Rxn<PermissionMatrixData> matrix = Rxn<PermissionMatrixData>();
  final RxnInt selectedGrantorId = RxnInt();

  /// functionId → override: 1 grant, -1 revoke, null inherit global.
  final RxMap<int, int?> checks = <int, int?>{}.obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(load());
  }

  Future<void> load() async {
    isLoading.value = true;
    final data = await queryPermissionMatrix(publicKennelId: publicKennelId);
    matrix.value = data;
    if (data != null && data.grantors.isNotEmpty) {
      selectGrantor(selectedGrantorId.value ?? data.grantors.first.id);
    }
    isLoading.value = false;
  }

  void selectGrantor(int grantorId) {
    final data = matrix.value;
    if (data == null) return;
    selectedGrantorId.value = grantorId;
    checks.clear();
    for (final f in data.functions) {
      checks[f.id] = data.overrideFor(grantorId, f.id); // 1 / -1 / null
    }
    checks.refresh();
    dirty.value = false;
  }

  bool globalGranted(int functionId) {
    final data = matrix.value;
    final gid = selectedGrantorId.value;
    if (data == null || gid == null) return false;
    return data.isGranted(gid, functionId);
  }

  void setValue(int functionId, int? value) {
    checks[functionId] = value;
    dirty.value = true;
  }

  Future<void> save() async {
    final data = matrix.value;
    final grantorId = selectedGrantorId.value;
    if (data == null || grantorId == null) return;
    final grantor = data.grantors.firstWhereOrNull((g) => g.id == grantorId);
    if (grantor == null) return;

    isSaving.value = true;
    final granted = data.functions
        .where((f) => checks[f.id] == 1)
        .map((f) => f.functionKey)
        .toList();
    final revoked = data.functions
        .where((f) => checks[f.id] == -1)
        .map((f) => f.functionKey)
        .toList();
    final ok = await savePermissionMatrix(
      grantorKey: grantor.grantorKey,
      publicKennelId: publicKennelId,
      grantedKeys: granted,
      revokedKeys: revoked,
    );
    isSaving.value = false;

    if (ok) {
      await load();
      Get.snackbar('Saved', '${grantor.displayName} override updated.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF16A34A),
          colorText: Colors.white,
          duration: const Duration(seconds: 3));
    } else {
      if (kDebugMode) debugPrint('KennelPermissions save failed');
      Get.snackbar('Error', 'Failed to save override. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFDC2626),
          colorText: Colors.white,
          duration: const Duration(seconds: 4));
    }
  }
}

/// Per-kennel permission override editor, embedded in the kennel editor's
/// platform-admin tab. Only meaningful for super-admins with CanManagePermissions.
class KennelPermissionsSection extends StatelessWidget {
  const KennelPermissionsSection({required this.publicKennelId, super.key});

  final String publicKennelId;

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<KennelPermissionsController>(tag: publicKennelId)) {
      Get.put(KennelPermissionsController(publicKennelId), tag: publicKennelId);
    }
    final controller =
        Get.find<KennelPermissionsController>(tag: publicKennelId);

    return Obx(() {
      if (controller.isLoading.value) {
        return const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      final data = controller.matrix.value;
      if (data == null) {
        return const Text('Could not load permissions.',
            style: TextStyle(color: Color(0xFF6B7280)));
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Override the global defaults for this kennel only. Tick = grant, '
            'dash = inherit global, cross = revoke.',
            style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 12),
          Obx(() => DropdownButtonFormField<int>(
                initialValue: controller.selectedGrantorId.value,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Role / flag',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: data.grantors
                    .map((g) => DropdownMenuItem<int>(
                          value: g.id,
                          child: Text('${g.displayName}  ·  ${g.typeLabel}',
                              overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) controller.selectGrantor(v);
                },
              )),
          const SizedBox(height: 8),
          ..._functionRows(controller, data),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Obx(() => ElevatedButton.icon(
                  icon: controller.isSaving.value
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.save),
                  label: const Text('Save override'),
                  onPressed:
                      (controller.dirty.value && !controller.isSaving.value)
                          ? controller.save
                          : null,
                )),
          ),
        ],
      );
    });
  }

  List<Widget> _functionRows(
      KennelPermissionsController controller, PermissionMatrixData data) {
    final functions = [...data.functions]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final rows = <Widget>[];
    String? currentArea;
    for (final f in functions) {
      if (f.featureArea != currentArea) {
        currentArea = f.featureArea;
        rows.add(Padding(
          padding: const EdgeInsets.fromLTRB(0, 12, 0, 4),
          child: Text(f.featureArea.toUpperCase(),
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: Color(0xFF6B7280))),
        ));
      }
      rows.add(Obx(() {
        final v = controller.checks[f.id];
        final inherited =
            controller.globalGranted(f.id) ? 'inherits: granted' : 'inherits: denied';
        final stateText = v == 1
            ? 'Grant (override)'
            : v == -1
                ? 'Revoke (override)'
                : 'Inherit — $inherited';
        return ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          leading: _triStateChip(v),
          // Cycle: inherit (null) → grant (1) → revoke (-1) → inherit.
          onTap: () =>
              controller.setValue(f.id, v == null ? 1 : (v == 1 ? -1 : null)),
          title: Text(f.displayName),
          subtitle: Text(stateText,
              style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
        );
      }));
    }
    return rows;
  }

  /// Tri-state indicator: grant = green + white check, revoke = red X,
  /// inherit = light-blue + small circle.
  Widget _triStateChip(int? state) {
    Color bg;
    Widget child;
    if (state == 1) {
      bg = const Color(0xFF16A34A); // green
      child = const Icon(Icons.check, size: 18, color: Colors.white);
    } else if (state == -1) {
      bg = const Color(0xFFFEE2E2); // light red
      child = const Icon(Icons.close, size: 18, color: Color(0xFFDC2626)); // red X
    } else {
      bg = const Color(0xFFDBEAFE); // light blue
      child = Container(
        width: 7,
        height: 7,
        decoration:
            const BoxDecoration(color: Color(0xFF3B82F6), shape: BoxShape.circle),
      );
    }
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Center(child: child),
    );
  }
}
