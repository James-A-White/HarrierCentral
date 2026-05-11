import 'package:curved_labeled_navigation_bar/curved_navigation_bar.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar_item.dart';
import 'package:harrier_central/imports.dart';
import 'package:harrier_central/pages/live_run_pages/live_run_chat_page.dart';
import 'package:harrier_central/pages/live_run_pages/live_run_general_page.dart';
import 'package:harrier_central/pages/live_run_pages/live_run_map_page.dart';
import 'package:harrier_central/pages/live_run_pages/live_run_qr_page.dart';

class LiveRunShell extends StatefulWidget {
  const LiveRunShell({super.key, required this.run});

  final RunDetailsAggregate run;

  @override
  State<LiveRunShell> createState() => _LiveRunShellState();
}

class _LiveRunShellState extends State<LiveRunShell> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Ensure state service is available and set active run name for display.
    final liveRunState = LiveRunService.ensure();
    liveRunState.startRun(
      eventId: widget.run.event.eventId,
      eventName: widget.run.event.eventName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      LiveRunGeneralPage(run: widget.run),
      LiveRunChatPage(run: widget.run),
      LiveRunMapPage(run: widget.run),
      LiveRunQrPage(run: widget.run),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: themeAppBarBackground,
        elevation: 3,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.run.event.eventName.isEmpty
              ? 'Live Run Mode'
              : widget.run.event.eventName,
          style: ts_appBarTitle,
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
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
      body: pages[_currentIndex],
      bottomNavigationBar: CurvedNavigationBar(
        index: _currentIndex,
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
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
