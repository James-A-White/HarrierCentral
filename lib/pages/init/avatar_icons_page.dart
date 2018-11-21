import 'package:flutter/material.dart';

class AvatarIconsPage extends StatefulWidget {
  const AvatarIconsPage({Key key}) : super(key: key);

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
  num imagePadding = 20.0;

  Widget _buildListView() {
    return Material(
      child: Padding(
        padding: const EdgeInsets.only(top: 20.0),
        child: ListView(
            scrollDirection: Axis.vertical,
            padding: EdgeInsets.only(top: 90.0),
            children: <Widget>[
              // Container(color:Colors.red, width:30.0,height:60.0),
              //         Container(color:Colors.blue, width:30.0,height:60.0),
              //                 Container(color:Colors.green, width:30.0,height:60.0),
              MaterialButton(
                  child: Padding(
                    padding: EdgeInsets.all(imagePadding),
                    child: Image.asset(
                      'images/avatars/avatar-1.png',
                      height: iconSize,
                      width: iconSize,
                    ),
                  ),
                  splashColor: Colors.greenAccent,
                  onPressed: () {
                    Navigator.of(context).pop(1);
                  }),
              MaterialButton(
                  child: Padding(
                    padding: EdgeInsets.all(imagePadding),
                    child: Image.asset(
                      'images/avatars/avatar-2.png',
                      height: iconSize,
                      width: iconSize,
                    ),
                  ),
                  splashColor: Colors.greenAccent,
                  onPressed: () {
                    Navigator.of(context).pop(2);
                  }),
              MaterialButton(
                  child: Padding(
                    padding: EdgeInsets.all(imagePadding),
                    child: Image.asset(
                      'images/avatars/avatar-3.png',
                      height: iconSize,
                      width: iconSize,
                    ),
                  ),
                  splashColor: Colors.greenAccent,
                  onPressed: () {
                    Navigator.of(context).pop(3);
                  }),
              MaterialButton(
                  child: Padding(
                    padding: EdgeInsets.all(imagePadding),
                    child: Image.asset(
                      'images/avatars/avatar-4.png',
                      height: iconSize,
                      width: iconSize,
                    ),
                  ),
                  splashColor: Colors.greenAccent,
                  onPressed: () {
                    Navigator.of(context).pop(4);
                  }),
            ]),
      ),
    );
  }
}
