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
            constraints: const BoxConstraints(maxWidth: 920),
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

  // Uniform row height so subtitle / no-subtitle rows keep an even rhythm and
  // the two columns stay aligned.
  static const double _rowHeight = 52;

  @override
  Widget build(BuildContext context) {
    final caps = [...data.capabilities]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final blocks = <Widget>[];

    // Live derived-entry preview (recomputes as capabilities are ticked).
    blocks.add(Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Obx(() {
        controller.checks.length; // subscribe to the working set
        return buildEntryPreview([
          for (final area in data.areas)
            AreaEntry(area.label, _entersLive(area.key, kSurfaceApp),
                _entersLive(area.key, kSurfacePortal)),
        ]);
      }),
    ));

    String? currentArea;
    final pending = <PermissionFunction>[];

    void flushSection() {
      if (pending.isEmpty) return;
      final items = [for (final f in pending) _item(f)];
      pending.clear();
      final grid = <Widget>[];
      for (var i = 0; i < items.length; i += 2) {
        grid.add(Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: items[i]),
            const SizedBox(width: 24),
            Expanded(
                child: i + 1 < items.length ? items[i + 1] : const SizedBox()),
          ],
        ));
      }
      blocks.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: grid),
      ));
    }

    for (final f in caps) {
      if (f.areaKey != currentArea) {
        flushSection();
        currentArea = f.areaKey;
        blocks.add(Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(f.featureArea.toUpperCase(),
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: Color(0xFF6B7280))),
        ));
      }
      pending.add(f);
    }
    flushSection();

    return ListView(
        padding: const EdgeInsets.only(bottom: 24), children: blocks);
  }

  bool _entersLive(String areaKey, int surface) => data.capabilities.any((f) =>
      f.areaKey == areaKey &&
      f.onSurface(surface) &&
      (controller.checks[f.id] ?? false));

  Widget _item(PermissionFunction f) {
    return Obx(() => SizedBox(
          height: _rowHeight,
          child: InkWell(
            onTap: () =>
                controller.toggle(f.id, !(controller.checks[f.id] ?? false)),
            child: Row(
              children: [
                Checkbox(
                  value: controller.checks[f.id] ?? false,
                  onChanged: (v) => controller.toggle(f.id, v ?? false),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(f.displayName,
                          style: const TextStyle(fontSize: 15, height: 1.1)),
                      if (f.hareScoped)
                        const Text('Also granted to a run’s hare',
                            style: TextStyle(
                                fontSize: 11.5,
                                height: 1.05,
                                color: Color(0xFF9CA3AF))),
                      ?surfaceTag(f.surfaces),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}
