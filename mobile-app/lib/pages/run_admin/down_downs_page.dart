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
        decoration: Backgrounds.defaultHcBackgroundLight(),
        child: _isLoading
            ? const HcAppCircularProgressIndicator(key: Key('dd_loading'))
            : _downDowns.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(30),
                      child: Text(
                        'No Down Downs yet for this run',
                        textAlign: TextAlign.center,
                        style: ts_headingLarge.copyWith(color: themeBackgroundColor),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _downDowns.length,
                    separatorBuilder: (context, i) => const Divider(height: 1, color: Colors.black26),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: dd.isDone ? Colors.green.withValues(alpha: 0.08) : null,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                      color: Colors.black87,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  dd.chargeText,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Text(
                  'by ${dd.createdByDisplayName}',
                  style: const TextStyle(fontSize: 12, color: Colors.black45),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          dd.isDone
              ? const Icon(Icons.check_circle, color: Colors.green, size: 32)
              : IconButton(
                  icon: const Icon(Icons.check_circle_outline, size: 32),
                  color: Colors.grey,
                  onPressed: onMarkDone,
                  tooltip: 'Mark done',
                ),
        ],
      ),
    );
  }
}
