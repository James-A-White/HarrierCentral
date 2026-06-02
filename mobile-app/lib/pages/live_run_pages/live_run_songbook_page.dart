import 'package:harrier_central/imports.dart';

class LiveRunSongbookPage extends StatelessWidget {
  const LiveRunSongbookPage({super.key, required this.run});

  final RunDetailsAggregate run;

  @override
  Widget build(BuildContext context) {
    return SongsPage(eventId: run.event.eventId);
  }
}
