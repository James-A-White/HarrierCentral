import 'package:http/http.dart' as http;
import 'package:hcportal/imports.dart';

// ---------------------------------------------------------------------------
// New kennel from a website (E12.F1.S10, James 2026-10-10) — HC Admin Tools ›
// Kennel requests › New kennel from a website. Paste the club's website; the
// AI reads it (KennelFromWebsite API) and fills a draft; a chat beside the
// draft asks for what the site does not say; Next turns the draft into an
// ordinary kennel request and opens it on the review page, where it is
// approved like any other. Platform admins only (the API's gate); the public
// hashruns.org version follows once this has been tried.
// ---------------------------------------------------------------------------

class KennelFromWebsiteController extends GetxController {
  final TextEditingController url = TextEditingController();
  final TextEditingController message = TextEditingController();
  final ScrollController chatScroll = ScrollController();

  /// The draft the API returns and is sent back on every turn.
  final Rxn<Map<String, dynamic>> draft = Rxn<Map<String, dynamic>>();
  final RxList<(String role, String text)> chat = <(String, String)>[].obs;
  final RxList<String> missing = <String>[].obs;
  final RxBool reading = false.obs;
  final RxBool sending = false.obs;
  final RxBool saving = false.obs;
  final RxString error = ''.obs;

  @override
  void onClose() {
    url.dispose();
    message.dispose();
    chatScroll.dispose();
    super.onClose();
  }

  String _token(String proc) => Utilities.generateToken(
    box.get(HIVE_DEVICE_ID) as String,
    proc,
    paramString: (box.get(HIVE_DEVICE_SECRET) as String?) ?? '',
  );

  Future<Map<String, dynamic>> _post(Map<String, dynamic> body) async {
    final http.Response r = await http
        .post(
          Uri.parse(KENNEL_FROM_WEBSITE_URL),
          headers: <String, String>{'content-type': 'application/json'},
          body: jsonEncode(<String, dynamic>{
            'deviceId': box.get(HIVE_DEVICE_ID) as String,
            'accessToken': _token('hcportal_kennelDraftLookup'),
            ...body,
          }),
        )
        .timeout(const Duration(seconds: 200));
    Map<String, dynamic> j;
    try {
      j = jsonDecode(r.body) as Map<String, dynamic>;
    } on Object {
      j = <String, dynamic>{};
    }
    if (r.statusCode != 200) {
      throw Exception((j['errorUserMessage'] as String?) ?? 'Harrier Central could not do that just now (${r.statusCode}).');
    }
    return j;
  }

  void _take(Map<String, dynamic> j) {
    draft.value = (j['draft'] as Map<String, dynamic>?) ?? draft.value;
    missing.assignAll(((j['missing'] as List<dynamic>?) ?? <dynamic>[]).map((e) => e.toString()));
    final String reply = (j['reply'] as String?) ?? '';
    if (reply.isNotEmpty) chat.add(('assistant', reply));
    _scrollDown();
  }

