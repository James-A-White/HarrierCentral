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
///
/// Split by a pill at the top into Groups (run, kennel and room chats) and
/// Friends (every hasher who has accepted a direct message, and the requests
/// to become one), each pill carrying its own unread count (James,
/// 2026-10-12; E9.F1.S29).
enum ChatsPill { groups, friends }

class ChatsPageController extends GetxController {
  ChatsPageController({this.initialPill});

  /// The pill to open on, when whoever opened Chats knows (a message request
  /// opens Friends). Null lets the counts choose — see [onInit].
  final ChatsPill? initialPill;

  /// The open page's controller, so a second ask to open Chats on a given
  /// pill can switch it rather than do nothing. Null when Chats is closed.
  static ChatsPageController? _open;

  final TextEditingController searchText = TextEditingController();
  final RxString query = ''.obs;

  final Rx<ChatsPill> pill = ChatsPill.groups.obs;

  /// Requests first, then threads — what the page draws.
  final RxList<dynamic> items = <dynamic>[].obs;

  /// The request whose Accept / Decline is in flight. '' when none.
  final RxString dmRequestBusyId = ''.obs;

  /// The mark-all-read round trip, for the button's spinner.
  final RxBool chatResetInProgress = false.obs;

  NotificationService? get _n => Get.isRegistered<NotificationService>()
      ? Get.find<NotificationService>()
      : null;

  final List<Worker> _workers = <Worker>[];

  @override
  void onInit() {
    super.onInit();
    _open = this;
    final NotificationService? n = _n;
    // Open where the news is: Friends when only Friends has something
    // unread, Groups otherwise. Chosen once from the counts already held,
    // never switched under the hasher when a later fetch lands.
    pill.value =
        initialPill ??
        ((n != null && n.unreadGroupsCount == 0 && n.unreadFriendsCount > 0)
            ? ChatsPill.friends
            : ChatsPill.groups);
    if (n != null) {
      _workers
        ..add(ever(n.unreadChatRuns, (_) => _rebuild()))
        ..add(ever(n.dmRequests, (_) => _rebuild()));
      unawaited(n.getEventChatMessageCounts());
    }
    _workers
      ..add(ever(query, (_) => _rebuild()))
      ..add(ever(pill, (_) => _rebuild()));
    _rebuild();
  }

  @override
  void onClose() {
    if (identical(_open, this)) _open = null;
    for (final Worker w in _workers) {
      w.dispose();
    }
    searchText.dispose();
    super.onClose();
  }

