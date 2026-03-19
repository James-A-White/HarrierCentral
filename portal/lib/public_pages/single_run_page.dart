import 'package:hcportal/admin_pages/run_list_page_controller.dart';
import 'package:hcportal/imports.dart';

class SingleRunPageController extends GetxController {
  SingleRunPageController({
    required this.textTheme,
    required this.publicEventId,
    this.backgroundColor,
    this.backButtonUrl,
  });

  final String textTheme;
  final String publicEventId;
  final String? backgroundColor;
  final String? backButtonUrl;

  RunDetailsModel? rdm;
  List<ParticipantModel> participants = [];
  bool? isNarrowScreen;
  final UniqueKey pageKey = UniqueKey();
  bool textThemeIsLight = true;
  bool isLoaded = false;

  @override
  void onInit() {
    super.onInit();
    unawaited(_init());
  }

  Future<void> _init() async {
    final edr = await _getEvent(publicEventId);
    rdm = edr?.runDetails;
    participants = edr?.participants ?? [];
    textThemeIsLight = textTheme.toLowerCase().contains('light');
    isLoaded = true;
    update();
  }

  DateTime getTodayAsDateOnly() {
    final dt = DateTime.now();
    return DateTime(dt.year, dt.month, dt.day);
  }

  Future<EventDetailsResult?> _getEvent(String publicEventId) async {
    RunDetailsModel? rdm;

    final deviceId = box.get(HIVE_DEVICE_ID) as String;
    final deviceSecret = (box.get(HIVE_DEVICE_SECRET) as String?) ?? '';
    final accessToken = Utilities.generateToken(
      deviceId,
      'hcportal_getEvent',
      paramString: deviceSecret,
    );

    final body = <String, dynamic>{
      'queryType': 'getEvent',
      'deviceId': deviceId,
      'accessToken': accessToken,
      'publicEventId': publicEventId,
    };

    final jsonResult = await ServiceCommon.sendHttpPostToHC6Api(body);
    debugPrint(jsonResult.startsWith(ERROR_PREFIX)
        ? 'SP 8b (a-b) [getEvent] called — FAILED'
        : 'SP 8b (a-b) [getEvent] called — success');
    if (jsonResult.length > 10) {
      final jsonItems = json.decode(jsonResult) as List<dynamic>;
      rdm = RunDetailsModel.fromJson(
        (jsonItems[0] as List<dynamic>)[0] as Map<String, dynamic>,
      );

      // Parse the participants from the second result set
      final participants = <ParticipantModel>[];
      final participantRecords = (jsonItems[1] as List<dynamic>);

      for (final record in participantRecords) {
        participants.add(
          ParticipantModel.fromJson(
            record as Map<String, dynamic>,
          ),
        );
      }
      return EventDetailsResult(runDetails: rdm, participants: participants);
    }

    return EventDetailsResult.empty();
  }
}

class SingleRunPage extends StatelessWidget {
  const SingleRunPage({
    required this.textTheme,
    required this.publicEventId,
    super.key,
    this.backgroundColor,
    this.backButtonUrl,
  });

  final String textTheme;
  final String publicEventId;
  final String? backgroundColor;
  final String? backButtonUrl;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SingleRunPageController>(
      init: SingleRunPageController(
        textTheme: textTheme,
        publicEventId: publicEventId,
        backgroundColor: backgroundColor,
        backButtonUrl: backButtonUrl,
      ),
      builder: (c) {
        c.isNarrowScreen ??=
            MediaQuery.of(context).size.width < NARROW_SCREEN_WIDTH;

        return PopScope(
          onPopInvokedWithResult: (bool didPop, _) async {
            if ((c.backButtonUrl != null) &&
                (c.backButtonUrl!.startsWith('http'))) {
              if (Uri.parse(c.backButtonUrl ?? '').isAbsolute) {
                openWindow(c.backButtonUrl ?? '', '_blank');
                return;
              } else {
                await IveCoreUtilities.showAlert(
                  context,
                  'Unable to open link',
                  'Harrier Central was unable to open ${c.backButtonUrl}',
                  'OK',
                );
                return;
              }
            } else {
              return;
              //TO DO(James): Check out why the boolean value is not accepted
              //return true;
            }
          },
          child: NotificationListener<SizeChangedLayoutNotification>(
            onNotification: (SizeChangedLayoutNotification notification) {

              if (c.isNarrowScreen !=
                  MediaQuery.of(context).size.width < NARROW_SCREEN_WIDTH) {
                c.isNarrowScreen =
                    MediaQuery.of(context).size.width < NARROW_SCREEN_WIDTH;
              }
              return true;
            },
            child: SizeChangedLayoutNotifier(
              key: c.pageKey,
              child: Scaffold(
                backgroundColor: c.backgroundColor == null
                    ? null
                    : HexColor(c.backgroundColor!),
                body: Container(
                  decoration: c.backgroundColor != null
                      ? null
                      : c.textThemeIsLight
                          ? Backgrounds.defaultHcBackground()
                          : Backgrounds.defaultHcBackgroundLight(),
                  child: c.isLoaded
                      ? _renderRunDetail(c)
                      : HcCircularProgressIndicator(key: UniqueKey()),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _renderRunDetail(SingleRunPageController c) {
    if (c.rdm != null) {
      return SingleChildScrollView(
        primary: false,
        child: RunDetailWidget(
          rdm: c.rdm!,
          participants: c.participants,
          textThemeIsLight: c.textThemeIsLight,
          isNarrowScreen: c.isNarrowScreen ?? false,
          backgroundColor: c.backgroundColor,
        ),
      );
    } else {
      return Container();
    }
  }
}
