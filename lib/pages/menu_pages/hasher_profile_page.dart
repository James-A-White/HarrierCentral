import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:sqflite/sqflite.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:harrier_central/database/database.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/styles.dart';
import 'package:harrier_central/widgets/offline_mode_ribbon.dart';
import 'package:harrier_central/util/utilities.dart';
import 'package:harrier_central/util/enums.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/widgets/profile_photo.dart';
import 'package:harrier_central/widgets/fancy_divider.dart';
import 'package:harrier_central/pages/init/choose_profile_image.dart';
import 'package:harrier_central/data/hc3_services/hashers_service.dart';
import 'package:harrier_central/data/hc3_services/hasher_kennel_map_service.dart';
import 'package:harrier_central/data/hc3_services/sync_user_data_service.dart';
import 'package:harrier_central/data/hc3_services/sync_event_admin_service.dart';
import 'package:harrier_central/data/hc3_services/sync_kennel_admin_service.dart';

// import 'package:harrier_central/widgets/user_details_ui.dart';
// import 'package:harrier_central/widgets/fancy_divider.dart';

enum EnumMyProfilePageType { myProfile, anyHasherProfile, newHasherProfile }

class HasherProfilePage extends StatefulWidget {
  //final FutureRunScopedModel futureRunsModel;

  const HasherProfilePage({Key key, @required this.dataContext, @required this.pageType, this.hasherId = GUID_EMPTY, this.eventId = GUID_EMPTY, this.kennelId = GUID_EMPTY, this.uiElementsToDisplay = 0, this.kennelShortName, this.hashNameFromSearch = ''}) : super(key: key);

  final EnumDataContext dataContext;
  final EnumMyProfilePageType pageType;
  final String hasherId;
  final String eventId;
  final String kennelId;
  final int uiElementsToDisplay;
  final String kennelShortName;
  final String hashNameFromSearch;

  static const int flagUiElement_followKennel = 0x00000001;
  static const int flagUiElement_inviteCode = 0x00000002;

  @override
  HasherProfilePageState createState() => HasherProfilePageState();
}

class HasherProfilePageState extends State<HasherProfilePage> {
  // String firstName = getStringPref(StringPrefsEnum.firstName);
  // String lastName = getStringPref(StringPrefsEnum.lastName);
  // String email = getStringPref(StringPrefsEnum.email);
  // String hashName = getStringPref(StringPrefsEnum.hashName);

  final GlobalKey<FormState> _profileFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _runCountFormKey = GlobalKey<FormState>();

  bool _autoValidate = false;

  final String deviceUserId = getStringPref(StringPrefsEnum.userId);

  // String _firstName = getStringPref(StringPrefsEnum.firstName);
  // String _lastName = getStringPref(StringPrefsEnum.lastName);
  // String _email = getStringPref(StringPrefsEnum.email);
  // String _hashName = getStringPref(StringPrefsEnum.displayName);
  // String _photo = getStringPref(StringPrefsEnum.profilePhotoUrl);

  bool _isLoading = true;
  bool _isDirty = false;
  bool _addAsKennelFollower = false;
  String photoPrefix = '';
  String newPhoto = '';
  HashersModel hasher;
  HasherKennelMapModel hkmData;
  String previousRunCount;

  bool isEmptyGuid(String guid) {
    if ((guid == null) || (guid.isEmpty) || (guid == GUID_EMPTY)) {
      return true;
    }
    return false;
  }

