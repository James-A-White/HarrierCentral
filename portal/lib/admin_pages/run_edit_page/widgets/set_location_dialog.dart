import 'package:hcportal/imports.dart';

/// Result of the Set-Location dialog. A null `regionId`/`cityId` with a
/// non-null name means the user chose "Other" and typed a free-text value.
/// `timezoneId` is only set when there is no structured city (the manual case);
/// when a structured `cityId` is present the timezone is derived from it.
class LocationSelection {
  const LocationSelection({
    required this.countryId,
    required this.countryName,
    this.regionId,
    this.regionName,
    this.cityId,
    this.cityName,
    this.timezoneId,
  });

  final String countryId;
  final String countryName;
  final String? regionId;
  final String? regionName;
  final String? cityId;
  final String? cityName;
  final int? timezoneId;
}

/// Dialog controller for the cascading Country -> Region -> City selector with
/// "Other" free-text fallbacks and a manual timezone picker. Self-contained:
/// it loads its own option lists and returns a [LocationSelection] on save.
class SetLocationController extends GetxController {
  SetLocationController({
    required this.initialCountryId,
    required this.initialRegionId,
    required this.initialRegionName,
    required this.initialCityId,
    required this.initialCityName,
    required this.initialTimezoneId,
  });

  /// Sentinel dropdown key for the "Other…" entry.
  static const String otherKey = '__other__';

  final String? initialCountryId;
  final String? initialRegionId;
  final String? initialRegionName;
  final String? initialCityId;
  final String? initialCityName;
  final int? initialTimezoneId;

  final RxMap<String, String> countryOptions = <String, String>{}.obs;
  final RxMap<String, String> regionOptions = <String, String>{}.obs;
  final RxMap<String, String> cityOptions = <String, String>{}.obs;
  final RxMap<int, String> timezoneOptions = <int, String>{}.obs;

  final RxnString countryId = RxnString();
  final RxnString regionId = RxnString();
  final RxnString cityId = RxnString();
  final RxnInt timezoneId = RxnInt();

  final RxBool regionIsOther = false.obs;
  final RxBool cityIsOther = false.obs;
  final RxnString regionOtherText = RxnString();
  final RxnString cityOtherText = RxnString();

  final RxBool isLoadingRegions = false.obs;
  final RxBool isLoadingCities = false.obs;
  final RxBool isLoadingTimezones = false.obs;
  final RxBool isReady = false.obs;

  String? _norm(String? id) =>
      (id == null || id.isEmpty) ? null : normalizeUuid(id);

  @override
  void onInit() {
    super.onInit();
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    countryOptions.value = await queryCountries();
    countryId.value = _norm(initialCountryId);

    if (countryId.value != null) {
      await _loadRegions(countryId.value!);
    }

    // Restore region: structured id, or "Other" if only a name was stored.
    final rId = _norm(initialRegionId);
    if (rId != null) {
      regionId.value = rId;
      await _loadCities(rId);
    } else if ((initialRegionName ?? '').isNotEmpty) {
      regionIsOther.value = true;
      regionOtherText.value = initialRegionName;
    }

    // Restore city: structured id, or "Other" if only a name was stored.
    final cId = _norm(initialCityId);
    if (cId != null && !regionIsOther.value) {
      cityId.value = cId;
    } else if ((initialCityName ?? '').isNotEmpty) {
      cityIsOther.value = true;
      cityOtherText.value = initialCityName;
    }

    // Manual timezone is relevant only when there's no structured city.
    if (cityId.value == null && (regionIsOther.value || cityIsOther.value)) {
      timezoneId.value = initialTimezoneId;
      await _loadTimezones();
    }

    isReady.value = true;
  }

  Future<void> _loadRegions(String forCountryId) async {
    isLoadingRegions.value = true;
    regionOptions.value = await queryRegions(forCountryId);
    isLoadingRegions.value = false;
  }

  Future<void> _loadCities(String forRegionId) async {
    isLoadingCities.value = true;
    cityOptions.value = await queryCities(forRegionId);
    isLoadingCities.value = false;
  }

