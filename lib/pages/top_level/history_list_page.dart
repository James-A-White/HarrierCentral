import 'dart:async';

import 'package:flutter/material.dart';


import 'package:harrier_central/services/kennel_run_history_totals_scoped_model.dart';
import 'package:harrier_central/widgets/kennel_run_history_count_list_item.dart';
import 'package:harrier_central/util/styles.dart';

import 'package:scoped_model/scoped_model.dart';

class HistoryListPage extends StatefulWidget {
  const HistoryListPage({Key key, @required this.kennelRunCountHistoryModel})
      : super(key: key);

  final KennelRunHistoryTotalsScopedModel kennelRunCountHistoryModel;

  @override
  HistoryListPageState createState() => HistoryListPageState(model: kennelRunCountHistoryModel);

}

class HistoryListPageState extends State<HistoryListPage> {
  
  HistoryListPageState({@required this.model});

  KennelRunHistoryTotalsScopedModel model;

  int pageIndex = 1;

  @override
  Widget build(BuildContext context) {

    return ScopedModel<KennelRunHistoryTotalsScopedModel>(
      model: model,
      child: Scaffold(
        body: ScopedModelDescendant<KennelRunHistoryTotalsScopedModel>(
          builder:
              (BuildContext context, Widget child, KennelRunHistoryTotalsScopedModel model) {

    if ((model.kennelRunCountList.isEmpty) &&
        (!model.isLoading)) {   // TODO(James): Check this statement and make sure the cast to FALSE is correct
      model.getKennelsFromBackend(true);}

            return model.isLoading
                ? _buildCircularProgressIndicator()
                : _buildListView();
          },
        ),
      ),
    );
  }

  Widget _buildCircularProgressIndicator() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Future<void> _handleRefresh() async {
    model.clearKennelList();
    model.getKennelsFromBackend(false);
    //model.notifyListeners();
  }

  Widget _buildListView() {
    return Container(
      decoration: Backgrounds.defaultHcBackgroundLight(),
      padding: const EdgeInsets.only(top: 0.0),
      child: model.getKennelsCount() == 0
          ? const Center(child: Text('No Kennels available.'))
          : RefreshIndicator(
              onRefresh: () => _handleRefresh(),
              displacement: 40.0,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: model.getKennelsCount(),
                itemBuilder: (BuildContext context, int index) {
                  return Container(
                    height: 140.0,
                    padding: const EdgeInsets.all(0.0),
                    child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: <Widget>[
                          KennelRunHistoryCountListItem(kennelRunHistoryCount: model.kennelRunCountList[index]),
                        ]),
                  );
                },
              ),
            ),
    );
  }
}
