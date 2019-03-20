
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:flutter/material.dart';

import 'package:harrier_central/util/routes.dart';
import 'package:harrier_central/util/styles.dart';



class FbLoginPage extends StatefulWidget {
    @override
  _LoginPageState createState() => _LoginPageState();
}


class _LoginPageState extends State<FbLoginPage> {
  bool isLoggedIn = false;
  dynamic profileData;
  String accessToken;

  FacebookLogin facebookLogin = FacebookLogin();

  void onLoginStatusChanged(bool isLoggedIn, {dynamic profileData, String accessToken}) {
    setState(() {
      this.isLoggedIn = isLoggedIn;
      this.profileData = profileData;
      this.accessToken = accessToken;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: ThemeColors.appBarBackground,
          title: const Text('Facebook Login'),
          actions: <Widget>[
            IconButton(
              icon: const  Icon(
                Icons.exit_to_app,
                color: Colors.white,
              ),
              onPressed: () => facebookLogin.isLoggedIn
                  .then<dynamic>((bool isLoggedIn) => isLoggedIn ? _logout() : null),
            ),
          ],
        ),
        body: Container(
          child: Center(
            child: isLoggedIn
                ? _displayUserData(profileData)
                : _displayLoginButton(),
          ),
        ),
      ),
    );
  }

  Future<void> initiateFacebookLogin() async {
    final FacebookLoginResult facebookLoginResult =
        await facebookLogin.logInWithReadPermissions(<String>['email']);

    switch (facebookLoginResult.status) {
      case FacebookLoginStatus.error:
        onLoginStatusChanged(false);
        break;
      case FacebookLoginStatus.cancelledByUser:
        onLoginStatusChanged(false);
        break;
      case FacebookLoginStatus.loggedIn:
        // dynamic graphResponse = await http.get(
        //     'https://graph.facebook.com/v2.12/me?fields=name,first_name,last_name,email,picture.height(200)&access_token=${facebookLoginResult.accessToken.token}');

        // dynamic profile = json.decode(graphResponse.body);
        // print(profile.toString());

        // onLoginStatusChanged(true, profileData: profile, accessToken: facebookLoginResult.accessToken.token );
        Navigator.pushReplacementNamed(context, RouteNames.MAIN_LANDING_PAGE.toString());
        break;
    }
  }

 dynamic _displayUserData(dynamic profileData) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          height: 200.0,
          width: 200.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
              fit: BoxFit.fill,
              image: NetworkImage(
                profileData['picture']['data']['url'],
              ),
            ),
          ),
        ),
        const SizedBox(height: 28.0),
        Text(
          "Logged in as: ${profileData['name']}",
          style: const TextStyle(
            fontSize: 20.0,
          ),
        ),
      ],
    );
  }

 dynamic _displayLoginButton() {
    return RaisedButton(
      child: const Text('Login with Facebook'),
      onPressed: () => initiateFacebookLogin(),
    );
  }

  dynamic _logout() async {
    await facebookLogin.logOut();
    onLoginStatusChanged(false);
    print('Logged out');
  }
}
