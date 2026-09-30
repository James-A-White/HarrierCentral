import 'dart:async';

import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

/// Gets a runner's attention when somebody on the trail has pressed
/// **Send Help** (James, 2026-09-30): three beeps and three buzzes, once per
/// call for help, wherever the app is when it arrives — the run chat push in
/// the foreground, or a new help mark landing on the PackTrack map.
///
/// One alert per help mark. The chat push and the map poll both know about
/// the same event, so the second to notice must stay quiet: callers pass a
/// key (the mark's timestamp, or the message id) and a key rings once.
class DistressAlert {
  DistressAlert._();

  static final Set<String> _rung = <String>{};
  static bool _ringing = false;

  /// Beep and buzz three times, unless [key] already rang.
  static Future<void> ring(String key) async {
    if (!_rung.add(key)) return;
    if (_ringing) return; // a second call for help while the first rings
    _ringing = true;
    try {
      final AudioPlayer player = AudioPlayer();
      try {
        await player.setAsset('assets/sounds/sos.wav');
        for (int i = 0; i < 3; i++) {
          unawaited(HapticFeedback.heavyImpact());
          await player.seek(Duration.zero);
          await player.play();
          // sos.wav is three short beeps (~0.9 s); a breath between rounds.
          await Future<void>.delayed(const Duration(milliseconds: 400));
          unawaited(HapticFeedback.heavyImpact());
          await Future<void>.delayed(const Duration(milliseconds: 400));
        }
      } finally {
        unawaited(player.dispose());
      }
    } catch (_) {
      // A phone with no audio session (silent switch, call in progress) still
      // got the haptics; the chat and the map carry the message itself.
    } finally {
      _ringing = false;
    }
  }

  /// A chat push is a call for help when the message is the Send Help text.
  static bool isHelpMessage(Object? text) =>
      text is String && text.trimLeft().startsWith('🆘');
}
