// @dart=2.11

//import 'dart:io' as platform;
import 'package:harrier_central/imports.dart';

class HashRunArtGalleryPage extends StatelessWidget {
  const HashRunArtGalleryPage({Key key, this.items}) : super(key: key);

  final List<Map<String, dynamic>> items;

  @override
  Widget build(BuildContext context) {
    final AppBar appBar = AppBar(
      centerTitle: true,
      backgroundColor: themeAppBarBackground,
      title: const Text(
        'Run artwork',
        style: TextStyle(
          color: Colors.white,
        ),
      ),
    );

    return Scaffold(
      //key: scaffoldKey,
      appBar: appBar,
      body: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: items.length,
        padding: const EdgeInsets.only(top: 5),
        // separatorBuilder: (BuildContext context, int index) => const Divider(
        //   height: 1.0,
        //   color: Colors.black45,
        // ),
        //itemExtent: 58.0,
        //shrinkWrap: true,
        itemBuilder: (BuildContext context, int index) {
          final Map<String, dynamic> item = items[index];
          if (item['eventImage'] == null) {
            return const SizedBox();
          }
          return Card(
            elevation: 4.0,
            margin: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 10.0),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: <Widget>[
                  GestureDetector(
                    onTap: () {
                      Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(
                          builder: (BuildContext context) => ZoomableImagePage2(
                            key: const Key('50201112'),
                            pageTitle: 'Zoomable Event Image',
                            imageUrl: item['eventImage'],
                            appBarBackgroundColor: themeAppBarBackground,
                            background: Backgrounds.defaultHcBackground(),
                          ),
                        ),
                      );
                    },
                    child: Image.network(
                      item['eventImage'],
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  Text(item['eventName'] ?? '', style: titleStyle.copyWith(color: Colors.black), textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
