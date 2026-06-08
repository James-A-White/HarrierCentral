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
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      unawaited(_silentRefresh());
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _sortList() {
    _downDowns.sort((a, b) {
      if (a.isDone == b.isDone) return a.createdAt.compareTo(b.createdAt);
      return a.isDone ? 1 : -1;
    });
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
        setState(() {
          _downDowns = all;
          _sortList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Failed to load Down Downs'), backgroundColor: Colors.red.shade700),
        );
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  // Background refresh — no loading spinner, no error snackbar on transient failures.
  Future<void> _silentRefresh() async {
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
        setState(() {
          _downDowns = all;
          _sortList();
        });
      }
    } catch (_) {
      // Silently ignore — next poll will retry.
    }
  }

  DownDownModel _copyWith(DownDownModel dd, {required bool isDone}) => DownDownModel(
        downDownId: dd.downDownId,
        chargeText: dd.chargeText,
        isDone: isDone,
        createdByDisplayName: dd.createdByDisplayName,
        createdByPhoto: dd.createdByPhoto,
        createdAt: dd.createdAt,
        hashers: dd.hashers,
      );

  Future<void> _markDone(DownDownModel dd) async {
    final ok = await _service.markDownDownDone(
      kennelId: widget.kennelId,
      eventId: widget.eventId,
      downDownId: dd.downDownId,
    );
    if (ok && mounted) {
      setState(() {
        final i = _downDowns.indexWhere((d) => d.downDownId == dd.downDownId);
        if (i >= 0) _downDowns[i] = _copyWith(dd, isDone: true);
        _sortList();
      });
    }
  }

  Future<void> _unmarkDone(DownDownModel dd) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Undo Down Down?', style: ts_alertDialogTitle),
        content: Text(
          'Mark this charge as pending again?',
          style: ts_alertDialogBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: themeBackgroundColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, undo'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final ok = await _service.unmarkDownDownDone(
      kennelId: widget.kennelId,
      eventId: widget.eventId,
      downDownId: dd.downDownId,
    );
    if (ok && mounted) {
      setState(() {
        final i = _downDowns.indexWhere((d) => d.downDownId == dd.downDownId);
        if (i >= 0) _downDowns[i] = _copyWith(dd, isDone: false);
        _sortList();
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
                        onCheckTap: dd.isDone
                            ? () => _unmarkDone(dd)
                            : () => _markDone(dd),
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
    required this.onCheckTap,
  });

  final DownDownModel dd;
  final String hasherNames;
  final VoidCallback onCheckTap;

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
              child: GestureDetector(
                onTap: onCheckTap,
                child: Icon(
                  dd.isDone ? Icons.check_circle : Icons.check_circle_outline,
                  color: dd.isDone ? Colors.yellow : Colors.lightBlueAccent,
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
