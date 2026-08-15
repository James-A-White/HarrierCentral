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
              const SizedBox(height: 4),
              const Text(
                'Each mark is a glyph or a short text (up to 7 characters — a '
                'space starts a new line).',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
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
// Trail tile preview — renders a marker the same way the app/web will:
// yellow rounded square, no border, glyph (mono tinted / fixed as-is) or
// stacked text. Shared by the slot row and the glyph picker.
// ---------------------------------------------------------------------------

class TrailTilePreview extends StatelessWidget {
  const TrailTilePreview({required this.slot, this.size = 52, super.key});

  final TrailSlotConfig slot;
  final double size;

  static const Color kYellow = Color(0xFFFCFF04);
  static const Color kInk = Color(0xFF2D0000);
  static const Color kInvertBg = Color(0xFF2D0000);
  static const Color kInvertInk = Color(0xFFFFFDF0);

  @override
  Widget build(BuildContext context) {
    final glyph = slot.kind == 'glyph' ? glyphById(slot.glyphId) : null;
    final fixed = glyph?.fixed ?? false;
    final invert = slot.invert && !fixed; // fixed glyphs ignore invert
    final bg = invert ? kInvertBg : kYellow;
    final ink = invert ? kInvertInk : kInk;

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.13),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(size * 0.2),
      ),
      child: _content(glyph, fixed, ink),
    );
  }

  Widget _content(TrailGlyph? glyph, bool fixed, Color ink) {
    if (slot.kind == 'text') {
      final t = (slot.text ?? '').trim();
      if (t.isEmpty) return const SizedBox.shrink();
      final lines = t.split(' ').where((l) => l.isNotEmpty).toList();
      return FittedBox(
        fit: BoxFit.contain,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final line in lines)
              Text(
                line,
                style: TextStyle(
                  color: ink,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
          ],
        ),
      );
    }
    if (glyph == null) {
      return Icon(Icons.help_outline, color: Colors.grey.shade400);
    }
    return Image.asset(
      glyph.assetPath,
      fit: BoxFit.contain,
      color: fixed ? null : ink, // mono → tint to ink; fixed → full colour
      colorBlendMode: fixed ? null : BlendMode.srcIn,
      errorBuilder: (_, _, _) => Icon(Icons.broken_image, color: ink),
    );
  }
}

// ---------------------------------------------------------------------------
// Text input formatter — cap non-space characters (spaces are line breaks).
// ---------------------------------------------------------------------------

