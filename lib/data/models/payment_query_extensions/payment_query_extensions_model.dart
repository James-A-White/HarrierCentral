import 'package:harrier_central/imports.dart';

part 'payment_query_extensions_model.freezed.dart';
part 'payment_query_extensions_model.g.dart';

@freezed
abstract class PaymentQueryExtensionsModel
    with _$PaymentQueryExtensionsModel
    implements BaseModel {
  factory PaymentQueryExtensionsModel({
    required String pkHemId,
    required String paidByName,
    required String paidToName,
    @Default(0) int isMember,
    @Default(0.0) double creditAvailable,
    @Default(0.0) double eventPriceForMembers,
    @Default(0.0) double eventPriceForNonMembers,
    String? confByName,
    @Default(0.0) double extrasPrice,
    String? extrasDescription,
    @Default(0.0) double discountAmountAvailable,
    @Default(0) int discountPercentAvailable,
    @Default(0) int isFollowing,
    String? discountAvailableDescription,
    @Default(false) bool isHashCredit,
  }) = _PaymentQueryExtensionsModel;

  factory PaymentQueryExtensionsModel.fromJson(Map<String, dynamic> json) =>
      _$PaymentQueryExtensionsModelFromJson(json);

  @override
  factory PaymentQueryExtensionsModel.fromMap(Map<String, dynamic> map) {
    return PaymentQueryExtensionsModel.fromJson(map);
  }
}
