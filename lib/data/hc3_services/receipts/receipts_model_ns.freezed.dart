// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'receipts_model_ns.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ReceiptsModel implements DiagnosticableTreeMixin {

 String get receiptId; String get eventId; String get userId; double get receiptAmount; int get costCategory; DateTime? get dateUploaded; String? get imageUrl; String? get receiptShortDesc; String? get notes; String? get reimbursedBy; String? get reimbursedOn; double? get reimbursedAmount; String? get reimbursedNotes; int? get removed; DateTime? get updatedAt;
/// Create a copy of ReceiptsModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReceiptsModelCopyWith<ReceiptsModel> get copyWith => _$ReceiptsModelCopyWithImpl<ReceiptsModel>(this as ReceiptsModel, _$identity);

  /// Serializes this ReceiptsModel to a JSON map.
  Map<String, dynamic> toJson();

@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'ReceiptsModel'))
    ..add(DiagnosticsProperty('receiptId', receiptId))..add(DiagnosticsProperty('eventId', eventId))..add(DiagnosticsProperty('userId', userId))..add(DiagnosticsProperty('receiptAmount', receiptAmount))..add(DiagnosticsProperty('costCategory', costCategory))..add(DiagnosticsProperty('dateUploaded', dateUploaded))..add(DiagnosticsProperty('imageUrl', imageUrl))..add(DiagnosticsProperty('receiptShortDesc', receiptShortDesc))..add(DiagnosticsProperty('notes', notes))..add(DiagnosticsProperty('reimbursedBy', reimbursedBy))..add(DiagnosticsProperty('reimbursedOn', reimbursedOn))..add(DiagnosticsProperty('reimbursedAmount', reimbursedAmount))..add(DiagnosticsProperty('reimbursedNotes', reimbursedNotes))..add(DiagnosticsProperty('removed', removed))..add(DiagnosticsProperty('updatedAt', updatedAt));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReceiptsModel&&(identical(other.receiptId, receiptId) || other.receiptId == receiptId)&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.receiptAmount, receiptAmount) || other.receiptAmount == receiptAmount)&&(identical(other.costCategory, costCategory) || other.costCategory == costCategory)&&(identical(other.dateUploaded, dateUploaded) || other.dateUploaded == dateUploaded)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.receiptShortDesc, receiptShortDesc) || other.receiptShortDesc == receiptShortDesc)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.reimbursedBy, reimbursedBy) || other.reimbursedBy == reimbursedBy)&&(identical(other.reimbursedOn, reimbursedOn) || other.reimbursedOn == reimbursedOn)&&(identical(other.reimbursedAmount, reimbursedAmount) || other.reimbursedAmount == reimbursedAmount)&&(identical(other.reimbursedNotes, reimbursedNotes) || other.reimbursedNotes == reimbursedNotes)&&(identical(other.removed, removed) || other.removed == removed)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,receiptId,eventId,userId,receiptAmount,costCategory,dateUploaded,imageUrl,receiptShortDesc,notes,reimbursedBy,reimbursedOn,reimbursedAmount,reimbursedNotes,removed,updatedAt);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'ReceiptsModel(receiptId: $receiptId, eventId: $eventId, userId: $userId, receiptAmount: $receiptAmount, costCategory: $costCategory, dateUploaded: $dateUploaded, imageUrl: $imageUrl, receiptShortDesc: $receiptShortDesc, notes: $notes, reimbursedBy: $reimbursedBy, reimbursedOn: $reimbursedOn, reimbursedAmount: $reimbursedAmount, reimbursedNotes: $reimbursedNotes, removed: $removed, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $ReceiptsModelCopyWith<$Res>  {
  factory $ReceiptsModelCopyWith(ReceiptsModel value, $Res Function(ReceiptsModel) _then) = _$ReceiptsModelCopyWithImpl;