  void _scrollDown() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (chatScroll.hasClients) {
      unawaited(chatScroll.animateTo(chatScroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250), curve: Curves.easeOut));
    }
  });

  Future<void> read() async {
    final String u = url.text.trim();
    if (u.isEmpty || reading.value) return;
    reading.value = true;
    error.value = '';
    try {
      _take(await _post(<String, dynamic>{'action': 'read', 'url': u}));
    } on Object catch (e) {
      error.value = e.toString().replaceFirst('Exception: ', '');
    } finally {
      reading.value = false;
    }
  }

  /// No website (or one that cannot be read): the chat starts from nothing.
  void startWithoutWebsite() {
    error.value = '';
    draft.value = <String, dynamic>{'socialLinks': <dynamic>[], 'sources': <String, dynamic>{}};
    missing.assignAll(<String>['kennel name', 'city', "first admin's email"]);
    chat.assignAll(<(String, String)>[
      ('assistant', "No website — no problem. What is the club's full name, and which city does it run in?"),
    ]);
  }

  Future<void> send() async {
    final String text = message.text.trim();
    if (text.isEmpty || sending.value || draft.value == null) return;
    final List<Map<String, String>> history = chat.map((m) => <String, String>{'role': m.$1, 'text': m.$2}).toList();
    chat.add(('user', text));
    message.clear();
    _scrollDown();
    sending.value = true;
    try {
      _take(await _post(<String, dynamic>{'action': 'chat', 'draft': draft.value, 'history': history, 'message': text}));
    } on Object catch (e) {
      chat.add(('assistant', e.toString().replaceFirst('Exception: ', '')));
    } finally {
      sending.value = false;
    }
  }

  void _set(Map<String, Object?> changes) {
    final Map<String, dynamic> d = Map<String, dynamic>.of(draft.value ?? <String, dynamic>{})..addAll(changes);
    draft.value = d;
  }

  void pickCity(Map<String, dynamic> c) {
    _set(<String, Object?>{
      'cityId': c['cityId'], 'regionId': c['regionId'], 'countryId': c['countryId'],
      'city': c['cityName'], 'region': c['regionName'], 'country': c['countryName'],
    });
    missing.remove('city');
  }

  void pickLogo(String? u) => _set(<String, Object?>{'logoUrl': u});

  /// A contact the site lists becomes the first admin — the admin still checks the email.
  void useContactAsAdmin(Map<String, dynamic> c) {
    final List<String> parts = ((c['name'] as String?) ?? '').trim().split(RegExp(r'\s+'));
    _set(<String, Object?>{
      'adminHashName': c['hashName'],
      'adminFirstName': parts.isNotEmpty && parts.first.isNotEmpty ? parts.first : null,
      'adminLastName': parts.length > 1 ? parts.sublist(1).join(' ') : null,
      'adminEmail': c['email'],
    });
    if ((c['email'] as String?)?.contains('@') ?? false) missing.remove("first admin's email");
    missing.remove("first admin's name");
  }

  List<Map<String, dynamic>> get socials =>
      ((draft.value?['socialLinks'] as List<dynamic>?) ?? <dynamic>[]).whereType<Map<String, dynamic>>().toList();

  void removeSocial(int i) => _set(<String, Object?>{'socialLinks': List<Map<String, dynamic>>.of(socials)..removeAt(i)});

  void toggleAudience(int i) {
    final List<Map<String, dynamic>> l = socials.map((m) => Map<String, dynamic>.of(m)).toList();
    l[i]['audience'] = l[i]['audience'] == 'members' ? 'public' : 'members';
    _set(<String, Object?>{'socialLinks': l});
  }

  void startOver() {
    draft.value = null;
    chat.clear();
    missing.clear();
    error.value = '';
  }

  /// The draft becomes a kennel request, which opens on the review page.
  Future<void> next() async {
    if (saving.value || draft.value == null) return;
    saving.value = true;
    try {
      final Map<String, dynamic> j = await _post(<String, dynamic>{
        'action': 'save',
        'draft': draft.value,
        'createToken': _token('hcportal_createKennelRequestFromDraft'),
      });
      final String id = ((j['kennelImportId'] as String?) ?? '').toLowerCase();
      final List<String> warnings = ((j['warnings'] as List<dynamic>?) ?? <dynamic>[]).map((e) => e.toString()).toList();
      final KennelRequestPage? page = await queryKennelRequests(1);
      final KennelRequestModel? request = page?.requests.firstWhereOrNull((r) => r.id == id);
      if (request == null) {
        kennelRequestNotice('The request was saved — find it under New.');
        Get.back<void>();
        return;
      }
      unawaited(Get.off<void>(() => KennelRequestDetailPage(request: request)));
      if (warnings.isNotEmpty) kennelRequestNotice(warnings.join(' '), isError: true);
    } on Object catch (e) {
      kennelRequestNotice(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      saving.value = false;
    }
  }
}

class KennelFromWebsitePage extends StatelessWidget {
  const KennelFromWebsitePage({super.key});

