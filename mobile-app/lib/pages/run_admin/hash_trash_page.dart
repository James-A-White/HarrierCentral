import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:harrier_central/imports.dart';

class HashTrashPage extends StatefulWidget {
  const HashTrashPage({
    super.key,
    required this.kennelId,
    required this.eventId,
    required this.eventName,
  });

  final String kennelId;
  final String eventId;
  final String eventName;

  @override
  State<HashTrashPage> createState() => _HashTrashPageState();
}

class _HashTrashPageState extends State<HashTrashPage>
    with SingleTickerProviderStateMixin {
  final _service = RunContentService();
  final _headlineController = TextEditingController();
  final _contentController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  int _status = 0; // 0=draft, 1=published

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    unawaited(_load());
  }

  @override
  void dispose() {
    _headlineController.dispose();
    _contentController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final model = await _service.getHashTrash(
        kennelId: widget.kennelId,
        eventId: widget.eventId,
      );
      if (model != null) {
        _headlineController.text = model.headline;
        _contentController.text = model.content ?? '';
        _status = model.status ?? 0;
      }
    } catch (e) {
      if (mounted) _showError('Failed to load HashTrash');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _save() async {
    if (_headlineController.text.trim().isEmpty) {
      _showError('Headline is required');
      return;
    }
    setState(() => _isSaving = true);
    try {
      final ok = await _service.saveHashTrash(
        kennelId: widget.kennelId,
        eventId: widget.eventId,
        headline: _headlineController.text.trim(),
        content: _contentController.text.trim(),
        status: _status,
      );
      if (mounted) {
        if (ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_status == 1 ? 'Published!' : 'Saved as draft'),
              backgroundColor: _status == 1 ? Colors.green.shade700 : Colors.blueGrey,
            ),
          );
        } else {
          _showError('Save failed. Please try again.');
        }
      }
    } catch (e) {
      if (mounted) _showError('Save failed. Please try again.');
    }
    if (mounted) setState(() => _isSaving = false);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: themeAppBarBackground,
        iconTheme: const IconThemeData(color: Colors.white, size: 28.0),
        title: Text('Hash Trash', style: ts_appBarTitle),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.save, color: Colors.white),
              onPressed: _isSaving ? null : _save,
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Edit'),
            Tab(text: 'Preview'),
          ],
        ),
      ),
      body: Container(
        decoration: Backgrounds.defaultHcBackground(),
        child: _isLoading
            ? const HcAppCircularProgressIndicator(key: Key('ht_loading'))
            : Column(
                children: [
                  // Status toggle
                  Container(
                    color: Colors.black26,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Text(
                          'Status: ',
                          style: ts_bodySmall.copyWith(color: Colors.white70),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Draft'),
                          selected: _status == 0,
                          onSelected: (_) => setState(() => _status = 0),
                          selectedColor: Colors.blueGrey,
                          labelStyle: TextStyle(
                            color: _status == 0 ? Colors.white : Colors.white54,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Published'),
                          selected: _status == 1,
                          onSelected: (_) => setState(() => _status = 1),
                          selectedColor: Colors.green.shade700,
                          labelStyle: TextStyle(
                            color: _status == 1 ? Colors.white : Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildEditor(),
                        _buildPreview(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildEditor() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Headline', style: ts_bodySmall.copyWith(color: Colors.white70)),
          const SizedBox(height: 4),
          TextField(
            controller: _headlineController,
            maxLength: 500,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Run headline...',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: Colors.black26,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.white24),
              ),
              counterStyle: const TextStyle(color: Colors.white54),
            ),
          ),
          const SizedBox(height: 12),
          Text('Article (markdown)', style: ts_bodySmall.copyWith(color: Colors.white70)),
          const SizedBox(height: 4),
          TextField(
            controller: _contentController,
            minLines: 12,
            maxLines: null,
            style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Write the Hash Trash here...\n\nMarkdown is supported:\n**bold**, *italic*, # Heading, [link](url)',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
              filled: true,
              fillColor: Colors.black26,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.white24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    final headline = _headlineController.text.trim();
    final content = _contentController.text.trim();
    if (headline.isEmpty && content.isEmpty) {
      return Center(
        child: Text(
          'Nothing to preview yet',
          style: ts_headingLarge.copyWith(color: Colors.white54),
        ),
      );
    }
    return Container(
      color: Colors.white,
      child: Markdown(
        data: headline.isNotEmpty
            ? '# $headline\n\n$content'
            : content,
        padding: const EdgeInsets.all(16),
      ),
    );
  }
}
