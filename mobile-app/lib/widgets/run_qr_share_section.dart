import 'package:harrier_central/imports.dart';

class RunQrShareSection extends StatelessWidget {
  const RunQrShareSection({
    super.key,
    required this.event,
    required this.kennel,
    required this.thisRunUrlForQr,
    required this.nextRunUrlForQr,
    required this.kennelUrlForQr,
    this.kennelWebsiteUrl,
  });

  final EventModel event;
  final KennelsModel kennel;
  final String thisRunUrlForQr;
  final String nextRunUrlForQr;
  final String kennelUrlForQr;
  final String? kennelWebsiteUrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        OverflowBar(
          spacing: 80,
          overflowSpacing: 40,
          alignment: MainAxisAlignment.center,
          overflowAlignment: OverflowBarAlignment.center,
          children: <Widget>[
            QrGroup(
              context: context,
              title: 'Run #${event.eventNumber}',
              description: 'this run',
              url: thisRunUrlForQr,
              helpTitle: 'URL for Hash #${event.eventNumber}',
              helpText:
                  "Here's a permanent link to Hash #${event.eventNumber} (${event.eventName}).\r\n\r\nShare it with others to spread the word about this hash!",
            ),
            QrGroup(
              context: context,
              title: 'Next ${kennel.kennelShortName} Run',
              description: 'next ${kennel.kennelShortName} run',
              url: nextRunUrlForQr,
              helpTitle: 'URL for Next Hash',
              helpText:
                  "Want to know what's next for ${kennel.kennelShortName}?\r\n\r\nThis link always points to the next ${kennel.kennelShortName} Hash run - perfect for bookmarking or sharing with friends!",
            ),
            if (kennelUrlForQr.isNotEmpty) ...<Widget>[
              QrGroup(
                context: context,
                title: '${kennel.kennelShortName} upcoming Runs',
                description: '${kennel.kennelName} upcoming runs',
                url: kennelUrlForQr,
                helpTitle: 'URL for upcoming ${kennel.kennelShortName} runs',
                helpText:
                    "This link opens a page with all upcoming ${kennel.kennelShortName} runs.\r\n\r\nNavigate to this page and scroll down to see everything that's planned!",
              ),
            ],
            if ((kennelWebsiteUrl ?? '').isNotEmpty &&
                kennelWebsiteUrl!.toLowerCase().startsWith('http')) ...<Widget>[
              QrGroup(
                context: context,
                title: '${kennel.kennelShortName} Website',
                description: '${kennel.kennelName} Website',
                url: kennelWebsiteUrl!,
                helpTitle: '${kennel.kennelShortName} Website',
                helpText:
                    "This link takes you to the ${kennel.kennelName} website - your go-to place for everything about Hashing with ${kennel.kennelShortName}!",
              ),
            ],
            // Global links — always shown at the very bottom (2026-07-31).
            QrGroup(
              context: context,
              title: 'Global Hash List',
              description: 'the global hash list',
              url: BASE_HASHRUNS_DOT_ORG_URL,
              helpTitle: 'Global Hash List',
              helpText:
                  'www.hashruns.org lists upcoming hash runs from kennels all over the world.\r\n\r\nUse it to find a hash wherever your travels take you!',
            ),
            QrGroup(
              context: context,
              title: 'Harrier Central',
              description: 'the Harrier Central website',
              url: HARRIER_CENTRAL_WEBSITE_URL,
              helpTitle: 'Harrier Central',
              helpText:
                  'www.harriercentral.com is the home of Harrier Central - the platform behind this app, where kennels can learn what it does and how to get started.',
            ),
            QrGroup(
              context: context,
              title: 'Harrier Central iOS App',
              description: 'Harrier Central on the App Store',
              url: APP_STORE_IOS_URL,
              helpTitle: 'Harrier Central for iPhone',
              helpText:
                  'Download Harrier Central for iPhone from the App Store.\r\n\r\nShare this link - or let friends scan the QR code - to get them hashing with the app!',
            ),
            QrGroup(
              context: context,
              title: 'Harrier Central Android App',
              description: 'Harrier Central on Google Play',
              url: APP_STORE_ANDROID_URL,
              helpTitle: 'Harrier Central for Android',
              helpText:
                  'Download Harrier Central for Android from Google Play.\r\n\r\nShare this link - or let friends scan the QR code - to get them hashing with the app!',
            ),
          ],
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}
