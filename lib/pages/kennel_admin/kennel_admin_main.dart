import 'package:flutter/material.dart';

import 'package:harrier_central/data_models/kennel_model.dart';
import 'package:harrier_central/widgets/kennel_logo.dart';
import 'package:harrier_central/pages/kennel_admin/kennel_members.dart';
import 'package:harrier_central/util/styles.dart';

class KennelAdminMainPage extends StatelessWidget {

  const KennelAdminMainPage({@required this.kennel});
  final Kennel kennel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: ThemeColors.appBarBackground,
        title: Text(
          '${kennel.kennelShortName} Admin',
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 30.0),
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
                  style: const TextStyle(color: Colors.white),
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
