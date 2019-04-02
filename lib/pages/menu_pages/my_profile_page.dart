import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/styles.dart';
import 'package:harrier_central/util/utilities.dart';
import 'package:harrier_central/data_models/user_model.dart';
import 'package:harrier_central/widgets/fancy_divider.dart';
import 'package:harrier_central/services/edit_user_service.dart';

// import 'package:harrier_central/widgets/user_details_ui.dart';
// import 'package:harrier_central/widgets/fancy_divider.dart';

class MyProfilePage extends StatefulWidget {
  //final FutureRunScopedModel futureRunsModel;

  const MyProfilePage({Key key}) : super(key: key);

  @override
  MyProfilePageState createState() => MyProfilePageState();
}

class MyProfilePageState extends State<MyProfilePage> {
  String firstName = getStringPref(StringPrefsEnum.firstName);
  String lastName = getStringPref(StringPrefsEnum.lastName);
  String email = getStringPref(StringPrefsEnum.email);
  String hashName = getStringPref(StringPrefsEnum.hashName);

  // final FocusNode firstNameFocusNode = FocusNode();
  // final FocusNode lastNameFocusNode = FocusNode();
  // final FocusNode emailFocusNode = FocusNode();
  // final FocusNode hashNameFocusNode = FocusNode();

  // TextEditingController firstNameTextController;
  // TextEditingController lastNameTextController;
  // TextEditingController emailTextController;
  // TextEditingController hashNameTextController;

  @override
  void initState() {
    super.initState();

    
    // firstNameTextController = TextEditingController();
    // lastNameTextController = TextEditingController();
    // emailTextController = TextEditingController();
    // hashNameTextController = TextEditingController();
  }

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _autoValidate = false;

  //String _displayName = getStringPref(StringPrefsEnum.displayName);
  String _firstName = getStringPref(StringPrefsEnum.firstName);
  String _lastName = getStringPref(StringPrefsEnum.lastName);
  String _email = getStringPref(StringPrefsEnum.email);
  String _hashName = getStringPref(StringPrefsEnum.displayName);
  //String _photo = getStringPref(StringPrefsEnum.profilePhotoUrl);

  bool _isLoading = false;

