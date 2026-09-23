// ignore_for_file: constant_identifier_names

import 'package:harrier_central/data/services/gdpr_delete_service.dart';
import 'package:harrier_central/data/services/get_invite_code_service.dart';
import 'package:harrier_central/imports.dart';

enum EnumMyProfilePageType { myProfile, anyHasherProfile, newHasherProfile }

/// State for the profile page in its three guises (my account, another
/// hasher, a new hasher): the loaded HashersModel, the six text fields with
/// their dirty tracking, the name preference, the photo, the historical
/// run counts, and the save / invite-code / run-history / delete flows.
///
/// Migrated from a 1570-line State on 2026-09-23. The dirty rule is a pure
/// static ([computeDirty]) with a unit test; every await is followed by an
/// isClosed check. Navigation and the two context-bound dialogs stay in the
/// page.
class HasherProfileController extends GetxController {
  HasherProfileController({
    required this.dataContext,
    required this.pageType,
    required this.hasherId,
    required this.eventId,
    required this.kennelId,
    required this.hashNameFromSearch,
  });

  final EnumDataContext dataContext;
  final EnumMyProfilePageType pageType;
  final String hasherId;
  final String eventId;
  final String kennelId;
  final String hashNameFromSearch;

  static String tagFor(EnumMyProfilePageType pageType, String hasherId) =>
      'profile-${pageType.name}-$hasherId';

  final GlobalKey<FormState> profileFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> runCountFormKey = GlobalKey<FormState>();

  final RxBool autoValidate = false.obs;
  final RxBool isLoading = true.obs;
  final RxBool isDirty = false.obs;
  final RxBool addAsKennelFollower = false.obs;
  final RxBool userRunHistoryLoading = false.obs;
  final RxInt nameDisplayPreference = 1.obs;
  final RxString newPhoto = bundledAvatarUrl(
    Random.secure().nextInt(49) + 1,
  ).obs;
  final Rxn<bool> historicalCountIsEstimateWidget = Rxn<bool>();

  int? _historicalTotalRunCount;
  int? _historicalHaringCount;
  bool? _historicalCountIsEstimate;
  String? email = getStringPref(StringPrefsEnum.email);
  String photoPrefix = '';
  HashersModel hasher = HashersModel.empty();

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController hashNameController = TextEditingController();
  final TextEditingController previousRunCountController =
      TextEditingController();
  final TextEditingController previousHaringCountController =
      TextEditingController();

  late final List<TextEditingController> _fields = <TextEditingController>[
    firstNameController,
    lastNameController,
    emailController,
    hashNameController,
    previousRunCountController,
    previousHaringCountController,
  ];

  @override
  void onInit() {
    super.onInit();
    for (final TextEditingController f in _fields) {
      f.addListener(checkDirty);
    }
    unawaited(_initializeValues());
  }

  @override
  void onClose() {
    for (final TextEditingController f in _fields) {
      f.removeListener(checkDirty);
      f.dispose();
    }
    super.onClose();
  }

  Future<void> _initializeValues() async {
    final isGranted = await Permission.location.isGranted;
    if (isClosed) return;
    appModel.hasLocationPermissions = isGranted;

    if (hashNameFromSearch.isNotEmpty) {
      hashNameController.text = hashNameFromSearch;
    }
    if (pageType != EnumMyProfilePageType.newHasherProfile) {
      await refreshUserDataFromTable(true);
      photoPrefix = hasherId;
    } else {
      if (kennelId.isNotEmpty && kennelId != GUID_EMPTY) {
        addAsKennelFollower.value = true;
      }
      hasher = HashersModel.empty();
      photoPrefix = 'newHcUser_${DateTime.now().microsecondsSinceEpoch}';
      isLoading.value = false;
    }
  }