@useResult
$Res call({
 String receiptId, String eventId, String userId, double receiptAmount, int costCategory, DateTime? dateUploaded, String? imageUrl, String? receiptShortDesc, String? notes, String? reimbursedBy, String? reimbursedOn, double? reimbursedAmount, String? reimbursedNotes, int? removed, DateTime? updatedAt
});




}
/// @nodoc
class _$ReceiptsModelCopyWithImpl<$Res>
    implements $ReceiptsModelCopyWith<$Res> {
  _$ReceiptsModelCopyWithImpl(this._self, this._then);

  final ReceiptsModel _self;
  final $Res Function(ReceiptsModel) _then;

/// Create a copy of ReceiptsModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? receiptId = null,Object? eventId = null,Object? userId = null,Object? receiptAmount = null,Object? costCategory = null,Object? dateUploaded = freezed,Object? imageUrl = freezed,Object? receiptShortDesc = freezed,Object? notes = freezed,Object? reimbursedBy = freezed,Object? reimbursedOn = freezed,Object? reimbursedAmount = freezed,Object? reimbursedNotes = freezed,Object? removed = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
receiptId: null == receiptId ? _self.receiptId : receiptId // ignore: cast_nullable_to_non_nullable
as String,eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,receiptAmount: null == receiptAmount ? _self.receiptAmount : receiptAmount // ignore: cast_nullable_to_non_nullable
as double,costCategory: null == costCategory ? _self.costCategory : costCategory // ignore: cast_nullable_to_non_nullable
as int,dateUploaded: freezed == dateUploaded ? _self.dateUploaded : dateUploaded // ignore: cast_nullable_to_non_nullable
as DateTime?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,receiptShortDesc: freezed == receiptShortDesc ? _self.receiptShortDesc : receiptShortDesc // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,reimbursedBy: freezed == reimbursedBy ? _self.reimbursedBy : reimbursedBy // ignore: cast_nullable_to_non_nullable
as String?,reimbursedOn: freezed == reimbursedOn ? _self.reimbursedOn : reimbursedOn // ignore: cast_nullable_to_non_nullable
as String?,reimbursedAmount: freezed == reimbursedAmount ? _self.reimbursedAmount : reimbursedAmount // ignore: cast_nullable_to_non_nullable
as double?,reimbursedNotes: freezed == reimbursedNotes ? _self.reimbursedNotes : reimbursedNotes // ignore: cast_nullable_to_non_nullable
as String?,removed: freezed == removed ? _self.removed : removed // ignore: cast_nullable_to_non_nullable
as int?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _ReceiptsModel with DiagnosticableTreeMixin implements ReceiptsModel {
   _ReceiptsModel({required this.receiptId, required this.eventId, required this.userId, this.receiptAmount = 0.0, this.costCategory = 0, this.dateUploaded, this.imageUrl, this.receiptShortDesc, this.notes, this.reimbursedBy, this.reimbursedOn, this.reimbursedAmount, this.reimbursedNotes, this.removed, this.updatedAt});
  factory _ReceiptsModel.fromJson(Map<String, dynamic> json) => _$ReceiptsModelFromJson(json);

@override final  String receiptId;
@override final  String eventId;
@override final  String userId;
@override@JsonKey() final  double receiptAmount;
@override@JsonKey() final  int costCategory;
@override final  DateTime? dateUploaded;
@override final  String? imageUrl;
@override final  String? receiptShortDesc;
@override final  String? notes;
@override final  String? reimbursedBy;
@override final  String? reimbursedOn;
@override final  double? reimbursedAmount;
@override final  String? reimbursedNotes;
@override final  int? removed;
@override final  DateTime? updatedAt;

/// Create a copy of ReceiptsModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReceiptsModelCopyWith<_ReceiptsModel> get copyWith => __$ReceiptsModelCopyWithImpl<_ReceiptsModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReceiptsModelToJson(this, );
}
@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'ReceiptsModel'))
    ..add(DiagnosticsProperty('receiptId', receiptId))..add(DiagnosticsProperty('eventId', eventId))..add(DiagnosticsProperty('userId', userId))..add(DiagnosticsProperty('receiptAmount', receiptAmount))..add(DiagnosticsProperty('costCategory', costCategory))..add(DiagnosticsProperty('dateUploaded', dateUploaded))..add(DiagnosticsProperty('imageUrl', imageUrl))..add(DiagnosticsProperty('receiptShortDesc', receiptShortDesc))..add(DiagnosticsProperty('notes', notes))..add(DiagnosticsProperty('reimbursedBy', reimbursedBy))..add(DiagnosticsProperty('reimbursedOn', reimbursedOn))..add(DiagnosticsProperty('reimbursedAmount', reimbursedAmount))..add(DiagnosticsProperty('reimbursedNotes', reimbursedNotes))..add(DiagnosticsProperty('removed', removed))..add(DiagnosticsProperty('updatedAt', updatedAt));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReceiptsModel&&(identical(other.receiptId, receiptId) || other.receiptId == receiptId)&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.receiptAmount, receiptAmount) || other.receiptAmount == receiptAmount)&&(identical(other.costCategory, costCategory) || other.costCategory == costCategory)&&(identical(other.dateUploaded, dateUploaded) || other.dateUploaded == dateUploaded)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.receiptShortDesc, receiptShortDesc) || other.receiptShortDesc == receiptShortDesc)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.reimbursedBy, reimbursedBy) || other.reimbursedBy == reimbursedBy)&&(identical(other.reimbursedOn, reimbursedOn) || other.reimbursedOn == reimbursedOn)&&(identical(other.reimbursedAmount, reimbursedAmount) || other.reimbursedAmount == reimbursedAmount)&&(identical(other.reimbursedNotes, reimbursedNotes) || other.reimbursedNotes == reimbursedNotes)&&(identical(other.removed, removed) || other.removed == removed)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,receiptId,eventId,userId,receiptAmount,costCategory,dateUploaded,imageUrl,receiptShortDesc,notes,reimbursedBy,reimbursedOn,reimbursedAmount,reimbursedNotes,removed,updatedAt);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'ReceiptsModel(receiptId: $receiptId, eventId: $eventId, userId: $userId, receiptAmount: $receiptAmount, costCategory: $costCategory, dateUploaded: $dateUploaded, imageUrl: $imageUrl, receiptShortDesc: $receiptShortDesc, notes: $notes, reimbursedBy: $reimbursedBy, reimbursedOn: $reimbursedOn, reimbursedAmount: $reimbursedAmount, reimbursedNotes: $reimbursedNotes, removed: $removed, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$ReceiptsModelCopyWith<$Res> implements $ReceiptsModelCopyWith<$Res> {
  factory _$ReceiptsModelCopyWith(_ReceiptsModel value, $Res Function(_ReceiptsModel) _then) = __$ReceiptsModelCopyWithImpl;
