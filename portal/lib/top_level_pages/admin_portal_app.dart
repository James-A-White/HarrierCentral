import 'package:hcportal/imports.dart';
import 'package:web/web.dart' as web;

// File-level globals — accessed across the app via imports.dart
late Box<dynamic> box;
Rx<PackageInfo?> packageInfo = Rx<PackageInfo?>(null);

class AdminPortalApp extends StatelessWidget {
  const AdminPortalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AdminPortalController>(
      init: AdminPortalController(),
      builder: (c) => Scaffold(
        appBar: AppBar(
          title: const Text('Harrier Central'),
        ),
        body: !c.isReady
            ? const Center(child: CircularProgressIndicator())
            : !((box.get(HIVE_IS_LOGGED_IN) ?? false) as bool)
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
                : Column(
                    children: <Widget>[
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            const SizedBox(height: 15),
                            Text(
                              'Version ${packageInfo.value?.version ?? 'unknown'}',
                              style: const TextStyle(
                                color: Colors.black38,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              'Welcome ${c.hashName}',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 30,
                              ),
                            ),
                            Text(
                              '(${c.firstName} ${c.lastName})',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 20,
                              ),
                            ),
                            if (c.allKennels.length > 10) ...[
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Container(
                                      padding:
                                          const EdgeInsets.only(bottom: 7),
                                      child: TextField(
                                        autocorrect: false,
                                        onChanged: c.filterKennels,
                                        focusNode: c.searchFocusNode,
                                        controller: c.searchController,
                                        keyboardType: TextInputType.text,
                                        style: const TextStyle(
                                          fontFamily: 'WorkSansSemiBold',
                                          fontSize: 16,
                                          color: Colors.black,
                                        ),
                                        decoration: const InputDecoration(
                                          filled: false,
                                          fillColor: Colors.transparent,
                                          border: InputBorder.none,
                                          icon: Icon(
                                            FontAwesome.search,
                                            color: Colors.black,
                                          ),
                                          hintText: 'Search...',
                                          hintStyle: TextStyle(
                                            fontFamily: 'WorkSansSemiBold',
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 40,
                                    child: TextButton(
                                      style: TextButton.styleFrom(
                                        textStyle: TextStyle(
                                          color: Colors.grey.shade900,
                                        ),
                                      ),
                                      child: const Text('X'),
                                      onPressed: () {
                                        c.searchController.text = '';
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 30),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: SingleChildScrollView(
                            primary: false,
                            child: StaggeredGrid.count(
                              crossAxisCount: 6,
                              mainAxisSpacing: 4,
                              crossAxisSpacing: 4,
                              children: c.filteredKennels.map(
                                (HasherKennelsModel e) {
                                  return StaggeredGridTile.count(
                                    crossAxisCellCount: e.isAdmin ? 2 : 1,
                                    mainAxisCellCount: e.isAdmin ? 2 : 1,
                                    child: ElevatedButton(
                                      style: ButtonStyle(
                                        backgroundColor:
                                            WidgetStateProperty.all<Color>(
                                          Colors.white,
                                        ),
                                        shape: WidgetStateProperty.all<
                                            OutlinedBorder>(
                                          RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                      ),
                                      onPressed: () async {
                                        if (e.isAdmin) {
                                          await Get.to<RunListPage>(
                                            () => RunListPage(e),
                                          );
                                        } else {
                                          await IveCoreUtilities.showAlert(
                                            navigatorKey.currentContext!,
                                            'Feature not available',
                                            'Currently the Harrier Central portal is only\r\navailable to Kennel administrators.\r\n\r\nYou are not an administrator for\r\n${e.kennelName}.\r\n\r\nBut keep watching this space! We will have\r\nnew features for all Hashers on our Web\r\nportal soon!',
                                            'OK',
                                          );
                                        }
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: KennelLogo(
                                          kennelLogoUrl: e.kennelLogo,
                                          kennelShortName: e.kennelShortName,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ).toList(),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            if ((c.publicHasherId.toUpperCase() ==
                                    HC_PORTAL_ADMIN_OPEE) ||
                                (c.publicHasherId.toUpperCase() ==
                                    HC_PORTAL_ADMIN_TUNA)) ...<Widget>[
                              const SizedBox(width: 20),
                              ElevatedButton(
                                child: Baseline(
                                  baseline: 16,
                                  baselineType: TextBaseline.alphabetic,
                                  child: Text(
                                    'Open monitor',
                                    style: buttonLabelStyleMedium,
                                  ),
                                ),
                                onPressed: () async {
                                  await Get.to<UsageDataPage>(
                                      UsageDataPage.new);
                                },
                              ),
                              const SizedBox(width: 20),
                            ],
                            ElevatedButton(
                              child: Baseline(
                                baseline: 16,
                                baselineType: TextBaseline.alphabetic,
                                child: Text(
                                  'Log out',
                                  style: buttonLabelStyleMedium,
                                ),
                              ),
                              onPressed: () async {
                                await box.clear();
                                web.window.location.reload();
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
