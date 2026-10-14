part of '../../kennel_page_new_ui.dart';

/// The Social Links tab (E12.F4.S4): every place the club talks, in the
/// order the app and the website show them.
class KennelSocialLinksTabContent extends StatelessWidget {
  const KennelSocialLinksTabContent({required this.controller, super.key});

  final KennelPageFormController controller;

  @override
  Widget build(BuildContext context) {
    return Lockable(
      lockState: controller.tabLocked[KennelTabType.socialLinks.index],
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HelperWidgets().categoryLabelWidget('Social and chat links'),
              const SizedBox(height: 4),
              const Text(
                'Shown as a row of icons on your kennel page in the app and on '
                'your website, in this order — drag the handle to reorder. '
                'Chat groups (WhatsApp, Signal, Telegram, WeChat, LINE …) are '
                'shown to members only unless you choose Everyone: spammers '
                'harvest public invite links.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 12),
              Obx(() {
                final List<SocialLink> links = controller.socialLinks.toList();
                final bool uploading = controller.socialQrUploading.value;
                if (links.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        'No links yet.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
                  );
                }
                return ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  itemCount: links.length,
                  onReorder: controller.moveSocialLink,
                  itemBuilder: (BuildContext context, int i) => _SocialLinkRow(
                    key: ObjectKey(controller.socialLinkFields[i]),
                    index: i,
                    link: links[i],
                    controller: controller,
                    uploading: uploading,
                  ),
                );
              }),
              const SizedBox(height: 12),
              Obx(() {
                final int n = controller.socialLinks.length;
                return Center(
                  child: n >= kMaxSocialLinks
                      ? const Text(
                          'That is the most a kennel can have ($kMaxSocialLinks).',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        )
                      : HcButton.secondary(
                          label: 'Add a link',
                          icon: Icons.add_link,
                          onPressed: controller.addSocialLink,
                        ),
                );
              }),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialLinkRow extends StatelessWidget {
  const _SocialLinkRow({
    required this.index,
    required this.link,
    required this.controller,
    required this.uploading,
    super.key,
  });

  final int index;
  final SocialLink link;
  final KennelPageFormController controller;
  final bool uploading;

  @override
  Widget build(BuildContext context) {
    final String? problem = link.problem;
    final bool isWeChat = link.platform == 'wechat';
    final bool isOther = link.platform == 'other';
    final bool untouched = (link.url ?? link.handle ?? '').isEmpty && link.qrImageUrl == null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: problem != null && !untouched ? Colors.red.shade300 : Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ReorderableDragStartListener(
                index: index,
                child: const Padding(
                  padding: EdgeInsets.fromLTRB(4, 10, 4, 0),
                  child: Icon(Icons.drag_indicator, color: Colors.black45),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 10, 8, 0),
                child: Icon(socialPlatformIcon(link.platform), size: 22, color: Colors.black54),
              ),
              SizedBox(
                width: 160,
                child: DropdownButtonFormField<String>(
                  key: ValueKey('social-platform-$index-${link.platform}'),
                  initialValue: link.platform,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Platform',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    for (final (String id, String label, _) in socialPlatforms)
                      DropdownMenuItem(value: id, child: Text(label, overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (String? p) {
                    if (p != null) controller.setSocialPlatform(index, p);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: TextField(
                  controller: controller.socialLinkFields[index],
                  decoration: InputDecoration(
                    labelText: isWeChat ? 'WeChat ID or https:// link' : 'Address',
                    hintText: isWeChat ? 'e.g. hashhouse_sh' : 'https://…',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (_) => controller.socialFieldChanged(index),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: controller.socialLabelFields[index],
                  decoration: InputDecoration(
                    labelText: isOther ? 'Name (required)' : 'Name (optional)',
                    hintText: isOther ? 'e.g. Club shop' : 'e.g. Run chat',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (_) => controller.socialFieldChanged(index),
                ),
              ),
              IconButton(
                tooltip: 'Remove',
                icon: Icon(Icons.delete_outline, color: Colors.red.shade600),
                onPressed: () => controller.removeSocialLink(index),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 36, top: 6),
            child: Wrap(
              spacing: 12,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'public', label: Text('Everyone', textAlign: TextAlign.center), icon: Icon(Icons.public, size: 16)),
                    ButtonSegment(value: 'members', label: Text('Members only', textAlign: TextAlign.center), icon: Icon(Icons.lock_outline, size: 16)),
                  ],
                  selected: {link.audience},
                  showSelectedIcon: false,
                  style: const ButtonStyle(visualDensity: VisualDensity.compact),
                  onSelectionChanged: (Set<String> s) => controller.setSocialAudience(index, s.first),
                ),
                if (isWeChat) ...[
                  if (link.qrImageUrl != null) ...[
                    // The QR image shown whole, never cropped.
                    SizedBox(
                      height: 56,
                      child: Image.network(link.qrImageUrl!, fit: BoxFit.contain),
                    ),
                    TextButton(
                      onPressed: () => controller.removeSocialQrImage(index),
                      child: const Text('Remove QR code', textAlign: TextAlign.center),
                    ),
                  ] else
                    HcButton.secondary(
                      label: uploading ? 'Uploading…' : 'Add the group QR code',
                      icon: Icons.qr_code_2,
                      loading: uploading,
                      onPressed: uploading ? null : () => controller.pickSocialQrImage(index),
                    ),
                ],
              ],
            ),
          ),
          if (problem != null && !untouched)
            Padding(
              padding: const EdgeInsets.only(left: 36, top: 6),
              child: Text(
                'Not saved yet: $problem',
                style: TextStyle(fontSize: 12, color: Colors.red.shade700),
              ),
            ),
        ],
      ),
    );
  }
}
