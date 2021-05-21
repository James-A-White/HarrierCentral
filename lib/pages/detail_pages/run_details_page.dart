import 'package:flutter/material.dart';

import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import 'package:harrier_central/widgets/run_tabs.dart';
import 'package:harrier_central/util/styles.dart';
import 'package:harrier_central/pages/run_admin/run_admin_main.dart';
import 'package:harrier_central/database/query_runs.dart';

class RunDetailsPage extends StatelessWidget {
  const RunDetailsPage({Key key, @required this.futureRun}) : super(key: key);

  final RunDetailsAggregate futureRun;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          actions: <Widget>[
            (futureRun.extensions.mismanagementRoleFlags ?? 0) == 0
                ? Container()
                : IconButton(
                    icon: const Icon(FontAwesome.gear, color: Colors.white),
                    onPressed: () {
                      Navigator.push<dynamic>(
                        context,
                        MaterialPageRoute<dynamic>(
                          builder: (BuildContext context) =>
                              RunDetailPage(eventId: futureRun.event.eventId),
                        ),
                      ); //_select(choices[0]);
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
