import 'package:flutter/material.dart';
import 'package:harrier_central/data_models/kennel_model.dart';
import 'package:harrier_central/widgets/kennel_logo.dart';

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
      body: 
                                Padding(
                                  padding: EdgeInsets.only(top:30.0),
                                  child: Align(
                                  alignment: Alignment.topCenter,
                                  child: KennelLogo(
                            kennelLogoUrl: kennel.kennelLogo,
                            kennelShortName: kennel.kennelShortName,
                            logoHeight: 200.0,
                            leftPadding: 0.0,
                          ),),)
      
      
    );
  }
}
