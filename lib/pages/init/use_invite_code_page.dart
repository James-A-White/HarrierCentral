import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:harrier_central/util/styles.dart';
import 'package:harrier_central/util/globals.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/widgets/offline_mode_ribbon.dart';
import 'package:harrier_central/data/services/authorize_device_service.dart';
import 'package:harrier_central/util/utilities.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/pages/top_level/main_navigation_page.dart';

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
            body: Container(
              decoration: Backgrounds.defaultHcBackground(),
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              child: const UseInviteCodePageContent(),
            ),
          ),
        ),
        const OfflineModeRibbon(),
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
      final num newFontSize = headingStyle.fontSize * deviceWidthScaleFactor;

      final TextStyle localHeadingStyle = headingStyle.copyWith(fontSize: newFontSize, height: 1.2);

      return Container(
        padding: const EdgeInsets.all(15),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SizedBox(
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
                    Utilities.showAlert(
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
                margin: const EdgeInsets.only(left:15,right:15),
                padding: const EdgeInsets.only(left:15,right:15,top:15,bottom:5),
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
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 24.0, color: Theme.of(context).accentColor),
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
                            value: true,
                            onChanged: (bool value) {
                              setState(() {
                                // historicalCountIsEstimate = value;
                                // checkDirty();
                              });
                            },
                          ),
                        ),
                        const Text(
                          'Include me in Global Hash Directory',
                          //style: headingStyle,
                          textAlign: TextAlign.center,
                        ),
                        GestureDetector(
                          onTap: () {
                            Utilities.showAlert(
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
                  ],
                ),
              ),
            ),


            const SizedBox(height: 35, width: 10),
            FlatButton(
              color: Colors.red,
              child: const Text('Get Started!'),
              textColor: Colors.white,
              onPressed: () {
                if (_formKey.currentState.validate()) {
                  // If the form is valid, display a snackbar. In the real world,
                  // you'd often call a server or save the information in a database.
                  isLoading = true;

                  final AuthorizeDeviceService srv = AuthorizeDeviceService();
                  final Future<Map<String, String>> apiCall = srv.authorizeDevice(context, QR_PREFIX_USER_RESET_CODE + inviteCodeTextController.text.toUpperCase());
                  apiCall.then((Map<String, String> result) {
                    setState(() {
                      isLoading = false;
                    });

                    if (result['result'] != 'failed') {
                      final String userName = getStringPref(StringPrefsEnum.displayName);

                      Utilities.showAlert(context, 'Profile Load Successful', 'The app has been successfully loaded for $userName.', 'OK').then((void dummy) {
                        Navigator.pushReplacement<dynamic, dynamic>(context, MaterialPageRoute<dynamic>(builder: (BuildContext context) => const MainNavigationPage()));
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
