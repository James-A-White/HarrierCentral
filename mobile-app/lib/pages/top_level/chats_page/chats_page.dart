import 'package:harrier_central/imports.dart';
import 'package:intl/intl.dart';

/// Chats — every run, kennel, room and direct-message thread, and the
/// requests to message this hasher — as its OWN page, opened over whatever
/// tab the hasher is on (James, 2026-10-01).
///
/// It used to be a display mode of the Runs list, switched on by the
/// top-bar bubble. That one choice caused every Chats bug since September:
/// the bubble had to jump the bottom bar to Runs to switch the mode on, the
/// mode was only switched off once the Runs tab had finished appearing (so
/// returning showed Chats for 2–3 s), and the tab-state flags that tried to
/// manage it stuck (the "Chats comes back" fixes). As a pushed page it has
/// none of that: the bottom bar does not move, Back returns to exactly where
/// the hasher was, and the Runs list cannot show chats at all.
///
/// The rows are the ones the Runs list drew, moved here unchanged.
class ChatsPageController extends GetxController {
  final TextEditingController searchText = TextEditingController();
  final RxString query = ''.obs;

  /// Requests first, then threads — what the page draws.
  final RxList<dynamic> items = <dynamic>[].obs;

  /// The request whose Accept / Decline is in flight. '' when none.
  final RxString dmRequestBusyId = ''.obs;

  /// The mark-all-read round trip, for the button's spinner.
  final RxBool chatResetInProgress = false.obs;

  /// One Chats page at a time: the bubble, a push and a toast can all ask.
  static bool isOpen = false;

  NotificationService? get _n => Get.isRegistered<NotificationService>()
      ? Get.find<NotificationService>()
      : null;

  final List<Worker> _workers = <Worker>[];

  @override
  void onInit() {
    super.onInit();
    isOpen = true;
    final NotificationService? n = _n;
    if (n != null) {
      _workers
        ..add(ever(n.unreadChatRuns, (_) => _rebuild()))
        ..add(ever(n.dmRequests, (_) => _rebuild()));
      unawaited(n.getEventChatMessageCounts());
    }
    _workers.add(ever(query, (_) => _rebuild()));
    _rebuild();
  }

  @override
  void onClose() {
    isOpen = false;
    for (final Worker w in _workers) {
      w.dispose();
    }
    searchText.dispose();
    super.onClose();
  }

  void _rebuild() {
    if (isClosed) return;
    final NotificationService? n = _n;
    final List<EventChatSummary> all =
        n?.unreadChatRuns.toList() ?? <EventChatSummary>[];
    final List<DirectMessageRequest> requests =
        n?.dmRequests.toList() ?? <DirectMessageRequest>[];
    final String q = query.value.trim().toLowerCase();
    final List<EventChatSummary> list = q.isEmpty
        ? all
        : all
              .where(
                (EventChatSummary s) =>
                    (s.kennelShortName ?? '').toLowerCase().contains(q) ||
                    (s.eventName ?? '').toLowerCase().contains(q) ||
                    (s.otherDisplayName ?? '').toLowerCase().contains(q) ||
                    (s.eventNumber?.toString() ?? '').contains(q),
              )
              .toList();
    final List<DirectMessageRequest> asked = q.isEmpty
        ? requests
        : requests
              .where(
                (DirectMessageRequest r) =>
                    r.displayName.toLowerCase().contains(q),
              )
              .toList();
    items.assignAll(<dynamic>[...asked, ...list]);
  }

