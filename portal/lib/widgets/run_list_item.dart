import 'package:hcportal/imports.dart';
import 'package:intl/intl.dart';

class RunListItem extends StatelessWidget {
  const RunListItem({
    required this.event,
    required this.onTap,
    this.isSelected = false,
    super.key,
  });

  final RunListModel event;
  final VoidCallback? onTap;
  final bool isSelected;

  static const _stripHeight = 80.0;
  static const _radius = 10.0;
  static const _red = Color(0xFFB91C1C);
  static const _darkSlate = Color(0xFF1E293B);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
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
            _buildStrip(),
            _buildBody(),
          ],
        ),
      ),
    );
  }

  // ── Image strip ────────────────────────────────────────────────────────────

  String? get _resolvedImageUrl {
    if (event.useFbImage == 1) {
      final url = event.extEventImage ?? '';
      if (url.startsWith('http')) return url;
    }
    final url = event.eventImage ?? '';
    if (url.startsWith('http')) return url;
    return null;
  }

  Widget _buildStrip() {
    final imageUrl = _resolvedImageUrl;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(_radius)),
      child: Stack(
        children: [
          // Determines strip height — image at natural ratio, or fixed logo bg
          if (imageUrl != null)
            Image.network(
              imageUrl,
              width: double.infinity,
              fit: BoxFit.fitWidth,
              errorBuilder: (_, __, ___) => _logoBackground(),
            )
          else
            _logoBackground(),
          if (event.isCountedRun == 1)
            Positioned(top: 8, right: 9, child: _runNumBadge()),
          Positioned(
            bottom: 7,
            left: 10,
            right: event.isCountedRun == 1 ? 60 : 12,
            child: Text(
              event.eventName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                shadows: [
                  Shadow(
                    offset: Offset(0, 1),
                    blurRadius: 8,
                    color: Color(0xCC000000),
                  ),
                  Shadow(
                    offset: Offset(0, 0),
                    blurRadius: 3,
                    color: Color(0xAA000000),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _logoBackground() {
    return SizedBox(
      height: _stripHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: _darkSlate),
          Center(
            child: KennelLogo(
              kennelLogoUrl: event.kennelLogo,
              kennelShortName: event.kennelShortName,
              logoHeight: 46,
              leftPadding: 0,
              rightPadding: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _runNumBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
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

  // ── Card body ──────────────────────────────────────────────────────────────

  Widget _buildBody() {
    final dateStr =
        DateFormat("E, MMM d 'at' h:mm a").format(event.eventStartDatetime);
    final relStr = _relativeTime(event.daysUntilEvent);

    return Padding(
      padding: const EdgeInsets.fromLTRB(11, 8, 11, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _row(
            icon: MaterialCommunityIcons.clock_outline,
            text: '$dateStr  ·  $relStr',
          ),
          const SizedBox(height: 2),
          _row(
            icon: MaterialCommunityIcons.map_marker_outline,
            text: event.eventCityAndCountry,
            muted: true,
          ),
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
            color:
                muted ? const Color(0xFF64748B) : const Color(0xFF334155),
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

  // ── Helpers ────────────────────────────────────────────────────────────────

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
