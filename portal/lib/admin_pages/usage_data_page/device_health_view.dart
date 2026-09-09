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
      if (d.sessions.isEmpty) {
        return const Center(
          child: Text('No app sessions uploaded in the last 14 days'),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _DeviceLine(devices: d.devices),
          const SizedBox(height: 6),
          Expanded(
            child: ListView.builder(
              itemCount: d.sessions.length,
              itemBuilder: (BuildContext context, int i) => _SessionCard(
                c: c,
                s: d.sessions[i],
                index: i,
              ),
            ),
          ),
        ],
      );
    });
  }
}

/// One line: each app device that uploaded a session in the window.
class _DeviceLine extends StatelessWidget {
  const _DeviceLine({required this.devices});
  final List<DeviceHealthDevice> devices;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: devices.map((DeviceHealthDevice dv) {
          final String when = DateFormat('MMM d, h:mm a').format(dv.lastLogin.toLocal());
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Chip(
              visualDensity: VisualDensity.compact,
              avatar: Icon(
                dv.isIos ? MaterialCommunityIcons.apple : MaterialIcons.android,
                size: 16,
                color: dv.isIos ? Colors.grey.shade700 : Colors.green.shade700,
              ),
              label: Text(
                '${dv.hcVersion} · last login $when · ${dv.sessions} sessions, ${dv.sessionsWithMetrics} with metrics',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// A session: one-line header always visible; the most recent card starts
/// open, the rest open on tap. Sessions from builds before 3.0.14 say so
/// instead of showing an empty grid.
class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.c, required this.s, required this.index});
  final DeviceHealthController c;
  final DeviceHealthSession s;
  final int index;

  @override
  Widget build(BuildContext context) {
    final String started = s.sessionStart != null
        ? DateFormat('EEE MMM d, h:mm a').format(s.sessionStart!)
        : 'uploaded ${DateFormat('EEE MMM d, h:mm a').format(s.loggedAt.toLocal())}';
    final Color platform = s.isIos ? Colors.grey.shade700 : Colors.green.shade700;
    final String drain = s.v('drain', '');
    return Obx(() {
      final bool open = c.selected.value == index;
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 3),
        elevation: open ? 2 : 0,
        color: open ? Colors.blue.shade50 : Colors.grey.shade50,
        child: InkWell(
          onTap: () => c.selected.value = open ? -1 : index,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(
                      s.isIos ? MaterialCommunityIcons.apple : MaterialIcons.android,
                      size: 16,
                      color: platform,
                    ),
                    const SizedBox(width: 6),
                    Text(started, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(width: 10),
                    Text(s.hcVersion, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: s.hasMetrics
                          ? Text(
                              'up ${s.v('up')} · cpu ${s.v('cpu')} · mem ${s.v('peak')} peak · '
                              'net ${s.v('app_rx')} / ${s.v('req', '0')} req · '
                              'gps ${s.v('loc_track', '0s')} · batt ${s.v('batt')}'
                              '${drain.isEmpty ? '' : ' ↓$drain'}'
                              '${s.summary.containsKey('bg_n') ? ' · bg×${s.v('bg_n', '0')} sleep×${s.v('sleep', '0')}' : ''}',
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            )
                          : Text(
                              s.errorLines > 0
                                  ? 'no metrics on this build · ${s.errorLines} error line(s)'
                                  : 'no metrics on this build',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                    ),
                    if (s.appError != null)
                      Icon(Icons.error_outline, size: 16, color: Colors.red.shade700),
                    Icon(open ? Icons.expand_less : Icons.expand_more, size: 18, color: Colors.grey.shade600),
                  ],
                ),
                if (open) _SessionBody(s: s),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _SessionBody extends StatelessWidget {
  const _SessionBody({required this.s});
  final DeviceHealthSession s;

  @override
  Widget build(BuildContext context) {
    final MetricsRing? ring = s.ring;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Uploaded ${DateFormat('MMM d, h:mm a').format(s.loggedAt.toLocal())}'
            '${s.errorLines > 0 ? ' · ${s.errorLines} error line(s) in the log' : ''}',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
          ),
          if (s.appError != null) ...<Widget>[
            const SizedBox(height: 4),
            Text(s.appError!, style: TextStyle(fontSize: 12, color: Colors.red.shade800)),
          ],
          if (ring != null && ring.rows.length >= 2) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              'Last ${ring.rows.length} minutes — memory (blue), battery (green), CPU % (orange); shaded = tracking a run',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 110,
              child: CustomPaint(painter: _RingPainter(ring), size: Size.infinite),
            ),
          ],
          if (s.peaks.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Text('Peaks', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey.shade800)),
            const SizedBox(height: 2),
            _KeyValueWrap(s.peaks),
          ],
          if (s.hasMetrics) ...<Widget>[
            const SizedBox(height: 8),
            Text('Session summary', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey.shade800)),
            const SizedBox(height: 2),
            _KeyValueWrap(s.summary),
          ],
        ],
      ),
    );
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey.shade300),
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
