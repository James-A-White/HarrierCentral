/// Kennel Songs Page Layout
///
/// This file defines the UI layout for the Kennel Songs tab.
/// The tab is split horizontally:
/// - Left panel: scrollable list of songs with checkboxes
/// - Right panel: detail view of the currently selected song
///
/// Kennels can select/deselect songs to manage their song library,
/// and can add brand-new songs via an "Add Song" button.

part of '../../kennel_page_new_ui.dart';

/// Maps a bawdy rating (0–3) to its display emoji string.
/// 0 = Clean 😇, 1 = Mild 🍺🍺, 2 = Spicy 🌶️🌶️🌶️, 3 = Bawdy 🔥🔥🔥🔥
String _bawdyEmoji(int rating) => switch (rating) {
      0 => '😇',
      1 => '🍺🍺',
      2 => '🌶️🌶️🌶️',
      3 => '🔥🔥🔥🔥',
      _ => '',
    };

// ---------------------------------------------------------------------------
// Songs Tab Content Widget
// ---------------------------------------------------------------------------

/// Content widget for the Kennel Songs tab.
///
/// Displays a split view with:
/// - A searchable, scrollable song list with checkboxes (left)
/// - A song detail form panel (right)
class KennelSongsTabContent extends StatelessWidget {
  const KennelSongsTabContent({required this.controller, super.key});

  final KennelPageFormController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isMobileScreen =
          controller.screenSize.value == EScreenSize.isMobileScreen;

      // Show loading spinner while songs are being fetched
      if (controller.songsLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      // On mobile, show a single-column layout with list on top and detail below
      if (isMobileScreen) {
        return _buildMobileLayout();
      }

      return _buildDesktopLayout();
    });
  }

  // ---------------------------------------------------------------------------
  // Layout Builders
  // ---------------------------------------------------------------------------

  /// Desktop layout: side-by-side split view with a vertical divider.
  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left panel — song list with checkboxes
        Expanded(
          flex: 2,
          child: _SongListPanel(controller: controller),
        ),

        // Vertical divider
        const VerticalDivider(width: 1, thickness: 1),

        // Right panel — song detail form
        Expanded(
          flex: 3,
          child: _SongDetailPanel(controller: controller),
        ),
      ],
    );
  }

  /// Mobile layout: stacked vertically with a horizontal divider.
  Widget _buildMobileLayout() {
    return Column(
      children: [
        // Song list (takes upper half)
        Expanded(
          flex: 1,
          child: _SongListPanel(controller: controller),
        ),

        const Divider(height: 1, thickness: 1),

        // Song detail (takes lower half)
        Expanded(
          flex: 1,
          child: _SongDetailPanel(controller: controller),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Song List Panel (Left Side)
// ---------------------------------------------------------------------------

/// Left panel showing a scrollable list of songs with checkboxes.
///
/// Includes:
/// - Search/filter field at the top
/// - "Add Song" button
/// - Scrollable list of [CheckboxListTile] items
class _SongListPanel extends StatelessWidget {
  const _SongListPanel({required this.controller});

  final KennelPageFormController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header row: search + add button
        _buildHeaderRow(),

        const Divider(height: 1),

        // Song list
        Expanded(child: _buildSongList()),
      ],
    );
  }

  /// Builds the header row with search field and "Add Song" button.
  Widget _buildHeaderRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Search field
          Expanded(
            child: TextField(
              controller: controller.songSearchController,
              decoration: InputDecoration(
                hintText: 'Search songs...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: Obx(() {
                  if (controller.songSearchQuery.value.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      controller.songSearchController.clear();
                      controller.songSearchQuery.value = '';
                    },
                  );
                }),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) => controller.songSearchQuery.value = value,
            ),
          ),

          const SizedBox(width: 8),

          // Add Song button — only visible to super-admins and song managers
          if (controller.canManageSongs)
            FilledButton.icon(
              onPressed: controller.startAddNewSong,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Song'),
            ),
        ],
      ),
    );
  }

  /// Builds the scrollable song list with checkboxes.
  Widget _buildSongList() {
    return Obx(() {
      final filteredSongs = controller.filteredSongs;

      if (filteredSongs.isEmpty) {
        return Center(
          child: Text(
            controller.songSearchQuery.value.isNotEmpty
                ? 'No songs match your search.'
                : 'No songs available.',
            style: bodyStyleBlack,
          ),
        );
      }

      return ListView.builder(
        itemCount: filteredSongs.length,
        itemBuilder: (context, index) {
          final song = filteredSongs[index];
          return _SongCheckboxTile(
            controller: controller,
            song: song,
          );
        },
      );
    });
  }
}

