import 'dart:math';
import 'dart:ui';
import 'dart:convert';
import 'dart:core';

import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:audioplayers/audio_cache.dart';
import 'package:fast_qr_reader_view/fast_qr_reader_view.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;


import 'package:harrier_central/data_models/user_model.dart';
import 'package:harrier_central/main.dart';
import 'package:harrier_central/pages/init/choose_profile_image.dart';
import 'package:harrier_central/pages/top_level/main_navigation_page.dart';
import 'package:harrier_central/services/add_user_service.dart';
import 'package:harrier_central/services/authorize_device_service.dart';
import 'package:harrier_central/util/enums.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/styles.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';


//import 'package:the_gorgeous_login/style/theme.dart' as Theme;

class LoginPage extends StatefulWidget {
  const LoginPage({Key key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final FocusNode myFocusNodeEmailLogin = FocusNode();
  final FocusNode myFocusNodePasswordLogin = FocusNode();

  final FocusNode myFocusNodeHashName = FocusNode();
  final FocusNode myFocusNodeEmail = FocusNode();
  final FocusNode myFocusNodeFirstName = FocusNode();
  final FocusNode myFocusNodeLastName = FocusNode();

  TextEditingController loginEmailController = TextEditingController();
  TextEditingController loginPasswordController = TextEditingController();

  //bool _obscureTextLogin = true;
  final bool _obscureTextSignup = false;
  //final bool _obscureTextSignupConfirm = true;

  TextEditingController signupEmailController = TextEditingController();
  TextEditingController signupFirstNameController = TextEditingController();
  TextEditingController signupLastNameController = TextEditingController();
  TextEditingController signupHashNameController = TextEditingController();

  PageController _pageController;
  int _scanState = 0;

  Color left = Colors.black;
  Color right = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: NotificationListener<OverscrollIndicatorNotification>(
        onNotification: (OverscrollIndicatorNotification overscroll) {
          overscroll.disallowGlow();
        },
        child: SingleChildScrollView(
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height >= 500.0
                ? MediaQuery.of(context).size.height
                : 500.0,
            decoration: Backgrounds.defaultHcBackground(),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                const Padding(
                  padding: EdgeInsets.only(top: 45.0),
                  child: Image(
                      width: 100.0,
                      height: 100.0,
                      fit: BoxFit.fill,
                      image: AssetImage('images/other/hc_app_icon.png')),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: _buildMenuBar(context),
                ),
                Expanded(
                  flex: 2,
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (int i) {
                      if (i == 0) {
                        setState(() {
                          right = Colors.white;
                          left = Colors.black;
                        });
                      } else if (i == 1) {
                        setState(() {
                          right = Colors.black;
                          left = Colors.white;
                        });
                      }
                    },
                    children: <Widget>[
                      ConstrainedBox(
                        constraints: const BoxConstraints.expand(),
                        child: _buildSignUp(context),
                      ),
                      ConstrainedBox(
                        constraints: const BoxConstraints.expand(),
                        child: _buildSignIn(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    myFocusNodeHashName.dispose();
    myFocusNodeEmail.dispose();
    myFocusNodeFirstName.dispose();
    myFocusNodeLastName.dispose();
    _pageController?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    // signupFirstNameController.text = 'delete';
    // signupLastNameController.text = 'delete';
    // signupHashNameController.text = 'delete';
    // signupEmailController.text =
    //     'delete_' + Random.secure().nextInt(99999999).toString() + '@test.com';

    SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    _pageController = PageController();
  }

  void showInSnackBar(String value, {int durationInSeconds = 3}) {
    FocusScope.of(context).requestFocus(FocusNode());
    _scaffoldKey.currentState?.removeCurrentSnackBar();
    _scaffoldKey.currentState.showSnackBar(SnackBar(
      content: Text(
        value,
        textAlign: TextAlign.center,
        style: const TextStyle(
            color: Colors.white,
            fontSize: 16.0,
            fontFamily: 'WorkSansSemiBold'),
      ),
      backgroundColor: Colors.blue,
      duration: Duration(seconds: durationInSeconds),
    ));
  }

  Widget _buildMenuBar(BuildContext context) {
    return Container(
      width: 300.0,
      height: 50.0,
      decoration: const BoxDecoration(
        color: Color(0x552B2B2B),
        borderRadius: BorderRadius.all(Radius.circular(25.0)),
      ),
      child: CustomPaint(
        painter: TabIndicationPainter(pageController: _pageController),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Expanded(
              child: FlatButton(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onPressed: _onSignInTabPress,
                child: Text(
                  'New',
                  style: TextStyle(
                      color: left,
                      fontSize: 16.0,
                      fontFamily: 'WorkSansSemiBold'),
                ),
              ),
            ),
            //Container(height: 33.0, width: 1.0, color: Colors.white),
            Expanded(
              child: FlatButton(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onPressed: _onSignUpTabPress,
                child: Text(
                  'Existing',
                  style: TextStyle(
                      color: right,
                      fontSize: 16.0,
                      fontFamily: 'WorkSansSemiBold'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignIn(BuildContext context) {
    return Container(
      //color: Colors.red,
      // padding: const EdgeInsets.only(top: 23.0),
      // child: Column(
      //   children: <Widget>[
      child: Stack(
        alignment: Alignment.topCenter,
        overflow: Overflow.visible,
        children: <Widget>[
          Positioned(
              top: 60,
              bottom: 140,
              //width:150,
              //height:150,
              child: _cameraPreviewWidget()
              // child:Container(
              //   child: _cameraPreviewWidget(), width: 200.0, height: 200.0),
              ),
          Positioned(
            bottom: 30,
            child: Container(
              margin: const EdgeInsets.only(top: 170.0),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(5.0)),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: LoginColors.loginGradientStart,
                    offset: const Offset(1.0, 6.0),
                    blurRadius: 20.0,
                  ),
                  BoxShadow(
                    color: LoginColors.loginGradientEnd,
                    offset: const Offset(1.0, 6.0),
                    blurRadius: 20.0,
                  ),
                ],
                gradient: LinearGradient(
                    colors: <Color>[
                      LoginColors.loginGradientEnd,
                      LoginColors.loginGradientStart
                    ],
                    begin: const FractionalOffset(0.2, 0.2),
                    end: const FractionalOffset(1.0, 1.0),
                    stops: const <double>[0.0, 1.0],
                    tileMode: TileMode.clamp),
              ),
              child: MaterialButton(
                  highlightColor: Colors.transparent,
                  splashColor: LoginColors.loginGradientEnd,
                  //shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(5.0))),
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(vertical: 10.0, horizontal: 42.0),
                    child: Text(
                      controller == null ? 'Start Scanning' : 'Stop Scanning',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 25.0,
                          fontFamily: 'WorkSansBold'),
                    ),
                  ),
                  onPressed: () => scanUserBarcode()),
            ),
          ),
          // Positioned(
          //   bottom: 90,
          //   child: Row(
          //     mainAxisAlignment: MainAxisAlignment.center,
          //     children: <Widget>[
          //       Container(
          //         decoration: const BoxDecoration(
          //           gradient: LinearGradient(
          //               colors: <Color>[
          //                 Colors.white10,
          //                 Colors.white,
          //               ],
          //               begin: FractionalOffset(0.0, 0.0),
          //               end: FractionalOffset(1.0, 1.0),
          //               stops: <double>[0.0, 1.0],
          //               tileMode: TileMode.clamp),
          //         ),
          //         width: 100.0,
          //         height: 1.0,
          //       ),
          //       const Padding(
          //         padding: EdgeInsets.only(left: 15.0, right: 15.0),
          //         child: Text(
          //           'Or',
          //           style: TextStyle(
          //               color: Colors.white,
          //               fontSize: 16.0,
          //               fontFamily: 'WorkSansMedium'),
          //         ),
          //       ),
          //       Container(
          //         decoration: const BoxDecoration(
          //           gradient: LinearGradient(
          //               colors: <Color>[
          //                 Colors.white,
          //                 Colors.white10,
          //               ],
          //               begin: FractionalOffset(0.0, 0.0),
          //               end: FractionalOffset(1.0, 1.0),
          //               stops: <double>[0.0, 1.0],
          //               tileMode: TileMode.clamp),
          //         ),
          //         width: 100.0,
          //         height: 1.0,
          //       ),
          //     ],
          //   ),
          // ),
          // Positioned(
          //   bottom: 20,
          //   child: Row(
          //     mainAxisAlignment: MainAxisAlignment.center,
          //     children: <Widget>[
          //       Padding(
          //         padding: const EdgeInsets.only(top: 10.0, right: 40.0),
          //         child: GestureDetector(
          //           onTap: () => showInSnackBar('Facebook button pressed'),
          //           child: Container(
          //             padding: const EdgeInsets.all(15.0),
          //             decoration: const BoxDecoration(
          //               shape: BoxShape.circle,
          //               color: Colors.white,
          //             ),
          //             child: const Icon(
          //               FontAwesomeIcons.facebookF,
          //               color: Color(0xFF0084ff),
          //             ),
          //           ),
          //         ),
          //       ),
          //       Padding(
          //         padding: const EdgeInsets.only(top: 10.0),
          //         child: GestureDetector(
          //           onTap: () => showInSnackBar('Google button pressed'),
          //           child: Container(
          //             padding: const EdgeInsets.all(15.0),
          //             decoration: const BoxDecoration(
          //               shape: BoxShape.circle,
          //               color: Colors.white,
          //             ),
          //             child: const Icon(
          //               FontAwesomeIcons.google,
          //               color: Color(0xFF0084ff),
          //             ),
          //           ),
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
        ],
      ),

      //   ],
      // ),
    );
  }

  Widget _buildSignUp(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 23.0),
      child: Column(
        children: <Widget>[
          Stack(
            alignment: Alignment.topCenter,
            overflow: Overflow.visible,
            children: <Widget>[
              Card(
                elevation: 2.0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Container(
                  width: 300.0,
                  height: 230.0,
                  child: Column(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(
                            top: 3.0, bottom: 3.0, left: 25.0, right: 25.0),
                        child: TextField(
                          focusNode: myFocusNodeFirstName,
                          controller: signupFirstNameController,
                          keyboardType: TextInputType.text,
                          textCapitalization: TextCapitalization.words,
                          style: const TextStyle(
                              fontFamily: 'WorkSansSemiBold',
                              fontSize: 16.0,
                              color: Colors.black),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            icon: Icon(
                              FontAwesomeIcons.user,
                              color: Colors.black,
                            ),
                            hintText: 'First Name',
                            hintStyle: TextStyle(
                                fontFamily: 'WorkSansSemiBold', fontSize: 16.0),
                          ),
                        ),
                      ),
                      Container(
                        width: 250.0,
                        height: 1.0,
                        color: Colors.grey[400],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            top: 3.0, bottom: 3.0, left: 25.0, right: 25.0),
                        child: TextField(
                          focusNode: myFocusNodeLastName,
                          controller: signupLastNameController,
                          keyboardType: TextInputType.text,
                          textCapitalization: TextCapitalization.words,
                          style: const TextStyle(
                              fontFamily: 'WorkSansSemiBold',
                              fontSize: 16.0,
                              color: Colors.black),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            icon: Icon(
                              FontAwesomeIcons.user,
                              color: Colors.black,
                            ),
                            hintText: 'Last Name',
                            hintStyle: TextStyle(
                                fontFamily: 'WorkSansSemiBold', fontSize: 16.0),
                          ),
                        ),
                      ),
                      Container(
                        width: 250.0,
                        height: 1.0,
                        color: Colors.grey[400],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            top: 3.0, bottom: 3.0, left: 25.0, right: 25.0),
                        child: TextField(
                          focusNode: myFocusNodeEmail,
                          controller: signupEmailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(
                              fontFamily: 'WorkSansSemiBold',
                              fontSize: 16.0,
                              color: Colors.black),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            icon: Icon(
                              FontAwesomeIcons.envelope,
                              color: Colors.black,
                            ),
                            hintText: 'Email Address',
                            hintStyle: TextStyle(
                                fontFamily: 'WorkSansSemiBold', fontSize: 16.0),
                          ),
                        ),
                      ),
                      Container(
                        width: 250.0,
                        height: 1.0,
                        color: Colors.grey[400],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            top: 3.0, bottom: 3.0, left: 25.0, right: 25.0),
                        child: TextField(
                          focusNode: myFocusNodeHashName,
                          controller: signupHashNameController,
                          obscureText: _obscureTextSignup,
                          style: const TextStyle(
                              fontFamily: 'WorkSansSemiBold',
                              fontSize: 16.0,
                              color: Colors.black),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            icon: Icon(
                              FontAwesomeIcons.dove,
                              color: Colors.black,
                            ),
                            hintText: 'Hash Name (optional)',
                            hintStyle: TextStyle(
                                fontFamily: 'WorkSansSemiBold', fontSize: 16.0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 210.0),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(5.0)),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: LoginColors.loginGradientStart,
                      offset: const Offset(1.0, 6.0),
                      blurRadius: 20.0,
                    ),
                    BoxShadow(
                      color: LoginColors.loginGradientEnd,
                      offset: const Offset(1.0, 6.0),
                      blurRadius: 20.0,
                    ),
                  ],
                  gradient: LinearGradient(
                      colors: <Color>[
                        LoginColors.loginGradientEnd,
                        LoginColors.loginGradientStart
                      ],
                      begin: const FractionalOffset(0.2, 0.2),
                      end: const FractionalOffset(1.0, 1.0),
                      stops: const <double>[0.0, 1.0],
                      tileMode: TileMode.clamp),
                ),
                child: MaterialButton(
                    highlightColor: Colors.transparent,
                    splashColor: LoginColors.loginGradientEnd,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                          vertical: 10.0, horizontal: 42.0),
                      child: Text(
                        'SIGN UP',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 25.0,
                            fontFamily: 'WorkSansBold'),
                      ),
                    ),
                    onPressed: () => _onSignUpButtonPress()),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                        colors: <Color>[
                          Colors.white10,
                          Colors.white,
                        ],
                        begin: FractionalOffset(0.0, 0.0),
                        end: FractionalOffset(1.0, 1.0),
                        stops: <double>[0.0, 1.0],
                        tileMode: TileMode.clamp),
                  ),
                  width: 100.0,
                  height: 1.0,
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 15.0, right: 15.0),
                  child: Text(
                    'Connect with',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.0,
                        fontFamily: 'WorkSansMedium'),
                  ),
                ),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                        colors: <Color>[
                          Colors.white,
                          Colors.white10,
                        ],
                        begin: FractionalOffset(0.0, 0.0),
                        end: FractionalOffset(1.0, 1.0),
                        stops: <double>[0.0, 1.0],
                        tileMode: TileMode.clamp),
                  ),
                  width: 100.0,
                  height: 1.0,
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 10.0, right: 0.0),
                child: GestureDetector(
                  onTap: () {
                    final facebookLogin = FacebookLogin();
                    facebookLogin.logInWithReadPermissions(['email']).then((FacebookLoginResult result) async {
                      String token = result.accessToken.token;
                      final graphResponse = await http.get('https://graph.facebook.com/v3.2/me?fields=name,first_name,last_name,picture,email&access_token=${token}');

                      dynamic profile = json.decode(graphResponse.body);

                      String name = profile['name'];
                      String first_name = profile['first_name'];
                      String last_name = profile['last_name'];
                      String emailAddress = profile['email'];
                      String facebookId = profile['id'];
                      dynamic picture = profile['picture']['data']['url'];

                      Preferences.setStringPref(StringPrefsEnum.profilePhotoUrl, picture);
                      Preferences.setStringPref(StringPrefsEnum.facebookId, facebookId);

                      signupFirstNameController.text = first_name;
                      signupLastNameController.text = last_name;
                      signupEmailController.text =emailAddress;


                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(15.0),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: const Icon(
                      FontAwesomeIcons.facebookF,
                      color: Color(0xFF0084ff),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _onSignInTabPress() {
    _pageController.animateToPage(0,
        duration: Duration(milliseconds: 500), curve: Curves.decelerate);
  }

  void _onSignUpTabPress() {
    _pageController?.animateToPage(1,
        duration: Duration(milliseconds: 500), curve: Curves.decelerate);
  }

  void _onSignUpButtonPress() {
    bool canProcess = true;

    if (signupFirstNameController.text.isEmpty) {
      canProcess = false;
      showInSnackBar('Please enter your first name');
    }

    if (signupLastNameController.text.isEmpty) {
      canProcess = false;
      showInSnackBar('Please enter your last name');
    }

    final bool emailValid = RegExp(
            r"[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?",
            caseSensitive: false)
        .hasMatch(signupEmailController.text);
    if (!emailValid) {
      canProcess = false;
      showInSnackBar('Please enter a valid email address');
    }

    if (canProcess) {
      setState(() {
        _scanState = 1;
      });

      final AddUserService t = AddUserService();
      final Future<UserModel> x = t.addUser(
          signupFirstNameController.text,
          signupLastNameController.text,
          signupEmailController.text,
          signupHashNameController.text,
          '',
          '',
          '',
          '00000000-0000-0000-0000-000000000000',
          '',
          hasherTypeMember);
      x.then((UserModel user) {
        Preferences.setStringPref(StringPrefsEnum.userId, user.hasherId);
        Preferences.setStringPref(StringPrefsEnum.firstName, user.firstName);
        Preferences.setStringPref(StringPrefsEnum.lastName, user.lastName);
        Preferences.setStringPref(StringPrefsEnum.hashName, user.hashName);
        Preferences.setStringPref(
            StringPrefsEnum.displayName, user.displayName);
        Preferences.setStringPref(StringPrefsEnum.email, user.email);
        Preferences.setStringPref(StringPrefsEnum.qrCode, user.qrCode);
        Preferences.setStringPref(
            StringPrefsEnum.qrSecretCode, user.qrSecretCode);
        Preferences.setStringPref(StringPrefsEnum.facebookId, user.facebookId);
        Preferences.setStringPref(
            StringPrefsEnum.profilePhotoUrl, 'bundle://Avatar-1');

        Future<dynamic>.delayed(const Duration(milliseconds: 35))
            .then((void dummy) {
          // Navigator.of(context,
          //     //.pushReplacementNamed(RouteNames.CHOOSE_PROFILE_IMAGE.toString());
          //     MaterialPageRoute<String>(
          //             builder: (context) => ChooseProfileImage(isInitFlow: false,
          //                   // kennelId: widget.futureRun.kennelId,
          //                   // eventId: widget.futureRun.eventId,
          //                   // attendenceState: attendenceAtHash,
          //                 ),
          //           )
          // );

          Navigator.push<String>(
            context,
            MaterialPageRoute<String>(
              builder: (context) => ChooseProfileImage(
                    true,
                    // kennelId: widget.futureRun.kennelId,
                    // eventId: widget.futureRun.eventId,
                    // attendenceState: attendenceAtHash,
                  ),
            ),
          );
        });
      });
    }
  }

  //
  //
  //
  //
  //
  //
  //
  // QR Code Scanner support
  //
  //
  //
  //
  //
  //

  String barcode = 'Waiting for Scan';

  QRReaderController controller;

  @override
  bool get wantKeepAlive => true;

  Future scanUserBarcode() async {
    if (controller == null) {
      setState(() => barcode = 'Scanning');
      cameras = await availableCameras();

      onNewCameraSelected(cameras[0]);
    } else {
      await stopScanning();
      setState(() => barcode = 'Waiting for scan');
    }
  }

  List<CameraDescription> cameras;

  void onCodeRead(String scanResult) async {
    final AudioCache audioPlayer = AudioCache(prefix: 'sounds/');
    audioPlayer.play('camera.mp3');

    await stopScanning();
    setState(() => barcode = 'Processing QR Scan');

    if (!scanResult.toUpperCase().startsWith('USC:')) {
      setState(() {
        _scanState = 3;
      });
    } else {
      setState(() {
        _scanState = 1;
      });

      AuthorizeDeviceService srv = AuthorizeDeviceService();
      final Future<Map<String, String>> apiCall =
          srv.authorizeDevice(scanResult);
      apiCall.then((Map<String, String> result) {
        if (result['result'] == 'success') {
          setState(() => _scanState = 0);
          Navigator.pushReplacement<dynamic,dynamic>(context, MaterialPageRoute<dynamic>(
                      builder: (BuildContext context) => MainNavigationPage()));
        } else {
          setState(() => _scanState = 2);
          showInSnackBar(result['message'], durationInSeconds: 7);
        }
      });
    }
  }

  Future stopScanning() async {
    controller.stopScanning();
    await controller.dispose();
    controller = null;
  }

  Widget _cameraPreviewWidget() {
    return LayoutBuilder(builder: (context, constraint) {
      return new Stack(
        alignment: AlignmentDirectional.center,
        children: <Widget>[
          Image.asset(
            _scanState == 1
                ? 'images/other/downloading_from_cloud.png'
                : _scanState == 2
                    ? 'images/other/download_failed.png'
                    : _scanState == 3
                        ? 'images/other/qr_not_recognized.png'
                        : 'images/other/qr_scanner.png',
          ),
          _scanState == 1
              ? Positioned(
                  top: 40,
                  child: SpinKitFadingCircle(itemBuilder: (_, int index) {
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        color:
                            index.isEven ? Colors.lightBlue[900] : Colors.white,
                      ),
                    );
                  }))
              : Container(),
          Container(
            padding: EdgeInsets.all(9.0),
            height: constraint.biggest.height,
            width: constraint.biggest.height,
            child: (controller == null)
                ? Container()
                : new QRReaderPreview(controller),
          )
        ],
      );
    });
  }

  void onNewCameraSelected(CameraDescription cameraDescription) async {
    if (controller != null) {
      await controller.dispose();
    }
    controller = new QRReaderController(cameraDescription,
        ResolutionPreset.high, [CodeFormat.qr, CodeFormat.pdf417], onCodeRead);

    // If the controller is updated then update the UI.
    controller.addListener(() {
      if (mounted) setState(() {});
      if (controller.value.hasError) {
        showInSnackBar('Camera error ${controller.value.errorDescription}');
      }
    });

    try {
      await controller.initialize();
    } on QRReaderException catch (e) {
      //logError(e.code, e.description);
      showInSnackBar('Error: ${e.code}\n${e.description}');
    }

    if (mounted) {
      setState(() {});
      controller.startScanning();
    }
  }
}

class TabIndicationPainter extends CustomPainter {
  Paint painter;
  final double dxTarget;
  final double dxEntry;
  final double radius;
  final double dy;

  final PageController pageController;

  TabIndicationPainter(
      {this.dxTarget = 125.0,
      this.dxEntry = 25.0,
      this.radius = 21.0,
      this.dy = 25.0,
      this.pageController})
      : super(repaint: pageController) {
    painter = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.fill;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final ScrollPosition pos = pageController.position;
    final double fullExtent =
        pos.maxScrollExtent - pos.minScrollExtent + pos.viewportDimension;

    final double pageOffset = pos.extentBefore / fullExtent;

    final bool left2right = dxEntry < dxTarget;
    final Offset entry = Offset(left2right ? dxEntry : dxTarget, dy);
    final Offset target = Offset(left2right ? dxTarget : dxEntry, dy);

    final Path path = Path();
    path.addArc(
        Rect.fromCircle(center: entry, radius: radius), 0.5 * pi, 1 * pi);
    path.addRect(Rect.fromLTRB(entry.dx, dy - radius, target.dx, dy + radius));
    path.addArc(
        Rect.fromCircle(center: target, radius: radius), 1.5 * pi, 1 * pi);

    canvas.translate(size.width * pageOffset, 0.0);
    canvas.drawShadow(path, const Color(0xFFfbab66), 3.0, true);
    canvas.drawPath(path, painter);
  }

  @override
  bool shouldRepaint(TabIndicationPainter oldDelegate) => true;
}
