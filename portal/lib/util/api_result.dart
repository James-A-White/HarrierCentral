sealed class ApiResult {
  const ApiResult();
}

final class ApiSuccess extends ApiResult {
  const ApiSuccess(this.body);
  final String body;
}

final class ApiError extends ApiResult {
  const ApiError();
}
