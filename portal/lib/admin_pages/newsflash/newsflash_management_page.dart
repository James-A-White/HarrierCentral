import 'package:hcportal/imports.dart';
import 'package:intl/intl.dart';

// ---------------------------------------------------------------------------
// Newsflash Management Page
// ---------------------------------------------------------------------------

class NewsflashManagementPage extends StatelessWidget {
  const NewsflashManagementPage({super.key, this.allKennels = const []});

  final List<HasherKennelsModel> allKennels;

  void _ensureController() {
    if (!Get.isRegistered<NewsflashManagementController>()) {
      Get.put(NewsflashManagementController());
    }
  }

  @override
  Widget build(BuildContext context) {
    _ensureController();
    final controller = Get.find<NewsflashManagementController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Newsflash'),
        leading: GestureDetector(
          onTap: () => Get.back<void>(),
          child: const Icon(MaterialCommunityIcons.arrow_left,
              color: Colors.black),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Newsflash'),
              onPressed: () => _showForm(context, controller, null),
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.newsflashes.isEmpty) {
          return const Center(
            child: Text(
              'No newsflashes yet. Tap Add Newsflash to create one.',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: controller.newsflashes.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final nf = controller.newsflashes[index];
            return _NewsflashTile(
              newsflash: nf,
              onEdit: () => _showForm(context, controller, nf),
              onDelete: () => _confirmDelete(context, controller, nf),
              onReaders: () => _showReaders(context, controller, nf),
            );
          },
        );
      }),
    );
  }

  // ---------------------------------------------------------------------------
  // Add / edit form
  // ---------------------------------------------------------------------------

  void _showForm(BuildContext context, NewsflashManagementController controller,
      NewsflashAdminModel? existing) {
    final kennels = allKennels;

    final titleCtrl =
        TextEditingController(text: existing?.title ?? '');
    final bodyCtrl =
        TextEditingController(text: existing?.bodyText ?? '');
    final imageUrlState = ValueNotifier<String?>(existing?.imageUrl);
    final startDateState =
        ValueNotifier<DateTime>(existing?.startDate ?? DateTime.now());
    final endDateState = ValueNotifier<DateTime?>(existing?.endDate);
    final kennelIdState = ValueNotifier<String?>(existing?.kennelId);
    final isUploading = ValueNotifier<bool>(false);
    final formKey = GlobalKey<FormState>();

    unawaited(Get.dialog<void>(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: _NewsflashForm(
            formKey: formKey,
            titleCtrl: titleCtrl,
            bodyCtrl: bodyCtrl,
            imageUrlState: imageUrlState,
            startDateState: startDateState,
            endDateState: endDateState,
            kennelIdState: kennelIdState,
            isUploading: isUploading,
            kennels: kennels,
            isEditing: existing != null,
            onSave: () async {
              if (!formKey.currentState!.validate()) return;
              Get.back<void>();
              await controller.saveNewsflash(
                newsflashId: existing?.newsflashId,
                title: titleCtrl.text.trim(),
                bodyText: bodyCtrl.text.trim(),
                imageUrl: imageUrlState.value,
                startDate: startDateState.value,
                endDate: endDateState.value,
                kennelId: kennelIdState.value,
              );
            },
          ),
        ),
      ),
    ));
  }

  // ---------------------------------------------------------------------------
  // Delete confirmation
  // ---------------------------------------------------------------------------

  Future<void> _confirmDelete(BuildContext context,
      NewsflashManagementController controller, NewsflashAdminModel nf) async {
    final confirmed = await Get.defaultDialog<bool>(
      title: 'Delete Newsflash',
      content: Text('Delete "${nf.title}"? This cannot be undone.'),
      actions: [
        TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel')),
        TextButton(
            onPressed: () => Get.back(result: true),
            child:
                const Text('Delete', style: TextStyle(color: Color(0xFFDC2626)))),
      ],
    );
    if (confirmed == true) {
      await controller.softDelete(nf.newsflashId);
    }
  }

  // ---------------------------------------------------------------------------
  // Readers list
  // ---------------------------------------------------------------------------

  void _showReaders(BuildContext context,
      NewsflashManagementController controller, NewsflashAdminModel nf) {
    unawaited(Get.dialog<void>(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 600),
          child: _ReadersDialog(
            newsflash: nf,
            loadReaders: controller.loadReaders,
          ),
        ),
      ),
    ));
  }
}

