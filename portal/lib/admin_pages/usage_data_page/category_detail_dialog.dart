import 'package:hcportal/imports.dart';

/// Persists column widths per category across dialog opens (in-memory,
/// survives for the lifetime of the app session).
final Map<String, List<double>> _savedColumnWidths = {};

class CategoryDetailDialog extends StatefulWidget {
  const CategoryDetailDialog({
    required this.title,
    required this.headers,
    required this.rows,
    super.key,
  });

  final String title;
  final List<String> headers;
  final List<List<String>> rows;

  @override
  State<CategoryDetailDialog> createState() => _CategoryDetailDialogState();
}

class _CategoryDetailDialogState extends State<CategoryDetailDialog> {
  late List<double> _widths;
  late String _cacheKey;
  final _dataScrollCtrl = ScrollController();
  double _headerOffset = 0;

  // Sorting state
  late List<List<String>> _sortedRows;
  int? _sortColumn;
  bool _sortAscending = true;

  double get _totalWidth =>
      _widths.fold<double>(0, (a, b) => a + b) + _widths.length * 16 + 24;

  @override
  void initState() {
    super.initState();
    _cacheKey = widget.headers.join('|');
    _sortedRows = List<List<String>>.from(widget.rows);
    final saved = _savedColumnWidths[_cacheKey];
    if (saved != null && saved.length == widget.headers.length) {
      _widths = List<double>.from(saved);
    } else {
      final w = 744.0 / widget.headers.length;
      _widths =
          List<double>.filled(widget.headers.length, w < 150.0 ? 150.0 : w);
    }
    _dataScrollCtrl.addListener(_onDataScroll);
  }

  void _onDataScroll() {
    setState(() => _headerOffset = _dataScrollCtrl.offset);
  }

  void _onSort(int columnIndex) {
    setState(() {
      if (_sortColumn == columnIndex) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = columnIndex;
        _sortAscending = true;
      }
      _sortedRows.sort((a, b) {
        final aVal = a[columnIndex];
        final bVal = b[columnIndex];
        // Try numeric comparison first.
        final aNum = double.tryParse(aVal.replaceAll(',', ''));
        final bNum = double.tryParse(bVal.replaceAll(',', ''));
        int cmp;
        if (aNum != null && bNum != null) {
          cmp = aNum.compareTo(bNum);
        } else {
          cmp = aVal.toLowerCase().compareTo(bVal.toLowerCase());
        }
        return _sortAscending ? cmp : -cmp;
      });
    });
  }

  void _resize(int index, double delta) {
    const minWidth = 40.0;
    final newWidth = _widths[index] + delta;
    if (newWidth >= minWidth) {
      setState(() {
        _widths[index] = newWidth;
      });
    }
  }

  void _saveWidths() {
    _savedColumnWidths[_cacheKey] = List<double>.from(_widths);
  }

  @override
  void dispose() {
    _dataScrollCtrl.removeListener(_onDataScroll);
    _dataScrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tw = _totalWidth;

    return Dialog(
      child: Container(
        width: 800,
        height: 600,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.rows.length} rows',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),

            // ── Header row ──
            // No ScrollView here — just a clipped Stack with manual
            // offset so that GestureDetector on resize handles has zero
            // gesture competition.
            SizedBox(
              height: 40,
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned(
                    left: -_headerOffset,
                    top: 0,
                    bottom: 0,
                    width: tw,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      color: Colors.grey.shade200,
                      child: Row(
                        children: <Widget>[
                          for (var i = 0; i < widget.headers.length; i++) ...[
                            SizedBox(
                              width: _widths[i],
                              child: InkWell(
                                onTap: () => _onSort(i),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        widget.headers[i],
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (_sortColumn == i)
                                      Icon(
                                        _sortAscending
                                            ? Icons.arrow_upward
                                            : Icons.arrow_downward,
                                        size: 14,
                                        color: Colors.grey.shade700,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            MouseRegion(
                              cursor: SystemMouseCursors.resizeColumn,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onHorizontalDragUpdate: (d) =>
                                    _resize(i, d.delta.dx),
                                onHorizontalDragEnd: (_) => _saveWidths(),
                                child: const SizedBox(
                                  width: 16,
                                  height: 24,
                                  child: Center(
                                    child: VerticalDivider(
                                      width: 1,
                                      thickness: 1,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // ── Data rows ──
            Expanded(
              child: SingleChildScrollView(
                controller: _dataScrollCtrl,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: tw,
                  child: widget.rows.isEmpty
                      ? const Center(child: Text('No data found'))
                      : ListView.separated(
                          itemCount: _sortedRows.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final row = _sortedRows[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 6,
                                horizontal: 12,
                              ),
                              child: Row(
                                children: <Widget>[
                                  for (var i = 0; i < row.length; i++) ...[
                                    SizedBox(
                                      width: _widths[i],
                                      child: Text(
                                        row[i],
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ),
            ),

            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
