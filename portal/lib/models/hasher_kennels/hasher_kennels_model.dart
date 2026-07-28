// ignore_for_file: non_constant_identifier_names

// package imports
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hcportal/imports.dart';

//import 'package:hcportal/imports.dart';

part 'hasher_kennels_model.freezed.dart';
part 'hasher_kennels_model.g.dart';

@freezed
abstract class HasherKennelsModel with _$HasherKennelsModel {
  factory HasherKennelsModel({
    required String publicKennelId,
    required String kennelName,
    required String kennelShortName,
    required String kennelUniqueShortName,
    required String kennelLogo,
    required String kennelCountryCodes,
    required String countryId,
    required String countryName,
    required int isFollowing,
    required int isMember,
    required int isHomeKennel,
    required int appAccessFlags,
    // Portal-only derived permissions (Permissions V2) for the current user in
    // this kennel, computed server-side in hcportal_getLandingPageData. 1 = allowed.
    @Default(0) int canEditWebsite,
    @Default(0) int canDesignWebsite,
    required int defaultTags1,
    required int defaultTags2,
    required int defaultTags3,
    required int defaultDigitsAfterDecimal,
    required String defaultCurrencySymbol,
    required DateTime defaultRunStartTime,
    @Default(1) int defaultRunDayOfWeek,
    required double cityLat,
    required double cityLon,
    required double defaultEventPriceForMembers,
    required double defaultEventPriceForNonMembers,
    String? cityName,
    String? regionName,
    // Kennel's default structured location ids (from getKennel) — used as the
    // inherited default for a run's Timezone-group Country/Region/City and as
    // the gazetteer fallback. provinceStateId is the kennel's region id.
    String? cityId,
    String? provinceStateId,
    String? continentName,
    DateTime? membershipExpirationDate,
    double? kennelLat,
    double? kennelLon,
  }) = _HasherKennelsModel;

  factory HasherKennelsModel.fromJson(Map<String, dynamic> json) =>
      _$HasherKennelsModelFromJson(json);

  // Define custom getters for bitwise flags
  const HasherKennelsModel._(); // Required for private access to the generated class

  bool get isAdmin => (((appAccessFlags & authIsAdmin) != 0) ||
      ((appAccessFlags & authIsSuperAdmin) != 0));

  bool get canManageKennel => (((appAccessFlags & authCanManageKennel) != 0) ||
      ((appAccessFlags & authIsSuperAdmin) != 0));

  bool get canManageRuns => (((appAccessFlags & authCanManageRuns) != 0) ||
      ((appAccessFlags & authIsSuperAdmin) != 0));

  bool get canManageHashCash =>
      (((appAccessFlags & authCanManageHashCash) != 0) ||
          ((appAccessFlags & authIsSuperAdmin) != 0));

  bool get canManageMembers =>
      (((appAccessFlags & authCanManageMembers) != 0) ||
          ((appAccessFlags & authIsSuperAdmin) != 0));

  bool get canManageAwards => (((appAccessFlags & authCanManageAwards) != 0) ||
      ((appAccessFlags & authIsSuperAdmin) != 0));

  bool get canManageSongs => (((appAccessFlags & authCanManageSongs) != 0) ||
      ((appAccessFlags & authIsSuperAdmin) != 0));

  bool get canManagePublicWebContent =>
      (((appAccessFlags & authCanManagePublicWebContent) != 0) ||
          ((appAccessFlags & authIsSuperAdmin) != 0));

  bool get isSuperAdmin => (((appAccessFlags & authIsSuperAdmin) != 0) ||
      ((appAccessFlags & authIsSuperAdmin) != 0));
}
