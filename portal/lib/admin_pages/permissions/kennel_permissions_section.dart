import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:hcportal/imports.dart';

/// The "View … Admin Tools" entry-gate function for each section. When that gate
/// resolves to denied for the selected grantor, the rest of the section is
/// disabled (you can't do things in an area you can't enter).
const Map<String, String> kSectionGate = <String, String>{
  'Runs & Events': 'enterRunAdmin',
  'Members': 'enterKennelAdmin',
};

/// Controller for a single kennel's permission overrides (tagged by
/// publicKennelId). Edits accumulate across grantors and are flushed by the
/// kennel editor's general Save (see KennelPageFormController.save); this
/// controller has no Save button of its own.
class KennelPermissionsController extends GetxController {
  KennelPermissionsController(this.publicKennelId);

  final String publicKennelId;

  final RxBool isLoading = true.obs;
  final Rxn<PermissionMatrixData> matrix = Rxn<PermissionMatrixData>();
  final RxnInt selectedGrantorId = RxnInt();

  /// Working state for the selected grantor: functionId → 1 grant / -1 revoke /
  /// null inherit.
  final RxMap<int, int?> checks = <int, int?>{}.obs;

  /// Accumulated pending edits across grantors: grantorId → {functionId → value}.
  final Map<int, Map<int, int?>> _edits = <int, Map<int, int?>>{};

  bool get hasPending => _edits.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    unawaited(load());
  }

  Future<void> load() async {
    isLoading.value = true;
    final data = await queryPermissionMatrix(publicKennelId: publicKennelId);
    matrix.value = data;
    _edits.clear();
    if (data != null && data.grantors.isNotEmpty) {
      selectGrantor(selectedGrantorId.value ?? data.grantors.first.id);
    }
    isLoading.value = false;
  }

  void selectGrantor(int grantorId) {
    final data = matrix.value;
    if (data == null) return;
    selectedGrantorId.value = grantorId;
    final edited = _edits[grantorId];
    checks.clear();
    for (final f in data.functions) {
      checks[f.id] =
          edited != null ? edited[f.id] : data.overrideFor(grantorId, f.id);
    }
    checks.refresh();
  }

  bool globalGranted(int functionId) {
    final data = matrix.value;
    final gid = selectedGrantorId.value;
    if (data == null || gid == null) return false;
    return data.isGranted(gid, functionId);
  }

  void setValue(int functionId, int? value) {
    checks[functionId] = value;
    final g = selectedGrantorId.value;
    if (g == null) return;
    _edits[g] = Map<int, int?>.from(checks);
    // Enable the kennel editor's general Save.
    if (Get.isRegistered<KennelPageFormController>()) {
      Get.find<KennelPageFormController>().checkIfFormIsDirty();
    }
  }

  /// Discard pending edits (used by the editor's Undo). Synchronous.
  void discardPending() {
    _edits.clear();
    final g = selectedGrantorId.value;
    if (g != null) selectGrantor(g);
  }

  /// Persist all pending grantor overrides. Called by the general Save.
  Future<bool> savePending() async {
    final data = matrix.value;
    if (data == null) return true;
    var allOk = true;
    for (final entry in _edits.entries) {
      final grantor =
          data.grantors.firstWhereOrNull((g) => g.id == entry.key);
      if (grantor == null) continue;
      final vals = entry.value;
      final granted = data.functions
          .where((f) => vals[f.id] == 1)
          .map((f) => f.functionKey)
          .toList();
      final revoked = data.functions
          .where((f) => vals[f.id] == -1)
          .map((f) => f.functionKey)
          .toList();
      final ok = await savePermissionMatrix(
        grantorKey: grantor.grantorKey,
        publicKennelId: publicKennelId,
        grantedKeys: granted,
        revokedKeys: revoked,
      );
      if (!ok) allOk = false;
    }
    _edits.clear();
    await load();
    if (!allOk) {
      if (kDebugMode) debugPrint('KennelPermissions: some overrides failed');
      Get.snackbar('Error', 'Some permission overrides failed to save.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFDC2626),
          colorText: Colors.white,
          duration: const Duration(seconds: 4));
    }
    return allOk;
  }
}

/// Per-kennel permission override editor, embedded in the kennel editor's
/// platform-admin tab. Saving is driven by the editor's general Save button.
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
            'dash = inherit global, cross = revoke. Changes save with the '
            'general Save button.',
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
      final gateKey = kSectionGate[f.featureArea];
      final isGate = gateKey != null && f.functionKey == gateKey;
      rows.add(Obx(() {
        final v = controller.checks[f.id];
        final inheritedGranted = controller.globalGranted(f.id);
        final stateText = v == 1
            ? 'Grant (override)'
            : v == -1
                ? 'Revoke (override)'
                : 'Inherit — inherits: ${inheritedGranted ? 'granted' : 'denied'}';
        final row = InkWell(
          // Cycle: inherit (null) → grant (1) → revoke (-1) → inherit.
          onTap: () =>
              controller.setValue(f.id, v == null ? 1 : (v == 1 ? -1 : null)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Row(
              children: [
                _triStateChip(v, inheritedGranted),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(f.displayName,
                          style: const TextStyle(fontSize: 19, height: 1.1)),
                      Text(stateText,
                          style: const TextStyle(
                              fontSize: 15,
                              height: 1.05,
                              color: Color(0xFF9CA3AF))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
        // Section gate: if this section's "View … Admin Tools" resolves to
        // denied (revoke, or inherit-denied), dim + disable the rest of it.
        if (gateKey != null && !isGate) {
          final gate =
              data.functions.firstWhereOrNull((x) => x.functionKey == gateKey);
          if (gate != null) {
            final gv = controller.checks[gate.id];
            final gateOpen =
                gv == 1 || (gv == null && controller.globalGranted(gate.id));
            if (!gateOpen) {
              return Opacity(opacity: 0.4, child: IgnorePointer(child: row));
            }
          }
        }
        return row;
      }));
    }
    return rows;
  }

  /// Tri-state indicator: grant = green + bold white check, revoke = deep-red +
  /// white ✕, inherit = mid/dark-grey with a dot coloured by what it inherits
  /// (green = inherits granted, red = inherits denied).
  Widget _triStateChip(int? state, bool inheritedGranted) {
    Color bg;
    Widget child;
    if (state == 1) {
      bg = const Color(0xFF16A34A); // green
      child = const Icon(Icons.check_rounded, size: 20, color: Colors.white);
    } else if (state == -1) {
      bg = const Color(0xFFB91C1C); // deep red
      child = const Icon(Icons.close_rounded, size: 20, color: Colors.white);
    } else {
      bg = const Color(0xFF4B5563); // mid/dark grey
      child = Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: inheritedGranted
              ? const Color(0xFF22C55E) // green — inherits granted
              : const Color(0xFFEF4444), // red — inherits denied
          shape: BoxShape.circle,
        ),
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
