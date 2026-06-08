import 'package:harrier_central/imports.dart';
import 'package:harrier_central/pages/run_admin/add_down_down_page.dart';

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

  Future<void> _showEditDialog(DownDownModel dd) async {
    final textController = TextEditingController(text: dd.chargeText);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Charge', style: ts_alertDialogTitle),
        content: TextField(
          controller: textController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'What did they do?',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: Colors.white,
          ),
          autofocus: true,
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
      ),
    );

    final editedText = textController.text.trim();
    textController.dispose();

    if (confirmed != true || editedText.isEmpty) return;

    final ok = await _service.updateDownDown(
      kennelId: widget.kennelId,
      eventId: widget.eventId,
      downDownId: dd.downDownId,
      chargeText: editedText,
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
    return AppScaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: themeAppBarBackground,
        iconTheme: const IconThemeData(color: Colors.white, size: 28.0),
        title: Text('Charges', style: ts_appBarTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _load,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: themeBackgroundColor,
        foregroundColor: Colors.white,
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
      body: Container(
        decoration: Backgrounds.defaultHcBackgroundLight(),
        child: _isLoading
            ? const HcAppCircularProgressIndicator(key: Key('charges_loading'))
            : _charges.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(30),
                      child: Text(
                        'No charges yet for this run.\nTap + to add one.',
                        textAlign: TextAlign.center,
                        style: ts_headingLarge.copyWith(color: themeBackgroundColor),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _charges.length,
                    separatorBuilder: (context, i) => const Divider(height: 1, color: Colors.black26),
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
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 22),
            color: Colors.grey.shade600,
            onPressed: onEdit,
            tooltip: 'Edit charge',
          ),
        ],
      ),
    );
  }
}
