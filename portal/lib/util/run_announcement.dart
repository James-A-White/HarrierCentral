import 'package:intl/intl.dart';
import 'package:hcportal/imports.dart';

/// The run notice a hare raiser would otherwise type into the kennel's
/// WhatsApp group — the portal's port of the app's RunAnnouncement, so Save
/// and send says the same thing from either client (parity rule,
/// 2026-10-09). On the web it opens WhatsApp through wa.me with the notice
/// pre-filled; the person picks the group and taps send.
class RunAnnouncement {
  const RunAnnouncement({required this.run, required this.kennel});

  final RunDetailsModel run;
  final HasherKennelsModel kennel;

  bool get _isCounted => run.isCountedRun != 0 && run.eventNumber > 0;

  String get url => _isCounted
      ? 'https://www.hashruns.org/${kennel.kennelUniqueShortName.toLowerCase()}/${run.eventNumber}'
      : 'https://www.hashruns.org/#/RID?publicEventId=${run.publicEventId ?? ''}';

  String rsvpUrl(bool yes) =>
      _isCounted ? '$url?RSVP=${yes ? 'Yes' : 'No'}' : '$url&RSVP=${yes ? 'Yes' : 'No'}';

  String get _title {
    final String num = _isCounted ? ' #${run.eventNumber}' : '';
    final String name = run.eventName.trim();
    return name.isEmpty
        ? '${kennel.kennelShortName}$num'
        : '${kennel.kennelShortName}$num – $name';
  }

  /// EventStartDatetime is the LOCAL wall-clock, formatted as-is.
  String get _when => DateFormat('EEE d MMM, h:mm a').format(run.eventStartDatetime);

  String get _where {
    final String one = (run.locationOneLineDesc ?? '').trim();
    final String city = (run.locationCity ?? '').trim();
    if (one.isEmpty) return city;
    if (city.isEmpty || one.toLowerCase().contains(city.toLowerCase())) return one;
    return '$one, $city';
  }

  String get _price {
    final double members = run.eventPriceForMembers ?? kennel.defaultEventPriceForMembers;
    final double nonMembers =
        run.eventPriceForNonMembers ?? kennel.defaultEventPriceForNonMembers;
    String money(double v) => v.toStringAsFixed(2);
    if (members <= 0 && nonMembers <= 0) return '';
    if (members == nonMembers || members <= 0) return money(nonMembers);
    if (nonMembers <= 0) return money(members);
    return '${money(members)} (members) · ${money(nonMembers)} (non-members)';
  }

  String get text {
    final StringBuffer b = StringBuffer();
    b.writeln('*$_title*');
    b.writeln('📅 $_when');
    final String hares = (run.hares ?? '').trim();
    if (hares.isNotEmpty) b.writeln('🐰 Hares: $hares');
    final String where = _where;
    if (where.isNotEmpty) b.writeln('📍 $where');
    final String price = _price;
    if (price.isNotEmpty) b.writeln('💰 $price');
    final String desc = run.eventDescription.trim();
    if (desc.isNotEmpty) {
      b.writeln();
      b.writeln(desc.length > 300 ? '${desc.substring(0, 297)}…' : desc);
    }
    b.writeln();
    b.writeln('✅ I\'m in: ${rsvpUrl(true)}');
    b.writeln('❌ Can\'t make it: ${rsvpUrl(false)}');
    b.writeln('Details: $url');
    return b.toString();
  }

  /// WhatsApp's web/app hand-off: opens with the notice pre-filled.
  Uri get whatsAppUri => Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
}
