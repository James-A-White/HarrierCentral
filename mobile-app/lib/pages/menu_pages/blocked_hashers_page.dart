import 'package:intl/intl.dart';
import 'package:harrier_central/imports.dart';

/// Who this hasher has blocked, with an Unblock on each (E9.F1.S16).
///
/// The list is the server's — hcapp_getBlockedHashers — and every Unblock
/// repaints from the list hcapp_setHasherBlock hands back, so the screen
/// never shows a state the server did not store. Blocking itself happens
/// on a chat message's long-press menu; this page is the way back.
class BlockedHashersController extends GetxController {
  /// null from the service means the call FAILED. An empty list is the
  /// ordinary answer for almost everyone and must not be drawn as an error,
  /// nor a failure drawn as "you have blocked nobody".
  final RxList<BlockedHasher> blocked = <BlockedHasher>[].obs;
  final RxBool loading = true.obs;
  final RxBool failed = false.obs;

  /// The row whose Unblock is in flight, so its button shows a spinner and
  /// a second tap does nothing.
  final RxString busyId = ''.obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(load());
  }

  Future<void> load() async {
    loading.value = true;
    final List<BlockedHasher>? list = await HasherBlockService.fetchBlocked();
    if (isClosed) return;
    failed.value = list == null;
    blocked.value = list ?? <BlockedHasher>[];
    loading.value = false;
  }

  Future<bool> _confirmUnblock(BlockedHasher h) async {
    final bool? yes = await Get.dialog<bool>(
      AlertDialog(
        title: Text('Unblock ${h.displayName}?', style: ts_alertDialogTitle),
        content: Text(
          'You will see their messages in every chat again.',
          style: ts_alertDialogBody,
        ),
        actions: <Widget>[
          // hcPop, not Get.back(): with a toast still up, Get.back() closes
          // the toast and leaves the dialog open (CLAUDE.md).
          TextButton(
            style: TextButton.styleFrom(backgroundColor: Colors.blueGrey),
            onPressed: () => hcPop<bool>(result: false),
            child: Text('Cancel', style: ts_button, textAlign: TextAlign.center),
          ),
          TextButton(
            style: TextButton.styleFrom(backgroundColor: hc_red),
            onPressed: () => hcPop<bool>(result: true),
            child: Text('Unblock', style: ts_button, textAlign: TextAlign.center),
          ),
        ],
      ),
    );
    return yes ?? false;
  }

  Future<void> unblock(BlockedHasher h) async {
    if (busyId.value.isNotEmpty) return;
    if (!await _confirmUnblock(h) || isClosed) return;

    busyId.value = h.publicHasherId;
    final BlockOutcome outcome = await HasherBlockService.setBlock(
      h.publicHasherId,
      blocked: false,
    );
    if (isClosed) return;
    busyId.value = '';

    if (!outcome.ok) {
      final String? why = outcome.refusal;
      hcSnack(
        (why == null || why.isEmpty)
            ? '${h.displayName} could not be unblocked. Please try again.'
            : why,
        error: true,
        seconds: 5,
      );
      return;
    }
    blocked.value = outcome.blocked!;
    hcSnack('${h.displayName} unblocked');
    // A chat open underneath this page has been hiding their messages;
    // it needs the whole thread again, not a delta.
    ChatPageController.refetchOpenThreads();
  }
}

class BlockedHashersPage extends StatelessWidget {
  const BlockedHashersPage({super.key});

  static final DateFormat _date = DateFormat.yMMMd();

  @override
  Widget build(BuildContext context) {
    // Owned by this page: GetBuilder(init:, global: false) with the dispose
    // hook, so leaving the page closes the controller and nothing is put
    // into the registry from inside build().
    return GetBuilder<BlockedHashersController>(
      init: BlockedHashersController(),
      global: false,
      dispose: (state) => state.controller?.onDelete(),
      builder: (BlockedHashersController controller) => AppScaffold(
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: themeAppBarBackground,
          iconTheme: const IconThemeData(color: Colors.white, size: 28.0),
          title: Text('Blocked Hashers', style: ts_appBarTitle),
        ),
        body: DecoratedBox(
          decoration: Backgrounds.defaultHcBackground(),
          child: SizedBox.expand(child: Obx(() => _body(controller))),
        ),
      ),
    );
  }

  Widget _body(BlockedHashersController controller) {
    // Every Rx this body depends on is read here, before any branch can
    // return early, so the Obx is subscribed to all of them (obx_scan).
    final bool loading = controller.loading.value;
    final bool failed = controller.failed.value;
    final List<BlockedHasher> blocked = controller.blocked.toList();
    final String busyId = controller.busyId.value;

    if (loading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (failed) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(
                'Your blocked hashers could not be loaded. A connection is '
                'required to see or change them.',
                style: ts_body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: Text(
                  'Try again',
                  style: ts_button,
                  textAlign: TextAlign.center,
                ),
                onPressed: () => unawaited(controller.load()),
              ),
            ],
          ),
        ),
      );
    }

    if (blocked.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            "You haven't blocked anyone.",
            style: ts_titleMedium,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            'Their messages are hidden from you in every chat, and they are '
            'not told. Unblock to see their messages again.',
            style: ts_body,
            textAlign: TextAlign.center,
          ),
        ),
        for (final BlockedHasher h in blocked)
          _row(controller, h, busy: busyId == h.publicHasherId),
      ],
    );
  }

  Widget _row(
    BlockedHashersController controller,
    BlockedHasher h, {
    required bool busy,
  }) {
    final DateTime? at = h.blockedAt;
    return Container(
      key: ValueKey<String>('blocked_${h.publicHasherId}'),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        // Its own dark fill so white text reads against the leaves.
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: <Widget>[
          // A profile photo is a portrait, and portraits stay circles
          // (CLAUDE.md — the no-mask rule is for kennel logos).
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.black26,
            backgroundImage: avatarImageProvider(h.photo),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(h.displayName, style: ts_titleMedium),
                if (at != null)
                  Text(
                    'Blocked ${_date.format(at.toLocal())}',
                    style: ts_bodySmall.copyWith(color: Colors.white70),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: busy ? null : () => unawaited(controller.unblock(h)),
            child: busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text('Unblock', style: ts_button, textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}
