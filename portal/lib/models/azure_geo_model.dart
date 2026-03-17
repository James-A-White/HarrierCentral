// ignore_for_file: avoid_dynamic_calls

class AzureGeoAddress {
  AzureGeoAddress({
    this.summary,
    this.addresses,
  });

  AzureGeoAddress.fromJson(Map<String, dynamic> json) {
    summary = json['summary'] != null
        ? Summary.fromJson(json['summary'] as Map<String, dynamic>)
        : null;
    if (json['addresses'] != null) {
      final jAddr = json['addresses'] as List<dynamic>;
      addresses = <Addresses>[];

      for (final item in jAddr) {
        addresses!.add(Addresses.fromJson(item as Map<String, dynamic>));
      }
    }
  }

  Summary? summary;
  List<Addresses>? addresses;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (summary != null) {
      data['summary'] = summary!.toJson();
    }
    if (addresses != null) {
      data['addresses'] =
          addresses!.map<dynamic>((dynamic v) => v.toJson()).toList();
    }
    return data;
  }
}

class Addresses {
  Addresses({this.address, this.position});

  Addresses.fromJson(Map<String, dynamic> json) {
    address = json['address'] != null
        ? Address.fromJson(json['address'] as Map<String, dynamic>)
        : null;
    position = json['position'] as String?;
  }

  Address? address;
  String? position;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (address != null) {
      data['address'] = address!.toJson();
    }
    data['position'] = position;
    return data;
  }
}

class Address {
  Address({
    this.buildingNumber,
    this.streetNumber,
    this.routeNumbers,
    this.street,
    this.streetName,
    this.streetNameAndNumber,
    this.countryCode,
    this.countrySubdivision,
    this.municipality,
    this.postalCode,
    this.country,
    this.countryCodeISO3,
    this.freeformAddress,
    this.boundingBox,
    this.extendedPostalCode,
    this.localName,
  });

  Address.fromJson(Map<String, dynamic> json) {
    buildingNumber = json['buildingNumber'] as String?;
    streetNumber = json['streetNumber'] as String?;
    // if (json['routeNumbers'] != null) {
    //   routeNumbers = <int>[];
    //   json['routeNumbers'].forEach((dynamic v) {
    //     routeNumbers!.add(Null.fromJson(v));
    //   });
    // }
    street = json['street'] as String?;
    streetName = json['streetName'] as String?;
    streetNameAndNumber = json['streetNameAndNumber'] as String?;
    countryCode = json['countryCode'] as String?;
    countrySubdivision = json['countrySubdivision'] as String?;
    municipality = json['municipality'] as String?;
    postalCode = json['postalCode'] as String?;
    country = json['country'] as String?;
    countryCodeISO3 = json['countryCodeISO3'] as String?;
    freeformAddress = json['freeformAddress'] as String?;
    boundingBox = json['boundingBox'] != null
        ? BoundingBox.fromJson(json['boundingBox'] as Map<String, dynamic>)
        : null;
    extendedPostalCode = json['extendedPostalCode'] as String?;
    localName = json['localName'] as String?;
  }

  String? buildingNumber;
  String? streetNumber;
  List<int>? routeNumbers;
  String? street;
  String? streetName;
  String? streetNameAndNumber;
  String? countryCode;
  String? countrySubdivision;
  String? municipality;
  String? postalCode;
  String? country;
  String? countryCodeISO3;
  String? freeformAddress;
  BoundingBox? boundingBox;
  String? extendedPostalCode;
  String? localName;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['buildingNumber'] = buildingNumber;
    data['streetNumber'] = streetNumber;
    if (routeNumbers != null) {
      data['routeNumbers'] =
          routeNumbers!.map<dynamic>((dynamic v) => v.toJson()).toList();
    }
    data['street'] = street;
    data['streetName'] = streetName;
    data['streetNameAndNumber'] = streetNameAndNumber;
    data['countryCode'] = countryCode;
    data['countrySubdivision'] = countrySubdivision;
    data['municipality'] = municipality;
    data['postalCode'] = postalCode;
    data['country'] = country;
    data['countryCodeISO3'] = countryCodeISO3;
    data['freeformAddress'] = freeformAddress;
    if (boundingBox != null) {
      data['boundingBox'] = boundingBox!.toJson();
    }
    data['extendedPostalCode'] = extendedPostalCode;
    data['localName'] = localName;
    return data;
  }
}

