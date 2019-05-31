import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:sqflite/sqflite.dart';

import 'package:harrier_central/database/database.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/styles.dart';
import 'package:harrier_central/widgets/offline_mode_ribbon.dart';
import 'package:harrier_central/util/utilities.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/widgets/profile_photo.dart';
import 'package:harrier_central/widgets/fancy_divider.dart';
import 'package:harrier_central/pages/init/choose_profile_image.dart';
import 'package:harrier_central/data/hc3_services/hashers_service.dart';
import 'package:harrier_central/data/hc3_services/sync_user_data_service.dart';

// import 'package:harrier_central/widgets/user_details_ui.dart';
// import 'package:harrier_central/widgets/fancy_divider.dart';

enum EnumMyProfilePageType { myProfile, anyHasherProfile, newHasherProfile }

class MyProfilePage extends StatefulWidget {
  //final FutureRunScopedModel futureRunsModel;

  const MyProfilePage({Key key, @required this.pageType, this.hasherId = GUID_EMPTY, this.eventId = GUID_EMPTY}) : super(key: key);

  final EnumMyProfilePageType pageType;
  final String hasherId;
  final String eventId;

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

  final String deviceUserId = getStringPref(StringPrefsEnum.userId);

  // String _firstName = getStringPref(StringPrefsEnum.firstName);
  // String _lastName = getStringPref(StringPrefsEnum.lastName);
  // String _email = getStringPref(StringPrefsEnum.email);
  // String _hashName = getStringPref(StringPrefsEnum.displayName);
  // String _photo = getStringPref(StringPrefsEnum.profilePhotoUrl);

  bool _isLoading = true;
  bool _isDirty = false;
  String photoPrefix = '';
  String newPhoto = '';
  HashersModel hasher;

  Future<void> refreshUserDataFromTable(bool forceRefresh) async {
    final Database db = await DBProvider.db.database;
    if (forceRefresh) {
      // always sync user data before editing
      final SyncUserDataService cSrv = SyncUserDataService();
      final bool res = await cSrv.updateFromBackend(db, SyncUserDataService.flagHashersTable, false);
      final String resultStr = res ? 'successfully' : 'unsuccessfully';
      print('Master data synchronized $resultStr');
    }

    final String query = ''' 
        SELECT 
          h.*
          FROM hashers h
          WHERE h.hasherId = "${widget.hasherId}"
          
          ''';

    try {
      setState(() {
        _isLoading = true;
      });
      final List<Map<String, dynamic>> results = await db.rawQuery(query);
      if ((results != null) && (results.isNotEmpty)) {
        hasher = HashersTableHelper.fromMap(results[0]);
        if (widget.pageType == EnumMyProfilePageType.myProfile) {
          hasher.email = getStringPref(StringPrefsEnum.email);
        }

        firstNameController.text = hasher.firstName;
        lastNameController.text = hasher.lastName;
        emailController.text = hasher.email;
        hashNameController.text = hasher.hashName;
        newPhoto = hasher.photo;
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print(e);
    }
  }

  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController hashNameController = TextEditingController();

  @override
  void initState() {
    if (widget.pageType != EnumMyProfilePageType.newHasherProfile) {
      refreshUserDataFromTable(true);
      photoPrefix = widget.hasherId;
    } else {
      hasher = HashersModel(hasherId:GUID_EMPTY);
      photoPrefix = 'newHcUser_' + DateTime.now().microsecondsSinceEpoch.toString();
      _isLoading = false;
    }

    firstNameController.addListener(() {
      checkDirty();
    });
    lastNameController.addListener(() {
      checkDirty();
    });
    emailController.addListener(() {
      checkDirty();
    });
    hashNameController.addListener(() {
      checkDirty();
    });
    super.initState();
  }

  void checkDirty() {
    if (_isLoading) {
      return;
    }
    bool isDirty = false;
    if (firstNameController.text != hasher?.firstName ?? '') {
      isDirty = true;
    }
    if (lastNameController.text != hasher?.lastName ?? '') {
      isDirty = true;
    }
    if ((emailController.text ?? '') != (hasher?.email ?? '')) {
      isDirty = true;
    }
    if (hashNameController.text != hasher?.hashName ?? '') {
      isDirty = true;
    }
    if (newPhoto != hasher?.photo ?? '') {
      isDirty = true;
    }

    if (isDirty != _isDirty) {
      setState(() {
        _isDirty = isDirty;
      });
    }
  }

  Widget _buildCircularProgressIndicator() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
        Text(
          'Loading / Updating User Profile',
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

        final HashersService srv = HashersService();

        final Future<dynamic> apiCall = srv.addEditUser(targetUserId: hasher.hasherId, firstName: firstNameController.text, lastName: lastNameController.text, email: emailController.text, hashName: hashNameController.text, photo: newPhoto, eventId: widget.eventId);

        apiCall.then((void dummy) async {
          refreshUserDataFromTable(false).then((void dummy) {
            setState(() {
              if (widget.pageType == EnumMyProfilePageType.myProfile) {
                setStringPref(StringPrefsEnum.profilePhotoUrl, hasher.photo);
                setStringPref(StringPrefsEnum.displayName, hasher.dispName);
                setStringPref(StringPrefsEnum.email, hasher.email);
                setStringPref(StringPrefsEnum.firstName, hasher.firstName);
                setStringPref(StringPrefsEnum.hashName, hasher.hashName);
                setStringPref(StringPrefsEnum.lastName, hasher.lastName);
              }
              _isLoading = false;
              checkDirty();
              if (widget.pageType != EnumMyProfilePageType.myProfile) {
                Navigator.of(context).pop(hasher);
              }
            });
          });
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
          controller: firstNameController,
          //initialValue: hasher.firstName,
          decoration: const InputDecoration(labelText: 'First Name'),
          keyboardType: TextInputType.text,
          validator: (String arg) {
            if (arg.length < 3)
              return 'Name must be more than 2 charaters';
            else
              return null;
          },
          onSaved: (String val) {
            hasher.firstName = val;
          },
        ),
        TextFormField(
          autocorrect: false,
          //initialValue: hasher.lastName,
          controller: lastNameController,
          decoration: const InputDecoration(labelText: 'Last Name'),
          keyboardType: TextInputType.text,
          validator: (String arg) {
            if (arg.length < 3)
              return 'Name must be more than 2 charaters';
            else
              return null;
          },
          onSaved: (String val) {
            hasher.lastName = val;
          },
        ),
        TextFormField(
          autocorrect: false,
          //initialValue: hasher.email,
          controller: emailController,
          decoration: const InputDecoration(labelText: 'Email'),
          keyboardType: TextInputType.emailAddress,
          validator: validateEmail,
          onSaved: (String val) {
            hasher.email = val;
          },
        ),
        TextFormField(
          autocorrect: false,
          //initialValue: hasher.hashName,
          controller: hashNameController,
          decoration: const InputDecoration(labelText: 'Hash Name (optional)'),
          onSaved: (String val) {
            hasher.hashName = val;
          },
          keyboardType: TextInputType.text,
        ),
        const SizedBox(
          height: 10.0,
        ),
      ],
    );
  }

