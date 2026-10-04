import 'package:harrier_central/imports.dart';
import 'package:intl/intl.dart';

/// Find a hasher to message (E9.F1.S26), opened from Chats. The server
/// decides who can be found — each hasher's own choice — and searches the
/// hash name and home kennel, and the real name only where the hasher
/// allowed it. A result opens the shared hasher page.
class HasherSearchController extends GetxController {
  final TextEditingController text = TextEditingController();
  final RxString query = ''.obs;
  final RxList<HasherSummary> results = <HasherSummary>[].obs;
  final RxBool searching = false.obs;
  final RxnString message = RxnString();

  Worker? _debounce;
  int _seq = 0;

  @override
  void onInit() {
    super.onInit();
    _debounce = debounce<String>(
      query,
      (String q) => unawaited(_search(q)),
      time: const Duration(milliseconds: 450),
    );
  }

  @override
  void onClose() {
    _debounce?.dispose();
    text.dispose();
    super.onClose();
  }

  void clear() {
    text.clear();
    query.value = '';
    results.clear();
    message.value = null;
  }

  Future<void> _search(String raw) async {
    final String q = raw.trim();
    final int seq = ++_seq;
    if (q.length < 2) {
      results.clear();
      message.value = q.isEmpty ? null : 'Type at least 2 letters of a name.';
      return;
    }
    searching.value = true;
    final HasherSearchOutcome out = await HasherDirectoryService.search(q);
    // A slower, older answer must not overwrite a newer one.
    if (isClosed || seq != _seq) return;
    searching.value = false;
    final List<HasherSummary>? found = out.results;
    if (found == null) {
      results.clear();
      message.value =
          out.refusal ?? "The search couldn't be run. Please try again.";
      return;
    }
    results.assignAll(found);
    message.value = found.isEmpty
        ? 'Nobody found. Only hashers who chose to be found can appear.'
        : null;
  }
}

