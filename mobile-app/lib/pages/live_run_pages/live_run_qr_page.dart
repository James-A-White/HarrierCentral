import 'package:harrier_central/imports.dart';

class LiveRunQrController extends GetxController {
  LiveRunQrController({required this.run})
    : thisRunUrlForQr = _buildThisRunUrl(run),
      nextRunUrlForQr = _buildNextRunUrl(run),
      kennelUrlForQr = _buildKennelUrl(run) {
    LiveRunService.ensure();
  }

  final RunDetailsAggregate run;

  final String thisRunUrlForQr;
  final String nextRunUrlForQr;
  final String kennelUrlForQr;

  static String _buildThisRunUrl(RunDetailsAggregate run) {
    if (run.event.isCountedRun != 0) {
      return '$BASE_HASHRUNS_DOT_ORG_URL${run.kennel.kennelUniqueShortName}/${run.event.eventNumber}';
    }
    return '$BASE_HASHRUNS_DOT_ORG_URL#/RID?publicEventId=${run.event.publicEventId}';
  }

  static String _buildNextRunUrl(RunDetailsAggregate run) {
    return '$BASE_HASHRUNS_DOT_ORG_URL${run.kennel.kennelUniqueShortName}/nextrun';
  }

  static String _buildKennelUrl(RunDetailsAggregate run) {
    return run.event.isCountedRun != 0
        ? '$BASE_HASHRUNS_DOT_ORG_URL${run.kennel.kennelUniqueShortName}'
        : '';
  }
}

class LiveRunQrPage extends StatelessWidget {
  LiveRunQrPage({super.key, required this.run})
    : controller = Get.put(
        LiveRunQrController(run: run),
        tag: 'live-run-qr-${run.event.eventId}',
      );

  final RunDetailsAggregate run;
  final LiveRunQrController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: Backgrounds.defaultHcBackground(),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: RunQrShareSection(
            event: controller.run.event,
            kennel: controller.run.kennel,
            thisRunUrlForQr: controller.thisRunUrlForQr,
            nextRunUrlForQr: controller.nextRunUrlForQr,
            kennelUrlForQr: controller.kennelUrlForQr,
            kennelWebsiteUrl: controller.run.kennel.kennelWebsiteUrl,
          ),
        ),
      ),
    );
  }
}
