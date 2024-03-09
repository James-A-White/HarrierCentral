// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'single_result_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

SingleResultModel _$SingleResultModelFromJson(Map<String, dynamic> json) {
  return _SingleResultModel.fromJson(json);
}

/// @nodoc
mixin _$SingleResultModel {
  String? get result => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SingleResultModelCopyWith<SingleResultModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SingleResultModelCopyWith<$Res> {
  factory $SingleResultModelCopyWith(
          SingleResultModel value, $Res Function(SingleResultModel) then) =
      _$SingleResultModelCopyWithImpl<$Res, SingleResultModel>;
  @useResult
  $Res call({String? result});
}

/// @nodoc
class _$SingleResultModelCopyWithImpl<$Res, $Val extends SingleResultModel>
    implements $SingleResultModelCopyWith<$Res> {
  _$SingleResultModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? result = freezed,
  }) {
    return _then(_value.copyWith(
      result: freezed == result
          ? _value.result
          : result // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SingleResultModelImplCopyWith<$Res>
    implements $SingleResultModelCopyWith<$Res> {
  factory _$$SingleResultModelImplCopyWith(_$SingleResultModelImpl value,
          $Res Function(_$SingleResultModelImpl) then) =
      __$$SingleResultModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String? result});
}

/// @nodoc
class __$$SingleResultModelImplCopyWithImpl<$Res>
    extends _$SingleResultModelCopyWithImpl<$Res, _$SingleResultModelImpl>
    implements _$$SingleResultModelImplCopyWith<$Res> {
  __$$SingleResultModelImplCopyWithImpl(_$SingleResultModelImpl _value,
      $Res Function(_$SingleResultModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? result = freezed,
  }) {
    return _then(_$SingleResultModelImpl(
      result: freezed == result
          ? _value.result
          : result // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SingleResultModelImpl implements _SingleResultModel {
  _$SingleResultModelImpl({this.result});

  factory _$SingleResultModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$SingleResultModelImplFromJson(json);

  @override
  final String? result;

  @override
  String toString() {
    return 'SingleResultModel(result: $result)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SingleResultModelImpl &&
            (identical(other.result, result) || other.result == result));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, result);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SingleResultModelImplCopyWith<_$SingleResultModelImpl> get copyWith =>
      __$$SingleResultModelImplCopyWithImpl<_$SingleResultModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SingleResultModelImplToJson(
      this,
    );
  }
}

abstract class _SingleResultModel implements SingleResultModel {
  factory _SingleResultModel({final String? result}) = _$SingleResultModelImpl;

  factory _SingleResultModel.fromJson(Map<String, dynamic> json) =
      _$SingleResultModelImpl.fromJson;

  @override
  String? get result;
  @override
  @JsonKey(ignore: true)
  _$$SingleResultModelImplCopyWith<_$SingleResultModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
