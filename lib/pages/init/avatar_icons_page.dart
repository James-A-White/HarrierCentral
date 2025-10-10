import 'package:harrier_central/imports.dart';

class AvatarIconsPage extends StatefulWidget {
  const AvatarIconsPage({super.key, this.selectedAvatarIcon});

  final int? selectedAvatarIcon;

  @override
  State<AvatarIconsPage> createState() => _AvatarIconsPageState();
}

class _AvatarIconsPageState extends State<AvatarIconsPage> {
  final GlobalKey<ScaffoldState> _ScaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return _buildListView();
  }

  double iconSize = 100.0;
  double imagePadding = 8.0;

  Widget _buildListView() {
    return AppScaffold(
      key: _ScaffoldKey,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: themeAppBarBackground,
        iconTheme: const IconThemeData(color: Colors.white, size: 28.0),
        title: Text('Choose Avatar', style: ts_appBarTitle),
      ),
      body: Material(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Padding(
          padding: const EdgeInsets.only(top: 20.0),
          child: GridView.builder(
            scrollDirection: Axis.vertical,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount:
                  (MediaQuery.of(context).orientation == Orientation.portrait)
                  ? 3
                  : 4,
            ),
            padding: const EdgeInsets.only(top: 10.0),
            itemCount: 50,
            itemBuilder: (BuildContext bldCtx, int index) {
              return MaterialButton(
                splashColor: Colors.greenAccent,
                onPressed: () {
                  Navigator.of(context).pop(index + 1);
                },
                child: Container(
                  color: (widget.selectedAvatarIcon ?? 0) == index + 1
                      ? hc_red
                      : Theme.of(context).scaffoldBackgroundColor,
                  child: Padding(
                    padding: EdgeInsets.all(imagePadding),
                    child: Image.asset(
                      'images/avatars/avatar-${index + 1}.jpg',
                      height: iconSize,
                      width: iconSize,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
