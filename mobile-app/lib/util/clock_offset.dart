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

  static int? _cachedMs;

  static int get offsetMs =>
      _cachedMs ??= getIntPref(IntPrefsEnum.clockOffsetMs) ?? 0;

  /// Now, in UTC, by the server's clock as best this phone knows it.
  static DateTime nowUtc() =>
      DateTime.now().toUtc().add(Duration(milliseconds: offsetMs));

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
    if (newMs == offsetMs) return false;
    _cachedMs = newMs;
    unawaited(setIntPref(IntPrefsEnum.clockOffsetMs, newMs));
    BootLogger.logError(
      '[ERROR][CLOCK]',
      'phone clock ${describe(-delta)} of server UTC; token offset now ${newMs}ms',
      null,
    );
    if (newMs != 0 &&
        getBoolPref(BoolPrefsEnum.clockOffsetNoticeShown) != true) {
      unawaited(setBoolPref(BoolPrefsEnum.clockOffsetNoticeShown, true));
      hcSnack(noticeFor(-delta), seconds: 12);
    }
    return true;
  }

  /// [phoneMinusServer] positive = the phone is ahead.
  static String noticeFor(Duration phoneMinusServer) =>
      "Your phone's clock is ${describe(phoneMinusServer)} of Coordinated "
      'Universal Time. If you are experiencing problems with some of your '
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
