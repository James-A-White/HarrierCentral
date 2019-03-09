import 'dart:async';

import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter/material.dart';

import 'package:harrier_central/remote_api_data/future_run_scoped_model.dart';
import 'package:harrier_central/remote_api_data/main_navigation_scoped_model.dart';
import 'package:harrier_central/widgets/run_list_item.dart';

import 'package:scoped_model/scoped_model.dart';
//

class FutureRunsListPage extends StatelessWidget {
  //final FutureRunScopedModel futureRunsModel;

  const FutureRunsListPage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return 
    
    // ScopedModelDescendant<MainNavigationScopedModel>(builder:
    //     (BuildContext context, Widget child, MainNavigationScopedModel model) {
    //   model.appBarTitle = 'Upcoming Runs';

       ScopedModelDescendant<FutureRunScopedModel>(builder:
          (BuildContext context, Widget child,
              FutureRunScopedModel futureRunsScopedModel) {
        if (!futureRunsScopedModel.isLoading) {
          futureRunsScopedModel.getFutureRunsFromBackend(false);
        }

        return FutureRunListPageBody();
        // return ScopedModel<FutureRunScopedModel>(
        //     model: futureRunsModel, child: FutureRunListPageBody());
      });
   // });
  }
}

class FutureRunListPageBody extends StatelessWidget {
  BuildContext context;
  FutureRunScopedModel model;

  int pageIndex = 1;

  @override
  Widget build(BuildContext context) {
    this.context = context;

    return Scaffold(
        //key: homePageModel.mainAppScaffoldKey,
        // appBar: AppBar(
        //   centerTitle: true,
        //   backgroundColor: Theme.of(context).primaryColor,
        //   title: Text(
        //     'Upcoming Runs List',
        //     style: TextStyle(
        //       color: Colors.white,
        //     ),
        //   ),
        // ),
        body: ScopedModelDescendant<FutureRunScopedModel>(
          builder:
              (BuildContext context, Widget child, FutureRunScopedModel model) {
            this.model = model;
            return model.isLoading
                ? _buildCircularProgressIndicator()
                : _buildListView();
          },
        ));
  }

  Widget _buildCircularProgressIndicator() {
    return Center(
      child: SpinKitFadingCircle(
        itemBuilder: (_, int index) {
          return DecoratedBox(
            decoration: BoxDecoration(
              color: index.isEven ? Colors.red : Colors.green,
            ),
          );
        },
      ),
    );
  }

  Future<Null> _handleRefresh() async {
    model.getFutureRunsFromBackend(true);
    model.notifyListeners();

    return null;
  }

  Widget _buildListView() {
    return Padding(
        padding: const EdgeInsets.only(top: 0.0),
        child: model.getFutureRunsCount() == 0
            ? const Center(child: Text('No Runs available.'))
            : RefreshIndicator(
                onRefresh: () => _handleRefresh(),
                displacement: 40.0,
                child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.only(top: 40.0, bottom: 40.0),
                    itemCount: model.getFutureRunsCount(),
                    itemBuilder: (BuildContext context, int index) {
                      if (model.futureRunsList[index].daysUntilNextRun < 9999) {
                        return RunListItem(
                            futureRun: model.futureRunsList[index]);
                      }
                    })));
  }
}
