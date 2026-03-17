// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'email_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EmailModel _$EmailModelFromJson(Map<String, dynamic> json) => _EmailModel(
      subject: json['subject'] as String,
      body: json['body'] as String,
      sendTo: json['sendTo'] as String,
      intTest: (json['intTest'] as num).toInt(),
      sendFrom: json['sendFrom'] as String?,
      cc: json['cc'] as String?,
      bcc: json['bcc'] as String?,
      replyTo: json['replyTo'] as String?,
      attachmentFileName: json['attachmentFileName'] as String?,
      attachmentFileContentBase64:
          json['attachmentFileContentBase64'] as String?,
    );

Map<String, dynamic> _$EmailModelToJson(_EmailModel instance) =>
    <String, dynamic>{
      'subject': instance.subject,
      'body': instance.body,
      'sendTo': instance.sendTo,
      'intTest': instance.intTest,
      'sendFrom': instance.sendFrom,
      'cc': instance.cc,
      'bcc': instance.bcc,
      'replyTo': instance.replyTo,
      'attachmentFileName': instance.attachmentFileName,
      'attachmentFileContentBase64': instance.attachmentFileContentBase64,
    };
