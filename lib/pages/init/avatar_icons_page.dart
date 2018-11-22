import 'package:flutter/material.dart';

class AvatarIconsPage extends StatefulWidget {
  int selectedAvatarIcon;
  AvatarIconsPage({Key key, this.selectedAvatarIcon}) : super(key: key);

  @override
  State<AvatarIconsPage> createState() => _AvatarIconsPageState();
}

class _AvatarIconsPageState extends State<AvatarIconsPage> {
  int pageIndex = 1;

  @override
  Widget build(BuildContext context) {
    return _buildListView();
  }

  num iconSize = 100.0;
  num imagePadding = 8.0;

  Widget _buildListView() {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.only(top: 20.0),
        child: GridView.builder(
          scrollDirection: Axis.vertical,
          gridDelegate: new SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount:
                  (MediaQuery.of(context).orientation == Orientation.portrait)
                      ? 2
                      : 3),
          padding: EdgeInsets.only(top: 10.0),
          itemCount: 4,
          itemBuilder: (BuildContext bldCtx, int index) {
            return MaterialButton(
                child: Container(
                  color: widget.selectedAvatarIcon == index + 1
                      ? Theme.of(context).accentColor
                      : Theme.of(context).scaffoldBackgroundColor,
                  child: Padding(
                    padding: EdgeInsets.all(imagePadding),
                    child: Image.asset(
                      'images/avatars/avatar-${index + 1}.png',
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
    );
  }
}