// ---------------------------------------------------------------------------
// Song Checkbox Tile
// ---------------------------------------------------------------------------

/// Individual song list tile with a checkbox and selection highlight.
class _SongCheckboxTile extends StatelessWidget {
  const _SongCheckboxTile({
    required this.controller,
    required this.song,
  });

  final KennelPageFormController controller;
  final SongModel song;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isSelected = controller.selectedSongId.value == song.id.asUuid;
      final isInKennel = controller.songSelections[song.id.asUuid]?.value == 1;

      return Container(
        color: isSelected ? Colors.blue.shade50 : null,
        child: ListTile(
          dense: true,
          leading: Checkbox(
            value: isInKennel,
            onChanged: (value) {
              unawaited(controller.toggleSongInKennel(song.id, value ?? false));
            },
          ),
          title: Text(
            song.SongName,
            style: bodyStyleBlack.copyWith(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: song.TuneOf != null && song.TuneOf!.isNotEmpty
              ? Text(
                  'Tune of: ${song.TuneOf}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          trailing: song.BawdyRating != null
              ? _buildBawdyRating(song.BawdyRating!)
              : null,
          onTap: () => controller.selectSong(song.id),
        ),
      );
    });
  }

  /// Builds a small bawdy rating indicator.
  Widget _buildBawdyRating(int rating) {
    final emoji = _bawdyEmoji(rating.clamp(0, 3));
    if (emoji.isEmpty) return const SizedBox.shrink();
    return Text(emoji, style: const TextStyle(fontSize: 14));
  }
}

// ---------------------------------------------------------------------------
// Song Detail Panel (Right Side)
// ---------------------------------------------------------------------------

/// Right panel showing details of the currently selected song.
///
/// When no song is selected, shows a placeholder message.
/// When adding a new song, shows an editable form.
/// When viewing an existing song, shows read-only detail fields.
class _SongDetailPanel extends StatelessWidget {
  const _SongDetailPanel({required this.controller});

  final KennelPageFormController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Adding a new song — show the editable form
      if (controller.isAddingSong.value) {
        return _buildNewSongForm();
      }

      // Check if a song is selected
      final selectedId = controller.selectedSongId.value;
      if (selectedId.isEmpty) {
        return _buildPlaceholder();
      }

      // Find the selected song
      final song = controller.allSongs.firstWhereOrNull(
        (s) => s.id == selectedId,
      );

      if (song == null) {
        return _buildPlaceholder();
      }

      // Editing mode — show the editable form pre-populated with this song
      if (controller.isEditingSong.value) {
        return _buildEditSongForm(song);
      }