  Future<void> refreshUserDataFromTable(bool forceRefresh) async {
    String query =
        '''
        SELECT 
          h.*
          FROM ${EnumDataTables.hashers.commonTableName} h
          WHERE h.hasherId = "$hasherId"

          ''';

    if (forceRefresh) {
      // always sync user data before editing
      // TODO(James): Make this AppDomainType correct
      switch (dataContext) {
        case EnumDataContext.event:
          await tableModel.syncEventAdminService.updateFromBackend(
            EnumDataTables.hashers.flag |
                EnumDataTables.hasherKennelMap.flag |
                EnumDataTables.hasherEventMap.flag,
            true,
            eventId,
          );
          break;
        case EnumDataContext.user:
          await tableModel.syncUserDataService.updateFromBackend(
            EnumDataTables.hashers.flag,
            true,
            debugText: 'hasher_profile_page: Hashers',
          );
          break;
        case EnumDataContext.kennel:
          await tableModel.syncKennelAdminService.updateFromBackend(
            EnumDataTables.hashers.flag | EnumDataTables.hasherKennelMap.flag,
            true,
            kennelId,
          );
          query =
              '''

          SELECT 
            h.*,
            hkm.${tableModel.hasherKennelMapTableHelper.colHistoricalTotalRunCount},
            hkm.${tableModel.hasherKennelMapTableHelper.colHistoricalHaringCount},
            hkm.${tableModel.hasherKennelMapTableHelper.colHistoricalCountIsEstimate}
            FROM ${EnumDataTables.hashers.commonTableName} h
            LEFT OUTER JOIN ${EnumDataTables.hasherKennelMap.kennelTableName} hkm ON hkm.${tableModel.hasherKennelMapTableHelper.colKennelId} = "$kennelId" AND hkm.${tableModel.hasherKennelMapTableHelper.colUserId} = "$hasherId"
            WHERE h.${tableModel.hashersTableHelper.colHasherId} = "$hasherId"
          ''';
          break;
      }
      if (isClosed) return;
    }

    try {
      isLoading.value = true;
      final List<Map<String, dynamic>> results = await database.rawQuery(query);
      if (isClosed) return;
      if (results.isNotEmpty) {
        hasher = HashersModel.fromJson(results[0]);

        if (dataContext == EnumDataContext.kennel) {
          _historicalTotalRunCount = results[0]['historicalTotalRunCount'];
          _historicalHaringCount = results[0]['historicalHaringCount'];
          _historicalCountIsEstimate =
              ((results[0]['historicalCountIsEstimate'] ?? 0) == 1);
        }

        firstNameController.text = hasher.firstName ?? '';
        lastNameController.text = hasher.lastName ?? '';
        // We don't reveal the e-mail in the app for anyone but the app's user.
        emailController.text = '';
        hashNameController.text = hasher.hashName ?? '';
        nameDisplayPreference.value = hasher.dispPref;
        // If we have returned from the photo chooser, don't overwrite.
        newPhoto.value = hasher.photo ?? newPhoto.value;
        previousRunCountController.text = (_historicalTotalRunCount ?? 0)
            .toString();
        previousHaringCountController.text = (_historicalHaringCount ?? 0)
            .toString();
        historicalCountIsEstimateWidget.value =
            _historicalCountIsEstimate ?? false;

        if (pageType == EnumMyProfilePageType.myProfile) {
          emailController.text = email ?? '';
        }
      }
      isLoading.value = false;
      checkDirty();
    } catch (e, s) {
      BootLogger.logError(
        '[HasherProfile.refreshUserDataFromTable] hasherId=$hasherId',
        e,
        s,
      );
    }
  }

  /// Whether anything on the form differs from what was loaded. Pure.
  static bool computeDirty({
    required HashersModel hasher,
    required String firstName,
    required String lastName,
    required String hashName,
    required String emailField,
    required String? storedEmail,
    required bool addAsKennelFollower,
    required int nameDisplayPreference,
    required String newPhoto,
    required String previousRunCountText,
    required String previousHaringCountText,
    required int? historicalTotalRunCount,
    required int? historicalHaringCount,
    required bool? estimateWidget,
    required bool? estimate,
  }) {
    if (firstName != (hasher.firstName ?? '')) return true;
    if (lastName != (hasher.lastName ?? '')) return true;
    if (addAsKennelFollower &&
        storedEmail != null &&
        emailField != storedEmail) {
      return true;
    }
    if (hashName != (hasher.hashName ?? '')) return true;
    if (nameDisplayPreference != hasher.dispPref) return true;
    if (newPhoto != (hasher.photo ?? '')) return true;
    if (previousRunCountText != (historicalTotalRunCount ?? 0).toString()) {
      return true;
    }
    if (previousHaringCountText != (historicalHaringCount ?? 0).toString()) {
      return true;
    }
    if (estimateWidget != (estimate ?? false)) return true;
    return false;
  }