  Future<void> _loadTimezones() async {
    final c = countryId.value;
    if (c == null) return;
    isLoadingTimezones.value = true;
    // Narrow by region only when a valid (non-Other) region is selected.
    timezoneOptions.value = await queryTimezonesForGeography(
      c,
      regionId: regionIsOther.value ? null : regionId.value,
    );
    isLoadingTimezones.value = false;
  }

  Future<void> selectCountry(String? id) async {
    countryId.value = _norm(id);
    regionId.value = null;
    cityId.value = null;
    regionIsOther.value = false;
    cityIsOther.value = false;
    regionOtherText.value = null;
    cityOtherText.value = null;
    timezoneId.value = null;
    regionOptions.clear();
    cityOptions.clear();
    timezoneOptions.clear();
    if (countryId.value != null) await _loadRegions(countryId.value!);
  }

  Future<void> selectRegion(String? value) async {
    cityId.value = null;
    cityOtherText.value = null;
    timezoneId.value = null;
    cityOptions.clear();
    timezoneOptions.clear();
    if (value == otherKey) {
      // Other region → free-text region AND free-text city (no city list).
      regionIsOther.value = true;
      regionId.value = null;
      cityIsOther.value = true;
      await _loadTimezones();
    } else {
      regionIsOther.value = false;
      regionOtherText.value = null;
      cityIsOther.value = false;
      regionId.value = _norm(value);
      if (regionId.value != null) await _loadCities(regionId.value!);
    }
  }

  Future<void> selectCity(String? value) async {
    timezoneId.value = null;
    timezoneOptions.clear();
    if (value == otherKey) {
      cityIsOther.value = true;
      cityId.value = null;
      await _loadTimezones();
    } else {
      cityIsOther.value = false;
      cityOtherText.value = null;
      cityId.value = _norm(value);
    }
  }

  void selectTimezone(int? id) => timezoneId.value = id;

  /// Manual timezone is required whenever the location has no structured city.
  bool get _needsManualTimezone => regionIsOther.value || cityIsOther.value;

  /// Whether the current selection is complete enough to save.
  bool get canSave {
    if (countryId.value == null) return false;
    if (regionIsOther.value) {
      return (regionOtherText.value ?? '').trim().isNotEmpty &&
          (cityOtherText.value ?? '').trim().isNotEmpty &&
          timezoneId.value != null;
    }
    if (regionId.value == null) return false;
    if (cityIsOther.value) {
      return (cityOtherText.value ?? '').trim().isNotEmpty &&
          timezoneId.value != null;
    }
    return cityId.value != null;
  }

  LocationSelection buildResult() {
    final cId = cityIsOther.value ? null : cityId.value;
    return LocationSelection(
      countryId: countryId.value!,
      countryName: countryOptions[countryId.value] ?? '',
      regionId: regionIsOther.value ? null : regionId.value,
      regionName: regionIsOther.value
          ? regionOtherText.value?.trim()
          : regionOptions[regionId.value],
      cityId: cId,
      cityName: cityIsOther.value
          ? cityOtherText.value?.trim()
          : cityOptions[cityId.value],
      // Timezone is derived from a structured city; only carry the manual pick.
      timezoneId: cId == null ? timezoneId.value : null,
    );
  }
}

/// Cascading Country -> Region -> City picker (with "Other" + manual timezone),
/// shown as a modal. Returns a [LocationSelection] via `Get.back`, or null on
/// cancel. Country is list-only; Region and City offer an "Other…" entry.
class SetLocationDialog extends StatelessWidget {
  const SetLocationDialog({required this.controller, super.key});

