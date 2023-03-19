// ignore_for_file: constant_identifier_names

import 'package:harrier_central/data/services/gdpr_delete_service.dart';
import 'package:harrier_central/data/services/get_invite_code_service.dart';
import 'package:harrier_central/imports_null_safe.dart';

enum EnumMyProfilePageType { myProfile, anyHasherProfile, newHasherProfile }

class HasherProfilePage extends StatefulWidget {
  //final FutureRunScopedModel futureRunsModel;

  const HasherProfilePage({
    Key? key,
    required this.dataContext,
    required this.pageType,
    this.hasherId = GUID_EMPTY,
    this.eventId = GUID_EMPTY,
    this.kennelId = GUID_EMPTY,
    this.uiElementsToDisplay = 0,
    this.kennelShortName = '',
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
  static const int flagUiElement_previousRunCount = 0x00000002;
  static const int flagUiElement_distancePref = 0x00000004;
  static const int flagUiElement_autoDisplayRunsDistance = 0x00000008;
  static const int flagUiElement_logOutAndRefreshButton = 0x00000010;
  static const int flagUiElement_refresh3rdPartyLogin = 0x00000020;
  static const int flagUiElement_gdprDeleteAccount = 0x00000040;
  static const int flagUiElement_getInviteCodeButton = 0x00000080;

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

  String? _email = getStringPref(StringPrefsEnum.email);
  int _hasherPreferences = getIntPref(IntPrefsEnum.hasherPreferences) ?? 0;

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
  late HashersModel _hasher;
  HasherKennelMapModel? _hkmData;

  bool isEmptyGuid(String? guid) {
    if ((guid == null) || (guid.isEmpty) || (guid == GUID_EMPTY)) {
      return true;
    }
    return false;
  }

  Future<void> _refreshUserDataFromTable(bool forceRefresh) async {
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
          await G0<TableModel>()
              .syncEventAdminService
              .updateFromBackend(SyncEventAdminService.flagHashersTable | SyncEventAdminService.flagHasherKennelMapTable | SyncEventAdminService.flagHasherEventMapTable, true, widget.eventId);
          //final String resultStr = res ? 'successfully' : 'unsuccessfully';
          //print('Event data synchronized in hasher profile page $resultStr @ ${DateTime.now().millisecondsSinceEpoch.toString()}');
          break;
        case EnumDataContext.user:
          await G0<TableModel>().syncUserDataService.updateFromBackend(
                SyncUserDataService.flagHashersTable,
                true,
                debugText: 'hasher_profile_page: Hashers',
              );
          //final String resultStr = res ? 'successfully' : 'unsuccessfully';
          //print('User master Hashers data synchronized in hasher profile page $resultStr @ ${DateTime.now().millisecondsSinceEpoch.toString()}');
          break;
        case EnumDataContext.kennel:
          await G0<TableModel>().syncKennelAdminService.updateFromBackend(SyncKennelAdminService.flagHashersTable | SyncKennelAdminService.flagHasherKennelMapTable, true, widget.kennelId);
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
      if (results.isNotEmpty) {
        _hasher = HashersModel.fromJson(results[0]);
        if (widget.dataContext == EnumDataContext.kennel) {
          _hkmData = G0<TableModel>().hasherKennelMapTableHelper.fromMap(results[0]);
        }

        _firstNameController.text = _hasher.firstName ?? '';
        _lastNameController.text = _hasher.lastName ?? '';
        _emailController.text = ''; // we don't reveal e-mail in the app for users other than the user of the app
        _hashNameController.text = _hasher.hashName ?? '';
        _nameDisplayPreference = _hasher.dispPref;
        _newPhoto = _hasher.photo ?? _newPhoto; // if we have returned from the photo chooser, don't overwrite
        _previousRunCountController.text = (_hkmData?.historicalTotalRunCount ?? 0).toString();
        _previousHaringCountController.text = (_hkmData?.historicalHaringCount ?? 0).toString();
        _historicalCountIsEstimate = (_hkmData?.historicalCountIsEstimate ?? 0) == 1;

        // fill in the e-mail for the user of the app.
        if (widget.pageType == EnumMyProfilePageType.myProfile) {
          _emailController.text = _email ?? '';
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

  String? _externalMapProvider;

  @override
  void initState() {
    Permission.location.isGranted.then((bool isGranted) {
      setState(() {
        G0<AppModel>().hasLocationPermissions = isGranted;
      });
    });

    if (widget.hashNameFromSearch.isNotEmpty) {
      _hashNameController.text = widget.hashNameFromSearch;
    }
    // //print('initState called from hasher_profile_page @ ${DateTime.now().millisecondsSinceEpoch.toString()}');
    if (widget.pageType != EnumMyProfilePageType.newHasherProfile) {
      _refreshUserDataFromTable(true);
      _photoPrefix = widget.hasherId;
    } else {
      if ((widget.kennelId.isNotEmpty) && (widget.kennelId != GUID_EMPTY)) {
        _addAsKennelFollower = true;
      }
      _hasher = HashersModel.empty();
      _photoPrefix = 'newHcUser_${DateTime.now().microsecondsSinceEpoch}';

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

    _newPhoto = 'bundle://avatar-${Random.secure().nextInt(49) + 1}';

    _externalMapProvider = getStringPref(StringPrefsEnum.mapPreference);

    super.initState();
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
    if (_firstNameController.text != (_hasher.firstName ?? '')) {
      isDirty = true;
    }
    if (_lastNameController.text != (_hasher.lastName ?? '')) {
      isDirty = true;
    }
    if ((_email != null) && ((_emailController.text) != (_email ?? ''))) {
      isDirty = true;
    }
    if (_hashNameController.text != (_hasher.hashName ?? '')) {
      isDirty = true;
    }
    if (_nameDisplayPreference != _hasher.dispPref) {
      isDirty = true;
    }
    if (_newPhoto != (_hasher.photo ?? '')) {
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

    if (_hasherPreferences != (_distancePreference + _autoRunPreference)) {
      isDirty = true;
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

  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  Future<void> _updateProfile() async {
    if (_profileFormKey.currentState!.validate()) {
//    If all data are correct then save data to out variables
      _profileFormKey.currentState!.save();

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
        kennelId: ((widget.kennelId.isEmpty)) ? GUID_EMPTY : widget.kennelId,
        historicalTotalRunCount: _previousRunCountController.text,
        historicalHaringCount: _previousHaringCountController.text,
        historicalCountIsEstimate: _historicalCountIsEstimate,
        preferences: _distancePreference + _autoRunPreference,
        followKennelOnAddNewUser: _addAsKennelFollower ? 1 : 0,
        nameDisplayPreference: _nameDisplayPreference,
      );

      if (!responseBody.startsWith(ERROR_PREFIX)) {
        if (widget.pageType == EnumMyProfilePageType.myProfile) {
          await setStringPref(StringPrefsEnum.email.name, _emailController.text);
          await setIntPref(IntPrefsEnum.hasherPreferences, _distancePreference + _autoRunPreference);
          _hasherPreferences = _distancePreference + _autoRunPreference;
        }

        HashersModel? h;
        final List<dynamic> jsonResult = json.decode(responseBody);

        // look through the returned results and find the
        // hasher we just edited. Usually only one
        // hasher will be returned, but there could be
        // edge cases where more than one Hasher record
        // is returned.
        for (int i = 0; i < jsonResult.length; i++) {
          if (jsonResult[i][0].containsKey('hasherId')) {
            for (int j = 0; j < jsonResult[i].length; j++) {
              if ((jsonResult[i][j]['firstName'].toString().toLowerCase() == (_hasher.firstName ?? '').toLowerCase()) &&
                  (jsonResult[i][j]['hashName'].toString().toLowerCase() == (_hasher.hashName ?? '').toLowerCase())) {
                h = HashersModel.fromJson(jsonResult[i][0]);
              }
            }
          }
        }

        if (h != null) {
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
        }

        await _refreshUserDataFromTable(true);
        setState(() {
          _isLoading = false;
          checkDirty();
        });

        if (widget.pageType != EnumMyProfilePageType.myProfile) {
          if (!mounted) return;
          Navigator.of(context).pop(h);
        } else {
          await IveCoreUtilities.showAlert(navigatorKey.currentContext!, 'Profile Updated', 'Your profile was updated successfully.', 'OK');
        }
      } else {
        await IveCoreUtilities.showAlert(
            navigatorKey.currentContext!, 'Profile Not Updated', 'There was a problem updating your profile. Please ensure you are connected to the Internet and try again later.', 'OK');
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
          validator: (String? arg) {
            if ((arg ?? '').isEmpty) {
              return 'First name must have a least one letter';
            } else {
              return null;
            }
          },
          onSaved: (String? val) {
            _hasher = _hasher.copyWith(firstName: val ?? '');
            //_hasher.firstName = val;
          },
        ),
        TextFormField(
          autocorrect: false,
          //initialValue: hasher.lastName,
          controller: _lastNameController,
          decoration: const InputDecoration(labelText: 'Last Name (or initial)'),
          keyboardType: TextInputType.text,
          validator: (String? arg) {
            if ((arg ?? '').isEmpty) {
              return 'Last name must have a least one letter';
            } else {
              return null;
            }
          },
          onSaved: (String? val) {
            _hasher = _hasher.copyWith(lastName: val ?? '');
            //_hasher.lastName = val;
          },
        ),
        if ((widget.pageType == EnumMyProfilePageType.myProfile) || (widget.pageType == EnumMyProfilePageType.newHasherProfile)) ...<Widget>[
          TextFormField(
            autocorrect: false,
            //initialValue: hasher.email,
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
            validator: Utilities.validateEmail,
            onSaved: (String? val) {
              _email = val ?? '';
            },
          ),
        ],
        TextFormField(
          autocorrect: false,
          //initialValue: hasher.hashName,
          controller: _hashNameController,
          decoration: const InputDecoration(labelText: 'Hash Name (optional)'),
          onSaved: (String? val) {
            _hasher = _hasher.copyWith(hashName: val ?? '');
            //_hasher.hashName = val;
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
          onSaved: (String? val) {
            _hasher = _hasher.copyWith(firstName: val ?? '');
            //_hasher.firstName = val;
          },
        ),
        TextFormField(
          autocorrect: false,
          controller: _previousHaringCountController,
          decoration: const InputDecoration(labelText: 'Historical haring count'),
          keyboardType: TextInputType.number,
          onSaved: (String? val) {
            _hasher = _hasher.copyWith(firstName: val ?? '');
            //_hasher.firstName = val;
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
                onChanged: (bool? value) {
                  setState(() {
                    _historicalCountIsEstimate = value ?? false;
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

  AppBar? appBar;

  int _nameDisplayPreference = 1;
  int _distancePreference = 0;
  int _autoRunPreference = 2;

  void _handleRadioValueChange0(int? value) {
    setState(() {
      _nameDisplayPreference = value ?? 0;
      checkDirty();
    });
  }

  void _handleRadioValueChange1(int? value) {
    setState(() {
      _distancePreference = value ?? 0;
      checkDirty();
    });
  }

  void _handleRadioValueChange2(int? value) {
    setState(() {
      _autoRunPreference = value ?? 0;
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
                ? Container(height: MediaQuery.of(context).size.height - (appBar?.preferredSize.height ?? 0), decoration: Backgrounds.defaultHcBackground(), child: _buildCircularProgressIndicator())
                : Container(
                    decoration: Backgrounds.defaultHcBackground(),
                    height: MediaQuery.of(context).size.height - (appBar?.preferredSize.height ?? 0),
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
                                      padding: EdgeInsets.only(top: 30.0, left: (G0<DeviceInfo>().deviceWidthScaleFactor - 1) * 30, right: (G0<DeviceInfo>().deviceWidthScaleFactor - 1) * 30),
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: <Widget>[
                                            Container(
                                              padding: const EdgeInsets.all(10.0),
                                              margin: const EdgeInsets.only(bottom: 30),
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
                                                    'Name Preference',
                                                    style: headingStyle20Black,
                                                  ),
                                                  const SizedBox(
                                                    height: 10,
                                                    width: 10,
                                                  ),
                                                  Row(
                                                    children: <Widget>[
                                                      Radio<int>(
                                                        value: 1,
                                                        groupValue: _nameDisplayPreference,
                                                        onChanged: _handleRadioValueChange0,
                                                      ),
                                                      const Text(
                                                        'Use Hash name',
                                                        style: TextStyle(fontSize: 16.0),
                                                      ),
                                                    ],
                                                  ),
                                                  Row(
                                                    children: <Widget>[
                                                      Radio<int>(
                                                        value: 2,
                                                        groupValue: _nameDisplayPreference,
                                                        onChanged: _handleRadioValueChange0,
                                                      ),
                                                      const Text(
                                                        'Use mortal name',
                                                        style: TextStyle(fontSize: 16.0),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const FancyDivider(key: Key('11203961'), innerColor: Colors.white, topMargin: 45.0, bottomMargin: 5.0),
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
                                                          currentProfileImage: _hasher.photo ?? _newPhoto,
                                                        ),
                                                      ),
                                                    ).then<void>((result) {
                                                      if ((result != null) && (result.isNotEmpty)) {
                                                        _newPhoto = result;
                                                        checkDirty();
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
                                                      if (G0<AppModel>().hasLocationPermissions)
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
                                                                    value: hasherPref_10,
                                                                    groupValue: _autoRunPreference,
                                                                    onChanged: _handleRadioValueChange2,
                                                                  ),
                                                                  Text(
                                                                    '10 ${getDistancePreferenceAsString(_distancePreference)}',
                                                                    style: const TextStyle(fontSize: 16.0),
                                                                  ),
                                                                ],
                                                              ),
                                                              Row(
                                                                children: <Widget>[
                                                                  Radio<int>(
                                                                    value: hasherPref_25,
                                                                    groupValue: _autoRunPreference,
                                                                    onChanged: _handleRadioValueChange2,
                                                                  ),
                                                                  Text(
                                                                    '25 ${getDistancePreferenceAsString(_distancePreference)}',
                                                                    style: const TextStyle(fontSize: 16.0),
                                                                  ),
                                                                ],
                                                              ),
                                                              Row(
                                                                children: <Widget>[
                                                                  Radio<int>(
                                                                    value: hasherPref_50,
                                                                    groupValue: _autoRunPreference,
                                                                    onChanged: _handleRadioValueChange2,
                                                                  ),
                                                                  Text(
                                                                    '50 ${getDistancePreferenceAsString(_distancePreference)}',
                                                                    style: const TextStyle(fontSize: 16.0),
                                                                  ),
                                                                ],
                                                              ),
                                                              Row(
                                                                children: <Widget>[
                                                                  Radio<int>(
                                                                    value: hasherPref_75,
                                                                    groupValue: _autoRunPreference,
                                                                    onChanged: _handleRadioValueChange2,
                                                                  ),
                                                                  Text(
                                                                    '75 ${getDistancePreferenceAsString(_distancePreference)}',
                                                                    style: const TextStyle(fontSize: 16.0),
                                                                  ),
                                                                ],
                                                              ),
                                                              Row(
                                                                children: <Widget>[
                                                                  Radio<int>(
                                                                    value: hasherPref_100,
                                                                    groupValue: _autoRunPreference,
                                                                    onChanged: _handleRadioValueChange2,
                                                                  ),
                                                                  Text(
                                                                    '100 ${getDistancePreferenceAsString(_distancePreference)}',
                                                                    style: const TextStyle(fontSize: 16.0),
                                                                  ),
                                                                ],
                                                              ),
                                                              Row(
                                                                children: <Widget>[
                                                                  Radio<int>(
                                                                    value: hasherPref_150,
                                                                    groupValue: _autoRunPreference,
                                                                    onChanged: _handleRadioValueChange2,
                                                                  ),
                                                                  Text(
                                                                    '150 ${getDistancePreferenceAsString(_distancePreference)}',
                                                                    style: const TextStyle(fontSize: 16.0),
                                                                  ),
                                                                ],
                                                              ),
                                                              Row(
                                                                children: <Widget>[
                                                                  Radio<int>(
                                                                    value: hasherPref_250,
                                                                    groupValue: _autoRunPreference,
                                                                    onChanged: _handleRadioValueChange2,
                                                                  ),
                                                                  Text(
                                                                    '250 ${getDistancePreferenceAsString(_distancePreference)}',
                                                                    style: const TextStyle(fontSize: 16.0),
                                                                  ),
                                                                ],
                                                              ),
                                                              Row(
                                                                children: <Widget>[
                                                                  Radio<int>(
                                                                    value: hasherPref_500,
                                                                    groupValue: _autoRunPreference,
                                                                    onChanged: _handleRadioValueChange2,
                                                                  ),
                                                                  Text(
                                                                    '500 ${getDistancePreferenceAsString(_distancePreference)}',
                                                                    style: const TextStyle(fontSize: 16.0),
                                                                  ),
                                                                ],
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      if (!G0<AppModel>().hasLocationPermissions) ...<Widget>[
                                                        Padding(
                                                          padding: const EdgeInsets.all(8.0),
                                                          child: Text(
                                                            'Distance to Runs',
                                                            style: headingStyle,
                                                            textAlign: TextAlign.center,
                                                          ),
                                                        ),
                                                        Padding(
                                                          padding: const EdgeInsets.all(8.0),
                                                          child: Text(
                                                            'Harrier Central can help you find runs that are nearby. In order to do this, the app needs to have access to the phone\'s current location, but currently location is disabled for this app.\r\n\r\nTo start using the distance features of Harrier Central please press the "Use Location" button below and follow the prompts.',
                                                            style: bodyStyle,
                                                            textAlign: TextAlign.center,
                                                          ),
                                                        ),
                                                        Padding(
                                                          padding: const EdgeInsets.only(top: 22.0, bottom: 0.0),
                                                          child: ElevatedButton(
                                                            style: ElevatedButton.styleFrom(
                                                              padding: const EdgeInsets.only(top: 8, bottom: 8, left: 20, right: 20),
                                                            ),
                                                            onPressed: () async {
                                                              await _enableLocationServices();
                                                            },
                                                            child: Text('Use Location', style: textStyleButton),
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                            const SizedBox(
                                              height: 20,
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
                                                        onChanged: (bool? value) {
                                                          setState(() {
                                                            _addAsKennelFollower = value ?? false;
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
                                    (widget.uiElementsToDisplay & HasherProfilePage.flagUiElement_previousRunCount == 0)
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
                                            ],
                                          ),
                                    (widget.uiElementsToDisplay & HasherProfilePage.flagUiElement_getInviteCodeButton == 0)
                                        ? Container()
                                        : Column(
                                            crossAxisAlignment: CrossAxisAlignment.stretch,
                                            children: <Widget>[
                                              const FancyDivider(
                                                key: Key('4542543'),
                                                innerColor: Colors.white,
                                                bottomMargin: 20.0,
                                                topMargin: 10.0,
                                              ),
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
                                                          final GetInviteCodeService svc = GetInviteCodeService();
                                                          final SingleResultModel? result = await svc.getInviteCode(widget.hasherId);

                                                          if ((result?.result ?? '').startsWith(QR_PREFIX_USER_RESET_CODE)) {
                                                            final QrPopup pp = QrPopup(
                                                              key: const Key('43930293'),
                                                              dialogTitle: 'The invite code for ${_hasher.dispName} is: \r\n\r\n${result!.result!.replaceAll(QR_PREFIX_USER_RESET_CODE, '')}',
                                                              qrText: result.result!,
                                                            );

                                                            await showDialog<void>(
                                                                context: navigatorKey.currentContext!,
                                                                barrierDismissible: false, // user must tap button!
                                                                builder: (BuildContext context) {
                                                                  return pp;
                                                                });
                                                          } else {
                                                            await IveCoreUtilities.showAlert(
                                                                navigatorKey.currentContext!,
                                                                'Code Not Available',
                                                                'The invite code for this user is not available because the user has already installed Harrier Central and has used the app recently.\r\n\r\nThis is a security feature to prevent unauthorized access to active Harrier Central accounts.',
                                                                'OK');
                                                          }
                                                        },
                                                        child: Text(
                                                          'Get invite code',
                                                          style: textStyleButton,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                    if (_externalMapProvider != null) ...<Widget>[
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
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              'Clear Map Preference',
                                              style: headingStyle,
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              'You have set your map preference to $_externalMapProvider. Click below to clear this preference. The next time you open an external map app, you will again be asked to indicate a preference.',
                                              style: bodyStyle,
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 15.0),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                                              children: <Widget>[
                                                ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 15.0),
                                                  ),
                                                  onPressed: () async {
                                                    await IveCoreUtilities.showAlert(
                                                      context,
                                                      'Map preferences cleared',
                                                      'Your map preference has been cleared. Next time you access an external map application, you will be prompted again to select a map preference.',
                                                      'OK',
                                                      showCancelButton: false,
                                                    );

                                                    await removePref(StringPrefsEnum.mapPreference);

                                                    setState(() {
                                                      _externalMapProvider = null;
                                                    });
                                                  },
                                                  child: Text(
                                                    'Clear map preference',
                                                    style: textStyleButton,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
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
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              'Reload Data',
                                              style: headingStyle,
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              'To maximize performance and support the ability to operate when not on a network, Harrier Central stores data relevant to your Hash experience on your phone.\r\n\r\nOn rare occasionions, this data may become out of sync with the master data stored in our central servers. To reload your Hash data, press the "Reload Data" button below. This will clear the existing data, restart Harrier Central, and reload the data from our servers.',
                                              style: bodyStyle,
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 15),
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
                                                              'Reload Data',
                                                              'Refreshing the cache removes all of the data stored on your phone by the Harrier Central app and reloads your profile from our backend servers.\r\n\r\nNormally you will only need to do this when asked to do so by our support team.',
                                                              'Reload data',
                                                              showCancelButton: true,
                                                              cancelButtonText: 'Cancel')
                                                          .then((bool? result) async {
                                                        if (result ?? false) {
                                                          final String userId = getStringPref(StringPrefsEnum.userId)!;
                                                          final String resetCode = getStringPref(StringPrefsEnum.resetCode) ?? '';
                                                          final String facebookAccessToken = getStringPref(StringPrefsEnum.facebookAccessToken) ?? '';
                                                          final String facebookId = getStringPref(StringPrefsEnum.facebookId) ?? '';

                                                          await clearPrefs();

                                                          await setStringPref(StringPrefsEnum.userId, userId);
                                                          await setStringPref(StringPrefsEnum.resetCode, resetCode);
                                                          await setStringPref(StringPrefsEnum.facebookAccessToken, facebookAccessToken);
                                                          await setStringPref(StringPrefsEnum.facebookId, facebookId);
                                                          await setIntPref(IntPrefsEnum.isResettingCache, 1);

                                                          await DBProvider.deleteDb(DB_NAME);

                                                          await G0.reset();

                                                          Phoenix.rebirth(navigatorKey.currentContext!);
                                                        }
                                                      });
                                                    },
                                                    child: Text(
                                                      'Reload Data',
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
                                                        bool? result = await IveCoreUtilities.showAlert(
                                                            context,
                                                            'Log out?',
                                                            'You will be logged out of Harrier Central and all of your data will be erased from this device, although your preferences and run information are safely stored on our servers.\r\n\r\nWhen choosing to log out the app will restart itself automatically.',
                                                            'Log out',
                                                            showCancelButton: true,
                                                            cancelButtonText: 'Stay logged in');

                                                        if (result ?? false) {
                                                          await clearPrefs();
                                                          await DBProvider.deleteDb(DB_NAME);
                                                          await G0.reset();

                                                          Phoenix.rebirth(navigatorKey.currentContext!);
                                                        }
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
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              'Third Party Login',
                                              style: headingStyle,
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              'For Kennels that are using integration with backends such as Facebook, it is required that we have permission to access the group\'s data. This is done by logging into that third party service using your phone.\r\n\r\nIf you are the administrator of a group that is using third party integration, please ensure your account is up to date by pressing the "Login with 3rd Party" button below.',
                                              style: bodyStyle,
                                              textAlign: TextAlign.center,
                                            ),
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
                                    if (widget.uiElementsToDisplay & HasherProfilePage.flagUiElement_gdprDeleteAccount != 0) ...<Widget>[
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
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              'Delete Account',
                                              style: headingStyle,
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              'In order to protect your privacy and ensure compliance with various national and international regulations, we offer you the ability to permanently delete your account. THIS ACTION CANNOT BE UNDONE.\r\n\r\nPerhaps instead you would like to keep your app and run counts but wish to anonymize your personal information? If so, scroll upwards and change your name and email address to anything you desire, understanding that your Kennel will not be able to email you through the app if you provide a fake email address. Click on Save Changes when you are done.',
                                              style: bodyStyle,
                                              textAlign: TextAlign.center,
                                            ),
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
                                                      bool? result = await IveCoreUtilities.showAlert(
                                                          context,
                                                          'Delete Account',
                                                          'Deleting your account will permanently remove your personal information from Harrier Central. Information associated with financial transactions and run attendence will be retained on behalf of the respective Kennels, but will be fully anonymized.\r\n\r\nWARNING:\r\nTHIS ACTION IS PERMANENT AND CANNOT BE REVERSED. Please proceed with caution.',
                                                          'Delete Account',
                                                          showCancelButton: true,
                                                          cancelButtonText: 'Keep Account');

                                                      if (result ?? false) {
                                                        await Future<void>.delayed(const Duration(milliseconds: 1500));

                                                        bool? result2 = await IveCoreUtilities.showAlert(navigatorKey.currentContext!, 'Delete Account',
                                                            'Just to double check since this cannot be undone. Are you sure you want to PERMANENTLY DELETE your account?', 'Delete Account',
                                                            showCancelButton: true, cancelButtonText: 'Keep Account');

                                                        if (result2 ?? false) {
                                                          final GdprDeleteService svc = GdprDeleteService();
                                                          final SingleResultModel? result = await svc.gdprDelete();

                                                          if ((result?.result ?? '') == 'success') {
                                                            await IveCoreUtilities.showAlert(
                                                              navigatorKey.currentContext!,
                                                              'Successful',
                                                              'Your account has been deleted. Thanks for using Harrier Central. We hope to see you back one day in the future!\r\n\r\nPlease note, the Harrier Central app must restart after you hit OK. We suggest closing the app and deleting it as it is useless without an account.',
                                                              'OK',
                                                            );
                                                          } else {
                                                            await IveCoreUtilities.showAlert(
                                                              navigatorKey.currentContext!,
                                                              'Contact us',
                                                              'For some reason, we were unable to delete your account. Please contact us at connect@harriercentral.com to request us to manually delete your account. Our apologies for the inconvenience. Meanwhile, we will remove all of your personal information related to Harrier Central from your phone.\r\n\r\nOnce the information has been deleted, the Harrier Central app will restart. We suggest closing the app and deleting it as it is useless without an account.',
                                                              'OK',
                                                            );
                                                          }

                                                          await clearPrefs();
                                                          await DBProvider.deleteDb(DB_NAME);
                                                          await G0.reset();

                                                          Phoenix.rebirth(navigatorKey.currentContext!);
                                                        }
                                                      }
                                                    },
                                                    child: Text(
                                                      'Delete Account',
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
                height: 60,
                width: MediaQuery.of(context).size.width,
                color: Colors.yellow[100],
                child: Connection.styleForConnected(
                  G0<AppModel>().connectionStatus,
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isDirty ? Colors.red.shade900 : Colors.grey,
                    ),
                    onPressed: () {
                      if (Connection.checkForConnection(context, G0<AppModel>().connectionStatus) && _isDirty) {
                        _updateProfile();
                      }
                    },
                    child: Text(widget.pageType == EnumMyProfilePageType.newHasherProfile ? 'Add Hasher' : 'Save Changes', style: textStyleButton),
                  ),
                ))),
        OfflineModeRibbon(
          showRibbon: G0<AppModel>().connectionStatus == EnumConnectionStatus.not_connected,
          lastSync: getDatePref(DatePrefsEnum.lastSuccessfulUserDataSyncAsDate),
          ribbonImage: 'images/icons/offline_mode.png',
          refreshFunction: () {
            setState(() {});
          },
        ),
      ],
    );
  }

  Future<void> _enableLocationServices() async {
    bool success = false;
    {
      final PermissionStatus ps = await Permission.location.request();

      if (ps.isPermanentlyDenied) {
        final bool? openSettings = await IveCoreUtilities.showAlert(
            navigatorKey.currentContext!,
            'Phone Settings',
            'You must change the location permissions in the phone\'s settings panel for Harrier Central.\r\n\r\nOnce you have done this, please close Settings and come back to Harrier Central.',
            'Open Settings',
            showCancelButton: true,
            cancelButtonText: 'Cancel');

        if (openSettings ?? false) {
          await openAppSettings();

          success = await IveCoreUtilities.showAlert(navigatorKey.currentContext!, 'Success?', 'Were you able to change the settings to enable location services?', 'Yes',
                  showCancelButton: true, cancelButtonText: 'No') ??
              false;
        }
      }

      if ((ps.isGranted) || success) {
        if (await Permission.location.serviceStatus.isEnabled) {
          G0<AppModel>().hasLocationPermissions = true;
          await Utilities.subscribeToGeoLocationStream().then((void _) async {
            await IveCoreUtilities.showAlert(
              context,
              'Location Services Enabled',
              'Location Services have been enabled.',
              'OK',
            );
          });
        }
      } else {
        await IveCoreUtilities.showAlert(
            navigatorKey.currentContext!,
            'Location Services problem',
            'Harrier Central was unable to confirm that Location Services have been enabled.\r\n\r\nPlease use the Settings panel to enable Location Services for Harrier Centra. Once you have done this, please close and restart Harrier Central.',
            'Open Settings',
            showCancelButton: true,
            cancelButtonText: 'Cancel');

        await openAppSettings();
      }
    }

    await IveCoreUtilities.showAlert(navigatorKey.currentContext!, 'Location preferences updated',
        'Your location preferences have been updated.\r\n\r\nYou may have to wait a few minutes or open and close the app before your current location is used by the app.', 'OK');
  }
}