  void checkDirty() {
    if (isLoading.value) return;
    isDirty.value = computeDirty(
      hasher: hasher,
      firstName: firstNameController.text,
      lastName: lastNameController.text,
      hashName: hashNameController.text,
      emailField: emailController.text,
      storedEmail: email,
      addAsKennelFollower: addAsKennelFollower.value,
      nameDisplayPreference: nameDisplayPreference.value,
      newPhoto: newPhoto.value,
      previousRunCountText: previousRunCountController.text,
      previousHaringCountText: previousHaringCountController.text,
      historicalTotalRunCount: _historicalTotalRunCount,
      historicalHaringCount: _historicalHaringCount,
      estimateWidget: historicalCountIsEstimateWidget.value,
      estimate: _historicalCountIsEstimate,
    );
  }

  void setNameDisplayPreference(int? value) {
    nameDisplayPreference.value = value ?? 0;
    checkDirty();
  }

  void setEstimate(bool value) {
    historicalCountIsEstimateWidget.value = value;
    checkDirty();
  }

  void onPhotoChosen(String url) {
    newPhoto.value = url;
    checkDirty();
  }

  /// Save. Returns whether the page should pop, and with what — a profile
  /// edited for someone else hands the saved hasher back to its caller.
  Future<({bool shouldPop, HashersModel? result})> updateProfile() async {
    const noPop = (shouldPop: false, result: null);
    if (!(profileFormKey.currentState?.validate() ?? false)) {
      // If the data are not valid then start auto validation.
      autoValidate.value = true;
      return noPop;
    }
    profileFormKey.currentState!.save();

    isLoading.value = true;

    final HashersService srv = HashersService();
    final String responseBody = await srv.addEditUser(
      targetUserId: hasher.hasherId,
      firstName: firstNameController.text,
      lastName: lastNameController.text,
      email: emailController.text,
      hashName: hashNameController.text,
      photo: newPhoto.value,
      eventId: eventId,
      kennelId: kennelId.isEmpty ? GUID_EMPTY : kennelId,
      historicalTotalRunCount: previousRunCountController.text,
      historicalHaringCount: previousHaringCountController.text,
      historicalCountIsEstimate: historicalCountIsEstimateWidget.value,
      // -1 = do not update; the SP COALESCEs it away. This page owns no
      // preference bits now that the auto-show radius moved to Settings
      // (James, 2026-09-20), so it must not write the column at all —
      // writing it from a stale local copy is how one screen clobbers
      // another's setting. This also fixed a live bug: the NON-self branch
      // used to send _autoRunPreference, whose value was never loaded for
      // another hasher, so an admin editing someone's profile rewrote that
      // hasher's Preferences to 2 — resetting their distance units and
      // turning their auto-show radius off.
      preferences: -1,
      followKennelOnAddNewUser: addAsKennelFollower.value ? 1 : 0,
      nameDisplayPreference: nameDisplayPreference.value,
    );
    if (isClosed) return noPop;

    if (responseBody.startsWith(ERROR_PREFIX)) {
      isLoading.value = false;
      await Utilities.showAlert(
        'Profile Not Updated',
        'There was a problem updating your profile. Please ensure you are connected to the Internet and try again later.',
        'OK',
      );
      return noPop;
    }

    if (pageType == EnumMyProfilePageType.myProfile) {
      await setStringPref(StringPrefsEnum.email, emailController.text);
    }

    // Look through the returned results for the hasher we just edited.
    // Usually only one comes back, but there are edge cases with more.
    final HashersModel? h = findSavedHasher(
      json.decode(responseBody),
      firstName: hasher.firstName ?? '',
      hashName: hasher.hashName ?? '',
    );

    if (h != null && pageType == EnumMyProfilePageType.myProfile) {
      await setStringPref(StringPrefsEnum.profilePhotoUrl, h.photo);
      await setStringPref(StringPrefsEnum.displayName, h.dispName);
      // Don't set the e-mail from the API result; the local value stands.
      await setStringPref(StringPrefsEnum.firstName, h.firstName);
      await setStringPref(StringPrefsEnum.hashName, h.hashName);
      await setStringPref(StringPrefsEnum.lastName, h.lastName);
    }

    await refreshUserDataFromTable(true);
    if (isClosed) return noPop;
    isLoading.value = false;
    checkDirty();
    historicalCountIsEstimateWidget.value = _historicalCountIsEstimate;

    if (pageType != EnumMyProfilePageType.myProfile) {
      return (shouldPop: true, result: h);
    }
    await Utilities.showAlert(
      'Profile Updated',
      'Your profile was updated successfully.',
      'OK',
    );
    return noPop;
  }

