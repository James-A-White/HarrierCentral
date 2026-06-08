import 'package:harrier_central/imports.dart';

class _SongResult {
  _SongResult({required this.songId, required this.songName});
  final String songId;
  final String songName;
}

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
      // pending (0) → cancelled (1) → done (2)
      final rankA = a.isDone ? 2 : (a.isCancelled ? 1 : 0);
      final rankB = b.isDone ? 2 : (b.isCancelled ? 1 : 0);
      if (rankA != rankB) return rankA.compareTo(rankB);
      return a.createdAt.compareTo(b.createdAt);
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

  DownDownModel _copyWith(DownDownModel dd, {bool? isDone, bool? isCancelled}) =>
      DownDownModel(
        downDownId: dd.downDownId,
        chargeText: dd.chargeText,
        isDone: isDone ?? dd.isDone,
        isCancelled: isCancelled ?? dd.isCancelled,
        createdByDisplayName: dd.createdByDisplayName,
        createdByPhoto: dd.createdByPhoto,
        createdAt: dd.createdAt,
        songChoice: dd.songChoice,
        songId: dd.songId,
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
        if (i >= 0) _downDowns[i] = _copyWith(dd, isDone: true, isCancelled: false);
        _sortList();
      });
    }
  }

  Future<void> _unmarkDone(DownDownModel dd) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Undo Down Down?', style: ts_alertDialogTitle),
        content: Text('Mark this charge as pending again?', style: ts_alertDialogBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: themeBackgroundColor, foregroundColor: Colors.white),
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

  Future<void> _cancel(DownDownModel dd) async {
    final ok = await _service.cancelDownDown(
      kennelId: widget.kennelId,
      eventId: widget.eventId,
      downDownId: dd.downDownId,
    );
    if (ok && mounted) {
      setState(() {
        final i = _downDowns.indexWhere((d) => d.downDownId == dd.downDownId);
        if (i >= 0) _downDowns[i] = _copyWith(dd, isCancelled: true, isDone: false);
        _sortList();
      });
    }
  }

  Future<void> _uncancel(DownDownModel dd) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Restore Down Down?', style: ts_alertDialogTitle),
        content: Text('Mark this charge as pending again?', style: ts_alertDialogBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: themeBackgroundColor, foregroundColor: Colors.white),
            child: const Text('Yes, restore'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final ok = await _service.uncancelDownDown(
      kennelId: widget.kennelId,
      eventId: widget.eventId,
      downDownId: dd.downDownId,
    );
    if (ok && mounted) {
      setState(() {
        final i = _downDowns.indexWhere((d) => d.downDownId == dd.downDownId);
        if (i >= 0) _downDowns[i] = _copyWith(dd, isCancelled: false);
        _sortList();
      });
    }
  }

  // Queries common_songs: kennel + auto-add songs first, fallback to all.
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
            title: Text('Edit Down Down', style: ts_alertDialogTitle),
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

    final editedCharge = chargeController.text.trim();
    final editedSong = songController.text.trim();

    if (confirmed != true || editedCharge.isEmpty) return;

    final ok = await _service.updateDownDown(
      kennelId: widget.kennelId,
      eventId: widget.eventId,
      downDownId: dd.downDownId,
      chargeText: editedCharge,
      songChoice: editedSong.isEmpty ? null : editedSong,
      songId: linkedSongId,
    );

    if (mounted) {
      if (ok) {
        unawaited(_load());
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Failed to update'), backgroundColor: Colors.red.shade700),
        );
      }
    }
  }

  Future<void> _playSong(DownDownModel dd) async {
    if (dd.songId == null) return;
    final result = await SongSessionService.selectSong(
      eventId: widget.eventId,
      songId: dd.songId!,
    );
    if (mounted) {
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Now playing: ${result.songTitle}'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to push song'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _handleCancelTap(DownDownModel dd) {
    if (dd.isCancelled) {
      unawaited(_uncancel(dd));
    } else {
      unawaited(_cancel(dd));
    }
  }

  void _handleCheckTap(DownDownModel dd) {
    if (dd.isDone) {
      unawaited(_unmarkDone(dd));
    } else {
      unawaited(_markDone(dd));
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
                    separatorBuilder: (context, i) => Divider(
                      height: 2,
                      thickness: 1.5,
                      color: Colors.lightBlueAccent.withValues(alpha: 0.7),
                    ),
                    itemBuilder: (context, index) {
                      final dd = _downDowns[index];
                      final names = dd.hashers.map((h) => h.displayName).join(', ');
                      return _DownDownTile(
                        dd: dd,
                        hasherNames: names,
                        onCancelTap: () => _handleCancelTap(dd),
                        onCheckTap: () => _handleCheckTap(dd),
                        onEditTap: () => _showEditDialog(dd),
                        onPlayTap: dd.songId != null ? () => _playSong(dd) : null,
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
    required this.onCancelTap,
    required this.onCheckTap,
    required this.onEditTap,
    this.onPlayTap,
  });

  final DownDownModel dd;
  final String hasherNames;
  final VoidCallback onCancelTap;
  final VoidCallback onCheckTap;
  final VoidCallback onEditTap;
  final VoidCallback? onPlayTap;

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
          // Creator profile pic — rounded square, 57×57
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: 57,
              height: 57,
              color: Colors.white24,
              child: (photo != null && photo.isNotEmpty)
                  ? Image(image: _photoProvider(photo), fit: BoxFit.cover)
                  : const Icon(Icons.person, color: Colors.white54, size: 32),
            ),
          ),
          const SizedBox(width: 10),
          // Text content
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
                        if (onPlayTap != null)
                          GestureDetector(
                            onTap: onPlayTap,
                            child: const Padding(
                              padding: EdgeInsets.only(left: 6),
                              child: Icon(
                                Icons.play_circle,
                                size: 22,
                                color: Colors.yellow,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Action icons — X (cancel), check (deliver), edit
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 44,
                height: 38,
                child: Center(
                  child: GestureDetector(
                    onTap: onCancelTap,
                    child: Icon(
                      dd.isCancelled ? Icons.cancel : Icons.cancel_outlined,
                      color: dd.isCancelled ? Colors.redAccent : Colors.lightBlueAccent,
                      size: 30,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 44,
                height: 38,
                child: Center(
                  child: GestureDetector(
                    onTap: onCheckTap,
                    child: Icon(
                      dd.isDone ? Icons.check_circle : Icons.check_circle_outline,
                      color: dd.isDone ? Colors.yellow : Colors.lightBlueAccent,
                      size: 30,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 44,
                height: 34,
                child: Center(
                  child: GestureDetector(
                    onTap: onEditTap,
                    child: const Icon(Icons.edit_outlined, color: Colors.white38, size: 22),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
