import 'dart:convert';
import 'dart:core';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter/cupertino.dart';

import 'package:audioplayers/audio_cache.dart';
import 'package:fast_qr_reader_view/fast_qr_reader_view.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:http/http.dart' as http;

import 'package:harrier_central/main.dart';
import 'package:harrier_central/pages/init/choose_profile_image.dart';
import 'package:harrier_central/pages/top_level/main_navigation_page.dart';
import 'package:harrier_central/services/authorize_device_service.dart';
import 'package:harrier_central/util/utilities.dart';
import 'package:harrier_central/util/enums.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/styles.dart';
import 'package:harrier_central/widgets/user_details_ui.dart';
import 'package:harrier_central/data_models/user_model.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';

class NewUserWidget extends StatefulWidget {
  const NewUserWidget(
      {Key key,
      this.isForThisDevice,
      this.eventId,
      this.kennelId,
      this.attendenceState,
      this.scaffoldKey})
      : super(key: key);

  final bool isForThisDevice;
  final String eventId;
  final String kennelId;
  final EnumAttendenceState<int> attendenceState;

  final GlobalKey<ScaffoldState> scaffoldKey;

  @override
  State<NewUserWidget> createState() {
    return NewUserState();
  }
}

class NewUserState extends State<NewUserWidget>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _scanState = 0;

  Color left = Colors.black;
  Color right = Colors.white;

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  GlobalKey<ScaffoldState> scaffoldKey;

  @override
  Widget build(BuildContext context) {
    {
      final AppBar appBar = AppBar(
        centerTitle: true,
        backgroundColor: themeAppBarBackground,
        title: const Text(
          'Add Member',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      );

      return Scaffold(
          key: scaffoldKey,
          appBar: widget.isForThisDevice ? null : appBar,
          body: SingleChildScrollView(
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height >= 500.0
                  ? MediaQuery.of(context).size.height -
                      (widget.isForThisDevice ? 0 : appBar.preferredSize.height)
                  : 500.0,
              decoration: Backgrounds.defaultHcBackground(),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: 45.0),
                    child: Image(
                        width: widget.isForThisDevice == true ? 50.0 : 100.0,
                        height: widget.isForThisDevice == true ? 50.0 : 100.0,
                        fit: BoxFit.fill,
                        image:
                            const AssetImage('images/other/hc_app_icon.png')),
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
          ));
    }
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
                    padding: const EdgeInsets.symmetric(
                        vertical: 10.0, horizontal: 42.0),
                    child: Text(
                      controller == null ? 'Start Scanning' : 'Stop Scanning',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 25.0,
                          fontFamily: 'WorkSansBold'),
                    ),
                  ),
                  onPressed: () => scanUserBarcode()),
            ),
          ),
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
    return Container(
      padding: const EdgeInsets.only(top: 23.0),
      child: Column(
        children: <Widget>[
          !widget.isForThisDevice
              ? Container()
              : Utilities.elegantDivider(
                  'First Connect\r\nto FB (optional)', 0.0, 5.0),
          !widget.isForThisDevice
              ? Container()
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0, right: 0.0),
                      child: GestureDetector(
                        onTap: () {
                          final FacebookLogin facebookLogin = FacebookLogin();
                          facebookLogin
                              .logInWithReadPermissions(<String>['email']).then(
                                  (FacebookLoginResult result) async {
                            final String token = result.accessToken.token;
                            final http.Response graphResponse = await http.get(
                                'https://graph.facebook.com/v3.2/me?fields=name,first_name,last_name,picture.width(640),email,gender&access_token=$token');

                            final dynamic profile =
                                json.decode(graphResponse.body);

                            final String firstName = profile['first_name'];
                            final String lastName = profile['last_name'];
                            final String email = profile['email'];
                            final String facebookId = profile['id'];
                            final String gender = profile['gender'];
                            final dynamic picture =
                                profile['picture']['data']['url'];

                            setStringPref(
                                StringPrefsEnum.facebookProfilePhoto, picture);
                            setStringPref(
                                StringPrefsEnum.facebookId, facebookId);
                            setStringPref(
                                StringPrefsEnum.facebookAccessToken, token);
                            setStringPref(StringPrefsEnum.gender, gender);

                            userDetailsUi.updateUi(firstName, lastName, email);
                            userDetailsUi.firstName = firstName;
                            userDetailsUi.lastName = lastName;
                            userDetailsUi.email = email;

                            Utilities.showAlert(
                                context,
                                'Facebook profile loaded',
                                'We have copied your Facebook profile information (name, email and profile photo) to the app. Please continue to register by adding your Hash name.',
                                'OK');
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(15.0),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: const Icon(
                            FontAwesome.facebook_f,
                            color: Color(0xFF0084ff),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
          !widget.isForThisDevice
              ? Container()
              : Utilities.elegantDivider('Then add\r\ndetails', 15.0, 20.0),
          Stack(
            alignment: Alignment.topCenter,
            overflow: Overflow.visible,
            children: <Widget>[
              userDetailsUi,
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
                        'NEXT >>',
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
        ],
      ),
    );
  }

  void _onSignInTabPress() {
    _pageController.animateToPage(0,
        duration: const Duration(milliseconds: 500), curve: Curves.decelerate);
  }

  void _onSignUpTabPress() {
    _pageController?.animateToPage(1,
        duration: const Duration(milliseconds: 500), curve: Curves.decelerate);
  }

  void _onSignUpButtonPress() {
    bool canProcess = true;

    if (userDetailsUi != null && userDetailsUi.firstName.isEmpty) {
      canProcess = false;
      Utilities.showInSnackBar(
          context, widget.scaffoldKey, 'Please enter your first name',
          durationInSeconds: 7);
    }

    if (userDetailsUi != null && userDetailsUi.lastName.isEmpty) {
      canProcess = false;
      Utilities.showInSnackBar(
          context, widget.scaffoldKey, 'Please enter your last name',
          durationInSeconds: 7);
    }

    bool emailValid = false;

    if (userDetailsUi != null) {
      emailValid = RegExp(
              r"[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?",
              caseSensitive: false)
          .hasMatch(userDetailsUi.email);
    }

    if (canProcess && !emailValid) {
      canProcess = false;
      Utilities.showInSnackBar(
          context, widget.scaffoldKey, 'Please enter a valid email address',
          durationInSeconds: 7);
    }

    if (canProcess && (userDetailsUi != null)) {
      setState(() {
        _scanState = 1;
      });

      if (widget.isForThisDevice) {
        setStringPref(StringPrefsEnum.firstName, userDetailsUi.firstName);
        setStringPref(StringPrefsEnum.lastName, userDetailsUi.lastName);
        setStringPref(StringPrefsEnum.email, userDetailsUi.email);
        setStringPref(StringPrefsEnum.hashName, userDetailsUi.hashName);

        Navigator.push(
          context,
          MaterialPageRoute<UserModel>(
            builder: (BuildContext context) => const ChooseProfileImage(
                  isForThisDevice: true,
                  doAddUser: true,
                ),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute<UserModel>(
            builder: (BuildContext context) => ChooseProfileImage(
                  isForThisDevice: widget.isForThisDevice,
                  doAddUser: true,
                  firstName: userDetailsUi.firstName,
                  lastName: userDetailsUi.lastName,
                  hashName: userDetailsUi.hashName,
                  email: userDetailsUi.email,
                  kennelId: widget.kennelId,
                  eventId: widget.eventId,
                  attendenceState: widget.attendenceState,
                ),
          ),
        ).then<dynamic>((UserModel user) {
          if (user != null) {
            Navigator.of(context).pop(user);
          }
        });
      }
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
      final Future<Map<String, String>> apiCall =
          srv.authorizeDevice(context, scanResult);
      apiCall.then((Map<String, String> result) {
        if (result != null) {
          Future<dynamic>.delayed(const Duration(milliseconds: 3500))
              .then((void dummy) {
            if (result['result'] == 'success') {
              setState(() => _scanState = 0);
              Navigator.pushReplacement<dynamic, dynamic>(
                  context,
                  MaterialPageRoute<dynamic>(
                      builder: (BuildContext context) =>
                          const MainNavigationPage()));
            } else {
              // downloading from the cloud failed
              setState(() => _scanState = 2);
              Utilities.showInSnackBar(
                  context, widget.scaffoldKey, result['message'],
                  durationInSeconds: 7);
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
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraint) {
      return Stack(
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
    controller = QRReaderController(cameraDescription, ResolutionPreset.high,
        <CodeFormat>[CodeFormat.qr, CodeFormat.pdf417], onCodeRead);

    // If the controller is updated then update the UI.
    controller.addListener(() {
      if (mounted) {
        setState(() {});
      }
      if (controller.value.hasError) {
        Utilities.showInSnackBar(context, widget.scaffoldKey,
            'Camera error ${controller.value.errorDescription}',
            durationInSeconds: 7);
      }
    });

    try {
      await controller.initialize();
    } on QRReaderException catch (e) {
      //logError(e.code, e.description);
      Utilities.showInSnackBar(
          context, widget.scaffoldKey, 'Error: ${e.code}\n${e.description}',
          durationInSeconds: 7);
    }

    if (mounted) {
      setState(() {});
      controller.startScanning();
    }
    // return Future<void>(() {});((){});
  }
}

class TabIndicationPainter extends CustomPainter {
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

  Paint painter;
  final double dxTarget;
  final double dxEntry;
  final double radius;
  final double dy;

  final PageController pageController;

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
