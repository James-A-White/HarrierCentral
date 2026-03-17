import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hcportal/imports.dart';

part 'email_model.freezed.dart';
part 'email_model.g.dart';

@freezed
abstract class EmailModel with _$EmailModel {
  const factory EmailModel({
    required String subject,
    required String body,
    required String sendTo,
    required int intTest,
    String? sendFrom,
    String? cc,
    String? bcc,
    String? replyTo,
    String? attachmentFileName,
    String? attachmentFileContentBase64,
  }) = _EmailModel;

  factory EmailModel.fromJson(Map<String, dynamic> json) =>
      _$EmailModelFromJson(json);

  factory EmailModel.empty() => _$EmailModelFromJson(
        json.decode('''
        {
            "subject":"",
            "body":"",
            "sendTo":"",
            "intTest":0
        }
        ''') as Map<String, dynamic>,
      );
}
