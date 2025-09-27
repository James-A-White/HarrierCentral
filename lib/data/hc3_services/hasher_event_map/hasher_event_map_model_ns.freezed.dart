// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'hasher_event_map_model_ns.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HasherEventMapModel implements DiagnosticableTreeMixin {

 String get hemId; String get userId; String get eventId; String? get hasherOwnEventId; String? get userStartEvent; String? get userEndEvent; int get rsvpState; int get attendenceState; int get isHare; int? get eventNotificationPreference; int? get eventEmailAlertPreference; int? get totalHaring; int? get totalHaringThisKennel; int? get totalRuns; int? get totalRunsThisKennel; int? get eventCountOverride; int get virginVisitorType; String? get displayName; String? get email; String? get phoneNumber;// these fields are cached from the event itself. This enables us to keep run count information without
// having to have the actual run cached on the phone
 String? get hemEventName; String? get hemCountryId; int? get hemEventNumber; DateTime get hemEventStartDatetime; int? get hemCanEditRunAttendence; String? get hemEventKennelId; int? get hemEventIsCountedAndVisible; String? get hemKennelUserPhoto; String? get hemKennelHashName; int? get removed; DateTime? get updatedAt;
/// Create a copy of HasherEventMapModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HasherEventMapModelCopyWith<HasherEventMapModel> get copyWith => _$HasherEventMapModelCopyWithImpl<HasherEventMapModel>(this as HasherEventMapModel, _$identity);

  /// Serializes this HasherEventMapModel to a JSON map.
  Map<String, dynamic> toJson();

