// @dart=2.11
import 'package:harrier_central/imports.dart';

enum EnumMyProfilePageType { myProfile, anyHasherProfile, newHasherProfile }

class HasherProfilePage extends StatefulWidget {
  //final FutureRunScopedModel futureRunsModel;

  const HasherProfilePage({
    Key key,
    @required this.dataContext,
    @required this.pageType,
    this.hasherId = GUID_EMPTY,
    this.eventId = GUID_EMPTY,
    this.kennelId = GUID_EMPTY,
    this.uiElementsToDisplay = 0,
    this.kennelShortName,
    this.hashNameFromSearch = '',
  }) : super(key: key);

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
  static const int flagUiElement_distancePref = 0x00000004;
  static const int flagUiElement_autoDisplayRunsDistance = 0x00000008;
  static const int flagUiElement_logOutAndRefreshButton = 0x00000010;
  static const int flagUiElement_refresh3rdPartyLogin = 0x00000020;

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

  String _email = getStringPref(StringPrefsEnum.email);
  int _hasherPreferences = getIntPref(IntPrefsEnum.hasherPreferences);

  // String _firstName = getStringPref(StringPrefsEnum.firstName);
  // String _lastName = getStringPref(StringPrefsEnum.lastName);
  // String _email = getStringPref(StringPrefsEnum.email);
  // String _hashName = getStringPref(StringPrefsEnum.displayName);
  // String _photo = getStringPref(StringPrefsEnum.profilePhotoUrl);

  bool _isLoading = true;
  bool _isDirty = false;
  bool _addAsKennelFollower = false;
  String _photoPrefix = '';
  String _newPhoto = 'bundle://avatar-${Random.secure().nextInt(49) + 1}';
  HashersModel _hasher;
  HasherKennelMapModel _hkmData;

  bool isEmptyGuid(String guid) {
    if ((guid == null) || (guid.isEmpty) || (guid == GUID_EMPTY)) {
      return true;
    }
    return false;
  }

  Future<void> refreshUserDataFromTable(bool forceRefresh) async {
    String query = ''' 
        SELECT 
          h.*
          FROM hashers h
          WHERE h.hasherId = "${widget.hasherId}"

          ''';

    if (forceRefresh) {
      // always sync user data before editing

      // TODO(James): Make this AppDomainType correct
      switch (widget.dataContext) {
        case EnumDataContext.event:
          await G0<TableModel>().syncEventAdminService.updateFromBackend(
              SyncEventAdminService.flagHashersTable | SyncEventAdminService.flagHasherKennelMapTable | SyncEventAdminService.flagHasherEventMapTable, true, widget.eventId);
          //final String resultStr = res ? 'successfully' : 'unsuccessfully';
          //print('Event data synchronized in hasher profile page $resultStr @ ${DateTime.now().millisecondsSinceEpoch.toString()}');
          break;
        case EnumDataContext.user:
          await G0<TableModel>().syncUserDataService.updateFromBackend(SyncUserDataService.flagHashersTable, true);
          //final String resultStr = res ? 'successfully' : 'unsuccessfully';
          //print('User master Hashers data synchronized in hasher profile page $resultStr @ ${DateTime.now().millisecondsSinceEpoch.toString()}');
          break;
        case EnumDataContext.kennel:
          await G0<TableModel>()
              .syncKennelAdminService
              .updateFromBackend(SyncKennelAdminService.flagHashersTable | SyncKennelAdminService.flagHasherKennelMapTable, true, widget.kennelId);
          //final String resultStr = res ? 'successfully' : 'unsuccessfully';
          //print('Kennel data synchronized in hasher profile page $resultStr @ ${DateTime.now().millisecondsSinceEpoch.toString()}');

          query = ''' 

          SELECT 
            h.*,
            hkm.${G0<TableModel>().hasherKennelMapTableHelper.colHistoricalTotalRunCount},
            hkm.${G0<TableModel>().hasherKennelMapTableHelper.colHistoricalHaringCount},
            hkm.${G0<TableModel>().hasherKennelMapTableHelper.colHistoricalCountIsEstimate}
            FROM ${G0<TableModel>().hashersTableHelper.getTableName(AppDomainType.kennel)} h
            LEFT OUTER JOIN ${G0<TableModel>().hasherKennelMapTableHelper.getTableName(AppDomainType.kennel)} hkm ON hkm.${G0<TableModel>().hasherKennelMapTableHelper.colKennelId} = "${widget.kennelId}" AND hkm.${G0<TableModel>().hasherKennelMapTableHelper.colUserId} = "${widget.hasherId}"
            WHERE h.${G0<TableModel>().hashersTableHelper.colHasherId} = "${widget.hasherId}"
          ''';

          break;
      }
    }

    try {
      setState(() {
        _isLoading = true;
      });
      final List<Map<String, dynamic>> results = await G0<Database>().rawQuery(query);
      if ((results != null) && (results.isNotEmpty)) {
        _hasher = HashersModel.fromJson(results[0]);
        if (widget.dataContext == EnumDataContext.kennel) {
          _hkmData = G0<TableModel>().hasherKennelMapTableHelper.fromMap(results[0]);
        }

        _firstNameController.text = _hasher.firstName;
        _lastNameController.text = _hasher.lastName;
        _emailController.text = ''; // we don't reveal e-mail in the app for users other than the user of the app
        _hashNameController.text = _hasher.hashName;
        _newPhoto = _hasher.photo; // if we have returned from the photo chooser, don't overwrite
        _previousRunCountController.text = (_hkmData?.historicalTotalRunCount ?? 0).toString();
        _previousHaringCountController.text = (_hkmData?.historicalHaringCount ?? 0).toString();
        _historicalCountIsEstimate = (_hkmData?.historicalCountIsEstimate ?? 0) == 1;

        // fill in the e-mail for the user of the app.
        if (widget.pageType == EnumMyProfilePageType.myProfile) {
          _emailController.text = _email;
          _distancePreference = _hasherPreferences & hasherPref_distanceMeasuredIn;
          _autoRunPreference = _hasherPreferences & hasherPref_distanceForAutoDisplay;
        }
      }

      _isLoading = false;
      checkDirty();
      setState(() {});
    } catch (e) {
      //print(e);
    }
  }

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _hashNameController = TextEditingController();
  final TextEditingController _previousRunCountController = TextEditingController();
  final TextEditingController _previousHaringCountController = TextEditingController();
  bool _historicalCountIsEstimate = false;