  final SetLocationController controller;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Obx(() {
            if (!controller.isReady.value) {
              return const SizedBox(
                height: 160,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Set Location (Timezone)',
                  style: TextStyle(
                    fontFamily: 'AvenirNextBold',
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Used to set the run’s timezone and to bias address '
                  'lookups — not the street address.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                _dropdown(
                  label: 'Country',
                  value: controller.countryId.value,
                  items: controller.countryOptions,
                  onChanged: controller.selectCountry,
                ),
                const SizedBox(height: 12),
                _regionField(),
                const SizedBox(height: 12),
                _cityField(),
                if (controller._needsManualTimezone) ...[
                  const SizedBox(height: 12),
                  _timezoneField(),
                ],
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    HcButton.secondary(
                      label: 'Cancel',
                      onPressed: () => Get.back<LocationSelection>(),
                    ),
                    const SizedBox(width: 12),
                    HcButton.primary(
                      label: 'Save',
                      onPressed: controller.canSave
                          ? () => Get.back<LocationSelection>(
                              result: controller.buildResult())
                          : null,
                    ),
                  ],
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _regionField() {
    if (controller.regionIsOther.value) {
      return _otherTextField(
        label: 'Region / State (Other)',
        value: controller.regionOtherText.value,
        onChanged: (v) => controller.regionOtherText.value = v,
        onClear: () => controller.selectRegion(null),
      );
    }
    return _dropdown(
      label: 'Region / State',
      value: controller.regionId.value,
      items: controller.regionOptions,
      enabled: controller.countryId.value != null,
      loading: controller.isLoadingRegions.value,
      onChanged: controller.selectRegion,
    );
  }

  Widget _cityField() {
    if (controller.cityIsOther.value) {
      return _otherTextField(
        label: 'City (Other)',
        value: controller.cityOtherText.value,
        onChanged: (v) => controller.cityOtherText.value = v,
        // A free-text city under a valid region can switch back to the list;
        // under an "Other" region the city stays free-text.
        onClear: controller.regionIsOther.value
            ? null
            : () => controller.selectCity(null),
      );
    }
    return _dropdown(
      label: 'City',
      value: controller.cityId.value,
      items: controller.cityOptions,
      enabled: controller.regionId.value != null,
      loading: controller.isLoadingCities.value,
      onChanged: controller.selectCity,
    );
  }

  Widget _timezoneField() {
    final items = controller.timezoneOptions;
    final current = items.containsKey(controller.timezoneId.value)
        ? controller.timezoneId.value
        : null;
    return DropdownButtonFormField<int>(
      initialValue: current,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Timezone',
        border: const OutlineInputBorder(),
        helperText: 'Required when region or city is "Other".',
        suffixIcon: controller.isLoadingTimezones.value
            ? const Padding(
                padding: EdgeInsets.all(10),
                child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2)),
              )
            : null,
      ),
      items: [
        for (final e in items.entries)
          DropdownMenuItem<int>(value: e.key, child: Text(e.value)),
      ],
      onChanged: controller.selectTimezone,
    );
  }

  /// A String-keyed dropdown that appends an "Other…" entry.
  Widget _dropdown({
    required String label,
    required String? value,
    required RxMap<String, String> items,
    required void Function(String?) onChanged,
    bool enabled = true,
    bool loading = false,
  }) {
    final hasValue = items.containsKey(value);
    return DropdownButtonFormField<String>(
      initialValue: hasValue ? value : null,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: loading
            ? const Padding(
                padding: EdgeInsets.all(10),
                child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2)),
              )
            : null,
      ),
      items: [
        for (final e in items.entries)
          DropdownMenuItem<String>(value: e.key, child: Text(e.value)),
        // Country is list-only; Region/City get an "Other…" entry.
        if (label != 'Country')
          const DropdownMenuItem<String>(
            value: SetLocationController.otherKey,
            child: Text('Other…'),
          ),
      ],
      onChanged: enabled ? onChanged : null,
    );
  }

  Widget _otherTextField({
    required String label,
    required String? value,
    required void Function(String) onChanged,
    VoidCallback? onClear,
  }) {
    return TextFormField(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: onClear == null
            ? null
            : IconButton(
                tooltip: 'Pick from list',
                icon: const Icon(Icons.list, size: 20),
                onPressed: onClear,
              ),
      ),
      onChanged: onChanged,
    );
  }
}
