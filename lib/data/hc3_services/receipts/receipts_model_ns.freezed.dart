// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'receipts_model_ns.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

ReceiptsModel _$ReceiptsModelFromJson(Map<String, dynamic> json) {
  return _ReceiptsModel.fromJson(json);
}

/// @nodoc
mixin _$ReceiptsModel {
  String get receiptId => throw _privateConstructorUsedError;
  String get eventId => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  num get receiptAmount => throw _privateConstructorUsedError;
  int get costCategory => throw _privateConstructorUsedError;
  DateTime get dateUploaded => throw _privateConstructorUsedError;
  String? get imageUrl => throw _privateConstructorUsedError;
  String? get receiptShortDescription => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  String? get reimbursedBy => throw _privateConstructorUsedError;
  String? get reimbursedOn => throw _privateConstructorUsedError;
  num? get reimbursedAmount => throw _privateConstructorUsedError;
  String? get reimbursedNotes => throw _privateConstructorUsedError;
  int get removed => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ReceiptsModelCopyWith<ReceiptsModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReceiptsModelCopyWith<$Res> {
  factory $ReceiptsModelCopyWith(
          ReceiptsModel value, $Res Function(ReceiptsModel) then) =
      _$ReceiptsModelCopyWithImpl<$Res, ReceiptsModel>;
  @useResult
  $Res call(
      {String receiptId,
      String eventId,
      String userId,
      num receiptAmount,
      int costCategory,
      DateTime dateUploaded,
      String? imageUrl,
      String? receiptShortDescription,
      String? notes,
      String? reimbursedBy,
      String? reimbursedOn,
      num? reimbursedAmount,
      String? reimbursedNotes,
      int removed,
      DateTime updatedAt});
}

/// @nodoc
class _$ReceiptsModelCopyWithImpl<$Res, $Val extends ReceiptsModel>
    implements $ReceiptsModelCopyWith<$Res> {
  _$ReceiptsModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? receiptId = null,
    Object? eventId = null,
    Object? userId = null,
    Object? receiptAmount = null,
    Object? costCategory = null,
    Object? dateUploaded = null,
    Object? imageUrl = freezed,
    Object? receiptShortDescription = freezed,
    Object? notes = freezed,
    Object? reimbursedBy = freezed,
    Object? reimbursedOn = freezed,
    Object? reimbursedAmount = freezed,
    Object? reimbursedNotes = freezed,
    Object? removed = null,
    Object? updatedAt = null,
  }) {
    return _then(_value.copyWith(
      receiptId: null == receiptId
          ? _value.receiptId
          : receiptId // ignore: cast_nullable_to_non_nullable
              as String,
      eventId: null == eventId
          ? _value.eventId
          : eventId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      receiptAmount: null == receiptAmount
          ? _value.receiptAmount
          : receiptAmount // ignore: cast_nullable_to_non_nullable
              as num,
      costCategory: null == costCategory
          ? _value.costCategory
          : costCategory // ignore: cast_nullable_to_non_nullable
              as int,
      dateUploaded: null == dateUploaded
          ? _value.dateUploaded
          : dateUploaded // ignore: cast_nullable_to_non_nullable
              as DateTime,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      receiptShortDescription: freezed == receiptShortDescription
          ? _value.receiptShortDescription
          : receiptShortDescription // ignore: cast_nullable_to_non_nullable
              as String?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      reimbursedBy: freezed == reimbursedBy
          ? _value.reimbursedBy
          : reimbursedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      reimbursedOn: freezed == reimbursedOn
          ? _value.reimbursedOn
          : reimbursedOn // ignore: cast_nullable_to_non_nullable
              as String?,
      reimbursedAmount: freezed == reimbursedAmount
          ? _value.reimbursedAmount
          : reimbursedAmount // ignore: cast_nullable_to_non_nullable
              as num?,
      reimbursedNotes: freezed == reimbursedNotes
          ? _value.reimbursedNotes
          : reimbursedNotes // ignore: cast_nullable_to_non_nullable
              as String?,
      removed: null == removed
          ? _value.removed
          : removed // ignore: cast_nullable_to_non_nullable
              as int,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_ReceiptsModelCopyWith<$Res>
    implements $ReceiptsModelCopyWith<$Res> {
  factory _$$_ReceiptsModelCopyWith(
          _$_ReceiptsModel value, $Res Function(_$_ReceiptsModel) then) =
      __$$_ReceiptsModelCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String receiptId,
      String eventId,
      String userId,
      num receiptAmount,
      int costCategory,
      DateTime dateUploaded,
      String? imageUrl,
      String? receiptShortDescription,
      String? notes,
      String? reimbursedBy,
      String? reimbursedOn,
      num? reimbursedAmount,
      String? reimbursedNotes,
      int removed,
      DateTime updatedAt});
}

/// @nodoc
class __$$_ReceiptsModelCopyWithImpl<$Res>
    extends _$ReceiptsModelCopyWithImpl<$Res, _$_ReceiptsModel>
    implements _$$_ReceiptsModelCopyWith<$Res> {
  __$$_ReceiptsModelCopyWithImpl(
      _$_ReceiptsModel _value, $Res Function(_$_ReceiptsModel) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? receiptId = null,
    Object? eventId = null,
    Object? userId = null,
    Object? receiptAmount = null,
    Object? costCategory = null,
    Object? dateUploaded = null,
    Object? imageUrl = freezed,
    Object? receiptShortDescription = freezed,
    Object? notes = freezed,
    Object? reimbursedBy = freezed,
    Object? reimbursedOn = freezed,
    Object? reimbursedAmount = freezed,
    Object? reimbursedNotes = freezed,
    Object? removed = null,
    Object? updatedAt = null,
  }) {
    return _then(_$_ReceiptsModel(
      receiptId: null == receiptId
          ? _value.receiptId
          : receiptId // ignore: cast_nullable_to_non_nullable
              as String,
      eventId: null == eventId
          ? _value.eventId
          : eventId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      receiptAmount: null == receiptAmount
          ? _value.receiptAmount
          : receiptAmount // ignore: cast_nullable_to_non_nullable
              as num,
      costCategory: null == costCategory
          ? _value.costCategory
          : costCategory // ignore: cast_nullable_to_non_nullable
              as int,
      dateUploaded: null == dateUploaded
          ? _value.dateUploaded
          : dateUploaded // ignore: cast_nullable_to_non_nullable
              as DateTime,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      receiptShortDescription: freezed == receiptShortDescription
          ? _value.receiptShortDescription
          : receiptShortDescription // ignore: cast_nullable_to_non_nullable
              as String?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      reimbursedBy: freezed == reimbursedBy
          ? _value.reimbursedBy
          : reimbursedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      reimbursedOn: freezed == reimbursedOn
          ? _value.reimbursedOn
          : reimbursedOn // ignore: cast_nullable_to_non_nullable
              as String?,
      reimbursedAmount: freezed == reimbursedAmount
          ? _value.reimbursedAmount
          : reimbursedAmount // ignore: cast_nullable_to_non_nullable
              as num?,
      reimbursedNotes: freezed == reimbursedNotes
          ? _value.reimbursedNotes
          : reimbursedNotes // ignore: cast_nullable_to_non_nullable
              as String?,
      removed: null == removed
          ? _value.removed
          : removed // ignore: cast_nullable_to_non_nullable
              as int,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_ReceiptsModel implements _ReceiptsModel {
  _$_ReceiptsModel(
      {required this.receiptId,
      required this.eventId,
      required this.userId,
      required this.receiptAmount,
      required this.costCategory,
      required this.dateUploaded,
      this.imageUrl,
      this.receiptShortDescription,
      this.notes,
      this.reimbursedBy,
      this.reimbursedOn,
      this.reimbursedAmount,
      this.reimbursedNotes,
      required this.removed,
      required this.updatedAt});

  factory _$_ReceiptsModel.fromJson(Map<String, dynamic> json) =>
      _$$_ReceiptsModelFromJson(json);

  @override
  final String receiptId;
  @override
  final String eventId;
  @override
  final String userId;
  @override
  final num receiptAmount;
  @override
  final int costCategory;
  @override
  final DateTime dateUploaded;
  @override
  final String? imageUrl;
  @override
  final String? receiptShortDescription;
  @override
  final String? notes;
  @override
  final String? reimbursedBy;
  @override
  final String? reimbursedOn;
  @override
  final num? reimbursedAmount;
  @override
  final String? reimbursedNotes;
  @override
  final int removed;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'ReceiptsModel(receiptId: $receiptId, eventId: $eventId, userId: $userId, receiptAmount: $receiptAmount, costCategory: $costCategory, dateUploaded: $dateUploaded, imageUrl: $imageUrl, receiptShortDescription: $receiptShortDescription, notes: $notes, reimbursedBy: $reimbursedBy, reimbursedOn: $reimbursedOn, reimbursedAmount: $reimbursedAmount, reimbursedNotes: $reimbursedNotes, removed: $removed, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_ReceiptsModel &&
            (identical(other.receiptId, receiptId) ||
                other.receiptId == receiptId) &&
            (identical(other.eventId, eventId) || other.eventId == eventId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.receiptAmount, receiptAmount) ||
                other.receiptAmount == receiptAmount) &&
            (identical(other.costCategory, costCategory) ||
                other.costCategory == costCategory) &&
            (identical(other.dateUploaded, dateUploaded) ||
                other.dateUploaded == dateUploaded) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(
                    other.receiptShortDescription, receiptShortDescription) ||
                other.receiptShortDescription == receiptShortDescription) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.reimbursedBy, reimbursedBy) ||
                other.reimbursedBy == reimbursedBy) &&
            (identical(other.reimbursedOn, reimbursedOn) ||
                other.reimbursedOn == reimbursedOn) &&
            (identical(other.reimbursedAmount, reimbursedAmount) ||
                other.reimbursedAmount == reimbursedAmount) &&
            (identical(other.reimbursedNotes, reimbursedNotes) ||
                other.reimbursedNotes == reimbursedNotes) &&
            (identical(other.removed, removed) || other.removed == removed) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      receiptId,
      eventId,
      userId,
      receiptAmount,
      costCategory,
      dateUploaded,
      imageUrl,
      receiptShortDescription,
      notes,
      reimbursedBy,
      reimbursedOn,
      reimbursedAmount,
      reimbursedNotes,
      removed,
      updatedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_ReceiptsModelCopyWith<_$_ReceiptsModel> get copyWith =>
      __$$_ReceiptsModelCopyWithImpl<_$_ReceiptsModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_ReceiptsModelToJson(
      this,
    );
  }
}

