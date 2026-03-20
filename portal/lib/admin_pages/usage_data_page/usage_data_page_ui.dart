import 'package:carousel_slider/carousel_slider.dart' as cs;
import 'package:hcportal/imports.dart';
import 'package:hcportal/admin_pages/usage_data_page/usage_data_page_controller.dart';
import 'package:hcportal/admin_pages/usage_data_page/login_history_dialog.dart';
import 'package:hcportal/models/usage_data_new_events/usage_data_new_events.dart';

// ---------------------------------------------------------------------------
// Usage Data Page
// ---------------------------------------------------------------------------

class UsageDataPage extends StatelessWidget {
  const UsageDataPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(UsageDataPageController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Usage Data'),
        leading: GestureDetector(
          onTap: () => Get.back<void>(),
          child: const Icon(
            MaterialCommunityIcons.arrow_left,
            color: Colors.black,
          ),
        ),
      ),
      body: Row(
        children: <Widget>[
          Expanded(
            flex: 25,
            child: _RecentHasherLogins(controller: controller),
          ),
          const SizedBox(width: 4),
          Expanded(
            flex: 60,
            child: Column(
              children: <Widget>[
                Expanded(
                  flex: 55,
                  child: _AppStats(controller: controller),
                ),
                Expanded(
                  flex: 20,
                  child: _IntegrationStats(controller: controller),
                ),
                const SizedBox(height: 4),
                Expanded(
                  flex: 25,
                  child: _NewEventsCarousel(controller: controller),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            flex: 15,
            child: _HcVersionColumn(controller: controller),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// New Events Carousel
// ---------------------------------------------------------------------------

class _NewEventsCarousel extends StatelessWidget {
  const _NewEventsCarousel({required this.controller});

  final UsageDataPageController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() => cs.CarouselSlider(
          options: cs.CarouselOptions(height: 130, autoPlay: true),
          items: controller.newEvents.map((evt) {
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
                      const SizedBox(width: 4),
                      KennelLogo(
                        kennelLogoUrl: evt.kennelLogo,
                        kennelShortName: evt.kennelShortName,
                        logoHeight: 100.0,
                        leftPadding: 15.0,
                      ),
                      Expanded(
                        child: _NewEventDetail(
                          controller: controller,
                          evt: evt,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }).toList(),
        ));
  }
}

class _NewEventDetail extends StatelessWidget {
  const _NewEventDetail({
    required this.controller,
    required this.evt,
  });

  final UsageDataPageController controller;
  final UdNewEventsModel evt;

  @override
  Widget build(BuildContext context) {
    const horizontalMargin = EdgeInsets.symmetric(horizontal: 8);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: Padding(
            padding: horizontalMargin,
            child: AutoSizeText(
              '${evt.kennelName} (${evt.kennelShortName})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              maxFontSize: 32,
              minFontSize: 5,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: horizontalMargin,
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
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: horizontalMargin,
            child: AutoSizeText(
              controller.formatMinutesDuration(
                evt.minutesUntilRun,
                isFuture: evt.minutesUntilRun > 0,
              ),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              maxFontSize: 32,
              minFontSize: 5,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: horizontalMargin,
            child: AutoSizeText(
              controller.formatCreatedUpdated(evt),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              maxFontSize: 32,
              minFontSize: 5,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// HC Version Column
// ---------------------------------------------------------------------------

class _HcVersionColumn extends StatelessWidget {
  const _HcVersionColumn({required this.controller});

  final UsageDataPageController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() => SingleChildScrollView(
          primary: false,
          child: Column(
            children: controller.hcVersions.map((hcVer) {
              final totalUsers = hcVer.isNotiPhone + hcVer.isiPhone;
              final maxVersion = controller.maxHcVersion.value == 0
                  ? 1
                  : controller.maxHcVersion.value;
              final lightness =
                  ((((totalUsers / maxVersion) / 2.0) - 0.85).abs())
                      .clamp(0.0, 1.0);
              final textColor = lightness < 0.7 ? Colors.white : Colors.black;
              final versionKey = '${hcVer.versionNum}/${hcVer.buildNum}';
              final isUpdating =
                  controller.isUpdatingVersion.value == versionKey;

              return Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: GestureDetector(
                  onTap: () async {
                    await controller.getHcVersionDetail(
                      hcVer.versionNum,
                      hcVer.buildNum,
                      title:
                          'Version ${hcVer.versionNum} / Build ${hcVer.buildNum}',
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 80),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    color: HSLColor.fromColor(Colors.purple)
                        .withLightness(lightness)
                        .toColor(),
                    child: isUpdating
                        ? const HcCircularProgressIndicator(
                            key: Key('version_loading'),
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              AutoSizeText(
                                versionKey,
                                style: TextStyle(
                                  fontSize: 18,
                                  color: textColor,
                                ),
                                minFontSize: 5,
                                maxFontSize: 22,
                                maxLines: 1,
                              ),
                              AutoSizeText(
                                totalUsers.toString(),
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                                minFontSize: 5,
                                maxFontSize: 32,
                                maxLines: 1,
                              ),
                              AutoSizeText(
                                '${hcVer.isiPhone} / ${hcVer.isNotiPhone}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: textColor,
                                ),
                                minFontSize: 5,
                                maxFontSize: 18,
                                maxLines: 1,
                              ),
                            ],
                          ),
                  ),
                ),
              );
            }).toList(),
          ),
        ));
  }
}

// ---------------------------------------------------------------------------
// App Stats
// ---------------------------------------------------------------------------

class _AppStats extends StatelessWidget {
  const _AppStats({required this.controller});

  final UsageDataPageController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.appActivity.isEmpty) return const SizedBox.shrink();

      return Column(
        children: <Widget>[
          _AppStatsHeaderRow(),
          const Divider(color: Colors.grey, height: 1, thickness: 1),
          for (var i = 0; i < controller.appActivity.length; i++)
            _AppStatsRow(controller: controller, index: i),
        ],
      );
    });
  }
}

class _AppStatsHeaderRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const Expanded(child: SizedBox()),
        for (final label in ['Hour', 'Day', 'Week', 'Month'])
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              color: Colors.grey.shade100,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AppStatsRow extends StatelessWidget {
  const _AppStatsRow({required this.controller, required this.index});

  final UsageDataPageController controller;
  final int index;

  /// Whether higher values are bad (e.g. Error rows). Defaults to false
  /// (higher is better / green). When true, the color scheme is reversed
  /// so that lower values show green.
  bool get _higherIsBad => controller.appActivity[index].dataType == 'Error';

  @override
  Widget build(BuildContext context) {
    final data = controller.appActivity[index];
    return Expanded(
      child: Column(
        children: <Widget>[
          Expanded(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Container(
                    color: Colors.grey.shade100,
                    constraints: const BoxConstraints.expand(),
                    child: Center(
                      child: AutoSizeText(
                        data.dataType,
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                        maxLines: 1,
                        minFontSize: 5,
                        maxFontSize: 32,
                      ),
                    ),
                  ),
                ),
                ..._buildStatsCell(index, 0, data.lastHour, data.lastHourComp),
                ..._buildStatsCell(index, 1, data.lastDay, data.lastDayComp),
                ..._buildStatsCell(index, 7, data.lastWeek, data.lastWeekComp),
                ..._buildStatsCell(
                    index, -1, data.lastMonth, data.lastMonthComp),
              ],
            ),
          ),
          const SizedBox(height: 1),
        ],
      ),
    );
  }

  List<Widget> _buildStatsCell(
    int id,
    int days,
    int value,
    int comparisonValue,
  ) {
    final ratio = _calculateRatio(value, comparisonValue);
    final isUpdating = controller.isUpdatingId.value == id &&
        controller.isUpdatingDays.value == days;

    // When _higherIsBad is true, reverse the color logic:
    // lower value = good = green, higher value = bad = red
    final bool isGreen;
    if (value == 0 && comparisonValue == 0) {
      isGreen = true; // neutral
    } else if (_higherIsBad) {
      isGreen = value <= comparisonValue; // fewer errors is good
    } else {
      isGreen = value >= comparisonValue; // more activity is good
    }

    return <Widget>[
      const SizedBox(width: 1),
      Expanded(
        child: GestureDetector(
          onTap: () async {
            if (!isUpdating && days >= 0) {
              final timeLabel = switch (days) {
                0 => 'Last Hour',
                1 => 'Last Day',
                7 => 'Last Week',
                _ => 'Last Month',
              };
              await controller.getCategoryDetail(
                id,
                days,
                title:
                    '${controller.appActivity[id].dataType} \u2013 $timeLabel',
              );
            }
          },
          child: ColoredBox(
            color: isUpdating
                ? Colors.grey.shade200
                : HSLColor.fromColor(
                    (value == 0 && comparisonValue == 0)
                        ? Colors.grey.shade50
                        : isGreen
                            ? Colors.green
                            : Colors.red,
                  ).withLightness(ratio).toColor(),
            child: isUpdating
                ? const HcCircularProgressIndicator(
                    key: Key('stats_loading'),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Expanded(
                        flex: 3,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: AutoSizeText(
                            value.toString(),
                            maxLines: 1,
                            maxFontSize: 32,
                            minFontSize: 5,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: AutoSizeText(
                            comparisonValue.toString(),
                            maxLines: 1,
                            maxFontSize: 20,
                            minFontSize: 5,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    ];
  }

  double _calculateRatio(int value, int comparisonValue) {
    if (value == 0 && comparisonValue == 0) return 0.8;
    if (value >= comparisonValue) {
      return comparisonValue > 0
          ? ((((value / comparisonValue) / 10.0).clamp(0.0, 1.0) - 1.0).abs())
              .clamp(0.5, 1.0)
          : 0.5;
    }
    return value > 0
        ? ((((comparisonValue / value) / 10.0).clamp(0.0, 1.0) - 1.0).abs())
            .clamp(0.5, 1.0)
        : 0.5;
  }
}

// ---------------------------------------------------------------------------
// Integration Stats
// ---------------------------------------------------------------------------

class _IntegrationStats extends StatelessWidget {
  const _IntegrationStats({required this.controller});

  final UsageDataPageController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.integrationMonitor.length < 3) {
        return const SizedBox.shrink();
      }
      return Row(
        children: <Widget>[
          _IntegrationBlock(
            controller: controller,
            integration: controller.integrationMonitor[0],
          ),
          _IntegrationBlock(
            controller: controller,
            integration: controller.integrationMonitor[1],
          ),
          _IntegrationBlock(
            controller: controller,
            integration: controller.integrationMonitor[2],
          ),
        ],
      );
    });
  }
}

class _IntegrationBlock extends StatelessWidget {
  const _IntegrationBlock({
    required this.controller,
    required this.integration,
  });

  final UsageDataPageController controller;
  final UdIntegrationMonitorModel integration;

  @override
  Widget build(BuildContext context) {
    final bgColor = integration.integrationEnabled == 0
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
            .toColor();

    return Expanded(
      child: GestureDetector(
        onTap: () => controller.integrationBlockPressed(integration),
        child: Container(
          height: 170,
          color: bgColor,
          child: Stack(
            alignment: AlignmentDirectional.center,
            children: <Widget>[
              Opacity(
                opacity: integration.integrationEnabled == 0 ? 0.25 : 1.0,
                child: Column(
                  children: <Widget>[
                    const SizedBox(height: 10),
                    Expanded(
                      child: AutoSizeText(
                        integration.integrationAbbreviation,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                        ),
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
                          fontWeight: FontWeight.bold,
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
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
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
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (integration.integrationEnabled == 0)
                const Icon(
                  MaterialIcons.do_not_disturb,
                  size: 150,
                  color: Colors.red,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recent Hasher Logins
// ---------------------------------------------------------------------------

class _RecentHasherLogins extends StatelessWidget {
  const _RecentHasherLogins({required this.controller});

  final UsageDataPageController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() => SingleChildScrollView(
          primary: false,
          child: Column(
            children: controller.recentUsers
                .map(
                  (hcUser) => Column(
                    children: <Widget>[
                      SizedBox(
                        height: 90,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            _UserPhoto(photo: hcUser.photo),
                            Expanded(
                              child: _UserInfoPanel(
                                controller: controller,
                                user: hcUser,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
                  ),
                )
                .toList(),
          ),
        ));
  }
}

class _UserPhoto extends StatelessWidget {
  const _UserPhoto({required this.photo});

  final String photo;

  @override
  Widget build(BuildContext context) {
    // Width = 90 to match the fixed row height, making a perfect square.
    return SizedBox(
      width: 90,
      child: ClipRect(child: _buildImage()),
    );
  }

  Widget _buildImage() {
    if (photo.startsWith('https://')) {
      return GestureDetector(
        onTap: () async {
          // Use navigatorKey or a stored context for the dialog
          await showDialog<void>(
            context: Get.overlayContext!,
            builder: (_) => ImageDialog(userPhoto: photo),
          );
        },
        child: HcNetworkImage(photo, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const ColoredBox(
              color: Colors.grey,
              child: Icon(Icons.person, color: Colors.white),
            )),
      );
    }

    if (photo.startsWith('bundle://')) {
      return Image.network(
        '${photo.replaceAll('bundle://', 'https://harriercentral.blob.core.windows.net/profile-photos/')}.jpg',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const ColoredBox(
          color: Colors.grey,
          child: Icon(Icons.person, color: Colors.white),
        ),
      );
    }

    return ColoredBox(color: Colors.grey.shade100);
  }
}

class _UserInfoPanel extends StatelessWidget {
  const _UserInfoPanel({
    required this.controller,
    required this.user,
  });

  final UsageDataPageController controller;
  final UdRecentUserModel user;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: HSLColor.fromColor(Colors.orange)
          .withLightness(
            (user.minutesSinceLastLogin / 120.0).clamp(0.0, 0.5) + 0.5,
          )
          .toColor(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () async {
              await showDialog<void>(
                context: context,
                builder: (_) => LoginHistoryDialog(
                  userId: user.userId,
                  userName: user.userName,
                  realName: user.realName,
                  controller: controller,
                ),
              );
            },
            child: AutoSizeText(
              user.userName,
              textAlign: TextAlign.center,
              maxLines: 1,
              maxFontSize: 32,
              minFontSize: 5,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                height: 0.85,
                decoration: TextDecoration.underline,
                color: user.loginCount < 2
                    ? Colors.black
                    : user.loginCount < 5
                        ? Colors.blue.shade800
                        : user.loginCount < 8
                            ? Colors.purple
                            : Colors.red.shade900,
              ),
            ),
          ),
          if (user.kennelShortName.length > 1)
            AutoSizeText(
              user.kennelShortName,
              maxLines: 1,
              minFontSize: 5,
              maxFontSize: 32,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red.shade600,
              ),
            ),
          _VersionRow(user: user),
          if (user.hcVersion.length > 1)
            AutoSizeText(
              controller.formatLoginTime(user),
              maxLines: 1,
              minFontSize: 5,
              maxFontSize: 32,
            ),
        ],
      ),
    );
  }
}

class _VersionRow extends StatelessWidget {
  const _VersionRow({required this.user});

  final UdRecentUserModel user;

  Color _highlightColor(int level) {
    switch (level) {
      case 0:
        return Colors.green.shade300;
      case 1:
        return Colors.yellow.shade300;
      case 2:
        return Colors.orange.shade300;
      case 3:
        return Colors.red.shade300;
      default:
        return Colors.purple.shade300;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Expanded(child: SizedBox()),
        if (user.isIphone != -1) ...<Widget>[
          Expanded(
            child: Icon(
              user.isIphone == 1
                  ? MaterialCommunityIcons.apple
                  : MaterialIcons.android,
              color:
                  user.isIphone == 1 ? Colors.red : Colors.lightGreen.shade800,
              size: 15,
            ),
          ),
          ColoredBox(
            color: _highlightColor(user.highlightPhoneVersion),
            child: AutoSizeText(
              user.systemVersion.trim(),
              minFontSize: 5,
              maxFontSize: 32,
              maxLines: 1,
              style: TextStyle(
                fontWeight: user.highlightPhoneVersion == 1
                    ? FontWeight.w900
                    : FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          const Icon(
            MaterialCommunityIcons.arrow_right_bold,
            color: Colors.black,
            size: 15,
          ),
        ],
        ColoredBox(
          color: _highlightColor(user.highlightHcVersion),
          child: AutoSizeText(
            user.hcVersion.replaceAll('HC Ver: ', ''),
            minFontSize: 5,
            maxFontSize: 32,
            maxLines: 1,
            style: TextStyle(
              fontWeight: user.highlightHcVersion == 1
                  ? FontWeight.w900
                  : FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        const Expanded(child: SizedBox()),
      ],
    );
  }
}
