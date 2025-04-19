// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'hashers_model_ns.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HashersModel implements DiagnosticableTreeMixin {
  String get hasherId;
  String? get firstName;
  String? get lastName;
  String get dispName;
  String? get hashName;
  String? get photo;
  int get dispPref;
  int get includeInGlobalHashDirectory;
  int? get removed;
  DateTime? get updatedAt;

  /// Create a copy of HashersModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $HashersModelCopyWith<HashersModel> get copyWith =>
      _$HashersModelCopyWithImpl<HashersModel>(
          this as HashersModel, _$identity);

  /// Serializes this HashersModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'HashersModel'))
      ..add(DiagnosticsProperty('hasherId', hasherId))
      ..add(DiagnosticsProperty('firstName', firstName))
      ..add(DiagnosticsProperty('lastName', lastName))
      ..add(DiagnosticsProperty('dispName', dispName))
      ..add(DiagnosticsProperty('hashName', hashName))
      ..add(DiagnosticsProperty('photo', photo))
      ..add(DiagnosticsProperty('dispPref', dispPref))
      ..add(DiagnosticsProperty(
          'includeInGlobalHashDirectory', includeInGlobalHashDirectory))
      ..add(DiagnosticsProperty('removed', removed))
      ..add(DiagnosticsProperty('updatedAt', updatedAt));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is HashersModel &&
            (identical(other.hasherId, hasherId) ||
                other.hasherId == hasherId) &&
            (identical(other.firstName, firstName) ||
                other.firstName == firstName) &&
            (identical(other.lastName, lastName) ||
                other.lastName == lastName) &&
            (identical(other.dispName, dispName) ||
                other.dispName == dispName) &&
            (identical(other.hashName, hashName) ||
                other.hashName == hashName) &&
            (identical(other.photo, photo) || other.photo == photo) &&
            (identical(other.dispPref, dispPref) ||
                other.dispPref == dispPref) &&
            (identical(other.includeInGlobalHashDirectory,
                    includeInGlobalHashDirectory) ||
                other.includeInGlobalHashDirectory ==
                    includeInGlobalHashDirectory) &&
            (identical(other.removed, removed) || other.removed == removed) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      hasherId,
      firstName,
      lastName,
      dispName,
      hashName,
      photo,
      dispPref,
      includeInGlobalHashDirectory,
      removed,
      updatedAt);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'HashersModel(hasherId: $hasherId, firstName: $firstName, lastName: $lastName, dispName: $dispName, hashName: $hashName, photo: $photo, dispPref: $dispPref, includeInGlobalHashDirectory: $includeInGlobalHashDirectory, removed: $removed, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class $HashersModelCopyWith<$Res> {
  factory $HashersModelCopyWith(
          HashersModel value, $Res Function(HashersModel) _then) =
      _$HashersModelCopyWithImpl;
  @useResult
  $Res call(
      {String hasherId,
      String? firstName,
      String? lastName,
      String dispName,
      String? hashName,
      String? photo,
      int dispPref,
      int includeInGlobalHashDirectory,
      int? removed,
      DateTime? updatedAt});
}

/// @nodoc
class _$HashersModelCopyWithImpl<$Res> implements $HashersModelCopyWith<$Res> {
  _$HashersModelCopyWithImpl(this._self, this._then);

  final HashersModel _self;
  final $Res Function(HashersModel) _then;

