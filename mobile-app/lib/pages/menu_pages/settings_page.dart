import 'package:harrier_central/imports.dart';

/// Settings — device + account preferences split out of My Profile
/// (2026-07-31): distance units, camera behaviour, GPS tracking quality.
/// The auto-display-runs radius stays on My Profile.
class SettingsPageController extends GetxController {
  final RxInt distancePreference = 0.obs;
  final RxBool savePhotosToCameraRoll = true.obs;
  final RxInt trackingQuality = (getIntPref(IntPrefsEnum.trackingQuality) ?? 2)
      .obs;
  final RxBool isSaving = false.obs;
  final RxBool isLoading = true.obs;

  /// The platform-wide chat rooms this hasher's roles put them in, as the
  /// SERVER lists them — including ones they have opted out of, which the
  /// chat list hides. Without the opted-out ones this screen could not offer
  /// a way back in.
  final RxList<ChatRoom> chatRooms = <ChatRoom>[].obs;
  final RxBool chatRoomsLoading = true.obs;
  final RxBool chatRoomsFailed = false.obs;
  final RxInt savingRoomType = (-1).obs;

  HashersModel? _hasher;

  /// The bits of hasherPreferences this page owns. Everything else (the
  /// auto-display radius on My Profile, photo sharing, debug harvest, ...)
  /// must ride through a save untouched: hcapp_addEditUser overwrites the
  /// whole Preferences column when @preferences is supplied, so the value is
  /// composed read-modify-write from the stored bitfield.
  static const int _ownedMask =
      hasherPref_distanceMeasuredIn | hasherPref_cameraRollSaveDisabled;

  @override
  void onInit() {
    super.onInit();
    final int stored = getIntPref(IntPrefsEnum.hasherPreferences) ?? 0;
    distancePreference.value = stored & hasherPref_distanceMeasuredIn;
    savePhotosToCameraRoll.value =
        (stored & hasherPref_cameraRollSaveDisabled) == 0;
    unawaited(_loadHasher());
    unawaited(loadChatRooms());
  }

  Future<void> loadChatRooms() async {
    chatRoomsLoading.value = true;
    final List<ChatRoom>? rooms =
        await ChatRoomService.fetchRooms(includeOptedOut: true);
    chatRoomsFailed.value = rooms == null;
    chatRooms.value = rooms ?? <ChatRoom>[];
    chatRoomsLoading.value = false;
  }

