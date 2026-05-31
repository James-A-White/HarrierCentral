import 'package:curved_labeled_navigation_bar/curved_navigation_bar.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar_item.dart';
import 'package:harrier_central/imports.dart';
import 'package:harrier_central/pages/live_run_pages/live_run_chat_page.dart';
import 'package:harrier_central/pages/live_run_pages/live_run_general_page.dart';
import 'package:harrier_central/pages/live_run_pages/live_run_map_page.dart';
import 'package:harrier_central/pages/live_run_pages/live_run_qr_page.dart';

class LiveRunShellController extends GetxController {
  final RxInt tabIndex = 0.obs;

  void setTab(int i) => tabIndex.value = i;

  @override
  void onClose() {
    // Clean up LiveRunService when the shell closes.
    if (Get.isRegistered<LiveRunService>()) {
      Get.delete<LiveRunService>(force: true);
    }
    super.onClose();
  }
}

class LiveRunShell extends StatelessWidget {
  const LiveRunShell({super.key, required this.run});

  final RunDetailsAggregate run;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LiveRunShellController());

    // Ensure state service is available and set active run name for display.
    final liveRunState = LiveRunService.ensure();
    liveRunState.startRun(
      eventId: run.event.eventId,
      eventName: run.event.eventName,
    );

    final pages = <Widget>[
      LiveRunGeneralPage(run: run),
      LiveRunChatPage(run: run),
      LiveRunMapPage(run: run),
      LiveRunQrPage(run: run),
    ];

    return Obx(
      () => Scaffold(
        appBar: AppBar(
          backgroundColor: themeAppBarBackground,
          elevation: 3,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            run.event.eventName.isEmpty ? 'Live Run Mode' : run.event.eventName,
            style: ts_appBarTitle,
          ),
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () {
              Get.delete<LiveRunShellController>(force: true);
              Navigator.of(context).pop();
            },
          ),
          actions: [
            IconButton(
              tooltip: 'End run tracking',
              icon: const Icon(Icons.flag_outlined, color: Colors.white),
              onPressed: () async {
                final generalTag = 'live-run-general-${run.event.eventId}';
                if (!Get.isRegistered<LiveRunGeneralController>(
                  tag: generalTag,
                )) {
                  return;
                }
                final confirmed = await showDialog<bool>(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => AlertDialog(
                    title: Text('End Run?', style: ts_alertDialogTitle),
                    content: Text(
                      'Are you sure you want to end your run? '
                      'Once stopped, tracking cannot be restarted. '
                      'Your data will be saved.',
                      style: ts_alertDialogBody,
                    ),
                    actions: [
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade600,
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Keep Tracking', style: ts_button),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: hc_red,
                          foregroundColor: Colors.white,
                        ),
                        child: Text('End Run', style: ts_button),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  Get.find<LiveRunGeneralController>(tag: generalTag)
                      .stopTracking();
                }
              },
            ),
          ],
        ),
        body: pages[controller.tabIndex.value],
        bottomNavigationBar: CurvedNavigationBar(
          index: controller.tabIndex.value,
          backgroundColor: Colors.transparent,
          color: Colors.white,
          buttonBackgroundColor: hc_red,
          items: [
            CurvedNavigationBarItem(
              child: Obx(() => Icon(Icons.dashboard_customize,
                  color: controller.tabIndex.value == 0
                      ? Colors.white
                      : Colors.black54)),
              label: 'Tools',
            ),
            CurvedNavigationBarItem(
              child: Obx(() => Icon(Icons.chat_bubble_outline,
                  color: controller.tabIndex.value == 1
                      ? Colors.white
                      : Colors.black54)),
              label: 'Chat',
            ),
            CurvedNavigationBarItem(
              child: Obx(() => Icon(Icons.map,
                  color: controller.tabIndex.value == 2
                      ? Colors.white
                      : Colors.black54)),
              label: 'Map',
            ),
            CurvedNavigationBarItem(
              child: Obx(() => Icon(Icons.qr_code_2,
                  color: controller.tabIndex.value == 3
                      ? Colors.white
                      : Colors.black54)),
              label: 'QRs',
            ),
          ],
          onTap: controller.setTab,
        ),
      ),
    );
  }
}