  static const Color _muted = Color(0xFF6B7280);
  static const Color _warnBg = Color(0xFFFEF3C7);
  static const Color _warnText = Color(0xFF92400E);
  static const Color _sourceChip = Color(0xFFE0F2FE);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<KennelFromWebsiteController>(
      init: KennelFromWebsiteController(),
      global: false,
      builder: (c) => Scaffold(
        appBar: AppBar(
          title: const Text('New kennel from a website'),
          leading: GestureDetector(
            onTap: () => Get.back<void>(),
            child: const Icon(MaterialCommunityIcons.arrow_left, color: Colors.black),
          ),
        ),
        body: Obx(() => c.draft.value == null ? _start(c) : _workspace(c)),
      ),
    );
  }

  // ── Step 1: the website ────────────────────────────────────────────────

  Widget _start(KennelFromWebsiteController c) {
    final bool busy = c.reading.value;
    final String err = c.error.value;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text("The club's website", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              const Text(
                'Harrier Central reads the site and its main pages, fills in what it can, then asks you for the rest. '
                'Nothing is saved until you press Next.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _muted),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: c.url,
                enabled: !busy,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => c.read(),
                decoration: const InputDecoration(
                  labelText: 'Website address',
                  hintText: 'https://www.yourclub.org',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.language),
                ),
              ),
              const SizedBox(height: 16),
              HcButton.primary(label: busy ? 'Reading the website…' : 'Read the website', icon: Icons.auto_awesome, loading: busy, onPressed: c.read),
              if (busy) ...[
                const SizedBox(height: 12),
                const Text('This takes 20–60 seconds: the home page, then up to five pages it links to.',
                    textAlign: TextAlign.center, style: TextStyle(color: _muted, fontSize: 13)),
              ],
              if (err.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(err, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFDC2626))),
              ],
              const SizedBox(height: 20),
              TextButton(
                onPressed: busy ? null : c.startWithoutWebsite,
                child: const Text('No website? Start with the chat', textAlign: TextAlign.center),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Step 2: chat beside the draft ──────────────────────────────────────

  Widget _workspace(KennelFromWebsiteController c) {
    return LayoutBuilder(builder: (BuildContext context, BoxConstraints box) {
      final bool wide = box.maxWidth >= 1000;
      final Widget body = wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 5, child: _chatPanel(c)),
                const SizedBox(width: 16),
                Expanded(flex: 4, child: _draftPanel(c)),
              ],
            )
          : Column(
              children: [
                Card(
                  elevation: 1,
                  child: ExpansionTile(
                    title: Obx(() => Text(
                          (c.draft.value?['kennelName'] as String?) ?? 'The draft',
                          overflow: TextOverflow.ellipsis,
                        )),
                    subtitle: const Text('Tap to see everything read so far'),
                    children: [SizedBox(height: 420, child: _draftPanel(c))],
                  ),
                ),
                Expanded(child: _chatPanel(c)),
              ],
            );
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          children: [
            Expanded(child: body),
            const SizedBox(height: 12),
            _footer(c),
          ],
        ),
      );
    });
  }

  Widget _chatPanel(KennelFromWebsiteController c) {
    return Card(
      elevation: 1,
      child: Column(
        children: [
          Expanded(
            child: Obx(() {
              final List<(String, String)> lines = c.chat.toList();
              final bool typing = c.sending.value;
              return ListView.builder(
                controller: c.chatScroll,
                padding: const EdgeInsets.all(12),
                itemCount: lines.length + (typing ? 1 : 0),
                itemBuilder: (_, int i) {
                  if (i == lines.length) return _bubble('assistant', '…');
                  return _bubble(lines[i].$1, lines[i].$2);
                },
              );
            }),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: c.message,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => c.send(),
                    decoration: const InputDecoration(
                      hintText: 'Answer, or correct anything in the draft…',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Obx(() => IconButton.filled(
                      tooltip: 'Send',
                      onPressed: c.sending.value ? null : c.send,
                      icon: const Icon(Icons.send),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(String role, String text) {
    final bool mine = role == 'user';
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: mine ? const Color(0xFFFEE2E2) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: SelectableText(text, style: const TextStyle(fontSize: 14, height: 1.35)),
      ),
    );
  }

  Widget _draftPanel(KennelFromWebsiteController c) {
    return Card(
      elevation: 1,
      child: Obx(() {
        final Map<String, dynamic> d = c.draft.value ?? <String, dynamic>{};
        final Map<String, dynamic> sources = (d['sources'] as Map<String, dynamic>?) ?? <String, dynamic>{};
        final List<Map<String, dynamic>> dups =
            ((d['duplicates'] as List<dynamic>?) ?? <dynamic>[]).whereType<Map<String, dynamic>>().toList();
        String? v(String k) {
          final Object? x = d[k];
          final String s = x == null ? '' : x.toString().trim();
          return s.isEmpty ? null : s;
        }

        const List<String> days = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
        final int? day = d['runDay'] is num ? (d['runDay'] as num).toInt() : null;
        return ListView(
          padding: const EdgeInsets.all(14),
          children: [
            for (final Map<String, dynamic> x in dups)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: _warnBg, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  'Already here? ${x['name']} — '
                  '${x['kind'] == 'request' ? 'an open request' : 'hashruns.org/${(x['slug'] as String? ?? '').toLowerCase()}'}'
                  ' (same ${x['reason']}).',
                  style: const TextStyle(color: _warnText, fontSize: 13),
                ),
              ),
            _logoPicker(c, d),
            const SizedBox(height: 8),
            _row('Kennel name', v('kennelName'), sources['kennelName']),
            _row('Short name', v('kennelShortName'), sources['kennelShortName']),
            _row('Description', v('description'), sources['description'], maxLines: 6),
            _row('Website', v('kennelUrl'), null),
            _cityRow(c, d, sources['city']),
            _row('Usual run', [if (day != null && day >= 1 && day <= 7) days[day], v('runTime')].whereType<String>().join(' at ').ifEmptyNull,
                sources['runDay'] ?? sources['runTime']),
            _row('Run fee', [
              if (v('feeMembers') != null) 'members ${v('feeMembers')}',
              if (v('feeVisitors') != null && v('feeVisitors') != v('feeMembers')) 'visitors ${v('feeVisitors')}',
            ].join(' · ').ifEmptyNull, sources['feeMembers']),
            if (v('feeNotes') != null) _row('Fees, as the site says', v('feeNotes'), null),
            _row('Founded', v('foundedOn'), sources['foundedOn']),
            _row('Runs page', v('runsPageUrl'), null),
            const Divider(height: 24),
            _row('First admin', [
              v('adminHashName'),
              [v('adminFirstName'), v('adminLastName')].whereType<String>().join(' ').ifEmptyNull,
              v('adminEmail'),
            ].whereType<String>().join(' · ').ifEmptyNull, null),
            _contacts(c, d),
            const Divider(height: 24),
            _socials(c),
          ],
        );
      }),
    );
  }

  Widget _row(String label, String? value, Object? source, {int maxLines = 3}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(fontSize: 13, color: _muted))),
          Expanded(
            child: Text(
              value ?? '—',
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, color: value == null ? _muted : null),
            ),
          ),
          if (value != null && source != null)
            Tooltip(
              message: 'The website says: "$source"',
              child: Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: _sourceChip, borderRadius: BorderRadius.circular(6)),
                child: const Text('from website', style: TextStyle(fontSize: 11)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _cityRow(KennelFromWebsiteController c, Map<String, dynamic> d, Object? source) {
    final bool matched = (d['cityId'] as String?)?.isNotEmpty ?? false;
    final List<Map<String, dynamic>> cands =
        ((d['cityCandidates'] as List<dynamic>?) ?? <dynamic>[]).whereType<Map<String, dynamic>>().toList();
    if (matched) {
      return _row('City', [d['city'], d['region'], d['country']].whereType<String>().join(', '), source);
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row('City', d['city'] == null ? null : '${d['city']} — not matched to our list', null),
          if (cands.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final Map<String, dynamic> x in cands)
                  ActionChip(
                    label: Text('${x['cityName']}, ${x['regionName']}, ${x['countryName']}', textAlign: TextAlign.center),
                    onPressed: () => c.pickCity(x),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _logoPicker(KennelFromWebsiteController c, Map<String, dynamic> d) {
    final String? chosen = d['logoUrl'] as String?;
    final List<String> cands = ((d['logoCandidates'] as List<dynamic>?) ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map((m) => m['url'] as String? ?? '')
        .where((u) => u.isNotEmpty)
        .toList();
    Widget img(String u, double h) => Image.network(
          u,
          height: h,
          fit: BoxFit.contain, // a kennel logo is never cropped
          errorBuilder: (_, _, _) => SizedBox(height: h, width: h, child: const Icon(Icons.broken_image_outlined, color: _muted)),
        );
    return Column(
      children: [
        Container(
          height: 130,
          alignment: Alignment.center,
          child: chosen == null ? const Text('No logo — a Harrier Central coin until one is uploaded', style: TextStyle(color: _muted)) : img(chosen, 120),
        ),
        if (cands.length > 1 || (cands.length == 1 && chosen == null))
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final String u in cands)
                InkWell(
                  onTap: () => c.pickLogo(u),
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      border: Border.all(color: u == chosen ? const Color(0xFFDC2626) : const Color(0xFFE5E7EB), width: 2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: img(u, 44),
                  ),
                ),
              TextButton(onPressed: () => c.pickLogo(null), child: const Text('No logo', textAlign: TextAlign.center)),
            ],
          ),
        const Text('Stored as an 800 × 800 picture with a transparent background.',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: _muted)),
      ],
    );
  }

  Widget _contacts(KennelFromWebsiteController c, Map<String, dynamic> d) {
    final List<Map<String, dynamic>> list =
        ((d['contacts'] as List<dynamic>?) ?? <dynamic>[]).whereType<Map<String, dynamic>>().toList();
    if (list.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('People the site names', style: TextStyle(fontSize: 13, color: _muted)),
        for (final Map<String, dynamic> p in list)
          Row(
            children: [
              Expanded(
                child: Text(
                  [p['role'], p['hashName'], p['name'], p['email']].whereType<String>().where((s) => s.isNotEmpty).join(' · '),
                  style: const TextStyle(fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(onPressed: () => c.useContactAsAdmin(p), child: const Text('Make admin', textAlign: TextAlign.center)),
            ],
          ),
      ],
    );
  }

  Widget _socials(KennelFromWebsiteController c) {
    final List<Map<String, dynamic>> list = c.socials;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Social and chat links (add more in the chat)', style: TextStyle(fontSize: 13, color: _muted)),
        if (list.isEmpty) const Text('None found', style: TextStyle(color: _muted)),
        for (int i = 0; i < list.length; i++)
          Row(
            children: [
              Icon(socialPlatformIcon(list[i]['platform'] as String? ?? ''), size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${socialPlatformLabel(list[i]['platform'] as String? ?? 'other')}: ${list[i]['url'] ?? list[i]['handle'] ?? ''}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              Tooltip(
                message: 'Who sees it on the kennel page — tap to change',
                child: TextButton(
                  onPressed: () => c.toggleAudience(i),
                  child: Text(list[i]['audience'] == 'members' ? 'Members' : 'Everyone', textAlign: TextAlign.center),
                ),
              ),
              IconButton(tooltip: 'Remove', icon: const Icon(Icons.close, size: 18), onPressed: () => c.removeSocial(i)),
            ],
          ),
      ],
    );
  }

  Widget _footer(KennelFromWebsiteController c) {
    return Obx(() {
      final List<String> m = c.missing.toList();
      final bool hasName = ((c.draft.value?['kennelName'] as String?) ?? '').trim().isNotEmpty;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            m.isEmpty ? 'Everything is filled in.' : 'Still needed: ${m.join(', ')}. You can also finish these on the review page.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: _muted),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              HcButton.secondary(label: 'Start over', onPressed: c.saving.value ? null : c.startOver),
              HcButton.primary(
                label: 'Next: review the request',
                icon: Icons.arrow_forward,
                loading: c.saving.value,
                onPressed: hasName ? c.next : null,
              ),
            ],
          ),
        ],
      );
    });
  }
}

extension on String {
  String? get ifEmptyNull => isEmpty ? null : this;
}
