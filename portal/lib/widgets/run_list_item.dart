import 'package:hcportal/imports.dart';
import 'package:intl/intl.dart';

class RunListItem extends StatelessWidget {
  const RunListItem({
    required this.event,
    required this.onTap,
    this.isSelected = false,
    this.chatCount = 0,
    super.key,
  });

  final RunListModel event;
  final VoidCallback? onTap;
  final bool isSelected;
  final int chatCount;

  static const _radius = 10.0;
  static const _red = Color(0xFFB91C1C);

  // Header strip colour — varies by event type; grey if hidden.
  static Color _typeColor(int scope, bool visible) {
    if (!visible) return const Color(0xFF94A3B8); // hidden → slate-400
    switch (scope) {
      case 1:
        return const Color(0xFF2563EB); // Normal run → blue-600
      case 2:
        return const Color(0xFF0891B2); // Special local → cyan-600
      case 3:
        return const Color(0xFF7C3AED); // Regional/state → violet-600
      case 4:
        return const Color(0xFFEA580C); // National → orange-600
      case 5:
        return const Color(0xFFDB2777); // Continental → pink-600
      case 6:
        return const Color(0xFFD97706); // World → amber-600
      case 7:
        return const Color(0xFF4F46E5); // Other → indigo-600
      default:
        return const Color(0xFF475569); // Not specified → slate-600
    }
  }

  bool get _isVisible => event.isVisible == 1;

  String? get _resolvedImageUrl {
    if (event.useFbImage == 1) {
      final url = event.extEventImage ?? '';
      if (url.startsWith('http')) return url;
    }
    final url = event.eventImage ?? '';
    if (url.startsWith('http')) return url;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _isVisible ? Colors.white : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(_radius),
          border: Border.all(
            color: isSelected ? _red : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? _red.withValues(alpha: 0.10)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: isSelected ? 8 : 3,
              spreadRadius: isSelected ? 2 : 0,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            if (_resolvedImageUrl != null) _buildImage(),
            _buildBody(),
          ],
        ),
      ),
    );
  }

  // ── Coloured header strip ──────────────────────────────────────────────────

  Widget _buildHeader() {
    final color = _typeColor(event.eventGeographicScope, _isVisible);
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(_radius)),
      child: Container(
        color: color,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        child: Row(
          children: [
            Expanded(
              child: Text(
                event.eventName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 4,
                      color: Color(0x44000000),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (event.isCountedRun == 1) ...[
              const SizedBox(width: 8),
              _runNumBadge(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _runNumBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '#${event.eventNumber}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ── Event image (below header, full-width, 100 % opacity) ─────────────────

  Widget _buildImage() {
    return HcNetworkImage(
      _resolvedImageUrl!,
      width: double.infinity,
      fit: BoxFit.fitWidth,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
  }

  // ── Card body ──────────────────────────────────────────────────────────────

  Widget _buildBody() {
    final dateStr =
        DateFormat("E, MMM d 'at' h:mm a").format(event.eventStartDatetime);
    final relStr = _relativeTime(event.daysUntilEvent);

    return Padding(
      padding: const EdgeInsets.fromLTRB(11, 8, 11, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _row(
                  icon: Icons.calendar_month_outlined,
                  text: '$dateStr  ·  $relStr',
                ),
                const SizedBox(height: 2),
                _row(
                  icon: MaterialCommunityIcons.map_marker_outline,
                  text: event.eventCityAndCountry,
                  muted: true,
                ),
                if ((event.locationOneLineDesc ?? '').isNotEmpty) ...[
                  const SizedBox(height: 2),
                  _row(
                    icon: Icons.place_outlined,
                    text: event.locationOneLineDesc!,
                    muted: true,
                  ),
                ],
                if ((event.hares ?? '').isNotEmpty) ...[
                  const SizedBox(height: 2),
                  _row(
                    icon: MaterialCommunityIcons.rabbit,
                    text: event.hares!,
                    muted: true,
                  ),
                ],
                if (event.eventGeographicScope > 1) ...[
                  const SizedBox(height: 6),
                  _specialChip(),
                ],
              ],
            ),
          ),
          if (chatCount > 0) ...[
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: _chatBadge(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _chatBadge() {
    return Container(
      constraints: const BoxConstraints(minWidth: 24),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: _red,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        chatCount.toString(),
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _row({
    required IconData icon,
    required String text,
    bool muted = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(
            icon,
            size: 14,
            color: muted ? const Color(0xFF64748B) : const Color(0xFF334155),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: muted
                  ? const Color(0xFF475569)
                  : const Color(0xFF1E293B),
              height: 1.4,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _specialChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        SPECIAL_EVENT_STRINGS.keys.elementAt(event.eventGeographicScope),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1D4ED8),
        ),
      ),
    );
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
}
