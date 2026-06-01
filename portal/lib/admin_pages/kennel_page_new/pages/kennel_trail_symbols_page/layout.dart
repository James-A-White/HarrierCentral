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
  late String? _selectedPurpose;

  @override
  void initState() {
    super.initState();
    _nameCtrl       = TextEditingController(text: widget.slot.name);
    _selectedIcon   = widget.slot.icon;
    _selectedAction = widget.slot.action;
    _selectedPurpose = widget.slot.purpose;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _notify() {
    widget.onChanged(TrailSlotConfig(
      slot:    widget.slot.slot,
      icon:    _selectedIcon,
      name:    _nameCtrl.text.trim(),
      action:  _selectedAction,
      purpose: _selectedPurpose,
    ));
  }

  bool get _isFixed => kFixedSlotPurposes.containsKey(widget.slot.slot);

  Widget _buildPurposeWidget() {
    final slot = widget.slot.slot;
    if (kFixedSlotPurposes.containsKey(slot)) {
      return Text(
        kFixedSlotPurposes[slot]!,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      );
    }
    return DropdownButtonFormField<String?>(
      value: _selectedPurpose,
      isExpanded: true,
      decoration: const InputDecoration(
        isDense: true,
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      items: [
        const DropdownMenuItem<String?>(value: null, child: Text('-- none --')),
        ...kVariableSlotPurposes.map(
          (p) => DropdownMenuItem<String?>(value: p, child: Text(p)),
        ),
      ],
      onChanged: (v) {
        setState(() => _selectedPurpose = v);
        _notify();
      },
    );
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

          // Purpose — fixed text for slots 1–5, dropdown for 6–12
          SizedBox(width: 150, child: _buildPurposeWidget()),
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

          // Name field — plain text for fixed slots, editable for variable slots
          Expanded(
            flex: 3,
            child: _isFixed
                ? Text(_nameCtrl.text, style: const TextStyle(fontSize: 14))
                : TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      isDense: true,
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    onChanged: (_) => _notify(),
                  ),
          ),
          const SizedBox(width: 8),

          // Action — plain text for fixed slots, dropdown for variable slots
          Expanded(
            flex: 2,
            child: _isFixed
                ? Text(
                    switch (_selectedAction) {
                      'addText' => 'Add Text',
                      'endRun'  => 'End Run',
                      _         => 'None',
                    },
                    style: const TextStyle(fontSize: 14),
                  )
                : DropdownButtonFormField<String?>(
                    value: _selectedAction,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Action',
                      isDense: true,
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
        width: 360,
        height: 480,
        child: GridView.count(
          crossAxisCount: 5,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          children: ([...kTrailSymbolLibrary]..sort((a, b) => a.$1.compareTo(b.$1))).map((entry) {
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
      ),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade700,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(''),
          child: const Text('Clear slot'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade700,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
