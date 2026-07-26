//import 'dart:io' as platform;
import 'package:harrier_central/imports.dart';
import 'package:intl/intl.dart';

class HashRunArtGalleryPage extends StatelessWidget {
  const HashRunArtGalleryPage({super.key, required this.items});

  final List<Map<String, dynamic>> items;

  @override
  Widget build(BuildContext context) {
    final AppBar appBar = AppBar(
      centerTitle: true,
      backgroundColor: themeAppBarBackground,
      iconTheme: const IconThemeData(color: Colors.white, size: 28.0),
      title: Text('Run Artwork', style: ts_appBarTitle),
    );

    return AppScaffold(
      //key: ScaffoldKey,
      appBar: appBar,
      body: Container(
        decoration: Backgrounds.defaultHcBackground(),
        child: ListView.builder(
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
            if (item[tableModel.eventsTableHelper.colEventImage] == null) {
              return const SizedBox();
            }
            return Card(
              elevation: 4.0,
              margin: const EdgeInsets.symmetric(
                horizontal: 30.0,
                vertical: 10.0,
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: <Widget>[
                    GestureDetector(
                      onTap: () async {
                        final RunDetailsAggregate? run = await tableModel
                            .eventsService
                            .getSingleRun(
                              item[tableModel.eventsTableHelper.colEventId],
                            );
                        if (run != null) {
                          await Navigator.push<dynamic>(
                            navigatorKey.currentContext!,
                            MaterialPageRoute<dynamic>(
                              builder: (BuildContext context) =>
                                  RunDetailsPage(futureRun: run),
                            ),
                          );
                        }
                      },
                      onLongPress: () async {
                        await Navigator.push<void>(
                          context,
                          MaterialPageRoute<void>(
                            builder: (BuildContext context) =>
                                ZoomableImagePage2(
                                  key: const Key('50201112'),
                                  pageTitle: 'Zoomable Event Image',
                                  imageUrl:
                                      item[tableModel
                                          .eventsTableHelper
                                          .colEventImage],
                                  appBarBackgroundColor: themeAppBarBackground,
                                  background: Backgrounds.defaultHcBackground(),
                                ),
                          ),
                        );
                      },
                      child: Image.network(
                        item[tableModel.eventsTableHelper.colEventImage],
                        // Cap decode resolution — gallery art can be large.
                        cacheWidth: 900,
                        errorBuilder:
                            (
                              BuildContext context,
                              Object error,
                              StackTrace? stackTrace,
                            ) {
                              return Container();
                            },
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        item[tableModel.eventsTableHelper.colEventName] ?? '',
                        style: ts_titleLarge.copyWith(color: Colors.black),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    item[tableModel.eventsTableHelper.colEventStartDatetime] !=
                            null
                        ? Padding(
                            padding: const EdgeInsets.only(top: 15.0),
                            child: Text(
                              DateFormat("E, MMM d, yyyy 'at' h:mm a").format(
                                DateTime.tryParse(
                                  item[tableModel
                                          .eventsTableHelper
                                          .colEventStartDatetime]
                                      ?.toString() ??
                                      '',
                                ) ??
                                    DateTime.now(),
                              ),
                              style: ts_title.copyWith(
                                color: Colors.grey.shade500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : Container(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ${DateFormat('MMM dd, yyyy').format(kennelMember.dateOfLastRun)}'
