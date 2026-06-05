import 'package:harrier_central/imports.dart';
import 'package:intl/intl.dart';

class GuestRunDetailPage extends StatelessWidget {
  const GuestRunDetailPage({super.key, required this.run});

  final GuestRunModel run;

  static final DateFormat _dateFmt = DateFormat('EEEE d MMMM y');
  static final DateFormat _timeFmt = DateFormat('h:mma');

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: themeAppBarBackground,
        iconTheme: const IconThemeData(color: Colors.white, size: 28),
        title: Text('Run Details', style: ts_appBarTitle),
      ),
      body: Container(
        decoration: Backgrounds.defaultHcBackground(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _KennelHeader(run: run),
              const SizedBox(height: 20),
              const Divider(color: Colors.white12),
              const SizedBox(height: 16),
              _RunTitle(run: run),
              const SizedBox(height: 16),
              _RunMeta(run: run, dateFmt: _dateFmt, timeFmt: _timeFmt),
              if ((run.hares ?? '').isNotEmpty) ...<Widget>[
                const SizedBox(height: 16),
                _DetailRow(
                  icon: Icons.directions_run,
                  label: 'Hares',
                  value: run.hares!,
                ),
              ],
              if ((run.eventDescription ?? '').isNotEmpty) ...<Widget>[
                const SizedBox(height: 16),
                const Divider(color: Colors.white12),
                const SizedBox(height: 12),
                Text(
                  run.eventDescription!,
                  style: ts_body.copyWith(color: Colors.white70, height: 1.5),
                ),
              ],
              const SizedBox(height: 24),
              _MemberPromptCard(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const GuestActionBar(),
    );
  }
}

// ---------------------------------------------------------------------------
// Kennel header — logo + name centred at the top
// ---------------------------------------------------------------------------

class _KennelHeader extends StatelessWidget {
  const _KennelHeader({required this.run});
  final GuestRunModel run;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        KennelLogo(
          kennelLogoUrl: run.kennelLogo,
          kennelShortName: run.kennelShortName ?? run.kennelName,
          logoHeight: 52,
          zoomGesture: KennelLogoZoomGesture.tap,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                run.kennelName,
                style: ts_body.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
              if (run.kennelContinent != null) ...<Widget>[
                const SizedBox(height: 2),
                Text(
                  run.kennelContinent!,
                  style: ts_body.copyWith(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Run title + type badge
// ---------------------------------------------------------------------------

class _RunTitle extends StatelessWidget {
  const _RunTitle({required this.run});
  final GuestRunModel run;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (run.eventNumber != null && run.eventNumber! > 0) ...<Widget>[
          Text(
            'Run #${run.eventNumber}',
            style: ts_body.copyWith(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 4),
        ],
        Text(
          run.eventName,
          style: ts_headingLarge.copyWith(color: Colors.white),
        ),
        if ((run.eventTypeName ?? '').isNotEmpty) ...<Widget>[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              run.eventTypeName!,
              style: ts_body.copyWith(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Date, time, location rows
// ---------------------------------------------------------------------------

class _RunMeta extends StatelessWidget {
  const _RunMeta({
    required this.run,
    required this.dateFmt,
    required this.timeFmt,
  });

  final GuestRunModel run;
  final DateFormat dateFmt;
  final DateFormat timeFmt;

  @override
  Widget build(BuildContext context) {
    final DateTime? start = run.eventStartDatetime;

    final String? locationDisplay = (run.locationOneLineDesc?.isNotEmpty ?? false)
        ? run.locationOneLineDesc
        : <String?>[
            run.locationStreet,
            run.locationCity,
            run.locationPostCode,
            run.locationCountry,
          ].where((s) => s != null && s.isNotEmpty).join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (start != null) ...<Widget>[
          _DetailRow(
            icon: Icons.calendar_today,
            label: 'Date',
            value: dateFmt.format(start),
          ),
          const SizedBox(height: 10),
          _DetailRow(
            icon: Icons.access_time,
            label: 'Time',
            value: timeFmt.format(start),
          ),
        ],
        if ((locationDisplay ?? '').isNotEmpty) ...<Widget>[
          const SizedBox(height: 10),
          _DetailRow(
            icon: Icons.location_on_outlined,
            label: 'Location',
            value: locationDisplay!,
          ),
        ],
        if (run.eventPriceForMembers != null &&
            run.eventPriceForMembers! > 0) ...<Widget>[
          const SizedBox(height: 10),
          _DetailRow(
            icon: Icons.payments_outlined,
            label: 'Hash cash',
            value:
                '${run.eventCurrencyType ?? ''} ${run.eventPriceForMembers!.toStringAsFixed(run.eventPriceForMembers! % 1 == 0 ? 0 : 2)}',
          ),
        ],
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, color: Colors.white38, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: ts_body.copyWith(
                  color: Colors.white38,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: ts_body.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Member-only prompt card
// ---------------------------------------------------------------------------

class _MemberPromptCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.people_outline, color: Colors.white38, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Log in to see who attended, GPS trails, and more.',
              style: ts_body.copyWith(color: Colors.white54),
            ),
          ),
        ],
      ),
    );
  }
}
