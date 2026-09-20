import 'package:harrier_central/imports.dart';

/// Settings — device + account preferences split out of My Profile
/// (2026-07-31): distance units, camera behaviour, GPS tracking quality.
/// The auto-display-runs radius stays on My Profile.
class SettingsPageController extends GetxController {
  final RxInt distancePreference = 0.obs;

  /// "Automatically show all runs within N" — moved here from My Account on
  /// 2026-09-20, which is now account-only. It shares the Preferences
  /// bitfield with the distance UNITS above (rung 0x3C), which is why this
  /// page owns both and why _ownedMask must cover them together: one
  /// read-modify-write, one save, no way for the two to overwrite each other.
  final RxInt autoRunPreference = 0.obs;
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
      hasherPref_distanceMeasuredIn |
      hasherPref_cameraRollSaveDisabled |
      hasherPref_distanceForAutoDisplay;

  @override
  void onInit() {
    super.onInit();
    final int stored = getIntPref(IntPrefsEnum.hasherPreferences) ?? 0;
    distancePreference.value = stored & hasherPref_distanceMeasuredIn;
    autoRunPreference.value = stored & hasherPref_distanceForAutoDisplay;
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

  Future<void> setAutoRunPreference(int? value) async {
    final int previous = autoRunPreference.value;
    autoRunPreference.value = value ?? 0;
    await _savePreferences(onFailureAutoRun: previous);
  }

  Future<void> enableLocationServices() async {
    bool success = false;
    {
      final PermissionStatus ps = await Permission.location.request();

      if (ps.isPermanentlyDenied) {
        final bool? openSettings = await Utilities.showAlert(
          'Phone Settings',
          'You must change the location permissions in the phone\'s settings panel for Harrier Central.\r\n\r\nOnce you have done this, please close Settings and come back to Harrier Central.',
          'Open Settings',
          showCancelButton: true,
          cancelButtonText: 'Cancel',
        );

        if (openSettings ?? false) {
          await openAppSettings();

          success =
              await Utilities.showAlert(
                'Success?',
                'Were you able to change the settings to enable location services?',
                'Yes',
                showCancelButton: true,
                cancelButtonText: 'No',
              ) ??
              false;
        }
      }

      if ((ps.isGranted) || success) {
        if (await Permission.location.serviceStatus.isEnabled) {
          appModel.hasLocationPermissions = true;
          final locService = Get.isRegistered<LocationService>()
              ? Get.find<LocationService>()
              : Get.put(LocationService());
          if (locService.initialized) {
            await Utilities.showAlert(
              'Location Services Enabled',
              'Location Services have been enabled.',
              'OK',
            );
          }
        }
      } else {
        await Utilities.showAlert(
          'Location Services problem',
          'Harrier Central was unable to confirm that Location Services have been enabled.\r\n\r\nPlease use the Settings panel to enable Location Services for Harrier Centra. Once you have done this, please close and restart Harrier Central.',
          'Open Settings',
          showCancelButton: true,
          cancelButtonText: 'Cancel',
        );

        await openAppSettings();
      }
    }

    await Utilities.showAlert(
      'Location preferences updated',
      'Your location preferences have been updated.\r\n\r\nYou may have to wait a few minutes or open and close the app before your current location is used by the app.',
      'OK',
    );
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
    int? onFailureAutoRun,
    bool? onFailureCamera,
  }) async {
    final HashersModel? h = _hasher;
    if (h == null) return; // still loading / no row — controls are absorbed
    isSaving.value = true;

    final int stored = getIntPref(IntPrefsEnum.hasherPreferences) ?? 0;
    final int newPrefs =
        (stored & ~_ownedMask) |
        distancePreference.value |
        autoRunPreference.value |
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
      if (onFailureAutoRun != null) {
        autoRunPreference.value = onFailureAutoRun;
      }
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

  /// "Automatically show all runs within N" — the radius that puts nearby
  /// runs on the list without being asked.
  ///
  /// Moved here from My Account on 2026-09-20 (James: "the only things left
  /// in My Account are account related"). It belongs beside the distance
  /// UNITS, which it is labelled in, and it shares their bitfield.
  ///
  /// Without location permission the radius is meaningless, so the section
  /// asks for permission instead of offering a setting that cannot work.
  /// miles or kilometres, from the hasher's own units bit. Lifted from
  /// HasherProfilePage with the radius it labels (2026-09-20) so this page
  /// does not reach into that one.
  String _distanceUnits(int distancePreference) =>
      distancePreference == 2 ? 'kilometers' : 'miles';

  Widget _autoShowRunsSection(SettingsPageController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        const FancyDivider(
          key: Key('settings_auto_show_runs_divider'),
          innerColor: Colors.white,
          topMargin: 20.0,
          bottomMargin: 10.0,
        ),
        if (!appModel.hasLocationPermissions) ...<Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('Distance to Runs', style: ts_headingLarge,
                textAlign: TextAlign.center),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Harrier Central can help you find runs that are nearby. In '
              'order to do this, the app needs to have access to the phone\'s '
              'current location, but currently location is disabled for this '
              'app.\r\n\r\nTo start using the distance features of Harrier '
              'Central please press the "Use Location" button below and follow '
              'the prompts.',
              style: ts_body,
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 22.0, bottom: 20.0),
            child: ElevatedButton(
              onPressed: () => unawaited(controller.enableLocationServices()),
              child: Text('Use Location', style: ts_button),
            ),
          ),
        ] else
          AbsorbPointer(
            absorbing:
                controller.isSaving.value || controller.isLoading.value,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.yellow[100],
                borderRadius: BorderRadius.circular(5.0),
              ),
              child: RadioGroup(
                groupValue: controller.autoRunPreference.value,
                onChanged: (int? v) =>
                    unawaited(controller.setAutoRunPreference(v)),
                child: Column(
                  children: <Widget>[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text('Automatically Show Runs',
                            style: ts_headingBlack),
                        _sectionSpinner(controller),
                      ],
                    ),
                    const Row(
                      children: <Widget>[
                        Radio<int>(value: hasherPref_0),
                        Text('Do not auto show runs'),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 12, top: 6),
                      child: Row(
                        children: <Widget>[
                          Text('Or...   ...Automatically Show All Runs Within...',
                              style: ts_footnoteBlack),
                        ],
                      ),
                    ),
                    // The label carries the hasher's own units, so changing
                    // miles/kilometres above relabels these without a reload.
                    for (final MapEntry<int, int> option
                        in const <int, int>{
                          hasherPref_10: 10,
                          hasherPref_25: 25,
                          hasherPref_50: 50,
                          hasherPref_75: 75,
                          hasherPref_100: 100,
                          hasherPref_150: 150,
                          hasherPref_250: 250,
                          hasherPref_500: 500,
                        }.entries)
                      Row(
                        children: <Widget>[
                          Radio<int>(value: option.key),
                          Text(
                            '${option.value} '
                            '${_distanceUnits(controller.distancePreference.value)}',
                          ),
                        ],
                      ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
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
              // The room's coin, so this console and the chat list name the
              // same room the same way.
              ChatRoomCoin(iconUrl: room.roomIcon, size: 32),
              // Tappable, so a quiet UNPINNED room can still be opened from
              // here — otherwise the only way in would be to pin it first and
              // go looking in the chat list (James, 2026-09-15).
              InkWell(
                onTap: () => Get.to(
                  () => ChatScaffold.room(
                    roomType: room.roomType,
                    title: room.roomName,
                    key: UniqueKey(),
                  ),
                ),
                child: Text(
                  room.roomName,
                  style: ts_body.copyWith(
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white54,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              // Big enough to read as a control rather than decoration, and
              // on its own dark disc so it stands off the leaves.
              Material(
                color: Colors.transparent,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => unawaited(controller.toggleRoomPin(room)),
                  child: Tooltip(
                    message: room.pinned
                        ? 'Pinned — tap to unpin'
                        : 'Not pinned — tap to pin',
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.45),
                        border: Border.all(
                          color: room.pinned ? Colors.white : Colors.white38,
                          width: room.pinned ? 2 : 1,
                        ),
                      ),
                      child: PinGlyph(pinned: room.pinned, size: 22),
                    ),
                  ),
                ),
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

  /// Deliberately NOT a ChoiceChip. The app's chip theme overrode both the
  /// background and the label colour, so the unselected state came out grey
  /// text on a grey pill — unreadable, and on the jungle background worse
  /// (James, 2026-09-15). Built from a Container so the contrast is ours.
  Widget _participationChip(
    SettingsPageController controller,
    ChatRoom room,
    int state,
    String label,
  ) {
    final bool selected = room.participationState == state;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => unawaited(controller.setParticipation(room, state)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            // Selected is the app's red with white on it; unselected is a
            // near-solid dark pill so white text reads against the leaves.
            color: selected ? hc_red : Colors.black.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? Colors.white : Colors.white54,
              width: selected ? 2 : 1,
            ),
          ),
          child: Text(
            label,
            style: ts_body.copyWith(
              fontSize: 14,
              color: Colors.white,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
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
                        _autoShowRunsSection(controller),
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