      return _buildSongDetail(song);
    });
  }

  // ---------------------------------------------------------------------------
  // Placeholder
  // ---------------------------------------------------------------------------

  /// Empty state — no song selected.
  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(FontAwesome5Solid.music, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Select a song to view its details',
            style: bodyStyleBlack.copyWith(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Song Detail (Read-Only)
  // ---------------------------------------------------------------------------

  /// Displays full detail for the selected song in a form-like layout.
  Widget _buildSongDetail(SongModel song) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Song image
          if (song.ImageUrl != null && song.ImageUrl!.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: HcNetworkImage(
                song.ImageUrl!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Audio player
          if (song.AudioUrl != null && song.AudioUrl!.isNotEmpty) ...[
            _SongAudioPlayer(key: ValueKey(song.id), url: song.AudioUrl!),
            const SizedBox(height: 16),
          ],

          // Song name header
          Text(song.SongName, style: headingStyleBlack),
          if (song.TuneOf != null && song.TuneOf!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Tune of: ${song.TuneOf}',
              style: bodyStyleBlack.copyWith(
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade700,
              ),
            ),
          ],

          const SizedBox(height: 16),
          const Divider(),

          // Metadata section
          HelperWidgets().categoryLabelWidget('Details'),
          _buildDetailRow('Bawdy Rating', _bawdyRatingText(song.BawdyRating)),
          _buildDetailRow('Tags', song.Tags ?? '—'),
          _buildDetailRow('Rank', song.Rank?.toString() ?? '—'),
          _buildDetailRow(
            'Auto-add to Kennel',
            (song.AutoAddToKennel ?? 0) > 0 ? 'Yes' : 'No',
          ),
          if (song.AddedBy_KennelName != null &&
              song.AddedBy_KennelName!.isNotEmpty)
            _buildDetailRow('Added by', song.AddedBy_KennelName!),

          const SizedBox(height: 12),
          // Edit button — only visible to users who can manage songs AND only
          // for songs that were added by this kennel.
          if (controller.canManageSongs &&
              song.AddedBy_KennelId?.asUuid ==
                  controller.originalData.kennelPublicId.uuid)
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: () => controller.startEditSong(song),
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Edit Song'),
              ),
            ),

          const SizedBox(height: 16),

          // Lyrics section
          if (song.Lyrics != null && song.Lyrics!.isNotEmpty) ...[
            HelperWidgets().categoryLabelWidget('Lyrics'),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: SelectableText(
                song.Lyrics!,
                style: bodyStyleBlack.copyWith(height: 1.6),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Notes section
          if (song.Notes != null && song.Notes!.isNotEmpty) ...[
            HelperWidgets().categoryLabelWidget('Notes'),
            Text(song.Notes!, style: bodyStyleBlack),
            const SizedBox(height: 16),
          ],

          // Actions section
          if (song.Actions != null && song.Actions!.isNotEmpty) ...[
            HelperWidgets().categoryLabelWidget('Actions'),
            Text(song.Actions!, style: bodyStyleBlack),
            const SizedBox(height: 16),
          ],

          // Variants section
          if (song.Variants != null && song.Variants!.isNotEmpty) ...[
            HelperWidgets().categoryLabelWidget('Variants'),
            Text(song.Variants!, style: bodyStyleBlack),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  /// Helper to build a label–value detail row.
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: bodyStyleBlack.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value, style: bodyStyleBlack),
          ),
        ],
      ),
    );
  }

  /// Converts a bawdy rating integer to a display string.
  String _bawdyRatingText(int? rating) {
    if (rating == null) return '—';
    final emoji = _bawdyEmoji(rating.clamp(0, 3));
    return emoji.isEmpty ? '—' : emoji;
  }

  // ---------------------------------------------------------------------------
  // New Song Form (Editable)
  // ---------------------------------------------------------------------------

  /// Form for adding a brand-new song.
  Widget _buildNewSongForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with cancel/save buttons
          Row(
            children: [
              Expanded(
                child: Text('Add New Song', style: headingStyleBlack),
              ),
              TextButton(
                onPressed: controller.cancelAddNewSong,
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: controller.saveNewSong,
                child: const Text('Save Song'),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(),

          // Song Name
          HelperWidgets().categoryLabelWidget('Song Information'),
          _buildFormField(
            controller: controller.newSongNameController,
            label: 'Song Name *',
          ),
          const SizedBox(height: 12),
          _buildFormField(
            controller: controller.newSongTuneOfController,
            label: 'Tune Of',
          ),

          const SizedBox(height: 16),

          // Lyrics
          HelperWidgets().categoryLabelWidget('Lyrics'),
          _buildFormField(
            controller: controller.newSongLyricsController,
            label: 'Lyrics',
            maxLines: 10,
          ),

          const SizedBox(height: 16),

          // Additional details
          HelperWidgets().categoryLabelWidget('Additional Details'),

          // Bawdy rating selector
          _buildBawdyRatingSelector(),
          const SizedBox(height: 12),

          _buildFormField(
            controller: controller.newSongNotesController,
            label: 'Notes',
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          _buildFormField(
            controller: controller.newSongActionsController,
            label: 'Actions (e.g., "Drink!" instructions)',
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          _buildFormField(
            controller: controller.newSongVariantsController,
            label: 'Variants',
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          _buildFormField(
            controller: controller.newSongTagsController,
            label: 'Tags (comma-separated)',
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// Bawdy rating selector — four labelled options rendered as a SegmentedButton.
  Widget _buildBawdyRatingSelector() {
    const options = [
      (value: 0, emoji: '😇', label: 'Clean'),
      (value: 1, emoji: '🍺🍺', label: 'Mild'),
      (value: 2, emoji: '🌶️🌶️🌶️', label: 'Spicy'),
      (value: 3, emoji: '🔥🔥🔥🔥', label: 'Bawdy'),
    ];

    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bawdy Rating',
            style: bodyStyleBlack.copyWith(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 6),
          SegmentedButton<int>(
            segments: [
              for (final opt in options)
                ButtonSegment<int>(
                  value: opt.value,
                  label: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(opt.emoji, style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 2),
                      Text(opt.label, style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
            ],
            selected: {controller.newSongBawdyRating.value},
            onSelectionChanged: (selection) {
              controller.newSongBawdyRating.value = selection.first;
            },
            showSelectedIcon: false,
          ),
        ],
      ),
    );
  }

  /// Form for editing an existing song (pre-populated via [startEditSong]).
  Widget _buildEditSongForm(SongModel song) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with cancel/save buttons
          Row(
            children: [
              Expanded(
                child: Text('Edit Song', style: headingStyleBlack),
              ),
              TextButton(
                onPressed: controller.cancelEditSong,
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: controller.saveEditedSong,
                child: const Text('Save Changes'),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(),

          HelperWidgets().categoryLabelWidget('Song Information'),
          _buildFormField(
            controller: controller.newSongNameController,
            label: 'Song Name *',
          ),
          const SizedBox(height: 12),
          _buildFormField(
            controller: controller.newSongTuneOfController,
            label: 'Tune Of',
          ),

          const SizedBox(height: 16),

          HelperWidgets().categoryLabelWidget('Lyrics'),
          _buildFormField(
            controller: controller.newSongLyricsController,
            label: 'Lyrics',
            maxLines: 10,
          ),

          const SizedBox(height: 16),

          HelperWidgets().categoryLabelWidget('Additional Details'),
          _buildBawdyRatingSelector(),
          const SizedBox(height: 12),
          _buildFormField(
            controller: controller.newSongNotesController,
            label: 'Notes',
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          _buildFormField(
            controller: controller.newSongActionsController,
            label: 'Actions (e.g., "Drink!" instructions)',
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          _buildFormField(
            controller: controller.newSongVariantsController,
            label: 'Variants',
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          _buildFormField(
            controller: controller.newSongTagsController,
            label: 'Tags (comma-separated)',
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// Helper to build a form text field.
  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Audio Player Widget
// ---------------------------------------------------------------------------

/// A self-contained audio player with full transport controls.
///
/// Uses [just_audio] to stream the song from the given [url].
/// Controls: play/pause, stop, skip ±10s, loop, speed, volume, seek slider.
/// The player is disposed automatically when the widget is removed.
class _SongAudioPlayer extends StatefulWidget {
  const _SongAudioPlayer({super.key, required this.url});

  final String url;

  @override
  State<_SongAudioPlayer> createState() => _SongAudioPlayerState();
}

class _SongAudioPlayerState extends State<_SongAudioPlayer> {
  static const _controlColor = Color(0xFFB71C1C); // Colors.red[900]

  late final AudioPlayer _player;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isLoading = true;
  bool _hasError = false;
  double _volume = 1.0;
  double _speed = 1.0;
  bool _looping = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    unawaited(_initPlayer());
  }

  Future<void> _initPlayer() async {
    try {
      _player.durationStream.listen((d) {
        if (mounted && d != null) setState(() => _duration = d);
      });
      _player.positionStream.listen((p) {
        if (mounted) setState(() => _position = p);
      });
      _player.playerStateStream.listen((_) {
        if (mounted) setState(() {});
      });

      await _player.setUrl(widget.url);
      if (mounted) setState(() => _isLoading = false);
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    unawaited(_player.dispose());
    super.dispose();
  }

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  void _skipBy(int seconds) {
    final target = _position + Duration(seconds: seconds);
    final clamped = target < Duration.zero
        ? Duration.zero
        : (target > _duration ? _duration : target);
    unawaited(_player.seek(clamped));
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) return const SizedBox.shrink();

    final playing = _player.playing;
    final completed = _player.processingState == ProcessingState.completed;
    final totalMs = _duration.inMilliseconds.toDouble();
    final posMs = _position.inMilliseconds.toDouble().clamp(0.0, totalMs);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: _isLoading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ---- Seek slider with time labels ----
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    activeTrackColor: _controlColor,
                    inactiveTrackColor: _controlColor.withValues(alpha: 0.25),
                    thumbColor: _controlColor,
                    overlayColor: _controlColor.withValues(alpha: 0.12),
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 7),
                  ),
                  child: Slider(
                    min: 0,
                    max: totalMs > 0 ? totalMs : 1,
                    value: posMs,
                    onChanged: (v) {
                      unawaited(
                        _player.seek(Duration(milliseconds: v.toInt())),
                      );
                    },
                  ),
                ),

                // ---- Elapsed / remaining time ----
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_fmt(_position),
                          style: bodyStyleBlack.copyWith(fontSize: 12)),
                      Text('-${_fmt(_duration - _position)}',
                          style: bodyStyleBlack.copyWith(
                              fontSize: 12, color: Colors.grey.shade600)),
                      Text(_fmt(_duration),
                          style: bodyStyleBlack.copyWith(fontSize: 12)),
                    ],
                  ),
                ),

                const SizedBox(height: 4),

                // ---- Transport controls ----
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Loop toggle
                    IconButton(
                      icon: Icon(
                        Icons.loop,
                        size: 20,
                        color: _looping ? _controlColor : Colors.grey.shade500,
                      ),
                      tooltip: _looping ? 'Disable loop' : 'Enable loop',
                      onPressed: () {
                        setState(() => _looping = !_looping);
                        unawaited(_player.setLoopMode(
                          _looping ? LoopMode.one : LoopMode.off,
                        ));
                      },
                    ),

                    // Skip back 10s
                    IconButton(
                      icon:
                          Icon(Icons.replay_10, size: 24, color: _controlColor),
                      tooltip: 'Back 10 seconds',
                      onPressed: () => _skipBy(-10),
                    ),

                    // Stop
                    IconButton(
                      icon: Icon(Icons.stop_rounded,
                          size: 28, color: _controlColor),
                      tooltip: 'Stop',
                      onPressed: () async {
                        await _player.stop();
                        await _player.seek(Duration.zero);
                      },
                    ),

                    // Play / Pause (large)
                    IconButton(
                      iconSize: 40,
                      icon: Icon(
                        (playing && !completed)
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled,
                        size: 40,
                        color: _controlColor,
                      ),
                      tooltip: (playing && !completed) ? 'Pause' : 'Play',
                      onPressed: () async {
                        if (completed) {
                          await _player.seek(Duration.zero);
                          await _player.play();
                        } else if (playing) {
                          await _player.pause();
                        } else {
                          await _player.play();
                        }
                      },
                    ),

                    // Skip forward 10s
                    IconButton(
                      icon: Icon(Icons.forward_10,
                          size: 24, color: _controlColor),
                      tooltip: 'Forward 10 seconds',
                      onPressed: () => _skipBy(10),
                    ),

                    // Speed control
                    PopupMenuButton<double>(
                      tooltip: 'Playback speed',
                      icon: Text(
                        '${_speed}x',
                        style: bodyStyleBlack.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _speed != 1.0
                              ? _controlColor
                              : Colors.grey.shade600,
                        ),
                      ),
                      onSelected: (v) {
                        setState(() => _speed = v);
                        unawaited(_player.setSpeed(v));
                      },
                      itemBuilder: (_) => [
                        for (final s in [0.5, 0.75, 1.0, 1.25, 1.5, 2.0])
                          PopupMenuItem(
                            value: s,
                            child: Text(
                              '${s}x',
                              style: TextStyle(
                                fontWeight: s == _speed
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 2),

                // ---- Volume slider ----
                Row(
                  children: [
                    Icon(
                      _volume == 0
                          ? Icons.volume_off
                          : _volume < 0.5
                              ? Icons.volume_down
                              : Icons.volume_up,
                      size: 20,
                      color: _controlColor,
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3,
                          activeTrackColor: _controlColor,
                          inactiveTrackColor:
                              _controlColor.withValues(alpha: 0.2),
                          thumbColor: _controlColor,
                          overlayColor: _controlColor.withValues(alpha: 0.1),
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 5),
                        ),
                        child: Slider(
                          min: 0,
                          max: 1,
                          value: _volume,
                          onChanged: (v) {
                            setState(() => _volume = v);
                            unawaited(_player.setVolume(v));
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
