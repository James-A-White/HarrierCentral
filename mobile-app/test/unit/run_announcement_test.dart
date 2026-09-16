import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/imports.dart';

/// The run announcement is a pure function of the event and the kennel, and
/// its text IS the feature — it is what lands in the kennel's WhatsApp group.
/// These pin the shape: which lines appear, which are suppressed, and which
/// link is used.
void main() {
  EventModel event({
    String name = 'Borough',
    int number = 2851,
    int counted = 1,
    String? hares = 'Run2Eat',
    String? where = 'The Victoria',
    String? city = 'London',
    double? members,
    double? nonMembers,
    String? description,
  }) => EventModel(
    eventId: 'e1',
    publicEventId: 'pub-e1',
    eventStartDatetime: DateTime(2026, 9, 19, 12, 0),
    eventStartDatetimeGmt: DateTime.utc(2026, 9, 19, 11, 0),
    kennelId: 'k1',
    isVisible: 1,
    isCountedRun: counted,
    isPromotedEvent: 0,
    eventGeographicScope: 0,
    eventInboundIntegrationId: 0,
    eventNumber: number,
    eventName: name,
    countryId: 'gb',
    doTrackHashCash: 0,
    tags1: 0,
    tags2: 0,
    tags3: 0,
    useFbLocation: 0,
    useFbLatLon: 0,
    useFbRunDetails: 0,
    useFbImage: 0,
    hares: hares,
    locationOneLineDesc: where,
    locationCity: city,
    eventPriceForMembers: members,
    eventPriceForNonMembers: nonMembers,
    eventDescription: description,
  );

  KennelsModel kennel({
    double members = 0,
    double nonMembers = 0,
    // A TEMPLATE, as stored: the formatter puts the amount where the ^ is.
    String? symbol = '£^',
  }) => KennelsModel(
    kennelId: 'k1',
    publicKennelId: 'pub-k1',
    cityId: 'c',
    regionId: 'r',
    countryId: 'gb',
    kennelName: 'London Hash House Harriers',
    kennelShortName: 'LH3',
    kennelUniqueShortName: 'lh3',
    kennelLogo: '',
    kennelPinColor: 0,
    disseminateAllowWebLinks: 1,
    kennelStatus: 1,
    canEditRunAttendence: 1,
    allowNegativeCredit: 0,
    allowSelfPayment: 0,
    defaultPriceForMembers: members,
    defaultPriceForNonMembers: nonMembers,
    membershipDurationInMonths: 12,
    defaultRunStartTime: DateTime(2000, 1, 1, 12),
    currencySymbol: symbol,
  );

  group('RunAnnouncement text', () {
    test('a full run reads as a notice: bold title, date, hares, venue, link', () {
      final String t = RunAnnouncement(event: event(), kennel: kennel()).text;
      final List<String> lines = t.split('\n');

      expect(lines.first, '*LH3 #2851 – Borough*',
          reason: 'WhatsApp bold is a single asterisk pair, and the title '
              'carries kennel, number and name');
      expect(lines[1], '📅 Sat 19 Sep, 12:00 PM',
          reason: 'the LOCAL wall-clock, formatted as-is — not converted');
      expect(lines[2], '🐰 Hares: Run2Eat');
      expect(lines[3], '📍 The Victoria, London');
      expect(t, contains('Details & map: https://www.hashruns.org/lh3/2851\n'));
      expect(t, endsWith('via Harrier Central'));
    });

    test('the RSVP links carry the answer as a query on the run URL', () {
      final RunAnnouncement a = RunAnnouncement(event: event(), kennel: kennel());
      expect(a.rsvpUrl(rsvpYes), 'https://www.hashruns.org/lh3/2851?RSVP=Yes');
      expect(a.rsvpUrl(rsvpNo), 'https://www.hashruns.org/lh3/2851?RSVP=No');
      final List<String> lines = a.text.split('\n');
      expect(lines, contains("✅ I'm in: https://www.hashruns.org/lh3/2851?RSVP=Yes"));
      expect(lines, contains("❌ Can't make it: https://www.hashruns.org/lh3/2851?RSVP=No"));
      expect(
        lines.indexWhere((String l) => l.startsWith('Details')),
        lessThan(lines.indexWhere((String l) => l.startsWith('✅'))),
        reason: 'the plain link comes first so WhatsApp previews the run, not the answer',
      );
    });

    test('an uncounted run appends the answer to the legacy fragment query', () {
      final RunAnnouncement a = RunAnnouncement(
        event: event(counted: 0, number: 0),
        kennel: kennel(),
      );
      expect(a.rsvpUrl(rsvpYes),
          'https://www.hashruns.org/#/RID?publicEventId=pub-e1&RSVP=Yes');
      expect(DeepLinkService.parse(Uri.parse(a.rsvpUrl(rsvpNo)))!.rsvp, rsvpNo,
          reason: 'what the notice writes, the app must read back');
    });

    test('lines with nothing to say are absent, not blank', () {
      final String t = RunAnnouncement(
        event: event(hares: '', where: null, city: null),
        kennel: kennel(),
      ).text;
      expect(t, isNot(contains('Hares')));
      expect(t, isNot(contains('📍')));
      expect(t, isNot(contains('💰')), reason: 'no price anywhere → no line');
    });

    test('venue does not repeat the city when it already names it', () {
      final String t = RunAnnouncement(
        event: event(where: 'The Victoria, London', city: 'London'),
        kennel: kennel(),
      ).text;
      expect(t, contains('📍 The Victoria, London'));
      expect(t, isNot(contains('London, London')));
    });

    test('price: kennel defaults fill in, and equal prices print once', () {
      final String same = RunAnnouncement(
        event: event(),
        kennel: kennel(members: 5, nonMembers: 5),
      ).text;
      expect(same, contains('💰 £5.00'));
      expect(same, isNot(contains('members')));

      final String split = RunAnnouncement(
        event: event(members: 5, nonMembers: 7),
        kennel: kennel(),
      ).text;
      expect(split, contains('💰 £5.00 (members) · £7.00 (non-members)'));
    });

    test('a symbol stored without its caret still shows the amount', () {
      // The formatter swallows the number when the template has no ^;
      // the announcement must never post "💰 £" to a group.
      final String t = RunAnnouncement(
        event: event(),
        kennel: kennel(members: 5, nonMembers: 5, symbol: '£'),
      ).text;
      expect(t, contains('💰 £5.00'));

      final String none = RunAnnouncement(
        event: event(),
        kennel: kennel(members: 5, nonMembers: 5, symbol: null),
      ).text;
      expect(none, contains('💰 5.00'));
    });

    test('a long description is cut with an ellipsis, a short one kept whole', () {
      final String short = RunAnnouncement(
        event: event(description: 'Bring a torch.'),
        kennel: kennel(),
      ).text;
      expect(short, contains('\nBring a torch.\n'));

      final String long = RunAnnouncement(
        event: event(description: 'x' * 400),
        kennel: kennel(),
      ).text;
      expect(long, contains('…'));
      expect(long, isNot(contains('x' * 300)));
    });

    test('an uncounted run has no number in the title and uses the legacy link', () {
      final String t = RunAnnouncement(
        event: event(counted: 0, number: 0),
        kennel: kennel(),
      ).text;
      expect(t.split('\n').first, '*LH3 – Borough*');
      expect(t, contains('#/RID?publicEventId=pub-e1'));
      expect(t, isNot(contains('hashruns.org/lh3/0')));
    });
  });
}
