import 'package:harrier_central/imports.dart';

part 'single_result_model.freezed.dart';
part 'single_result_model.g.dart';

@freezed
abstract class SingleResultModel with _$SingleResultModel implements BaseModel {
  factory SingleResultModel({String? result}) = _SingleResultModel;

  factory SingleResultModel.fromJson(Map<String, dynamic> json) =>
      _$SingleResultModelFromJson(json);

  @override
  factory SingleResultModel.fromMap(Map<String, dynamic> map) {
    return SingleResultModel.fromJson(map);
  }
}
