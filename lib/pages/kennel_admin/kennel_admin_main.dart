import 'package:flutter/material.dart';

import 'package:harrier_central/data_models/kennel_model.dart';
import 'package:harrier_central/widgets/kennel_logo.dart';
import 'package:harrier_central/pages/kennel_admin/kennel_members.dart';

class KennelAdminMainPage extends StatelessWidget {
  KennelAdminMainPage({@required this.kennel});

  Kennel kennel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        title: Text(
          '${kennel.kennelShortName} Admin',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.only(top: 30.0),
        child: Column(
          children: <Widget>[
            Align(
              alignment: Alignment.topCenter,
              child: KennelLogo(
                kennelLogoUrl: kennel.kennelLogo,
                kennelShortName: kennel.kennelShortName,
                logoHeight: 200.0,
                leftPadding: 0.0,
              ),
            ),
            Container(
              width: 150.0,
              child: RaisedButton(
                child: const Text(
                  'Members',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  Navigator.push<dynamic>(
                    context,
                    MaterialPageRoute<dynamic>(
                      builder: (context) => KennelMembersList(
                            kennel: kennel
                          ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
