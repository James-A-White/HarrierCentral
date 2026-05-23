import 'package:harrier_central/imports.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class ThirdPartyLogin extends StatefulWidget {
  const ThirdPartyLogin(this.isNewUser, {super.key});

  final bool isNewUser;

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<ThirdPartyLogin> {
  bool _isLoggedIn = false;
  ThirdPartyLoginData? _profileData;

  // bool _includeInGlobalHashDirectory = true;

  final TextEditingController _hashNameTextController = TextEditingController();
  final FocusNode _hashNameFocusNode = FocusNode();

  final TextEditingController _emailTextController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    if (!widget.isNewUser) {
      _hashNameTextController.value = TextEditingValue(
        text: getStringPref(StringPrefsEnum.hashName) ?? '',
      );
      _emailTextController.value = TextEditingValue(
        text: getStringPref(StringPrefsEnum.email) ?? '',
      );
    }
  }

  void _onLoginStatusChanged(bool loggedIn, {ThirdPartyLoginData? loginData}) {
    setStateIfMounted(() {
      _isLoggedIn = loggedIn;
      _profileData = loginData;
    });
  }

  @override
  void dispose() {
    _hashNameTextController.dispose();
    _hashNameFocusNode.dispose();
    _emailTextController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        backgroundColor: themeAppBarBackground,
        iconTheme: const IconThemeData(color: Colors.white, size: 28.0),
        title: Text('3rd Party Login', style: ts_appBarTitle),
      ),
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: Backgrounds.defaultHcBackground(),
        height: MediaQuery.sizeOf(context).height,
        child: _isLoading
            ? const Center(
                child: HcAppCircularProgressIndicator(key: Key('532270149')),
              )
            : _isLoggedIn
            ? _displayUserData(_profileData)
            : Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    if (!Platform.isIOS) ...<Widget>[
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 0.0,
                          vertical: 20.0,
                        ),
                        child: Center(
                          child: Text(
                            'No third party logins are available on Android devices.',
                            style: ts_headingVeryLarge,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],

                    if (Platform.isIOS) ...<Widget>[
                      GestureDetector(
                        onTap: () async {
                          await _appleLogin();
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 0.0,
                            vertical: 20.0,
                          ),
                          child: Image(
                            height: 60,
                            fit: BoxFit.fitWidth,
                            image: AssetImage(
                              'images/init/sign_in_with_apple.png',
                            ),
                          ),
                        ),
                      ),
                    ],
                    // Padding(
                    //   padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 20.0),
                    //   child: SignInWithAppleButton(
                    //       height: 60,
                    //       style: SignInWithAppleButtonStyle.whiteOutlined,
                    //       onPressed: () {
                    //         _appleLogin();
                    //       }),
                    // ),
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _appleLogin() async {
    try {
      final AuthorizationCredentialAppleID
      appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: <AppleIDAuthorizationScopes>[
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: WebAuthenticationOptions(
          clientId: 'com.harriercentral.hc',
          redirectUri: Uri.parse(
            'https://hcazurefunctions7.azurewebsites.net/api/HandleResponseFromApple',
          ),
        ),
        nonce: 'riejlwWj8f093FekWo9r3Edo9sp2Rdp3',
        state: 'Test',
      );

      await setStringPref(
        StringPrefsEnum.thirdPartyAuthorizationCode,
        appleCredential.authorizationCode,
      );
      await setStringPref(
        StringPrefsEnum.thirdPartyAccessToken,
        appleCredential.identityToken,
      );
      await setStringPref(
        StringPrefsEnum.thirdPartyUserId,
        appleCredential.userIdentifier,
      );
      await setStringPref(
        StringPrefsEnum.thirdPartyLoginType,
        ThirdPartyLoginType.apple.name,
      );
      await setStringPref(
        StringPrefsEnum.thirdPartyEmail,
        appleCredential.email,
      );

      await setDatePref(
        DatePrefsEnum.thirdPartyTokenLastUpdated,
        DateTime.now(),
      );

      final ThirdPartyLoginData d = ThirdPartyLoginData(
        ThirdPartyLoginType.apple.name,
        appleCredential.identityToken ?? '',
        appleCredential.userIdentifier ?? '',
        appleCredential.givenName ?? '',
        appleCredential.familyName ?? '',
        authorizationCode: appleCredential.authorizationCode,
        thirdPartyEmail: appleCredential.email ?? '',
      );

      if (widget.isNewUser) {
        _emailTextController.value = TextEditingValue(
          text: appleCredential.email ?? '',
        );
      }

      _onLoginStatusChanged(true, loginData: d);

      // ignore: unused_catch_clause
    } on UnknownSignInWithAppleException catch (e) {
      //print('UnknownSignInWithAppleException');
      //print(e.message);
      _onLoginStatusChanged(false);
      // ignore: unused_catch_clause
    } on SignInWithAppleCredentialsException catch (e) {
      //print('SignInWithAppleCredentialsException');
      //print(e.message);
      _onLoginStatusChanged(false);
      // ignore: unused_catch_clause
    } on SignInWithAppleAuthorizationException catch (e) {
      //print('SignInWithAppleCredentialsException');
      //print(e.message);
      _onLoginStatusChanged(false);
      // ignore: unused_catch_clause
    } on SignInWithAppleNotSupportedException catch (e) {
      //print('SignInWithAppleCredentialsException');
      //print(e.message);
      _onLoginStatusChanged(false);
    }

    // Now send the credential (especially `credential.authorizationCode`) to your server to create a session
    // after they have been validated with Apple (see `Integration` section for more information on how to do this)
  }

  Widget _displayUserData(ThirdPartyLoginData? profileData) {
    if (profileData == null) {
      return const SizedBox();
    }
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          //const SizedBox(height: 28.0),
          Padding(
            padding: const EdgeInsets.only(top: 25.0, bottom: 15.0),
            child: Text(
              'Logged in as:',
              textAlign: TextAlign.center,
              style: ts_title,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 15.0),
            child: Text(
              profileData.name ??
                  ('${profileData.firstName} ${profileData.lastName}'),
              textAlign: TextAlign.center,
              style: ts_headingVeryLarge,
            ),
          ),
          if ((profileData.photoUrl?.length ?? 0) > 5) ...<Widget>[
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20),
              child: SizedBox(
                width: MediaQuery.sizeOf(context).width / 2.0,
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.rectangle,
                      borderRadius: const BorderRadius.all(
                        Radius.circular(10.0),
                      ),
                      image: DecorationImage(
                        //fit: BoxFit.fitWidth,
                        image: NetworkImage(profileData.photoUrl!),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],

          const FancyDivider(
            key: Key('16692236'),
            innerColor: Colors.white,
            topMargin: 35.0,
            bottomMargin: 15.0,
          ),
          if (widget.isNewUser) ...<Widget>[
            Form(
              key: _formKey,
              child: Container(
                margin: const EdgeInsets.only(left: 15, right: 15),
                padding: const EdgeInsets.only(
                  left: 15,
                  right: 15,
                  top: 15,
                  bottom: 5,
                ),

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
                      controller: _hashNameTextController,
                      focusNode: _hashNameFocusNode,
                      decoration: InputDecoration(
                        labelText: 'Hash Name',
                        //hintText: profileData != null ? 'Just ' + profileData['first_name'] : '',
                        fillColor: hc_red,
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
                      style: ts_titleDarkRedLarge,
                    ),
                    const SizedBox(height: 20, width: 10),
                    TextFormField(
                      autocorrect: false,
                      //textCapitalization: TextCapitalization.characters,
                      controller: _emailTextController,
                      focusNode: _emailFocusNode,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        //hintText: profileData != null ? 'Just ' + profileData['first_name'] : '',
                        fillColor: hc_red,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: const BorderSide(),
                        ),
                      ),
                      validator: (String? value) {
                        return Utilities.validateEmail(value);
                      },
                      //,
                      // onSaved: (String val) {
                      //   _email = val;
                      // },
                      //keyboardType: TextInputType.,
                      textAlign: TextAlign.center,
                      style: ts_titleDarkRed,
                    ),
                    const SizedBox(height: 20, width: 10),
                    const SizedBox(height: 8, width: 10),
                  ],
                ),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.only(top: 25.0),
            child: TextButton(
              style: text_button_style,
              child: Text(
                widget.isNewUser ? 'Get started!' : 'Save Login Info',
                style: ts_button,
              ),
              onPressed: () async {
                if (!widget.isNewUser ||
                    ((_formKey.currentState != null) &&
                        (_formKey.currentState!.validate()))) {
                  setStateIfMounted(() {
                    _isLoading = true;
                  });

                  final HashersService hSrv = HashersService();
                  final dynamic result = await hSrv.processThirdPartyLogin(
                    loginData: profileData,
                    hashName: _hashNameTextController.text,
                    email: _emailTextController.text,
                    includeInGlobalHashDirectory: 0,
                    // includeInGlobalHashDirectory: _includeInGlobalHashDirectory ? 1 : 0,
                  );

                  if (result != null) {
                    await setStringPref(
                      StringPrefsEnum.profilePhotoUrl,
                      result[0]['photo'],
                    );
                    await setStringPref(
                      StringPrefsEnum.displayName,
                      result[0]['displayName'],
                    );
                    // if the email has not already been set, populate it with the email address received by the third party identity provider
                    if ((getStringPref(StringPrefsEnum.email) ?? '')
                        .trim()
                        .isEmpty) {
                      await setStringPref(
                        StringPrefsEnum.email,
                        result[0]['email'],
                      );
                    }
                    await setStringPref(
                      StringPrefsEnum.thirdPartyLoginEmail,
                      result[0]['thirdPartyEmail'],
                    );

                    final String thirdPartyLoginType =
                        result[0]['thirdPartyLoginType'] ?? 'none';
                    await setStringPref(
                      StringPrefsEnum.thirdPartyLoginType,
                      thirdPartyLoginType,
                    );

                    await setStringPref(
                      StringPrefsEnum.thirdPartyAuthorizationCode,
                      result[0]['thirdPartyAuthorizationCode'],
                    );
                    await setStringPref(
                      StringPrefsEnum.thirdPartyAccessToken,
                      result[0]['thirdPartyAccessToken'],
                    );
                    await setStringPref(
                      StringPrefsEnum.thirdPartyUserId,
                      result[0]['thirdPartyUserId'],
                    );

                    if (result[0]['thirdPartyTokenLastUpdated'] != null) {
                      await setDatePref(
                        DatePrefsEnum.thirdPartyTokenLastUpdated,
                        DateTime.tryParse(
                          result[0]['thirdPartyTokenLastUpdated'],
                        ),
                      );
                    } else {
                      await removePref(
                        DatePrefsEnum.thirdPartyTokenLastUpdated,
                      );
                    }

                    if (result[0]['thirdPartyAccessTokenExpires'] != null) {
                      await setDatePref(
                        DatePrefsEnum.thirdPartyTokenExpires,
                        DateTime.tryParse(
                          result[0]['thirdPartyAccessTokenExpires'],
                        ),
                      );
                    } else {
                      await removePref(DatePrefsEnum.thirdPartyTokenExpires);
                    }

                    await setStringPref(
                      StringPrefsEnum.firstName,
                      result[0]['firstName'],
                    );
                    await setStringPref(
                      StringPrefsEnum.hashName,
                      result[0]['hashName'],
                    );
                    await setStringPref(
                      StringPrefsEnum.lastName,
                      result[0]['lastName'],
                    );
                    await setStringPref(
                      StringPrefsEnum.qrCode,
                      result[0]['qrCode'],
                    );
                    await setStringPref(
                      StringPrefsEnum.supportCode,
                      result[0]['supportCode'],
                    );
                    await setStringPref(
                      StringPrefsEnum.resetCode,
                      result[0]['resetCode'],
                    );
                    await setStringPref(
                      StringPrefsEnum.qrSecretCode,
                      result[0]['qrSecretCode'],
                    );
                    await setStringPref(
                      StringPrefsEnum.userId,
                      result[0]['hasherId'],
                    );
                    final int preferences =
                        int.tryParse(result[0]['preferences'].toString()) ??
                        0; // we turn the result into a string and then back into an int to allow the DB to return either int or string without causing an error
                    await setIntPref(
                      IntPrefsEnum.hasherPreferences,
                      preferences,
                    );
                  } else {
                    await Utilities.showAlert(
                      'Account not created',
                      'There was a problem creating your account. Please delete the app and try again later or contact us at harriercentral@gmail.com.\r\n\r\nSorry for the inconvenience!',
                      'OK',
                    );
                    return;
                  }

                  if (widget.isNewUser) {
                    //final String profilePhotoUrl = getStringPref(StringPrefsEnum.profilePhotoUrl);
                    final String fileNamePrefix =
                        getStringPref(StringPrefsEnum.supportCode) ?? '';
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
                      ),
                    );
                  } else {
                    // not a new user, pop back to the User profile page.
                    await Utilities.showAlert(
                      'Login Successful',
                      'Your login was successful and your access has been upated.',
                      'OK',
                    ).then((_) {
                      Navigator.of(navigatorKey.currentContext!).pop();
                    });
                  }
                }
              },
            ),
          ),
          const SizedBox(height: 10, width: 10),
        ],
      ),
    );
  }
}

class ThirdPartyLoginData {
  ThirdPartyLoginData(
    this.loginType,
    this.accessToken,
    this.id,
    this.firstName,
    this.lastName, {
    this.photoUrl,
    this.name,
    this.authorizationCode,
    this.accessTokenExpires,
    this.thirdPartyEmail,
  }) {
    name ??= '$firstName $lastName';
  }

  String loginType;
  String accessToken;
  String id;
  String firstName;
  String lastName;

  String? name;
  String? photoUrl;
  String? authorizationCode;
  String? thirdPartyEmail;
  DateTime? accessTokenExpires;
}
