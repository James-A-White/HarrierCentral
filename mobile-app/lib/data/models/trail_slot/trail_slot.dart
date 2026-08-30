import 'package:harrier_central/imports.dart';

// 'endRun' (the On Inn terminator) was removed from the slot system
// 2026-08-15 — ending a run is the End Run button's job. The raw string is
// still recognised by the config cleanse filter so old kennel configs are
// scrubbed, and by the map's track-type parser for historical marks.
enum TrailSlotAction { addText }

// ---------------------------------------------------------------------------
// Canonical glyph library — mirrors docs/trail_markers/glyph_registry.json.
// The registry (not the filename) is authoritative for colorMode.
// ---------------------------------------------------------------------------

class TrailGlyph {
  const TrailGlyph(this.id, this.file, this.defaultName, {this.fixed = false});

  final String id;
  final String file;
  final String defaultName;
  final bool fixed; // full-colour, never tinted/inverted (e.g. caution)

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
  // Plain circle and plain X — the two halves of the combined 'check'
  // glyph, for kennels that mark them separately (added 2026-08-30).
  TrailGlyph('circle', 'circle.mono.png', 'Circle'),
  TrailGlyph('cross', 'cross.mono.png', 'X'),
  TrailGlyph('threelines', 'threelines.mono.png', 'Three Lines'),
  // RENDER-ONLY: On Inn is no longer a placeable slot (2026-08-15), but the
  // glyph stays so the map can draw historical GLY::oninn marks
  // (run_tracker_map_controller resolves them via glyphById).
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
// TrailSlot — a kennel's configured mark. A slot is a glyph OR a short text.
// ---------------------------------------------------------------------------

class TrailSlot {
  const TrailSlot({
    required this.slot,
    required this.kind,
    this.glyphId,
    this.text,
    this.invert = false,
    required this.name,
    this.action,
  });

  final int slot;
  final String kind; // 'glyph' | 'text'
  final String? glyphId; // when kind == 'glyph'
  final String? text; // when kind == 'text' — up to 7 non-space chars; ' ' = newline
  final bool invert; // placeholder: light-on-dark (text + mono glyphs only)
  final String name;

  /// Raw action string from JSON. Use [parsedAction] for typed access.
  final String? action;

  TrailSlotAction? get parsedAction => switch (action) {
        'addText' => TrailSlotAction.addText,
        _ => null,
      };

  /// The glyph for this slot, or null for a text slot / unknown id.
  TrailGlyph? get glyph => kind == 'glyph' ? glyphById(glyphId) : null;

  /// The self-describing track `type` string for a placed mark of this slot.
  /// See docs/trail_markers/SPEC.md §3:
  /// `GLY::glyphId` | `TXT::text` optionally followed by `::L=label` `::A=action`.
  String trackType({String? label}) {
    final buffer = StringBuffer(
      kind == 'text' ? 'TXT::${text ?? ''}' : 'GLY::${glyphId ?? ''}',
    );
    final trimmed = label?.trim();
    if (trimmed != null && trimmed.isNotEmpty) buffer.write('::L=$trimmed');
    if (action != null && action!.isNotEmpty) buffer.write('::A=$action');
    return buffer.toString();
  }

  factory TrailSlot.fromJson(Map<String, dynamic> json) {
    // New schema: explicit `kind`.
    if (json['kind'] != null) {
      return TrailSlot(
        slot: json['slot'] as int,
        kind: json['kind'] as String,
        glyphId: json['glyphId'] as String?,
        text: json['text'] as String?,
        invert: json['invert'] == true,
        name: (json['name'] as String?) ?? '',
        action: json['action'] as String?,
      );
    }
    // Legacy schema: map the old `icon` filename → glyph/text.
    final legacy = _legacyIconToMarker(json['icon'] as String?);
    return TrailSlot(
      slot: json['slot'] as int,
      kind: legacy.kind,
      glyphId: legacy.glyphId,
      text: legacy.text,
      name: (json['name'] as String?) ?? '',
      action: json['action'] as String?,
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

    // On Inn entries (oninn.png / I-500..504) intentionally unmapped
    // (2026-08-15): On Inn is no longer a placeable mark, so legacy configs
    // carrying it convert to an empty slot and drop out.
    const named = {
      'check.png': 'g:check', 'caution.png': 'g:caution',
      'drinkstop.png': 'g:drinkstop', 'fishhook.png': 'g:fishhook',
      'hashview.png': 'g:hashview', 'label.png': 'g:label',
      'regroup.png': 'g:regroup',
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
        550 => 'g:caution',
        _ => null,
      };
    }
    if (code == null) return empty;
    final parts = code.split(':');
    return parts[0] == 'g' ? glyph(parts[1]) : txt(parts[1]);
  }

