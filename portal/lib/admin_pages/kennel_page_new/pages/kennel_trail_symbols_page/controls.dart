part of '../../kennel_page_new_controller.dart';

// ---------------------------------------------------------------------------
// Trail symbol slot model (portal-local, not shared with app)
// ---------------------------------------------------------------------------

class TrailSlotConfig {
  TrailSlotConfig({
    required this.slot,
    this.kind = 'glyph',
    this.glyphId,
    this.text,
    this.invert = false,
    this.name = '',
    this.action,
    this.purpose,
  });

  final int slot;
  String kind;       // 'glyph' | 'text'
  String? glyphId;   // when kind == 'glyph' — an id from the glyph registry
  String? text;      // when kind == 'text' — up to 7 non-space chars; ' ' = newline
  bool invert;       // placeholder: light-on-dark rendering (text + mono glyphs only)
  String name;
  String? action;    // null | 'addText' | 'endRun'
  String? purpose;   // portal metadata only — not used in the app

  bool get isEmpty => kind == 'text'
      ? (text == null || text!.trim().isEmpty)
      : (glyphId == null || glyphId!.isEmpty);

  Map<String, dynamic> toMap() => {
        'slot': slot,
        'kind': kind,
        if (kind == 'text') 'text': text else 'glyphId': glyphId,
        'invert': invert,
        'name': name,
        'action': action,
        'purpose': purpose,
      };

  static TrailSlotConfig fromJson(Map<String, dynamic> json) {
    // New schema: has an explicit `kind`.
    if (json['kind'] != null) {
      return TrailSlotConfig(
        slot:    json['slot'] as int,
        kind:    json['kind'] as String,
        glyphId: json['glyphId'] as String?,
        text:    json['text'] as String?,
        invert:  json['invert'] == true,
        name:    (json['name'] as String?) ?? '',
        action:  json['action'] as String?,
        purpose: json['purpose'] as String?,
      );
    }
    // Legacy schema: map the old `icon` filename → glyph/text (best effort;
    // the admin can adjust in the editor). Unknown icons become empty slots.
    final legacy = _legacyIconToMarker(json['icon'] as String?);
    return TrailSlotConfig(
      slot:    json['slot'] as int,
      kind:    legacy.kind,
      glyphId: legacy.glyphId,
      text:    legacy.text,
      name:    (json['name'] as String?) ?? '',
      action:  json['action'] as String?,
      purpose: json['purpose'] as String?,
    );
  }

  /// Maps a legacy `I-NNN.png` / named-symbol filename to the new marker model.
  /// Letter-based symbols become text; pictorial ones map to a glyph id.
  static ({String kind, String? glyphId, String? text}) _legacyIconToMarker(
    String? icon,
  ) {
    ({String kind, String? glyphId, String? text}) glyph(String id) =>
        (kind: 'glyph', glyphId: id, text: null);
    ({String kind, String? glyphId, String? text}) txt(String t) =>
        (kind: 'text', glyphId: null, text: t);
    const empty = (kind: 'glyph', glyphId: null, text: null);

    if (icon == null || icon.isEmpty) return empty;
    final f = icon.toLowerCase();

    const named = {
      'check.png': 'g:check', 'caution.png': 'g:caution',
      'drinkstop.png': 'g:drinkstop', 'fishhook.png': 'g:fishhook',
      'hashview.png': 'g:hashview', 'label.png': 'g:label',
      'oninn.png': 'g:oninn', 'regroup.png': 'g:regroup',
      'whichyway.png': 'g:whichyway',
      'checkback.png': 't:CB', 'falsetrail.png': 't:FT', 'shortcut.png': 't:SC',
    };
    String? code = named[f];
    if (code == null && f.startsWith('i-')) {
      final n = int.tryParse(f.substring(2, f.indexOf('.'))) ?? -1;
      code = switch (n) {
        >= 1 && <= 4 => 'g:check',
        >= 50 && <= 58 => 't:FT',
        >= 100 && <= 102 => 't:SC',
        >= 150 && <= 151 => 't:CB',
        200 => 'g:whichyway',
        250 => 'g:fishhook',
        >= 300 && <= 301 => 'g:regroup',
        >= 350 && <= 351 => 'g:hashview',
        400 => 'g:label',
        450 => 'g:drinkstop',
        451 => 't:BS',
        452 => 't:DS',
        500 => 'g:oninn',
        >= 501 && <= 504 => 't:ON IN',
        550 => 'g:caution',
        _ => null,
      };
    }
    if (code == null) return empty;
    final parts = code.split(':');
    return parts[0] == 'g' ? glyph(parts[1]) : txt(parts[1]);
  }
}

// ---------------------------------------------------------------------------
// Canonical glyph library — mirrors docs/trail_markers/glyph_registry.json
// ---------------------------------------------------------------------------

class TrailGlyph {
  const TrailGlyph(this.id, this.file, this.defaultName, {this.fixed = false});

  final String id;
  final String file;
  final String defaultName;
  final bool fixed; // true = full-colour, never tinted/inverted (e.g. caution)

  String get assetPath => 'images/trail_glyphs/$file';
}

