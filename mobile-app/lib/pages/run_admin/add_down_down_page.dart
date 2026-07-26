import 'package:harrier_central/imports.dart';

class _SongResult {
  _SongResult({required this.songId, required this.songName});
  final String songId;
  final String songName;
}

/// Simple model for an attendee shown in the hasher picker.
class _AttendeeItem {
  _AttendeeItem({required this.hasherId, required this.displayName});
  final String hasherId;
  final String displayName;
  bool selected = false;
}

class AddDownDownPage extends StatefulWidget {
  const AddDownDownPage({
    super.key,
    required this.kennelId,
    required this.eventId,
    required this.eventName,
    this.kennelSlug = '',
    this.eventNumber = 0,
  });

  final String kennelId;
  final String eventId;
  final String eventName;
  final String kennelSlug;
  final int eventNumber;

  @override
  State<AddDownDownPage> createState() => _AddDownDownPageState();
}

class _AddDownDownPageState extends State<AddDownDownPage> {
  final _service = RunContentService();
  final _chargeController = TextEditingController();
  final _songController = TextEditingController();
  final _externalNameController = TextEditingController();

  /// Names of people being charged who are NOT registered HC users.
  final List<String> _externalNames = [];

  String? _linkedSongId;
  bool _suppressNextSongSearch = false;
  List<_SongResult> _songResults = [];

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isCapturingPhoto = false;
  String? _chargePhotoUrl;
  List<_AttendeeItem> _attendees = [];

  @override
  void initState() {
    super.initState();
    unawaited(_loadAttendees());
  }

  @override
  void dispose() {
    _chargeController.dispose();
    _songController.dispose();
    _externalNameController.dispose();
    super.dispose();
  }

  /// Adds the typed (or supplied) name to the external-people list, ignoring
  /// blanks and case-insensitive duplicates, then clears the input.
  void _addExternalName([String? value]) {
    final name = (value ?? _externalNameController.text).trim();
    _externalNameController.clear();
    if (name.isEmpty) return;
    final exists = _externalNames.any((n) => n.toLowerCase() == name.toLowerCase());
    if (!exists) {
      setState(() => _externalNames.add(name));
    } else {
      setState(() {}); // reflect the cleared input
    }
  }

  Future<void> _searchSongs(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _songResults = []);
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
      LIMIT 10
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
      LIMIT 10
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

