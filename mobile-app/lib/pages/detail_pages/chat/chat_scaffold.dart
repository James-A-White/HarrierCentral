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
///
/// A DIRECT MESSAGE (E9.F1.S7) has no pin; its app bar shows the other
/// party's photo and name, and a menu: Mute / Unmute, Block, End
/// conversation. Its live state travels in a [DmThreadState] shared with
/// the page, so the menu and the composer agree without a registry lookup.
class ChatScaffold extends StatefulWidget {
  const ChatScaffold({
    required this.title,
    required this.eventId,
    required this.publicEventId,
    this.isKennelThread = false,
    this.roomType,
    this.dmState,
    super.key,
  });

  final String title;
  final String eventId;
  final String publicEventId;
  final bool isKennelThread;
  final int? roomType;
  final DmThreadState? dmState;

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

  /// A direct message thread with one other hasher.
  factory ChatScaffold.dm({
    required HcId threadId,
    required HcId otherPublicHasherId,
    required String otherDisplayName,
    String? otherPhoto,
    Key? key,
  }) => ChatScaffold(
    title: otherDisplayName,
    eventId: '',
    publicEventId: '',
    dmState: DmThreadState(
      threadId: threadId,
      otherPublicHasherId: otherPublicHasherId,
      otherDisplayName: otherDisplayName,
      otherPhoto: otherPhoto,
    ),
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
  bool get _isDm => widget.dmState != null;

  @override
  void initState() {
    super.initState();
    if (!_isDm) unawaited(_loadPin());
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

  // ── DM menu ───────────────────────────────────────────────────────────────

  Future<void> _toggleMute(DmThreadState dm) async {
    if (_saving) return;
    final bool next = !dm.muted.value;
    setState(() => _saving = true);
    final bool? stored = await DirectMessageService.setMute(
      dm.threadId,
      mute: next,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (stored == null) {
      hcSnack(
        'That could not be saved. Please try again.',
        error: true,
      );
      return;
    }
    dm.muted.value = stored;
    hcSnack(stored ? 'Muted' : 'Unmuted');
  }

  Future<void> _block(DmThreadState dm) async {
    final String name = dm.otherDisplayName.value;
    if (!await ChatPageController.confirmBlock(name) || !mounted) return;
    final BlockOutcome outcome = await HasherBlockService.setBlock(
      dm.otherPublicHasherId.value,
      blocked: true,
    );
    if (!mounted) return;
    if (!outcome.ok) {
      final String? why = outcome.refusal;
      hcSnack(
        (why == null || why.isEmpty)
            ? '$name could not be blocked. Please try again.'
            : why,
        error: true,
        seconds: 5,
      );
      return;
    }
    hcSnack('Blocked');
    // Sending is refused while either side blocks, and their messages leave
    // this screen on the next full fetch.
    dm.canSend.value = false;
    ChatPageController.refetchOpenThreads();
  }

  Future<bool> _confirmEnd(String name) async {
    final bool? yes = await Get.dialog<bool>(
      AlertDialog(
        title: Text('End this conversation?', style: ts_alertDialogTitle),
        content: Text(
          'Neither of you will be able to send more messages. What was said '
          'stays readable, and $name is not told.',
          style: ts_alertDialogBody,
        ),
        actions: <Widget>[
          // hcPop, not Get.back(): with a toast still up, Get.back() closes
          // the toast and leaves the dialog open (CLAUDE.md).
          TextButton(
            style: TextButton.styleFrom(backgroundColor: Colors.blueGrey),
            onPressed: () => hcPop<bool>(result: false),
            child: Text(
              'Cancel',
              style: ts_button,
              textAlign: TextAlign.center,
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(backgroundColor: hc_red),
            onPressed: () => hcPop<bool>(result: true),
            child: Text(
              'End conversation',
              style: ts_button,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
    return yes ?? false;
  }

  Future<void> _end(DmThreadState dm) async {
    if (!await _confirmEnd(dm.otherDisplayName.value) || !mounted) return;
    final bool ok = await DirectMessageService.end(dm.threadId);
    if (!mounted) return;
    if (!ok) {
      hcSnack(
        'The conversation could not be ended. Please try again.',
        error: true,
      );
      return;
    }
    dm.canSend.value = false;
    hcSnack('Conversation ended');
  }

  List<Widget> _dmActions(DmThreadState dm) => <Widget>[
    Obx(() {
      final bool muted = dm.muted.value;
      final bool known = dm.known.value;
      final bool canSend = dm.canSend.value;
      return PopupMenuButton<String>(
        tooltip: 'Conversation options',
        icon: const Icon(Icons.more_vert, color: Colors.white),
        onSelected: (String key) {
          switch (key) {
            case 'mute':
              unawaited(_toggleMute(dm));
            case 'block':
              unawaited(_block(dm));
            case 'end':
              unawaited(_end(dm));
          }
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          // Mute is offered once the read has said which way it is, so the
          // label never flips a moment after it is shown.
          if (known)
            PopupMenuItem<String>(
              value: 'mute',
              enabled: !_saving,
              child: ListTile(
                leading: Icon(
                  muted ? Icons.notifications_active : Icons.notifications_off,
                  color: hc_blue,
                ),
                title: Text(muted ? 'Unmute' : 'Mute', style: ts_titleBlack),
              ),
            ),
          PopupMenuItem<String>(
            value: 'block',
            child: ListTile(
              leading: Icon(Icons.block, color: hc_red),
              title: Text(
                'Block ${dm.otherDisplayName.value}',
                style: ts_titleBlack.copyWith(color: hc_red),
              ),
            ),
          ),
          if (canSend)
            PopupMenuItem<String>(
              value: 'end',
              child: ListTile(
                leading: Icon(Icons.logout, color: hc_red),
                title: Text(
                  'End conversation',
                  style: ts_titleBlack.copyWith(color: hc_red),
                ),
              ),
            ),
        ],
      );
    }),
  ];

  /// The other party's photo (a portrait, so a circle — CLAUDE.md) and name.
  Widget _dmTitle(DmThreadState dm) => Obx(() {
    final String name = dm.otherDisplayName.value;
    final String photo = dm.otherPhoto.value;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        CircleAvatar(
          radius: 16,
          backgroundColor: Colors.black26,
          backgroundImage: avatarImageProvider(photo.isEmpty ? null : photo),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  });

  @override
  Widget build(BuildContext context) {
    final DmThreadState? dm = widget.dmState;
    return Scaffold(
      appBar: AppBar(
        title: dm == null ? Text(widget.title) : _dmTitle(dm),
        backgroundColor: themeButtonColors,
        foregroundColor: Colors.white,
        actions: dm != null
            ? _dmActions(dm)
            : <Widget>[
                // Hidden until the state is known, rather than guessing: an
                // icon that shows "unpinned" and then flips a moment later
                // reads as the app having undone the hasher's choice.
                if (_pinKnown)
                  IconButton(
                    tooltip: _pinned
                        ? 'Pinned — tap to unpin'
                        : 'Not pinned — tap to pin',
                    // Same glyph as the settings console and the chat list,
                    // so "pinned" looks like one thing across the app. An
                    // outline pin was too close to the filled one to tell
                    // apart at a glance.
                    icon: PinGlyph(pinned: _pinned, size: 24, color: Colors.white),
                    onPressed: _saving ? null : () => unawaited(_togglePin()),
                  ),
              ],
      ),
      body: dm != null
          ? ChatPage.dm(state: dm)
          : ChatPage(
              eventId: widget.eventId,
              publicEventId: widget.publicEventId,
              isKennelThread: widget.isKennelThread,
              roomType: widget.roomType,
            ),
    );
  }
}
