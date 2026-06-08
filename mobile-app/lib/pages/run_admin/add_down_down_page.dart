import 'package:harrier_central/imports.dart';

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
    super.dispose();
  }

  Future<void> _loadAttendees() async {
    setState(() => _isLoading = true);
    try {
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
          AND hem.${tableModel.hasherEventMapTableHelper.colAttendenceState} >= 20
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
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _submit,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text('Submit', style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ],
      ),
      body: Container(
        decoration: Backgrounds.defaultHcBackgroundLight(),
        child: _isLoading
            ? const HcAppCircularProgressIndicator(key: Key('add_dd_loading'))
            : Column(
                children: [
                  // Charge text input
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: TextField(
                      controller: _chargeController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Charge',
                        hintText: 'What did they do?',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        Text(
                          'Select hashers ($selectedCount selected)',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: _attendees.isEmpty
                        ? Center(
                            child: Text(
                              'No attendees found yet.\nCheck-in data may still be loading.',
                              textAlign: TextAlign.center,
                              style: ts_headingLarge.copyWith(color: themeBackgroundColor),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _attendees.length,
                            itemBuilder: (context, index) {
                              final attendee = _attendees[index];
                              return CheckboxListTile(
                                value: attendee.selected,
                                title: Text(attendee.displayName),
                                onChanged: (v) => setState(() => attendee.selected = v ?? false),
                                activeColor: themeBackgroundColor,
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