const kTrailGlyphs = <TrailGlyph>[
  TrailGlyph('check', 'check.mono.png', 'Check'),
  TrailGlyph('whichyway', 'whichyway.mono.png', 'Whichy Way'),
  TrailGlyph('fishhook', 'fishhook.mono.png', 'Fish Hook'),
  TrailGlyph('regroup', 'regroup.mono.png', 'Regroup'),
  TrailGlyph('hashview', 'hashview.mono.png', 'Hash View'),
  TrailGlyph('label', 'label.mono.png', 'Label'),
  TrailGlyph('drinkstop', 'drinkstop.mono.png', 'Drink Stop'),
  TrailGlyph('oninn', 'oninn.mono.png', 'On Inn'),
  TrailGlyph('caution', 'caution.fixed.png', 'Caution', fixed: true),
];

TrailGlyph? glyphById(String? id) {
  if (id == null) return null;
  for (final g in kTrailGlyphs) {
    if (g.id == id) return g;
  }
  return null;
}

// ---------------------------------------------------------------------------
// Purpose metadata — fixed labels for slots 1–5, dropdown options for 6–12
// ---------------------------------------------------------------------------

/// Slots 1–5 have a fixed, non-editable purpose.
const Map<int, String> kFixedSlotPurposes = {
  1: 'Check',
  2: 'False Trail',
  3: 'Drink Stop',
  4: 'On Inn',
  5: 'Caution',
};

/// Options for the purpose dropdown on slots 6–12.
/// Does not include the fixed-five purposes above.
const List<String> kVariableSlotPurposes = [
  'Short Cut',
  'Checkback',
  'Whichy Way',
  'Fish Hook',
  'Regroup',
  'Hash View',
  'Label',
  'Other',
];

// ---------------------------------------------------------------------------
// Default 12-slot configuration (mirrors mobile app TrailSlot.defaults).
// Letter marks are text; pictorial marks reference a glyph id.
// ---------------------------------------------------------------------------

final kDefaultTrailSlots = [
  TrailSlotConfig(slot: 1,  kind: 'glyph', glyphId: 'check',     name: 'Check'),
  TrailSlotConfig(slot: 2,  kind: 'text',  text: 'FT',           name: 'False Trail'),
  TrailSlotConfig(slot: 3,  kind: 'text',  text: 'SC',           name: 'Short Cut'),
  TrailSlotConfig(slot: 4,  kind: 'text',  text: 'CB',           name: 'Checkback'),
  TrailSlotConfig(slot: 5,  kind: 'glyph', glyphId: 'whichyway', name: 'Whichy Way'),
  TrailSlotConfig(slot: 6,  kind: 'glyph', glyphId: 'fishhook',  name: 'Fish Hook',  purpose: 'Fish Hook'),
  TrailSlotConfig(slot: 7,  kind: 'glyph', glyphId: 'regroup',   name: 'Regroup',    purpose: 'Regroup'),
  TrailSlotConfig(slot: 8,  kind: 'glyph', glyphId: 'hashview',  name: 'Hash View',  purpose: 'Hash View'),
  TrailSlotConfig(slot: 9,  kind: 'glyph', glyphId: 'label',     name: 'Label',      action: 'addText', purpose: 'Label'),
  TrailSlotConfig(slot: 10, kind: 'glyph', glyphId: 'drinkstop', name: 'Drink Stop'),
  TrailSlotConfig(slot: 11, kind: 'glyph', glyphId: 'oninn',     name: 'On Inn',     action: 'endRun'),
  TrailSlotConfig(slot: 12, kind: 'glyph', glyphId: 'caution',   name: 'Caution',    action: 'addText'),
];

// ---------------------------------------------------------------------------
// Controller extension
// ---------------------------------------------------------------------------

extension KennelTrailSymbolsControlsExtension on KennelPageFormController {
  RxList<TrailSlotConfig> get trailSlots => _trailSlots;

  void initTrailSymbolsControls() {
    _trailSlots.value = _parseTrailSlots(editedData.value.trailSymbolsConfigJson);
  }

  void updateTrailSlot(TrailSlotConfig updated) {
    final idx = _trailSlots.indexWhere((s) => s.slot == updated.slot);
    if (idx >= 0) {
      _trailSlots[idx] = updated;
    }
    _flushTrailSlotsToModel();
  }

  void _flushTrailSlotsToModel() {
    final configured = _trailSlots.where((s) => !s.isEmpty).toList();
    // jsonEncode escapes user-entered name/text safely (quotes, etc.).
    final json = jsonEncode(configured.map((s) => s.toMap()).toList());
    editedData.value = editedData.value.copyWith(trailSymbolsConfigJson: json);
    checkIfFormIsDirty();
  }

  static List<TrailSlotConfig> _parseTrailSlots(String? json) {
    final result = List<TrailSlotConfig>.generate(
      12,
      (i) => TrailSlotConfig(slot: i + 1),
    );
    if (json != null && json.isNotEmpty) {
      try {
        final parsed = jsonDecode(json) as List<dynamic>;
        for (final entry in parsed) {
          final config = TrailSlotConfig.fromJson(entry as Map<String, dynamic>);
          if (config.slot >= 1 && config.slot <= 12) {
            result[config.slot - 1] = config;
          }
        }
        return result;
      } catch (_) {}
    }
    return List<TrailSlotConfig>.from(kDefaultTrailSlots);
  }
}
