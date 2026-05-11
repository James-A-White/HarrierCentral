import 'package:harrier_central/imports.dart';

class MismanagementRolesPage extends StatefulWidget {
  const MismanagementRolesPage({super.key, required this.mismanagementRoles});

  final int mismanagementRoles;

  @override
  MismanagementRolesPageState createState() => MismanagementRolesPageState();
}

class MismanagementRolesPageState extends State<MismanagementRolesPage> {
  late Mismanagement mmRoles;

  @override
  void initState() {
    super.initState();
    mmRoles = Mismanagement(widget.mismanagementRoles);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: themeAppBarBackground,
        iconTheme: const IconThemeData(color: Colors.white, size: 28.0),
        title: Text('Set mismanagement roles', style: ts_appBarTitle),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(
                top: 0.0,
                left: 25.0,
                right: 25.0,
                bottom: 0.0,
              ),
              decoration: Backgrounds.defaultHcBackgroundLight(),
              child: Scrollbar(
                child: SingleChildScrollView(
                  child: Column(
                    children: <Widget>[
                      // getOption('Is on mismanagement', mmRoles.getMismanagementState(mmRoleIsOnMm), (bool value) {
                      //   mmRoles.setMismanagementState(mmRoleIsOnMm, value);
                      // }),
                      const SizedBox(height: 30.0),
                      getOption(
                        'Grand Master/Mistress (GM)',
                        mmRoles.getMismanagementState(mmRoleFlagGm),
                        (bool value) {
                          mmRoles.setMismanagementState(mmRoleFlagGm, value);
                        },
                      ),
                      getOption(
                        'Vice GM',
                        mmRoles.getMismanagementState(mmRoleFlagVgm),
                        (bool value) {
                          mmRoles.setMismanagementState(mmRoleFlagVgm, value);
                        },
                      ),
                      getOption(
                        'Religious Advisor',
                        mmRoles.getMismanagementState(mmRoleFlagRa),
                        (bool value) {
                          mmRoles.setMismanagementState(mmRoleFlagRa, value);
                        },
                      ),
                      getOption(
                        'Hash Cash',
                        mmRoles.getMismanagementState(mmRoleFlagHashCash),
                        (bool value) {
                          mmRoles.setMismanagementState(
                            mmRoleFlagHashCash,
                            value,
                          );
                        },
                      ),
                      getOption(
                        'Hare Raiser',
                        mmRoles.getMismanagementState(mmRoleFlagHareRaiser),
                        (bool value) {
                          mmRoles.setMismanagementState(
                            mmRoleFlagHareRaiser,
                            value,
                          );
                        },
                      ),
                      getOption(
                        'On Sec (Secretary)',
                        mmRoles.getMismanagementState(mmRoleFlagOnSec),
                        (bool value) {
                          mmRoles.setMismanagementState(mmRoleFlagOnSec, value);
                        },
                      ),
                      const Divider(
                        color: Colors.grey,
                        height: 3.0,
                        thickness: 2.0,
                      ),
                      const SizedBox(height: 10.0),

                      getOption(
                        'Banker Wanker',
                        mmRoles.getMismanagementState(mmRoleFlagHashBank),
                        (bool value) {
                          mmRoles.setMismanagementState(
                            mmRoleFlagHashBank,
                            value,
                          );
                        },
                      ),
                      getOption(
                        'Bash Master',
                        mmRoles.getMismanagementState(mmRoleFlagBashMaster),
                        (bool value) {
                          mmRoles.setMismanagementState(
                            mmRoleFlagBashMaster,
                            value,
                          );
                        },
                      ),
                      getOption(
                        'Bash Money Master',
                        mmRoles.getMismanagementState(mmRoleFlagBashMoney),
                        (bool value) {
                          mmRoles.setMismanagementState(
                            mmRoleFlagBashMoney,
                            value,
                          );
                        },
                      ),
                      getOption(
                        'Beer Meister',
                        mmRoles.getMismanagementState(mmRoleFlagBeerMeister),
                        (bool value) {
                          mmRoles.setMismanagementState(
                            mmRoleFlagBeerMeister,
                            value,
                          );
                        },
                      ),

                      getOption(
                        'Cunning Linguist (Translator)',
                        mmRoles.getMismanagementState(mmRoleFlagTranslator),
                        (bool value) {
                          mmRoles.setMismanagementState(
                            mmRoleFlagTranslator,
                            value,
                          );
                        },
                      ),

                      getOption(
                        'Hash Communications',
                        mmRoles.getMismanagementState(mmRoleFlagCommunications),
                        (bool value) {
                          mmRoles.setMismanagementState(
                            mmRoleFlagCommunications,
                            value,
                          );
                        },
                      ),
                      getOption(
                        'Down Down Master',
                        mmRoles.getMismanagementState(mmRoleFlagDownDownMaster),
                        (bool value) {
                          mmRoles.setMismanagementState(
                            mmRoleFlagDownDownMaster,
                            value,
                          );
                        },
                      ),
                      getOption(
                        'Event Meister',
                        mmRoles.getMismanagementState(mmRoleFlagEventMeister),
                        (bool value) {
                          mmRoles.setMismanagementState(
                            mmRoleFlagEventMeister,
                            value,
                          );
                        },
                      ),

                      getOption(
                        'Haberdasher',
                        mmRoles.getMismanagementState(mmRoleFlagHaberdasher),
                        (bool value) {
                          mmRoles.setMismanagementState(
                            mmRoleFlagHaberdasher,
                            value,
                          );
                        },
                      ),

                      getOption(
                        'Hash Flash',
                        mmRoles.getMismanagementState(mmRoleFlagHashFlash),
                        (bool value) {
                          mmRoles.setMismanagementState(
                            mmRoleFlagHashFlash,
                            value,
                          );
                        },
                      ),
                      getOption(
                        'Hash Harlot',
                        mmRoles.getMismanagementState(mmRoleFlagHashHo),
                        (bool value) {
                          mmRoles.setMismanagementState(
                            mmRoleFlagHashHo,
                            value,
                          );
                        },
                      ),

                      getOption(
                        'Hash Hugs',
                        mmRoles.getMismanagementState(mmRoleFlagHashHugs),
                        (bool value) {
                          mmRoles.setMismanagementState(
                            mmRoleFlagHashHugs,
                            value,
                          );
                        },
                      ),

                      getOption(
                        'Hash Sweep',
                        mmRoles.getMismanagementState(mmRoleFlagHashSweep),
                        (bool value) {
                          mmRoles.setMismanagementState(
                            mmRoleFlagHashSweep,
                            value,
                          );
                        },
                      ),
                      getOption(
                        'Hash Trash (newsletter)',
                        mmRoles.getMismanagementState(mmRoleFlagHashTrash),
                        (bool value) {
                          mmRoles.setMismanagementState(
                            mmRoleFlagHashTrash,
                            value,
                          );
                        },
                      ),
                      getOption(
                        'Scribe Master',
                        mmRoles.getMismanagementState(mmRoleFlagScribe),
                        (bool value) {
                          mmRoles.setMismanagementState(
                            mmRoleFlagScribe,
                            value,
                          );
                        },
                      ),

                      getOption(
                        'Social Media Whore',
                        mmRoles.getMismanagementState(
                          mmRoleFlagSocialMediaWhore,
                        ),
                        (bool value) {
                          mmRoles.setMismanagementState(
                            mmRoleFlagSocialMediaWhore,
                            value,
                          );
                        },
                      ),

                      getOption(
                        'Song Meister',
                        mmRoles.getMismanagementState(mmRoleFlagSongMeister),
                        (bool value) {
                          mmRoles.setMismanagementState(
                            mmRoleFlagSongMeister,
                            value,
                          );
                        },
                      ),

                      getOption(
                        'Trail Master',
                        mmRoles.getMismanagementState(mmRoleFlagTrailMaster),
                        (bool value) {
                          mmRoles.setMismanagementState(
                            mmRoleFlagTrailMaster,
                            value,
                          );
                        },
                      ),

                      getOption(
                        'Web Meister',
                        mmRoles.getMismanagementState(mmRoleFlagWebMeister),
                        (bool value) {
                          mmRoles.setMismanagementState(
                            mmRoleFlagWebMeister,
                            value,
                          );
                        },
                      ),

                      getOption(
                        '<Other not listed>',
                        mmRoles.getMismanagementState(mmRoleFlagOther),
                        (bool value) {
                          mmRoles.setMismanagementState(mmRoleFlagOther, value);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Container(
            height: 90.0,
            padding: const EdgeInsets.only(bottom: 20, top: 20),
            color: Colors.white,
            child: Align(
              child: Container(
                //height: 40.0,
                margin: const EdgeInsets.only(bottom: 10.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: hc_red),
                  onPressed: () {
                    // if mismanagementFlags = 1 that means this person has no role, so set all to zero, otherwise set the mmRoleIsOnMm flag
                    Navigator.of(context).pop(
                      ((mmRoles.mismanagementFlags ?? 0) & mmRoleAllFlags) <= 1
                          ? 0
                          : (mmRoles.mismanagementFlags ?? 0) | mmRoleIsOnMm,
                    );
                  },
                  child: Text('Save changes', style: ts_button),
                ),
              ),
            ),
          ),
        ],
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
                setState(() {
                  toggleState(value ?? false);
                });
              },
            ),
          ),
          Text(title, style: ts_headingBlack, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
