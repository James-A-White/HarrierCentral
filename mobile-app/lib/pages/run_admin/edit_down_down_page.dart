import 'package:harrier_central/imports.dart';

/// Edit Down Down. Stateless over [EditDownDownController].
class EditDownDownPage extends StatelessWidget {
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
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
    filled: true,
    fillColor: Colors.white,
  );

  @override
  Widget build(BuildContext context) {
    return GetBuilder<EditDownDownController>(
      init: EditDownDownController(
        kennelId: kennelId,
        eventId: eventId,
        kennelSlug: kennelSlug,
        eventNumber: eventNumber,
        downDown: downDown,
      ),
      tag: EditDownDownController.tagFor(downDown.downDownId),
      builder: (EditDownDownController c) => Obx(() => _body(context, c)),
    );
  }

  Widget _body(BuildContext context, EditDownDownController c) {
    final bool isSaving = c.isSaving.value;
    final bool isCapturingPhoto = c.isCapturingPhoto.value;
    final String? linkedSongId = c.linkedSongId.value;
    final String? chargePhotoUrl = c.chargePhotoUrl.value;
    final List<SongResult> songResults = c.songResults;
    return AppScaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: themeAppBarBackground,
        iconTheme: const IconThemeData(color: Colors.white, size: 28.0),
        title: Text(pageTitle, style: ts_appBarTitle),
        actions: [
          isSaving
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.check, color: Colors.white),
                  tooltip: 'Save',
                  onPressed: () => unawaited(c.save()),
                ),
        ],
      ),
      // A scroll view, not a Column with an Expanded list: on a short phone
      // with the keyboard up the form was taller than the space, and the song
      // results got zero height (2026-09-25). The results now follow the form
      // and scroll with it; large screens look the same.
      body: Container(
        decoration: Backgrounds.defaultHcBackground(),
        height: double.infinity,
        child: SingleChildScrollView(
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
                      controller: c.chargeController,
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
                      controller: c.songController,
                      style: const TextStyle(color: Colors.black87),
                      decoration: _fieldDecoration.copyWith(
                        hintText: 'Start typing to search…',
                        prefixIcon: const Icon(Icons.music_note),
                        suffixIcon: linkedSongId != null
                            ? Tooltip(
                                message: 'Unlink song',
                                child: IconButton(
                                  icon: const Icon(Icons.link_off, size: 18),
                                  onPressed: () =>
                                      c.unlinkSong(clearResults: true),
                                ),
                              )
                            : null,
                      ),
                      onChanged: c.onSongChanged,
                    ),
                  ],
                ),
              ),

              if (linkedSongId != null)
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
                        icon: isCapturingPhoto
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                chargePhotoUrl != null
                                    ? Icons.check_circle_outline
                                    : Icons.camera_alt,
                                color: Colors.white70,
                              ),
                        label: Text(
                          chargePhotoUrl != null
                              ? 'Photo added'
                              : 'Add photo (optional)',
                          style: const TextStyle(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white30),
                        ),
                        onPressed: isCapturingPhoto
                            ? null
                            : () => unawaited(c.takeChargePhoto()),
                      ),
                    ),
                    if (chargePhotoUrl != null) ...[
                      const SizedBox(width: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          chargePhotoUrl,
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

              if (songResults.isNotEmpty) ...[
                const Divider(height: 1, thickness: 1, color: Colors.white24),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
                  child: const Text(
                    'Select a song to link it',
                    style: TextStyle(fontSize: 11, color: Colors.white54),
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: songResults.length,
                  itemBuilder: (context, index) {
                    final song = songResults[index];
                    return ListTile(
                      leading: const Icon(
                        Icons.music_note,
                        color: Colors.white70,
                        size: 20,
                      ),
                      title: Text(
                        song.songName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      onTap: () => c.pickSong(song),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
