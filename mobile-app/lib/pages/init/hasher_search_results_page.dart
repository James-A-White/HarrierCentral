import 'package:harrier_central/imports.dart';

class HasherSearchResultsPage extends StatefulWidget {
  const HasherSearchResultsPage({super.key, required this.matches});

  final List<HasherKennelMatch> matches;

  @override
  State<HasherSearchResultsPage> createState() =>
      _HasherSearchResultsPageState();
}

class _HasherSearchResultsPageState extends State<HasherSearchResultsPage> {
  String? _selectedPublicHasherId;
  String? _selectedKennelId;
  bool _isSending = false;

  Map<String, List<HasherKennelMatch>> get _grouped {
    final Map<String, List<HasherKennelMatch>> map =
        <String, List<HasherKennelMatch>>{};
    for (final HasherKennelMatch m in widget.matches) {
      map.putIfAbsent(m.publicHasherId, () => <HasherKennelMatch>[]).add(m);
    }
    return map;
  }

  void _selectKennel(String publicHasherId, String kennelId) {
    setState(() {
      _selectedPublicHasherId = publicHasherId;
      _selectedKennelId = kennelId;
    });
  }

  Future<void> _sendInviteCode() async {
    if (_selectedPublicHasherId == null) return;
    setState(() => _isSending = true);

    final bool success =
        await FindMyAccountService.requestInviteCodeByPublicHasherId(
      _selectedPublicHasherId!,
    );

    if (!mounted) return;
    setState(() => _isSending = false);

    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green.shade700,
          content: const Text(
            "We've sent your invite code by email. Check your inbox!",
            style: TextStyle(color: Colors.white),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
      await Future<void>.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      await Navigator.pushReplacement<void, void>(
        context,
        MaterialPageRoute<void>(builder: (_) => const UseInviteCodePage()),
      );
    } else {
      await Utilities.showAlert(
        'Send failed',
        'We could not send your invite code. Please check your connection and try again.',
        'OK',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, List<HasherKennelMatch>> grouped = _grouped;
    final List<String> hasherIds = grouped.keys.toList();

    return AppScaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: themeAppBarBackground,
        iconTheme: const IconThemeData(color: Colors.white, size: 28.0),
        title: Text('We found some matches', style: ts_appBarTitle),
      ),
      body: Container(
        decoration: Backgrounds.defaultHcBackground(),
        child: Column(
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'We found ${widget.matches.length == 1 ? 'an account' : 'some accounts'} that may be yours.',
                      style: ts_body,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap your kennel to select it — we\'ll email you an invite code.',
                      style: ts_body.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 20),
                    for (final String hasherId in hasherIds) ...<Widget>[
                      _HasherCard(
                        matches: grouped[hasherId]!,
                        selectedKennelId:
                            _selectedPublicHasherId == hasherId
                                ? _selectedKennelId
                                : null,
                        onKennelSelected: (String kennelId) =>
                            _selectKennel(hasherId, kennelId),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: _selectedKennelId != null
                            ? Colors.green.shade700
                            : Colors.grey.shade600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed:
                          _selectedKennelId == null || _isSending
                              ? null
                              : _sendInviteCode,
                      child: _isSending
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text('Send me my invite code', style: ts_button),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pushReplacement<void, void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const CreateNewAccountPage(),
                      ),
                    ),
                    child: Text(
                      "None of these are me — create a new account",
                      style:
                          ts_body.copyWith(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hasher card — shows photo + name with expandable kennel rows
// ---------------------------------------------------------------------------

class _HasherCard extends StatelessWidget {
  const _HasherCard({
    required this.matches,
    required this.selectedKennelId,
    required this.onKennelSelected,
  });

  final List<HasherKennelMatch> matches;
  final String? selectedKennelId;
  final void Function(String kennelId) onKennelSelected;

  @override
  Widget build(BuildContext context) {
    final HasherKennelMatch hasher = matches.first;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                ProfilePhoto(
                  profilePhotoUrl:
                      hasher.photo.isEmpty ? null : hasher.photo,
                  photoHeight: 44,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    hasher.displayName,
                    style: ts_body.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 6),
            Text(
              'Kennels',
              style: ts_body.copyWith(
                color: Colors.white54,
                fontSize: 11,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 4),
            for (final HasherKennelMatch kennel in matches)
              _KennelRow(
                kennel: kennel,
                isSelected: selectedKennelId == kennel.kennelId,
                onTap: () => onKennelSelected(kennel.kennelId),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Kennel row — tappable with selection highlight
// ---------------------------------------------------------------------------

class _KennelRow extends StatelessWidget {
  const _KennelRow({
    required this.kennel,
    required this.isSelected,
    required this.onTap,
  });

  final HasherKennelMatch kennel;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.green.shade700.withOpacity(0.4)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.green.shade400 : Colors.transparent,
          ),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? Colors.green.shade300 : Colors.white38,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                kennel.kennelName,
                style: ts_body.copyWith(
                  color: isSelected ? Colors.white : Colors.white70,
                ),
              ),
            ),
            Text(
              '${kennel.runCount} run${kennel.runCount == 1 ? '' : 's'}',
              style: ts_body.copyWith(
                color: Colors.white38,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
