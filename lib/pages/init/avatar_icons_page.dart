import 'package:harrier_central/imports.dart';

class AvatarIconsPage extends StatefulWidget {
  const AvatarIconsPage({Key key, this.selectedAvatarIcon}) : super(key: key);

  final int selectedAvatarIcon;

  @override
  State<AvatarIconsPage> createState() => _AvatarIconsPageState();
}

class _AvatarIconsPageState extends State<AvatarIconsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return _buildListView();
  }

  num iconSize = 100.0;
  num imagePadding = 8.0;

  Widget _buildListView() {
    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: themeAppBarBackground,
          title: const Text(
            'Choose Avatar',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ),
        body: Material(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: GridView.builder(
              scrollDirection: Axis.vertical,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: (MediaQuery.of(context).orientation == Orientation.portrait) ? 3 : 4),
              padding: const EdgeInsets.only(top: 10.0),
              itemCount: 50,
              itemBuilder: (BuildContext bldCtx, int index) {
                return MaterialButton(
                    child: Container(
                      color: widget.selectedAvatarIcon == index + 1 ? Theme.of(context).accentColor : Theme.of(context).scaffoldBackgroundColor,
                      child: Padding(
                        padding: EdgeInsets.all(imagePadding),
                        child: Image.asset(
                          'images/avatars/avatar-${index + 1}.jpg',
                          height: iconSize,
                          width: iconSize,
                        ),
                      ),
                    ),
                    splashColor: Colors.greenAccent,
                    onPressed: () {
                      Navigator.of(context).pop(index + 1);
                    });
              },
            ),
          ),
        ));
  }
}
