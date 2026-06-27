part of '../../kennel_page_new_ui.dart';

class KennelTrailTypesTabContent extends StatelessWidget {
  const KennelTrailTypesTabContent({required this.controller, super.key});

  final KennelPageFormController controller;

  @override
  Widget build(BuildContext context) {
    return Lockable(
      lockState: controller.tabLocked[KennelTabType.trailTypes.index],
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HelperWidgets().categoryLabelWidget('Trail Types'),
              const SizedBox(height: 4),
              const Text(
                'The trails runners pick from when tracking, and filter by on the '
                'run map. Rename or hide the built-in five, or add your own. '
                '"Normal" can be renamed but never hidden — it is the default for '
                'runners who don\'t pick a trail.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 12),
              Obx(() => Column(
                    children: controller.trailTypes
                        .map((t) => _TrailTypeRow(
                              key: ValueKey(t.value),
                              type: t,
                              onChanged: controller.updateTrailType,
                              onDelete: t.value >= kCustomTrailValueStart
                                  ? () => controller.deleteTrailType(t.value)
                                  : null,
                            ))
                        .toList(),
                  )),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: controller.addCustomTrailType,
                icon: const Icon(Icons.add),
                label: const Text('Add custom trail type'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Single trail-type row
// ---------------------------------------------------------------------------

class _TrailTypeRow extends StatefulWidget {
  const _TrailTypeRow({
    required this.type,
    required this.onChanged,
    this.onDelete,
    super.key,
  });

  final TrailTypeConfig type;
  final void Function(TrailTypeConfig) onChanged;
  final VoidCallback? onDelete;

  @override
  State<_TrailTypeRow> createState() => _TrailTypeRowState();
}

class _TrailTypeRowState extends State<_TrailTypeRow> {
  late TextEditingController _labelCtrl;
  late TextEditingController _emojiCtrl;
  late bool _hidden;

  bool get _isNormal => widget.type.value == kNormalTrailValue;

  @override
  void initState() {
    super.initState();
    _labelCtrl = TextEditingController(text: widget.type.label);
    _emojiCtrl = TextEditingController(text: widget.type.emoji);
    _hidden = widget.type.hidden;
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _emojiCtrl.dispose();
    super.dispose();
  }

  void _notify() {
    widget.onChanged(TrailTypeConfig(
      value: widget.type.value,
      label: _labelCtrl.text.trim(),
      emoji: _emojiCtrl.text.trim(),
      hidden: _hidden,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _hidden ? Colors.grey.shade200 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          // Stable value (id)
          SizedBox(
            width: 36,
            child: Text(
              '${widget.type.value}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),

          // Emoji
          SizedBox(
            width: 60,
            child: TextField(
              controller: _emojiCtrl,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                labelText: 'Emoji',
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              ),
              onChanged: (_) => _notify(),
            ),
          ),
          const SizedBox(width: 8),

          // Label
          Expanded(
            child: TextField(
              controller: _labelCtrl,
              decoration: const InputDecoration(
                labelText: 'Label',
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              onChanged: (_) => _notify(),
            ),
          ),
          const SizedBox(width: 8),

          // Hidden toggle — Normal can never be hidden.
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Hide', style: TextStyle(fontSize: 11)),
              Switch(
                value: _hidden,
                onChanged: _isNormal
                    ? null
                    : (v) {
                        setState(() => _hidden = v);
                        _notify();
                      },
              ),
            ],
          ),

          // Delete — customs only.
          if (widget.onDelete != null)
            IconButton(
              tooltip: 'Delete',
              icon: Icon(Icons.delete_outline, color: Colors.red.shade600),
              onPressed: widget.onDelete,
            ),
        ],
      ),
    );
  }
}
