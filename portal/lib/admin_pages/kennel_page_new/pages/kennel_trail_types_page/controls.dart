part of '../../kennel_page_new_controller.dart';

// ---------------------------------------------------------------------------
// Trail-type model (portal-local; mirrors mobile TrailType / web TrailType)
// ---------------------------------------------------------------------------

class TrailTypeConfig {
  TrailTypeConfig({
    required this.value,
    this.label = '',
    this.emoji = '',
    this.hidden = false,
  });

  final int value;
  String label;
  String emoji;
  bool hidden;

  bool get isCustom => value >= kCustomTrailValueStart;

  static TrailTypeConfig fromJson(Map<String, dynamic> json) => TrailTypeConfig(
        value: (json['value'] as num).toInt(),
        label: (json['label'] as String?) ?? '',
        emoji: (json['emoji'] as String?) ?? '',
        hidden: json['hidden'] == true || json['hidden'] == 1,
      );
}

/// Undeclared / legacy tracks resolve to this lane. Permanent — never hidden.
const int kNormalTrailValue = 3;

/// Kennel-defined custom types start here (1–99 reserved for built-ins).
const int kCustomTrailValueStart = 100;

/// Built-in defaults (mirror mobile TrailType.defaults / web TRAIL_DEFAULTS).
final List<TrailTypeConfig> kDefaultTrailTypes = [
  TrailTypeConfig(value: 1, label: 'Walkers', emoji: '🚶'),
  TrailTypeConfig(value: 2, label: 'Short', emoji: '🐔'),
  TrailTypeConfig(value: 3, label: 'Normal', emoji: '🏃'),
  TrailTypeConfig(value: 4, label: 'Long', emoji: '🐂'),
  TrailTypeConfig(value: 5, label: 'Ballbreaker', emoji: '💥'),
];

// ---------------------------------------------------------------------------
// Controller extension
// ---------------------------------------------------------------------------

extension KennelTrailTypesControlsExtension on KennelPageFormController {
  RxList<TrailTypeConfig> get trailTypes => _trailTypes;

  void initTrailTypesControls() {
    _trailTypes.value = _parseTrailTypes(editedData.value.trailTypesConfigJson);
  }

  void updateTrailType(TrailTypeConfig updated) {
    final idx = _trailTypes.indexWhere((t) => t.value == updated.value);
    if (idx >= 0) {
      _trailTypes[idx] = updated;
      _flushTrailTypesToModel();
    }
  }

  void addCustomTrailType() {
    final used = _trailTypes.map((t) => t.value).toSet();
    var next = kCustomTrailValueStart;
    while (used.contains(next)) {
      next++;
    }
    _trailTypes.add(TrailTypeConfig(value: next));
    _flushTrailTypesToModel();
  }

  void deleteTrailType(int value) {
    if (value < kCustomTrailValueStart) return; // built-ins can't be deleted
    _trailTypes.removeWhere((t) => t.value == value);
    _flushTrailTypesToModel();
  }

  void _flushTrailTypesToModel() {
    // Merge-by-value: store only deviations from the built-in defaults plus all
    // (non-blank) customs, so future default changes still propagate.
    final entries = <String>[];
    for (final t in _trailTypes) {
      if (t.value >= kCustomTrailValueStart) {
        if (t.label.trim().isEmpty) continue; // skip blank customs
        entries.add(_typeToJsonString(t));
      } else {
        final def = kDefaultTrailTypes.firstWhere((d) => d.value == t.value);
        final deviates = t.label.trim() != def.label ||
            t.emoji.trim() != def.emoji ||
            t.hidden;
        if (deviates) entries.add(_typeToJsonString(t));
      }
    }
    final json = entries.isEmpty ? null : '[${entries.join(',')}]';
    editedData.value = editedData.value.copyWith(trailTypesConfigJson: json);
    checkIfFormIsDirty();
  }

  static List<TrailTypeConfig> _parseTrailTypes(String? json) {
    // Seed with copies of the built-in defaults (so edits don't mutate consts).
    final byValue = <int, TrailTypeConfig>{
      for (final d in kDefaultTrailTypes)
        d.value:
            TrailTypeConfig(value: d.value, label: d.label, emoji: d.emoji),
    };
    if (json != null && json.isNotEmpty) {
      try {
        final parsed = jsonDecode(json) as List<dynamic>;
        for (final entry in parsed) {
          final cfg = TrailTypeConfig.fromJson(entry as Map<String, dynamic>);
          final existing = byValue[cfg.value];
          if (existing != null) {
            if (cfg.label.isNotEmpty) existing.label = cfg.label;
            if (cfg.emoji.isNotEmpty) existing.emoji = cfg.emoji;
            existing.hidden = cfg.hidden;
          } else {
            byValue[cfg.value] = cfg;
          }
        }
      } catch (_) {}
    }
    // Normal (#3) can never be hidden.
    byValue[kNormalTrailValue]?.hidden = false;
    final list = byValue.values.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return list;
  }

  static String _typeToJsonString(TrailTypeConfig t) {
    String esc(String s) => s.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
    return '{"value":${t.value},"label":"${esc(t.label.trim())}",'
        '"emoji":"${esc(t.emoji.trim())}","hidden":${t.hidden}}';
  }
}
