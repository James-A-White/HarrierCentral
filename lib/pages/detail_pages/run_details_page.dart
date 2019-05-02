import 'package:flutter/material.dart';

import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import 'package:harrier_central/data/models/planned_run_model.dart';
import 'package:harrier_central/widgets/run_tabs.dart';
import 'package:harrier_central/util/styles.dart';
import 'package:harrier_central/pages/run_admin/run_admin_main.dart';


class RunDetailsPage extends StatelessWidget { 
  const RunDetailsPage({Key key, @required this.futureRun}) : super(key: key);

  final PlannedRun futureRun;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          actions: <Widget>[
            !futureRun.hasMmPrivileges
                ? Container()
                : IconButton(
                    icon: const Icon(FontAwesome.gear, color: Colors.white),
                    onPressed: () {
                      Navigator.push<dynamic>(
                context,
                MaterialPageRoute<dynamic>(
                  builder: (BuildContext context) => RunAdminMainPage(
                        eventId: futureRun.eventId
                      ),
                ),
              );//_select(choices[0]);
                    },
                  ),
          ],
          centerTitle: true,
          backgroundColor: themeAppBarBackground,
          title: const Text(
            'Run Details',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ),
        body: RunTabs(futureRun: futureRun));
  }
}