@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'HasherEventMapModel'))
    ..add(DiagnosticsProperty('hemId', hemId))..add(DiagnosticsProperty('userId', userId))..add(DiagnosticsProperty('eventId', eventId))..add(DiagnosticsProperty('hasherOwnEventId', hasherOwnEventId))..add(DiagnosticsProperty('userStartEvent', userStartEvent))..add(DiagnosticsProperty('userEndEvent', userEndEvent))..add(DiagnosticsProperty('rsvpState', rsvpState))..add(DiagnosticsProperty('attendenceState', attendenceState))..add(DiagnosticsProperty('isHare', isHare))..add(DiagnosticsProperty('eventNotificationPreference', eventNotificationPreference))..add(DiagnosticsProperty('eventEmailAlertPreference', eventEmailAlertPreference))..add(DiagnosticsProperty('totalHaring', totalHaring))..add(DiagnosticsProperty('totalHaringThisKennel', totalHaringThisKennel))..add(DiagnosticsProperty('totalRuns', totalRuns))..add(DiagnosticsProperty('totalRunsThisKennel', totalRunsThisKennel))..add(DiagnosticsProperty('eventCountOverride', eventCountOverride))..add(DiagnosticsProperty('virginVisitorType', virginVisitorType))..add(DiagnosticsProperty('displayName', displayName))..add(DiagnosticsProperty('email', email))..add(DiagnosticsProperty('phoneNumber', phoneNumber))..add(DiagnosticsProperty('hemEventName', hemEventName))..add(DiagnosticsProperty('hemCountryId', hemCountryId))..add(DiagnosticsProperty('hemEventNumber', hemEventNumber))..add(DiagnosticsProperty('hemEventStartDatetime', hemEventStartDatetime))..add(DiagnosticsProperty('hemCanEditRunAttendence', hemCanEditRunAttendence))..add(DiagnosticsProperty('hemEventKennelId', hemEventKennelId))..add(DiagnosticsProperty('hemEventIsCountedAndVisible', hemEventIsCountedAndVisible))..add(DiagnosticsProperty('hemKennelUserPhoto', hemKennelUserPhoto))..add(DiagnosticsProperty('hemKennelHashName', hemKennelHashName))..add(DiagnosticsProperty('removed', removed))..add(DiagnosticsProperty('updatedAt', updatedAt));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HasherEventMapModel&&(identical(other.hemId, hemId) || other.hemId == hemId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.hasherOwnEventId, hasherOwnEventId) || other.hasherOwnEventId == hasherOwnEventId)&&(identical(other.userStartEvent, userStartEvent) || other.userStartEvent == userStartEvent)&&(identical(other.userEndEvent, userEndEvent) || other.userEndEvent == userEndEvent)&&(identical(other.rsvpState, rsvpState) || other.rsvpState == rsvpState)&&(identical(other.attendenceState, attendenceState) || other.attendenceState == attendenceState)&&(identical(other.isHare, isHare) || other.isHare == isHare)&&(identical(other.eventNotificationPreference, eventNotificationPreference) || other.eventNotificationPreference == eventNotificationPreference)&&(identical(other.eventEmailAlertPreference, eventEmailAlertPreference) || other.eventEmailAlertPreference == eventEmailAlertPreference)&&(identical(other.totalHaring, totalHaring) || other.totalHaring == totalHaring)&&(identical(other.totalHaringThisKennel, totalHaringThisKennel) || other.totalHaringThisKennel == totalHaringThisKennel)&&(identical(other.totalRuns, totalRuns) || other.totalRuns == totalRuns)&&(identical(other.totalRunsThisKennel, totalRunsThisKennel) || other.totalRunsThisKennel == totalRunsThisKennel)&&(identical(other.eventCountOverride, eventCountOverride) || other.eventCountOverride == eventCountOverride)&&(identical(other.virginVisitorType, virginVisitorType) || other.virginVisitorType == virginVisitorType)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.email, email) || other.email == email)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.hemEventName, hemEventName) || other.hemEventName == hemEventName)&&(identical(other.hemCountryId, hemCountryId) || other.hemCountryId == hemCountryId)&&(identical(other.hemEventNumber, hemEventNumber) || other.hemEventNumber == hemEventNumber)&&(identical(other.hemEventStartDatetime, hemEventStartDatetime) || other.hemEventStartDatetime == hemEventStartDatetime)&&(identical(other.hemCanEditRunAttendence, hemCanEditRunAttendence) || other.hemCanEditRunAttendence == hemCanEditRunAttendence)&&(identical(other.hemEventKennelId, hemEventKennelId) || other.hemEventKennelId == hemEventKennelId)&&(identical(other.hemEventIsCountedAndVisible, hemEventIsCountedAndVisible) || other.hemEventIsCountedAndVisible == hemEventIsCountedAndVisible)&&(identical(other.hemKennelUserPhoto, hemKennelUserPhoto) || other.hemKennelUserPhoto == hemKennelUserPhoto)&&(identical(other.hemKennelHashName, hemKennelHashName) || other.hemKennelHashName == hemKennelHashName)&&(identical(other.removed, removed) || other.removed == removed)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,hemId,userId,eventId,hasherOwnEventId,userStartEvent,userEndEvent,rsvpState,attendenceState,isHare,eventNotificationPreference,eventEmailAlertPreference,totalHaring,totalHaringThisKennel,totalRuns,totalRunsThisKennel,eventCountOverride,virginVisitorType,displayName,email,phoneNumber,hemEventName,hemCountryId,hemEventNumber,hemEventStartDatetime,hemCanEditRunAttendence,hemEventKennelId,hemEventIsCountedAndVisible,hemKennelUserPhoto,hemKennelHashName,removed,updatedAt]);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'HasherEventMapModel(hemId: $hemId, userId: $userId, eventId: $eventId, hasherOwnEventId: $hasherOwnEventId, userStartEvent: $userStartEvent, userEndEvent: $userEndEvent, rsvpState: $rsvpState, attendenceState: $attendenceState, isHare: $isHare, eventNotificationPreference: $eventNotificationPreference, eventEmailAlertPreference: $eventEmailAlertPreference, totalHaring: $totalHaring, totalHaringThisKennel: $totalHaringThisKennel, totalRuns: $totalRuns, totalRunsThisKennel: $totalRunsThisKennel, eventCountOverride: $eventCountOverride, virginVisitorType: $virginVisitorType, displayName: $displayName, email: $email, phoneNumber: $phoneNumber, hemEventName: $hemEventName, hemCountryId: $hemCountryId, hemEventNumber: $hemEventNumber, hemEventStartDatetime: $hemEventStartDatetime, hemCanEditRunAttendence: $hemCanEditRunAttendence, hemEventKennelId: $hemEventKennelId, hemEventIsCountedAndVisible: $hemEventIsCountedAndVisible, hemKennelUserPhoto: $hemKennelUserPhoto, hemKennelHashName: $hemKennelHashName, removed: $removed, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $HasherEventMapModelCopyWith<$Res>  {
  factory $HasherEventMapModelCopyWith(HasherEventMapModel value, $Res Function(HasherEventMapModel) _then) = _$HasherEventMapModelCopyWithImpl;