  Future<void> refreshUserDataFromTable(bool forceRefresh) async {
    final Database db = await DBProvider.db.database;

    String query = ''' 
        SELECT 
          h.*
          FROM hashers h
          WHERE h.hasherId = "${widget.hasherId}"

          ''';

    if (forceRefresh) {
      // always sync user data before editing

      switch (widget.dataContext) {
        case EnumDataContext.event:
          final SyncEventAdminService cSrv = SyncEventAdminService();
          final bool res = await cSrv.updateFromBackend(db, SyncEventAdminService.flagHashersTable | SyncEventAdminService.flagHasherKennelMapTable | SyncEventAdminService.flagHasherEventMapTable, true, widget.eventId);
          final String resultStr = res ? 'successfully' : 'unsuccessfully';
          print('Event data synchronized in hasher profile page $resultStr @ ${DateTime.now().millisecondsSinceEpoch.toString()}');
          break;
        case EnumDataContext.user:
          final SyncUserDataService cSrv = SyncUserDataService();
          final bool res = await cSrv.updateFromBackend(db, SyncUserDataService.flagHashersTable, true);
          final String resultStr = res ? 'successfully' : 'unsuccessfully';
          print('User master Hashers data synchronized in hasher profile page $resultStr @ ${DateTime.now().millisecondsSinceEpoch.toString()}');
          break;
        case EnumDataContext.kennel:
          final SyncKennelAdminService cSrv = SyncKennelAdminService();
          final bool res = await cSrv.updateFromBackend(db, SyncKennelAdminService.flagHashersTable | SyncKennelAdminService.flagHasherKennelMapTable, true, widget.kennelId);
          final String resultStr = res ? 'successfully' : 'unsuccessfully';
          print('Kennel data synchronized in hasher profile page $resultStr @ ${DateTime.now().millisecondsSinceEpoch.toString()}');

          query = ''' 

          SELECT 
            h.*,
            hkm.historicalPackRunCount,
            hkm.historicalHaringCount,
            hkm.historicalCountIsEstimate
            FROM hashers h
            LEFT OUTER JOIN ${HasherKennelMapTableHelper.getTableName(HasherKennelMapTableType.kennelAdmin)} hkm ON hkm.kennelId = "${widget.kennelId}" AND hkm.userId = "${widget.hasherId}"
            WHERE h.hasherId = "${widget.hasherId}"
          
          ''';

          break;
      }
    }

    try {
      setState(() {
        _isLoading = true;
      });
      final List<Map<String, dynamic>> results = await db.rawQuery(query);
      if ((results != null) && (results.isNotEmpty)) {
        hasher = HashersTableHelper.fromMap(results[0]);
        if (widget.dataContext == EnumDataContext.kennel) {
          hkmData = HasherKennelMapTableHelper.fromMap(results[0]);
        }
        if (widget.pageType == EnumMyProfilePageType.myProfile) {
          hasher.email = getStringPref(StringPrefsEnum.email);
        }

        firstNameController.text = hasher.firstName;
        lastNameController.text = hasher.lastName;
        emailController.text = hasher.email;
        hashNameController.text = hasher.hashName;
        newPhoto = hasher.photo;
        previousRunCountController.text = (hkmData?.historicalPackRunCount ?? 0).toString();
        previousHaringCountController.text = (hkmData?.historicalHaringCount ?? 0).toString();
        historicalCountIsEstimate = (hkmData?.historicalCountIsEstimate ?? 0) == 1;
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
  TextEditingController previousRunCountController = TextEditingController();
  TextEditingController previousHaringCountController = TextEditingController();
  bool historicalCountIsEstimate = false;

  @override
  void initState() {

    if (widget.hashNameFromSearch.isNotEmpty)
    {
      hashNameController.text = widget.hashNameFromSearch;
    }
    // print('initState called from hasher_profile_page @ ${DateTime.now().millisecondsSinceEpoch.toString()}');
    if (widget.pageType != EnumMyProfilePageType.newHasherProfile) {
      refreshUserDataFromTable(true);
      photoPrefix = widget.hasherId;
    } else {
      if ((widget.kennelId != null) && (widget.kennelId.isNotEmpty) && (widget.kennelId != GUID_EMPTY)) {
        _addAsKennelFollower = true;
      }
      hasher = HashersModel(hasherId: GUID_EMPTY);
      photoPrefix = 'newHcUser_' + DateTime.now().microsecondsSinceEpoch.toString();
      _isLoading = false;
    }

    appBar = AppBar(
      centerTitle: true,
      backgroundColor: themeAppBarBackground,
      title: Text(
        widget.pageType == EnumMyProfilePageType.myProfile ? 'My Profile' : 'Hasher Profile',
        style: const TextStyle(
          color: Colors.white,
        ),
      ),
    );

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
    previousRunCountController.addListener(() {
      checkDirty();
    });
    previousHaringCountController.addListener(() {
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
    if (previousRunCountController.text != (hkmData?.historicalPackRunCount ?? 0).toString()) {
      isDirty = true;
    }
    if (previousHaringCountController.text != (hkmData?.historicalHaringCount ?? 0).toString()) {
      isDirty = true;
    }

    if (historicalCountIsEstimate != ((hkmData?.historicalCountIsEstimate ?? 0) == 1))
    {
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

  GlobalKey<ScaffoldState> scaffoldKey;

  void _updateProfile() {
    if (_profileFormKey.currentState.validate()) {
//    If all data are correct then save data to out variables
      _profileFormKey.currentState.save();

      setState(() {
        _isLoading = true;

        final HashersService srv = HashersService();

        final Future<dynamic> apiCall = srv.addEditUser(
            targetUserId: hasher.hasherId,
            firstName: firstNameController.text,
            lastName: lastNameController.text,
            email: emailController.text,
            hashName: hashNameController.text,
            photo: newPhoto,
            eventId: widget.eventId,
            kennelId: ((widget.kennelId == null) || (widget.kennelId == '')) ? GUID_EMPTY : widget.kennelId,
            historicalPackRunCount: previousRunCountController.text,
            historicalHaringCount: previousHaringCountController.text,
            historicalCountIsEstimate: historicalCountIsEstimate,
            followKennelOnAddNewUser: _addAsKennelFollower ? 1 : 0);

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

  Widget profileFormUi() {
    return Column(
      children: <Widget>[
        TextFormField(
          autocorrect: false,
          controller: firstNameController,
          //initialValue: hasher.firstName,
          decoration: const InputDecoration(labelText: 'First name (or initial)'),
          keyboardType: TextInputType.text,
          validator: (String arg) {
            if (arg.isEmpty)
              return 'First name must have a least one letter';
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
          decoration: const InputDecoration(labelText: 'Last Name (or initial)'),
          keyboardType: TextInputType.text,
          validator: (String arg) {
            if (arg.isEmpty)
              return 'Last name must have a least one letter';
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

  Widget runCountUi() {
    return Column(
      children: <Widget>[
        TextFormField(
          autocorrect: false,
          controller: previousRunCountController,
          decoration: const InputDecoration(labelText: 'Historical run count'),
          keyboardType: TextInputType.number,
          onSaved: (String val) {
            hasher.firstName = val;
          },
        ),
        TextFormField(
          autocorrect: false,
          controller: previousHaringCountController,
          decoration: const InputDecoration(labelText: 'Historical haring count'),
          keyboardType: TextInputType.number,
          onSaved: (String val) {
            hasher.firstName = val;
          },
        ),
                const SizedBox(
          height: 15.0,
        ),
        Row(
          children: <Widget>[
            Container(
              margin: const EdgeInsets.only(right: 10),
              height: 25,
              width: 25,
              color: Colors.yellow[100],
              child: Checkbox(
                value: historicalCountIsEstimate,
                onChanged: (bool value) {
                  setState(() {
                    historicalCountIsEstimate = value;
                    checkDirty();
                  });
                },
              ),
            ),
            const Text(
              'Run counts are estimates',
              //style: headingStyle,
              textAlign: TextAlign.center,
            ),
          ],
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

  AppBar appBar;

  @override
  Widget build(BuildContext context) {
    num scrollHeight = 740.0;
    if ((widget.uiElementsToDisplay & HasherProfilePage.flagUiElement_inviteCode) != 0) {
      scrollHeight = 1510.0;
    } else if (widget.uiElementsToDisplay & HasherProfilePage.flagUiElement_followKennel != 0) {
      scrollHeight = 860.0;
    }

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
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanDown: (_) {
                        FocusScope.of(context).requestFocus(FocusNode());
                      },
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
                                          Container(height: scrollHeight),
                                          Positioned(
                                            top: 10,
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
                                                            key: _profileFormKey,
                                                            autovalidate: _autoValidate,
                                                            child: profileFormUi(),
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
                                                                          currentProfileImage: hasher?.photo ?? newPhoto,
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
                                          Positioned(top: 740, left: 30, right: 30, child: (widget.uiElementsToDisplay & (HasherProfilePage.flagUiElement_followKennel | HasherProfilePage.flagUiElement_inviteCode) == 0) ? Container() : const FancyDivider(innerColor: Colors.white)),
                                          Positioned(
                                            top: 760,
                                            child: (widget.uiElementsToDisplay & HasherProfilePage.flagUiElement_followKennel == 0)
                                                ? Container()
                                                : Container(
                                                    padding: const EdgeInsets.all(10.0),
                                                    margin: const EdgeInsets.only(bottom: 45),
                                                    decoration: BoxDecoration(
                                                      color: Colors.yellow[100],
                                                      borderRadius: BorderRadius.circular(5.0),
                                                    ),
                                                    child: Row(
                                                      children: <Widget>[
                                                        Container(
                                                          margin: const EdgeInsets.only(right: 10),
                                                          height: 25,
                                                          width: 25,
                                                          color: Colors.yellow[100],
                                                          child: Checkbox(
                                                            value: _addAsKennelFollower,
                                                            onChanged: (bool value) {
                                                              setState(() {
                                                                _addAsKennelFollower = value;
                                                              });
                                                            },
                                                          ),
                                                        ),
                                                        const Text(
                                                          'Follow this Kennel',
                                                          //style: headingStyle,
                                                          textAlign: TextAlign.center,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                          ),
                                          Positioned(
                                            top: 760,
                                            left: 30,
                                            right: 30,
                                            child: (widget.uiElementsToDisplay & HasherProfilePage.flagUiElement_inviteCode == 0)
                                                ? Container()
                                                : Column(
                                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                                    children: <Widget>[
                                                      Text(
                                                        'Previous run count:',
                                                        style: headingStyle,
                                                        textAlign: TextAlign.center,
                                                      ),
                                                      Text(
                                                        'Number of runs with ${widget.kennelShortName} that are not listed in Harrier Central',
                                                        style: headingStyle20italic,
                                                        textAlign: TextAlign.center,
                                                      ),
                                                      Container(
                                                        padding: const EdgeInsets.all(10.0),
                                                        margin: const EdgeInsets.only(top: 20, bottom: 40),
                                                        // width: 100,
                                                        // height: 50,
                                                        decoration: BoxDecoration(
                                                          color: Colors.yellow[100],
                                                          borderRadius: BorderRadius.circular(5.0),
                                                        ),
                                                        child: Form(key: _runCountFormKey, autovalidate: _autoValidate, child: runCountUi()),
                                                      ),
                                                      const FancyDivider(innerColor: Colors.white),
                                                      Text(
                                                        'Invite code:',
                                                        style: headingStyle,
                                                        textAlign: TextAlign.center,
                                                      ),
                                                      Text(
                                                        (hasher?.resetCode ?? '').replaceAll(QR_PREFIX_USER_RESET_CODE, ''),
                                                        style: largeText,
                                                        textAlign: TextAlign.center,
                                                      ),
                                                      Container(
                                                        margin: const EdgeInsets.only(top: 20),
                                                        // height: (MediaQuery.of(context).size.width * 0.8 < MediaQuery.of(context).size.height * 0.4) ? MediaQuery.of(context).size.width * 0.8 : MediaQuery.of(context).size.height * 0.4,
                                                        // width: (MediaQuery.of(context).size.width * 0.8 < MediaQuery.of(context).size.height * 0.4) ? MediaQuery.of(context).size.width * 0.8 : MediaQuery.of(context).size.height * 0.4,
                                                        child: QrImage(
                                                            backgroundColor: Colors.white,
                                                            padding: const EdgeInsets.all(20.0),
                                                            data: hasher?.resetCode ?? '',
                                                            //data: 'testing123',
                                                            version: 4,
                                                            //size: 200.0,
                                                            errorCorrectionLevel: 3),
                                                      ),
                                                    ],
                                                  ),
                                          ),
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
        ),
        Positioned(
            bottom: 0,
            child: Container(
                padding: const EdgeInsets.fromLTRB(220, 10, 10, 10),
                child: Utilities.styleForConnected(
                  RaisedButton(
                    color: _isDirty ? Theme.of(context).accentColor : Colors.grey,
                    onPressed: () {
                      if (Utilities.checkForConnection(context) && _isDirty) {
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
