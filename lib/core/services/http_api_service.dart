import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class HttpApiService {
  static String get _baseUrl => AppConfig.baseUrl;
  
  Map<String, String> _getHeaders() => {
    'Content-Type': 'application/json',
    'x-api-key': AppConfig.apiAccessKey,
  };

  Future<dynamic> get(String endpoint, {Map<String, String>? customHeaders}) async {
    final headers = customHeaders ?? _getHeaders();
    final response = await http.get(Uri.parse('$_baseUrl$endpoint'), headers: headers);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load data from $_baseUrl$endpoint, Status: ${response.statusCode}');
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body, {Map<String, String>? customHeaders}) async {
    final headers = customHeaders ?? _getHeaders();
    final response = await http.post(
      Uri.parse('$_baseUrl$endpoint'),
      headers: headers,
      body: json.encode(body),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to post data to $_baseUrl$endpoint, Status: ${response.statusCode}');
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> body, {Map<String, String>? customHeaders}) async {
    final headers = customHeaders ?? _getHeaders();
    final response = await http.put(
      Uri.parse('$_baseUrl$endpoint'),
      headers: headers,
      body: json.encode(body),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to put data to $_baseUrl$endpoint, Status: ${response.statusCode}');
  }

  Future<dynamic> delete(String endpoint, {Map<String, String>? customHeaders}) async {
    final headers = customHeaders ?? _getHeaders();
    final response = await http.delete(Uri.parse('$_baseUrl$endpoint'), headers: headers);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to delete data at $_baseUrl$endpoint, Status: ${response.statusCode}');
  }
}
