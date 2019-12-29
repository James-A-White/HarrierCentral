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
            Text(
              'Please enter your\r\ninvite code',
              style: localHeadingStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 35, width: 10),
            Form(
              key: _formKey,
              child: Container(
                padding: const EdgeInsets.all(10),
                color: Colors.yellow[100],
                child: TextFormField(
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
            // GestureDetector(
            //   onTap: (){
            //     //  Navigator.push<dynamic>(
            //     //             context,
            //     //             MaterialPageRoute<dynamic>(builder: (BuildContext context) => PDFScreen()),
            //     //           ),
            //   },
            //   child: Container(
            //     padding: const EdgeInsets.all(10),
            //     decoration: BoxDecoration(
            //       borderRadius: BorderRadius.circular(20.0),
            //       color: Colors.white,
            //       border: Border.all(
            //         color: Theme.of(context).accentColor,
            //         width: 2, //                   <--- border width here
            //       ),
            //     ),
            //     child: Row(
            //       children: <Widget>[
            //         Image(
            //           width: PROFILE_PIC_SIZE2 * deviceWidthScaleFactor,
            //           height: PROFILE_PIC_SIZE2 * deviceWidthScaleFactor,
            //           fit: BoxFit.fill,
            //           image: const AssetImage('images/icons/inviteCode.png'),
            //         ),
            //         const SizedBox(height: 1, width: 10),
            //         Expanded(
            //           child: Column(mainAxisSize: MainAxisSize.max, mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            //             Text('Use Invite Code', style: localTitleStyle),
            //             Text(
            //               'Use the invite code provided by your kennel to create or reconnect to your Harrier Central account',
            //               style: localBodyStyle,
            //               //softWrap: true,
            //             ),
            //           ]),
            //         ),
            //       ],
            //     ),
            //   ),
            // ),
            // Container(
            //   padding: const EdgeInsets.all(10),
            //   decoration: BoxDecoration(
            //     borderRadius: BorderRadius.circular(20.0),
            //     color: Colors.white,
            //     border: Border.all(
            //       color: Theme.of(context).accentColor,
            //       width: 2, //                   <--- border width here
            //     ),
            //   ),
            //   child: Row(
            //     children: <Widget>[
            //       Image(
            //         width: PROFILE_PIC_SIZE2 * deviceWidthScaleFactor,
            //         height: PROFILE_PIC_SIZE2 * deviceWidthScaleFactor,
            //         fit: BoxFit.fill,
            //         image: const AssetImage('images/icons/facebookLogoCircle.png'),
            //       ),
            //       const SizedBox(height: 1, width: 10),
            //       Expanded(
            //         child: Column(mainAxisSize: MainAxisSize.max, mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            //           Text('Use Facebook', style: localTitleStyle),
            //           Text(
            //             'Create a new Harrier Central account or connect to your existing account using your Facebook login',
            //             style: localBodyStyle,
            //             //softWrap: true,
            //           ),
            //         ]),
            //       ),
            //     ],
            //   ),
            // ),
            // Container(
            //   padding: const EdgeInsets.all(10),
            //   decoration: BoxDecoration(
            //     borderRadius: BorderRadius.circular(20.0),
            //     color: Colors.white,
            //     border: Border.all(
            //       color: Theme.of(context).accentColor,
            //       width: 2, //                   <--- border width here
            //     ),
            //   ),
            //   child: Row(
            //     children: <Widget>[
            //       Image(
            //         width: PROFILE_PIC_SIZE2 * deviceWidthScaleFactor,
            //         height: PROFILE_PIC_SIZE2 * deviceWidthScaleFactor,
            //         fit: BoxFit.fill,
            //         image: const AssetImage('images/icons/qrPhone.png'),
            //       ),
            //       const SizedBox(height: 1, width: 10),
            //       Expanded(
            //         child: Column(mainAxisSize: MainAxisSize.max, mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            //           Text('Transfer app', style: localTitleStyle),
            //           Text(
            //             'Use a QR code to transfer your Harrier Central account to this phone from another phone',
            //             style: localBodyStyle,
            //             //softWrap: true,
            //           ),
            //         ]),
            //       ),
            //     ],
            //   ),
            // ),
            // Container(
            //   padding: EdgeInsets.all(10),
            //   decoration: BoxDecoration(
            //     borderRadius: BorderRadius.circular(20.0),
            //     color: Colors.white,
            //     border: Border.all(
            //       color: Theme.of(context).accentColor,
            //       width: 2, //                   <--- border width here
            //     ),
            //   ),
            //   child: Row(
            //     children: <Widget>[
            //       Image(
            //         width: PROFILE_PIC_SIZE2 * deviceWidthScaleFactor,
            //         height: PROFILE_PIC_SIZE2 * deviceWidthScaleFactor,
            //         fit: BoxFit.fill,
            //         image: const AssetImage('images/icons/pencil.png'),
            //       ),
            //       const SizedBox(height: 1, width: 10),
            //       Expanded(
            //         child: Column(mainAxisSize: MainAxisSize.max, mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            //           Text('Create New Account', style: localTitleStyle),
            //           Text(
            //             'Provide information to create a new Harrier Central account if you are not already in the system',
            //             style: localBodyStyle,
            //             //softWrap: true,
            //           ),
            //         ]),
            //       ),
            //     ],
            //   ),
            // ),
          ],
        ),
      );
    });
  }
}
