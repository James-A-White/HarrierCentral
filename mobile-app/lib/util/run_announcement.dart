import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:harrier_central/imports.dart';

/// The messaging apps a kennel can prefer. Codes match
/// HC.Kennel.DefaultMessagingPlatform; WhatsApp is the server default.
enum MessagingPlatform {
  whatsApp(1, 'WhatsApp'),
  telegram(2, 'Telegram'),
  signal(3, 'Signal'),
  messenger(4, 'Messenger'),
  weChat(5, 'WeChat');

  const MessagingPlatform(this.code, this.label);
  final int code;
  final String label;

  static MessagingPlatform fromCode(int? code) => MessagingPlatform.values
      .firstWhere((MessagingPlatform p) => p.code == code,
          orElse: () => MessagingPlatform.whatsApp);

  /// Whether the app can hand the NOTICE straight to this platform.
  ///
  /// The five are not equal, and the honest word for the difference is
  /// "scheme": WhatsApp and Telegram accept pre-filled text; Messenger takes
  /// a link only; Signal and WeChat have no compose scheme at all, so for
  /// them the best possible is the OS share sheet with one fewer decision.
  bool get opensWithNotice => this == whatsApp || this == telegram;
}

/// The run announcement — the message a hare raiser would otherwise type by
/// hand into the kennel's WhatsApp group — and the two ways of sending it.
///
/// NO WhatsApp Business account, no Meta approval, no API key. This is the
/// admin's OWN WhatsApp on their own phone: the app pre-fills the message,
/// WhatsApp opens on the group picker, one tap sends. That is not a
/// compromise, it is the better design — the post comes from a number the
/// group already knows, into a group the admin is already in, and nothing
/// has to be added to 43 kennels' groups. A Business bot number would need
/// exactly that, for every kennel, forever (James, 2026-09-15).
///
/// What the mechanism cannot do, and that is fine: post without a tap, pick
/// the group itself, or confirm delivery. Publishing is a deliberate act; a
/// tap is the right amount of ceremony for it.
///
/// Built from the event and the kennel rather than an aggregate, because the
/// run editor holds a RunAdminAggregate and the share sheet a
/// RunDetailsAggregate, and both carry those two.
class RunAnnouncement {
  const RunAnnouncement({required this.event, required this.kennel});

  final EventModel event;
  final KennelsModel kennel;

  bool get _isCounted => event.isCountedRun != 0;

  /// The run's own page on the web. Counted runs have a real route; uncounted
  /// ones fall back to the legacy hash-URL, which still resolves.
  String get url => _isCounted
      ? '$BASE_HASHRUNS_DOT_ORG_URL${kennel.kennelUniqueShortName}/${event.eventNumber}'
      : '$BASE_HASHRUNS_DOT_ORG_URL#/RID?publicEventId=${event.publicEventId}';

  /// The same link with the answer on the end: `?RSVP=Yes` / `?RSVP=No`.
  /// Tapping it opens the app, records the RSVP, and lands on the check-in
  /// tab showing the tick and who else is coming (James, 2026-09-16). The
  /// legacy form already has a query inside its fragment, so the answer is
  /// appended with `&` there; DeepLinkService reads both shapes.
  String rsvpUrl(EnumRsvpState state) {
    final String answer = state == rsvpYes ? 'Yes' : 'No';
    return _isCounted ? '$url?RSVP=$answer' : '$url&RSVP=$answer';
  }

  String get _title {
    final String num = _isCounted && event.eventNumber > 0
        ? ' #${event.eventNumber}'
        : '';
    final String name = event.eventName.trim();
    return name.isEmpty
        ? '${kennel.kennelShortName}$num'
        : '${kennel.kennelShortName}$num – $name';
  }

  /// EventStartDatetime is the LOCAL wall-clock (see /hc-event-datetimes), so
  /// it is formatted as-is — the group is local too, and converting it would
  /// be the bug, not the fix.
  String get _when =>
      DateFormat('EEE d MMM, h:mm a').format(event.eventStartDatetime);

  String get _where {
    final String one = (event.locationOneLineDesc ?? '').trim();
    final String city = (event.locationCity ?? '').trim();
    if (one.isEmpty) return city;
    if (city.isEmpty || one.toLowerCase().contains(city.toLowerCase())) {
      return one;
    }
    return '$one, $city';
  }

  /// Price line, only when there is a price. Kennel defaults fill the gaps
  /// the same way the run-detail screen does.
  ///
  /// The kennel's currencySymbol is a TEMPLATE, not a prefix: the formatter
  /// does `symbol.replaceAll('^', amount)`, so "£^" renders £5.00 and "^ €"
  /// renders 5.00 €. A symbol with no caret would therefore swallow the
  /// number entirely, so one is supplied — better a bare "5.00" than a bare
  /// "£" in a message that is about to go to sixty people.
  String get _price {
    final String raw = kennel.currencySymbol ?? '';
    final String sym = raw.contains('^') ? raw : '$raw^';
    final double members =
        event.eventPriceForMembers ?? kennel.defaultPriceForMembers;
    final double nonMembers =
        event.eventPriceForNonMembers ?? kennel.defaultPriceForNonMembers;
    String money(double v) => IveCoreUtilities.getFormattedMoney(v, 2, sym);

    if (members <= 0 && nonMembers <= 0) return '';
    if (members == nonMembers || members <= 0) return money(nonMembers);
    if (nonMembers <= 0) return money(members);
    return '${money(members)} (members) · ${money(nonMembers)} (non-members)';
  }

