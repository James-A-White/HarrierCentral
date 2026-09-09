import 'dart:ui' as ui;

import 'package:hcportal/imports.dart';
import 'package:hcportal/models/device_health/device_health.dart';
import 'package:intl/intl.dart';

/// Selection + data for one user's Device Health tab. Registered with the
/// user id as tag so two open dialogs cannot share state.
class DeviceHealthController extends GetxController {
  DeviceHealthController(this.userId, this.page);
  final String userId;
  final UsageDataPageController page;

  final Rxn<DeviceHealth> data = Rxn<DeviceHealth>();
  final RxBool loading = true.obs;
  final RxInt selected = 0.obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(_load());
  }

  Future<void> _load() async {
    data.value = await page.getDeviceHealth(userId);
    loading.value = false;
  }

  DeviceHealthSession? get selectedSession {
    final List<DeviceHealthSession>? s = data.value?.sessions;
    if (s == null || s.isEmpty) return null;
    return s[selected.value.clamp(0, s.length - 1)];
  }
}

class DeviceHealthView extends StatelessWidget {
  const DeviceHealthView({required this.userId, required this.page, super.key});
  final String userId;
  final UsageDataPageController page;

  @override
  Widget build(BuildContext context) {
    final DeviceHealthController c = Get.put(
      DeviceHealthController(userId, page),
      tag: userId,
    );
    return Obx(() {
      if (c.loading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      final DeviceHealth d = c.data.value ?? DeviceHealth.empty;
      if (d.devices.isEmpty) {
        return const Center(child: Text('No devices for this user'));
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _DeviceStrip(devices: d.devices),
          const SizedBox(height: 8),
          if (d.sessions.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'No metrics yet — they arrive one launch after a session on 3.0.14 or later',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else ...<Widget>[
            _SessionHeader(),
            const Divider(height: 1),
            Expanded(flex: 3, child: _SessionList(c: c, d: d)),
            const Divider(height: 1),
            Expanded(flex: 2, child: _SessionDetail(c: c)),
          ],
        ],
      );
    });
  }
}

class _DeviceStrip extends StatelessWidget {
  const _DeviceStrip({required this.devices});
  final List<DeviceHealthDevice> devices;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: devices.map((DeviceHealthDevice dv) {
        final String when = DateFormat('MMM d, h:mm a').format(dv.lastLogin.toLocal());
        return Chip(
          avatar: Icon(
            dv.isIos ? MaterialCommunityIcons.apple : MaterialIcons.android,
            size: 16,
            color: dv.isIos ? Colors.grey.shade700 : Colors.green.shade700,
          ),
          label: Text(
            '${dv.hcVersion}  ·  last login $when  ·  '
            '${dv.sessionsWithMetrics}/${dv.sessions} sessions with metrics',
            style: const TextStyle(fontSize: 12),
          ),
        );
      }).toList(),
    );
  }
}

const List<(String, int)> _cols = <(String, int)>[
  ('Uploaded', 3),
  ('Build', 2),
  ('Up (fg)', 2),
  ('CPU', 2),
  ('Mem peak / avail', 3),
  ('Net rx · req/fail · lat', 3),
  ('GPS track', 2),
  ('Battery', 2),
  ('Errors', 3),
];

class _SessionHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      color: Colors.grey.shade200,
      child: Row(
        children: _cols
            .map((c) => Expanded(
                  flex: c.$2,
                  child: Text(c.$1, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                ))
            .toList(),
      ),
    );
  }
}

