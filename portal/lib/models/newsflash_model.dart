/// Pending newsflash returned by hcportal_getPendingNewsflashes.
/// Plain Dart class — no Freezed required.
class NewsflashModel {
  const NewsflashModel({
    required this.newsflashId,
    required this.title,
    required this.bodyText,
    this.imageUrl,
    required this.startDate,
    this.endDate,
  });

  factory NewsflashModel.fromJson(Map<String, dynamic> json) {
    return NewsflashModel(
      newsflashId: (json['newsflashId'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      bodyText: (json['bodyText'] as String?) ?? '',
      imageUrl: json['imageUrl'] as String?,
      startDate: DateTime.tryParse((json['startDate'] as String?) ?? '') ??
          DateTime.now(),
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'] as String)
          : null,
    );
  }

  final String newsflashId;
  final String title;
  final String bodyText;
  final String? imageUrl;
  final DateTime startDate;
  final DateTime? endDate;
}