  /// The message. WhatsApp renders *bold* and keeps line breaks, so this
  /// reads as a proper notice rather than a paragraph. Every line is guarded:
  /// a run with no hares or no price simply has no such line.
  String get text {
    final StringBuffer b = StringBuffer();
    b.writeln('*$_title*');
    b.writeln('📅 $_when');
    final String hares = (event.hares ?? '').trim();
    if (hares.isNotEmpty) b.writeln('🐰 Hares: $hares');
    final String where = _where;
    if (where.isNotEmpty) b.writeln('📍 $where');
    final String price = _price;
    if (price.isNotEmpty) b.writeln('💰 $price');

    final String desc = (event.eventDescription ?? '').trim();
    if (desc.isNotEmpty) {
      b.writeln();
      // Enough to say what kind of run it is, not the whole notice — the link
      // carries the rest, and a wall of text is what people scroll past.
      b.writeln(desc.length > 220 ? '${desc.substring(0, 217).trimRight()}…' : desc);
    }

    // A blank line between the links so each reads as its own thing, and
    // "I'll be there" rather than "I'm in" — plain words for hashers whose
    // first language is not English (James, 2026-09-16).
    b.writeln();
    b.writeln('🗺️ Details & map: $url');
    b.writeln();
    b.writeln("✅ I'll be there: ${rsvpUrl(rsvpYes)}");
    b.writeln();
    b.writeln("❌ Can't make it: ${rsvpUrl(rsvpNo)}");
    b.writeln();
    b.write('via Harrier Central');
    return b.toString();
  }

  /// The kennel's preferred platform (E9.F6). Drives the main button; the
  /// others sit behind its chevron.
  MessagingPlatform get preferred =>
      MessagingPlatform.fromCode(kennel.defaultMessagingPlatform);

  /// Sends via whichever platform is asked for, doing the most that platform
  /// allows. Returns true when the app itself took the message.
  Future<bool> sendVia(MessagingPlatform platform) async {
    switch (platform) {
      case MessagingPlatform.whatsApp:
        return postToWhatsApp();
      case MessagingPlatform.telegram:
        return _launchOrShare(
          Uri.parse('tg://msg?text=${Uri.encodeComponent(text)}'),
        );
      case MessagingPlatform.messenger:
        // Messenger's share takes a LINK only; the notice text is dropped.
        return _launchOrShare(
          Uri.parse('fb-messenger://share?link=${Uri.encodeComponent(url)}'),
        );
      case MessagingPlatform.signal:
      case MessagingPlatform.weChat:
        await shareAnywhere();
        return false;
    }
  }

  Future<bool> _launchOrShare(Uri uri) async {
    try {
      if (await canLaunchUrl(uri)) {
        if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return true;
      }
    } catch (_) {}
    await shareAnywhere();
    return false;
  }

  /// Opens WhatsApp with the message pre-filled; the admin picks the group
  /// and sends. Falls back to the OS share sheet when WhatsApp is not
  /// installed — or cannot be seen: iOS needs `whatsapp` in
  /// LSApplicationQueriesSchemes and Android needs a `<queries>` entry, and
  /// without them canLaunchUrl says no even when the app is there.
  ///
  /// Returns true when WhatsApp itself took the message.
  Future<bool> postToWhatsApp() async {
    final Uri wa = Uri.parse(
      'whatsapp://send?text=${Uri.encodeComponent(text)}',
    );
    try {
      if (await canLaunchUrl(wa)) {
        final bool ok = await launchUrl(wa, mode: LaunchMode.externalApplication);
        if (ok) return true;
      }
    } catch (_) {
      // Fall through to the share sheet.
    }
    await shareAnywhere();
    return false;
  }

  /// A two-row chooser — WhatsApp, or everything else — for the places that
  /// have ONE share button and no room for two. Returns after the send.
  Future<void> chooseAndSend(BuildContext context) async {
    final bool? whatsApp = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext c) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(height: 12),
            Text(
              'Announce this run',
              style: ts_titleMedium.copyWith(color: Colors.black87),
            ),
            ListTile(
              leading: MessagingPlatformGlyph(preferred, size: 30),
              title: Text('Share on ${preferred.label}',
                  style: const TextStyle(color: Colors.black87, fontSize: 17, fontWeight: FontWeight.w600)),
              subtitle: const Text('The notice, ready to send to the kennel group',
                  style: TextStyle(color: Colors.black54, fontSize: 14)),
              onTap: () => Navigator.of(c).pop(true),
            ),
            ListTile(
              leading: Icon(Icons.campaign_outlined, color: hc_blue, size: 30),
              title: const Text('Announce elsewhere',
                  style: TextStyle(color: Colors.black87, fontSize: 17, fontWeight: FontWeight.w600)),
              subtitle: const Text('Signal, Telegram, SMS, email…',
                  style: TextStyle(color: Colors.black54, fontSize: 14)),
              onTap: () => Navigator.of(c).pop(false),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (whatsApp == null) return;
    if (whatsApp) {
      await sendVia(preferred);
    } else {
      await shareAnywhere();
    }
  }

  /// The OS share sheet — Signal, Telegram, SMS, email, and WhatsApp too if
  /// that is where the user points it.
  Future<void> shareAnywhere() async {
    await SharePlus.instance.share(
      ShareParams(text: text, subject: _title),
    );
  }
}