@useResult
$Res call({
 String hemId, String userId, String eventId, String? hasherOwnEventId, String? userStartEvent, String? userEndEvent, int rsvpState, int attendenceState, int isHare, int? eventNotificationPreference, int? eventEmailAlertPreference, int? totalHaring, int? totalHaringThisKennel, int? totalRuns, int? totalRunsThisKennel, int? eventCountOverride, int virginVisitorType, String? displayName, String? email, String? phoneNumber, String? hemEventName, String? hemCountryId, int? hemEventNumber, DateTime hemEventStartDatetime, int? hemCanEditRunAttendence, String? hemEventKennelId, int? hemEventIsCountedAndVisible, String? hemKennelUserPhoto, String? hemKennelHashName, int? removed, DateTime? updatedAt
});




}
/// @nodoc
class _$HasherEventMapModelCopyWithImpl<$Res>
    implements $HasherEventMapModelCopyWith<$Res> {
  _$HasherEventMapModelCopyWithImpl(this._self, this._then);

  final HasherEventMapModel _self;
  final $Res Function(HasherEventMapModel) _then;

/// Create a copy of HasherEventMapModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? hemId = null,Object? userId = null,Object? eventId = null,Object? hasherOwnEventId = freezed,Object? userStartEvent = freezed,Object? userEndEvent = freezed,Object? rsvpState = null,Object? attendenceState = null,Object? isHare = null,Object? eventNotificationPreference = freezed,Object? eventEmailAlertPreference = freezed,Object? totalHaring = freezed,Object? totalHaringThisKennel = freezed,Object? totalRuns = freezed,Object? totalRunsThisKennel = freezed,Object? eventCountOverride = freezed,Object? virginVisitorType = null,Object? displayName = freezed,Object? email = freezed,Object? phoneNumber = freezed,Object? hemEventName = freezed,Object? hemCountryId = freezed,Object? hemEventNumber = freezed,Object? hemEventStartDatetime = null,Object? hemCanEditRunAttendence = freezed,Object? hemEventKennelId = freezed,Object? hemEventIsCountedAndVisible = freezed,Object? hemKennelUserPhoto = freezed,Object? hemKennelHashName = freezed,Object? removed = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
hemId: null == hemId ? _self.hemId : hemId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,hasherOwnEventId: freezed == hasherOwnEventId ? _self.hasherOwnEventId : hasherOwnEventId // ignore: cast_nullable_to_non_nullable
as String?,userStartEvent: freezed == userStartEvent ? _self.userStartEvent : userStartEvent // ignore: cast_nullable_to_non_nullable
as String?,userEndEvent: freezed == userEndEvent ? _self.userEndEvent : userEndEvent // ignore: cast_nullable_to_non_nullable
as String?,rsvpState: null == rsvpState ? _self.rsvpState : rsvpState // ignore: cast_nullable_to_non_nullable
as int,attendenceState: null == attendenceState ? _self.attendenceState : attendenceState // ignore: cast_nullable_to_non_nullable
as int,isHare: null == isHare ? _self.isHare : isHare // ignore: cast_nullable_to_non_nullable
as int,eventNotificationPreference: freezed == eventNotificationPreference ? _self.eventNotificationPreference : eventNotificationPreference // ignore: cast_nullable_to_non_nullable
as int?,eventEmailAlertPreference: freezed == eventEmailAlertPreference ? _self.eventEmailAlertPreference : eventEmailAlertPreference // ignore: cast_nullable_to_non_nullable
as int?,totalHaring: freezed == totalHaring ? _self.totalHaring : totalHaring // ignore: cast_nullable_to_non_nullable
as int?,totalHaringThisKennel: freezed == totalHaringThisKennel ? _self.totalHaringThisKennel : totalHaringThisKennel // ignore: cast_nullable_to_non_nullable
as int?,totalRuns: freezed == totalRuns ? _self.totalRuns : totalRuns // ignore: cast_nullable_to_non_nullable
as int?,totalRunsThisKennel: freezed == totalRunsThisKennel ? _self.totalRunsThisKennel : totalRunsThisKennel // ignore: cast_nullable_to_non_nullable
as int?,eventCountOverride: freezed == eventCountOverride ? _self.eventCountOverride : eventCountOverride // ignore: cast_nullable_to_non_nullable
as int?,virginVisitorType: null == virginVisitorType ? _self.virginVisitorType : virginVisitorType // ignore: cast_nullable_to_non_nullable
as int,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,phoneNumber: freezed == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String?,hemEventName: freezed == hemEventName ? _self.hemEventName : hemEventName // ignore: cast_nullable_to_non_nullable
as String?,hemCountryId: freezed == hemCountryId ? _self.hemCountryId : hemCountryId // ignore: cast_nullable_to_non_nullable
as String?,hemEventNumber: freezed == hemEventNumber ? _self.hemEventNumber : hemEventNumber // ignore: cast_nullable_to_non_nullable
as int?,hemEventStartDatetime: null == hemEventStartDatetime ? _self.hemEventStartDatetime : hemEventStartDatetime // ignore: cast_nullable_to_non_nullable
as DateTime,hemCanEditRunAttendence: freezed == hemCanEditRunAttendence ? _self.hemCanEditRunAttendence : hemCanEditRunAttendence // ignore: cast_nullable_to_non_nullable
as int?,hemEventKennelId: freezed == hemEventKennelId ? _self.hemEventKennelId : hemEventKennelId // ignore: cast_nullable_to_non_nullable
as String?,hemEventIsCountedAndVisible: freezed == hemEventIsCountedAndVisible ? _self.hemEventIsCountedAndVisible : hemEventIsCountedAndVisible // ignore: cast_nullable_to_non_nullable
as int?,hemKennelUserPhoto: freezed == hemKennelUserPhoto ? _self.hemKennelUserPhoto : hemKennelUserPhoto // ignore: cast_nullable_to_non_nullable
as String?,hemKennelHashName: freezed == hemKennelHashName ? _self.hemKennelHashName : hemKennelHashName // ignore: cast_nullable_to_non_nullable
as String?,removed: freezed == removed ? _self.removed : removed // ignore: cast_nullable_to_non_nullable
as int?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [HasherEventMapModel].
extension HasherEventMapModelPatterns on HasherEventMapModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HasherEventMapModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HasherEventMapModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HasherEventMapModel value)  $default,){
final _that = this;
switch (_that) {
case _HasherEventMapModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HasherEventMapModel value)?  $default,){
final _that = this;
switch (_that) {
case _HasherEventMapModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String hemId,  String userId,  String eventId,  String? hasherOwnEventId,  String? userStartEvent,  String? userEndEvent,  int rsvpState,  int attendenceState,  int isHare,  int? eventNotificationPreference,  int? eventEmailAlertPreference,  int? totalHaring,  int? totalHaringThisKennel,  int? totalRuns,  int? totalRunsThisKennel,  int? eventCountOverride,  int virginVisitorType,  String? displayName,  String? email,  String? phoneNumber,  String? hemEventName,  String? hemCountryId,  int? hemEventNumber,  DateTime hemEventStartDatetime,  int? hemCanEditRunAttendence,  String? hemEventKennelId,  int? hemEventIsCountedAndVisible,  String? hemKennelUserPhoto,  String? hemKennelHashName,  int? removed,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HasherEventMapModel() when $default != null:
return $default(_that.hemId,_that.userId,_that.eventId,_that.hasherOwnEventId,_that.userStartEvent,_that.userEndEvent,_that.rsvpState,_that.attendenceState,_that.isHare,_that.eventNotificationPreference,_that.eventEmailAlertPreference,_that.totalHaring,_that.totalHaringThisKennel,_that.totalRuns,_that.totalRunsThisKennel,_that.eventCountOverride,_that.virginVisitorType,_that.displayName,_that.email,_that.phoneNumber,_that.hemEventName,_that.hemCountryId,_that.hemEventNumber,_that.hemEventStartDatetime,_that.hemCanEditRunAttendence,_that.hemEventKennelId,_that.hemEventIsCountedAndVisible,_that.hemKennelUserPhoto,_that.hemKennelHashName,_that.removed,_that.updatedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String hemId,  String userId,  String eventId,  String? hasherOwnEventId,  String? userStartEvent,  String? userEndEvent,  int rsvpState,  int attendenceState,  int isHare,  int? eventNotificationPreference,  int? eventEmailAlertPreference,  int? totalHaring,  int? totalHaringThisKennel,  int? totalRuns,  int? totalRunsThisKennel,  int? eventCountOverride,  int virginVisitorType,  String? displayName,  String? email,  String? phoneNumber,  String? hemEventName,  String? hemCountryId,  int? hemEventNumber,  DateTime hemEventStartDatetime,  int? hemCanEditRunAttendence,  String? hemEventKennelId,  int? hemEventIsCountedAndVisible,  String? hemKennelUserPhoto,  String? hemKennelHashName,  int? removed,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _HasherEventMapModel():
return $default(_that.hemId,_that.userId,_that.eventId,_that.hasherOwnEventId,_that.userStartEvent,_that.userEndEvent,_that.rsvpState,_that.attendenceState,_that.isHare,_that.eventNotificationPreference,_that.eventEmailAlertPreference,_that.totalHaring,_that.totalHaringThisKennel,_that.totalRuns,_that.totalRunsThisKennel,_that.eventCountOverride,_that.virginVisitorType,_that.displayName,_that.email,_that.phoneNumber,_that.hemEventName,_that.hemCountryId,_that.hemEventNumber,_that.hemEventStartDatetime,_that.hemCanEditRunAttendence,_that.hemEventKennelId,_that.hemEventIsCountedAndVisible,_that.hemKennelUserPhoto,_that.hemKennelHashName,_that.removed,_that.updatedAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String hemId,  String userId,  String eventId,  String? hasherOwnEventId,  String? userStartEvent,  String? userEndEvent,  int rsvpState,  int attendenceState,  int isHare,  int? eventNotificationPreference,  int? eventEmailAlertPreference,  int? totalHaring,  int? totalHaringThisKennel,  int? totalRuns,  int? totalRunsThisKennel,  int? eventCountOverride,  int virginVisitorType,  String? displayName,  String? email,  String? phoneNumber,  String? hemEventName,  String? hemCountryId,  int? hemEventNumber,  DateTime hemEventStartDatetime,  int? hemCanEditRunAttendence,  String? hemEventKennelId,  int? hemEventIsCountedAndVisible,  String? hemKennelUserPhoto,  String? hemKennelHashName,  int? removed,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _HasherEventMapModel() when $default != null:
return $default(_that.hemId,_that.userId,_that.eventId,_that.hasherOwnEventId,_that.userStartEvent,_that.userEndEvent,_that.rsvpState,_that.attendenceState,_that.isHare,_that.eventNotificationPreference,_that.eventEmailAlertPreference,_that.totalHaring,_that.totalHaringThisKennel,_that.totalRuns,_that.totalRunsThisKennel,_that.eventCountOverride,_that.virginVisitorType,_that.displayName,_that.email,_that.phoneNumber,_that.hemEventName,_that.hemCountryId,_that.hemEventNumber,_that.hemEventStartDatetime,_that.hemCanEditRunAttendence,_that.hemEventKennelId,_that.hemEventIsCountedAndVisible,_that.hemKennelUserPhoto,_that.hemKennelHashName,_that.removed,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HasherEventMapModel with DiagnosticableTreeMixin implements HasherEventMapModel {
   _HasherEventMapModel({required this.hemId, required this.userId, required this.eventId, this.hasherOwnEventId, this.userStartEvent, this.userEndEvent, required this.rsvpState, required this.attendenceState, required this.isHare, this.eventNotificationPreference, this.eventEmailAlertPreference, this.totalHaring, this.totalHaringThisKennel, this.totalRuns, this.totalRunsThisKennel, this.eventCountOverride, required this.virginVisitorType, this.displayName, this.email, this.phoneNumber, this.hemEventName, this.hemCountryId, this.hemEventNumber, required this.hemEventStartDatetime, this.hemCanEditRunAttendence, this.hemEventKennelId, this.hemEventIsCountedAndVisible, this.hemKennelUserPhoto, this.hemKennelHashName, this.removed, this.updatedAt});
  factory _HasherEventMapModel.fromJson(Map<String, dynamic> json) => _$HasherEventMapModelFromJson(json);

@override final  String hemId;
@override final  String userId;
@override final  String eventId;
@override final  String? hasherOwnEventId;
@override final  String? userStartEvent;
@override final  String? userEndEvent;
@override final  int rsvpState;
@override final  int attendenceState;
@override final  int isHare;
@override final  int? eventNotificationPreference;
@override final  int? eventEmailAlertPreference;
@override final  int? totalHaring;
@override final  int? totalHaringThisKennel;
@override final  int? totalRuns;
@override final  int? totalRunsThisKennel;
@override final  int? eventCountOverride;
@override final  int virginVisitorType;
@override final  String? displayName;
@override final  String? email;
@override final  String? phoneNumber;
// these fields are cached from the event itself. This enables us to keep run count information without
// having to have the actual run cached on the phone
@override final  String? hemEventName;
@override final  String? hemCountryId;
@override final  int? hemEventNumber;
@override final  DateTime hemEventStartDatetime;
@override final  int? hemCanEditRunAttendence;
@override final  String? hemEventKennelId;
@override final  int? hemEventIsCountedAndVisible;
@override final  String? hemKennelUserPhoto;
@override final  String? hemKennelHashName;
@override final  int? removed;
@override final  DateTime? updatedAt;

/// Create a copy of HasherEventMapModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HasherEventMapModelCopyWith<_HasherEventMapModel> get copyWith => __$HasherEventMapModelCopyWithImpl<_HasherEventMapModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HasherEventMapModelToJson(this, );
}
@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'HasherEventMapModel'))
    ..add(DiagnosticsProperty('hemId', hemId))..add(DiagnosticsProperty('userId', userId))..add(DiagnosticsProperty('eventId', eventId))..add(DiagnosticsProperty('hasherOwnEventId', hasherOwnEventId))..add(DiagnosticsProperty('userStartEvent', userStartEvent))..add(DiagnosticsProperty('userEndEvent', userEndEvent))..add(DiagnosticsProperty('rsvpState', rsvpState))..add(DiagnosticsProperty('attendenceState', attendenceState))..add(DiagnosticsProperty('isHare', isHare))..add(DiagnosticsProperty('eventNotificationPreference', eventNotificationPreference))..add(DiagnosticsProperty('eventEmailAlertPreference', eventEmailAlertPreference))..add(DiagnosticsProperty('totalHaring', totalHaring))..add(DiagnosticsProperty('totalHaringThisKennel', totalHaringThisKennel))..add(DiagnosticsProperty('totalRuns', totalRuns))..add(DiagnosticsProperty('totalRunsThisKennel', totalRunsThisKennel))..add(DiagnosticsProperty('eventCountOverride', eventCountOverride))..add(DiagnosticsProperty('virginVisitorType', virginVisitorType))..add(DiagnosticsProperty('displayName', displayName))..add(DiagnosticsProperty('email', email))..add(DiagnosticsProperty('phoneNumber', phoneNumber))..add(DiagnosticsProperty('hemEventName', hemEventName))..add(DiagnosticsProperty('hemCountryId', hemCountryId))..add(DiagnosticsProperty('hemEventNumber', hemEventNumber))..add(DiagnosticsProperty('hemEventStartDatetime', hemEventStartDatetime))..add(DiagnosticsProperty('hemCanEditRunAttendence', hemCanEditRunAttendence))..add(DiagnosticsProperty('hemEventKennelId', hemEventKennelId))..add(DiagnosticsProperty('hemEventIsCountedAndVisible', hemEventIsCountedAndVisible))..add(DiagnosticsProperty('hemKennelUserPhoto', hemKennelUserPhoto))..add(DiagnosticsProperty('hemKennelHashName', hemKennelHashName))..add(DiagnosticsProperty('removed', removed))..add(DiagnosticsProperty('updatedAt', updatedAt));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HasherEventMapModel&&(identical(other.hemId, hemId) || other.hemId == hemId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.hasherOwnEventId, hasherOwnEventId) || other.hasherOwnEventId == hasherOwnEventId)&&(identical(other.userStartEvent, userStartEvent) || other.userStartEvent == userStartEvent)&&(identical(other.userEndEvent, userEndEvent) || other.userEndEvent == userEndEvent)&&(identical(other.rsvpState, rsvpState) || other.rsvpState == rsvpState)&&(identical(other.attendenceState, attendenceState) || other.attendenceState == attendenceState)&&(identical(other.isHare, isHare) || other.isHare == isHare)&&(identical(other.eventNotificationPreference, eventNotificationPreference) || other.eventNotificationPreference == eventNotificationPreference)&&(identical(other.eventEmailAlertPreference, eventEmailAlertPreference) || other.eventEmailAlertPreference == eventEmailAlertPreference)&&(identical(other.totalHaring, totalHaring) || other.totalHaring == totalHaring)&&(identical(other.totalHaringThisKennel, totalHaringThisKennel) || other.totalHaringThisKennel == totalHaringThisKennel)&&(identical(other.totalRuns, totalRuns) || other.totalRuns == totalRuns)&&(identical(other.totalRunsThisKennel, totalRunsThisKennel) || other.totalRunsThisKennel == totalRunsThisKennel)&&(identical(other.eventCountOverride, eventCountOverride) || other.eventCountOverride == eventCountOverride)&&(identical(other.virginVisitorType, virginVisitorType) || other.virginVisitorType == virginVisitorType)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.email, email) || other.email == email)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.hemEventName, hemEventName) || other.hemEventName == hemEventName)&&(identical(other.hemCountryId, hemCountryId) || other.hemCountryId == hemCountryId)&&(identical(other.hemEventNumber, hemEventNumber) || other.hemEventNumber == hemEventNumber)&&(identical(other.hemEventStartDatetime, hemEventStartDatetime) || other.hemEventStartDatetime == hemEventStartDatetime)&&(identical(other.hemCanEditRunAttendence, hemCanEditRunAttendence) || other.hemCanEditRunAttendence == hemCanEditRunAttendence)&&(identical(other.hemEventKennelId, hemEventKennelId) || other.hemEventKennelId == hemEventKennelId)&&(identical(other.hemEventIsCountedAndVisible, hemEventIsCountedAndVisible) || other.hemEventIsCountedAndVisible == hemEventIsCountedAndVisible)&&(identical(other.hemKennelUserPhoto, hemKennelUserPhoto) || other.hemKennelUserPhoto == hemKennelUserPhoto)&&(identical(other.hemKennelHashName, hemKennelHashName) || other.hemKennelHashName == hemKennelHashName)&&(identical(other.removed, removed) || other.removed == removed)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,hemId,userId,eventId,hasherOwnEventId,userStartEvent,userEndEvent,rsvpState,attendenceState,isHare,eventNotificationPreference,eventEmailAlertPreference,totalHaring,totalHaringThisKennel,totalRuns,totalRunsThisKennel,eventCountOverride,virginVisitorType,displayName,email,phoneNumber,hemEventName,hemCountryId,hemEventNumber,hemEventStartDatetime,hemCanEditRunAttendence,hemEventKennelId,hemEventIsCountedAndVisible,hemKennelUserPhoto,hemKennelHashName,removed,updatedAt]);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'HasherEventMapModel(hemId: $hemId, userId: $userId, eventId: $eventId, hasherOwnEventId: $hasherOwnEventId, userStartEvent: $userStartEvent, userEndEvent: $userEndEvent, rsvpState: $rsvpState, attendenceState: $attendenceState, isHare: $isHare, eventNotificationPreference: $eventNotificationPreference, eventEmailAlertPreference: $eventEmailAlertPreference, totalHaring: $totalHaring, totalHaringThisKennel: $totalHaringThisKennel, totalRuns: $totalRuns, totalRunsThisKennel: $totalRunsThisKennel, eventCountOverride: $eventCountOverride, virginVisitorType: $virginVisitorType, displayName: $displayName, email: $email, phoneNumber: $phoneNumber, hemEventName: $hemEventName, hemCountryId: $hemCountryId, hemEventNumber: $hemEventNumber, hemEventStartDatetime: $hemEventStartDatetime, hemCanEditRunAttendence: $hemCanEditRunAttendence, hemEventKennelId: $hemEventKennelId, hemEventIsCountedAndVisible: $hemEventIsCountedAndVisible, hemKennelUserPhoto: $hemKennelUserPhoto, hemKennelHashName: $hemKennelHashName, removed: $removed, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$HasherEventMapModelCopyWith<$Res> implements $HasherEventMapModelCopyWith<$Res> {
  factory _$HasherEventMapModelCopyWith(_HasherEventMapModel value, $Res Function(_HasherEventMapModel) _then) = __$HasherEventMapModelCopyWithImpl;