class _SessionList extends StatelessWidget {
  const _SessionList({required this.c, required this.d});
  final DeviceHealthController c;
  final DeviceHealth d;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: d.sessions.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (BuildContext context, int i) {
        final DeviceHealthSession s = d.sessions[i];
        final bool isSel = c.selected.value == i;
        final String drain = s.v('drain', '');
        final String batt = s.v('batt', '—') + (drain.isEmpty ? '' : '  ↓$drain');
        final String errors = s.appError != null
            ? _short(s.appError!, 40)
            : (s.errorLines > 0 ? '${s.errorLines} error line(s)' : '');
        final List<String> cells = <String>[
          DateFormat('MMM d, h:mm a').format(s.loggedAt.toLocal()),
          s.hcVersion,
          '${s.v('up')} (${s.v('fg')})',
          '${s.v('cpu')} ${s.v('cpu%', '') == '' ? '' : '· ${s.v('cpu%')}%'}',
          '${s.v('peak')} / ${s.v('avail')}',
          '${s.v('app_rx')} · ${s.v('req', '0')}/${s.v('fail', '0')} · ${s.v('lat_max')}',
          s.v('loc_track', '0s'),
          batt,
          errors,
        ];
        return InkWell(
          onTap: () => c.selected.value = i,
          child: Container(
            color: isSel ? Colors.blue.shade50 : null,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            child: Row(
              children: List<Widget>.generate(
                cells.length,
                (int k) => Expanded(
                  flex: _cols[k].$2,
                  child: Text(
                    cells[k],
                    style: TextStyle(
                      fontSize: 12,
                      color: k == 8 && s.appError != null ? Colors.red.shade800 : Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static String _short(String s, int n) => s.length <= n ? s : '${s.substring(0, n)}…';
}

class _SessionDetail extends StatelessWidget {
  const _SessionDetail({required this.c});
  final DeviceHealthController c;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final DeviceHealthSession? s = c.selectedSession;
      if (s == null) return const SizedBox.shrink();
      final MetricsRing? ring = s.ring;
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (ring != null && ring.rows.length >= 2) ...<Widget>[
              Text(
                'Last ${ring.rows.length} minutes before the session ended — memory (blue), battery (green), CPU % (orange); shaded = tracking a run',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 110,
                child: CustomPaint(painter: _RingPainter(ring), size: Size.infinite),
              ),
              const SizedBox(height: 8),
            ],
            if (s.peaks.isNotEmpty) ...<Widget>[
              Text('Peaks', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey.shade800)),
              _KeyValueWrap(s.peaks),
              const SizedBox(height: 6),
            ],
            Text('Session summary', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey.shade800)),
            _KeyValueWrap(s.summary),
            if (s.appError != null) ...<Widget>[
              const SizedBox(height: 6),
              Text(s.appError!, style: TextStyle(fontSize: 12, color: Colors.red.shade800)),
            ],
            const SizedBox(height: 8),
          ],
        ),
      );
    });
  }
}

class _KeyValueWrap extends StatelessWidget {
  const _KeyValueWrap(this.map);
  final Map<String, String> map;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: map.entries
          .map((MapEntry<String, String> e) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 11, color: Colors.black),
                    children: <TextSpan>[
                      TextSpan(text: '${e.key} ', style: TextStyle(color: Colors.grey.shade700)),
                      TextSpan(text: e.value, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }
}

/// Three normalised polylines over the ring rows, each scaled to its own
/// min–max so the SHAPE is visible whatever the units; the labels at the left
/// edge give the actual range. Minutes spent tracking are shaded.
class _RingPainter extends CustomPainter {
  _RingPainter(this.ring);
  final MetricsRing ring;

  @override
  void paint(Canvas canvas, Size size) {
    final int n = ring.rows.length;
    if (n < 2) return;
    final double left = 78;
    final double w = size.width - left;
    final double dx = w / (n - 1);

    // Shade tracking minutes
    final List<String> tiers = ring.labels('tier');
    final Paint shade = Paint()..color = Colors.grey.shade300;
    for (int i = 0; i < tiers.length; i++) {
      if (tiers[i] == 'track' || tiers[i] == 'paused') {
        canvas.drawRect(Rect.fromLTWH(left + i * dx - dx / 2, 0, dx, size.height), shade);
      }
    }

    void line(String col, Color color, double yTop, String label) {
      final List<double?> s = ring.series(col);
      final List<double> vals = s.whereType<double>().toList();
      if (vals.length < 2) return;
      double lo = vals.reduce((a, b) => a < b ? a : b);
      double hi = vals.reduce((a, b) => a > b ? a : b);
      if (hi == lo) hi = lo + 1;
      final Path p = Path();
      bool started = false;
      for (int i = 0; i < s.length; i++) {
        final double? v = s[i];
        if (v == null) { started = false; continue; }
        final double x = left + i * dx;
        final double y = size.height - 4 - (v - lo) / (hi - lo) * (size.height - 8);
        if (!started) { p.moveTo(x, y); started = true; } else { p.lineTo(x, y); }
      }
      canvas.drawPath(p, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1.5);
      final TextPainter tp = TextPainter(
        text: TextSpan(text: '$label ${_fmt(lo)}–${_fmt(hi)}', style: TextStyle(fontSize: 10, color: color)),
        textDirection: ui.TextDirection.ltr,
      )..layout(maxWidth: left - 4);
      tp.paint(canvas, Offset(0, yTop));
    }

    line('rss_mb', Colors.blue.shade700, 2, 'MB');
    line('batt', Colors.green.shade700, 16, '%');
    line('cpu%', Colors.orange.shade800, 30, 'cpu');
  }

  static String _fmt(double v) => v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.ring != ring;
}
