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
// Single slot row
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

  Future<void> _pickIcon(BuildContext context) async {
    final picked = await showDialog<String?>(
      context: context,
      builder: (_) => _SymbolPickerDialog(current: _selectedIcon),
    );
    // null return = cancelled; the dialog returns the sentinel '' for "clear"
    if (picked == null) return;
    setState(() => _selectedIcon = picked.isEmpty ? null : picked);
    _notify();
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
          // Slot number
          SizedBox(
            width: 28,
            child: Text(
              '${widget.slot.slot}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),

          // Symbol picker button — shows current PNG or empty placeholder
          GestureDetector(
            onTap: () => _pickIcon(context),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: _selectedIcon != null
                  ? Padding(
                      padding: const EdgeInsets.all(4),
                      child: Image.asset(
                        'images/trail_symbols/$_selectedIcon',
                        fit: BoxFit.contain,
                      ),
                    )
                  : const Icon(Icons.add, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 8),

          // Name field
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

          // Action dropdown
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
                DropdownMenuItem(value: null,      child: Text('None')),
                DropdownMenuItem(value: 'addText', child: Text('Add Text')),
                DropdownMenuItem(value: 'endRun',  child: Text('End Run')),
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

// ---------------------------------------------------------------------------
// Symbol picker dialog — 4-wide grid of all available PNGs
// ---------------------------------------------------------------------------

class _SymbolPickerDialog extends StatelessWidget {
  const _SymbolPickerDialog({this.current});

  final String? current;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Choose a symbol'),
      contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: kTrailSymbolLibrary.map((entry) {
                final icon = entry.$1;
                final isSelected = icon == current;
                return GestureDetector(
                  onTap: () => Navigator.of(context).pop(icon),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.blue.shade100
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? Colors.blue.shade600
                            : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    padding: const EdgeInsets.all(6),
                    child: Image.asset(
                      'images/trail_symbols/$icon',
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(''),
          child: const Text('Clear slot', style: TextStyle(color: Colors.red)),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
