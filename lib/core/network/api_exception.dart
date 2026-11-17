class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  bool get unauthorized => statusCode == 401;
  bool get notFound => statusCode == 404;
  @override
  String toString() => message;
}
