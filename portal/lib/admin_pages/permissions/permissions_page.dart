import 'package:hcportal/imports.dart';

/// Super-admin Permissions Matrix editor (global default + per-kennel overrides).
class PermissionsPage extends StatelessWidget {
  const PermissionsPage({super.key, this.allKennels = const []});

  final List<HasherKennelsModel> allKennels;

  void _ensureController() {
    if (!Get.isRegistered<PermissionsController>()) {
      Get.put(PermissionsController());
    }
  }

  @override
  Widget build(BuildContext context) {
    _ensureController();
    final controller = Get.find<PermissionsController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Permissions'),
        leading: GestureDetector(
          onTap: () => Get.back<void>(),
          child:
              const Icon(MaterialCommunityIcons.arrow_left, color: Colors.black),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Obx(() => TextButton.icon(
                  icon: controller.isSaving.value
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: const Text('Save'),
                  onPressed:
                      (controller.dirty.value && !controller.isSaving.value)
                          ? controller.save
                          : null,
                )),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = controller.matrix.value;
        if (data == null) {
          return const Center(
            child: Text('Could not load the permission matrix.',
                style: TextStyle(color: Color(0xFF6B7280))),
          );
        }
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              children: [
                _ScopePicker(controller: controller, allKennels: allKennels),
                _GrantorPicker(controller: controller, data: data),
                if (controller.isKennelScope)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(
                      'Kennel override — tick = grant, dash = inherit global, cross = revoke.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                  ),
                const Divider(height: 1),
                Expanded(
                    child:
                        _FunctionChecklist(controller: controller, data: data)),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// Scope picker (Global default | a specific kennel)
// ---------------------------------------------------------------------------

class _ScopePicker extends StatelessWidget {
  const _ScopePicker({required this.controller, required this.allKennels});

  final PermissionsController controller;
  final List<HasherKennelsModel> allKennels;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Obx(() => DropdownButtonFormField<String?>(
            initialValue: controller.selectedKennelPublicId.value,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Scope',
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Global default (all kennels)'),
              ),
              ...allKennels.map((k) => DropdownMenuItem<String?>(
                    value: k.publicKennelId,
                    child:
                        Text('${k.kennelName} (override)', overflow: TextOverflow.ellipsis),
                  )),
            ],
            onChanged: (v) => controller.selectScope(v),
          )),
    );
  }
}

// ---------------------------------------------------------------------------
// Grantor (role/flag) picker
// ---------------------------------------------------------------------------

class _GrantorPicker extends StatelessWidget {
  const _GrantorPicker({required this.controller, required this.data});

  final PermissionsController controller;
  final PermissionMatrixData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Obx(() => DropdownButtonFormField<int>(
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
    );
  }
}

// ---------------------------------------------------------------------------
// Function checklist grouped by feature area
// ---------------------------------------------------------------------------

class _FunctionChecklist extends StatelessWidget {
  const _FunctionChecklist({required this.controller, required this.data});

  final PermissionsController controller;
  final PermissionMatrixData data;

  @override
  Widget build(BuildContext context) {
    final functions = [...data.functions]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final rows = <Widget>[];
    String? currentArea;
    for (final f in functions) {
      if (f.featureArea != currentArea) {
        currentArea = f.featureArea;
        rows.add(Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            f.featureArea.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: Color(0xFF6B7280),
            ),
          ),
        ));
      }
      rows.add(Obx(() {
        final v = controller.checks[f.id];
        if (controller.isKennelScope) {
          // Tri-state: 1 grant (checked), -1 revoke (unchecked), null inherit (dash).
          final inheritedText = controller.globalGranted(f.id)
              ? 'inherits: granted'
              : 'inherits: denied';
          final stateText = v == 1
              ? 'Grant (override)'
              : v == -1
                  ? 'Revoke (override)'
                  : 'Inherit — $inheritedText';
          return CheckboxListTile(
            dense: true,
            tristate: true,
            controlAffinity: ListTileControlAffinity.leading,
            value: v == 1 ? true : (v == -1 ? false : null),
            // Explicit cycle: inherit(null) → grant(1) → revoke(-1) → inherit.
            onChanged: (_) => controller.setValue(
                f.id, v == null ? 1 : (v == 1 ? -1 : null)),
            title: Text(f.displayName),
            subtitle: Text(stateText,
                style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
          );
        }
        return CheckboxListTile(
          dense: true,
          controlAffinity: ListTileControlAffinity.leading,
          value: v == 1,
          onChanged: (checked) =>
              controller.setValue(f.id, (checked ?? false) ? 1 : null),
          title: Text(f.displayName),
          subtitle: f.hareScoped
              ? const Text('Also granted to a run’s hare',
                  style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)))
              : null,
        );
      }));
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: rows,
    );
  }
}
