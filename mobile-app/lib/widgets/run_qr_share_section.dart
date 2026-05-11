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
          ],
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}
