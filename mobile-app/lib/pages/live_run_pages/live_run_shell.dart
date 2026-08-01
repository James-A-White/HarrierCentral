import 'package:curved_labeled_navigation_bar/curved_navigation_bar.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar_item.dart';
import 'package:harrier_central/imports.dart';
import 'package:harrier_central/pages/live_run_pages/live_run_charges_page.dart';
import 'package:harrier_central/pages/live_run_pages/live_run_chat_page.dart';
import 'package:harrier_central/pages/live_run_pages/live_run_general_page.dart';
import 'package:harrier_central/pages/live_run_pages/live_run_map_page.dart';
import 'package:harrier_central/pages/live_run_pages/live_run_qr_page.dart';
import 'package:harrier_central/pages/live_run_pages/live_run_rose_page.dart';
import 'package:harrier_central/pages/live_run_pages/live_run_songbook_page.dart';

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

    // Charges (Down Downs) is admin-only — mirror hcapp_getDownDowns so a
    // non-admin opening the tab doesn't fire a request the server rejects. The
    // tab stays (fixed-index layout); only its content is gated.
    // See /hc-authorizations.
    final bool canViewCharges = canAccessFeature(
      KennelFeature.manageDownDowns,
      appAccessFlags: run.extensions.appAccessFlags,
      mismanagementRoles: run.extensions.mismanagementRoles,
      kennelOverrideJson: run.kennel.permissionOverrideJson,
    );

    final pages = <Widget>[
      LiveRunGeneralPage(run: run),
      LiveRunChatPage(run: run),
      LiveRunMapPage(run: run),
      canViewCharges
          ? LiveRunChargesPage(
              kennelId: run.kennel.kennelId,
              eventId: run.event.eventId,
              eventName: run.event.eventName,
              kennelSlug: run.kennel.kennelUniqueShortName,
              eventNumber: run.event.absoluteEventNumber ?? 0,
            )
          : const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'Charges are only available to the GM, VGMs, RAs, and '
                  'Beermeister for this kennel.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
      LiveRunSongbookPage(run: run),
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
              tooltip: 'Where is everyone?',
              icon: const Icon(Icons.radar, color: Colors.white),
              onPressed: () => Get.to(() => LiveRunRosePage(run: run)),
            ),
            IconButton(
              tooltip: 'Share QR codes',
              icon: const Icon(Icons.qr_code_2, color: Colors.white),
              onPressed: () => Get.to(() => LiveRunQrPage(run: run)),
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
              child: Obx(() => Icon(Icons.sports_bar,
                  color: controller.tabIndex.value == 3
                      ? Colors.white
                      : Colors.black54)),
              label: 'Charges',
            ),
            CurvedNavigationBarItem(
              child: Obx(() => Icon(Icons.music_note,
                  color: controller.tabIndex.value == 4
                      ? Colors.white
                      : Colors.black54)),
              label: 'Songs',
            ),
          ],
          onTap: controller.setTab,
        ),
      ),
    );
  }
}
