import 'package:harrier_central/imports.dart';

class SongsPage extends StatelessWidget {
  const SongsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final SongsPageController c = Get.isRegistered<SongsPageController>()
        ? Get.find<SongsPageController>()
        : Get.put(SongsPageController());

    return Container(
      decoration: Backgrounds.defaultHcBackground(),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double fullHeight = constraints.maxHeight;
          final double collapsedLyricsHeight =
              fullHeight * SongsPageController.collapsedLyricsFraction;
          final double listHeight = fullHeight - collapsedLyricsHeight;

          return SizedBox(
            height: fullHeight,
            child: Stack(
              children: <Widget>[
                // Song list occupies top ~2/3
                _buildSongList(c, listHeight),

                // Lyrics panel occupies bottom ~1/3, expandable to full screen
                _buildLyricsPanel(c, collapsedLyricsHeight, fullHeight),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Bawdy rating filter toggles
  // ---------------------------------------------------------------------------

  Widget _buildBawdyFilterBar(SongsPageController c) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Obx(
        () => Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: SongsPageController.bawdyIcons.entries.map((
            MapEntry<int, String> entry,
          ) {
            final bool isActive = c.activeBawdyFilters.contains(entry.key);
            return GestureDetector(
              onTap: () => c.toggleBawdyFilter(entry.key),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive ? Colors.white : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isActive ? themeButtonColors : Colors.grey.shade400,
                    width: isActive ? 2 : 1,
                  ),
                ),
                child: Opacity(
                  opacity: isActive ? 1.0 : 0.4,
                  child: Text(
                    entry.value,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Search bar (matches kennel list style)
  // ---------------------------------------------------------------------------

  Widget _buildSearchBar(SongsPageController c) {
    return Material(
      elevation: 8.0,
      shadowColor: Colors.black87,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.only(left: 10),
        child: Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                autocorrect: false,
                onChanged: c.onSearchChanged,
                focusNode: c.searchFocusNode,
                controller: c.searchController,
                keyboardType: TextInputType.text,
                style: ts_titleMediumBlack,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  icon: const Icon(FontAwesome.search, color: Colors.black),
                  hintText: 'Search songs...',
                  hintStyle: ts_searchLabel,
                ),
              ),
            ),
            SizedBox(
              width: 40,
              child: TextButton(
                style: TextButton.styleFrom(
                  shape: button_shape,
                  textStyle: TextStyle(color: Colors.grey.shade700),
                  backgroundColor: Colors.white,
                ),
                child: Text(
                  'X',
                  style: ts_headingBlack.copyWith(color: Colors.grey.shade700),
                ),
                onPressed: c.clearSearch,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Song list item
  // ---------------------------------------------------------------------------

  Widget _buildSongListItem(SongsPageController c, SongsModel song) {
    return Obx(() {
      final bool isSelected = c.selectedSong.value?.songId == song.songId;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Card(
          elevation: isSelected ? 6.0 : 2.0,
          color: isSelected ? themeLightBackground : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: isSelected
                ? BorderSide(color: themeButtonColors, width: 2)
                : BorderSide.none,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => c.selectSong(song),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14.0,
                vertical: 10.0,
              ),
              child: Row(
                children: <Widget>[
                  // Sung checkbox
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: Checkbox(
                      value: c.sungSongIds.contains(song.songId),
                      activeColor: themeButtonColors,
                      onChanged: (_) => c.toggleSung(song.songId),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Song image or fallback icon
                  if (song.imageUrl != null && song.imageUrl!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        song.imageUrl!,
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (BuildContext context, Object e, StackTrace? st) =>
                                Icon(
                                  Icons.music_note,
                                  color: isSelected
                                      ? themeButtonColors
                                      : Colors.grey.shade600,
                                  size: 24,
                                ),
                      ),
                    )
                  else
                    Icon(
                      Icons.music_note,
                      color: isSelected
                          ? themeButtonColors
                          : Colors.grey.shade600,
                      size: 24,
                    ),
                  const SizedBox(width: 12),
                  // Song info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          song.songName,
                          style: ts_titleMediumBlack,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (song.tuneOf != null && song.tuneOf!.isNotEmpty)
                          Text(
                            'Tune of: ${song.tuneOf}',
                            style: ts_condensedMediumBlack.copyWith(
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  // Bawdy rating indicator (0 = clean, 3 = most bawdy)
                  Text(switch (song.bawdyRating) {
                    3 => '🔥🔥🔥🔥',
                    2 => '🌶️🌶️🌶️',
                    1 => '🍺🍺',
                    _ => '😇',
                  }, style: const TextStyle(fontSize: 18)),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  // ---------------------------------------------------------------------------
  // Song list (top section)
  // ---------------------------------------------------------------------------

  Widget _buildSongList(SongsPageController c, double height) {
    return Obx(() {
      if (c.isLoading.value) {
        return SizedBox(
          height: height,
          child: const Center(
            child: HcAppCircularProgressIndicator(key: Key('songs_loading')),
          ),
        );
      }

      if (c.allSongs.isEmpty) {
        return SizedBox(
          height: height,
          child: Center(
            child: Text('No songs synced yet.', style: ts_headingLarge),
          ),
        );
      }

      return SizedBox(
        height: height,
        child: Stack(
          children: <Widget>[
            // List behind the filter/search bar so the elevation shadow is visible
            Positioned.fill(
              top: 92, // filter bar (~44) + search bar (~48)
              child: RefreshIndicator(
                onRefresh: c.loadSongs,
                child: Obx(
                  () => ListView.builder(
                    padding: const EdgeInsets.only(top: 8),
                    controller: c.listScrollController,
                    itemCount: c.filteredSongs.length + 1,
                    itemBuilder: (BuildContext context, int index) {
                      if (index == c.filteredSongs.length) {
                        return const SizedBox(height: 8);
                      }
                      return _buildSongListItem(c, c.filteredSongs[index]);
                    },
                  ),
                ),
              ),
            ),
            // Filter bar + search bar on top
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[_buildBawdyFilterBar(c), _buildSearchBar(c)],
              ),
            ),
          ],
        ),
      );
    });
  }

  // ---------------------------------------------------------------------------
  // Lyrics panel (bottom section — collapsed preview / expanded full screen)
  // ---------------------------------------------------------------------------

  Widget _buildLyricsPanel(
    SongsPageController c,
    double collapsedHeight,
    double fullHeight,
  ) {
    return AnimatedBuilder(
      animation: c.lyricsExpansion,
      builder: (BuildContext context, Widget? child) {
        final double panelHeight =
            collapsedHeight +
            (fullHeight - collapsedHeight) * c.lyricsExpansion.value;

        return Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: panelHeight,
          child: GestureDetector(
            onTap: () {
              if (!c.isLyricsExpanded.value && c.selectedSong.value != null) {
                c.toggleLyricsExpanded();
              }
            },
            child: Obx(() {
              final bool expanded = c.isLyricsExpanded.value;
              final SongsModel? song = c.selectedSong.value;
              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(expanded ? 0 : 20),
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: song == null
                    ? _buildNoSongSelected()
                    : _buildLyricsContent(c, panelHeight),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildNoSongSelected() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.touch_app,
            color: Colors.white.withValues(alpha: 0.5),
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap a song to preview lyrics',
            style: ts_medium.copyWith(
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLyricsContent(SongsPageController c, double panelHeight) {
    return Obx(() {
      final bool expanded = c.isLyricsExpanded.value;
      final SongsModel? song = c.selectedSong.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Header bar with song name + expand/collapse icon
          _buildLyricsHeader(c),
          // Lyrics body
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: ShaderMask(
                shaderCallback: (Rect bounds) {
                  // Fade-out at bottom when collapsed to hint there's more
                  if (expanded) {
                    return const LinearGradient(
                      colors: <Color>[Colors.white, Colors.white],
                    ).createShader(bounds);
                  }
                  return LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      Colors.white,
                      Colors.white,
                      Colors.white.withValues(alpha: 0.0),
                    ],
                    stops: const <double>[0.0, 0.7, 1.0],
                  ).createShader(bounds);
                },
                blendMode: BlendMode.dstIn,
                child: SingleChildScrollView(
                  controller: c.lyricsScrollController,
                  physics: expanded
                      ? const AlwaysScrollableScrollPhysics()
                      : const NeverScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 40.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        if (expanded &&
                            song?.tuneOf != null &&
                            song!.tuneOf!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Text(
                              'Tune of: ${song.tuneOf}',
                              style: ts_titleMedium.copyWith(
                                color: Colors.white,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        Text(
                          song?.lyrics ?? '',
                          style: ts_body.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            height: 1.6,
                          ),
                        ),
                        // Song image (only when expanded and imageUrl exists)
                        if (expanded &&
                            song?.imageUrl != null &&
                            song!.imageUrl!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 20.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                song.imageUrl!,
                                fit: BoxFit.contain,
                                width: double.infinity,
                                errorBuilder:
                                    (
                                      BuildContext context,
                                      Object error,
                                      StackTrace? stackTrace,
                                    ) {
                                      return const SizedBox.shrink();
                                    },
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // "Tap to expand" hint when collapsed
          if (!expanded)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Center(
                child: Icon(
                  Icons.keyboard_arrow_up,
                  color: Colors.white.withValues(alpha: 0.5),
                  size: 28,
                ),
              ),
            ),
          // Audio player controls (only when expanded and audioUrl exists)
          if (expanded &&
              c.audioPlayer != null &&
              song?.audioUrl != null &&
              song!.audioUrl!.isNotEmpty)
            _buildAudioPlayer(c),
        ],
      );
    });
  }

  Widget _buildAudioPlayer(SongsPageController c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Seek slider + timestamps
          _buildSeekBar(c),
          const SizedBox(height: 4),
          // Transport controls row
          _buildTransportControls(c),
          const SizedBox(height: 4),
          // Speed + Volume row
          _buildSpeedAndVolumeControls(c),
        ],
      ),
    );
  }

  Widget _buildSeekBar(SongsPageController c) {
    return StreamBuilder<Duration>(
      stream: c.audioPlayer!.positionStream,
      builder: (BuildContext context, AsyncSnapshot<Duration> posSnapshot) {
        final Duration position = posSnapshot.data ?? Duration.zero;
        final Duration total = c.audioPlayer!.duration ?? Duration.zero;
        final double maxMs = total.inMilliseconds.toDouble().clamp(
          1,
          double.infinity,
        );
        return Column(
          children: <Widget>[
            SliderTheme(
              data: SliderThemeData(
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                trackHeight: 3,
                activeTrackColor: themeButtonColors,
                inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
                thumbColor: Colors.white,
              ),
              child: Slider(
                min: 0,
                max: maxMs,
                value: position.inMilliseconds.toDouble().clamp(0, maxMs),
                onChanged: (double value) {
                  unawaited(
                    c.audioPlayer!.seek(Duration(milliseconds: value.toInt())),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    c.formatDuration(position),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    c.formatDuration(total),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTransportControls(SongsPageController c) {
    return StreamBuilder<PlayerState>(
      stream: c.audioPlayer!.playerStateStream,
      builder: (BuildContext context, AsyncSnapshot<PlayerState> snapshot) {
        final PlayerState? playerState = snapshot.data;
        final bool isPlaying = playerState?.playing ?? false;
        final ProcessingState processingState =
            playerState?.processingState ?? ProcessingState.idle;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Loop mode
            StreamBuilder<LoopMode>(
              stream: c.audioPlayer!.loopModeStream,
              builder:
                  (BuildContext context, AsyncSnapshot<LoopMode> loopSnap) {
                    final LoopMode loopMode = loopSnap.data ?? LoopMode.off;
                    return IconButton(
                      iconSize: 24,
                      icon: Icon(
                        loopMode == LoopMode.one
                            ? Icons.repeat_one
                            : Icons.repeat,
                        color: loopMode == LoopMode.off
                            ? Colors.white.withValues(alpha: 0.4)
                            : themeButtonColors,
                      ),
                      tooltip: 'Loop: ${loopMode.name}',
                      onPressed: () {
                        final LoopMode next = switch (loopMode) {
                          LoopMode.off => LoopMode.one,
                          LoopMode.one => LoopMode.all,
                          LoopMode.all => LoopMode.off,
                        };
                        unawaited(c.audioPlayer!.setLoopMode(next));
                      },
                    );
                  },
            ),
            // Rewind 10s
            IconButton(
              iconSize: 28,
              icon: const Icon(Icons.replay_10, color: Colors.white),
              tooltip: 'Rewind 10s',
              onPressed: () {
                final Duration pos = c.audioPlayer!.position;
                unawaited(
                  c.audioPlayer!.seek(
                    Duration(
                      milliseconds: (pos.inMilliseconds - 10000).clamp(
                        0,
                        double.maxFinite.toInt(),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            // Stop
            IconButton(
              iconSize: 28,
              icon: const Icon(Icons.stop_circle_outlined, color: Colors.white),
              tooltip: 'Stop',
              onPressed: () async {
                await c.audioPlayer!.stop();
                await c.audioPlayer!.seek(Duration.zero);
              },
            ),
            // Play / Pause / Replay
            IconButton(
              iconSize: 44,
              icon: Icon(
                processingState == ProcessingState.completed
                    ? Icons.replay_circle_filled
                    : isPlaying
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_filled,
                color: Colors.white,
              ),
              tooltip: processingState == ProcessingState.completed
                  ? 'Replay'
                  : isPlaying
                  ? 'Pause'
                  : 'Play',
              onPressed: () async {
                if (processingState == ProcessingState.completed) {
                  await c.audioPlayer!.seek(Duration.zero);
                  await c.audioPlayer!.play();
                } else if (isPlaying) {
                  await c.audioPlayer!.pause();
                } else {
                  await c.audioPlayer!.play();
                }
              },
            ),
            // Forward 10s
            IconButton(
              iconSize: 28,
              icon: const Icon(Icons.forward_10, color: Colors.white),
              tooltip: 'Forward 10s',
              onPressed: () {
                final Duration pos = c.audioPlayer!.position;
                final Duration total = c.audioPlayer!.duration ?? Duration.zero;
                unawaited(
                  c.audioPlayer!.seek(
                    Duration(
                      milliseconds: (pos.inMilliseconds + 10000).clamp(
                        0,
                        total.inMilliseconds,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildSpeedAndVolumeControls(SongsPageController c) {
    return Row(
      children: <Widget>[
        // Speed control
        Expanded(
          child: StreamBuilder<double>(
            stream: c.audioPlayer!.speedStream,
            builder: (BuildContext context, AsyncSnapshot<double> speedSnap) {
              final double speed = speedSnap.data ?? 1.0;
              return Row(
                children: <Widget>[
                  Icon(
                    Icons.speed,
                    color: Colors.white.withValues(alpha: 0.7),
                    size: 18,
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 5,
                        ),
                        trackHeight: 2,
                        activeTrackColor: themeButtonColors,
                        inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
                        thumbColor: Colors.white,
                      ),
                      child: Slider(
                        min: 0.5,
                        max: 2.0,
                        value: speed,
                        onChanged: (double value) {
                          unawaited(
                            c.audioPlayer!.setSpeed(
                              (value * 4).roundToDouble() /
                                  4, // snap to 0.25 increments
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 36,
                    child: Text(
                      '${speed.toStringAsFixed(2)}x',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        // Volume control
        Expanded(
          child: StreamBuilder<double>(
            stream: c.audioPlayer!.volumeStream,
            builder: (BuildContext context, AsyncSnapshot<double> volSnap) {
              final double volume = volSnap.data ?? 1.0;
              return Row(
                children: <Widget>[
                  Icon(
                    volume == 0
                        ? Icons.volume_off
                        : volume < 0.5
                        ? Icons.volume_down
                        : Icons.volume_up,
                    color: Colors.white.withValues(alpha: 0.7),
                    size: 18,
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 5,
                        ),
                        trackHeight: 2,
                        activeTrackColor: themeButtonColors,
                        inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
                        thumbColor: Colors.white,
                      ),
                      child: Slider(
                        min: 0.0,
                        max: 1.0,
                        value: volume,
                        onChanged: (double value) {
                          unawaited(c.audioPlayer!.setVolume(value));
                        },
                      ),
                    ),
                  ),
                  // Mute toggle
                  IconButton(
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      volume == 0 ? Icons.volume_up : Icons.volume_off,
                      color: Colors.white.withValues(alpha: 0.5),
                      size: 16,
                    ),
                    tooltip: volume == 0 ? 'Unmute' : 'Mute',
                    onPressed: () {
                      unawaited(
                        c.audioPlayer!.setVolume(volume == 0 ? 1.0 : 0.0),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLyricsHeader(SongsPageController c) {
    return Obx(() {
      final SongsModel? song = c.selectedSong.value;
      final bool expanded = c.isLyricsExpanded.value;

      return Padding(
        padding: const EdgeInsets.fromLTRB(20.0, 12.0, 8.0, 4.0),
        child: Row(
          children: <Widget>[
            Icon(
              Icons.music_note,
              color: themeButtonColors.withValues(alpha: 0.8),
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                song?.songName ?? '',
                style: ts_titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (expanded)
              IconButton(
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white,
                  size: 28,
                ),
                tooltip: 'Collapse lyrics',
                onPressed: c.toggleLyricsExpanded,
              ),
          ],
        ),
      );
    });
  }
}
