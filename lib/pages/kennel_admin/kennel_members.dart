import 'dart:async';

import 'package:flutter/material.dart';

import 'package:scoped_model/scoped_model.dart';

import 'package:harrier_central/services/kennel_member_scoped_model.dart';
import 'package:harrier_central/pages/kennel_admin/add_member_page.dart';
import 'package:harrier_central/widgets/kennel_member_list_item.dart';
import 'package:harrier_central/data_models/kennel_model.dart';
import 'package:harrier_central/util/styles.dart';

class KennelMembersList extends StatelessWidget {
  KennelMembersList({Key key, @required this.kennel}) : super(key: key);

  final Kennel kennel;

  final KennelMemberScopedModel kennelMemberModel = KennelMemberScopedModel();

  @override
  Widget build(BuildContext context) {
    if ((kennelMemberModel?.kennelMembersList?.length ?? 0) == 0) {
      kennelMemberModel.getKennelMembersFromBackend(1, true, kennel.kennelId);
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: ThemeColors.appBarBackground,
        title: Text(
          '${kennel.kennelShortName} Members',
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: ScopedModel<KennelMemberScopedModel>(
          model: kennelMemberModel,
          child: KennelMembersListPageBody(
            kennelId: kennel.kennelId,
          )),
    );
  }
}

class KennelMembersListPageBody extends StatelessWidget {
  KennelMembersListPageBody({Key key, @required this.kennelId})
      : super(key: key);

  final String kennelId;

  BuildContext context;
  KennelMemberScopedModel model;

  int pageIndex = 1;

  @override
  Widget build(BuildContext context) {
    this.context = context;

    return ScopedModelDescendant<KennelMemberScopedModel>(
      builder:
          (BuildContext context, Widget child, KennelMemberScopedModel model) {
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
    model.getKennelMembersFromBackend(1, false, kennelId);
    model.notifyListeners();

    return null;
  }

  Widget _buildListView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: model.getKennelMembersListCount() == 0
                ? const Center(child: Text('No Kennels available.'))
                : RefreshIndicator(
                    onRefresh: () => _handleRefresh(),
                    displacement: 40.0,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: model.getKennelMembersListCount(),
                      itemBuilder: (BuildContext context, int index) {
                        return Container(
                          height: 85.0,
                          padding: const EdgeInsets.all(0.0),
                          child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: <Widget>[
                                KennelMemberListItem(
                                    kennelMember:
                                        model.kennelMembersList[index]),
                              ]),
                        );
                      },
                    ),
                  ),
          ),
        ),
        Container(
          width: 150.0,
          child: RaisedButton(
            child: const Text(
              'Add Member',
              style: const TextStyle(color: Colors.white),
            ),
            onPressed: () {
              Navigator.push<dynamic>(
                context,
                MaterialPageRoute<dynamic>(
                  builder: (BuildContext context) => AddMemberPage(
                        kennelId: kennelId,
                      ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
