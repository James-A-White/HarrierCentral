// @dart=2.11
import 'package:harrier_central/imports.dart';
import 'package:harrier_central/widgets/email_popup.dart';

class UseInviteCodePage extends StatefulWidget {
  //final FutureRunScopedModel futureRunsModel;

  const UseInviteCodePage({Key key}) : super(key: key);

  @override
  UseInviteCodePageState createState() => UseInviteCodePageState();
}

class UseInviteCodePageState extends State<UseInviteCodePage> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Container(height: MediaQuery.of(context).size.height, width: MediaQuery.of(context).size.width),
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
                  'Use Invite Code',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
              body: SingleChildScrollView(
                child: Container(
                  decoration: Backgrounds.defaultHcBackground(),
                  height: MediaQuery.of(context).size.height,
                  width: MediaQuery.of(context).size.width,
                  child: const UseInviteCodePageContent(),
                ),
              ),
              resizeToAvoidBottomInset: false),
        ),
        OfflineModeRibbon(
          showRibbon: G0<AppModel>().connectionStatus == EnumConnectionStatus.not_connected,
          lastSync: getDatePref(DatePrefsEnum.lastSuccessfulUserDataSyncAsDate),
          ribbonImage: 'images/icons/offline_mode.png',
        ),
      ],
    );
  }
}

class UseInviteCodePageContent extends StatefulWidget {
  const UseInviteCodePageContent({Key key}) : super(key: key);

  @override
  _UseInviteCodePageContentState createState() => _UseInviteCodePageContentState();
}

class _UseInviteCodePageContentState extends State<UseInviteCodePageContent> {
  TextEditingController inviteCodeTextController;
  InputDecoration inviteCodeDecoration;
  final FocusNode inviteCodeFocusNode = FocusNode();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  bool includeInGlobalHashDirectory = true;

  String emailAddress = '';

