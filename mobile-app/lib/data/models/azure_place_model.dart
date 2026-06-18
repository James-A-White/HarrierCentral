// ignore_for_file: avoid_dynamic_calls

// Models for the Azure Maps Search (fuzzy/place) API response.
// Used by the gazetteer location lookup in the edit run details screen.

class AzurePlace {
  AzurePlace({this.summary, this.results});

  AzurePlace.fromJson(Map<String, dynamic> json) {
    summary = json['summary'] != null
        ? AzurePlaceSummary.fromJson(json['summary'] as Map<String, dynamic>)
        : null;
    if (json['results'] != null) {
      results = (json['results'] as List<dynamic>)
          .map((item) => AzurePlaceResult.fromJson(item as Map<String, dynamic>))
          .toList();
    }
  }

  AzurePlaceSummary? summary;
  List<AzurePlaceResult>? results;
}

class AzurePlaceSummary {
  AzurePlaceSummary({this.query, this.numResults, this.totalResults});

  AzurePlaceSummary.fromJson(Map<String, dynamic> json) {
    query = json['query'] as String?;
    numResults = json['numResults'] as int?;
    totalResults = json['totalResults'] as int?;
  }

  String? query;
  int? numResults;
  int? totalResults;
}

class AzurePlaceResult {
  AzurePlaceResult({this.type, this.id, this.score, this.poi, this.address, this.position});

  AzurePlaceResult.fromJson(Map<String, dynamic> json) {
    type = json['type'] as String?;
    id = json['id'] as String?;
    score = json['score'] as double?;
    if (json['poi'] != null) {
      poi = AzurePlacePoi.fromJson(json['poi'] as Map<String, dynamic>);
    }
    if (json['address'] != null) {
      address = AzurePlaceAddress.fromJson(json['address'] as Map<String, dynamic>);
    }
    if (json['position'] != null) {
      position = AzurePlaceLatLon.fromJson(json['position'] as Map<String, dynamic>);
    }
  }

  String? type;
  String? id;
  double? score;
  AzurePlacePoi? poi;
  AzurePlaceAddress? address;
  AzurePlaceLatLon? position;
}

class AzurePlacePoi {
  AzurePlacePoi({this.name});

  AzurePlacePoi.fromJson(Map<String, dynamic> json) {
    name = json['name'] as String?;
  }

  String? name;
}

class AzurePlaceAddress {
  AzurePlaceAddress({
    this.streetNameAndNumber,
    this.streetName,
    this.municipality,
    this.countrySubdivision,
    this.postalCode,
    this.country,
    this.countryCode,
    this.freeformAddress,
    this.localName,
  });

  AzurePlaceAddress.fromJson(Map<String, dynamic> json) {
    streetNameAndNumber = json['streetNameAndNumber'] as String?;
    streetName = json['streetName'] as String?;
    municipality = json['municipality'] as String?;
    countrySubdivision = json['countrySubdivision'] as String?;
    postalCode = json['postalCode'] as String?;
    country = json['country'] as String?;
    countryCode = json['countryCode'] as String?;
    freeformAddress = json['freeformAddress'] as String?;
    localName = json['localName'] as String?;
  }

  String? streetNameAndNumber;
  String? streetName;
  String? municipality;
  String? countrySubdivision;
  String? postalCode;
  String? country;
  String? countryCode;
  String? freeformAddress;
  String? localName;
}

class AzurePlaceLatLon {
  AzurePlaceLatLon({this.lat, this.lon});

  AzurePlaceLatLon.fromJson(Map<String, dynamic> json) {
    lat = json['lat'] as double?;
    lon = json['lon'] as double?;
  }

  double? lat;
  double? lon;
}