@override @useResult
$Res call({
 String hemId, String userId, String eventId, String? hasherOwnEventId, String? userStartEvent, String? userEndEvent, int rsvpState, int attendenceState, int isHare, int? eventNotificationPreference, int? eventEmailAlertPreference, int? totalHaring, int? totalHaringThisKennel, int? totalRuns, int? totalRunsThisKennel, int? eventCountOverride, int virginVisitorType, String? displayName, String? email, String? phoneNumber, String? hemEventName, String? hemCountryId, int? hemEventNumber, DateTime hemEventStartDatetime, int? hemCanEditRunAttendence, String? hemEventKennelId, int? hemEventIsCountedAndVisible, String? hemKennelUserPhoto, String? hemKennelHashName, int? removed, DateTime? updatedAt
});




}
/// @nodoc
class __$HasherEventMapModelCopyWithImpl<$Res>
    implements _$HasherEventMapModelCopyWith<$Res> {
  __$HasherEventMapModelCopyWithImpl(this._self, this._then);

  final _HasherEventMapModel _self;
  final $Res Function(_HasherEventMapModel) _then;

/// Create a copy of HasherEventMapModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? hemId = null,Object? userId = null,Object? eventId = null,Object? hasherOwnEventId = freezed,Object? userStartEvent = freezed,Object? userEndEvent = freezed,Object? rsvpState = null,Object? attendenceState = null,Object? isHare = null,Object? eventNotificationPreference = freezed,Object? eventEmailAlertPreference = freezed,Object? totalHaring = freezed,Object? totalHaringThisKennel = freezed,Object? totalRuns = freezed,Object? totalRunsThisKennel = freezed,Object? eventCountOverride = freezed,Object? virginVisitorType = null,Object? displayName = freezed,Object? email = freezed,Object? phoneNumber = freezed,Object? hemEventName = freezed,Object? hemCountryId = freezed,Object? hemEventNumber = freezed,Object? hemEventStartDatetime = null,Object? hemCanEditRunAttendence = freezed,Object? hemEventKennelId = freezed,Object? hemEventIsCountedAndVisible = freezed,Object? hemKennelUserPhoto = freezed,Object? hemKennelHashName = freezed,Object? removed = freezed,Object? updatedAt = freezed,}) {
  return _then(_HasherEventMapModel(
hemId: null == hemId ? _self.hemId : hemId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,hasherOwnEventId: freezed == hasherOwnEventId ? _self.hasherOwnEventId : hasherOwnEventId // ignore: cast_nullable_to_non_nullable
as String?,userStartEvent: freezed == userStartEvent ? _self.userStartEvent : userStartEvent // ignore: cast_nullable_to_non_nullable
as String?,userEndEvent: freezed == userEndEvent ? _self.userEndEvent : userEndEvent // ignore: cast_nullable_to_non_nullable
as String?,rsvpState: null == rsvpState ? _self.rsvpState : rsvpState // ignore: cast_nullable_to_non_nullable
as int,attendenceState: null == attendenceState ? _self.attendenceState : attendenceState // ignore: cast_nullable_to_non_nullable
as int,isHare: null == isHare ? _self.isHare : isHare // ignore: cast_nullable_to_non_nullable
as int,eventNotificationPreference: freezed == eventNotificationPreference ? _self.eventNotificationPreference : eventNotificationPreference // ignore: cast_nullable_to_non_nullable
as int?,eventEmailAlertPreference: freezed == eventEmailAlertPreference ? _self.eventEmailAlertPreference : eventEmailAlertPreference // ignore: cast_nullable_to_non_nullable
as int?,totalHaring: freezed == totalHaring ? _self.totalHaring : totalHaring // ignore: cast_nullable_to_non_nullable
as int?,totalHaringThisKennel: freezed == totalHaringThisKennel ? _self.totalHaringThisKennel : totalHaringThisKennel // ignore: cast_nullable_to_non_nullable
as int?,totalRuns: freezed == totalRuns ? _self.totalRuns : totalRuns // ignore: cast_nullable_to_non_nullable
as int?,totalRunsThisKennel: freezed == totalRunsThisKennel ? _self.totalRunsThisKennel : totalRunsThisKennel // ignore: cast_nullable_to_non_nullable
as int?,eventCountOverride: freezed == eventCountOverride ? _self.eventCountOverride : eventCountOverride // ignore: cast_nullable_to_non_nullable
as int?,virginVisitorType: null == virginVisitorType ? _self.virginVisitorType : virginVisitorType // ignore: cast_nullable_to_non_nullable
as int,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,phoneNumber: freezed == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String?,hemEventName: freezed == hemEventName ? _self.hemEventName : hemEventName // ignore: cast_nullable_to_non_nullable
as String?,hemCountryId: freezed == hemCountryId ? _self.hemCountryId : hemCountryId // ignore: cast_nullable_to_non_nullable
as String?,hemEventNumber: freezed == hemEventNumber ? _self.hemEventNumber : hemEventNumber // ignore: cast_nullable_to_non_nullable
as int?,hemEventStartDatetime: null == hemEventStartDatetime ? _self.hemEventStartDatetime : hemEventStartDatetime // ignore: cast_nullable_to_non_nullable
as DateTime,hemCanEditRunAttendence: freezed == hemCanEditRunAttendence ? _self.hemCanEditRunAttendence : hemCanEditRunAttendence // ignore: cast_nullable_to_non_nullable
as int?,hemEventKennelId: freezed == hemEventKennelId ? _self.hemEventKennelId : hemEventKennelId // ignore: cast_nullable_to_non_nullable
as String?,hemEventIsCountedAndVisible: freezed == hemEventIsCountedAndVisible ? _self.hemEventIsCountedAndVisible : hemEventIsCountedAndVisible // ignore: cast_nullable_to_non_nullable
as int?,hemKennelUserPhoto: freezed == hemKennelUserPhoto ? _self.hemKennelUserPhoto : hemKennelUserPhoto // ignore: cast_nullable_to_non_nullable
as String?,hemKennelHashName: freezed == hemKennelHashName ? _self.hemKennelHashName : hemKennelHashName // ignore: cast_nullable_to_non_nullable
as String?,removed: freezed == removed ? _self.removed : removed // ignore: cast_nullable_to_non_nullable
as int?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
