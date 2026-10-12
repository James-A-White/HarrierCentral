import 'dart:ui' show PathMetric;

import 'package:harrier_central/imports.dart';
import 'package:harrier_central/widgets/hc_badges.dart' as badges;

/// Where this hasher and I stand on direct messages (E9.F1.S32).
enum HasherDmState {
  /// No friendship yet — never asked, asked and waiting, or declined. A tap
  /// asks (or opens at once, when they accept anyone).
  notFriends,

  /// Friends, nothing said yet.
  friends,

  /// Friends with a conversation.
  talked,
}

/// The chat bubble on a hasher's row, wherever individual hashers are
/// listed — the RSVP pack first (James, 2026-10-12: "anywhere in the app
/// where you see individual hashers there should be a way to open a direct
/// message with them"). Three looks, read reactively off the DM rows the
/// Chats list already holds:
///
///   talked     → solid GREEN bubble (with the red unread count, as on a card)
///   friends    → GREEN outline bubble
///   notFriends → GREY dashed outline bubble
///
/// Green = friend, grey = not yet (James, 2026-10-12: the all-white looks
/// were too alike to tell apart at a glance).
///
/// A tap on a friend opens the thread straight from the row's data; anyone
/// else goes through `messageHasher`, so the server's rules — their DM
/// setting, a block — decide, exactly as from a chat message.
///
/// Name the hasher by [hasherId] — the internal id every list built from
/// the user sync holds — or by [publicHasherId], which the server-built
/// lists (Find a hasher, By Hasher) carry. Draws nothing on my own row.
/// [onDark] is for the jungle; off, it is drawn for a white card.
class HasherDmBubble extends StatelessWidget {
  const HasherDmBubble({
    this.hasherId,
    this.publicHasherId,
    required this.displayName,
    this.photo,
    this.onDark = true,
    this.size = 26,
    this.dense = false,
    super.key,
  });

  final String? hasherId;
  final HcId? publicHasherId;
  final String displayName;
  final String? photo;
  final bool onDark;
  final double size;

  /// For a row of plain text lines (the leaderboard), where a full-size
  /// button would double every row's height.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final HcId? id = (hasherId ?? '').isEmpty ? null : HcId(hasherId!);
    final HcId? pub = (publicHasherId ?? '').isEmpty ? null : publicHasherId;
    if (id == null && pub == null) return const SizedBox.shrink();
    // Not on my own row: nobody messages themselves.
    if (id != null && id == HcId(getStringPref(StringPrefsEnum.userId) ?? '')) {
      return const SizedBox.shrink();
    }
    if (pub != null &&
        pub == HcId(getStringPref(StringPrefsEnum.publicHasherId) ?? '')) {
      return const SizedBox.shrink();
    }

