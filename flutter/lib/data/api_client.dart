import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../models/app_models.dart';

class ApiClient {
  ApiClient({required this.baseUrl, required this.sessionId, this.accessToken});

  final String baseUrl;
  final String sessionId;
  final String? accessToken;

  Uri _uri(String path, {Map<String, String?> queryParameters = const {}}) {
    final raw = Uri.parse('$baseUrl$path');
    final filtered = <String, String>{};
    for (final entry in queryParameters.entries) {
      final value = entry.value?.trim();
      if (value != null && value.isNotEmpty) {
        filtered[entry.key] = value;
      }
    }
    if (filtered.isEmpty) {
      return raw;
    }
    return raw.replace(queryParameters: {...raw.queryParameters, ...filtered});
  }

  Map<String, String> _headers({bool json = false, bool form = false}) {
    final headers = <String, String>{};
    if (accessToken != null && accessToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $accessToken';
    }
    if (json) {
      headers['Content-Type'] = 'application/json';
    }
    if (form) {
      headers['Content-Type'] = 'application/x-www-form-urlencoded';
    }
    return headers;
  }

  Future<String> ping() async {
    final response = await http.get(_uri('/'));
    final data = _decodeJsonObject(response);
    return data['message']?.toString() ?? 'Backend reachable';
  }

  Future<AuthToken> signup({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final response = await http.post(
      _uri('/api/auth/signup'),
      headers: _headers(json: true),
      body: jsonEncode({
        'email': email,
        'password': password,
        'full_name': fullName,
      }),
    );
    return AuthToken.fromJson(_decodeJsonObject(response));
  }

  Future<AuthToken> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      _uri('/api/auth/login'),
      headers: _headers(form: true),
      body: {'username': email, 'password': password},
    );
    return AuthToken.fromJson(_decodeJsonObject(response));
  }

  Future<UserProfileData> getProfile() async {
    final response = await http.get(
      _uri(
        '/api/profile/',
        queryParameters: accessToken == null
            ? {'session_id': sessionId}
            : const {},
      ),
      headers: _headers(),
    );
    return UserProfileData.fromJson(_decodeJsonObject(response));
  }

  Future<UserProfileData> updateProfile(UserProfileData profile) async {
    final response = await http.post(
      _uri('/api/profile/'),
      headers: _headers(json: true),
      body: jsonEncode(
        profile.toJson()..putIfAbsent(
          'session_id',
          () => accessToken == null ? sessionId : null,
        ),
      ),
    );
    return UserProfileData.fromJson(_decodeJsonObject(response));
  }

  Future<AnalyzeResponse> analyze({
    required Uint8List bytes,
    required String filename,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      _uri(
        '/api/analyze/',
        queryParameters: accessToken == null
            ? {'session_id': sessionId}
            : const {},
      ),
    );
    request.headers.addAll(_headers());
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
        contentType: _inferMediaType(filename),
      ),
    );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return AnalyzeResponse.fromJson(_decodeJsonObject(response));
  }

  Future<List<ScanHistoryItem>> getScanHistory() async {
    final response = await http.get(
      _uri('/api/history/scans'),
      headers: _headers(),
    );
    return _decodeJsonList(response).map(ScanHistoryItem.fromJson).toList();
  }

  Future<Map<String, int>> getHistoryStats() async {
    final response = await http.get(
      _uri('/api/history/stats'),
      headers: _headers(),
    );
    final data = _decodeJsonObject(response);
    return {
      'total_scans': data['total_scans'] as int,
      'safe_products': data['safe_products'] as int,
    };
  }

  Future<List<SavedProductItem>> getSavedProducts() async {
    final response = await http.get(
      _uri('/api/history/saved-products'),
      headers: _headers(),
    );
    return _decodeJsonList(response).map(SavedProductItem.fromJson).toList();
  }

  Future<String> saveProduct(int scanId) async {
    final response = await http.post(
      _uri('/api/history/save-product'),
      headers: _headers(json: true),
      body: jsonEncode({'scan_id': scanId}),
    );
    final data = _decodeJsonObject(response);
    return data['message']?.toString() ?? 'Saved';
  }

  Future<SharedScanData> getSharedScan(String token) async {
    final response = await http.get(_uri('/api/shared/$token'));
    return SharedScanData.fromJson(_decodeJsonObject(response));
  }

  Map<String, dynamic> _decodeJsonObject(http.Response response) {
    final body = utf8.decode(response.bodyBytes);
    dynamic decoded;
    if (body.isNotEmpty) {
      try {
        decoded = jsonDecode(body);
      } catch (_) {
        decoded = null;
      }
    }

    if (response.statusCode >= 400) {
      throw ApiException(
        _extractErrorMessage(decoded) ?? 'Request failed',
        statusCode: response.statusCode,
        body: body,
      );
    }

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return decoded.cast<String, dynamic>();
    }
    throw ApiException(
      'Unexpected response format',
      statusCode: response.statusCode,
    );
  }

  List<Map<String, dynamic>> _decodeJsonList(http.Response response) {
    final body = utf8.decode(response.bodyBytes);
    dynamic decoded;
    if (body.isNotEmpty) {
      try {
        decoded = jsonDecode(body);
      } catch (_) {
        decoded = null;
      }
    }

    if (response.statusCode >= 400) {
      throw ApiException(
        _extractErrorMessage(decoded) ?? 'Request failed',
        statusCode: response.statusCode,
        body: body,
      );
    }

    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((item) => item.cast<String, dynamic>())
          .toList();
    }
    throw ApiException(
      'Unexpected list response format',
      statusCode: response.statusCode,
    );
  }

  String? _extractErrorMessage(dynamic decoded) {
    if (decoded is Map) {
      final detail = decoded['detail'];
      if (detail is String && detail.trim().isNotEmpty) {
        return detail;
      }
    }
    return null;
  }
}

MediaType _inferMediaType(String filename) {
  final lower = filename.toLowerCase();
  if (lower.endsWith('.png')) {
    return MediaType('image', 'png');
  }
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
    return MediaType('image', 'jpeg');
  }
  if (lower.endsWith('.webp')) {
    return MediaType('image', 'webp');
  }
  return MediaType('application', 'octet-stream');
}