abstract class _ReceiptsModel implements ReceiptsModel {
  factory _ReceiptsModel(
      {required final String receiptId,
      required final String eventId,
      required final String userId,
      required final num receiptAmount,
      required final int costCategory,
      required final DateTime dateUploaded,
      final String? imageUrl,
      final String? receiptShortDescription,
      final String? notes,
      final String? reimbursedBy,
      final String? reimbursedOn,
      final num? reimbursedAmount,
      final String? reimbursedNotes,
      required final int removed,
      required final DateTime updatedAt}) = _$_ReceiptsModel;

  factory _ReceiptsModel.fromJson(Map<String, dynamic> json) =
      _$_ReceiptsModel.fromJson;

  @override
  String get receiptId;
  @override
  String get eventId;
  @override
  String get userId;
  @override
  num get receiptAmount;
  @override
  int get costCategory;
  @override
  DateTime get dateUploaded;
  @override
  String? get imageUrl;
  @override
  String? get receiptShortDescription;
  @override
  String? get notes;
  @override
  String? get reimbursedBy;
  @override
  String? get reimbursedOn;
  @override
  num? get reimbursedAmount;
  @override
  String? get reimbursedNotes;
  @override
  int get removed;
  @override
  DateTime get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$_ReceiptsModelCopyWith<_$_ReceiptsModel> get copyWith =>
      throw _privateConstructorUsedError;
}
