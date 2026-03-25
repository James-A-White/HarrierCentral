// ignore_for_file: avoid_web_libraries_in_flutter

import 'package:hcportal/admin_pages/kennel_page_new/kennel_page_new_enums.dart';
import 'package:hcportal/admin_pages/run_list_page_controller.dart';
import 'package:hcportal/imports.dart';
import 'package:hcportal/models/email/email_model.dart';
import 'package:intl/intl.dart';
import 'package:latlng/latlng.dart';
import 'package:map/map.dart' as geo_map;
import 'package:web/web.dart' as web;

@JS('window.open')
external JSObject? _openWindow(String url, String target);

const _kRed = Color(0xFFB91C1C);
const _kBorder = Color(0xFFE2E8F0);
const _kTextPrimary = Color(0xFF0F172A);
const _kTextSecondary = Color(0xFF475569);
const _kTextMuted = Color(0xFF94A3B8);

class RunListDetailPanel extends StatelessWidget {
  const RunListDetailPanel({
    required this.edr,
    required this.controller,
    super.key,
  });

  final EventDetailsResult edr;
  final RunListPageController controller;

  bool get _hasEvent =>
      edr.runDetails.publicEventId != '00000000-0000-0000-0000-000000000000';

  @override
  Widget build(BuildContext context) {
    if (!_hasEvent) return _emptyState();
    return _detailView(context);
  }

  // ── Empty state ────────────────────────────────────────────────────────────

  Widget _emptyState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(MaterialCommunityIcons.arrow_left, size: 48, color: _kTextMuted),
          SizedBox(height: 16),
          Text(
            'Select a run from the list\nto view details',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: _kTextSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }

  // ── Detail view ────────────────────────────────────────────────────────────

