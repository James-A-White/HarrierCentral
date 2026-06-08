class HashTrashModel {
  HashTrashModel({
    required this.headline,
    required this.content,
    required this.status,
  });

  final String headline;
  final String? content;
  final int? status;

  bool get isDraft => status == 0;
  bool get isPublished => status == 1;
  bool get isEmpty => headline.isEmpty && (content == null || content!.isEmpty);

  static HashTrashModel? fromJson(Map<String, dynamic> json) {
    final headline = json['headline'] as String? ?? '';
    final content = json['content'] as String?;
    final status = json['status'] as int?;
    if (headline.isEmpty && content == null && status == null) return null;
    return HashTrashModel(headline: headline, content: content, status: status);
  }
}