  @override
  void initState() {
    super.initState();

    inviteCodeTextController = TextEditingController();
    inviteCodeDecoration = InputDecoration(
      labelText: 'Invite Code',
      fillColor: Colors.red,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: const BorderSide(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (BuildContext context, BoxConstraints viewportConstraints) {
      final num newFontSize = headingStyle.fontSize * G0<DeviceInfo>().deviceWidthScaleFactor;

      final TextStyle localHeadingStyle = headingStyle.copyWith(fontSize: newFontSize, height: 1.2);

      return SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const SizedBox(
                  width: 46,
                  height: 10,
                ),
                Text(
                  'Please enter your\r\ninvite code',
                  style: localHeadingStyle,
                  textAlign: TextAlign.center,
                ),
                GestureDetector(
                  onTap: () {
                    IveCoreUtilities.showAlert(
                        context,
                        'What is an "Invite Code"?',
                        'An Invite Code is a six character code that allows you to connect to an existing account in Harrier Central.\r\n\r\nTypically you will receive an invite code from your home Kennel when they have already created an account for you in order to track your run counts.\r\n\r\nIf you do not have an Invite Code, please go back to the previous screen and select the option to Create a New Account.',
                        'OK');
                  },
                  child: Container(
                    padding: const EdgeInsets.only(left: 20),
                    height: 26,
                    child: Image.asset('images/icons/more_info_button.png'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 35, width: 10),
            Form(
              key: _formKey,
              child: Container(
                margin: const EdgeInsets.only(left: 15, right: 15),
                padding: const EdgeInsets.only(left: 15, right: 15, top: 15, bottom: 5),
                color: Colors.yellow[100],
                child: Column(
                  children: <Widget>[
                    TextFormField(
                      autocorrect: false,
                      textCapitalization: TextCapitalization.characters,
                      controller: inviteCodeTextController,
                      focusNode: inviteCodeFocusNode,
                      decoration: inviteCodeDecoration,
                      validator: (String val) {
                        if (val.length != 6) {
                          return 'Invite codes are six characters';
                        } else {
                          return null;
                        }
                      },
                      keyboardType: TextInputType.text,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 24.0, color: Colors.red.shade900),
                    ),
                    const SizedBox(height: 20, width: 10),
                    Row(
                      children: <Widget>[
                        Container(
                          margin: const EdgeInsets.only(right: 10),
                          height: 25,
                          width: 25,
                          color: Colors.yellow[100],
                          child: Checkbox(
                            value: includeInGlobalHashDirectory,
                            onChanged: (bool value) {
                              setState(() {
                                includeInGlobalHashDirectory = value;
                                // checkDirty();
                              });
                            },
                          ),
                        ),
                        const Expanded(
                          child: Text(
                            'Include me in Global Hash Directory',
                            //style: headingStyle,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            IveCoreUtilities.showAlert(
                                context,
                                'What is the Global Hash Directory?',
                                'The Global Hash Directory is a list of all Hashers who use Harrier Central and "opt-in" to be included in the list.\r\n\r\nWhen you select to be included in the Directory your name, home Kennel and any mismanagement roles you have will be publicly available.\r\n\r\nYou may also use Harrier Central to send short email messages to anyone else in the Directory without sharing your e-mail address.',
                                'OK');
                          },
                          child: Container(
                            padding: const EdgeInsets.only(left: 20),
                            height: 26,
                            child: Image.asset('images/icons/more_info_button.png'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8, width: 10),
                    TextButton(
                        child: const Text('Email me a new invite code'),
                        style: TextButton.styleFrom(backgroundColor: Colors.transparent, primary: Colors.red.shade800),
                        onPressed: () async {
                          final EmailPopup emailPopup = EmailPopup(
                            initialEmailAddress: emailAddress,
                          );

                          final Future<Map<String, String>> dlg = showDialog<Map<String, String>>(
                              context: context,
                              barrierDismissible: false, // user must tap button!
                              builder: (BuildContext context) {
                                return emailPopup;
                              });

                          dlg.then((Map<String, String> x) async {
                            final String email = x['email'];
                            final String type = x['type'];

                            if (type != 'cancel') {
                              emailAddress = email;
                              final String userMessage = await HashersService.sendInviteCodeByEmail(email);
                              await IveCoreUtilities.showAlert(navigatorKey.currentContext, 'Instructions', userMessage, 'OK');
                            }
                          });
                        }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 35, width: 10),
            isLoading
                ? Text(
                    'Please wait...',
                    style: localHeadingStyle,
                    textAlign: TextAlign.center,
                  )
                : TextButton(
                    child: const Text('Get Started!'),
                    onPressed: () {
                      if (_formKey.currentState.validate()) {
                        // If the form is valid, display a snackbar. In the real world,
                        // you'd often call a server or save the information in a database.
                        setState(() {
                          isLoading = true;
                        });

                        final AuthorizeDeviceService srv = AuthorizeDeviceService();
                        final Future<Map<String, String>> apiCall = srv.authorizeDevice(context, QR_PREFIX_USER_RESET_CODE + inviteCodeTextController.text.toUpperCase(),
                            includeInGlobalHashDirectory: includeInGlobalHashDirectory ? 1 : 0);
                        apiCall.then((Map<String, String> result) {
                          setState(() {
                            isLoading = false;
                          });

                          if (result['result'] != 'failed') {
                            final String userName = getStringPref(StringPrefsEnum.displayName);

                            String profilePhotoUrl = getStringPref(StringPrefsEnum.profilePhotoUrl);
                            profilePhotoUrl ??= 'bundle://avatar-' + (Random.secure().nextInt(49) + 1).toString();

                            IveCoreUtilities.showAlert(context, 'Success!', 'The app has been successfully set up for $userName.', 'OK').then((void _) {
                              Navigator.pushReplacement<dynamic, dynamic>(
                                  context,
                                  MaterialPageRoute<dynamic>(
                                    builder: (BuildContext context) => ChooseProfileImage(
                                      isForThisDevice: true,
                                      fileNamePrefix: getStringPref(StringPrefsEnum.supportCode),
                                      currentProfileImage: profilePhotoUrl,
                                      popToCaller: false,
                                    ),
                                  ));
                            });
                          } else {
                            // TODO(James): Do something here if the auth device fails
                          }
                        });
                      }
                    },
                  ),
            const SizedBox(height: 50, width: 10),
          ],
        ),
      );
    });
  }
}
