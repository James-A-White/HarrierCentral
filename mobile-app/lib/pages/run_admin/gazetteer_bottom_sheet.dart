import 'package:harrier_central/data/models/azure_place_model.dart';
import 'package:harrier_central/imports.dart';

class GazetteerBottomSheet extends StatefulWidget {
  const GazetteerBottomSheet({
    super.key,
    required this.initialQuery,
    required this.kennelLat,
    required this.kennelLon,
    required this.onResultSelected,
  });

  final String initialQuery;
  final double kennelLat;
  final double kennelLon;
  final void Function(AzurePlaceResult) onResultSelected;

  @override
  State<GazetteerBottomSheet> createState() => GazetteerBottomSheetState();
}

class GazetteerBottomSheetState extends State<GazetteerBottomSheet> {
  late final TextEditingController _searchController;
  List<AzurePlaceResult> _results = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    if (widget.initialQuery.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _search());
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _results = [];
    });

    try {
      final uri = Uri.parse(APP_GEOCODE_PLACE_TO_ADDRESS_API_URL).replace(
        queryParameters: {
          'q': query,
          'lat': widget.kennelLat.toString(),
          'lon': widget.kennelLon.toString(),
        },
      );
      final response = await get(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final place = AzurePlace.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
        setState(() {
          _results = place.results ?? [];
          _hasSearched = true;
        });
      }
    } catch (_) {
      // leave results empty
    } finally {
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            _buildHandle(),
            _buildHeader(),
            _buildSearchBar(),
            const Divider(height: 1),
            Expanded(child: _buildResults(scrollController)),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          Icon(Icons.search, color: hc_red, size: 22),
          const SizedBox(width: 10),
          Text('Location Lookup', style: ts_headingBlack),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              autofocus: false,
              decoration: InputDecoration(
                hintText: 'Search for a place…',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                isDense: true,
              ),
              onSubmitted: (_) => _search(),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: hc_red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            onPressed: _isSearching ? null : _search,
            child: _isSearching
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Search'),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(ScrollController scrollController) {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            _hasSearched
                ? 'No results found'
                : 'Enter a place name, address, or establishment',
            style: ts_mediumBlack.copyWith(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.separated(
      controller: scrollController,
      itemCount: _results.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (_, index) => _buildResultTile(_results[index]),
    );
  }

  Widget _buildResultTile(AzurePlaceResult result) {
    final addr = result.address;
    final name =
        result.poi?.name ?? addr?.freeformAddress ?? 'Unknown location';
    final subtitle = [
      addr?.municipality,
      addr?.countrySubdivision,
      addr?.country,
    ].where((s) => s != null && s.isNotEmpty).join(', ');

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: hc_red,
        child: const Icon(Icons.place, color: Colors.white, size: 18),
      ),
      title: Text(
        name,
        style: ts_titleMediumBlack,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: subtitle.isNotEmpty
          ? Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis)
          : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.of(context).pop();
        widget.onResultSelected(result);
      },
    );
  }
}
