/// Reader row returned by hcportal_getNewsflashReaders (admin view).
/// Plain Dart class — no Freezed required.
class NewsflashReaderModel {
  const NewsflashReaderModel({
    required this.publicHasherId,
    required this.hashName,
    required this.displayName,
    required this.isDismissed,
    this.nextShowDate,
    required this.updatedAt,
  });

  factory NewsflashReaderModel.fromJson(Map<String, dynamic> json) {
    return NewsflashReaderModel(
      publicHasherId: (json['publicHasherId'] as String?) ?? '',
      hashName: (json['hashName'] as String?) ?? '',
      displayName: (json['displayName'] as String?) ?? '',
      isDismissed: json['isDismissed'] == true || json['isDismissed'] == 1,
      nextShowDate: json['nextShowDate'] != null
          ? DateTime.tryParse(json['nextShowDate'] as String)
          : null,
      updatedAt: DateTime.tryParse((json['updatedAt'] as String?) ?? '') ??
          DateTime.now(),
    );
  }

  final String publicHasherId;
  final String hashName;
  final String displayName;
  final bool isDismissed;
  final DateTime? nextShowDate;
  final DateTime updatedAt;
}
