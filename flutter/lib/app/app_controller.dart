import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/api_client.dart';
import '../models/app_models.dart';

class AppController extends ChangeNotifier {
  AppController._({
    SharedPreferences? prefs,
    required String backendUrl,
    required String sessionId,
    String? accessToken,
    String? currentEmail,
    String? healthMessage,
    bool backendReachable = false,
  }) : _prefs = prefs,
       _backendUrl = backendUrl,
       _sessionId = sessionId,
       _accessToken = accessToken,
       _currentEmail = currentEmail,
       _healthMessage = healthMessage,
       _backendReachable = backendReachable;

  static const _backendUrlKey = 'backend_url';
  static const _sessionIdKey = 'session_id';
  static const _accessTokenKey = 'access_token';
  static const _currentEmailKey = 'current_email';

  final SharedPreferences? _prefs;

  String _backendUrl;
  String _sessionId;
  String? _accessToken;
  String? _currentEmail;
  String? _healthMessage;
  bool _backendReachable;
  AnalyzeResponse? _lastAnalysis;
  int _totalScans = 0;
  int _safeProducts = 0;

  static Future<AppController> bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionId = prefs.getString(_sessionIdKey) ?? _generateSessionId();
    final controller = AppController._(
      prefs: prefs,
      backendUrl: prefs.getString(_backendUrlKey) ?? 'http://10.0.2.2:8000',
      sessionId: sessionId,
      accessToken: prefs.getString(_accessTokenKey),
      currentEmail: prefs.getString(_currentEmailKey),
    );
    await controller._persistSessionId();
    await controller.refreshHealth();
    await controller.refreshStats();
    return controller;
  }

  factory AppController.preview() {
    return AppController._(
      backendUrl: 'http://127.0.0.1:8000',
      sessionId: 'preview-session',
      accessToken: null,
      currentEmail: null,
      healthMessage: 'Preview mode',
      backendReachable: true,
    );
  }

  String get backendUrl => _backendUrl;
  String get sessionId => _sessionId;
  String? get accessToken => _accessToken;
  String? get currentEmail => _currentEmail;
  String? get healthMessage => _healthMessage;
  bool get backendReachable => _backendReachable;
  bool get isAuthenticated => _accessToken != null && _accessToken!.isNotEmpty;
  AnalyzeResponse? get lastAnalysis => _lastAnalysis;
  int get totalScans => _totalScans;
  int get safeProducts => _safeProducts;

  ApiClient get api => ApiClient(
    baseUrl: _backendUrl,
    sessionId: _sessionId,
    accessToken: _accessToken,
  );

  Future<void> setBackendUrl(String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == _backendUrl) {
      return;
    }
    _backendUrl = trimmed;
    await _prefs?.setString(_backendUrlKey, _backendUrl);
    notifyListeners();
    await refreshHealth();
  }

  Future<void> refreshHealth() async {
    try {
      _healthMessage = await api.ping();
      _backendReachable = true;
    } catch (error) {
      _healthMessage = error.toString();
      _backendReachable = false;
    }
    notifyListeners();
  }

  Future<void> login({required String email, required String password}) async {
    final token = await api.login(email: email, password: password);
    await _applyAuthState(token: token, email: email);
  }

  Future<void> signup({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final token = await api.signup(
      email: email,
      password: password,
      fullName: fullName,
    );
    await _applyAuthState(token: token, email: email);
  }

  Future<void> logout() async {
    _accessToken = null;
    _currentEmail = null;
    _totalScans = 0;
    _safeProducts = 0;
    await _prefs?.remove(_accessTokenKey);
    await _prefs?.remove(_currentEmailKey);
    notifyListeners();
  }

  Future<UserProfileData> loadProfile() async {
    return api.getProfile();
  }

  Future<UserProfileData> saveProfile(UserProfileData profile) async {
    return api.updateProfile(profile);
  }

  Future<AnalyzeResponse> analyze({
    required Uint8List bytes,
    required String filename,
  }) async {
    final response = await api.analyze(bytes: bytes, filename: filename);
    _lastAnalysis = response;
    notifyListeners();
    return response;
  }

  Future<List<ScanHistoryItem>> fetchScans() async {
    return api.getScanHistory();
  }

  Future<List<SavedProductItem>> fetchSavedProducts() async {
    return api.getSavedProducts();
  }

  Future<String> saveProduct(int scanId) async {
    return api.saveProduct(scanId);
  }

  Future<SharedScanData> fetchSharedScan(String token) async {
    return api.getSharedScan(token);
  }

  Future<void> refreshStats() async {
    if (!isAuthenticated) return;
    try {
      final stats = await api.getHistoryStats();
      _totalScans = stats['total_scans'] ?? 0;
      _safeProducts = stats['safe_products'] ?? 0;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _applyAuthState({
    required AuthToken token,
    required String email,
  }) async {
    _accessToken = token.accessToken;
    _currentEmail = email;
    await _prefs?.setString(_accessTokenKey, token.accessToken);
    await _prefs?.setString(_currentEmailKey, email);
    await refreshStats();
    notifyListeners();
  }

  Future<void> _persistSessionId() async {
    await _prefs?.setString(_sessionIdKey, _sessionId);
  }

  static String _generateSessionId() {
    final random = Random.secure();
    final bytes = List<int>.generate(18, (_) => random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }
}
