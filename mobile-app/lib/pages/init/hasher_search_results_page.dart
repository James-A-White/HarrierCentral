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
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    final Map<String, List<HasherKennelMatch>> grouped = _grouped;
    if (grouped.length == 1) {
      _selectedPublicHasherId = grouped.keys.first;
    }
  }

  Map<String, List<HasherKennelMatch>> get _grouped {
    final Map<String, List<HasherKennelMatch>> map =
        <String, List<HasherKennelMatch>>{};
    for (final HasherKennelMatch m in widget.matches) {
      map.putIfAbsent(m.publicHasherId, () => <HasherKennelMatch>[]).add(m);
    }
    return map;
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
          backgroundColor: Colors.teal.shade700,
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
                        isSelected: _selectedPublicHasherId == hasherId,
                        onTap: () => setState(
                          () => _selectedPublicHasherId = hasherId,
                        ),
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
                        backgroundColor: _selectedPublicHasherId != null
                            ? Colors.green.shade700
                            : Colors.grey.shade600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed:
                          _selectedPublicHasherId == null || _isSending
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
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Colors.white38),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pushReplacement<void, void>(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const CreateNewAccountPage(),
                        ),
                      ),
                      child: Text(
                        "None of these are me",
                        style: ts_button,
                      ),
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
// Hasher card — tappable at the hasher level; kennels shown as context only
// ---------------------------------------------------------------------------

class _HasherCard extends StatelessWidget {
  const _HasherCard({
    required this.matches,
    required this.isSelected,
    required this.onTap,
  });

  final List<HasherKennelMatch> matches;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final HasherKennelMatch hasher = matches.first;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.green.shade700.withOpacity(0.25)
              : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.green.shade400 : Colors.white12,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  ProfilePhoto(
                    profilePhotoUrl: hasher.photo.isEmpty ? null : hasher.photo,
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
                  Icon(
                    isSelected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color:
                        isSelected ? Colors.green.shade300 : Colors.white38,
                    size: 24,
                  ),
                ],
              ),
              if (matches.isNotEmpty) ...<Widget>[
                const SizedBox(height: 10),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 8),
                Text(
                  'Run history',
                  style: ts_body.copyWith(
                    color: Colors.white54,
                    fontSize: 11,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                for (final HasherKennelMatch kennel in matches)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            kennel.kennelName,
                            style:
                                ts_body.copyWith(color: Colors.white70),
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
              ],
            ],
          ),
        ),
      ),
    );
  }
}
