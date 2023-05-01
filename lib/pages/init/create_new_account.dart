// @dart=2.11
import 'package:harrier_central/imports.dart';

class CreateNewAccountPage extends StatefulWidget {
  //final FutureRunScopedModel futureRunsModel;

  const CreateNewAccountPage({Key key}) : super(key: key);

  @override
  CreateNewAccountPageState createState() => CreateNewAccountPageState();
}

class CreateNewAccountPageState extends State<CreateNewAccountPage> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        SizedBox(height: MediaQuery.of(context).size.height, width: MediaQuery.of(context).size.width),
        Positioned(
          top: 0,
          left: 0,
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Scaffold(
            appBar: AppBar(
              centerTitle: true,
              backgroundColor: themeAppBarBackground,
              title: const Text(
                'Create New Account',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
            body: Container(
              decoration: Backgrounds.defaultHcBackground(),
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              child: const CreateNewAccountPageContent(),
            ),
          ),
        ),
        OfflineModeRibbon(
          showRibbon: G0<AppModel>().connectionStatus == EnumConnectionStatus.not_connected,
          lastSync: getDatePref(DatePrefsEnum.lastSuccessfulUserDataSyncAsDate),
          ribbonImage: 'images/icons/offline_mode.png',
          refreshFunction: () {
            setState(() {});
          },
        ),
      ],
    );
  }
}

class CreateNewAccountPageContent extends StatefulWidget {
  const CreateNewAccountPageContent({Key key}) : super(key: key);

  @override
  CreateNewAccountPageContentState createState() => CreateNewAccountPageContentState();
}

class CreateNewAccountPageContentState extends State<CreateNewAccountPageContent> {
  TextEditingController inviteCodeTextController;
  InputDecoration inviteCodeDecoration;
  final FocusNode inviteCodeFocusNode = FocusNode();

  //final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  bool includeInGlobalHashDirectory = true;

  @override
  void initState() {
    super.initState();
  }

  UserDetailsUi userDetailsUi;

