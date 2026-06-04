import 'package:harrier_central/imports.dart';

class FindMyAccountPage extends StatefulWidget {
  const FindMyAccountPage({super.key});

  @override
  State<FindMyAccountPage> createState() => _FindMyAccountPageState();
}

class _FindMyAccountPageState extends State<FindMyAccountPage> {
  final TextEditingController _hashNameController = TextEditingController();
  bool _isSearching = false;
  bool _noResultsFound = false;

  @override
  void dispose() {
    _hashNameController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final String hashName = _hashNameController.text.trim();
    if (hashName.length < 2) {
      await Utilities.showAlert(
        'Too short',
        'Please enter at least 2 characters.',
        'OK',
      );
      return;
    }

    setState(() {
      _isSearching = true;
      _noResultsFound = false;
    });

    final (:double? lat, :double? lon) =
        await FindMyAccountService.resolveLocation();

    final List<HasherKennelMatch>? results =
        await FindMyAccountService.findHashersByHashName(
      hashName: hashName,
      lat: lat,
      lon: lon,
    );

    if (!mounted) return;
    setState(() => _isSearching = false);

    if (results == null) {
      await Utilities.showAlert(
        'Search failed',
        'We could not complete your search. Please check your connection and try again.',
        'OK',
      );
      return;
    }

    if (results.isEmpty) {
      setState(() => _noResultsFound = true);
      return;
    }

    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => HasherSearchResultsPage(matches: results),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: themeAppBarBackground,
        iconTheme: const IconThemeData(color: Colors.white, size: 28.0),
        title: Text('Find My Account', style: ts_appBarTitle),
      ),
      body: Container(
        decoration: Backgrounds.defaultHcBackground(),
        width: MediaQuery.sizeOf(context).width,
        height: MediaQuery.sizeOf(context).height,
        child: SafeArea(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 28.0, vertical: 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Do you have a hash name?',
                  style: ts_headingVeryLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Enter your hash name and we\'ll check whether a Harrier Central account already exists for you.',
                  style: ts_body,
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _hashNameController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  onSubmitted: (_) => _search(),
                  style: ts_body,
                  decoration: InputDecoration(
                    hintText: 'Hash name',
                    hintStyle: ts_hint,
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon:
                        const Icon(Icons.search, color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isSearching ? null : _search,
                    child: _isSearching
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text('Search', style: ts_button),
                  ),
                ),
                if (_noResultsFound) ...<Widget>[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'No account found',
                          style: ts_body.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'We couldn\'t find a Harrier Central account with that hash name near you. You can create a new account below, or ask your kennel mis-management for an invite code.',
                          style: ts_body,
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 40),
                const Divider(color: Colors.white24),
                const SizedBox(height: 16),
                Text(
                  'Already have an invite code?',
                  style: ts_body.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 10),
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
                    onPressed: () => Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const UseInviteCodePage(),
                      ),
                    ),
                    child: Text('I have an invite code', style: ts_button),
                  ),
                ),
                const SizedBox(height: 12),
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
                    onPressed: () => Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const CreateNewAccountPage(),
                      ),
                    ),
                    child: Text(
                      "I definitely don't have an account",
                      style: ts_button,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