class BoundingBox {
  BoundingBox({
    this.northEast,
    this.southWest,
    this.entity,
  });

  BoundingBox.fromJson(Map<String, dynamic> json) {
    northEast = json['northEast'] as String?;
    southWest = json['southWest'] as String?;
    entity = json['entity'] as String?;
  }

  String? northEast;
  String? southWest;
  String? entity;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['northEast'] = northEast;
    data['southWest'] = southWest;
    data['entity'] = entity;
    return data;
  }
}

class AzurePlace {
  AzurePlace({
    this.summary,
    this.results,
  });

  AzurePlace.fromJson(Map<String, dynamic> json) {
    summary = json['summary'] != null
        ? Summary.fromJson(json['summary'] as Map<String, dynamic>)
        : null;

    if (json['results'] != null) {
      results = <Results>[];
      // Safely cast to List
      final resultsJson = json['results'] as List<dynamic>;

      for (final item in resultsJson) {
        // Each item should be a Map<String, dynamic>
        results!.add(Results.fromJson(item as Map<String, dynamic>));
      }
    }
  }

  Summary? summary;
  List<Results>? results;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (summary != null) {
      data['summary'] = summary!.toJson();
    }
    if (results != null) {
      data['results'] =
          results!.map<dynamic>((dynamic v) => v.toJson()).toList();
    }
    return data;
  }
}

class Summary {
  Summary({
    this.query,
    this.queryType,
    this.queryTime,
    this.numResults,
    this.offset,
    this.totalResults,
    this.fuzzyLevel,
    this.geoBias,
  });

  Summary.fromJson(Map<String, dynamic> json) {
    query = json['query'] as String?;
    queryType = json['queryType'] as String?;
    queryTime = json['queryTime'] as int?;
    numResults = json['numResults'] as int?;
    offset = json['offset'] as int?;
    totalResults = json['totalResults'] as int?;
    fuzzyLevel = json['fuzzyLevel'] as int?;
    geoBias = json['geoBias'] != null
        ? GeoBias.fromJson(json['geoBias'] as Map<String, dynamic>)
        : null;
  }

  String? query;
  String? queryType;
  int? queryTime;
  int? numResults;
  int? offset;
  int? totalResults;
  int? fuzzyLevel;
  GeoBias? geoBias;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['query'] = query;
    data['queryType'] = queryType;
    data['queryTime'] = queryTime;
    data['numResults'] = numResults;
    data['offset'] = offset;
    data['totalResults'] = totalResults;
    data['fuzzyLevel'] = fuzzyLevel;
    if (geoBias != null) {
      data['geoBias'] = geoBias!.toJson();
    }
    return data;
  }
}

class GeoBias {
  GeoBias({
    this.lat,
    this.lon,
  });

  GeoBias.fromJson(Map<String, dynamic> json) {
    lat = json['lat'] as double?;
    lon = json['lon'] as double?;
  }

  double? lat;
  double? lon;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['lat'] = lat;
    data['lon'] = lon;
    return data;
  }
}

class Results {
  Results({
    this.type,
    this.id,
    this.score,
    this.dist,
    this.info,
    this.poi,
    this.address,
    this.position,
    this.viewport,
    this.entryPoints,
    this.dataSources,
    this.entityType,
    this.boundingBox,
  });

