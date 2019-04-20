import 'package:flutter/material.dart';

import 'package:harrier_central/data/models/planned_run_model.dart';
import 'package:harrier_central/widgets/run_tabs.dart';
import 'package:harrier_central/util/styles.dart';

class RunDetailsPage extends StatelessWidget {
  const RunDetailsPage({Key key, @required this.futureRun}) : super(key: key);

  final PlannedRun futureRun;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        //key: homePageModel.mainAppScaffoldKey,
        appBar: AppBar(
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
