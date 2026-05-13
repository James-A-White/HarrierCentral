/// Typed result returned by service operations.
/// Use instead of returning null or magic strings for error states.
///
/// Usage:
///   ServiceResult[String] result = await someService.doThing();
///   if (result.isSuccess) { use(result.value!); }
///   else { showError(result.errorMessage); }
sealed class ServiceResult<T> {
  const ServiceResult();

  bool get isSuccess => this is ServiceSuccess<T>;
  bool get isFailure => this is ServiceFailure<T>;

  T? get value => isSuccess ? (this as ServiceSuccess<T>).data : null;
  String? get errorMessage =>
      isFailure ? (this as ServiceFailure<T>).message : null;
  int? get errorCode => isFailure ? (this as ServiceFailure<T>).code : null;

  factory ServiceResult.success(T data) => ServiceSuccess(data);
  factory ServiceResult.failure(String message, {int? code}) =>
      ServiceFailure(message, code: code);
}

final class ServiceSuccess<T> extends ServiceResult<T> {
  const ServiceSuccess(this.data);
  final T data;
}

final class ServiceFailure<T> extends ServiceResult<T> {
  const ServiceFailure(this.message, {this.code});
  final String message;
  final int? code;
}
