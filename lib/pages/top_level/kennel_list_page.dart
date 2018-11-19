import 'dart:async';
import 'package:flutter/material.dart';
import 'package:harrier_central/remote_api_data/kennel_scoped_model.dart';
import 'package:harrier_central/widgets/kennel_list_item.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:harrier_central/remote_api_data/main_navigation_scoped_model.dart';

class KennelsListPage extends StatelessWidget {
  final KennelScopedModel kennelModel;

  const KennelsListPage({Key key, @required this.kennelModel})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScopedModelDescendant<MainNavigationScopedModel>(builder:
        (BuildContext context, Widget child, MainNavigationScopedModel model) {
      model.appBarTitle = 'My Kennels';

      return ScopedModel<KennelScopedModel>(
          model: kennelModel, child: KennelsListPageBody());
    });
  }
}

class KennelsListPageBody extends StatelessWidget {
  BuildContext context;
  KennelScopedModel model;

  int pageIndex = 1;

  @override
  Widget build(BuildContext context) {
    this.context = context;

    return ScopedModelDescendant<KennelScopedModel>(
      builder: (BuildContext context, Widget child, KennelScopedModel model) {
        this.model = model;
        return model.isLoading
            ? _buildCircularProgressIndicator()
            : _buildListView();
      },
    );
  }

  Widget _buildCircularProgressIndicator() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Future<Null> _handleRefresh() async {
    model.getKennelsFromBackend(1, false);
    model.notifyListeners();

    return null;
  }

  Widget _buildListView() {
    return Padding(
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
                    height: 130.0,
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
