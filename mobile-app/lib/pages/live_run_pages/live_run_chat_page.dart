import 'package:harrier_central/imports.dart';

class LiveRunChatController extends GetxController {
  LiveRunChatController({required this.run}) {
    LiveRunService.ensure();
  }

  final RunDetailsAggregate run;
}

class LiveRunChatPage extends StatelessWidget {
  LiveRunChatPage({super.key, required this.run})
    : controller = Get.put(
        LiveRunChatController(run: run),
        tag: 'live-run-chat-${run.event.eventId}',
      );

  final RunDetailsAggregate run;
  final LiveRunChatController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: Backgrounds.defaultHcBackground(),
      child: ChatPage(
        eventId: run.event.eventId,
        publicEventId: run.event.publicEventId,
      ),
    );
  }
}
