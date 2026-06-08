import 'package:harrier_central/imports.dart';

class DownDownsPage extends StatefulWidget {
  const DownDownsPage({
    super.key,
    required this.kennelId,
    required this.eventId,
    required this.eventName,
  });

  final String kennelId;
  final String eventId;
  final String eventName;

  @override
  State<DownDownsPage> createState() => _DownDownsPageState();
}

class _DownDownsPageState extends State<DownDownsPage> {
  final _service = RunContentService();

  bool _isLoading = true;
  List<DownDownModel> _downDowns = [];

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final result = await _service.getDownDowns(
        kennelId: widget.kennelId,
        eventId: widget.eventId,
      );
      if (result != null && mounted) {
        final all = result.downDowns;
        for (final dd in all) {
          dd.hashers = result.hashers
              .where((h) => h.downDownId == dd.downDownId)
              .toList();
        }
        setState(() { _downDowns = all; });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load DownDowns'), backgroundColor: Colors.red.shade700),
        );
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _markDone(DownDownModel dd) async {
    final ok = await _service.markDownDownDone(
      kennelId: widget.kennelId,
      eventId: widget.eventId,
      downDownId: dd.downDownId,
    );
    if (ok && mounted) {
      setState(() {
        final index = _downDowns.indexWhere((d) => d.downDownId == dd.downDownId);
        if (index >= 0) {
          _downDowns[index] = DownDownModel(
            downDownId: dd.downDownId,
            chargeText: dd.chargeText,
            isDone: true,
            createdByDisplayName: dd.createdByDisplayName,
            createdByPhoto: dd.createdByPhoto,
            createdAt: dd.createdAt,
            hashers: dd.hashers,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: themeAppBarBackground,
        iconTheme: const IconThemeData(color: Colors.white, size: 28.0),
        title: Text('Down Downs', style: ts_appBarTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _load,
          ),
        ],
      ),
      body: Container(
        decoration: Backgrounds.defaultHcBackground(),
        child: _isLoading
            ? const HcAppCircularProgressIndicator(key: Key('dd_loading'))
            : _downDowns.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(30),
                      child: Text(
                        'No Down Downs yet for this run',
                        textAlign: TextAlign.center,
                        style: ts_headingLarge.copyWith(color: Colors.white),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _downDowns.length,
                    separatorBuilder: (context, i) => const Divider(height: 1, color: Colors.white12),
                    itemBuilder: (context, index) {
                      final dd = _downDowns[index];
                      final names = dd.hashers.map((h) => h.displayName).join(', ');
                      return _DownDownTile(
                        dd: dd,
                        hasherNames: names,
                        onMarkDone: dd.isDone ? null : () => _markDone(dd),
                      );
                    },
                  ),
      ),
    );
  }
}

class _DownDownTile extends StatelessWidget {
  const _DownDownTile({
    required this.dd,
    required this.hasherNames,
    this.onMarkDone,
  });

  final DownDownModel dd;
  final String hasherNames;
  final VoidCallback? onMarkDone;

  ImageProvider _photoProvider(String photo) {
    if (photo.startsWith('https://')) return NetworkImage(photo);
    return AssetImage('images/avatars/${photo.replaceAll('bundle://', '')}.jpg');
  }

  @override
  Widget build(BuildContext context) {
    final photo = dd.createdByPhoto;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Creator profile pic
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white24,
            backgroundImage: (photo != null && photo.isNotEmpty)
                ? _photoProvider(photo)
                : null,
            child: (photo == null || photo.isEmpty)
                ? const Icon(Icons.person, color: Colors.white54, size: 24)
                : null,
          ),
          const SizedBox(width: 10),
          // Text — flows past the avatar if the charge is long
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasherNames.isNotEmpty)
                  Text(
                    hasherNames,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.yellow,
                    ),
                  ),
                Text(
                  'by ${dd.createdByDisplayName}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontStyle: FontStyle.italic,
                    color: Colors.yellow,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  dd.chargeText,
                  style: const TextStyle(fontSize: 14, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Checkmark — fixed 44×44 so done/not-done never shift alignment
          SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: dd.isDone
                  ? const Icon(Icons.check_circle, color: Colors.yellow, size: 32)
                  : GestureDetector(
                      onTap: onMarkDone,
                      child: const Icon(
                        Icons.check_circle_outline,
                        color: Colors.lightBlueAccent,
                        size: 32,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