  Widget _detailView(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _heroImage(),
                _eventHeaderCard(),
                const SizedBox(height: 14),
                _infoGrid(),
                if (_latLon(edr.runDetails) != null) ...[
                  const SizedBox(height: 14),
                  _mapPreview(edr.runDetails),
                ],
                if (_shouldShowParticipants) ...[
                  const SizedBox(height: 14),
                  _participantsSection(),
                ],
                const SizedBox(height: 72), // room for action bar
              ],
            ),
          ),
        ),
        _actionBar(context),
      ],
    );
  }

  // ── Hero image ─────────────────────────────────────────────────────────────

  Widget _heroImage() {
    final rdm = edr.runDetails;
    final url = rdm.useFbImage == 1 ? rdm.extEventImage : rdm.eventImage;
    if ((url ?? '').isEmpty || !url!.startsWith('http')) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: HcNetworkImage(
          url,
          width: double.infinity,
          fit: BoxFit.fitWidth,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      ),
    );
  }

  // ── Event header card ──────────────────────────────────────────────────────

  Widget _eventHeaderCard() {
    final rdm = edr.runDetails;
    final eventName = (rdm.useFbRunDetails == 1 && rdm.extEventName != null)
        ? rdm.extEventName!
        : rdm.eventName;
    final daysUntil = _daysUntil(rdm.eventStartDatetime);
    final fees = _feesText(rdm);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFFFFCDD2), Color(0xFFFFF3E0)],
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((rdm.kennelLogo ?? '').isNotEmpty &&
                (rdm.kennelShortName ?? '').isNotEmpty) ...[
              ClipOval(
                child: KennelLogo(
                  kennelLogoUrl: rdm.kennelLogo!,
                  kennelShortName: rdm.kennelShortName!,
                  logoHeight: 70,
                  leftPadding: 0,
                  rightPadding: 0,
                ),
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eventName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _kTextPrimary,
                      height: 1.2,
                    ),
                  ),
                  if ((rdm.kennelName ?? '').isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      rdm.kennelName!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _kRed,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (rdm.isCountedRun == 1)
                        _badge(
                          'Run #${rdm.eventNumber}',
                          bg: const Color(0xFFF1F5F9),
                          fg: _kTextSecondary,
                        ),
                      _badge(
                        rdm.eventGeographicScope > 1
                            ? SPECIAL_EVENT_STRINGS.keys
                                .elementAt(rdm.eventGeographicScope)
                            : 'Normal run',
                        bg: const Color(0xFFEFF6FF),
                        fg: const Color(0xFF2563EB),
                      ),
                      _badge(
                        _relativeTime(daysUntil),
                        bg: daysUntil < 0
                            ? const Color(0xFFFEF3C7)
                            : const Color(0xFFF0FDF4),
                        fg: daysUntil < 0
                            ? const Color(0xFF92400E)
                            : const Color(0xFF15803D),
                      ),
                      if (fees.isNotEmpty)
                        _badge(
                          fees,
                          bg: const Color(0xFFF0FDF4),
                          fg: const Color(0xFF15803D),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, {required Color bg, required Color fg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: fg,
        ),
      ),
    );
  }

  // ── Info grid ──────────────────────────────────────────────────────────────

  Widget _infoGrid() {
    final rdm = edr.runDetails;
    final hasHares = (rdm.hares ?? '').isNotEmpty;
    final activeTags = _activeTags(rdm);

    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _whenCard(rdm)),
              const SizedBox(width: 14),
              Expanded(child: _whereCard(rdm)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (hasHares) ...[
                Expanded(child: _haresCard(rdm)),
                const SizedBox(width: 14),
              ],
              Expanded(child: _visibilityCard(rdm)),
            ],
          ),
        ),
        if (activeTags.isNotEmpty) ...[
          const SizedBox(height: 14),
          _tagsCard(activeTags),
        ],
      ],
    );
  }

  List<RunTag> _activeTags(RunDetailsModel rdm) {
    return RunTag.values.where((tag) {
      final group = tag.bitFlag ~/ 4294967296;
      final bit = tag.bitFlag & 0x7FFFFFFF;
      return (group == 1 && (bit & rdm.tags1) != 0) ||
             (group == 2 && (bit & rdm.tags2) != 0) ||
             (group == 4 && (bit & rdm.tags3) != 0);
    }).toList();
  }

  Widget _tagsCard(List<RunTag> tags) {
    return _infoCard(
      label: 'Event tags',
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [for (final tag in tags) _tagChip(tag)],
        ),
      ],
    );
  }

  Color _tagIconColor(RunTag tag) {
    return switch (tag) {
      RunTag.redDress => Colors.red,
      RunTag.fullMoon => Colors.amber.shade600,
      RunTag.familyHash => Colors.blue.shade600,
      RunTag.normalRun => Colors.green.shade600,
      RunTag.harriette => Colors.pink.shade400,
      RunTag.agm => Colors.purple.shade600,
      RunTag.drinkingPractice => Colors.orange.shade700,
      RunTag.hangoverRun => Colors.brown.shade400,
      RunTag.menOnly => Colors.blue.shade700,
      RunTag.womenOnly => Colors.pink.shade600,
      RunTag.kidsAllowed => Colors.lightBlue.shade400,
      RunTag.noKidsAllowed => Colors.red.shade400,
      RunTag.dogFriendly => Colors.brown.shade600,
      RunTag.noDogsAllowed => Colors.red.shade400,
      RunTag.bringFlashlight => Colors.amber.shade600,
      RunTag.waterOnTrail => Colors.blue.shade500,
      RunTag.swimStop => Colors.cyan.shade500,
      RunTag.nightRun => Colors.indigo.shade600,
      RunTag.shiggyRun => Colors.brown.shade500,
      RunTag.cityHash => Colors.blueGrey.shade600,
      RunTag.steepHills => Colors.green.shade700,
      RunTag.bikeHash => Colors.orange.shade600,
      RunTag.charityEvent => Colors.red.shade600,
      RunTag.campingHash => Colors.green.shade800,
      _ => Colors.grey.shade700,
    };
  }

  Widget _tagChip(RunTag tag) {
    final color = _tagIconColor(tag);
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 1.5),
            ),
            alignment: Alignment.center,
            child: Icon(tag.icon, size: 14, color: color),
          ),
          const SizedBox(width: 8),
          Text(
            tag.title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _kTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _whenCard(RunDetailsModel rdm) {
    return _infoCard(
      label: 'When',
      children: [
        _infoRow(null, DateFormat('EEEE, d MMMM yyyy').format(rdm.eventStartDatetime)),
        _infoRow(null, DateFormat('h:mm a').format(rdm.eventStartDatetime), muted: true),
      ],
    );
  }

  Widget _whereCard(RunDetailsModel rdm) {
    final venue = _venueName(rdm);
    final address = _address(rdm);
    return _infoCard(
      label: 'Where',
      children: [
        if (venue.isNotEmpty) _infoRow(null, venue),
        if (address.isNotEmpty) _infoRow(null, address, muted: true),
      ],
    );
  }

  Widget _haresCard(RunDetailsModel rdm) {
    return _infoCard(
      label: 'Hares',
      children: [_infoRow(null, rdm.hares ?? '')],
    );
  }

  Widget _visibilityCard(RunDetailsModel rdm) {
    return _infoCard(
      label: 'Visibility',
      children: [
        _infoRow(null, rdm.isVisible == 1 ? 'Visible' : 'Hidden'),
      ],
    );
  }

  Widget _infoCard({required String label, required List<Widget> children}) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: _kTextMuted,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String? label, String value, {bool muted = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: _kTextMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
          ],
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: muted ? FontWeight.w400 : FontWeight.w500,
              color: muted ? _kTextSecondary : _kTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Participants ───────────────────────────────────────────────────────────

  bool get _isFutureRun =>
      edr.runDetails.eventStartDatetime.isAfter(DateTime.now());

  List<ParticipantModel> get _rsvpList =>
      edr.participants.where((p) => p.rsvpState >= 2).toList();

  bool get _shouldShowParticipants {
    if (_isFutureRun) return _rsvpList.isNotEmpty;
    return edr.participants.isNotEmpty;
  }

  Widget _participantsSection() {
    if (_isFutureRun) return _rsvpSection();
    return _packSection();
  }

  Widget _packSection() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'THE PACK',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: _kTextMuted,
            ),
          ),
          const SizedBox(height: 12),
          ParticipantsTable(edr.participants),
        ],
      ),
    );
  }

  Widget _rsvpSection() {
    final rsvps = _rsvpList;
    final confirmed = rsvps.where((p) => p.rsvpState >= 3).length;
    final maybes = rsvps.where((p) => p.rsvpState == 2).length;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                "WHO'S COMING",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: _kTextMuted,
                ),
              ),
              const SizedBox(width: 8),
              _rsvpCountBadge('$confirmed Coming', const Color(0xFFDCFCE7), const Color(0xFF166534)),
              if (maybes > 0) ...[
                const SizedBox(width: 4),
                _rsvpCountBadge('+$maybes maybe',
                    const Color(0xFFFEF9C3), const Color(0xFF854D0E)),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Table(
            columnWidths: const {
              0: IntrinsicColumnWidth(),  // RSVP icon
              1: FlexColumnWidth(),       // Name (+ hare rabbit)
              2: IntrinsicColumnWidth(),  // Runs
              3: IntrinsicColumnWidth(),  // Haring
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              TableRow(
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                children: [
                  const SizedBox(width: 22),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('Name',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _kTextMuted)),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 6),
                    child: Text('Runs',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _kTextMuted)),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 6),
                    child: Text('Haring',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _kTextMuted)),
                  ),
                ],
              ),
              for (final p in rsvps) _rsvpRow(p),
            ],
          ),
        ],
      ),
    );
  }

  TableRow _rsvpRow(ParticipantModel p) {
    final isHare = p.isHare != 0;
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, right: 6),
          child: _rsvpStatusIcon(p, isHare),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            p.displayName,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _kTextPrimary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8, left: 12),
          child: Text(
            '${p.totalRunsThisKennel}',
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 13, color: _kTextSecondary),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8, left: 12),
          child: Text(
            '${p.totalHaringThisKennel}',
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 13, color: _kTextSecondary),
          ),
        ),
      ],
    );
  }

  Widget _rsvpStatusIcon(ParticipantModel p, bool isHare) {
    if (isHare) {
      return _iconCircle(
        const Color(0xFF7C3AED),
        const Icon(MaterialCommunityIcons.rabbit, size: 12, color: Colors.white),
      );
    }
    if (p.rsvpState == 2) {
      return _iconCircle(
        const Color(0xFFD97706),
        const Icon(Icons.question_mark_rounded, size: 12, color: Colors.white),
      );
    }
    // rsvpState >= 3: going
    return _iconCircle(
      const Color(0xFF16A34A),
      const Icon(Icons.check, size: 12, color: Colors.white),
    );
  }

  Widget _iconCircle(Color color, Widget icon) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: icon,
    );
  }

  Widget _rsvpCountBadge(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
    );
  }

  // ── Action bar ─────────────────────────────────────────────────────────────

  Widget _actionBar(BuildContext context) {
    final rdm = edr.runDetails;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _kBorder)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          if (controller.kennel.canManageRuns)
            _btn(
              'Delete',
              Icons.delete_outline,
              style: _Btn.danger,
              onPressed: () async {
                final confirm = await CoreUtilities.showAlert(
                      'Delete Run',
                      'Would you like to delete "${rdm.eventName}"?',
                      'Delete run',
                      showCancelButton: true,
                    ) ??
                    false;
                if (confirm && rdm.publicEventId != null) {
                  await controller.deleteEvent(rdm.publicEventId);
                }
              },
            ),
          const Spacer(),
          if (rdm.publicEventId != null)
            _btn(
              'Copy link',
              Icons.link,
              onPressed: () async {
                final isLocal =
                    web.window.location.href.contains('localhost');
                final url =
                    '${isLocal ? 'localhost:8080' : 'https://www.hashruns.org'}/${rdm.kennelUniqueShortName}/${rdm.absoluteEventNumber ?? rdm.eventNumber}';
                await Clipboard.setData(ClipboardData(text: url));
                if (!context.mounted) return;
                await IveCoreUtilities.showAlert(
                  context,
                  'Copy link',
                  'The link to this run was copied to your clipboard',
                  'OK',
                );
              },
            ),
          const SizedBox(width: 8),
          if (_mapUrl(rdm).isNotEmpty)
            _btn(
              'Map',
              Icons.map_outlined,
              onPressed: () {
                final url = _mapUrl(rdm);
                if (Uri.parse(url).isAbsolute) _openWindow(url, '_blank');
              },
            ),
          const SizedBox(width: 8),
          _btn(
            'Trail Chat',
            Icons.chat_bubble_outline,
            onPressed: () async {
              if (rdm.publicEventId == null) return;
              await Get.to<ChatSheetPage>(
                () => ChatSheetPage(
                  publicEventId: rdm.publicEventId!,
                  messageTitle: rdm.eventName,
                  eventName: rdm.eventName,
                ),
              );
              controller.resetBadgeCount(rdm.publicEventId!);
            },
          ),
          const SizedBox(width: 8),
          _btn(
            'Email',
            Icons.email_outlined,
            onPressed: () async => Get.to<EmailModel>(EmailPage.new),
          ),
          if (controller.kennel.canManageRuns ||
              controller.kennel.canManageHashCash) ...[
            const SizedBox(width: 8),
            _btn(
              'Edit Run',
              Icons.edit_outlined,
              style: _Btn.primary,
              onPressed: () async {
                await Get.to<RunEditPage>(
                  () => RunEditPage(
                    runData: rdm,
                    kennelData: controller.kennel,
                    isAddMode: false,
                  ),
                );
                controller.eventForSingleEventDetailsView.value =
                    await querySingleEvent(rdm.publicEventId ?? '');
              },
            ),
          ],
        ],
      ),
    );
  }

  // ── Shared widgets ─────────────────────────────────────────────────────────

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: child,
    );
  }

  Widget _btn(
    String label,
    IconData icon, {
    required VoidCallback onPressed,
    _Btn style = _Btn.secondary,
  }) {
    final Color bg, border, fg;
    switch (style) {
      case _Btn.primary:
        bg = _kRed;
        border = _kRed;
        fg = Colors.white;
      case _Btn.danger:
        bg = Colors.white;
        border = const Color(0xFFFCA5A5);
        fg = _kRed;
      case _Btn.secondary:
        bg = Colors.white;
        border = _kBorder;
        fg = const Color(0xFF374151);
    }
    return TextButton(
      style: TextButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        side: BorderSide(color: border),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle:
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  int _daysUntil(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(dt.year, dt.month, dt.day);
    return eventDay.difference(today).inDays;
  }

  String _relativeTime(int days) {
    if (days == 0) return 'Today';
    if (days == 1) return 'Tomorrow';
    if (days == -1) return 'Yesterday';
    if (days > 0) {
      if (days <= 14) return 'in $days days';
      if (days <= 30) {
        final w = days ~/ 7;
        return 'in $w ${w == 1 ? 'week' : 'weeks'}';
      }
      if (days <= 365) {
        final m = days ~/ 30;
        return 'in $m ${m == 1 ? 'month' : 'months'}';
      }
      final y = days ~/ 365;
      return 'in $y ${y == 1 ? 'year' : 'years'}';
    }
    final abs = days.abs();
    if (abs <= 14) return '$abs days ago';
    if (abs <= 30) {
      final w = abs ~/ 7;
      return '$w ${w == 1 ? 'week' : 'weeks'} ago';
    }
    if (abs <= 365) {
      final m = abs ~/ 30;
      return '$m ${m == 1 ? 'month' : 'months'} ago';
    }
    final y = abs ~/ 365;
    return '$y ${y == 1 ? 'year' : 'years'} ago';
  }

  String _feesText(RunDetailsModel rdm) {
    final mFee =
        rdm.eventPriceForMembers ?? rdm.kennelDefaultEventPriceForMembers ?? 0;
    final gFee = rdm.eventPriceForNonMembers ??
        rdm.kennelDefaultEventPriceForNonMembers ??
        0;
    if (mFee == 0 && gFee == 0) return '';
    final sym = (rdm.currencySymbol ?? '^').replaceAll('^', '');
    final dec = rdm.digitsAfterDecimal ?? 2;
    String fmt(num v) => '$sym${v.toDouble().toStringAsFixed(dec)}';
    if (mFee == gFee) return fmt(mFee);
    return '${fmt(mFee)} members · ${fmt(gFee)} guests';
  }

  String _venueName(RunDetailsModel rdm) =>
      (rdm.useFbLocation == 1 ? rdm.extLocationOneLineDesc : rdm.locationOneLineDesc) ?? '';

  String _address(RunDetailsModel rdm) {
    final ext = rdm.useFbLocation == 1;
    return [
      ext ? (rdm.extLocationStreet ?? '') : (rdm.locationStreet ?? ''),
      ext ? (rdm.extLocationCity ?? '') : (rdm.locationCity ?? ''),
      ext ? (rdm.extLocationPostCode ?? '') : (rdm.locationPostCode ?? ''),
      ext ? (rdm.extLocationRegion ?? '') : (rdm.locationRegion ?? ''),
      ext ? (rdm.extLocationCountry ?? '') : (rdm.locationCountry ?? ''),
    ].where((s) => s.isNotEmpty).join(', ');
  }

  (double, double)? _latLon(RunDetailsModel rdm) {
    if ((rdm.useFbLatLon != 0) &&
        rdm.fbLatitude != null &&
        rdm.fbLongitude != null &&
        rdm.fbLongitude!.abs() <= 180) {
      return (rdm.fbLatitude!, rdm.fbLongitude!);
    }
    if ((rdm.useFbLatLon == 0) &&
        rdm.hcLatitude != null &&
        rdm.hcLongitude != null &&
        rdm.hcLongitude!.abs() <= 180) {
      return (rdm.hcLatitude!, rdm.hcLongitude!);
    }
    return null;
  }

  Widget _mapPreview(RunDetailsModel rdm) {
    final coords = _latLon(rdm);
    if (coords == null) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: _MapPreviewWidget(
        key: ValueKey(rdm.publicEventId),
        lat: coords.$1,
        lon: coords.$2,
        onTap: () {
          final url = _mapUrl(rdm);
          if (Uri.parse(url).isAbsolute) _openWindow(url, '_blank');
        },
      ),
    );
  }

  String _mapUrl(RunDetailsModel rdm) {
    if ((rdm.useFbLatLon != 0) &&
        (rdm.fbLongitude != null) &&
        rdm.fbLongitude!.abs() <= 180) {
      return 'https://www.google.com/maps/search/?api=1&query=${rdm.fbLatitude},${rdm.fbLongitude}';
    }
    if ((rdm.useFbLatLon == 0) &&
        (rdm.hcLongitude != null) &&
        rdm.hcLongitude!.abs() <= 180) {
      return 'https://www.google.com/maps/search/?api=1&query=${rdm.hcLatitude},${rdm.hcLongitude}';
    }
    final address = _address(rdm).trim();
    if (address.isEmpty) return '';
    return 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}';
  }
}

