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
    required this.kennelSlug,
    required this.eventNumber,
    required this.downDown,
    this.pageTitle = 'Edit Charge',
  });

  final String kennelId;
  final String eventId;
  final String kennelSlug;
  final int eventNumber;
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
  String? _chargePhotoUrl;
  bool _isCapturingPhoto = false;

  @override
  void initState() {
    super.initState();
    _chargeController = TextEditingController(text: widget.downDown.chargeText);
    _songController = TextEditingController(text: widget.downDown.songChoice ?? '');
    _linkedSongId = widget.downDown.songId;
    _chargePhotoUrl = widget.downDown.chargePhotoUrl;
  }

  @override
  void dispose() {
    _chargeController.dispose();
    _songController.dispose();
    super.dispose();
  }

  Future<void> _takeChargePhoto() async {
    setState(() => _isCapturingPhoto = true);
    try {
      final url = await KennelPhotoService().captureAndUpload(
        eventId: widget.eventId,
        kennelId: widget.kennelId,
        kennelSlug: widget.kennelSlug,
        eventNumber: widget.eventNumber,
        skipMapMarker: true,
      );
      if (url != null && mounted) {
        setState(() => _chargePhotoUrl = url);
      }
    } finally {
      if (mounted) setState(() => _isCapturingPhoto = false);
    }
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
    final newPhoto = _chargePhotoUrl != widget.downDown.chargePhotoUrl
        ? _chargePhotoUrl
        : null;

    final ok = await _service.updateDownDown(
      kennelId: widget.kennelId,
      eventId: widget.eventId,
      downDownId: widget.downDown.downDownId,
      chargeText: chargeText,
      songChoice: songText.isEmpty ? null : songText,
      songId: _linkedSongId,
      chargePhotoUrl: newPhoto,
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

  Widget _fieldLabel(String text) => Padding(
        padding: const EdgeInsets.only(left: 2, bottom: 5),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      );

  static const _fieldDecoration = InputDecoration(
    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
    filled: true,
    fillColor: Colors.white,
  );

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
            // Charge text field
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel('Charge'),
                  TextField(
                    controller: _chargeController,
                    maxLines: 3,
                    autofocus: true,
                    style: const TextStyle(color: Colors.black87),
                    decoration: _fieldDecoration.copyWith(
                      hintText: 'Enter the charge…',
                    ),
                  ),
                ],
              ),
            ),

            // Song field
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel('Recommended song (optional)'),
                  TextField(
                    controller: _songController,
                    style: const TextStyle(color: Colors.black87),
                    decoration: _fieldDecoration.copyWith(
                      hintText: 'Start typing to search…',
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
                ],
              ),
            ),

            if (_linkedSongId != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 16, 10),
                child: Row(
                  children: [
                    const Icon(Icons.link, size: 14, color: Colors.yellow),
                    const SizedBox(width: 6),
                    const Text(
                      'Song linked',
                      style: TextStyle(fontSize: 12, color: Colors.yellow),
                    ),
                  ],
                ),
              ),

            // Photo row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: _isCapturingPhoto
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Icon(
                              _chargePhotoUrl != null
                                  ? Icons.check_circle_outline
                                  : Icons.camera_alt,
                              color: Colors.white70,
                            ),
                      label: Text(
                        _chargePhotoUrl != null ? 'Photo added' : 'Add photo (optional)',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white30),
                      ),
                      onPressed: _isCapturingPhoto ? null : _takeChargePhoto,
                    ),
                  ),
                  if (_chargePhotoUrl != null) ...[
                    const SizedBox(width: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        _chargePhotoUrl!,
                        width: 44,
                        height: 44,
                        cacheWidth: 132,
                        cacheHeight: 132,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            if (_songResults.isNotEmpty) ...[
              const Divider(height: 1, thickness: 1, color: Colors.white24),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
                child: const Text(
                  'Select a song to link it',
                  style: TextStyle(fontSize: 11, color: Colors.white54),
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