// ---------------------------------------------------------------------------
// Newsflash list tile
// ---------------------------------------------------------------------------

class _NewsflashTile extends StatelessWidget {
  const _NewsflashTile({
    required this.newsflash,
    required this.onEdit,
    required this.onDelete,
    required this.onReaders,
  });

  final NewsflashAdminModel newsflash;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onReaders;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy');
    final dateRange = newsflash.endDate != null
        ? '${fmt.format(newsflash.startDate)} – ${fmt.format(newsflash.endDate!)}'
        : 'From ${fmt.format(newsflash.startDate)}';
    final scope =
        newsflash.kennelName != null ? newsflash.kennelName! : 'All Kennels';

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          newsflash.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                      ),
                      if (newsflash.isDeleted)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Deleted',
                              style: TextStyle(
                                  fontSize: 11, color: Color(0xFFDC2626))),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$dateRange  ·  $scope  ·  ${newsflash.dismissedCount} read',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(MaterialCommunityIcons.account_group,
                      size: 20, color: Color(0xFF6B7280)),
                  tooltip: 'View readers',
                  onPressed: onReaders,
                ),
                if (!newsflash.isDeleted) ...[
                  IconButton(
                    icon: const Icon(MaterialCommunityIcons.pencil,
                        size: 20, color: Color(0xFF6B7280)),
                    tooltip: 'Edit',
                    onPressed: onEdit,
                  ),
                  IconButton(
                    icon: const Icon(MaterialCommunityIcons.delete_outline,
                        size: 20, color: Color(0xFFDC2626)),
                    tooltip: 'Delete',
                    onPressed: onDelete,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Add / edit form widget
// ---------------------------------------------------------------------------

class _NewsflashForm extends StatelessWidget {
  const _NewsflashForm({
    required this.formKey,
    required this.titleCtrl,
    required this.bodyCtrl,
    required this.imageUrlState,
    required this.startDateState,
    required this.endDateState,
    required this.kennelIdState,
    required this.isUploading,
    required this.kennels,
    required this.isEditing,
    required this.onSave,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController titleCtrl;
  final TextEditingController bodyCtrl;
  final ValueNotifier<String?> imageUrlState;
  final ValueNotifier<DateTime> startDateState;
  final ValueNotifier<DateTime?> endDateState;
  final ValueNotifier<String?> kennelIdState;
  final ValueNotifier<bool> isUploading;
  final List<HasherKennelsModel> kennels;
  final bool isEditing;
  final VoidCallback onSave;

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;

    final ext = (file.extension ?? 'jpg').toLowerCase();
    isUploading.value = true;

    final fileName = await ServiceCommon.uploadFile(
      file.bytes!,
      'newsflash',
      DocumentType.newsflashImage.name,
      UiControlType.imageUpload,
      filenameExtension: ext,
      filenamePrefix: 'nf_',
    );

    isUploading.value = false;

    if (fileName.isNotEmpty) {
      imageUrlState.value = '$BASE_NEWSFLASH_IMAGE_URL$fileName';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Text(
            isEditing ? 'Edit Newsflash' : 'Add Newsflash',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 16),

        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title
                  TextFormField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Title *',
                      border: OutlineInputBorder(),
                    ),
                    maxLength: 250,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                  ),
                  const SizedBox(height: 12),

                  // Body
                  TextFormField(
                    controller: bodyCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Message *',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 5,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Message is required' : null,
                  ),
                  const SizedBox(height: 12),

                  // Image
                  ValueListenableBuilder<bool>(
                    valueListenable: isUploading,
                    builder: (_, uploading, __) {
                      return ValueListenableBuilder<String?>(
                        valueListenable: imageUrlState,
                        builder: (_, imageUrl, __) {
                          return _ImagePicker(
                            imageUrl: imageUrl,
                            isUploading: uploading,
                            onPick: _pickImage,
                            onClear: () => imageUrlState.value = null,
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Dates
                  Row(
                    children: [
                      Expanded(
                        child: ValueListenableBuilder<DateTime>(
                          valueListenable: startDateState,
                          builder: (_, startDate, __) {
                            return _DateField(
                              label: 'Start date *',
                              date: startDate,
                              onChanged: (d) => startDateState.value = d,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ValueListenableBuilder<DateTime?>(
                          valueListenable: endDateState,
                          builder: (_, endDate, __) {
                            return _DateField(
                              label: 'End date (optional)',
                              date: endDate,
                              onChanged: (d) => endDateState.value = d,
                              onClear: () => endDateState.value = null,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Kennel selector
                  ValueListenableBuilder<String?>(
                    valueListenable: kennelIdState,
                    builder: (_, kennelId, __) {
                      return DropdownButtonFormField<String?>(
                        initialValue: kennelId,
                        decoration: const InputDecoration(
                          labelText: 'Target audience',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('All Kennels (Platform-wide)'),
                          ),
                          ...kennels.map((k) => DropdownMenuItem<String?>(
                                value: k.publicKennelId,
                                child: Text(k.kennelName),
                              )),
                        ],
                        onChanged: (v) => kennelIdState.value = v,
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),

        // Actions
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Get.back<void>(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: onSave,
                child: Text(isEditing ? 'Save changes' : 'Create'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Image picker widget (used inside the form)
// ---------------------------------------------------------------------------

class _ImagePicker extends StatelessWidget {
  const _ImagePicker({
    required this.imageUrl,
    required this.isUploading,
    required this.onPick,
    required this.onClear,
  });

  final String? imageUrl;
  final bool isUploading;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    if (isUploading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HcNetworkImage(
            imageUrl!,
            height: 250,
            width: double.infinity,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              TextButton.icon(
                icon: const Icon(Icons.upload, size: 16),
                label: const Text('Change image'),
                onPressed: onPick,
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Remove'),
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                onPressed: onClear,
              ),
            ],
          ),
        ],
      );
    }

    return OutlinedButton.icon(
      icon: const Icon(Icons.upload),
      label: const Text('Upload image (optional)'),
      onPressed: onPick,
    );
  }
}

// ---------------------------------------------------------------------------
// Date field widget
// ---------------------------------------------------------------------------

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.date,
    required this.onChanged,
    this.onClear,
  });

  final String label;
  final DateTime? date;
  final ValueChanged<DateTime> onChanged;
  final VoidCallback? onClear;

  Future<void> _pick() async {
    final picked = await showDatePicker(
      context: Get.overlayContext!,
      initialDate: date ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy');
    return InkWell(
      onTap: _pick,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: onClear != null && date != null
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 16),
                  onPressed: onClear,
                )
              : const Icon(Icons.calendar_today, size: 16),
        ),
        child: Text(
          date != null ? fmt.format(date!) : 'Select…',
          style: TextStyle(
            color: date != null ? null : const Color(0xFF9CA3AF),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Readers dialog
// ---------------------------------------------------------------------------

class _ReadersDialog extends StatefulWidget {
  const _ReadersDialog({
    required this.newsflash,
    required this.loadReaders,
  });

  final NewsflashAdminModel newsflash;
  final Future<List<NewsflashReaderModel>> Function(String) loadReaders;

  @override
  State<_ReadersDialog> createState() => _ReadersDialogState();
}

class _ReadersDialogState extends State<_ReadersDialog> {
  late Future<List<NewsflashReaderModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.loadReaders(widget.newsflash.newsflashId);
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy HH:mm');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Readers — ${widget.newsflash.title}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
                onPressed: () => Get.back<void>(),
              ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: FutureBuilder<List<NewsflashReaderModel>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final readers = snapshot.data ?? [];
              if (readers.isEmpty) {
                return const Center(
                  child: Text('No interactions recorded yet.',
                      style: TextStyle(color: Color(0xFF6B7280))),
                );
              }
              return ListView.builder(
                itemCount: readers.length,
                itemBuilder: (_, i) {
                  final r = readers[i];
                  return ListTile(
                    title: Text(r.displayName.isNotEmpty
                        ? r.displayName
                        : r.hashName),
                    subtitle: Text(fmt.format(r.updatedAt.toLocal())),
                    trailing: r.isDismissed
                        ? const Chip(
                            label: Text('Read',
                                style: TextStyle(fontSize: 11)),
                            backgroundColor: Color(0xFFDCFCE7),
                          )
                        : const Chip(
                            label: Text('Snoozed',
                                style: TextStyle(fontSize: 11)),
                            backgroundColor: Color(0xFFFEF9C3),
                          ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
