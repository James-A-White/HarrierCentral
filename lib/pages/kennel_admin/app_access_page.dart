// @dart=2.11
import 'package:harrier_central/imports.dart';

class AppAccessPage extends StatefulWidget {
  const AppAccessPage({Key key, @required this.appAccess}) : super(key: key);

  final int appAccess;

  @override
  _AppAccessPageState createState() => _AppAccessPageState();
}

class _AppAccessPageState extends State<AppAccessPage> {
  AppAccess appAccess;

  @override
  void initState() {
    appAccess = AppAccess(widget.appAccess);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: themeAppBarBackground,
        title: const Text(
          'Set HC App access',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: appAccess == null
          ? Container()
          : Container(
              padding: const EdgeInsets.only(top: 25.0, left: 25.0, right: 25.0, bottom: 70.0),
              decoration: Backgrounds.defaultHcBackgroundLight(),
              height: MediaQuery.of(context).size.height,
              child: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    // getOption('Is on mismanagement', mmRoles.getMismanagementState(mmRoleIsOnMm), (bool value) {
                    //   mmRoles.setMismanagementState(mmRoleIsOnMm, value);
                    // }),

                    getOption('Is Super Admin', appAccess.getAppAccess(authIsSuperAdmin), (bool value) {
                      appAccess.setAppAccess(authIsSuperAdmin, value);
                    }),
                    getOption('Manage Kennel(s)', appAccess.getAppAccess(authCanManageKennel), (bool value) {
                      appAccess.setAppAccess(authCanManageKennel, value);
                    }),
                    getOption('Manage Runs', appAccess.getAppAccess(authCanManageRuns), (bool value) {
                      appAccess.setAppAccess(authCanManageRuns, value);
                    }),
                    getOption('Manage Hash Cash', appAccess.getAppAccess(authCanManageHashCash), (bool value) {
                      appAccess.setAppAccess(authCanManageHashCash, value);
                    }),
                    getOption('Manage Members', appAccess.getAppAccess(authCanManageMembers), (bool value) {
                      appAccess.setAppAccess(authCanManageMembers, value);
                    }),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade900,
                      ),
                      onPressed: () {
                        // if appAccessFlags = 1 that means this person has no admin privileges, so set all to zero while at the same time preserving the superAdmin bit, otherwise set the authIsAdmin flag
                        final int access = (appAccess.appAccessFlags & authAllFlags) <= 1 ? (appAccess.appAccessFlags & authIsSuperAdmin) : appAccess.appAccessFlags | authIsAdmin;
                        Navigator.of(context).pop(access);
                      },
                      child: Text('Save changes', style: textStyleButton),
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
              onChanged: (bool value) {
                setState(() {
                  toggleState(value);
                });
              },
            ),
          ),
          Text(
            title,
            style: headingStyle20Black,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