    final NotificationService? ns = notificationServiceOrNull;
    // No service means nothing reactive to read, and an Obx that reads no
    // Rx throws — draw the not-yet bubble outside one.
    if (ns == null) return _button(HasherDmState.notFriends, 0, null);
    return Obx(() {
      final EventChatSummary? row = ns.unreadChatRuns.firstWhereOrNull(
        (EventChatSummary s) =>
            s.isDmThread &&
            ((id != null && s.otherHasherId == id) ||
                (pub != null && s.otherPublicHasherId == pub)),
      );
      final HasherDmState state = row == null
          ? HasherDmState.notFriends
          : (row.messageCount ?? 0) > 0
          ? HasherDmState.talked
          : HasherDmState.friends;
      return _button(state, row?.badgeCount ?? 0, row);
    });
  }

  Widget _button(HasherDmState state, int unread, EventChatSummary? row) {
    return IconButton(
      // Compact: it sits at the end of rows that are already full.
      visualDensity: VisualDensity.compact,
      padding: dense ? EdgeInsets.zero : null,
      constraints: dense
          ? const BoxConstraints.tightFor(width: 36, height: 28)
          : null,
      tooltip: state == HasherDmState.notFriends
          ? 'Ask $displayName to chat'
          : 'Message $displayName',
      onPressed: () => unawaited(_open(row)),
      icon: _icon(state, unread),
    );
  }

  Widget _icon(HasherDmState state, int unread) {
    // Bright enough to read on the jungle; deeper on a white card.
    final Color friend = onDark
        ? Colors.lightGreenAccent.shade400
        : Colors.green.shade700;
    final Color stranger = onDark ? Colors.grey.shade400 : Colors.grey.shade600;
    switch (state) {
      case HasherDmState.talked:
        final Icon solid = Icon(
          MaterialCommunityIcons.chat,
          color: friend,
          size: size,
        );
        if (unread <= 0) return solid;
        return badges.Badge(
          position: badges.BadgePosition.topEnd(top: -6, end: -8),
          badgeContent: Container(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            constraints: const BoxConstraints(minWidth: 14),
            height: 13,
            child: AutoSizeText(
              unread.toString(),
              textAlign: TextAlign.center,
              maxLines: 1,
              minFontSize: 10,
              maxFontSize: 13,
              style: ts_badge,
            ),
          ),
          badgeStyle: badges.BadgeStyle(
            badgeColor: Colors.red.shade800,
            padding: const EdgeInsets.all(4),
          ),
          child: solid,
        );
      case HasherDmState.friends:
        return Icon(
          MaterialCommunityIcons.chat_outline,
          color: friend,
          size: size,
        );
      case HasherDmState.notFriends:
        return CustomPaint(
          size: Size.square(size),
          painter: _DashedChatBubblePainter(color: stranger),
        );
    }
  }

  Future<void> _open(EventChatSummary? row) async {
    final HcId? thread = row?.threadId;
    if (row != null && thread != null) {
      await ChatPageController.openDirectMessage(
        threadId: thread,
        otherPublicHasherId: row.otherPublicHasherId ?? HcId.empty,
        otherDisplayName: (row.otherDisplayName ?? '').trim().isEmpty
            ? displayName
            : row.otherDisplayName!.trim(),
        otherPhoto: row.otherPhoto ?? photo,
      );
    } else {
      await messageHasher(
        publicHasherId,
        displayName,
        hasherId: (hasherId ?? '').isEmpty ? null : HcId(hasherId!),
      );
    }
    // A thread opened (or a hasher who accepts anyone became a friend):
    // re-read the rows so this bubble and every other one catch up.
    unawaited(notificationServiceOrNull?.getEventChatMessageCounts());
  }
}

/// The Material Design Icons `chat` outline, stroked in dashes — the bubble
/// for someone who is not (yet) a friend. Drawn rather than a glyph because
/// no icon font has a dashed bubble; the path is the MDI one, so it sits
/// exactly where `chat` and `chat_outline` do.
class _DashedChatBubblePainter extends CustomPainter {
  _DashedChatBubblePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // MDI "chat", in its 24-unit box.
    final Path bubble = Path()
      ..moveTo(12, 3)
      ..cubicTo(17.5, 3, 22, 6.58, 22, 11)
      ..cubicTo(22, 15.42, 17.5, 19, 12, 19)
      ..cubicTo(10.76, 19, 9.57, 18.82, 8.47, 18.5)
      ..cubicTo(5.55, 21, 2, 21, 2, 21)
      ..cubicTo(4.33, 18.67, 4.7, 17.1, 4.75, 16.5)
      ..cubicTo(3.05, 15.07, 2, 13.13, 2, 11)
      ..cubicTo(2, 6.58, 6.5, 3, 12, 3)
      ..close();
    final double k = size.shortestSide / 24;
    final Path scaled = bubble.transform(
      (Matrix4.identity()..scaleByDouble(k, k, 1, 1)).storage,
    );
    final Paint pen = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8 * k
      ..strokeCap = StrokeCap.round;
    final double on = 2.6 * k;
    final double off = 2.0 * k;
    for (final PathMetric m in scaled.computeMetrics()) {
      double d = 0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + on), pen);
        d += on + off;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedChatBubblePainter old) => old.color != color;
}
