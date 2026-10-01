import 'dart:async';
import 'dart:io' show HttpDate;

import 'package:harrier_central/imports.dart';

/// A phone whose clock is wrong mints tokens the server refuses: a token's
/// time block comes from the phone's clock and the server accepts only a
/// couple of blocks either side of ITS time (E1.F1.S7, James 2026-10-01 —
/// 35 invalid-token errors from 10 hashers in September).
///
/// On an invalid-token reply, [ServiceCommon] hands this the reply's HTTP
/// `Date` header — the server's own clock, which every API reply carries —
/// and the difference is kept per device and added to the time every token
/// is minted with. The server's check does not change, so the replay window
/// is what it always was; this only tells the phone what time it is on our
/// server, which is not a secret.
///
/// Measured against the phone's RAW clock every time, so a phone whose clock
/// is later fixed learns an offset of zero on its next refusal: self-healing.
/// Under [_ignoreBelow] is latency, not drift; beyond [_cap] (±12 h) is not a
/// clock that can be trusted at all, and the existing "turn on automatic
/// time" message (E1.F1.S3) stands.
class ClockOffset {
  ClockOffset._();

  static const Duration _ignoreBelow = Duration(seconds: 30);
  static const Duration _cap = Duration(hours: 12);

  /// PackTrack uses the correction only beyond this (James, 2026-10-01): a
  /// smaller offset is within what network latency and the Date header's
  /// one-second rounding could make up, and applying it would add jitter to
  /// a trail. Tokens use any offset over [_ignoreBelow], because the
  /// server's tolerance is only a minute or so.
  static const Duration _trackThreshold = Duration(minutes: 2);

  /// A new measurement replaces the stored offset only when it differs by
  /// more than this — so latency cannot make the offset creep reply by reply.
  static const Duration _hysteresis = Duration(seconds: 30);

  static int? _cachedMs;

  static int get offsetMs =>
      _cachedMs ??= getIntPref(IntPrefsEnum.clockOffsetMs) ?? 0;

  /// Now, in UTC, by the server's clock as best this phone knows it — for
  /// minting tokens.
  static DateTime nowUtc() =>
      DateTime.now().toUtc().add(Duration(milliseconds: offsetMs));

  /// The offset PackTrack applies: the learned one when it is over two
  /// minutes, otherwise none — the phone's own clock, as before.
  static int get trackOffsetMs =>
      offsetMs.abs() > _trackThreshold.inMilliseconds ? offsetMs : 0;

  /// Now, for stamping a track point or mark (see [trackOffsetMs]).
  static DateTime trackNowUtc() =>
      DateTime.now().toUtc().add(Duration(milliseconds: trackOffsetMs));

  /// Learn from a reply's `Date` header. Returns true when the stored offset
  /// changed (the caller retries either way).
  static bool learnFrom(String? dateHeader) {
    if (dateHeader == null || dateHeader.isEmpty) return false;
    final DateTime server;
    try {
      server = HttpDate.parse(dateHeader).toUtc();
    } catch (_) {
      return false;
    }
    final Duration delta = server.difference(DateTime.now().toUtc());
    final int newMs = delta.abs() < _ignoreBelow || delta.abs() > _cap
        ? 0
        : delta.inMilliseconds;
    if (delta.abs() > _cap) {
      BootLogger.logBreadcrumb(
        '[CLOCK] phone is ${describe(-delta)} — beyond ±12 h, not corrected',
      );
    }
    if ((newMs - offsetMs).abs() <= _hysteresis.inMilliseconds) return false;
    _cachedMs = newMs;
    unawaited(setIntPref(IntPrefsEnum.clockOffsetMs, newMs));
    BootLogger.logError(
      '[ERROR][CLOCK]',
      'phone clock ${describe(-delta)} server UTC; token offset now ${newMs}ms',
      null,
    );
    if (newMs != 0 && getBoolPref(BoolPrefsEnum.clockNoticeShown) != true) {
      _showNoticeWhenReady(noticeFor(-delta));
    }
    return true;
  }

  static Timer? _noticeTimer;

  /// The offset is usually learnt from the first reply at boot, before the
  /// app has a screen to draw on: 1428 called the snackbar then, GetX threw
  /// a null-check inside it, and the flag was already set, so James never saw
  /// the notice (2026-10-01). So: wait until there is an overlay, show it,
  /// and only THEN record that it was shown. Gives up after two minutes and
  /// tries again on the next correction.
  static void _showNoticeWhenReady(String text) {
    _noticeTimer?.cancel();
    int tries = 0;
    _noticeTimer = Timer.periodic(const Duration(seconds: 2), (Timer t) {
      tries++;
      if (Get.overlayContext == null) {
        if (tries >= 60) t.cancel();
        return;
      }
      t.cancel();
      try {
        hcSnack(text, seconds: 12);
        unawaited(setBoolPref(BoolPrefsEnum.clockNoticeShown, true));
      } catch (e, s) {
        BootLogger.logError('[ERROR][CLOCK]', 'notice failed: $e', s);
      }
    });
  }

  /// [phoneMinusServer] positive = the phone is ahead.
  static String noticeFor(Duration phoneMinusServer) =>
      "Your phone's clock is ${describe(phoneMinusServer)}"
      "${phoneMinusServer.isNegative ? '' : ' of'} Coordinated Universal Time. "
      'If you are experiencing problems with some of your '
      'apps, you may want to consider setting your phone to set the clock '
      'automatically from an internet time source.';

  /// "1 hour and 36 minutes ahead", "4 minutes behind", "45 seconds ahead".
  static String describe(Duration phoneMinusServer) {
    final Duration d = phoneMinusServer.abs();
    final String dir = phoneMinusServer.isNegative ? 'behind' : 'ahead';
    final int h = d.inHours;
    final int m = d.inMinutes % 60;
    String unit(int n, String w) => '$n $w${n == 1 ? '' : 's'}';
    final String amount = h > 0
        ? (m > 0
              ? '${unit(h, 'hour')} and ${unit(m, 'minute')}'
              : unit(h, 'hour'))
        : (d.inMinutes > 0
              ? unit(d.inMinutes, 'minute')
              : unit(d.inSeconds, 'second'));
    return '$amount $dir';
  }
}
