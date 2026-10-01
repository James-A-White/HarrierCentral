import 'package:flutter_chat_core/flutter_chat_core.dart' as core;
import 'package:intl/intl.dart';
import 'package:harrier_central/imports.dart';

/// Bubbles for the chat's photo and location messages (E9.F1.S11/S12,
/// 2026-09-29). They share the text bubble's shape and colours, from the same
/// ChatTheme, so the three kinds read as one conversation.
///
/// Taps and long presses are not handled here: the chat library wraps every
/// bubble in a GestureDetector that calls ChatPageController.handleMessageTap
/// / handleMessageLongPress, which know what the message is.

/// Metadata keys a location card carries (set by ChatPageController).
const String kChatLocationLatKey = 'hcLat';
const String kChatLocationLngKey = 'hcLng';

/// The point a location message shows, or null when [message] is not one.
ChatLocation? chatLocationOf(core.Message message) {
  if (message is! core.CustomMessage) return null;
  final Object? lat = message.metadata?[kChatLocationLatKey];
  final Object? lng = message.metadata?[kChatLocationLngKey];
  if (lat is! num || lng is! num) return null;
  return ChatLocation(lat.toDouble(), lng.toDouble());
}

/// sending → spinner, sent → one tick (the server took it), delivered → two
/// ticks (its own push came back to this device, or the server handed the
/// message back on a fetch), error → a warning.
///
/// Drawn here rather than through flutter_chat_core's getIconForStatus,
/// which returns the SAME single Icons.check for sent and delivered — the
/// upgrade in ChatPageController._upgradeOwnMessagesToDelivered would be
/// invisible.
Widget chatStatusIcon(core.MessageStatus status, Color? colour) {
  switch (status) {
    case core.MessageStatus.sending:
      return SizedBox(
        width: 10,
        height: 10,
        child: CircularProgressIndicator(color: colour, strokeWidth: 1.5),
      );
    case core.MessageStatus.error:
      return const Icon(
        Icons.error_outline,
        size: 15,
        color: Colors.amberAccent,
      );
    case core.MessageStatus.sent:
      return Icon(Icons.check, size: 15, color: colour);
    case core.MessageStatus.delivered:
      return Icon(Icons.done_all, size: 15, color: colour);
    // Read by the other hasher (DMs, E9.F1.S24): the same double tick in a
    // bright green that reads on the blue bubble — WhatsApp's blue would
    // vanish against it.
    case core.MessageStatus.seen:
      return const Icon(Icons.done_all, size: 15, color: Color(0xFF69F0AE));
  }
}

/// The time, and — on MY bubbles only — the tick. Null when there is
/// neither to show.
Widget? chatTimeAndStatus(
  core.Message message, {
  required bool isSentByMe,
  required TextStyle style,
  required DateFormat timeFormat,
}) {
  final DateTime? sent = message.resolvedTime;
  final core.MessageStatus? status = message.resolvedStatus;
  if (sent == null && !(isSentByMe && status != null)) return null;
  return Row(
    mainAxisSize: MainAxisSize.min,
    spacing: 3,
    children: <Widget>[
      if (sent != null) Text(timeFormat.format(sent.toLocal()), style: style),
      if (isSentByMe && status != null) chatStatusIcon(status, style.color),
    ],
  );
}

/// A photo in the chat, whole and at its own aspect ratio (CLAUDE.md photo
/// rule): the image is only BOUNDED — never given a shape — so a portrait
/// stays tall, a panorama stays wide, and nobody at the edge is cut off.
class ChatImageBubble extends StatelessWidget {
  const ChatImageBubble({
    required this.message,
    required this.isSentByMe,
    required this.theme,
    required this.timeFormat,
    super.key,
  });

  final core.ImageMessage message;
  final bool isSentByMe;
  final core.ChatTheme theme;
  final DateFormat timeFormat;

  static const double _maxWidth = 240;
  static const double _maxHeight = 320;

