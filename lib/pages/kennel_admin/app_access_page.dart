import 'package:harrier_central/imports.dart';

class AppAccessPage extends StatefulWidget {
  const AppAccessPage({@required this.appAccess});

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
            : SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.only(top: 25.0, left: 25.0, right: 25.0, bottom: 70.0),
                  decoration: Backgrounds.defaultHcBackgroundLight(),
                  child: Column(
                    children: <Widget>[
                      // getOption('Is on mismanagement', mmRoles.getMismanagementState(mmRoleIsOnMm), (bool value) {
                      //   mmRoles.setMismanagementState(mmRoleIsOnMm, value);
                      // }),
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
                          primary: Theme.of(context).accentColor,
                        ),
                        onPressed: () {
                          // if mismanagementFlags = 1 that means this person has no role, so set all to zero, otherwise set the mmRoleIsOnMm flag
                          Navigator.of(context).pop((appAccess.appAccessFlags & authAllFlags) <= 1 ? 0 : appAccess.appAccessFlags | authIsAdmin);
                        },
                        child: Text('Save changes', style: buttonTextStyle),
                      ),
                    ],
                  ),
                ),
              ));
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
