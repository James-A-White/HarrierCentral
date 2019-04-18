import 'dart:async';

import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter/material.dart';

import 'package:harrier_central/services/future_run_scoped_model.dart';
import 'package:harrier_central/widgets/run_list_item.dart';
import 'package:harrier_central/util/styles.dart';

import 'package:scoped_model/scoped_model.dart';
//

class FutureRunsListPage extends StatefulWidget {
  const FutureRunsListPage({Key key}) : super(key: key);

  @override
  FutureRunListPageState createState() => FutureRunListPageState();
}

class FutureRunListPageState extends State<FutureRunsListPage> {
  // BuildContext context;
  FutureRunScopedModel model;

  int pageIndex = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: ScopedModelDescendant<FutureRunScopedModel>(
      builder:
          (BuildContext context, Widget child, FutureRunScopedModel model) {
        this.model = model;

        if ((model.futureRunsList.isEmpty) && (!model.isLoading)) {
          model.getFutureRunsFromBackend(true);
        }

        return model.isLoading
            ? _buildCircularProgressIndicator()
            : _buildListView();
      },
    ));
  }

  Widget _buildCircularProgressIndicator() {
    return Center(
      child: SpinKitCircle(
        size: 75.0,
        itemBuilder: (_, int index) {
          return DecoratedBox(
            decoration: BoxDecoration(
              color: index.isEven
                  ? Colors.grey[400]
                  : Theme.of(context).accentColor,
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleRefresh() async {
    model.getFutureRunsFromBackend(true);
    // model.notifyListeners();
  }

  Widget _buildListView() {
    return Container(
      decoration: Backgrounds.defaultHcBackground(),
      child: model.getFutureRunsCount() == 0
          ? const Center(child: Text('No Runs available.'))
          : RefreshIndicator(
              onRefresh: () => _handleRefresh(),
              displacement: 40.0,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                //padding: const EdgeInsets.only( bottom: 40.0),
                itemCount: model.getFutureRunsCount(),
                itemBuilder: (BuildContext context, int index) {
                  if ((model.futureRunsList[index].daysUntilNextRun < 9999) &&
                      (model.futureRunsList[index].isVisible != 0)) {
                    return RunListItem(futureRun: model.futureRunsList[index]);
                  } else {
                    return Container();
                  }
                },
              ),
            ),
    );
  }
}
