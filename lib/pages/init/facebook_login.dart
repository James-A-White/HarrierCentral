import 'dart:convert';

// import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter/material.dart';
import 'package:harrier_central/data/hc3_services/hashers_service.dart';

import 'package:harrier_central/util/styles.dart';
import 'package:ive_flutter_core/util/core_utilities.dart';

import 'package:ive_flutter_core/widgets/fancy_divider.dart';
import 'package:harrier_central/pages/top_level/main_navigation_page.dart';
import 'package:ive_flutter_core/widgets/circular_progress_indicator.dart';
import 'package:harrier_central/util/enums.dart';

class FbLoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<FbLoginPage> {
  bool isLoggedIn = false;
  dynamic profileData;
  String facebookAccessToken;

  bool includeInGlobalHashDirectory = true;

  TextEditingController hashNameTextController;
  final FocusNode hashNameFocusNode = FocusNode();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    hashNameTextController = TextEditingController();
  }

  void onLoginStatusChanged(bool loggedIn,
      {dynamic profData, String accessToken}) {
    setState(() {
      isLoggedIn = loggedIn;
      profileData = profData;
      facebookAccessToken = accessToken;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: themeAppBarBackground,
        title: const Text('Facebook Login'),
        // actions: <Widget>[
        //   IconButton(
        //     icon: const Icon(
        //       Icons.exit_to_app,
        //       color: Colors.white,
        //     ),
        //     onPressed: () => facebookLogin.isLoggedIn.then<dynamic>((bool isLoggedIn) => isLoggedIn ? _logout() : null),
        //   ),
        // ],
      ),
      resizeToAvoidBottomPadding: false,
      body: Container(
        decoration: Backgrounds.defaultHcBackground(),
        child: Center(
          child: isLoading
              ? const Center(
                  child: HcCircularProgressIndicator(),
                )
              : isLoggedIn
                  ? _displayUserData(profileData)
                  : GestureDetector(
                      onTap: () {
                        _login();
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Image(
                          fit: BoxFit.fill,
                          image: AssetImage('images/init/facebook_login.png'),
                        ),
                      ),
                    ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    try {
      // by default the login method has the next permissions ['email','public_profile']
      final AccessToken accessToken = await FacebookAuth.instance.login();
      print(accessToken.toJson());
      // get the user data
      final Map<String, dynamic> userData = await FacebookAuth.instance.getUserData(
          fields:
              'name,picture.width(300),email,birthday,gender,link,first_name,last_name');
      print(userData);

      onLoginStatusChanged(true,
          profData: userData, accessToken: accessToken.token);
    } on FacebookAuthException catch (e) {
      switch (e.errorCode) {
        case FacebookAuthErrorCode.OPERATION_IN_PROGRESS:
          print('You have a previous login operation in progress');
          break;
        case FacebookAuthErrorCode.CANCELLED:
          print('login cancelled');
          break;
        case FacebookAuthErrorCode.FAILED:
          print('login failed');
          break;
      }
    }
  }

  // Future<void> initiateFacebookLogin() async {
  //   final FacebookLoginResult facebookLoginResult = await facebookLogin.logIn(<String>['email']);

  //   switch (facebookLoginResult.status) {
  //     case FacebookLoginStatus.error:
  //       onLoginStatusChanged(false);
  //       break;
  //     case FacebookLoginStatus.cancelledByUser:
  //       onLoginStatusChanged(false);
  //       break;
  //     case FacebookLoginStatus.loggedIn:
  //       final dynamic graphResponse = await http.get('https://graph.facebook.com/v2.12/me?fields=name,first_name,last_name,email,picture.height(200)&access_token=${facebookLoginResult.accessToken.token}');

  //       final dynamic profile = json.decode(graphResponse.body);
  //       print(profile.toString());

  //       onLoginStatusChanged(true, profData: profile, accessToken: facebookLoginResult.accessToken.token);
  //       //Navigator.pushReplacementNamed(context, RouteNames.MAIN_LANDING_PAGE.toString());
  //       break;
  //   }
  // }

  dynamic _displayUserData(dynamic profileData) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        //const SizedBox(height: 28.0),
        Padding(
          padding: const EdgeInsets.only(top: 25.0, bottom: 15.0),
          child: Text('Logged in as:',
              textAlign: TextAlign.center, style: smallTitleStyle),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 15.0),
          child: Text(profileData['name'],
              textAlign: TextAlign.center, style: largeTitleStyle),
        ),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 20, right: 20),
            child: AspectRatio(
              aspectRatio: 1.0,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  borderRadius: const BorderRadius.all(Radius.circular(10.0)),
                  image: DecorationImage(
                    fit: BoxFit.fill,
                    image: NetworkImage(
                      profileData['picture']['data']['url'],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        const FancyDivider(
          innerColor: Colors.white,
          topMargin: 35.0,
          bottomMargin: 15.0,
        ),
        Form(
          key: _formKey,
          child: Container(
            margin: const EdgeInsets.only(left: 15, right: 15),
            padding:
                const EdgeInsets.only(left: 15, right: 15, top: 15, bottom: 5),

            decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              borderRadius: const BorderRadius.all(Radius.circular(10.0)),
              color: Colors.yellow[100],
            ),

            //color: Colors.yellow[100],
            child: Column(
              children: <Widget>[
                TextFormField(
                  autocorrect: false,
                  //textCapitalization: TextCapitalization.characters,
                  controller: hashNameTextController,
                  focusNode: hashNameFocusNode,
                  decoration: InputDecoration(
                    labelText: 'Hash Name',
                    //hintText: profileData != null ? 'Just ' + profileData['first_name'] : '',
                    fillColor: Colors.red,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: const BorderSide(),
                    ),
                  ),
                  // validator: (String val) {
                  //   if (val.length != 6) {
                  //     return 'Invite codes are six characters';
                  //   } else {
                  //     return null;
                  //   }
                  // },
                  //keyboardType: TextInputType.,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 24.0,
                      color: Theme.of(context).accentColor),
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
                        CoreUtilities.showAlert(
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
        Padding(
          padding: const EdgeInsets.only(top: 15.0),
          child: FlatButton(
            color: Theme.of(context).accentColor,
            child: const Text('Get Started!'),
            textColor: Colors.white,
            onPressed: () async {
              if (_formKey.currentState.validate()) {
                // If the form is valid, display a snackbar. In the real world,
                // you'd often call a server or save the information in a database.
                setState(() {
                  isLoading = true;
                });

                final HashersService hSrv = HashersService();
                final String responseBody = await hSrv.processFacebookLogin(
                    firstName: profileData['first_name'],
                    lastName: profileData['last_name'],
                    email: profileData['email'],
                    hashName: hashNameTextController.text,
                    photo: profileData['picture']['data']['url'],
                    facebookId: profileData['id'],
                    facebookAccessToken: facebookAccessToken,
                    includeInGlobalHashDirectory:
                        includeInGlobalHashDirectory ? 1 : 0);

                final dynamic result = json.decode(responseBody);

                setStringPref(
                    StringPrefsEnum.profilePhotoUrl, result[0]['photo']);
                setStringPref(
                    StringPrefsEnum.displayName, result[0]['displayName']);
                setStringPref(StringPrefsEnum.email, result[0]['email']);
                setStringPref(
                    StringPrefsEnum.facebookId, result[0]['facebookId']);
                setStringPref(
                    StringPrefsEnum.firstName, result[0]['firstName']);
                setStringPref(StringPrefsEnum.hashName, result[0]['hashName']);
                setStringPref(StringPrefsEnum.lastName, result[0]['lastName']);
                setStringPref(StringPrefsEnum.qrCode, result[0]['qrCode']);
                setStringPref(
                    StringPrefsEnum.supportCode, result[0]['supportCode']);
                setStringPref(
                    StringPrefsEnum.resetCode, result[0]['resetCode']);
                setStringPref(
                    StringPrefsEnum.qrSecretCode, result[0]['qrSecretCode']);
                setStringPref(StringPrefsEnum.userId, result[0]['hasherId']);

                Navigator.pushReplacement<dynamic, dynamic>(
                    context,
                    MaterialPageRoute<dynamic>(
                        builder: (BuildContext context) =>
                            const MainNavigationPage()));
              }
            },
          ),
        ),
        const SizedBox(height: 10, width: 10),
      ],
    );
  }
}
