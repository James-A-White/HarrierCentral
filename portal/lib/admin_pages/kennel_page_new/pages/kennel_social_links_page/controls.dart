part of '../../kennel_page_new_controller.dart';

// ---------------------------------------------------------------------------
// Social Links tab (E12.F4.S4)
//
// The rows live here; the model's socialLinksJson holds ONLY the rows that
// pass SocialLink.problem — the same rules HC6.SocialLinksProblem applies.
// The editor auto-saves, so a row still being typed must never reach the
// SP: it would be refused and the refusal shown as an error dialog mid-edit.
// A row with a problem stays on screen with the problem under it, "not
// saved yet", until it is fixed or removed.
// ---------------------------------------------------------------------------

/// At most this many links (HC6.SocialLinksProblem refuses more).
const int kMaxSocialLinks = 20;

extension KennelSocialLinksControlsExtension on KennelPageFormController {
  RxList<SocialLink> get socialLinks => _socialLinks;
  List<TextEditingController> get socialLinkFields => _socialLinkFields;
  List<TextEditingController> get socialLabelFields => _socialLabelFields;
  RxBool get socialQrUploading => _socialQrUploading;

  /// (Re)builds the rows from the model — on open and after Undo.
  void initSocialLinksControls() {
    _disposeSocialLinkFields();
    final List<SocialLink> links = socialLinksFromJson(editedData.value.socialLinksJson);
    for (final SocialLink l in links) {
      _socialLinkFields.add(TextEditingController(text: l.url ?? l.handle ?? ''));
      _socialLabelFields.add(TextEditingController(text: l.label ?? ''));
    }
    _socialLinks.assignAll(links);
  }

  void _disposeSocialLinkFields() {
    for (final TextEditingController c in _socialLinkFields) {
      c.dispose();
    }
    for (final TextEditingController c in _socialLabelFields) {
      c.dispose();
    }
    _socialLinkFields.clear();
    _socialLabelFields.clear();
  }

  void addSocialLink() {
    if (_socialLinks.length >= kMaxSocialLinks) return;
    _socialLinkFields.add(TextEditingController());
    _socialLabelFields.add(TextEditingController());
    // No platform yet: the row's logo square shows a placeholder until one
    // is chosen.
    _socialLinks.add(SocialLink(platform: ''));
    // Nothing to flush: an empty row is not valid, so the model is unchanged.
  }

  void removeSocialLink(int i) {
    _socialLinks.removeAt(i);
    _socialLinkFields.removeAt(i).dispose();
    _socialLabelFields.removeAt(i).dispose();
    _flushSocialLinksToModel();
  }

  void moveSocialLink(int from, int to) {
    if (to > from) to--; // ReorderableListView reports the slot before removal
    if (from == to) return;
    _socialLinks.insert(to, _socialLinks.removeAt(from));
    _socialLinkFields.insert(to, _socialLinkFields.removeAt(from));
    _socialLabelFields.insert(to, _socialLabelFields.removeAt(from));
    _flushSocialLinksToModel();
  }

  /// A new platform resets the audience to that platform's default: chat
  /// groups to members, everything else to everyone.
  void setSocialPlatform(int i, String platform) {
    final SocialLink l = _socialLinks[i];
    l.platform = platform;
    l.audience = socialMembersByDefault.contains(platform) ? 'members' : 'public';
    if (platform != 'wechat') l.qrImageUrl = null;
    _syncRowFromFields(i);
    _socialLinks.refresh();
    _flushSocialLinksToModel();
  }

  void setSocialAudience(int i, String audience) {
    _socialLinks[i].audience = audience;
    _socialLinks.refresh();
    _flushSocialLinksToModel();
  }

  /// Typing in a row's address or label field.
  void socialFieldChanged(int i) {
    _syncRowFromFields(i);
    _socialLinks.refresh();
    _flushSocialLinksToModel();
  }

  /// Uploads a WeChat group QR image to the logos container and puts its
  /// address on the row.
  Future<void> pickSocialQrImage(int i) async {
    if (_socialQrUploading.value) return;
    _socialQrUploading.value = true; // shown before the picker opens
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      final PlatformFile? file = (result == null || result.files.isEmpty) ? null : result.files.first;
      if (file?.bytes == null) return;
      final String ext = (file!.extension ?? 'jpg').toLowerCase();
      final String fileName = await ServiceCommon.uploadFile(
        file.bytes!,
        editedData.value.kennelPublicId.uuid,
        DocumentType.kennelLogo.name,
        UiControlType.imageUpload,
        filenameExtension: ext == 'png' ? 'png' : 'jpg',
        filenamePrefix: 'qr_',
      );
      if (fileName.isEmpty || isClosed || i >= _socialLinks.length) return;
      _socialLinks[i].qrImageUrl = '$BASE_KENNEL_LOGOS_URL$fileName';
      _socialLinks.refresh();
      _flushSocialLinksToModel();
    } finally {
      if (!isClosed) _socialQrUploading.value = false;
    }
  }

  void removeSocialQrImage(int i) {
    _socialLinks[i].qrImageUrl = null;
    _socialLinks.refresh();
    _flushSocialLinksToModel();
  }

  /// The row's address field holds a link, or — for WeChat, which has no
  /// group links — a WeChat ID.
  void _syncRowFromFields(int i) {
    final SocialLink l = _socialLinks[i];
    final String text = _socialLinkFields[i].text.trim();
    final bool isWeChatId = l.platform == 'wechat' && text.isNotEmpty && !text.startsWith('https://');
    l.url = isWeChatId || text.isEmpty ? null : text;
    l.handle = isWeChatId ? text : null;
    final String label = _socialLabelFields[i].text.trim();
    l.label = label.isEmpty ? null : label;
  }

  void _flushSocialLinksToModel() {
    final List<SocialLink> valid = _socialLinks.where((l) => l.problem == null).toList();
    // '' rather than null when empty: the SP reads NULL as "unchanged".
    final String json = valid.isEmpty ? '' : socialLinksToJson(valid)!;
    final String before = editedData.value.socialLinksJson ?? '';
    if (json == before) return;
    // Opening a kennel with no links holds null; keep null while still empty
    // so an untouched editor is not "dirty".
    final String? next = (json.isEmpty && originalData.socialLinksJson == null) ? null : json;
    editedData.value = editedData.value.copyWith(socialLinksJson: next);
    checkIfFormIsDirty();
  }
}