  /// Pin or unpin a room from the settings console. Same optimistic-then-
  /// revert shape as [setParticipation].
  Future<void> toggleRoomPin(ChatRoom room) async {
    final int index = chatRooms.indexWhere((r) => r.roomType == room.roomType);
    if (index < 0) return;
    final bool next = !room.pinned;

    void apply(bool value) => chatRooms[index] = ChatRoom(
      roomType: room.roomType,
      roomName: room.roomName,
      unreadCount: room.unreadCount,
      participationState: room.participationState,
      pinned: value,
    );

    savingRoomType.value = room.roomType;
    apply(next);
    final bool ok = await ChatPinService.setPin(
      roomType: room.roomType,
      pinned: next,
    );
    if (!ok) {
      apply(!next);
      Get.snackbar(
        'Not saved',
        'That chat room could not be ${next ? 'pinned' : 'unpinned'}. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
    savingRoomType.value = -1;
  }

  /// Optimistic, then reconciled: the chip moves at once because a round trip
  /// makes a settings toggle feel broken, but a failure puts it back rather
  /// than leaving the screen claiming something the server never stored.
  Future<void> setParticipation(ChatRoom room, int state) async {
    if (room.participationState == state) return;
    final int previous = room.participationState;
    final int index = chatRooms.indexWhere((r) => r.roomType == room.roomType);
    if (index < 0) return;

    void apply(int value) => chatRooms[index] = ChatRoom(
      roomType: room.roomType,
      roomName: room.roomName,
      unreadCount: room.unreadCount,
      participationState: value,
      pinned: room.pinned,
    );

    savingRoomType.value = room.roomType;
    apply(state);
    final bool ok = await ChatRoomService.setParticipation(
      roomType: room.roomType,
      participationState: state,
    );
    if (!ok) {
      apply(previous);
      Get.snackbar(
        'Not saved',
        'That chat room setting could not be saved. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
    savingRoomType.value = -1;
  }

  /// addEditUser requires the profile identity fields — read them from the
  /// local DB (the same source My Profile uses) so a preferences save can
  /// never blank the user's name or photo.
  Future<void> _loadHasher() async {
    try {
      final List<Map<String, dynamic>> rows = await database.rawQuery('''
        SELECT h.* FROM ${EnumDataTables.hashers.commonTableName} h
        WHERE h.${tableModel.hashersTableHelper.colHasherId} = "$currentUserId"
      ''');
      if (rows.isNotEmpty) {
        _hasher = HashersModel.fromJson(rows.first);
      }
    } catch (e, s) {
      BootLogger.logError('[SettingsPageController._loadHasher]', e, s);
    }
    isLoading.value = false;
  }

  Future<void> setDistancePreference(int? value) async {
    final int previous = distancePreference.value;
    distancePreference.value = value ?? 0;
    await _savePreferences(onFailureDistance: previous);
  }

  Future<void> setSavePhotosToCameraRoll(bool value) async {
    final bool previous = savePhotosToCameraRoll.value;
    savePhotosToCameraRoll.value = value;
    await _savePreferences(onFailureCamera: previous);
  }

  Future<void> setTrackingQuality(int value) async {
    trackingQuality.value = value;
    await setIntPref(IntPrefsEnum.trackingQuality, value);
  }

  Future<void> _savePreferences({
    int? onFailureDistance,
    bool? onFailureCamera,
  }) async {
    final HashersModel? h = _hasher;
    if (h == null) return; // still loading / no row — controls are absorbed
    isSaving.value = true;

    final int stored = getIntPref(IntPrefsEnum.hasherPreferences) ?? 0;
    final int newPrefs =
        (stored & ~_ownedMask) |
        distancePreference.value |
        (savePhotosToCameraRoll.value ? 0 : hasherPref_cameraRollSaveDisabled);

    final String responseBody = await HashersService().addEditUser(
      targetUserId: h.hasherId,
      firstName: h.firstName ?? '',
      lastName: h.lastName ?? '',
      email: getStringPref(StringPrefsEnum.email) ?? '',
      hashName: h.hashName ?? '',
      photo: h.photo ?? '',
      eventId: GUID_EMPTY,
      kennelId: GUID_EMPTY,
      historicalTotalRunCount: '-1',
      historicalHaringCount: '-1',
      historicalCountIsEstimate: false,
      preferences: newPrefs,
      nameDisplayPreference: -1,
    );

    if (!responseBody.startsWith(ERROR_PREFIX)) {
      await setIntPref(IntPrefsEnum.hasherPreferences, newPrefs);
    } else {
      if (onFailureDistance != null) {
        distancePreference.value = onFailureDistance;
      }
      if (onFailureCamera != null) {
        savePhotosToCameraRoll.value = onFailureCamera;
      }
      await Utilities.showAlert(
        'Settings Not Updated',
        'There was a problem updating your settings. Please ensure you are connected to the Internet and try again later.',
        'OK',
      );
    }
    isSaving.value = false;
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  /// The hasher's platform-wide chat rooms and how they take part in each.
  ///
  /// Drawn only when there is something to draw: most hashers hold no role
  /// and belong to no room, and an empty "Chat Rooms" heading would be a
  /// section that never does anything. A failure says so rather than showing
  /// an empty list, which would read as "you were removed from your rooms".
  Widget _chatRoomsSection(SettingsPageController controller) {
    if (controller.chatRoomsLoading.value) return const SizedBox.shrink();
    if (!controller.chatRoomsFailed.value && controller.chatRooms.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        const FancyDivider(
          key: Key('settings_chat_rooms_divider'),
          innerColor: Colors.white,
          topMargin: 20.0,
          bottomMargin: 10.0,
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Chat Rooms',
            style: ts_headingLarge,
            textAlign: TextAlign.center,
          ),
        ),
        if (controller.chatRoomsFailed.value) ...<Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              'Your chat rooms could not be loaded. A connection is required '
              'to change these settings.',
              style: ts_body,
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: Text('Try again', style: ts_button),
              onPressed: () => unawaited(controller.loadChatRooms()),
            ),
          ),
        ] else ...<Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8, bottom: 12),
            child: Text(
              'These rooms come with the roles you hold. Choose how much you '
              'want to hear from each one.',
              style: ts_body,
              textAlign: TextAlign.center,
            ),
          ),
          for (final ChatRoom room in controller.chatRooms)
            _chatRoomRow(controller, room),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _chatRoomRow(SettingsPageController controller, ChatRoom room) {
    final bool busy =
        controller.savingRoomType.value == room.roomType ||
        controller.isLoading.value;

    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          // The name and the pin sit together, because this screen is the
          // durable way BACK: an unpinned room only reappears in the chat list
          // when it has unread, so for a quiet room there would otherwise be
          // nowhere to re-pin it (James, 2026-09-15).
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            children: <Widget>[
              Text(room.roomName, style: ts_body, textAlign: TextAlign.center),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: room.pinned ? 'Unpin from the chat list'
                                     : 'Pin to the top of the chat list',
                icon: Icon(
                  room.pinned ? Icons.push_pin : Icons.push_pin_outlined,
                  size: 20,
                  color: room.pinned ? Colors.white : Colors.white60,
                ),
                onPressed: () => unawaited(controller.toggleRoomPin(room)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Wrap, not Row: three labelled choices are wider than a phone at a
          // large text size, and a Wrap takes a second line where a Row
          // overflows.
          AbsorbPointer(
            absorbing: busy,
            child: Opacity(
              opacity: busy ? 0.5 : 1.0,
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  _participationChip(controller, room, kRoomParticipatePush,
                      'Notify me'),
                  _participationChip(controller, room,
                      kRoomParticipateBadgesOnly, 'Badge only'),
                  _participationChip(controller, room, kRoomOptOut, 'Leave'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _participationChip(
    SettingsPageController controller,
    ChatRoom room,
    int state,
    String label,
  ) {
    final bool selected = room.participationState == state;
    return ChoiceChip(
      label: Text(
        label,
        // The chip sits on the jungle background: an unselected chip is dark,
        // so its label has to be light. ts_footnoteBlack and friends are
        // black and would vanish here.
        style: ts_body.copyWith(
          fontSize: 13,
          color: selected ? Colors.white : Colors.white70,
        ),
      ),
      selected: selected,
      showCheckmark: false,
      selectedColor: hc_red,
      backgroundColor: Colors.black.withValues(alpha: 0.28),
      side: BorderSide(color: selected ? hc_red : Colors.white24),
      onSelected: (_) =>
          unawaited(controller.setParticipation(room, state)),
    );
  }

  Widget _sectionSpinner(SettingsPageController controller) {
    if (!controller.isSaving.value) return const SizedBox.shrink();
    return const Padding(
      padding: EdgeInsets.only(left: 8.0),
      child: SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _trackingQualityOption(
    SettingsPageController controller,
    int value,
    String label,
    String sub,
    int boltCount,
  ) {
    final bool isSelected = controller.trackingQuality.value == value;
    return GestureDetector(
      onTap: () => unawaited(controller.setTrackingQuality(value)),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? themeBackgroundColor.withValues(alpha: 0.12)
              : Colors.transparent,
          border: Border.all(
            color: isSelected ? themeBackgroundColor : Colors.grey.shade400,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? themeBackgroundColor : Colors.grey,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    sub,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: List.generate(
                3,
                (i) => Icon(
                  Icons.bolt,
                  size: 18,
                  color: i < boltCount
                      ? Colors.amber.shade700
                      : Colors.grey.shade300,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final SettingsPageController controller = Get.put(SettingsPageController());
    final AppBar appBar = AppBar(
      centerTitle: true,
      backgroundColor: themeAppBarBackground,
      iconTheme: const IconThemeData(color: Colors.white, size: 28.0),
      title: Text('Settings', style: ts_appBarTitle),
    );
    return Stack(
      children: <Widget>[
        SizedBox(
          height: MediaQuery.sizeOf(context).height,
          width: MediaQuery.sizeOf(context).width,
        ),
        Positioned(
          top: 0,
          left: 0,
          width: MediaQuery.sizeOf(context).width,
          height: MediaQuery.sizeOf(context).height,
          child: AppScaffold(
            appBar: appBar,
            body: Container(
              decoration: Backgrounds.defaultHcBackground(),
              height:
                  MediaQuery.sizeOf(context).height -
                  appBar.preferredSize.height,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.only(top: 30, left: 20, right: 20),
                  child: Obx(
                    () => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        // ------------------------- Distance Preference
                        AbsorbPointer(
                          absorbing:
                              controller.isSaving.value ||
                              controller.isLoading.value,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.yellow[100],
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                            child: RadioGroup(
                              groupValue: controller.distancePreference.value,
                              onChanged: (int? v) =>
                                  unawaited(controller.setDistancePreference(v)),
                              child: Column(
                                children: <Widget>[
                                  const SizedBox(height: 10, width: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Text(
                                        'Distance Preference',
                                        style: ts_headingBlack,
                                      ),
                                      _sectionSpinner(controller),
                                    ],
                                  ),
                                  const SizedBox(height: 10, width: 10),
                                  Row(
                                    children: <Widget>[
                                      Radio<int>(value: 0),
                                      const Text(
                                        'Auto',
                                        style: TextStyle(fontSize: 16.0),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: <Widget>[
                                      Radio<int>(value: 2),
                                      const Text(
                                        'Kilometers',
                                        style: TextStyle(fontSize: 16.0),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: <Widget>[
                                      Radio<int>(value: 3),
                                      const Text(
                                        'Miles',
                                        style: TextStyle(fontSize: 16.0),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // ------------------------- Camera Behaviour
                        const FancyDivider(
                          key: Key('settings_camera_divider'),
                          innerColor: Colors.white,
                          topMargin: 20.0,
                          bottomMargin: 10.0,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Camera Behavior',
                                style: ts_headingLarge,
                                textAlign: TextAlign.center,
                              ),
                              _sectionSpinner(controller),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 8.0,
                            right: 8.0,
                            bottom: 12.0,
                          ),
                          child: Text(
                            'Harrier Central saves your trail photos to our backend server where they are available to be shared. You can also save these photos directly to your phone with the setting below.',
                            style: ts_body,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              AbsorbPointer(
                                absorbing:
                                    controller.isSaving.value ||
                                    controller.isLoading.value,
                                child: Transform.scale(
                                  scale: 1.4,
                                  child: Switch(
                                    value:
                                        controller.savePhotosToCameraRoll.value,
                                    onChanged: (bool value) => unawaited(
                                      controller.setSavePhotosToCameraRoll(
                                        value,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Save photos to phone',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'AvenirNextRegular',
                                  fontSize: 20.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // ------------------------- GPS Tracking Quality
                        const FancyDivider(
                          key: Key('settings_tracking_divider'),
                          innerColor: Colors.white,
                          topMargin: 10.0,
                          bottomMargin: 10.0,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 4.0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.power,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'GPS Tracking Quality',
                                style: ts_headingLarge,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 4.0,
                          ),
                          child: Text(
                            'Higher accuracy gives a more detailed trail track but drains battery faster.',
                            style: ts_body,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(bottom: 40.0),
                          decoration: BoxDecoration(
                            color: Colors.yellow[100],
                            borderRadius: BorderRadius.circular(5.0),
                          ),
                          child: Column(
                            children: [
                              _trackingQualityOption(
                                controller,
                                2,
                                'Best',
                                'Finest GPS detail — highest battery use',
                                3,
                              ),
                              _trackingQualityOption(
                                controller,
                                1,
                                'Balanced',
                                'Good accuracy — moderate battery use',
                                2,
                              ),
                              _trackingQualityOption(
                                controller,
                                0,
                                'Power Saver',
                                'Coarser track — lowest battery use',
                                1,
                              ),
                            ],
                          ),
                        ),
                        // ------------------------- Chat Rooms
                        _chatRoomsSection(controller),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        OfflineModeRibbon(
          lastSync: getDatePref(DatePrefsEnum.lastSuccessfulUserDataSync),
          ribbonImage: 'images/icons/offline_mode.png',
          refreshFunction: () {},
        ),
      ],
    );
  }
}
