import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/styles.dart';
import 'package:harrier_central/widgets/offline_mode_ribbon.dart';
import 'package:harrier_central/util/utilities.dart';
import 'package:harrier_central/widgets/profile_photo.dart';
import 'package:harrier_central/data/models/user_model.dart';
import 'package:harrier_central/widgets/fancy_divider.dart';
import 'package:harrier_central/data/services/edit_user_service.dart';
import 'package:harrier_central/pages/init/choose_profile_image.dart';

// import 'package:harrier_central/widgets/user_details_ui.dart';
// import 'package:harrier_central/widgets/fancy_divider.dart';

class MyProfilePage extends StatefulWidget {
  //final FutureRunScopedModel futureRunsModel;

  const MyProfilePage({Key key}) : super(key: key);

  @override
  MyProfilePageState createState() => MyProfilePageState();
}

class MyProfilePageState extends State<MyProfilePage> {
  // String firstName = getStringPref(StringPrefsEnum.firstName);
  // String lastName = getStringPref(StringPrefsEnum.lastName);
  // String email = getStringPref(StringPrefsEnum.email);
  // String hashName = getStringPref(StringPrefsEnum.hashName);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _autoValidate = false;

  String _firstName = getStringPref(StringPrefsEnum.firstName);
  String _lastName = getStringPref(StringPrefsEnum.lastName);
  String _email = getStringPref(StringPrefsEnum.email);
  String _hashName = getStringPref(StringPrefsEnum.displayName);
  String _photo = getStringPref(StringPrefsEnum.profilePhotoUrl);

  bool _isLoading = false;