  @override
  void initState() {
    if (widget.hashNameFromSearch.isNotEmpty) {
      _hashNameController.text = widget.hashNameFromSearch;
    }
    // //print('initState called from hasher_profile_page @ ${DateTime.now().millisecondsSinceEpoch.toString()}');
    if (widget.pageType != EnumMyProfilePageType.newHasherProfile) {
      refreshUserDataFromTable(true);
      _photoPrefix = widget.hasherId;
    } else {
      if ((widget.kennelId != null) && (widget.kennelId.isNotEmpty) && (widget.kennelId != GUID_EMPTY)) {
        _addAsKennelFollower = true;
      }
      _hasher = HashersModel(hasherId: GUID_EMPTY);
      _photoPrefix = 'newHcUser_' + DateTime.now().microsecondsSinceEpoch.toString();

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

    _firstNameController.addListener(() {
      checkDirty();
    });
    _lastNameController.addListener(() {
      checkDirty();
    });
    _emailController.addListener(() {
      checkDirty();
    });
    _hashNameController.addListener(() {
      checkDirty();
    });
    _previousRunCountController.addListener(() {
      checkDirty();
    });
    _previousHaringCountController.addListener(() {
      checkDirty();
    });
    super.initState();

    _newPhoto = 'bundle://avatar-${Random.secure().nextInt(49) + 1}';
  }

  String getDistancePreferenceAsString(int distPref) {
    if (distPref == 2) {
      return 'kilometers';
    } else if (distPref == 3) {
      return 'miles';
    }
    return 'miles';
  }

  void checkDirty() {
    if (_isLoading) {
      return;
    }
    bool isDirty = false;
    if (_firstNameController.text != _hasher?.firstName ?? '') {
      isDirty = true;
    }
    if (_lastNameController.text != _hasher?.lastName ?? '') {
      isDirty = true;
    }
    if ((_email != null) && ((_emailController.text ?? '') != (_email ?? ''))) {
      isDirty = true;
    }
    if (_hashNameController.text != _hasher?.hashName ?? '') {
      isDirty = true;
    }
    if (_newPhoto != _hasher?.photo ?? '') {
      isDirty = true;
    }
    if (_previousRunCountController.text != (_hkmData?.historicalTotalRunCount ?? 0).toString()) {
      isDirty = true;
    }
    if (_previousHaringCountController.text != (_hkmData?.historicalHaringCount ?? 0).toString()) {
      isDirty = true;
    }
    if (_historicalCountIsEstimate != ((_hkmData?.historicalCountIsEstimate ?? 0) == 1)) {
      isDirty = true;
    }

    if (_hasher != null) {
      _hasherPreferences ??= 0;
      if (_hasherPreferences != (_distancePreference + _autoRunPreference)) {
        isDirty = true;
      }
    }

    if (_historicalCountIsEstimate != ((_hkmData?.historicalCountIsEstimate ?? 0) == 1)) {
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
                color: index.isEven ? Colors.grey[50] : Colors.red.shade900,
              ),
            );
          },
        ),
      ]),
    );
  }

  GlobalKey<ScaffoldState> scaffoldKey;

  Future<void> _updateProfile() async {
    if (_profileFormKey.currentState.validate()) {
//    If all data are correct then save data to out variables
      _profileFormKey.currentState.save();

      // write the value of the email address to local preferences

      setState(() {
        _isLoading = true;
      });

      final HashersService srv = HashersService();

      final String responseBody = await srv.addEditUser(
          targetUserId: _hasher.hasherId,
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          email: _emailController.text,
          hashName: _hashNameController.text,
          photo: _newPhoto,
          eventId: widget.eventId,
          kennelId: ((widget.kennelId == null) || (widget.kennelId == '')) ? GUID_EMPTY : widget.kennelId,
          historicalTotalRunCount: _previousRunCountController.text,
          historicalHaringCount: _previousHaringCountController.text,
          historicalCountIsEstimate: _historicalCountIsEstimate,
          preferences: _distancePreference + _autoRunPreference,
          followKennelOnAddNewUser: _addAsKennelFollower ? 1 : 0);

      if (!responseBody.startsWith(ERROR_PREFIX)) {
        if (widget.pageType == EnumMyProfilePageType.myProfile) {
          await setStringPref(StringPrefsEnum.email, _emailController.text);
          await setIntPref(IntPrefsEnum.hasherPreferences, _distancePreference + _autoRunPreference);
        }

        HashersModel h;
        final List<dynamic> jsonResult = json.decode(responseBody);

        // look through the returned results and find the
        // hasher we just edited. Usually only one
        // hasher will be returned, but there could be
        // edge cases where more than one Hasher record
        // is returned.
        for (int i = 0; i < jsonResult.length; i++) {
          if (jsonResult[i][0].containsKey('hasherId')) {
            for (int j = 0; j < jsonResult[i].length; j++) {
              if (jsonResult[i][j]['hasherId'].toString().toLowerCase() == _hasher.hasherId.toLowerCase()) {
                h = HashersModel.fromJson(jsonResult[i][0]);
              }
            }
          }
        }

        if (widget.pageType == EnumMyProfilePageType.myProfile) {
          await setStringPref(StringPrefsEnum.profilePhotoUrl, h.photo);
          await setStringPref(StringPrefsEnum.displayName, h.dispName);
          // don't set the e-mail with the result from the
          // api call. Use the local value in hasher.email instead
          //setStringPref(StringPrefsEnum.email, hasher.email);
          await setStringPref(StringPrefsEnum.firstName, h.firstName);
          await setStringPref(StringPrefsEnum.hashName, h.hashName);
          await setStringPref(StringPrefsEnum.lastName, h.lastName);
        }

        await refreshUserDataFromTable(true);
        setState(() {
          _isLoading = false;
          checkDirty();
        });

        if (widget.pageType != EnumMyProfilePageType.myProfile) {
          Navigator.of(context).pop(h);
        } else {
          await IveCoreUtilities.showAlert(context, 'Profile Updated', 'Your profile was updated successfully.', 'OK');
        }
      } else {
        await IveCoreUtilities.showAlert(
            context, 'Profile Not Updated', 'There was a problem updating your profile. Please ensure you are connected to the Internet and try again later.', 'OK');
      }
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
          controller: _firstNameController,
          //initialValue: hasher.firstName,
          decoration: const InputDecoration(labelText: 'First name (or initial)'),
          keyboardType: TextInputType.text,
          validator: (String arg) {
            if (arg.isEmpty) {
              return 'First name must have a least one letter';
            } else {
              return null;
            }
          },
          onSaved: (String val) {
            _hasher.firstName = val;
          },
        ),
        TextFormField(
          autocorrect: false,
          //initialValue: hasher.lastName,
          controller: _lastNameController,
          decoration: const InputDecoration(labelText: 'Last Name (or initial)'),
          keyboardType: TextInputType.text,
          validator: (String arg) {
            if (arg.isEmpty) {
              return 'Last name must have a least one letter';
            } else {
              return null;
            }
          },
          onSaved: (String val) {
            _hasher.lastName = val;
          },
        ),
        if (widget.pageType == EnumMyProfilePageType.myProfile) ...<Widget>[
          TextFormField(
            autocorrect: false,
            //initialValue: hasher.email,
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
            validator: Utilities.validateEmail,
            onSaved: (String val) {
              _email = val;
            },
          ),
        ],
        TextFormField(
          autocorrect: false,
          //initialValue: hasher.hashName,
          controller: _hashNameController,
          decoration: const InputDecoration(labelText: 'Hash Name (optional)'),
          onSaved: (String val) {
            _hasher.hashName = val;
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
          controller: _previousRunCountController,
          decoration: const InputDecoration(labelText: 'Historical run count'),
          keyboardType: TextInputType.number,
          onSaved: (String val) {
            _hasher.firstName = val;
          },
        ),
        TextFormField(
          autocorrect: false,
          controller: _previousHaringCountController,
          decoration: const InputDecoration(labelText: 'Historical haring count'),
          keyboardType: TextInputType.number,
          onSaved: (String val) {
            _hasher.firstName = val;
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
                value: _historicalCountIsEstimate,
                onChanged: (bool value) {
                  setState(() {
                    _historicalCountIsEstimate = value;
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

  AppBar appBar;

  int _distancePreference = 0;
  int _autoRunPreference = 2;

  void _handleRadioValueChange1(int value) {
    setState(() {
      _distancePreference = value;
      checkDirty();
    });
  }

  void _handleRadioValueChange2(int value) {
    setState(() {
      _autoRunPreference = value;
      checkDirty();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        SizedBox(height: MediaQuery.of(context).size.height, width: MediaQuery.of(context).size.width),
        Positioned(
          top: 0,
          left: 0,
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Scaffold(
            key: scaffoldKey,
            appBar: appBar,
            body: _isLoading
                ? Container(
                    height: MediaQuery.of(context).size.height - appBar.preferredSize.height,
                    decoration: Backgrounds.defaultHcBackground(),
                    child: _buildCircularProgressIndicator())
                : Container(
                    decoration: Backgrounds.defaultHcBackground(),
                    height: MediaQuery.of(context).size.height - appBar.preferredSize.height,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanDown: (_) {
                        FocusScope.of(context).requestFocus(FocusNode());
                      },
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 30, left: 20, right: 20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              SizedBox(
                                width: MediaQuery.of(context).size.width,
                                child: Column(
                                  children: <Widget>[
                                    Text(
                                      widget.pageType == EnumMyProfilePageType.myProfile ? 'My Profile Information' : 'Hasher Profile Information',
                                      style: headingStyle,
                                      textAlign: TextAlign.center,
                                    ),
                                    Container(
                                      padding: EdgeInsets.only(
                                          top: 30.0, left: (G0<DeviceInfo>().deviceWidthScaleFactor - 1) * 30, right: (G0<DeviceInfo>().deviceWidthScaleFactor - 1) * 30),
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
                                                autovalidateMode: _autoValidate ? AutovalidateMode.always : AutovalidateMode.disabled,
                                                child: profileFormUi(),
                                              ),
                                            ),
                                            const FancyDivider(key: Key('11203961'), innerColor: Colors.white),
                                            Container(
                                              height: 220,
                                              color: Colors.white,
                                              padding: const EdgeInsets.all(10.0),
                                              margin: const EdgeInsets.only(top: 20, bottom: 30),
                                              child: _newPhoto.isEmpty
                                                  ? Image.asset(
                                                      'images/icons/create_profile_photo.png',
                                                    )
                                                  : Padding(
                                                      padding: const EdgeInsets.only(left: 0, right: 0),
                                                      child: AspectRatio(
                                                        aspectRatio: 1.0,
                                                        child: ProfilePhoto(
                                                          profilePhotoUrl: _newPhoto,
                                                          //photoHeight: 200.0,
                                                          //leftPadding: 0.0,
                                                        ),

                                                        // Container(
                                                        //   decoration: BoxDecoration(
                                                        //     shape: BoxShape.rectangle,
                                                        //     borderRadius: const BorderRadius.all(Radius.circular(10.0)),
                                                        //     image: DecorationImage(
                                                        //       fit: BoxFit.fill,
                                                        //       image: NetworkImage(
                                                        //         newPhoto,
                                                        //       ),
                                                        //     ),
                                                        //   ),
                                                        // ),
                                                      ),
                                                    ),
                                            ),
                                            Connection.styleForConnected(
                                              G0<AppModel>().connectionStatus,
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  padding: const EdgeInsets.only(top: 8, bottom: 8, left: 20, right: 20),
                                                ),
                                                onPressed: () {
                                                  if (Connection.checkForConnection(context, G0<AppModel>().connectionStatus)) {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute<String>(
                                                        builder: (BuildContext context) => ChooseProfileImage(
                                                          isForThisDevice: widget.pageType == EnumMyProfilePageType.myProfile,
                                                          fileNamePrefix: _photoPrefix,
                                                          currentProfileImage: _hasher?.photo ?? _newPhoto,
                                                        ),
                                                      ),
                                                    ).then((String result) {
                                                      if ((result != null) && (result.isNotEmpty)) {
                                                        _newPhoto = result;
                                                        checkDirty();
                                                        //setState(() {});
                                                      }
                                                    });
                                                  }
                                                },
                                                child: Text('Update Profile Image', style: textStyleButton),
                                              ),
                                            ),
                                            const SizedBox(height: 15),
                                            (widget.uiElementsToDisplay & HasherProfilePage.flagUiElement_distancePref == 0)
                                                ? Container()
                                                : Column(
                                                    children: <Widget>[
                                                      const FancyDivider(
                                                        key: Key('422030201'),
                                                        innerColor: Colors.white,
                                                        topMargin: 30.0,
                                                        bottomMargin: 20.0,
                                                      ),
                                                      Container(
                                                        decoration: BoxDecoration(
                                                          color: Colors.yellow[100],
                                                          borderRadius: BorderRadius.circular(5.0),
                                                        ),
                                                        child: Column(
                                                          children: <Widget>[
                                                            const SizedBox(
                                                              height: 10,
                                                              width: 10,
                                                            ),
                                                            Text(
                                                              'Distance Preference',
                                                              style: headingStyle20Black,
                                                            ),
                                                            const SizedBox(
                                                              height: 10,
                                                              width: 10,
                                                            ),
                                                            Row(
                                                              children: <Widget>[
                                                                Radio<int>(
                                                                  value: 0,
                                                                  groupValue: _distancePreference,
                                                                  onChanged: _handleRadioValueChange1,
                                                                ),
                                                                const Text(
                                                                  'Auto',
                                                                  style: TextStyle(fontSize: 16.0),
                                                                ),
                                                              ],
                                                            ),
                                                            Row(
                                                              children: <Widget>[
                                                                Radio<int>(
                                                                  value: 2,
                                                                  groupValue: _distancePreference,
                                                                  onChanged: _handleRadioValueChange1,
                                                                ),
                                                                const Text(
                                                                  'Kilometers',
                                                                  style: TextStyle(fontSize: 16.0),
                                                                ),
                                                              ],
                                                            ),
                                                            Row(
                                                              children: <Widget>[
                                                                Radio<int>(
                                                                  value: 3,
                                                                  groupValue: _distancePreference,
                                                                  onChanged: _handleRadioValueChange1,
                                                                ),
                                                                const Text(
                                                                  'Miles',
                                                                  style: TextStyle(fontSize: 16.0),
                                                                ),
                                                              ],
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      G0<AppModel>().hasLocationPermissions
                                                          ? Container()
                                                          : Padding(
                                                              padding: const EdgeInsets.only(top: 22.0, bottom: 10.0),
                                                              child: ElevatedButton(
                                                                onPressed: () async {
                                                                  if (Platform.isIOS) {
                                                                    if (await Permission.locationWhenInUse.isGranted) {
                                                                      await setIntPref(IntPrefsEnum.hasLocationPermissions, 1);
                                                                      G0<AppModel>().hasLocationPermissions = true;
                                                                      await Utilities.subscribeToGeoLocationStream();
                                                                    }
                                                                  } else {
                                                                    if (await Permission.location.isGranted) {
                                                                      await setIntPref(IntPrefsEnum.hasLocationPermissions, 1);
                                                                      G0<AppModel>().hasLocationPermissions = true;
                                                                      await Utilities.subscribeToGeoLocationStream();
                                                                    }
                                                                  }

                                                                  await IveCoreUtilities.showAlert(
                                                                      context,
                                                                      'Location preferences updated',
                                                                      'Your location preferences have been updated.\r\n\r\nYou may have to wait a few minutes or open and close the app before your current location is used by the app.',
                                                                      'OK');
                                                                },
                                                                child: Text('Enable Location Svcs', style: buttonTextStyle),
                                                              ),
                                                            ),
                                                    ],
                                                  ),
                                            (widget.uiElementsToDisplay & HasherProfilePage.flagUiElement_autoDisplayRunsDistance == 0)
                                                ? Container()
                                                : Column(
                                                    children: <Widget>[
                                                      const FancyDivider(
                                                        key: Key('51344451'),
                                                        innerColor: Colors.white,
                                                        topMargin: 45.0,
                                                        bottomMargin: 20.0,
                                                      ),
                                                      Container(
                                                        decoration: BoxDecoration(
                                                          color: Colors.yellow[100],
                                                          borderRadius: BorderRadius.circular(5.0),
                                                        ),
                                                        child: Column(
                                                          children: <Widget>[
                                                            const SizedBox(
                                                              height: 20,
                                                              width: 10,
                                                            ),
                                                            Row(
                                                              children: <Widget>[
                                                                Radio<int>(
                                                                  value: 0,
                                                                  groupValue: _autoRunPreference,
                                                                  onChanged: _handleRadioValueChange2,
                                                                ),
                                                                const Text(
                                                                  'Do not auto show runs',
                                                                  style: TextStyle(fontSize: 16.0),
                                                                ),
                                                              ],
                                                            ),
                                                            Text(
                                                              'Or...\r\n...Automatically Show\r\nAll Runs Within...',
                                                              textAlign: TextAlign.center,
                                                              style: headingStyle20Black,
                                                            ),
                                                            const SizedBox(
                                                              height: 10,
                                                              width: 10,
                                                            ),
                                                            Row(
                                                              children: <Widget>[
                                                                Radio<int>(
                                                                  value: 4,
                                                                  groupValue: _autoRunPreference,
                                                                  onChanged: _handleRadioValueChange2,
                                                                ),
                                                                Text(
                                                                  '10 ' + getDistancePreferenceAsString(_distancePreference),
                                                                  style: const TextStyle(fontSize: 16.0),
                                                                ),
                                                              ],
                                                            ),
                                                            Row(
                                                              children: <Widget>[
                                                                Radio<int>(
                                                                  value: 8,
                                                                  groupValue: _autoRunPreference,
                                                                  onChanged: _handleRadioValueChange2,
                                                                ),
                                                                Text(
                                                                  '25 ' + getDistancePreferenceAsString(_distancePreference),
                                                                  style: const TextStyle(fontSize: 16.0),
                                                                ),
                                                              ],
                                                            ),
                                                            Row(
                                                              children: <Widget>[
                                                                Radio<int>(
                                                                  value: 12,
                                                                  groupValue: _autoRunPreference,
                                                                  onChanged: _handleRadioValueChange2,
                                                                ),
                                                                Text(
                                                                  '50 ' + getDistancePreferenceAsString(_distancePreference),
                                                                  style: const TextStyle(fontSize: 16.0),
                                                                ),
                                                              ],
                                                            ),
                                                            Row(
                                                              children: <Widget>[
                                                                Radio<int>(
                                                                  value: 16,
                                                                  groupValue: _autoRunPreference,
                                                                  onChanged: _handleRadioValueChange2,
                                                                ),
                                                                Text(
                                                                  '75 ' + getDistancePreferenceAsString(_distancePreference),
                                                                  style: const TextStyle(fontSize: 16.0),
                                                                ),
                                                              ],
                                                            ),
                                                            Row(
                                                              children: <Widget>[
                                                                Radio<int>(
                                                                  value: 20,
                                                                  groupValue: _autoRunPreference,
                                                                  onChanged: _handleRadioValueChange2,
                                                                ),
                                                                Text(
                                                                  '100 ' + getDistancePreferenceAsString(_distancePreference),
                                                                  style: const TextStyle(fontSize: 16.0),
                                                                ),
                                                              ],
                                                            ),
                                                            Row(
                                                              children: <Widget>[
                                                                Radio<int>(
                                                                  value: 24,
                                                                  groupValue: _autoRunPreference,
                                                                  onChanged: _handleRadioValueChange2,
                                                                ),
                                                                Text(
                                                                  '150 ' + getDistancePreferenceAsString(_distancePreference),
                                                                  style: const TextStyle(fontSize: 16.0),
                                                                ),
                                                              ],
                                                            ),
                                                            Row(
                                                              children: <Widget>[
                                                                Radio<int>(
                                                                  value: 28,
                                                                  groupValue: _autoRunPreference,
                                                                  onChanged: _handleRadioValueChange2,
                                                                ),
                                                                Text(
                                                                  '200 ' + getDistancePreferenceAsString(_distancePreference),
                                                                  style: const TextStyle(fontSize: 16.0),
                                                                ),
                                                              ],
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      G0<AppModel>().hasLocationPermissions
                                                          ? Container()
                                                          : Padding(
                                                              padding: const EdgeInsets.only(top: 22.0, bottom: 10.0),
                                                              child: ElevatedButton(
                                                                onPressed: () async {
                                                                  if (Platform.isIOS) {
                                                                    if (await Permission.locationWhenInUse.isGranted) {
                                                                      await setIntPref(IntPrefsEnum.hasLocationPermissions, 1);
                                                                      G0<AppModel>().hasLocationPermissions = true;
                                                                      await Utilities.subscribeToGeoLocationStream();
                                                                    }
                                                                  } else {
                                                                    if (await Permission.location.isGranted) {
                                                                      await setIntPref(IntPrefsEnum.hasLocationPermissions, 1);
                                                                      G0<AppModel>().hasLocationPermissions = true;
                                                                      await Utilities.subscribeToGeoLocationStream();
                                                                    }
                                                                  }

                                                                  await IveCoreUtilities.showAlert(
                                                                      context,
                                                                      'Location preferences updated',
                                                                      'Your location preferences have been updated.\r\n\r\nYou may have to wait a few minutes or open and close the app before your current location is used by the app.',
                                                                      'OK');
                                                                },
                                                                child: Text('Enable Location Svcs', style: buttonTextStyle),
                                                              ),
                                                            ),
                                                    ],
                                                  ),
                                            const SizedBox(
                                              height: 40,
                                              width: 40,
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                                    (widget.uiElementsToDisplay & HasherProfilePage.flagUiElement_followKennel == 0)
                                        ? Container()
                                        : Column(
                                            children: <Widget>[
                                              const FancyDivider(
                                                key: Key('882552302'),
                                                innerColor: Colors.white,
                                                bottomMargin: 20.0,
                                              ),
                                              Container(
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
                                            ],
                                          ),
                                    (widget.uiElementsToDisplay & HasherProfilePage.flagUiElement_inviteCode == 0)
                                        ? Container()
                                        : Column(
                                            crossAxisAlignment: CrossAxisAlignment.stretch,
                                            children: <Widget>[
                                              const FancyDivider(
                                                key: Key('612233999'),
                                                innerColor: Colors.white,
                                                bottomMargin: 20.0,
                                              ),
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
                                                child: Form(
                                                  key: _runCountFormKey,
                                                  autovalidateMode: _autoValidate ? AutovalidateMode.always : AutovalidateMode.disabled,
                                                  child: runCountUi(),
                                                ),
                                              ),
                                              // FancyDivider(
                                              //   key: Key('xxxxxxx'),
                                              //   innerColor: Colors.white,
                                              //   bottomMargin: 20.0,
                                              // ),
                                              // Text(
                                              //   'Invite code:',
                                              //   style: headingStyle,
                                              //   textAlign: TextAlign.center,
                                              // ),
                                              // const SizedBox(
                                              //   height: 10,
                                              //   width: 10,
                                              // ),
                                              // Text(
                                              //   (hasher?.resetCode ?? '').replaceAll(QR_PREFIX_USER_RESET_CODE, ''),
                                              //   style: largeText,
                                              //   textAlign: TextAlign.center,
                                              // ),
                                              // Container(
                                              //   margin: const EdgeInsets.only(top: 20),
                                              //   // height: (MediaQuery.of(context).size.width * 0.8 < MediaQuery.of(context).size.height * 0.4) ? MediaQuery.of(context).size.width * 0.8 : MediaQuery.of(context).size.height * 0.4,
                                              //   // width: (MediaQuery.of(context).size.width * 0.8 < MediaQuery.of(context).size.height * 0.4) ? MediaQuery.of(context).size.width * 0.8 : MediaQuery.of(context).size.height * 0.4,
                                              //   child: QrImage(
                                              //       backgroundColor: Colors.white,
                                              //       padding: const EdgeInsets.all(20.0),
                                              //       data: hasher?.resetCode ?? '',
                                              //       //data: 'testing123',
                                              //       version: 4,
                                              //       //size: 200.0,
                                              //       errorCorrectionLevel: 3),
                                              // ),
                                            ],
                                          ),
                                    if (widget.uiElementsToDisplay & HasherProfilePage.flagUiElement_logOutAndRefreshButton != 0) ...<Widget>[
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: <Widget>[
                                          const FancyDivider(
                                            key: Key('8552133039'),
                                            innerColor: Colors.white,
                                            topMargin: 30.0,
                                            bottomMargin: 20.0,
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(top: 15, bottom: 15),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                                              children: <Widget>[
                                                Connection.styleForConnected(
                                                  G0<AppModel>().connectionStatus,
                                                  ElevatedButton(
                                                    style: ElevatedButton.styleFrom(
                                                      padding: const EdgeInsets.only(top: 8, bottom: 8, left: 20, right: 20),
                                                    ),
                                                    onPressed: () async {
                                                      await IveCoreUtilities.showAlert(
                                                              context,
                                                              'Refresh cache',
                                                              'Refreshing the cache removes all of the data stored on your phone by the Harrier Central app and reloads your profile from our backend servers.\r\n\r\nNormally you will only need to do this when asked to do so by our support team.',
                                                              'Refresh cache',
                                                              showCancelButton: true,
                                                              cancelButtonText: 'Cancel')
                                                          .then((bool result) async {
                                                        if (result) {
                                                          final String userId = getStringPref(StringPrefsEnum.userId);
                                                          final String resetCode = getStringPref(StringPrefsEnum.resetCode);
                                                          final String facebookAccessToken = getStringPref(StringPrefsEnum.facebookAccessToken);
                                                          final String facebookId = getStringPref(StringPrefsEnum.facebookId);

                                                          await clearPrefs();

                                                          await setStringPref(StringPrefsEnum.userId, userId);
                                                          await setStringPref(StringPrefsEnum.resetCode, resetCode);
                                                          await setStringPref(StringPrefsEnum.facebookAccessToken, facebookAccessToken);
                                                          await setStringPref(StringPrefsEnum.facebookId, facebookId);
                                                          await setIntPref(IntPrefsEnum.isResettingCache, 1);

                                                          await DBProvider.deleteDb(DB_NAME);

                                                          await G0.reset();
                                                          Phoenix.rebirth(context);
                                                        }
                                                      });
                                                    },
                                                    child: Text(
                                                      'Refresh cache',
                                                      style: textStyleButton,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (Utilities.isOpeeOrTuna()) ...<Widget>[
                                            Padding(
                                              padding: const EdgeInsets.only(top: 15, bottom: 40),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                                children: <Widget>[
                                                  Connection.styleForConnected(
                                                    G0<AppModel>().connectionStatus,
                                                    ElevatedButton(
                                                      style: ElevatedButton.styleFrom(
                                                        padding: const EdgeInsets.only(top: 8, bottom: 8, left: 20, right: 20),
                                                      ),
                                                      onPressed: () async {
                                                        await IveCoreUtilities.showAlert(
                                                                context,
                                                                'Log out?',
                                                                'You will be logged out of Harrier Central and all of your data will be erased from this device, although your preferences and run information are safely stored on our servers.\r\n\r\nWhen choosing to log out the app will restart itself automatically.',
                                                                'Log out',
                                                                showCancelButton: true,
                                                                cancelButtonText: 'Stay logged in')
                                                            .then((bool result) async {
                                                          if (result) {
                                                            await clearPrefs();
                                                            await DBProvider.deleteDb(DB_NAME);
                                                            await G0.reset();
                                                            Phoenix.rebirth(context);
                                                          }
                                                        });
                                                      },
                                                      child: Text(
                                                        'Log out',
                                                        style: textStyleButton,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ]
                                        ],
                                      ),
                                    ],
                                    if (widget.uiElementsToDisplay & HasherProfilePage.flagUiElement_refresh3rdPartyLogin != 0) ...<Widget>[
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: <Widget>[
                                          const FancyDivider(
                                            key: Key('655522013'),
                                            innerColor: Colors.white,
                                            topMargin: 30.0,
                                            bottomMargin: 20.0,
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(top: 15, bottom: 15),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                                              children: <Widget>[
                                                Connection.styleForConnected(
                                                  G0<AppModel>().connectionStatus,
                                                  ElevatedButton(
                                                    style: ElevatedButton.styleFrom(
                                                      padding: const EdgeInsets.only(top: 8, bottom: 8, left: 20, right: 20),
                                                    ),
                                                    onPressed: () async {
                                                      await Navigator.push<dynamic>(
                                                        context,
                                                        MaterialPageRoute<dynamic>(builder: (BuildContext context) => const ThirdPartyLogin(false)),
                                                      );
                                                    },
                                                    child: Text(
                                                      'Login with 3rd Party',
                                                      style: textStyleButton,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 70, height: 70),
                            ],
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
                padding: const EdgeInsets.only(top: 10, right: 20, bottom: 10, left: 20),
                child: Connection.styleForConnected(
                  G0<AppModel>().connectionStatus,
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      primary: _isDirty ? Colors.red.shade900 : Colors.grey,
                    ),
                    onPressed: () {
                      if (Connection.checkForConnection(context, G0<AppModel>().connectionStatus) && _isDirty) {
                        _updateProfile();
                      }
                    },
                    child: Text(widget.pageType == EnumMyProfilePageType.newHasherProfile ? 'Add Hasher' : 'Save Changes', style: buttonTextStyle),
                  ),
                ),
                height: 60,
                width: MediaQuery.of(context).size.width,
                color: Colors.yellow[100])),
        OfflineModeRibbon(
          showRibbon: G0<AppModel>().connectionStatus == EnumConnectionStatus.not_connected,
          lastSync: getDatePref(DatePrefsEnum.lastSuccessfulUserDataSyncAsDate),
          ribbonImage: 'images/icons/offline_mode.png',
        ),
      ],
    );
  }
}