  static const List<TrailSlot> defaults = [
    // Slots 1-5 are the permanent marks and mirror the portal's
    // kFixedSlotPurposes (Check / False Trail / Drink Stop / Label / Caution).
    // Label became permanent at slot 4 on 2026-08-30; the same change realigned
    // 3 and 5, which had drifted from the fixed purposes when On Inn was
    // removed. Keep this list and the portal's kDefaultTrailSlots identical.
    TrailSlot(slot: 1,  kind: 'glyph', glyphId: 'check',     name: 'Check'),
    TrailSlot(slot: 2,  kind: 'text',  text: 'FT',           name: 'False Trail'),
    TrailSlot(slot: 3,  kind: 'glyph', glyphId: 'drinkstop', name: 'Drink Stop'),
    TrailSlot(slot: 4,  kind: 'glyph', glyphId: 'label',     name: 'Label',      action: 'addText'),
    TrailSlot(slot: 5,  kind: 'glyph', glyphId: 'caution',   name: 'Caution',    action: 'addText'),
    // 6-12 are kennel-configurable.
    TrailSlot(slot: 6,  kind: 'text',  text: 'SC',           name: 'Short Cut'),
    TrailSlot(slot: 7,  kind: 'text',  text: 'CB',           name: 'Checkback'),
    TrailSlot(slot: 8,  kind: 'glyph', glyphId: 'whichyway', name: 'Whichy Way'),
    TrailSlot(slot: 9,  kind: 'glyph', glyphId: 'fishhook',  name: 'Fish Hook'),
    TrailSlot(slot: 10, kind: 'glyph', glyphId: 'regroup',   name: 'Regroup'),
    TrailSlot(slot: 11, kind: 'glyph', glyphId: 'hashview',  name: 'Hash View'),
    // Slot 12 intentionally empty. Slot 11 was On Inn until 2026-08-15 —
    // removed permanently; ending a run is the End Run button's job. The
    // 'oninn' glyph stays in kTrailGlyphs so historical marks still render.
  ];

}

extension KennelsModelTrailSlots on KennelsModel {
  List<TrailSlot> get trailSlots {
    final json = trailSymbolsConfigJson;
    if (json == null || json.isEmpty) return TrailSlot.defaults;
    try {
      final list = jsonDecode(json) as List<dynamic>;
      final slots = list
          .map((e) => TrailSlot.fromJson(e as Map<String, dynamic>))
          .where((s) => !_isOnInnSlot(s))
          .toList();
      return _ensureLabelSlot(slots);
    } catch (_) {
      return TrailSlot.defaults;
    }
  }

  /// On Inn is no longer a placeable mark (2026-08-15) — ending a run is the
  /// End Run button's job. Kennel configs saved before the removal (and the
  /// portal's old editor) can still contain one, so it is filtered out here
  /// rather than trusted away: an endRun-action slot, the oninn glyph, or a
  /// legacy "ON IN" text tile.
  static bool _isOnInnSlot(TrailSlot s) =>
      s.action == 'endRun' ||
      s.glyphId == 'oninn' ||
      (s.kind == 'text' && (s.text ?? '').trim().toUpperCase() == 'ON IN');

  /// Guarantee a functional (text-capable) Label mark is always available.
  ///
  /// The custom-text entry popup only opens for a slot with
  /// `action: addText`; a kennel whose `trailSymbolsConfigJson` omits the
  /// Label slot would otherwise leave hares with no way to drop a labelled
  /// mark. If no such slot is present we append the canonical Label from
  /// [TrailSlot.defaults], re-numbered to sit after the configured marks.
  List<TrailSlot> _ensureLabelSlot(List<TrailSlot> slots) {
    final hasLabel = slots.any(
      (s) => s.glyphId == 'label' && s.parsedAction == TrailSlotAction.addText,
    );
    if (hasLabel) return slots;

    final label = TrailSlot.defaults.firstWhere((s) => s.glyphId == 'label');
    final nextSlot = slots.isEmpty
        ? 1
        : slots.map((s) => s.slot).reduce((a, b) => a > b ? a : b) + 1;
    return <TrailSlot>[
      ...slots,
      TrailSlot(
        slot: nextSlot,
        kind: label.kind,
        glyphId: label.glyphId,
        text: label.text,
        invert: label.invert,
        name: label.name,
        action: label.action,
      ),
    ];
  }
}
