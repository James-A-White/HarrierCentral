part of '../../kennel_page_new_controller.dart';

// ---------------------------------------------------------------------------
// Trail symbol slot model (portal-local, not shared with app)
// ---------------------------------------------------------------------------

class TrailSlotConfig {
  TrailSlotConfig({required this.slot, this.icon, this.name = '', this.action, this.purpose});

  final int slot;
  String? icon;
  String name;
  String? action;   // null | 'addText' | 'endRun'
  String? purpose;  // portal metadata only — not used in the app

  bool get isEmpty => icon == null || icon!.isEmpty;

  static TrailSlotConfig fromJson(Map<String, dynamic> json) =>
      TrailSlotConfig(
        slot:    json['slot'] as int,
        icon:    json['icon'] as String?,
        name:    (json['name'] as String?) ?? '',
        action:  json['action'] as String?,
        purpose: json['purpose'] as String?,
      );
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
// Available symbol icons in the library
// ---------------------------------------------------------------------------

/// Available trail symbol asset filenames. The picker dialog sorts these by
/// filename, so new icons inserted between existing numbers appear in order
/// automatically — add entries here in any order.
const kTrailSymbolLibrary = [
  // I-series numbered symbols
  ('I-000.png', ''),
  ('I-001.png', ''), ('I-002.png', ''), ('I-003.png', ''), ('I-004.png', ''),
  ('I-050.png', ''), ('I-051.png', ''), ('I-052.png', ''), ('I-053.png', ''),
  ('I-054.png', ''), ('I-055.png', ''), ('I-056.png', ''), ('I-057.png', ''),
  ('I-058.png', ''),
  ('I-100.png', ''), ('I-101.png', ''), ('I-102.png', ''),
  ('I-150.png', ''), ('I-151.png', ''),
  ('I-200.png', ''),
  ('I-250.png', ''),
  ('I-300.png', ''), ('I-301.png', ''),
  ('I-350.png', ''), ('I-351.png', ''),
  ('I-400.png', ''),
  ('I-450.png', ''), ('I-451.png', ''), ('I-452.png', ''),
  ('I-500.png', ''), ('I-501.png', ''), ('I-502.png', ''), ('I-503.png', ''),
  ('I-504.png', ''),
  ('I-550.png', ''),
  ('I-600.png', ''), ('I-601.png', ''),
  // Named semantic symbols
  ('caution.png',   ''), ('check.png',     ''), ('checkback.png', ''),
  ('drinkstop.png', ''), ('falsetrail.png',''), ('fishhook.png',  ''),
  ('hashview.png',  ''), ('label.png',     ''), ('oninn.png',     ''),
  ('regroup.png',   ''), ('shortcut.png',  ''), ('whichyway.png', ''),
];

// ---------------------------------------------------------------------------
// Default 12-slot configuration (mirrors mobile app TrailSlot.defaults)
// ---------------------------------------------------------------------------

final kDefaultTrailSlots = [
  TrailSlotConfig(slot: 1,  icon: 'I-001.png', name: 'Check'),
  TrailSlotConfig(slot: 2,  icon: 'I-050.png', name: 'False Trail'),
  TrailSlotConfig(slot: 3,  icon: 'I-100.png', name: 'Short Cut'),
  TrailSlotConfig(slot: 4,  icon: 'I-150.png', name: 'Checkback'),
  TrailSlotConfig(slot: 5,  icon: 'I-200.png', name: 'Whichy Way'),
  TrailSlotConfig(slot: 6,  icon: 'I-250.png', name: 'Fish Hook',  purpose: 'Fish Hook'),
  TrailSlotConfig(slot: 7,  icon: 'I-300.png', name: 'Regroup',    purpose: 'Regroup'),
  TrailSlotConfig(slot: 8,  icon: 'I-350.png', name: 'Hash View',  purpose: 'Hash View'),
  TrailSlotConfig(slot: 9,  icon: 'I-400.png', name: 'Label',      action: 'addText', purpose: 'Label'),
  TrailSlotConfig(slot: 10, icon: 'I-450.png', name: 'Drink Stop'),
  TrailSlotConfig(slot: 11, icon: 'I-500.png', name: 'On Inn',     action: 'endRun'),
  TrailSlotConfig(slot: 12, icon: 'I-550.png', name: 'Caution',    action: 'addText'),
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
    final action  = s.action  == null ? 'null' : '"${s.action}"';
    final purpose = s.purpose == null ? 'null' : '"${s.purpose}"';
    return '{"slot":${s.slot},"icon":"${s.icon}","name":"${s.name}","action":$action,"purpose":$purpose}';
  }
}
