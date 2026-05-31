part of '../../kennel_page_new_controller.dart';

// ---------------------------------------------------------------------------
// Trail symbol slot model (portal-local, not shared with app)
// ---------------------------------------------------------------------------

class TrailSlotConfig {
  TrailSlotConfig({required this.slot, this.icon, this.name = '', this.action});

  final int slot;
  String? icon;
  String name;
  String? action; // null | 'addText' | 'endRun'

  bool get isEmpty => icon == null || icon!.isEmpty;

  static TrailSlotConfig fromJson(Map<String, dynamic> json) =>
      TrailSlotConfig(
        slot: json['slot'] as int,
        icon: json['icon'] as String?,
        name: (json['name'] as String?) ?? '',
        action: json['action'] as String?,
      );
}

// ---------------------------------------------------------------------------
// Available symbol icons in the library
// ---------------------------------------------------------------------------

/// Ordered list of available trail symbol asset filenames.
/// The picker dialog renders each as an image — no text labels
/// so admins assign their own meaning per kennel.
const kTrailSymbolLibrary = [
  ('I-001.png', ''),
  ('I-002.png', ''),
  ('I-003.png', ''),
  ('I-004.png', ''),
  ('I-005.png', ''),
  ('I-006.png', ''),
  ('I-007.png', ''),
  ('I-008.png', ''),
  ('I-009.png', ''),
  ('I-010.png', ''),
  ('I-011.png', ''),
  ('I-012.png', ''),
];

// ---------------------------------------------------------------------------
// Default 12-slot configuration (mirrors mobile app TrailSlot.defaults)
// ---------------------------------------------------------------------------

final kDefaultTrailSlots = [
  TrailSlotConfig(slot: 1,  icon: 'I-001.png', name: 'Check'),
  TrailSlotConfig(slot: 2,  icon: 'I-002.png', name: 'False Trail'),
  TrailSlotConfig(slot: 3,  icon: 'I-003.png', name: 'Short Cut'),
  TrailSlotConfig(slot: 4,  icon: 'I-004.png', name: 'Checkback'),
  TrailSlotConfig(slot: 5,  icon: 'I-005.png', name: 'Whichy Way'),
  TrailSlotConfig(slot: 6,  icon: 'I-006.png', name: 'Fish Hook'),
  TrailSlotConfig(slot: 7,  icon: 'I-007.png', name: 'Regroup'),
  TrailSlotConfig(slot: 8,  icon: 'I-008.png', name: 'Hash View'),
  TrailSlotConfig(slot: 9,  icon: 'I-009.png', name: 'Label',       action: 'addText'),
  TrailSlotConfig(slot: 10, icon: 'I-010.png', name: 'Drink Stop'),
  TrailSlotConfig(slot: 11, icon: 'I-011.png', name: 'On Inn',      action: 'endRun'),
  TrailSlotConfig(slot: 12, icon: 'I-012.png', name: 'Caution',     action: 'addText'),
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
    final json = '[${configured.map(_slotToJsonString).join(',')}]';
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

  static String _slotToJsonString(TrailSlotConfig s) {
    final action = s.action == null ? 'null' : '"${s.action}"';
    return '{"slot":${s.slot},"icon":"${s.icon}","name":"${s.name}","action":$action}';
  }
}
