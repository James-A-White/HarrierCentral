import 'dart:async';

import 'package:flutter/material.dart';

import 'package:harrier_central/services/kennel_scoped_model.dart';
import 'package:harrier_central/widgets/kennel_list_item.dart';
import 'package:harrier_central/util/styles.dart';

import 'package:scoped_model/scoped_model.dart';

class KennelsListPage extends StatefulWidget {
  const KennelsListPage({Key key, @required this.kennelModel})
      : super(key: key);

  final KennelScopedModel kennelModel;

  @override
  KennelsListPageState createState() => KennelsListPageState(model: kennelModel);

}

class KennelsListPageState extends State<KennelsListPage> {
  
  KennelsListPageState({@required this.model});

  KennelScopedModel model;

  int pageIndex = 1;

  @override
  Widget build(BuildContext context) {

    return ScopedModel<KennelScopedModel>(
      model: model,
      child: Scaffold(
        body: ScopedModelDescendant<KennelScopedModel>(
          builder:
              (BuildContext context, Widget child, KennelScopedModel model) {

    if ((model.kennelsList.isEmpty) &&
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
      decoration: Backgrounds.defaultHcBackground(),
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
                    height: 150.0,
                    padding: const EdgeInsets.all(0.0),
                    child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: <Widget>[
                          KennelsListItem(kennel: model.kennelsList[index]),
                        ]),
                  );
                },
              ),
            ),
    );
  }
}
