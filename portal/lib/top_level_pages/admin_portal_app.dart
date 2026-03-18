import 'package:hcportal/imports.dart';

// File-level globals — accessed across the app via imports.dart
late Box<dynamic> box;
Rx<PackageInfo?> packageInfo = Rx<PackageInfo?>(null);

class AdminPortalApp extends StatelessWidget {
  const AdminPortalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AdminPortalController>(
      init: AdminPortalController(),
      builder: (c) {
        final isLoggedIn = (box.get(HIVE_IS_LOGGED_IN) ?? false) as bool;

        // Auto-navigate to the combined run-list page once kennels are loaded.
        if (c.isReady && isLoggedIn && c.allKennels.isNotEmpty &&
            !c.hasNavigated) {
          c.hasNavigated = true;
          final firstKennel = c.allKennels.firstWhere(
            (k) => k.isAdmin,
            orElse: () => c.allKennels.first,
          );
          WidgetsBinding.instance.addPostFrameCallback((_) {
            unawaited(
              Get.off(
                () => RunListPage(
                  firstKennel,
                  allKennels: c.allKennels,
                  publicHasherId: c.publicHasherId,
                ),
              ),
            );
          });
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Harrier Central')),
          body: !c.isReady
              ? const Center(child: CircularProgressIndicator())
              : !isLoggedIn
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          const Text(
                            'Use the scanner in your Harrier Central app\r\nby pressing this icon from the main window',
                            style: TextStyle(color: Colors.black, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              MaterialCommunityIcons.qrcode_scan,
                              color: Colors.blue.shade900,
                              size: 35,
                            ),
                          ),
                          const Text(
                            'and scan the QR code below to\r\nlog into the Harrier Central portal',
                            style: TextStyle(color: Colors.black, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.only(top: 20, bottom: 150),
                            child: QrImageView(
                              data: QR_PREFIX_FOR_WEB_PORTAL_AUTHENTICATION +
                                  c.authCode,
                              size: 200,
                            ),
                          ),
                        ],
                      ),
                    )
                  : const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