  Future<void> markAllChatsRead() async {
    if (chatResetInProgress.value) return;
    chatResetInProgress.value = true;
    try {
      await _n?.resetAllEventChatCounts();
    } finally {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!isClosed) chatResetInProgress.value = false;
    }
  }

  /// Accept (the thread opens) or decline (the requester is told nothing)
  /// one request to message this hasher (E9.F1.S19).
  Future<void> respondToDmRequest(
    DirectMessageRequest r, {
    required bool accept,
  }) async {
    if (dmRequestBusyId.value.isNotEmpty) return;
    dmRequestBusyId.value = r.fromPublicHasherId;
    String? refusal;
    final DmStartResult? result = await DirectMessageService.respond(
      r.fromPublicHasherId,
      accept: accept,
      onRefused: (String? why) => refusal = why,
    );
    if (isClosed) return;
    dmRequestBusyId.value = '';
    final NotificationService? notifications = _n;
    if (result == null) {
      hcSnack(
        (refusal == null || refusal!.isEmpty)
            ? 'That could not be done. Please try again.'
            : refusal!,
        error: true,
        seconds: 5,
      );
      unawaited(notifications?.getEventChatMessageCounts());
      return;
    }
    notifications?.dmRequests.removeWhere(
      (DirectMessageRequest x) => x.fromPublicHasherId == r.fromPublicHasherId,
    );
    notifications?.recalculateBadges();
    if (result.outcome == DmOutcome.open && result.threadId != null) {
      await ChatPageController.openDirectMessage(
        threadId: result.threadId!,
        otherPublicHasherId: result.otherPublicHasherId,
        otherDisplayName: result.otherDisplayName,
        otherPhoto: result.otherPhoto,
      );
      return;
    }
    hcSnack(
      accept
          ? '${result.otherDisplayName} could not be messaged right now.'
          : 'Declined',
      error: accept,
    );
    unawaited(notifications?.getEventChatMessageCounts());
  }
}

/// Open Chats over whatever is on screen — the bubble, a DM-request push and
/// its toast all come here. A second ask while it is open does nothing.
Future<void> openChatsPage() async {
  if (ChatsPageController.isOpen) return;
  await Get.to<void>(() => const ChatsPage());
}

