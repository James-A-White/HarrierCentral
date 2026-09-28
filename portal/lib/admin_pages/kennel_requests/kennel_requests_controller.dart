import 'package:hcportal/imports.dart';

/// The Kennel requests list (E12.F1.S5): one status at a time, with the
/// count of every status for the filter chips, and a selection for closing
/// several requests at once — the spam arrives in bursts.
class KennelRequestsController extends GetxController {
  final Rx<KennelRequestStatus> status = KennelRequestStatus.newRequest.obs;
  final RxList<KennelRequestModel> requests = <KennelRequestModel>[].obs;
  final RxMap<int, int> counts = <int, int>{}.obs;
  final RxSet<String> selected = <String>{}.obs;
  final RxBool isLoading = true.obs;
  final RxBool isBusy = false.obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(load());
  }

  Future<void> load() async {
    isLoading.value = true;
    final page = await queryKennelRequests(status.value.code);
    if (isClosed) return;
    if (page != null) {
      requests.assignAll(page.requests);
      counts.assignAll(page.counts);
    }
    selected.clear();
    isLoading.value = false;
  }

  Future<void> showStatus(KennelRequestStatus s) async {
    if (s == status.value) return;
    status.value = s;
    await load();
  }

  void toggle(String id) {
    if (!selected.remove(id)) selected.add(id);
  }

  /// Closes (or reopens) every selected request with [newStatus].
  Future<void> setSelectedStatus(int newStatus, {String? note}) async {
    if (selected.isEmpty || isBusy.value) return;
    isBusy.value = true;
    final changed = await setKennelRequestStatus(selected.toList(), newStatus, reviewNote: note);
    isBusy.value = false;
    if (changed != null) {
      kennelRequestNotice('${changed == 1 ? '1 request' : '$changed requests'} '
          'marked ${KennelRequestStatus.fromCode(newStatus).label.toLowerCase()}.');
    }
    await load();
  }
}

/// One request under review (E12.F1.S5–S6): the fields the reviewer may
/// correct, the database's own country → region → city, and the three ways
/// out — approve, close, or reopen.
class KennelRequestDetailController extends GetxController {
  KennelRequestDetailController(this.request);

  KennelRequestModel request;

  late final TextEditingController firstName = TextEditingController(text: request.firstName);
  late final TextEditingController lastName = TextEditingController(text: request.lastName);
  late final TextEditingController hashName = TextEditingController(text: request.hashName);
  late final TextEditingController email = TextEditingController(text: request.email);
  late final TextEditingController kennelName = TextEditingController(text: request.kennelName);
  late final TextEditingController shortName = TextEditingController(text: request.kennelShortName);
  late final TextEditingController description = TextEditingController(text: request.kennelDescription);
  late final TextEditingController kennelUrl = TextEditingController(text: request.kennelUrl ?? '');
  late final TextEditingController facebookUrl = TextEditingController(text: request.kennelFacebookUrl ?? '');
  late final TextEditingController hashCash = TextEditingController(text: request.hashCash ?? '');
  late final TextEditingController reviewNote = TextEditingController(text: request.reviewNote ?? '');

  final RxMap<String, String> countryOptions = <String, String>{}.obs;
  final RxMap<String, String> regionOptions = <String, String>{}.obs;
  final RxMap<String, String> cityOptions = <String, String>{}.obs;
  final RxnString countryId = RxnString();
  final RxnString regionId = RxnString();
  final RxnString cityId = RxnString();

  /// Anything edited since the last save — approval saves it first.
  final RxBool isDirty = false.obs;
  final RxBool isBusy = false.obs;

  /// Tells the list to reload when the page closes.
  bool changed = false;

  List<TextEditingController> get _fields => [
    firstName, lastName, hashName, email, kennelName, shortName,
    description, kennelUrl, facebookUrl, hashCash, reviewNote,
  ];

  bool get shortNameIsValid => RegExp(r'^[A-Za-z0-9]{1,20}$').hasMatch(shortName.text.trim());

  @override
  void onInit() {
    super.onInit();
    for (final c in _fields) {
      c.addListener(_markDirty);
    }
    countryId.value = request.countryId;
    regionId.value = request.regionId;
    cityId.value = request.cityId;
    unawaited(_loadLocations());
  }

  @override
  void onClose() {
    for (final c in _fields) {
      c.dispose();
    }
    super.onClose();
  }

  void _markDirty() => isDirty.value = true;

  Future<void> _loadLocations() async {
    countryOptions.assignAll(await queryCountries());
    if (countryId.value != null) regionOptions.assignAll(await queryRegions(countryId.value!));
    if (regionId.value != null) cityOptions.assignAll(await queryCities(regionId.value!));
  }

  Future<void> pickCountry(String? id) async {
    if (id == null || id == countryId.value) return;
    countryId.value = id;
    regionId.value = null;
    cityId.value = null;
    regionOptions.clear();
    cityOptions.clear();
    isDirty.value = true;
    regionOptions.assignAll(await queryRegions(id));
  }

  Future<void> pickRegion(String? id) async {
    if (id == null || id == regionId.value) return;
    regionId.value = id;
    cityId.value = null;
    cityOptions.clear();
    isDirty.value = true;
    cityOptions.assignAll(await queryCities(id));
  }

  void pickCity(String? id) {
    if (id == null || id == cityId.value) return;
    cityId.value = id;
    isDirty.value = true;
  }

  /// Sends every field; the SP keeps what did not change.
  Future<bool> save() async {
    if (isBusy.value) return false;
    isBusy.value = true;
    final ok = await updateKennelRequest(request.id, <String, String?>{
      'firstName': firstName.text,
      'lastName': lastName.text,
      'hashName': hashName.text,
      'emailAddress': email.text,
      'kennelName': kennelName.text,
      'kennelShortName': shortName.text,
      'kennelDescription': description.text,
      'kennelUrl': kennelUrl.text,
      'kennelFacebookUrl': facebookUrl.text,
      'hashCash': hashCash.text,
      'reviewNote': reviewNote.text,
      'countryId': countryId.value,
      'regionId': regionId.value,
      'cityId': cityId.value,
    });
    isBusy.value = false;
    if (ok) {
      isDirty.value = false;
      changed = true;
    }
    return ok;
  }

  /// Saves any edits, then approves. Returns what was made, or null.
  Future<ApprovedKennel?> approve() async {
    if (isDirty.value && !await save()) return null;
    isBusy.value = true;
    final approved = await approveKennelRequest(request.id);
    isBusy.value = false;
    if (approved != null) changed = true;
    return approved;
  }

  Future<bool> setStatus(int newStatus) async {
    if (isBusy.value) return false;
    isBusy.value = true;
    final note = reviewNote.text.trim();
    final n = await setKennelRequestStatus(
      [request.id],
      newStatus,
      reviewNote: note.isEmpty ? null : note,
    );
    isBusy.value = false;
    if (n != null && n > 0) {
      changed = true;
      return true;
    }
    return false;
  }
}

/// A short notice at the foot of the page, as the other admin tools use.
void kennelRequestNotice(String message, {bool isError = false}) {
  Get.snackbar(
    isError ? 'Not done' : 'Done',
    message,
    snackPosition: SnackPosition.BOTTOM,
    backgroundColor: isError ? const Color(0xFFDC2626) : const Color(0xFF15803D),
    colorText: Colors.white,
    duration: const Duration(seconds: 4),
    maxWidth: 560,
  );
}
