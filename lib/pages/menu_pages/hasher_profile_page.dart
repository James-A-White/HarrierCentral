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
  static const int flagUiElement_logOutButton = 0x00000010;

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
  String email = getStringPref(StringPrefsEnum.email);
  int hasherPreferences = getIntPref(IntPrefsEnum.hasherPreferences);

  // String _firstName = getStringPref(StringPrefsEnum.firstName);
  // String _lastName = getStringPref(StringPrefsEnum.lastName);
  // String _email = getStringPref(StringPrefsEnum.email);
  // String _hashName = getStringPref(StringPrefsEnum.displayName);
  // String _photo = getStringPref(StringPrefsEnum.profilePhotoUrl);

  bool _isLoading = true;
  bool _isDirty = false;
  bool _addAsKennelFollower = false;
  String photoPrefix = '';
  String newPhoto = 'bundle://avatar-${Random.secure().nextInt(49) + 1}';
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
          final bool res = await G0<TableModel>().syncEventAdminService.updateFromBackend(
              SyncEventAdminService.flagHashersTable | SyncEventAdminService.flagHasherKennelMapTable | SyncEventAdminService.flagHasherEventMapTable, true, widget.eventId);
          final String resultStr = res ? 'successfully' : 'unsuccessfully';
          print('Event data synchronized in hasher profile page $resultStr @ ${DateTime.now().millisecondsSinceEpoch.toString()}');
          break;
        case EnumDataContext.user:
          final bool res = await G0<TableModel>().syncUserDataService.updateFromBackend(SyncUserDataService.flagHashersTable, true);
          final String resultStr = res ? 'successfully' : 'unsuccessfully';
          print('User master Hashers data synchronized in hasher profile page $resultStr @ ${DateTime.now().millisecondsSinceEpoch.toString()}');
          break;
        case EnumDataContext.kennel:
          final bool res = await G0<TableModel>()
              .syncKennelAdminService
              .updateFromBackend(SyncKennelAdminService.flagHashersTable | SyncKennelAdminService.flagHasherKennelMapTable, true, widget.kennelId);
          final String resultStr = res ? 'successfully' : 'unsuccessfully';
          print('Kennel data synchronized in hasher profile page $resultStr @ ${DateTime.now().millisecondsSinceEpoch.toString()}');

          query = ''' 

          SELECT 
            h.*,
            hkm.historicalPackRunCount,
            hkm.historicalHaringCount,
            hkm.historicalCountIsEstimate
            FROM hashers h
            LEFT OUTER JOIN ${G0<TableModel>().hasherKennelMapTableHelper.getTableName(AppDomainType.kennel)} hkm ON hkm.kennelId = "${widget.kennelId}" AND hkm.userId = "${widget.hasherId}"
            WHERE h.hasherId = "${widget.hasherId}"
          
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
        hasher = HashersModel.fromJson(results[0]);
        if (widget.dataContext == EnumDataContext.kennel) {
          hkmData = G0<TableModel>().hasherKennelMapTableHelper.fromMap(results[0]);
        }

        firstNameController.text = hasher.firstName;
        lastNameController.text = hasher.lastName;
        emailController.text = ''; // we don't reveal e-mail in the app for users other than the user of the app
        hashNameController.text = hasher.hashName;
        newPhoto = hasher.photo; // if we have returned from the photo chooser, don't overwrite
        previousRunCountController.text = (hkmData?.historicalPackRunCount ?? 0).toString();
        previousHaringCountController.text = (hkmData?.historicalHaringCount ?? 0).toString();
        historicalCountIsEstimate = (hkmData?.historicalCountIsEstimate ?? 0) == 1;

        // fill in the e-mail for the user of the app.
        if (widget.pageType == EnumMyProfilePageType.myProfile) {
          emailController.text = email;
          _distancePreference = hasherPreferences & hasherPref_distanceMeasuredIn;
          _autoRunPreference = hasherPreferences & hasherPref_distanceForAutoDisplay;
        }
      }

      _isLoading = false;
      checkDirty();
      setState(() {});
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
    if (widget.hashNameFromSearch.isNotEmpty) {
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

    newPhoto = 'bundle://avatar-${Random.secure().nextInt(49) + 1}';
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
    if (firstNameController.text != hasher?.firstName ?? '') {
      isDirty = true;
    }
    if (lastNameController.text != hasher?.lastName ?? '') {
      isDirty = true;
    }
    if ((email != null) && ((emailController.text ?? '') != (email ?? ''))) {
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
    if (historicalCountIsEstimate != ((hkmData?.historicalCountIsEstimate ?? 0) == 1)) {
      isDirty = true;
    }

    if (hasher != null) {
      hasherPreferences ??= 0;
      if (hasherPreferences != (_distancePreference + _autoRunPreference)) {
        isDirty = true;
      }
    }

    if (historicalCountIsEstimate != ((hkmData?.historicalCountIsEstimate ?? 0) == 1)) {
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
        // write the value of the email address to local preferences

        _isLoading = true;

        final HashersService srv = HashersService();

        final Future<String> apiCall = srv.addEditUser(
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
            preferences: _distancePreference + _autoRunPreference,
            followKennelOnAddNewUser: _addAsKennelFollower ? 1 : 0);

        apiCall.then((String responseBody) async {
          if (!responseBody.startsWith(ERROR_PREFIX)) {
            if (widget.pageType == EnumMyProfilePageType.myProfile) {
              setStringPref(StringPrefsEnum.email, emailController.text);
              setIntPref(IntPrefsEnum.hasherPreferences, _distancePreference + _autoRunPreference);
            }
            final dynamic jsonResult = json.decode(responseBody);
            final HashersModel h = HashersModel.fromJson(jsonResult[0][0]);
            setState(() {
              if (widget.pageType == EnumMyProfilePageType.myProfile) {
                setStringPref(StringPrefsEnum.profilePhotoUrl, h.photo);
                setStringPref(StringPrefsEnum.displayName, h.dispName);
                // don't set the e-mail with the result from the
                // api call. Use the local value in hasher.email instead
                //setStringPref(StringPrefsEnum.email, hasher.email);
                setStringPref(StringPrefsEnum.firstName, h.firstName);
                setStringPref(StringPrefsEnum.hashName, h.hashName);
                setStringPref(StringPrefsEnum.lastName, h.lastName);
              }

              refreshUserDataFromTable(true);
              _isLoading = false;
              checkDirty();

              if (widget.pageType != EnumMyProfilePageType.myProfile) {
                Navigator.of(context).pop(h);
              } else {
                IveCoreUtilities.showAlert(context, 'Profile Updated', 'Your profile was updated successfully.', 'OK');
              }
            });
          } else {
            IveCoreUtilities.showAlert(
                context, 'Profile Not Updated', 'There was a problem updating your profile. Please ensure you are connected to the Internet and try again later.', 'OK');
          }
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
            email = val;
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
        return 'Please enter a valid Email';
      else
        return null;
    }
    return 'Please enter a valid Email';
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
                              Container(
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
                                                  autovalidateMode: _autoValidate ? AutovalidateMode.always : AutovalidateMode.disabled,
                                                  child: profileFormUi(),
                                                ),
                                              ),
                                              FancyDivider(key: UniqueKey(), innerColor: Colors.white),
                                              Container(
                                                height: 220,
                                                color: Colors.white,
                                                padding: const EdgeInsets.all(10.0),
                                                margin: const EdgeInsets.only(top: 20, bottom: 30),
                                                child: newPhoto.isEmpty
                                                    ? Image.asset(
                                                        'images/icons/create_profile_photo.png',
                                                      )
                                                    : Padding(
                                                        padding: const EdgeInsets.only(left: 0, right: 0),
                                                        child: AspectRatio(
                                                          aspectRatio: 1.0,
                                                          child: ProfilePhoto(
                                                            profilePhotoUrl: newPhoto,
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
                                                  onPressed: () {
                                                    if (Connection.checkForConnection(context, G0<AppModel>().connectionStatus)) {
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
                                                        if ((result != null) && (result.isNotEmpty)) {
                                                          newPhoto = result;
                                                          checkDirty();
                                                          //setState(() {});
                                                        }
                                                      });
                                                    }
                                                  },
                                                  child: Text('Update Profile Image', style: buttonTextStyle),
                                                ),
                                              ),
                                              (widget.uiElementsToDisplay & HasherProfilePage.flagUiElement_distancePref == 0)
                                                  ? Container()
                                                  : Column(
                                                      children: <Widget>[
                                                        FancyDivider(
                                                          key: UniqueKey(),
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
                                                                        setIntPref(IntPrefsEnum.hasLocationPermissions, 1);
                                                                        G0<AppModel>().hasLocationPermissions = true;
                                                                        Utilities.subscribeToGeoLocationStream();
                                                                      }
                                                                    } else {
                                                                      if (await Permission.location.isGranted) {
                                                                        setIntPref(IntPrefsEnum.hasLocationPermissions, 1);
                                                                        G0<AppModel>().hasLocationPermissions = true;
                                                                        Utilities.subscribeToGeoLocationStream();
                                                                      }
                                                                    }

                                                                    IveCoreUtilities.showAlert(
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
                                                        FancyDivider(
                                                          key: UniqueKey(),
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
                                                                        setIntPref(IntPrefsEnum.hasLocationPermissions, 1);
                                                                        G0<AppModel>().hasLocationPermissions = true;
                                                                        Utilities.subscribeToGeoLocationStream();
                                                                      }
                                                                    } else {
                                                                      if (await Permission.location.isGranted) {
                                                                        setIntPref(IntPrefsEnum.hasLocationPermissions, 1);
                                                                        G0<AppModel>().hasLocationPermissions = true;
                                                                        Utilities.subscribeToGeoLocationStream();
                                                                      }
                                                                    }

                                                                    IveCoreUtilities.showAlert(
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
                                    ),
                                    (widget.uiElementsToDisplay & HasherProfilePage.flagUiElement_followKennel == 0)
                                        ? Container()
                                        : Column(
                                            children: <Widget>[
                                              FancyDivider(
                                                key: UniqueKey(),
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
                                              FancyDivider(
                                                key: UniqueKey(),
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
                                              //   key: UniqueKey(),
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
                                    (widget.uiElementsToDisplay & HasherProfilePage.flagUiElement_logOutButton == 0)
                                        ? Container()
                                        : Column(
                                            crossAxisAlignment: CrossAxisAlignment.stretch,
                                            children: <Widget>[
                                              FancyDivider(
                                                key: UniqueKey(),
                                                innerColor: Colors.white,
                                                topMargin: 45.0,
                                                bottomMargin: 20.0,
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.only(top: 25, bottom: 25),
                                                child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: <Widget>[
                                                  Connection.styleForConnected(
                                                    G0<AppModel>().connectionStatus,
                                                    ElevatedButton(
                                                      style: ElevatedButton.styleFrom(
                                                        padding: const EdgeInsets.only(top: 8, bottom: 8, left: 20, right: 20),
                                                      ),
                                                      onPressed: () async {
                                                        IveCoreUtilities.showAlert(
                                                                context,
                                                                'Log out?',
                                                                'You will be logged out of Harrier Central and all of your data will be erased from this device, although your preferences and run information are safely stored on our servers.\r\n\r\nYou may have to manually close and re-open the app to log back in again if you choose to log out.',
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
                                                ]),
                                              ),
                                            ],
                                          ),
                                  ],
                                ),
                              ),
                              Container(width: 70, height: 70),
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
                      primary: _isDirty ? Theme.of(context).accentColor : Colors.grey,
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
