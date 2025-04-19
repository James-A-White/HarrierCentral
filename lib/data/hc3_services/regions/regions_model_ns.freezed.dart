// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'regions_model_ns.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RegionsModel implements DiagnosticableTreeMixin {
  String get regionId;
  String get regionName;
  String? get regionSearchTags;
  String? get regionAbbreviation;
  String get countryId;
  String? get flagFile;
  int? get removed;
  DateTime? get updatedAt;

  /// Create a copy of RegionsModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $RegionsModelCopyWith<RegionsModel> get copyWith =>
      _$RegionsModelCopyWithImpl<RegionsModel>(
          this as RegionsModel, _$identity);

  /// Serializes this RegionsModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'RegionsModel'))
      ..add(DiagnosticsProperty('regionId', regionId))
      ..add(DiagnosticsProperty('regionName', regionName))
      ..add(DiagnosticsProperty('regionSearchTags', regionSearchTags))
      ..add(DiagnosticsProperty('regionAbbreviation', regionAbbreviation))
      ..add(DiagnosticsProperty('countryId', countryId))
      ..add(DiagnosticsProperty('flagFile', flagFile))
      ..add(DiagnosticsProperty('removed', removed))
      ..add(DiagnosticsProperty('updatedAt', updatedAt));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is RegionsModel &&
            (identical(other.regionId, regionId) ||
                other.regionId == regionId) &&
            (identical(other.regionName, regionName) ||
                other.regionName == regionName) &&
            (identical(other.regionSearchTags, regionSearchTags) ||
                other.regionSearchTags == regionSearchTags) &&
            (identical(other.regionAbbreviation, regionAbbreviation) ||
                other.regionAbbreviation == regionAbbreviation) &&
            (identical(other.countryId, countryId) ||
                other.countryId == countryId) &&
            (identical(other.flagFile, flagFile) ||
                other.flagFile == flagFile) &&
            (identical(other.removed, removed) || other.removed == removed) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      regionId,
      regionName,
      regionSearchTags,
      regionAbbreviation,
      countryId,
      flagFile,
      removed,
      updatedAt);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'RegionsModel(regionId: $regionId, regionName: $regionName, regionSearchTags: $regionSearchTags, regionAbbreviation: $regionAbbreviation, countryId: $countryId, flagFile: $flagFile, removed: $removed, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class $RegionsModelCopyWith<$Res> {
  factory $RegionsModelCopyWith(
          RegionsModel value, $Res Function(RegionsModel) _then) =
      _$RegionsModelCopyWithImpl;
  @useResult
  $Res call(
      {String regionId,
      String regionName,
      String? regionSearchTags,
      String? regionAbbreviation,
      String countryId,
      String? flagFile,
      int? removed,
      DateTime? updatedAt});
}

/// @nodoc
class _$RegionsModelCopyWithImpl<$Res> implements $RegionsModelCopyWith<$Res> {
  _$RegionsModelCopyWithImpl(this._self, this._then);

  final RegionsModel _self;
  final $Res Function(RegionsModel) _then;

