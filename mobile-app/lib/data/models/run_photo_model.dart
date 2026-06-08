class RunPhotoModel {
  const RunPhotoModel({
    required this.photoId,
    required this.blobUrl,
    this.editedBlobUrl,
    this.title,
    this.description,
    required this.createdAt,
    this.uploaderDisplayName,
    this.isOwnPhoto = false,
    this.status = 2,
    this.assetId,
  });

  final String photoId;
  final String blobUrl;
  /// Hash-Flash-edited crop. Null until the Hash Flash crops the photo.
  /// Always display [effectiveUrl]. Always re-edit from [blobUrl] (original).
  final String? editedBlobUrl;
  final String? title;
  final String? description;
  final DateTime createdAt;
  final String? uploaderDisplayName;

  /// True for the authenticated user's own photos (from hcapp_getRunPhotos rowset 0).
  final bool isOwnPhoto;

  /// Photo status code. 0 = private, 2 = public, 3 = gallery, 4 = home, 5 = cover.
  final int status;

  /// Device asset ID — only populated for own photos, allows loading from device.
  final String? assetId;

  /// The URL to display: edited version if available, original otherwise.
  String get effectiveUrl => editedBlobUrl ?? blobUrl;

  String get displayCaption => description ?? title ?? '';

  // publicWeb_getRunPhotos rowset 1
  factory RunPhotoModel.fromPublicJson(Map<String, dynamic> json) =>
      RunPhotoModel(
        photoId: json['photoId'] as String? ?? '',
        blobUrl: json['BlobUrl'] as String? ?? '',
        editedBlobUrl: json['EditedBlobUrl'] as String?,
        title: json['Title'] as String?,
        description: json['Description'] as String?,
        createdAt: _parseDateTime(json['CreatedAt']) ?? DateTime(0),
        uploaderDisplayName: json['uploaderDisplayName'] as String?,
        isOwnPhoto: false,
        status: 2,
      );

  // hcapp_getRunPhotos rowset 0 — authenticated user's own photos (all statuses)
  factory RunPhotoModel.fromOwnJson(Map<String, dynamic> json) =>
      RunPhotoModel(
        photoId: json['photoId'] as String? ?? '',
        blobUrl: json['BlobUrl'] as String? ?? '',
        editedBlobUrl: json['EditedBlobUrl'] as String?,
        title: json['Title'] as String?,
        description: json['Description'] as String?,
        createdAt: _parseDateTime(json['CreatedAt']) ?? DateTime(0),
        uploaderDisplayName: null,
        isOwnPhoto: true,
        status: (json['Status'] as num?)?.toInt() ?? 0,
        assetId: json['AssetId'] as String?,
      );

  // hcapp_getRunPhotos rowset 1 — others' public photos (status >= 2)
  factory RunPhotoModel.fromOthersJson(Map<String, dynamic> json) =>
      RunPhotoModel(
        photoId: json['photoId'] as String? ?? '',
        blobUrl: json['BlobUrl'] as String? ?? '',
        editedBlobUrl: json['EditedBlobUrl'] as String?,
        title: json['Title'] as String?,
        description: json['Description'] as String?,
        createdAt: _parseDateTime(json['CreatedAt']) ?? DateTime(0),
        uploaderDisplayName: json['uploaderDisplayName'] as String?,
        isOwnPhoto: false,
        status: (json['Status'] as num?)?.toInt() ?? 2,
      );

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
