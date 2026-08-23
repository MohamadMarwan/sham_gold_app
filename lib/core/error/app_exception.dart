/// Typed application exceptions — replaces raw `Exception` strings across the app.
///
/// Discriminating on exception type in the UI allows showing contextual
/// messages (e.g., "No internet" vs. "Server error") instead of generic toasts.
library;

// ─── Base Exception ────────────────────────────────────────────────────────
abstract class AppException implements Exception {
  final String message;
  final String? code;
  const AppException(this.message, {this.code});

  @override
  String toString() => 'AppException[$code]: $message';
}

// ─── Network / Connectivity ────────────────────────────────────────────────
/// Thrown when a network call times out.
class TimeoutException extends AppException {
  const TimeoutException([String? msg])
      : super(msg ?? 'انتهت مهلة الاتصال. تحقق من اتصالك بالإنترنت.', code: 'TIMEOUT');
}

/// Thrown when the device has no internet connection.
class NoInternetException extends AppException {
  const NoInternetException([String? msg])
      : super(msg ?? 'لا يوجد اتصال بالإنترنت.', code: 'NO_INTERNET');
}

// ─── Server / API ──────────────────────────────────────────────────────────
/// Thrown when the server returns a non-2xx status code.
class ServerException extends AppException {
  final int? statusCode;
  const ServerException(String message, {this.statusCode, String? code})
      : super(message, code: code ?? 'SERVER_ERROR');
}

/// Thrown when the JSON response cannot be parsed.
class ParseException extends AppException {
  const ParseException([String? msg])
      : super(msg ?? 'خطأ في معالجة البيانات.', code: 'PARSE_ERROR');
}

// ─── Cache ─────────────────────────────────────────────────────────────────
/// Thrown when a required cache entry is missing.
class CacheMissException extends AppException {
  const CacheMissException([String? msg])
      : super(msg ?? 'البيانات المحلية غير متوفرة.', code: 'CACHE_MISS');
}

// ─── Business Logic ────────────────────────────────────────────────────────
/// Thrown when a required resource is not found.
class NotFoundException extends AppException {
  const NotFoundException([String? msg])
      : super(msg ?? 'العنصر المطلوب غير موجود.', code: 'NOT_FOUND');
}

/// Generic fallback for unexpected errors.
class UnknownException extends AppException {
  const UnknownException([String? msg])
      : super(msg ?? 'حدث خطأ غير متوقع.', code: 'UNKNOWN');
}

/// Utility: wraps any exception into a typed [AppException].
AppException wrapException(Object e) {
  if (e is AppException) return e;
  final msg = e.toString();
  if (msg.contains('انتهت مهلة') || msg.contains('TimeoutException')) {
    return const TimeoutException();
  }
  if (msg.contains('SocketException') || msg.contains('No address')) {
    return const NoInternetException();
  }
  return UnknownException(msg);
}