  /// The space the photo will take once it has loaded, so the list does not
  /// jump when it does. Known for my own photos (decoded before upload);
  /// others' arrive without dimensions and get a neutral box.
  Size get _placeholderSize {
    final double? w = message.width;
    final double? h = message.height;
    if (w == null || h == null || w <= 0 || h <= 0) {
      return const Size(_maxWidth, _maxWidth * 0.75);
    }
    final double scale = <double>[
      _maxWidth / w,
      _maxHeight / h,
      1,
    ].reduce((double a, double b) => a < b ? a : b);
    return Size(w * scale, h * scale);
  }

  Widget _placeholder(Color fg, {bool broken = false}) {
    final Size size = _placeholderSize;
    return SizedBox(
      width: size.width,
      height: size.height,
      child: Center(
        child: broken
            ? Icon(Icons.broken_image_outlined, color: fg, size: 36)
            : SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(color: fg, strokeWidth: 2),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color bg = isSentByMe
        ? theme.colors.primary
        : theme.colors.surfaceContainer;
    final Color fg = isSentByMe
        ? theme.colors.onPrimary
        : theme.colors.onSurface;
    final TextStyle time = theme.typography.labelSmall.copyWith(
      color: fg.withValues(alpha: 0.7),
    );

    final String source = message.source;
    final bool isRemote = source.startsWith('http');
    final Widget image = isRemote
        ? Image(
            image: CachedNetworkImageProvider(source),
            fit: BoxFit.contain,
            frameBuilder: (_, Widget child, int? frame, bool sync) =>
                (frame == null && !sync) ? _placeholder(fg) : child,
            errorBuilder: (_, _, _) => _placeholder(fg, broken: true),
          )
        : Image.file(
            File(source),
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => _placeholder(fg, broken: true),
          );

    final Widget? stamp = chatTimeAndStatus(
      message,
      isSentByMe: isSentByMe,
      style: time,
      timeFormat: timeFormat,
    );

    return ClipRRect(
      borderRadius: theme.shape,
      child: Container(
        color: bg,
        padding: const EdgeInsets.all(4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Bounded, never shaped or clipped: the photo keeps its own
            // aspect ratio inside these limits.
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: _maxWidth,
                maxHeight: _maxHeight,
              ),
              child: image,
            ),
            if (stamp != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 2),
                child: stamp,
              ),
          ],
        ),
      ),
    );
  }
}

/// A location in the chat: a pin, "Location" and the coordinates. Tapping
/// it opens the map app, the same way the run pin does.
class ChatLocationCard extends StatelessWidget {
  const ChatLocationCard({
    required this.message,
    required this.location,
    required this.isSentByMe,
    required this.theme,
    required this.timeFormat,
    super.key,
  });

  final core.Message message;
  final ChatLocation location;
  final bool isSentByMe;
  final core.ChatTheme theme;
  final DateFormat timeFormat;

  @override
  Widget build(BuildContext context) {
    final Color bg = isSentByMe
        ? theme.colors.primary
        : theme.colors.surfaceContainer;
    final Color fg = isSentByMe
        ? theme.colors.onPrimary
        : theme.colors.onSurface;
    final TextStyle title = theme.typography.bodyMedium.copyWith(
      color: fg,
      fontWeight: FontWeight.w600,
    );
    final TextStyle coords = theme.typography.bodySmall.copyWith(color: fg);
    final TextStyle time = theme.typography.labelSmall.copyWith(
      color: fg.withValues(alpha: 0.7),
    );
    final Widget? stamp = chatTimeAndStatus(
      message,
      isSentByMe: isSentByMe,
      style: time,
      timeFormat: timeFormat,
    );

    return ClipRRect(
      borderRadius: theme.shape,
      child: Container(
        color: bg,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.location_on,
                  size: 34,
                  color: isSentByMe ? Colors.white : hc_red,
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text('Location', style: title),
                    Text(location.display, style: coords),
                  ],
                ),
              ],
            ),
            if (stamp != null)
              Padding(padding: const EdgeInsets.only(top: 4), child: stamp),
          ],
        ),
      ),
    );
  }
}