  @override
  Widget build(BuildContext context) {
    userDetailsUi ??= UserDetailsUi(
      firstName: '',
      lastName: '',
      email: '',
      hashName: '',
    );
    return LayoutBuilder(builder: (BuildContext context, BoxConstraints viewportConstraints) {
      final num newFontSize = headingStyle.fontSize * G0<DeviceInfo>().deviceWidthScaleFactor;

      final TextStyle localHeadingStyle = headingStyle.copyWith(fontSize: newFontSize, height: 1.2);

      return SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(15),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  //SizedBox(width: 46,height: 10,),
                  Text(
                    'Please enter your\r\nuser details',
                    style: localHeadingStyle,
                    textAlign: TextAlign.center,
                  ),
                  // GestureDetector(
                  //   onTap: () {
                  //     await IveCoreUtilities.showAlert(
                  //         context,
                  //         'What is an "Invite Code"?',
                  //         'An Invite Code is a six character code that allows you to connect to an existing account in Harrier Central.\r\n\r\nTypically you will receive an invite code from your home Kennel when they have already created an account for you in order to track your run counts.\r\n\r\nIf you do not have an Invite Code, please go back to the previous screen and select the option to Create a New Account.',
                  //         'OK');
                  //   },
                  //   child: Container(
                  //     padding: const EdgeInsets.only(left: 20),
                  //     height: 26,
                  //     child: Image.asset('images/icons/more_info_button.png'),
                  //   ),
                  // ),
                ],
              ),
              const SizedBox(
                height: 30,
                width: 30,
              ),
              Container(
                margin: const EdgeInsets.only(left: 15, right: 15),
                padding: const EdgeInsets.all(10),
                color: Colors.yellow[100],
                child: Column(
                  children: <Widget>[
                    userDetailsUi,
                    const SizedBox(
                      height: 30,
                      width: 30,
                    ),
                    // Row(
                    //   children: <Widget>[
                    //     Container(
                    //       margin: const EdgeInsets.only(right: 10),
                    //       height: 25,
                    //       width: 25,
                    //       color: Colors.yellow[100],
                    //       child: Checkbox(
                    //         value: includeInGlobalHashDirectory,
                    //         onChanged: (bool value) {
                    //           setState(() {
                    //             includeInGlobalHashDirectory = value;
                    //           });
                    //         },
                    //       ),
                    //     ),
                    //     const Expanded(
                    //       child: Text(
                    //         'Include me in Global Hash Directory',
                    //         //style: headingStyle,
                    //         textAlign: TextAlign.center,
                    //         maxLines: 2,
                    //       ),
                    //     ),
                    //     GestureDetector(
                    //       onTap: () async {
                    //         await IveCoreUtilities.showAlert(
                    //             context,
                    //             'What is the Global Hash Directory?',
                    //             'The Global Hash Directory is a list of all Hashers who use Harrier Central and "opt-in" to be included in the list.\r\n\r\nWhen you select to be included in the Directory your name, home Kennel and any mismanagement roles you have will be publicly available.\r\n\r\nYou may also use Harrier Central to send short email messages to anyone else in the Directory without sharing your e-mail address.',
                    //             'OK');
                    //       },
                    //       child: Container(
                    //         padding: const EdgeInsets.only(left: 20),
                    //         height: 26,
                    //         child: Image.asset('images/icons/more_info_button.png'),
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    const SizedBox(height: 8, width: 10),
                  ],
                ),
              ),
              const SizedBox(height: 35, width: 10),
              if (!isLoading) ...<Widget>[
                TextButton(
                  child: Text('Get Started!', style: textStyleButton),
                  onPressed: () async {
                    if (userDetailsUi.validateForm()) {
                      // If the form is valid, display a snackbar. In the real world,
                      // you'd often call a server or save the information in a database.
                      setState(() {
                        isLoading = true;
                      });

                      await setStringPref(StringPrefsEnum.firstName, userDetailsUi.firstName);
                      await setStringPref(StringPrefsEnum.lastName, userDetailsUi.lastName);
                      await setStringPref(StringPrefsEnum.email, userDetailsUi.email);
                      await setStringPref(StringPrefsEnum.hashName, userDetailsUi.hashName);

                      final HashersService srv = HashersService();

                      final String profilePhotoUrl = 'bundle://avatar-${Random.secure().nextInt(49) + 1}';

                      final String responseBody = await srv.addEditUser(
                          targetUserId: GUID_EMPTY,
                          firstName: userDetailsUi.firstName,
                          lastName: userDetailsUi.lastName,
                          email: userDetailsUi.email,
                          hashName: userDetailsUi.hashName,
                          photo: profilePhotoUrl,
                          // includeInGlobalHashDirectory: includeInGlobalHashDirectory ? 1 : 0);
                          includeInGlobalHashDirectory: 0);

                      bool isSuccessfulLoad = false;

                      if (responseBody == ERROR_INVITE_CODE_SENT) {
                        isSuccessfulLoad = true;

                        if (!mounted) return;
                        await Navigator.push<dynamic>(context, MaterialPageRoute<dynamic>(builder: (BuildContext context) => const UseInviteCodePage()));
                      } else if (!responseBody.startsWith(ERROR_PREFIX)) {
                        final List<dynamic> jsonResultSets = json.decode(responseBody);
                        if (jsonResultSets.isNotEmpty) {
                          final List<dynamic> subSet = jsonResultSets[0];
                          if (subSet.isNotEmpty) {
                            final Map<String, dynamic> result = subSet[0];
                            if (result.isNotEmpty) {
                              await setStringPref(StringPrefsEnum.profilePhotoUrl, result['photo']);
                              await setStringPref(StringPrefsEnum.displayName, result['displayName']);
                              //setStringPref(StringPrefsEnum.email, result['email']);
                              // await setStringPref(StringPrefsEnum.facebookId, result['facebookId']);
                              await setStringPref(StringPrefsEnum.firstName, result['firstName']);
                              await setStringPref(StringPrefsEnum.hashName, result['hashName']);
                              await setStringPref(StringPrefsEnum.lastName, result['lastName']);
                              await setStringPref(StringPrefsEnum.qrCode, result['qrCode']);
                              await setStringPref(StringPrefsEnum.supportCode, result['supportCode']);
                              await setStringPref(StringPrefsEnum.resetCode, result['resetCode']);
                              await setStringPref(StringPrefsEnum.qrSecretCode, result['qrSecretCode']);
                              await setStringPref(StringPrefsEnum.userId, result['hasherId']);
                              final int preferences = int.tryParse(result['preferences'] ?? '14') ?? 14;
                              await setIntPref(IntPrefsEnum.hasherPreferences, preferences);
                              isSuccessfulLoad = true;

                              //final String profilePhotoUrl = getStringPref(StringPrefsEnum.profilePhotoUrl);
                              final String fileNamePrefix = getStringPref(StringPrefsEnum.supportCode);
                              //profilePhotoUrl ??= 'bundle://avatar-' + (Random.secure().nextInt(49) + 1).toString();

                              if (!mounted) return;
                              await Navigator.pushReplacement<dynamic, dynamic>(
                                  context,
                                  MaterialPageRoute<dynamic>(
                                    builder: (BuildContext context) => ChooseProfileImage(
                                      isForThisDevice: true,
                                      fileNamePrefix: fileNamePrefix,
                                      currentProfileImage: null,
                                      popToCaller: false,
                                    ),
                                  ));
                            }
                          }
                        }
                      }

                      if (!isSuccessfulLoad) {
                        await IveCoreUtilities.showAlert(
                            navigatorKey.currentContext,
                            'Account not created',
                            'There was a problem creating your account. Please delete the app and try again later or contact us at connect@harriercentral.com.\r\n\r\nSorry for the inconvenience!',
                            'OK');
                      }
                    }
                  },
                ),
              ],
              const SizedBox(height: 50, width: 10),
            ],
          ),
        ),
      );
    });
  }
}
