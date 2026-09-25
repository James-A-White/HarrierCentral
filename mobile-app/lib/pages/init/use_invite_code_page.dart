import 'package:harrier_central/imports.dart';

class UseInviteCodePage extends StatefulWidget {
  //final FutureRunScopedModel futureRunsModel;

  const UseInviteCodePage({super.key, this.initialCode});

  /// A code obtained without typing — the passkey sign-in (E9.F7.S13) —
  /// which the page submits on its own as soon as it is shown.
  final String? initialCode;

  @override
  UseInviteCodePageState createState() => UseInviteCodePageState();
}

class UseInviteCodePageState extends State<UseInviteCodePage> {
  @override
  Widget build(BuildContext context) {
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
            appBar: AppBar(
              centerTitle: true,
              backgroundColor: themeAppBarBackground,
              iconTheme: const IconThemeData(color: Colors.white, size: 28.0),
              title: Text('Use Invite Code', style: ts_appBarTitle),
            ),
            body: SingleChildScrollView(
              child: Container(
                decoration: Backgrounds.defaultHcBackground(),
                height: MediaQuery.sizeOf(context).height,
                width: MediaQuery.sizeOf(context).width,
                child: UseInviteCodePageContent(
                  initialCode: widget.initialCode,
                ),
              ),
            ),
            resizeToAvoidBottomInset: false,
          ),
        ),
        OfflineModeRibbon(
          lastSync: getDatePref(DatePrefsEnum.lastSuccessfulUserDataSync),
          ribbonImage: 'images/icons/offline_mode.png',
          refreshFunction: () {
            setStateIfMounted(() {});
          },
        ),
      ],
    );
  }
}

/// The invite-code form. Stateless over [InviteCodeController].
class UseInviteCodePageContent extends StatelessWidget {
  const UseInviteCodePageContent({super.key, this.initialCode});

  final String? initialCode;

  static final InputDecoration _inviteCodeDecoration = InputDecoration(
    labelText: 'Invite Code',
    fillColor: hc_red,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10.0),
      borderSide: const BorderSide(),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return GetBuilder<InviteCodeController>(
      init: InviteCodeController(initialCode: initialCode),
      tag: InviteCodeController.tag,
      builder: (InviteCodeController c) => LayoutBuilder(
        builder: (BuildContext context, BoxConstraints viewportConstraints) {
          final double newFontSize =
              (ts_headingLarge.fontSize ?? 24.0) *
              deviceInfo.deviceWidthScaleFactor;

          final TextStyle localHeadingStyle = ts_headingLarge.copyWith(
            fontSize: newFontSize,
            height: 1.2,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(15),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const SizedBox(width: 46.0),
                    Expanded(
                      child: Text(
                        'Please enter your invite code',
                        maxLines: 3,
                        style: localHeadingStyle,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        await Utilities.showAlert(
                          'What is an "Invite Code"?',
                          'An Invite Code is a six character code that allows you to connect to an existing account in Harrier Central.\r\n\r\nYou can ask any Harrier Central admin from your Home Kennel to provide you with your invite code using their Harrier Central app.\r\n\r\nIf you do not have an Invite Code, please go back to the previous screen and select the option to Create a New Account.',
                          'OK',
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.only(left: 20),
                        height: 26,
                        child: Image.asset('images/icons/info_button.png'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 35, width: 10),
                Form(
                  key: c.formKey,
                  child: Container(
                    margin: const EdgeInsets.only(left: 15, right: 15),
                    padding: const EdgeInsets.only(
                      left: 15,
                      right: 15,
                      top: 15,
                      bottom: 5,
                    ),
                    color: Colors.yellow[100],
                    child: Column(
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: TextFormField(
                                autocorrect: false,
                                textCapitalization:
                                    TextCapitalization.characters,
                                controller: c.inviteCodeTextController,
                                focusNode: c.inviteCodeFocusNode,
                                decoration: _inviteCodeDecoration,
                                validator: (String? val) {
                                  if (val == null) {
                                    return 'Application error 1802. Please contact us at harriercentral@gmail.com';
                                  } else if (val.length != 6) {
                                    return 'Invite codes are six characters';
                                  } else {
                                    return null;
                                  }
                                },
                                keyboardType: TextInputType.text,
                                textAlign: TextAlign.center,
                                style: ts_titleDarkRedLarge,
                              ),
                            ),
                            const SizedBox(width: 15.0),
                            TextButton(
                              style: text_button_style.copyWith(
                                padding: const WidgetStatePropertyAll(
                                  EdgeInsets.all(8.0),
                                ),
                                minimumSize: const WidgetStatePropertyAll(
                                  Size.zero,
                                ),
                                alignment: Alignment.center,
                              ),
                              onPressed: c.toggleQrScanner,
                              child: const Icon(
                                MaterialCommunityIcons.qrcode_scan,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        Obx(
                          () => Visibility(
                            visible: c.showQrScanner.value,
                            maintainState: true,
                            child: Container(
                              padding: const EdgeInsets.all(11.0),
                              child: AspectRatio(
                                aspectRatio: 1.0,
                                child: MobileScanner(
                                  controller: c.scanner,
                                  onDetect: c.onDetect,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20, width: 10),
                        const SizedBox(height: 16, width: 10),
                        Obx(
                          () => c.isLoading.value
                              ? Text(
                                  'Please wait...',
                                  // Dark on the pale-yellow card — the page's
                                  // yellow heading style is invisible here.
                                  style: localHeadingStyle.copyWith(
                                    color: themeAppBarBackground,
                                  ),
                                  textAlign: TextAlign.center,
                                )
                              : SizedBox(
                                  width: double.infinity,
                                  child: TextButton(
                                    style: text_button_style,
                                    onPressed: () =>
                                        unawaited(c.submitInviteCode()),
                                    child: Text(
                                      'Get Started!',
                                      style: ts_button,
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20, width: 10),
                // Inset to line up with Get Started inside the card above
                // (its margin 15 + padding 15), not the full page width.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: text_button_style,
                      onPressed: () async {
                        final EmailPopup emailPopup = EmailPopup(
                          initialEmailAddress: c.emailAddress,
                        );
                        final Map<String, String?>? x =
                            await showDialog<Map<String, String>>(
                              context: context,
                              barrierDismissible: false,
                              builder: (BuildContext context) => emailPopup,
                            );
                        if (x == null) return;
                        final String email = x['email'] ?? '';
                        final String type = x['type'] ?? '';
                        if (type == 'cancel') return;
                        final String userMessage = await c.emailNewCode(email);
                        await Utilities.showAlert(
                          'Instructions',
                          userMessage,
                          'OK',
                        );
                      },
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Email me a new invite code',
                          style: ts_button,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: text_button_style.copyWith(
                        backgroundColor: const WidgetStatePropertyAll(
                          Colors.grey,
                        ),
                      ),
                      onPressed: () => Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const EmailNotReceivedPage(),
                        ),
                      ),
                      child: Text(
                        "I didn't receive an email",
                        style: ts_button,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 50),
              ],
            ),
          );
        },
      ),
    );
  }
}