  /// The saved row in an addEditUser reply: the rowset that carries
  /// hasherIds, matched on first name and hash name (case-insensitive). Pure.
  static HashersModel? findSavedHasher(
    List<dynamic> jsonResult, {
    required String firstName,
    required String hashName,
  }) {
    HashersModel? h;
    for (int i = 0; i < jsonResult.length; i++) {
      final dynamic rowset = jsonResult[i];
      if (rowset is! List || rowset.isEmpty) continue;
      if (rowset[0] is! Map || !(rowset[0] as Map).containsKey('hasherId')) {
        continue;
      }
      for (int j = 0; j < rowset.length; j++) {
        if ((rowset[j]['firstName'].toString().toLowerCase() ==
                firstName.toLowerCase()) &&
            (rowset[j]['hashName'].toString().toLowerCase() ==
                hashName.toLowerCase())) {
          h = HashersModel.fromJson(rowset[0]);
        }
      }
    }
    return h;
  }

  Future<SingleResultModel?> getInviteCode() =>
      GetInviteCodeService().getInviteCode(hasherId);

  /// Loads this hasher's history for [kennelId] and pulls their attendance
  /// and payments into the kennel domain. Null when there is no history —
  /// the old code indexed [0] of an empty list.
  Future<RunHistoryModel?> loadRunHistory() async {
    userRunHistoryLoading.value = true;
    try {
      final List<RunHistoryModel> runHistory =
          await RunHistoryQueries.getRunHistory(hasherId, kennelId);
      await tableModel.syncKennelAdminService.clearEventData();
      await tableModel.syncKennelAdminService.updateFromBackend(
        EnumDataTables.hasherEventMap.flag | EnumDataTables.payments.flag,
        false,
        kennelId,
        targetHasherId: hasherId,
      );
      return runHistory.isEmpty ? null : runHistory.first;
    } catch (e, s) {
      BootLogger.logError('[HasherProfile.loadRunHistory] $hasherId', e, s);
      return null;
    } finally {
      if (!isClosed) userRunHistoryLoading.value = false;
    }
  }

  /// GDPR delete: two confirmations, the server call, then everything local
  /// is wiped and the app restarts at the entry page.
  Future<void> deleteAccount() async {
    final bool? result = await Utilities.showAlert(
      'Delete Account',
      'Deleting your account will permanently remove your personal information from Harrier Central. Information associated with financial transactions and run attendence will be retained on behalf of the respective Kennels, but will be fully anonymized.\r\n\r\nWARNING:\r\nTHIS ACTION IS PERMANENT AND CANNOT BE REVERSED. Please proceed with caution.',
      'Delete Account',
      showCancelButton: true,
      cancelButtonText: 'Keep Account',
    );
    if (!(result ?? false)) return;

    await Future<void>.delayed(const Duration(milliseconds: 1500));

    final bool? result2 = await Utilities.showAlert(
      'Delete Account',
      'Just to double check since this cannot be undone. Are you sure you want to PERMANENTLY DELETE your account?',
      'Delete Account',
      showCancelButton: true,
      cancelButtonText: 'Keep Account',
    );
    if (!(result2 ?? false)) return;

    final SingleResultModel? deleted = await GdprDeleteService().gdprDelete();
    if ((deleted?.result ?? '') == 'success') {
      await Utilities.showAlert(
        'Successful',
        'Your account has been deleted. Thanks for using Harrier Central. We hope to see you back one day in the future!\r\n\r\nPlease note, the Harrier Central app must restart after you hit OK. We suggest closing the app and deleting it as it is useless without an account.',
        'OK',
      );
    } else {
      await Utilities.showAlert(
        'Contact us',
        'For some reason, we were unable to delete your account. Please contact us at harriercentral@gmail.com to request us to manually delete your account. Our apologies for the inconvenience. Meanwhile, we will remove all of your personal information related to Harrier Central from your phone.\r\n\r\nOnce the information has been deleted, the Harrier Central app will restart. We suggest closing the app and deleting it as it is useless without an account.',
        'OK',
      );
    }

    await clearPrefs();
    await deleteAllSecure();
    await DBProvider.deleteDb(DB_NAME);
    await Get.offAll(() => AppEntryPage());
  }
}
