import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  ApiException(this.statusCode, this.message, [this.errors]);

  final int statusCode;
  final String message;
  final Map<String, dynamic>? errors;

  @override
  String toString() => message;
}

/// Thin HTTP wrapper: base URL, bearer token, JSON decode, error mapping.
class ApiClient {
  ApiClient({String? baseUrl}) : baseUrl = baseUrl ?? _defaultBaseUrl();

  final String baseUrl;
  String? _token;

  set token(String? value) => _token = value;

  static String _defaultBaseUrl() {
    // Android emulator reaches the host machine via 10.0.2.2.
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:8000/api';
    return 'http://127.0.0.1:8000/api';
  }

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<Map<String, dynamic>> get(String path,
      [Map<String, String>? query]) async {
    final uri =
        Uri.parse('$baseUrl$path').replace(queryParameters: query);
    return _handle(await http.get(uri, headers: _headers));
  }

  Future<Map<String, dynamic>> post(String path,
      [Map<String, dynamic>? body]) async {
    return _handle(await http.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
      body: jsonEncode(body ?? {}),
    ));
  }

  /// Multipart upload (e.g. avatar image) from raw bytes.
  Future<Map<String, dynamic>> uploadBytes(
    String path, {
    required String field,
    required List<int> bytes,
    required String filename,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'))
      ..headers.addAll({
        'Accept': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      })
      ..files.add(http.MultipartFile.fromBytes(field, bytes, filename: filename));

    final streamed = await request.send();
    return _handle(await http.Response.fromStream(streamed));
  }

  Future<Map<String, dynamic>> patch(String path,
      Map<String, dynamic> body) async {
    return _handle(await http.patch(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
      body: jsonEncode(body),
    ));
  }

  Map<String, dynamic> _handle(http.Response response) {
    final Map<String, dynamic> json = response.body.isEmpty
        ? {}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json;
    }

    throw ApiException(
      response.statusCode,
      (json['message'] as String?) ?? 'Terjadi kesalahan (${response.statusCode}).',
      json['errors'] as Map<String, dynamic>?,
    );
  }
}
