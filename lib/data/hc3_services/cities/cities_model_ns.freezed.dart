// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cities_model_ns.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CitiesModel implements DiagnosticableTreeMixin {
  String get cityId;
  String get cityName;
  String? get citySearchTags;
  String get regionId;
  double get latitude;
  double get longitude;
  String get cityAscii;
  String? get flagFile;
  int? get removed;
  DateTime? get updatedAt;

  /// Create a copy of CitiesModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $CitiesModelCopyWith<CitiesModel> get copyWith =>
      _$CitiesModelCopyWithImpl<CitiesModel>(this as CitiesModel, _$identity);

  /// Serializes this CitiesModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'CitiesModel'))
      ..add(DiagnosticsProperty('cityId', cityId))
      ..add(DiagnosticsProperty('cityName', cityName))
      ..add(DiagnosticsProperty('citySearchTags', citySearchTags))
      ..add(DiagnosticsProperty('regionId', regionId))
      ..add(DiagnosticsProperty('latitude', latitude))
      ..add(DiagnosticsProperty('longitude', longitude))
      ..add(DiagnosticsProperty('cityAscii', cityAscii))
      ..add(DiagnosticsProperty('flagFile', flagFile))
      ..add(DiagnosticsProperty('removed', removed))
      ..add(DiagnosticsProperty('updatedAt', updatedAt));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is CitiesModel &&
            (identical(other.cityId, cityId) || other.cityId == cityId) &&
            (identical(other.cityName, cityName) ||
                other.cityName == cityName) &&
            (identical(other.citySearchTags, citySearchTags) ||
                other.citySearchTags == citySearchTags) &&
            (identical(other.regionId, regionId) ||
                other.regionId == regionId) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.cityAscii, cityAscii) ||
                other.cityAscii == cityAscii) &&
            (identical(other.flagFile, flagFile) ||
                other.flagFile == flagFile) &&
            (identical(other.removed, removed) || other.removed == removed) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, cityId, cityName, citySearchTags,
      regionId, latitude, longitude, cityAscii, flagFile, removed, updatedAt);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'CitiesModel(cityId: $cityId, cityName: $cityName, citySearchTags: $citySearchTags, regionId: $regionId, latitude: $latitude, longitude: $longitude, cityAscii: $cityAscii, flagFile: $flagFile, removed: $removed, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class $CitiesModelCopyWith<$Res> {
  factory $CitiesModelCopyWith(
          CitiesModel value, $Res Function(CitiesModel) _then) =
      _$CitiesModelCopyWithImpl;
  @useResult
  $Res call(
      {String cityId,
      String cityName,
      String? citySearchTags,
      String regionId,
      double latitude,
      double longitude,
      String cityAscii,
      String? flagFile,
      int? removed,
      DateTime? updatedAt});
}

/// @nodoc
class _$CitiesModelCopyWithImpl<$Res> implements $CitiesModelCopyWith<$Res> {
  _$CitiesModelCopyWithImpl(this._self, this._then);

  final CitiesModel _self;
  final $Res Function(CitiesModel) _then;