  Widget _buildCircularProgressIndicator() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
        Text(
          'Updating User Profile',
          style: headingStyle,
          textAlign: TextAlign.center,
        ),
        Container(height: 30),
        SpinKitCircle(
          size: 75.0,
          itemBuilder: (_, int index) {
            return DecoratedBox(
              decoration: BoxDecoration(
                color: index.isEven ? Colors.grey[50] : Theme.of(context).accentColor,
              ),
            );
          },
        ),
      ]),
    );
  }

  TextStyle headingStyle = const TextStyle(fontFamily: 'AvenirNextRegular', fontStyle: FontStyle.normal, color: Colors.yellow, fontSize: 22.0, height: 1.0);

  TextStyle buttonTextStyle = const TextStyle(fontFamily: 'AvenirNextRegular', fontStyle: FontStyle.normal, color: Colors.white, fontSize: 16.0, height: 1.0);

  GlobalKey<ScaffoldState> scaffoldKey;

  void _updateProfile() {
    if (_formKey.currentState.validate()) {
//    If all data are correct then save data to out variables
      _formKey.currentState.save();

      setState(() {
        _isLoading = true;
        final String userId = getStringPref(StringPrefsEnum.userId);

        final EditUserService srv = EditUserService();
        final Future<dynamic> apiCall = srv.editUser(context: context, targetUserId: userId, firstName: _firstName, lastName: _lastName, email: _email, hashName: _hashName, photo: '');

        apiCall.then((dynamic result) {
          setState(() {
            _isLoading = false;
            if (result is UserModel) {
              setStringPref(StringPrefsEnum.profilePhotoUrl, result.photo);
              setStringPref(StringPrefsEnum.displayName, result.displayName);
              setStringPref(StringPrefsEnum.email, result.email);
              setStringPref(StringPrefsEnum.firstName, result.firstName);
              setStringPref(StringPrefsEnum.hashName, result.hashName);
              setStringPref(StringPrefsEnum.lastName, result.lastName);
            }
          });

          // if (result[
          //         'result'] !=
          //     'failed') {
          //   userName = getStringPref(
          //       StringPrefsEnum
          //           .displayName);
          //   userQrCode =
          //       getStringPref(
          //           StringPrefsEnum
          //               .qrSecretCode);

          //   Utilities.showAlert(
          //       context,
          //       'App Reset Successful',
          //       'Your app has been successfully reset. Please close and restart the app to ensure all data is properly reloaded.',
          //       'OK');
          // }
        });
      });
    } else {
//    If all data are not valid then start auto validation.
      setState(() {
        _autoValidate = true;
      });
    }
  }

  Widget formUi() {
    return Column(
      children: <Widget>[
        TextFormField(
          autocorrect: false,
          initialValue: _firstName,
          decoration: const InputDecoration(labelText: 'First Name'),
          keyboardType: TextInputType.text,
          validator: (String arg) {
            if (arg.length < 3)
              return 'Name must be more than 2 charaters';
            else
              return null;
          },
          onSaved: (String val) {
            _firstName = val;
          },
        ),
        TextFormField(
          autocorrect: false,
          initialValue: _lastName,
          decoration: const InputDecoration(labelText: 'Last Name'),
          keyboardType: TextInputType.text,
          validator: (String arg) {
            if (arg.length < 3)
              return 'Name must be more than 2 charaters';
            else
              return null;
          },
          onSaved: (String val) {
            _lastName = val;
          },
        ),
        TextFormField(
          autocorrect: false,
          initialValue: _email,
          decoration: const InputDecoration(labelText: 'Email'),
          keyboardType: TextInputType.emailAddress,
          validator: validateEmail,
          onSaved: (String val) {
            _email = val;
          },
        ),
        TextFormField(
          autocorrect: false,
          initialValue: _hashName,
          decoration: const InputDecoration(labelText: 'Hash Name (optional)'),
          onSaved: (String val) {
            _hashName = val;
          },
          keyboardType: TextInputType.text,
        ),
        const SizedBox(
          height: 10.0,
        ),
        Utilities.styleForConnected(
          RaisedButton(
            onPressed: () {
              if (Utilities.checkForConnection(context)) {
                _updateProfile();
              }
            },
            child: Text('Save Changes', style: buttonTextStyle),
          ),
        ),
      ],
    );
  }

  String validateEmail(String value) {
    const Pattern pattern = r"[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?";
    final RegExp regex = RegExp(pattern, caseSensitive: false);
    if (!regex.hasMatch(value))
      return 'Enter Valid Email';
    else
      return null;
  }

  @override
  Widget build(BuildContext context) {
    final AppBar appBar = AppBar(
      centerTitle: true,
      backgroundColor: themeAppBarBackground,
      title: const Text(
        'My Profile',
        style: TextStyle(
          color: Colors.white,
        ),
      ),
    );
    return Stack(
      children: <Widget>[
        Container(height: MediaQuery.of(context).size.height, width: MediaQuery.of(context).size.width),
        Positioned(
          top: 0,
          left: 0,
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Scaffold(
            key: scaffoldKey,
            appBar: appBar,
            body: _isLoading
                ? Container(height: MediaQuery.of(context).size.height - appBar.preferredSize.height, decoration: Backgrounds.defaultHcBackground(), child: _buildCircularProgressIndicator())
                : Container(
                    decoration: Backgrounds.defaultHcBackground(),
                    height: MediaQuery.of(context).size.height - appBar.preferredSize.height,
                    child: SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                            //minHeight: viewportConstraints.maxHeight,
                            ),
                        child: IntrinsicHeight(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 30, left: 20, right: 20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: <Widget>[
                                // TODO(James): Bring this back eventually
                                // UserDetailsUi(firstName: firstName, lastName: lastName, email: email, hashName: hashName,),
                                // const FancyDivider(innerColor: Colors.white),
                                Container(
                                  width: MediaQuery.of(context).size.width,
                                  child: IntrinsicHeight(
                                    child: Stack(
                                      fit: StackFit.expand,
                                      alignment: AlignmentDirectional.center,
                                      children: <Widget>[
                                        Container(height: 800),
                                        Positioned(
                                          top: 25,
                                          left: 0,
                                          right: 0,
                                          child: Text(
                                            'My Profile Information',
                                            style: headingStyle,
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        Positioned(
                                            top: 40,
                                            //bottom: 20,
                                            width: MediaQuery.of(context).size.width,
                                            child: Container(
                                              padding: const EdgeInsets.all(30.0),
                                              child: Container(
                                                child: Center(
                                                  child: Column(
                                                    children: <Widget>[
                                                      Container(
                                                        padding: const EdgeInsets.all(10.0),
                                                        margin: const EdgeInsets.only(bottom: 45),
                                                        decoration: BoxDecoration(
                                                          color: Colors.yellow[100],
                                                          borderRadius: BorderRadius.circular(5.0),
                                                        ),
                                                        child: Form(
                                                          key: _formKey,
                                                          autovalidate: _autoValidate,
                                                          child: formUi(),
                                                        ),
                                                      ),

                                                      const FancyDivider(innerColor: Colors.white),

                                                      //SizedBox(height: 30),
                                                      Container(
                                                        height: 220,
                                                        color: Colors.white,
                                                        padding: const EdgeInsets.all(10.0),
                                                        margin: const EdgeInsets.only(top: 20, bottom: 30),
                                                        child: ProfilePhoto(
                                                          profilePhotoUrl: _photo,
                                                          photoHeight: 200.0,
                                                          leftPadding: 0.0,
                                                        ),
                                                      ),

                                                      Utilities.styleForConnected(
                                                        RaisedButton(
                                                          onPressed: () {
                                                            if (Utilities.checkForConnection(context)) {
                                                              Navigator.push(
                                                                context,
                                                                MaterialPageRoute<UserModel>(
                                                                  builder: (BuildContext context) => const ChooseProfileImage(
                                                                        isForThisDevice: true,
                                                                        doAddUser: false,
                                                                      ),
                                                                ),
                                                              ).then((dynamic result) {
                                                                setState(() {
                                                                  _photo = getStringPref(StringPrefsEnum.profilePhotoUrl);
                                                                });
                                                              });
                                                            }
                                                          },
                                                          child: Text('Update Profile Image', style: buttonTextStyle),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            )),
                                      ],
                                    ),
                                  ),
                                ),
                                Container(width: 40, height: 40),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ),
        
        const OfflineModeRibbon(),
      
      ],
    );
  }
}
