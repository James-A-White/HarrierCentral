// ignore_for_file: constant_identifier_names

import 'package:harrier_central/imports.dart';

/// The profile page: my account, another hasher, or a new hasher. Stateless
/// over [HasherProfileController]; navigation and the context-bound dialogs
/// stay here.
class HasherProfilePage extends StatelessWidget {
  //final FutureRunScopedModel futureRunsModel;

  const HasherProfilePage({
    super.key,
    required this.dataContext,
    required this.pageType,
    this.hasherId = GUID_EMPTY,
    this.eventId = GUID_EMPTY,
    this.kennelId = GUID_EMPTY,
    this.uiElementsToDisplay = 0,
    this.kennelShortName = '',
    this.hashNameFromSearch = '',
  });

  final EnumDataContext dataContext;
  final EnumMyProfilePageType pageType;
  final String hasherId;
  final String eventId;
  final String kennelId;
  final int uiElementsToDisplay;
  final String kennelShortName;
  final String hashNameFromSearch;

  // 0x04 (distancePref), 0x10 (logOutAndRefresh/Reload Data) and 0x0800
  // (copyBootLog) were retired 2026-07-31: distance/camera/GPS settings moved
  // to the Settings page; Reload Data and Diagnostic Logs moved to Support.
  static const int flagUiElement_followKennel = 0x00000001;
  static const int flagUiElement_previousRunCount = 0x00000002;
  static const int flagUiElement_autoDisplayRunsDistance = 0x00000008;
  static const int flagUiElement_refresh3rdPartyLogin = 0x00000020;
  static const int flagUiElement_gdprDeleteAccount = 0x00000040;
  static const int flagUiElement_getInviteCodeButton = 0x00000080;
  //static const int flagUiElement_logOutOfFacebook = 0x00000100;
  static const int flagUiElement_logOutButton = 0x00000200;
  static const int flagUiElement_getUserRunHistory = 0x00000400;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HasherProfileController>(
      init: HasherProfileController(
        dataContext: dataContext,
        pageType: pageType,
        hasherId: hasherId,
        eventId: eventId,
        kennelId: kennelId,
        hashNameFromSearch: hashNameFromSearch,
      ),
      tag: HasherProfileController.tagFor(pageType, hasherId),
      builder: (HasherProfileController c) => Obx(() => _body(context, c)),
    );
  }

  Future<void> _save(BuildContext context, HasherProfileController c) async {
    final ({bool shouldPop, HashersModel? result}) r = await c.updateProfile();
    if (r.shouldPop && context.mounted) Navigator.of(context).pop(r.result);
  }

  Future<void> _openRunHistory(
    BuildContext context,
    HasherProfileController c,
  ) async {
    final RunHistoryModel? runHistory = await c.loadRunHistory();
    if (runHistory == null || !context.mounted) return;
    await Navigator.of(context).push<dynamic>(
      MaterialPageRoute<dynamic>(
        builder: (BuildContext context) => UserRunHistoryListPage(
          appDomain: AppDomainType.values.byName(dataContext.name),
          hashName: hashNameFromSearch,
          hasherId: hasherId,
          kennelInfo: runHistory,
          refreshKennelInfo: () {},
        ),
      ),
    );
  }

  Widget _buildCircularProgressIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            'Loading / Updating User Profile',
            style: ts_headingLarge,
            textAlign: TextAlign.center,
          ),
          Container(height: 30),
          const HcAppCircularProgressIndicator(key: Key('887262')),
        ],
      ),
    );
  }

  Widget _profileFormUi(HasherProfileController c) {
    return Column(
      children: <Widget>[
        TextFormField(
          autocorrect: false,
          controller: c.firstNameController,
          //initialValue: hasher.firstName,
          decoration: const InputDecoration(
            labelText: 'First name (or initial)',
          ),
          keyboardType: TextInputType.text,
          validator: (String? arg) {
            if ((arg ?? '').isEmpty) {
              return 'First name must have a least one letter';
            } else {
              return null;
            }
          },
          onSaved: (String? val) {
            c.hasher = c.hasher.copyWith(firstName: val ?? '');
          },
        ),
        TextFormField(
          autocorrect: false,
          //initialValue: hasher.lastName,
          controller: c.lastNameController,
          decoration: const InputDecoration(
            labelText: 'Last Name (or initial)',
          ),
          keyboardType: TextInputType.text,
          validator: (String? arg) {
            if ((arg ?? '').isEmpty) {
              return 'Last name must have a least one letter';
            } else {
              return null;
            }
          },
          onSaved: (String? val) {
            c.hasher = c.hasher.copyWith(lastName: val ?? '');
          },
        ),
        if ((pageType == EnumMyProfilePageType.myProfile) ||
            (pageType == EnumMyProfilePageType.newHasherProfile)) ...<Widget>[
          TextFormField(
            autocorrect: false,
            //initialValue: hasher.email,
            controller: c.emailController,
            decoration: const InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
            validator: Utilities.validateEmail,
            onSaved: (String? val) {
              c.email = val ?? '';
            },
          ),
        ],
        TextFormField(
          autocorrect: false,
          //initialValue: hasher.hashName,
          controller: c.hashNameController,
          decoration: const InputDecoration(labelText: 'Hash Name (optional)'),
          onSaved: (String? val) {
            c.hasher = c.hasher.copyWith(hashName: val ?? '');
          },
          keyboardType: TextInputType.text,
        ),
        const SizedBox(height: 10.0),
      ],
    );
  }

  Widget _runCountUi(HasherProfileController c) {
    return Column(
      children: <Widget>[
        TextFormField(
          autocorrect: false,
          controller: c.previousRunCountController,
          decoration: const InputDecoration(labelText: 'Historical run count'),
          keyboardType: TextInputType.number,
        ),
        TextFormField(
          autocorrect: false,
          controller: c.previousHaringCountController,
          decoration: const InputDecoration(
            labelText: 'Historical haring count',
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 15.0),
        Row(
          children: <Widget>[
            Container(
              margin: const EdgeInsets.only(right: 10),
              height: 25,
              width: 25,
              color: Colors.yellow[100],
              child: Checkbox(
                value: c.historicalCountIsEstimateWidget.value ?? false,
                onChanged: (bool? value) => c.setEstimate(value ?? false),
              ),
            ),
            const Text(
              'Run counts are estimates',
              //style: headingStyle,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        const SizedBox(height: 10.0),
      ],
    );
  }

  Widget _body(BuildContext context, HasherProfileController c) {
    final String newPhoto = c.newPhoto.value;
    final bool userRunHistoryLoading = c.userRunHistoryLoading.value;
    final AppBar appBar = AppBar(
      centerTitle: true,
      backgroundColor: themeAppBarBackground,
      iconTheme: const IconThemeData(color: Colors.white, size: 28.0),
      title: Text(
        pageType == EnumMyProfilePageType.myProfile
            ? 'My Account'
            : 'Hasher Profile',
        style: ts_appBarTitle,
      ),
    );
    return Stack(
      children: <Widget>[
        SizedBox(
          height: MediaQuery.sizeOf(context).height,
          width: MediaQuery.sizeOf(context).width,
        ),
        Positioned(
          top: 0,
          left: 0,
          width: MediaQuery.sizeOf(context).width,
          height: MediaQuery.sizeOf(context).height,
          child: AppScaffold(
            //key: ScaffoldKey,
            appBar: appBar,
            body: c.isLoading.value
                ? Container(
                    height:
                        MediaQuery.sizeOf(context).height -
                        appBar.preferredSize.height,
                    decoration: Backgrounds.defaultHcBackground(),
                    child: _buildCircularProgressIndicator(),
                  )
                : Container(
                    decoration: Backgrounds.defaultHcBackground(),
                    height:
                        MediaQuery.sizeOf(context).height -
                        appBar.preferredSize.height,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanDown: (_) {
                        FocusScope.of(context).requestFocus(FocusNode());
                      },
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.only(
                            top: 30,
                            left: 20,
                            right: 20,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              SizedBox(
                                width: MediaQuery.sizeOf(context).width,
                                child: Column(
                                  children: <Widget>[
                                    Text(
                                      pageType ==
                                              EnumMyProfilePageType.myProfile
                                          ? 'My Profile Information'
                                          : 'Hasher Profile Information',
                                      style: ts_headingLarge,
                                      textAlign: TextAlign.center,
                                    ),
                                    Container(
                                      padding: EdgeInsets.only(
                                        top: 30.0,
                                        left:
                                            (deviceInfo.deviceWidthScaleFactor -
                                                1) *
                                            30,
                                        right:
                                            (deviceInfo.deviceWidthScaleFactor -
                                                1) *
                                            30,
                                      ),
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: <Widget>[
                                            Container(
                                              padding: const EdgeInsets.all(
                                                10.0,
                                              ),
                                              margin: const EdgeInsets.only(
                                                bottom: 30,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.yellow[100],
                                                borderRadius:
                                                    BorderRadius.circular(5.0),
                                              ),
                                              child: Form(
                                                key: c.profileFormKey,
                                                autovalidateMode:
                                                    c.autoValidate.value
                                                    ? AutovalidateMode.always
                                                    : AutovalidateMode.disabled,
                                                child: _profileFormUi(c),
                                              ),
                                            ),
                                            Container(
                                              decoration: BoxDecoration(
                                                color: Colors.yellow[100],
                                                borderRadius:
                                                    BorderRadius.circular(5.0),
                                              ),
                                              child: RadioGroup(
                                                groupValue: c
                                                    .nameDisplayPreference
                                                    .value,
                                                onChanged:
                                                    c.setNameDisplayPreference,
                                                child: Column(
                                                  children: <Widget>[
                                                    const SizedBox(
                                                      height: 10,
                                                      width: 10,
                                                    ),
                                                    Text(
                                                      'Name Preference',
                                                      style: ts_headingBlack,
                                                    ),
                                                    const SizedBox(
                                                      height: 10,
                                                      width: 10,
                                                    ),

                                                    Row(
                                                      children: <Widget>[
                                                        Radio<int>(value: 1),
                                                        const Text(
                                                          'Use Hash name',
                                                          style: TextStyle(
                                                            fontSize: 16.0,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    Row(
                                                      children: <Widget>[
                                                        Radio<int>(value: 2),
                                                        const Text(
                                                          'Use mortal name',
                                                          style: TextStyle(
                                                            fontSize: 16.0,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const FancyDivider(
                                              key: Key('11203961'),
                                              innerColor: Colors.white,
                                              topMargin: 45.0,
                                              bottomMargin: 5.0,
                                            ),
                                            Container(
                                              height: 220,
                                              color: Colors.white,
                                              padding: const EdgeInsets.all(
                                                10.0,
                                              ),
                                              margin: const EdgeInsets.only(
                                                top: 20,
                                                bottom: 30,
                                              ),
                                              child: newPhoto.isEmpty
                                                  ? Image.asset(
                                                      'images/icons/create_profile_photo.png',
                                                    )
                                                  : Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            left: 0,
                                                            right: 0,
                                                          ),
                                                      child: AspectRatio(
                                                        aspectRatio: 1.0,
                                                        child: ProfilePhoto(
                                                          profilePhotoUrl:
                                                              newPhoto,
                                                          photoHeight: 200.0,
                                                          //leftPadding: 0.0,
                                                        ),

                                                        // Container(
                                                        //   decoration: BoxDecoration(
                                                        //     shape: BoxShape.rectangle,
                                                        //       fit: BoxFit.fill,
                                                        //       image: NetworkImage(
                                                        //         newPhoto,
                                                      ),
                                                    ),
                                            ),
                                            StyleForConnected(
                                              child: ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 8,
                                                        bottom: 8,
                                                        left: 20,
                                                        right: 20,
                                                      ),
                                                ),
                                                onPressed: () async {
                                                  if (!Utilities.isConnected(
                                                    showDialog: true,
                                                  )) {
                                                    return;
                                                  }

                                                  final String?
                                                  result = await Navigator.push<String>(
                                                    context,
                                                    MaterialPageRoute<String>(
                                                      builder:
                                                          (
                                                            BuildContext
                                                            context,
                                                          ) => ChooseProfileImage(
                                                            isForThisDevice:
                                                                pageType ==
                                                                EnumMyProfilePageType
                                                                    .myProfile,
                                                            fileNamePrefix:
                                                                c.photoPrefix,
                                                            currentProfileImage:
                                                                c
                                                                    .hasher
                                                                    .photo ??
                                                                newPhoto,
                                                          ),
                                                    ),
                                                  );

                                                  if (result != null &&
                                                      result.isNotEmpty) {
                                                    c.onPhotoChosen(result);
                                                  }
                                                },
                                                child: Text(
                                                  'Update Profile Image',
                                                  style: ts_button,
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 15),
                                          ],
                                        ),
                                      ),
                                    ),
                                    (uiElementsToDisplay &
                                                HasherProfilePage
                                                    .flagUiElement_followKennel ==
                                            0)
                                        ? Container()
                                        : Column(
                                            children: <Widget>[
                                              const FancyDivider(
                                                key: Key('882552302'),
                                                innerColor: Colors.white,
                                                bottomMargin: 20.0,
                                              ),
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  10.0,
                                                ),
                                                margin: const EdgeInsets.only(
                                                  bottom: 45,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.yellow[100],
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        5.0,
                                                      ),
                                                ),
                                                child: Row(
                                                  children: <Widget>[
                                                    Container(
                                                      margin:
                                                          const EdgeInsets.only(
                                                            right: 10,
                                                          ),
                                                      height: 25,
                                                      width: 25,
                                                      color: Colors.yellow[100],
                                                      child: Checkbox(
                                                        value: c
                                                            .addAsKennelFollower
                                                            .value,
                                                        onChanged: (bool? value) =>
                                                            c
                                                                    .addAsKennelFollower
                                                                    .value =
                                                                value ?? false,
                                                      ),
                                                    ),
                                                    const Text(
                                                      'Follow this Kennel',
                                                      //style: headingStyle,
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                    (uiElementsToDisplay &
                                                HasherProfilePage
                                                    .flagUiElement_previousRunCount ==
                                            0)
                                        ? Container()
                                        : Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: <Widget>[
                                              const FancyDivider(
                                                key: Key('612233999'),
                                                innerColor: Colors.white,
                                                bottomMargin: 20.0,
                                              ),
                                              Text(
                                                'Previous run count:',
                                                style: ts_headingLarge,
                                                textAlign: TextAlign.center,
                                              ),
                                              Text(
                                                'Number of runs with $kennelShortName that are not listed in Harrier Central',
                                                style: ts_headingItalic,
                                                textAlign: TextAlign.center,
                                              ),
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  10.0,
                                                ),
                                                margin: const EdgeInsets.only(
                                                  top: 20,
                                                  bottom: 40,
                                                ),
                                                // width: 100,
                                                // height: 50,
                                                decoration: BoxDecoration(
                                                  color: Colors.yellow[100],
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        5.0,
                                                      ),
                                                ),
                                                child: Form(
                                                  key: c.runCountFormKey,
                                                  autovalidateMode:
                                                      c.autoValidate.value
                                                      ? AutovalidateMode.always
                                                      : AutovalidateMode
                                                            .disabled,
                                                  child: _runCountUi(c),
                                                ),
                                              ),
                                            ],
                                          ),
                                    (uiElementsToDisplay &
                                                HasherProfilePage
                                                    .flagUiElement_getInviteCodeButton ==
                                            0)
                                        ? Container()
                                        : Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: <Widget>[
                                              const FancyDivider(
                                                key: Key('4542543'),
                                                innerColor: Colors.white,
                                                bottomMargin: 20.0,
                                                topMargin: 10.0,
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 15,
                                                  bottom: 40,
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceAround,
                                                  children: <Widget>[
                                                    StyleForConnected(
                                                      child: ElevatedButton(
                                                        style: ElevatedButton.styleFrom(
                                                          padding:
                                                              const EdgeInsets.only(
                                                                top: 8,
                                                                bottom: 8,
                                                                left: 20,
                                                                right: 20,
                                                              ),
                                                        ),
                                                        onPressed: () async {
                                                          final SingleResultModel?
                                                          result = await c
                                                              .getInviteCode();

                                                          if ((result?.result ??
                                                                  '')
                                                              .startsWith(
                                                                QR_PREFIX_USER_RESET_CODE,
                                                              )) {
                                                            final QrPopup
                                                            pp = QrPopup(
                                                              key: const Key(
                                                                '43930293',
                                                              ),
                                                              dialogTitle:
                                                                  'The invite code for ${c.hasher.dispName} is: \r\n\r\n${result!.result!.replaceAll(QR_PREFIX_USER_RESET_CODE, '')}',
                                                              qrText: result
                                                                  .result!,
                                                            );

                                                            await showDialog<
                                                              void
                                                            >(
                                                              context: navigatorKey
                                                                  .currentContext!,
                                                              barrierDismissible:
                                                                  false, // user must tap button!
                                                              builder:
                                                                  (
                                                                    BuildContext
                                                                    context,
                                                                  ) {
                                                                    return pp;
                                                                  },
                                                            );
                                                          } else {
                                                            await Utilities.showAlert(
                                                              'Code Not Available',
                                                              'The invite code for this user is not available because the user has already installed Harrier Central and has used the app recently.\r\n\r\nThis is a security feature to prevent unauthorized access to active Harrier Central accounts.',
                                                              'OK',
                                                            );
                                                          }
                                                        },
                                                        child: Text(
                                                          'Get invite code',
                                                          style: ts_button,
                                                          textAlign: TextAlign.center,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                    (uiElementsToDisplay &
                                                HasherProfilePage
                                                    .flagUiElement_getUserRunHistory ==
                                            0)
                                        ? Container()
                                        : Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: <Widget>[
                                              const FancyDivider(
                                                key: Key('4542543'),
                                                innerColor: Colors.white,
                                                bottomMargin: 20.0,
                                                topMargin: 10.0,
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 15,
                                                  bottom: 40,
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceAround,
                                                  children: <Widget>[
                                                    StyleForConnected(
                                                      child: ElevatedButton(
                                                        style: ElevatedButton.styleFrom(
                                                          padding:
                                                              const EdgeInsets.only(
                                                                top: 8,
                                                                bottom: 8,
                                                                left: 20,
                                                                right: 20,
                                                              ),
                                                        ),
                                                        onPressed:
                                                            userRunHistoryLoading
                                                            ? null
                                                            : () =>
                                                                  _openRunHistory(
                                                                    context,
                                                                    c,
                                                                  ),
                                                        child:
                                                            userRunHistoryLoading
                                                            ? Row(
                                                                children: [
                                                                  Text(
                                                                    'Please wait...',
                                                                    style:
                                                                        ts_button,
                                                                  ),
                                                                  const SizedBox(
                                                                    width: 20,
                                                                  ),
                                                                  SizedBox(
                                                                    height: 20,
                                                                    width: 20,

                                                                    child: HcAppCircularProgressIndicator(
                                                                      color1: Colors
                                                                          .white,
                                                                      size: 20,
                                                                      key:
                                                                          UniqueKey(),
                                                                    ),
                                                                  ),
                                                                ],
                                                              )
                                                            : Text(
                                                                'View Run History',
                                                                style:
                                                                    ts_button,
                                                              ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                    if (uiElementsToDisplay &
                                            HasherProfilePage
                                                .flagUiElement_logOutButton !=
                                        0) ...<Widget>[
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
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
                                              'Log out of Harrier Central',
                                              style: ts_heading,
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              'This app is currently logged in to Harrier Central.\r\n\r\nPress the Log Out button if you would like to log out from your Harrier Central account on this device. Your data will remain on our servers and you can log in again in the future without the loss of any data.',
                                              style: ts_body,
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 15,
                                              bottom: 15,
                                            ),
                                            // A Wrap: side by side where they
                                            // fit, stacked (centred) where they
                                            // do not — a Row overflowed at 1.5x.
                                            child: Wrap(
                                              alignment:
                                                  WrapAlignment.spaceAround,
                                              runSpacing: 12,
                                              spacing: 12,
                                              children: <Widget>[
                                                StyleForConnected(
                                                  child: ElevatedButton(
                                                    style: ElevatedButton.styleFrom(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            top: 8,
                                                            bottom: 8,
                                                            left: 20,
                                                            right: 20,
                                                          ),
                                                    ),
                                                    onPressed: () async {
                                                      await IveCoreUtilities.showAlert(
                                                        context,
                                                        'Log out?',
                                                        'You will be logged out of Harrier Central and all of your data will be erased from this device, although your preferences and run information are safely stored on our servers.\r\n\r\nWhen choosing to log out the app will restart itself automatically.',
                                                        'Log out',
                                                        showCancelButton: true,
                                                        cancelButtonText:
                                                            'Stay logged in',
                                                      ).then((
                                                        bool? result,
                                                      ) async {
                                                        if (result ?? false) {
                                                          await AppBootService.resetAndReboot(
                                                            keepResetCode:
                                                                false,
                                                          );
                                                        }
                                                      });
                                                    },
                                                    child: Text(
                                                      'Log out of Harrier Central',
                                                      style: ts_button,
                                                      textAlign: TextAlign.center,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    // Passkeys: how you get in, so it sits
                                    // with Third Party Login rather than on
                                    // Settings, which is now preferences only
                                    // (James, 2026-09-20). Self-contained —
                                    // it fetches, draws and revokes on its
                                    // own and needs nothing from this page.
                                    if (pageType ==
                                        EnumMyProfilePageType.myProfile)
                                      PasskeysSection(),
                                    if (uiElementsToDisplay &
                                            HasherProfilePage
                                                .flagUiElement_refresh3rdPartyLogin !=
                                        0) ...<Widget>[
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
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
                                              style: ts_headingLarge,
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              'For Kennels that are using integration with backends such as Facebook, it is required that we have permission to access the group\'s data. This is done by logging into that third party service using your phone.\r\n\r\nIf you are the administrator of a group that is using third party integration, please ensure your account is up to date by pressing the "Login with 3rd Party" button below.',
                                              style: ts_body,
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 15,
                                              bottom: 15,
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceAround,
                                              children: <Widget>[
                                                StyleForConnected(
                                                  child: ElevatedButton(
                                                    style: ElevatedButton.styleFrom(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            top: 8,
                                                            bottom: 8,
                                                            left: 20,
                                                            right: 20,
                                                          ),
                                                    ),
                                                    onPressed: () async {
                                                      await Navigator.push<
                                                        dynamic
                                                      >(
                                                        context,
                                                        MaterialPageRoute<
                                                          dynamic
                                                        >(
                                                          builder:
                                                              (
                                                                BuildContext
                                                                context,
                                                              ) =>
                                                                  const ThirdPartyLogin(
                                                                    false,
                                                                  ),
                                                        ),
                                                      );
                                                    },
                                                    child: Text(
                                                      'Login with 3rd Party',
                                                      style: ts_button,
                                                      textAlign: TextAlign.center,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    if (uiElementsToDisplay &
                                            HasherProfilePage
                                                .flagUiElement_gdprDeleteAccount !=
                                        0) ...<Widget>[
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
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
                                              style: ts_headingLarge,
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              'In order to protect your privacy and ensure compliance with various national and international regulations, we offer you the ability to permanently delete your account. THIS ACTION CANNOT BE UNDONE.\r\n\r\nPerhaps instead you would like to keep your app and run counts but wish to anonymize your personal information? If so, scroll upwards and change your name and email address to anything you desire, understanding that your Kennel will not be able to email you through the app if you provide a fake email address. Click on Save Changes when you are done.',
                                              style: ts_body,
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 15,
                                              bottom: 15,
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceAround,
                                              children: <Widget>[
                                                StyleForConnected(
                                                  child: ElevatedButton(
                                                    style: ElevatedButton.styleFrom(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            top: 8,
                                                            bottom: 8,
                                                            left: 20,
                                                            right: 20,
                                                          ),
                                                    ),
                                                    onPressed: () => unawaited(
                                                      c.deleteAccount(),
                                                    ),
                                                    child: Text(
                                                      'Delete Account',
                                                      style: ts_button,
                                                      textAlign: TextAlign.center,
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
                              // Clears the Save bar, which grows by the
                              // system inset below.
                              SizedBox(
                                width: 70,
                                height:
                                    70 +
                                    MediaQuery.viewPaddingOf(context).bottom,
                              ),
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
          // Edge to edge (Android 15+, and iOS's home indicator): the bar
          // reaches the screen's bottom edge, so it takes the system inset
          // as extra padding or the gesture handle sits across the button.
          child: Container(
            padding: EdgeInsets.only(
              top: 10,
              right: 20,
              bottom: 10 + MediaQuery.viewPaddingOf(context).bottom,
              left: 20,
            ),
            height: 60 + MediaQuery.viewPaddingOf(context).bottom,
            width: MediaQuery.sizeOf(context).width,
            color: Colors.yellow[100],
            child: StyleForConnected(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.isDirty.value ? hc_red : Colors.grey,
                ),
                onPressed: () async {
                  if (Utilities.isConnected(showDialog: true) &&
                      c.isDirty.value) {
                    await _save(context, c);
                  }
                },
                child: Text(
                  pageType == EnumMyProfilePageType.newHasherProfile
                      ? 'Add Hasher'
                      : 'Save Changes',
                  style: ts_button,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
        OfflineModeRibbon(
          lastSync: getDatePref(DatePrefsEnum.lastSuccessfulUserDataSync),
          ribbonImage: 'images/icons/offline_mode.png',
          refreshFunction: () => c.update(),
        ),
      ],
    );
  }
}
