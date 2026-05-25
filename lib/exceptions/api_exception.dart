import 'api_error_codes.dart';

class ApiException implements Exception {
  final ApiErrorCode code;
  final String? debugMessage;
  final int? statusCode;

  ApiException(this.code, {this.debugMessage, this.statusCode});

  @override
  String toString() =>
      'ApiException($code${debugMessage != null ? ': $debugMessage' : ''})';
}

class TickerNotFoundException extends ApiException {
  TickerNotFoundException({String? ticker})
      : super(ApiErrorCode.tickerNotFound,
            statusCode: 404, debugMessage: ticker);
}