  /// Create a copy of RegionsModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? regionId = null,
    Object? regionName = null,
    Object? regionSearchTags = freezed,
    Object? regionAbbreviation = freezed,
    Object? countryId = null,
    Object? flagFile = freezed,
    Object? removed = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_self.copyWith(
      regionId: null == regionId
          ? _self.regionId
          : regionId // ignore: cast_nullable_to_non_nullable
              as String,
      regionName: null == regionName
          ? _self.regionName
          : regionName // ignore: cast_nullable_to_non_nullable
              as String,
      regionSearchTags: freezed == regionSearchTags
          ? _self.regionSearchTags
          : regionSearchTags // ignore: cast_nullable_to_non_nullable
              as String?,
      regionAbbreviation: freezed == regionAbbreviation
          ? _self.regionAbbreviation
          : regionAbbreviation // ignore: cast_nullable_to_non_nullable
              as String?,
      countryId: null == countryId
          ? _self.countryId
          : countryId // ignore: cast_nullable_to_non_nullable
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
class _RegionsModel with DiagnosticableTreeMixin implements RegionsModel {
  _RegionsModel(
      {required this.regionId,
      required this.regionName,
      this.regionSearchTags,
      this.regionAbbreviation,
      required this.countryId,
      this.flagFile,
      this.removed,
      this.updatedAt});
  factory _RegionsModel.fromJson(Map<String, dynamic> json) =>
      _$RegionsModelFromJson(json);

  @override
  final String regionId;
  @override
  final String regionName;
  @override
  final String? regionSearchTags;
  @override
  final String? regionAbbreviation;
  @override
  final String countryId;
  @override
  final String? flagFile;
  @override
  final int? removed;
  @override
  final DateTime? updatedAt;

  /// Create a copy of RegionsModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$RegionsModelCopyWith<_RegionsModel> get copyWith =>
      __$RegionsModelCopyWithImpl<_RegionsModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$RegionsModelToJson(
      this,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'RegionsModel'))
      ..add(DiagnosticsProperty('regionId', regionId))
      ..add(DiagnosticsProperty('regionName', regionName))
      ..add(DiagnosticsProperty('regionSearchTags', regionSearchTags))
      ..add(DiagnosticsProperty('regionAbbreviation', regionAbbreviation))
      ..add(DiagnosticsProperty('countryId', countryId))
      ..add(DiagnosticsProperty('flagFile', flagFile))
      ..add(DiagnosticsProperty('removed', removed))
      ..add(DiagnosticsProperty('updatedAt', updatedAt));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _RegionsModel &&
            (identical(other.regionId, regionId) ||
                other.regionId == regionId) &&
            (identical(other.regionName, regionName) ||
                other.regionName == regionName) &&
            (identical(other.regionSearchTags, regionSearchTags) ||
                other.regionSearchTags == regionSearchTags) &&
            (identical(other.regionAbbreviation, regionAbbreviation) ||
                other.regionAbbreviation == regionAbbreviation) &&
            (identical(other.countryId, countryId) ||
                other.countryId == countryId) &&
            (identical(other.flagFile, flagFile) ||
                other.flagFile == flagFile) &&
            (identical(other.removed, removed) || other.removed == removed) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      regionId,
      regionName,
      regionSearchTags,
      regionAbbreviation,
      countryId,
      flagFile,
      removed,
      updatedAt);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'RegionsModel(regionId: $regionId, regionName: $regionName, regionSearchTags: $regionSearchTags, regionAbbreviation: $regionAbbreviation, countryId: $countryId, flagFile: $flagFile, removed: $removed, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class _$RegionsModelCopyWith<$Res>
    implements $RegionsModelCopyWith<$Res> {
  factory _$RegionsModelCopyWith(
          _RegionsModel value, $Res Function(_RegionsModel) _then) =
      __$RegionsModelCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String regionId,
      String regionName,
      String? regionSearchTags,
      String? regionAbbreviation,
      String countryId,
      String? flagFile,
      int? removed,
      DateTime? updatedAt});
}

/// @nodoc
class __$RegionsModelCopyWithImpl<$Res>
    implements _$RegionsModelCopyWith<$Res> {
  __$RegionsModelCopyWithImpl(this._self, this._then);

  final _RegionsModel _self;
  final $Res Function(_RegionsModel) _then;

  /// Create a copy of RegionsModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? regionId = null,
    Object? regionName = null,
    Object? regionSearchTags = freezed,
    Object? regionAbbreviation = freezed,
    Object? countryId = null,
    Object? flagFile = freezed,
    Object? removed = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_RegionsModel(
      regionId: null == regionId
          ? _self.regionId
          : regionId // ignore: cast_nullable_to_non_nullable
              as String,
      regionName: null == regionName
          ? _self.regionName
          : regionName // ignore: cast_nullable_to_non_nullable
              as String,
      regionSearchTags: freezed == regionSearchTags
          ? _self.regionSearchTags
          : regionSearchTags // ignore: cast_nullable_to_non_nullable
              as String?,
      regionAbbreviation: freezed == regionAbbreviation
          ? _self.regionAbbreviation
          : regionAbbreviation // ignore: cast_nullable_to_non_nullable
              as String?,
      countryId: null == countryId
          ? _self.countryId
          : countryId // ignore: cast_nullable_to_non_nullable
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
