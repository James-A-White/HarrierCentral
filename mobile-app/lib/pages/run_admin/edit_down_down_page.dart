import 'package:harrier_central/imports.dart';

class _SongResult {
  _SongResult({required this.songId, required this.songName});
  final String songId;
  final String songName;
}

class EditDownDownPage extends StatefulWidget {
  const EditDownDownPage({
    super.key,
    required this.kennelId,
    required this.eventId,
    required this.downDown,
    this.pageTitle = 'Edit Charge',
  });

  final String kennelId;
  final String eventId;
  final DownDownModel downDown;
  final String pageTitle;

  @override
  State<EditDownDownPage> createState() => _EditDownDownPageState();
}

class _EditDownDownPageState extends State<EditDownDownPage> {
  final _service = RunContentService();
  late final TextEditingController _chargeController;
  late final TextEditingController _songController;

  String? _linkedSongId;
  bool _suppressNextSearch = false;
  List<_SongResult> _songResults = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _chargeController = TextEditingController(text: widget.downDown.chargeText);
    _songController = TextEditingController(text: widget.downDown.songChoice ?? '');
    _linkedSongId = widget.downDown.songId;
  }

  @override
  void dispose() {
    _chargeController.dispose();
    _songController.dispose();
    super.dispose();
  }

  Future<void> _searchSongs(String query) async {
    if (query.trim().isEmpty) {
      if (mounted) setState(() => _songResults = []);
      return;
    }
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
      LIMIT 30
    ''', [kId, pattern, kId]);

    if (kennelRows.isNotEmpty) {
      if (mounted) {
        setState(() => _songResults = kennelRows
            .map((r) => _SongResult(
                  songId: r[tbl.colSongId] as String,
                  songName: r[tbl.colSongName] as String,
                ))
            .toList());
      }
      return;
    }

    final globalRows = await database.rawQuery('''
      SELECT ${tbl.colSongId}, ${tbl.colSongName}
      FROM $songTable
      WHERE ${tbl.colRemoved} = 0
        AND LOWER(${tbl.colSongName}) LIKE LOWER(?)
      ORDER BY ${tbl.colSongName}
      LIMIT 30
    ''', [pattern]);

    if (mounted) {
      setState(() => _songResults = globalRows
          .map((r) => _SongResult(
                songId: r[tbl.colSongId] as String,
                songName: r[tbl.colSongName] as String,
              ))
          .toList());
    }
  }

  Future<void> _save() async {
    final chargeText = _chargeController.text.trim();
    if (chargeText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Charge text is required')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final songText = _songController.text.trim();
    final ok = await _service.updateDownDown(
      kennelId: widget.kennelId,
      eventId: widget.eventId,
      downDownId: widget.downDown.downDownId,
      chargeText: chargeText,
      songChoice: songText.isEmpty ? null : songText,
      songId: _linkedSongId,
    );

    if (mounted) {
      if (ok) {
        Get.back(result: true);
      } else {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to update. Please try again.'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: themeAppBarBackground,
        iconTheme: const IconThemeData(color: Colors.white, size: 28.0),
        title: Text(widget.pageTitle, style: ts_appBarTitle),
        actions: [
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.check, color: Colors.white),
                  tooltip: 'Save',
                  onPressed: _save,
                ),
        ],
      ),
      body: Container(
        decoration: Backgrounds.defaultHcBackground(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: TextField(
                controller: _chargeController,
                maxLines: 3,
                autofocus: true,
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  labelText: 'Charge',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: TextField(
                controller: _songController,
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  labelText: 'Recommended song (optional)',
                  hintText: 'Start typing to search…',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.music_note),
                  suffixIcon: _linkedSongId != null
                      ? Tooltip(
                          message: 'Unlink song',
                          child: IconButton(
                            icon: const Icon(Icons.link_off, size: 18),
                            onPressed: () => setState(() {
                              _linkedSongId = null;
                              _songResults = [];
                            }),
                          ),
                        )
                      : null,
                ),
                onChanged: (value) {
                  if (_suppressNextSearch) {
                    _suppressNextSearch = false;
                    return;
                  }
                  _linkedSongId = null;
                  unawaited(_searchSongs(value));
                },
              ),
            ),
            if (_linkedSongId != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 16, 10),
                child: Row(
                  children: [
                    const Icon(Icons.link, size: 14, color: Colors.yellow),
                    const SizedBox(width: 6),
                    Text(
                      'Song linked',
                      style: const TextStyle(fontSize: 12, color: Colors.yellow),
                    ),
                  ],
                ),
              ),
            if (_songResults.isNotEmpty) ...[
              const Divider(height: 1, thickness: 1, color: Colors.white24),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
                child: Text(
                  'Select a song to link it',
                  style: const TextStyle(fontSize: 11, color: Colors.white54),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _songResults.length,
                  itemBuilder: (context, index) {
                    final song = _songResults[index];
                    return ListTile(
                      leading: const Icon(Icons.music_note, color: Colors.white70, size: 20),
                      title: Text(
                        song.songName,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      onTap: () {
                        _suppressNextSearch = true;
                        _songController.text = song.songName;
                        setState(() {
                          _linkedSongId = song.songId;
                          _songResults = [];
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