@override @useResult
$Res call({
 String receiptId, String eventId, String userId, double receiptAmount, int costCategory, DateTime? dateUploaded, String? imageUrl, String? receiptShortDesc, String? notes, String? reimbursedBy, String? reimbursedOn, double? reimbursedAmount, String? reimbursedNotes, int? removed, DateTime? updatedAt
});




}
/// @nodoc
class __$ReceiptsModelCopyWithImpl<$Res>
    implements _$ReceiptsModelCopyWith<$Res> {
  __$ReceiptsModelCopyWithImpl(this._self, this._then);

  final _ReceiptsModel _self;
  final $Res Function(_ReceiptsModel) _then;

/// Create a copy of ReceiptsModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? receiptId = null,Object? eventId = null,Object? userId = null,Object? receiptAmount = null,Object? costCategory = null,Object? dateUploaded = freezed,Object? imageUrl = freezed,Object? receiptShortDesc = freezed,Object? notes = freezed,Object? reimbursedBy = freezed,Object? reimbursedOn = freezed,Object? reimbursedAmount = freezed,Object? reimbursedNotes = freezed,Object? removed = freezed,Object? updatedAt = freezed,}) {
  return _then(_ReceiptsModel(
receiptId: null == receiptId ? _self.receiptId : receiptId // ignore: cast_nullable_to_non_nullable
as String,eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,receiptAmount: null == receiptAmount ? _self.receiptAmount : receiptAmount // ignore: cast_nullable_to_non_nullable
as double,costCategory: null == costCategory ? _self.costCategory : costCategory // ignore: cast_nullable_to_non_nullable
as int,dateUploaded: freezed == dateUploaded ? _self.dateUploaded : dateUploaded // ignore: cast_nullable_to_non_nullable
as DateTime?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,receiptShortDesc: freezed == receiptShortDesc ? _self.receiptShortDesc : receiptShortDesc // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,reimbursedBy: freezed == reimbursedBy ? _self.reimbursedBy : reimbursedBy // ignore: cast_nullable_to_non_nullable
as String?,reimbursedOn: freezed == reimbursedOn ? _self.reimbursedOn : reimbursedOn // ignore: cast_nullable_to_non_nullable
as String?,reimbursedAmount: freezed == reimbursedAmount ? _self.reimbursedAmount : reimbursedAmount // ignore: cast_nullable_to_non_nullable
as double?,reimbursedNotes: freezed == reimbursedNotes ? _self.reimbursedNotes : reimbursedNotes // ignore: cast_nullable_to_non_nullable
as String?,removed: freezed == removed ? _self.removed : removed // ignore: cast_nullable_to_non_nullable
as int?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
