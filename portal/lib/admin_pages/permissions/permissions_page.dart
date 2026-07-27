import 'package:hcportal/imports.dart';

/// Super-admin editor for the GLOBAL permission defaults.
/// (Per-kennel overrides are set in each kennel's editor.)
class PermissionsPage extends StatelessWidget {
  const PermissionsPage({super.key});

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
        title: const Text('Permissions — Global Defaults'),
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
                          child: CircularProgressIndicator(strokeWidth: 2))
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Obx(() => DropdownButtonFormField<int>(
                        initialValue: controller.selectedGrantorId.value,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Role / flag',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                        items: data.grantors
                            .map((g) => DropdownMenuItem<int>(
                                  value: g.id,
                                  child: Text(
                                      '${g.displayName}  ·  ${g.typeLabel}',
                                      overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) controller.selectGrantor(v);
                        },
                      )),
                ),
                const Divider(height: 1),
                Expanded(
                  child: _GlobalChecklist(controller: controller, data: data),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _GlobalChecklist extends StatelessWidget {
  const _GlobalChecklist({required this.controller, required this.data});

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
          child: Text(f.featureArea.toUpperCase(),
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: Color(0xFF6B7280))),
        ));
      }
      rows.add(Obx(() => CheckboxListTile(
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
            value: controller.checks[f.id] ?? false,
            onChanged: (v) => controller.toggle(f.id, v ?? false),
            title: Text(f.displayName),
            subtitle: f.hareScoped
                ? const Text('Also granted to a run’s hare',
                    style:
                        TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)))
                : null,
          )));
    }
    return ListView(
        padding: const EdgeInsets.only(bottom: 24), children: rows);
  }
}
