import 'package:harrier_central/imports.dart';
import 'package:harrier_central/pages/run_admin/down_down_people.dart';

/// Add Down Down. Stateless over [AddDownDownController].
class AddDownDownPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return GetBuilder<AddDownDownController>(
      init: AddDownDownController(
        kennelId: kennelId,
        eventId: eventId,
        eventName: eventName,
        kennelSlug: kennelSlug,
        eventNumber: eventNumber,
      ),
      tag: AddDownDownController.tagFor(eventId),
      builder: (AddDownDownController c) => Obx(() => _body(context, c)),
    );
  }

  Widget _body(BuildContext context, AddDownDownController c) {
    // Snapshots inside the Obx so the lists and their counts agree.
    final bool isSaving = c.isSaving.value;
    final bool isCapturingPhoto = c.isCapturingPhoto.value;
    final String? linkedSongId = c.linkedSongId.value;
    final String? chargePhotoUrl = c.chargePhotoUrl.value;
    final List<SongResult> songResults = c.songResults;
    final List<String> externalNames = c.externalNames;
    final List<AttendeeItem> attendees = c.attendees;
    final int selectedCount = attendees.where((a) => a.selected).length;
    return AppScaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: themeAppBarBackground,
        iconTheme: const IconThemeData(color: Colors.white, size: 28.0),
        title: Text('Add Down Down', style: ts_appBarTitle),
      ),
      body: Container(
        decoration: Backgrounds.defaultHcBackground(),
        child: c.isLoading.value
            ? const HcAppCircularProgressIndicator(key: Key('add_dd_loading'))
            // One scroll view for the whole page: the form, then the
            // attendees. It was a fixed Column above an Expanded list, and on
            // a short phone with the keyboard up the form alone was taller
            // than the space — the external-name field and the song
            // suggestions ended up under the keyboard with nothing to scroll
            // (2026-09-25). Large screens look the same; the list just scrolls
            // with the form instead of under it.
            : CustomScrollView(
                slivers: <Widget>[
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        // Charge text input with inline send button
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              TextField(
                                controller: c.chargeController,
                                maxLines: 3,
                                decoration: InputDecoration(
                                  labelText: 'Charge',
                                  hintText: 'What did they do?',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.fromLTRB(
                                    12,
                                    12,
                                    52,
                                    12,
                                  ),
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
                                    onTap: isSaving
                                        ? null
                                        : () => unawaited(c.submit()),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: isSaving
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.send,
                                              color: Colors.white,
                                              size: 20,
                                            ),
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
                            controller: c.songController,
                            decoration: InputDecoration(
                              labelText: 'Recommended song (optional)',
                              hintText: 'e.g. Down Down',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              prefixIcon: const Icon(Icons.music_note),
                              suffixIcon: linkedSongId != null
                                  ? Tooltip(
                                      message: 'Unlink song',
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.link_off,
                                          size: 18,
                                        ),
                                        onPressed: c.unlinkSong,
                                      ),
                                    )
                                  : null,
                            ),
                            onChanged: c.onSongChanged,
                          ),
                        ),
                        if (songResults.isNotEmpty)
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
                                itemCount: songResults.length,
                                itemBuilder: (context, index) {
                                  final song = songResults[index];
                                  return ListTile(
                                    dense: true,
                                    leading: const Icon(
                                      Icons.music_note,
                                      size: 16,
                                      color: Colors.black54,
                                    ),
                                    title: Text(
                                      song.songName,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    onTap: () => c.pickSong(song),
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
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: Colors.white30,
                                    ),
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
                                    errorBuilder: (_, _, _) =>
                                        const SizedBox.shrink(),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    size: 18,
                                    color: Colors.white54,
                                  ),
                                  onPressed: c.removePhoto,
                                  tooltip: 'Remove photo',
                                ),
                              ],
                            ],
                          ),
                        ),
                        // People not in the app — free-text names added as chips.
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          child: DownDownExternalNamesField(
                            c: c,
                            names: externalNames,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          child: Row(
                            children: [
                              Text(
                                'People in the app ($selectedCount selected)',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: Colors.white24),
                      ],
                    ),
                  ),
                  if (attendees.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(
                          'No attendees found yet.\nCheck-in data may still be loading.',
                          textAlign: TextAlign.center,
                          style: ts_headingLarge.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    )
                  else
                    SliverList.builder(
                      itemCount: attendees.length,
                      itemBuilder: (context, index) {
                        final attendee = attendees[index];
                        return DownDownAttendeeTile(c: c, attendee: attendee);
                      },
                    ),
                ],
              ),
      ),
    );
  }
}
