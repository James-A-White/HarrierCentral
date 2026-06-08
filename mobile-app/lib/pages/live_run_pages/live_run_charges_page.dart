import 'package:harrier_central/imports.dart';
import 'package:harrier_central/pages/run_admin/add_down_down_page.dart';

class _SongResult {
  _SongResult({required this.songId, required this.songName});
  final String songId;
  final String songName;
}

class LiveRunChargesPage extends StatefulWidget {
  const LiveRunChargesPage({
    super.key,
    required this.kennelId,
    required this.eventId,
    required this.eventName,
  });

  final String kennelId;
  final String eventId;
  final String eventName;

  @override
  State<LiveRunChargesPage> createState() => _LiveRunChargesPageState();
}

class _LiveRunChargesPageState extends State<LiveRunChargesPage> {
  final _service = RunContentService();

  bool _isLoading = true;
  List<DownDownModel> _charges = [];

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
        setState(() => _charges = all);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Failed to load charges'), backgroundColor: Colors.red.shade700),
        );
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<List<_SongResult>> _searchSongs(String query) async {
    if (query.trim().isEmpty) return [];
    final tbl = tableModel.songsTableHelper;
    final songTable = EnumDataTables.songs.commonTableName;
    final pattern = '%${query.trim()}%';
    final kId = widget.kennelId;

    final kennelRows = await database.rawQuery('''
      SELECT ${tbl.colSongId}, ${tbl.colSongName}
      FROM $songTable
      WHERE ${tbl.colRemoved} = 0
        AND (${tbl.colAddedByKennelId} = ?
             OR ${tbl.colAutoAddToKennel} > 0)
        AND LOWER(${tbl.colSongName}) LIKE LOWER(?)
      ORDER BY
        CASE WHEN ${tbl.colAddedByKennelId} = ? THEN 0 ELSE 1 END,
        ${tbl.colSongName}
      LIMIT 10
    ''', [kId, pattern, kId]);

    if (kennelRows.isNotEmpty) {
      return kennelRows
          .map((r) => _SongResult(
                songId: r[tbl.colSongId] as String,
                songName: r[tbl.colSongName] as String,
              ))
          .toList();
    }

    final globalRows = await database.rawQuery('''
      SELECT ${tbl.colSongId}, ${tbl.colSongName}
      FROM $songTable
      WHERE ${tbl.colRemoved} = 0
        AND LOWER(${tbl.colSongName}) LIKE LOWER(?)
      ORDER BY ${tbl.colSongName}
      LIMIT 10
    ''', [pattern]);

    return globalRows
        .map((r) => _SongResult(
              songId: r[tbl.colSongId] as String,
              songName: r[tbl.colSongName] as String,
            ))
        .toList();
  }

  Future<void> _showEditDialog(DownDownModel dd) async {
    final chargeController = TextEditingController(text: dd.chargeText);
    final songController = TextEditingController(text: dd.songChoice ?? '');
    String? linkedSongId = dd.songId;
    bool suppressNextSearch = false;
    List<_SongResult> songResults = [];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          Future<void> doSearch(String query) async {
            final results = await _searchSongs(query);
            setDialogState(() => songResults = results);
          }

          return AlertDialog(
            title: Text('Edit Charge', style: ts_alertDialogTitle),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: chargeController,
                    maxLines: 3,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Charge',
                      hintText: 'What did they do?',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: songController,
                    decoration: InputDecoration(
                      labelText: 'Recommended song (optional)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.music_note),
                      suffixIcon: linkedSongId != null
                          ? Tooltip(
                              message: 'Unlink song',
                              child: IconButton(
                                icon: const Icon(Icons.link_off, size: 18),
                                onPressed: () {
                                  linkedSongId = null;
                                  setDialogState(() {});
                                },
                              ),
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      if (suppressNextSearch) {
                        suppressNextSearch = false;
                        return;
                      }
                      linkedSongId = null;
                      unawaited(doSearch(value));
                    },
                  ),
                  if (songResults.isNotEmpty)
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: songResults.length,
                        itemBuilder: (context, index) {
                          final song = songResults[index];
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.music_note, size: 16, color: Colors.black54),
                            title: Text(song.songName, style: const TextStyle(fontSize: 14)),
                            onTap: () {
                              suppressNextSearch = true;
                              songController.text = song.songName;
                              linkedSongId = song.songId;
                              setDialogState(() => songResults = []);
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
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
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );

    final editedText = chargeController.text.trim();
    final editedSong = songController.text.trim();

    if (confirmed != true || editedText.isEmpty) return;

    final ok = await _service.updateDownDown(
      kennelId: widget.kennelId,
      eventId: widget.eventId,
      downDownId: dd.downDownId,
      chargeText: editedText,
      songChoice: editedSong.isEmpty ? null : editedSong,
      songId: linkedSongId,
    );

    if (mounted) {
      if (ok) {
        unawaited(_load());
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Failed to update charge'), backgroundColor: Colors.red.shade700),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = Container(
      decoration: Backgrounds.defaultHcBackground(),
      child: _isLoading
          ? const HcAppCircularProgressIndicator(key: Key('charges_loading'))
          : RefreshIndicator(
              onRefresh: _load,
              child: _charges.isEmpty
                  ? ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(30),
                          child: Center(
                            child: Text(
                              'No charges yet for this run.\nPull to refresh or tap + to add one.',
                              textAlign: TextAlign.center,
                              style: ts_headingLarge.copyWith(color: Colors.white70),
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: 80, top: 8),
                      itemCount: _charges.length,
                      separatorBuilder: (context, i) => Divider(height: 2, thickness: 1.5, color: Colors.lightBlueAccent.withValues(alpha: 0.7)),
                      itemBuilder: (context, index) {
                        final dd = _charges[index];
                        final names = dd.hashers.map((h) => h.displayName).join(', ');
                        return _ChargeTile(
                          dd: dd,
                          hasherNames: names,
                          onEdit: () => _showEditDialog(dd),
                        );
                      },
                    ),
            ),
    );

    return Stack(
      children: [
        content,
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            backgroundColor: Colors.yellow,
            foregroundColor: Colors.black87,
            onPressed: () async {
              await Get.to(
                () => AddDownDownPage(
                  kennelId: widget.kennelId,
                  eventId: widget.eventId,
                  eventName: widget.eventName,
                ),
              );
              unawaited(_load());
            },
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

class _ChargeTile extends StatelessWidget {
  const _ChargeTile({
    required this.dd,
    required this.hasherNames,
    required this.onEdit,
  });

  final DownDownModel dd;
  final String hasherNames;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                if (dd.songChoice != null && dd.songChoice!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Row(
                      children: [
                        const Icon(Icons.music_note, size: 13, color: Colors.white54),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            dd.songChoice!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white54,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 22),
            color: Colors.white54,
            onPressed: onEdit,
            tooltip: 'Edit charge',
          ),
        ],
      ),
    );
  }
}
