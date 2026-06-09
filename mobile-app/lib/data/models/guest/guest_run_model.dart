class GuestRunModel {
  const GuestRunModel({
    required this.publicEventId,
    this.eventNumber,
    required this.eventName,
    this.eventStartDatetime,
    this.eventStartDatetimeGmt,
    this.kennelIANATimezone,
    this.eventTypeName,
    this.eventPriceForMembers,
    this.eventPriceForNonMembers,
    this.eventCurrencyType,
    this.hares,
    this.locationOneLineDesc,
    this.locationStreet,
    this.locationCity,
    this.locationPostCode,
    this.locationRegion,
    this.locationCountry,
    this.latitude,
    this.longitude,
    this.w3wJson,
    this.eventDescription,
    this.eventImage,
    this.eventUrl,
    this.tags1 = 0,
    this.tags2 = 0,
    this.tags3 = 0,
    this.isCountedRun = false,
    required this.kennelSlug,
    this.kennelShortName,
    required this.kennelName,
    this.kennelLogo,
    this.primaryColor,
    this.accentColor,
    required this.publicKennelId,
    this.kennelWebsiteDomain,
    this.kennelContinent,
  });

  final String publicEventId;
  final int? eventNumber;
  final String eventName;
  final DateTime? eventStartDatetime;
  final DateTime? eventStartDatetimeGmt;
  final String? kennelIANATimezone;
  final String? eventTypeName;
  final double? eventPriceForMembers;
  final double? eventPriceForNonMembers;
  final String? eventCurrencyType;
  final String? hares;
  final String? locationOneLineDesc;
  final String? locationStreet;
  final String? locationCity;
  final String? locationPostCode;
  final String? locationRegion;
  final String? locationCountry;
  final double? latitude;
  final double? longitude;
  final String? w3wJson;
  final String? eventDescription;
  final String? eventImage;
  final String? eventUrl;
  final int tags1;
  final int tags2;
  final int tags3;
  final bool isCountedRun;
  final String kennelSlug;
  final String? kennelShortName;
  final String kennelName;
  final String? kennelLogo;
  final String? primaryColor;
  final String? accentColor;
  final String publicKennelId;
  final String? kennelWebsiteDomain;
  final String? kennelContinent;

  // JSON keys are PascalCase — they come directly from the SQL SELECT aliases
  // in publicWeb_getGlobalRuns, which PublicWebApi.cs forwards without casing
  // transformation.
  factory GuestRunModel.fromJson(Map<String, dynamic> json) {
    return GuestRunModel(
      publicEventId: json['PublicEventId'] as String? ?? '',
      eventNumber: (json['EventNumber'] as num?)?.toInt(),
      eventName: json['EventName'] as String? ?? '',
      eventStartDatetime: _parseDateTime(json['EventStartDatetime']),
      eventStartDatetimeGmt: _parseDateTime(json['EventStartDatetimeGmt']),
      kennelIANATimezone: json['KennelIANATimezone'] as String?,
      eventTypeName: json['EventTypeName'] as String?,
      eventPriceForMembers:
          (json['EventPriceForMembers'] as num?)?.toDouble(),
      eventPriceForNonMembers:
          (json['EventPriceForNonMembers'] as num?)?.toDouble(),
      eventCurrencyType: json['EventCurrencyType'] as String?,
      hares: json['Hares'] as String?,
      locationOneLineDesc: json['LocationOneLineDesc'] as String?,
      locationStreet: json['LocationStreet'] as String?,
      locationCity: json['LocationCity'] as String?,
      locationPostCode: json['LocationPostCode'] as String?,
      locationRegion: json['LocationRegion'] as String?,
      locationCountry: json['LocationCountry'] as String?,
      latitude: (json['Latitude'] as num?)?.toDouble(),
      longitude: (json['Longitude'] as num?)?.toDouble(),
      w3wJson: json['w3wJson'] as String?,
      eventDescription: json['EventDescription'] as String?,
      eventImage: json['EventImage'] as String?,
      eventUrl: json['EventUrl'] as String?,
      tags1: (json['Tags1'] as num?)?.toInt() ?? 0,
      tags2: (json['Tags2'] as num?)?.toInt() ?? 0,
      tags3: (json['Tags3'] as num?)?.toInt() ?? 0,
      isCountedRun:
          json['IsCountedRun'] == true || json['IsCountedRun'] == 1,
      kennelSlug: json['KennelSlug'] as String? ?? '',
      kennelShortName: json['KennelShortName'] as String?,
      kennelName: json['KennelName'] as String? ?? '',
      kennelLogo: json['KennelLogo'] as String?,
      primaryColor: json['PrimaryColor'] as String?,
      accentColor: json['AccentColor'] as String?,
      publicKennelId: json['PublicKennelId'] as String? ?? '',
      kennelWebsiteDomain: json['KennelWebsiteDomain'] as String?,
      kennelContinent: json['KennelContinent'] as String?,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
