// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'single_result_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SingleResultModel implements DiagnosticableTreeMixin {

 String? get result;
/// Create a copy of SingleResultModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SingleResultModelCopyWith<SingleResultModel> get copyWith => _$SingleResultModelCopyWithImpl<SingleResultModel>(this as SingleResultModel, _$identity);

  /// Serializes this SingleResultModel to a JSON map.
  Map<String, dynamic> toJson();

@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'SingleResultModel'))
    ..add(DiagnosticsProperty('result', result));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SingleResultModel&&(identical(other.result, result) || other.result == result));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,result);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'SingleResultModel(result: $result)';
}


}

/// @nodoc
abstract mixin class $SingleResultModelCopyWith<$Res>  {
  factory $SingleResultModelCopyWith(SingleResultModel value, $Res Function(SingleResultModel) _then) = _$SingleResultModelCopyWithImpl;
@useResult
$Res call({
 String? result
});




}
/// @nodoc
class _$SingleResultModelCopyWithImpl<$Res>
    implements $SingleResultModelCopyWith<$Res> {
  _$SingleResultModelCopyWithImpl(this._self, this._then);

  final SingleResultModel _self;
  final $Res Function(SingleResultModel) _then;

/// Create a copy of SingleResultModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? result = freezed,}) {
  return _then(_self.copyWith(
result: freezed == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SingleResultModel].
extension SingleResultModelPatterns on SingleResultModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SingleResultModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SingleResultModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SingleResultModel value)  $default,){
final _that = this;
switch (_that) {
case _SingleResultModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SingleResultModel value)?  $default,){
final _that = this;
switch (_that) {
case _SingleResultModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? result)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SingleResultModel() when $default != null:
return $default(_that.result);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? result)  $default,) {final _that = this;
switch (_that) {
case _SingleResultModel():
return $default(_that.result);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? result)?  $default,) {final _that = this;
switch (_that) {
case _SingleResultModel() when $default != null:
return $default(_that.result);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SingleResultModel with DiagnosticableTreeMixin implements SingleResultModel {
   _SingleResultModel({this.result});
  factory _SingleResultModel.fromJson(Map<String, dynamic> json) => _$SingleResultModelFromJson(json);

@override final  String? result;

/// Create a copy of SingleResultModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SingleResultModelCopyWith<_SingleResultModel> get copyWith => __$SingleResultModelCopyWithImpl<_SingleResultModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SingleResultModelToJson(this, );
}
@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'SingleResultModel'))
    ..add(DiagnosticsProperty('result', result));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SingleResultModel&&(identical(other.result, result) || other.result == result));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,result);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'SingleResultModel(result: $result)';
}


}

/// @nodoc
abstract mixin class _$SingleResultModelCopyWith<$Res> implements $SingleResultModelCopyWith<$Res> {
  factory _$SingleResultModelCopyWith(_SingleResultModel value, $Res Function(_SingleResultModel) _then) = __$SingleResultModelCopyWithImpl;
@override @useResult
$Res call({
 String? result
});




}
/// @nodoc
class __$SingleResultModelCopyWithImpl<$Res>
    implements _$SingleResultModelCopyWith<$Res> {
  __$SingleResultModelCopyWithImpl(this._self, this._then);

  final _SingleResultModel _self;
  final $Res Function(_SingleResultModel) _then;

/// Create a copy of SingleResultModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? result = freezed,}) {
  return _then(_SingleResultModel(
result: freezed == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
