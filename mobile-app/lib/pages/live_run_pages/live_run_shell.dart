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
              tooltip: 'End run tracking (coming soon)',
              icon: const Icon(Icons.flag_outlined, color: Colors.white),
              onPressed: () {
                // Placeholder for future end-run logic.
                Get.snackbar(
                  'End run tracking',
                  'This will be wired up soon.',
                  snackPosition: SnackPosition.BOTTOM,
                );
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
              child: Icon(Icons.dashboard_customize, color: Colors.black54),
              label: 'Tools',
            ),
            CurvedNavigationBarItem(
              child: Icon(Icons.chat_bubble_outline, color: Colors.black54),
              label: 'Chat',
            ),
            CurvedNavigationBarItem(
              child: Icon(Icons.map, color: Colors.black54),
              label: 'Map',
            ),
            CurvedNavigationBarItem(
              child: Icon(Icons.qr_code_2, color: Colors.black54),
              label: 'QRs',
            ),
          ],
          onTap: controller.setTab,
        ),
      ),
    );
  }
}
