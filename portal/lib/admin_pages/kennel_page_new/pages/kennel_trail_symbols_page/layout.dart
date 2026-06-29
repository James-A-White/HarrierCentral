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
    // On a phone the single horizontal row can't fit the Name + Action fields
    // (they collapse to unusable slivers), so stack the slot vertically.
    final narrow = Get.width < 600;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: narrow ? _buildNarrow(context) : _buildWide(context),
    );
  }

  // Wide: number · purpose · icon · name · action all on one line.
  Widget _buildWide(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _numberBox(),
        const SizedBox(width: 8),
        SizedBox(width: 150, child: _buildPurposeWidget()),
        const SizedBox(width: 8),
        _iconButton(context),
        const SizedBox(width: 8),
        Expanded(flex: 3, child: _nameField()),
        const SizedBox(width: 8),
        Expanded(flex: 2, child: _actionDropdown()),
      ],
    );
  }

  // Narrow (phone): number + icon + purpose on top, then full-width Name and
  // Action fields stacked below so they're usable.
  Widget _buildNarrow(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _numberBox(),
            const SizedBox(width: 8),
            _iconButton(context),
            const SizedBox(width: 12),
            Expanded(child: _buildPurposeWidget()),
          ],
        ),
        const SizedBox(height: 10),
        _nameField(),
        const SizedBox(height: 10),
        _actionDropdown(),
      ],
    );
  }

  Widget _numberBox() {
    return SizedBox(
      width: 28,
      child: Text(
        '${widget.slot.slot}',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        textAlign: TextAlign.center,
      ),
    );
  }

  // Symbol picker button — shows current PNG or empty placeholder.
  Widget _iconButton(BuildContext context) {
    return GestureDetector(
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
    );
  }

  Widget _nameField() {
    return TextField(
      controller: _nameCtrl,
      decoration: const InputDecoration(
        labelText: 'Name',
        isDense: true,
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      onChanged: (_) => _notify(),
    );
  }

  Widget _actionDropdown() {
    return DropdownButtonFormField<String?>(
      value: _selectedAction,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Action',
        isDense: true,
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      items: const [
        DropdownMenuItem(value: null, child: Text('None')),
        DropdownMenuItem(value: 'addText', child: Text('Add Text')),
        DropdownMenuItem(value: 'endRun', child: Text('End Run')),
      ],
      onChanged: (v) {
        setState(() => _selectedAction = v);
        _notify();
      },
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
        HcButton.destructive(
          label: 'Clear slot',
          onPressed: () => Navigator.of(context).pop(''),
        ),
        HcButton.secondary(
          label: 'Cancel',
          onPressed: () => Navigator.of(context).pop(null),
        ),
      ],
    );
  }
}
