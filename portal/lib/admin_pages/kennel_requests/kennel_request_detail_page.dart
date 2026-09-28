import 'package:hcportal/imports.dart';
import 'package:intl/intl.dart';

// ---------------------------------------------------------------------------
// One kennel request (E12.F1.S5–S6): what was asked for, the warnings that
// matter before approving, the fields a reviewer may correct — the location
// always from the database's own countries, regions and cities — and the
// decision: Approve, Reject ▾ (rejected · spam · duplicate), or Reopen.
// ---------------------------------------------------------------------------

class KennelRequestDetailPage extends StatelessWidget {
  const KennelRequestDetailPage({super.key, required this.request});

  final KennelRequestModel request;

  static const Color _muted = Color(0xFF6B7280);
  static const Color _warnBg = Color(0xFFFEF3C7);
  static const Color _warnText = Color(0xFF92400E);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<KennelRequestDetailController>(
      init: KennelRequestDetailController(request),
      global: false,
      builder: (c) => Scaffold(
        appBar: AppBar(
          title: Text(request.kennelName, overflow: TextOverflow.ellipsis),
          leading: GestureDetector(
            onTap: () => Get.back<void>(),
            child: const Icon(MaterialCommunityIcons.arrow_left, color: Colors.black),
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              children: [
                _summary(),
                const SizedBox(height: 12),
                ..._warnings(c),
                _section('The kennel'),
                _field(c.kennelName, 'Kennel name', enabled: request.isOpen),
                _field(
                  c.shortName,
                  'Short name — letters and digits, becomes hashruns.org/<short name>',
                  enabled: request.isOpen,
                ),
                _field(c.description, 'Description', enabled: request.isOpen, maxLines: 6),
                _field(c.kennelUrl, 'Website', enabled: request.isOpen),
                _field(c.facebookUrl, 'Facebook page', enabled: request.isOpen),
                _field(c.hashCash, 'Hash cash (the number becomes the default run price)', enabled: request.isOpen),
                _section('Where'),
                if (request.countryText != null || request.cityText != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'They wrote: ${[request.cityText, request.regionText, request.countryText].whereType<String>().join(', ')}',
                      style: const TextStyle(fontSize: 13, color: _muted),
                    ),
                  ),
                _locationPickers(c),
                _section('Who asked — becomes the kennel admin'),
                _field(c.firstName, 'First name', enabled: request.isOpen),
                _field(c.lastName, 'Last name', enabled: request.isOpen),
                _field(c.hashName, 'Hash name', enabled: request.isOpen),
                _field(c.email, 'Email (their sign-in code goes here)', enabled: request.isOpen),
                _answers(),
                _section('Review'),
                _field(c.reviewNote, 'Note (kept with the request; shown on the list)', maxLines: 3),
                const SizedBox(height: 16),
                _actions(context, c),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _summary() {
    final r = request;
    final fmt = DateFormat('d MMM yyyy, HH:mm');
    final lines = <String>[
      'Status: ${KennelRequestStatus.fromCode(r.status).label}',
      if (r.submittedOn != null) 'Sent ${fmt.format(r.submittedOn!.toLocal())}',
      if (r.confirmedAt != null) 'Email confirmed ${fmt.format(r.confirmedAt!.toLocal())}',
      if (r.reviewedAt != null)
        'Reviewed ${fmt.format(r.reviewedAt!.toLocal())}${r.reviewedByHashName == null ? '' : ' by ${r.reviewedByHashName}'}',
      if (r.submitIp != null) 'From ${r.submitIp}',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(lines.join('  ·  '), style: const TextStyle(fontSize: 13, color: _muted)),
        if (r.approvedKennelSlug != null) ...[
          const SizedBox(height: 8),
          InkWell(
            onTap: () => unawaited(launchUrl(
              Uri.parse('https://www.hashruns.org/${r.approvedKennelSlug!.toLowerCase()}'),
              webOnlyWindowName: '_blank',
            )),
            child: Text(
              'hashruns.org/${r.approvedKennelSlug!.toLowerCase()}',
              style: const TextStyle(color: Color(0xFF1E40AF), decoration: TextDecoration.underline),
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _warnings(KennelRequestDetailController c) {
    final r = request;
    final items = <String>[
      if (r.similarKennels != null)
        'Kennels with the same name already exist: ${r.similarKennels}. Is this a duplicate?',
      if (r.existingHashName != null)
        '${r.email} already has an account (${r.existingHashName}). Approving makes that account the admin; no new account is made.',
      if (r.isOpen && r.status == 0)
        'The requester has not confirmed their email yet.',
    ];
    return [
      for (final w in items)
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: _warnBg, borderRadius: BorderRadius.circular(8)),
          child: Text(w, style: const TextStyle(color: _warnText, fontSize: 13)),
        ),
    ];
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 8),
    child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
  );

  Widget _field(
    TextEditingController controller,
    String label, {
    bool enabled = true,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        enabled: enabled,
        minLines: 1,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true),
      ),
    );
  }

  Widget _locationPickers(KennelRequestDetailController c) {
    Widget picker(
      String label,
      Map<String, String> options,
      String? value,
      void Function(String?) onChanged,
    ) {
      final entries = options.entries.toList();
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: DropdownButtonFormField<String>(
          // A value the options do not (yet) hold would assert.
          initialValue: options.containsKey(value) ? value : null,
          isExpanded: true,
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true),
          items: [
            for (final e in entries) DropdownMenuItem(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis)),
          ],
          onChanged: request.isOpen ? onChanged : null,
        ),
      );
    }

    return Obx(() {
      final countries = Map<String, String>.of(c.countryOptions);
      final regions = Map<String, String>.of(c.regionOptions);
      final cities = Map<String, String>.of(c.cityOptions);
      final country = c.countryId.value;
      final region = c.regionId.value;
      final city = c.cityId.value;
      return Column(
        children: [
          // Keys make each picker start again when its options change.
          KeyedSubtree(
            key: ValueKey('country-${countries.length}-$country'),
            child: picker('Country', countries, country, c.pickCountry),
          ),
          KeyedSubtree(
            key: ValueKey('region-$country-${regions.length}-$region'),
            child: picker('Region', regions, region, c.pickRegion),
          ),
          KeyedSubtree(
            key: ValueKey('city-$region-${cities.length}-$city'),
            child: picker('City', cities, city, c.pickCity),
          ),
          if (request.isOpen && country != null && region != null && cities.isNotEmpty && city == null)
            const Text(
              'City not listed? Pick the nearest one — the kennel admin can refine it later.',
              style: TextStyle(fontSize: 12, color: _muted),
              textAlign: TextAlign.center,
            ),
        ],
      );
    });
  }

  Widget _answers() {
    final r = request;
    final rows = <(String, String?)>[
      ('Runs per month', r.runsPerMonth),
      ('Hashers per run', r.hashersPerRun),
      ('Next run number', r.nextRunNumber),
      ('How they heard of us', r.howDidYouLearn),
      ('Comments', r.comments),
    ].where((e) => e.$2 != null && e.$2 != 'Unknown').toList();
    if (rows.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _section('Their other answers'),
        for (final (label, value) in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text.rich(TextSpan(children: [
              TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
              TextSpan(text: value),
            ])),
          ),
      ],
    );
  }

