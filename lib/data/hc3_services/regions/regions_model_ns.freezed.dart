// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'regions_model_ns.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

RegionsModel _$RegionsModelFromJson(Map<String, dynamic> json) {
  return _RegionsModel.fromJson(json);
}

/// @nodoc
mixin _$RegionsModel {
  String? get regionId => throw _privateConstructorUsedError;
  String? get regionName => throw _privateConstructorUsedError;
  String? get regionSearchTags => throw _privateConstructorUsedError;
  String? get regionAbbreviation => throw _privateConstructorUsedError;
  String? get countryId => throw _privateConstructorUsedError;
  String? get flagFile => throw _privateConstructorUsedError;
  int? get removed => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $RegionsModelCopyWith<RegionsModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RegionsModelCopyWith<$Res> {
  factory $RegionsModelCopyWith(
          RegionsModel value, $Res Function(RegionsModel) then) =
      _$RegionsModelCopyWithImpl<$Res, RegionsModel>;
  @useResult
  $Res call(
      {String? regionId,
      String? regionName,
      String? regionSearchTags,
      String? regionAbbreviation,
      String? countryId,
      String? flagFile,
      int? removed,
      DateTime? updatedAt});
}

/// @nodoc
class _$RegionsModelCopyWithImpl<$Res, $Val extends RegionsModel>
    implements $RegionsModelCopyWith<$Res> {
  _$RegionsModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? regionId = freezed,
    Object? regionName = freezed,
    Object? regionSearchTags = freezed,
    Object? regionAbbreviation = freezed,
    Object? countryId = freezed,
    Object? flagFile = freezed,
    Object? removed = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_value.copyWith(
      regionId: freezed == regionId
          ? _value.regionId
          : regionId // ignore: cast_nullable_to_non_nullable
              as String?,
      regionName: freezed == regionName
          ? _value.regionName
          : regionName // ignore: cast_nullable_to_non_nullable
              as String?,
      regionSearchTags: freezed == regionSearchTags
          ? _value.regionSearchTags
          : regionSearchTags // ignore: cast_nullable_to_non_nullable
              as String?,
      regionAbbreviation: freezed == regionAbbreviation
          ? _value.regionAbbreviation
          : regionAbbreviation // ignore: cast_nullable_to_non_nullable
              as String?,
      countryId: freezed == countryId
          ? _value.countryId
          : countryId // ignore: cast_nullable_to_non_nullable
              as String?,
      flagFile: freezed == flagFile
          ? _value.flagFile
          : flagFile // ignore: cast_nullable_to_non_nullable
              as String?,
      removed: freezed == removed
          ? _value.removed
          : removed // ignore: cast_nullable_to_non_nullable
              as int?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_RegionsModelCopyWith<$Res>
    implements $RegionsModelCopyWith<$Res> {
  factory _$$_RegionsModelCopyWith(
          _$_RegionsModel value, $Res Function(_$_RegionsModel) then) =
      __$$_RegionsModelCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String? regionId,
      String? regionName,
      String? regionSearchTags,
      String? regionAbbreviation,
      String? countryId,
      String? flagFile,
      int? removed,
      DateTime? updatedAt});
}

/// @nodoc
class __$$_RegionsModelCopyWithImpl<$Res>
    extends _$RegionsModelCopyWithImpl<$Res, _$_RegionsModel>
    implements _$$_RegionsModelCopyWith<$Res> {
  __$$_RegionsModelCopyWithImpl(
      _$_RegionsModel _value, $Res Function(_$_RegionsModel) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? regionId = freezed,
    Object? regionName = freezed,
    Object? regionSearchTags = freezed,
    Object? regionAbbreviation = freezed,
    Object? countryId = freezed,
    Object? flagFile = freezed,
    Object? removed = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_$_RegionsModel(
      regionId: freezed == regionId
          ? _value.regionId
          : regionId // ignore: cast_nullable_to_non_nullable
              as String?,
      regionName: freezed == regionName
          ? _value.regionName
          : regionName // ignore: cast_nullable_to_non_nullable
              as String?,
      regionSearchTags: freezed == regionSearchTags
          ? _value.regionSearchTags
          : regionSearchTags // ignore: cast_nullable_to_non_nullable
              as String?,
      regionAbbreviation: freezed == regionAbbreviation
          ? _value.regionAbbreviation
          : regionAbbreviation // ignore: cast_nullable_to_non_nullable
              as String?,
      countryId: freezed == countryId
          ? _value.countryId
          : countryId // ignore: cast_nullable_to_non_nullable
              as String?,
      flagFile: freezed == flagFile
          ? _value.flagFile
          : flagFile // ignore: cast_nullable_to_non_nullable
              as String?,
      removed: freezed == removed
          ? _value.removed
          : removed // ignore: cast_nullable_to_non_nullable
              as int?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_RegionsModel implements _RegionsModel {
  _$_RegionsModel(
      {required this.regionId,
      required this.regionName,
      required this.regionSearchTags,
      required this.regionAbbreviation,
      required this.countryId,
      required this.flagFile,
      required this.removed,
      required this.updatedAt});

  factory _$_RegionsModel.fromJson(Map<String, dynamic> json) =>
      _$$_RegionsModelFromJson(json);

  @override
  final String? regionId;
  @override
  final String? regionName;
  @override
  final String? regionSearchTags;
  @override
  final String? regionAbbreviation;
  @override
  final String? countryId;
  @override
  final String? flagFile;
  @override
  final int? removed;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'RegionsModel(regionId: $regionId, regionName: $regionName, regionSearchTags: $regionSearchTags, regionAbbreviation: $regionAbbreviation, countryId: $countryId, flagFile: $flagFile, removed: $removed, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_RegionsModel &&
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

  @JsonKey(ignore: true)
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

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_RegionsModelCopyWith<_$_RegionsModel> get copyWith =>
      __$$_RegionsModelCopyWithImpl<_$_RegionsModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_RegionsModelToJson(
      this,
    );
  }
}

abstract class _RegionsModel implements RegionsModel {
  factory _RegionsModel(
      {required final String? regionId,
      required final String? regionName,
      required final String? regionSearchTags,
      required final String? regionAbbreviation,
      required final String? countryId,
      required final String? flagFile,
      required final int? removed,
      required final DateTime? updatedAt}) = _$_RegionsModel;

  factory _RegionsModel.fromJson(Map<String, dynamic> json) =
      _$_RegionsModel.fromJson;

  @override
  String? get regionId;
  @override
  String? get regionName;
  @override
  String? get regionSearchTags;
  @override
  String? get regionAbbreviation;
  @override
  String? get countryId;
  @override
  String? get flagFile;
  @override
  int? get removed;
  @override
  DateTime? get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$_RegionsModelCopyWith<_$_RegionsModel> get copyWith =>
      throw _privateConstructorUsedError;
}
