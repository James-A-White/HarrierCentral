import 'package:harrier_central/imports.dart';

/// The Support page: secret QR code, support code, Reload Data and (for the
/// harvest cohort) the diagnostic-log copy. Stateless over
/// [SupportController].
class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SupportController>(
      init: SupportController(),
      tag: SupportController.tag,
      builder: (SupportController c) => Obx(() {
        if (c.isReloading.value) return const SizedBox.shrink();
        final bool bootLogCopied = c.bootLogCopied.value;
        final AppBar appBar = AppBar(
          centerTitle: true,
          backgroundColor: themeAppBarBackground,
          iconTheme: const IconThemeData(color: Colors.white, size: 28.0),
          title: Text('Support', style: ts_appBarTitle),
        );
        return Stack(
          children: <Widget>[
            SizedBox(
              height: MediaQuery.sizeOf(context).height,
              width: MediaQuery.sizeOf(context).width,
            ),
            Positioned(
              top: 0,
              left: 0,
              width: MediaQuery.sizeOf(context).width,
              height: MediaQuery.sizeOf(context).height,
              child: AppScaffold(
                appBar: appBar,
                body: Container(
                  decoration: Backgrounds.defaultHcBackground(),
                  height:
                      MediaQuery.sizeOf(context).height -
                      appBar.preferredSize.height,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: 20,
                        left: 0,
                        right: 0,
                      ),
                      child: Column(
                        children: <Widget>[
                          AutoSizeText(
                            'Secret QR code for:',
                            //'QR Code for xxx',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            style: ts_headingLarge,
                          ),
                          const SizedBox(height: 15.0),
                          AutoSizeText(
                            c.userName,
                            //'QR Code for xxx',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            style: ts_titleVeryLarge,
                          ),
                          const SizedBox(height: 15.0),
                          SizedBox(
                            height:
                                (MediaQuery.sizeOf(context).width * 0.8 <
                                    MediaQuery.sizeOf(context).height * 0.4)
                                ? MediaQuery.sizeOf(context).width * 0.8
                                : MediaQuery.sizeOf(context).height * 0.4,
                            width:
                                (MediaQuery.sizeOf(context).width * 0.8 <
                                    MediaQuery.sizeOf(context).height * 0.4)
                                ? MediaQuery.sizeOf(context).width * 0.8
                                : MediaQuery.sizeOf(context).height * 0.4,
                            child: Stack(
                              alignment: AlignmentDirectional.center,
                              children: <Widget>[
                                QrImageView(
                                  backgroundColor: Colors.white,
                                  padding: const EdgeInsets.all(10.0),
                                  data:
                                      '$QR_PREFIX_USER_SECRET_CODE${c.userSecretCode.value.toUpperCase()}',
                                  //data: 'testing123',
                                  version: 5,
                                  //size: 200.0,
                                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10.0),
                          TextButton(
                            style: text_button_style,
                            child: Text(
                              'Learn more about this feature',
                              style: ts_button,
                              textAlign: TextAlign.center,
                            ),
                            onPressed: () async {
                              await _displayInstructions(context);
                            },
                          ),
                          const FancyDivider(
                            key: Key('7911393501'),
                            innerColor: Colors.white,
                            topMargin: 20.0,
                            bottomMargin: 20.0,
                          ),
                          Text(
                            'Support Code:',
                            style: ts_headingLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 15.0),
                          Text(
                            c.supportCode,
                            style: ts_titleVeryLarge,
                            textAlign: TextAlign.center,
                          ),
                          // ---------------- Reload Data (from My Profile,
                          // 2026-07-31)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                const FancyDivider(
                                  key: Key('support_reload_divider'),
                                  innerColor: Colors.white,
                                  topMargin: 30.0,
                                  bottomMargin: 20.0,
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    'Reload Data',
                                    style: ts_headingLarge,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    'To maximize performance and support the ability to operate when not on a network, Harrier Central stores data relevant to your Hash experience on your phone.\r\n\r\nOn rare occasions, this data may become out of sync with the master data stored in our central servers. To reload your Hash data, press the "Reload Data" button below. This will clear the existing data, restart Harrier Central, and reload the data from our servers.',
                                    style: ts_body,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: <Widget>[
                                      StyleForConnected(
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.only(
                                              top: 8,
                                              bottom: 8,
                                              left: 20,
                                              right: 20,
                                            ),
                                          ),
                                          onPressed: () async {
                                            await Utilities.showAlert(
                                              'Reload Data',
                                              'Refreshing the cache removes all of the data stored on your phone by the Harrier Central app and reloads your profile from our backend servers.\r\n\r\nNormally you will only need to do this when asked to do so by our support team.',
                                              'Reload data',
                                              showCancelButton: true,
                                              cancelButtonText: 'Cancel',
                                            ).then((bool? result) async {
                                              if (result ?? false) {
                                                await c.reloadData();
                                              }
                                            });
                                          },
                                          child: Text(
                                            'Reload Data',
                                            style: ts_button,
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // ---------------- Diagnostic Logs (from My
                          // Profile, 2026-07-31; harvest-cohort gated as
                          // before)
                          if (getBoolPref(BoolPrefsEnum.debugHarvestEnabled) ==
                              true)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20.0,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  const FancyDivider(
                                    key: Key('support_diaglog_divider'),
                                    innerColor: Colors.white,
                                    topMargin: 30.0,
                                    bottomMargin: 20.0,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      'Diagnostic Logs',
                                      style: ts_headingLarge,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      'Copy the app\'s startup log to the clipboard for diagnostic purposes.',
                                      style: ts_body,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 15.0,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: <Widget>[
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: bootLogCopied
                                                ? Colors.green.shade700
                                                : hc_blue,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 8.0,
                                              horizontal: 15.0,
                                            ),
                                          ),
                                          onPressed: () => unawaited(
                                            c.copyBootLogToClipboard(),
                                          ),
                                          icon: Icon(
                                            bootLogCopied
                                                ? Icons.check
                                                : Icons.copy,
                                            size: 16,
                                          ),
                                          label: Text(
                                            bootLogCopied
                                                ? 'Copied!'
                                                : 'Copy log to clipboard',
                                            style: ts_button,
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          //   innerColor: Colors.white,
                          //   topMargin: 40.0,
                          //   bottomMargin: 30.0,
                          //   'Invite Code:',
                          //   style: ts_headingLarge,
                          //   textAlign: TextAlign.center,

                          //       children: <Widget>[
                          //         Container(
                          //           //color: Colors.white,
                          //             color: Colors.yellow[100],
                          //             autocorrect: false,
                          //             controller: _resetCodeTextController,
                          //             focusNode: _resetCodeFocusNode,
                          //             decoration: _resetCodeDecoration,
                          //             // },
                          //             keyboardType: TextInputType.text,
                          //             style: const TextStyle(
                          //               color: Colors.yellow,
                          //               fontFamily: 'Poppins',
                          //                           SyncUserDataService.flagAllMasterData,
                          //                           false,
                          //                           debugText: 'support_page: All master data',

                          //                       final AuthorizeDeviceService srv = AuthorizeDeviceService();

                          //                 },
                          //                 child: Text(
                          //                   'Reset App',
                          //                   style: ts_button,
                          //                           SyncUserDataService.flagAllMasterData,
                          //                           false,
                          //                           debugText: 'support_page: All master data 2',

                          //                       final AuthorizeDeviceService srv = AuthorizeDeviceService();

                          //                 },
                          //                 child: Text(
                          //                   'Reload Database',
                          //                   style: ts_button,
                          //       ],
                          const SizedBox(width: 40, height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            OfflineModeRibbon(
              lastSync: getDatePref(DatePrefsEnum.lastSuccessfulUserDataSync),
              ribbonImage: 'images/icons/offline_mode.png',
              refreshFunction: () => c.update(),
            ),
          ],
        );
      }),
    );
  }

  Future<bool?> _displayInstructions(BuildContext context) async {
    return showDialog<bool?>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('About your QR Secret Code', style: ts_alertDialogTitle),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'Harrier Central does not use either usernames or passwords. Instead we identify you using a \'secret QR code\'. This QR code can be used to allow Harrier Central running on another device to access your account. If you want to install Harrier Central on another device, when you first install the app, select \'existing user\' and use the scanner to scan this code. The app on the new device will then be configured to access your account',
                  textAlign: TextAlign.justify,
                  style: ts_alertDialogBody,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: text_button_style,
              child: Text('OK, Got it!', style: ts_button, textAlign: TextAlign.center),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }
}
