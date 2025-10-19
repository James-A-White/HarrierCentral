import 'package:harrier_central/imports.dart';
import 'dart:math' as math;
import 'package:share_plus/share_plus.dart';

class QrGroup extends StatelessWidget {
  const QrGroup({
    super.key,
    required this.context,
    required this.title,
    required this.description,
    required this.url,
    required this.helpTitle,
    required this.helpText,
  });

  final String title;
  final String description;
  final String url;
  final BuildContext context;
  final String helpTitle;
  final String helpText;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title, style: ts_title),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Column(
              children: [
                GestureDetector(
                  onTap: () async {
                    await Utilities.showAlert(helpTitle, helpText, 'OK');
                  },
                  child: SizedBox(
                    height: 35,
                    child: Image.asset('images/icons/info_button.png'),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: 50,
                  child: GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: url));

                      Utilities.showAlert(
                        'Link copied',
                        'A link to $description has been copied to your clipboard',
                        'OK',
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 0.0),
                      child: const Icon(
                        FontAwesome.copy,
                        color: Colors.white,
                        size: 36.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(width: 25),
            GestureDetector(
              onTap: () async {
                await Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) => ZoomableImagePage2(
                      key: const Key('39392001'),
                      pageTitle: title,
                      qrCode: url,
                      qrColor: Colors.white,
                      appBarBackgroundColor: themeAppBarBackground,
                      background: Backgrounds.defaultHcBackground(),
                      margin: 20.0,
                    ),
                  ),
                );
              },
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(10),
                child: QrImageView(
                  data: url,
                  version: QrVersions.auto,
                  size: math.min(160, MediaQuery.of(context).size.width / 2),
                ),
              ),
            ),
            SizedBox(width: 25),
            SizedBox(
              width: 50,

              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      SharePlus.instance.share(ShareParams(text: url));
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(left: 0.0),
                      child: Platform.isAndroid
                          ? const Icon(
                              MaterialIcons.share,
                              color: Colors.white,
                              size: 36.0,
                            )
                          : const Icon(
                              MaterialIcons.ios_share,
                              color: Colors.white,
                              size: 36.0,
                            ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  GestureDetector(
                    onTap: () {
                      if (Connection2.checkForConnection(
                        appModel.connectionStatus,
                      )) {
                        launchUrl(
                          Uri.parse(url),
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(left: 0.0),
                      child: const Icon(
                        SimpleLineIcons.globe,
                        color: Colors.white,
                        size: 36.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        //const SizedBox(height: 40),
      ],
    );
  }
}
