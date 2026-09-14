import 'package:harrier_central/imports.dart';

//

class SupportPage extends StatefulWidget {
  //final FutureRunScopedModel futureRunsModel;

  const SupportPage({super.key});

  @override
  SupportPageState createState() => SupportPageState();
}

class SupportPageState extends State<SupportPage> {
  // final String _firstName = getStringPref(StringPrefsEnum.firstName) ?? '';
  // final String _lastName = getStringPref(StringPrefsEnum.lastName) ?? '';
  // final String _email = getStringPref(StringPrefsEnum.email) ?? '';
  // final String _hashName = getStringPref(StringPrefsEnum.hashName) ?? '';

  // final FocusNode _resetCodeFocusNode = FocusNode();
  // final TextEditingController _resetCodeTextController =
  //     TextEditingController();
  // final InputDecoration _resetCodeDecoration = InputDecoration(
  //   labelText: 'Invite Code',
  //   fillColor: hc_red,
  //   border: OutlineInputBorder(
  //     borderRadius: BorderRadius.circular(25.0),
  //     borderSide: const BorderSide(),
  //   ),
  // );

  @override
  void initState() {
    super.initState();
    _loadSecretCode();
    unawaited(_loadChatRooms());
  }

  /// The rooms this hasher may enter, as the SERVER lists them. Not a
  /// hard-coded set: a room added to HC6.ChatRoomCatalog() appears here with
  /// no app release. The SPs check membership themselves — this only decides
  /// what is drawn.
  List<ChatRoom>? _rooms;

  /// Null [_rooms] with this set means the call failed, which is NOT the same
  /// as holding no roles. Most hashers are in no room at all, and drawing a
  /// failure as "you have none" is the same trap as flashing "No runs" while
  /// the cache loads.
  bool _roomsFailed = false;

  Future<void> _loadChatRooms() async {
    final List<ChatRoom>? rooms = await ChatRoomService.fetchRooms();
    if (!mounted) return;
    setState(() {
      _rooms = rooms;
      _roomsFailed = rooms == null;
    });
  }

  Future<void> _openRoom(ChatRoom room) async {
    // Delete first AND after: the controller is Get.put by the page, so a
    // stale one would otherwise be reused for the next room opened.
    await Get.delete<ChatPageController>(force: true);
    // ChatScaffold, not ChatPage: pushed bare, a room had no app bar and no
    // back button at all (shipped that way in 3.1.0+1358). The wrapper also
    // carries the pin icon.
    await Get.to<ChatScaffold>(
      () => ChatScaffold.room(
        roomType: room.roomType,
        title: room.roomName,
        key: UniqueKey(),
      ),
    );
    await Get.delete<ChatPageController>(force: true);
    // Unread counts move while the room is open, so re-read them on the way
    // back rather than leaving a stale badge on the button.
    unawaited(_loadChatRooms());
  }