class _MaxNonSpaceFormatter extends TextInputFormatter {
  const _MaxNonSpaceFormatter(this.max);
  final int max;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final nonSpace = newValue.text.replaceAll(' ', '').length;
    return nonSpace > max ? oldValue : newValue;
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
  late TextEditingController _textCtrl;
  late String _kind;
  late String? _glyphId;
  late bool _invert;
  late String? _selectedAction;
  late String? _selectedPurpose;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.slot.name);
    _textCtrl = TextEditingController(text: widget.slot.text ?? '');
    _kind = widget.slot.kind;
    _glyphId = widget.slot.glyphId;
    _invert = widget.slot.invert;
    _selectedAction = widget.slot.action;
    _selectedPurpose = widget.slot.purpose;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  TrailSlotConfig get _current => TrailSlotConfig(
        slot: widget.slot.slot,
        kind: _kind,
        glyphId: _glyphId,
        text: _textCtrl.text,
        invert: _invert,
        name: _nameCtrl.text.trim(),
        action: _selectedAction,
        purpose: _selectedPurpose,
      );

  void _notify() => widget.onChanged(_current);

  bool get _selectedGlyphIsFixed => glyphById(_glyphId)?.fixed ?? false;

  Future<void> _pickGlyph(BuildContext context) async {
    final picked = await showDialog<String?>(
      context: context,
      builder: (_) => _GlyphPickerDialog(current: _glyphId),
    );
    if (picked == null) return; // cancelled
    setState(() => _glyphId = picked.isEmpty ? null : picked);
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Line 1: number · preview · kind toggle · invert
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _numberBox(),
              const SizedBox(width: 8),
              TrailTilePreview(slot: _current, size: 52),
              const SizedBox(width: 12),
              Expanded(child: _kindToggle()),
              _invertToggle(),
            ],
          ),
          const SizedBox(height: 10),
          // Line 2: the glyph picker or the text field
          _kind == 'glyph' ? _glyphPickerButton(context) : _textField(),
          const SizedBox(height: 10),
          // Line 3: name · action · purpose (wraps on narrow)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(width: 220, child: _nameField()),
              SizedBox(width: 150, child: _actionDropdown()),
              SizedBox(width: 170, child: _buildPurposeWidget()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _numberBox() {
    return SizedBox(
      width: 24,
      child: Text(
        '${widget.slot.slot}',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _kindToggle() {
    return Wrap(
      spacing: 6,
      children: [
        ChoiceChip(
          label: const Text('Glyph'),
          selected: _kind == 'glyph',
          onSelected: (_) {
            setState(() => _kind = 'glyph');
            _notify();
          },
        ),
        ChoiceChip(
          label: const Text('Text'),
          selected: _kind == 'text',
          onSelected: (_) {
            setState(() => _kind = 'text');
            _notify();
          },
        ),
      ],
    );
  }

  Widget _invertToggle() {
    // Invert is meaningless for a fixed-colour glyph (e.g. Caution).
    final disabled = _kind == 'glyph' && _selectedGlyphIsFixed;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Invert',
          style: TextStyle(
            fontSize: 12,
            color: disabled ? Colors.grey.shade400 : Colors.black87,
          ),
        ),
        Switch(
          value: _invert && !disabled,
          onChanged: disabled
              ? null
              : (v) {
                  setState(() => _invert = v);
                  _notify();
                },
        ),
      ],
    );
  }

  Widget _glyphPickerButton(BuildContext context) {
    final glyph = glyphById(_glyphId);
    return OutlinedButton.icon(
      onPressed: () => _pickGlyph(context),
      icon: const Icon(Icons.grid_view, size: 18),
      label: Text(glyph == null ? 'Choose a glyph' : glyph.defaultName),
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        minimumSize: const Size.fromHeight(40),
      ),
    );
  }

  Widget _textField() {
    return TextField(
      controller: _textCtrl,
      textCapitalization: TextCapitalization.characters,
      inputFormatters: [
        FilteringTextInputFormatter.deny(RegExp(':')), // protect the `::` separator
        const _MaxNonSpaceFormatter(7),
      ],
      decoration: const InputDecoration(
        labelText: 'Mark text',
        hintText: 'e.g. YBF  ·  space = new line',
        isDense: true,
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      ),
      onChanged: (_) {
        setState(() {}); // refresh live preview
        _notify();
      },
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
      initialValue: _selectedAction,
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
        // 'endRun' removed 2026-08-15: On Inn / run termination is no longer
        // a configurable mark action — the mobile End Run button owns it.
        // Slots carrying endRun in old configs are dropped at parse time, so
        // this dropdown can never be asked to display the removed value.
      ],
      onChanged: (v) {
        setState(() => _selectedAction = v);
        _notify();
      },
    );
  }

  Widget _buildPurposeWidget() {
    final slot = widget.slot.slot;
    if (kFixedSlotPurposes.containsKey(slot)) {
      return InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Purpose',
          isDense: true,
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        ),
        child: Text(
          kFixedSlotPurposes[slot]!,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      );
    }
    return DropdownButtonFormField<String?>(
      initialValue: _selectedPurpose,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Purpose',
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
}

// ---------------------------------------------------------------------------
// Glyph picker dialog — grid of the canonical glyph library
// ---------------------------------------------------------------------------

class _GlyphPickerDialog extends StatelessWidget {
  const _GlyphPickerDialog({this.current});

  final String? current;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Choose a glyph'),
      contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      content: SizedBox(
        width: 360,
        child: GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.82,
          children: kTrailGlyphs.map((g) {
            final isSelected = g.id == current;
            return GestureDetector(
              onTap: () => Navigator.of(context).pop(g.id),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue.shade50 : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Colors.blue.shade600 : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                padding: const EdgeInsets.all(6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TrailTilePreview(
                      slot: TrailSlotConfig(
                        slot: 0,
                        kind: 'glyph',
                        glyphId: g.id,
                      ),
                      size: 56,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      g.defaultName,
                      style: const TextStyle(fontSize: 11),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        HcButton.secondary(
          label: 'Cancel',
          onPressed: () => Navigator.of(context).pop(null),
        ),
      ],
    );
  }
}
