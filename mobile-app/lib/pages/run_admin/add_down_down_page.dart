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
  });

  final String kennelId;
  final String eventId;
  final String eventName;

  @override
  State<AddDownDownPage> createState() => _AddDownDownPageState();
}

class _AddDownDownPageState extends State<AddDownDownPage> {
  final _service = RunContentService();
  final _chargeController = TextEditingController();
  final _songController = TextEditingController();

  String? _linkedSongId;
  bool _suppressNextSongSearch = false;
  List<_SongResult> _songResults = [];

  bool _isLoading = true;
  bool _isSaving = false;
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
    super.dispose();
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

  Future<void> _submit() async {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one hasher')),
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
        songChoice: _songController.text.trim().isEmpty ? null : _songController.text.trim(),
        songId: _linkedSongId,
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
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        Text(
                          'Select hashers ($selectedCount selected)',
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
