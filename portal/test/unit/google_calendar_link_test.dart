import 'package:flutter_test/flutter_test.dart';
import 'package:hcportal/util/google_calendar_link.dart';

// The same cases the API's GoogleCalendarIcsUrl was checked against
// (Dayton H3's calendar, 2026-10-15): keep the three copies in step.
void main() {
  test('Google Calendar links are recognised', () {
    expect(isGoogleCalendarLink('https://calendar.google.com/calendar/embed?src=dh3calendar%40gmail.com&ctz=America%2FNew_York'), isTrue);
    expect(isGoogleCalendarLink('https://calendar.google.com/calendar/u/0?cid=ZGgzY2FsZW5kYXJAZ21haWwuY29t'), isTrue);
    expect(isGoogleCalendarLink('https://calendar.google.com/calendar/ical/dh3calendar%40gmail.com/public/basic.ics'), isTrue);
    expect(isGoogleCalendarLink('  https://calendar.google.com/calendar/embed?src=x%40group.calendar.google.com  '), isTrue);
  });

  test('anything else is refused', () {
    expect(isGoogleCalendarLink('https://daytonhhh.org/hashevents/'), isFalse);
    expect(isGoogleCalendarLink('https://calendar.google.com/calendar/r'), isFalse); // no calendar named
    expect(isGoogleCalendarLink('http://calendar.google.com/calendar/embed?src=a%40b.c'), isFalse); // not https
    expect(isGoogleCalendarLink('https://calendar.google.com.evil.io/calendar/embed?src=a%40b.c'), isFalse);
    expect(isGoogleCalendarLink('https://outlook.office365.com/owa/calendar/x/calendar.ics'), isFalse);
    expect(isGoogleCalendarLink(''), isFalse);
    expect(isGoogleCalendarLink(null), isFalse);
  });
}
