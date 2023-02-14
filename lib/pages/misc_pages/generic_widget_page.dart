// @dart=2.11

//import 'dart:io' as platform;
import 'package:harrier_central/imports.dart';

class GenericWidgetPage extends StatelessWidget {
  const GenericWidgetPage({Key key, this.widget, this.appBarTitle}) : super(key: key);

  final Widget widget;
  final String appBarTitle;

  @override
  Widget build(BuildContext context) {
    final AppBar appBar = AppBar(
      centerTitle: true,
      backgroundColor: themeAppBarBackground,
      title: Text(
        appBarTitle,
        style: const TextStyle(
          color: Colors.white,
        ),
      ),
    );

    return Scaffold(
      //key: scaffoldKey,
      appBar: appBar,
      body: Container(decoration: Backgrounds.defaultHcBackground(), child: widget),
    );
  }
}


// ${DateFormat('MMM dd, yyyy').format(kennelMember.dateOfLastRun)}'
