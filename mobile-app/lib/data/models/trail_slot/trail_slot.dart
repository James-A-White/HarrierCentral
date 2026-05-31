import 'package:harrier_central/imports.dart';

enum TrailSlotAction { addText, endRun }

class TrailSlot {
  const TrailSlot({
    required this.slot,
    required this.icon,
    required this.name,
    this.action,
  });

  final int slot;
  final String icon;
  final String name;

  /// Raw action string from JSON. Use [parsedAction] for typed access.
  final String? action;

  TrailSlotAction? get parsedAction => switch (action) {
    'addText' => TrailSlotAction.addText,
    'endRun' => TrailSlotAction.endRun,
    _ => null,
  };

  String get assetPath => 'images/live_run_trail_markers/$icon';

  factory TrailSlot.fromJson(Map<String, dynamic> json) => TrailSlot(
    slot: json['slot'] as int,
    icon: json['icon'] as String,
    name: json['name'] as String,
    action: json['action'] as String?,
  );

  static const List<TrailSlot> defaults = [
    TrailSlot(slot: 1,  icon: 'I-001.png', name: 'Check'),
    TrailSlot(slot: 2,  icon: 'I-002.png', name: 'False Trail'),
    TrailSlot(slot: 3,  icon: 'I-003.png', name: 'Short Cut'),
    TrailSlot(slot: 4,  icon: 'I-004.png', name: 'Checkback'),
    TrailSlot(slot: 5,  icon: 'I-005.png', name: 'Whichy Way'),
    TrailSlot(slot: 6,  icon: 'I-006.png', name: 'Fish Hook'),
    TrailSlot(slot: 7,  icon: 'I-007.png', name: 'Regroup'),
    TrailSlot(slot: 8,  icon: 'I-008.png', name: 'Hash View'),
    TrailSlot(slot: 9,  icon: 'I-009.png', name: 'Label',       action: 'addText'),
    TrailSlot(slot: 10, icon: 'I-010.png', name: 'Drink Stop'),
    TrailSlot(slot: 11, icon: 'I-011.png', name: 'On Inn',      action: 'endRun'),
    TrailSlot(slot: 12, icon: 'I-012.png', name: 'Caution',     action: 'addText'),
  ];
}

extension KennelsModelTrailSlots on KennelsModel {
  List<TrailSlot> get trailSlots {
    final json = trailSymbolsConfigJson;
    if (json == null || json.isEmpty) return TrailSlot.defaults;
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list
          .map((e) => TrailSlot.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return TrailSlot.defaults;
    }
  }
}
