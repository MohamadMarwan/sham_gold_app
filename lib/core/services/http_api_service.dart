import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class HttpApiService {
  static String get _baseUrl => AppConfig.baseUrl;

  /// Default timeout durations
  static const Duration _getTimeout = Duration(seconds: 15);
  static const Duration _mutateTimeout = Duration(seconds: 20);

  Map<String, String> _getHeaders() => {
    'Content-Type': 'application/json',
    'x-api-key': AppConfig.apiAccessKey,
  };

  Future<dynamic> _handleResponse(http.Response response, String url) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      String errorMessage = 'Failed to fetch data from $url, Status: ${response.statusCode}';
      try {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic> && decoded.containsKey('message')) {
          errorMessage = decoded['message'];
        }
      } catch (e) {
        // Not a JSON response — use default message
      }
      throw Exception(errorMessage);
    }
  }

  Future<dynamic> get(String endpoint, {Map<String, String>? customHeaders}) async {
    final headers = customHeaders ?? _getHeaders();
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl$endpoint'), headers: headers)
          .timeout(_getTimeout);
      return _handleResponse(response, '$_baseUrl$endpoint');
    } on TimeoutException {
      throw Exception('انتهت مهلة الاتصال. تحقق من اتصالك بالإنترنت وحاول مجدداً.');
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body, {Map<String, String>? customHeaders}) async {
    final headers = customHeaders ?? _getHeaders();
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl$endpoint'),
            headers: headers,
            body: json.encode(body),
          )
          .timeout(_mutateTimeout);
      return _handleResponse(response, '$_baseUrl$endpoint');
    } on TimeoutException {
      throw Exception('انتهت مهلة الإرسال. تحقق من اتصالك بالإنترنت وحاول مجدداً.');
    }
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> body, {Map<String, String>? customHeaders}) async {
    final headers = customHeaders ?? _getHeaders();
    try {
      final response = await http
          .put(
            Uri.parse('$_baseUrl$endpoint'),
            headers: headers,
            body: json.encode(body),
          )
          .timeout(_mutateTimeout);
      return _handleResponse(response, '$_baseUrl$endpoint');
    } on TimeoutException {
      throw Exception('انتهت مهلة التحديث. تحقق من اتصالك بالإنترنت وحاول مجدداً.');
    }
  }

  Future<dynamic> delete(String endpoint, {Map<String, String>? customHeaders}) async {
    final headers = customHeaders ?? _getHeaders();
    try {
      final response = await http
          .delete(Uri.parse('$_baseUrl$endpoint'), headers: headers)
          .timeout(_getTimeout);
      return _handleResponse(response, '$_baseUrl$endpoint');
    } on TimeoutException {
      throw Exception('انتهت مهلة الاتصال. تحقق من اتصالك بالإنترنت وحاول مجدداً.');
    }
  }
}

