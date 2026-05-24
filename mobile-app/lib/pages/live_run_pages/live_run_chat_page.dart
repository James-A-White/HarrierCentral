import 'package:harrier_central/imports.dart';

class LiveRunChatPage extends StatelessWidget {
  const LiveRunChatPage({super.key, required this.run});

  final RunDetailsAggregate run;

  @override
  Widget build(BuildContext context) {
    LiveRunService.ensure();
    return Container(
      decoration: Backgrounds.defaultHcBackground(),
      child: ChatPage(
        eventId: run.event.eventId,
        publicEventId: run.event.publicEventId,
      ),
    );
  }
}
