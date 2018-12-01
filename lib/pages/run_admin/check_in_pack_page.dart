
import 'dart:core';

import 'package:cached_network_image/cached_network_image.dart';

import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:harrier_central/data_models/future_run_model.dart';
import 'package:harrier_central/data_models/get_users_by_event_model.dart';
import 'package:harrier_central/remote_api_data/get_users_by_event_service.dart';

class CheckInPackPage extends StatefulWidget {
  CheckInPackPage({
    @required this.futureRun,
  });

  FutureRun futureRun;

  @override
  State<CheckInPackPage> createState() {
    return CheckInPackPageState();
  }
}

class CheckInPackPageState extends State<CheckInPackPage> {
  GetUsersByEvent _getPackService = GetUsersByEvent();

  bool _loadingPack = false;

  GlobalKey packListBox = GlobalKey();

  List<GetUsersByEventModel> packList;

  Future<Null> _getPackWithRefresh() async {
    _getPackService
        .getUsersByEvent(
            widget.futureRun.eventId, '00000000-0000-0000-0000-000000000000')
        .then((List<GetUsersByEventModel> _thePack) {
      packList = _thePack;
      setState(() {});
    });

    setState(() {});

    return null;
  }

  void getPack(bool forceRefresh) {
    if ((packList == null) || forceRefresh) {
      _getPackService
          .getUsersByEvent(
              widget.futureRun.eventId, '00000000-0000-0000-0000-000000000000')
          .then((List<GetUsersByEventModel> _thePack) {
        packList = _thePack;
        setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    getPack(false);
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        title: Text(
          '${widget.futureRun.eventName} Check In',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: Container(
        key: packListBox,
        margin: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 15.0),
        padding: const EdgeInsets.all(8.0),
        decoration: new BoxDecoration(
            border: new Border.all(color: Theme.of(context).accentColor)),
        child: Scrollbar(
          child: RefreshIndicator(
            onRefresh: _getPackWithRefresh,
            child: ClipRect(
              clipBehavior: Clip.antiAlias,
              clipper: packListBox.currentContext == null
                  ? null
                  : RectClipper(
                      width: packListBox.currentContext
                          .findRenderObject()
                          .paintBounds
                          .width,
                      height: packListBox.currentContext
                          .findRenderObject()
                          .paintBounds
                          .height),
              child: StaggeredGridView.countBuilder(
                crossAxisCount: 3,
                itemCount: packList?.length ?? 0,
                itemBuilder: (BuildContext context, int index) {
                  // if (packList[index].hasherId ==
                  //     userId) {
                  //   packList[index].userStatus =
                  //       widget.futureRun.rsvpState;

                  //   if (widget.futureRun.rsvpState ==
                  //       4) {
                  //     packList[index].isHare = 1;
                  //   } else {
                  //     packList[index].isHare = 0;
                  //   }
                  // }

                  return packList.isEmpty
                      ? new Container(
                          color: Colors.grey[300],
                          width: 70.0,
                          height: 70.0,
                          child: new Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: new Center(
                                  child: new CircularProgressIndicator())),
                        )
                      : GestureDetector(
                          onTap: () {
                            String actionText = '';

                            if (packList[index].isHare == 1) {
                              actionText = ' will hare the Hash';
                            } else {
                              switch (packList[index].userStatus) {
                                case 1:
                                  actionText = ' will not join the Hash';
                                  break;
                                case 2:
                                  actionText = ' might join the Hash';
                                  break;
                                case 3:
                                case 4:
                                case 5:
                                case 6:
                                  actionText = ' will join the Hash';
                                  break;
                                case 0:
                                default:
                                  break;
                              }
                            }
                            ;

                            final snackBar = SnackBar(
                              duration: Duration(seconds: 2),
                              content: Text(
                                packList[index].displayName + actionText,
                                style: const TextStyle(
                                    fontFamily: 'AvenirNextCondensedDemiBold',
                                    fontStyle: FontStyle.normal,
                                    fontSize: 20.0,
                                    height: 0.85),
                              ),
                              backgroundColor: Theme.of(context).accentColor,
                            );

                            Scaffold.of(context).showSnackBar(snackBar);
                          },
                          child: Stack(
                            children: <Widget>[
                              packList[index].photo.startsWith('http')
                                  ? CachedNetworkImage(
                                      imageUrl: packList[index].photo,
                                      placeholder:
                                          const CircularProgressIndicator(),
                                      errorWidget: const Icon(Icons.error),
                                      //fadeOutDuration:  Duration(seconds: 1),
                                      fadeInDuration: Duration(milliseconds: 0),
                                      width: 300.0,
                                      height: 300.0,
                                      fit: BoxFit.fill)
                                  : packList[index].photo.startsWith('bundle')
                                      ? Image(
                                          width: 300.0,
                                          height: 300.0,
                                          fit: BoxFit.fill,
                                          image: AssetImage('images/avatars/' +
                                              packList[index]
                                                  .photo
                                                  .toLowerCase()
                                                  .replaceFirst(
                                                      'bundle://', '') +
                                              '.png'),
                                        )
                                      : Image(
                                          width: 300.0,
                                          height: 300.0,
                                          fit: BoxFit.fill,
                                          image: AssetImage(
                                              'images/avatars/avatar-2.png'),
                                        ),
                              Positioned(
                                right: 1.0,
                                bottom: 1.0,
                                child: CircleAvatar(
                                  backgroundColor: Colors.white,
                                  radius: 12.0,
                                ),
                              ),
                              Positioned(
                                right: 3.0,
                                bottom: packList[index].userStatus <= 0
                                    ? 2.5
                                    : packList[index].isHare == 1 ? 3.0 : 3.5,
                                child: packList[index].userStatus <= 0
                                    ? CircleAvatar(
                                        backgroundColor: Colors.blue,
                                        radius: 10.0,
                                      )
                                    : packList[index].userStatus == 1
                                        ? Icon(
                                            FontAwesomeIcons.solidTimesCircle,
                                            color: Colors.red,
                                            size: 20.0)
                                        : packList[index].userStatus == 2
                                            ? Icon(
                                                FontAwesomeIcons
                                                    .solidQuestionCircle,
                                                color: Colors.orange,
                                                size: 20.0)
                                            : packList[index].isHare == 0
                                                ? Icon(
                                                    FontAwesomeIcons
                                                        .solidCheckCircle,
                                                    color: Colors.green,
                                                    size: 20.0)
                                                : Image.asset(
                                                    'images/icons/hare_icon.png',
                                                    color: Colors.deepPurple,
                                                    height: 20.0,
                                                    width: 20.0),

                                // AssetImage(
                                //     'images/icons/hare_icon.png'),
                              ),
                            ],
                          ),
                        ); //TODO: Replace this with another avatar for missing image
                },
                staggeredTileBuilder: (int index) {
                  return packList[index].isHare == 0
                      ? new StaggeredTile.count(1, 1)
                      : new StaggeredTile.count(2, 2);
                },
                mainAxisSpacing: 8.0,
                crossAxisSpacing: 8.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RectClipper extends CustomClipper<Rect> {
  RectClipper({@required this.width, @required this.height});

  double width;
  double height;

  @override
  Rect getClip(Size size) {
    Rect r = const Offset(0.0, 0.0) & Size(width, height - 33);

    // This is where we decide what part of our image is going to be
    // visible. If you try to run the app now, nothing will be shown.
    return r;
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) => false;
}
