part of '../../kennel_website_page_controller.dart';

extension FeaturesControlsExtension on KennelWebsiteController {
  void initFeaturesControls() {
    _parseFeaturesFromJson(originalData.pageFeaturesJson);
  }

  void _parseFeaturesFromJson(String? raw) {
    Map<String, dynamic> data = {};
    if (raw != null && raw.isNotEmpty) {
      try {
        data = json.decode(raw) as Map<String, dynamic>;
      } catch (_) {}
    }
    featShowLanding.value = (data['showLanding'] as bool?) ?? true;
    featShowAbout.value   = (data['showAbout']   as bool?) ?? true;
    featShowHistory.value = (data['showHistory'] as bool?) ?? true;
    featShowRuns.value    = (data['showRuns']    as bool?) ?? true;
    featShowEvents.value  = (data['showEvents']  as bool?) ?? false;
    featShowStats.value   = (data['showStats']   as bool?) ?? false;
    featShowSongs.value   = (data['showSongs']   as bool?) ?? false;
    featPastRunsCount.value = (data['pastRunsCount'] as int?) ?? 12;
  }

  String _serializeFeaturesJson() {
    return json.encode({
      'showLanding':    featShowLanding.value,
      'showAbout':      featShowAbout.value,
      'showHistory':    featShowHistory.value,
      'showRuns':       featShowRuns.value,
      'showEvents':     featShowEvents.value,
      'showStats':      featShowStats.value,
      'showSongs':      featShowSongs.value,
      'pastRunsCount':  featPastRunsCount.value,
    });
  }

  void updateFeatureFlag(String key, bool value) {
    switch (key) {
      case 'showLanding':  featShowLanding.value  = value;
      case 'showAbout':    featShowAbout.value    = value;
      case 'showHistory':  featShowHistory.value  = value;
      case 'showRuns':     featShowRuns.value     = value;
      case 'showEvents':   featShowEvents.value   = value;
      case 'showStats':    featShowStats.value    = value;
      case 'showSongs':    featShowSongs.value    = value;
    }
    editedData.value = editedData.value.copyWith(
        pageFeaturesJson: _serializeFeaturesJson());
    checkIfFormIsDirty();
  }

  void updatePastRunsCount(int count) {
    featPastRunsCount.value = count.clamp(1, 100);
    editedData.value = editedData.value.copyWith(
        pageFeaturesJson: _serializeFeaturesJson());
    checkIfFormIsDirty();
  }

  void undoFeaturesState() {
    _parseFeaturesFromJson(originalData.pageFeaturesJson);
  }
}
