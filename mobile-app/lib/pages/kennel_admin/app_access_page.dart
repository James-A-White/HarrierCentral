import 'package:harrier_central/imports.dart';

class AppAccessPage extends StatefulWidget {
  const AppAccessPage({super.key, required this.appAccess});

  final int appAccess;

  @override
  AppAccessPageState createState() => AppAccessPageState();
}

class AppAccessPageState extends State<AppAccessPage> {
  AppAccess appAccess = AppAccess(0);

  @override
  void initState() {
     super.initState();
    appAccess = AppAccess(widget.appAccess);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: themeAppBarBackground,
        iconTheme: const IconThemeData(color: Colors.white, size: 28.0),
        title: Text('Set HC App access', style: ts_appBarTitle),
      ),
      body: appAccess == AppAccess(0)
          ? Container()
          : Container(
              padding: const EdgeInsets.only(
                top: 25.0,
                left: 25.0,
                right: 25.0,
                bottom: 70.0,
              ),
              decoration: Backgrounds.defaultHcBackgroundLight(),
              height: MediaQuery.sizeOf(context).height,
              child: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    // getOption('Is on mismanagement', mmRoles.getMismanagementState(mmRoleIsOnMm), (bool value) {
                    //   mmRoles.setMismanagementState(mmRoleIsOnMm, value);
                    // }),
                    getOption(
                      'Is Super Admin',
                      appAccess.getAppAccess(authIsSuperAdmin),
                      (bool value) {
                        appAccess.setAppAccess(authIsSuperAdmin, value);
                      },
                    ),
                    getOption(
                      'Manage Kennel(s)',
                      appAccess.getAppAccess(authCanManageKennel),
                      (bool value) {
                        appAccess.setAppAccess(authCanManageKennel, value);
                      },
                    ),
                    getOption(
                      'Manage Runs',
                      appAccess.getAppAccess(authCanManageRuns),
                      (bool value) {
                        appAccess.setAppAccess(authCanManageRuns, value);
                      },
                    ),
                    getOption(
                      'Manage Hash Cash',
                      appAccess.getAppAccess(authCanManageHashCash),
                      (bool value) {
                        appAccess.setAppAccess(authCanManageHashCash, value);
                      },
                    ),
                    getOption(
                      'Manage Members',
                      appAccess.getAppAccess(authCanManageMembers),
                      (bool value) {
                        appAccess.setAppAccess(authCanManageMembers, value);
                      },
                    ),
                    getOption(
                      'Manage Awards',
                      appAccess.getAppAccess(authCanManageAwards),
                      (bool value) {
                        appAccess.setAppAccess(authCanManageAwards, value);
                      },
                    ),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: hc_red),
                      onPressed: () {
                        // if appAccessFlags = 1 that means this person has no admin privileges, so set all to zero while at the same time preserving the superAdmin bit, otherwise set the authIsAdmin flag
                        final int access =
                            ((appAccess.appAccessFlags ?? 0) & authAllFlags) <=
                                1
                            ? ((appAccess.appAccessFlags ?? 0) &
                                  authIsSuperAdmin)
                            : (appAccess.appAccessFlags ?? 0) | authIsAdmin;
                        Navigator.of(context).pop(access);
                      },
                      child: Text('Save changes', style: ts_button),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget getOption(String title, bool value, Function toggleState) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: <Widget>[
          Container(
            margin: const EdgeInsets.only(right: 10),
            height: 25,
            width: 25,
            color: Colors.yellow[100],
            child: Checkbox(
              value: value,
              onChanged: (bool? value) {
                if (value != null) {
                  setState(() {
                    toggleState(value);
                  });
                }
              },
            ),
          ),
          Text(title, style: ts_headingBlack, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
