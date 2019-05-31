import 'dart:convert';
import 'dart:core';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter/cupertino.dart';

import 'package:audioplayers/audio_cache.dart';
import 'package:fast_qr_reader_view/fast_qr_reader_view.dart';
import 'package:http/http.dart' as http;

import 'package:harrier_central/main.dart';
import 'package:harrier_central/pages/init/choose_profile_image.dart';
import 'package:harrier_central/pages/top_level/main_navigation_page.dart';
import 'package:harrier_central/data/services/authorize_device_service.dart';
import 'package:harrier_central/util/utilities.dart';
import 'package:harrier_central/util/enums.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/styles.dart';
import 'package:harrier_central/util/routes.dart';
import 'package:harrier_central/widgets/user_details_ui.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:harrier_central/widgets/fancy_divider.dart';
import 'package:harrier_central/widgets/bubble_tab_indicator.dart';
import 'package:harrier_central/data/hc3_services/hashers_service.dart';
import 'package:harrier_central/widgets/circular_progress_indicator.dart';

class NewUserWidget extends StatefulWidget {
  const NewUserWidget({Key key, this.eventId, this.kennelId, this.attendenceState, this.scaffoldKey}) : super(key: key);

  final String eventId;
  final String kennelId;
  final EnumAttendenceState<int> attendenceState;

  final GlobalKey<ScaffoldState> scaffoldKey;

  @override
  State<NewUserWidget> createState() {
    return NewUserState();
  }
}

class NewUserState extends State<NewUserWidget> with SingleTickerProviderStateMixin {
  List<Tab> tabs = <Tab>[];

  bool isAdmin = true;

  final FocusNode resetCodeFocusNode = FocusNode();
  TextEditingController resetCodeTextController;
  InputDecoration resetCodeDecoration;

  bool isLoading = false;

  PageController _pageController;
  TabController _tabController;

  String userName = '';

  final String userId = getStringPref(StringPrefsEnum.userId);

  GlobalKey tabKey;

  int _scanState = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: Backgrounds.defaultHcBackground(),
        child: isLoading
            ? HcCircularProgressIndicator()
            : Stack(
                alignment: AlignmentDirectional.center,
                children: <Widget>[
                  // Positioned(
                  //     top: 30,
                  //     left: 0,
                  //     right: 0,
                  //     child: Text(
                  //       'QR Code Scanner',
                  //       textAlign: TextAlign.center,
                  //       style: const TextStyle(
                  //           fontFamily: 'AvenirNextRegular',
                  //           fontStyle: FontStyle.normal,
                  //           color: Colors.white,
                  //           fontSize: 24.0,
                  //           height: 1.0),
                  //     )),
                  Positioned(
                    top: 20,
                    left: 20,
                    right: 20,
                    child: Container(
                      width: 340.0,
                      height: 45.0,
                      child: Text('Set up Harrier Central', textAlign: TextAlign.center, style: titleStyle),
                    ),
                  ),

                  Positioned(
                    top: 70,
                    left: 20,
                    right: 20,
                    child: Container(
                      width: 340.0,
                      height: 45.0,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColorLight,
                        borderRadius: const BorderRadius.all(Radius.circular(35.0)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 1.0, right: 1.0),
                        child: TabBar(
                          labelStyle: const TextStyle(fontFamily: 'AvenirNextCondensedMedium', fontStyle: FontStyle.normal, fontSize: 17.0, height: 0.8),
                          unselectedLabelStyle: const TextStyle(fontFamily: 'AvenirNextCondensedMedium', fontStyle: FontStyle.normal, fontSize: 17.0, height: 0.8),
                          isScrollable: false,
                          unselectedLabelColor: Colors.black,
                          labelColor: Colors.white,
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicator: BubbleTabIndicator(
                            indicatorHeight: 35.0,
                            indicatorColor: Theme.of(context).buttonColor,
                            tabBarIndicatorSize: TabBarIndicatorSize.tab,
                          ),
                          tabs: tabs,
                          controller: _tabController,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                      top: 130,
                      bottom: 0,
                      child: Container(
                        key: tabKey,
                        //color: Colors.teal,
                        width: MediaQuery.of(context).size.width,
                        child: TabBarView(
                          controller: _tabController,
                          children: <Widget>[
                            _buildSignUp(context),
                            _buildInvite(context),
                            _buildTransfer(context),
                          ],
                        ),
                      )),
                ],
              ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController?.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initTabs();

    _pageController = PageController(initialPage: 0, keepPage: true);
    _tabController = TabController(vsync: this, length: tabs.length);

    resetCodeTextController = TextEditingController();
    resetCodeDecoration = InputDecoration(
      labelText: 'Invite Code',
      fillColor: Colors.red,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25.0),
        borderSide: const BorderSide(),
      ),
    );
  }