  /// Create a copy of HashersModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? hasherId = null,
    Object? firstName = freezed,
    Object? lastName = freezed,
    Object? dispName = null,
    Object? hashName = freezed,
    Object? photo = freezed,
    Object? dispPref = null,
    Object? includeInGlobalHashDirectory = null,
    Object? removed = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_self.copyWith(
      hasherId: null == hasherId
          ? _self.hasherId
          : hasherId // ignore: cast_nullable_to_non_nullable
              as String,
      firstName: freezed == firstName
          ? _self.firstName
          : firstName // ignore: cast_nullable_to_non_nullable
              as String?,
      lastName: freezed == lastName
          ? _self.lastName
          : lastName // ignore: cast_nullable_to_non_nullable
              as String?,
      dispName: null == dispName
          ? _self.dispName
          : dispName // ignore: cast_nullable_to_non_nullable
              as String,
      hashName: freezed == hashName
          ? _self.hashName
          : hashName // ignore: cast_nullable_to_non_nullable
              as String?,
      photo: freezed == photo
          ? _self.photo
          : photo // ignore: cast_nullable_to_non_nullable
              as String?,
      dispPref: null == dispPref
          ? _self.dispPref
          : dispPref // ignore: cast_nullable_to_non_nullable
              as int,
      includeInGlobalHashDirectory: null == includeInGlobalHashDirectory
          ? _self.includeInGlobalHashDirectory
          : includeInGlobalHashDirectory // ignore: cast_nullable_to_non_nullable
              as int,
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
class _HashersModel with DiagnosticableTreeMixin implements HashersModel {
  _HashersModel(
      {required this.hasherId,
      this.firstName,
      this.lastName,
      required this.dispName,
      this.hashName,
      this.photo,
      required this.dispPref,
      required this.includeInGlobalHashDirectory,
      this.removed,
      this.updatedAt});
  factory _HashersModel.fromJson(Map<String, dynamic> json) =>
      _$HashersModelFromJson(json);

  @override
  final String hasherId;
  @override
  final String? firstName;
  @override
  final String? lastName;
  @override
  final String dispName;
  @override
  final String? hashName;
  @override
  final String? photo;
  @override
  final int dispPref;
  @override
  final int includeInGlobalHashDirectory;
  @override
  final int? removed;
  @override
  final DateTime? updatedAt;

  /// Create a copy of HashersModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$HashersModelCopyWith<_HashersModel> get copyWith =>
      __$HashersModelCopyWithImpl<_HashersModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$HashersModelToJson(
      this,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'HashersModel'))
      ..add(DiagnosticsProperty('hasherId', hasherId))
      ..add(DiagnosticsProperty('firstName', firstName))
      ..add(DiagnosticsProperty('lastName', lastName))
      ..add(DiagnosticsProperty('dispName', dispName))
      ..add(DiagnosticsProperty('hashName', hashName))
      ..add(DiagnosticsProperty('photo', photo))
      ..add(DiagnosticsProperty('dispPref', dispPref))
      ..add(DiagnosticsProperty(
          'includeInGlobalHashDirectory', includeInGlobalHashDirectory))
      ..add(DiagnosticsProperty('removed', removed))
      ..add(DiagnosticsProperty('updatedAt', updatedAt));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _HashersModel &&
            (identical(other.hasherId, hasherId) ||
                other.hasherId == hasherId) &&
            (identical(other.firstName, firstName) ||
                other.firstName == firstName) &&
            (identical(other.lastName, lastName) ||
                other.lastName == lastName) &&
            (identical(other.dispName, dispName) ||
                other.dispName == dispName) &&
            (identical(other.hashName, hashName) ||
                other.hashName == hashName) &&
            (identical(other.photo, photo) || other.photo == photo) &&
            (identical(other.dispPref, dispPref) ||
                other.dispPref == dispPref) &&
            (identical(other.includeInGlobalHashDirectory,
                    includeInGlobalHashDirectory) ||
                other.includeInGlobalHashDirectory ==
                    includeInGlobalHashDirectory) &&
            (identical(other.removed, removed) || other.removed == removed) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      hasherId,
      firstName,
      lastName,
      dispName,
      hashName,
      photo,
      dispPref,
      includeInGlobalHashDirectory,
      removed,
      updatedAt);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'HashersModel(hasherId: $hasherId, firstName: $firstName, lastName: $lastName, dispName: $dispName, hashName: $hashName, photo: $photo, dispPref: $dispPref, includeInGlobalHashDirectory: $includeInGlobalHashDirectory, removed: $removed, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class _$HashersModelCopyWith<$Res>
    implements $HashersModelCopyWith<$Res> {
  factory _$HashersModelCopyWith(
          _HashersModel value, $Res Function(_HashersModel) _then) =
      __$HashersModelCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String hasherId,
      String? firstName,
      String? lastName,
      String dispName,
      String? hashName,
      String? photo,
      int dispPref,
      int includeInGlobalHashDirectory,
      int? removed,
      DateTime? updatedAt});
}

/// @nodoc
class __$HashersModelCopyWithImpl<$Res>
    implements _$HashersModelCopyWith<$Res> {
  __$HashersModelCopyWithImpl(this._self, this._then);

  final _HashersModel _self;
  final $Res Function(_HashersModel) _then;

  /// Create a copy of HashersModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? hasherId = null,
    Object? firstName = freezed,
    Object? lastName = freezed,
    Object? dispName = null,
    Object? hashName = freezed,
    Object? photo = freezed,
    Object? dispPref = null,
    Object? includeInGlobalHashDirectory = null,
    Object? removed = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_HashersModel(
      hasherId: null == hasherId
          ? _self.hasherId
          : hasherId // ignore: cast_nullable_to_non_nullable
              as String,
      firstName: freezed == firstName
          ? _self.firstName
          : firstName // ignore: cast_nullable_to_non_nullable
              as String?,
      lastName: freezed == lastName
          ? _self.lastName
          : lastName // ignore: cast_nullable_to_non_nullable
              as String?,
      dispName: null == dispName
          ? _self.dispName
          : dispName // ignore: cast_nullable_to_non_nullable
              as String,
      hashName: freezed == hashName
          ? _self.hashName
          : hashName // ignore: cast_nullable_to_non_nullable
              as String?,
      photo: freezed == photo
          ? _self.photo
          : photo // ignore: cast_nullable_to_non_nullable
              as String?,
      dispPref: null == dispPref
          ? _self.dispPref
          : dispPref // ignore: cast_nullable_to_non_nullable
              as int,
      includeInGlobalHashDirectory: null == includeInGlobalHashDirectory
          ? _self.includeInGlobalHashDirectory
          : includeInGlobalHashDirectory // ignore: cast_nullable_to_non_nullable
              as int,
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