class HasherSearchPage extends StatelessWidget {
  const HasherSearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HasherSearchController>(
      init: HasherSearchController(),
      global: false,
      dispose: (GetBuilderState<HasherSearchController> s) =>
          s.controller?.onDelete(),
      builder: (HasherSearchController c) => AppScaffold(
        appBar: AppBar(
          backgroundColor: themeAppBarBackground,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => hcPop<void>(),
            tooltip: 'Back',
          ),
          title: Text('Find a hasher', style: ts_appBarTitle),
          centerTitle: true,
        ),
        body: DecoratedBox(
          decoration: Backgrounds.defaultHcBackground(),
          child: Column(
            children: <Widget>[
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextField(
                  // A tap or scroll anywhere else puts the keyboard away (James,
                  // 2026-10-04): rows claim their own taps, so the app-wide
                  // empty-space dismiss never heard them.
                  onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
                  controller: c.text,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  onChanged: (String v) => c.query.value = v,
                  decoration: InputDecoration(
                    hintText: 'Hash name, real name or home kennel',
                    border: InputBorder.none,
                    prefixIcon: const Icon(Icons.search, color: Colors.black),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.close, color: Colors.black54),
                      onPressed: c.clear,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Obx(() {
                  final List<HasherSummary> found = c.results.toList();
                  final bool searching = c.searching.value;
                  final String? msg = c.message.value;
                  if (searching && found.isEmpty) {
                    return const Center(
                      child: HcAppCircularProgressIndicator(),
                    );
                  }
                  if (found.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          msg ??
                              'Search for hashers by name. Only hashers who '
                                  'chose to be found will appear.',
                          style: ts_body,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
                    itemCount: found.length,
                    itemBuilder: (BuildContext context, int i) =>
                        HasherRow(hasher: found[i], onDark: true),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One hasher in a list — search results (on the jungle) and By Hasher (on
/// the light Run Counts page). Opens the hasher page.
class HasherRow extends StatelessWidget {
  const HasherRow({
    super.key,
    required this.hasher,
    required this.onDark,
    this.rank,
  });

  final HasherSummary hasher;
  final bool onDark;

  /// By Hasher numbers its rows.
  final int? rank;

  @override
  Widget build(BuildContext context) {
    final Color ink = onDark ? Colors.white : Colors.black87;
    final Color soft = onDark ? Colors.white70 : Colors.black54;
    final String sub = <String>[
      if ((hasher.homeKennelShortName ?? '').isNotEmpty)
        hasher.homeKennelShortName!,
      if (hasher.runsTogether > 0)
        '${hasher.runsTogether} ${hasher.runsTogether == 1 ? 'run' : 'runs'} together',
    ].join(' · ');
    return InkWell(
      onTap: () => unawaited(HasherPage.open(hasher)),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: onDark
            ? BoxDecoration(
                color: Colors.black.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(10),
              )
            : null,
        child: Row(
          children: <Widget>[
            if (rank != null)
              SizedBox(
                width: 34,
                child: Text(
                  '$rank',
                  style: ts_body.copyWith(color: soft),
                  textAlign: TextAlign.center,
                ),
              ),
            // Profile photos are square and shown whole (James,
            // 2026-10-02): never trimmed into a circle.
            HasherPhoto(url: hasher.photo, size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    hasher.displayName,
                    style: ts_titleMediumBold.copyWith(color: ink),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (sub.isNotEmpty)
                    Text(
                      sub,
                      style: ts_body.copyWith(color: soft),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: soft),
          ],
        ),
      ),
    );
  }
}

/// A hasher's profile photo: square and whole, never trimmed into a circle
/// (James, 2026-10-02: "Profile photos are always square").
class HasherPhoto extends StatelessWidget {
  const HasherPhoto({super.key, required this.url, required this.size});

  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: (url ?? '').isEmpty
          ? Image.asset(
              'images/icons/create_profile_photo.png',
              fit: BoxFit.contain,
            )
          : Image(image: avatarImageProvider(url), fit: BoxFit.contain),
    );
  }
}

/// The small line under a By Hasher count (James, 2026-10-02): when you
/// first ran together and where you have run together most —
/// "since Sep 2013 · mostly EELS H3". Falls back to their home kennel when
/// neither is known (a server before 2026-10-02, or an old cached list).
String? byHasherLine(HasherSummary h) {
  final List<String> parts = <String>[
    if (h.firstTogether != null)
      'since ${DateFormat('MMM yyyy').format(h.firstTogether!.toLocal())}',
    if ((h.mostlyKennelShortName ?? '').isNotEmpty)
      'mostly ${h.mostlyKennelShortName}',
  ];
  if (parts.isNotEmpty) return parts.join(' · ');
  return h.homeKennelShortName ?? h.homeKennelName;
}

/// Run Counts › By Hasher's row, styled as By Kennel's
/// (KennelRunHistoryCountListItem): picture = count, name above, a small
/// line below. Opens the hasher page.
class HasherRunCountListItem extends StatelessWidget {
  const HasherRunCountListItem({super.key, required this.hasher});

  final HasherSummary hasher;

  @override
  Widget build(BuildContext context) {
    final String? line = byHasherLine(hasher);
    return InkWell(
      onTap: () => unawaited(HasherPage.open(hasher)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 20.0),
            child: HasherPhoto(url: hasher.photo, size: 80),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 2.0),
            child: Text(
              ' = ',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: ts_titleCondensedVeryLargeBlack,
              textAlign: TextAlign.left,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  hasher.displayName,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: ts_titleCondensedBlack,
                  textAlign: TextAlign.left,
                ),
                Text(
                  '${hasher.runsTogether}',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: ts_titleCondensedVeryLargeBlack,
                  textAlign: TextAlign.left,
                ),
                SizedBox(
                  height: 20.0,
                  child: line == null
                      ? null
                      : Text(
                          '($line)',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: ts_titleMediumCondensedBlack.copyWith(
                            fontSize: 18.0,
                          ),
                          textAlign: TextAlign.left,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