  Widget _buildCircularProgressIndicator() {
    return Center(
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
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
                    color: index.isEven
                        ? Colors.grey[50]
                        : Theme.of(context).accentColor,
                  ),
                );
              },
            ),
          ]),
    );
  }

  TextStyle headingStyle = const TextStyle(
      fontFamily: 'AvenirNextRegular',
      fontStyle: FontStyle.normal,
      color: Colors.yellow,
      fontSize: 22.0,
      height: 1.0);

  TextStyle buttonTextStyle = const TextStyle(
      fontFamily: 'AvenirNextRegular',
      fontStyle: FontStyle.normal,
      color: Colors.white,
      fontSize: 16.0,
      height: 1.0);

  GlobalKey<ScaffoldState> scaffoldKey;

  void _updateProfile() {
    if (_formKey.currentState.validate()) {
//    If all data are correct then save data to out variables
      _formKey.currentState.save();

      setState(() {
        _isLoading = true;
        final String userId = getStringPref(StringPrefsEnum.userId);

        final EditUserService srv = EditUserService();
        final Future<dynamic> apiCall = srv.editUser(
            context: context,
            targetUserId: userId,
            firstName: _firstName,
            lastName: _lastName,
            email: _email,
            hashName: _hashName,
            photo: '');

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

  Widget FormUI() {
    return new Column(
      children: <Widget>[
        new TextFormField(
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
        new TextFormField(
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
        new TextFormField(
          autocorrect: false,
          initialValue: _email,
          decoration: const InputDecoration(labelText: 'Email'),
          keyboardType: TextInputType.emailAddress,
          validator: validateEmail,
          onSaved: (String val) {
            _email = val;
          },
        ),
        new TextFormField(
          autocorrect: false, 
          initialValue: _hashName,
          decoration: const InputDecoration(labelText: 'Hash Name (optional)'),
          onSaved: (String val) {
            _hashName = val;
          },
          keyboardType: TextInputType.text,
        ),
        new SizedBox(
          height: 10.0,
        ),
        new RaisedButton(
          onPressed: _updateProfile,
          child: new Text('Update Your Profile', style: buttonTextStyle),
        )
      ],
    );
  }

  String validateEmail(String value) {
    const Pattern pattern =
        r"[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?";
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
    return Scaffold(
      key: scaffoldKey,
      appBar: appBar,
      body:

          // new SingleChildScrollView(
          //     child: new Container(
          //       decoration: Backgrounds.defaultHcBackgroundLight(),
          //       padding: new EdgeInsets.all(15.0),
          //       child: new Form(
          //         key: _formKey,
          //         autovalidate: _autoValidate,
          //         child: FormUI(),
          //       ),
          //     ),
          //   ),

          _isLoading
              ? Container(
                  height: MediaQuery.of(context).size.height -
                      appBar.preferredSize.height,
                  decoration: Backgrounds.defaultHcBackground(),
                  child: _buildCircularProgressIndicator())
              : Container(
                  decoration: Backgrounds.defaultHcBackground(),
                  height: MediaQuery.of(context).size.height -
                      appBar.preferredSize.height,
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                          //minHeight: viewportConstraints.maxHeight,
                          ),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: const EdgeInsets.only(
                              top: 30, left: 20, right: 20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              // TODO(James): Bring this back eventually
                              // UserDetailsUi(firstName: firstName, lastName: lastName, email: email, hashName: hashName,),
                              // const FancyDivider(innerColor: Colors.white),
                              Container(
                                //height:500,
                                width: MediaQuery.of(context).size.width,

                                child: IntrinsicHeight(
                                  child: Stack(
                                    fit: StackFit.expand,
                                    alignment: AlignmentDirectional.center,
                                    children: <Widget>[
                                      Container(height: 500),
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
                                          width:
                                              MediaQuery.of(context).size.width,
                                          child: Container(
                                            padding: const EdgeInsets.all(30.0),

                                            //color: const Color.fromARGB(255, 255, 255, 255),
                                            child: Container(
                                              child: Center(
                                                child: Column(
                                                  children: <Widget>[
                                                    Container(
                                                      //color: Colors.white,
                                                      padding:
                                                          const EdgeInsets.all(
                                                              10.0),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            Colors.yellow[100],
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(5.0),
                                                      ),
                                                      // padding: const EdgeInsets.only(
                                                      //     top: 0.0, bottom: 8.0),
                                                      child: new Form(
                                                        key: _formKey,
                                                        autovalidate:
                                                            _autoValidate,
                                                        child: FormUI(),
                                                      ),

                                                      //     Column(children: <Widget>[
                                                      //   Padding(
                                                      //     padding:
                                                      //         const EdgeInsets.all(
                                                      //             8.0),
                                                      //     child: TextFormField(
                                                      //       autocorrect: false,
                                                      //       controller:
                                                      //           firstNameTextController,
                                                      //       focusNode:
                                                      //           firstNameFocusNode,
                                                      //       decoration:
                                                      //           InputDecoration(
                                                      //         labelText:
                                                      //             'First Name',
                                                      //         fillColor: Colors.red,
                                                      //         border:
                                                      //             OutlineInputBorder(
                                                      //           borderRadius:
                                                      //               BorderRadius
                                                      //                   .circular(
                                                      //                       25.0),
                                                      //           borderSide:
                                                      //               BorderSide(),
                                                      //         ),
                                                      //       ),
                                                      //       // validator: (val) {
                                                      //       //   if (val.length == 0) {
                                                      //       //     return "Email cannot be empty";
                                                      //       //   } else {
                                                      //       //     return null;
                                                      //       //   }
                                                      //       // },
                                                      //       keyboardType:
                                                      //           TextInputType.text,
                                                      //       style: const TextStyle(
                                                      //         fontFamily: 'Poppins',
                                                      //       ),
                                                      //     ),
                                                      //   ),
                                                      //   Padding(
                                                      //     padding:
                                                      //         const EdgeInsets.all(
                                                      //             8.0),
                                                      //     child: TextFormField(
                                                      //       autocorrect: false,
                                                      //       controller:
                                                      //           lastNameTextController,
                                                      //       focusNode:
                                                      //           lastNameFocusNode,
                                                      //       decoration:
                                                      //           InputDecoration(
                                                      //         labelText:
                                                      //             'Last Name',
                                                      //         fillColor: Colors.red,
                                                      //         border:
                                                      //             OutlineInputBorder(
                                                      //           borderRadius:
                                                      //               BorderRadius
                                                      //                   .circular(
                                                      //                       25.0),
                                                      //           borderSide:
                                                      //               BorderSide(),
                                                      //         ),
                                                      //       ),
                                                      //       // validator: (val) {
                                                      //       //   if (val.length == 0) {
                                                      //       //     return "Email cannot be empty";
                                                      //       //   } else {
                                                      //       //     return null;
                                                      //       //   }
                                                      //       // },
                                                      //       keyboardType:
                                                      //           TextInputType.text,
                                                      //       style: const TextStyle(
                                                      //         fontFamily: 'Poppins',
                                                      //       ),
                                                      //     ),
                                                      //   ),
                                                      //   Padding(
                                                      //     padding:
                                                      //         const EdgeInsets.all(
                                                      //             8.0),
                                                      //     child: TextFormField(
                                                      //       autocorrect: false,
                                                      //       controller:
                                                      //           emailTextController,
                                                      //       focusNode:
                                                      //           emailFocusNode,
                                                      //       decoration:
                                                      //           InputDecoration(
                                                      //         labelText: 'Email',
                                                      //         fillColor: Colors.red,
                                                      //         border:
                                                      //             OutlineInputBorder(
                                                      //           borderRadius:
                                                      //               BorderRadius
                                                      //                   .circular(
                                                      //                       25.0),
                                                      //           borderSide:
                                                      //               BorderSide(),
                                                      //         ),
                                                      //       ),
                                                      //       // validator: (val) {
                                                      //       //   if (val.length == 0) {
                                                      //       //     return "Email cannot be empty";
                                                      //       //   } else {
                                                      //       //     return null;
                                                      //       //   }
                                                      //       // },
                                                      //       keyboardType:
                                                      //           TextInputType.text,
                                                      //       style: const TextStyle(
                                                      //         fontFamily: 'Poppins',
                                                      //       ),
                                                      //     ),
                                                      //   ),
                                                      //   Padding(
                                                      //     padding:
                                                      //         const EdgeInsets.all(
                                                      //             8.0),
                                                      //     child: TextFormField(
                                                      //       autocorrect: false,
                                                      //       controller:
                                                      //           hashNameTextController,
                                                      //       focusNode:
                                                      //           hashNameFocusNode,
                                                      //       decoration:
                                                      //           InputDecoration(
                                                      //         labelText:
                                                      //             'Hash Name',
                                                      //         fillColor: Colors.red,
                                                      //         border:
                                                      //             OutlineInputBorder(
                                                      //           borderRadius:
                                                      //               BorderRadius
                                                      //                   .circular(
                                                      //                       25.0),
                                                      //           borderSide:
                                                      //               BorderSide(),
                                                      //         ),
                                                      //       ),
                                                      //       // validator: (val) {
                                                      //       //   if (val.length == 0) {
                                                      //       //     return "Email cannot be empty";
                                                      //       //   } else {
                                                      //       //     return null;
                                                      //       //   }
                                                      //       // },
                                                      //       keyboardType:
                                                      //           TextInputType.text,
                                                      //       style: const TextStyle(
                                                      //         fontFamily: 'Poppins',
                                                      //       ),
                                                      //     ),
                                                      //   ),
                                                      // ]),
                                                    ),


                                                    // Padding(
                                                    //   padding:
                                                    //       const EdgeInsets.only(
                                                    //           top: 25),
                                                    //   child: Row(
                                                    //       mainAxisAlignment:
                                                    //           MainAxisAlignment
                                                    //               .spaceAround,
                                                    //       children: <Widget>[
                                                    //         RaisedButton(
                                                    //           padding:
                                                    //               const EdgeInsets
                                                    //                       .only(
                                                    //                   top: 15,
                                                    //                   bottom:
                                                    //                       15,
                                                    //                   left: 50,
                                                    //                   right:
                                                    //                       50),
                                                    //           onPressed: () {
                                                    //             bool
                                                    //                 canProcess =
                                                    //                 true;
                                                    //             bool
                                                    //                 emailValid =
                                                    //                 false;

                                                    //             emailValid = RegExp(
                                                    //                     r"[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?",
                                                    //                     caseSensitive:
                                                    //                         false)
                                                    //                 .hasMatch(
                                                    //                     emailTextController
                                                    //                         .text);

                                                    //             if (!emailValid) {
                                                    //               canProcess =
                                                    //                   false;
                                                    //               Utilities.showInSnackBar(
                                                    //                   context,
                                                    //                   scaffoldKey,
                                                    //                   'Please enter a valid email address',
                                                    //                   durationInSeconds:
                                                    //                       7);
                                                    //             }

                                                    //             if (canProcess) {
                                                    //               setState(() {
                                                    //                 _isLoading =
                                                    //                     true;
                                                    //                 final String
                                                    //                     userId =
                                                    //                     getStringPref(
                                                    //                         StringPrefsEnum.userId);

                                                    //                 final EditUserService
                                                    //                     srv =
                                                    //                     EditUserService();
                                                    //                 final Future<dynamic> apiCall = srv.editUser(
                                                    //                     context:
                                                    //                         context,
                                                    //                     targetUserId:
                                                    //                         userId,
                                                    //                     firstName:
                                                    //                         _firstName,
                                                    //                     lastName:
                                                    //                         _lastName,
                                                    //                     email: _email,
                                                    //                     hashName:
                                                    //                         _hashName,
                                                    //                     photo:
                                                    //                         '');

                                                    //                 apiCall.then(
                                                    //                     (dynamic
                                                    //                         result) {
                                                    //                   setState(
                                                    //                       () {
                                                    //                     _isLoading =
                                                    //                         false;
                                                    //                     if (result
                                                    //                         is UserModel) {
                                                    //                       setStringPref(
                                                    //                           StringPrefsEnum.profilePhotoUrl,
                                                    //                           result.photo);
                                                    //                       setStringPref(
                                                    //                           StringPrefsEnum.displayName,
                                                    //                           result.displayName);
                                                    //                       setStringPref(
                                                    //                           StringPrefsEnum.email,
                                                    //                           result.email);
                                                    //                       setStringPref(
                                                    //                           StringPrefsEnum.firstName,
                                                    //                           result.firstName);
                                                    //                       setStringPref(
                                                    //                           StringPrefsEnum.hashName,
                                                    //                           result.hashName);
                                                    //                       setStringPref(
                                                    //                           StringPrefsEnum.lastName,
                                                    //                           result.lastName);
                                                    //                     }
                                                    //                   });

                                                    //                   // if (result[
                                                    //                   //         'result'] !=
                                                    //                   //     'failed') {
                                                    //                   //   userName = getStringPref(
                                                    //                   //       StringPrefsEnum
                                                    //                   //           .displayName);
                                                    //                   //   userQrCode =
                                                    //                   //       getStringPref(
                                                    //                   //           StringPrefsEnum
                                                    //                   //               .qrSecretCode);

                                                    //                   //   Utilities.showAlert(
                                                    //                   //       context,
                                                    //                   //       'App Reset Successful',
                                                    //                   //       'Your app has been successfully reset. Please close and restart the app to ensure all data is properly reloaded.',
                                                    //                   //       'OK');
                                                    //                   // }
                                                    //                 });
                                                    //               });
                                                    //             }
                                                    //           },
                                                    //           child: const Text(
                                                    //             'Update User Profile',
                                                    //             style: TextStyle(
                                                    //                 color: Colors
                                                    //                     .white),
                                                    //           ),
                                                    //         ),
                                                    //       ]),
                                                    // ),
                                                
                                                
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
    );
  }

  Future<bool> _displayInstructions(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('About your QR Secret Code'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Text(
                  'Harrier Central does not use either usernames or passwords. Instead we identify you using a \'secret QR code\'. This QR code can be used to allow Harrier Central running on another device to access your account. If you want to install Harrier Central on another device, when you first install the app, select \'existing user\' and use the scanner to scan this code. The app on the new device will then be configured to access your account',
                  textAlign: TextAlign.justify,
                  style: TextStyle(
                      fontFamily: 'AvenirNextRegular',
                      fontStyle: FontStyle.normal,
                      fontSize: 16.0,
                      height: 1.0),
                )
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: const Text('OK, Got it!'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }
}