  /// Create a copy of CitiesModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? cityId = null,
    Object? cityName = null,
    Object? citySearchTags = freezed,
    Object? regionId = null,
    Object? latitude = null,
    Object? longitude = null,
    Object? cityAscii = null,
    Object? flagFile = freezed,
    Object? removed = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_self.copyWith(
      cityId: null == cityId
          ? _self.cityId
          : cityId // ignore: cast_nullable_to_non_nullable
              as String,
      cityName: null == cityName
          ? _self.cityName
          : cityName // ignore: cast_nullable_to_non_nullable
              as String,
      citySearchTags: freezed == citySearchTags
          ? _self.citySearchTags
          : citySearchTags // ignore: cast_nullable_to_non_nullable
              as String?,
      regionId: null == regionId
          ? _self.regionId
          : regionId // ignore: cast_nullable_to_non_nullable
              as String,
      latitude: null == latitude
          ? _self.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double,
      longitude: null == longitude
          ? _self.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double,
      cityAscii: null == cityAscii
          ? _self.cityAscii
          : cityAscii // ignore: cast_nullable_to_non_nullable
              as String,
      flagFile: freezed == flagFile
          ? _self.flagFile
          : flagFile // ignore: cast_nullable_to_non_nullable
              as String?,
      removed: freezed == removed
          ? _self.removed
          : removed // ignore: cast_nullable_to_non_nullable
              as int?,
      updatedAt: freezed == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _CitiesModel with DiagnosticableTreeMixin implements CitiesModel {
  const _CitiesModel(
      {required this.cityId,
      required this.cityName,
      this.citySearchTags,
      required this.regionId,
      required this.latitude,
      required this.longitude,
      required this.cityAscii,
      this.flagFile,
      this.removed,
      this.updatedAt});
  factory _CitiesModel.fromJson(Map<String, dynamic> json) =>
      _$CitiesModelFromJson(json);

  @override
  final String cityId;
  @override
  final String cityName;
  @override
  final String? citySearchTags;
  @override
  final String regionId;
  @override
  final double latitude;
  @override
  final double longitude;
  @override
  final String cityAscii;
  @override
  final String? flagFile;
  @override
  final int? removed;
  @override
  final DateTime? updatedAt;

  /// Create a copy of CitiesModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$CitiesModelCopyWith<_CitiesModel> get copyWith =>
      __$CitiesModelCopyWithImpl<_CitiesModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$CitiesModelToJson(
      this,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'CitiesModel'))
      ..add(DiagnosticsProperty('cityId', cityId))
      ..add(DiagnosticsProperty('cityName', cityName))
      ..add(DiagnosticsProperty('citySearchTags', citySearchTags))
      ..add(DiagnosticsProperty('regionId', regionId))
      ..add(DiagnosticsProperty('latitude', latitude))
      ..add(DiagnosticsProperty('longitude', longitude))
      ..add(DiagnosticsProperty('cityAscii', cityAscii))
      ..add(DiagnosticsProperty('flagFile', flagFile))
      ..add(DiagnosticsProperty('removed', removed))
      ..add(DiagnosticsProperty('updatedAt', updatedAt));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _CitiesModel &&
            (identical(other.cityId, cityId) || other.cityId == cityId) &&
            (identical(other.cityName, cityName) ||
                other.cityName == cityName) &&
            (identical(other.citySearchTags, citySearchTags) ||
                other.citySearchTags == citySearchTags) &&
            (identical(other.regionId, regionId) ||
                other.regionId == regionId) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.cityAscii, cityAscii) ||
                other.cityAscii == cityAscii) &&
            (identical(other.flagFile, flagFile) ||
                other.flagFile == flagFile) &&
            (identical(other.removed, removed) || other.removed == removed) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, cityId, cityName, citySearchTags,
      regionId, latitude, longitude, cityAscii, flagFile, removed, updatedAt);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'CitiesModel(cityId: $cityId, cityName: $cityName, citySearchTags: $citySearchTags, regionId: $regionId, latitude: $latitude, longitude: $longitude, cityAscii: $cityAscii, flagFile: $flagFile, removed: $removed, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class _$CitiesModelCopyWith<$Res>
    implements $CitiesModelCopyWith<$Res> {
  factory _$CitiesModelCopyWith(
          _CitiesModel value, $Res Function(_CitiesModel) _then) =
      __$CitiesModelCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String cityId,
      String cityName,
      String? citySearchTags,
      String regionId,
      double latitude,
      double longitude,
      String cityAscii,
      String? flagFile,
      int? removed,
      DateTime? updatedAt});
}

/// @nodoc
class __$CitiesModelCopyWithImpl<$Res> implements _$CitiesModelCopyWith<$Res> {
  __$CitiesModelCopyWithImpl(this._self, this._then);

  final _CitiesModel _self;
  final $Res Function(_CitiesModel) _then;

  /// Create a copy of CitiesModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? cityId = null,
    Object? cityName = null,
    Object? citySearchTags = freezed,
    Object? regionId = null,
    Object? latitude = null,
    Object? longitude = null,
    Object? cityAscii = null,
    Object? flagFile = freezed,
    Object? removed = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_CitiesModel(
      cityId: null == cityId
          ? _self.cityId
          : cityId // ignore: cast_nullable_to_non_nullable
              as String,
      cityName: null == cityName
          ? _self.cityName
          : cityName // ignore: cast_nullable_to_non_nullable
              as String,
      citySearchTags: freezed == citySearchTags
          ? _self.citySearchTags
          : citySearchTags // ignore: cast_nullable_to_non_nullable
              as String?,
      regionId: null == regionId
          ? _self.regionId
          : regionId // ignore: cast_nullable_to_non_nullable
              as String,
      latitude: null == latitude
          ? _self.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double,
      longitude: null == longitude
          ? _self.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double,
      cityAscii: null == cityAscii
          ? _self.cityAscii
          : cityAscii // ignore: cast_nullable_to_non_nullable
              as String,
      flagFile: freezed == flagFile
          ? _self.flagFile
          : flagFile // ignore: cast_nullable_to_non_nullable
              as String?,
      removed: freezed == removed
          ? _self.removed
          : removed // ignore: cast_nullable_to_non_nullable
              as int?,
      updatedAt: freezed == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

// dart format on