  Results.fromJson(Map<String, dynamic> json) {
    // Simple string/double fields
    type = json['type'] as String?;
    id = json['id'] as String?;
    score = json['score'] as double?;
    dist = json['dist'] as double?;
    info = json['info'] as String?;

    // Nested objects
    if (json['poi'] != null) {
      poi = Poi.fromJson(json['poi'] as Map<String, dynamic>);
    }
    if (json['address'] != null) {
      address = Address.fromJson(json['address'] as Map<String, dynamic>);
    }
    if (json['position'] != null) {
      position = GeoBias.fromJson(json['position'] as Map<String, dynamic>);
    }
    if (json['viewport'] != null) {
      viewport = Viewport.fromJson(json['viewport'] as Map<String, dynamic>);
    }

    // entryPoints: parse list if non-null
    if (json['entryPoints'] != null) {
      final entryPointsJson = json['entryPoints'] as List<dynamic>;
      entryPoints = entryPointsJson
          .map((item) => EntryPoints.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    // More nested objects
    if (json['dataSources'] != null) {
      dataSources =
          DataSources.fromJson(json['dataSources'] as Map<String, dynamic>);
    }

    entityType = json['entityType'] as String?;

    // boundingBox can be treated as a Viewport if that’s how the JSON is structured
    if (json['boundingBox'] != null) {
      boundingBox =
          Viewport.fromJson(json['boundingBox'] as Map<String, dynamic>);
    }
  }

  String? type;
  String? id;
  double? score;
  double? dist;
  String? info;
  Poi? poi;
  Address? address;
  GeoBias? position;
  Viewport? viewport;
  List<EntryPoints>? entryPoints;
  DataSources? dataSources;
  String? entityType;
  Viewport? boundingBox;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};

    data['type'] = type;
    data['id'] = id;
    data['score'] = score;
    data['dist'] = dist;
    data['info'] = info;

    if (poi != null) {
      data['poi'] = poi!.toJson();
    }
    if (address != null) {
      data['address'] = address!.toJson();
    }
    if (position != null) {
      data['position'] = position!.toJson();
    }
    if (viewport != null) {
      data['viewport'] = viewport!.toJson();
    }

    if (entryPoints != null) {
      data['entryPoints'] = entryPoints!.map((ep) => ep.toJson()).toList();
    }

    if (dataSources != null) {
      data['dataSources'] = dataSources!.toJson();
    }

    data['entityType'] = entityType;

    if (boundingBox != null) {
      data['boundingBox'] = boundingBox!.toJson();
    }

    return data;
  }
}

class Poi {
  Poi({
    this.name,
    this.phone,
    this.categorySet,
    this.categories,
    this.classifications,
    this.url,
  });

  // Named constructor to parse from JSON
  Poi.fromJson(Map<String, dynamic> json) {
    // Cast to String? for nullable fields
    name = json['name'] as String?;
    phone = json['phone'] as String?;

    // categorySet: parse if non-null
    if (json['categorySet'] != null) {
      final catSetJson = json['categorySet'] as List<dynamic>;
      categorySet = catSetJson
          .map((item) => CategorySet.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    // categories: parse if non-null
    if (json['categories'] != null) {
      final categoriesJson = json['categories'] as List<dynamic>;
      categories = categoriesJson.map((item) => item as String).toList();
    }

    // classifications: parse if non-null
    if (json['classifications'] != null) {
      final classificationsJson = json['classifications'] as List<dynamic>;
      classifications = classificationsJson
          .map((item) => Classifications.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    // url: cast to String?
    url = json['url'] as String?;
  }

  String? name;
  String? phone;
  List<CategorySet>? categorySet;
  List<String>? categories;
  List<Classifications>? classifications;
  String? url;

  // Convert the object back to a JSON-compatible map
  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};

    data['name'] = name;
    data['phone'] = phone;

    if (categorySet != null) {
      data['categorySet'] = categorySet!.map((cs) => cs.toJson()).toList();
    }

    data['categories'] = categories;

    if (classifications != null) {
      data['classifications'] =
          classifications!.map((c) => c.toJson()).toList();
    }

    data['url'] = url;
    return data;
  }
}

class CategorySet {
  CategorySet({this.id});

  CategorySet.fromJson(Map<String, dynamic> json) {
    id = json['id'] as int?;
  }

  int? id;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['id'] = id;
    return data;
  }
}

class Classifications {
  Classifications({
    this.code,
    this.names,
  });