  String validateEmail(String value) {
    if (value.isNotEmpty) {
      const Pattern pattern = r"[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?";
      final RegExp regex = RegExp(pattern, caseSensitive: false);
      if (!regex.hasMatch(value))
        return 'Enter Valid Email';
      else
        return null;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final AppBar appBar = AppBar(
      centerTitle: true,
      backgroundColor: themeAppBarBackground,
      title: Text(
        widget.pageType == EnumMyProfilePageType.myProfile ? 'My Profile' : 'Hasher Profile',
        style: const TextStyle(
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
                                            widget.pageType == EnumMyProfilePageType.myProfile ? 'My Profile Information' : 'Hasher Profile Information',
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
                                                        child: newPhoto.isEmpty
                                                            ? Image.asset(
                                                                'images/icons/create_profile_photo.png',
                                                              )
                                                            : ProfilePhoto(
                                                                profilePhotoUrl: newPhoto,
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
                                                                MaterialPageRoute<String>(
                                                                  builder: (BuildContext context) => ChooseProfileImage(
                                                                        isForThisDevice: widget.pageType == EnumMyProfilePageType.myProfile,
                                                                        fileNamePrefix: photoPrefix,
                                                                        currentProfileImage: hasher?.photo ?? '',
                                                                      ),
                                                                ),
                                                              ).then((String result) {
                                                                if ((result != null) && (result.toString().isNotEmpty)) {
                                                                  setState(() {
                                                                    newPhoto = result;
                                                                    checkDirty();
                                                                  });
                                                                }
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
        Positioned(
            bottom: 0,
            child: Container(
                padding: const EdgeInsets.fromLTRB(220, 10, 10, 10),
                child: Utilities.styleForConnected(
                  RaisedButton(
                    color: _isDirty ? Theme.of(context).accentColor : Colors.grey,
                    onPressed: () {
                      if (Utilities.checkForConnection(context)) {
                        _updateProfile();
                      }
                    },
                    child: Text(widget.pageType == EnumMyProfilePageType.newHasherProfile ? 'Add Hasher' : 'Save Changes', style: buttonTextStyle),
                  ),
                ),
                height: 60,
                width: MediaQuery.of(context).size.width,
                color: Colors.yellow[100])),
        const OfflineModeRibbon(),
      ],
    );
  }
}