  Widget _roomButton(ChatRoom room) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
    child: SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.forum_outlined, color: Colors.white),
        label: Text(
          room.unreadCount > 0
              ? '${room.roomName}  (${room.unreadCount})'
              : room.roomName,
          style: ts_button,
          textAlign: TextAlign.center,
        ),
        onPressed: () => _openRoom(room),
      ),
    ),
  );

  // qrSecretCode now lives in the keychain (async) — load it after first frame.
  Future<void> _loadSecretCode() async {
    final String code = await getQrSecretCode() ?? '';
    if (mounted) setState(() => _userSecretCode = code);
  }

  final _userName = getStringPref(StringPrefsEnum.displayName) ?? '';
  String _userSecretCode = '';
  final String _supportCode = getStringPref(StringPrefsEnum.supportCode) ?? '';

  bool isLoading = false;
  bool _isReloading = false;
  bool _bootLogCopied = false;

  Future<void> _reloadData() async {
    if (mounted) setState(() => _isReloading = true);
    await AppBootService.resetAndReboot(keepResetCode: true);
    // Reached only if the reset was aborted (e.g. offline) — clear the spinner.
    if (mounted) setState(() => _isReloading = false);
  }

  Future<void> _copyBootLogToClipboard() async {
    final text =
        getStringPref(StringPrefsEnum.lastSessionErrorLog) ?? 'No error log.';
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    setState(() => _bootLogCopied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _bootLogCopied = false);
    });
  }

  Widget _buildCircularProgressIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            'Applying Invite Code',
            style: ts_headingLarge,
            textAlign: TextAlign.center,
          ),
          Container(height: 30),
          const HcAppCircularProgressIndicator(key: Key('68462')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isReloading) {
      return SizedBox.shrink();
    }
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
            body: isLoading
                ? Container(
                    height:
                        MediaQuery.sizeOf(context).height -
                        appBar.preferredSize.height,
                    decoration: Backgrounds.defaultHcBackground(),
                    child: _buildCircularProgressIndicator(),
                  )
                : Container(
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
                            // Platform-wide chat rooms — the rooms this
                            // hasher's roles put them in, listed by the
                            // server. Above the QR code because someone
                            // opening Support to ask a question should see
                            // them before their own secret code.
                            if (_roomsFailed) ...<Widget>[
                              Padding(
                                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                                child: Text(
                                  'Chat rooms could not be loaded. A connection '
                                  'is required to see them.',
                                  textAlign: TextAlign.center,
                                  style: ts_body.copyWith(fontSize: 13),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.refresh,
                                        color: Colors.white),
                                    label: Text('Try again', style: ts_button),
                                    onPressed: () => unawaited(_loadChatRooms()),
                                  ),
                                ),
                              ),
                              const Divider(color: Colors.white24),
                              const SizedBox(height: 10),
                            ] else if (_rooms != null && _rooms!.isNotEmpty) ...<Widget>[
                              for (final ChatRoom room in _rooms!)
                                _roomButton(room),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
                                child: Text(
                                  _rooms!.length == 1
                                      ? 'Talk to the other hashers who share your role.'
                                      : 'Talk to the other hashers who share your roles.',
                                  textAlign: TextAlign.center,
                                  style: ts_body.copyWith(fontSize: 13),
                                ),
                              ),
                              const Divider(color: Colors.white24),
                              const SizedBox(height: 10),
                            ],
                            AutoSizeText(
                              'Secret QR code for:',
                              //'QR Code for xxx',
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              style: ts_headingLarge,
                            ),
                            const SizedBox(height: 15.0),
                            AutoSizeText(
                              _userName,
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
                                        '$QR_PREFIX_USER_SECRET_CODE${_userSecretCode.toUpperCase()}',
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
                              _supportCode,
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
                                      'To maximize performance and support the ability to operate when not on a network, Harrier Central stores data relevant to your Hash experience on your phone.\r\n\r\nOn rare occasionions, this data may become out of sync with the master data stored in our central servers. To reload your Hash data, press the "Reload Data" button below. This will clear the existing data, restart Harrier Central, and reload the data from our servers.',
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
                                                  await _reloadData();
                                                }
                                              });
                                            },
                                            child: Text(
                                              'Reload Data',
                                              style: ts_button,
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
                            if (getBoolPref(
                                  BoolPrefsEnum.debugHarvestEnabled,
                                ) ==
                                true)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20.0,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
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
                                              backgroundColor: _bootLogCopied
                                                  ? Colors.green.shade700
                                                  : hc_blue,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 8.0,
                                                    horizontal: 15.0,
                                                  ),
                                            ),
                                            onPressed:
                                                _copyBootLogToClipboard,
                                            icon: Icon(
                                              _bootLogCopied
                                                  ? Icons.check
                                                  : Icons.copy,
                                              size: 16,
                                            ),
                                            label: Text(
                                              _bootLogCopied
                                                  ? 'Copied!'
                                                  : 'Copy log to clipboard',
                                              style: ts_button,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            // const FancyDivider(
                            //   key: Key('6624334671'),
                            //   innerColor: Colors.white,
                            //   topMargin: 40.0,
                            //   bottomMargin: 30.0,
                            // ),
                            // Text(
                            //   'Invite Code:',
                            //   style: ts_headingLarge,
                            //   textAlign: TextAlign.center,
                            // ),
                            // Container(
                            //   padding: const EdgeInsets.all(30.0),

                            //   //color: const Color.fromARGB(255, 255, 255, 255),
                            //   child: Center(
                            //     child: Column(
                            //       children: <Widget>[
                            //         Container(
                            //           //color: Colors.white,
                            //           padding: const EdgeInsets.all(10.0),
                            //           decoration: BoxDecoration(
                            //             color: Colors.yellow[100],
                            //             borderRadius: BorderRadius.circular(5.0),
                            //           ),
                            //           // padding: const EdgeInsets.only(
                            //           //     top: 0.0, bottom: 8.0),
                            //           child: TextFormField(
                            //             autocorrect: false,
                            //             controller: _resetCodeTextController,
                            //             focusNode: _resetCodeFocusNode,
                            //             decoration: _resetCodeDecoration,
                            //             // validator: (val) {
                            //             //   if (val.length == 0) {
                            //             //     return "Email cannot be empty";
                            //             //   } else {
                            //             //     return null;
                            //             //   }
                            //             // },
                            //             keyboardType: TextInputType.text,
                            //             style: const TextStyle(
                            //               color: Colors.yellow,
                            //               fontFamily: 'Poppins',
                            //             ),
                            //           ),
                            //         ),
                            //         Padding(
                            //           padding: const EdgeInsets.only(top: 25),
                            //           child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: <Widget>[
                            //             StyleForConnected(
                            //
                            //               ElevatedButton(
                            //                 style: ElevatedButton.styleFrom(
                            //                   padding: const EdgeInsets.only(top: 8, bottom: 8, left: 20, right: 20),
                            //                 ),
                            //                 onPressed: () async {
                            //                   if (Utilities.isConnected(appModel.connectionStatus)) {
                            //                     await tableModel.syncUserDataService.updateFromBackend(
                            //                           SyncUserDataService.flagAllMasterData,
                            //                           false,
                            //                           debugText: 'support_page: All master data',
                            //                         );
                            //                     //final String resultStr = result ? 'successfully' : 'unsuccessfully';
                            //                     //print('Master data synchronized $resultStr');

                            //                     if (_resetCodeTextController.text.length == 6) {
                            //                       setStateIfMounted(() {
                            //                         isLoading = true;
                            //                       });

                            //                       final AuthorizeDeviceService srv = AuthorizeDeviceService();

                            //                       if (!mounted) return;
                            //                       final Map<String, String> result = await srv.authorizeDevice(navigatorKey.currentContext!, QR_PREFIX_USER_RESET_CODE + _resetCodeTextController.text.toUpperCase());

                            //                       setStateIfMounted(() {
                            //                         isLoading = false;
                            //                       });

                            //                       if (result['result'] != 'failed') {
                            //                         _userName = getStringPref(StringPrefsEnum.displayName) ?? _userName;
                            //                         _userSecretCode = getStringPref(StringPrefsEnum.qrSecretCode) ?? _userSecretCode;

                            //                         await Utilities.showAlert('App Reset Successful', 'Your app has been successfully reset. Please close and restart the app to ensure all data is properly reloaded.', 'OK');
                            //                       }
                            //                     }
                            //                   }
                            //                 },
                            //                 child: Text(
                            //                   'Reset App',
                            //                   style: ts_button,
                            //                 ),
                            //               ),
                            //             ),
                            //           ]),
                            //         ),
                            //         Padding(
                            //           padding: const EdgeInsets.only(top: 25),
                            //           child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: <Widget>[
                            //             StyleForConnected(
                            //
                            //               ElevatedButton(
                            //                 style: ElevatedButton.styleFrom(
                            //                   padding: const EdgeInsets.only(top: 8, bottom: 8, left: 20, right: 20),
                            //                 ),
                            //                 onPressed: () async {
                            //                   if (Utilities.isConnected(appModel.connectionStatus)) {
                            //                     await tableModel.syncUserDataService.updateFromBackend(
                            //                           SyncUserDataService.flagAllMasterData,
                            //                           false,
                            //                           debugText: 'support_page: All master data 2',
                            //                         );
                            //                     // final String resultStr = result ? 'successfully' : 'unsuccessfully';
                            //                     // print('Master data synchronized $resultStr');

                            //                     if (_resetCodeTextController.text.length == 6) {
                            //                       setStateIfMounted(() {
                            //                         isLoading = true;
                            //                       });

                            //                       final AuthorizeDeviceService srv = AuthorizeDeviceService();

                            //                       if (!mounted) return;
                            //                       final Map<String, String> result = await srv.authorizeDevice(navigatorKey.currentContext!, QR_PREFIX_USER_RESET_CODE + _resetCodeTextController.text.toUpperCase());

                            //                       setStateIfMounted(() {
                            //                         isLoading = false;
                            //                       });

                            //                       if (result['result'] != 'failed') {
                            //                         _userName = getStringPref(StringPrefsEnum.displayName) ?? _userName;
                            //                         _userSecretCode = getStringPref(StringPrefsEnum.qrSecretCode) ?? _userSecretCode;

                            //                         await Utilities.showAlert('App Reset Successful', 'Your app has been successfully reset. Please close and restart the app to ensure all data is properly reloaded.', 'OK');
                            //                       }
                            //                     }
                            //                   }
                            //                 },
                            //                 child: Text(
                            //                   'Reload Database',
                            //                   style: ts_button,
                            //                 ),
                            //               ),
                            //             ),
                            //           ]),
                            //         ),
                            //       ],
                            //     ),
                            //   ),
                            // ),
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
          refreshFunction: () {
            setStateIfMounted(() {});
          },
        ),
      ],
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
              child: Text('OK, Got it!', style: ts_button),
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
