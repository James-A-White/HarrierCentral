import 'dart:convert';

class DownDownHasherModel {
  DownDownHasherModel({
    required this.downDownId,
    required this.hasherId,
    required this.displayName,
  });

  final String downDownId;
  final String hasherId;
  final String displayName;

  static DownDownHasherModel fromJson(Map<String, dynamic> json) =>
      DownDownHasherModel(
        downDownId: json['downDownId'] as String,
        hasherId: json['hasherId'] as String,
        displayName: json['displayName'] as String? ?? '',
      );
}

class DownDownModel {
  DownDownModel({
    required this.downDownId,
    required this.chargeText,
    required this.isDone,
    required this.isCancelled,
    required this.createdByDisplayName,
    required this.createdAt,
    this.createdByPhoto,
    this.songChoice,
    this.songId,
    this.chargePhotoUrl,
    this.hashers = const [],
    this.externalNames = const [],
  });

  final String downDownId;
  final String chargeText;
  final bool isDone;
  final bool isCancelled;
  final String createdByDisplayName;
  final String? createdByPhoto;
  final String? songChoice;
  final String? songId;
  final String? chargePhotoUrl;
  final DateTime createdAt;
  List<DownDownHasherModel> hashers;

  /// Names of charged people who are NOT registered HC users. Parsed from the
  /// server's `externalNames` JSON-array column. In-app hashers live in [hashers];
  /// a charge may include both.
  final List<String> externalNames;

  /// All charged people for display — in-app hasher names followed by the
  /// external (not-in-app) names.
  List<String> get allChargedNames =>
      [...hashers.map((h) => h.displayName), ...externalNames];

  static DownDownModel fromJson(Map<String, dynamic> json) => DownDownModel(
        downDownId: json['downDownId'] as String,
        chargeText: json['chargeText'] as String? ?? '',
        isDone: json['isDone'] == true || json['isDone'] == 1,
        isCancelled: json['isCancelled'] == true || json['isCancelled'] == 1,
        createdByDisplayName: json['createdByDisplayName'] as String? ?? '',
        createdByPhoto: json['createdByPhoto'] as String?,
        songChoice: json['songChoice'] as String?,
        songId: json['songId'] as String?,
        chargePhotoUrl: json['chargePhotoUrl'] as String?,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        externalNames: _parseExternalNames(json['externalNames']),
      );

  static List<String> _parseExternalNames(dynamic raw) {
    if (raw is! String || raw.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .map((e) => e?.toString().trim() ?? '')
            .where((s) => s.isNotEmpty)
            .toList();
      }
    } catch (_) {/* malformed JSON → no external names */}
    return const [];
  }
}
