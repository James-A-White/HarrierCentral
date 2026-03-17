import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hcportal/imports.dart';

part 'participant_model.freezed.dart';
part 'participant_model.g.dart';

@freezed
abstract class ParticipantModel with _$ParticipantModel {
  const factory ParticipantModel({
    required String displayName,
    required int rsvpState,
    required int attendanceState,
    required int totalRunsThisKennel,
    required int totalHaringThisKennel,
    required String amountPaidStr,
    required String amountOwedStr,
    required String creditAvailableStr,
    required int virginVisitorType,
  }) = _ParticipantModel;

  factory ParticipantModel.fromJson(Map<String, dynamic> json) =>
      _$ParticipantModelFromJson(json);

  factory ParticipantModel.empty() => _$ParticipantModelFromJson(
        json.decode('''
        {
            "displayName":"",
            "rsvpState":0,
            "attendanceState":0,
            "totalRunsThisKennel":0,
            "totalHaringThisKennel":0,
            "amountPaidStr":"",
            "amountOwedStr":"",
            "creditAvailableStr":"",
            "virginVisitorType":0
        }
        ''') as Map<String, dynamic>,
      );
}
