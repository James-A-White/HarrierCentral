//import 'dart:io' as platform;
import 'package:harrier_central/imports.dart';

class GenericWidgetPage extends StatelessWidget {
  const GenericWidgetPage({
    super.key,
    required this.widget,
    required this.appBarTitle,
  });

  final Widget widget;
  final String appBarTitle;

  @override
  Widget build(BuildContext context) {
    final AppBar appBar = AppBar(
      centerTitle: true,
      backgroundColor: themeAppBarBackground,
      iconTheme: const IconThemeData(
        color: Colors.white,
        size: 28.0,
      ),
      title: Text(appBarTitle, style: ts_appBarTitle),
    );

    return Scaffold(
      //key: scaffoldKey,
      appBar: appBar,
      body: Container(decoration: Backgrounds.defaultHcBackground(), child: widget),
    );
  }
}