class ChatsPage extends StatelessWidget {
  const ChatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ChatsPageController>(
      init: ChatsPageController(),
      global: false,
      builder: (ChatsPageController controller) => AppScaffold(
        appBar: AppBar(
          backgroundColor: themeAppBarBackground,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => hcPop<void>(),
            tooltip: 'Back',
          ),
          title: Text('Chats', style: ts_appBarTitle),
          centerTitle: true,
          actions: <Widget>[
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _ChatsResetButton(controller: controller),
            ),
          ],
        ),
        body: DecoratedBox(
          decoration: Backgrounds.defaultHcBackground(),
          child: Column(
            children: <Widget>[
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextField(
                  controller: controller.searchText,
                  onChanged: (String v) => controller.query.value = v,
                  decoration: InputDecoration(
                    hintText: 'Search chats...',
                    border: InputBorder.none,
                    prefixIcon: const Icon(Icons.search, color: Colors.black),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.close, color: Colors.black54),
                      onPressed: () {
                        controller.searchText.clear();
                        controller.query.value = '';
                      },
                    ),
                  ),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => Get.isRegistered<NotificationService>()
                      ? Get.find<NotificationService>()
                            .getEventChatMessageCounts()
                      : null,
                  child: Obx(() {
                    final List<dynamic> items = controller.items.toList();
                    final String busyId = controller.dmRequestBusyId.value;
                    if (items.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: <Widget>[
                          const SizedBox(height: 60),
                          Text(
                            controller.query.value.isEmpty
                                ? "You're up to date!"
                                : 'No chats match your search.',
                            style: ts_headingLarge,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      );
                    }
                    return ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
                      itemCount: items.length,
                      itemBuilder: (BuildContext context, int index) {
                        final dynamic item = items[index];
                        if (item is DirectMessageRequest) {
                          final bool first =
                              index == 0 ||
                              items[index - 1] is! DirectMessageRequest;
                          return _ChatRows(controller)._dmRequestRow(
                            item,
                            first: first,
                            busy: busyId == item.fromPublicHasherId,
                          );
                        }
                        return _ChatRows(
                          controller,
                        )._chatRunRow(item as EventChatSummary);
                      },
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatsResetButton extends StatelessWidget {
  const _ChatsResetButton({required this.controller});
  final ChatsPageController controller;

  @override
  Widget build(BuildContext context) =>
      _ChatRows(controller)._showResetChatCountsButton();
}

/// The row builders the Runs list used, unchanged but for their owner.
class _ChatRows {
  _ChatRows(this.controller);
  final ChatsPageController controller;

  Widget _chatRunRow(EventChatSummary s) {
    // A direct message is a person, not a run, a kennel or a room.
    if (s.isDmThread) return _dmThreadRow(s);
    // A room has no kennel, no run number and no date — its name IS the row.
    final String title = s.isRoomThread
        ? (s.eventName ?? 'Chat room')
        : s.isKennelThread
        ? '${s.kennelShortName ?? s.eventName ?? 'Kennel'} Kennel Chat'
        : (s.kennelShortName != null && s.eventNumber != null)
        ? '${s.kennelShortName} #${s.eventNumber}'
        : (s.eventName ?? 'Run');
    String dateStr = '';
    final gmt = s.eventStartDatetimeGmt;
    if (gmt != null && gmt.isNotEmpty) {
      final dt = DateTime.tryParse(gmt);
      if (dt != null) {
        dateStr = DateFormat('EEE, d MMM yyyy').format(dt.toLocal());
      }
    }
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(top: 10.0),
      child: ListTile(
        leading: s.isRoomThread
            ? ChatRoomCoin(iconUrl: s.roomIcon, size: 44)
            : KennelLogo(
                kennelId: s.kennelId,
                kennelLogoUrl: s.kennelLogo,
                kennelShortName: s.kennelShortName ?? '',
                logoHeight: 44,
              ),
        title: Text(title, style: ts_tileText),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (!s.isRoomThread && (s.eventName ?? '').isNotEmpty)
              Text(
                s.eventName!,
                style: ts_footnoteBlack,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            if (s.isRoomThread)
              Text(
                s.messageCount == 0
                    ? 'No messages yet'
                    : 'Harrier Central chat room',
                style: ts_footnoteBlack,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            if (dateStr.isNotEmpty) Text(dateStr, style: ts_footnoteBlack),
          ],
        ),
        // A read thread keeps its place in the list and simply loses the
        // badge (James, 2026-09-13) — a chevron says it is still a thread you
        // can open, rather than leaving a hole where the badge was.
        trailing: s.pinned && s.badgeCount == 0
            // The row sits on a WHITE card, so this one is dark — the glyph
            // takes the colour rather than assuming the jungle.
            ? const PinGlyph(pinned: true, size: 18, color: Colors.black54)
            : s.badgeCount > 0
            ? _unreadBadge(s.badgeCount)
            : const Icon(Icons.chevron_right, color: Colors.black38),
        onTap: () async {
          // A room is named by its type alone — no event, no kennel.
          if (s.isRoomThread) {
            await Get.to(
              () => ChatScaffold.room(
                roomType: s.roomType!,
                title: title,
                key: UniqueKey(),
              ),
            );
            if (Get.isRegistered<NotificationService>()) {
              unawaited(
                Get.find<NotificationService>().getEventChatMessageCounts(),
              );
            }
            return;
          }
          final bool kennelThread = s.isKennelThread;
          if (!kennelThread && s.eventId == null) return;
          if (kennelThread && (s.publicKennelId ?? '').isEmpty) return;
          // ChatPage is normally a tab body inside RunDetailsPage, which
          // supplies the app bar (back) and keyboard-safe Scaffold. Opened
          // standalone from here it needs its own Scaffold + AppBar so there's
          // a back button and the input stays above the keyboard.
          await Get.to(
            () => ChatScaffold(
              title: title,
              eventId: kennelThread ? s.kennelId! : s.eventId!,
              publicEventId: kennelThread ? s.publicKennelId! : s.publicEventId,
              isKennelThread: kennelThread,
            ),
          );
          // Refresh unread counts after leaving the chat so the badge and this
          // list update.
          if (Get.isRegistered<NotificationService>()) {
            await Get.find<NotificationService>().getEventChatMessageCounts();
          }
        },
      ),
    );
  }

  /// The red unread count on a chat row.
  Widget _unreadBadge(int count) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.red,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Text(
      '$count',
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    ),
  );

  /// When a thread last had something said in it, for a DM row.
  static String _lastMessageLabel(EventChatSummary s) {
    if ((s.messageCount ?? 0) == 0) return 'No messages yet';
    final DateTime? at = DateTime.tryParse(s.lastMessageAt ?? '');
    if (at == null) return 'Direct message';
    return DateFormat('EEE, d MMM yyyy HH:mm').format(at.toLocal());
  }

  /// A direct message thread in the Chats view (E9.F1.S7): the other
  /// party's photo — a person, so a circle — their name, when the thread
  /// last moved, and the unread count. Opens the thread; the badges are
  /// refreshed on return.
  Widget _dmThreadRow(EventChatSummary s) {
    final HcId threadId = s.threadId!;
    final String name = (s.otherDisplayName ?? '').trim().isEmpty
        ? (s.eventName ?? 'A hasher')
        : s.otherDisplayName!.trim();
    final String? photo = s.otherPhoto ?? s.kennelLogo;
    return Card(
      key: ValueKey<String>('dm-$threadId'),
      elevation: 3,
      margin: const EdgeInsets.only(top: 10.0),
      child: ListTile(
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: Colors.black12,
          backgroundImage: avatarImageProvider(photo),
        ),
        title: Text(name, style: ts_tileText),
        subtitle: Text(
          _lastMessageLabel(s),
          style: ts_footnoteBlack,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: s.badgeCount > 0
            ? _unreadBadge(s.badgeCount)
            : const Icon(Icons.chevron_right, color: Colors.black38),
        onTap: () => unawaited(
          ChatPageController.openDirectMessage(
            threadId: threadId,
            otherPublicHasherId: s.otherPublicHasherId ?? HcId.empty,
            otherDisplayName: name,
            otherPhoto: photo,
          ),
        ),
      ),
    );
  }

  /// One hasher asking to message this one (E9.F1.S19), with Accept and
  /// Decline. The first row of the group carries its heading, in the same
  /// bar the run list uses for its sections.
  Widget _dmRequestRow(
    DirectMessageRequest r, {
    required bool first,
    required bool busy,
  }) {
    final DateTime? at = r.requestedAt;
    return Column(
      key: ValueKey<String>('dm-request-${r.fromPublicHasherId}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (first)
          Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.only(top: 2.0),
            color: themeButtonColors,
            height: 40.0,
            alignment: Alignment.center,
            child: Text(
              'Message requests',
              textAlign: TextAlign.center,
              style: ts_titleLarge,
            ),
          ),
        Card(
          elevation: 3,
          margin: const EdgeInsets.only(top: 10.0),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.black12,
                  backgroundImage: avatarImageProvider(r.photo),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(r.displayName, style: ts_tileText),
                      Text(
                        at == null
                            ? 'wants to message you'
                            : 'wants to message you — '
                                  '${DateFormat('d MMM').format(at.toLocal())}',
                        style: ts_footnoteBlack,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // Wrap, not Row: two buttons at a large text size are
                      // wider than the space beside a photo.
                      AbsorbPointer(
                        absorbing: busy,
                        child: Opacity(
                          opacity: busy ? 0.5 : 1.0,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: <Widget>[
                              ElevatedButton(
                                onPressed: () => unawaited(
                                  controller.respondToDmRequest(
                                    r,
                                    accept: true,
                                  ),
                                ),
                                child: Text(
                                  'Accept',
                                  style: ts_button,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              // The same widget as Accept so the two share
                              // the theme's shape, padding and type; only
                              // the colour says which is which (James,
                              // 2026-09-29).
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueGrey,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () => unawaited(
                                  controller.respondToDmRequest(
                                    r,
                                    accept: false,
                                  ),
                                ),
                                child: Text(
                                  'Decline',
                                  style: ts_button,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (busy)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _showResetChatCountsButton() {
    return Obx(() {
      final bool busy = controller.chatResetInProgress.value;
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.only(top: 0.0, bottom: 0.0),
          // Flash green while the mark-all-read is in flight so the tap has a
          // clear, immediate acknowledgement (null keeps the theme default red).
          backgroundColor: busy ? Colors.green.shade600 : null,
        ),
        // Disabled while busy — prevents a double-tap firing a second reset.
        onPressed: busy ? null : controller.markAllChatsRead,
        child: Padding(
          padding: const EdgeInsets.only(left: 0, right: 0, top: 0, bottom: 0),
          child: busy
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(
                  Ionicons.checkmark_done_sharp,
                  color: Colors.white,
                  size: 30.0,
                ),
        ),
      );
    });
  }
}
