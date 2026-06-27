import 'package:harrier_central/imports.dart';

/// A PackTrack trail type ("lane") a runner can declare and filter playback by
/// (Walkers / Short / Normal / Long / Ballbreaker, plus any kennel customs).
///
/// The [value] is a stable identifier that rides on the track as `TRL::<value>`;
/// labels and emojis are presentation only and can be overridden per kennel.
/// Built-ins are values 1–5 (6–99 reserved); kennel-custom types start at 100.
///
/// Resolution is **merge-by-value**: kennel config holds only deviations from
/// the built-in [defaults] — an entry overrides a built-in's label/emoji/hidden
/// (only the fields it provides), or adds a custom type. Mirrors the trail-mark
/// pattern ([TrailSlot] + `KennelsModel.trailSymbolsConfigJson`).
class TrailType {
  const TrailType({
    required this.value,
    required this.label,
    required this.emoji,
    this.hidden = false,
    this.sortOrder,
  });

  final int value;
  final String label;
  final String emoji;
  final bool hidden;
  final int? sortOrder;

  /// Sort key: explicit [sortOrder] when set, otherwise the [value].
  int get effectiveSortOrder => sortOrder ?? value;

  /// The lane used for undeclared / legacy tracks. Permanent — a kennel can
  /// rename it but can never hide or remove it.
  static const int normalValue = 3;

  /// Lowest value a kennel-defined custom type may use.
  static const int customValueStart = 100;

  static const List<TrailType> defaults = [
    TrailType(value: 1, label: 'Walkers', emoji: '🚶'),
    TrailType(value: 2, label: 'Short', emoji: '🐔'),
    TrailType(value: 3, label: 'Normal', emoji: '🏃'),
    TrailType(value: 4, label: 'Long', emoji: '🐂'),
    TrailType(value: 5, label: 'Ballbreaker', emoji: '💥'),
  ];

  TrailType copyWith({
    String? label,
    String? emoji,
    bool? hidden,
    int? sortOrder,
  }) => TrailType(
    value: value,
    label: label ?? this.label,
    emoji: emoji ?? this.emoji,
    hidden: hidden ?? this.hidden,
    sortOrder: sortOrder ?? this.sortOrder,
  );

  /// Full value→type map after merging the kennel [configJson] over the
  /// built-in defaults. Includes hidden entries (so a track declared on a
  /// since-hidden lane can still be labelled). Guarantees Normal (#3) is present
  /// and never hidden. Parse failures fall back to defaults.
  static Map<int, TrailType> resolveMap(String? configJson) {
    final byValue = <int, TrailType>{
      for (final t in defaults) t.value: t,
    };

    if (configJson != null && configJson.trim().isNotEmpty) {
      try {
        final list = jsonDecode(configJson) as List<dynamic>;
        for (final raw in list) {
          if (raw is! Map<String, dynamic>) continue;
          final value = (raw['value'] as num?)?.toInt();
          if (value == null) continue;

          final hidden = raw.containsKey('hidden')
              ? (raw['hidden'] == true || raw['hidden'] == 1)
              : null;
          final sortOrder = (raw['sortOrder'] as num?)?.toInt();
          final label = raw['label'] as String?;
          final emoji = raw['emoji'] as String?;

          final existing = byValue[value];
          if (existing != null) {
            // Override a built-in (or an already-added custom) — only the
            // provided fields change.
            byValue[value] = existing.copyWith(
              label: label,
              emoji: emoji,
              hidden: hidden,
              sortOrder: sortOrder,
            );
          } else {
            // New custom type — a label is required; emoji optional.
            if (label == null || label.isEmpty) continue;
            byValue[value] = TrailType(
              value: value,
              label: label,
              emoji: emoji ?? '',
              hidden: hidden ?? false,
              sortOrder: sortOrder,
            );
          }
        }
      } catch (_) {
        return {for (final t in defaults) t.value: t};
      }
    }

    // Normal (#3) is permanent and can never be hidden — re-inject defensively.
    final normal = byValue[normalValue];
    if (normal == null) {
      byValue[normalValue] = defaults.firstWhere((t) => t.value == normalValue);
    } else if (normal.hidden) {
      byValue[normalValue] = normal.copyWith(hidden: false);
    }

    return byValue;
  }

  /// Visible, ordered lane list for the capture picker / filter (hidden removed).
  static List<TrailType> resolveVisible(String? configJson) {
    final list = resolveMap(configJson).values.where((t) => !t.hidden).toList();
    list.sort((a, b) {
      final c = a.effectiveSortOrder.compareTo(b.effectiveSortOrder);
      return c != 0 ? c : a.value.compareTo(b.value);
    });
    return list;
  }

  /// Resolves a single declared lane [value] to its type for display, falling
  /// back to Normal for unknown values so there is always something to show.
  static TrailType resolveOne(int value, String? configJson) {
    final map = resolveMap(configJson);
    return map[value] ?? map[normalValue]!;
  }
}

extension KennelsModelTrailTypes on KennelsModel {
  /// Visible, ordered trail types for this kennel (built-ins merged with the
  /// kennel's customisations).
  List<TrailType> get trailTypes =>
      TrailType.resolveVisible(trailTypesConfigJson);

  /// Full value→type map for this kennel, including hidden lanes — use for
  /// labelling a track's declared lane.
  Map<int, TrailType> get trailTypeMap =>
      TrailType.resolveMap(trailTypesConfigJson);
}
