import 'package:harrier_central/imports.dart';

/// How close a kennel membership is to lapsing.
///
/// The warning tiers are a fraction of the kennel's own membership period, so
/// a 12-month kennel warns at 36 days and a 6-month kennel at 18 — the badge
/// means the same thing ("a tenth of your year left") everywhere.
enum MembershipStatus {
  /// Not a member of this kennel, or the membership has already lapsed.
  none,

  /// Membership is live with plenty of time left.
  current,

  /// Within 10% of the membership period of expiring.
  expiringSoon,

  /// Within 5% of the membership period of expiring.
  expiringCritical,
}

/// Expiry at or beyond this is a lifetime membership — the sentinel
/// `hcapp_processPayment` writes for renewal mode 3. Never warns.
final DateTime _lifetimeSentinel = DateTime(2999);

const double _soonFraction = 0.10;
const double _criticalFraction = 0.05;

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
  if (!expiry.isAfter(now)) return MembershipStatus.none;

  if (renewalMode == 3 || !expiry.isBefore(_lifetimeSentinel)) {
    return MembershipStatus.current;
  }

  // Fixed-year kennels renew on a shared anniversary, so the period is the
  // year itself — that mode ignores MembershipDurationInMonths.
  final int months = renewalMode == 2
      ? 12
      : (durationInMonths > 0 ? durationInMonths : 12);
  final double periodDays = months * _daysPerMonth;

  final double daysLeft = expiry.difference(now).inMinutes / (60 * 24);

  if (daysLeft <= periodDays * _criticalFraction) {
    return MembershipStatus.expiringCritical;
  }
  if (daysLeft <= periodDays * _soonFraction) {
    return MembershipStatus.expiringSoon;
  }
  return MembershipStatus.current;
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
/// comfortable, an amber triangle as it nears its end, a red alert triangle
/// once it is nearly gone. Returns null when there is no membership to badge.
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
    case MembershipStatus.expiringCritical:
      return Icon(
        MaterialCommunityIcons.alert,
        color: Colors.red.shade700,
        size: size,
      );
  }
}