enum _Btn { primary, secondary, danger }

// ── Map preview widget ──────────────────────────────────────────────────────

class _MapPreviewWidget extends StatelessWidget {
  const _MapPreviewWidget({
    super.key,
    required this.lat,
    required this.lon,
    required this.onTap,
  });

  final double lat;
  final double lon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final mapController = geo_map.MapController(
      location: LatLng(Angle.degree(lat), Angle.degree(lon)),
      zoom: 15,
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          height: 250,
          width: double.infinity,
          child: Stack(
            children: [
              geo_map.MapLayout(
                controller: mapController,
                builder: (context, transformer) {
                  final pos = transformer.toOffset(
                    LatLng(Angle.degree(lat), Angle.degree(lon)),
                  );
                  return Stack(
                    children: [
                      geo_map.TileLayer(
                        builder: (context, x, y, z) {
                          final url =
                              'https://www.google.com/maps/vt/pb=!1m4!1m3!1i$z!2i$x!3i$y!2m3!1e0!2sm!3i420120488!3m7!2sen!5e1105!12m4!1e68!2m2!1sset!2sRoadmap!4e0!5m1!1e0!23i4111425';
                          return Image.network(url, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const SizedBox.shrink());
                        },
                      ),
                      Positioned(
                        left: pos.dx - 24,
                        top: pos.dy - 48,
                        child: IgnorePointer(
                          child: Image.asset(
                            'images/maps/map_pin_foot.png',
                            height: 48,
                            width: 48,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              Positioned(
                right: 8,
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.open_in_new,
                    size: 16,
                    color: Color(0xFF374151),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
