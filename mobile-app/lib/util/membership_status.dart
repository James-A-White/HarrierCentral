import 'package:harrier_central/imports.dart';

/// How close a kennel membership is to lapsing — or how recently it lapsed.
///
/// The thresholds are a fraction of the kennel's own membership period, so
/// a 12-month kennel warns at ~36 days and a 6-month kennel at ~18 — the
/// badge means the same thing ("a tenth of your year left") everywhere.
enum MembershipStatus {
  /// Not a member of this kennel, and not recently lapsed.
  none,

  /// Membership is live with plenty of time left.
  current,

  /// Within 10% of the membership period of expiring.
  expiringSoon,

  /// Membership expired within the last 20% of the membership period —
  /// still worth chasing for a renewal. Beyond that window they're
  /// treated as not renewing and get [none].
  lapsedRecently,
}

/// Expiry at or beyond this is a lifetime membership. Never warns.
/// `hcapp_processPayment` writes 2999 for renewal-mode-3 grants, but any
/// hand-set date of 2100 or later counts as lifetime too — that is the
/// project-wide definition, shared with the membership charge sheet.
final DateTime _lifetimeSentinel = DateTime(2100);

const double _soonFraction = 0.10;
const double _lapsedFraction = 0.20;

/// 365.25 / 12 — so 12 months is a year, not 360 days.
const double _daysPerMonth = 30.4375;

/// Tier for a membership expiring on [expiry].
///
/// [durationInMonths] and [renewalMode] come from the kennel
/// (`MembershipDurationInMonths` / `MembershipRenewalMode`: 1 = rolling,
/// 2 = fixed year, 3 = lifetime).
MembershipStatus membershipStatusFor({
  required DateTime? expiry,
  required int durationInMonths,
  required int renewalMode,
  DateTime? asOf,
}) {
  if (expiry == null) return MembershipStatus.none;

  final DateTime now = asOf ?? DateTime.now();

  if (renewalMode == 3 || !expiry.isBefore(_lifetimeSentinel)) {
    return expiry.isAfter(now)
        ? MembershipStatus.current
        : MembershipStatus.none;
  }

  // Fixed-year kennels renew on a shared anniversary, so the period is the
  // year itself — that mode ignores MembershipDurationInMonths.
  final int months = renewalMode == 2
      ? 12
      : (durationInMonths > 0 ? durationInMonths : 12);
  final double periodDays = months * _daysPerMonth;

  final double daysLeft = expiry.difference(now).inMinutes / (60 * 24);

  if (daysLeft > periodDays * _soonFraction) return MembershipStatus.current;
  if (daysLeft > 0) return MembershipStatus.expiringSoon;
  if (-daysLeft <= periodDays * _lapsedFraction) {
    return MembershipStatus.lapsedRecently;
  }
  return MembershipStatus.none;
}

/// As [membershipStatusFor], but for an expiry still in its stored text form.
MembershipStatus membershipStatusForText({
  required String? expiryText,
  required int durationInMonths,
  required int renewalMode,
  DateTime? asOf,
}) => membershipStatusFor(
  expiry: expiryText == null ? null : DateTime.tryParse(expiryText)?.toLocal(),
  durationInMonths: durationInMonths,
  renewalMode: renewalMode,
  asOf: asOf,
);

/// The member badge for [status] — green star while the membership is
/// comfortable, an amber triangle through the last 10% of the period, a red
/// alert triangle once it has lapsed (kept up for 20% of the period as a
/// "chase the renewal" flag). Returns null when there is nothing to badge.
Widget? membershipStatusIcon(MembershipStatus status, {double size = 23}) {
  switch (status) {
    case MembershipStatus.none:
      return null;
    case MembershipStatus.current:
      return Icon(
        MaterialCommunityIcons.star_circle,
        color: Colors.green.shade800,
        size: size,
      );
    case MembershipStatus.expiringSoon:
      return Icon(
        MaterialCommunityIcons.triangle,
        color: Colors.amber.shade800,
        size: size,
      );
    case MembershipStatus.lapsedRecently:
      return Icon(
        MaterialCommunityIcons.alert,
        color: Colors.red.shade700,
        size: size,
      );
  }
}