  void _rebuild() {
    if (isClosed) return;
    final NotificationService? n = _n;
    final bool friends = pill.value == ChatsPill.friends;
    final List<EventChatSummary> all =
        (n?.unreadChatRuns.toList() ?? <EventChatSummary>[])
            .where((EventChatSummary s) => s.isDmThread == friends)
            .toList();
    // Requests are people, so they belong to Friends.
    final List<DirectMessageRequest> requests = friends
        ? (n?.dmRequests.toList() ?? <DirectMessageRequest>[])
        : <DirectMessageRequest>[];
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
/// its toast all come here. A second ask while it is open does not push
/// another page; it only switches to [pill] when one is given.
///
/// "Open" is whether the Chats ROUTE is on the stack, asked of the navigator
/// each time — not a flag. 1430 kept a flag on the controller and cleared it
/// in onClose, which a page-local GetBuilder never calls on pop, so after the
/// first visit the bubble did nothing (James, 2026-10-01).
Future<void> openChatsPage({ChatsPill? pill}) async {
  if (Get.currentRoute == ChatsPage.routeName) {
    final ChatsPageController? open = ChatsPageController._open;
    if (pill != null && open != null && !open.isClosed) open.pill.value = pill;
    return;
  }
  await Get.to<void>(
    () => ChatsPage(initialPill: pill),
    routeName: ChatsPage.routeName,
  );
}

class ChatsPage extends StatelessWidget {
  const ChatsPage({super.key, this.initialPill});

  final ChatsPill? initialPill;

  static const String routeName = '/chats';

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ChatsPageController>(
      init: ChatsPageController(initialPill: initialPill),
      global: false,
      // A page-local GetBuilder does not close its controller on pop; do it
      // here, or its workers outlive the page (as in chat_page.dart).
      dispose: (GetBuilderState<ChatsPageController> state) =>
          state.controller?.onDelete(),
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
          // Find a hasher lives on the Friends pill now (E9.F1.S29).
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
              _ChatsPills(controller: controller),
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                // The hint names the pill being searched.
                child: Obx(
                  () => TextField(
                    // A tap or scroll anywhere else puts the keyboard away (James,
                    // 2026-10-04): rows claim their own taps, so the app-wide
                    // empty-space dismiss never heard them.
                    onTapOutside: (_) =>
                        FocusManager.instance.primaryFocus?.unfocus(),
                    textInputAction: TextInputAction.done,
                    controller: controller.searchText,
                    onChanged: (String v) => controller.query.value = v,
                    decoration: InputDecoration(
                      hintText: controller.pill.value == ChatsPill.friends
                          ? 'Search friends...'
                          : 'Search groups...',
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
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => Get.isRegistered<NotificationService>()
                      ? Get.find<NotificationService>()
                            .getEventChatMessageCounts()
                      : null,
                  child: Obx(() {
                    // Every Rx read first, before any branch can skip one.
                    final List<dynamic> items = controller.items.toList();
                    final String busyId = controller.dmRequestBusyId.value;
                    final bool friends =
                        controller.pill.value == ChatsPill.friends;
                    final bool searching = controller.query.value.isNotEmpty;
                    // Friends opens with the way to find someone to message,
                    // which used to sit in the Chats header (E9.F1.S29).
                    final int lead = friends ? 1 : 0;
                    if (items.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        children: <Widget>[
                          if (friends) const _FindHasherButton(),
                          const SizedBox(height: 48),
                          Text(
                            searching
                                ? 'No chats match your search.'
                                : friends
                                ? 'No friends yet'
                                : "You're up to date!",
                            style: ts_headingLarge,
                            textAlign: TextAlign.center,
                          ),
                          if (friends && !searching) ...<Widget>[
                            const SizedBox(height: 12),
                            Text(
                              'To message someone, long-press one of their '
                              'messages in any chat and choose Message, or '
                              'use Find a hasher. They appear here once they '
                              'accept.',
                              style: ts_body,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      );
                    }
                    return ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
                      itemCount: items.length + lead,
                      itemBuilder: (BuildContext context, int i) {
                        if (i < lead) return const _FindHasherButton();
                        final int index = i - lead;
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

/// Groups | Friends, each with its unread count (E9.F1.S29). The counts are
/// NotificationService's own, folded from the map the chat bubble sums, so
/// the two pills always add up to the bubble.
class _ChatsPills extends StatelessWidget {
  const _ChatsPills({required this.controller});
  final ChatsPageController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Obx(() {
            final ChatsPill selected = controller.pill.value;
            final NotificationService? n =
                Get.isRegistered<NotificationService>()
                ? Get.find<NotificationService>()
                : null;
            final int groups = n?.unreadGroupsCount ?? 0;
            final int friends = n?.unreadFriendsCount ?? 0;
            return SegmentedButton<ChatsPill>(
              // Fills the width, so the two halves are the same size.
              expandedInsets: EdgeInsets.zero,
              showSelectedIcon: false,
              segments: <ButtonSegment<ChatsPill>>[
                ButtonSegment<ChatsPill>(
                  value: ChatsPill.groups,
                  label: _label(
                    'Groups',
                    groups,
                    selected: selected == ChatsPill.groups,
                  ),
                ),
                ButtonSegment<ChatsPill>(
                  value: ChatsPill.friends,
                  label: _label(
                    'Friends',
                    friends,
                    selected: selected == ChatsPill.friends,
                  ),
                ),
              ],
              selected: <ChatsPill>{selected},
              onSelectionChanged: (Set<ChatsPill> s) =>
                  controller.pill.value = s.first,
              // The same colours as the email audience pills: red selected,
              // white otherwise.
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith(
                  (Set<WidgetState> states) =>
                      states.contains(WidgetState.selected)
                      ? hc_red
                      : Colors.white,
                ),
                foregroundColor: WidgetStateProperty.resolveWith(
                  (Set<WidgetState> states) =>
                      states.contains(WidgetState.selected)
                      ? Colors.white
                      : Colors.black87,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  /// A pill's name and, when it has any, its unread count — red on the
  /// white pill, white on the red one, so it reads on both.
  static Widget _label(String text, int count, {required bool selected}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        if (count > 0) ...<Widget>[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: selected ? Colors.white : Colors.red,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count > 99 ? '99+' : '$count',
              style: TextStyle(
                color: selected ? hc_red : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Find a hasher to message (E9.F1.S26), at the top of Friends.
class _FindHasherButton extends StatelessWidget {
  const _FindHasherButton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.person_search, color: Colors.white),
          label: Text(
            'Find a hasher',
            style: ts_button,
            textAlign: TextAlign.center,
          ),
          onPressed: () => unawaited(
            Get.to<void>(() => const HasherSearchPage()) ??
                Future<void>.value(),
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
        // Pinned shows the same glyph as a pinned room or kennel chat.
        trailing: s.badgeCount > 0
            ? _unreadBadge(s.badgeCount)
            : s.pinned
            ? const PinGlyph(pinned: true, size: 18, color: Colors.black54)
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
