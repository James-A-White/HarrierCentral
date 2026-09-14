import 'package:harrier_central/imports.dart';

/// A chat with its own app bar, back button and pin control.
///
/// Three call sites were each building their own Scaffold + AppBar around
/// ChatPage, and a fourth — the chat rooms on the Support page — was pushing
/// ChatPage bare, so a room opened with NO app bar and no way back (fixed
/// here, E9.F1.S8). One wrapper means the pin icon exists everywhere a chat
/// does, rather than on whichever screens got updated.
///
/// ChatPage used as a TAB BODY (inside RunDetailsPage) keeps using ChatPage
/// directly — that screen supplies its own app bar, and nesting a second one
/// would put two back buttons on the page.
class ChatScaffold extends StatefulWidget {
  const ChatScaffold({
    required this.title,
    required this.eventId,
    required this.publicEventId,
    this.isKennelThread = false,
    this.roomType,
    super.key,
  });

  final String title;
  final String eventId;
  final String publicEventId;
  final bool isKennelThread;
  final int? roomType;

  /// A platform-wide room. It has no event or kennel id — it is named by its
  /// room type alone.
  factory ChatScaffold.room({
    required int roomType,
    required String title,
    Key? key,
  }) => ChatScaffold(
    title: title,
    eventId: '',
    publicEventId: '',
    roomType: roomType,
    key: key,
  );

  @override
  State<ChatScaffold> createState() => _ChatScaffoldState();
}

class _ChatScaffoldState extends State<ChatScaffold> {
  bool _pinned = false;
  bool _pinKnown = false;
  bool _saving = false;

  bool get _isRoom => widget.roomType != null;

  @override
  void initState() {
    super.initState();
    unawaited(_loadPin());
  }

  Future<void> _loadPin() async {
    // A room's pin lives in a bitfield on the hasher row, and the room list
    // already carries it, so it is read from there rather than re-derived.
    if (_isRoom) {
      final List<ChatRoom>? rooms = await ChatRoomService.fetchRooms();
      final ChatRoom? mine = rooms
          ?.where((ChatRoom r) => r.roomType == widget.roomType)
          .firstOrNull;
      if (!mounted) return;
      setState(() {
        _pinned = mine?.pinned ?? true;
        _pinKnown = mine != null;
      });
      return;
    }

    final bool p = await ChatPinService.isPinned(
      eventId: widget.isKennelThread ? null : widget.eventId,
      kennelId: widget.isKennelThread ? widget.eventId : null,
    );
    if (!mounted) return;
    setState(() {
      _pinned = p;
      _pinKnown = true;
    });
  }

  Future<void> _togglePin() async {
    if (_saving) return;
    final bool next = !_pinned;
    // Optimistic: the icon moves at once, because a control that waits on a
    // round trip reads as broken. A failure puts it back.
    setState(() {
      _pinned = next;
      _saving = true;
    });

    final bool ok = await ChatPinService.setPin(
      eventId: (_isRoom || widget.isKennelThread) ? null : widget.eventId,
      kennelId: widget.isKennelThread ? widget.eventId : null,
      roomType: widget.roomType,
      pinned: next,
    );

    if (!mounted) return;
    setState(() {
      if (!ok) _pinned = !next;
      _saving = false;
    });
    if (!ok) {
      Get.snackbar(
        'Not saved',
        'That chat could not be ${next ? 'pinned' : 'unpinned'}. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: themeButtonColors,
        foregroundColor: Colors.white,
        actions: <Widget>[
          // Hidden until the state is known, rather than guessing: an icon
          // that shows "unpinned" and then flips a moment later reads as the
          // app having undone the hasher's choice.
          if (_pinKnown)
            IconButton(
              tooltip: _pinned ? 'Pinned — tap to unpin'
                               : 'Not pinned — tap to pin',
              // Same glyph as the settings console and the chat list, so
              // "pinned" looks like one thing across the app. An outline pin
              // was too close to the filled one to tell apart at a glance.
              icon: PinGlyph(
                pinned: _pinned,
                size: 24,
                color: Colors.white,
              ),
              onPressed: _saving ? null : () => unawaited(_togglePin()),
            ),
        ],
      ),
      body: ChatPage(
        eventId: widget.eventId,
        publicEventId: widget.publicEventId,
        isKennelThread: widget.isKennelThread,
        roomType: widget.roomType,
      ),
    );
  }
}
