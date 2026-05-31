part of '../../kennel_page_new_ui.dart';

class KennelTrailSymbolsTabContent extends StatelessWidget {
  const KennelTrailSymbolsTabContent({required this.controller, super.key});

  final KennelPageFormController controller;

  @override
  Widget build(BuildContext context) {
    return Lockable(
      lockState: controller.tabLocked[KennelTabType.trailSymbols.index],
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HelperWidgets().categoryLabelWidget('Trail Symbol Slots'),
              const SizedBox(height: 8),
              Obx(() => Column(
                    children: controller.trailSlots
                        .map((slot) => _TrailSlotRow(
                              key: ValueKey(slot.slot),
                              slot: slot,
                              onChanged: controller.updateTrailSlot,
                            ))
                        .toList(),
                  )),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Single slot row widget
// ---------------------------------------------------------------------------

class _TrailSlotRow extends StatefulWidget {
  const _TrailSlotRow({required this.slot, required this.onChanged, super.key});

  final TrailSlotConfig slot;
  final void Function(TrailSlotConfig) onChanged;

  @override
  State<_TrailSlotRow> createState() => _TrailSlotRowState();
}

class _TrailSlotRowState extends State<_TrailSlotRow> {
  late TextEditingController _nameCtrl;
  late String? _selectedIcon;
  late String? _selectedAction;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.slot.name);
    _selectedIcon = widget.slot.icon;
    _selectedAction = widget.slot.action;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _notify() {
    widget.onChanged(TrailSlotConfig(
      slot: widget.slot.slot,
      icon: _selectedIcon,
      name: _nameCtrl.text.trim(),
      action: _selectedAction,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '${widget.slot.slot}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),

          Expanded(
            flex: 3,
            child: DropdownButtonFormField<String?>(
              value: _selectedIcon,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Symbol',
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('— Empty —', style: TextStyle(color: Colors.grey)),
                ),
                ...kTrailSymbolLibrary.map(
                  (entry) => DropdownMenuItem<String?>(
                    value: entry.$1,
                    child: Text(entry.$2, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
              onChanged: (v) {
                setState(() => _selectedIcon = v);
                _notify();
              },
            ),
          ),
          const SizedBox(width: 8),

          Expanded(
            flex: 3,
            child: TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Name',
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              onChanged: (_) => _notify(),
            ),
          ),
          const SizedBox(width: 8),

          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String?>(
              value: _selectedAction,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Action',
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(value: null,        child: Text('None')),
                DropdownMenuItem(value: 'addText',   child: Text('Add Text')),
                DropdownMenuItem(value: 'endRun',    child: Text('End Run')),
              ],
              onChanged: (v) {
                setState(() => _selectedAction = v);
                _notify();
              },
            ),
          ),
        ],
      ),
    );
  }
}
