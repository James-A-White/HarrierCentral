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
    this.hashers = const [],
  });

  final String downDownId;
  final String chargeText;
  final bool isDone;
  final bool isCancelled;
  final String createdByDisplayName;
  final String? createdByPhoto;
  final DateTime createdAt;
  List<DownDownHasherModel> hashers;

  static DownDownModel fromJson(Map<String, dynamic> json) => DownDownModel(
        downDownId: json['downDownId'] as String,
        chargeText: json['chargeText'] as String? ?? '',
        isDone: json['isDone'] == true || json['isDone'] == 1,
        isCancelled: json['isCancelled'] == true || json['isCancelled'] == 1,
        createdByDisplayName: json['createdByDisplayName'] as String? ?? '',
        createdByPhoto: json['createdByPhoto'] as String?,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}
