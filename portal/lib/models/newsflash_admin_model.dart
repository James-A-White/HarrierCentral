/// Newsflash row returned by hcportal_getNewsflashList (admin view).
/// Plain Dart class — no Freezed required.
class NewsflashAdminModel {
  const NewsflashAdminModel({
    required this.newsflashId,
    required this.title,
    required this.bodyText,
    this.imageUrl,
    required this.startDate,
    this.endDate,
    this.kennelId,
    this.kennelName,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
    required this.dismissedCount,
  });

  factory NewsflashAdminModel.fromJson(Map<String, dynamic> json) {
    return NewsflashAdminModel(
      newsflashId: (json['newsflashId'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      bodyText: (json['bodyText'] as String?) ?? '',
      imageUrl: json['imageUrl'] as String?,
      startDate: DateTime.tryParse((json['startDate'] as String?) ?? '') ??
          DateTime.now(),
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'] as String)
          : null,
      kennelId: json['kennelId'] as String?,
      kennelName: json['kennelName'] as String?,
      isDeleted: json['isDeleted'] == true || json['isDeleted'] == 1,
      createdAt: DateTime.tryParse((json['createdAt'] as String?) ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse((json['updatedAt'] as String?) ?? '') ??
          DateTime.now(),
      dismissedCount: (json['dismissedCount'] as int?) ?? 0,
    );
  }

  final String newsflashId;
  final String title;
  final String bodyText;
  final String? imageUrl;
  final DateTime startDate;
  final DateTime? endDate;
  final String? kennelId;
  final String? kennelName;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int dismissedCount;
}