  Widget _actions(BuildContext context, KennelRequestDetailController c) {
    return Obx(() {
      final busy = c.isBusy.value;
      final dirty = c.isDirty.value;
      final hasCity = c.cityId.value != null;
      if (!request.isOpen) {
        return Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            if (dirty)
              HcButton.secondary(label: 'Save note', loading: busy, onPressed: () => _saveNote(c)),
            if (request.status != 2)
              HcButton.primary(label: 'Reopen', loading: busy, onPressed: () => _close(c, 1)),
          ],
        );
      }
      return Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: [
          HcButton.primary(
            label: 'Approve',
            icon: MaterialCommunityIcons.check,
            loading: busy,
            onPressed: hasCity ? () => _approve(context, c) : null,
          ),
          HcButton.secondary(
            label: 'Save changes',
            onPressed: (busy || !dirty) ? null : () => _save(c),
          ),
          PopupMenuButton<int>(
            enabled: !busy,
            tooltip: 'Reject',
            onSelected: (s) => _close(c, s),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 3, child: Text('Reject')),
              PopupMenuItem(value: 4, child: Text('Spam')),
              PopupMenuItem(value: 5, child: Text('Duplicate')),
            ],
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Reject', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFDC2626))),
                  Icon(MaterialCommunityIcons.menu_down, color: Color(0xFFDC2626)),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  Future<void> _save(KennelRequestDetailController c) async {
    if (await c.save()) kennelRequestNotice('Changes saved.');
  }

  Future<void> _saveNote(KennelRequestDetailController c) async {
    if (await c.save()) kennelRequestNotice('Note saved.');
  }

  Future<void> _close(KennelRequestDetailController c, int status) async {
    final label = KennelRequestStatus.fromCode(status).label.toLowerCase();
    if (await c.setStatus(status)) {
      Get.back<void>();
      kennelRequestNotice(status == 1 ? 'Request reopened.' : 'Request marked $label.');
    }
  }

  Future<void> _approve(BuildContext context, KennelRequestDetailController c) async {
    final shortName = c.shortName.text.trim();
    if (!c.shortNameIsValid) {
      kennelRequestNotice('The short name may only hold letters and digits (up to 20) — edit it first.', isError: true);
      return;
    }
    final confirmed = await Get.defaultDialog<bool>(
      title: 'Approve ${c.kennelName.text.trim()}?',
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          'This creates the kennel (web address based on $shortName), makes '
          '${c.email.text.trim()} its admin — '
          '${request.existingHashName == null ? 'with a new account' : 'using their existing account'} — '
          'adds the platform admins as helpers, and emails them a sign-in code.',
          textAlign: TextAlign.center,
        ),
      ),
      actions: [
        HcButton.secondary(label: 'Cancel', onPressed: () => Get.back(result: false)),
        HcButton.primary(label: 'Approve', onPressed: () => Get.back(result: true)),
      ],
    );
    if (confirmed != true) return;

    final made = await c.approve();
    if (made == null) return;
    Get.back<void>();
    unawaited(Get.defaultDialog<void>(
      title: '${made.kennelName} is live',
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SelectableText('hashruns.org/${made.slug}', textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              made.welcomeEmailSent
                  ? 'Welcome email with the sign-in code sent to ${made.adminEmail}.'
                  : 'The welcome email to ${made.adminEmail} could NOT be sent — '
                        'they can request a code from the app with that address.',
              textAlign: TextAlign.center,
              style: TextStyle(color: made.welcomeEmailSent ? null : const Color(0xFFDC2626)),
            ),
          ],
        ),
      ),
      actions: [HcButton.primary(label: 'OK', onPressed: () => Get.back<void>())],
    ));
  }
}