  Classifications.fromJson(Map<String, dynamic> json) {
    // Cast to String? for nullable fields
    code = json['code'] as String?;

    // names: parse if non-null
    if (json['names'] != null) {
      final namesList = json['names'] as List<dynamic>;
      names = namesList
          .map((item) => Names.fromJson(item as Map<String, dynamic>))
          .toList();
    }
  }

  String? code;
  List<Names>? names;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['code'] = code;
    if (names != null) {
      data['names'] = names!.map((item) => item.toJson()).toList();
    }
    return data;
  }
}

class Names {
  Names({
    this.nameLocale,
    this.name,
  });

  Names.fromJson(Map<String, dynamic> json) {
    nameLocale = json['nameLocale'] as String?;
    name = json['name'] as String?;
  }

  String? nameLocale;
  String? name;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['nameLocale'] = nameLocale;
    data['name'] = name;
    return data;
  }
}

class Viewport {
  Viewport({
    this.topLeftPoint,
    this.btmRightPoint,
  });

  Viewport.fromJson(Map<String, dynamic> json) {
    // Safely parse nested objects
    if (json['topLeftPoint'] != null) {
      topLeftPoint =
          GeoBias.fromJson(json['topLeftPoint'] as Map<String, dynamic>);
    }
    if (json['btmRightPoint'] != null) {
      btmRightPoint =
          GeoBias.fromJson(json['btmRightPoint'] as Map<String, dynamic>);
    }
  }

  GeoBias? topLeftPoint;
  GeoBias? btmRightPoint;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (topLeftPoint != null) {
      data['topLeftPoint'] = topLeftPoint!.toJson();
    }
    if (btmRightPoint != null) {
      data['btmRightPoint'] = btmRightPoint!.toJson();
    }
    return data;
  }
}

// // Example GeoBias class (not provided in your snippet).
// // Make sure to fix it similarly if needed.
// class GeoBias {
//   GeoBias({this.latitude, this.longitude});

//   GeoBias.fromJson(Map<String, dynamic> json) {
//     latitude = json['latitude'] as double?;
//     longitude = json['longitude'] as double?;
//   }

//   double? latitude;
//   double? longitude;

//   Map<String, dynamic> toJson() {
//     return {
//       'latitude': latitude,
//       'longitude': longitude,
//     };
//   }
// }

class EntryPoints {
  EntryPoints({
    this.type,
    this.position,
  });

  EntryPoints.fromJson(Map<String, dynamic> json) {
    type = json['type'] as String?;
    if (json['position'] != null) {
      position = GeoBias.fromJson(json['position'] as Map<String, dynamic>);
    }
  }

  String? type;
  GeoBias? position;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['type'] = type;
    if (position != null) {
      data['position'] = position!.toJson();
    }
    return data;
  }
}

class DataSources {
  DataSources({
    this.poiDetails,
    this.geometry,
  });

  DataSources.fromJson(Map<String, dynamic> json) {
    // poiDetails: parse if non-null
    if (json['poiDetails'] != null) {
      final detailsList = json['poiDetails'] as List<dynamic>;
      poiDetails = detailsList
          .map((item) => PoiDetails.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    // geometry: parse if non-null
    if (json['geometry'] != null) {
      geometry = Geometry.fromJson(json['geometry'] as Map<String, dynamic>);
    }
  }

  List<PoiDetails>? poiDetails;
  Geometry? geometry;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (poiDetails != null) {
      data['poiDetails'] = poiDetails!.map((item) => item.toJson()).toList();
    }
    if (geometry != null) {
      data['geometry'] = geometry!.toJson();
    }
    return data;
  }
}

class PoiDetails {
  PoiDetails({
    this.id,
    this.sourceName,
  });

  PoiDetails.fromJson(Map<String, dynamic> json) {
    id = json['id'] as String?;
    sourceName = json['sourceName'] as String?;
  }

  String? id;
  String? sourceName;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['id'] = id;
    data['sourceName'] = sourceName;
    return data;
  }
}

class Geometry {
  Geometry({this.id});

  Geometry.fromJson(Map<String, dynamic> json) {
    id = json['id'] as String?;
  }

  String? id;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['id'] = id;
    return data;
  }
}
