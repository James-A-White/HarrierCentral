// ignore_for_file: sort_child_properties_last

import 'package:carousel_slider/carousel_slider.dart' as cs;
import 'package:hcportal/imports.dart';
import 'package:hcportal/models/usage_category_detail/usage_category_detail.dart';
import 'package:hcportal/models/usage_data_new_events/usage_data_new_events.dart';

class UsageDataPage extends StatefulWidget {
  const UsageDataPage({super.key});

  @override
  UsageDataPageState createState() => UsageDataPageState();
}

Timer? _timer;

class UsageDataPageState extends State<UsageDataPage> {
  @override
  void initState() {
    super.initState();
    unawaited(initStateAsync());
  }

  bool _isFetching = false;

  Future<void> initStateAsync() async {
    if (_isFetching) return;
    _isFetching = true;
    try {
      await _getUsageData();
      setState(() {});
    } finally {
      _isFetching = false;
    }
    _timer = Timer.periodic(const Duration(minutes: 1), (Timer timer) async {
      if (_isFetching) return;
      _isFetching = true;
      try {
        await _getUsageData();
        setState(() {});
      } finally {
        _isFetching = false;
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }

  final List<UdHcVersion> _hcVersions = <UdHcVersion>[];
  int _maxHcVersion = 0;
  final List<UdAppActivityModel> _appActivity = <UdAppActivityModel>[];
  final List<UdIntegrationMonitorModel> _integrationMonitor =
      <UdIntegrationMonitorModel>[];
  final List<UdRecentUserModel> _recentUsers = <UdRecentUserModel>[];
  final List<UdNewEventsModel> _newEvents = <UdNewEventsModel>[];

  Future<void> _getUsageData() async {
    final deviceId = box.get(HIVE_DEVICE_ID) as String;
    final deviceSecret = (box.get(HIVE_DEVICE_SECRET) as String?) ?? '';
    final String accessToken = Utilities.generateToken(
      deviceId,
      'hcportal_getUsageData',
      paramString: deviceSecret,
    );

    final body = <String, dynamic>{
      'queryType': 'getUsageData',
      'deviceId': deviceId,
      'accessToken': accessToken,
    };
    var jsonString = await ServiceCommon.sendHttpPostToHC6Api(body);
    debugPrint(jsonString.startsWith(ERROR_PREFIX)
        ? 'SP 16a (a-b) [getUsageData] called — FAILED'
        : 'SP 16a (a-b) [getUsageData] called — success');
    jsonString = jsonString.replaceAll('[[{', '{').replaceAll('}]]', '}');
    final elements = jsonString.split('],[');

    _hcVersions.clear();
    _maxHcVersion = 0;
    final hcVersionData = json.decode('[${elements[0]}]') as List<dynamic>;
    for (final dynamic element in hcVersionData) {
      final hcVersion = UdHcVersion.fromJson(element as Map<String, dynamic>);
      _hcVersions.add(hcVersion);
      _maxHcVersion =
          max(hcVersion.isNotiPhone + hcVersion.isiPhone, _maxHcVersion);
    }

    _integrationMonitor.clear();
    final integrationMonitorData =
        json.decode('[${elements[1]}]') as List<dynamic>;
    for (final element in integrationMonitorData) {
      _integrationMonitor.add(
        UdIntegrationMonitorModel.fromJson(element as Map<String, dynamic>),
      );
    }

    _appActivity.clear();
    final appActivityData = json.decode('[${elements[2]}]') as List<dynamic>;
    for (final element in appActivityData) {
      _appActivity
          .add(UdAppActivityModel.fromJson(element as Map<String, dynamic>));
    }

    _recentUsers.clear();
    final recentUserData = json.decode('[${elements[3]}]') as List<dynamic>;
    for (final element in recentUserData) {
      _recentUsers
          .add(UdRecentUserModel.fromJson(element as Map<String, dynamic>));
    }

    _newEvents.clear();
    final newEventData = json.decode('[${elements[4]}]') as List<dynamic>;
    for (final element in newEventData) {
      _newEvents
          .add(UdNewEventsModel.fromJson(element as Map<String, dynamic>));
    }

    setState(() {});
    return;
  }

  Future<void> _getCategoryDetail(
    int categoryId,
    int days,
    BuildContext context,
  ) async {
    final deviceId = box.get(HIVE_DEVICE_ID) as String;
    final deviceSecret = (box.get(HIVE_DEVICE_SECRET) as String?) ?? '';
    final accessToken = Utilities.generateToken(
      deviceId,
      'hcportal_getCategoryDetail2',
      paramString: deviceSecret,
    );

    final body = <String, dynamic>{
      'queryType': 'getCategoryDetail2',
      'deviceId': deviceId,
      'accessToken': accessToken,
      'categoryId': categoryId.toString(),
      'days': days.toString(),
    };

    final jsonResult = await ServiceCommon.sendHttpPostToHC6Api(body);
    debugPrint(jsonResult.startsWith(ERROR_PREFIX)
        ? 'SP 7a (a-d) [getCategoryDetail2] called — FAILED'
        : 'SP 7a (a-d) [getCategoryDetail2] called — success');

    final jsonItems = json.decode(jsonResult) as List<dynamic>;

    final displayStr = StringBuffer();

    final items = jsonItems[0] as List<dynamic>;

    for (var i = 0; i < items.length; i++) {
      final item =
          UdCategoryDetailModel.fromJson(items[i] as Map<String, dynamic>);
      displayStr.write('${item.message ?? ''}\r\n');
    }

    await IveCoreUtilities.showAlert(
      navigatorKey.currentContext!,
      'Details',
      displayStr.toString(),
      'OK',
    );
  }

  Future<void> _getHcVersionDetail(
    String version,
    String buildNumber,
    BuildContext context,
  ) async {
    final deviceId = box.get(HIVE_DEVICE_ID) as String;
    final deviceSecret = (box.get(HIVE_DEVICE_SECRET) as String?) ?? '';
    final accessToken = Utilities.generateToken(
      deviceId,
      'hcportal_getCategoryDetail2',
      paramString: deviceSecret,
    );

    final body = <String, dynamic>{
      'queryType': 'getCategoryDetail2',
      'deviceId': deviceId,
      'accessToken': accessToken,
      'categoryId': '100',
      'days': '14',
      'hcVersion': version,
      'hcBuild': buildNumber,
    };

    final jsonResult = await ServiceCommon.sendHttpPostToHC6Api(body);
    debugPrint(jsonResult.startsWith(ERROR_PREFIX)
        ? 'SP 7b (a-d) [getCategoryDetail2] called — FAILED'
        : 'SP 7b (a-d) [getCategoryDetail2] called — success');

    final jsonItems = json.decode(jsonResult) as List<dynamic>;

    final displayStr = StringBuffer();

    final items = jsonItems[0] as List<dynamic>;

    for (var i = 0; i < items.length; i++) {
      final item =
          UdCategoryDetailModel.fromJson(items[i] as Map<String, dynamic>);
      displayStr.write('${item.message ?? ''}\r\n');
    }

    if (!context.mounted) return;
    await IveCoreUtilities.showAlert(
      context,
      'Details',
      displayStr.toString(),
      'OK',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Usage Data'),
        leading: GestureDetector(
          onTap: () {
            Get.back<void>();
          },
          child: const Icon(
            MaterialCommunityIcons.arrow_left,
            color: Colors.black,
          ),
        ),
      ),
      body: Row(
        children: <Widget>[
          Expanded(flex: 25, child: _recentHasherLogins()),
          const VerticalDivider(
            color: Colors.grey,
            thickness: 1,
            width: 1,
          ),
          Expanded(
            flex: 65,
            child: Column(
              children: <Widget>[
                Expanded(flex: 60, child: _appStats()),
                Expanded(flex: 20, child: _integrationStats()),
                const Divider(
                  color: Colors.grey,
                  height: 1,
                  thickness: 1,
                ),
                Expanded(flex: 20, child: _newEventsWidget()),
              ],
            ),
          ),
          const VerticalDivider(
            color: Colors.grey,
            thickness: 1,
            width: 1,
          ),
          Expanded(flex: 10, child: _hcVersionColumn()),
        ],
      ),
    );
  }

  Widget _newEventsWidget() {
    return cs.CarouselSlider(
      options: cs.CarouselOptions(height: 130, autoPlay: true),
      items: _newEvents.map((UdNewEventsModel evt) {
        return Builder(
          builder: (BuildContext context) {
            return GestureDetector(
              onTap: () {
                if (evt.publicEventId.isNotEmpty) {
                  openWindow(
                    'https://www.hashruns.org/#/RID?publicEventId=${evt.publicEventId}&textTheme=light',
                    '_blank',
                  );
                }
              },
              child: Row(
                children: <Widget>[
                  const VerticalDivider(
                    color: Colors.grey,
                    thickness: 1,
                    width: 1,
                  ),
                  KennelLogo(
                    kennelLogoUrl: evt.kennelLogo,
                    kennelShortName: evt.kennelShortName,
                    logoHeight: 100.0,
                    leftPadding: 15.0,
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Expanded(
                          child: Container(
                            width: MediaQuery.of(context).size.width,
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            //decoration: BoxDecoration(color: Colors.amber),
                            child: AutoSizeText(
                              '${evt.kennelName} (${evt.kennelShortName})',
                              style: const TextStyle(
                                fontSize: 16,
                                fontFamily: 'AvenirNextDemiBold',
                              ),
                              maxLines: 1,
                              maxFontSize: 32,
                              minFontSize: 5,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            width: MediaQuery.of(context).size.width,
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            //decoration: BoxDecoration(color: Colors.amber),
                            child: AutoSizeText(
                              evt.activityLastDay > 0
                                  ? '[${evt.activityLastDay}] ${evt.eventName}'
                                  : evt.eventName,
                              maxLines: 1,
                              minFontSize: 10,
                              maxFontSize: 20,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.blue.shade800,
                                fontSize: 20,
                                fontFamily: 'AvenirNextBold',
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            width: MediaQuery.of(context).size.width,
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            //decoration: BoxDecoration(color: Colors.amber),
                            child: AutoSizeText(
                              evt.minutesUntilRun > 0
                                  ? evt.minutesUntilRun < 60
                                      ? 'Run starts in ${evt.minutesUntilRun} minutes'
                                      : evt.minutesUntilRun < 1440
                                          ? 'Run starts in ${evt.minutesUntilRun ~/ 60} hours, ${evt.minutesUntilRun % 60} minutes'
                                          : 'Run starts in ${evt.minutesUntilRun ~/ 1440} days, ${(evt.minutesUntilRun % 1440) ~/ 60} hours, ${evt.minutesUntilRun % 60} minutes'
                                  : evt.minutesUntilRun > -60
                                      ? 'Run started ${-evt.minutesUntilRun} minutes ago'
                                      : evt.minutesUntilRun > 1440
                                          ? 'Run started ${(-evt.minutesUntilRun) ~/ 60} hours, ${(-evt.minutesUntilRun) % 60} minutes ago'
                                          : 'Run started ${(-evt.minutesUntilRun) ~/ 1440} days, ${((-evt.minutesUntilRun) % 1440) ~/ 60} hours, ${(-evt.minutesUntilRun) % 60} minutes ago',
                              style: const TextStyle(
                                fontSize: 20,
                                fontFamily: 'AvenirNextDemiBold',
                              ),
                              maxLines: 1,
                              maxFontSize: 32,
                              minFontSize: 5,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            width: MediaQuery.of(context).size.width,
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            //decoration: BoxDecoration(color: Colors.amber),
                            child: AutoSizeText(
                              evt.minutesAgoCreated - 2 > evt.minutesAgoUpdated
                                  ? evt.minutesAgoUpdated < 60
                                      ? 'Updated ${evt.minutesAgoUpdated} minutes ago'
                                      : 'Updated ${evt.minutesAgoUpdated ~/ 60} hours, ${evt.minutesAgoUpdated % 60} minutes ago'
                                  : evt.minutesAgoCreated < 60
                                      ? 'Created ${evt.minutesAgoCreated} minutes ago'
                                      : 'Created ${evt.minutesAgoCreated ~/ 60} hours, ${evt.minutesAgoCreated % 60} minutes ago',
                              style: const TextStyle(
                                fontSize: 20,
                                fontFamily: 'AvenirNextDemiBold',
                              ),
                              maxLines: 1,
                              maxFontSize: 32,
                              minFontSize: 5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _hcVersionColumn() {
    return SingleChildScrollView(
      primary: false,
      child: Column(
        children: _hcVersions
            .map(
              (UdHcVersion hcVer) => Column(
                children: <Widget>[
                  GestureDetector(
                    onTap: () async {
                      _isUpdatingVersion =
                          '${hcVer.versionNum}/${hcVer.buildNum}';
                      setState(() {});
                      await _getHcVersionDetail(
                        hcVer.versionNum,
                        hcVer.buildNum,
                        context,
                      );
                      _isUpdatingVersion = '';
                      setState(() {});
                    },
                    child: Container(
                      width: 150,
                      height: 100,
                      child: (_isUpdatingVersion ==
                              '${hcVer.versionNum}/${hcVer.buildNum}')
                          ? const HcCircularProgressIndicator(
                              key: Key('2342342411'))
                          : Column(
                              children: <Widget>[
                                const SizedBox(height: 6),
                                AutoSizeText(
                                  '${hcVer.versionNum}/${hcVer.buildNum}',
                                  style: TextStyle(
                                    fontSize: 22,
                                    color: ((((hcVer.isNotiPhone +
                                                                hcVer
                                                                    .isiPhone) /
                                                            _maxHcVersion) /
                                                        2.0) -
                                                    0.85)
                                                .abs() <
                                            0.7
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                  minFontSize: 5,
                                  maxFontSize: 32,
                                  maxLines: 1,
                                ),
                                AutoSizeText(
                                  (hcVer.isNotiPhone + hcVer.isiPhone)
                                      .toString(),
                                  style: TextStyle(
                                    fontSize: 36,
                                    color: ((((hcVer.isNotiPhone +
                                                                hcVer
                                                                    .isiPhone) /
                                                            _maxHcVersion) /
                                                        2.0) -
                                                    0.85)
                                                .abs() <
                                            0.7
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                  minFontSize: 5,
                                  maxFontSize: 32,
                                  maxLines: 1,
                                ),
                                AutoSizeText(
                                  '${hcVer.isiPhone} / ${hcVer.isNotiPhone}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: ((((hcVer.isNotiPhone +
                                                                hcVer
                                                                    .isiPhone) /
                                                            _maxHcVersion) /
                                                        2.0) -
                                                    0.85)
                                                .abs() <
                                            0.7
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                  minFontSize: 5,
                                  maxFontSize: 32,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                      color: HSLColor.fromColor(Colors.purple)
                          //.withSaturation((hcVer.isNotiPhone + hcVer.isiPhone) / _maxHcVersion)
                          .withLightness(
                            ((((hcVer.isNotiPhone + hcVer.isiPhone) /
                                            _maxHcVersion) /
                                        2.0) -
                                    0.85)
                                .abs(),
                          )
                          .toColor(),
                    ),
                  ),
                  const Divider(
                    color: Colors.grey,
                    thickness: 1,
                    height: 1,
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _appStats() {
    final rows = <Widget>[
      _appStatsHeaderRow(),
      const Divider(
        color: Colors.grey,
        height: 1,
        thickness: 1,
      ),
    ];
    for (var i = 0; i < _appActivity.length; i++) {
      rows.add(_appStatsRow(i));
    }

    return _appActivity.isEmpty ? Container() : Column(children: rows);
  }

  Row _appStatsHeaderRow() {
    return Row(
      children: <Widget>[
        const Expanded(child: Text('')),
        _headerText('Hour', true),
        _headerText('Day', true),
        _headerText('Week', true),
        _headerText('Month', true),
      ],
    );
  }

  Widget _headerText(String text, bool includeDivider) {
    return Expanded(
      child: Row(
        children: <Widget>[
          if (includeDivider) ...<Widget>[
            const SizedBox(
              height: 30,
              child: VerticalDivider(
                color: Colors.grey,
                thickness: 1,
                width: 1,
              ),
            ),
          ],
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(top: 5),
              height: 30,
              color: Colors.yellow.shade100,
              child: AutoSizeText(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
                maxLines: 1,
                minFontSize: 5,
                maxFontSize: 32,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _appStatsRow(int id) {
    final data = _appActivity[id];
    return Expanded(
      child: Column(
        children: <Widget>[
          Expanded(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Container(
                    color: Colors.yellow.shade100,
                    constraints: const BoxConstraints.expand(),
                    child: Center(
                      child: AutoSizeText(
                        data.dataType,
                        textAlign: TextAlign.end,
                        style: const TextStyle(fontSize: 20),
                        maxLines: 1,
                        minFontSize: 5,
                        maxFontSize: 32,
                      ),
                    ),
                  ),
                ),
                ..._appStatsCell(id, 0, data.lastHour, data.lastHourComp, true),
                ..._appStatsCell(id, 1, data.lastDay, data.lastDayComp, true),
                ..._appStatsCell(id, 7, data.lastWeek, data.lastWeekComp, true),
                ..._appStatsCell(
                  id,
                  -1,
                  data.lastMonth,
                  data.lastMonthComp,
                  true,
                ),
              ],
            ),
          ),
          const Divider(
            color: Colors.grey,
            height: 1,
            thickness: 1,
          ),
        ],
      ),
    );
  }

  int _isUpdatingId = -1;
  int _isUpdatingDays = -1;
  String _isUpdatingVersion = '';

  List<Widget> _appStatsCell(
    int id,
    int days,
    int value,
    int comparisonValue,
    bool includeDivider,
  ) {
    var ratio = 1.0;
    if ((value == 0) && (comparisonValue == 0)) {
      ratio = 0.8;
    } else if (value >= comparisonValue) {
      if (comparisonValue > 0) {
        ratio =
            ((((value / comparisonValue) / 10.0).clamp(0.0, 1.0) - 1.0).abs())
                .clamp(0.5, 1.0);
      } else {
        ratio = 0.5;
      }
    } else {
      if (value > 0) {
        ratio =
            ((((comparisonValue / value) / 10.0).clamp(0.0, 1.0) - 1.0).abs())
                .clamp(0.5, 1.0);
      } else {
        ratio = 0.5;
      }
    }

    return <Widget>[
      if (includeDivider) ...<Widget>[
        const VerticalDivider(color: Colors.grey, width: 1, thickness: 1),
      ],
      Expanded(
        child: GestureDetector(
          onTap: () async {
            if ((_isUpdatingDays == -1) && (days >= 0)) {
              setState(() {
                _isUpdatingDays = days;
                _isUpdatingId = id;
              });
              await _getCategoryDetail(id, days, context);
              setState(() {
                _isUpdatingDays = -1;
                _isUpdatingId = -1;
              });
            }
          },
          child: ColoredBox(
            color: ((_isUpdatingDays == days) && (_isUpdatingId == id))
                ? Colors.grey.shade200
                : HSLColor.fromColor(
                    ((value == 0) && (comparisonValue == 0))
                        ? Colors.yellow.shade100
                        : value >= comparisonValue
                            ? Colors.green
                            : Colors.red,
                  ).withLightness(ratio).toColor(),
            child: ((_isUpdatingDays == days) && (_isUpdatingId == id))
                ? const HcCircularProgressIndicator(key: Key('2342342411'))
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Expanded(
                        child: AutoSizeText(
                          value.toString(),
                          maxLines: 1,
                          maxFontSize: 32,
                          minFontSize: 5,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 30,
                            fontFamily: 'AvenirNextBold',
                          ),
                        ),
                      ),
                      Expanded(
                        child: AutoSizeText(
                          comparisonValue.toString(),
                          maxLines: 1,
                          maxFontSize: 32,
                          minFontSize: 5,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    ];
  }

  Future<void> _integrationBlockPressed(
    UdIntegrationMonitorModel integration,
  ) async {
    if (integration.integrationId == 1) {
      await IveCoreUtilities.showAlert(
        context,
        'Naughty / Nice list',
        '${('Naughty List,${integration.kennelsFailedInfo}').replaceAll(',', '\r\n')}\r\nNice List${(',${integration.kennelsSucceededInfo}').replaceAll(',', '\r\n')}',
        'Done',
      );
    }
  }

  Widget _integrationStats() {
    return _integrationMonitor.length < 3
        ? Container()
        : Row(
            children: <Widget>[
              _integrationBlock(_integrationMonitor[0]),
              _integrationBlock(_integrationMonitor[1]),
              _integrationBlock(_integrationMonitor[2]),
            ],
          );
  }

  Widget _integrationBlock(UdIntegrationMonitorModel integration) {
    return Expanded(
      child: Container(
        height: 170,
        color: integration.integrationEnabled == 0
            ? Colors.grey.shade200
            : HSLColor.fromColor(
                integration.minutesAgo <= integration.interval
                    ? Colors.green
                    : Colors.red,
              )
                .withLightness(
                  1 -
                      (((integration.minutesAgo / (integration.interval + .0))
                                      .clamp(0.0, 2.0) -
                                  1.0)
                              .abs() *
                          0.5),
                )
                .toColor(),
        child: GestureDetector(
          onTap: () => _integrationBlockPressed(integration),
          child: Stack(
            alignment: AlignmentDirectional.center,
            children: <Widget>[
              Column(
                children: <Widget>[
                  const SizedBox(height: 10),
                  Expanded(
                    child: AutoSizeText(
                      integration.integrationAbbreviation,
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                  Expanded(
                    child: AutoSizeText(
                      '${integration.minutesAgo} min',
                      maxLines: 1,
                      maxFontSize: 56,
                      minFontSize: 5,
                      style: const TextStyle(
                        fontSize: 56,
                        fontFamily: 'AvenirNextBold',
                      ),
                    ),
                  ),
                  Expanded(
                    child: AutoSizeText(
                      '${integration.recordsRead} read / ${integration.errorCount} errors',
                      maxLines: 1,
                      maxFontSize: 32,
                      minFontSize: 5,
                      style: const TextStyle(
                        fontSize: 24,
                        fontFamily: 'AvenirNextDemiBold',
                      ),
                    ),
                  ),
                  Expanded(
                    child: AutoSizeText(
                      '${integration.kennelsSucceeded} Nice / ${integration.kennelsFailed} Naughty',
                      maxLines: 1,
                      maxFontSize: 32,
                      minFontSize: 5,
                      style: const TextStyle(
                        fontSize: 24,
                        fontFamily: 'AvenirNextDemiBold',
                      ),
                    ),
                  ),
                ],
              ),
              if (integration.integrationEnabled == 0) ...<Widget>[
                const Opacity(
                  opacity: 0.5,
                  child: Icon(
                    MaterialIcons.do_not_disturb,
                    size: 150,
                    color: Colors.red,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _recentHasherLogins() {
    return SingleChildScrollView(
      primary: false,
      child: Column(
        children: _recentUsers
            .map(
              (UdRecentUserModel hcUser) => Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      if (hcUser.photo.startsWith('https://'))
                        Expanded(
                          flex: 30,
                          child: GestureDetector(
                            onTap: () async {
                              await showDialog<void>(
                                context: context,
                                builder: (_) =>
                                    ImageDialog(userPhoto: hcUser.photo),
                              );
                            },
                            child: Image.network(
                              hcUser.photo,
                              // height: 100.0,
                              // width: 100.0,
                            ),
                          ),
                        )
                      else
                        Expanded(
                          flex: 30,
                          child: hcUser.photo.startsWith('bundle://')
                              ? Image.network(
                                  '${hcUser.photo.replaceAll('bundle://', 'https://harriercentral.blob.core.windows.net/profile-photos/')}.jpg',
                                  // height: 100.0,
                                  // width: 100.0,
                                )
                              : Container(
                                  // height: 100.0,
                                  // width: 100.0,
                                  color: Colors.yellow.shade50,
                                ),
                        ),
                      Expanded(
                        flex: 100,
                        child: ColoredBox(
                          //height: 100.0,
                          color: HSLColor.fromColor(Colors.orange)
                              .withLightness(
                                (hcUser.minutesSinceLastLogin / 120.0)
                                        .clamp(0.0, 0.5) +
                                    0.5,
                              )
                              .toColor(),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              const SizedBox(height: 10),
                              SizedBox(
                                //width: 200.0,
                                child: AutoSizeText(
                                  hcUser.userName,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  maxFontSize: 32,
                                  minFontSize: 5,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontFamily: 'AvenirNextCondensedDemiBold',
                                    height: 0.85,
                                    color: (hcUser.loginCount < 2)
                                        ? Colors.black
                                        : (hcUser.loginCount < 5)
                                            ? Colors.blue.shade800
                                            : (hcUser.loginCount < 8)
                                                ? Colors.purple
                                                : Colors.red.shade900,
                                  ),
                                ),
                              ),
                              if (hcUser.kennelShortName.length > 1)
                                AutoSizeText(
                                  hcUser.kennelShortName,
                                  maxLines: 1,
                                  minFontSize: 5,
                                  maxFontSize: 32,
                                  style: TextStyle(
                                    fontFamily: 'AvenirNextCondensedBold',
                                    //fontSize: 16.0,
                                    color: Colors.red.shade600,
                                  ),
                                ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  const Expanded(child: SizedBox()),
                                  if (hcUser.isIphone != -1) ...<Widget>[
                                    Expanded(
                                      child: Icon(
                                        hcUser.isIphone == 1
                                            ? MaterialCommunityIcons.apple
                                            : MaterialIcons.android,
                                        color: hcUser.isIphone == 1
                                            ? Colors.red
                                            : Colors.lightGreen.shade800,
                                        size: 15,
                                      ),
                                    ),
                                    ColoredBox(
                                      color: hcUser.highlightPhoneVersion == 0
                                          ? Colors.green.shade300
                                          : hcUser.highlightPhoneVersion == 1
                                              ? Colors.yellow.shade300
                                              : hcUser.highlightPhoneVersion ==
                                                      2
                                                  ? Colors.orange.shade300
                                                  : hcUser.highlightPhoneVersion ==
                                                          3
                                                      ? Colors.red.shade300
                                                      : Colors.purple.shade300,
                                      child: AutoSizeText(
                                        hcUser.systemVersion.trim(),
                                        minFontSize: 5,
                                        maxFontSize: 32,
                                        maxLines: 1,
                                        style: TextStyle(
                                          fontFamily:
                                              hcUser.highlightPhoneVersion == 1
                                                  ? 'AvenirNextHeavy'
                                                  : 'AvenirNextCondensedBold',
                                          //fontSize: 14.0,
                                          color: Colors.black,
                                          // color: hcUser.highlightPhoneVersion == 1 ? Colors.red.shade600 : Colors.black,
                                        ),
                                      ),
                                    ),
                                    const Icon(
                                      MaterialCommunityIcons.arrow_right_bold,
                                      color: Colors.black,
                                      size: 15,
                                    ),
                                  ],
                                  //const SizedBox(width: 5.0),
                                  ColoredBox(
                                    color: hcUser.highlightHcVersion == 0
                                        ? Colors.green.shade300
                                        : hcUser.highlightHcVersion == 1
                                            ? Colors.yellow.shade300
                                            : hcUser.highlightHcVersion == 2
                                                ? Colors.orange.shade300
                                                : hcUser.highlightHcVersion == 3
                                                    ? Colors.red.shade300
                                                    : Colors.purple.shade300,
                                    child: AutoSizeText(
                                      hcUser.hcVersion
                                          .replaceAll('HC Ver: ', ''),
                                      minFontSize: 5,
                                      maxFontSize: 32,
                                      maxLines: 1,
                                      style: TextStyle(
                                        fontFamily:
                                            hcUser.highlightHcVersion == 1
                                                ? 'AvenirNextHeavy'
                                                : 'AvenirNextCondensedBold',
                                        //fontSize: 14.0,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                  const Expanded(child: SizedBox()),
                                ],
                              ),
                              if (hcUser.hcVersion.length > 1)
                                AutoSizeText(
                                  '${(hcUser.minutesSinceLastLogin ~/ 60) == 0 ? '${hcUser.minutesSinceLastLogin % 60} min ago / ' : '${hcUser.minutesSinceLastLogin ~/ 60}:${(hcUser.minutesSinceLastLogin % 60).toString().padLeft(2, '0')} ago / '}${hcUser.loginCount} login(s)',
                                  maxLines: 1,
                                  minFontSize: 5,
                                  maxFontSize: 32,
                                  //style: const TextStyle(fontSize: 20.0),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(
                    color: Colors.grey,
                    thickness: 1,
                    height: 1,
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}