  void _initTabs() {
    if (tabs.isEmpty) {
      tabs.add(const Tab(text: 'New user'));
      tabs.add(const Tab(text: 'Invite'));
      tabs.add(const Tab(text: 'Transfer'));
    }
  }

  Widget _buildInvite(BuildContext context) {
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
            top: 0,
            child: Column(
              children: <Widget>[
                Container(
                  width: MediaQuery.of(context).size.width,
                  padding: const EdgeInsets.only(top: 10, left: 20.0, right: 20.0, bottom: 25.0),
                  child: Text('Use this if you have received an invite code from a Hash group.', textAlign: TextAlign.center, style: smallHeadingStyle),
                ),
                Container(padding: const EdgeInsets.only(top: 15), width: MediaQuery.of(context).size.width, child: const FancyDivider(innerColor: Colors.white)),
              ],
            ),
          ),
          Positioned(
              top: 135,
              //bottom: 20,
              width: MediaQuery.of(context).size.width,
              child: Container(
                padding: const EdgeInsets.only(left: 30.0, right: 30.0, bottom: 10.0),

                //color: const Color.fromARGB(255, 255, 255, 255),
                child: Container(
                  child: Center(
                    child: Column(
                      children: <Widget>[
                        Container(
                          //color: Colors.white,
                          padding: const EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          // padding: const EdgeInsets.only(
                          //     top: 0.0, bottom: 8.0),
                          child: TextFormField(
                            autocorrect: false,
                            controller: resetCodeTextController,
                            focusNode: resetCodeFocusNode,
                            decoration: resetCodeDecoration,
                            // validator: (val) {
                            //   if (val.length == 0) {
                            //     return "Email cannot be empty";
                            //   } else {
                            //     return null;
                            //   }
                            // },
                            keyboardType: TextInputType.text,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 25),
                          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: <Widget>[
                            RaisedButton(
                              padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 42.0),
                              onPressed: () {
                                setState(() {
                                  isLoading = true;

                                  final AuthorizeDeviceService srv = AuthorizeDeviceService();
                                  final Future<Map<String, String>> apiCall = srv.authorizeDevice(context, 'RC:' + resetCodeTextController.text.toUpperCase());
                                  apiCall.then((Map<String, String> result) {
                                    setState(() {
                                      isLoading = false;
                                    });

                                    if (result['result'] != 'failed') {
                                      userName = getStringPref(StringPrefsEnum.displayName);

                                      Utilities.showAlert(context, 'Profile Load Successful', 'The app has been successfully loaded for $userName.', 'OK').then((void dummy) {
                                        Navigator.pushReplacement<dynamic, dynamic>(context, MaterialPageRoute<dynamic>(builder: (BuildContext context) => const MainNavigationPage()));
                                      });
                                    } else {
                                      // TODO(James): Do something here if the auth device fails
                                    }
                                  });
                                });
                              },
                              child: Text(
                                'Use Invite Code',
                                style: textStyleButton,
                              ),
                            ),
                          ]),
                        ),
                      ],
                    ),
                  ),
                ),
              )),
        ],
      ),

      //   ],
      // ),
    );
  }

  Widget _buildTransfer(BuildContext context) {
    return SingleChildScrollView(
      //color: Colors.red,
      // padding: const EdgeInsets.only(top: 23.0),
      // child: Column(
      //   children: <Widget>[
      child: Stack(
        alignment: Alignment.topCenter,
        overflow: Overflow.visible,
        children: <Widget>[
          Container(
            width: 10,
            height: math.min(500, MediaQuery.of(context).size.height - 100),
          ),
          Positioned(
            top: 0,
            child: Column(
              children: <Widget>[
                Container(
                  width: MediaQuery.of(context).size.width,
                  padding: const EdgeInsets.only(top: 10, left: 20.0, right: 20.0, bottom: 25.0),
                  child: Text('Use this to transfer your Harrier Central account to a new phone.', textAlign: TextAlign.center, style: smallHeadingStyle),
                ),
                Container(padding: const EdgeInsets.only(top: 15), width: MediaQuery.of(context).size.width, child: const FancyDivider(innerColor: Colors.white)),
              ],
            ),
          ),
          Positioned(
              top: 132,
              bottom: 80,
              //width:150,
              //height:150,
              child: _cameraPreviewWidget()
              // child:Container(
              //   child: _cameraPreviewWidget(), width: 200.0, height: 200.0),
              ),
          Positioned(
            bottom: 0,
            child: RaisedButton(
                highlightColor: Colors.transparent,
                splashColor: LoginColors.loginGradientEnd,
                //shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(5.0))),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 42.0),
                  child: Text(
                    controller == null ? 'Scan Transfer Code' : 'Stop Scanning',
                    style: textStyleButton,
                  ),
                ),
                onPressed: () => scanUserBarcode()),
          )
        ],
      ),

      //   ],
      // ),
    );
  }

  UserDetailsUi userDetailsUi;

  Widget _buildSignUp(BuildContext context) {
    userDetailsUi ??= UserDetailsUi(
      firstName: '',
      lastName: '',
      email: '',
      hashName: '',
    );
    return SingleChildScrollView(
      //padding: const EdgeInsets.only(top: 0.0),
      child: Column(
        children: <Widget>[
          Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 10, left: 20.0, right: 20.0, bottom: 25.0),
                child: Text('Use this if you have never been entered into Harrier Central', textAlign: TextAlign.center, style: smallHeadingStyle),
              ),
              Utilities.elegantDivider('First Connect\r\nto FB (optional)', 0.0, 5.0),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 10.0, right: 0.0),
                child: Row(
                  children: <Widget>[
                    GestureDetector(
                      onTap: () {
                        final FacebookLogin facebookLogin = FacebookLogin();
                        facebookLogin.logInWithReadPermissions(<String>['email']).then((FacebookLoginResult result) async {
                          final String token = result.accessToken.token;
                          final http.Response graphResponse = await http.get('https://graph.facebook.com/v3.2/me?fields=name,first_name,last_name,picture.width(640),email,gender&access_token=$token');

                          final dynamic profile = json.decode(graphResponse.body);

                          final String firstName = profile['first_name'];
                          final String lastName = profile['last_name'];
                          final String email = profile['email'];
                          final String facebookId = profile['id'];
                          final String gender = profile['gender'];
                          final dynamic picture = profile['picture']['data']['url'];

                          setStringPref(StringPrefsEnum.facebookProfilePhoto, picture);
                          setStringPref(StringPrefsEnum.facebookId, facebookId);
                          setStringPref(StringPrefsEnum.facebookAccessToken, token);
                          setStringPref(StringPrefsEnum.gender, gender);

                          userDetailsUi.updateUi(firstName, lastName, email);
                          userDetailsUi.firstName = firstName;
                          userDetailsUi.lastName = lastName;
                          userDetailsUi.email = email;

                          Utilities.showAlert(context, 'Facebook profile loaded', 'We have copied your Facebook profile information (name, email and profile photo) to the app. Please continue to register by adding your Hash name.', 'OK');
                        });
                      },
                      child: Container(
                        width: 250,
                        child: Image.asset('images/init/facebook_login.png'),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Utilities.showAlert(
                            context,
                            'Why Connect with Facebook?',
                            'If you are not on a Hash group\'s Mismanagement, this only saves you time typing in your name and e-mail address. For those with administrative access to Harrier Central, having your Facebook credentials allows us to automatically download run information from your Hash group\'s Facebook events and add them to the app.',
                            'OK');
                      },
                      child: Container(
                        padding: const EdgeInsets.only(left: 20),
                        height: 40,
                        child: Image.asset('images/icons/more_info_button.png'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Utilities.elegantDivider('Then add\r\ndetails', 15.0, 20.0),
          userDetailsUi,
          Padding(
            padding: const EdgeInsets.only(top: 18.0),
            child: RaisedButton(
                highlightColor: Colors.transparent,
                splashColor: LoginColors.loginGradientEnd,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 42.0),
                  child: Text(
                    'Next',
                    style: TextStyle(color: Colors.white, fontSize: 25.0, fontFamily: 'WorkSansBold'),
                  ),
                ),
                onPressed: () => _onSignUpButtonPress()),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // void _onSignInTabPress() {
  //   _pageController.animateToPage(0,
  //       duration: const Duration(milliseconds: 500), curve: Curves.decelerate);
  // }

  // void _onSignUpTabPress() {
  //   _pageController?.animateToPage(1,
  //       duration: const Duration(milliseconds: 500), curve: Curves.decelerate);
  // }

  void _onSignUpButtonPress() {
    bool canProcess = true;

    if (userDetailsUi != null && userDetailsUi.firstName.isEmpty) {
      canProcess = false;
      Utilities.showInSnackBar(context, widget.scaffoldKey, 'Please enter your first name', durationInSeconds: 7);
    }

    if (userDetailsUi != null && userDetailsUi.lastName.isEmpty) {
      canProcess = false;
      Utilities.showInSnackBar(context, widget.scaffoldKey, 'Please enter your last name', durationInSeconds: 7);
    }

    bool emailValid = false;

    if (userDetailsUi != null) {
      emailValid = RegExp(r"[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?", caseSensitive: false).hasMatch(userDetailsUi.email);
    }

    if (canProcess && !emailValid) {
      canProcess = false;
      Utilities.showInSnackBar(context, widget.scaffoldKey, 'Please enter a valid email address', durationInSeconds: 7);
    }

    if (canProcess && (userDetailsUi != null)) {
      setState(() {
        _scanState = 1;
      });

      setStringPref(StringPrefsEnum.firstName, userDetailsUi.firstName);
      setStringPref(StringPrefsEnum.lastName, userDetailsUi.lastName);
      setStringPref(StringPrefsEnum.email, userDetailsUi.email);
      setStringPref(StringPrefsEnum.hashName, userDetailsUi.hashName);

      isLoading = true;
      Navigator.push(
        context,
        MaterialPageRoute<String>(
          builder: (BuildContext context) => ChooseProfileImage(
                isForThisDevice: true,
                currentProfileImage: '',
                fileNamePrefix: 'newHcUser_' + DateTime.now().microsecondsSinceEpoch.toString(),
              ),
        ),
      ).then<String>((String profilePhotoUrl) {
        final HashersService srv = HashersService();

        final Future<String> apiCall = srv.addEditUser(targetUserId: GUID_EMPTY, firstName: userDetailsUi.firstName, lastName: userDetailsUi.lastName, email: userDetailsUi.email, hashName: userDetailsUi.hashName, photo: profilePhotoUrl);

        apiCall.then((String responseBody) async {
          final List<dynamic> jsonResultSets = json.decode(responseBody);
          if (jsonResultSets.isNotEmpty)
          {
            final List<dynamic> subSet =jsonResultSets[0];
            if (subSet.isNotEmpty)
            {
              final Map<String,dynamic> result = subSet[0];
              if (result.isNotEmpty)
              {
                setStringPref(StringPrefsEnum.profilePhotoUrl, result['photo']);
                setStringPref(StringPrefsEnum.displayName, result['displayName']);
                setStringPref(StringPrefsEnum.email, result['email']);
                setStringPref(StringPrefsEnum.facebookId, result['facebookId']);
                setStringPref(StringPrefsEnum.firstName, result['firstName']);
                setStringPref(StringPrefsEnum.hashName, result['hashName']);
                setStringPref(StringPrefsEnum.lastName, result['lastName']);
                setStringPref(StringPrefsEnum.qrCode, result['qrCode']);
                setStringPref(StringPrefsEnum.supportCode, result['supportCode']);
                setStringPref(StringPrefsEnum.qrSecretCode, result['qrSecretCode']);
                setStringPref(StringPrefsEnum.userId, result['hasherId']);
              }
            }
          }
          print(jsonResultSets.length);
          Navigator.pushReplacement<dynamic, dynamic>(context, MaterialPageRoute<dynamic>(builder: (BuildContext context) => const MainNavigationPage()));
        });
      });
    }
  }

  String barcode = 'Waiting for Scan';

  QRReaderController controller;

  bool get wantKeepAlive => true;

  Future<dynamic> scanUserBarcode() async {
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

  Future<void> onCodeRead(String scanResult) async {
    final AudioCache audioPlayer = AudioCache(prefix: 'sounds/');
    audioPlayer.play('camera.mp3');

    await stopScanning();
    setState(() => barcode = 'Processing QR Scan');

    if (!scanResult.toUpperCase().startsWith('USC:')) {
      setState(() {
        // QR code not recognized
        _scanState = 3;
      });
    } else {
      setState(() {
        // dowloading from the cloud
        _scanState = 1;
      });

      final AuthorizeDeviceService srv = AuthorizeDeviceService();
      final Future<Map<String, String>> apiCall = srv.authorizeDevice(context, scanResult);
      apiCall.then((Map<String, String> result) {
        if (result != null) {
          Future<dynamic>.delayed(const Duration(milliseconds: 3500)).then((void dummy) {
            if (result['result'] == 'success') {
              setState(() => _scanState = 0);
              Navigator.pushReplacement<dynamic, dynamic>(context, MaterialPageRoute<dynamic>(builder: (BuildContext context) => const MainNavigationPage()));
            } else {
              // downloading from the cloud failed
              setState(() => _scanState = 2);
              Utilities.showInSnackBar(context, widget.scaffoldKey, result['message'], durationInSeconds: 7);
            }
          });
        }
      });
    }
    // return Future<void>(() {});((){});
  }

  Future<dynamic> stopScanning() async {
    controller.stopScanning();
    await controller.dispose();
    controller = null;
  }

  Widget _cameraPreviewWidget() {
    return LayoutBuilder(builder: (BuildContext context, BoxConstraints constraint) {
      return Stack(
        alignment: AlignmentDirectional.center,
        children: <Widget>[
          Image.asset(
            _scanState == 1 ? 'images/other/downloading_from_cloud.png' : _scanState == 2 ? 'images/other/download_failed.png' : _scanState == 3 ? 'images/other/qr_not_recognized.png' : 'images/other/qr_scanner.png',
          ),
          _scanState == 1
              ? Positioned(
                  top: 40,
                  child: SpinKitFadingCircle(itemBuilder: (_, int index) {
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        color: index.isEven ? Colors.lightBlue[900] : Colors.white,
                      ),
                    );
                  }))
              : Container(),
          Container(
            padding: const EdgeInsets.all(9.0),
            height: constraint.biggest.height,
            width: constraint.biggest.height,
            child: (controller == null)
                // if the controller is not active, do not
                // overlay anything on top of the image
                // otherwise if the controller is active,
                // overlay the camera preview on top of the image
                ? Container()
                : QRReaderPreview(controller),
          )
        ],
      );
    });
  }

  Future<void> onNewCameraSelected(CameraDescription cameraDescription) async {
    if (controller != null) {
      await controller.dispose();
    }
    controller = QRReaderController(cameraDescription, ResolutionPreset.high, <CodeFormat>[CodeFormat.qr, CodeFormat.pdf417], onCodeRead);

    // If the controller is updated then update the UI.
    controller.addListener(() {
      if (mounted) {
        setState(() {});
      }
      if (controller.value.hasError) {
        Utilities.showInSnackBar(context, widget.scaffoldKey, 'Camera error ${controller.value.errorDescription}', durationInSeconds: 7);
      }
    });

    try {
      await controller.initialize();
    } on QRReaderException catch (e) {
      //logError(e.code, e.description);
      Utilities.showInSnackBar(context, widget.scaffoldKey, 'Error: ${e.code}\n${e.description}', durationInSeconds: 7);
    }

    if (mounted) {
      setState(() {});
      controller.startScanning();
    }
    // return Future<void>(() {});((){});
  }
}