  Future<void> _loadAttendees() async {
    setState(() => _isLoading = true);
    try {
      // Sync the event HEM table first so attendees are available locally.
      // Without this the event_ tables are empty unless run admin was opened first.
      if (Utilities.isConnected()) {
        await tableModel.syncEventAdminService.updateRsvpsFromBackend(widget.eventId);
      }

      final query = '''
        SELECT
          h.${tableModel.hashersTableHelper.colHasherId} as hasherId,
          coalesce(
            hem.${tableModel.hasherEventMapTableHelper.colDisplayName},
            h.${tableModel.hashersTableHelper.colDispName},
            h.${tableModel.hashersTableHelper.colHashName},
            h.${tableModel.hashersTableHelper.colFirstName} || " " || h.${tableModel.hashersTableHelper.colLastName},
            "<no name>"
          ) as displayName
        FROM ${EnumDataTables.hasherEventMap.eventTableName} hem
        INNER JOIN ${EnumDataTables.hashers.commonTableName} h
          ON hem.${tableModel.hasherEventMapTableHelper.colUserId} = h.${tableModel.hashersTableHelper.colHasherId}
        WHERE hem.${tableModel.hasherEventMapTableHelper.colEventId} = '${widget.eventId}'
          AND (
            hem.${tableModel.hasherEventMapTableHelper.colAttendenceState} >= 20
            OR hem.${tableModel.hasherEventMapTableHelper.colRsvpState} = 3
          )
          AND h.${tableModel.hashersTableHelper.colRemoved} = 0
        ORDER BY displayName COLLATE NOCASE
      ''';

      final results = await database.rawQuery(query);
      setState(() {
        _attendees = results
            .map((r) => _AttendeeItem(
                  hasherId: r['hasherId'] as String,
                  displayName: r['displayName'] as String? ?? '<no name>',
                ))
            .toList();
      });
    } catch (e, s) {
      BootLogger.logError('[AddDownDownPage._loadAttendees]', e, s);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  List<_AttendeeItem> get _selected => _attendees.where((a) => a.selected).toList();

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

  Future<void> _submit() async {
    // Fold in any name typed but not yet added via the + button.
    if (_externalNameController.text.trim().isNotEmpty) {
      _addExternalName();
    }

    if (_selected.isEmpty && _externalNames.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one person — a hasher or a name')),
      );
      return;
    }
    if (_chargeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the charge')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final id = await _service.addDownDown(
        kennelId: widget.kennelId,
        eventId: widget.eventId,
        hasherIds: _selected.map((a) => a.hasherId).toList(),
        chargeText: _chargeController.text.trim(),
        externalNames: _externalNames,
        songChoice: _songController.text.trim().isEmpty ? null : _songController.text.trim(),
        songId: _linkedSongId,
        chargePhotoUrl: _chargePhotoUrl,
      );
      if (mounted) {
        if (id != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Down Down recorded!'), backgroundColor: Colors.green),
          );
          Get.back();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to save. Are you a run attendee?'),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Error saving. Please try again.'), backgroundColor: Colors.red.shade700),
        );
      }
    }
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _selected.length;

    return AppScaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: themeAppBarBackground,
        iconTheme: const IconThemeData(color: Colors.white, size: 28.0),
        title: Text('Add Down Down', style: ts_appBarTitle),
      ),
      body: Container(
        decoration: Backgrounds.defaultHcBackground(),
        child: _isLoading
            ? const HcAppCircularProgressIndicator(key: Key('add_dd_loading'))
            : Column(
                children: [
                  // Charge text input with inline send button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        TextField(
                          controller: _chargeController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Charge',
                            hintText: 'What did they do?',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.fromLTRB(12, 12, 52, 12),
                          ),
                        ),
                        Positioned(
                          right: 6,
                          bottom: 6,
                          child: Material(
                            color: themeBackgroundColor,
                            borderRadius: BorderRadius.circular(20),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: _isSaving ? null : _submit,
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: _isSaving
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : const Icon(Icons.send, color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: TextField(
                      controller: _songController,
                      decoration: InputDecoration(
                        labelText: 'Recommended song (optional)',
                        hintText: 'e.g. Down Down',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.music_note),
                        suffixIcon: _linkedSongId != null
                            ? Tooltip(
                                message: 'Unlink song',
                                child: IconButton(
                                  icon: const Icon(Icons.link_off, size: 18),
                                  onPressed: () => setState(() => _linkedSongId = null),
                                ),
                              )
                            : null,
                      ),
                      onChanged: (value) {
                        if (_suppressNextSongSearch) {
                          _suppressNextSongSearch = false;
                          return;
                        }
                        _linkedSongId = null;
                        unawaited(_searchSongs(value));
                      },
                    ),
                  ),
                  if (_songResults.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _songResults.length,
                          itemBuilder: (context, index) {
                            final song = _songResults[index];
                            return ListTile(
                              dense: true,
                              leading: const Icon(Icons.music_note, size: 16, color: Colors.black54),
                              title: Text(song.songName, style: const TextStyle(fontSize: 14)),
                              onTap: () {
                                _suppressNextSongSearch = true;
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
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
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
                                    _chargePhotoUrl != null ? Icons.check_circle_outline : Icons.camera_alt,
                                    color: Colors.white70,
                                  ),
                            label: Text(
                              _chargePhotoUrl != null ? 'Photo added' : 'Add photo (optional)',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white30)),
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
                          IconButton(
                            icon: const Icon(Icons.close, size: 18, color: Colors.white54),
                            onPressed: () => setState(() => _chargePhotoUrl = null),
                            tooltip: 'Remove photo',
                          ),
                        ],
                      ],
                    ),
                  ),
                  // People not in the app — free-text names added as chips.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'People not in the app',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _externalNameController,
                          textInputAction: TextInputAction.done,
                          textCapitalization: TextCapitalization.words,
                          onSubmitted: _addExternalName,
                          decoration: InputDecoration(
                            hintText: 'Add a name, then tap +',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            filled: true,
                            fillColor: Colors.white,
                            isDense: true,
                            prefixIcon: const Icon(Icons.person_add_alt_1),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.add),
                              tooltip: 'Add name',
                              onPressed: () => _addExternalName(),
                            ),
                          ),
                        ),
                        if (_externalNames.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: _externalNames
                                .map((name) => Chip(
                                      label: Text(name),
                                      backgroundColor: Colors.yellow.shade700,
                                      labelStyle: const TextStyle(
                                        color: Colors.black87,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      deleteIconColor: Colors.black54,
                                      onDeleted: () => setState(() => _externalNames.remove(name)),
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
                                    ))
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        Text(
                          'People in the app ($selectedCount selected)',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Colors.white24),
                  Expanded(
                    child: _attendees.isEmpty
                        ? Center(
                            child: Text(
                              'No attendees found yet.\nCheck-in data may still be loading.',
                              textAlign: TextAlign.center,
                              style: ts_headingLarge.copyWith(color: Colors.white70),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _attendees.length,
                            itemBuilder: (context, index) {
                              final attendee = _attendees[index];
                              return CheckboxListTile(
                                value: attendee.selected,
                                title: Text(
                                  attendee.displayName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.yellow,
                                  ),
                                ),
                                onChanged: (v) => setState(() => attendee.selected = v ?? false),
                                activeColor: Colors.yellow,
                                checkColor: Colors.black87,
                                side: const BorderSide(color: Colors.yellow, width: 1.5),
                                controlAffinity: ListTileControlAffinity.leading,
                                dense: true,
                                visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}
