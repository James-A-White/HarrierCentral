// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'db_error_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DbErrorModelImpl _$$DbErrorModelImplFromJson(Map<String, dynamic> json) =>
    _$DbErrorModelImpl(
      errorId: json['errorId'] as String?,
      errorType: json['errorType'] as num?,
      errorTitle: json['errorTitle'] as String?,
      errorUserMessage: json['errorUserMessage'] as String?,
      debugMessage: json['debugMessage'] as String?,
      errorProc: json['errorProc'] as String?,
    );

Map<String, dynamic> _$$DbErrorModelImplToJson(_$DbErrorModelImpl instance) =>
    <String, dynamic>{
      'errorId': instance.errorId,
      'errorType': instance.errorType,
      'errorTitle': instance.errorTitle,
      'errorUserMessage': instance.errorUserMessage,
      'debugMessage': instance.debugMessage,
      'errorProc': instance.errorProc,
    };
